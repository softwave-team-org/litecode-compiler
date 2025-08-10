#!/bin/bash

# LiteCode Cross-Compilation Toolchain Installer

echo "🛠️  LiteCode Cross-Compilation Toolchain Installer"
echo ""

# Detect current platform
ARCH=$(uname -m)
echo "Current architecture: $ARCH"

# Check if we're on a Debian/Ubuntu system
if command -v apt-get &> /dev/null; then
    echo "Detected Debian/Ubuntu system"
    echo ""
    
    echo "Installing cross-compilation toolchains..."
    
    # Install ARM64 toolchain
    echo "📦 Installing ARM64 (aarch64) toolchain..."
    sudo apt-get update
    sudo apt-get install -y gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu
    
    # Install ARM32 toolchain  
    echo "📦 Installing ARM32 (armhf) toolchain..."
    sudo apt-get install -y gcc-arm-linux-gnueabihf binutils-arm-linux-gnueabihf
    
    echo ""
    echo "✅ Cross-compilation toolchains installed!"
    echo ""
    echo "You can now cross-compile LiteCode programs:"
    echo "  ./lcc --target arm64 program.lc   # Compile for ARM64"
    echo "  ./lcc --target arm32 program.lc   # Compile for ARM32"
    
elif command -v dnf &> /dev/null; then
    echo "Detected Fedora/RHEL system"
    echo ""
    
    echo "Installing cross-compilation toolchains..."
    
    # Install ARM64 toolchain
    echo "📦 Installing ARM64 (aarch64) toolchain..."
    sudo dnf install -y gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu
    
    # Install ARM32 toolchain
    echo "📦 Installing ARM32 (armhf) toolchain..."
    sudo dnf install -y gcc-arm-linux-gnu binutils-arm-linux-gnu
    
    echo ""
    echo "✅ Cross-compilation toolchains installed!"
    
elif command -v pacman &> /dev/null; then
    echo "Detected Arch Linux system"
    echo ""
    
    echo "Installing cross-compilation toolchains..."
    
    # Install ARM toolchains from AUR (requires manual installation)
    echo "📦 For Arch Linux, install from AUR:"
    echo "  yay -S aarch64-linux-gnu-gcc"
    echo "  yay -S arm-linux-gnueabihf-gcc"
    echo ""
    echo "Or use the official repositories if available"
    
else
    echo "Unknown package manager. Please install cross-compilation toolchains manually:"
    echo ""
    echo "For ARM64: gcc-aarch64-linux-gnu, binutils-aarch64-linux-gnu"
    echo "For ARM32: gcc-arm-linux-gnueabihf, binutils-arm-linux-gnueabihf"
fi

echo ""
echo "🧪 Testing toolchains..."

# Test ARM64 toolchain
if command -v aarch64-linux-gnu-as &> /dev/null; then
    echo "✅ ARM64 assembler found"
else
    echo "❌ ARM64 assembler not found"
fi

if command -v aarch64-linux-gnu-ld &> /dev/null; then
    echo "✅ ARM64 linker found"
else
    echo "❌ ARM64 linker not found"
fi

# Test ARM32 toolchain
if command -v arm-linux-gnueabihf-as &> /dev/null; then
    echo "✅ ARM32 assembler found"
else
    echo "❌ ARM32 assembler not found"
fi

if command -v arm-linux-gnueabihf-ld &> /dev/null; then
    echo "✅ ARM32 linker found"
else
    echo "❌ ARM32 linker not found"
fi

echo ""
echo "🎯 LiteCode is now ready for cross-compilation!"
echo ""
echo "Usage examples:"
echo "  ./lcc --version                    # Show supported targets"
echo "  ./lcc program.lc                   # Compile for current platform"
echo "  ./lcc --target x86_64 program.lc   # Compile for x86_64"
echo "  ./lcc --target arm64 program.lc    # Compile for ARM64"
echo "  ./lcc --target arm32 program.lc    # Compile for ARM32"
