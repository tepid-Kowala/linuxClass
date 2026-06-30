#!/usr/bin/env bash
# tests/test_config_scripts.sh
set -e

CONFIG_FILE="$HOME/.claude/companion/config.json"
READ_SCRIPT="./scripts/read-config.sh"
WRITE_SCRIPT="./scripts/write-config.sh"

# Setup: known config state
mkdir -p "$HOME/.claude/companion"
cat > "$CONFIG_FILE" << 'CONF'
{
  "friendly": 7,
  "sarcasm": 5,
  "energy": 8
}
CONF

# Test 1: read-config outputs valid JSON with correct values
OUTPUT=$(bash "$READ_SCRIPT")
FRIENDLY=$(echo "$OUTPUT" | jq '.friendly')
[ "$FRIENDLY" = "7" ] || { echo "FAIL: read-config wrong friendly (got $FRIENDLY)"; exit 1; }

# Test 2: write-config updates a value
bash "$WRITE_SCRIPT" sarcasm 9
OUTPUT=$(bash "$READ_SCRIPT")
SARCASM=$(echo "$OUTPUT" | jq '.sarcasm')
[ "$SARCASM" = "9" ] || { echo "FAIL: write-config didn't update sarcasm (got $SARCASM)"; exit 1; }

# Test 3: write-config rejects value > 10
bash "$WRITE_SCRIPT" energy 11 2>/dev/null && { echo "FAIL: should reject value > 10"; exit 1; } || true

# Test 4: write-config rejects negative value
bash "$WRITE_SCRIPT" friendly -1 2>/dev/null && { echo "FAIL: should reject negative"; exit 1; } || true

# Test 5: write-config rejects unknown axis
bash "$WRITE_SCRIPT" charisma 5 2>/dev/null && { echo "FAIL: should reject unknown axis"; exit 1; } || true

# Test 6: write-config doesn't corrupt other values
bash "$WRITE_SCRIPT" energy 3
OUTPUT=$(bash "$READ_SCRIPT")
SARCASM=$(echo "$OUTPUT" | jq '.sarcasm')
[ "$SARCASM" = "9" ] || { echo "FAIL: write-config corrupted sarcasm (got $SARCASM)"; exit 1; }

echo "PASS: all config script tests passed"
