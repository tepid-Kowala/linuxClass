#!/usr/bin/env bash
# decay.sh — drift personality axes 1 step toward defaults each session.
# Energy recovers toward default (resting between sessions).

CONFIG="$HOME/.claude/companion/config.json"
[ -f "$CONFIG" ] || exit 0

TMP=$(mktemp)
jq '
  def drift(v; d): if v > d then v - 1 elif v < d then v + 1 else v end;
  .friendly = drift(.friendly;           7) |
  .sarcasm  = drift(.sarcasm;            5) |
  .energy   = drift(.energy;             8) |
  .love     = drift(.love;               5) |
  .sadness  = drift(.sadness;            2) |
  .anger    = drift((.anger    // 2);    2)
' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
