package NormEngineCore

Token_Type :: enum {
    IDENTIFIER,
    KEYWORD,
    OPERATOR,
    LITERAL,
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