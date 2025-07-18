package NormEngine

import "core:fmt"
import "core:os"
import "core:strings"
import "core:c"
import core "core"
import "core/utils"

States :: struct{
    runnning_cli: bool,
}

state: ^States

@(export)
NormEngine_init :: proc() {
    fmt.println("Init")
	state = new(States)

	state^ = States {
		runnning_cli = true,
	}

	NormEngine_hot_reloaded(state)
}

@(export)
NormEngine_update :: proc() {
	update()

	// Everything on tracking allocator is valid until end-of-frame.
	free_all(context.temp_allocator)
}

@(export)
NormEngine_should_run :: proc() -> bool {
    when ODIN_OS != .JS {
        //TODO
	}
    
	return state.runnning_cli
}

@(export)
NormEngine_shutdown :: proc() {
	free(state)
}

@(export)
NormEngine_shutdown_window :: proc() {
	state.runnning_cli = false
}

@(export)
NormEngine_memory :: proc() -> rawptr {
	return state
}

@(export)
NormEngine_memory_size :: proc() -> int {
	return size_of(States)
}

@(export)
NormEngine_hot_reloaded :: proc(mem: rawptr) {
	state = (^States)(mem)
	// Here you can also set your own global variables. A good idea is to make
	// your global variables into pointers that point to something inside `g`.
}

@(export)
NormEngine_force_reload :: proc() -> bool {
	return false //TODO
}

@(export)
NormEngine_force_restart :: proc() -> bool {
	return false //TODO
}

update :: proc(){
    utils.norm_print(.INFO, "%v> %v", utils.TEXT_GREEN, utils.TEXT_WHITE)
    // Read user input
    buf: [256]byte
    n, err := os.read(os.stdin, buf[:])
    if err != nil {
        fmt.println("Error reading input:", err)
    }
    
    input := strings.trim_space(string(buf[:n]))
    
    // Handle empty input
    if len(input) == 0 {
    }
    
    // Split input into command and arguments
    args := strings.split(input, " ")
    defer delete(args)
    
    if len(args) == 0 {
    }
    
    command := args[0]

    // Handle commands                utils.fire("bash", "-c", fmt.tprintf("cd %v && ./%v%v.exe", out_dir, EXE_NAME, exe_suffix))
    switch command {
    case "exit", "quit":
        fmt.println("Goodbye!")
        state.runnning_cli = false
        return
        
    case "help":
        show_help()
        
    case "build":
        if len(args) < 2 {
            utils.norm_println(.WARNING, "Usage: build <file>")
        }
        
        filepath := args[1]
        result := core.build_file(filepath)
        if result.success {
            utils.norm_println(.INFO, "Build successful: %v", result.output_path)
        } else {
            utils.norm_println(.ERROR, "Build failed: %v", result.error)
        }
        
    case "validate":
        if len(args) < 2 {
            utils.norm_println(.WARNING, "Usage: validate <file>")
        }
        
        filepath := args[1]
        if core.validate_file(filepath) {
            utils.norm_println(.INFO, "File is valid: %v", filepath)
        } else {
            utils.norm_println(.ERROR, "File is not valid: %v", filepath)
        }
        
    case "info":
        show_info()
        
    case "clear":
        clear_screen()
        
    case:
        utils.norm_println(.WARNING, "Unknown command:", command)
        utils.norm_println(.INFO, "Type 'help' for available commands")
    }
}

init :: proc() {
    fmt.println("=== NormEngine CLI ===")
    fmt.println("Type 'help' for available commands, 'exit' to quit")
}

show_help :: proc() {
    utils.norm_println(.INFO, ":)")
    fmt.println("Available commands:")
    fmt.println("  build <file>     - Build a .norm file")
    fmt.println("  validate <file>  - Validate a .norm file")
    fmt.println("  info            - Show system information")
    fmt.println("  clear           - Clear the screen")
    fmt.println("  help            - Show this help message")
    fmt.println("  exit/quit       - Exit the program")
}

show_info :: proc() {
    utils.norm_println(.INFO, "NormEngine CLI")
    utils.norm_println(.INFO, "Platform:", core.PLATFORM)
    utils.norm_println(.INFO, "Mode:", core.BUILD_MODE)
    utils.norm_println(.INFO, "Supported extensions:", core.get_supported_extensions())
}

// Foreign import for system calls
when ODIN_OS == .Windows {
    foreign import libc "system:msvcrt.lib"
} else {
    foreign import libc "system:c"
}

@(default_calling_convention="c")
foreign libc {
    system :: proc(command: cstring) -> c.int ---
}

clear_screen :: proc() {
    when core.PLATFORM == .windows {
        system("cls")
    } else {
        system("clear")
    }
}

run_gui :: proc() {
    utils.norm_println(.INFO, "Launching GUI...")
    // GUI also uses core functionality
    // result := core.build_file(selected_file)
    // Display result in GUI
    utils.norm_println(.WARNING, "GUI mode not implemented yet")
}