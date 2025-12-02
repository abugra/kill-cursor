#!/bin/bash

# Build script for KillCursor macOS app

set -e

echo "Building KillCursor..."

# Create build directory
mkdir -p build

# Compile Swift code
swiftc -o build/KillCursor \
    -target x86_64-apple-macosx11.0 \
    KillCursor/KillCursor.swift

# Create app bundle structure
APP_DIR="build/KillCursor.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy executable
cp build/KillCursor "$APP_DIR/Contents/MacOS/"

# Copy Info.plist
cp Info.plist "$APP_DIR/Contents/"

# Create icon set and convert to .icns
if [ -f "AppIcon.icon/Assets/skull.png" ]; then
    echo "Creating app icon..."
    ICONSET_DIR="build/KillCursor.iconset"
    mkdir -p "$ICONSET_DIR"
    
    # Copy PNG and create different sizes for icon set
    ICON_SOURCE="AppIcon.icon/Assets/skull.png"
    
    # Create required icon sizes
    sips -z 16 16 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16.png" > /dev/null 2>&1
    sips -z 32 32 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null 2>&1
    sips -z 32 32 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32.png" > /dev/null 2>&1
    sips -z 64 64 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null 2>&1
    sips -z 128 128 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128.png" > /dev/null 2>&1
    sips -z 256 256 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null 2>&1
    sips -z 256 256 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256.png" > /dev/null 2>&1
    sips -z 512 512 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null 2>&1
    sips -z 512 512 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_512x512.png" > /dev/null 2>&1
    sips -z 1024 1024 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null 2>&1
    
    # Convert iconset to icns
    iconutil -c icns "$ICONSET_DIR" -o "$APP_DIR/Contents/Resources/AppIcon.icns" 2>/dev/null || {
        # Fallback: if iconutil fails, just copy the PNG
        echo "Warning: iconutil failed, using PNG directly"
        cp "$ICON_SOURCE" "$APP_DIR/Contents/Resources/AppIcon.png"
    }
    
    # Clean up iconset directory
    rm -rf "$ICONSET_DIR"
fi

# Create status bar icons from icon-dark.png and icon-light.png
if [ -f "icon-dark.png" ] && [ -f "icon-light.png" ]; then
    echo "Creating status bar icons from icon-dark.png and icon-light.png..."
    # Status bar icons: macOS uses 22x22 for normal, 44x44 for retina (@2x)
    # Create dark mode icons
    sips -z 22 22 "icon-dark.png" --out "$APP_DIR/Contents/Resources/StatusBarIconDark.png" > /dev/null 2>&1
    sips -z 44 44 "icon-dark.png" --out "$APP_DIR/Contents/Resources/StatusBarIconDark@2x.png" > /dev/null 2>&1
    # Create light mode icons
    sips -z 22 22 "icon-light.png" --out "$APP_DIR/Contents/Resources/StatusBarIconLight.png" > /dev/null 2>&1
    sips -z 44 44 "icon-light.png" --out "$APP_DIR/Contents/Resources/StatusBarIconLight@2x.png" > /dev/null 2>&1
fi

echo "Build complete! App is at: $APP_DIR"
echo "To run: open $APP_DIR"

