package NormEngineCore

import "core:strings"
import "core:unicode"
import "core:fmt"

tokenize :: proc(content: string) -> []Token {
    tokens := make([dynamic]Token)
    
    lines := strings.split(content, "\n")
    defer delete(lines)
    
    for line, line_num in lines {
        fmt.println("[norm] ", line)
        if strings.has_prefix(strings.trim_space(line), "///") {
            append(&tokens, Token{
                type = .COMMENT,
                value = line,
                line = line_num + 1,
                column = 1,
            })
        } else if strings.contains(line, "Component") {
            append(&tokens, Token{
                type = .KEYWORD,
                value = "Component",
                line = line_num + 1,
                column = strings.index(line, "Component") + 1,
            })
        } else if strings.contains(line, "Operator"){
            append(&tokens, Token{
                type = .OPERATOR,
                value = "Operator",
                line = line_num + 1,
                column = strings.index(line, "Operator") + 1
            })
        }
    }
    
    append(&tokens, Token{type = .EOF, line = len(lines), column = 1})
    fmt.println(tokens)
    return tokens[:]
}