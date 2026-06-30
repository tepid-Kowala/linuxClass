#!/usr/bin/env bash
# tests/test_install.sh
# Tests the install.sh script for Task 4
set -e

PLUGIN_DIR="$HOME/.claude/plugins/companion"
CONFIG_FILE="$HOME/.claude/companion/config.json"

# Clean slate
rm -rf "$PLUGIN_DIR" "$HOME/.claude/companion"

# Run installer
cd /home/wes/Desktop/linuxClass
bash install.sh

# Test 1: plugin directory exists
[ -d "$PLUGIN_DIR" ] || { echo "FAIL: plugin dir missing"; exit 1; }

# Test 2: plugin.json present
[ -f "$PLUGIN_DIR/plugin.json" ] || { echo "FAIL: plugin.json missing"; exit 1; }

# Test 3: skill file present
[ -f "$PLUGIN_DIR/skills/companion.md" ] || { echo "FAIL: companion.md missing"; exit 1; }

# Test 4: read-config.sh present and executable
[ -x "$PLUGIN_DIR/scripts/read-config.sh" ] || { echo "FAIL: read-config.sh missing or not executable"; exit 1; }

# Test 5: write-config.sh present and executable
[ -x "$PLUGIN_DIR/scripts/write-config.sh" ] || { echo "FAIL: write-config.sh missing or not executable"; exit 1; }

# Test 6: config file has correct defaults
[ -f "$CONFIG_FILE" ] || { echo "FAIL: config file missing"; exit 1; }
FRIENDLY=$(jq '.friendly' "$CONFIG_FILE")
SARCASM=$(jq '.sarcasm' "$CONFIG_FILE")
ENERGY=$(jq '.energy' "$CONFIG_FILE")
[ "$FRIENDLY" = "7" ] || { echo "FAIL: friendly default wrong (got $FRIENDLY)"; exit 1; }
[ "$SARCASM" = "5" ] || { echo "FAIL: sarcasm default wrong (got $SARCASM)"; exit 1; }
[ "$ENERGY" = "8" ] || { echo "FAIL: energy default wrong (got $ENERGY)"; exit 1; }

# Test 7: second install run does NOT overwrite existing config
jq '.friendly = 3' "$CONFIG_FILE" > /tmp/companion_test.json && mv /tmp/companion_test.json "$CONFIG_FILE"
bash install.sh
FRIENDLY=$(jq '.friendly' "$CONFIG_FILE")
[ "$FRIENDLY" = "3" ] || { echo "FAIL: reinstall overwrote existing config (got $FRIENDLY)"; exit 1; }

echo "PASS: all install tests passed"
