package NormEngineCore

Token_Type :: enum byte {
    IDENTIFIER,
    KEYWORD,
    OPERATOR,
    COMMENT,
    END_COMP,
    EOF,
}

Token :: struct {
    type: Token_Type,
    value: string,
    line: int,
    column: int,
}

Node :: struct {
    name : string,
    parent : ^Node,
    children : [dynamic]^Node,
    properties : [dynamic]Property,
}

Node_Type :: enum byte {
    ROOT,
    COMPONENT,
    PROPERTY,
    COMMENT,
}

NodeRegistry :: struct {
    // The flat map for O(1) lookups by name
    by_name: map[string]^Node,

    // A list of all top-level components (those without a parent)
    roots:   [dynamic]^Node,
}

Style :: struct {
    name : string,
    properties : [dynamic]Property,
    parent : ^Style,
}

Property :: struct {
    name : KeyWord,
    value : string, // TODO this should probably be replaced with something 
}

//Usage: if comp, ok := _mode.(^Component); ok{...}

Identifier_Mode :: union {
    ^Node,
    ^Style,
}

KeyWord :: enum byte { 
    TYPE,
    STYLE,
    ONCLICK,
    COMMENT,
}

KeyWords := #partial [KeyWord]string {
    .TYPE = "type",
    .STYLE = "style",
    .ONCLICK = "onClick",
}

isKeyWord :: proc(string_to_check: string) -> bool {
	for i in KeyWords{
        if(string_to_check == i){
            return true
        }
	}
	return false
}