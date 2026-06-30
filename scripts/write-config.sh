#!/usr/bin/env bash
# scripts/write-config.sh <axis> <value>
# Updates one personality value. Validates axis name and 0-10 range.
set -e

AXIS="$1"
VALUE="$2"
CONFIG_FILE="$HOME/.claude/companion/config.json"

case "$AXIS" in
  friendly|sarcasm|energy|name) ;;
  *)
    echo "ERROR: unknown axis '$AXIS'. Valid axes: friendly, sarcasm, energy, name" >&2
    exit 1
    ;;
esac

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

TMP=$(mktemp)
if [ "$AXIS" = "name" ]; then
  # name is a string — no range validation
  jq --arg v "$VALUE" '.name = $v' "$CONFIG_FILE" > "$TMP" \
    && mv "$TMP" "$CONFIG_FILE" || { rm -f "$TMP"; echo "ERROR: failed to write config" >&2; exit 1; }
else
  if ! [[ "$VALUE" =~ ^[0-9]+$ ]] || [ "$VALUE" -lt 0 ] || [ "$VALUE" -gt 10 ]; then
    echo "ERROR: value must be an integer 0–10 (got '$VALUE')" >&2
    exit 1
  fi
  jq ".$AXIS = $VALUE" "$CONFIG_FILE" > "$TMP" \
    && mv "$TMP" "$CONFIG_FILE" || { rm -f "$TMP"; echo "ERROR: failed to write config" >&2; exit 1; }
fi
