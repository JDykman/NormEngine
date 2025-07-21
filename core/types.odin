package NormEngineCore

Token_Type :: enum {
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

AST_Node :: struct {
    type: Node_Type,
    name: string,
    properties: map[string]string,
    children: []AST_Node,
}

Node_Type :: enum {
    ROOT,
    COMPONENT,
    PROPERTY,
    COMMENT,
}


KeyWord :: enum { 
    TYPE,
    STYLE,
    ONCLICK,
}

KeyWords := [KeyWord]string {
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