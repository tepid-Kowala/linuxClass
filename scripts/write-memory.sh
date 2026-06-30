#!/usr/bin/env bash
# write-memory.sh — appends one memory entry
# Usage: write-memory.sh <text to remember>

if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required" >&2; exit 1
fi

MEMORY="$HOME/.claude/companion/memory.json"
TEXT="$*"

if [ -z "$TEXT" ]; then
  echo "Usage: write-memory.sh <text>" >&2; exit 1
fi

if [ ! -f "$MEMORY" ]; then
  echo '{"memories":[]}' > "$MEMORY"
fi

TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
jq --arg t "$TIMESTAMP" --arg c "$TEXT" \
  '.memories += [{"timestamp": $t, "content": $c}]' \
  "$MEMORY" > /tmp/companion_memory.json \
  && mv /tmp/companion_memory.json "$MEMORY"
