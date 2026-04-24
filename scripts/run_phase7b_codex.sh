#!/usr/bin/env bash
# Phase 7b — C_llm vs C_final blind forced choice (via codex)
# "Is forge output as good as what humans shipped after review?"
set -euo pipefail

SAMPLES="/Users/junekim/Documents/refactor-equivalence/samples"
RESULTS=()
PICKED_CLLM=0
PICKED_CFINAL=0
TOTAL=0

for DIR in $SAMPLES/v2-single-round/*/; do
  NAME=$(basename "$DIR")
  LOG="$DIR/pipeline.log"
  [ ! -f "$LOG" ] && continue
  grep -q "explicit build=1, test=1" "$LOG" 2>/dev/null || continue

  TRIAL="$SAMPLES/v2/$NAME"
  F="$TRIAL/find_c_test.json"
  [ ! -f "$F" ] && continue

  # Need C_llm diff and C_final diff
  CLLM="$DIR/blind-blind/merged.diff"
  CFINAL_DIFF="$DIR/phase7/diff-human.patch"
  [ ! -s "$CLLM" ] && continue
  [ ! -s "$CFINAL_DIFF" ] && continue

  PHASE7B="$TRIAL/phase7b"
  mkdir -p "$PHASE7B"
  [ -f "$PHASE7B/review.json" ] && [ -s "$PHASE7B/review.json" ] && {
    echo "$NAME: already done, skip"
    # Tally existing result
    CHOICE=$(jq -r '.forced_choice' "$PHASE7B/review.json" 2>/dev/null || echo "")
    LABEL_A=$(jq -r '.version_A' "$PHASE7B/assignment.json" 2>/dev/null || echo "")
    if [ -n "$CHOICE" ] && [ -n "$LABEL_A" ]; then
      [ "$CHOICE" = "A" ] && PICKED="$LABEL_A" || {
        LABEL_B=$(jq -r '.version_B' "$PHASE7B/assignment.json" 2>/dev/null)
        PICKED="$LABEL_B"
      }
      [ "$PICKED" = "c_llm" ] && PICKED_CLLM=$((PICKED_CLLM + 1))
      [ "$PICKED" = "c_final" ] && PICKED_CFINAL=$((PICKED_CFINAL + 1))
      TOTAL=$((TOTAL + 1))
    fi
    continue
  }

  # Random A/B assignment based on PR number
  PR_NUM=$(echo "$NAME" | grep -oE '[0-9]+$')
  if [ $((PR_NUM % 3)) -eq 0 ]; then
    DIFF_A="$CLLM"; LABEL_A="c_llm"
    DIFF_B="$CFINAL_DIFF"; LABEL_B="c_final"
  else
    DIFF_A="$CFINAL_DIFF"; LABEL_A="c_final"
    DIFF_B="$CLLM"; LABEL_B="c_llm"
  fi

  jq -n --arg a "$LABEL_A" --arg b "$LABEL_B" '{version_A: $a, version_B: $b}' > "$PHASE7B/assignment.json"

  GOAL=$(head -30 "$TRIAL/goal/GOAL.md" 2>/dev/null || head -30 "$DIR/goal/GOAL.md" 2>/dev/null || echo "No description available")
  DIFF_A_CONTENT=$(head -300 "$DIFF_A")
  DIFF_B_CONTENT=$(head -300 "$DIFF_B")

  echo "$NAME: Phase 7b (A=$LABEL_A, B=$LABEL_B)..."

  # Use codex for the review
  REVIEW=$(codex exec "You are reviewing a pull request. Two implementations of the same change. Both pass tests. Pick the one you'd approve for merge.

## PR Context

$GOAL

## Version A
\`\`\`diff
$DIFF_A_CONTENT
\`\`\`

## Version B
\`\`\`diff
$DIFF_B_CONTENT
\`\`\`

Pick A or B. Brief rationale (1-2 sentences).

Respond ONLY as JSON, no other text:
{\"forced_choice\": \"A\" or \"B\", \"rationale\": \"...\"}
" 2>&1)

  # Extract JSON from codex output
  echo "$REVIEW" > "$PHASE7B/stdout.log"
  JSON_LINE=$(echo "$REVIEW" | grep -o '{[^}]*"forced_choice"[^}]*}' | tail -1 || echo "")

  if [ -n "$JSON_LINE" ]; then
    echo "$JSON_LINE" > "$PHASE7B/review.json"
    CHOICE=$(echo "$JSON_LINE" | jq -r '.forced_choice' 2>/dev/null || echo "")
    if [ "$CHOICE" = "A" ]; then
      PICKED="$LABEL_A"
    else
      PICKED="$LABEL_B"
    fi
    [ "$PICKED" = "c_llm" ] && PICKED_CLLM=$((PICKED_CLLM + 1))
    [ "$PICKED" = "c_final" ] && PICKED_CFINAL=$((PICKED_CFINAL + 1))
    TOTAL=$((TOTAL + 1))
    RATIONALE=$(echo "$JSON_LINE" | jq -r '.rationale' 2>/dev/null || echo "")
    echo "  → picked=$PICKED ($RATIONALE)"
  else
    echo "  → no JSON extracted"
    echo "{}" > "$PHASE7B/review.json"
  fi

  # Small delay to avoid rate limiting
  sleep 2
done

echo ""
echo "=== Phase 7b Results ==="
echo "Total:        $TOTAL"
echo "Picked c_llm:   $PICKED_CLLM"
echo "Picked c_final: $PICKED_CFINAL"
if [ $TOTAL -gt 0 ]; then
  echo "c_llm rate:   $(echo "scale=0; $PICKED_CLLM * 100 / $TOTAL" | bc)%"
fi
