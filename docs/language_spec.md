# LiteCode V0.1 Language Specification

## Overview

LiteCode is a minimal, general-purpose programming language designed to prioritize programmer ergonomics, simplicity, and safety. This document specifies the language features for version 0.1.

## Language Features

### Data Types

- `num`: Numeric type (integer if no decimal, double if . present)
- `text`: String type, enclosed in double quotes
- `char`: Single character, enclosed in single quotes  
- `bool`: Boolean values `true` or `false`
- `null`: Allowed only for nullable types
- Custom struct types: User-defined composite types

### Null Safety

- **Nullable Types**: Declared with `?` (e.g., `num? x`, `text? s`)
- **Default Non-Nullable**: Variables must be initialized and cannot be null unless marked with `?`
- **Null Checks**: Use `== null` or `!= null` in conditions

### Constants with val

- **Purpose**: The `val` keyword declares constant variables that cannot be reassigned
- **Syntax**: `val type name = value;`
- **Rules**:
  - Constants must be initialized at declaration
  - Reassignment is prohibited (compile-time error)
  - Nullable constants allowed: `val num? x = null;`

### Syntax Rules

- **Delimiter**: Semicolon (`;`) terminates statements
- **Scoping**: C-like curly braces `{}` define blocks
- **Ergonomics**: Square brackets `[]` used for function calls and control structures
- **Entry Point**: All code must be inside `run { ... };` block

## Syntax Constructs

### Variables and Constants

```litecode
// Variable declaration
num x = 10;
num? y = null;

// Constant declaration  
val num PI = 3.14;
val text? NAME = null;

// Assignment (only for variables)
x = 20;  // valid
// PI = 3.14159;  // compile error
```

### Functions

```litecode
fnc add[num a, num b]:num {
    return a + b;
}

// With constant parameters
fnc calc[val num x]:num {
    return x * 2;
}

// Function call
num result = @add[5, 3];
```

### Structs

```litecode
// Struct declaration
struct Person {
    text name;
    num age;
    bool active;
};

// Struct variable declaration
Person person1;
Person? person2 = null;  // nullable struct

// Struct initialization with literal
Person alice = Person{name: "Alice", age: 25, active: true};

// Member access and assignment
alice->age = 26;
text personName = alice->name;

// Constant struct members
struct Config {
    val num MAX_SIZE = 100;
    text environment;
};
```

### Conditionals

```litecode
if [condition] {
    statements;
} or [other_condition] {
    statements;
} else {
    statements;
}
```

### For Loops

```litecode
for [num i = 0; i < 5; i = i + 1] {
    @print["Loop $i"];
}

// With constants
for [val num i = 0; i < 5; i = i + 1] {
    @print["Constant loop var: $i"];
}
```

### Repeat-When-Fixed (Switch-Case)

```litecode
repeat [expression] {
    when [value1] {
        statements;
    }
    when [value2] {
        statements;
    }
    fixed {
        statements;  // default case (optional)
    }
}
```

### Error Handling

```litecode
try {
    statements;
} catch[error] {
    statements;
} finally {
    statements;
}
```

### String Operations

```litecode
// String interpolation - embedding variables in strings
text name = "Alice";
num age = 25;
@print["Hello $name, you are $age years old"];

// String concatenation with +>> operator
text greeting = "Hello " +>> name;
text message = "User " +>> name +>> " is " +>> age +>> " years old";

// Mixed interpolation and concatenation
text result = "Prefix: " +>> "Value is $age" +>> " suffix";
```

```litecode
### Input/Output

```litecode
// Print with interpolation
@print["Value: $x"];

// Print with formatting
@print[x:f];  // float format
@print[x:d];  // integer format  
@print[x:s];  // string format

// Input
text input = @read["Enter text: "];
num number = @num.read["Enter number: "];
```
```

### Operators

- **Arithmetic**: `+`, `-`, `*`, `/`, `%`
- **Comparison**: `==`, `!=`, `<`, `>`, `<=`, `>=`
- **Logical**: `&&` (AND), `||` (OR), `!!` (NOT)
- **String Concatenation**: `+`

### Comments

```litecode
// Single-line comment
```

## Example Programs

### Hello World

```litecode
run {
    @print["Hello, LiteCode!"];
};
```

### Function with Constants

```litecode
fnc is_even[val num n]:bool {
    return n % 2 == 0;
}

run {
    val num LIMIT = 5;
    for [val num i = 1; i <= LIMIT; i = i + 1] {
        if [is_even[i]] {
            @print["$i is even"];
        } else {
            @print["$i is odd"];
        }
    }
};
```

### Repeat-When-Fixed Example

```litecode
fnc dayName[num day]:void {
    repeat [day] {
        when [1] {
            @print["Monday"];
        }
        when [2] {
            @print["Tuesday"];
        }
        when [3] {
            @print["Wednesday"];
        }
        when [4] {
            @print["Thursday"];
        }
        when [5] {
            @print["Friday"];
        }
        fixed {
            @print["Weekend or invalid day"];
        }
    }
}

run {
    @dayName[3];  // Prints "Wednesday"
    @dayName[7];  // Prints "Weekend or invalid day"
};
```

### Error Handling

```litecode
run {
    try {
        val num x = num.@read["Enter number: "];
        if [x != null && x > 0] {
            @print["Positive: $x:f"];
        } else {
            @print["Invalid or non-positive"];
        }
    } catch[error] {
        @print["Error: $error"];
    } finally {
        @print["Done"];
    }
};
```

## Compilation Process

1. **Lexical Analysis**: Tokenizes source code
2. **Syntax Analysis**: Builds Abstract Syntax Tree (AST)
3. **Semantic Analysis**: Type checking, null safety validation, constant enforcement
4. **Code Generation**: Generates x86-64 assembly code
5. **Assembly & Linking**: Creates executable

## Error Messages

### Compile-Time Errors

- Missing run block: "Program must contain exactly one run block"
- Uninitialized constant: "Constant x must be initialized at declaration"
- Reassigning constant: "Cannot reassign constant x"
- Null assignment: "Cannot assign null to non-nullable type"

### Runtime Errors

- Invalid input: "Invalid input for type"
- Division by zero: "Division by zero"

## Language Goals

- **Minimalism**: Keep features minimal and focused
- **Ergonomics**: Prioritize `[]` syntax and concise operators  
- **Safety**: Enforce null safety and constant immutability
- **Clarity**: Clear error messages and predictable behavior
