#+feature dynamic-literals
package NormEngineCore

import "core:fmt"
import "core:os"
import "core:strings"
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
        type = .COMPONENT,
        name = "root",
        properties = make(map[string]string),
        children = make([]AST_Node, 0),
    }

    // Basic parsing logic - expand as needed
    for token in tokens {
        if token.type == .LITERAL {
            fmt.println(token.value)   
        }
    }
    
    fmt.println(root)
    return root
}

// build_comp :: proc(type: Token_Type, ast: ^AST_Node, x: int) -> AST_Node{
//     switch type{
//         case . 

//     }
// }


//TODO: Remove?
get_values :: proc(token: Token, filepath: string) -> map[string]string{
    content, read_ok := os.read_entire_file(filepath)
    str_content := string(content) 
    lines := strings.split(str_content, "\n")
   
    fmt.println("Token: ", token)
    fmt.println("lines: ", lines)
    out := make(map[string]string)
    defer delete(out)

    comp_start := token.line
    comp_end := token

    fmt.println("Starting property fetch at line: ", token.line)



    for line in lines{
        if strings.has_prefix(strings.trim_space(line), "Component") {
            // Begin building component
            out["Component"] = "eg"
        }
    }
    return out
}
