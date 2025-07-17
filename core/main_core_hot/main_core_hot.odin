/*
Development core exe. Loads build/hot_reload/core.dll and reloads it whenever it
changes.
*/

package main

import "core:dynlib"
import "core:fmt"
import "core:c/libc"
import "core:os"
import "core:os/os2"
import "core:log"
import "core:mem"
import "core:path/filepath"

when ODIN_OS == .Windows {
	DLL_EXT :: ".dll"
} else when ODIN_OS == .Darwin {
	DLL_EXT :: ".dylib"
} else {
	DLL_EXT :: ".so"
}

CORE_DLL_DIR :: "build/hot_reload/"
CORE_DLL_PATH :: CORE_DLL_DIR + "core" + DLL_EXT

// We copy the DLL because using it directly would lock it, which would prevent
// the compiler from writing to it.
copy_dll :: proc(to: string) -> bool {
	copy_err := os2.copy_file(to, CORE_DLL_PATH)

	if copy_err != nil {
		fmt.printfln("Failed to copy " + CORE_DLL_PATH + " to {0}: %v", to, copy_err)
		return false
	}

	return true
}

Core_API :: struct {
	lib: dynlib.Library,
	init_window: proc(),
	init: proc(),
	update: proc(),
	should_run: proc() -> bool,
	shutdown: proc(),
	shutdown_window: proc(),
	memory: proc() -> rawptr,
	memory_size: proc() -> int,
	hot_reloaded: proc(mem: rawptr),
	force_reload: proc() -> bool,
	force_restart: proc() -> bool,
	modification_time: os.File_Time,
	api_version: int,
}

load_core_api :: proc(api_version: int) -> (api: Core_API, ok: bool) {
	mod_time, mod_time_error := os.last_write_time_by_name(CORE_DLL_PATH)
	if mod_time_error != os.ERROR_NONE {
		fmt.printfln(
			"Failed getting last write time of " + CORE_DLL_PATH + ", error code: {1}",
			mod_time_error,
		)
		return
	}

	core_dll_name := fmt.tprintf(CORE_DLL_DIR + "core_{0}" + DLL_EXT, api_version)
	copy_dll(core_dll_name) or_return

	// This proc matches the names of the fields in Core_API to symbols in the
	// core DLL. It actually looks for symbols starting with `core_`, which is
	// why the argument `"core_"` is there.
	_, ok = dynlib.initialize_symbols(&api, core_dll_name, "core_", "lib")
	if !ok {
		fmt.printfln("Failed initializing symbols: {0}", dynlib.last_error())
	}

	api.api_version = api_version
	api.modification_time = mod_time
	ok = true

	return
}

unload_core_api :: proc(api: ^Core_API) {
	if api.lib != nil {
		if !dynlib.unload_library(api.lib) {
			fmt.printfln("Failed unloading lib: {0}", dynlib.last_error())
		}
	}

	if os.remove(fmt.tprintf(CORE_DLL_DIR + "core_{0}" + DLL_EXT, api.api_version)) != nil {
		fmt.printfln("Failed to remove {0}core_{1}" + DLL_EXT + " copy", CORE_DLL_DIR, api.api_version)
	}
}

main :: proc() {
	// Set working dir to dir of executable.
	exe_path := os.args[0]
	exe_dir := filepath.dir(string(exe_path), context.temp_allocator)
	os.set_current_directory(exe_dir)

	context.logger = log.create_console_logger()

	default_allocator := context.allocator
	tracking_allocator: mem.Tracking_Allocator
	mem.tracking_allocator_init(&tracking_allocator, default_allocator)
	context.allocator = mem.tracking_allocator(&tracking_allocator)

	reset_tracking_allocator :: proc(a: ^mem.Tracking_Allocator) -> bool {
		err := false

		for _, value in a.allocation_map {
			log.errorf("%v: Leaked %v bytes\n", value.location, value.size)
			err = true
		}

		mem.tracking_allocator_clear(a)
		return err
	}

	core_api_version := 0
	core_api, core_api_ok := load_core_api(core_api_version)

	if !core_api_ok {
		fmt.println("Failed to load Core API")
		return
	}

	core_api_version += 1
	core_api.init_window()
	core_api.init()

	old_core_apis := make([dynamic]Core_API, default_allocator)

	for core_api.should_run() {
		core_api.update()
		force_reload := core_api.force_reload()
		force_restart := core_api.force_restart()
		reload := force_reload || force_restart
		core_dll_mod, core_dll_mod_err := os.last_write_time_by_name(CORE_DLL_PATH)

		if core_dll_mod_err == os.ERROR_NONE && core_api.modification_time != core_dll_mod {
			reload = true
		}

		if reload {
			new_core_api, new_core_api_ok := load_core_api(core_api_version)

			if new_core_api_ok {
				force_restart = force_restart || core_api.memory_size() != new_core_api.memory_size()

				if !force_restart {
					// This does the normal hot reload

					// Note that we don't unload the old core APIs because that
					// would unload the DLL. The DLL can contain stored info
					// such as string literals. The old DLLs are only unloaded
					// on a full reset or on shutdown.
					append(&old_core_apis, core_api)
					core_memory := core_api.memory()
					core_api = new_core_api
					core_api.hot_reloaded(core_memory)
				} else {
					// This does a full reset. That's basically like opening and
					// closing the core, without having to restart the executable.
					//
					// You end up in here if the core requests a full reset OR
					// if the size of the core memory has changed. That would
					// probably lead to a crash anyways.

					core_api.shutdown()
					reset_tracking_allocator(&tracking_allocator)

					for &g in old_core_apis {
						unload_core_api(&g)
					}

					clear(&old_core_apis)
					unload_core_api(&core_api)
					core_api = new_core_api
					core_api.init()
				}

				core_api_version += 1
			}
		}

		if len(tracking_allocator.bad_free_array) > 0 {
			for b in tracking_allocator.bad_free_array {
				log.errorf("Bad free at: %v", b.location)
			}

			// This prevents the core from closing without you seeing the bad
			// frees. This is mostly needed because I use Sublime Text and my core's
			// console isn't hooked up into Sublime's console properly.
			libc.getchar()
			panic("Bad free detected")
		}
	}

	free_all(context.temp_allocator)
	core_api.shutdown()
	if reset_tracking_allocator(&tracking_allocator) {
		// This prevents the core from closing without you seeing the memory
		// leaks. This is mostly needed because I use Sublime Text and my core's
		// console isn't hooked up into Sublime's console properly.
		libc.getchar()
	}

	for &g in old_core_apis {
		unload_core_api(&g)
	}

	delete(old_core_apis)

	core_api.shutdown_window()
	unload_core_api(&core_api)
	mem.tracking_allocator_destroy(&tracking_allocator)
}

// Make core use good GPU on laptops.

@(export)
NvOptimusEnablement: u32 = 1

@(export)
AmdPowerXpressRequestHighPerformance: i32 = 1