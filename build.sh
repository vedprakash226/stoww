#!/bin/bash
set -e

APP_NAME="Stow"
APP_DIR="$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
DMG_NAME="$APP_NAME.dmg"

echo "Building Swift Source via swiftc (bypassing SPM Sandbox)..."
mkdir -p .module-cache
swiftc $(find Sources -name "*.swift") -parse-as-library -module-cache-path .module-cache -o "$APP_NAME"

echo "Creating App Bundle..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

if [ -f "icon.png" ]; then
    echo "Generating AppIcon.icns from icon.png..."
    mkdir -p AppIcon.iconset
    sips -z 16 16     icon.png --out AppIcon.iconset/icon_16x16.png > /dev/null
    sips -z 32 32     icon.png --out AppIcon.iconset/icon_16x16@2x.png > /dev/null
    sips -z 32 32     icon.png --out AppIcon.iconset/icon_32x32.png > /dev/null
    sips -z 64 64     icon.png --out AppIcon.iconset/icon_32x32@2x.png > /dev/null
    sips -z 128 128   icon.png --out AppIcon.iconset/icon_128x128.png > /dev/null
    sips -z 256 256   icon.png --out AppIcon.iconset/icon_128x128@2x.png > /dev/null
    sips -z 256 256   icon.png --out AppIcon.iconset/icon_256x256.png > /dev/null
    sips -z 512 512   icon.png --out AppIcon.iconset/icon_256x256@2x.png > /dev/null
    sips -z 512 512   icon.png --out AppIcon.iconset/icon_512x512.png > /dev/null
    sips -z 1024 1024 icon.png --out AppIcon.iconset/icon_512x512@2x.png > /dev/null
    iconutil -c icns AppIcon.iconset
    rm -R AppIcon.iconset
    mv AppIcon.icns "$RESOURCES_DIR/"
fi

echo "Copying executable..."
mv "$APP_NAME" "$MACOS_DIR/$APP_NAME"

echo "Creating Info.plist..."
cat > "$CONTENTS_DIR/Info.plist" <<PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.stow</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
PLIST_EOF

echo "Signing App Bundle (Ad-hoc)..."
codesign --force --deep --sign - "$APP_DIR"

echo "Packaging into $DMG_NAME..."
rm -f "$DMG_NAME"
rm -rf build_dmg
mkdir -p build_dmg/Stow
cp -a "$APP_DIR" build_dmg/Stow/
ln -s /Applications build_dmg/Stow/Applications
hdiutil create -volname "Stow" -srcfolder build_dmg/Stow -ov -format UDZO "$DMG_NAME" > /dev/null
rm -rf build_dmg

echo "Done! App created at $APP_DIR and packaged as $DMG_NAME"
