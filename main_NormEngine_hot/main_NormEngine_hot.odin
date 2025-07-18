/*
Development NormEngine exe. Loads build/hot_reload/NormEngine.dll and reloads it whenever it
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

NormEngine_DLL_DIR :: "build/hot_reload/"
NormEngine_DLL_PATH :: NormEngine_DLL_DIR + "NormEngine" + DLL_EXT

// We copy the DLL because using it directly would lock it, which would prevent
// the compiler from writing to it.
copy_dll :: proc(to: string) -> bool {
	copy_err := os2.copy_file(to, NormEngine_DLL_PATH)

	if copy_err != nil {
		fmt.printfln("Failed to copy " + NormEngine_DLL_PATH + " to {0}: %v", to, copy_err)
		return false
	}

	return true
}

NormEngine_API :: struct {
	lib: dynlib.Library,
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

load_NormEngine_api :: proc(api_version: int) -> (api: NormEngine_API, ok: bool) {
	mod_time, mod_time_error := os.last_write_time_by_name(NormEngine_DLL_PATH)
	if mod_time_error != os.ERROR_NONE {
		fmt.printfln(
			"Failed getting last write time of " + NormEngine_DLL_PATH + ", error code: {1}",
			mod_time_error,
		)
		return
	}

	NormEngine_dll_name := fmt.tprintf(NormEngine_DLL_DIR + "NormEngine_{0}" + DLL_EXT, api_version)
	copy_dll(NormEngine_dll_name) or_return

	// This proc matches the names of the fields in NormEngine_API to symbols in the
	// NormEngine DLL. It actually looks for symbols starting with `NormEngine_`, which is
	// why the argument `"NormEngine_"` is there.
	_, ok = dynlib.initialize_symbols(&api, NormEngine_dll_name, "NormEngine_", "lib")
	if !ok {
		fmt.printfln("Failed initializing symbols: {0}", dynlib.last_error())
	}

	api.api_version = api_version
	api.modification_time = mod_time
	ok = true

	return
}

unload_NormEngine_api :: proc(api: ^NormEngine_API) {
	if api.lib != nil {
		if !dynlib.unload_library(api.lib) {
			fmt.printfln("Failed unloading lib: {0}", dynlib.last_error())
		}
	}

	if os.remove(fmt.tprintf(NormEngine_DLL_DIR + "NormEngine_{0}" + DLL_EXT, api.api_version)) != nil {
		fmt.printfln("Failed to remove {0}NormEngine_{1}" + DLL_EXT + " copy", NormEngine_DLL_DIR, api.api_version)
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

	NormEngine_api_version := 0
	NormEngine_api, NormEngine_api_ok := load_NormEngine_api(NormEngine_api_version)

	if !NormEngine_api_ok {
		fmt.println("Failed to load NormEngine API")
		return
	}

	NormEngine_api_version += 1
	NormEngine_api.init()

	old_NormEngine_apis := make([dynamic]NormEngine_API, default_allocator)
	for NormEngine_api.should_run() {
		NormEngine_api.update()
		force_reload := NormEngine_api.force_reload()
		force_restart := NormEngine_api.force_restart()
		reload := force_reload || force_restart
		NormEngine_dll_mod, NormEngine_dll_mod_err := os.last_write_time_by_name(NormEngine_DLL_PATH)

		if NormEngine_dll_mod_err == os.ERROR_NONE && NormEngine_api.modification_time != NormEngine_dll_mod {
			reload = true
		}

		if reload {
			new_NormEngine_api, new_NormEngine_api_ok := load_NormEngine_api(NormEngine_api_version)

			if new_NormEngine_api_ok {
				force_restart = force_restart || NormEngine_api.memory_size() != new_NormEngine_api.memory_size()

				if !force_restart {
					// This does the normal hot reload

					// Note that we don't unload the old NormEngine APIs because that
					// would unload the DLL. The DLL can contain stored info
					// such as string literals. The old DLLs are only unloaded
					// on a full reset or on shutdown.
					append(&old_NormEngine_apis, NormEngine_api)
					NormEngine_memory := NormEngine_api.memory()
					NormEngine_api = new_NormEngine_api
					NormEngine_api.hot_reloaded(NormEngine_memory)
				} else {
					// This does a full reset. That's basically like opening and
					// closing the NormEngine, without having to restart the executable.
					//
					// You end up in here if the NormEngine requests a full reset OR
					// if the size of the NormEngine memory has changed. That would
					// probably lead to a crash anyways.

					NormEngine_api.shutdown()
					reset_tracking_allocator(&tracking_allocator)

					for &g in old_NormEngine_apis {
						unload_NormEngine_api(&g)
					}

					clear(&old_NormEngine_apis)
					unload_NormEngine_api(&NormEngine_api)
					NormEngine_api = new_NormEngine_api
					NormEngine_api.init()
				}

				NormEngine_api_version += 1
			}
		}

		if len(tracking_allocator.bad_free_array) > 0 {
			for b in tracking_allocator.bad_free_array {
				log.errorf("Bad free at: %v", b.location)
			}

			// This prevents the NormEngine from closing without you seeing the bad
			// frees. This is mostly needed because I use Sublime Text and my NormEngine's
			// console isn't hooked up into Sublime's console properly.
			libc.getchar()
			panic("Bad free detected")
		}
	}

	free_all(context.temp_allocator)
	NormEngine_api.shutdown()
	if reset_tracking_allocator(&tracking_allocator) {
		// This prevents the NormEngine from closing without you seeing the memory
		// leaks. This is mostly needed because I use Sublime Text and my NormEngine's
		// console isn't hooked up into Sublime's console properly.
		libc.getchar()
	}

	for &g in old_NormEngine_apis {
		unload_NormEngine_api(&g)
	}

	delete(old_NormEngine_apis)

	NormEngine_api.shutdown_window()
	unload_NormEngine_api(&NormEngine_api)
	mem.tracking_allocator_destroy(&tracking_allocator)
}

// Make NormEngine use good GPU on laptops.

@(export)
NvOptimusEnablement: u32 = 1

@(export)
AmdPowerXpressRequestHighPerformance: i32 = 1
