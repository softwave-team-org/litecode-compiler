# LiteCode Documentation

Welcome to the LiteCode programming language documentation! This directory contains comprehensive guides and references for learning and using LiteCode.

## Documentation Files

### 📚 Main Guides

1. **[Comprehensive Syntax Guide](syntax_guide.md)**
   - Complete language reference with detailed explanations
   - All syntax features with examples
   - Best practices and common patterns
   - Error prevention tips

2. **[Quick Reference](quick_reference.md)**
   - Cheat sheet for quick lookup
   - Basic syntax patterns
   - Common commands and patterns
   - Essential compiler flags

3. **[Language Specification](language_spec.md)**
   - Formal language specification
   - Technical details and grammar
   - Compilation process overview

### 🎯 Getting Started

If you're new to LiteCode:
1. Start with the [Quick Reference](quick_reference.md) for an overview
2. Read the [Comprehensive Syntax Guide](syntax_guide.md) for detailed learning
3. Explore the `../examples/` directory for practical code samples
4. Refer to the [Language Specification](language_spec.md) for technical details

### 💡 Examples Directory

The `../examples/` directory contains practical code samples:
- **01_hello_world.lc** - Basic program structure and comments
- **02_variables_types.lc** - All data types and variable usage
- **03_constants.lc** - Constants with `val` keyword
- **04_functions.lc** - Function definitions and calls
- **05_control_flow.lc** - Conditionals and logical operators
- **06_loops.lc** - For loops and iteration patterns
- **07_null_safety.lc** - Nullable types and null checking
- **09_repeat_when_fixed.lc** - Switch-case equivalent with `repeat`/`when`/`fixed`

### 🔧 Compiler Usage

Basic compilation commands:
```bash
# Build the compiler
dub build --build=release

# Compile a LiteCode program
./lcc program.lc

# See all options
./lcc --help
```

### 📋 Language Features Summary

LiteCode provides:
- **Ergonomic Syntax**: Square brackets `[]` for function calls
- **Null Safety**: Non-nullable types by default, optional `?` for nullable
- **Immutable Constants**: `val` keyword for constants that cannot be reassigned
- **Multi-Architecture**: Compile for x86_64, ARM64, and ARM32
- **Simple Types**: `num`, `text`, `char`, `bool`, nullable variants
- **Control Flow**: `if`/`or`/`else` conditionals, `for` loops, `repeat`/`when`/`fixed` (switch-case)
- **Error Handling**: `try`/`catch`/`finally` blocks
- **Comments**: Single-line `//` and multi-line `/? ?/`

### 🚀 Quick Start Example

```litecode
// Define a function
fnc greet[text name]:text {
    return "Hello, " + name + "!";
}

// Main program entry point
run {
    val text USER_NAME = "World";
    text message = greet[USER_NAME];
    print[message];
};
```

### 📖 Learning Path

1. **Beginner**: Read Quick Reference → Try Hello World example
2. **Intermediate**: Study Syntax Guide → Work through all examples
3. **Advanced**: Review Language Specification → Build complex programs

For questions or contributions, see the main project repository.
