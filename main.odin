package NormEngine

import "core:fmt"
import "core:os"
import "core:strings"
import "core:bufio"
import "core:c"
import core "core"
import "core/utils"

main :: proc() {
    when core.BUILD_MODE == .gui {
        run_gui()
    } else {
        run_cli()
    }
}

run_cli :: proc() {
    fmt.println("=== NormEngine CLI ===")
    fmt.println("Type 'help' for available commands, 'exit' to quit")
    
    // Interactive CLI loop
    for {
        fmt.print("norm> ")
        
        // Read user input
        buf: [256]byte
        n, err := os.read(os.stdin, buf[:])
        if err != nil {
            fmt.println("Error reading input:", err)
            continue
        }
        
        input := strings.trim_space(string(buf[:n]))
        
        // Handle empty input
        if len(input) == 0 {
            continue
        }
        
        // Split input into command and arguments
        args := strings.split(input, " ")
        defer delete(args)
        
        if len(args) == 0 {
            continue
        }
        
        command := args[0]
        
        // Handle commands                utils.fire("bash", "-c", fmt.tprintf("cd %v && ./%v%v.exe", out_dir, EXE_NAME, exe_suffix))

        switch command {
            case "exit", "quit":
                fmt.println("Goodbye!")
                return
                
            case "help":
                show_help()
                
            case "build":
                if len(args) < 2 {
                    fmt.println("Usage: build <file>")
                    continue
                }
                
                filepath := args[1]
                result := core.build_file(filepath)
                if result.success {
                    utils.norm_print(.INFO, "Build successful: ", result.output_path)
                } else {
                    utils.norm_print(.ERROR, "Build failed:", result.error)
                }
                
            case "validate":
                if len(args) < 2 {
                    fmt.println("Usage: validate <file>")
                    continue
                }
                
                filepath := args[1]
                if core.validate_file(filepath) {
                    utils.norm_print(.INFO, "File is valid: %v", filepath)
                } else {
                    utils.norm_print(.INFO, "File is not valid: %v", filepath)
                }
                
            case "info":
                show_info()
                
            case "clear":
                clear_screen()
                
            case:
                fmt.println("Unknown command:", command)
                fmt.println("Type 'help' for available commands")
        }
    }
}

show_help :: proc() {
    fmt.println("Available commands:")
    fmt.println("  build <file>     - Build a .norm file")
    fmt.println("  validate <file>  - Validate a .norm file")
    fmt.println("  info            - Show system information")
    fmt.println("  clear           - Clear the screen")
    fmt.println("  help            - Show this help message")
    fmt.println("  exit/quit       - Exit the program")
}

show_info :: proc() {
    fmt.println("NormEngine CLI")
    fmt.println("Platform:", core.PLATFORM)
    fmt.println("Mode:", core.BUILD_MODE)
    fmt.println("Supported extensions:", core.get_supported_extensions())
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
    utils.norm_print(.INFO, "Launching GUI...")
    // GUI also uses core functionality
    // result := core.build_file(selected_file)
    // Display result in GUI
    utils.norm_print(.WARNING, "GUI mode not implemented yet")
}