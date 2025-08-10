#!/usr/bin/env rdmd

module main;

import std.stdio;
import std.file;
import std.path;
import std.getopt;
import std.string;
import std.conv;
import std.process;

import lexer;
import parser;
import semantic;
import multiarch_codegen;
import platform;
import ast;

class CompilerError : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}

struct CompilerOptions {
    bool verbose = false;
    bool keepAssembly = false;
    string outputFile = "";
    bool showHelp = false;
    bool showVersion = false;
    string targetArch = ""; // Allow manual architecture override
}

void printUsage() {
    writeln("LiteCode Compiler (lcc) v0.1");
    writeln("Usage: lcc [options] <input.lc>");
    writeln();
    writeln("Options:");
    writeln("  -o <file>        Specify output file name");
    writeln("  -S               Keep assembly file");
    writeln("  -v, --verbose    Verbose output");
    writeln("  --target <arch>  Target architecture (x86_64, arm64, arm32)");
    writeln("  -h, --help      Show this help message");
    writeln("  --version       Show version information");
    writeln();
    writeln("Examples:");
    writeln("  lcc program.lc                    # Compile for current platform");
    writeln("  lcc -o hello program.lc           # Compile to 'hello'");
    writeln("  lcc --target arm64 program.lc     # Cross-compile for ARM64");
    writeln("  lcc -S program.lc                 # Keep assembly file");
}

void printVersion() {
    writeln("LiteCode Compiler (lcc) version 0.1");
    writeln("Built with D programming language");
    writeln("Supported targets: x86_64, ARM64, ARM32 Linux");
    
    // Show current platform
    auto platform = detectPlatform();
    writeln("Current platform: ", platform.platform);
    writeln("Architecture: ", platform.arch);
}

CompilerOptions parseArgs(string[] args) {
    CompilerOptions options;
    
    try {
        auto helpInformation = getopt(args,
            std.getopt.config.passThrough, // Allow unrecognized arguments
            "o|output", "Output file name", &options.outputFile,
            "S|keep-asm", "Keep assembly file", &options.keepAssembly,
            "v|verbose", "Verbose output", &options.verbose,
            "target", "Target architecture (x86_64, arm64, arm32)", &options.targetArch,
            "h|help", "Show help", &options.showHelp,
            "version", "Show version", &options.showVersion
        );
        
        if (helpInformation.helpWanted || options.showHelp) {
            options.showHelp = true;
        }
    } catch (Exception e) {
        throw new CompilerError("Error parsing command line arguments: " ~ e.msg);
    }
    
    return options;
}

void compile(string inputFile, CompilerOptions options) {
    if (options.verbose) {
        writeln("Compiling: ", inputFile);
    }
    
    // Check if input file exists
    if (!exists(inputFile)) {
        throw new CompilerError("Input file not found: " ~ inputFile);
    }
    
    // Read source code
    string sourceCode;
    try {
        sourceCode = readText(inputFile);
    } catch (Exception e) {
        throw new CompilerError("Failed to read input file: " ~ e.msg);
    }
    
    if (options.verbose) {
        writeln("Source code length: ", sourceCode.length, " characters");
    }
    
    // Lexical analysis
    if (options.verbose) {
        writeln("Starting lexical analysis...");
    }
    
    auto lexer = new Lexer(sourceCode);
    Token[] tokens;
    
    try {
        tokens = lexer.tokenize();
    } catch (Exception e) {
        throw new CompilerError("Lexical error: " ~ e.msg);
    }
    
    if (options.verbose) {
        writeln("Lexical analysis complete. Tokens: ", tokens.length);
    }
    
    // Syntax analysis
    if (options.verbose) {
        writeln("Starting syntax analysis...");
    }
    
    auto parser = new Parser(tokens);
    Program program;
    
    try {
        program = parser.parse();
    } catch (Exception e) {
        throw new CompilerError("Syntax error: " ~ e.msg);
    }
    
    if (options.verbose) {
        writeln("Syntax analysis complete.");
        writeln("Functions: ", program.functions.length);
        writeln("Run block statements: ", program.runBlock.statements.length);
    }
    
    // Semantic analysis
    if (options.verbose) {
        writeln("Starting semantic analysis...");
    }
    
    auto analyzer = new SemanticAnalyzer();
    
    try {
        analyzer.analyze(program);
    } catch (Exception e) {
        throw new CompilerError("Semantic error: " ~ e.msg);
    }
    
    if (options.verbose) {
        writeln("Semantic analysis complete.");
    }
    
    // Determine target platform
    PlatformInfo targetPlatform;
    if (options.targetArch.length > 0) {
        // Manual architecture override
        switch (options.targetArch.toLower()) {
            case "x86_64":
            case "x86-64":
            case "amd64":
                targetPlatform = PlatformInfo(Architecture.X86_64, Platform.LINUX_X86_64);
                break;
            case "arm64":
            case "aarch64":
                targetPlatform = PlatformInfo(Architecture.ARM64, Platform.LINUX_ARM64);
                break;
            case "arm32":
            case "arm":
            case "armv7":
                targetPlatform = PlatformInfo(Architecture.ARM32, Platform.LINUX_ARM32);
                break;
            default:
                throw new CompilerError("Unsupported target architecture: " ~ options.targetArch);
        }
    } else {
        // Auto-detect platform
        targetPlatform = detectPlatform();
    }
    
    if (options.verbose) {
        writeln("Target platform: ", targetPlatform.platform);
        writeln("Target architecture: ", targetPlatform.arch);
        
        // Check if we have the required toolchain
        if (!hasToolchain(targetPlatform)) {
            writeln("Warning: Target toolchain not found. Install cross-compilation tools:");
            switch (targetPlatform.arch) {
                case Architecture.ARM64:
                    writeln("  sudo apt-get install gcc-aarch64-linux-gnu");
                    break;
                case Architecture.ARM32:
                    writeln("  sudo apt-get install gcc-arm-linux-gnueabihf");
                    break;
                default:
                    break;
            }
        }
    }
    
    // Determine output files
    string baseName = stripExtension(baseName(inputFile));
    string outputFile = options.outputFile.length > 0 ? options.outputFile : baseName;
    string asmFile = baseName ~ ".s";
    
    // Code generation
    if (options.verbose) {
        writeln("Starting code generation...");
        writeln("Assembly file: ", asmFile);
        writeln("Output file: ", outputFile);
    }
    
    try {
        auto generator = createCodeGenerator(targetPlatform.arch);
        string assemblyCode = generator.generateCode(program);
        std.file.write(asmFile, assemblyCode);
    } catch (Exception e) {
        throw new CompilerError("Code generation error: " ~ e.msg);
    }
    
    if (options.verbose) {
        writeln("Code generation complete.");
    }
    
    // Assembly and linking
    if (options.verbose) {
        writeln("Starting assembly and linking...");
    }
    
    try {
        assembleAndLink(asmFile, outputFile, targetPlatform);
    } catch (Exception e) {
        throw new CompilerError("Assembly/linking error: " ~ e.msg);
    }
    
    // Clean up assembly file unless requested to keep it
    if (!options.keepAssembly && exists(asmFile)) {
        try {
            remove(asmFile);
        } catch (Exception e) {
            // Non-fatal error
            if (options.verbose) {
                writeln("Warning: Could not remove assembly file: ", e.msg);
            }
        }
    }
    
    if (options.verbose) {
        writeln("Compilation successful!");
        writeln("Output: ", outputFile);
    } else {
        writeln("Compiled successfully: ", outputFile);
    }
}

int main(string[] args) {
    CompilerOptions options;
    
    try {
        options = parseArgs(args);
    } catch (CompilerError e) {
        stderr.writeln("Error: ", e.msg);
        return 1;
    }
    
    if (options.showVersion) {
        printVersion();
        return 0;
    }
    
    if (options.showHelp) {
        printUsage();
        return 0;
    }
    
    // After getopt processing, args contains remaining unprocessed arguments
    // args[0] is still the program name, so actual file arguments start at args[1]
    if (args.length < 2) {
        stderr.writeln("Error: No input file specified");
        printUsage();
        return 1;
    }
    
    string inputFile = args[1]; // First non-option argument should be input file
    
    // Validate input file extension
    if (!inputFile.endsWith(".lc")) {
        stderr.writeln("Warning: Input file should have .lc extension");
    }
    
    try {
        compile(inputFile, options);
    } catch (CompilerError e) {
        stderr.writeln("Compilation failed: ", e.msg);
        return 1;
    } catch (Exception e) {
        stderr.writeln("Internal compiler error: ", e.msg);
        return 1;
    }
    
    return 0;
}

void assembleAndLink(string asmFile, string outputFile, PlatformInfo platform) {
    string objFile = outputFile ~ ".o";
    
    // Assemble
    string[] assembleCmd = [platform.assembler] ~ platform.assemblerFlags ~ ["-o", objFile, asmFile];
    auto assembleResult = execute(assembleCmd);
    if (assembleResult.status != 0) {
        throw new Exception("Assembly failed: " ~ assembleResult.output);
    }
    
    // Link
    string[] linkCmd = [platform.linker] ~ platform.linkerFlags ~ ["-o", outputFile, objFile];
    auto linkResult = execute(linkCmd);
    if (linkResult.status != 0) {
        throw new Exception("Linking failed: " ~ linkResult.output);
    }
    
    // Clean up object file
    std.file.remove(objFile);
}
