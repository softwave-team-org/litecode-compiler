# Repeat-When-Fixed Implementation

## Overview

The `repeat-when-fixed` construct is LiteCode's equivalent to C's `switch-case-default` statement. It provides a clean, ergonomic way to handle multiple conditional branches based on a single expression.

## Syntax

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

## Key Features

- **Expression evaluation**: The expression is evaluated once and compared against each `when` case
- **Value matching**: Each `when` case specifies a literal value to match against
- **Optional default**: The `fixed` clause acts as a default case when no `when` cases match
- **Type safety**: All `when` values must be of the same type as the expression
- **Automatic fallthrough prevention**: Each case automatically jumps to the end after execution

## Implementation Details

### Lexer Changes
- Added `REPEAT`, `WHEN`, `FIXED` tokens
- Updated keyword mapping to recognize new keywords

### Parser Changes
- Added `RepeatStatement` and `WhenCase` AST nodes
- Integrated parsing into `parseStatement()` method
- Supports optional `fixed` clause

### Semantic Analysis
- Type checking ensures all `when` values match the expression type
- Validates proper structure and syntax

### Code Generation
- Generates efficient jump tables for all three target architectures (x86_64, ARM64, ARM32)
- Uses compare-and-jump instructions for optimal performance
- Handles both cases with and without `fixed` clauses

## Examples

### Basic Usage
```litecode
num grade = 85;
repeat [grade / 10] {
    when [9] {
        @print["A grade"];
    }
    when [8] {
        @print["B grade"];
    }
    when [7] {
        @print["C grade"];
    }
    fixed {
        @print["Below C"];
    }
}
```

### Without Default Case
```litecode
repeat [day] {
    when [1] {
        @print["Monday"];
    }
    when [2] {
        @print["Tuesday"];
    }
}
// Execution continues here if no match
```

## Advantages Over If-Else Chains

1. **Cleaner syntax**: More readable than long if-else-if chains
2. **Performance**: Single expression evaluation vs. multiple condition checks
3. **Maintainability**: Easy to add/remove cases
4. **Familiarity**: Similar to switch statements in other languages

## Comparison with C Switch

| Feature | LiteCode repeat-when-fixed | C switch-case |
|---------|---------------------------|---------------|
| Keyword | `repeat [expr] { when [val] {} }` | `switch (expr) { case val: }` |
| Default | `fixed {}` | `default:` |
| Fallthrough | Automatic prevention | Manual `break` required |
| Braces | Required for each case | Optional |
| Syntax style | Matches LiteCode `[]` convention | Traditional C syntax |

## Testing

The implementation has been tested with:
- Basic value matching
- Default case handling
- No default case scenarios
- Multiple case scenarios
- Type validation
- All target architectures (x86_64, ARM64, ARM32)

## Future Enhancements

Potential future improvements could include:
- Range matching: `when [1..5] {}`
- Multiple value matching: `when [1, 3, 5] {}`
- Expression matching: `when [x > 10] {}`
- Pattern matching for more complex data types
