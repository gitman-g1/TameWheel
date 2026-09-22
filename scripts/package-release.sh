#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Support/Info.plist)"
OUTPUT_DIR="${1:-$PROJECT_DIR/dist/releases}"
mkdir -p "$OUTPUT_DIR" "$PROJECT_DIR/.build"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"
STAGING_DIR="$(mktemp -d "$PROJECT_DIR/.build/package-release.XXXXXX")"
trap 'rm -rf "$STAGING_DIR"' EXIT

# Build both slices without touching the user's currently running dist/TameWheel.app.
bash scripts/build-app.sh release "$STAGING_DIR/arm64" arm64
bash scripts/build-app.sh release "$STAGING_DIR/x86_64" x86_64

IMAGE_DIR="$STAGING_DIR/image"
APP_DIR="$IMAGE_DIR/TameWheel.app"
mkdir -p "$IMAGE_DIR"
ditto "$STAGING_DIR/arm64/TameWheel.app" "$APP_DIR"
xcrun lipo -create \
    "$STAGING_DIR/arm64/TameWheel.app/Contents/MacOS/TameWheel" \
    "$STAGING_DIR/x86_64/TameWheel.app/Contents/MacOS/TameWheel" \
    -output "$APP_DIR/Contents/MacOS/TameWheel"

# This public testing build uses an ad-hoc signature, not Developer ID notarization.
codesign --force --sign - "$APP_DIR"
codesign --verify --strict --all-architectures "$APP_DIR"
for ARCHITECTURE in arm64 x86_64; do
    xcrun lipo "$APP_DIR/Contents/MacOS/TameWheel" -verify_arch "$ARCHITECTURE"
done
plutil -lint "$APP_DIR/Contents/Info.plist"

PACKAGE_NAME="TameWheel-$VERSION-universal"
ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$OUTPUT_DIR/$PACKAGE_NAME.zip"
ln -s /Applications "$IMAGE_DIR/Applications"
cp Support/Install.txt "$IMAGE_DIR/安装说明 Installation.txt"
hdiutil create -volname "TameWheel $VERSION" -srcfolder "$IMAGE_DIR" \
    -format UDZO -ov "$OUTPUT_DIR/$PACKAGE_NAME.dmg"

(
    cd "$OUTPUT_DIR"
    shasum -a 256 "$PACKAGE_NAME.dmg" "$PACKAGE_NAME.zip" > SHA256SUMS.txt
)
printf '\nRelease assets: %s\n' "$OUTPUT_DIR"
printf 'Version: %s · Apple Silicon + Intel · ad-hoc signed\n' "$VERSION"
