#!/usr/bin/env bash
# install.sh
# Installs the Steve Bobs companion plugin into Claude Code.
set -e

if ! command -v jq &> /dev/null; then
  echo "ERROR: jq is required. Install it with: sudo apt install jq"
  exit 1
fi

PLUGIN_DIR="$HOME/.claude/plugins/companion"
CONFIG_DIR="$HOME/.claude/companion"
CONFIG_FILE="$CONFIG_DIR/config.json"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$PLUGIN_DIR/skills"
mkdir -p "$PLUGIN_DIR/scripts"
mkdir -p "$CONFIG_DIR"

cp "$SRC/plugin.json"                  "$PLUGIN_DIR/plugin.json"
cp "$SRC/skills/companion.md"          "$PLUGIN_DIR/skills/companion.md"
cp "$SRC/scripts/read-config.sh"       "$PLUGIN_DIR/scripts/read-config.sh"
cp "$SRC/scripts/write-config.sh"      "$PLUGIN_DIR/scripts/write-config.sh"

chmod +x "$PLUGIN_DIR/scripts/read-config.sh"
chmod +x "$PLUGIN_DIR/scripts/write-config.sh"

# Only write default config if none exists — preserve user's settings on reinstall
if [ ! -f "$CONFIG_FILE" ]; then
  cat > "$CONFIG_FILE" << 'CONF'
{
  "friendly": 7,
  "sarcasm": 5,
  "energy": 8
}
CONF
fi

echo "Steve Bobs installed! Restart Claude Code and try /companion"
