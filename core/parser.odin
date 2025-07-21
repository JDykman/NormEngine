#+feature dynamic-literals
package NormEngineCore

import utils "utils"
// TODO: Attach metadata to parsed nodes for things like:
// - Source location (line number, filename)
// - Doc-comments (///) as a field on Component
// - Errors or warnings
// This helps for tooltips, previews, and IDE features later.

// TODO: Add a Symbol Table / ID Registry early in the parsing process.
// This will help track declared component names, style definitions, and event handler references.
// It will also prevent name collisions and assist with exporting and IDE integrations.

SymbolTable :: struct {
    components: map[string]bool,
    styles:     map[string]bool,
    handlers:   map[string]bool,
}

// Example: Initialize a symbol table at the start of parsing
init_symbol_table :: proc() -> SymbolTable {
    return SymbolTable{
        components = make(map[string]bool),
        styles     = make(map[string]bool),
        handlers   = make(map[string]bool),
    }
}

//TODO: Handle subcomponents -> children - i.e. pauseButton.lite should be a child of pauseButton
parse :: proc(tokens: []Token, filepath: string) -> AST_Node {
    root := AST_Node{
        type = .ROOT,
        name = "root",
        properties = make(map[string]string),
        children = make([]AST_Node, 0),
    }

    // Basic parsing logic - expand as needed
    for token in tokens {
        utils.norm_println(.DEBUG, "%v: %v",token.type, token.value)   
        if token.type == .COMMENT {
        }
    }
    
    utils.norm_println(.DEBUG, "%v", root)
    return root
}

// build_comp :: proc(type: Token_Type, ast: ^AST_Node, x: int) -> AST_Node{
//     switch type{
//         case . 

//     }
// }


//TODO: Remove?
// get_values :: proc(token: Token, filepath: string) -> map[string]string{
//     content, read_ok := os.read_entire_file(filepath)

//     str_content := string(content) 
//     lines := strings.split(str_content, "\n")
   
//     utils.norm_println(.INFO, "Token: %v", token)
//     utils.norm_println(.INFO, "lines: %v", lines)
//     out := make(map[string]string)
//     defer delete(out)

//     comp_start := token.line
//     comp_end := token
//     utils.norm_println(.INFO, "Starting property fetch at line: %v", token.line)



//     for line in lines{
//         if strings.has_prefix(strings.trim_space(line), "Component") {
//             // Begin building component
//             out["Component"] = "eg"
//         }
//     }
//     return out
// }
