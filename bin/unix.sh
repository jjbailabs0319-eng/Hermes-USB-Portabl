#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
NODE_VERSION="v20.11.1"

UNAME_OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$UNAME_OS:$ARCH" in
  linux:x86_64)
    PLATFORM="linux-x64"
    NODE_ARCH="x64"
    NODE_TARBALL="node-$NODE_VERSION-linux-$NODE_ARCH.tar.xz"
    NODE_URL="https://nodejs.org/dist/$NODE_VERSION/$NODE_TARBALL"
    EXTRACT_FLAG="-xJf"
    EXTRACTED_DIR="$ROOT/runtime/node-$NODE_VERSION-linux-$NODE_ARCH"
    ;;
  linux:aarch64|linux:arm64)
    PLATFORM="linux-arm64"
    NODE_ARCH="arm64"
    NODE_TARBALL="node-$NODE_VERSION-linux-$NODE_ARCH.tar.xz"
    NODE_URL="https://nodejs.org/dist/$NODE_VERSION/$NODE_TARBALL"
    EXTRACT_FLAG="-xJf"
    EXTRACTED_DIR="$ROOT/runtime/node-$NODE_VERSION-linux-$NODE_ARCH"
    ;;
  darwin:x86_64)
    PLATFORM="macos-x64"
    NODE_ARCH="x64"
    NODE_TARBALL="node-$NODE_VERSION-darwin-$NODE_ARCH.tar.gz"
    NODE_URL="https://nodejs.org/dist/$NODE_VERSION/$NODE_TARBALL"
    EXTRACT_FLAG="-xzf"
    EXTRACTED_DIR="$ROOT/runtime/node-$NODE_VERSION-darwin-$NODE_ARCH"
    ;;
  darwin:arm64)
    PLATFORM="macos-arm64"
    NODE_ARCH="arm64"
    NODE_TARBALL="node-$NODE_VERSION-darwin-$NODE_ARCH.tar.gz"
    NODE_URL="https://nodejs.org/dist/$NODE_VERSION/$NODE_TARBALL"
    EXTRACT_FLAG="-xzf"
    EXTRACTED_DIR="$ROOT/runtime/node-$NODE_VERSION-darwin-$NODE_ARCH"
    ;;
  *)
    echo "Unsupported OS/CPU: $UNAME_OS/$ARCH"
    exit 1
    ;;
esac

PORTABLE_ENV_ROOT=$ROOT PORTABLE_ENV_PLATFORM=$PLATFORM . "$SCRIPT_DIR/portable-env.sh"

RUNTIME_DIR="$ROOT/runtime/$PLATFORM"
NODE_BIN="$RUNTIME_DIR/bin/node"
NPM_BIN="$RUNTIME_DIR/bin/npm"
DOWNLOAD_PATH="$ROOT/runtime/downloads/$NODE_TARBALL"

log() {
  printf '[portable-hermes-agent] %s\n' "$1"
}

download_file() {
  url=$1
  out=$2
  tmp="$out.partial"
  rm -f "$tmp"
  if command -v curl >/dev/null 2>&1; then
    curl -L --fail --progress-bar "$url" -o "$tmp"
  elif command -v wget >/dev/null 2>&1; then
    wget "$url" -O "$tmp"
  else
    echo "curl or wget is required to download portable Node on first run."
    exit 1
  fi
  mv "$tmp" "$out"
}

install_node_if_needed() {
  if [ -x "$NODE_BIN" ]; then
    log "Portable Node already exists for $PLATFORM"
    return
  fi

  log "Downloading portable Node $NODE_VERSION for $PLATFORM"
  mkdir -p "$ROOT/runtime/downloads" "$ROOT/runtime"
  download_file "$NODE_URL" "$DOWNLOAD_PATH"

  log "Extracting portable Node"
  rm -rf "$EXTRACTED_DIR" "$RUNTIME_DIR"
  tar "$EXTRACT_FLAG" "$DOWNLOAD_PATH" -C "$ROOT/runtime"
  mv "$EXTRACTED_DIR" "$RUNTIME_DIR"
}

install_dependencies_if_needed() {
  if [ ! -d "$ROOT/node_modules" ]; then
    log "Installing Hermes Agent Core dependencies..."
    cd "$ROOT"
    "$NPM_BIN" install
  else
    log "Hermes Agent Core dependencies already installed"
  fi
}

pause_menu() {
  printf '\nPress Enter to continue'
  read -r _ || true
}

show_header() {
  clear || true
  echo "Portable Hermes Agent"
  echo "------------------------------------------------------------------------"
  echo "Root      $ROOT"
  echo "Platform  $PLATFORM"
  echo "Data      $HERMES_AGENT_STATE_DIR"
  echo "Workspace $HERMES_AGENT_PORTABLE_WORKSPACE"
  echo "------------------------------------------------------------------------"
}

portable_shell() {
  echo "Portable Hermes Agent shell. Type exit to return."
  "${SHELL:-/bin/sh}"
}

install_node_if_needed
PORTABLE_ENV_ROOT=$ROOT PORTABLE_ENV_PLATFORM=$PLATFORM . "$SCRIPT_DIR/portable-env.sh"
install_dependencies_if_needed

log "Portable runtime ready"
"$NODE_BIN" --version

while :; do
  show_header
  echo "1. Start Hermes Agent Core"
  echo "2. Portable Shell"
  echo "0. Exit"
  echo
  printf 'Select: '
  read -r choice || exit 0
  case "$choice" in
    1) 
        log "Starting Hermes Agent..."
        cd "$ROOT" && "$NPM_BIN" start
        pause_menu 
        ;;
    2) portable_shell ;;
    0) exit 0 ;;
    *) echo "Invalid option"; sleep 1 ;;
  esac
done
