#!/usr/bin/env bash
# scripts/read-config.sh
# Outputs the current personality config as JSON.
# Creates default config if none exists.

CONFIG_FILE="$HOME/.claude/companion/config.json"

if [ ! -f "$CONFIG_FILE" ]; then
  mkdir -p "$(dirname "$CONFIG_FILE")"
  cat > "$CONFIG_FILE" << 'CONF'
{
  "name": "Steve Bobs",
  "friendly": 7,
  "sarcasm": 5,
  "energy": 8
}
CONF
fi

cat "$CONFIG_FILE"
