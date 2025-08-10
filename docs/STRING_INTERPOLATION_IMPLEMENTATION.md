# String Interpolation and Concatenation Implementation

## Overview

This document describes the comprehensive implementation of string interpolation and concatenation runtime for the LiteCode compiler. The implementation provides efficient dynamic string operations with formatting support.

## Features Implemented

### 1. String Interpolation Runtime

#### Dynamic String Buffer Allocation
- **Dynamic Memory Management**: Uses a dedicated `string_buffer` (4KB) for string operations
- **Automatic Size Calculation**: Computes total length required for interpolated strings
- **Memory Safety**: Proper null termination and bounds checking

#### Variable Value to String Conversion
- **Automatic Type Detection**: Converts any value type to string representation
- **Number to String**: Handles both integer and floating-point numbers
- **Boolean to String**: Converts `true`/`false` values
- **Character to String**: Single character conversion
- **String Pass-through**: Direct use of existing string values

#### String Formatting Support
- **`:d` Format**: Integer/decimal formatting
- **`:f` Format**: Floating-point number formatting  
- **`:s` Format**: String formatting (pass-through)
- **Auto-format**: Automatic type-appropriate formatting when no specifier given

### 2. String Concatenation Runtime

#### String Length Calculation
- **Efficient Length Computation**: Uses optimized `strlen` implementation
- **Total Size Prediction**: Pre-calculates required buffer size
- **Multi-string Support**: Handles concatenation of multiple string operands

#### Memory Allocation for Result
- **Buffer Management**: Uses shared string buffer for results
- **Dynamic Sizing**: Allocates based on computed total length
- **Memory Reuse**: Efficient buffer utilization across operations

#### String Copying and Joining
- **Optimized Memory Copy**: Custom `memcpy_simple` implementation
- **Sequential Assembly**: Copies strings in correct order
- **Null Termination**: Ensures proper string termination

## Technical Implementation

### AST Node Extensions

```d
class StringInterpolation : Expression {
    string[] parts;              // Static text parts
    Expression[] expressions;    // Dynamic expressions to interpolate
    string[] formatSpecifiers;   // Format specifications like ":d", ":f", ":s"
}

class StringConcatenation : Expression {
    Expression left;             // Left operand
    Expression right;            // Right operand
}
```

### Runtime Functions (x86_64 Assembly)

#### Core String Functions
- `string_interpolate`: Main interpolation function
- `string_concat`: String concatenation function
- `string_append`: Append string to buffer
- `value_to_string_formatted`: Value conversion with formatting
- `num_to_string`: Number to string conversion
- `memcpy_simple`: Memory copy utility

#### Memory Layout
```assembly
.section .data
input_buffer:   .space 256      # Input operations
temp_buffer:    .space 64       # Number conversion
string_buffer:  .space 4096     # String operations
```

### Parser Enhancements

#### Interpolation Syntax Support
- **`${expression}` form**: Full expression interpolation
- **`${expression:format}` form**: Expression with format specifier
- **`$variable` form**: Simple variable interpolation

#### Format Specifier Parsing
- Detects `:d`, `:f`, `:s` format specifications
- Stores format information in AST nodes
- Handles empty/default format cases

### Semantic Analysis

#### Type Checking
- Validates interpolation expressions
- Ensures format compatibility
- Handles string concatenation type rules
- Automatic type conversion support

#### Expression Analysis
```d
private LCType analyzeStringInterpolation(StringInterpolation strInterp) {
    foreach (expr; strInterp.expressions) {
        analyzeExpression(expr);  // Validate each expression
    }
    return new TextType();        // Always returns text
}
```

### Code Generation

#### X86_64 Implementation
- Stack-based parameter passing for runtime functions
- Register-efficient value conversion
- Optimized string buffer management
- System call integration for I/O operations

#### Multi-Architecture Support
- ARM64 implementation (partial)
- ARM32 implementation (partial)
- Consistent runtime interface across architectures

## Performance Characteristics

### String Interpolation
- **Time Complexity**: O(n + m) where n = total string length, m = number of expressions
- **Space Complexity**: O(result_length) with shared buffer reuse
- **Memory Usage**: Fixed 4KB buffer for most operations

### String Concatenation
- **Time Complexity**: O(n + m) where n, m = string lengths
- **Space Complexity**: O(n + m) for result
- **Optimization**: Single-pass copying with pre-calculated sizes

## Usage Examples

### Basic Interpolation
```litecode
var name = "World";
print("Hello, ${name}!");           // Output: Hello, World!
```

### Formatted Interpolation
```litecode
var count = 42;
var price = 99.95;
print("Item: ${count:d} @ $${price:f}");  // Output: Item: 42 @ $99.95
```

### String Concatenation
```litecode
var first = "Hello";
var second = "World";
var result = first + " " + second;   // Output: Hello World
```

### Complex Expressions
```litecode
var x = 10;
var y = 20;
print("${x} + ${y} = ${x + y:d}");  // Output: 10 + 20 = 30
```

## Runtime Safety

### Memory Management
- Fixed-size buffers prevent unbounded allocation
- Proper null termination prevents buffer overruns
- Bounds checking in critical operations

### Error Handling
- Graceful handling of conversion failures
- Default values for invalid formats
- Safe fallbacks for memory exhaustion

### Type Safety
- Semantic analysis prevents type errors
- Runtime conversion handles all basic types
- Format mismatch handled gracefully

## Future Enhancements

### Potential Improvements
1. **Dynamic Memory Allocation**: Replace fixed buffers with heap allocation
2. **Advanced Formatting**: Support for width, precision, alignment
3. **Locale Support**: Internationalization for number/date formatting
4. **Performance Optimization**: SIMD instructions for string operations
5. **Garbage Collection**: Automatic memory management for string results

### Extended Format Specifiers
- **`:x`**: Hexadecimal formatting
- **`:b`**: Binary formatting
- **`:e`**: Scientific notation
- **`:,`**: Thousands separator
- **`:%d`**: Custom width specifications

This implementation provides a solid foundation for string operations in LiteCode while maintaining efficiency and type safety.
