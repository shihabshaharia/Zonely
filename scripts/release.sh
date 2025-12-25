#!/bin/bash
set -e

# --- GET PROJECT ROOT (Absolute Path) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# --- CONFIGURATION ---
APP_NAME="Zonely"
SCHEME_NAME="Zonly"
VERSION=$(grep -o 'current = "[^"]*"' Sources/AppVersion.swift | cut -d'"' -f2)

# Define paths (using absolute paths)
DIST_DIR="$PROJECT_ROOT/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
DMG_NAME_FINAL="$DIST_DIR/${APP_NAME}_v${VERSION}.dmg"

# Background Image
BG_IMAGE="$PROJECT_ROOT/art/background.png"

echo "🚀 Starting Optimal Release for $APP_NAME v$VERSION..."
echo "   📁 Project root: $PROJECT_ROOT"

# 1. CLEAN & BUILD
echo "🔨 Building..."
rm -rf .build "$DIST_DIR"
mkdir -p "$DIST_DIR"

# Build Release
swift build -c release -Xswiftc -DRELEASE --product "$SCHEME_NAME" 2>&1 | grep -v "warning:"

# Create .app Bundle
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"
cp ".build/release/$SCHEME_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Generate Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.shihabshaharia.zonely</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

# 2. GENERATE COMPRESSED ZIP
echo "🗜️  Generating ZIP..."
(cd "$DIST_DIR" && zip -r -q "${APP_NAME}_v${VERSION}.zip" "$APP_NAME.app")

# 3. GENERATE PROFESSIONAL DMG (Using dmgbuild)
echo "💿 Generating Professional DMG..."

# Export variables for dmgbuild script
export DMG_NAME="$DMG_NAME_FINAL"
export VOL_NAME="$APP_NAME Installer"
export APP_PATH="$APP_BUNDLE"
export BG_IMAGE="$BG_IMAGE"

if [ -f "$BG_IMAGE" ]; then
    echo "   ✅ Using background: $BG_IMAGE"
else
    echo "   ⚠️ Warning: Background image not found at $BG_IMAGE"
fi

# Run dmgbuild
# We use the python script we created
dmgbuild -s "$PROJECT_ROOT/scripts/dmg_settings.py" "$VOL_NAME" "$DMG_NAME_FINAL"

echo "✅ BOOM! Done."
echo "   📂 ZIP: $DIST_DIR/${APP_NAME}_v${VERSION}.zip"
echo "   📂 DMG: $DMG_NAME_FINAL"

# Clean up build artifacts if needed, but keeping them in dist for now
open "$DIST_DIR"