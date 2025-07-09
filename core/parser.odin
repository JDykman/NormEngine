package NormEngineCore

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

parse :: proc(tokens: []Token) -> AST_Node {
    root := AST_Node{
        type = .COMPONENT,
        name = "root",
        properties = make(map[string]string),
        children = make([]AST_Node, 0),
    }
    
    // Basic parsing logic - expand as needed
    for token in tokens {
        if token.type == .KEYWORD && token.value == "Component" {
            // Parse component
            // This is a placeholder - implement proper parsing
        }
    }
    
    return root
}