#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"
mkdir -p .build/cache .build/clang-module-cache
export CLANG_MODULE_CACHE_PATH="$PROJECT_DIR/.build/clang-module-cache"

TEST_OPTIONS=(--cache-path "$PROJECT_DIR/.build/cache")
SWIFT_COMPILER="$(xcrun --find swiftc)"
TEST_PLUGIN="$(dirname "$SWIFT_COMPILER")/../lib/swift/host/plugins/testing/libTestingMacros.dylib"
# 部分 Command Line Tools 的 Swift Build 未自动加载自带的 Testing 宏。
if [[ -f "$TEST_PLUGIN" ]]; then
    TEST_OPTIONS+=(-Xswiftc -load-plugin-library -Xswiftc "$TEST_PLUGIN")
fi
xcrun swift test "${TEST_OPTIONS[@]}"
