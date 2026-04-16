#!/usr/bin/env bash
# Gemini reviewer for cli/cli PRs
set -euo pipefail
: "${PR:?}"
BUNDLE=/Users/junekim/Documents/refactor-equivalence/samples/dev/cli-$PR

P1_PROMPT="You are a blinded code reviewer doing Phase 1 forced-choice merge-readiness review of a Go (cli/cli) change.

Read $BUNDLE/review-bundle.md for the task.
Read $BUNDLE/diff-A.patch and $BUNDLE/diff-B.patch.
DO NOT read diff-C_final.patch, review-assignment.json, or any other file in $BUNDLE.

Answer only Phase 1. Write JSON to $BUNDLE/review-phase1.json with fields phase_1_choice, phase_1_rationale, phase_1_semantic_concerns.A, phase_1_semantic_concerns.B."

gemini -m gemini-3.1-pro-preview --approval-mode yolo \
  --include-directories "$BUNDLE" \
  -p "$P1_PROMPT" \
  > "$BUNDLE/gemini-p1-stdout.log" 2>&1

P23_PROMPT="Continue the review from Phase 1 (at $BUNDLE/review-phase1.json).

Now read $BUNDLE/diff-C_final.patch (the version reviewers accepted). Complete Phase 2 (trajectory classification: past/short/wrong for A and B) and Phase 3 (blinding check).

Write JSON to $BUNDLE/review-phase23.json with fields phase_2_trajectory_A, phase_2_trajectory_B, phase_3_blinding."

gemini -m gemini-3.1-pro-preview --approval-mode yolo \
  --include-directories "$BUNDLE" \
  -p "$P23_PROMPT" \
  > "$BUNDLE/gemini-p23-stdout.log" 2>&1

echo "PR $PR: review done"
