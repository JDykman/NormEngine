package NormEngineCore

import "core:strings"
import "core:unicode"
import "core:fmt"

/* 
    Rip everything out the file and create a dynamic array of tokens ([dynamic]Token)
*/
tokenize :: proc(content: string) -> []Token {
    tokens := make([dynamic]Token)
    
    lines := strings.split(content, "\n")
    
    defer delete(lines)
    
    for line, line_num in lines {
        line := strings.trim_suffix(line, "{")
        line = strings.trim_suffix(line, "}")
        fmt.println("[norm] ", line)
        if strings.has_prefix(strings.trim_space(line), "///") {
            append(&tokens, Token{
                type = .COMMENT,
                value = line,
                line = line_num + 1,
                column = 1,
            })
        } else if strings.contains(line, "}") {
            append(&tokens, Token{
                type = .END_COMP,
                value = strings.trim_space(line),
                line = line_num + 1,
                column = strings.index(line, "End_Comp") + 1,
            })
        } else if strings.contains(line, "Component") {
            append(&tokens, Token{
                type = .KEYWORD,
                value = strings.trim_space(line),
                line = line_num + 1,
                column = strings.index(line, "Component") + 1,
            })
        } else {
            // Should be a property
            append(&tokens, Token{
                type = .LITERAL,
                value = strings.trim_space(line),
                line = line_num + 1,
                column = strings.index(line, "Literal") + 1
            })
        }
    }
    
    append(&tokens, Token{type = .EOF, line = len(lines), column = 1})
    //fmt.println(tokens)
    return tokens[:]
}