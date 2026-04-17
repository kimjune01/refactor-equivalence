#!/usr/bin/env bash
# v2 find_c_test: earliest commit in PR branch where merge-time tests pass,
# with C_final's test files overlaid.
#
# Differences from v1 find_c_test.sh:
# - Operates in a git worktree (not the main repo) — safe for parallel trials.
# - Computes test-file diff between C_base and C_final; overlays additions,
#   modifications, and deletions (not just copies).
# - Runs npm ci + npm run build between commits so self-imports resolve.
# - Emits per-commit pass/fail JSON into OUT_DIR.
#
# Usage:
#   WORKTREE=/tmp/refactor-eq-workdir/v2-wt-24460 \
#   C_BASE=<sha> \
#   C_FINAL=<sha> \
#   TEST_CMD="npm run test --workspaces --if-present -- --exclude '**/x.test.ts'" \
#   BUILD_CMD="npm run build" \
#   OUT_DIR=/Users/.../samples/v2/gemini-cli-24460 \
#   ./scripts/find_c_test_v2.sh
#
# Optional:
#   TEST_GLOBS="*.test.ts *.test.tsx *_test.py *_test.go"   (default below)
set -euo pipefail

: "${WORKTREE:?}"
: "${C_BASE:?}"
: "${C_FINAL:?}"
: "${TEST_CMD:?}"
: "${BUILD_CMD:=npm run build}"
: "${INSTALL_CMD:=auto}"
: "${OUT_DIR:?}"
: "${TEST_GLOBS:=**/*.test.ts **/*.test.tsx **/*_test.go **/*_test.py **/test_*.py **/*.test.rs}"

mkdir -p "$OUT_DIR"
LOG="$OUT_DIR/find_c_test.log"
SUMMARY="$OUT_DIR/find_c_test.json"
: > "$LOG"

cd "$WORKTREE"

# ---- compute test-file changes between C_base and C_final ---------
# Use post-filter (grep) instead of git pathspec globs because git's default
# pathspec magic doesn't treat '**/' correctly. Filter on language-standard
# test-file suffixes.
TEST_REGEX='(\.test\.(ts|tsx|rs)$|_test\.(go|py)$|^tests/|/test_[^/]+\.py$)'

ADDED_OR_MODIFIED=$(git diff --diff-filter=AMR --name-only "$C_BASE" "$C_FINAL" 2>/dev/null | grep -E "$TEST_REGEX" || true)
DELETED=$(git diff --diff-filter=D --name-only "$C_BASE" "$C_FINAL" 2>/dev/null | grep -E "$TEST_REGEX" || true)

echo "[find_c_test_v2] added-or-modified tests ($(echo "$ADDED_OR_MODIFIED" | grep -c . || true)):" | tee -a "$LOG"
echo "$ADDED_OR_MODIFIED" | tee -a "$LOG"
echo "[find_c_test_v2] deleted tests ($(echo "$DELETED" | grep -c . || true)):" | tee -a "$LOG"
echo "$DELETED" | tee -a "$LOG"

# ---- walk commits C_base..C_final in chronological order ---------
COMMITS=$(git log --reverse --format=%H "$C_BASE..$C_FINAL")
N_COMMITS=$(echo "$COMMITS" | grep -c . || true)
echo "[find_c_test_v2] scanning $N_COMMITS commits" | tee -a "$LOG"

LAST_LOCKFILE=""
RESULTS=()

for C in $COMMITS; do
  echo "=== commit $C ===" | tee -a "$LOG"
  git -c advice.detachedHead=false checkout --quiet --force "$C"

  # Overlay C_final's test files
  if [ -n "$ADDED_OR_MODIFIED" ]; then
    for f in $ADDED_OR_MODIFIED; do
      mkdir -p "$(dirname "$f")"
      git show "$C_FINAL:$f" > "$f" 2>/dev/null || true
    done
  fi
  if [ -n "$DELETED" ]; then
    for f in $DELETED; do
      if [ -f "$f" ]; then rm -f "$f"; fi
    done
  fi

  # Reinstall deps only if lockfile changed vs last commit.
  # Detect lockfile: package-lock.json (npm), go.sum (Go), Cargo.lock (Rust)
  LF=""
  for _LF in package-lock.json pnpm-lock.yaml go.sum Cargo.lock; do
    [ -f "$_LF" ] && LF="$_LF" && break
  done
  [ -z "$LF" ] && LF="package-lock.json"  # fallback
  CUR_LOCKFILE=$(git hash-object "$LF" 2>/dev/null || echo none)
  if [ "$CUR_LOCKFILE" != "$LAST_LOCKFILE" ]; then
    echo "[find_c_test_v2] lockfile ($LF) changed → install" | tee -a "$LOG"
    # Determine install command
    if [ "$INSTALL_CMD" = "auto" ]; then
      if [ -f pnpm-lock.yaml ]; then
        RESOLVED_INSTALL="pnpm install --frozen-lockfile --ignore-scripts"
      elif [ -f package.json ]; then
        # npm: neutralize prepare script so broken PR-mid commits don't fail install
        TMP_PJ=$(mktemp)
        jq '.scripts.prepare = "echo skipping prepare"' package.json > "$TMP_PJ" && mv "$TMP_PJ" package.json
        RESOLVED_INSTALL="npm ci --prefer-offline --no-audit --no-fund"
      elif [ -f go.mod ]; then
        RESOLVED_INSTALL="go mod download"
      elif [ -f Cargo.toml ]; then
        RESOLVED_INSTALL="true"
      else
        RESOLVED_INSTALL="true"
      fi
    else
      RESOLVED_INSTALL="$INSTALL_CMD"
    fi
    if ! eval "$RESOLVED_INSTALL" >>"$LOG" 2>&1; then
      echo "FAIL_INSTALL $C" | tee -a "$LOG"
      RESULTS+=("{\"commit\":\"$C\",\"result\":\"fail_install\"}")
      continue
    fi
    LAST_LOCKFILE="$CUR_LOCKFILE"
  fi

  # Build
  if ! eval "$BUILD_CMD" >>"$LOG" 2>&1; then
    echo "FAIL_BUILD $C" | tee -a "$LOG"
    RESULTS+=("{\"commit\":\"$C\",\"result\":\"fail_build\"}")
    # Restore tree state before continuing
    git checkout --quiet --force "$C" -- . 2>/dev/null || true
    continue
  fi

  # Test
  if eval "$TEST_CMD" >>"$LOG" 2>&1; then
    echo "PASS $C" | tee -a "$LOG"
    echo "$C" > "$OUT_DIR/c_test_commit.txt"
    RESULTS+=("{\"commit\":\"$C\",\"result\":\"pass\"}")
    # Assemble summary JSON
    printf '{"c_test":"%s","c_base":"%s","c_final":"%s","added_or_modified_tests":%s,"deleted_tests":%s,"commits_scanned":%s}\n' \
      "$C" "$C_BASE" "$C_FINAL" \
      "$(printf '%s\n' $ADDED_OR_MODIFIED | jq -R . | jq -s .)" \
      "$(printf '%s\n' $DELETED | jq -R . | jq -s .)" \
      "[$(IFS=,; echo "${RESULTS[*]}")]" > "$SUMMARY"
    # Restore clean state
    git checkout --quiet --force "$C" -- . 2>/dev/null || true
    exit 0
  else
    echo "FAIL_TEST $C" | tee -a "$LOG"
    RESULTS+=("{\"commit\":\"$C\",\"result\":\"fail_test\"}")
  fi
  # Restore tree state before next iteration
  git checkout --quiet --force "$C" -- . 2>/dev/null || true
done

echo "[find_c_test_v2] no passing commit found in range $C_BASE..$C_FINAL" | tee -a "$LOG"
printf '{"c_test":null,"c_base":"%s","c_final":"%s","added_or_modified_tests":%s,"deleted_tests":%s,"commits_scanned":%s}\n' \
  "$C_BASE" "$C_FINAL" \
  "$(printf '%s\n' $ADDED_OR_MODIFIED | jq -R . | jq -s .)" \
  "$(printf '%s\n' $DELETED | jq -R . | jq -s .)" \
  "[$(IFS=,; echo "${RESULTS[*]}")]" > "$SUMMARY"
exit 1
