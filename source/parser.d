module parser;

import lexer;
import ast;
import types;
import std.conv;
import std.string;
import std.stdio;

class ParseError : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}

class Parser {
    private Token[] tokens;
    private size_t current;
    
    this(Token[] tokens) {
        this.tokens = tokens;
        this.current = 0;
    }
    
    Program parse() {
        StructDeclaration[] structs;
        FunctionDeclaration[] functions;
        RunBlock runBlock;
        
        skipNewlines();
        
        while (!isAtEnd() && !check(TokenType.RUN)) {
            if (check(TokenType.STRUCT)) {
                structs ~= parseStruct();
            } else if (check(TokenType.FNC)) {
                functions ~= parseFunction();
            } else {
                throw new ParseError("Expected struct declaration, function declaration, or run block");
            }
            skipNewlines();
        }
        
        if (!check(TokenType.RUN)) {
            throw new ParseError("Missing run block");
        }
        
        runBlock = parseRunBlock();
        
        skipNewlines();
        if (!isAtEnd()) {
            throw new ParseError("Unexpected tokens after run block");
        }
        
        return new Program(structs, functions, runBlock);
    }
    
    private FunctionDeclaration parseFunction() {
        consume(TokenType.FNC, "Expected 'fnc'");
        
        Token nameToken = consume(TokenType.IDENTIFIER, "Expected function name");
        string name = nameToken.value;
        
        consume(TokenType.LEFT_BRACKET, "Expected '['");
        
        Parameter[] parameters;
        if (!check(TokenType.RIGHT_BRACKET)) {
            do {
                parameters ~= parseParameter();
            } while (match(TokenType.COMMA));
        }
        
        consume(TokenType.RIGHT_BRACKET, "Expected ']'");
        consume(TokenType.COLON, "Expected ':'");
        
        LCType returnType = parseType();
        
        consume(TokenType.LEFT_BRACE, "Expected '{'");
        skipNewlines();
        
        Statement[] body;
        while (!check(TokenType.RIGHT_BRACE) && !isAtEnd()) {
            body ~= parseStatement();
            skipNewlines();
        }
        
        consume(TokenType.RIGHT_BRACE, "Expected '}'");
        
        return new FunctionDeclaration(name, parameters, returnType, body, nameToken.line, nameToken.column);
    }
    
    private StructDeclaration parseStruct() {
        Token structToken = consume(TokenType.STRUCT, "Expected 'struct'");
        Token nameToken = consume(TokenType.IDENTIFIER, "Expected struct name");
        string name = nameToken.value;
        
        consume(TokenType.LEFT_BRACE, "Expected '{'");
        skipNewlines();
        
        StructField[] fields;
        while (!check(TokenType.RIGHT_BRACE) && !isAtEnd()) {
            LCType fieldType = parseType();
            Token fieldNameToken = consume(TokenType.IDENTIFIER, "Expected field name");
            string fieldName = fieldNameToken.value;
            consume(TokenType.SEMICOLON, "Expected ';' after field declaration");
            skipNewlines();
            
            fields ~= StructField(fieldName, fieldType);
        }
        
        consume(TokenType.RIGHT_BRACE, "Expected '}'");
        consume(TokenType.SEMICOLON, "Expected ';' after struct declaration");
        
        return new StructDeclaration(name, fields, structToken.line, structToken.column);
    }
    
    private Parameter parseParameter() {
        bool isConstant = false;
        if (check(TokenType.VAL)) {
            advance();
            isConstant = true;
        }
        
        LCType type = parseType();
        Token nameToken = consume(TokenType.IDENTIFIER, "Expected parameter name");
        
        return new Parameter(type, nameToken.value, isConstant);
    }
    
    private RunBlock parseRunBlock() {
        Token runToken = consume(TokenType.RUN, "Expected 'run'");
        consume(TokenType.LEFT_BRACE, "Expected '{'");
        skipNewlines();
        
        Statement[] statements;
        while (!check(TokenType.RIGHT_BRACE) && !isAtEnd()) {
            statements ~= parseStatement();
            skipNewlines();
        }
        
        consume(TokenType.RIGHT_BRACE, "Expected '}'");
        consume(TokenType.SEMICOLON, "Expected ';' after run block");
        
        return new RunBlock(statements, runToken.line, runToken.column);
    }
    
    private Statement parseStatement() {
        if (check(TokenType.VAL)) {
            return parseVarDeclaration(true);
        }
        
        if (checkType()) {
            // Look ahead to see if this is really a variable declaration
            // Variable declaration: Type identifier = value;
            // Variable declaration: Type identifier;
            Token firstToken = peek();
            Token secondToken = peekNext();
            
            // If first is identifier and second is -> or [, it's an assignment, not declaration
            if (firstToken.type == TokenType.IDENTIFIER && 
                (secondToken.type == TokenType.ARROW || secondToken.type == TokenType.LEFT_BRACKET || 
                 secondToken.type == TokenType.ASSIGN)) {
                // This is assignment, not variable declaration - fall through
            } else {
                return parseVarDeclaration(false);
            }
        }
        
        if (check(TokenType.IF)) {
            return parseIfStatement();
        }
        
        if (check(TokenType.FOR)) {
            return parseForStatement();
        }
        
        if (check(TokenType.TRY)) {
            return parseTryStatement();
        }
        
        if (check(TokenType.REPEAT)) {
            return parseRepeatStatement();
        }
        
        if (check(TokenType.RETURN)) {
            return parseReturnStatement();
        }
        
        if (check(TokenType.LEFT_BRACE)) {
            return parseBlockStatement();
        }
        
        // Check for assignment, array assignment, or member assignment
        if (check(TokenType.IDENTIFIER)) {
            Token currentToken = peek();
            Token nextToken = peekNext();
            
            if (nextToken.type == TokenType.ASSIGN) {
                // Simple assignment: identifier = value
                Token nameToken = advance();
                consume(TokenType.ASSIGN, "Expected '='");
                Expression value = parseExpression();
                consume(TokenType.SEMICOLON, "Expected ';'");
                return new Assignment(nameToken.value, value, nameToken.line, nameToken.column);
            } else if (nextToken.type == TokenType.LEFT_BRACKET) {
                // Array assignment: identifier[index] = value
                Token nameToken = advance();
                consume(TokenType.LEFT_BRACKET, "Expected '['");
                Expression index = parseExpression();
                consume(TokenType.RIGHT_BRACKET, "Expected ']'");
                consume(TokenType.ASSIGN, "Expected '='");
                Expression value = parseExpression();
                consume(TokenType.SEMICOLON, "Expected ';'");
                
                // Create array access expression and array assignment
                auto arrayExpr = new Identifier(nameToken.value, nameToken.line, nameToken.column);
                return new ArrayAssignment(arrayExpr, index, value, nameToken.line, nameToken.column);
            } else if (nextToken.type == TokenType.ARROW) {
                // Member assignment: identifier->member = value
                Token nameToken = advance();
                consume(TokenType.ARROW, "Expected '->'");
                Token memberToken = consume(TokenType.IDENTIFIER, "Expected member name");
                consume(TokenType.ASSIGN, "Expected '='");
                Expression value = parseExpression();
                consume(TokenType.SEMICOLON, "Expected ';'");
                
                auto objectExpr = new Identifier(nameToken.value, nameToken.line, nameToken.column);
                return new MemberAssignment(objectExpr, memberToken.value, value, nameToken.line, nameToken.column);
            }
        }
        
        // Expression statement
        Expression expr = parseExpression();
        consume(TokenType.SEMICOLON, "Expected ';'");
        return new ExpressionStatement(expr, expr.line, expr.column);
    }
    
    private Statement parseVarDeclaration(bool isConstant) {
        Token startToken = peek();
        
        if (isConstant) {
            consume(TokenType.VAL, "Expected 'val'");
        }
        
        LCType type = parseType();
        Token nameToken = consume(TokenType.IDENTIFIER, "Expected variable name");
        
        Expression initializer;
        if (match(TokenType.ASSIGN)) {
            initializer = parseExpression();
        } else if (isConstant) {
            throw new ParseError("Constants must be initialized");
        }
        
        consume(TokenType.SEMICOLON, "Expected ';'");
        
        return new VarDeclaration(type, nameToken.value, initializer, isConstant, startToken.line, startToken.column);
    }
    
    private Statement parseIfStatement() {
        Token ifToken = consume(TokenType.IF, "Expected 'if'");
        consume(TokenType.LEFT_BRACKET, "Expected '['");
        Expression condition = parseExpression();
        consume(TokenType.RIGHT_BRACKET, "Expected ']'");
        
        consume(TokenType.LEFT_BRACE, "Expected '{'");
        skipNewlines();
        Statement[] thenBody;
        while (!check(TokenType.RIGHT_BRACE) && !isAtEnd()) {
            thenBody ~= parseStatement();
            skipNewlines();
        }
        consume(TokenType.RIGHT_BRACE, "Expected '}'");
        
        IfStatement ifStmt = new IfStatement(condition, thenBody, ifToken.line, ifToken.column);
        IfStatement currentIf = ifStmt;
        
        // Handle "or" clauses (else if)
        while (match(TokenType.OR)) {
            consume(TokenType.LEFT_BRACKET, "Expected '['");
            Expression orCondition = parseExpression();
            consume(TokenType.RIGHT_BRACKET, "Expected ']'");
            
            consume(TokenType.LEFT_BRACE, "Expected '{'");
            skipNewlines();
            Statement[] orBody;
            while (!check(TokenType.RIGHT_BRACE) && !isAtEnd()) {
                orBody ~= parseStatement();
                skipNewlines();
            }
            consume(TokenType.RIGHT_BRACE, "Expected '}'");
            
            IfStatement orStmt = new IfStatement(orCondition, orBody);
            currentIf.elseIf = orStmt;
            currentIf = orStmt;
        }
        
        // Handle else clause
        if (match(TokenType.ELSE)) {
            consume(TokenType.LEFT_BRACE, "Expected '{'");
            skipNewlines();
            while (!check(TokenType.RIGHT_BRACE) && !isAtEnd()) {
                currentIf.elseBody ~= parseStatement();
                skipNewlines();
            }
            consume(TokenType.RIGHT_BRACE, "Expected '}'");
        }
        
        return ifStmt;
    }
    
    private Statement parseForStatement() {
        Token forToken = consume(TokenType.FOR, "Expected 'for'");
        consume(TokenType.LEFT_BRACKET, "Expected '['");
        
        Statement initialization = parseStatement(); // This consumes the semicolon
        
        Expression condition = parseExpression();
        consume(TokenType.SEMICOLON, "Expected ';'");
        
        Statement increment = parseForIncrement();
        consume(TokenType.RIGHT_BRACKET, "Expected ']'");
        
        consume(TokenType.LEFT_BRACE, "Expected '{'");
        skipNewlines();
        Statement[] body;
        while (!check(TokenType.RIGHT_BRACE) && !isAtEnd()) {
            body ~= parseStatement();
            skipNewlines();
        }
        consume(TokenType.RIGHT_BRACE, "Expected '}'");
        
        return new ForStatement(initialization, condition, increment, body, forToken.line, forToken.column);
    }
    
    private Statement parseForIncrement() {
        // Parse increment/decrement without expecting semicolon
        if (check(TokenType.IDENTIFIER) && peekNext().type == TokenType.ASSIGN) {
            Token nameToken = advance();
            consume(TokenType.ASSIGN, "Expected '='");
            Expression value = parseExpression();
            return new Assignment(nameToken.value, value, nameToken.line, nameToken.column);
        }
        
        Expression expr = parseExpression();
        return new ExpressionStatement(expr, expr.line, expr.column);
    }
    
    private Statement parseTryStatement() {
        Token tryToken = consume(TokenType.TRY, "Expected 'try'");
        consume(TokenType.LEFT_BRACE, "Expected '{'");
        skipNewlines();
        
        Statement[] tryBody;
        while (!check(TokenType.RIGHT_BRACE) && !isAtEnd()) {
            tryBody ~= parseStatement();
            skipNewlines();
        }
        consume(TokenType.RIGHT_BRACE, "Expected '}'");
        
        string catchVariable;
        Statement[] catchBody;
        if (match(TokenType.CATCH)) {
            consume(TokenType.LEFT_BRACKET, "Expected '['");
            Token catchVar = consume(TokenType.IDENTIFIER, "Expected catch variable name");
            catchVariable = catchVar.value;
            consume(TokenType.RIGHT_BRACKET, "Expected ']'");
            
            consume(TokenType.LEFT_BRACE, "Expected '{'");
            skipNewlines();
            while (!check(TokenType.RIGHT_BRACE) && !isAtEnd()) {
                catchBody ~= parseStatement();
                skipNewlines();
            }
            consume(TokenType.RIGHT_BRACE, "Expected '}'");
        }
        
        Statement[] finallyBody;
        if (match(TokenType.FINALLY)) {
            consume(TokenType.LEFT_BRACE, "Expected '{'");
            skipNewlines();
            while (!check(TokenType.RIGHT_BRACE) && !isAtEnd()) {
                finallyBody ~= parseStatement();
                skipNewlines();
            }
            consume(TokenType.RIGHT_BRACE, "Expected '}'");
        }
        
        return new TryStatement(tryBody, catchVariable, catchBody, finallyBody, tryToken.line, tryToken.column);
    }
    
    private Statement parseRepeatStatement() {
        Token repeatToken = consume(TokenType.REPEAT, "Expected 'repeat'");
        
        consume(TokenType.LEFT_BRACKET, "Expected '['");
        Expression expression = parseExpression();
        consume(TokenType.RIGHT_BRACKET, "Expected ']'");
        
        consume(TokenType.LEFT_BRACE, "Expected '{'");
        skipNewlines();
        
        WhenCase[] whenCases;
        Statement[] fixedBody;
        
        // Parse when cases
        while (check(TokenType.WHEN) && !isAtEnd()) {
            advance(); // consume 'when'
            consume(TokenType.LEFT_BRACKET, "Expected '['");
            Expression caseValue = parseExpression();
            consume(TokenType.RIGHT_BRACKET, "Expected ']'");
            
            consume(TokenType.LEFT_BRACE, "Expected '{'");
            skipNewlines();
            
            Statement[] caseBody;
            while (!check(TokenType.RIGHT_BRACE) && !isAtEnd()) {
                caseBody ~= parseStatement();
                skipNewlines();
            }
            consume(TokenType.RIGHT_BRACE, "Expected '}'");
            skipNewlines();
            
            whenCases ~= new WhenCase(caseValue, caseBody);
        }
        
        // Parse fixed case (optional, acts like default)
        if (check(TokenType.FIXED)) {
            advance(); // consume 'fixed'
            consume(TokenType.LEFT_BRACE, "Expected '{'");
            skipNewlines();
            
            while (!check(TokenType.RIGHT_BRACE) && !isAtEnd()) {
                fixedBody ~= parseStatement();
                skipNewlines();
            }
            consume(TokenType.RIGHT_BRACE, "Expected '}'");
            skipNewlines();
        }
        
        consume(TokenType.RIGHT_BRACE, "Expected '}'");
        
        return new RepeatStatement(expression, whenCases, fixedBody, repeatToken.line, repeatToken.column);
    }
    
    private Statement parseReturnStatement() {
        Token returnToken = consume(TokenType.RETURN, "Expected 'return'");
        
        Expression value;
        if (!check(TokenType.SEMICOLON)) {
            value = parseExpression();
        }
        
        consume(TokenType.SEMICOLON, "Expected ';'");
        return new ReturnStatement(value, returnToken.line, returnToken.column);
    }
    
    private Statement parseBlockStatement() {
        Token braceToken = consume(TokenType.LEFT_BRACE, "Expected '{'");
        skipNewlines();
        
        Statement[] statements;
        while (!check(TokenType.RIGHT_BRACE) && !isAtEnd()) {
            statements ~= parseStatement();
            skipNewlines();
        }
        
        consume(TokenType.RIGHT_BRACE, "Expected '}'");
        return new BlockStatement(statements, braceToken.line, braceToken.column);
    }
    
    private Expression parseExpression() {
        return parseOr();
    }
    
    private Expression parseOr() {
        Expression expr = parseAnd();
        
        while (match(TokenType.OR_OP)) {
            Token operator = previous();
            Expression right = parseAnd();
            expr = new BinaryOp(expr, operator.value, right, expr.line, expr.column);
        }
        
        return expr;
    }
    
    private Expression parseAnd() {
        Expression expr = parseEquality();
        
        while (match(TokenType.AND)) {
            Token operator = previous();
            Expression right = parseEquality();
            expr = new BinaryOp(expr, operator.value, right, expr.line, expr.column);
        }
        
        return expr;
    }
    
    private Expression parseEquality() {
        Expression expr = parseComparison();
        
        while (match(TokenType.EQUAL, TokenType.NOT_EQUAL)) {
            Token operator = previous();
            Expression right = parseComparison();
            expr = new BinaryOp(expr, operator.value, right, expr.line, expr.column);
        }
        
        return expr;
    }
    
    private Expression parseComparison() {
        Expression expr = parseTerm();
        
        while (match(TokenType.GREATER, TokenType.GREATER_EQUAL, TokenType.LESS, TokenType.LESS_EQUAL)) {
            Token operator = previous();
            Expression right = parseTerm();
            expr = new BinaryOp(expr, operator.value, right, expr.line, expr.column);
        }
        
        return expr;
    }
    
    private Expression parseTerm() {
        Expression expr = parseFactor();
        
        while (match(TokenType.MINUS, TokenType.PLUS, TokenType.PLUS_CONCAT)) {
            Token operator = previous();
            Expression right = parseFactor();
            
            if (operator.type == TokenType.PLUS_CONCAT) {
                // Create StringConcatenation node for +>> operator
                expr = new StringConcatenation(expr, right, expr.line, expr.column);
            } else {
                // Regular binary operation for + and -
                expr = new BinaryOp(expr, operator.value, right, expr.line, expr.column);
            }
        }
        
        return expr;
    }
    
    private Expression parseFactor() {
        Expression expr = parseUnary();
        
        while (match(TokenType.DIVIDE, TokenType.MULTIPLY, TokenType.MODULO)) {
            Token operator = previous();
            Expression right = parseUnary();
            expr = new BinaryOp(expr, operator.value, right, expr.line, expr.column);
        }
        
        return expr;
    }
    
    private Expression parseUnary() {
        if (match(TokenType.NOT, TokenType.MINUS, TokenType.PLUS)) {
            Token operator = previous();
            Expression right = parseUnary();
            return new UnaryOp(operator.value, right, operator.line, operator.column);
        }
        
        return parseCall();
    }
    
    private Expression parseCall() {
        Expression expr = parsePrimary();
        
        while (true) {
            if (match(TokenType.LEFT_BRACKET)) {
                expr = finishCall(expr);
            } else if (match(TokenType.DOT)) {
                // Handle member access for built-in types
                Token memberToken = consume(TokenType.IDENTIFIER, "Expected member name after '.'");
                
                // Check if this is a type function call (like "num.read")
                if (auto ident = cast(Identifier)expr) {
                    if (ident.name == "num" || ident.name == "text" || ident.name == "char" || ident.name == "bool") {
                        // Type function call like "num.read"
                        string qualifiedName = ident.name ~ "." ~ memberToken.value;
                        expr = new Identifier(qualifiedName, ident.line, ident.column);
                    } else {
                        throw new ParseError("Use -> for struct member access, not .");
                    }
                } else {
                    throw new ParseError("Use -> for struct member access, not .");
                }
            } else if (match(TokenType.ARROW)) {
                // Handle struct member access
                Token memberToken = consume(TokenType.IDENTIFIER, "Expected member name after '->'");
                
                // Always treat as struct member access
                expr = new MemberAccess(expr, memberToken.value, memberToken.line, memberToken.column);
            } else {
                break;
            }
        }
        
        return expr;
    }
    
    private Expression finishCall(Expression callee) {
        Expression[] arguments;
        
        if (!check(TokenType.RIGHT_BRACKET)) {
            do {
                arguments ~= parseExpression();
            } while (match(TokenType.COMMA));
        }
        
        consume(TokenType.RIGHT_BRACKET, "Expected ']' after arguments");
        
        // Handle special case for built-in functions (backward compatibility)
        if (auto ident = cast(Identifier)callee) {
            if (ident.name == "print" || ident.name == "read" || 
                ident.name.indexOf('.') != -1) { // member function calls like num.read
                return new FunctionCall(ident.name, arguments, callee.line, callee.column);
            }
        }
        
        // Default case: array access
        if (arguments.length != 1) {
            throw new ParseError("Array access requires exactly one index");
        }
        return new ArrayAccess(callee, arguments[0], callee.line, callee.column);
    }
    
    private Expression parsePrimary() {
        if (match(TokenType.BOOL)) {
            Token token = previous();
            return new BoolLiteral(token.value == "true", token.line, token.column);
        }
        
        if (match(TokenType.NULL)) {
            Token token = previous();
            return new NullLiteral(token.line, token.column);
        }
        
        if (match(TokenType.NUMBER)) {
            Token token = previous();
            double value = to!double(token.value);
            bool isInteger = token.value.indexOf('.') == -1;
            return new NumberLiteral(value, isInteger, token.line, token.column);
        }
        
        if (match(TokenType.TEXT)) {
            Token token = previous();
            return parseStringWithInterpolation(token);
        }
        
        if (match(TokenType.CHAR)) {
            Token token = previous();
            return new CharLiteral(token.value[0], token.line, token.column);
        }
        
        // Array literals: [1, 2, 3] 
        if (match(TokenType.LEFT_BRACKET)) {
            Token token = previous();
            Expression[] elements;
            
            if (!check(TokenType.RIGHT_BRACKET)) {
                do {
                    elements ~= parseExpression();
                } while (match(TokenType.COMMA));
            }
            
            consume(TokenType.RIGHT_BRACKET, "Expected ']' after array elements");
            return new ArrayLiteral(elements, token.line, token.column);
        }
        
        // Function calls: @functionName[args]
        if (match(TokenType.AT)) {
            Token atToken = previous();
            Token nameToken = consume(TokenType.IDENTIFIER, "Expected function name after '@'");
            consume(TokenType.LEFT_BRACKET, "Expected '[' after function name");
            
            Expression[] arguments;
            if (!check(TokenType.RIGHT_BRACKET)) {
                do {
                    arguments ~= parseExpression();
                } while (match(TokenType.COMMA));
            }
            
            consume(TokenType.RIGHT_BRACKET, "Expected ']' after function arguments");
            return new FunctionCall(nameToken.value, arguments, atToken.line, atToken.column);
        }
        
        if (match(TokenType.IDENTIFIER)) {
            Token token = previous();
            
            // Check for struct literal: StructName{field1: value1, field2: value2}
            if (check(TokenType.LEFT_BRACE)) {
                advance(); // consume '{'
                
                string[] fieldNames;
                Expression[] fieldValues;
                
                if (!check(TokenType.RIGHT_BRACE)) {
                    do {
                        Token fieldNameToken = consume(TokenType.IDENTIFIER, "Expected field name");
                        consume(TokenType.COLON, "Expected ':' after field name");
                        Expression value = parseExpression();
                        
                        fieldNames ~= fieldNameToken.value;
                        fieldValues ~= value;
                    } while (match(TokenType.COMMA));
                }
                
                consume(TokenType.RIGHT_BRACE, "Expected '}' after struct literal");
                return new StructLiteral(token.value, fieldNames, fieldValues, token.line, token.column);
            }
            
            return new Identifier(token.value, token.line, token.column);
        }
        
        // Handle type keywords as identifiers for member access (e.g., num.read)
        if (match(TokenType.NUM)) {
            Token token = previous();
            return new Identifier("num", token.line, token.column);
        }
        
        if (match(TokenType.TEXT_TYPE)) {
            Token token = previous();
            return new Identifier("text", token.line, token.column);
        }
        
        if (match(TokenType.CHAR_TYPE)) {
            Token token = previous();
            return new Identifier("char", token.line, token.column);
        }
        
        if (match(TokenType.BOOL_TYPE)) {
            Token token = previous();
            return new Identifier("bool", token.line, token.column);
        }
        
        if (match(TokenType.TEXT)) {
            Token token = previous();
            return parseStringWithInterpolation(token);
        }
        
        if (match(TokenType.CHAR)) {
            Token token = previous();
            return new CharLiteral(token.value[0], token.line, token.column);
        }
        
        if (match(TokenType.BOOL)) {
            Token token = previous();
            return new BoolLiteral(token.value == "true", token.line, token.column);
        }
        
        if (match(TokenType.LEFT_PAREN)) {
            Expression expr = parseExpression();
            consume(TokenType.RIGHT_PAREN, "Expected ')' after expression");
            return expr;
        }
        
        throw new ParseError("Expected expression");
    }
    
    private Expression parseStringWithInterpolation(Token token) {
        string text = token.value;
        
        // Simple check for $ interpolation
        if (text.indexOf('$') == -1) {
            return new TextLiteral(text, token.line, token.column);
        }
        
        // Parse interpolation with format specifier support
        string[] parts;
        Expression[] expressions;
        string[] formatSpecifiers;
        
        size_t i = 0;
        string currentPart = "";
        
        while (i < text.length) {
            if (text[i] == '$') {
                if (i + 1 < text.length && text[i + 1] == '{') {
                    // ${expression:format} form
                    parts ~= currentPart;
                    currentPart = "";
                    i += 2; // skip ${
                    
                    string exprText = "";
                    string formatSpec = "";
                    int braceCount = 1;
                    bool inFormat = false;
                    
                    while (i < text.length && braceCount > 0) {
                        if (text[i] == '{') braceCount++;
                        else if (text[i] == '}') braceCount--;
                        
                        if (braceCount > 0) {
                            if (text[i] == ':' && !inFormat) {
                                inFormat = true;
                            } else if (inFormat) {
                                formatSpec ~= text[i];
                            } else {
                                exprText ~= text[i];
                            }
                        }
                        i++;
                    }
                    
                    // Parse the expression (simplified - just create identifier)
                    expressions ~= new Identifier(exprText, token.line, token.column);
                    formatSpecifiers ~= ":" ~ formatSpec; // Include the colon prefix
                } else if (i + 1 < text.length && isAlpha(text[i + 1])) {
                    // $variable form
                    parts ~= currentPart;
                    currentPart = "";
                    i++; // skip $
                    
                    string varName = "";
                    while (i < text.length && isAlphaNumeric(text[i])) {
                        varName ~= text[i];
                        i++;
                    }
                    
                    expressions ~= new Identifier(varName, token.line, token.column);
                    formatSpecifiers ~= ""; // No format specifier for simple form
                } else {
                    currentPart ~= text[i];
                    i++;
                }
            } else {
                currentPart ~= text[i];
                i++;
            }
        }
        
        parts ~= currentPart;
        
        return new StringInterpolation(parts, expressions, formatSpecifiers, token.line, token.column);
    }
    
    private LCType parseType() {
        string typeName;
        
        if (match(TokenType.NUM)) {
            typeName = "num";
        } else if (match(TokenType.TEXT_TYPE)) {
            typeName = "text";
        } else if (match(TokenType.CHAR_TYPE)) {
            typeName = "char";
        } else if (match(TokenType.BOOL_TYPE)) {
            typeName = "bool";
        } else if (match(TokenType.VOID)) {
            typeName = "void";
        } else if (match(TokenType.IDENTIFIER)) {
            // Custom struct type
            Token typeToken = previous();
            typeName = typeToken.value;
        } else {
            throw new ParseError("Expected type");
        }
        
        // Handle array syntax: type[size] or type[]
        if (check(TokenType.LEFT_BRACKET)) {
            advance(); // consume '['
            
            if (check(TokenType.RIGHT_BRACKET)) {
                // Dynamic array: type[]
                advance(); // consume ']'
                typeName ~= "[]";
            } else if (check(TokenType.NUMBER)) {
                // Fixed size array: type[size]
                Token sizeToken = advance();
                consume(TokenType.RIGHT_BRACKET, "Expected ']' after array size");
                typeName ~= "[" ~ sizeToken.value ~ "]";
            } else {
                throw new ParseError("Expected array size or ']' for dynamic array");
            }
        }
        
        bool nullable = match(TokenType.QUESTION);
        if (nullable) {
            typeName ~= "?";
        }
        
        return types.parseType(typeName);
    }
    
    private bool checkType() {
        return check(TokenType.NUM) || check(TokenType.TEXT_TYPE) || 
               check(TokenType.CHAR_TYPE) || check(TokenType.BOOL_TYPE) || 
               check(TokenType.VOID) || check(TokenType.IDENTIFIER);
    }
    
    private bool match(TokenType[] types...) {
        foreach (type; types) {
            if (check(type)) {
                advance();
                return true;
            }
        }
        return false;
    }
    
    private bool check(TokenType type) {
        if (isAtEnd()) return false;
        return peek().type == type;
    }
    
    private Token advance() {
        if (!isAtEnd()) current++;
        return previous();
    }
    
    private bool isAtEnd() {
        return peek().type == TokenType.EOF;
    }
    
    private Token peek() {
        return tokens[current];
    }
    
    private Token peekNext() {
        if (current + 1 >= tokens.length) return tokens[$-1]; // EOF
        return tokens[current + 1];
    }
    
    private Token peekThird() {
        if (current + 2 >= tokens.length) return tokens[$-1]; // EOF
        return tokens[current + 2];
    }
    
    private Token peekFourth() {
        if (current + 3 >= tokens.length) return tokens[$-1]; // EOF
        return tokens[current + 3];
    }
    
    private Token previous() {
        return tokens[current - 1];
    }
    
    private Token consume(TokenType type, string message) {
        if (check(type)) return advance();
        
        Token current_token = peek();
        string error_msg = message ~ " at line " ~ to!string(current_token.line) ~ 
                          ", column " ~ to!string(current_token.column);
        throw new ParseError(error_msg);
    }
    
    private void skipNewlines() {
        while (match(TokenType.NEWLINE)) {
            // Skip newlines
        }
    }
    
    private bool isAlpha(char c) {
        return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_';
    }
    
    private bool isAlphaNumeric(char c) {
        return isAlpha(c) || (c >= '0' && c <= '9');
    }
}
