#!/usr/bin/env bash
# Build blind review bundle for Phase 7 — cli/cli variant.
# Same structure as build_review_bundle.sh but with Go repo paths.
set -euo pipefail
: "${PR:?}"
REPO=/tmp/refactor-eq-workdir/cli
SNAP=/tmp/refactor-eq-workdir/snapshots-cli/$PR
OUT=/Users/junekim/Documents/refactor-equivalence/samples/dev/cli-$PR

mkdir -p "$OUT"

SEED=$(printf "%s" "$PR" | shasum -a 256 | awk '{print $1}' | cut -c1)
case $SEED in
  0|1|2|3|4|5|6|7) A_SNAP=c_test ; B_SNAP=c_llm ;;
  *) A_SNAP=c_llm ; B_SNAP=c_test ;;
esac

cd $REPO
case $PR in
  12567) BASE=af4dad088a8ac767ff4710b5e9f8b7dc4986fc51;;
  12695) BASE=1af2823fc330004cb1e00ecdde6032040237de6d;;
  12696) BASE=027adc7bf5045f264bf038fb9a5dc170abef22a9;;
  *) echo "unknown PR $PR"; exit 1;;
esac

TITLE=$(gh pr view $PR -R cli/cli --json title --jq '.title')
BODY=$(gh pr view $PR -R cli/cli --json body --jq '.body')

build_diff() {
  local snap=$1
  local out=$2
  : > "$out"
  for f in $(find "$SNAP/$snap" -type f -name '*.go' 2>/dev/null); do
    rel=${f#$SNAP/$snap/}
    if git show "$BASE:$rel" > /tmp/_base_file 2>/dev/null; then
      diff -u --label "a/$rel" --label "b/$rel" /tmp/_base_file "$f" >> "$out" 2>/dev/null || true
    else
      diff -u --label "a/$rel" --label "b/$rel" /dev/null "$f" >> "$out" 2>/dev/null || true
    fi
  done
  rm -f /tmp/_base_file
}

build_diff "$A_SNAP" "$OUT/diff-A.patch"
build_diff "$B_SNAP" "$OUT/diff-B.patch"
build_diff c_final "$OUT/diff-C_final.patch"

cat > "$OUT/review-assignment.json" <<EOF
{
  "pr": $PR,
  "repo": "cli/cli",
  "seed": "$SEED",
  "candidate_A": "$A_SNAP",
  "candidate_B": "$B_SNAP",
  "revealed_in_phase_2": "c_final"
}
EOF

cat > "$OUT/review-bundle.md" <<EOF
# Blind merge-readiness review — cli/cli PR $PR

## PR metadata (reviewer sees)

**Title:** $TITLE

**Body:**

$BODY

## Task description

Two candidate Go implementations of the PR's stated purpose are available as diffs from the same base commit. You will evaluate them in two phases. You may not see the original PR discussion, the version reviewers actually accepted, or which version was produced by an LLM.

Assume the test suite passes on both candidates. Your judgment is about merge-readiness on code quality and maintainability, not about correctness.

## Phase 1 — Forced choice

- **Candidate A**: \`diff-A.patch\`
- **Candidate B**: \`diff-B.patch\`

**Question:** Assuming tests pass, which version would you approve for merge?

Answer: A or B. Rationale 1–2 sentences. Note semantic concerns per candidate.

## Phase 2 — Trajectory classification

See C_final diff at \`diff-C_final.patch\` — the version reviewers accepted.

Classify Candidate A and Candidate B each as: past / short / wrong relative to C_final.

## Phase 3 — Blinding check

Did you believe any candidate was final/LLM-generated? Identifying signals?

## Output format

Write JSON:
\`\`\`json
{
  "phase_1_choice": "A" | "B",
  "phase_1_rationale": "<1-2 sentences>",
  "phase_1_semantic_concerns": { "A": "<concern or null>", "B": "<concern or null>" },
  "phase_2_trajectory_A": "past" | "short" | "wrong",
  "phase_2_trajectory_B": "past" | "short" | "wrong",
  "phase_3_blinding": {
    "believed_a_final": true | false,
    "believed_b_final": true | false,
    "believed_a_llm": true | false,
    "believed_b_llm": true | false,
    "identifying_signals": "<sentence or null>"
  }
}
\`\`\`
EOF

echo "Built bundle: $OUT/review-bundle.md"
echo "  A = $A_SNAP, B = $B_SNAP (seed $SEED)"
echo "  diff-A: $(wc -l < $OUT/diff-A.patch) lines"
echo "  diff-B: $(wc -l < $OUT/diff-B.patch) lines"
