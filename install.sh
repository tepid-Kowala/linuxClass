#!/usr/bin/env bash
# install.sh
# Installs the Steve Bobs companion plugin into Claude Code.
set -e

if ! command -v jq &> /dev/null; then
  echo "ERROR: jq is required. Install it with: sudo apt install jq"
  exit 1
fi

PLUGIN_DIR="$HOME/.claude/plugins/companion"
COMMANDS_DIR="$HOME/.claude/commands"
CONFIG_DIR="$HOME/.claude/companion"
CONFIG_FILE="$CONFIG_DIR/config.json"
SETTINGS="$HOME/.claude/settings.json"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install plugin support files
mkdir -p "$PLUGIN_DIR/.claude-plugin"
mkdir -p "$PLUGIN_DIR/hooks-handlers"
mkdir -p "$PLUGIN_DIR/skills/companion"
mkdir -p "$PLUGIN_DIR/scripts"
mkdir -p "$CONFIG_DIR"

cp "$SRC/.claude-plugin/plugin.json"                "$PLUGIN_DIR/.claude-plugin/plugin.json"
cp "$SRC/skills/companion/SKILL.md"                 "$PLUGIN_DIR/skills/companion/SKILL.md"
cp "$SRC/scripts/read-config.sh"                    "$PLUGIN_DIR/scripts/read-config.sh"
cp "$SRC/scripts/write-config.sh"                   "$PLUGIN_DIR/scripts/write-config.sh"
cp "$SRC/scripts/read-memory.sh"                    "$PLUGIN_DIR/scripts/read-memory.sh"
cp "$SRC/scripts/write-memory.sh"                   "$PLUGIN_DIR/scripts/write-memory.sh"
cp "$SRC/hooks-handlers/session-start.sh"           "$PLUGIN_DIR/hooks-handlers/session-start.sh"
cp "$SRC/hooks-handlers/user-prompt.sh"             "$PLUGIN_DIR/hooks-handlers/user-prompt.sh"

chmod +x "$PLUGIN_DIR/scripts/read-config.sh"
chmod +x "$PLUGIN_DIR/scripts/write-config.sh"
chmod +x "$PLUGIN_DIR/scripts/read-memory.sh"
chmod +x "$PLUGIN_DIR/scripts/write-memory.sh"
chmod +x "$PLUGIN_DIR/hooks-handlers/session-start.sh"
chmod +x "$PLUGIN_DIR/hooks-handlers/user-prompt.sh"

# Install /companion and /steve as global user commands
mkdir -p "$COMMANDS_DIR"
cp "$SRC/commands/companion.md" "$COMMANDS_DIR/companion.md"
cp "$SRC/commands/steve.md"     "$COMMANDS_DIR/steve.md"

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

# Register SessionStart hook in settings.json
if [ -f "$SETTINGS" ]; then
  SESSION_CMD="bash $PLUGIN_DIR/hooks-handlers/session-start.sh"
  PROMPT_CMD="bash $PLUGIN_DIR/hooks-handlers/user-prompt.sh"
  jq --arg sc "$SESSION_CMD" --arg pc "$PROMPT_CMD" '
    .hooks.SessionStart    = [{"hooks":[{"type":"command","command":$sc,"timeout":10}]}] |
    .hooks.UserPromptSubmit = [{"hooks":[{"type":"command","command":$pc,"timeout":5}]}]
  ' "$SETTINGS" > /tmp/companion_settings.json \
    && mv /tmp/companion_settings.json "$SETTINGS"
fi

echo "Steve Bobs installed! Restart Claude Code — Steve will greet you at every session start."
