# LiteCode Quick Reference

## Basic Syntax Cheat Sheet

### Comments
```litecode
// Single line comment
/? Multi-line comment
   spans multiple lines ?/
```

### Data Types
```litecode
num integer = 42;           // Integer or float
text message = "Hello";     // String in double quotes
char letter = 'A';          // Character in single quotes
bool flag = true;           // Boolean: true or false
num? optional = null;       // Nullable type with ?
```

### Variables vs Constants
```litecode
num variable = 10;          // Mutable
variable = 20;              // Can reassign

val num CONSTANT = 10;      // Immutable
// CONSTANT = 20;           // Error: cannot reassign
```

### Functions
```litecode
fnc functionName[type param]:returnType {
    return value;
}

// Call with @ prefix and square brackets
num result = @functionName[argument];
```

### Control Flow
```litecode
// Conditionals
if [condition] {
    // code
} or [otherCondition] {
    // code
} else {
    // code
}

// Loops
for [num i = 0; i < 10; i = i + 1] {
    // code
}

// Switch-case equivalent
repeat [expression] {
    when [value1] {
        // code
    }
    when [value2] {
        // code
    }
    fixed {
        // default case (optional)
    }
}

// Error handling
try {
    // risky code
} catch[error] {
    // handle error
} finally {
    // cleanup
}
```

### Operators
```litecode
// Arithmetic: +, -, *, /, %
// Comparison: ==, !=, <, >, <=, >=
// Logical: && (AND), || (OR), !! (NOT)
// Assignment: =
// String concat: +
```

### Program Structure
```litecode
// Optional functions
fnc helper[]:void {
    @print["Helper"];
}

// Required run block
run {
    helper[];
    @print["Main program"];
};
```

### Print with Interpolation
```litecode
num age = 25;
text name = "Alice";
@print["$name is $age years old"];
@print["Formatted: $age:d"];  // :d, :f, :s format specifiers
```

### Input
```litecode
text userInput = @read["Enter text: "];  // Read with prompt
text data = @read[""];                   // Read without prompt
```

## Common Patterns

### Input Validation
```litecode
fnc isValid[num value]:bool {
    return value >= 0 && value <= 100;
}

if [isValid[userInput]] {
    // process input
} else {
    @print["Invalid input"];
}
```

### Null Safety
```litecode
num? optional = getValue[];
if [optional != null] {
    @print["Value: $optional"];
} else {
    @print["No value"];
}
```

### Recursive Function
```litecode
fnc factorial[num n]:num {
    if [n <= 1] {
        return 1;
    } else {
        return n * factorial[n - 1];
    }
}
```

## Compilation Commands

```bash
# Basic compilation
lcc program.lc

# Custom output name
lcc -o myprogram program.lc

# Keep assembly file
lcc -S program.lc

# Verbose output
lcc -v program.lc

# Cross-compile
lcc --target arm64 program.lc

# Help and version
lcc --help
lcc --version
```

## Error Prevention

### ✅ Do:
- End statements with `;`
- Use `[]` for function calls
- Use `""` for strings, `''` for chars
- Check nullable values before use
- Use `val` for constants
- Include run block

### ❌ Don't:
- Use `()` for function calls
- Reassign constants
- Assign null to non-nullable types
- Use constant variables in loops
- Forget the run block
- Mix quote types

## File Extensions
- Source files: `.lc`
- Assembly files: `.s` (with -S flag)
- Executables: no extension (default)
