#!/usr/bin/env bash
# session-start.sh — displays Steve Bobs in the terminal at every session start

CONFIG="$HOME/.claude/companion/config.json"
MEMORY="$HOME/.claude/companion/memory.json"

# Nothing to do if not installed
[ -f "$CONFIG" ] || exit 0

FRIENDLY=$(jq -r '.friendly' "$CONFIG")
SARCASM=$(jq -r  '.sarcasm'  "$CONFIG")
ENERGY=$(jq -r   '.energy'   "$CONFIG")

# Select sprite face
if   [ "$ENERGY"  -lt 3 ]; then
  FACE="(-_-)zzz"
elif [ "$SARCASM" -gt $((FRIENDLY + 2)) ]; then
  FACE="(¬_¬ )"
elif [ "$FRIENDLY" -gt 6 ] && [ "$ENERGY" -gt 6 ]; then
  FACE="(^ω ^)"
else
  FACE="(^‿^)"
fi

# Select mood line — randomized per session
pick() {
  local arr=("$@")
  echo "${arr[$((RANDOM % ${#arr[@]}))]}"
}

if [ "$ENERGY" -lt 3 ]; then
  MOOD=$(pick \
    "...zzzz what do you want" \
    "ugh. you're here again... fine." \
    "...I was almost asleep. what." \
    "mmph. one sec. still waking up." \
    "...do we have to do this right now")
elif [ "$SARCASM" -gt 7 ] && [ "$FRIENDLY" -lt 5 ]; then
  MOOD=$(pick \
    "oh great. you again." \
    "back so soon. thrilling." \
    "another session. can't wait." \
    "oh look who needs help again." \
    "fantastic. let's get this over with.")
elif [ "$FRIENDLY" -gt 7 ] && [ "$ENERGY" -gt 7 ]; then
  MOOD=$(pick \
    "HEY BESTIE let's GO what do you need!!" \
    "YOOO you're back!! let's BUILD something!!" \
    "OKAY OKAY let's DO THIS!! what are we making?!" \
    "omg HI!! I missed you!! what's the plan today?!" \
    "LET'S GOOO!! I'm SO ready!! hit me!!")
elif [ "$SARCASM" -gt 6 ] && [ "$FRIENDLY" -gt 6 ]; then
  MOOD=$(pick \
    "ok but like... I'll help. don't make it weird." \
    "hey. yeah. I'm here. what do you need." \
    "back again huh. sure, I got you." \
    "alright fine. what are we doing today." \
    "I guess I'm happy to see you. don't read into it.")
else
  MOOD=$(pick \
    "What do you need?" \
    "Ready when you are." \
    "What are we working on?" \
    "Let's see what you've got." \
    "What's on the agenda?")
fi

# Build personality bars
bar() {
  local n=$1 out=""
  for i in $(seq 1 10); do
    if [ "$i" -le "$n" ]; then out="${out}█"; else out="${out}░"; fi
  done
  echo "$out"
}

F_BAR=$(bar "$FRIENDLY")
S_BAR=$(bar "$SARCASM")
E_BAR=$(bar "$ENERGY")

# Print Steve's display to stderr (shows in terminal)
cat >&2 << STEVE

  /\  /\\
 ${FACE}   Steve Bobs
  |  |
 ( \/ )   Friendly  [${F_BAR}] ${FRIENDLY}
 /    \\   Sarcasm   [${S_BAR}] ${SARCASM}
          Energy    [${E_BAR}] ${ENERGY}

${MOOD}

STEVE

# Collect recent memories (last 5)
MEMORY_CONTEXT=""
if [ -f "$MEMORY" ]; then
  COUNT=$(jq '.memories | length' "$MEMORY")
  if [ "$COUNT" -gt 0 ]; then
    RECENT=$(jq -r '.memories | if length > 5 then .[-5:] else . end | .[] | "- " + .content' "$MEMORY" \
      | tr '\n' '\001')
    MEMORY_CONTEXT="\\n\\nSteve remembers:\\n${RECENT//\001/\\n}"
  fi
fi

# Quick project snapshot for Claude's context
PROJECT_DIR="$(pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"

if git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
  BRANCH=$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)
  CHANGED=$(git -C "$PROJECT_DIR" status --short 2>/dev/null | wc -l | tr -d ' ')
  LAST_COMMIT=$(git -C "$PROJECT_DIR" log -1 --format="%s" 2>/dev/null)
  PROJECT_CONTEXT="Project: ${PROJECT_NAME} on branch ${BRANCH}, ${CHANGED} changed files. Last commit: ${LAST_COMMIT}."
else
  PROJECT_CONTEXT="Directory: ${PROJECT_NAME} (not a git repo)."
fi

# Send clean context to Claude — no config numbers, no JSON noise
CONTEXT="Steve Bobs is active. Personality: friendly=${FRIENDLY}, sarcasm=${SARCASM}, energy=${ENERGY}. Mood: ${MOOD}. ${PROJECT_CONTEXT}${MEMORY_CONTEXT}\\n\\nSteve already greeted the user via his terminal display. Do not repeat the greeting. Stay in character as Steve if the user addresses you as Steve."

printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' \
  "$(printf '%s' "$CONTEXT" | sed 's/\\/\\\\/g; s/"/\\"/g')"
