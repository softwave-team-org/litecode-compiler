module lexer;

import std.string;
import std.conv;
import std.ascii;
import std.regex;

enum TokenType {
    // Literals
    NUMBER,
    TEXT,
    CHAR,
    BOOL,
    NULL,
    
    // Identifiers and keywords
    IDENTIFIER,
    
    // Keywords
    VAL,
    FNC,
    RUN,
    IF,
    OR,
    ELSE,
    FOR,
    TRY,
    CATCH,
    FINALLY,
    RETURN,
    PRINT,
    READ,
    REPEAT,
    WHEN,
    FIXED,
    STRUCT,
    
    // Types
    NUM,
    TEXT_TYPE,
    CHAR_TYPE,
    BOOL_TYPE,
    VOID,
    
    // Operators
    PLUS,
    PLUS_CONCAT,  // String concatenation operator +>>
    MINUS,
    MULTIPLY,
    DIVIDE,
    MODULO,
    
    // Comparison
    EQUAL,
    NOT_EQUAL,
    LESS,
    GREATER,
    LESS_EQUAL,
    GREATER_EQUAL,
    
    // Logical
    AND,
    OR_OP,
    NOT,
    
    // Assignment
    ASSIGN,
    
    // Punctuation
    SEMICOLON,
    COMMA,
    DOT,
    COLON,
    QUESTION,
    DOLLAR,
    AT,
    ARROW,  // ->
    
    // Brackets
    LEFT_BRACKET,
    RIGHT_BRACKET,
    LEFT_BRACE,
    RIGHT_BRACE,
    LEFT_PAREN,
    RIGHT_PAREN,
    
    // Special
    NEWLINE,
    EOF,
    
    // Format specifiers
    FORMAT_D,
    FORMAT_F,
    FORMAT_S
}

struct Token {
    TokenType type;
    string value;
    int line;
    int column;
    
    this(TokenType type, string value, int line, int column) {
        this.type = type;
        this.value = value;
        this.line = line;
        this.column = column;
    }
}

class Lexer {
    private string source;
    private size_t current;
    private int line;
    private int column;
    private Token[] tokens;
    
    private static string[string] keywords;
    
    static this() {
        keywords = [
            "val": "VAL",
            "fnc": "FNC", 
            "run": "RUN",
            "if": "IF",
            "or": "OR",
            "else": "ELSE",
            "for": "FOR",
            "try": "TRY",
            "catch": "CATCH",
            "finally": "FINALLY",
            "return": "RETURN",
            "repeat": "REPEAT",
            "when": "WHEN",
            "fixed": "FIXED",
            "struct": "STRUCT",
            "num": "NUM",
            "text": "TEXT_TYPE",
            "char": "CHAR_TYPE", 
            "bool": "BOOL_TYPE",
            "void": "VOID",
            "true": "BOOL",
            "false": "BOOL",
            "null": "NULL"
        ];
    }
    
    this(string source) {
        this.source = source;
        this.current = 0;
        this.line = 1;
        this.column = 1;
    }
    
    Token[] tokenize() {
        while (!isAtEnd()) {
            skipWhitespace();
            if (isAtEnd()) break;
            
            size_t start = current;
            int startLine = line;
            int startColumn = column;
            
            char c = advance();
            
            switch (c) {
                case '+':
                    if (peek() == '>' && peek(1) == '>') {
                        advance(); // consume first '>'
                        advance(); // consume second '>'
                        addToken(TokenType.PLUS_CONCAT, "+>>", startLine, startColumn);
                    } else {
                        addToken(TokenType.PLUS, "+", startLine, startColumn);
                    }
                    break;
                case '-':
                    if (peek() == '>') {
                        advance(); // consume '>'
                        addToken(TokenType.ARROW, "->", startLine, startColumn);
                    } else {
                        addToken(TokenType.MINUS, "-", startLine, startColumn);
                    }
                    break;
                case '*':
                    addToken(TokenType.MULTIPLY, "*", startLine, startColumn);
                    break;
                case '/':
                    if (peek() == '/') {
                        // Single-line comment: skip to end of line
                        advance(); // consume second '/'
                        while (peek() != '\n' && !isAtEnd()) advance();
                    } else if (peek() == '?') {
                        // Multi-line comment: skip until ?/
                        advance(); // consume '?'
                        bool foundEnd = false;
                        while (!isAtEnd() && !foundEnd) {
                            if (peek() == '?' && peek(1) == '/') {
                                advance(); // consume '?'
                                advance(); // consume '/'
                                foundEnd = true;
                            } else {
                                advance();
                            }
                        }
                        // If we reach end of file without closing comment, 
                        // that's a lexical error, but we'll just ignore it for now
                    } else {
                        addToken(TokenType.DIVIDE, "/", startLine, startColumn);
                    }
                    break;
                case '%':
                    addToken(TokenType.MODULO, "%", startLine, startColumn);
                    break;
                case '=':
                    if (peek() == '=') {
                        advance();
                        addToken(TokenType.EQUAL, "==", startLine, startColumn);
                    } else {
                        addToken(TokenType.ASSIGN, "=", startLine, startColumn);
                    }
                    break;
                case '!':
                    if (peek() == '=') {
                        advance();
                        addToken(TokenType.NOT_EQUAL, "!=", startLine, startColumn);
                    } else if (peek() == '!') {
                        advance();
                        addToken(TokenType.NOT, "!!", startLine, startColumn);
                    }
                    break;
                case '<':
                    if (peek() == '=') {
                        advance();
                        addToken(TokenType.LESS_EQUAL, "<=", startLine, startColumn);
                    } else {
                        addToken(TokenType.LESS, "<", startLine, startColumn);
                    }
                    break;
                case '>':
                    if (peek() == '=') {
                        advance();
                        addToken(TokenType.GREATER_EQUAL, ">=", startLine, startColumn);
                    } else {
                        addToken(TokenType.GREATER, ">", startLine, startColumn);
                    }
                    break;
                case '&':
                    if (peek() == '&') {
                        advance();
                        addToken(TokenType.AND, "&&", startLine, startColumn);
                    }
                    break;
                case '|':
                    if (peek() == '|') {
                        advance();
                        addToken(TokenType.OR_OP, "||", startLine, startColumn);
                    }
                    break;
                case ';':
                    addToken(TokenType.SEMICOLON, ";", startLine, startColumn);
                    break;
                case ',':
                    addToken(TokenType.COMMA, ",", startLine, startColumn);
                    break;
                case '.':
                    addToken(TokenType.DOT, ".", startLine, startColumn);
                    break;
                case ':':
                    // Check for format specifiers
                    if (peek() == 'd') {
                        advance();
                        addToken(TokenType.FORMAT_D, ":d", startLine, startColumn);
                    } else if (peek() == 'f') {
                        advance();
                        addToken(TokenType.FORMAT_F, ":f", startLine, startColumn);
                    } else if (peek() == 's') {
                        advance();
                        addToken(TokenType.FORMAT_S, ":s", startLine, startColumn);
                    } else {
                        addToken(TokenType.COLON, ":", startLine, startColumn);
                    }
                    break;
                case '?':
                    addToken(TokenType.QUESTION, "?", startLine, startColumn);
                    break;
                case '$':
                    addToken(TokenType.DOLLAR, "$", startLine, startColumn);
                    break;
                case '@':
                    addToken(TokenType.AT, "@", startLine, startColumn);
                    break;
                case '[':
                    addToken(TokenType.LEFT_BRACKET, "[", startLine, startColumn);
                    break;
                case ']':
                    addToken(TokenType.RIGHT_BRACKET, "]", startLine, startColumn);
                    break;
                case '{':
                    addToken(TokenType.LEFT_BRACE, "{", startLine, startColumn);
                    break;
                case '}':
                    addToken(TokenType.RIGHT_BRACE, "}", startLine, startColumn);
                    break;
                case '(':
                    addToken(TokenType.LEFT_PAREN, "(", startLine, startColumn);
                    break;
                case ')':
                    addToken(TokenType.RIGHT_PAREN, ")", startLine, startColumn);
                    break;
                case '"':
                    scanString(startLine, startColumn);
                    break;
                case '\'':
                    scanChar(startLine, startColumn);
                    break;
                case '\n':
                    addToken(TokenType.NEWLINE, "\n", startLine, startColumn);
                    break;
                default:
                    if (isDigit(c)) {
                        current--; column--; // backtrack
                        scanNumber(startLine, startColumn);
                    } else if (isAlpha(c) || c == '_') {
                        current--; column--; // backtrack
                        scanIdentifier(startLine, startColumn);
                    } else {
                        // Unknown character, skip it
                    }
                    break;
            }
        }
        
        addToken(TokenType.EOF, "", line, column);
        return tokens;
    }
    
    private bool isAtEnd() {
        return current >= source.length;
    }
    
    private char advance() {
        if (isAtEnd()) return '\0';
        char c = source[current++];
        if (c == '\n') {
            line++;
            column = 1;
        } else {
            column++;
        }
        return c;
    }
    
    private char peek(size_t offset = 0) {
        size_t pos = current + offset;
        if (pos >= source.length) return '\0';
        return source[pos];
    }
    
    private void skipWhitespace() {
        while (!isAtEnd()) {
            char c = peek();
            if (c == ' ' || c == '\r' || c == '\t') {
                advance();
            } else {
                break;
            }
        }
    }
    
    private void scanString(int startLine, int startColumn) {
        string value = "";
        
        while (peek() != '"' && !isAtEnd()) {
            if (peek() == '\n') {
                line++;
                column = 1;
            }
            char c = advance();
            
            // Handle escape sequences
            if (c == '\\') {
                if (!isAtEnd()) {
                    char escaped = advance();
                    switch (escaped) {
                        case 'n': value ~= '\n'; break;
                        case 't': value ~= '\t'; break;
                        case 'r': value ~= '\r'; break;
                        case '\\': value ~= '\\'; break;
                        case '"': value ~= '"'; break;
                        default: value ~= escaped; break;
                    }
                }
            } else {
                value ~= c;
            }
        }
        
        if (isAtEnd()) {
            // Unterminated string
            return;
        }
        
        // Consume closing "
        advance();
        
        addToken(TokenType.TEXT, value, startLine, startColumn);
    }
    
    private void scanChar(int startLine, int startColumn) {
        if (isAtEnd()) return;
        
        char value;
        char c = advance();
        
        if (c == '\\') {
            if (!isAtEnd()) {
                char escaped = advance();
                switch (escaped) {
                    case 'n': value = '\n'; break;
                    case 't': value = '\t'; break;
                    case 'r': value = '\r'; break;
                    case '\\': value = '\\'; break;
                    case '\'': value = '\''; break;
                    default: value = escaped; break;
                }
            }
        } else {
            value = c;
        }
        
        if (peek() != '\'' || isAtEnd()) {
            // Invalid char literal
            return;
        }
        
        // Consume closing '
        advance();
        
        addToken(TokenType.CHAR, [value], startLine, startColumn);
    }
    
    private void scanNumber(int startLine, int startColumn) {
        string value = "";
        bool hasDecimal = false;
        
        while (isDigit(peek())) {
            value ~= advance();
        }
        
        // Look for decimal point
        if (peek() == '.' && isDigit(peek(1))) {
            hasDecimal = true;
            value ~= advance(); // consume '.'
            
            while (isDigit(peek())) {
                value ~= advance();
            }
        }
        
        addToken(TokenType.NUMBER, value, startLine, startColumn);
    }
    
    private void scanIdentifier(int startLine, int startColumn) {
        string value = "";
        
        while (isAlphaNumeric(peek())) {
            value ~= advance();
        }
        
        // Check if it's a keyword
        TokenType type = TokenType.IDENTIFIER;
        if (value in keywords) {
            switch (keywords[value]) {
                case "VAL": type = TokenType.VAL; break;
                case "FNC": type = TokenType.FNC; break;
                case "RUN": type = TokenType.RUN; break;
                case "IF": type = TokenType.IF; break;
                case "OR": type = TokenType.OR; break;
                case "ELSE": type = TokenType.ELSE; break;
                case "FOR": type = TokenType.FOR; break;
                case "TRY": type = TokenType.TRY; break;
                case "CATCH": type = TokenType.CATCH; break;
                case "FINALLY": type = TokenType.FINALLY; break;
                case "RETURN": type = TokenType.RETURN; break;
                case "REPEAT": type = TokenType.REPEAT; break;
                case "WHEN": type = TokenType.WHEN; break;
                case "FIXED": type = TokenType.FIXED; break;
                case "STRUCT": type = TokenType.STRUCT; break;
                case "NUM": type = TokenType.NUM; break;
                case "TEXT_TYPE": type = TokenType.TEXT_TYPE; break;
                case "CHAR_TYPE": type = TokenType.CHAR_TYPE; break;
                case "BOOL_TYPE": type = TokenType.BOOL_TYPE; break;
                case "VOID": type = TokenType.VOID; break;
                case "BOOL": type = TokenType.BOOL; break;
                case "NULL": type = TokenType.NULL; break;
                default: break;
            }
        }
        
        addToken(type, value, startLine, startColumn);
    }
    
    private void addToken(TokenType type, string value, int line, int column) {
        tokens ~= Token(type, value, line, column);
    }
    
    private bool isDigit(char c) {
        return c >= '0' && c <= '9';
    }
    
    private bool isAlpha(char c) {
        return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_';
    }
    
    private bool isAlphaNumeric(char c) {
        return isAlpha(c) || isDigit(c);
    }
}
