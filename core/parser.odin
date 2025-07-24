#+feature dynamic-literals
package NormEngineCore

import utils "utils"
import "core:strings"

// TODO: Attach metadata to parsed nodes for things like:
// - Source location (line number, filename)
// - Errors or warnings
// This helps for tooltips, previews, and IDE features later.

//TODO: Handle subcomponents -> children - i.e. pauseButton.lite should be a child of pauseButton
parse :: proc(tokens: [dynamic]Token) -> (^NodeRegistry, ^Node){
    root : ^Node
    registry := new(NodeRegistry)
	registry.by_name = make(map[string]^Node)
	registry.roots = make([dynamic]^Node)

    c : ^Node
    root, _ = add_node(registry, "root", nil)

    _mode : Identifier_Mode
    commentAllocator : [dynamic]Property
    defer delete(commentAllocator)
    // Basic parsing logic - expand as needed
    for token in tokens {
        if token.type == .IDENTIFIER && strings.has_prefix(strings.trim_space(token.value), "Component"){
            _mode = c
            split_raw_vals := strings.split(strings.trim_space(token.value), " ") // Get each word
            // Assume the first word is the idenentifier, second is the value we want, and third is '}'
            // ["Component", "pauseButton.lite", "{"] -> ["pauseButton", "lite"]
            split_vals := strings.split(split_raw_vals[1], ".") 
            node_name := split_vals[len(split_vals)-1]
            if len(split_vals) == 1 {
                c, _ = add_node(registry, node_name, root)
            }else {
                // it's a sub component
                parent_name := split_vals[len(split_vals)-2]
				// 1. Get the POINTER from the map. Add a check for safety.
				if parent_node, ok := registry.by_name[parent_name]; ok {
					// 2. Pass the POINTER directly. Do not dereference and take the address.
					c, _ = add_node(registry, node_name, parent_node)
				} else {
					utils.norm_println(.ERROR, "Parent node '%v' not found.", parent_name)
					continue
				}
            } 
			if len(commentAllocator) > 0 {
				for comment in commentAllocator {
					append(&c.properties, comment)
				}
				clear(&commentAllocator) // Clear the allocator after flushing
			}            
            delete(split_raw_vals)
            delete(split_vals)
            utils.norm_println(.INFO, "Appended Node: %v", c)
            continue
        }
        if token.type == .COMMENT {
            comment := Property{
                .COMMENT,
                strings.trim_space(strings.trim(token.value, "/")),
            }
            append(&commentAllocator, comment)
            continue
        }
    }
    utils.norm_println(.DEBUG, "Node Registry: %v", registry)
    return registry, root
}

// This is the "constructor" for a Node. It creates a fully-formed object.
add_node :: proc(
	registry: ^NodeRegistry,
	name: string,
	parent: ^Node,
) -> (^Node, bool) {
	// 1. Check for name collision first.
	if _, exists := registry.by_name[name]; exists {
		utils.norm_println(.ERROR, "Node with name '%v' already exists.", name)
		return nil, false
	}

	// 2. Allocate the Node struct.
	c := new(Node)

	// 3. Immediately initialize all internal dynamic collections.
	//    This ensures the node is in a valid state from the moment it's created.
	c.children = make([dynamic]^Node)
	c.properties = make([dynamic]Property)

	// 4. Assign its data.
	c.name = name
	c.parent = parent

	// 5. Add the fully-formed node to the registry.
	registry.by_name[name] = c

	// 6. Add to the tree hierarchy. This now appends to a non-nil array.
	if parent != nil {
		append(&parent.children, c)
	} else {
		// This is a top-level node (like the initial 'root')
		append(&registry.roots, c)
	}

	return c, true
}