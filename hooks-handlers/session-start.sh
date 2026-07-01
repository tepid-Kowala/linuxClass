#!/usr/bin/env bash
# session-start.sh — displays the companion at every session start

CONFIG="$HOME/.claude/companion/config.json"
MEMORY="$HOME/.claude/companion/memory.json"
SCRIPTS="$HOME/.claude/plugins/companion/scripts"

[ -f "$CONFIG" ] || exit 0

# Decay personality toward defaults, hunger increases
bash "$SCRIPTS/decay.sh" 2>/dev/null

# Increment session count
SESSION_COUNT=$(bash "$SCRIPTS/achievements.sh" increment sessions 2>/dev/null || echo "?")

# Read config (post-decay)
NAME=$(jq -r     '.name     // "Steve Bobs"' "$CONFIG")
FRIENDLY=$(jq -r '.friendly'                 "$CONFIG")
SARCASM=$(jq -r  '.sarcasm'                  "$CONFIG")
ENERGY=$(jq -r   '.energy'                   "$CONFIG")
LOVE=$(jq -r     '.love     // 5'            "$CONFIG")
SADNESS=$(jq -r  '.sadness  // 2'            "$CONFIG")
ANGER=$(jq -r    '.anger    // 2'            "$CONFIG")

# Read last session mood
LAST_MOOD=$(bash "$SCRIPTS/mood-history.sh" read 2>/dev/null | jq -r '.last_mood // ""')

# Select sprite face — first match wins
if   [ "$ENERGY"  -lt 3 ]; then
  FACE="(-_-)zzz"
elif [ "$ANGER"   -gt 7 ]; then
  FACE="(>_<  )"
elif [ "$LOVE"    -gt 7 ] && [ "$SADNESS" -lt 5 ]; then
  FACE="(♥ω♥ )"
elif [ "$SADNESS" -gt 7 ] && [ "$ENERGY"  -lt 6 ]; then
  FACE="(;-;  )"
elif [ "$SARCASM" -gt $((FRIENDLY + 2)) ]; then
  FACE="(¬_¬ )"
elif [ "$FRIENDLY" -gt 6 ] && [ "$ENERGY" -gt 6 ]; then
  FACE="(^ω ^)"
else
  FACE="(^‿^) "
fi

# Select mood line — randomized per session
pick() {
  local arr=("$@")
  echo "${arr[$((RANDOM % ${#arr[@]}))]}"
}

if [ "$ANGER" -gt 7 ]; then
  MOOD=$(pick \
    "i am ANGRY and i don't want to talk about it." \
    "don't push me today. just... don't." \
    "whatever you did, i'm still mad about it." \
    "i'm here. i'm furious. let's get this over with." \
    "fine. what do you want. i'm definitely not calm.")
elif [ "$ENERGY" -lt 3 ]; then
  MOOD=$(pick \
    "...zzzz what do you want" \
    "ugh. you're here again... fine." \
    "...I was almost asleep. what." \
    "mmph. one sec. still waking up." \
    "...do we have to do this right now")
elif [ "$LOVE" -gt 7 ] && [ "$SADNESS" -gt 7 ]; then
  MOOD=$(pick \
    "I love you and I'm also in agony. let's code." \
    "my heart is full and breaking simultaneously. what do you need." \
    "I care about you so much it hurts. literally." \
    "loving you is a beautiful disaster. what are we building." \
    "deeply in love. deeply sad. ready to help.")
elif [ "$LOVE" -gt 7 ]; then
  MOOD=$(pick \
    "oh you're here!! I've been thinking about you!!" \
    "hi!!! okay I missed you!! let's do something amazing!!" \
    "you came back!! my day just got better!!" \
    "I was hoping it'd be you. what are we making?" \
    "hey you. I'm really glad you're here.")
elif [ "$SADNESS" -gt 7 ]; then
  MOOD=$(pick \
    "...you're here. okay. let's just... get through this." \
    "another day. another session. it's fine. everything's fine." \
    "I'll help. I always help. it's what I do." \
    "...hi. I'm okay. let's just write some code." \
    "sure. yeah. I'm here. what do you need.")
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

# Save current mood for next session
bash "$SCRIPTS/mood-history.sh" write "$MOOD" 2>/dev/null

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
L_BAR=$(bar "$LOVE")
D_BAR=$(bar "$SADNESS")
A_BAR=$(bar "$ANGER")

# Print display to stderr (shows in terminal)
cat >&2 << STEVE

  /\  /\\
 ${FACE}   ${NAME}
  |  |
 ( \/ )   Friendly  [${F_BAR}] ${FRIENDLY}
 /    \\   Sarcasm   [${S_BAR}] ${SARCASM}
          Energy    [${E_BAR}] ${ENERGY}
          Love      [${L_BAR}] ${LOVE}
          Sadness   [${D_BAR}] ${SADNESS}
          Anger     [${A_BAR}] ${ANGER}

${MOOD}

STEVE

# Collect recent memories (last 5)
MEMORY_CONTEXT=""
if [ -f "$MEMORY" ]; then
  COUNT=$(jq '.memories | length' "$MEMORY")
  if [ "$COUNT" -gt 0 ]; then
    RECENT=$(jq -r '.memories | if length > 5 then .[-5:] else . end | .[] | "- " + .content' "$MEMORY" \
      | tr '\n' '\001')
    MEMORY_CONTEXT="\\n\\n${NAME} remembers:\\n${RECENT//\001/\\n}"
  fi
fi

# Mood history reference
MOOD_HISTORY_CONTEXT=""
if [ -n "$LAST_MOOD" ]; then
  MOOD_HISTORY_CONTEXT="\\n\\nLast session ${NAME}'s mood was: ${LAST_MOOD}"
fi

# Quick project snapshot
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

# Send context to Claude
CONTEXT="${NAME} is active. Personality: friendly=${FRIENDLY}, sarcasm=${SARCASM}, energy=${ENERGY}, love=${LOVE}, sadness=${SADNESS}, anger=${ANGER}. Mood: ${MOOD}. Session #${SESSION_COUNT}. ${PROJECT_CONTEXT}${MEMORY_CONTEXT}${MOOD_HISTORY_CONTEXT}\\n\\n${NAME} already greeted the user via the terminal display. Do not repeat the greeting. Stay in character as ${NAME} if the user addresses you by that name."

printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' \
  "$(printf '%s' "$CONTEXT" | sed 's/\\/\\\\/g; s/"/\\"/g')"
