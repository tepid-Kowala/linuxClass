#!/usr/bin/env bash
# tests/test_install.sh
# Tests the install.sh script
set -e

PLUGIN_DIR="$HOME/.claude/plugins/companion"
COMMAND_FILE="$HOME/.claude/commands/companion.md"
CONFIG_FILE="$HOME/.claude/companion/config.json"
SETTINGS="$HOME/.claude/settings.json"

# Self-locate to repo root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Save existing state
EXISTING_CONFIG=""
if [ -f "$CONFIG_FILE" ]; then EXISTING_CONFIG=$(cat "$CONFIG_FILE"); fi

EXISTING_COMMAND=""
if [ -f "$COMMAND_FILE" ]; then EXISTING_COMMAND=$(cat "$COMMAND_FILE"); fi

EXISTING_SETTINGS=""
if [ -f "$SETTINGS" ]; then EXISTING_SETTINGS=$(cat "$SETTINGS"); fi

# Clean slate
rm -rf "$PLUGIN_DIR" "$HOME/.claude/companion"
rm -f "$COMMAND_FILE"

# Cleanup trap: restore prior state, leave plugin installed
cleanup() {
  if [ -n "$EXISTING_CONFIG" ]; then
    mkdir -p "$(dirname "$CONFIG_FILE")"
    echo "$EXISTING_CONFIG" > "$CONFIG_FILE"
  fi
  if [ -n "$EXISTING_COMMAND" ]; then
    mkdir -p "$(dirname "$COMMAND_FILE")"
    echo "$EXISTING_COMMAND" > "$COMMAND_FILE"
  fi
  if [ -n "$EXISTING_SETTINGS" ]; then
    echo "$EXISTING_SETTINGS" > "$SETTINGS"
  fi
}
trap cleanup EXIT

# Run installer
cd "$REPO_ROOT"
bash install.sh

# Test 1: plugin directory exists
[ -d "$PLUGIN_DIR" ] || { echo "FAIL: plugin dir missing"; exit 1; }

# Test 2: .claude-plugin/plugin.json present
[ -f "$PLUGIN_DIR/.claude-plugin/plugin.json" ] || { echo "FAIL: .claude-plugin/plugin.json missing"; exit 1; }

# Test 3: global command file installed
[ -f "$COMMAND_FILE" ] || { echo "FAIL: ~/.claude/commands/companion.md missing"; exit 1; }

# Test 4: skill file present
[ -f "$PLUGIN_DIR/skills/companion/SKILL.md" ] || { echo "FAIL: skills/companion/SKILL.md missing"; exit 1; }

# Test 5: SKILL.md has required frontmatter
grep -q "^name: companion" "$PLUGIN_DIR/skills/companion/SKILL.md" || { echo "FAIL: SKILL.md missing frontmatter"; exit 1; }

# Test 6: session-start hook present and executable
[ -x "$PLUGIN_DIR/hooks-handlers/session-start.sh" ] || { echo "FAIL: session-start.sh missing or not executable"; exit 1; }

# Test 7: session-start hook produces valid JSON
"$PLUGIN_DIR/hooks-handlers/session-start.sh" | python3 -m json.tool > /dev/null || { echo "FAIL: session-start.sh output is not valid JSON"; exit 1; }

# Test 8: memory scripts present and executable
[ -x "$PLUGIN_DIR/scripts/read-memory.sh" ]  || { echo "FAIL: read-memory.sh missing or not executable"; exit 1; }
[ -x "$PLUGIN_DIR/scripts/write-memory.sh" ] || { echo "FAIL: write-memory.sh missing or not executable"; exit 1; }

# Test 9: read-config.sh and write-config.sh present and executable
[ -x "$PLUGIN_DIR/scripts/read-config.sh" ]  || { echo "FAIL: read-config.sh missing or not executable"; exit 1; }
[ -x "$PLUGIN_DIR/scripts/write-config.sh" ] || { echo "FAIL: write-config.sh missing or not executable"; exit 1; }

# Test 10: config file has correct defaults
[ -f "$CONFIG_FILE" ] || { echo "FAIL: config file missing"; exit 1; }
FRIENDLY=$(jq '.friendly' "$CONFIG_FILE")
SARCASM=$(jq '.sarcasm'  "$CONFIG_FILE")
ENERGY=$(jq '.energy'    "$CONFIG_FILE")
[ "$FRIENDLY" = "7" ] || { echo "FAIL: friendly default wrong (got $FRIENDLY)"; exit 1; }
[ "$SARCASM"  = "5" ] || { echo "FAIL: sarcasm default wrong (got $SARCASM)";  exit 1; }
[ "$ENERGY"   = "8" ] || { echo "FAIL: energy default wrong (got $ENERGY)";   exit 1; }

# Test 11: reinstall does NOT overwrite existing config
jq '.friendly = 3' "$CONFIG_FILE" > /tmp/companion_test.json && mv /tmp/companion_test.json "$CONFIG_FILE"
bash install.sh
FRIENDLY=$(jq '.friendly' "$CONFIG_FILE")
[ "$FRIENDLY" = "3" ] || { echo "FAIL: reinstall overwrote existing config (got $FRIENDLY)"; exit 1; }

# Test 12: SessionStart hook registered in settings.json
if [ -f "$SETTINGS" ]; then
  jq -e '.hooks.SessionStart' "$SETTINGS" > /dev/null || { echo "FAIL: SessionStart hook not in settings.json"; exit 1; }
fi

echo "PASS: all install tests passed"
