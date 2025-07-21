#+feature dynamic-literals
package NormEngineCore

import utils "utils"
import "core:strings"
// TODO: Attach metadata to parsed nodes for things like:
// - Source location (line number, filename)
// - Doc-comments (///) as a field on Component
// - Errors or warnings
// This helps for tooltips, previews, and IDE features later.

// TODO: Add a Symbol Table / ID Registry early in the parsing process.
// This will help track declared component names, style definitions, and event handler references.
// It will also prevent name collisions and assist with exporting and IDE integrations.

Component :: struct {
    name : string,
    properties : []KeyWord,
    parent : ^Component,
}

Components : map[string]^Component

init_component :: proc(name: string, parent : ^Component = nil) -> ^Component {
    c := new(Component)
    //defer free(c)
    c.parent = parent
    c.name = name
    Components[name] = c
    return c
}

//TODO: Handle subcomponents -> children - i.e. pauseButton.lite should be a child of pauseButton
parse :: proc(tokens: [dynamic]Token) -> AST_Node {
    Components = make(map[string]^Component)
    defer(delete(Components)) // Delete this later
    root := AST_Node{
        type = .ROOT,
        name = "root",
        properties = make(map[string]string),
        children = make([]AST_Node, 0),
    }
    
    c : ^Component
    defer free(c)
    // Basic parsing logic - expand as needed
    for token in tokens {
        //utils.norm_println(.DEBUG, "%v: %v",token.type, token.value)   
        if token.type == .IDENTIFIER {
            split_raw_vals := strings.split(strings.trim_space(token.value), " ") // Get each word
            // Assume the first word is the idenentifier, second is the value we want, and third is '}'
            // ["Component", "pauseButton.lite", "{"] -> ["pauseButton", "lite"]
            split_vals := strings.split(split_raw_vals[1], ".") 
            if len(split_vals) == 1 {
                c = init_component(split_vals[0])
                utils.norm_println(.DEBUG, "Component: %v", c)
            }else {
                // it's a sub component
                _parent := Components[split_vals[len(split_vals)-2]]^
                c = init_component(split_vals[len(split_vals)- 1], &_parent)
                utils.norm_println(.DEBUG, "SubComponent: %v", c)
                utils.norm_println(.DEBUG, "Components Parent: %v", c.parent)
                
            } 
            delete(split_raw_vals)
            delete(split_vals)
            // init_component(token.value)
            //utils.norm_println(.DEBUG, "%v", split_vals)
        }
    }
    utils.norm_println(.DEBUG, "%v", root)
    return root
}