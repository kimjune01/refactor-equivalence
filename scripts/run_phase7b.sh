#!/usr/bin/env bash
# Phase 7b — C_llm vs C_final blind forced choice
# "Is forge output as good as what humans shipped after review?"
set -euo pipefail

SAMPLES="/Users/junekim/Documents/refactor-equivalence/samples"

for DIR in $SAMPLES/v2-single-round/*/; do
  NAME=$(basename "$DIR")
  LOG="$DIR/pipeline.log"
  [ ! -f "$LOG" ] && continue
  grep -q "explicit build=1, test=1" "$LOG" 2>/dev/null || continue

  TRIAL="$SAMPLES/v2/$NAME"
  F="$TRIAL/find_c_test.json"
  [ ! -f "$F" ] && continue

  C_BASE=$(jq -r '.c_base' "$F")
  C_FINAL=$(jq -r '.c_final' "$F")
  C_TEST=$(jq -r '.c_test' "$F")

  # Need C_llm diff and C_final diff from C_base
  CLLM="$DIR/blind-blind/merged.diff"
  CFINAL_DIFF="$DIR/phase7/diff-human.patch"
  [ ! -s "$CLLM" ] && continue
  [ ! -s "$CFINAL_DIFF" ] && continue

  PHASE7B="$TRIAL/phase7b"
  mkdir -p "$PHASE7B"
  [ -f "$PHASE7B/review.json" ] && echo "$NAME: already done, skip" && continue

  # Random A/B assignment
  PR_NUM=$(echo "$NAME" | grep -oE '[0-9]+$')
  if [ $((PR_NUM % 3)) -eq 0 ]; then
    DIFF_A="$CLLM"; LABEL_A="c_llm"
    DIFF_B="$CFINAL_DIFF"; LABEL_B="c_final"
  else
    DIFF_A="$CFINAL_DIFF"; LABEL_A="c_final"
    DIFF_B="$CLLM"; LABEL_B="c_llm"
  fi

  jq -n --arg a "$LABEL_A" --arg b "$LABEL_B" '{version_A: $a, version_B: $b}' > "$PHASE7B/assignment.json"

  GOAL=$(head -30 "$TRIAL/goal/GOAL.md" 2>/dev/null || head -30 "$DIR/goal/GOAL.md" 2>/dev/null)
  DIFF_A_CONTENT=$(head -200 "$DIFF_A")
  DIFF_B_CONTENT=$(head -200 "$DIFF_B")

  echo "$NAME: Phase 7b (A=$LABEL_A, B=$LABEL_B)..."

  GEMINI_API_KEY= GOOGLE_API_KEY= GOOGLE_GENAI_USE_VERTEXAI=true \
    GOOGLE_APPLICATION_CREDENTIALS="$HOME/Downloads/atom.json" \
    GOOGLE_CLOUD_PROJECT=qvs-atom-gcp-research GOOGLE_CLOUD_LOCATION=global \
    command gemini -m gemini-3.1-pro-preview --approval-mode yolo -p "
## PR Context

$GOAL

## Forced choice

Two implementations of the same change. Both pass tests. Which would you approve for merge?

### Version A
\`\`\`diff
$DIFF_A_CONTENT
\`\`\`

### Version B
\`\`\`diff
$DIFF_B_CONTENT
\`\`\`

Pick A or B. Brief rationale.

Respond as JSON: {\"forced_choice\": \"A\" or \"B\", \"rationale\": \"...\"}
" > "$PHASE7B/stdout.log" 2>&1

  grep -o '{.*}' "$PHASE7B/stdout.log" | tail -1 > "$PHASE7B/review.json" 2>/dev/null

  if [ -s "$PHASE7B/review.json" ]; then
    CHOICE=$(jq -r '.forced_choice' "$PHASE7B/review.json" 2>/dev/null)
    [ "$CHOICE" = "A" ] && PICKED="$LABEL_A" || PICKED="$LABEL_B"
    echo "  → picked=$PICKED"
  else
    echo "  → no JSON"
  fi
done
