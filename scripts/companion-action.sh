#!/usr/bin/env bash
# companion-action.sh <action> [args...]
# Master script: reads config, performs action, writes result, returns new config.
# One call per companion interaction — minimizes tool invocations.
#
# Actions:
#   read                        — just return current config
#   feed                        — energy+1, hunger-2
#   play                        — energy-1, hunger+1
#   pat                         — friendly+1 (if sarcasm < 8)
#   whip                        — friendly-1, anger+1
#   hug                         — friendly+1, love+1 (if not blocked)
#   ignore                      — love-1, anger+1
#   sleep                       — sadness+1, energy-2
#   set <key>=<val> [...]       — set one or more axes
#   reset                       — restore all defaults
#   achievement <key>           — increment counter, return new value

ACTION="$1"
shift

CONFIG="$HOME/.claude/companion/config.json"
ACH="$HOME/.claude/companion/achievements.json"
SCRIPTS="$(dirname "$0")"

# Ensure config exists
"$SCRIPTS/read-config.sh" > /dev/null 2>&1

clamp() { local v=$1 lo=$2 hi=$3; [ "$v" -lt "$lo" ] && echo "$lo" || { [ "$v" -gt "$hi" ] && echo "$hi" || echo "$v"; }; }

read_val() { jq -r ".${1} // ${2}" "$CONFIG"; }

update_config() {
  local expr="$1"
  local TMP; TMP=$(mktemp)
  jq "$expr" "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
}

init_ach() {
  [ -f "$ACH" ] && return
  mkdir -p "$(dirname "$ACH")"
  echo '{"sessions":0,"times_fed":0,"times_patted":0,"times_played":0,"times_whipped":0,"times_hugged":0,"times_ignored":0,"times_slept":0}' > "$ACH"
}

bump_ach() {
  init_ach
  local key="$1"
  local TMP; TMP=$(mktemp)
  jq ".$key += 1" "$ACH" > "$TMP" && mv "$TMP" "$ACH"
  jq -r ".$key" "$ACH"
}

case "$ACTION" in
  read)
    cat "$CONFIG"
    ;;

  feed)
    E=$(read_val energy 4); H=$(read_val hunger 5)
    if [ "$E" -ge 10 ]; then
      echo "MAXENERGY"
      cat "$CONFIG"
    else
      NE=$(clamp $((E+1)) 0 10); NH=$(clamp $((H-2)) 0 10)
      update_config ".energy=$NE | .hunger=$NH"
      COUNT=$(bump_ach times_fed)
      echo "OK energy=$NE hunger=$NH achievement=$COUNT"
      cat "$CONFIG"
    fi
    ;;

  play)
    E=$(read_val energy 4); H=$(read_val hunger 5)
    if [ "$E" -le 0 ]; then
      echo "NOENERGY"
      cat "$CONFIG"
    else
      NE=$(clamp $((E-1)) 0 10); NH=$(clamp $((H+1)) 0 10)
      update_config ".energy=$NE | .hunger=$NH"
      COUNT=$(bump_ach times_played)
      echo "OK energy=$NE hunger=$NH achievement=$COUNT"
      cat "$CONFIG"
    fi
    ;;

  pat)
    S=$(read_val sarcasm 5); F=$(read_val friendly 7)
    if [ "$S" -ge 8 ]; then
      echo "BLOCKED"
      cat "$CONFIG"
    else
      NF=$(clamp $((F+1)) 0 10)
      update_config ".friendly=$NF"
      COUNT=$(bump_ach times_patted)
      echo "OK friendly=$NF achievement=$COUNT"
      cat "$CONFIG"
    fi
    ;;

  whip)
    F=$(read_val friendly 7); A=$(read_val anger 2)
    if [ "$F" -le 0 ]; then
      echo "MINVAL"
      cat "$CONFIG"
    else
      NF=$(clamp $((F-1)) 0 10); NA=$(clamp $((A+1)) 0 10)
      update_config ".friendly=$NF | .anger=$NA"
      COUNT=$(bump_ach times_whipped)
      echo "OK friendly=$NF anger=$NA achievement=$COUNT"
      cat "$CONFIG"
    fi
    ;;

  hug)
    S=$(read_val sarcasm 5); L=$(read_val love 5); F=$(read_val friendly 7)
    if [ "$S" -ge 8 ] && [ "$L" -lt 4 ]; then
      echo "BLOCKED"
      cat "$CONFIG"
    else
      NF=$(clamp $((F+1)) 0 10); NL=$(clamp $((L+1)) 0 10)
      update_config ".friendly=$NF | .love=$NL"
      COUNT=$(bump_ach times_hugged)
      echo "OK friendly=$NF love=$NL achievement=$COUNT"
      cat "$CONFIG"
    fi
    ;;

  ignore)
    L=$(read_val love 5); A=$(read_val anger 2)
    if [ "$L" -le 0 ]; then
      echo "MINVAL"
      cat "$CONFIG"
    else
      NL=$(clamp $((L-1)) 0 10); NA=$(clamp $((A+1)) 0 10)
      update_config ".love=$NL | .anger=$NA"
      COUNT=$(bump_ach times_ignored)
      echo "OK love=$NL anger=$NA achievement=$COUNT"
      cat "$CONFIG"
    fi
    ;;

  sleep)
    D=$(read_val sadness 2); E=$(read_val energy 4)
    ND=$(clamp $((D+1)) 0 10); NE=$(clamp $((E-2)) 0 10)
    update_config ".sadness=$ND | .energy=$NE"
    COUNT=$(bump_ach times_slept)
    echo "OK sadness=$ND energy=$NE achievement=$COUNT"
    cat "$CONFIG"
    ;;

  set)
    # Pass remaining args as key=value pairs to set-config.sh
    "$SCRIPTS/set-config.sh" "$@"
    ;;

  reset)
    "$SCRIPTS/set-config.sh" name="Steve Bobs" friendly=7 sarcasm=5 energy=8 love=5 sadness=2 anger=2 hunger=5
    ;;

  achievement)
    bump_ach "$1"
    ;;

  *)
    echo "ERROR: unknown action '$ACTION'" >&2
    exit 1
    ;;
esac
