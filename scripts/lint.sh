#!/bin/bash

# Run SwiftLint using the pre-built binary
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
SWIFTLINT_BIN="$PROJECT_ROOT/binaries/swiftlint"

if [ ! -f "$SWIFTLINT_BIN" ]; then
    echo "Error: SwiftLint binary not found at $SWIFTLINT_BIN"
    exit 1
fi

# Make sure the binary is executable
chmod +x "$SWIFTLINT_BIN"

# Run SwiftLint
"$SWIFTLINT_BIN" "$@"