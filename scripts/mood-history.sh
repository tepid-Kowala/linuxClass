#!/usr/bin/env bash
# mood-history.sh read|write [mood_string]
# Persists Steve's mood between sessions.

ACTION="$1"
MOOD="${2:-}"
HIST_FILE="$HOME/.claude/companion/mood_history.json"

case "$ACTION" in
  read)
    if [ -f "$HIST_FILE" ]; then
      cat "$HIST_FILE"
    else
      echo '{"last_mood":null,"last_session":null}'
    fi
    ;;
  write)
    mkdir -p "$(dirname "$HIST_FILE")"
    ESCAPED=$(printf '%s' "$MOOD" | sed 's/\\/\\\\/g; s/"/\\"/g')
    printf '{"last_mood":"%s","last_session":"%s"}\n' \
      "$ESCAPED" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$HIST_FILE"
    ;;
esac
