package NormEngineCore

import "core:strings"
import "utils"

/* 
    Rip everything out the file and create a dynamic array of tokens ([dynamic]Token)
*/
tokenize :: proc(content: string) -> []Token {
    tokens := make([dynamic]Token)
    
    lines := strings.split(content, "\n")
    
    defer delete(lines)
    
    for &line, line_num in lines {
        line = strings.trim_suffix(line, "{")
        
        //utils.norm_println("ass", line)
        if strings.has_prefix(strings.trim_space(line), "///") {
            append(&tokens, Token{
                type = .COMMENT,
                value = line,
                line = line_num + 1,
                column = 1, //TODO Check for comma's 
            })
        }else if strings.has_prefix(strings.trim_space(line), "Component") {
            append(&tokens, Token{
                type = .IDENTIFIER,
                value = line,
                line = line_num + 1,
                column = 1, //TODO Check for sub component
            })
        }else if strings.has_suffix(strings.trim_space(line), "}") {
            append(&tokens, Token{
                type = .END_COMP,
                value = line,
                line = line_num + 1,
                column = 1,
            })
        }else { // Property
            for k in Keywords{
                if strings.has_prefix(strings.trim_space(line), k){
                    // TODO Validate the values types
                    
                    append(&tokens, Token{
                        type = .KEYWORD,
                        value = line,
                        line = line_num + 1,
                        column = 1,
                    })
                    continue
                }
            }
        }
    }

    utils.norm_println(.DEBUG, "Tokenized %v lines", len(tokens))
    //utils.norm_println(tokens, .INFO)
    
    append(&tokens, Token{type = .EOF, line = len(lines), column = 1})
    //utils.norm_println(.INFOtokens)
    return tokens[:]
}