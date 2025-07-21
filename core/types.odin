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

Keywords := []string {
    "type",
    "style",
    "onClick",
}

isKeyword :: proc(string_to_check: string) -> bool {
	for i in Keywords{
        if(string_to_check == i){
            return true
        }
	}
	return false
}