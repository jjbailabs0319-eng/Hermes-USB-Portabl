#!/usr/bin/env bash
set -e

# 1. Dynamic Path Detection
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT="$SCRIPT_DIR"

# 2. Configure Local .tmp Cache (Host Leakage Prevention)
TMPDIR="$ROOT/.tmp"
export npm_config_cache="$TMPDIR/npm-cache"
export NODE_ENV="production"

mkdir -p "$TMPDIR/npm-cache"

# 3. Detect Platform & Register local node/npm onto temporary PATH
UNAME_OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$UNAME_OS:$ARCH" in
  linux:x86_64) PLATFORM="linux-x64" ;;
  linux:aarch64|linux:arm64) PLATFORM="linux-arm64" ;;
  darwin:x86_64) PLATFORM="macos-x64" ;;
  darwin:arm64) PLATFORM="macos-arm64" ;;
  *)
    echo "[Hermes] Unsupported OS/CPU: $UNAME_OS/$ARCH"
    exit 1
    ;;
esac

NODE_BIN="$ROOT/runtime/$PLATFORM/bin"
export PATH="$NODE_BIN:$PATH"

echo "=================================================="
echo "[Hermes] Starting Portable Shell & Path Virtualizer"
echo "[Hermes] ROOT=$ROOT"
echo "[Hermes] CACHE=$TMPDIR"
echo "=================================================="

# Install dependencies if node_modules does not exist
if [ ! -d "$ROOT/node_modules" ]; then
    echo "[Hermes] Installing core dependencies locally..."
    npm install --cache "$npm_config_cache"
fi

# 4. Start Core Execution
echo "[Hermes] Launching Engine..."
npm start
