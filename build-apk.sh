#!/bin/bash
# filepath: /workspaces/Dictate/build-apk.sh

# Default values
BUILD_TYPE="debug"
CLEAN_BUILD=false
OUTPUT_DIR="./build-output"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --release)
            BUILD_TYPE="release"
            shift
            ;;
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [--release] [--clean] [--output DIR] [--help]"
            echo "  --release     Build release APK instead of debug"
            echo "  --clean       Clean build (remove existing containers/images)"
            echo "  --output DIR  Specify output directory (default: ./build-output)"
            echo "  --help        Show this help message"
            echo ""
            echo "Output filename will be: dictate-v[VERSION]-[BUILD_TYPE].apk"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "🚀 Building Dictate APK ($BUILD_TYPE)..."

# Get version from build.gradle for display
VERSION=$(grep 'versionName' app/build.gradle | sed 's/.*"\(.*\)".*/\1/' 2>/dev/null || echo "unknown")
echo "📋 Version: $VERSION"
echo "📄 Output filename: dictate-v$VERSION-$BUILD_TYPE.apk"

# Clean if requested
if [ "$CLEAN_BUILD" = true ]; then
    echo "🧹 Cleaning existing Docker artifacts..."
    docker rmi dictate-builder 2>/dev/null || true
    rm -rf "$OUTPUT_DIR"
fi

# Build Docker image
echo "📦 Building Docker image..."
docker build -t dictate-builder .

if [ $? -ne 0 ]; then
    echo "❌ Docker build failed!"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Run container and build APK
echo "🔨 Building $BUILD_TYPE APK in container..."
if [ "$BUILD_TYPE" = "release" ]; then
    docker run --rm -v $(pwd)/$OUTPUT_DIR:/shared -e BUILD_TYPE=release dictate-builder
else
    docker run --rm -v $(pwd)/$OUTPUT_DIR:/shared dictate-builder
fi

if [ $? -eq 0 ]; then
    echo "✅ APK built successfully!"
    echo "📱 APK location: $OUTPUT_DIR/"
    echo "📄 Generated files:"
    ls -la "$OUTPUT_DIR/" | grep -E "\\.apk$" | while read line; do
        echo "   📦 $line"
    done
else
    echo "❌ APK build failed!"
    exit 1
fi