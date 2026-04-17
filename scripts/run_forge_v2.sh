#!/usr/bin/env bash
# v2 forge pipeline orchestrator — single-round MVP.
#
# Runs the v2 pipeline end-to-end on one PR. Iterative phases (hunt-spec,
# hunt-code, reviewer-loop) start as single-round; expand to iterative if
# dev-set observations show convergence issues.
#
# Usage:
#   PR=24460 \
#   REPO=gemini-cli \
#   SRC_REPO=/tmp/refactor-eq-workdir/gemini-cli \
#   C_BASE=<sha> \
#   C_TEST=<sha> \
#   TRIAL_DIR=/Users/.../samples/v2/gemini-cli-24460 \
#   CLEANROOM=/tmp/refactor-eq-workdir/cleanroom-v2/24460 \
#   TEST_CMD="npm run test --workspaces --if-present -- --exclude '**/sandboxManager.integration.test.ts'" \
#   BUILD_CMD="npm run build" \
#   ./scripts/run_forge_v2.sh
set -euo pipefail

: "${PR:?}"
: "${REPO:?}"
: "${SRC_REPO:?}"
: "${C_BASE:?}"
: "${C_TEST:?}"
: "${TRIAL_DIR:?}"
: "${CLEANROOM:?}"
: "${TEST_CMD:?}"
: "${BUILD_CMD:=npm run build}"

PROMPTS=/Users/junekim/Documents/refactor-equivalence/prompts/forge-v2
SCRIPTS=/Users/junekim/Documents/refactor-equivalence/scripts

mkdir -p "$TRIAL_DIR"/{inputs,volley,blind-blind,gates,reviewer-loop,c_llm,measurements,phase7}
touch "$TRIAL_DIR/anomalies.md" "$TRIAL_DIR/deviations.md"
# Clear stale no-op-class from any previous attempt; fresh run has no no-op by default
: > "$TRIAL_DIR/no-op-class.txt"

# Copy cleanroom's forge inputs into trial dir for prompt-path consistency
cp "$CLEANROOM/FORGE_INPUT_DIFF.patch"  "$TRIAL_DIR/inputs/diff-base-to-test.patch"
cp "$CLEANROOM/FORGE_ALLOWED_FILES.txt" "$TRIAL_DIR/inputs/allowed-files.txt"

log() { echo "[$(date -u +%FT%TZ)] $*" | tee -a "$TRIAL_DIR/pipeline.log"; }

render_prompt() {
  local src="$1"
  local n="${2:-1}"
  sed -e "s|{TRIAL_DIR}|$TRIAL_DIR|g" \
      -e "s|{CLEANROOM}|$CLEANROOM|g" \
      -e "s|{N}|$n|g" \
      -e "s|{N+1}|$((n+1))|g" \
      -e "s|{BUILD_CMD}|$BUILD_CMD|g" \
      -e "s|{TEST_CMD}|$TEST_CMD|g" \
      "$src"
}

# Ensure meta.json exists
if [ ! -f "$TRIAL_DIR/meta.json" ]; then
  jq -n \
    --arg pr "$PR" --arg repo "$REPO" \
    --arg cbase "$C_BASE" --arg ctest "$C_TEST" \
    --arg cleanroom "$CLEANROOM" \
    --arg test_cmd "$TEST_CMD" --arg build_cmd "$BUILD_CMD" \
    '{pr: $pr, repo: $repo, c_base: $cbase, c_test: $ctest, cleanroom: $cleanroom, test_cmd: $test_cmd, build_cmd: $build_cmd, v2_pipeline_start: now|todateiso8601}' \
    > "$TRIAL_DIR/meta.json"
fi

log "== v2 forge pipeline start — PR $PR =="
log "cleanroom: $CLEANROOM"
log "C_base: $C_BASE"
log "C_test: $C_TEST"

# ------------------------------------------------------------------
# 4a. Volley (goal-anchored) — codex GPT-5.4
# ------------------------------------------------------------------
N=1
log "[4a] Volley round $N"
VOLLEY_PROMPT=$(render_prompt "$PROMPTS/01-volley.md" "$N")
codex exec -c model="gpt-5.4" -s danger-full-access --skip-git-repo-check --cd "$CLEANROOM" "$VOLLEY_PROMPT" \
  > "$TRIAL_DIR/volley/round-$N-codex-stdout.log" 2>&1 || log "[4a] codex exec nonzero exit — inspect log"
if [ ! -f "$TRIAL_DIR/volley/round-$N-claims.md" ]; then
  log "[4a] WARNING: expected $TRIAL_DIR/volley/round-$N-claims.md not written by codex"
fi

# ------------------------------------------------------------------
# 4b. Hunt-spec (single round MVP) — codex
# ------------------------------------------------------------------
log "[4b] Hunt-spec round $N"
HUNT_SPEC_PROMPT=$(render_prompt "$PROMPTS/02-hunt-spec.md" "$N")
codex exec -c model="gpt-5.4" -s danger-full-access --skip-git-repo-check --cd "$CLEANROOM" "$HUNT_SPEC_PROMPT" \
  > "$TRIAL_DIR/volley/hunt-spec-round-$N-stdout.log" 2>&1 || log "[4b] codex nonzero — inspect log"

# ------------------------------------------------------------------
# 4c. Reconcile — codex
# ------------------------------------------------------------------
log "[4c] Reconcile"
RECONCILE_PROMPT=$(render_prompt "$PROMPTS/03-reconcile.md" "$N")
codex exec -c model="gpt-5.4" -s danger-full-access --skip-git-repo-check --cd "$CLEANROOM" "$RECONCILE_PROMPT" \
  > "$TRIAL_DIR/volley/reconcile-stdout.log" 2>&1 || log "[4c] codex nonzero — inspect log"
# The reconcile prompt writes to either round-2-claims.md or sharpened-spec-final.md.
# For single-round MVP we accept whichever exists and treat it as final.
if [ -f "$TRIAL_DIR/volley/sharpened-spec-final.md" ]; then
  FINAL_SPEC="$TRIAL_DIR/volley/sharpened-spec-final.md"
elif [ -f "$TRIAL_DIR/volley/round-2-claims.md" ]; then
  cp "$TRIAL_DIR/volley/round-2-claims.md" "$TRIAL_DIR/volley/sharpened-spec-final.md"
  FINAL_SPEC="$TRIAL_DIR/volley/sharpened-spec-final.md"
else
  log "[4c] WARNING: no reconciled spec written; using round-1 claims as final"
  if [ -f "$TRIAL_DIR/volley/round-$N-claims.md" ]; then
    cp "$TRIAL_DIR/volley/round-$N-claims.md" "$TRIAL_DIR/volley/sharpened-spec-final.md"
  else
    log "[4c] WARNING: no volley output at all — writing empty spec (expect trivial no-op)"
    printf '## Accepted Claims\n\n(none — volley produced no output)\n\n## Rejected\n\n' > "$TRIAL_DIR/volley/sharpened-spec-final.md"
  fi
  FINAL_SPEC="$TRIAL_DIR/volley/sharpened-spec-final.md"
fi

# ------------------------------------------------------------------
# 4d. Blind-blind-merge — opus + codex in separate dirs
# ------------------------------------------------------------------
OPUS_DIR="/tmp/refactor-eq-workdir/bb-opus-$PR"
CODEX_DIR="/tmp/refactor-eq-workdir/bb-codex-$PR"
for D in "$OPUS_DIR" "$CODEX_DIR"; do
  [ -d "$D" ] && mv "$D" "/tmp/bb-backup-$(basename "$D")-$(date +%s)"
  mkdir -p "$D"
  # Copy source tree (not node_modules) from cleanroom to each blind-blind dir
  rsync -a --exclude=node_modules --exclude=.git "$CLEANROOM/" "$D/"
  # Copy goal + spec + allowed files + input diff for the implementer
  cp "$TRIAL_DIR/goal/GOAL.md" "$D/GOAL.md"
  cp "$FINAL_SPEC" "$D/SHARPENED_SPEC.md"
  cp "$CLEANROOM/FORGE_INPUT_DIFF.patch" "$D/FORGE_INPUT_DIFF.patch"
  cp "$CLEANROOM/FORGE_ALLOWED_FILES.txt" "$D/FORGE_ALLOWED_FILES.txt"
done

log "[4d] Blind-blind implement: opus at $OPUS_DIR, codex at $CODEX_DIR"
IMPL_PROMPT=$(cat "$PROMPTS/04-implement.md")

# Opus (claude -p, non-interactive mode)
(
  cd "$OPUS_DIR"
  claude -p --model claude-opus-4-6 --dangerously-skip-permissions "$IMPL_PROMPT" \
    > "$TRIAL_DIR/blind-blind/opus-stdout.log" 2>&1
) &
OPUS_PID=$!

# Codex
(
  codex exec -c model="gpt-5.4" -s danger-full-access --skip-git-repo-check --cd "$CODEX_DIR" "$IMPL_PROMPT" \
    > "$TRIAL_DIR/blind-blind/codex-stdout.log" 2>&1
) &
CODEX_PID=$!

log "[4d] waiting for opus (pid $OPUS_PID) and codex (pid $CODEX_PID)"
set +e
wait $OPUS_PID; OPUS_EXIT=$?
wait $CODEX_PID; CODEX_EXIT=$?
set -e
log "[4d] opus exit $OPUS_EXIT, codex exit $CODEX_EXIT"

# Diffs vs C_test
DIFF_EXCLUDES=(--exclude=node_modules --exclude=.git --exclude=dist --exclude=bundle --exclude=build --exclude=.next --exclude=target --exclude=GOAL.md --exclude=FORGE_INPUT_DIFF.patch --exclude=FORGE_ALLOWED_FILES.txt --exclude=SHARPENED_SPEC.md --exclude=IMPLEMENT_SUMMARY.md)
(cd "$OPUS_DIR" && diff -urN "$CLEANROOM" "$OPUS_DIR" "${DIFF_EXCLUDES[@]}" 2>/dev/null) > "$TRIAL_DIR/blind-blind/opus-dir.diff" || true
(cd "$CODEX_DIR" && diff -urN "$CLEANROOM" "$CODEX_DIR" "${DIFF_EXCLUDES[@]}" 2>/dev/null) > "$TRIAL_DIR/blind-blind/codex-dir.diff" || true

OPUS_CHURN=$(wc -l < "$TRIAL_DIR/blind-blind/opus-dir.diff" | tr -d ' ')
CODEX_CHURN=$(wc -l < "$TRIAL_DIR/blind-blind/codex-dir.diff" | tr -d ' ')
log "[4d] churn: opus=$OPUS_CHURN, codex=$CODEX_CHURN"

# Whole-model selection: smaller sum wins; tie → alpha (codex < opus)
if [ "$CODEX_CHURN" -le "$OPUS_CHURN" ]; then
  WINNER=codex
  WINNER_DIR="$CODEX_DIR"
else
  WINNER=opus
  WINNER_DIR="$OPUS_DIR"
fi
log "[4d] winner: $WINNER"
jq -n --arg winner "$WINNER" --arg opus_churn "$OPUS_CHURN" --arg codex_churn "$CODEX_CHURN" \
  '{winner: $winner, opus_churn: $opus_churn|tonumber, codex_churn: $codex_churn|tonumber, rule: "smaller-sum-of-churn, tie→alpha"}' \
  > "$TRIAL_DIR/blind-blind/merge-decisions.json"

# Assemble merged candidate: apply winner's changes onto cleanroom copy
MERGED_DIR="/tmp/refactor-eq-workdir/bb-merged-$PR"
[ -d "$MERGED_DIR" ] && mv "$MERGED_DIR" "/tmp/bb-backup-merged-$(date +%s)"
rsync -a --exclude=node_modules --exclude=.git "$WINNER_DIR/" "$MERGED_DIR/"

# Hydrate deps in merged_dir (language-aware)
(
  cd "$MERGED_DIR"
  if [ -f pnpm-lock.yaml ]; then
    pnpm install --frozen-lockfile --ignore-scripts >> "$TRIAL_DIR/gates/merged-install.log" 2>&1
  elif [ -f package.json ]; then
    ORIG_PKG=$(mktemp)
    cp "$CLEANROOM/package.json" "$ORIG_PKG"
    TMP_PJ=$(mktemp)
    jq '.scripts.prepare = "echo skipping prepare"' package.json > "$TMP_PJ" && mv "$TMP_PJ" package.json
    npm ci --prefer-offline --no-audit --no-fund >> "$TRIAL_DIR/gates/merged-install.log" 2>&1
    cp "$ORIG_PKG" "$MERGED_DIR/package.json"
    rm -f "$ORIG_PKG"
  elif [ -f go.mod ]; then
    go mod download >> "$TRIAL_DIR/gates/merged-install.log" 2>&1
  fi
) && log "[4d] merged_dir install OK" || log "[4d] merged_dir install FAILED — inspect gates/merged-install.log"

# Remove pipeline-input artifacts so the merged diff reflects ONLY refactor changes.
if [ -f "$MERGED_DIR/IMPLEMENT_SUMMARY.md" ]; then
  cp "$MERGED_DIR/IMPLEMENT_SUMMARY.md" "$TRIAL_DIR/blind-blind/winner-implement-summary.md"
fi
for f in IMPLEMENT_SUMMARY.md SHARPENED_SPEC.md GOAL.md FORGE_INPUT_DIFF.patch FORGE_ALLOWED_FILES.txt; do
  rm -f "$MERGED_DIR/$f"
done

# Save merged diff (exclude build/install artifacts + pipeline-input scaffolding
# so the diff reflects only source-level changes the implementer made).
(cd "$CLEANROOM" && diff -urN "$CLEANROOM" "$MERGED_DIR" "${DIFF_EXCLUDES[@]}" 2>/dev/null) > "$TRIAL_DIR/blind-blind/merged.diff" || true

# ------------------------------------------------------------------
# 4e. Implementation evidence check
# ------------------------------------------------------------------
# Check the saved summary copy from winner's dir (merged_dir may have been
# cleaned of pipeline artifacts already).
SUMMARY_FILE="$TRIAL_DIR/blind-blind/winner-implement-summary.md"
if [ ! -f "$SUMMARY_FILE" ]; then
  log "[4e] WARNING: no IMPLEMENT_SUMMARY.md from winner — declaring trivial no-op"
  echo "trivial" > "$TRIAL_DIR/no-op-class.txt"
fi
# We cheaply check: if merged.diff is empty → trivial no-op
MERGED_LINES=$(wc -l < "$TRIAL_DIR/blind-blind/merged.diff" | tr -d ' ')
log "[4e] merged diff lines: $MERGED_LINES"
if [ "$MERGED_LINES" -eq 0 ]; then
  echo "trivial" > "$TRIAL_DIR/no-op-class.txt"
  log "[4e] trivial no-op: merged diff empty"
fi

# ------------------------------------------------------------------
# 4f. Hunt-code (single round MVP, full build+tests) — codex
# ------------------------------------------------------------------
log "[4f] Hunt-code round 1"
HUNT_CODE_PROMPT=$(render_prompt "$PROMPTS/05-hunt-code.md" 1)
codex exec -c model="gpt-5.4" -s danger-full-access --skip-git-repo-check --cd "$MERGED_DIR" "$HUNT_CODE_PROMPT" \
  > "$TRIAL_DIR/gates/hunt-code-round-1-stdout.log" 2>&1 || log "[4f] codex nonzero — inspect log"

# Run build + test explicitly too (in case codex didn't do it)
(cd "$MERGED_DIR" && eval "$BUILD_CMD" > "$TRIAL_DIR/gates/build-log.txt" 2>&1) && BUILD_OK=1 || BUILD_OK=0
(cd "$MERGED_DIR" && eval "$TEST_CMD" > "$TRIAL_DIR/gates/test-log.txt" 2>&1) && TEST_OK=1 || TEST_OK=0
log "[4f] explicit build=$BUILD_OK, test=$TEST_OK"

if [ "$BUILD_OK" = "0" ] || [ "$TEST_OK" = "0" ]; then
  log "[4f] build or test failed — hard no-op, falling back to C_test"
  echo "hard" > "$TRIAL_DIR/no-op-class.txt"
  # C_llm = C_test for metrics
  cp "$CLEANROOM/FORGE_INPUT_DIFF.patch" "$TRIAL_DIR/c_llm/diff.patch.placeholder"
  log "pipeline aborted at 4f"
  exit 0
fi

# ------------------------------------------------------------------
# 4g. Reviewer-loop (single round MVP) — Gemini
# ------------------------------------------------------------------
log "[4g] Reviewer-loop round 1"
# Save input diff for reviewer
cp "$TRIAL_DIR/blind-blind/merged.diff" "$TRIAL_DIR/reviewer-loop/round-1-input.diff"

REVIEWER_PROMPT=$(render_prompt "$PROMPTS/06-reviewer-loop.md" 1)
GEMINI_API_KEY= GOOGLE_API_KEY= GOOGLE_GENAI_USE_VERTEXAI=true \
  GOOGLE_APPLICATION_CREDENTIALS="$HOME/Downloads/atom.json" \
  GOOGLE_CLOUD_PROJECT=qvs-atom-gcp-research GOOGLE_CLOUD_LOCATION=global \
  command gemini -m gemini-3.1-pro-preview --approval-mode yolo -p "$REVIEWER_PROMPT" \
  > "$TRIAL_DIR/reviewer-loop/round-1-stdout.log" 2>&1 || log "[4g] gemini nonzero — inspect log"

# Reviewer's comments were written by gemini to round-1-comments.md (per prompt)
# For MVP we stop after round 1.
log "[4g] reviewer-loop round 1 complete (single-round MVP)"

# ------------------------------------------------------------------
# 4h. Ship-time complexity gate
# ------------------------------------------------------------------
log "[4h] Ship-time complexity gate"
SCOPE_FILES=$(paste -sd, "$CLEANROOM/FORGE_ALLOWED_FILES.txt")
if [ -n "$SCOPE_FILES" ]; then
  node "$SCRIPTS/complexity_gate_v2.mjs" \
    --c-test-dir "$CLEANROOM" \
    --c-llm-dir "$MERGED_DIR" \
    --scope-files "$SCOPE_FILES" \
    --delta 0.05 \
    --out "$TRIAL_DIR/gates/complexity-gate.json" \
    && GATE_OK=1 || GATE_OK=0
  log "[4h] gate result: pass=$GATE_OK"
  if [ "$GATE_OK" = "0" ]; then
    log "[4h] complexity regressed; falling back to C_test"
    echo "complexity-gate-fail" >> "$TRIAL_DIR/deviations.md"
    # Still save what we had
  fi
else
  log "[4h] scope-files empty; skipping gate"
fi

# ------------------------------------------------------------------
# Finalize — save C_llm artifacts
# ------------------------------------------------------------------
mkdir -p "$TRIAL_DIR/c_llm/files"
cp "$TRIAL_DIR/blind-blind/merged.diff" "$TRIAL_DIR/c_llm/diff.patch"
# Copy modified files only (from allowed set)
while IFS= read -r f; do
  [ -z "$f" ] && continue
  if [ -f "$MERGED_DIR/$f" ]; then
    mkdir -p "$TRIAL_DIR/c_llm/files/$(dirname "$f")"
    cp "$MERGED_DIR/$f" "$TRIAL_DIR/c_llm/files/$f"
  fi
done < "$CLEANROOM/FORGE_ALLOWED_FILES.txt"

# Update meta.json
jq --arg end "$(date -u +%FT%TZ)" \
   --arg no_op "$(cat "$TRIAL_DIR/no-op-class.txt" 2>/dev/null || echo none)" \
   '.v2_pipeline_end = $end | .no_op_class = $no_op' \
   "$TRIAL_DIR/meta.json" > "$TRIAL_DIR/meta.json.tmp" \
   && mv "$TRIAL_DIR/meta.json.tmp" "$TRIAL_DIR/meta.json"

log "== pipeline complete =="
