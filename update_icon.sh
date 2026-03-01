#!/bin/bash
set -e

SOURCE="/tmp/cropped_icon.png"
DEST_DIR="/Users/goodman/works/sseay/EyeBreak/Faraway/Assets.xcassets/AppIcon.appiconset"

mkdir -p "$DEST_DIR"

echo "Converting images..."
sips -s format png -z 16 16 "$SOURCE" --out "$DEST_DIR/icon_16x16.png"
sips -s format png -z 32 32 "$SOURCE" --out "$DEST_DIR/icon_16x16@2x.png"
sips -s format png -z 32 32 "$SOURCE" --out "$DEST_DIR/icon_32x32.png"
sips -s format png -z 64 64 "$SOURCE" --out "$DEST_DIR/icon_32x32@2x.png"
sips -s format png -z 128 128 "$SOURCE" --out "$DEST_DIR/icon_128x128.png"
sips -s format png -z 256 256 "$SOURCE" --out "$DEST_DIR/icon_128x128@2x.png"
sips -s format png -z 256 256 "$SOURCE" --out "$DEST_DIR/icon_256x256.png"
sips -s format png -z 512 512 "$SOURCE" --out "$DEST_DIR/icon_256x256@2x.png"
sips -s format png -z 512 512 "$SOURCE" --out "$DEST_DIR/icon_512x512.png"
sips -s format png -z 1024 1024 "$SOURCE" --out "$DEST_DIR/icon_512x512@2x.png"

echo "Done generating icons!"
