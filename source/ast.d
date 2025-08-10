module ast;

import types;

// Base AST node
abstract class ASTNode {
    int line;
    int column;
    
    this(int line = 0, int column = 0) {
        this.line = line;
        this.column = column;
    }
}

// Expressions
abstract class Expression : ASTNode {
    LCType type;
    
    this(int line = 0, int column = 0) {
        super(line, column);
    }
}

class NumberLiteral : Expression {
    double value;
    bool isInteger;
    
    this(double value, bool isInteger, int line = 0, int column = 0) {
        super(line, column);
        this.value = value;
        this.isInteger = isInteger;
        this.type = new NumType();
    }
}

class TextLiteral : Expression {
    string value;
    
    this(string value, int line = 0, int column = 0) {
        super(line, column);
        this.value = value;
        this.type = new TextType();
    }
}

class CharLiteral : Expression {
    char value;
    
    this(char value, int line = 0, int column = 0) {
        super(line, column);
        this.value = value;
        this.type = new CharType();
    }
}

class BoolLiteral : Expression {
    bool value;
    
    this(bool value, int line = 0, int column = 0) {
        super(line, column);
        this.value = value;
        this.type = new BoolType();
    }
}

class NullLiteral : Expression {
    this(int line = 0, int column = 0) {
        super(line, column);
        this.type = new NullType();
    }
}

class Identifier : Expression {
    string name;
    
    this(string name, int line = 0, int column = 0) {
        super(line, column);
        this.name = name;
    }
}

class BinaryOp : Expression {
    Expression left;
    string operator;
    Expression right;
    
    this(Expression left, string operator, Expression right, int line = 0, int column = 0) {
        super(line, column);
        this.left = left;
        this.operator = operator;
        this.right = right;
    }
}

class UnaryOp : Expression {
    string operator;
    Expression operand;
    
    this(string operator, Expression operand, int line = 0, int column = 0) {
        super(line, column);
        this.operator = operator;
        this.operand = operand;
    }
}

class FunctionCall : Expression {
    string name;
    Expression[] arguments;
    
    this(string name, Expression[] arguments, int line = 0, int column = 0) {
        super(line, column);
        this.name = name;
        this.arguments = arguments;
    }
}

class StringInterpolation : Expression {
    string[] parts;
    Expression[] expressions;
    string[] formatSpecifiers; // Format specifications like ":d", ":f", ":s"
    
    this(string[] parts, Expression[] expressions, string[] formatSpecifiers = null, int line = 0, int column = 0) {
        super(line, column);
        this.parts = parts;
        this.expressions = expressions;
        this.formatSpecifiers = formatSpecifiers.length > 0 ? formatSpecifiers : new string[expressions.length];
        this.type = new TextType();
    }
}

class StringConcatenation : Expression {
    Expression left;
    Expression right;
    
    this(Expression left, Expression right, int line = 0, int column = 0) {
        super(line, column);
        this.left = left;
        this.right = right;
        this.type = new TextType();
    }
}

class ArrayLiteral : Expression {
    Expression[] elements;
    
    this(Expression[] elements, int line = 0, int column = 0) {
        super(line, column);
        this.elements = elements;
    }
}

class ArrayAccess : Expression {
    Expression array;
    Expression index;
    
    this(Expression array, Expression index, int line = 0, int column = 0) {
        super(line, column);
        this.array = array;
        this.index = index;
    }
}

class ArrayAssignment : Statement {
    Expression array;
    Expression index;
    Expression value;
    
    this(Expression array, Expression index, Expression value, int line = 0, int column = 0) {
        super(line, column);
        this.array = array;
        this.index = index;
        this.value = value;
    }
}

// Statements
abstract class Statement : ASTNode {
    this(int line = 0, int column = 0) {
        super(line, column);
    }
}

class VarDeclaration : Statement {
    LCType varType;
    string name;
    Expression initializer;
    bool isConstant; // true for val, false for regular variables
    bool isCompileTimeConstant; // true if this constant can be evaluated at compile time
    
    this(LCType varType, string name, Expression initializer, bool isConstant, int line = 0, int column = 0) {
        super(line, column);
        this.varType = varType;
        this.name = name;
        this.initializer = initializer;
        this.isConstant = isConstant;
        this.isCompileTimeConstant = false; // Will be set during semantic analysis
    }
}

class Assignment : Statement {
    string name;
    Expression value;
    
    this(string name, Expression value, int line = 0, int column = 0) {
        super(line, column);
        this.name = name;
        this.value = value;
    }
}

class IfStatement : Statement {
    Expression condition;
    Statement[] thenBody;
    IfStatement elseIf; // for "or" clauses
    Statement[] elseBody;
    
    this(Expression condition, Statement[] thenBody, int line = 0, int column = 0) {
        super(line, column);
        this.condition = condition;
        this.thenBody = thenBody;
    }
}

class ForStatement : Statement {
    Statement initialization;
    Expression condition;
    Statement increment;
    Statement[] body;
    
    this(
        Statement initialization,
        Expression condition,
        Statement increment,
        Statement[] body,
        int line = 0,
        int column = 0
    ) {
        super(line, column);
        this.initialization = initialization;
        this.condition = condition;
        this.increment = increment;
        this.body = body;
    }
}

class TryStatement : Statement {
    Statement[] tryBody;
    string catchVariable;
    Statement[] catchBody;
    Statement[] finallyBody;
    
    this(
        Statement[] tryBody,
        string catchVariable,
        Statement[] catchBody,
        Statement[] finallyBody,
        int line = 0,
        int column = 0
    ) {
        super(line, column);
        this.tryBody = tryBody;
        this.catchVariable = catchVariable;
        this.catchBody = catchBody;
        this.finallyBody = finallyBody;
    }
}

class WhenCase {
    Expression value;
    Statement[] body;
    
    this(Expression value, Statement[] body) {
        this.value = value;
        this.body = body;
    }
}

class RepeatStatement : Statement {
    Expression expression;
    WhenCase[] whenCases;
    Statement[] fixedBody;
    
    this(
        Expression expression,
        WhenCase[] whenCases,
        Statement[] fixedBody,
        int line = 0,
        int column = 0
    ) {
        super(line, column);
        this.expression = expression;
        this.whenCases = whenCases;
        this.fixedBody = fixedBody;
    }
}

class ReturnStatement : Statement {
    Expression value;
    
    this(Expression value, int line = 0, int column = 0) {
        super(line, column);
        this.value = value;
    }
}

class ExpressionStatement : Statement {
    Expression expression;
    
    this(Expression expression, int line = 0, int column = 0) {
        super(line, column);
        this.expression = expression;
    }
}

class BlockStatement : Statement {
    Statement[] statements;
    
    this(Statement[] statements, int line = 0, int column = 0) {
        super(line, column);
        this.statements = statements;
    }
}

// Function-related nodes
class Parameter {
    LCType type;
    string name;
    bool isConstant; // true if declared with val
    
    this(LCType type, string name, bool isConstant = false) {
        this.type = type;
        this.name = name;
        this.isConstant = isConstant;
    }
}

class FunctionDeclaration : ASTNode {
    string name;
    Parameter[] parameters;
    LCType returnType;
    Statement[] body;
    
    this(string name, Parameter[] parameters, LCType returnType, Statement[] body, int line = 0, int column = 0) {
        super(line, column);
        this.name = name;
        this.parameters = parameters;
        this.returnType = returnType;
        this.body = body;
    }
}

class RunBlock : ASTNode {
    Statement[] statements;
    
    this(Statement[] statements, int line = 0, int column = 0) {
        super(line, column);
        this.statements = statements;
    }
}

// Struct-related AST nodes
class StructDeclaration : ASTNode {
    string name;
    StructField[] fields;
    
    this(string name, StructField[] fields, int line = 0, int column = 0) {
        super(line, column);
        this.name = name;
        this.fields = fields;
    }
}

class MemberAccess : Expression {
    Expression object;
    string memberName;
    
    this(Expression object, string memberName, int line = 0, int column = 0) {
        super(line, column);
        this.object = object;
        this.memberName = memberName;
    }
}

class MemberAssignment : Statement {
    Expression object;
    string memberName;
    Expression value;
    
    this(Expression object, string memberName, Expression value, int line = 0, int column = 0) {
        super(line, column);
        this.object = object;
        this.memberName = memberName;
        this.value = value;
    }
}

class StructLiteral : Expression {
    string typeName;
    string[] fieldNames;
    Expression[] fieldValues;
    
    this(string typeName, string[] fieldNames, Expression[] fieldValues, int line = 0, int column = 0) {
        super(line, column);
        this.typeName = typeName;
        this.fieldNames = fieldNames;
        this.fieldValues = fieldValues;
    }
}

// Program (root node)
class Program : ASTNode {
    StructDeclaration[] structs;
    FunctionDeclaration[] functions;
    RunBlock runBlock;
    
    this(StructDeclaration[] structs, FunctionDeclaration[] functions, RunBlock runBlock) {
        this.structs = structs;
        this.functions = functions;
        this.runBlock = runBlock;
    }
}
