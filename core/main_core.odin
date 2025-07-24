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
    utils.norm_println(.INFO, "Processing file:%v", filepath)
    filepath := filepath
    filepath = check_extension(filepath)
    defer delete(filepath)

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
    utils.norm_println(.INFO, "Tokenizing")
    tokens := tokenize(content_str)
    defer delete(tokens)
    
    // 2. Parse
    utils.norm_println(.INFO, "Parsing")
    registry, root := parse(tokens) //TODO do something with the registry
    defer delete_registry(registry)

    // 3. Generate output
    //TODO this will eventually need to be replaced so that it works dynamically for each supported language
    utils.norm_println(.INFO, "Generating")
    output := emit(root)
    
    // Write output file
    output_path, _ := strings.replace(filepath, ".norm", ".gen.txt", -1)
    defer(delete(output_path))
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
validate_file :: proc(_filepath: string) -> bool {
    return strings.has_suffix(_filepath, ".norm")
}

check_extension :: proc(_filepath: string) -> string{
    if strings.has_suffix(_filepath, ".norm"){return strings.clone(_filepath)}
    else{
        return strings.concatenate({_filepath, ".norm"})
    }
}


supported_import_extensions: []string = {".norm"}
supported_export_extensions: []string = {"N/A"}

get_import_supported_extensions :: proc() -> []string {
    return supported_import_extensions
}

get_export_supported_extensions :: proc() -> []string {
    return supported_export_extensions
}

// This procedure cleans up all memory associated with a NodeRegistry.
delete_registry :: proc(registry: ^NodeRegistry) {
	// Always good practice to check for nil before dereferencing.
	if registry == nil {
		return
	}

	// 1. Free each individual node and its internal dynamic arrays.
	//    We iterate through the `by_name` map as it contains every node we've allocated.
	if registry.by_name != nil {
		for _, node in registry.by_name {
			if node != nil {
				// Free the dynamic arrays inside the node first.
				delete(node.children)
				delete(node.properties)
				// Now free the node struct itself.
				free(node)
			}
		}
	}

	// 2. Free the registry's own internal collections.
	delete(registry.by_name)
	delete(registry.roots)

	// 3. Finally, free the registry struct itself.
	free(registry)
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