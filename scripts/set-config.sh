#!/usr/bin/env bash
# set-config.sh [key=value ...]
# Updates multiple config values in a single call.
# Example: set-config.sh energy=5 hunger=3 anger=1
# String values: set-config.sh name="Steve Bobs"
# Returns the updated config JSON.

CONFIG_FILE="$HOME/.claude/companion/config.json"

if [ ! -f "$CONFIG_FILE" ]; then
  mkdir -p "$(dirname "$CONFIG_FILE")"
  cat > "$CONFIG_FILE" << 'CONF'
{
  "name": "Steve Bobs",
  "friendly": 7,
  "sarcasm": 5,
  "energy": 8,
  "love": 5,
  "sadness": 2,
  "anger": 2
}
CONF
fi

VALID_INT="friendly sarcasm energy love sadness anger"
VALID_STR="name"

for arg in "$@"; do
  KEY="${arg%%=*}"
  VALUE="${arg#*=}"

  # Validate key
  VALID=0
  for k in $VALID_INT $VALID_STR; do
    [ "$k" = "$KEY" ] && VALID=1 && break
  done
  if [ "$VALID" -eq 0 ]; then
    echo "ERROR: unknown key '$KEY'" >&2
    exit 1
  fi

  TMP=$(mktemp)
  IS_STR=0
  for k in $VALID_STR; do [ "$k" = "$KEY" ] && IS_STR=1 && break; done

  if [ "$IS_STR" -eq 1 ]; then
    jq --arg v "$VALUE" ".$KEY = \$v" "$CONFIG_FILE" > "$TMP" \
      && mv "$TMP" "$CONFIG_FILE" || { rm -f "$TMP"; echo "ERROR: write failed" >&2; exit 1; }
  else
    if ! [[ "$VALUE" =~ ^[0-9]+$ ]] || [ "$VALUE" -lt 0 ] || [ "$VALUE" -gt 10 ]; then
      echo "ERROR: '$KEY' value must be 0–10 (got '$VALUE')" >&2
      exit 1
    fi
    jq ".$KEY = $VALUE" "$CONFIG_FILE" > "$TMP" \
      && mv "$TMP" "$CONFIG_FILE" || { rm -f "$TMP"; echo "ERROR: write failed" >&2; exit 1; }
  fi
done

cat "$CONFIG_FILE"
