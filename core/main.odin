package NormEngineCore

import "core:fmt"
import "core:os"
import "core:strings"
import "core:c"
import utils "utils"

// TODO - make a todo list idfk
// 1. Implement error handling
// 2. Add logging
// 3. Optimize performance

// Core API that both CLI and GUI use
Build_Result :: struct {
    success: bool,
    output_path: string,
    error: string,
}

build_file :: proc(filepath: string) -> Build_Result {
    fmt.println("[core] Processing file:", filepath)
    
    if !os.exists(filepath) {
        return Build_Result{
            success = false,
            error = fmt.tprintf("File not found: %s", filepath),
        }
    }
    
    // Load file content
    content, read_ok := os.read_entire_file(filepath)
    if !read_ok {
        return Build_Result{
            success = false,
            error = fmt.tprintf("Failed to read file: %s", filepath),
        }
    }
    defer delete(content)
    
    // Process through the pipeline
    content_str := string(content)
    
    // 1. Tokenize
    utils.norm_print("Tokenizing", .INFO)
    tokens := tokenize(content_str)
    defer delete(tokens)
    
    // 2. Parse
    utils.norm_print("Parsing", .INFO)
    ast := parse(tokens, filepath)
    
    // 3. Generate output
    utils.norm_print("Generating", .INFO)
    output := emit(ast)
    
    // Write output file
    output_path, _ := strings.replace(filepath, ".norm", ".generated", -1)
    write_ok := os.write_entire_file(output_path, transmute([]u8)output)
    if !write_ok {
        return Build_Result{
            success = false,
            error = fmt.tprintf("\033[31mFailed to write output file\033[0m: %s", output_path),
        }
    }
    
    return Build_Result{
        success = true,
        output_path = output_path,
    }
}

// Other core functions that both CLI and GUI might need
validate_file :: proc(filepath: string) -> bool {
    return strings.has_suffix(filepath, ".norm")
}

supported_extensions: []string = {".norm"}

get_supported_extensions :: proc() -> []string {
    return supported_extensions
}

// Add this if os.system is not available
when ODIN_OS == .Windows {
    foreign import libc "system:msvcrt.lib"
    @(default_calling_convention="c")
    foreign libc {
        system :: proc(command: cstring) -> c.int ---
    }
} else {
    foreign import libc "system:c"
    @(default_calling_convention="c")
    foreign libc {
        system :: proc(command: cstring) -> c.int ---
    }
}