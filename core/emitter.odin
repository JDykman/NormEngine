package NormEngineCore

import "core:fmt"
import "core:strings"

// emit is the main entry point for code generation.
// It takes the root node of the AST and returns the generated output as a string.
// The caller is responsible for deleting the returned string.
emit :: proc(root_node: ^Node) -> string {
	// A string builder is the most efficient way to construct the output.
	builder := strings.builder_make()
	defer strings.builder_destroy(&builder)

	// Write a header for the generated file.
	strings.write_string(&builder, "// --- Generated Norm AST ---\n")
	strings.write_string(&builder, "// This file is auto-generated. Do not edit.\n//\n")

	// The root node itself isn't a component, its children are.
	// We iterate through the top-level components.
	for component in root_node.children {
		emit_node(&builder, component, 0)
		// Add a blank line for readability between top-level components.
		strings.write_string(&builder, "//\n")
	}

	// Clone the builder's content into a new string that we can return.
	// This is important because the builder will be destroyed, but the caller
	// needs a valid string to work with.
	return strings.clone(strings.to_string(builder))
}

// emit_node is a recursive helper that traverses the AST.
// It's more efficient to pass the node by pointer (`^Node`) to avoid copying the struct.
emit_node :: proc(builder: ^strings.Builder, node: ^Node, indent_level: int) {
	// Safety check: don't process a nil node.
	if node == nil {
		return
	}

	// 1. Emit the current node's information.
    fmt.sbprintf(builder,"// ")
	write_indent(builder, indent_level)
    fmt.sbprintf(builder, "Component: %s\n", node.name)

	// 2. Emit all properties associated with this node.
	if len(node.properties) > 0 {
		for prop in node.properties {
            fmt.sbprintf(builder,"// ")
			write_indent(builder, indent_level + 1)
			// Using %v for the property name handles different enum types gracefully.
			fmt.sbprintf(builder, "- Property (%v): \"%s\"\n", prop.name, prop.value)
		}
	}

	// 3. Recursively emit all children of this node.
	if len(node.children) > 0 {
        fmt.sbprintf(builder,"// ")
		write_indent(builder, indent_level + 1)
		strings.write_string(builder, "- Children:\n")
		for child in node.children {
			// The child is already a pointer, so we pass it directly.
			// We increase the indent level to show the hierarchy.
			emit_node(builder, child, indent_level + 2)
		}
    }
}

// write_indent is a simple utility to add indentation to the output.
write_indent :: proc(builder: ^strings.Builder, level: int) {
	for _ in 0..<level {
		strings.write_string(builder, "  ") // Use two spaces for indentation.
	}
}