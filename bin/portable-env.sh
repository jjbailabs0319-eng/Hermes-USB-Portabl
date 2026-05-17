#!/usr/bin/env sh
set -eu

ROOT=${PORTABLE_ENV_ROOT:-${ROOT:-}}
PLATFORM=${PORTABLE_ENV_PLATFORM:-${PLATFORM:-}}

if [ -z "$ROOT" ] || [ -z "$PLATFORM" ]; then
  if [ "$#" -ge 2 ]; then
    ROOT=$1
    PLATFORM=$2
  else
    echo "portable-env.sh requires ROOT and PLATFORM."
    return 1 2>/dev/null || exit 1
  fi
fi

PACKAGE_ROOT="$ROOT/packages/$PLATFORM"
NPM_PREFIX="$PACKAGE_ROOT/npm-global"
NPM_CACHE="$PACKAGE_ROOT/npm-cache"
NODE_ROOT="$ROOT/runtime/$PLATFORM"

export HERMES_AGENT_PORTABLE_ROOT="$ROOT"
export HERMES_AGENT_PORTABLE_PLATFORM="$PLATFORM"
export HERMES_AGENT_HOME="$ROOT/data/home"
export HERMES_AGENT_STATE_DIR="$ROOT/data/state"
export HERMES_AGENT_CONFIG_PATH="$ROOT/data/config/hermes-agent.json"
export HERMES_AGENT_PORTABLE_WORKSPACE="$ROOT/data/workspace"
export HOME="$HERMES_AGENT_HOME"
export TMPDIR="$ROOT/data/temp"
export npm_config_prefix="$NPM_PREFIX"
export npm_config_cache="$NPM_CACHE"
export npm_config_update_notifier=false
export npm_config_fund=false
export npm_config_audit=false
export npm_config_bin_links=false
export PATH="$NODE_ROOT/bin:$NPM_PREFIX/bin:$PATH"

mkdir -p \
  "$HERMES_AGENT_HOME" \
  "$HERMES_AGENT_STATE_DIR" \
  "$(dirname "$HERMES_AGENT_CONFIG_PATH")" \
  "$HERMES_AGENT_PORTABLE_WORKSPACE" \
  "$TMPDIR" \
  "$NPM_PREFIX" \
  "$NPM_CACHE" \
  "$ROOT/runtime/downloads" \
  "$ROOT/logs"

create_config() {
  if [ -f "$ROOT/templates/hermes-agent.portable.json" ]; then
    sed "s|\${HERMES_AGENT_PORTABLE_WORKSPACE}|$HERMES_AGENT_PORTABLE_WORKSPACE|g" \
      "$ROOT/templates/hermes-agent.portable.json" > "$HERMES_AGENT_CONFIG_PATH"
  else
    printf '{}\n' > "$HERMES_AGENT_CONFIG_PATH"
  fi
}

if [ ! -f "$HERMES_AGENT_CONFIG_PATH" ]; then
  create_config
fi
