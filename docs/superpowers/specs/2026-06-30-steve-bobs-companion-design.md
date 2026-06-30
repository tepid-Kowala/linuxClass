# Steve Bobs — Claude Code Companion Design

**Date:** 2026-06-30
**Status:** Approved

---

## Overview

Steve Bobs is a llama companion that lives inside Claude Code as a `/companion` plugin. He has a persistent personality defined by three axes (friendly, sarcasm, energy) that shape both his ASCII sprite expression and the tone of his responses. He can roast your code or motivate you, all in character.

---

## Plugin Structure

```
~/.claude/plugins/companion/
├── plugin.json                  # manifest — registers /companion skill
├── skills/
│   └── companion.md             # skill definition Claude follows
└── scripts/
    ├── read-config.sh           # reads ~/.claude/companion/config.json
    └── write-config.sh          # writes a single personality value

~/.claude/companion/
└── config.json                  # persistent personality state
```

---

## Personality System

Three axes stored in `~/.claude/companion/config.json`, each 0–10:

```json
{
  "friendly": 7,
  "sarcasm": 5,
  "energy": 8
}
```

### Personality Combos → Vibe

| Combo | Vibe |
|---|---|
| friendly↑ sarcasm↑ energy↑ | Hyped best friend who absolutely destroys your code |
| friendly↑ sarcasm↓ energy↑ | Enthusiastic cheerleader |
| friendly↓ sarcasm↑ energy↑ | Ruthless senior dev roasting you |
| friendly↑ sarcasm↓ energy↓ | Calm, warm mentor |
| any + energy↓ | Sleepy, low-effort responses |

The skill builds a dynamic system prompt from these values. Claude uses that prompt to respond in Steve's personality for the entire companion session.

---

## ASCII Character Sprites

Steve Bobs is a llama. His face changes based on dominant personality axes:

```
HIGH ENERGY + HIGH FRIENDLY        HIGH SARCASM + LOW FRIENDLY
  ╔═════════════╗                    ╔═════════════╗
  ║   /\  /\   ║                    ║   /\  /\   ║
  ║  (^ω ^)    ║                    ║  (¬_¬ )    ║
  ║   |  |     ║                    ║   |  |     ║
  ║  ( \/ )    ║                    ║  ( \/ )    ║
  ║  /    \    ║                    ║  /    \    ║
  ╚═════════════╝                    ╚═════════════╝

LOW ENERGY                          DEFAULT / BALANCED
  ╔═════════════╗                    ╔═════════════╗
  ║   /\  /\   ║                    ║   /\  /\   ║
  ║  (-_-)zzz  ║                    ║  (^‿^)     ║
  ║   |  |     ║                    ║   |  |     ║
  ║  ( \/ )    ║                    ║  ( \/ )    ║
  ║  /    \    ║                    ║  /    \    ║
  ╚═════════════╝                    ╚═════════════╝
```

Sprite selection priority: energy < 3 → sleepy. Otherwise: sarcasm > friendly+2 → sarcastic. friendly > 6 + energy > 6 → hype. Default: balanced.

---

## Skill Behavior & Subcommands

### Invocation Display

```
  /\  /\
 (^‿^)   Steve Bobs
  |  |
 ( \/ )   Friendly  [████████░░] 8
 /    \   Sarcasm   [█████░░░░░] 5
          Energy    [█████████░] 9

What do you need, bestie? (roast/motivate/set/reset)
```

### Subcommands

| Command | Behavior |
|---|---|
| `/companion` | Shows Steve + current personality bars |
| `/companion roast` | Prompts user to paste code; Steve reviews it in character |
| `/companion motivate` | Steve fires off encouragement in current personality |
| `/companion set <axis> <value>` | Updates one slider (0–10), redraws Steve |
| `/companion reset` | Resets all sliders to defaults (friendly=7, sarcasm=5, energy=8) |

### Roast Flow

1. User types `/companion roast`
2. Steve responds: *"paste the crime scene"* (wording adjusts to personality)
3. User pastes code in next message
4. Steve responds with code review in character

### Motivate Flow

1. User types `/companion motivate`
2. Steve immediately responds with encouragement in current personality

---

## Config Defaults

```json
{
  "friendly": 7,
  "sarcasm": 5,
  "energy": 8
}
```

Config lives at `~/.claude/companion/config.json`. Created on first run if missing.

---

## Out of Scope

- Hooks injecting Steve's personality into normal (non-companion) Claude responses
- Custom user-defined sprites
- More than three personality axes
- Memory of past sessions beyond personality config
