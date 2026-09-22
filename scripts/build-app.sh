#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

CONFIGURATION="${1:-debug}"
case "$CONFIGURATION" in
    debug|release) ;;
    *) printf 'Usage: bash scripts/build-app.sh [debug|release] [output-directory]\n' >&2; exit 1 ;;
esac

# 将编译缓存留在项目内，方便清理，也避免依赖全局缓存目录。
mkdir -p .build/cache .build/clang-module-cache
export CLANG_MODULE_CACHE_PATH="$PROJECT_DIR/.build/clang-module-cache"

BUILD_OPTIONS=(--configuration "$CONFIGURATION" --cache-path "$PROJECT_DIR/.build/cache")
xcrun swift build "${BUILD_OPTIONS[@]}"
BINARY_DIR="$(xcrun swift build "${BUILD_OPTIONS[@]}" --show-bin-path)"
APP_DIR="${2:-$PROJECT_DIR/dist}/ScrollMate.app"

mkdir -p "$APP_DIR/Contents/MacOS"
cp "$BINARY_DIR/ScrollMate" "$APP_DIR/Contents/MacOS/ScrollMate"
cp Support/Info.plist "$APP_DIR/Contents/Info.plist"

# 本机临时签名，不依赖 Apple 开发者账号，也不等同于公证。
codesign --force --sign - "$APP_DIR"
printf '\nBuilt: %s\n' "$APP_DIR"
