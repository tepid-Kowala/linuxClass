#!/usr/bin/env bash
# read-memory.sh — outputs Steve's memory as JSON
MEMORY="$HOME/.claude/companion/memory.json"

if [ ! -f "$MEMORY" ]; then
  echo '{"memories":[]}'
  exit 0
fi

cat "$MEMORY"
