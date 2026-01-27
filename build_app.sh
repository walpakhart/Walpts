#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT/Walpts"
swift build --disable-sandbox -c release
BIN="$ROOT/Walpts/.build/release/Walpts"
APP_DIR="$ROOT/build/Walpts.app"
ICON_SRC="$ROOT/Assets/AppIcon.svg"
BASE_PNG="$ROOT/build/AppIconBase.png"
ICONSET_DIR="$ROOT/build/AppIcon.iconset"
rm -rf "$APP_DIR"
rm -rf "$BASE_PNG" "$ICONSET_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
cat > "$APP_DIR/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Walpts</string>
    <key>CFBundleExecutable</key>
    <string>Walpts</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.walpts</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
</dict>
</plist>
EOF
sips -s format png "$ICON_SRC" --out "$BASE_PNG" >/dev/null
mkdir -p "$ICONSET_DIR"
sips -s format png "$BASE_PNG" --out "$ICONSET_DIR/icon_16x16.png" --resampleHeightWidth 16 16 >/dev/null
sips -s format png "$BASE_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png" --resampleHeightWidth 32 32 >/dev/null
sips -s format png "$BASE_PNG" --out "$ICONSET_DIR/icon_32x32.png" --resampleHeightWidth 32 32 >/dev/null
sips -s format png "$BASE_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png" --resampleHeightWidth 64 64 >/dev/null
sips -s format png "$BASE_PNG" --out "$ICONSET_DIR/icon_128x128.png" --resampleHeightWidth 128 128 >/dev/null
sips -s format png "$BASE_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png" --resampleHeightWidth 256 256 >/dev/null
sips -s format png "$BASE_PNG" --out "$ICONSET_DIR/icon_256x256.png" --resampleHeightWidth 256 256 >/dev/null
sips -s format png "$BASE_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png" --resampleHeightWidth 512 512 >/dev/null
sips -s format png "$BASE_PNG" --out "$ICONSET_DIR/icon_512x512.png" --resampleHeightWidth 512 512 >/dev/null
sips -s format png "$BASE_PNG" --out "$ICONSET_DIR/icon_512x512@2x.png" --resampleHeightWidth 1024 1024 >/dev/null
iconutil -c icns "$ICONSET_DIR" -o "$APP_DIR/Contents/Resources/AppIcon.icns"
cp "$BIN" "$APP_DIR/Contents/MacOS/Walpts"
chmod +x "$APP_DIR/Contents/MacOS/Walpts"
