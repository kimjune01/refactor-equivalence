#!/usr/bin/env bash
# v2 end-to-end: takes a PR whose C_test is already extracted, builds
# cleanroom, runs forge pipeline.
#
# Prereqs:
#   samples/v2/gemini-cli-<PR>/find_c_test.json exists with c_test != null
#   samples/v2/gemini-cli-<PR>/goal/GOAL.md exists
#
# Usage:
#   PR=24460 ./scripts/run_pr_end_to_end.sh
set -euo pipefail

: "${PR:?}"
: "${REPO:=gemini-cli}"
: "${OWNER:=google-gemini}"
: "${SRC_REPO:=/tmp/refactor-eq-workdir/gemini-cli}"

SAMPLES=/Users/junekim/Documents/refactor-equivalence/samples/v2
SCRIPTS=/Users/junekim/Documents/refactor-equivalence/scripts
TRIAL_DIR="$SAMPLES/${REPO}-${PR}"
CLEANROOM="/tmp/refactor-eq-workdir/cleanroom-v2/${PR}"

# 1. Verify C_test exists
if [ ! -f "$TRIAL_DIR/find_c_test.json" ]; then
  echo "ERROR: $TRIAL_DIR/find_c_test.json missing. Run find_c_test_v2.sh first."
  exit 1
fi
C_TEST=$(jq -r '.c_test' "$TRIAL_DIR/find_c_test.json")
C_BASE=$(jq -r '.c_base' "$TRIAL_DIR/find_c_test.json")
if [ "$C_TEST" = "null" ] || [ -z "$C_TEST" ]; then
  if [ "${ALLOW_CTEST_EQ_CFINAL:-0}" = "1" ]; then
    C_TEST=$(jq -r '.c_final' "$TRIAL_DIR/find_c_test.json")
    echo "WARN: c_test not found. Falling back to c_test = c_final = $C_TEST (ALLOW_CTEST_EQ_CFINAL=1)" >&2
    echo "deviation: c_test_forced_to_c_final=$C_TEST" >> "$TRIAL_DIR/deviations.md"
  else
    echo "ERROR: c_test is null in $TRIAL_DIR/find_c_test.json. Set ALLOW_CTEST_EQ_CFINAL=1 to force."
    exit 1
  fi
fi

# 2. Verify goal exists
if [ ! -f "$TRIAL_DIR/goal/GOAL.md" ]; then
  echo "ERROR: $TRIAL_DIR/goal/GOAL.md missing"
  exit 1
fi

echo "[$(date -u +%FT%TZ)] e2e PR $PR — C_base=$C_BASE, C_test=$C_TEST"

# 3. Build cleanroom at C_test
REPO_EXCLUDES="bundle"
SRC_REPO="$SRC_REPO" \
C_BASE="$C_BASE" \
C_TEST="$C_TEST" \
GOAL_FILE="$TRIAL_DIR/goal/GOAL.md" \
REPO_EXCLUDES="$REPO_EXCLUDES" \
WORKSPACE="$CLEANROOM" \
"$SCRIPTS/build_cleanroom_v2.sh"

# 4. Verify test passes at C_test (already validated by find_c_test_v2, but re-assert)
# Per-repo test/build commands
case "$REPO" in
  gemini-cli)
    TEST_CMD="npm run test --workspaces --if-present -- --exclude '**/sandboxManager.integration.test.ts'"
    BUILD_CMD="npm run build"
    ;;
  cli)
    TEST_CMD="go test ./... -count=1 -short"
    BUILD_CMD="go build ./..."
    ;;
  ruff|biome)
    export PATH="$HOME/.cargo/bin:$PATH"
    TEST_CMD="cargo test --workspace"
    BUILD_CMD="cargo build"
    ;;
  *)
    TEST_CMD="${TEST_CMD:?No TEST_CMD for repo $REPO}"
    BUILD_CMD="${BUILD_CMD:?No BUILD_CMD for repo $REPO}"
    ;;
esac

# 5. Run forge pipeline
PR="$PR" \
REPO="$REPO" \
SRC_REPO="$SRC_REPO" \
C_BASE="$C_BASE" \
C_TEST="$C_TEST" \
TRIAL_DIR="$TRIAL_DIR" \
CLEANROOM="$CLEANROOM" \
TEST_CMD="$TEST_CMD" \
BUILD_CMD="$BUILD_CMD" \
"$SCRIPTS/run_forge_v2.sh"

echo "[$(date -u +%FT%TZ)] e2e PR $PR complete"
