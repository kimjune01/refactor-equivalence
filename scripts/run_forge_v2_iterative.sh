#!/usr/bin/env bash
# v2 forge pipeline — FULL ITERATIVE per prereg.
#
# Hunt-spec: iterate to zero blockers, cap N=10.
# Hunt-code: iterate to zero findings + build+test pass, cap N=10.
# Reviewer-loop: iterate to zero comments or shrinkage stops, cap N=10.
#
# Usage: same as run_forge_v2.sh
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
MAX_ROUNDS=10

mkdir -p "$TRIAL_DIR"/{inputs,volley,blind-blind,gates,reviewer-loop,c_llm,measurements,phase7}
touch "$TRIAL_DIR/anomalies.md" "$TRIAL_DIR/deviations.md"
: > "$TRIAL_DIR/no-op-class.txt"

cp "$CLEANROOM/FORGE_INPUT_DIFF.patch"  "$TRIAL_DIR/inputs/diff-base-to-test.patch"
cp "$CLEANROOM/FORGE_ALLOWED_FILES.txt" "$TRIAL_DIR/inputs/allowed-files.txt"

log() { echo "[$(date -u +%FT%TZ)] $*" | tee -a "$TRIAL_DIR/pipeline.log"; }

render_prompt() {
  local src="$1"; local n="${2:-1}"
  sed -e "s|{TRIAL_DIR}|$TRIAL_DIR|g" -e "s|{CLEANROOM}|$CLEANROOM|g" \
      -e "s|{N}|$n|g" -e "s|{N+1}|$((n+1))|g" \
      -e "s|{BUILD_CMD}|$BUILD_CMD|g" -e "s|{TEST_CMD}|$TEST_CMD|g" \
      -e "s|{FINDINGS_FILE}|${3:-}|g" "$src"
}

if [ ! -f "$TRIAL_DIR/meta.json" ]; then
  jq -n --arg pr "$PR" --arg repo "$REPO" --arg cbase "$C_BASE" --arg ctest "$C_TEST" \
    --arg cleanroom "$CLEANROOM" --arg test_cmd "$TEST_CMD" --arg build_cmd "$BUILD_CMD" \
    '{pr:$pr,repo:$repo,c_base:$cbase,c_test:$ctest,cleanroom:$cleanroom,test_cmd:$test_cmd,build_cmd:$build_cmd,v2_pipeline_start:now|todateiso8601,iterative:true}' \
    > "$TRIAL_DIR/meta.json"
fi

log "== v2 ITERATIVE forge pipeline — PR $PR =="

# ==================================================================
# 4a+4b+4c. Volley + Hunt-spec + Reconcile — ITERATIVE to zero blockers
# ==================================================================
SPEC_ROUND=1
while [ $SPEC_ROUND -le $MAX_ROUNDS ]; do
  log "[4a] Volley round $SPEC_ROUND"
  VOLLEY_PROMPT=$(render_prompt "$PROMPTS/01-volley.md" "$SPEC_ROUND")
  codex exec -c model="gpt-5.4" -s danger-full-access --skip-git-repo-check --cd "$CLEANROOM" "$VOLLEY_PROMPT" \
    > "$TRIAL_DIR/volley/round-$SPEC_ROUND-codex-stdout.log" 2>&1 || log "[4a] codex nonzero"

  log "[4b] Hunt-spec round $SPEC_ROUND"
  HUNT_SPEC_PROMPT=$(render_prompt "$PROMPTS/02-hunt-spec.md" "$SPEC_ROUND")
  codex exec -c model="gpt-5.4" -s danger-full-access --skip-git-repo-check --cd "$CLEANROOM" "$HUNT_SPEC_PROMPT" \
    > "$TRIAL_DIR/volley/hunt-spec-round-$SPEC_ROUND-stdout.log" 2>&1 || log "[4b] codex nonzero"

  # Check for blockers
  FINDINGS_FILE="$TRIAL_DIR/volley/hunt-spec-round-$SPEC_ROUND.md"
  if [ -f "$FINDINGS_FILE" ]; then
    BLOCKERS=$(grep -ci "blocker" "$FINDINGS_FILE" 2>/dev/null || true)
    HAS_FINDINGS=$(grep -ci "finding" "$FINDINGS_FILE" 2>/dev/null || true)
  else
    BLOCKERS=0; HAS_FINDINGS=0
  fi

  if [ "$BLOCKERS" -eq 0 ] && [ "$HAS_FINDINGS" -eq 0 ]; then
    log "[4b] Hunt-spec round $SPEC_ROUND: no findings — spec converged"
    # Use current claims as final
    if [ -f "$TRIAL_DIR/volley/round-$SPEC_ROUND-claims.md" ]; then
      cp "$TRIAL_DIR/volley/round-$SPEC_ROUND-claims.md" "$TRIAL_DIR/volley/sharpened-spec-final.md"
    fi
    break
  fi

  if grep -qi "no findings" "$FINDINGS_FILE" 2>/dev/null; then
    log "[4b] Hunt-spec round $SPEC_ROUND: 'No findings' — spec converged"
    if [ -f "$TRIAL_DIR/volley/round-$SPEC_ROUND-claims.md" ]; then
      cp "$TRIAL_DIR/volley/round-$SPEC_ROUND-claims.md" "$TRIAL_DIR/volley/sharpened-spec-final.md"
    fi
    break
  fi

  log "[4b] Hunt-spec round $SPEC_ROUND: $BLOCKERS blockers, $HAS_FINDINGS findings — reconciling"
  log "[4c] Reconcile round $SPEC_ROUND"
  RECONCILE_PROMPT=$(render_prompt "$PROMPTS/03-reconcile.md" "$SPEC_ROUND")
  codex exec -c model="gpt-5.4" -s danger-full-access --skip-git-repo-check --cd "$CLEANROOM" "$RECONCILE_PROMPT" \
    > "$TRIAL_DIR/volley/reconcile-round-$SPEC_ROUND-stdout.log" 2>&1 || log "[4c] codex nonzero"

  # Check if reconcile produced next-round claims or final
  if [ -f "$TRIAL_DIR/volley/sharpened-spec-final.md" ]; then
    log "[4c] Reconcile produced sharpened-spec-final.md — done"
    break
  fi

  SPEC_ROUND=$((SPEC_ROUND + 1))
done

log "[spec] Converged after $SPEC_ROUND round(s)"

# Ensure final spec exists
if [ ! -f "$TRIAL_DIR/volley/sharpened-spec-final.md" ]; then
  LATEST_CLAIMS=$(ls -t "$TRIAL_DIR/volley/round-"*"-claims.md" 2>/dev/null | head -1)
  if [ -n "$LATEST_CLAIMS" ]; then
    cp "$LATEST_CLAIMS" "$TRIAL_DIR/volley/sharpened-spec-final.md"
  else
    printf '## Accepted Claims\n\n(none)\n\n## Rejected\n\n' > "$TRIAL_DIR/volley/sharpened-spec-final.md"
  fi
fi
FINAL_SPEC="$TRIAL_DIR/volley/sharpened-spec-final.md"

# ==================================================================
# 4d. Blind-blind-merge — opus + codex
# ==================================================================
OPUS_DIR="/tmp/refactor-eq-workdir/bb-opus-$PR"
CODEX_DIR="/tmp/refactor-eq-workdir/bb-codex-$PR"
DIFF_EXCLUDES=(--exclude=node_modules --exclude=.git --exclude=dist --exclude=bundle --exclude=build --exclude=.next --exclude=target --exclude=GOAL.md --exclude=FORGE_INPUT_DIFF.patch --exclude=FORGE_ALLOWED_FILES.txt --exclude=SHARPENED_SPEC.md --exclude=IMPLEMENT_SUMMARY.md --exclude=ADDRESS_SUMMARY.md)

for D in "$OPUS_DIR" "$CODEX_DIR"; do
  [ -d "$D" ] && mv "$D" "/tmp/bb-backup-$(basename "$D")-$(date +%s)"
  mkdir -p "$D"
  rsync -a --exclude=node_modules --exclude=.git "$CLEANROOM/" "$D/"
  cp "$TRIAL_DIR/goal/GOAL.md" "$D/GOAL.md"
  cp "$FINAL_SPEC" "$D/SHARPENED_SPEC.md"
  cp "$CLEANROOM/FORGE_INPUT_DIFF.patch" "$D/FORGE_INPUT_DIFF.patch"
  cp "$CLEANROOM/FORGE_ALLOWED_FILES.txt" "$D/FORGE_ALLOWED_FILES.txt"
done

log "[4d] Blind-blind implement"
IMPL_PROMPT=$(cat "$PROMPTS/04-implement.md")
(cd "$OPUS_DIR" && claude -p --model claude-opus-4-6 --dangerously-skip-permissions "$IMPL_PROMPT" > "$TRIAL_DIR/blind-blind/opus-stdout.log" 2>&1) &
OPUS_PID=$!
(codex exec -c model="gpt-5.4" -s danger-full-access --skip-git-repo-check --cd "$CODEX_DIR" "$IMPL_PROMPT" > "$TRIAL_DIR/blind-blind/codex-stdout.log" 2>&1) &
CODEX_PID=$!
set +e; wait $OPUS_PID; wait $CODEX_PID; set -e

(cd "$OPUS_DIR" && diff -urN "$CLEANROOM" "$OPUS_DIR" "${DIFF_EXCLUDES[@]}" 2>/dev/null) > "$TRIAL_DIR/blind-blind/opus-dir.diff" || true
(cd "$CODEX_DIR" && diff -urN "$CLEANROOM" "$CODEX_DIR" "${DIFF_EXCLUDES[@]}" 2>/dev/null) > "$TRIAL_DIR/blind-blind/codex-dir.diff" || true
OPUS_CHURN=$(wc -l < "$TRIAL_DIR/blind-blind/opus-dir.diff" | tr -d ' ')
CODEX_CHURN=$(wc -l < "$TRIAL_DIR/blind-blind/codex-dir.diff" | tr -d ' ')
log "[4d] churn: opus=$OPUS_CHURN, codex=$CODEX_CHURN"

if [ "$CODEX_CHURN" -le "$OPUS_CHURN" ]; then WINNER=codex; WINNER_DIR="$CODEX_DIR"
else WINNER=opus; WINNER_DIR="$OPUS_DIR"; fi
log "[4d] winner: $WINNER"
jq -n --arg w "$WINNER" --arg oc "$OPUS_CHURN" --arg cc "$CODEX_CHURN" \
  '{winner:$w,opus_churn:($oc|tonumber),codex_churn:($cc|tonumber)}' > "$TRIAL_DIR/blind-blind/merge-decisions.json"

# Assemble merged dir
MERGED_DIR="/tmp/refactor-eq-workdir/bb-merged-$PR"
[ -d "$MERGED_DIR" ] && mv "$MERGED_DIR" "/tmp/bb-backup-merged-$(date +%s)"
rsync -a --exclude=node_modules --exclude=.git "$WINNER_DIR/" "$MERGED_DIR/"

# Install deps
(
  cd "$MERGED_DIR"
  if [ -f pnpm-lock.yaml ]; then
    pnpm install --frozen-lockfile --ignore-scripts >> "$TRIAL_DIR/gates/merged-install.log" 2>&1
  elif [ -f package.json ]; then
    ORIG_PKG=$(mktemp); cp "$CLEANROOM/package.json" "$ORIG_PKG"
    TMP_PJ=$(mktemp); jq '.scripts.prepare = "echo skip"' package.json > "$TMP_PJ" && mv "$TMP_PJ" package.json
    npm ci --prefer-offline --no-audit --no-fund >> "$TRIAL_DIR/gates/merged-install.log" 2>&1
    cp "$ORIG_PKG" "$MERGED_DIR/package.json"; rm -f "$ORIG_PKG"
  elif [ -f go.mod ]; then
    go mod download >> "$TRIAL_DIR/gates/merged-install.log" 2>&1
  fi
) && log "[4d] install OK" || log "[4d] install FAILED"

# Clean pipeline artifacts
[ -f "$MERGED_DIR/IMPLEMENT_SUMMARY.md" ] && cp "$MERGED_DIR/IMPLEMENT_SUMMARY.md" "$TRIAL_DIR/blind-blind/winner-implement-summary.md"
for f in IMPLEMENT_SUMMARY.md SHARPENED_SPEC.md GOAL.md FORGE_INPUT_DIFF.patch FORGE_ALLOWED_FILES.txt ADDRESS_SUMMARY.md; do
  rm -f "$MERGED_DIR/$f"
done

(cd "$CLEANROOM" && diff -urN "$CLEANROOM" "$MERGED_DIR" "${DIFF_EXCLUDES[@]}" 2>/dev/null) > "$TRIAL_DIR/blind-blind/merged.diff" || true

# 4e evidence check
[ ! -f "$TRIAL_DIR/blind-blind/winner-implement-summary.md" ] && echo "trivial" > "$TRIAL_DIR/no-op-class.txt" && log "[4e] trivial no-op"
MERGED_LINES=$(wc -l < "$TRIAL_DIR/blind-blind/merged.diff" | tr -d ' ')
log "[4e] merged diff: $MERGED_LINES lines"
[ "$MERGED_LINES" -eq 0 ] && echo "trivial" > "$TRIAL_DIR/no-op-class.txt"

# ==================================================================
# 4f. Hunt-code — ITERATIVE: build+test+hunt → fix → repeat, cap N=10
# ==================================================================
HC_ROUND=1
while [ $HC_ROUND -le $MAX_ROUNDS ]; do
  log "[4f] Hunt-code round $HC_ROUND"

  # Build + test first
  set +e
  (cd "$MERGED_DIR" && eval "$BUILD_CMD" > "$TRIAL_DIR/gates/build-round-$HC_ROUND.log" 2>&1); B=$?
  (cd "$MERGED_DIR" && eval "$TEST_CMD" > "$TRIAL_DIR/gates/test-round-$HC_ROUND.log" 2>&1); T=$?
  set -e
  log "[4f] round $HC_ROUND build=$([ $B -eq 0 ] && echo PASS || echo FAIL) test=$([ $T -eq 0 ] && echo PASS || echo FAIL)"

  if [ $B -ne 0 ] || [ $T -ne 0 ]; then
    # Build/test failed — give implementer the error to fix
    log "[4f] round $HC_ROUND: build/test failed — implementer addressing"
    {
      echo "## Build/test failure — round $HC_ROUND"
      echo "**Build exit**: $B"
      [ $B -ne 0 ] && echo '```' && tail -30 "$TRIAL_DIR/gates/build-round-$HC_ROUND.log" && echo '```'
      echo "**Test exit**: $T"
      [ $T -ne 0 ] && echo '```' && tail -30 "$TRIAL_DIR/gates/test-round-$HC_ROUND.log" && echo '```'
    } > "$TRIAL_DIR/gates/hunt-code-round-$HC_ROUND.md"

    # Implementer fixes
    ADDRESS_PROMPT=$(render_prompt "$PROMPTS/07-address-findings.md" "$HC_ROUND" "$TRIAL_DIR/gates/hunt-code-round-$HC_ROUND.md")
    codex exec -c model="gpt-5.4" -s danger-full-access --skip-git-repo-check --cd "$MERGED_DIR" "$ADDRESS_PROMPT" \
      > "$TRIAL_DIR/gates/address-round-$HC_ROUND-stdout.log" 2>&1 || log "[4f] address nonzero"

    # Clean artifacts implementer may have left
    rm -f "$MERGED_DIR/ADDRESS_SUMMARY.md"

    HC_ROUND=$((HC_ROUND + 1))
    continue
  fi

  # Build+test pass — now run adversarial hunt
  HUNT_CODE_PROMPT=$(render_prompt "$PROMPTS/05-hunt-code.md" "$HC_ROUND")
  codex exec -c model="gpt-5.4" -s danger-full-access --skip-git-repo-check --cd "$MERGED_DIR" "$HUNT_CODE_PROMPT" \
    > "$TRIAL_DIR/gates/hunt-code-round-$HC_ROUND-stdout.log" 2>&1 || log "[4f] codex nonzero"

  FINDINGS_FILE="$TRIAL_DIR/gates/hunt-code-round-$HC_ROUND.md"
  if [ -f "$FINDINGS_FILE" ] && grep -qi "no findings" "$FINDINGS_FILE" 2>/dev/null; then
    log "[4f] Hunt-code round $HC_ROUND: zero findings — converged"
    break
  fi

  FINDING_COUNT=$(grep -ci "^## Finding" "$FINDINGS_FILE" 2>/dev/null || true)
  BLOCKER_COUNT=$(grep -ci "blocker" "$FINDINGS_FILE" 2>/dev/null || true)
  log "[4f] round $HC_ROUND: $FINDING_COUNT findings ($BLOCKER_COUNT blockers)"

  if [ "$FINDING_COUNT" -eq 0 ]; then
    log "[4f] No structured findings — treating as converged"
    break
  fi

  # Implementer addresses findings
  log "[4f] Implementer addressing round $HC_ROUND findings"
  ADDRESS_PROMPT=$(render_prompt "$PROMPTS/07-address-findings.md" "$HC_ROUND" "$FINDINGS_FILE")
  claude -p --model claude-opus-4-6 --dangerously-skip-permissions --add-dir "$MERGED_DIR" "$ADDRESS_PROMPT" \
    > "$TRIAL_DIR/gates/address-round-$HC_ROUND-stdout.log" 2>&1 || log "[4f] address nonzero"
  rm -f "$MERGED_DIR/ADDRESS_SUMMARY.md"

  HC_ROUND=$((HC_ROUND + 1))
done

if [ $HC_ROUND -gt $MAX_ROUNDS ]; then
  log "[4f] Hunt-code hit cap ($MAX_ROUNDS rounds) — unconverged"
fi

# Final build+test verification after convergence
set +e
(cd "$MERGED_DIR" && eval "$BUILD_CMD" > "$TRIAL_DIR/gates/build-log.txt" 2>&1); BUILD_OK=$?
(cd "$MERGED_DIR" && eval "$TEST_CMD" > "$TRIAL_DIR/gates/test-log.txt" 2>&1); TEST_OK=$?
set -e
log "[4f] final build=$([ $BUILD_OK -eq 0 ] && echo PASS || echo FAIL) test=$([ $TEST_OK -eq 0 ] && echo PASS || echo FAIL)"

if [ $BUILD_OK -ne 0 ] || [ $TEST_OK -ne 0 ]; then
  log "[4f] final build/test failed after $HC_ROUND rounds — hard no-op"
  echo "hard" > "$TRIAL_DIR/no-op-class.txt"
  log "pipeline aborted at 4f"
  exit 0
fi

# ==================================================================
# 4g. Reviewer-loop — ITERATIVE: review → fix → re-review, cap N=10
# ==================================================================
RV_ROUND=1
PREV_COMMENTS=999
while [ $RV_ROUND -le $MAX_ROUNDS ]; do
  log "[4g] Reviewer-loop round $RV_ROUND"

  # Generate diff for reviewer
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
    log "[4g] Reviewer round $RV_ROUND: 'No comments' — converged (approved)"
    echo "converged_approved" > "$TRIAL_DIR/reviewer-loop/final-state.txt"
    break
  fi

  CUR_COMMENTS=$(grep -ci "^## Comment" "$COMMENTS_FILE" 2>/dev/null || true)
  log "[4g] round $RV_ROUND: $CUR_COMMENTS comments (prev: $PREV_COMMENTS)"

  if [ "$CUR_COMMENTS" -eq 0 ]; then
    log "[4g] No structured comments — treating as approved"
    echo "converged_approved" > "$TRIAL_DIR/reviewer-loop/final-state.txt"
    break
  fi

  if [ "$CUR_COMMENTS" -ge "$PREV_COMMENTS" ]; then
    log "[4g] Comment count not shrinking ($CUR_COMMENTS >= $PREV_COMMENTS) — impasse"
    echo "impasse" > "$TRIAL_DIR/reviewer-loop/final-state.txt"
    break
  fi

  # Implementer addresses reviewer comments
  log "[4g] Implementer addressing round $RV_ROUND comments"
  ADDRESS_PROMPT=$(render_prompt "$PROMPTS/07-address-findings.md" "$RV_ROUND" "$COMMENTS_FILE")
  claude -p --model claude-opus-4-6 --dangerously-skip-permissions --add-dir "$MERGED_DIR" "$ADDRESS_PROMPT" \
    > "$TRIAL_DIR/reviewer-loop/address-round-$RV_ROUND-stdout.log" 2>&1 || log "[4g] address nonzero"
  rm -f "$MERGED_DIR/ADDRESS_SUMMARY.md"

  # Re-verify build+test after implementer changes
  set +e
  (cd "$MERGED_DIR" && eval "$BUILD_CMD" > /dev/null 2>&1); RB=$?
  (cd "$MERGED_DIR" && eval "$TEST_CMD" > /dev/null 2>&1); RT=$?
  set -e
  if [ $RB -ne 0 ] || [ $RT -ne 0 ]; then
    log "[4g] Implementer broke build/test addressing reviewer comments — reverting is too complex, accepting with comments"
    echo "impasse_build_broken" > "$TRIAL_DIR/reviewer-loop/final-state.txt"
    break
  fi

  PREV_COMMENTS=$CUR_COMMENTS
  RV_ROUND=$((RV_ROUND + 1))
done

if [ $RV_ROUND -gt $MAX_ROUNDS ]; then
  log "[4g] Reviewer-loop hit cap ($MAX_ROUNDS rounds)"
  echo "cap_hit" > "$TRIAL_DIR/reviewer-loop/final-state.txt"
fi

log "[4g] Reviewer-loop done after $RV_ROUND round(s): $(cat "$TRIAL_DIR/reviewer-loop/final-state.txt" 2>/dev/null || echo unknown)"

# ==================================================================
# 4h. Ship-time complexity gate
# ==================================================================
log "[4h] Ship-time complexity gate"
SCOPE_FILES=$(paste -sd, "$CLEANROOM/FORGE_ALLOWED_FILES.txt" 2>/dev/null || true)
if [ -n "$SCOPE_FILES" ]; then
  node "$SCRIPTS/complexity_gate_v2.mjs" \
    --c-test-dir "$CLEANROOM" --c-llm-dir "$MERGED_DIR" \
    --scope-files "$SCOPE_FILES" --delta 0.05 \
    --out "$TRIAL_DIR/gates/complexity-gate.json" \
    && GATE_OK=1 || GATE_OK=0
  log "[4h] gate: $([ $GATE_OK -eq 1 ] && echo PASS || echo FAIL)"
fi

# ==================================================================
# Finalize
# ==================================================================
mkdir -p "$TRIAL_DIR/c_llm/files"
(cd "$CLEANROOM" && diff -urN "$CLEANROOM" "$MERGED_DIR" "${DIFF_EXCLUDES[@]}" 2>/dev/null) > "$TRIAL_DIR/c_llm/diff.patch" || true
while IFS= read -r f; do
  [ -z "$f" ] && continue
  [ -f "$MERGED_DIR/$f" ] && { mkdir -p "$TRIAL_DIR/c_llm/files/$(dirname "$f")"; cp "$MERGED_DIR/$f" "$TRIAL_DIR/c_llm/files/$f"; }
done < "$CLEANROOM/FORGE_ALLOWED_FILES.txt" 2>/dev/null

jq --arg end "$(date -u +%FT%TZ)" \
   --arg noop "$(cat "$TRIAL_DIR/no-op-class.txt" 2>/dev/null || echo none)" \
   --arg spec_rounds "$SPEC_ROUND" --arg hc_rounds "$HC_ROUND" --arg rv_rounds "$RV_ROUND" \
   --arg rv_state "$(cat "$TRIAL_DIR/reviewer-loop/final-state.txt" 2>/dev/null || echo unknown)" \
   '.v2_pipeline_end=$end | .no_op_class=$noop | .spec_rounds=($spec_rounds|tonumber) | .hunt_code_rounds=($hc_rounds|tonumber) | .reviewer_rounds=($rv_rounds|tonumber) | .reviewer_final_state=$rv_state' \
   "$TRIAL_DIR/meta.json" > "$TRIAL_DIR/meta.json.tmp" && mv "$TRIAL_DIR/meta.json.tmp" "$TRIAL_DIR/meta.json"

log "== pipeline complete (spec=$SPEC_ROUND hc=$HC_ROUND rv=$RV_ROUND) =="
