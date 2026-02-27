#!/bin/bash
# EyeBreak - Build Script
# 在 Mac 上运行这个脚本来编译 App

set -e

echo "🌻 Building EyeBreak..."
echo ""

# Build the app
xcodebuild -project EyeBreak.xcodeproj \
    -scheme EyeBreak \
    -configuration Release \
    -derivedDataPath build \
    clean build

# Find the built app
APP_PATH=$(find build -name "EyeBreak.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Build failed - app not found"
    exit 1
fi

# Copy to output
mkdir -p output
cp -R "$APP_PATH" output/EyeBreak.app

echo ""
echo "✅ Build successful!"
echo "📍 App location: output/EyeBreak.app"
echo ""
echo "To install:"
echo "  1. Drag 'output/EyeBreak.app' to /Applications"
echo "  2. Double-click to launch"
echo "  3. The 👁️ icon will appear in your menu bar"
echo ""
echo "🌻 Made with care"
