package NormEngineCore

import "core:fmt"
import "core:strings"

// TODO: Implement a proper error handling system
// - e.g. norm> error at line 4, col 12: expected '}'

emit :: proc(ast: AST_Node) -> string {
    builder := strings.builder_make()
    defer strings.builder_destroy(&builder)
    
    emit_node(&builder, ast, 0)
    
    return strings.clone(strings.to_string(builder))
}

emit_node :: proc(builder: ^strings.Builder, node: AST_Node, indent: int) {
    // Add indentation
    for i in 0..<indent {
        strings.write_string(builder, "  ")
    }
    
    switch node.type {
        case .COMPONENT:
            strings.write_string(builder, fmt.tprintf("// Generated component: %s\n", node.name))
        case .PROPERTY:
            strings.write_string(builder, fmt.tprintf("// Property: %s\n", node.name))
        case .COMMENT:
            strings.write_string(builder, fmt.tprintf("%s\n", node.name))
    }
    
    // Recursively emit children
    for child in node.children {
        emit_node(builder, child, indent + 1)
    }
}