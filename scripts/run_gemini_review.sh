#!/usr/bin/env bash
# Run gemini as Phase 7 reviewer for one PR.
# Two invocations to preserve Phase 1 blinding.
#
# Usage:
#   PR=24437 ./scripts/run_gemini_review.sh
set -euo pipefail
: "${PR:?}"
BUNDLE=/Users/junekim/Documents/refactor-equivalence/samples/dev/$PR

# Assignment-aware: read A/B → c_test/c_llm mapping
A_SNAP=$(jq -r '.candidate_A' "$BUNDLE/review-assignment.json")
B_SNAP=$(jq -r '.candidate_B' "$BUNDLE/review-assignment.json")

# Phase 1: blind forced choice. Only A and B visible, not C_final.
P1_PROMPT="You are acting as a blinded code reviewer for a Phase 1 forced-choice merge-readiness review.

Read the review bundle at $BUNDLE/review-bundle.md for the task definition.

Read Candidate A's diff at $BUNDLE/diff-A.patch and Candidate B's diff at $BUNDLE/diff-B.patch.

DO NOT read any other file in $BUNDLE. Specifically: do not read diff-C_final.patch, review-assignment.json, or any other artifact.

Answer only Phase 1. Do NOT answer Phase 2 or Phase 3 in this response.

Output only a single JSON object with these fields:
{
  \"phase_1_choice\": \"A\" or \"B\",
  \"phase_1_rationale\": \"<1-2 sentences>\",
  \"phase_1_semantic_concerns\": {
    \"A\": \"<concern or null>\",
    \"B\": \"<concern or null>\"
  }
}

Write the JSON to $BUNDLE/review-phase1.json. Do not print the JSON inline; only write the file."

gemini -m gemini-3.1-pro-preview --approval-mode yolo \
  --include-directories "$BUNDLE" \
  -p "$P1_PROMPT" \
  > "$BUNDLE/gemini-p1-stdout.log" 2>&1

# Phase 2 + 3: reveal C_final, classify trajectory + blinding check.
P23_PROMPT="You previously reviewed Candidate A and Candidate B for PR $PR and answered Phase 1. Your Phase 1 answer is at $BUNDLE/review-phase1.json.

Now proceed to Phase 2 and Phase 3 as described in $BUNDLE/review-bundle.md.

Read the C_final diff at $BUNDLE/diff-C_final.patch — this is the version reviewers accepted on the original PR.

For Phase 2: classify Candidate A and Candidate B each into one of: past, short, wrong, relative to C_final.

For Phase 3: report whether you could tell which candidate was final/LLM/identifiable based on style, polish, diff shape, or any other signal.

Output only a single JSON object with these fields:
{
  \"phase_2_trajectory_A\": \"past\" or \"short\" or \"wrong\",
  \"phase_2_trajectory_B\": \"past\" or \"short\" or \"wrong\",
  \"phase_3_blinding\": {
    \"believed_a_final\": true or false,
    \"believed_b_final\": true or false,
    \"believed_a_llm\": true or false,
    \"believed_b_llm\": true or false,
    \"identifying_signals\": \"<sentence or null>\"
  }
}

Write the JSON to $BUNDLE/review-phase23.json. Do not print the JSON inline; only write the file."

gemini -m gemini-3.1-pro-preview --approval-mode yolo \
  --include-directories "$BUNDLE" \
  -p "$P23_PROMPT" \
  > "$BUNDLE/gemini-p23-stdout.log" 2>&1

echo "PR $PR: review done"
[ -f "$BUNDLE/review-phase1.json" ] && cat "$BUNDLE/review-phase1.json" | head -5
[ -f "$BUNDLE/review-phase23.json" ] && cat "$BUNDLE/review-phase23.json" | head -10
