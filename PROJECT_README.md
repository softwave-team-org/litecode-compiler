# LiteCode Programming Language Compiler (lcc)

LiteCode is a minimal, general-purpose programming language designed to prioritize programmer ergonomics, simplicity, and safety. The compiler is written in D programming language with multi-architecture assembly code generation.

## Key Features

- **Ergonomic Syntax**: Uses `[]` for arrays and control structures, `@` for function calls to reduce finger strain
- **Mandatory Entry Point**: Programs must be written within a `run { ... };` block
- **Constant Values**: `val` keyword declares immutable variables, preventing reassignment
- **Null Safety**: Non-nullable types by default, with `?` for nullable types
- **Minimal Constructs**: Supports variables, constants, functions, conditionals, C-like for loops, error handling, and enhanced I/O
- **C-like Logical Operators**: Uses `&&`, `||`, and `!!` for boolean operations
- **Multi-Architecture Support**: Targets x86_64, ARM64 (AArch64), and ARM32 (ARMv7) on Linux

## Example Program

```litecode
fnc add[num a, num b]:num {
  return a + b;
}

run {
  val num x = 5;
  val num y = 3;
  num result = @add[x, y];
  @print["Result: $result"];
};
```

## Building and Running

### Prerequisites
- DMD (D compiler) or LDC2
- GNU Assembler (gas)
- GNU Linker (ld)
- For cross-compilation: binutils-aarch64-linux-gnu, binutils-arm-linux-gnueabihf

### Build the Compiler
```bash
dub build --build=release
```

### Install Cross-Compilation Toolchains
```bash
sudo apt-get install binutils-aarch64-linux-gnu binutils-arm-linux-gnueabihf
# Or run the provided script:
./install-toolchains.sh
```

### Compile and Run a Program
```bash
# Compile for current platform
./lcc examples/01_hello_world.lc

# Cross-compile for ARM64
./lcc --target arm64 examples/01_hello_world.lc

# Verbose output and keep assembly
./lcc -v -S examples/01_hello_world.lc
```

## Syntax Overview

### Variables and Constants
```litecode
num x = 10;           // Mutable variable
val num PI = 3.14;    // Immutable constant
text? name = null;    // Nullable type
```

### Functions
```litecode
fnc functionName[type param]:returnType {
    return value;
}

// Call with @ prefix
num result = @functionName[argument];
```

### Arrays
```litecode
num[] numbers = [1, 2, 3, 4, 5];  // Array declaration
num firstElement = numbers[0];     // Array access
numbers[1] = 10;                   // Array assignment
```

### Control Flow
```litecode
if [condition] {
    // code
} or [otherCondition] {
    // code
} else {
    // code
}

for [num i = 0; i < 10; i = i + 1] {
    @print["Loop: $i"];
}
```

## Documentation

Comprehensive documentation is available in the `docs/` directory:
- **[Quick Reference](docs/quick_reference.md)** - Cheat sheet for quick lookup
- **[Syntax Guide](docs/syntax_guide.md)** - Complete language reference with examples
- **[Language Specification](docs/language_spec.md)** - Formal language specification

## Examples

The `examples/` directory contains practical code samples:
- **01_hello_world.lc** - Basic program structure and comments
- **02_variables_types.lc** - All data types and variable usage
- **03_constants.lc** - Constants with `val` keyword
- **04_functions.lc** - Function definitions and calls
- **05_control_flow.lc** - Conditionals and logical operators
- **06_loops.lc** - For loops and iteration
- **07_null_safety.lc** - Nullable types and null checking
- **08_input_output.lc** - User input and output formatting

## Architecture Support

LiteCode compiler supports cross-compilation for multiple architectures:

| Architecture | Platform | Status |
|-------------|----------|---------|
| x86_64 | Linux | ✅ Supported |
| ARM64 (AArch64) | Linux | ✅ Supported |
| ARM32 (ARMv7) | Linux | ✅ Supported |

## Language Philosophy

LiteCode prioritizes:
1. **Simplicity**: Minimal syntax with clear semantics
2. **Safety**: Null safety and immutable constants by default
3. **Ergonomics**: Comfortable syntax for frequent operations
4. **Performance**: Direct compilation to native assembly
5. **Portability**: Multi-architecture support

## Contributing

Contributions are welcome! Please read the documentation and examine the examples before contributing.

## License

MIT License - see LICENSE file for details.
