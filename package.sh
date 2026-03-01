#!/bin/bash
# EyeBreak - Package Script
# Runs build.sh, builds the DMG with create-dmg, and sets the DMG icon

set -e

echo "🌻 Building App..."
./build.sh

echo "📦 Creating DMG Package..."
rm -f Faraway.dmg
create-dmg \
  --volname "Faraway" \
  --background "Faraway/png/DMG安装器背景.png" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "Faraway.app" 150 190 \
  --hide-extension "Faraway.app" \
  --app-drop-link 450 190 \
  "Faraway.dmg" \
  "output/Faraway.app"

echo "🎨 Setting DMG File Icon..."
swift set_dmg_icon.swift "output/Faraway.app/Contents/Resources/AppIcon.icns" "Faraway.dmg"

echo "✅ All Done! Faraway.dmg is ready."
