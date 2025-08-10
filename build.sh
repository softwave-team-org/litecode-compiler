#!/bin/bash

# LiteCode Compiler Build Script

set -e

echo "🚀 Building LiteCode Compiler (lcc)..."

# Check if dmd is available
if ! command -v dmd &> /dev/null; then
    echo "❌ Error: DMD compiler not found. Please install DMD or LDC2."
    exit 1
fi

# Detect current platform
ARCH=$(uname -m)
echo "📋 Current architecture: $ARCH"

# Build the compiler
echo "⚙️  Compiling source files..."
dub build --build=release

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ LiteCode compiler built successfully!"
    echo "📁 Executable: ./lcc"
    echo ""
    echo "🎯 Multi-architecture support:"
    echo "  • x86_64 (Intel/AMD 64-bit)"
    echo "  • ARM64 (AArch64)"
    echo "  • ARM32 (ARMv7)"
    echo ""
    echo "📖 Usage examples:"
    echo "  ./lcc program.lc                   # Compile for current platform ($ARCH)"
    echo "  ./lcc --target arm64 program.lc    # Cross-compile for ARM64"
    echo "  ./lcc --target arm32 program.lc    # Cross-compile for ARM32"
    echo "  ./lcc --version                    # Show version and platform info"
    echo ""
    echo "🛠️  To install cross-compilation toolchains:"
    echo "  ./install-toolchains.sh"
    echo ""
    echo "🧪 Test the compiler:"
    echo "  ./lcc examples/hello.lc"
else
    echo "❌ Build failed!"
    exit 1
fi
