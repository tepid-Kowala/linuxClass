#!/usr/bin/env bash
# achievements.sh <action> [key]
# Tracks interaction counts and checks milestones.
# Actions: increment <key>, get <key>, all

ACTION="$1"
KEY="$2"
ACH_FILE="$HOME/.claude/companion/achievements.json"

init() {
  mkdir -p "$(dirname "$ACH_FILE")"
  [ -f "$ACH_FILE" ] && return
  cat > "$ACH_FILE" << 'EOF'
{
  "sessions": 0,
  "times_fed": 0,
  "times_patted": 0,
  "times_played": 0,
  "times_whipped": 0,
  "times_hugged": 0,
  "times_ignored": 0,
  "times_slept": 0
}
EOF
}

init

case "$ACTION" in
  increment)
    TMP=$(mktemp)
    jq ".$KEY += 1" "$ACH_FILE" > "$TMP" && mv "$TMP" "$ACH_FILE"
    jq -r ".$KEY" "$ACH_FILE"
    ;;
  get)
    jq -r ".${KEY} // 0" "$ACH_FILE"
    ;;
  all)
    cat "$ACH_FILE"
    ;;
esac
