#!/usr/bin/env bash
set -e

# 1. Dynamic Path Detection (No hardcoded roots)
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT="$SCRIPT_DIR"

# 2. Configure Local .tmp Cache & Isolation (Zero-Trace)
export TMPDIR="$ROOT/.tmp"
export UV_CACHE_DIR="$TMPDIR/uv-cache"
export HERMES_HOME="$ROOT/data"
export PYTHONUTF8=1

mkdir -p "$TMPDIR" "$UV_CACHE_DIR" "$HERMES_HOME"

# 3. Download Portable uv if missing
UV_BIN="$TMPDIR/bin"
export PATH="$UV_BIN:$PATH"

if [ ! -x "$UV_BIN/uv" ]; then
    echo "[Hermes] Downloading Portable 'uv' package manager..."
    mkdir -p "$UV_BIN"
    curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="$UV_BIN" sh
fi

echo "=================================================="
echo "[Hermes] Starting Portable V2 (NousResearch Merge)"
echo "[Hermes] ROOT=$ROOT"
echo "[Hermes] HERMES_HOME=$HERMES_HOME"
echo "=================================================="

# 4. Setup Python Virtual Environment using uv
cd "$ROOT"
if [ ! -d "$TMPDIR/.venv" ]; then
    echo "[Hermes] Creating isolated Python 3.11 environment..."
    uv venv "$TMPDIR/.venv" --python 3.11
    
    echo "[Hermes] Installing core Hermes Agent dependencies..."
    export VIRTUAL_ENV="$TMPDIR/.venv"
    export PATH="$TMPDIR/.venv/bin:$PATH"
    uv pip install -e ".[all]"
else
    export VIRTUAL_ENV="$TMPDIR/.venv"
    export PATH="$TMPDIR/.venv/bin:$PATH"
fi

show_menu() {
    clear
    echo "=================================================="
    echo "[Hermes] Portable V2 Dashboard"
    echo "=================================================="
    echo "1. Start Hermes CLI (TUI)"
    echo "2. Start Hermes Gateway (Telegram/Discord)"
    echo "3. Start Setup Wizard (Initial Config)"
    echo "4. Portable Shell"
    echo "0. Exit"
    echo
}

while true; do
    show_menu
    read -rp "Select: " choice
    case "$choice" in
        1) hermes; read -rp "Press Enter to continue..." ;;
        2) hermes gateway start; read -rp "Press Enter to continue..." ;;
        3) hermes setup; read -rp "Press Enter to continue..." ;;
        4) echo "[Hermes] Type 'exit' to return to menu."; bash ;;
        0) exit 0 ;;
        *) echo "Invalid option"; sleep 1 ;;
    esac
done
