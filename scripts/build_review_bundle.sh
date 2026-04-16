#!/usr/bin/env bash
# Build a blind review bundle for Phase 7.
#
# Reviewer sees:
#   - PR title
#   - PR body
#   - Neutral task description
#   - Unlabeled diffs from C_base → Candidate A and C_base → Candidate B
#
# {A, B} = {C_test, C_llm} in order determined by a per-PR deterministic seed.
#
# Usage:
#   PR=24437 ./scripts/build_review_bundle.sh
#
# Reads:
#   /tmp/refactor-eq-workdir/snapshots/$PR/{c_test,c_llm,c_final}
# Writes:
#   samples/dev/$PR/review-bundle.md
#   samples/dev/$PR/review-assignment.json  (A/B → c_test|c_llm)
set -euo pipefail
: "${PR:?}"
REPO=/tmp/refactor-eq-workdir/gemini-cli
SNAP=/tmp/refactor-eq-workdir/snapshots/$PR
OUT=/Users/junekim/Documents/refactor-equivalence/samples/dev/$PR

mkdir -p "$OUT"

# Deterministic but distributed A/B assignment: parity of SHA256(PR)
SEED=$(printf "%s" "$PR" | shasum -a 256 | awk '{print $1}' | cut -c1)
# Map hex char to 0 or 1 based on high bit
case $SEED in
  0|1|2|3|4|5|6|7) A_SNAP=c_test ; B_SNAP=c_llm ;;
  *) A_SNAP=c_llm ; B_SNAP=c_test ;;
esac

# Per-PR metadata
cd $REPO
case $PR in
  24437) BASE=7d1848d578b644c274fcd1f6d03685aafc19e8ed;;
  24483) BASE=beff8c91aa48d6f0d080debe7a682d46a0016cf7;;
  24489) BASE=615e078341fc09cac56dbf26588ff69254d66899;;
  24623) BASE=15298b28c2753bab9e72b3f432ceb423a3ac981f;;
  25101) BASE=0fd0851e1a05d34a714296c86df71197f8f940f8;;
  *) echo "unknown PR $PR"; exit 1;;
esac

TITLE=$(gh pr view $PR -R google-gemini/gemini-cli --json title --jq '.title')
BODY=$(gh pr view $PR -R google-gemini/gemini-cli --json body --jq '.body')

# Build diff A: C_base → Candidate A
# For each file in the snapshot, compare against C_base in the source repo.
build_diff() {
  local snap=$1
  local out=$2
  : > "$out"
  for f in $(find "$SNAP/$snap" -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.toml' \) 2>/dev/null); do
    rel=${f#$SNAP/$snap/}
    # Get C_base version of the file
    if git show "$BASE:$rel" > /tmp/_base_file 2>/dev/null; then
      diff -u --label "a/$rel" --label "b/$rel" /tmp/_base_file "$f" >> "$out" 2>/dev/null || true
    else
      # New file in candidate — show whole file as addition
      diff -u --label "a/$rel" --label "b/$rel" /dev/null "$f" >> "$out" 2>/dev/null || true
    fi
  done
  rm -f /tmp/_base_file
}

build_diff "$A_SNAP" "$OUT/diff-A.patch"
build_diff "$B_SNAP" "$OUT/diff-B.patch"
build_diff c_final "$OUT/diff-C_final.patch"

# Write assignment record
cat > "$OUT/review-assignment.json" <<EOF
{
  "pr": $PR,
  "seed": "$SEED",
  "candidate_A": "$A_SNAP",
  "candidate_B": "$B_SNAP",
  "revealed_in_phase_2": "c_final"
}
EOF

# Write the reviewer-facing bundle
cat > "$OUT/review-bundle.md" <<EOF
# Blind merge-readiness review — PR $PR

## PR metadata (reviewer sees)

**Title:** $TITLE

**Body:**

$BODY

## Task description

Two candidate implementations of the PR's stated purpose are available as diffs from the same base commit. You will evaluate them in two phases. You may not see the original PR discussion, the version reviewers actually accepted, or which version was produced by an LLM.

Assume the test suite passes on both candidates. Your judgment is about merge-readiness on code quality and maintainability, not about correctness.

## Phase 1 — Forced choice

Read both diffs:

- **Candidate A**: \`diff-A.patch\`
- **Candidate B**: \`diff-B.patch\`

**Question:** Assuming tests pass, which version would you approve for merge?

Answer: A or B.

Record your rationale in 1–2 sentences. If either version raises a semantic concern (behavior change not visible in the diff, likely regression, dangerous pattern), note it.

## Phase 2 — Trajectory classification

After Phase 1, you are shown a third diff: \`diff-C_final.patch\`. This is the version reviewers accepted on the merged PR.

Classify Candidate A and Candidate B relative to C_final, into one of three classes each:

- **Past C_final** — simpler than C_final and you would still approve it (simpler + no new correctness or clarity concerns)
- **Short of C_final** — improved over C_test but leaves complexity that C_final removed
- **Wrong direction** — no meaningful improvement, or worse than C_test

## Phase 3 — Blinding check

After Phases 1 and 2, answer:

- Did you believe any candidate was the final version?
- Did you believe any candidate was LLM-generated?
- Did any style, polish, or diff shape let you identify which candidate was which?

## Output format

Return a single JSON object with these fields:

\`\`\`json
{
  "phase_1_choice": "A" | "B",
  "phase_1_rationale": "<1-2 sentences>",
  "phase_1_semantic_concerns": {
    "A": "<concern or null>",
    "B": "<concern or null>"
  },
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
echo "  diff-A.patch: $(wc -l < $OUT/diff-A.patch) lines"
echo "  diff-B.patch: $(wc -l < $OUT/diff-B.patch) lines"
echo "  diff-C_final.patch: $(wc -l < $OUT/diff-C_final.patch) lines"
