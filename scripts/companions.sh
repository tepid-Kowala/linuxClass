#!/usr/bin/env bash
# companions.sh <action> [name]
# Manages multiple named companion personality configs.
# Actions: new <name>, switch <name>, list, export, import

ACTION="$1"
NAME="$2"
COMPANIONS_DIR="$HOME/.claude/companion/companions"
CONFIG="$HOME/.claude/companion/config.json"

mkdir -p "$COMPANIONS_DIR"

default_config() {
  local n="$1"
  cat << EOF
{
  "name": "$n",
  "friendly": 7,
  "sarcasm": 5,
  "energy": 8,
  "love": 5,
  "sadness": 2,
  "anger": 2,
  "hunger": 5
}
EOF
}

case "$ACTION" in
  new)
    [ -z "$NAME" ] && { echo "ERROR: name required" >&2; exit 1; }
    TARGET="$COMPANIONS_DIR/$NAME.json"
    [ -f "$TARGET" ] && { echo "ERROR: companion '$NAME' already exists" >&2; exit 1; }
    default_config "$NAME" | jq '.' > "$TARGET"
    echo "Created companion: $NAME"
    ;;

  switch)
    [ -z "$NAME" ] && { echo "ERROR: name required" >&2; exit 1; }
    TARGET="$COMPANIONS_DIR/$NAME.json"
    [ ! -f "$TARGET" ] && { echo "ERROR: companion '$NAME' not found. Use 'list' to see available." >&2; exit 1; }
    # Save current config under its own name
    if [ -f "$CONFIG" ]; then
      CURRENT=$(jq -r '.name // "unnamed"' "$CONFIG" 2>/dev/null)
      cp "$CONFIG" "$COMPANIONS_DIR/$CURRENT.json"
    fi
    cp "$TARGET" "$CONFIG"
    echo "Switched to: $NAME"
    ;;

  list)
    ACTIVE=""
    [ -f "$CONFIG" ] && ACTIVE=$(jq -r '.name // ""' "$CONFIG" 2>/dev/null)
    echo "Companions:"
    if [ -f "$CONFIG" ]; then
      if [ -n "$ACTIVE" ]; then
        echo "  * $ACTIVE (active)"
      fi
    fi
    for f in "$COMPANIONS_DIR"/*.json; do
      [ -f "$f" ] || continue
      CNAME=$(basename "$f" .json)
      [ "$CNAME" = "$ACTIVE" ] && continue
      echo "    $CNAME"
    done
    ;;

  export)
    [ -f "$CONFIG" ] || { echo "ERROR: no config found" >&2; exit 1; }
    cat "$CONFIG"
    ;;

  import)
    # Read JSON from stdin
    NEW_CONFIG=$(cat)
    if ! echo "$NEW_CONFIG" | jq '.' > /dev/null 2>&1; then
      echo "ERROR: invalid JSON" >&2; exit 1
    fi
    echo "$NEW_CONFIG" | jq '.' > "$CONFIG"
    echo "Config imported successfully."
    ;;
esac
