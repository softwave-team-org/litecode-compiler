module platform;

import std.process;
import std.string;
import std.conv;

enum Architecture {
    X86_64,
    ARM64,
    ARM32
}

enum Platform {
    LINUX_X86_64,
    LINUX_ARM64, 
    LINUX_ARM32
}

struct PlatformInfo {
    Architecture arch;
    Platform platform;
    string assembler;
    string linker;
    string[] assemblerFlags;
    string[] linkerFlags;
    
    this(Architecture arch, Platform platform) {
        this.arch = arch;
        this.platform = platform;
        
        // Set platform-specific tools and flags
        switch (platform) {
            case Platform.LINUX_X86_64:
                assembler = "as";
                linker = "ld";
                assemblerFlags = ["--64"];
                linkerFlags = [];
                break;
            case Platform.LINUX_ARM64:
                assembler = "aarch64-linux-gnu-as";
                linker = "aarch64-linux-gnu-ld";
                assemblerFlags = [];
                linkerFlags = [];
                break;
            case Platform.LINUX_ARM32:
                assembler = "arm-linux-gnueabihf-as";
                linker = "arm-linux-gnueabihf-ld";
                assemblerFlags = [];
                linkerFlags = [];
                break;
            default:
                assembler = "as";
                linker = "ld";
                assemblerFlags = [];
                linkerFlags = [];
                break;
        }
    }
}

PlatformInfo detectPlatform() {
    // Try to detect the current platform
    auto result = execute(["uname", "-m"]);
    if (result.status == 0) {
        string machine = strip(result.output);
        
        switch (machine) {
            case "x86_64":
                return PlatformInfo(Architecture.X86_64, Platform.LINUX_X86_64);
            case "aarch64":
                return PlatformInfo(Architecture.ARM64, Platform.LINUX_ARM64);
            case "armv7l":
            case "armv6l":
                return PlatformInfo(Architecture.ARM32, Platform.LINUX_ARM32);
            default:
                // Default to x86_64
                return PlatformInfo(Architecture.X86_64, Platform.LINUX_X86_64);
        }
    }
    
    // Fallback to x86_64
    return PlatformInfo(Architecture.X86_64, Platform.LINUX_X86_64);
}

bool hasToolchain(PlatformInfo platform) {
    // Check if the required assembler exists
    auto result = execute([platform.assembler, "--version"]);
    return result.status == 0;
}
