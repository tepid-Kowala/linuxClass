#!/usr/bin/env bash
# decay.sh — drift personality axes 1 step toward defaults each session.
# Hunger increases by 1 per session (gets hungrier over time).
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
  .anger    = drift((.anger    // 2);    2) |
  .hunger   = (if (.hunger // 5) < 10 then (.hunger // 5) + 1 else 10 end)
' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
