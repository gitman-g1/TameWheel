#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

CONFIGURATION="${1:-debug}"
ARCHITECTURE="${3:-native}"
case "$CONFIGURATION" in
    debug|release) ;;
    *) printf 'Usage: bash scripts/build-app.sh [debug|release] [output-directory] [native|arm64|x86_64]\n' >&2; exit 1 ;;
esac
case "$ARCHITECTURE" in
    native|arm64|x86_64) ;;
    *) printf 'Unsupported architecture: %s\n' "$ARCHITECTURE" >&2; exit 1 ;;
esac

# 将编译缓存留在项目内，方便清理，也避免依赖全局缓存目录。
mkdir -p .build/cache .build/clang-module-cache
export CLANG_MODULE_CACHE_PATH="$PROJECT_DIR/.build/clang-module-cache"

BUILD_OPTIONS=(--configuration "$CONFIGURATION" --cache-path "$PROJECT_DIR/.build/cache")
if [[ "$ARCHITECTURE" != native ]]; then
    BUILD_OPTIONS+=(--arch "$ARCHITECTURE")
fi
xcrun swift build "${BUILD_OPTIONS[@]}"
BINARY_DIR="$(xcrun swift build "${BUILD_OPTIONS[@]}" --show-bin-path)"
APP_DIR="${2:-$PROJECT_DIR/dist}/TameWheel.app"

mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BINARY_DIR/TameWheel" "$APP_DIR/Contents/MacOS/TameWheel"
cp Support/Info.plist "$APP_DIR/Contents/Info.plist"
cp Support/AppIcon.icns "$APP_DIR/Contents/Resources/AppIcon.icns"

# 本机临时签名，不依赖 Apple 开发者账号，也不等同于公证。
codesign --force --sign - "$APP_DIR"
printf '\nBuilt: %s\n' "$APP_DIR"
