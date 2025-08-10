module semantic;

import std.stdio;
import std.format;
import std.conv;
import ast;
import types;

class SemanticError : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}

class SemanticAnalyzer {
    private LCType[string] variables;
    private FunctionType[string] functions;
    
    this() {
        // Add built-in functions
        auto printParams = [cast(LCType)new TextType()];
        functions["print"] = new FunctionType(printParams, new VoidType());
        
        auto readParams = cast(LCType[])[];
        functions["read"] = new FunctionType(readParams, new TextType());
    }
    
    void analyze(Program program) {
        // First pass: register all struct declarations
        foreach (structDecl; program.structs) {
            registerStruct(new StructType(structDecl.name, structDecl.fields));
        }
        
        // Second pass: register all function declarations
        foreach (func; program.functions) {
            if (func.name in functions) {
                throw new SemanticError("Function '" ~ func.name ~ "' already declared");
            }
            
            LCType[] paramTypes;
            foreach (param; func.parameters) {
                paramTypes ~= param.type;
            }
            
            functions[func.name] = new FunctionType(paramTypes, func.returnType);
        }
        
        // Third pass: analyze function bodies
        foreach (func; program.functions) {
            analyzeFunctionDeclaration(func);
        }
        
        // Analyze run block
        if (program.runBlock) {
            foreach (statement; program.runBlock.statements) {
                analyzeStatement(statement);
            }
        }
    }
    
    private void analyzeStatement(ASTNode statement) {
        if (auto varDecl = cast(VarDeclaration)statement) {
            analyzeVariableDeclaration(varDecl);
        } else if (auto assignment = cast(Assignment)statement) {
            analyzeAssignment(assignment);
        } else if (auto funcCall = cast(FunctionCall)statement) {
            analyzeFunctionCall(funcCall);
        } else if (auto funcDecl = cast(FunctionDeclaration)statement) {
            // Function declarations are handled separately in analyze()
        } else if (auto arrayAssign = cast(ArrayAssignment)statement) {
            analyzeArrayAssignment(arrayAssign);
        } else if (auto memberAssign = cast(MemberAssignment)statement) {
            analyzeMemberAssignment(memberAssign);
        } else if (auto returnStmt = cast(ReturnStatement)statement) {
            analyzeReturnStatement(returnStmt);
        } else if (auto ifStmt = cast(IfStatement)statement) {
            analyzeIfStatement(ifStmt);
        } else if (auto forStmt = cast(ForStatement)statement) {
            analyzeForStatement(forStmt);
        } else if (auto repeatStmt = cast(RepeatStatement)statement) {
            analyzeRepeatStatement(repeatStmt);
        }
    }
    
    private void analyzeVariableDeclaration(VarDeclaration varDecl) {
        if (varDecl.name in variables) {
            throw new SemanticError("Variable '" ~ varDecl.name ~ "' already declared");
        }
        
        LCType valueType;
        if (varDecl.initializer) {
            valueType = analyzeExpression(varDecl.initializer);
        }
        
        if (varDecl.varType && valueType) {
            if (!varDecl.varType.equals(valueType)) {
                throw new SemanticError("Type mismatch in variable declaration for '" ~ varDecl.name ~ "'");
            }
        }
        
        LCType finalType = varDecl.varType ? varDecl.varType : valueType;
        if (!finalType) {
            throw new SemanticError("Cannot infer type for variable '" ~ varDecl.name ~ "'");
        }
        
        variables[varDecl.name] = finalType;
    }
    
    private void analyzeAssignment(Assignment assignment) {
        if (assignment.name !in variables) {
            throw new SemanticError("Undefined variable '" ~ assignment.name ~ "'");
        }
        
        LCType valueType = analyzeExpression(assignment.value);
        LCType varType = variables[assignment.name];
        
        if (!varType.equals(valueType)) {
            throw new SemanticError("Type mismatch in assignment to '" ~ assignment.name ~ "'");
        }
    }
    
    private void analyzeArrayAssignment(ArrayAssignment arrayAssign) {
        // For now, assume array is an Identifier (simple variable)
        auto arrayId = cast(Identifier)arrayAssign.array;
        if (!arrayId) {
            throw new SemanticError("Complex array expressions not yet supported");
        }
        
        if (arrayId.name !in variables) {
            throw new SemanticError("Undefined array '" ~ arrayId.name ~ "'");
        }
        
        LCType arrayType = variables[arrayId.name];
        auto arrType = cast(ArrayType)arrayType;
        if (!arrType) {
            throw new SemanticError("Variable '" ~ arrayId.name ~ "' is not an array");
        }
        
        LCType indexType = analyzeExpression(arrayAssign.index);
        if (!cast(NumType)indexType) {
            throw new SemanticError("Array index must be a number");
        }
        
        LCType valueType = analyzeExpression(arrayAssign.value);
        if (!arrType.elementType.equals(valueType)) {
            throw new SemanticError("Type mismatch in array assignment");
        }
    }
    
    private void analyzeFunctionCall(FunctionCall funcCall) {
        if (funcCall.name !in functions) {
            throw new SemanticError("Undefined function '" ~ funcCall.name ~ "'");
        }
        
        FunctionType funcType = functions[funcCall.name];
        
        if (funcCall.arguments.length != funcType.parameterTypes.length) {
            throw new SemanticError("Function '" ~ funcCall.name ~ "' expects " ~ 
                                  to!string(funcType.parameterTypes.length) ~ " arguments, got " ~ 
                                  to!string(funcCall.arguments.length));
        }
        
        for (size_t i = 0; i < funcCall.arguments.length; i++) {
            LCType argType = analyzeExpression(funcCall.arguments[i]);
            if (!funcType.parameterTypes[i].equals(argType)) {
                string msg = "Argument " ~ to!string(i + 1) ~ " type mismatch in call to '" ~ funcCall.name ~ "'";
                throw new SemanticError(msg);
            }
        }
    }
    
    private void analyzeFunctionDeclaration(FunctionDeclaration funcDecl) {
        // Analyze function body in new scope
        auto oldVars = variables.dup;
        
        // Add parameters to scope
        foreach (param; funcDecl.parameters) {
            variables[param.name] = param.type;
        }
        
        foreach (statement; funcDecl.body) {
            analyzeStatement(statement);
        }
        
        // Restore previous scope
        variables = oldVars;
    }
    
    private void analyzeReturnStatement(ReturnStatement returnStmt) {
        if (returnStmt.value) {
            analyzeExpression(returnStmt.value);
        }
    }
    
    private void analyzeIfStatement(IfStatement ifStmt) {
        LCType condType = analyzeExpression(ifStmt.condition);
        if (!cast(BoolType)condType) {
            throw new SemanticError("If condition must be a boolean");
        }
        
        foreach (statement; ifStmt.thenBody) {
            analyzeStatement(statement);
        }
        
        if (ifStmt.elseBody) {
            foreach (statement; ifStmt.elseBody) {
                analyzeStatement(statement);
            }
        }
    }

    
    private void analyzeForStatement(ForStatement forStmt) {
        // Analyze for loop components
        if (forStmt.initialization) {
            analyzeStatement(forStmt.initialization);
        }
        
        if (forStmt.condition) {
            LCType condType = analyzeExpression(forStmt.condition);
            if (!cast(BoolType)condType) {
                throw new SemanticError("For loop condition must be a boolean");
            }
        }
        
        if (forStmt.increment) {
            analyzeStatement(forStmt.increment);
        }
        
        foreach (statement; forStmt.body) {
            analyzeStatement(statement);
        }
    }
    
    private void analyzeRepeatStatement(RepeatStatement repeatStmt) {
        // Analyze the expression to switch on
        LCType exprType = analyzeExpression(repeatStmt.expression);
        
        // Analyze each when case
        foreach (whenCase; repeatStmt.whenCases) {
            // Check that the case value is compatible with the expression type
            LCType caseType = analyzeExpression(whenCase.value);
            if (!exprType.equals(caseType)) {
                throw new SemanticError("Case value type does not match repeat expression type");
            }
            
            // Analyze the statements in this case
            foreach (statement; whenCase.body) {
                analyzeStatement(statement);
            }
        }
        
        // Analyze the fixed (default) case if present
        foreach (statement; repeatStmt.fixedBody) {
            analyzeStatement(statement);
        }
    }
    
    private LCType analyzeExpression(ASTNode expr) {
        if (auto literal = cast(NumberLiteral)expr) {
            return new NumType();
        } else if (auto literal = cast(TextLiteral)expr) {
            return new TextType();
        } else if (auto literal = cast(CharLiteral)expr) {
            return new CharType();
        } else if (auto literal = cast(BoolLiteral)expr) {
            return new BoolType();
        } else if (auto literal = cast(NullLiteral)expr) {
            return new NullType();
        } else if (auto strInterp = cast(StringInterpolation)expr) {
            return analyzeStringInterpolation(strInterp);
        } else if (auto strConcat = cast(StringConcatenation)expr) {
            return analyzeStringConcatenation(strConcat);
        } else if (auto arrayLit = cast(ArrayLiteral)expr) {
            return analyzeArrayLiteral(arrayLit);
        } else if (auto variable = cast(Identifier)expr) {
            if (variable.name !in variables) {
                throw new SemanticError("Undefined variable '" ~ variable.name ~ "'");
            }
            return variables[variable.name];
        } else if (auto arrayAccess = cast(ArrayAccess)expr) {
            return analyzeArrayAccess(arrayAccess);
        } else if (auto memberAccess = cast(MemberAccess)expr) {
            return analyzeMemberAccess(memberAccess);
        } else if (auto structLit = cast(StructLiteral)expr) {
            return analyzeStructLiteral(structLit);
        } else if (auto funcCall = cast(FunctionCall)expr) {
            analyzeFunctionCall(funcCall);
            return functions[funcCall.name].returnType;
        } else if (auto binOp = cast(BinaryOp)expr) {
            return analyzeBinaryOperation(binOp);
        } else if (auto unOp = cast(UnaryOp)expr) {
            return analyzeUnaryOperation(unOp);
        }
        
        throw new SemanticError("Unknown expression type");
    }
    
    private LCType analyzeArrayLiteral(ArrayLiteral arrayLit) {
        if (arrayLit.elements.length == 0) {
            throw new SemanticError("Cannot infer type of empty array literal");
        }
        
        LCType elementType = analyzeExpression(arrayLit.elements[0]);
        
        foreach (i, element; arrayLit.elements[1..$]) {
            LCType elemType = analyzeExpression(element);
            if (!elementType.equals(elemType)) {
                throw new SemanticError("All array elements must have the same type");
            }
        }
        
        return new ArrayType(elementType, cast(int)arrayLit.elements.length);
    }
    
    private LCType analyzeStringInterpolation(StringInterpolation strInterp) {
        // Analyze all embedded expressions
        foreach (expr; strInterp.expressions) {
            analyzeExpression(expr);
        }
        // String interpolation always results in a text type
        return new TextType();
    }
    
    private LCType analyzeStringConcatenation(StringConcatenation strConcat) {
        // Analyze both operands
        LCType leftType = analyzeExpression(strConcat.left);
        LCType rightType = analyzeExpression(strConcat.right);
        
        // String concatenation (+>>) allows text, numeric, boolean, and char types
        // All non-text types will be automatically converted to string at runtime
        bool leftValid = cast(TextType)leftType || cast(NumType)leftType || 
                        cast(BoolType)leftType || cast(CharType)leftType;
        bool rightValid = cast(TextType)rightType || cast(NumType)rightType || 
                         cast(BoolType)rightType || cast(CharType)rightType;
        
        if (!leftValid || !rightValid) {
            throw new SemanticError("String concatenation (+>>) requires text, numeric, boolean, or char operands");
        }
        
        // String concatenation always results in a text type
        return new TextType();
    }
    
    private LCType analyzeArrayAccess(ArrayAccess arrayAccess) {
        // For now, assume array is an Identifier (simple variable)
        auto arrayId = cast(Identifier)arrayAccess.array;
        if (!arrayId) {
            throw new SemanticError("Complex array expressions not yet supported");
        }
        
        if (arrayId.name !in variables) {
            throw new SemanticError("Undefined array '" ~ arrayId.name ~ "'");
        }
        
        LCType arrayType = variables[arrayId.name];
        auto arrType = cast(ArrayType)arrayType;
        if (!arrType) {
            throw new SemanticError("Variable '" ~ arrayId.name ~ "' is not an array");
        }
        
        LCType indexType = analyzeExpression(arrayAccess.index);
        if (!cast(NumType)indexType) {
            throw new SemanticError("Array index must be a number");
        }
        
        return arrType.elementType;
    }
    
    private LCType analyzeBinaryOperation(BinaryOp binOp) {
        LCType leftType = analyzeExpression(binOp.left);
        LCType rightType = analyzeExpression(binOp.right);
        
        switch (binOp.operator) {
            case "+":
                // Handle numeric addition only (string concatenation uses +>> now)
                if (cast(NumType)leftType && cast(NumType)rightType) {
                    return new NumType();
                } else {
                    throw new SemanticError("Addition (+) requires numeric operands. Use +>> for concatenation.");
                }
                
            case "-", "*", "/", "%":
                if (!cast(NumType)leftType || !cast(NumType)rightType) {
                    throw new SemanticError("Arithmetic operations require numeric operands");
                }
                return new NumType();
                
            case "==", "!=", "<", ">", "<=", ">=":
                if (!leftType.equals(rightType)) {
                    throw new SemanticError("Comparison requires operands of the same type");
                }
                return new BoolType();
                
            case "&&", "||":
                if (!cast(BoolType)leftType || !cast(BoolType)rightType) {
                    throw new SemanticError("Logical operations require boolean operands");
                }
                return new BoolType();
                
            default:
                throw new SemanticError("Unknown binary operator: " ~ binOp.operator);
        }
    }
    
    private LCType analyzeUnaryOperation(UnaryOp unOp) {
        LCType operandType = analyzeExpression(unOp.operand);
        
        switch (unOp.operator) {
            case "-":
                if (!cast(NumType)operandType) {
                    throw new SemanticError("Unary minus requires numeric operand");
                }
                return new NumType();
                
            case "!":
                if (!cast(BoolType)operandType) {
                    throw new SemanticError("Logical NOT requires boolean operand");
                }
                return new BoolType();
                
            default:
                throw new SemanticError("Unknown unary operator: " ~ unOp.operator);
        }
    }
    
    private void analyzeMemberAssignment(MemberAssignment memberAssign) {
        LCType objectType = analyzeExpression(memberAssign.object);
        
        if (auto structType = cast(StructType)objectType) {
            if (!structType.hasField(memberAssign.memberName)) {
                throw new SemanticError(
                    "Struct '" ~ structType.name ~ "' has no field '" ~ memberAssign.memberName ~ "'"
                );
            }
            
            LCType fieldType = structType.getFieldType(memberAssign.memberName);
            LCType valueType = analyzeExpression(memberAssign.value);
            
            if (!fieldType.canAssignFrom(valueType)) {
                throw new SemanticError("Cannot assign " ~ valueType.toString() ~ " to " ~ fieldType.toString());
            }
        } else {
            throw new SemanticError(
                "Cannot access member '" ~ memberAssign.memberName ~ 
                "' on non-struct type " ~ objectType.toString()
            );
        }
    }
    
    private LCType analyzeMemberAccess(MemberAccess memberAccess) {
        LCType objectType = analyzeExpression(memberAccess.object);
        
        if (auto structType = cast(StructType)objectType) {
            if (!structType.hasField(memberAccess.memberName)) {
                throw new SemanticError(
                    "Struct '" ~ structType.name ~ "' has no field '" ~ memberAccess.memberName ~ "'"
                );
            }
            
            LCType fieldType = structType.getFieldType(memberAccess.memberName);
            memberAccess.type = fieldType;
            return fieldType;
        } else {
            throw new SemanticError(
                "Cannot access member '" ~ memberAccess.memberName ~ 
                "' on non-struct type " ~ objectType.toString()
            );
        }
    }
    
    private LCType analyzeStructLiteral(StructLiteral structLit) {
        StructType structType = getStructType(structLit.typeName);
        if (structType is null) {
            throw new SemanticError("Unknown struct type '" ~ structLit.typeName ~ "'");
        }
        
        // Check that all required fields are provided
        if (structLit.fieldNames.length != structType.fields.length) {
            throw new SemanticError("Struct literal must initialize all fields");
        }
        
        // Check field names and types
        for (size_t i = 0; i < structLit.fieldNames.length; i++) {
            string fieldName = structLit.fieldNames[i];
            Expression fieldValue = structLit.fieldValues[i];
            
            if (!structType.hasField(fieldName)) {
                throw new SemanticError("Struct '" ~ structLit.typeName ~ "' has no field '" ~ fieldName ~ "'");
            }
            
            LCType expectedType = structType.getFieldType(fieldName);
            LCType actualType = analyzeExpression(fieldValue);
            
            if (!expectedType.canAssignFrom(actualType)) {
                throw new SemanticError(
                    "Cannot assign " ~ actualType.toString() ~
                    " to field '" ~ fieldName ~
                    "' of type " ~ expectedType.toString()
                );
            }
        }
        
        structLit.type = structType;
        return structType;
    }
}

