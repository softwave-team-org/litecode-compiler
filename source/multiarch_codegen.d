module multiarch_codegen;

import ast;
import types;
import platform;
import std.stdio;
import std.conv;
import std.string;
import std.file;
import std.process;

abstract class ArchCodeGenerator {
    protected string[] code;
    protected string[] dataSection;
    protected int labelCounter;
    protected string[string] stringLiterals;
    protected int stackOffset;
    protected string[string] variables;
    protected string[string] functions;
    protected bool inFunction;
    
    // Compile-time constants table
    protected struct ConstantValue {
        double numValue;
        string textValue;
        char charValue;
        bool boolValue;
        string type; // "num", "text", "char", "bool"
    }
    protected ConstantValue[string] constants;
    
    this() {
        labelCounter = 0;
        stackOffset = 0;
        inFunction = false;
    }
    
    abstract string generateCode(Program program);
    abstract void generateExpression(Expression expr);
    abstract void generateStatement(Statement stmt);
    abstract void generateFunction(FunctionDeclaration func);
    abstract void generateRunBlock(RunBlock runBlock);
    abstract void addSystemCallHelpers();
    
    protected string getStringLabel(string str) {
        if (str !in stringLiterals) {
            string label = "str_" ~ to!string(stringLiterals.length);
            stringLiterals[str] = label;
            dataSection ~= label ~ ": .asciz \"" ~ escapeString(str) ~ "\"";
        }
        return stringLiterals[str];
    }
    
    protected string escapeString(string str) {
        string result = "";
        foreach (char c; str) {
            switch (c) {
                case '\n': result ~= "\\n"; break;
                case '\t': result ~= "\\t"; break;
                case '\r': result ~= "\\r"; break;
                case '\\': result ~= "\\\\"; break;
                case '"': result ~= "\\\""; break;
                default: result ~= c; break;
            }
        }
        return result;
    }
}

// X86_64 Code Generator
class X86_64CodeGenerator : ArchCodeGenerator {
    override string generateCode(Program program) {
        code ~= ".section .data";
        
        code ~= "";
        code ~= ".section .text";
        code ~= ".global _start";
        
        foreach (func; program.functions) {
            generateFunction(func);
        }
        
        generateRunBlock(program.runBlock);
        addSystemCallHelpers();
        
        if (dataSection.length > 0) {
            code ~= "";
            code ~= ".section .data";
            code ~= dataSection;
        }
        
        return join(code, "\n");
    }
    
    override void generateFunction(FunctionDeclaration func) {
        // Use function name directly without prefix for proper linking
        functions[func.name] = func.name;
        
        code ~= "";
        code ~= func.name ~ ":";
        code ~= "    pushq %rbp";
        code ~= "    movq %rsp, %rbp";
        
        bool oldInFunction = inFunction;
        int oldStackOffset = stackOffset;
        string[string] oldVariables = variables.dup;
        
        inFunction = true;
        stackOffset = 0;
        
        // Parameters are passed in registers, copy to stack
        foreach (i, param; func.parameters) {
            stackOffset -= 8;
            variables[param.name] = to!string(stackOffset);
            // Copy parameter from register to stack
            switch (i) {
                case 0: code ~= "    movq %rdi, " ~ to!string(stackOffset) ~ "(%rbp)"; break;
                case 1: code ~= "    movq %rsi, " ~ to!string(stackOffset) ~ "(%rbp)"; break;
                case 2: code ~= "    movq %rdx, " ~ to!string(stackOffset) ~ "(%rbp)"; break;
                case 3: code ~= "    movq %rcx, " ~ to!string(stackOffset) ~ "(%rbp)"; break;
                case 4: code ~= "    movq %r8, " ~ to!string(stackOffset) ~ "(%rbp)"; break;
                case 5: code ~= "    movq %r9, " ~ to!string(stackOffset) ~ "(%rbp)"; break;
                default: break; // Additional parameters would be on stack
            }
        }
        
        foreach (stmt; func.body) {
            generateStatement(stmt);
        }
        
        // Default return value of 0 if no explicit return
        if (!inFunction || true) { // Always add default return
            code ~= "    movq $0, %rax";
        }
        
        code ~= "    movq %rbp, %rsp";
        code ~= "    popq %rbp";
        code ~= "    ret";
        
        inFunction = oldInFunction;
        stackOffset = oldStackOffset;
        variables = oldVariables;
    }
    
    override void generateRunBlock(RunBlock runBlock) {
        code ~= "";
        code ~= "_start:";
        code ~= "    pushq %rbp";
        code ~= "    movq %rsp, %rbp";
        
        foreach (stmt; runBlock.statements) {
            generateStatement(stmt);
        }
        
        code ~= "    movq $60, %rax    # sys_exit";
        code ~= "    movq $0, %rdi     # exit status";
        code ~= "    syscall";
    }
    
    override void generateStatement(Statement stmt) {
        if (auto varDecl = cast(VarDeclaration)stmt) {
            if (varDecl.isCompileTimeConstant && varDecl.initializer) {
                // Store compile-time constant value, don't allocate stack space
                ConstantValue constVal;
                
                if (auto numLit = cast(NumberLiteral)varDecl.initializer) {
                    constVal.numValue = numLit.value;
                    constVal.type = "num";
                } else if (auto textLit = cast(TextLiteral)varDecl.initializer) {
                    constVal.textValue = textLit.value;
                    constVal.type = "text";
                } else if (auto charLit = cast(CharLiteral)varDecl.initializer) {
                    constVal.charValue = charLit.value;
                    constVal.type = "char";
                } else if (auto boolLit = cast(BoolLiteral)varDecl.initializer) {
                    constVal.boolValue = boolLit.value;
                    constVal.type = "bool";
                }
                
                constants[varDecl.name] = constVal;
            } else {
                stackOffset -= 8;
                variables[varDecl.name] = to!string(stackOffset);
                
                if (varDecl.initializer) {
                    generateExpression(varDecl.initializer);
                    code ~= "    movq %rax, " ~ to!string(stackOffset) ~ "(%rbp)";
                }
            }
        } else if (auto assignment = cast(Assignment)stmt) {
            generateExpression(assignment.value);
            string offset = variables[assignment.name];
            code ~= "    movq %rax, " ~ offset ~ "(%rbp)";
        } else if (auto exprStmt = cast(ExpressionStatement)stmt) {
            generateExpression(exprStmt.expression);
        } else if (auto retStmt = cast(ReturnStatement)stmt) {
            if (retStmt.value) {
                generateExpression(retStmt.value);
            }
            // Return value is already in %rax
            code ~= "    movq %rbp, %rsp";
            code ~= "    popq %rbp";
            code ~= "    ret";
        } else if (auto repeatStmt = cast(RepeatStatement)stmt) {
            generateRepeatStatement(repeatStmt);
        }
    }
    
    override void generateExpression(Expression expr) {
        if (auto numLit = cast(NumberLiteral)expr) {
            long value = cast(long)numLit.value;
            code ~= "    movq $" ~ to!string(value) ~ ", %rax";
        } else if (auto textLit = cast(TextLiteral)expr) {
            string label = getStringLabel(textLit.value);
            code ~= "    movq $" ~ label ~ ", %rax";
        } else if (auto charLit = cast(CharLiteral)expr) {
            code ~= "    movq $" ~ to!string(cast(int)charLit.value) ~ ", %rax";
        } else if (auto boolLit = cast(BoolLiteral)expr) {
            code ~= "    movq $" ~ (boolLit.value ? "1" : "0") ~ ", %rax";
        } else if (auto nullLit = cast(NullLiteral)expr) {
            code ~= "    movq $0, %rax";
        } else if (auto ident = cast(Identifier)expr) {
            // Check if it's a compile-time constant first
            if (ident.name in constants) {
                ConstantValue constVal = constants[ident.name];
                switch (constVal.type) {
                    case "num":
                        code ~= "    movq $" ~ to!string(cast(long)constVal.numValue) ~ ", %rax";
                        break;
                    case "text":
                        string label = getStringLabel(constVal.textValue);
                        code ~= "    movq $" ~ label ~ ", %rax";
                        break;
                    case "char":
                        code ~= "    movq $" ~ to!string(cast(int)constVal.charValue) ~ ", %rax";
                        break;
                    case "bool":
                        code ~= "    movq $" ~ (constVal.boolValue ? "1" : "0") ~ ", %rax";
                        break;
                    default:
                        break;
                }
            } else {
                string offset = variables[ident.name];
                code ~= "    movq " ~ offset ~ "(%rbp), %rax";
            }
        } else if (auto binOp = cast(BinaryOp)expr) {
            generateBinaryOp(binOp);
        } else if (auto funcCall = cast(FunctionCall)expr) {
            generateFunctionCall(funcCall);
        } else if (auto strInterp = cast(StringInterpolation)expr) {
            generateStringInterpolation(strInterp);
        } else if (auto strConcat = cast(StringConcatenation)expr) {
            generateStringConcatenation(strConcat);
        }
    }
    
    void generateBinaryOp(BinaryOp binOp) {
        // Generate left operand
        generateExpression(binOp.left);
        code ~= "    pushq %rax";
        
        // Generate right operand
        generateExpression(binOp.right);
        code ~= "    movq %rax, %rbx";
        code ~= "    popq %rax";
        
        // Perform operation
        switch (binOp.operator) {
            case "+":
                code ~= "    addq %rbx, %rax";
                break;
            case "-":
                code ~= "    subq %rbx, %rax";
                break;
            case "*":
                code ~= "    imulq %rbx, %rax";
                break;
            case "/":
                code ~= "    cqto";           // Sign extend %rax to %rdx:%rax
                code ~= "    idivq %rbx";     // Divide %rdx:%rax by %rbx
                break;
            case "%":
                code ~= "    cqto";
                code ~= "    idivq %rbx";
                code ~= "    movq %rdx, %rax"; // Remainder is in %rdx
                break;
            case "==":
                code ~= "    cmpq %rbx, %rax";
                code ~= "    sete %al";
                code ~= "    movzbq %al, %rax";
                break;
            case "!=":
                code ~= "    cmpq %rbx, %rax";
                code ~= "    setne %al";
                code ~= "    movzbq %al, %rax";
                break;
            case "<":
                code ~= "    cmpq %rbx, %rax";
                code ~= "    setl %al";
                code ~= "    movzbq %al, %rax";
                break;
            case "<=":
                code ~= "    cmpq %rbx, %rax";
                code ~= "    setle %al";
                code ~= "    movzbq %al, %rax";
                break;
            case ">":
                code ~= "    cmpq %rbx, %rax";
                code ~= "    setg %al";
                code ~= "    movzbq %al, %rax";
                break;
            case ">=":
                code ~= "    cmpq %rbx, %rax";
                code ~= "    setge %al";
                code ~= "    movzbq %al, %rax";
                break;
            default:
                break;
        }
    }
    
    void generateFunctionCall(FunctionCall funcCall) {
        // Handle built-in functions
        if (funcCall.name == "print") {
            generatePrintCall(funcCall);
            return;
        }
        
        if (funcCall.name == "read") {
            generateReadCall(funcCall);
            return;
        }
        
        // Handle type-specific read functions
        if (funcCall.name == "num.read") {
            generateTypeReadCall(funcCall, "num");
            return;
        }
        
        if (funcCall.name == "text.read") {
            generateTypeReadCall(funcCall, "text");
            return;
        }
        
        if (funcCall.name == "char.read") {
            generateTypeReadCall(funcCall, "char");
            return;
        }
        
        if (funcCall.name == "bool.read") {
            generateTypeReadCall(funcCall, "bool");
            return;
        }
        
        // Regular function call
        // Save caller-saved registers
        code ~= "    pushq %rcx";
        code ~= "    pushq %rdx";
        code ~= "    pushq %rsi";
        code ~= "    pushq %rdi";
        code ~= "    pushq %r8";
        code ~= "    pushq %r9";
        code ~= "    pushq %r10";
        code ~= "    pushq %r11";
        
        // Pass arguments (simplified - assumes all arguments fit in registers)
        foreach_reverse (i, arg; funcCall.arguments) {
            generateExpression(arg);
            switch (i) {
                case 0: code ~= "    movq %rax, %rdi"; break;
                case 1: code ~= "    movq %rax, %rsi"; break;
                case 2: code ~= "    movq %rax, %rdx"; break;
                case 3: code ~= "    movq %rax, %rcx"; break;
                case 4: code ~= "    movq %rax, %r8"; break;
                case 5: code ~= "    movq %rax, %r9"; break;
                default:
                    // Push to stack for additional arguments
                    code ~= "    pushq %rax";
                    break;
            }
        }
        
        // Call function
        code ~= "    call " ~ funcCall.name;
        
        // Clean up stack for additional arguments
        if (funcCall.arguments.length > 6) {
            long stackCleanup = cast(long)funcCall.arguments.length * 8 - 48;  // 6 * 8 = 48
            code ~= "    addq $" ~ to!string(stackCleanup) ~ ", %rsp";
        }
        
        // Restore caller-saved registers
        code ~= "    popq %r11";
        code ~= "    popq %r10";
        code ~= "    popq %r9";
        code ~= "    popq %r8";
        code ~= "    popq %rdi";
        code ~= "    popq %rsi";
        code ~= "    popq %rdx";
        code ~= "    popq %rcx";
    }
    
    void generatePrintCall(FunctionCall funcCall) {
        // Generate the expression and determine its type at compile time
        Expression arg = funcCall.arguments[0];
        
        if (auto numLit = cast(NumberLiteral)arg) {
            // Number literal - convert to string then print
            generateExpression(arg);
            code ~= "    movq %rax, %rdi";
            code ~= "    call num_to_string";
            code ~= "    movq %rax, %rdi";
            code ~= "    call print_string";
        } else if (auto textLit = cast(TextLiteral)arg) {
            // Text literal - print directly as string
            generateExpression(arg);
            code ~= "    movq %rax, %rdi";
            code ~= "    call print_string";
        } else if (auto charLit = cast(CharLiteral)arg) {
            // Character literal - convert to string then print
            generateExpression(arg);
            code ~= "    movq %rax, %rdi";
            code ~= "    call char_to_string";
            code ~= "    movq %rax, %rdi";
            code ~= "    call print_string";
        } else if (auto boolLit = cast(BoolLiteral)arg) {
            // Boolean literal - convert to string then print
            generateExpression(arg);
            code ~= "    movq %rax, %rdi";
            code ~= "    call bool_to_string";
            code ~= "    movq %rax, %rdi";
            code ~= "    call print_string";
        } else if (auto ident = cast(Identifier)arg) {
            // Variable - check if it's a compile-time constant first
            if (ident.name in constants) {
                ConstantValue constVal = constants[ident.name];
                switch (constVal.type) {
                    case "num":
                        generateExpression(arg);
                        code ~= "    movq %rax, %rdi";
                        code ~= "    call num_to_string";
                        code ~= "    movq %rax, %rdi";
                        code ~= "    call print_string";
                        break;
                    case "text":
                        generateExpression(arg);
                        code ~= "    movq %rax, %rdi";
                        code ~= "    call print_string";
                        break;
                    case "char":
                        generateExpression(arg);
                        code ~= "    movq %rax, %rdi";
                        code ~= "    call char_to_string";
                        code ~= "    movq %rax, %rdi";
                        code ~= "    call print_string";
                        break;
                    case "bool":
                        generateExpression(arg);
                        code ~= "    movq %rax, %rdi";
                        code ~= "    call bool_to_string";
                        code ~= "    movq %rax, %rdi";
                        code ~= "    call print_string";
                        break;
                    default:
                        break;
                }
            } else {
                // Runtime variable - use auto detection
                generateExpression(arg);
                code ~= "    movq %rax, %rdi";
                code ~= "    call print_value_auto";
            }
        } else {
            // Complex expressions (function calls, binary ops, etc.) - use auto detection
            generateExpression(arg);
            code ~= "    movq %rax, %rdi";
            code ~= "    call print_value_auto";
        }
    }
    
    void generateReadCall(FunctionCall funcCall) {
        // Print prompt if provided
        if (funcCall.arguments.length > 0) {
            generateExpression(funcCall.arguments[0]);
            code ~= "    movq %rax, %rdi";
            code ~= "    call print_string";
        }
        
        // Call read function to get user input
        code ~= "    call read_string";
        // Result will be in %rax (pointer to input string)
    }
    
    void generateTypeReadCall(FunctionCall funcCall, string typeName) {
        // Print prompt if provided
        if (funcCall.arguments.length > 0) {
            generateExpression(funcCall.arguments[0]);
            code ~= "    movq %rax, %rdi";
            code ~= "    call print_string";
        }
        
        // Call read function to get user input
        code ~= "    call read_string";
        
        // Convert to the appropriate type and handle defaults
        switch(typeName) {
            case "num":
                // Try to convert string to number, default to 0 on error
                code ~= "    movq %rax, %rdi";
                code ~= "    call string_to_num";
                break;
            case "text":
                // Already a string, no conversion needed
                break;
            case "char":
                // Get first character, default to '\\0' if empty
                code ~= "    movq %rax, %rdi";
                code ~= "    call string_to_char";
                break;
            case "bool":
                // Convert to boolean (true/false), default to false
                code ~= "    movq %rax, %rdi";
                code ~= "    call string_to_bool";
                break;
            default:
                // Fallback to string
                break;
        }
        // Result will be in %rax
    }
    
    void generateStringInterpolation(StringInterpolation strInterp) {
        // Call runtime string interpolation function
        code ~= "    # String interpolation with " ~ to!string(strInterp.expressions.length) ~ " expressions";
        
        // Push parts count and expressions count
        code ~= "    pushq $" ~ to!string(strInterp.parts.length);
        code ~= "    pushq $" ~ to!string(strInterp.expressions.length);
        
        // Push all string parts (in reverse order for stack)
        for (int i = cast(int)strInterp.parts.length - 1; i >= 0; i--) {
            string label = getStringLabel(strInterp.parts[i]);
            code ~= "    pushq $" ~ label;
        }
        
        // Push all expression values and their format specifiers
        for (int i = cast(int)strInterp.expressions.length - 1; i >= 0; i--) {
            // Generate expression value
            generateExpression(strInterp.expressions[i]);
            code ~= "    pushq %rax";
            
            // Push format specifier (default to empty string if not specified)
            string formatSpec = (i < strInterp.formatSpecifiers.length) ? 
                              strInterp.formatSpecifiers[i] : "";
            string formatLabel = getStringLabel(formatSpec);
            code ~= "    pushq $" ~ formatLabel;
        }
        
        // Call string interpolation runtime function
        code ~= "    call string_interpolate";
        
        // Clean up stack - total items pushed:
        // 2 (counts) + parts.length + expressions.length * 2 (value + format)
        int stackCleanup = (2 + cast(int)strInterp.parts.length + cast(int)strInterp.expressions.length * 2) * 8;
        code ~= "    addq $" ~ to!string(stackCleanup) ~ ", %rsp";
        
        // Result string pointer is in %rax
    }
    
    void generateStringConcatenation(StringConcatenation strConcat) {
        // Generate left operand 
        generateExpression(strConcat.left);
        
        // Check if left operand is a number literal and convert it
        if (auto numLit = cast(NumberLiteral)strConcat.left) {
            // It's a number literal, convert to string
            code ~= "    movq %rax, %rdi";
            code ~= "    call num_to_string";
        } else if (auto charLit = cast(CharLiteral)strConcat.left) {
            // It's a character literal, convert to string
            code ~= "    movq %rax, %rdi";
            code ~= "    call char_to_string";
        } else if (auto boolLit = cast(BoolLiteral)strConcat.left) {
            // It's a boolean literal, convert to string
            code ~= "    movq %rax, %rdi";
            code ~= "    call bool_to_string";
        }
        // Text literals and string variables are already strings - no conversion needed
        
        code ~= "    pushq %rax";
        
        // Generate right operand
        generateExpression(strConcat.right);
        
        // Check if right operand is a number literal and convert it
        if (auto numLit = cast(NumberLiteral)strConcat.right) {
            // It's a number literal, convert to string
            code ~= "    movq %rax, %rdi";
            code ~= "    call num_to_string";
        } else if (auto charLit = cast(CharLiteral)strConcat.right) {
            // It's a character literal, convert to string
            code ~= "    movq %rax, %rdi";
            code ~= "    call char_to_string";
        } else if (auto boolLit = cast(BoolLiteral)strConcat.right) {
            // It's a boolean literal, convert to string
            code ~= "    movq %rax, %rdi";
            code ~= "    call bool_to_string";
        } else if (auto ident = cast(Identifier)strConcat.right) {
            // Variable - check if it's a compile-time constant first
            if (ident.name in constants) {
                ConstantValue constVal = constants[ident.name];
                if (constVal.type == "num") {
                    code ~= "    movq %rax, %rdi";
                    code ~= "    call num_to_string";
                } else if (constVal.type == "char") {
                    code ~= "    movq %rax, %rdi";
                    code ~= "    call char_to_string";
                } else if (constVal.type == "bool") {
                    code ~= "    movq %rax, %rdi";
                    code ~= "    call bool_to_string";
                }
                // text constants are already strings
            } else {
                // Runtime variable - assume it's a number for now (simplified)
                code ~= "    movq %rax, %rdi";
                code ~= "    call num_to_string";
            }
        }
        // Text literals and string variables are already strings - no conversion needed
        
        code ~= "    movq %rax, %rsi";      // right string in %rsi
        code ~= "    popq %rdi";            // left string in %rdi
        
        // Call regular string concatenation
        code ~= "    call string_concat";
        
        // Result string pointer is in %rax
    }
    
    override void addSystemCallHelpers() {
        code ~= "";
        code ~= "print_string:";
        code ~= "    pushq %rbp";
        code ~= "    movq %rsp, %rbp";
        code ~= "    # String address is in %rdi, need to get length first";
        code ~= "    call strlen          # get string length, %rdi preserved";
        code ~= "    movq %rax, %rdx      # length in %rdx";
        code ~= "    movq %rdi, %rsi      # string address in %rsi";
        code ~= "    movq $1, %rax        # sys_write";
        code ~= "    movq $1, %rdi        # stdout in %rdi";
        code ~= "    syscall";
        code ~= "    popq %rbp";
        code ~= "    ret";
        
        code ~= "";
        code ~= "read_string:";
        code ~= "    pushq %rbp";
        code ~= "    movq %rsp, %rbp";
        code ~= "    # Read from stdin to input_buffer";
        code ~= "    movq $0, %rax        # sys_read";
        code ~= "    movq $0, %rdi        # stdin";
        code ~= "    movq $input_buffer, %rsi";
        code ~= "    movq $255, %rdx      # max length";
        code ~= "    syscall";
        code ~= "    # Remove newline if present";
        code ~= "    movq $input_buffer, %rdi";
        code ~= "    call remove_newline";
        code ~= "    movq $input_buffer, %rax  # return pointer to buffer";
        code ~= "    popq %rbp";
        code ~= "    ret";
        
        code ~= "";
        code ~= "remove_newline:";
        code ~= "    pushq %rbp";
        code ~= "    movq %rsp, %rbp";
        code ~= "    movq %rdi, %rsi      # copy string pointer";
        code ~= "find_newline:";
        code ~= "    movb (%rsi), %al     # load current character";
        code ~= "    cmpb $0, %al         # check for null terminator";
        code ~= "    je done_newline      # if null, we're done";
        code ~= "    cmpb $10, %al        # check for newline (\\n)";
        code ~= "    je replace_newline   # if newline, replace it";
        code ~= "    incq %rsi            # move to next character";
        code ~= "    jmp find_newline";
        code ~= "replace_newline:";
        code ~= "    movb $0, (%rsi)      # replace newline with null";
        code ~= "done_newline:";
        code ~= "    popq %rbp";
        code ~= "    ret";
        
        code ~= "";
        code ~= "strlen:";
        code ~= "    movq $0, %rax";
        code ~= "strlen_loop:";
        code ~= "    cmpb $0, (%rdi,%rax)";
        code ~= "    je strlen_done";
        code ~= "    incq %rax";
        code ~= "    jmp strlen_loop";
        code ~= "strlen_done:";
        code ~= "    ret";
        
        // String to number conversion
        code ~= "";
        code ~= "string_to_num:";
        code ~= "    pushq %rbp";
        code ~= "    movq %rsp, %rbp";
        code ~= "    movq $0, %rax        # result accumulator";
        code ~= "    movq $0, %rcx        # sign flag (0 = positive, 1 = negative)";
        code ~= "    movq %rdi, %rsi      # string pointer";
        code ~= "    # Skip whitespace";
        code ~= "skip_ws:";
        code ~= "    movb (%rsi), %dl";
        code ~= "    cmpb $0, %dl         # null terminator";
        code ~= "    je num_default       # empty string, return 0";
        code ~= "    cmpb $32, %dl        # space";
        code ~= "    je next_char";
        code ~= "    cmpb $9, %dl         # tab";
        code ~= "    je next_char";
        code ~= "    cmpb $45, %dl        # minus sign";
        code ~= "    je handle_minus";
        code ~= "    cmpb $43, %dl        # plus sign";
        code ~= "    je handle_plus";
        code ~= "    jmp parse_digits";
        code ~= "next_char:";
        code ~= "    incq %rsi";
        code ~= "    jmp skip_ws";
        code ~= "handle_minus:";
        code ~= "    movq $1, %rcx        # set negative flag";
        code ~= "    incq %rsi";
        code ~= "    jmp parse_digits";
        code ~= "handle_plus:";
        code ~= "    incq %rsi";
        code ~= "parse_digits:";
        code ~= "    movb (%rsi), %dl";
        code ~= "    cmpb $0, %dl         # null terminator";
        code ~= "    je apply_sign";
        code ~= "    cmpb $48, %dl        # '0'";
        code ~= "    jl num_default       # not a digit, return 0";
        code ~= "    cmpb $57, %dl        # '9'";
        code ~= "    jg num_default       # not a digit, return 0";
        code ~= "    subb $48, %dl        # convert ASCII to digit";
        code ~= "    imulq $10, %rax      # multiply by 10";
        code ~= "    addq %rdx, %rax      # add digit";
        code ~= "    incq %rsi";
        code ~= "    jmp parse_digits";
        code ~= "apply_sign:";
        code ~= "    cmpq $1, %rcx        # check if negative";
        code ~= "    jne num_done";
        code ~= "    negq %rax            # make negative";
        code ~= "    jmp num_done";
        code ~= "num_default:";
        code ~= "    movq $0, %rax        # default to 0";
        code ~= "num_done:";
        code ~= "    popq %rbp";
        code ~= "    ret";
        
        // String to character conversion
        code ~= "";
        code ~= "string_to_char:";
        code ~= "    movb (%rdi), %al     # get first character";
        code ~= "    cmpb $0, %al         # check if empty string";
        code ~= "    jne char_done";
        code ~= "    movb $0, %al         # default to null character";
        code ~= "char_done:";
        code ~= "    ret";
        
        // String to boolean conversion
        code ~= "";
        code ~= "string_to_bool:";
        code ~= "    pushq %rbp";
        code ~= "    movq %rsp, %rbp";
        code ~= "    pushq %rdi";
        code ~= "    call strlen";
        code ~= "    popq %rdi";
        code ~= "    cmpq $4, %rax        # check if length is 4 (\"true\")";
        code ~= "    je check_true";
        code ~= "    cmpq $5, %rax        # check if length is 5 (\"false\")";
        code ~= "    je check_false";
        code ~= "    jmp bool_default";
        code ~= "check_true:";
        code ~= "    movl (%rdi), %eax    # load first 4 bytes";
        code ~= "    cmpl $0x65757274, %eax  # \"true\" in little endian";
        code ~= "    je bool_true";
        code ~= "    jmp bool_default";
        code ~= "check_false:";
        code ~= "    movl (%rdi), %eax    # load first 4 bytes";
        code ~= "    cmpl $0x736c6166, %eax  # \"fals\" in little endian";
        code ~= "    jne bool_default";
        code ~= "    movb 4(%rdi), %al    # check 5th byte";
        code ~= "    cmpb $101, %al       # 'e'";
        code ~= "    je bool_false";
        code ~= "    jmp bool_default";
        code ~= "bool_true:";
        code ~= "    movq $1, %rax";
        code ~= "    jmp bool_done";
        code ~= "bool_false:";
        code ~= "    movq $0, %rax";
        code ~= "    jmp bool_done";
        code ~= "bool_default:";
        code ~= "    movq $0, %rax        # default to false";
        code ~= "bool_done:";
        code ~= "    popq %rbp";
        code ~= "    ret";
        
        // String concatenation runtime
        addStringConcatenationRuntime();
        
        // String interpolation runtime
        addStringInterpolationRuntime();
        
        // Value to string conversion functions
        addValueToStringConversion();
        
        code ~= "";
        code ~= ".section .data";
        code ~= "input_buffer: .space 256";
        code ~= "temp_buffer: .space 64     # For number to string conversion";
        code ~= "string_buffer: .space 4096  # For string operations";
    }
    
    private void addStringConcatenationRuntime() {
        code ~= "";
        code ~= "# String concatenation function";
        code ~= "# Input: %rdi = left string, %rsi = right string";  
        code ~= "# Output: %rax = pointer to new concatenated string";
        code ~= "string_concat:";
        code ~= "    pushq %rbp";
        code ~= "    movq %rsp, %rbp";
        code ~= "    pushq %rdi           # save left string";
        code ~= "    pushq %rsi           # save right string";
        
        code ~= "    # Calculate length of left string";
        code ~= "    call strlen";
        code ~= "    movq %rax, %r8       # left length in %r8";
        
        code ~= "    # Calculate length of right string";
        code ~= "    movq -16(%rbp), %rdi # right string from stack";
        code ~= "    call strlen";
        code ~= "    movq %rax, %r9       # right length in %r9";
        
        code ~= "    # Calculate total length (left + right + 1 for null terminator)";
        code ~= "    movq %r8, %r10       # total = left length";
        code ~= "    addq %r9, %r10       # total += right length";
        code ~= "    incq %r10            # total += 1 for null terminator";
        
        code ~= "    # Allocate memory (simple approach: use string_buffer)";
        code ~= "    movq $string_buffer, %rax  # result buffer";
        code ~= "    movq %rax, %r11      # save result pointer";
        
        code ~= "    # Copy left string";
        code ~= "    movq -8(%rbp), %rsi  # left string from stack";
        code ~= "    movq %r8, %rcx       # left length";
        code ~= "    movq %rax, %rdi      # destination";
        code ~= "    call memcpy_simple";
        
        code ~= "    # Copy right string";
        code ~= "    addq %r8, %r11       # advance destination pointer";
        code ~= "    movq %r11, %rdi      # destination";
        code ~= "    movq -16(%rbp), %rsi # right string from stack";
        code ~= "    movq %r9, %rcx       # right length";
        code ~= "    call memcpy_simple";
        
        code ~= "    # Add null terminator";
        code ~= "    addq %r9, %r11       # point to end";
        code ~= "    movb $0, (%r11)      # null terminate";
        
        code ~= "    # Return result pointer";
        code ~= "    movq $string_buffer, %rax";
        code ~= "    addq $16, %rsp       # clean up stack";
        code ~= "    popq %rbp";
        code ~= "    ret";
        
        // Add auto-conversion string concatenation
        code ~= "";
        code ~= "# String concatenation with automatic type conversion";
        code ~= "# Input: %rdi = left value, %rsi = right value";  
        code ~= "# Output: %rax = pointer to new concatenated string";
        code ~= "string_concat_auto:";
        code ~= "    pushq %rbp";
        code ~= "    movq %rsp, %rbp";
        code ~= "    pushq %rdi           # save left value";
        code ~= "    pushq %rsi           # save right value";
        
        code ~= "    # Convert left value to string";
        code ~= "    movq %rdi, %rax";
        code ~= "    call value_to_string_auto";
        code ~= "    pushq %rax          # save left string";
        
        code ~= "    # Convert right value to string";
        code ~= "    movq -16(%rbp), %rdi # right value from stack";
        code ~= "    call value_to_string_auto";
        code ~= "    movq %rax, %rsi     # right string in %rsi";
        code ~= "    popq %rdi           # left string in %rdi";
        
        code ~= "    # Call regular string concatenation";
        code ~= "    call string_concat";
        
        code ~= "    addq $16, %rsp      # clean up stack";
        code ~= "    popq %rbp";
        code ~= "    ret";
    }
    
    private void addStringInterpolationRuntime() {
        code ~= "";
        code ~= "# String interpolation function";
        code ~= "# Stack layout (from top): expr_count, parts_count, parts..., expr_values..., format_specs...";
        code ~= "string_interpolate:";
        code ~= "    pushq %rbp";
        code ~= "    movq %rsp, %rbp";
        
        code ~= "    # Get counts from stack";
        code ~= "    movq 16(%rbp), %r8   # expression count";
        code ~= "    movq 24(%rbp), %r9   # parts count";
        
        code ~= "    # Initialize result buffer";
        code ~= "    movq $string_buffer, %rdi";
        code ~= "    movb $0, (%rdi)      # start with empty string";
        code ~= "    movq %rdi, %r10      # current position in result";
        
        code ~= "    # Loop through parts and expressions";
        code ~= "    movq $0, %r11        # part index";
        code ~= "    movq $0, %r12        # expression index";
        
        code ~= "interpolate_loop:";
        code ~= "    # Append current part if available";
        code ~= "    cmpq %r9, %r11       # check if more parts";
        code ~= "    jge check_expressions";
        
        code ~= "    # Calculate part address on stack";
        code ~= "    # parts start at 32(%rbp) + (parts_count - 1 - r11) * 8";
        code ~= "    movq %r9, %rax";
        code ~= "    decq %rax";
        code ~= "    subq %r11, %rax";
        code ~= "    shlq $3, %rax        # multiply by 8";
        code ~= "    addq $32, %rax";
        code ~= "    addq %rbp, %rax";
        code ~= "    movq (%rax), %rsi    # part string pointer";
        
        code ~= "    # Append part to result";
        code ~= "    call string_append";
        
        code ~= "check_expressions:";
        code ~= "    # Append current expression if available";
        code ~= "    cmpq %r8, %r12       # check if more expressions";
        code ~= "    jge next_iteration";
        
        code ~= "    # Calculate expression value address";
        code ~= "    # expressions start after parts: 32(%rbp) + parts_count * 8 + (expr_count - 1 - r12) * 16";
        code ~= "    movq %r9, %rax";
        code ~= "    shlq $3, %rax        # parts_count * 8";
        code ~= "    addq $32, %rax";
        
        code ~= "    movq %r8, %rbx";
        code ~= "    decq %rbx";
        code ~= "    subq %r12, %rbx";
        code ~= "    shlq $4, %rbx        # multiply by 16 (value + format = 2 * 8)";
        code ~= "    addq %rbx, %rax";
        code ~= "    addq %rbp, %rax";
        
        code ~= "    movq (%rax), %rdi    # expression value";
        code ~= "    movq 8(%rax), %rsi   # format specifier";
        
        code ~= "    # Convert value to string based on format";
        code ~= "    call value_to_string_formatted";
        
        code ~= "    # Append converted string to result";
        code ~= "    movq %rax, %rsi";
        code ~= "    call string_append";
        
        code ~= "next_iteration:";
        code ~= "    incq %r11            # increment part index";
        code ~= "    incq %r12            # increment expression index";
        code ~= "    cmpq %r9, %r11       # check if more parts";
        code ~= "    jl interpolate_loop";
        code ~= "    cmpq %r8, %r12       # check if more expressions";
        code ~= "    jl interpolate_loop";
        
        code ~= "    # Return result";
        code ~= "    movq $string_buffer, %rax";
        code ~= "    popq %rbp";
        code ~= "    ret";
    }
    
    private void addValueToStringConversion() {
        code ~= "";
        code ~= "# Simple memory copy function";
        code ~= "# %rdi = dest, %rsi = src, %rcx = count";
        code ~= "memcpy_simple:";
        code ~= "    cmpq $0, %rcx";
        code ~= "    je memcpy_done";
        code ~= "    movb (%rsi), %al";
        code ~= "    movb %al, (%rdi)";
        code ~= "    incq %rsi";
        code ~= "    incq %rdi";
        code ~= "    decq %rcx";
        code ~= "    jmp memcpy_simple";
        code ~= "memcpy_done:";
        code ~= "    ret";
        
        code ~= "";
        code ~= "# String append function";
        code ~= "# %rdi = current position in result buffer (modified), %rsi = string to append";
        code ~= "string_append:";
        code ~= "    pushq %rbp";
        code ~= "    movq %rsp, %rbp";
        code ~= "    pushq %rdi           # save current position";
        code ~= "    pushq %rsi           # save string to append";
        
        code ~= "    # Find end of current string";
        code ~= "    movq $string_buffer, %rdi";
        code ~= "    call strlen";
        code ~= "    movq $string_buffer, %rdi";
        code ~= "    addq %rax, %rdi      # point to end";
        
        code ~= "    # Copy new string";
        code ~= "    movq 8(%rbp), %rsi   # string to append";
        code ~= "    call strlen";
        code ~= "    movq %rax, %rcx      # length to copy";
        code ~= "    movq 8(%rbp), %rsi   # string to append";
        code ~= "    call memcpy_simple";
        
        code ~= "    # Add null terminator";
        code ~= "    addq %rcx, %rdi";
        code ~= "    movb $0, (%rdi)";
        
        code ~= "    addq $16, %rsp       # clean up stack";
        code ~= "    popq %rbp";
        code ~= "    ret";
        
        code ~= "";
        code ~= "# Convert value to string with format";
        code ~= "# %rdi = value, %rsi = format specifier string";
        code ~= "# %rax = pointer to converted string";
        code ~= "value_to_string_formatted:";
        code ~= "    pushq %rbp";
        code ~= "    movq %rsp, %rbp";
        code ~= "    pushq %rdi           # save value";
        code ~= "    pushq %rsi           # save format";
        
        code ~= "    # Check format specifier";
        code ~= "    movq %rsi, %rdi";
        code ~= "    call strlen";
        code ~= "    cmpq $0, %rax        # empty format";
        code ~= "    je format_auto";
        
        code ~= "    movq 8(%rbp), %rsi   # format string";
        code ~= "    movb (%rsi), %al";
        code ~= "    cmpb $':', %al       # check for : prefix";
        code ~= "    jne format_auto";
        
        code ~= "    movb 1(%rsi), %al    # get format character";
        code ~= "    cmpb $'d', %al       # integer format";
        code ~= "    je format_integer";
        code ~= "    cmpb $'f', %al       # float format";  
        code ~= "    je format_float";
        code ~= "    cmpb $'s', %al       # string format";
        code ~= "    je format_string";
        
        code ~= "format_auto:";
        code ~= "    # Auto-detect format based on value (simple: treat as integer)";
        code ~= "format_integer:";
        code ~= "    movq 16(%rbp), %rdi  # value";
        code ~= "    call num_to_string";
        code ~= "    jmp format_done";
        
        code ~= "format_float:";
        code ~= "    # For simplicity, treat as integer";
        code ~= "    movq 16(%rbp), %rdi  # value";
        code ~= "    call num_to_string";
        code ~= "    jmp format_done";
        
        code ~= "format_string:";
        code ~= "    # Value is already a string pointer";
        code ~= "    movq 16(%rbp), %rax  # return value as-is";
        
        code ~= "format_done:";
        code ~= "    addq $16, %rsp";
        code ~= "    popq %rbp";
        code ~= "    ret";
        
        code ~= "";
        code ~= "# Convert number to string";
        code ~= "# %rdi = number, %rax = pointer to string";
        code ~= "num_to_string:";
        code ~= "    pushq %rbp";
        code ~= "    movq %rsp, %rbp";
        code ~= "    pushq %rdi           # save number";
        
        code ~= "    # Handle zero case";
        code ~= "    cmpq $0, %rdi";
        code ~= "    jne num_to_str_nonzero";
        code ~= "    movq $temp_buffer, %rax";
        code ~= "    movb $'0', (%rax)";
        code ~= "    movb $0, 1(%rax)";
        code ~= "    jmp num_to_str_done";
        
        code ~= "num_to_str_nonzero:";
        code ~= "    movq $temp_buffer, %rsi";
        code ~= "    addq $63, %rsi       # point to end of buffer";
        code ~= "    movb $0, (%rsi)      # null terminate";
        code ~= "    decq %rsi";
        
        code ~= "    # Handle negative numbers";
        code ~= "    movq $0, %r8         # negative flag";
        code ~= "    cmpq $0, %rdi";
        code ~= "    jge num_to_str_positive";
        code ~= "    movq $1, %r8         # set negative flag";
        code ~= "    negq %rdi            # make positive";
        
        code ~= "num_to_str_positive:";
        code ~= "    # Convert digits";
        code ~= "num_to_str_loop:";
        code ~= "    cmpq $0, %rdi";
        code ~= "    je num_to_str_sign";
        code ~= "    movq %rdi, %rax";
        code ~= "    movq $10, %rcx";
        code ~= "    movq $0, %rdx";
        code ~= "    divq %rcx            # divide by 10";
        code ~= "    addb $'0', %dl       # convert remainder to ASCII";
        code ~= "    movb %dl, (%rsi)     # store digit";
        code ~= "    decq %rsi";
        code ~= "    movq %rax, %rdi      # quotient becomes new number";
        code ~= "    jmp num_to_str_loop";
        
        code ~= "num_to_str_sign:";
        code ~= "    # Add negative sign if needed";
        code ~= "    cmpq $1, %r8";
        code ~= "    jne num_to_str_result";
        code ~= "    movb $'-', (%rsi)";
        code ~= "    decq %rsi";
        
        code ~= "num_to_str_result:";
        code ~= "    incq %rsi            # point to start of string";
        code ~= "    movq %rsi, %rax      # return pointer";
        
        code ~= "num_to_str_done:";
        code ~= "    addq $8, %rsp";
        code ~= "    popq %rbp";
        code ~= "    ret";
        
        // Add automatic value to string conversion
        code ~= "";
        code ~= "# Automatic value to string conversion";
        code ~= "# Input: %rdi = value";  
        code ~= "# Output: %rax = pointer to string representation";
        code ~= "value_to_string_auto:";
        code ~= "    pushq %rbp";
        code ~= "    movq %rsp, %rbp";
        
        code ~= "    # For simplicity, always treat values as numbers for now";
        code ~= "    # This handles the common case of concatenating numbers with strings";
        code ~= "    call num_to_string";
        
        code ~= "    popq %rbp";
        code ~= "    ret";
        
        // Add automatic print function for any LiteCode data type
        code ~= "";
        code ~= "# Automatic print function for any LiteCode value";
        code ~= "# Input: %rdi = value (number, string pointer, char, bool)";
        code ~= "print_value_auto:";
        code ~= "    pushq %rbp";
        code ~= "    movq %rsp, %rbp";
        code ~= "    pushq %rdi           # save value";
        
        code ~= "    # Simple heuristic for LiteCode data types:";
        code ~= "    # - Small integers (0-1000000): likely numbers or bools";
        code ~= "    # - Large values that look like addresses: likely string pointers";
        code ~= "    # - Values 0-255: could be characters";
        
        code ~= "    cmpq $1000000, %rdi  # if value < 1M, likely a number";
        code ~= "    jl print_as_number";
        
        code ~= "    # Check if it's a valid string pointer";
        code ~= "    # Try to read first byte safely";
        code ~= "    cmpq $0x1000, %rdi   # reasonable minimum address";
        code ~= "    jl print_as_number";
        
        code ~= "    movb (%rdi), %al";
        code ~= "    cmpb $0, %al         # null string";
        code ~= "    je print_as_string";
        code ~= "    cmpb $32, %al        # printable ASCII range";
        code ~= "    jl print_as_number   # not printable, treat as number";
        code ~= "    cmpb $126, %al";
        code ~= "    jg print_as_number   # not printable, treat as number";
        
        code ~= "print_as_string:";
        code ~= "    # Looks like a string, print as string";
        code ~= "    call print_string";
        code ~= "    jmp print_auto_done";
        
        code ~= "print_as_number:";
        code ~= "    movq %rdi, %rax";
        code ~= "    call num_to_string";
        code ~= "    movq %rax, %rdi";
        code ~= "    call print_string";
        
        code ~= "print_auto_done:";
        code ~= "    addq $8, %rsp";
        code ~= "    popq %rbp";
        code ~= "    ret";
        
        // Add conversion functions for specific LiteCode data types
        code ~= "";
        code ~= "# Convert character to string";
        code ~= "# Input: %rdi = character value";
        code ~= "# Output: %rax = pointer to string representation";
        code ~= "char_to_string:";
        code ~= "    pushq %rbp";
        code ~= "    movq %rsp, %rbp";
        
        code ~= "    movq $temp_buffer, %rax";
        code ~= "    movb %dil, (%rax)    # store character";
        code ~= "    movb $0, 1(%rax)     # null terminate";
        
        code ~= "    popq %rbp";
        code ~= "    ret";
        
        code ~= "";
        code ~= "# Convert boolean to string";
        code ~= "# Input: %rdi = boolean value (0 or 1)";
        code ~= "# Output: %rax = pointer to string representation";
        code ~= "bool_to_string:";
        code ~= "    pushq %rbp";
        code ~= "    movq %rsp, %rbp";
        
        code ~= "    cmpq $0, %rdi";
        code ~= "    je bool_false_str";
        
        code ~= "    # True case";
        string trueLabel = getStringLabel("true");
        code ~= "    movq $" ~ trueLabel ~ ", %rax";
        code ~= "    jmp bool_str_done";
        
        code ~= "bool_false_str:";
        code ~= "    # False case";
        string falseLabel = getStringLabel("false");
        code ~= "    movq $" ~ falseLabel ~ ", %rax";
        
        code ~= "bool_str_done:";
        code ~= "    popq %rbp";
        code ~= "    ret";
    }
    
    private void generateRepeatStatement(RepeatStatement repeatStmt) {
        // Generate the expression to switch on
        generateExpression(repeatStmt.expression);
        code ~= "    movq %rax, %rdx  # store switch expression in %rdx";
        
        string endLabel = "repeat_end_" ~ to!string(labelCounter++);
        string[] caseLabels;
        
        // Generate labels for each case
        foreach (i, whenCase; repeatStmt.whenCases) {
            caseLabels ~= "repeat_case_" ~ to!string(labelCounter++);
        }
        
        string fixedLabel = "repeat_fixed_" ~ to!string(labelCounter++);
        
        // Generate comparison and jumps for each case
        foreach (i, whenCase; repeatStmt.whenCases) {
            generateExpression(whenCase.value);
            code ~= "    cmpq %rax, %rdx";
            code ~= "    je " ~ caseLabels[i];
        }
        
        // Jump to fixed case if no match
        if (repeatStmt.fixedBody.length > 0) {
            code ~= "    jmp " ~ fixedLabel;
        } else {
            code ~= "    jmp " ~ endLabel;
        }
        
        // Generate code for each when case
        foreach (i, whenCase; repeatStmt.whenCases) {
            code ~= caseLabels[i] ~ ":";
            foreach (stmt; whenCase.body) {
                generateStatement(stmt);
            }
            code ~= "    jmp " ~ endLabel;
        }
        
        // Generate fixed case if present
        if (repeatStmt.fixedBody.length > 0) {
            code ~= fixedLabel ~ ":";
            foreach (stmt; repeatStmt.fixedBody) {
                generateStatement(stmt);
            }
        }
        
        code ~= endLabel ~ ":";
    }
}

// ARM64 Code Generator
class ARM64CodeGenerator : ArchCodeGenerator {
    override string generateCode(Program program) {
        code ~= ".section .data";
        
        code ~= "";
        code ~= ".section .text";
        code ~= ".global _start";
        
        foreach (func; program.functions) {
            generateFunction(func);
        }
        
        generateRunBlock(program.runBlock);
        addSystemCallHelpers();
        
        if (dataSection.length > 0) {
            code ~= "";
            code ~= ".section .data";
            code ~= dataSection;
        }
        
        return join(code, "\n");
    }
    
    override void generateFunction(FunctionDeclaration func) {
        string functionLabel = "func_" ~ func.name;
        functions[func.name] = functionLabel;
        
        code ~= "";
        code ~= functionLabel ~ ":";
        code ~= "    stp x29, x30, [sp, #-16]!";
        code ~= "    mov x29, sp";
        
        bool oldInFunction = inFunction;
        int oldStackOffset = stackOffset;
        string[string] oldVariables = variables.dup;
        
        inFunction = true;
        stackOffset = 0;
        
        foreach (i, param; func.parameters) {
            stackOffset -= 8;
            variables[param.name] = to!string(stackOffset);
        }
        
        foreach (stmt; func.body) {
            generateStatement(stmt);
        }
        
        code ~= "    ldp x29, x30, [sp], #16";
        code ~= "    ret";
        
        inFunction = oldInFunction;
        stackOffset = oldStackOffset;
        variables = oldVariables;
    }
    
    override void generateRunBlock(RunBlock runBlock) {
        code ~= "";
        code ~= "_start:";
        code ~= "    stp x29, x30, [sp, #-16]!";
        code ~= "    mov x29, sp";
        
        foreach (stmt; runBlock.statements) {
            generateStatement(stmt);
        }
        
        code ~= "    mov x8, #93      // sys_exit";
        code ~= "    mov x0, #0       // exit status";
        code ~= "    svc #0           // system call";
    }
    
    override void generateStatement(Statement stmt) {
        if (auto varDecl = cast(VarDeclaration)stmt) {
            stackOffset -= 8;
            variables[varDecl.name] = to!string(stackOffset);
            
            if (varDecl.initializer) {
                generateExpression(varDecl.initializer);
                code ~= "    str x0, [x29, #" ~ to!string(stackOffset) ~ "]";
            }
        } else if (auto assignment = cast(Assignment)stmt) {
            generateExpression(assignment.value);
            string offset = variables[assignment.name];
            code ~= "    str x0, [x29, #" ~ offset ~ "]";
        } else if (auto exprStmt = cast(ExpressionStatement)stmt) {
            generateExpression(exprStmt.expression);
        } else if (auto repeatStmt = cast(RepeatStatement)stmt) {
            generateRepeatStatementARM64(repeatStmt);
        }
    }
    
    override void generateExpression(Expression expr) {
        if (auto numLit = cast(NumberLiteral)expr) {
            long value = cast(long)numLit.value;
            code ~= "    mov x0, #" ~ to!string(value);
        } else if (auto textLit = cast(TextLiteral)expr) {
            string label = getStringLabel(textLit.value);
            code ~= "    adr x0, " ~ label;
        } else if (auto funcCall = cast(FunctionCall)expr) {
            if (funcCall.name == "print") {
                generateExpression(funcCall.arguments[0]);
                code ~= "    bl print_string";
            }
        } else if (auto strInterp = cast(StringInterpolation)expr) {
            generateStringInterpolation(strInterp);
        } else if (auto strConcat = cast(StringConcatenation)expr) {
            generateStringConcatenation(strConcat);
        }
    }
    
    void generateStringInterpolation(StringInterpolation strInterp) {
        // Simplified ARM64 string interpolation
        // For now, just return the first part
        if (strInterp.parts.length > 0) {
            string label = getStringLabel(strInterp.parts[0]);
            code ~= "    adr x0, " ~ label;
        } else {
            string label = getStringLabel("");
            code ~= "    adr x0, " ~ label;
        }
    }
    
    void generateStringConcatenation(StringConcatenation strConcat) {
        // Simplified ARM64 string concatenation
        // For now, just return the left operand
        generateExpression(strConcat.left);
    }
    
    override void addSystemCallHelpers() {
        code ~= "";
        code ~= "print_string:";
        code ~= "    stp x29, x30, [sp, #-16]!";
        code ~= "    mov x29, sp";
        code ~= "    mov x1, x0           // string address";
        code ~= "    bl strlen            // get string length";
        code ~= "    mov x2, x0           // length";
        code ~= "    mov x0, #1           // stdout";
        code ~= "    mov x8, #64          // sys_write";
        code ~= "    svc #0               // system call";
        code ~= "    ldp x29, x30, [sp], #16";
        code ~= "    ret";
        
        code ~= "";
        code ~= "strlen:";
        code ~= "    mov x1, #0";
        code ~= "strlen_loop:";
        code ~= "    ldrb w2, [x0, x1]";
        code ~= "    cbz w2, strlen_done";
        code ~= "    add x1, x1, #1";
        code ~= "    b strlen_loop";
        code ~= "strlen_done:";
        code ~= "    mov x0, x1";
        code ~= "    ret";
    }
    
    private void generateRepeatStatementARM64(RepeatStatement repeatStmt) {
        // Generate the expression to switch on
        generateExpression(repeatStmt.expression);
        code ~= "    mov x1, x0  // store switch expression in x1";
        
        string endLabel = "repeat_end_" ~ to!string(labelCounter++);
        string[] caseLabels;
        
        // Generate labels for each case
        foreach (i, whenCase; repeatStmt.whenCases) {
            caseLabels ~= "repeat_case_" ~ to!string(labelCounter++);
        }
        
        string fixedLabel = "repeat_fixed_" ~ to!string(labelCounter++);
        
        // Generate comparison and jumps for each case
        foreach (i, whenCase; repeatStmt.whenCases) {
            generateExpression(whenCase.value);
            code ~= "    cmp x0, x1";
            code ~= "    beq " ~ caseLabels[i];
        }
        
        // Jump to fixed case if no match
        if (repeatStmt.fixedBody.length > 0) {
            code ~= "    b " ~ fixedLabel;
        } else {
            code ~= "    b " ~ endLabel;
        }
        
        // Generate code for each when case
        foreach (i, whenCase; repeatStmt.whenCases) {
            code ~= caseLabels[i] ~ ":";
            foreach (stmt; whenCase.body) {
                generateStatement(stmt);
            }
            code ~= "    b " ~ endLabel;
        }
        
        // Generate fixed case if present
        if (repeatStmt.fixedBody.length > 0) {
            code ~= fixedLabel ~ ":";
            foreach (stmt; repeatStmt.fixedBody) {
                generateStatement(stmt);
            }
        }
        
        code ~= endLabel ~ ":";
    }
}

// ARM32 Code Generator
class ARM32CodeGenerator : ArchCodeGenerator {
    override string generateCode(Program program) {
        code ~= ".section .data";
        
        code ~= "";
        code ~= ".section .text";
        code ~= ".global _start";
        
        foreach (func; program.functions) {
            generateFunction(func);
        }
        
        generateRunBlock(program.runBlock);
        addSystemCallHelpers();
        
        if (dataSection.length > 0) {
            code ~= "";
            code ~= ".section .data";
            code ~= dataSection;
        }
        
        return join(code, "\n");
    }
    
    override void generateFunction(FunctionDeclaration func) {
        string functionLabel = "func_" ~ func.name;
        functions[func.name] = functionLabel;
        
        code ~= "";
        code ~= functionLabel ~ ":";
        code ~= "    push {fp, lr}";
        code ~= "    mov fp, sp";
        
        bool oldInFunction = inFunction;
        int oldStackOffset = stackOffset;
        string[string] oldVariables = variables.dup;
        
        inFunction = true;
        stackOffset = 0;
        
        foreach (i, param; func.parameters) {
            stackOffset -= 4;
            variables[param.name] = to!string(stackOffset);
        }
        
        foreach (stmt; func.body) {
            generateStatement(stmt);
        }
        
        code ~= "    pop {fp, lr}";
        code ~= "    bx lr";
        
        inFunction = oldInFunction;
        stackOffset = oldStackOffset;
        variables = oldVariables;
    }
    
    override void generateRunBlock(RunBlock runBlock) {
        code ~= "";
        code ~= "_start:";
        code ~= "    push {fp, lr}";
        code ~= "    mov fp, sp";
        
        foreach (stmt; runBlock.statements) {
            generateStatement(stmt);
        }
        
        code ~= "    mov r7, #1       @ sys_exit";
        code ~= "    mov r0, #0       @ exit status";
        code ~= "    svc #0           @ system call";
    }
    
    override void generateStatement(Statement stmt) {
        if (auto varDecl = cast(VarDeclaration)stmt) {
            stackOffset -= 4;
            variables[varDecl.name] = to!string(stackOffset);
            
            if (varDecl.initializer) {
                generateExpression(varDecl.initializer);
                code ~= "    str r0, [fp, #" ~ to!string(stackOffset) ~ "]";
            }
        } else if (auto assignment = cast(Assignment)stmt) {
            generateExpression(assignment.value);
            string offset = variables[assignment.name];
            code ~= "    str r0, [fp, #" ~ offset ~ "]";
        } else if (auto exprStmt = cast(ExpressionStatement)stmt) {
            generateExpression(exprStmt.expression);
        } else if (auto repeatStmt = cast(RepeatStatement)stmt) {
            generateRepeatStatementARM32(repeatStmt);
        }
    }
    
    override void generateExpression(Expression expr) {
        if (auto numLit = cast(NumberLiteral)expr) {
            long value = cast(long)numLit.value;
            code ~= "    mov r0, #" ~ to!string(value);
        } else if (auto textLit = cast(TextLiteral)expr) {
            string label = getStringLabel(textLit.value);
            code ~= "    ldr r0, =" ~ label;
        } else if (auto funcCall = cast(FunctionCall)expr) {
            if (funcCall.name == "print") {
                generateExpression(funcCall.arguments[0]);
                code ~= "    bl print_string";
            }
        }
    }
    
    override void addSystemCallHelpers() {
        code ~= "";
        code ~= "print_string:";
        code ~= "    push {fp, lr}";
        code ~= "    mov fp, sp";
        code ~= "    mov r1, r0           @ string address";
        code ~= "    bl strlen            @ get string length";
        code ~= "    mov r2, r0           @ length";
        code ~= "    mov r0, #1           @ stdout";
        code ~= "    mov r7, #4           @ sys_write";
        code ~= "    svc #0               @ system call";
        code ~= "    pop {fp, lr}";
        code ~= "    bx lr";
        
        code ~= "";
        code ~= "strlen:";
        code ~= "    mov r1, #0";
        code ~= "strlen_loop:";
        code ~= "    ldrb r2, [r0, r1]";
        code ~= "    cmp r2, #0";
        code ~= "    beq strlen_done";
        code ~= "    add r1, r1, #1";
        code ~= "    b strlen_loop";
        code ~= "strlen_done:";
        code ~= "    mov r0, r1";
        code ~= "    bx lr";
    }
    
    private void generateRepeatStatementARM32(RepeatStatement repeatStmt) {
        // Generate the expression to switch on
        generateExpression(repeatStmt.expression);
        code ~= "    mov r1, r0  @ store switch expression in r1";
        
        string endLabel = "repeat_end_" ~ to!string(labelCounter++);
        string[] caseLabels;
        
        // Generate labels for each case
        foreach (i, whenCase; repeatStmt.whenCases) {
            caseLabels ~= "repeat_case_" ~ to!string(labelCounter++);
        }
        
        string fixedLabel = "repeat_fixed_" ~ to!string(labelCounter++);
        
        // Generate comparison and jumps for each case
        foreach (i, whenCase; repeatStmt.whenCases) {
            generateExpression(whenCase.value);
            code ~= "    cmp r0, r1";
            code ~= "    beq " ~ caseLabels[i];
        }
        
        // Jump to fixed case if no match
        if (repeatStmt.fixedBody.length > 0) {
            code ~= "    b " ~ fixedLabel;
        } else {
            code ~= "    b " ~ endLabel;
        }
        
        // Generate code for each when case
        foreach (i, whenCase; repeatStmt.whenCases) {
            code ~= caseLabels[i] ~ ":";
            foreach (stmt; whenCase.body) {
                generateStatement(stmt);
            }
            code ~= "    b " ~ endLabel;
        }
        
        // Generate fixed case if present
        if (repeatStmt.fixedBody.length > 0) {
            code ~= fixedLabel ~ ":";
            foreach (stmt; repeatStmt.fixedBody) {
                generateStatement(stmt);
            }
        }
        
        code ~= endLabel ~ ":";
    }
}

ArchCodeGenerator createCodeGenerator(Architecture arch) {
    switch (arch) {
        case Architecture.X86_64:
            return new X86_64CodeGenerator();
        case Architecture.ARM64:
            return new ARM64CodeGenerator();
        case Architecture.ARM32:
            return new ARM32CodeGenerator();
        default:
            return new X86_64CodeGenerator();
    }
}
