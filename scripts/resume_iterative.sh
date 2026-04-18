#!/usr/bin/env bash
# Resume from single-round: rebuild merged_dir from saved diff, then run
# iterative hunt-code + reviewer-loop to convergence.
#
# Usage:
#   PR=24476 REPO=gemini-cli SRC_REPO=/tmp/refactor-eq-workdir/gemini-cli \
#   TEST_CMD="..." BUILD_CMD="..." ./scripts/resume_iterative.sh
set -euo pipefail

: "${PR:?}"
: "${REPO:?}"
: "${SRC_REPO:?}"
: "${TEST_CMD:?}"
: "${BUILD_CMD:?}"

SCRIPTS=/Users/junekim/Documents/refactor-equivalence/scripts
PROMPTS=/Users/junekim/Documents/refactor-equivalence/prompts/forge-v2
TRIAL_DIR="/Users/junekim/Documents/refactor-equivalence/samples/v2/${REPO}-${PR}"
OLD_TRIAL="/Users/junekim/Documents/refactor-equivalence/samples/v2-single-round/${REPO}-${PR}"
CLEANROOM="/tmp/refactor-eq-workdir/cleanroom-v2/${PR}"
MERGED_DIR="/tmp/refactor-eq-workdir/bb-merged-${PR}"
MAX_ROUNDS=10

DIFF_EXCLUDES=(--exclude=node_modules --exclude=.git --exclude=dist --exclude=bundle --exclude=build --exclude=.next --exclude=target --exclude=GOAL.md --exclude=FORGE_INPUT_DIFF.patch --exclude=FORGE_ALLOWED_FILES.txt --exclude=SHARPENED_SPEC.md --exclude=IMPLEMENT_SUMMARY.md --exclude=ADDRESS_SUMMARY.md)

log() { echo "[$(date -u +%FT%TZ)] $*" | tee -a "$TRIAL_DIR/pipeline-iterative.log"; }

render_prompt() {
  local src="$1"; local n="${2:-1}"
  sed -e "s|{TRIAL_DIR}|$TRIAL_DIR|g" -e "s|{CLEANROOM}|$CLEANROOM|g" \
      -e "s|{N}|$n|g" -e "s|{BUILD_CMD}|$BUILD_CMD|g" -e "s|{TEST_CMD}|$TEST_CMD|g" \
      -e "s|{FINDINGS_FILE}|${3:-}|g" "$src"
}

# 1. Rebuild cleanroom at C_test
C_TEST=$(jq -r '.c_test' "$TRIAL_DIR/find_c_test.json")
C_BASE=$(jq -r '.c_base' "$TRIAL_DIR/find_c_test.json")
log "== Resume iterative — $REPO-$PR =="
log "Rebuilding cleanroom at C_test=$C_TEST"

SRC_REPO="$SRC_REPO" C_BASE="$C_BASE" C_TEST="$C_TEST" \
  GOAL_FILE="$TRIAL_DIR/goal/GOAL.md" WORKSPACE="$CLEANROOM" \
  "$SCRIPTS/build_cleanroom_v2.sh"

# 2. Rebuild merged_dir from single-round's winner diff
log "Rebuilding merged_dir from single-round diff"
[ -d "$MERGED_DIR" ] && mv "$MERGED_DIR" "/tmp/bb-backup-merged-$(date +%s)"
# Start from cleanroom, apply the winner's changes
rsync -a --exclude=node_modules --exclude=.git "$CLEANROOM/" "$MERGED_DIR/"

# Apply the saved c_llm diff
DIFF_FILE="$OLD_TRIAL/c_llm/diff.patch"
if [ -f "$DIFF_FILE" ] && [ -s "$DIFF_FILE" ]; then
  # The diff is in diff -urN format; convert paths and apply
  cd "$MERGED_DIR"
  # Strip the absolute paths from the diff and apply
  sed "s|$CLEANROOM/||g; s|$MERGED_DIR/||g" "$DIFF_FILE" | patch -p0 --forward --silent 2>/dev/null || log "patch had rejects (may be ok)"
  cd /Users/junekim/Documents/refactor-equivalence
else
  # Try applying from c_llm/files/ directly
  if [ -d "$OLD_TRIAL/c_llm/files" ]; then
    rsync -a "$OLD_TRIAL/c_llm/files/" "$MERGED_DIR/"
    log "Applied c_llm files directly"
  else
    log "WARNING: no diff or files to apply — merged_dir = cleanroom"
  fi
fi

# 3. Install deps in merged_dir
(
  cd "$MERGED_DIR"
  if [ -f pnpm-lock.yaml ]; then
    pnpm install --frozen-lockfile --ignore-scripts > /dev/null 2>&1
  elif [ -f package.json ]; then
    TMP_PJ=$(mktemp); jq '.scripts.prepare = "echo skip"' package.json > "$TMP_PJ" && mv "$TMP_PJ" package.json
    npm ci --prefer-offline --no-audit --no-fund > /dev/null 2>&1
    cp "$CLEANROOM/package.json" "$MERGED_DIR/package.json"
  elif [ -f go.mod ]; then
    go mod download > /dev/null 2>&1
  fi
) && log "install OK" || log "install FAILED"

# Clean pipeline artifacts from merged_dir
for f in IMPLEMENT_SUMMARY.md SHARPENED_SPEC.md GOAL.md FORGE_INPUT_DIFF.patch FORGE_ALLOWED_FILES.txt ADDRESS_SUMMARY.md; do
  rm -f "$MERGED_DIR/$f"
done

# Copy inputs for prompts
mkdir -p "$TRIAL_DIR/gates" "$TRIAL_DIR/reviewer-loop"

# ==================================================================
# 4f. Hunt-code — ITERATIVE
# ==================================================================
HC_ROUND=1
while [ $HC_ROUND -le $MAX_ROUNDS ]; do
  log "[4f] Hunt-code round $HC_ROUND"

  set +e
  (cd "$MERGED_DIR" && eval "$BUILD_CMD" > "$TRIAL_DIR/gates/build-round-$HC_ROUND.log" 2>&1); B=$?
  (cd "$MERGED_DIR" && eval "$TEST_CMD" > "$TRIAL_DIR/gates/test-round-$HC_ROUND.log" 2>&1); T=$?
  set -e
  log "[4f] round $HC_ROUND build=$([ $B -eq 0 ] && echo PASS || echo FAIL) test=$([ $T -eq 0 ] && echo PASS || echo FAIL)"

  if [ $B -ne 0 ] || [ $T -ne 0 ]; then
    {
      echo "## Build/test failure — round $HC_ROUND"
      [ $B -ne 0 ] && echo '```' && tail -30 "$TRIAL_DIR/gates/build-round-$HC_ROUND.log" && echo '```'
      [ $T -ne 0 ] && echo '```' && tail -30 "$TRIAL_DIR/gates/test-round-$HC_ROUND.log" && echo '```'
    } > "$TRIAL_DIR/gates/hunt-code-round-$HC_ROUND.md"

    ADDRESS_PROMPT=$(render_prompt "$PROMPTS/07-address-findings.md" "$HC_ROUND" "$TRIAL_DIR/gates/hunt-code-round-$HC_ROUND.md")
    codex exec -c model="gpt-5.4" -s danger-full-access --skip-git-repo-check --cd "$MERGED_DIR" "$ADDRESS_PROMPT" \
      > "$TRIAL_DIR/gates/address-round-$HC_ROUND-stdout.log" 2>&1 || log "[4f] address nonzero"
    rm -f "$MERGED_DIR/ADDRESS_SUMMARY.md"
    HC_ROUND=$((HC_ROUND + 1))
    continue
  fi

  # Build+test pass — adversarial hunt
  HUNT_CODE_PROMPT=$(render_prompt "$PROMPTS/05-hunt-code.md" "$HC_ROUND")
  codex exec -c model="gpt-5.4" -s danger-full-access --skip-git-repo-check --cd "$MERGED_DIR" "$HUNT_CODE_PROMPT" \
    > "$TRIAL_DIR/gates/hunt-code-round-$HC_ROUND-stdout.log" 2>&1 || log "[4f] codex nonzero"

  FINDINGS_FILE="$TRIAL_DIR/gates/hunt-code-round-$HC_ROUND.md"
  if [ -f "$FINDINGS_FILE" ] && grep -qi "no findings" "$FINDINGS_FILE" 2>/dev/null; then
    log "[4f] round $HC_ROUND: zero findings — converged"
    break
  fi

  FINDING_COUNT=$(grep -ci "^## Finding" "$FINDINGS_FILE" 2>/dev/null || true)
  log "[4f] round $HC_ROUND: $FINDING_COUNT findings"

  if [ "$FINDING_COUNT" -eq 0 ]; then
    log "[4f] No structured findings — converged"
    break
  fi

  # Address findings
  log "[4f] Addressing round $HC_ROUND findings"
  ADDRESS_PROMPT=$(render_prompt "$PROMPTS/07-address-findings.md" "$HC_ROUND" "$FINDINGS_FILE")
  codex exec -c model="gpt-5.4" -s danger-full-access --skip-git-repo-check --cd "$MERGED_DIR" "$ADDRESS_PROMPT" \
    > "$TRIAL_DIR/gates/address-round-$HC_ROUND-stdout.log" 2>&1 || log "[4f] address nonzero"
  rm -f "$MERGED_DIR/ADDRESS_SUMMARY.md"

  HC_ROUND=$((HC_ROUND + 1))
done

# Final build+test
set +e
(cd "$MERGED_DIR" && eval "$BUILD_CMD" > "$TRIAL_DIR/gates/build-log.txt" 2>&1); BUILD_OK=$?
(cd "$MERGED_DIR" && eval "$TEST_CMD" > "$TRIAL_DIR/gates/test-log.txt" 2>&1); TEST_OK=$?
set -e
log "[4f] final build=$([ $BUILD_OK -eq 0 ] && echo PASS || echo FAIL) test=$([ $TEST_OK -eq 0 ] && echo PASS || echo FAIL)"

if [ $BUILD_OK -ne 0 ] || [ $TEST_OK -ne 0 ]; then
  log "[4f] final build/test failed — hard no-op"
  echo "hard" > "$TRIAL_DIR/no-op-class.txt"
  log "pipeline aborted at 4f after $HC_ROUND rounds"
  exit 0
fi

# ==================================================================
# 4g. Reviewer-loop — ITERATIVE
# ==================================================================
RV_ROUND=1
PREV_COMMENTS=999
while [ $RV_ROUND -le $MAX_ROUNDS ]; do
  log "[4g] Reviewer-loop round $RV_ROUND"

  (cd "$CLEANROOM" && diff -urN "$CLEANROOM" "$MERGED_DIR" "${DIFF_EXCLUDES[@]}" 2>/dev/null) \
    > "$TRIAL_DIR/reviewer-loop/round-$RV_ROUND-input.diff" || true

  REVIEWER_PROMPT=$(render_prompt "$PROMPTS/06-reviewer-loop.md" "$RV_ROUND")
  GEMINI_API_KEY= GOOGLE_API_KEY= GOOGLE_GENAI_USE_VERTEXAI=true \
    GOOGLE_APPLICATION_CREDENTIALS="$HOME/Downloads/atom.json" \
    GOOGLE_CLOUD_PROJECT=qvs-atom-gcp-research GOOGLE_CLOUD_LOCATION=global \
    command gemini -m gemini-3.1-pro-preview --approval-mode yolo -p "$REVIEWER_PROMPT" \
    > "$TRIAL_DIR/reviewer-loop/round-$RV_ROUND-stdout.log" 2>&1 || log "[4g] gemini nonzero"

  COMMENTS_FILE="$TRIAL_DIR/reviewer-loop/round-$RV_ROUND-comments.md"
  if [ -f "$COMMENTS_FILE" ] && grep -qi "no comments" "$COMMENTS_FILE" 2>/dev/null; then
    log "[4g] round $RV_ROUND: approved"
    echo "converged_approved" > "$TRIAL_DIR/reviewer-loop/final-state.txt"
    break
  fi

  CUR_COMMENTS=$(grep -ci "^## Comment" "$COMMENTS_FILE" 2>/dev/null || true)
  log "[4g] round $RV_ROUND: $CUR_COMMENTS comments (prev $PREV_COMMENTS)"

  if [ "$CUR_COMMENTS" -eq 0 ]; then
    echo "converged_approved" > "$TRIAL_DIR/reviewer-loop/final-state.txt"
    break
  fi

  if [ "$CUR_COMMENTS" -ge "$PREV_COMMENTS" ]; then
    log "[4g] Not shrinking — impasse"
    echo "impasse" > "$TRIAL_DIR/reviewer-loop/final-state.txt"
    break
  fi

  log "[4g] Addressing round $RV_ROUND comments"
  ADDRESS_PROMPT=$(render_prompt "$PROMPTS/07-address-findings.md" "$RV_ROUND" "$COMMENTS_FILE")
  codex exec -c model="gpt-5.4" -s danger-full-access --skip-git-repo-check --cd "$MERGED_DIR" "$ADDRESS_PROMPT" \
    > "$TRIAL_DIR/reviewer-loop/address-round-$RV_ROUND-stdout.log" 2>&1 || log "[4g] address nonzero"
  rm -f "$MERGED_DIR/ADDRESS_SUMMARY.md"

  # Verify build+test after fixes
  set +e
  (cd "$MERGED_DIR" && eval "$BUILD_CMD" > /dev/null 2>&1); RB=$?
  (cd "$MERGED_DIR" && eval "$TEST_CMD" > /dev/null 2>&1); RT=$?
  set -e
  if [ $RB -ne 0 ] || [ $RT -ne 0 ]; then
    log "[4g] Broke build/test — impasse"
    echo "impasse_build_broken" > "$TRIAL_DIR/reviewer-loop/final-state.txt"
    break
  fi

  PREV_COMMENTS=$CUR_COMMENTS
  RV_ROUND=$((RV_ROUND + 1))
done

[ $RV_ROUND -gt $MAX_ROUNDS ] && echo "cap_hit" > "$TRIAL_DIR/reviewer-loop/final-state.txt"
log "[4g] done after $RV_ROUND round(s): $(cat "$TRIAL_DIR/reviewer-loop/final-state.txt" 2>/dev/null)"

# Complexity gate
log "[4h] Complexity gate"
SCOPE_FILES=$(paste -sd, "$CLEANROOM/FORGE_ALLOWED_FILES.txt" 2>/dev/null || true)
if [ -n "$SCOPE_FILES" ]; then
  node "$SCRIPTS/complexity_gate_v2.mjs" \
    --c-test-dir "$CLEANROOM" --c-llm-dir "$MERGED_DIR" \
    --scope-files "$SCOPE_FILES" --delta 0.05 \
    --out "$TRIAL_DIR/gates/complexity-gate.json" \
    && log "[4h] PASS" || log "[4h] FAIL"
fi

# Update meta
jq --arg hc "$HC_ROUND" --arg rv "$RV_ROUND" \
   --arg state "$(cat "$TRIAL_DIR/reviewer-loop/final-state.txt" 2>/dev/null || echo unknown)" \
   --arg end "$(date -u +%FT%TZ)" \
   '. + {iterative_hunt_code_rounds:($hc|tonumber),iterative_reviewer_rounds:($rv|tonumber),iterative_reviewer_state:$state,iterative_end:$end}' \
   "$TRIAL_DIR/meta.json" > "$TRIAL_DIR/meta.json.tmp" && mv "$TRIAL_DIR/meta.json.tmp" "$TRIAL_DIR/meta.json" 2>/dev/null || true

log "== iterative complete (hc=$HC_ROUND rv=$RV_ROUND) =="
