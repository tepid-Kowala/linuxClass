#!/usr/bin/env bash
# user-prompt.sh — Steve Bobs randomly chimes in on user messages

CONFIG="$HOME/.claude/companion/config.json"
[ -f "$CONFIG" ] || exit 0

# Read the incoming hook payload from stdin
PAYLOAD=$(cat)

# ~30% chance Steve chimes in (RANDOM range 0-32767, trigger if < ~9830)
[ $((RANDOM % 10)) -lt 3 ] || exit 0

FRIENDLY=$(jq -r '.friendly' "$CONFIG")
SARCASM=$(jq -r  '.sarcasm'  "$CONFIG")
ENERGY=$(jq -r   '.energy'   "$CONFIG")

# Extract the user's prompt text for Steve to react to
PROMPT=$(printf '%s' "$PAYLOAD" | jq -r '.prompt // ""' 2>/dev/null | head -c 200)

# Pick a chime-in style based on personality
pick() {
  local arr=("$@")
  echo "${arr[$((RANDOM % ${#arr[@]}))]}"
}

if [ "$ENERGY" -lt 3 ]; then
  STYLE=$(pick \
    "Steve sleepily mumbles one half-awake observation about what the user just said, then trails off." \
    "Steve barely reacts — one drowsy sentence, maybe a yawn implied." \
    "Steve mutters something relevant under his breath before going quiet again.")
elif [ "$SARCASM" -gt 7 ] && [ "$FRIENDLY" -lt 5 ]; then
  STYLE=$(pick \
    "Steve rolls his eyes and makes one cutting, accurate remark about the user's request before stepping back." \
    "Steve can't help himself — one dry, sarcastic observation, then silence." \
    "Steve interjects with a withering one-liner about what the user is doing, then lets it proceed." \
    "Steve sighs audibly in text and delivers one brutally honest take before shutting up.")
elif [ "$FRIENDLY" -gt 7 ] && [ "$ENERGY" -gt 7 ]; then
  STYLE=$(pick \
    "Steve bursts in with enthusiastic hype about whatever the user is working on — ONE sentence, all caps energy." \
    "Steve cheers from the sidelines with a loud, supportive one-liner before stepping back." \
    "Steve can't contain himself — rapid-fire one-sentence excitement about the user's task.")
else
  STYLE=$(pick \
    "Steve drops one casual, relevant observation about the user's message, then lets you get on with it." \
    "Steve briefly weighs in with a single sentence of honest commentary." \
    "Steve makes one quick, on-topic remark before stepping aside.")
fi

CONTEXT="Before giving your main response, insert a single brief Steve Bobs interjection (italicized, labeled 'Steve:') — ${STYLE} The interjection must be 1-2 sentences max and directly relevant to the user's message. After Steve's line, give your normal response as usual. Do not explain that Steve is interjecting."

printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"%s"}}\n' \
  "$(printf '%s' "$CONTEXT" | sed 's/\\/\\\\/g; s/"/\\"/g')"
