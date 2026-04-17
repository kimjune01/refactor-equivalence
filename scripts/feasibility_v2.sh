#!/usr/bin/env bash
# v2 pre-selection feasibility check at C_final.
#
# Per PREREG_V2.md C1: test command passes at C_final; source-only
# C_test→C_final diff is non-empty; ≥1 source file after exclusions.
#
# This script only checks the FIRST criterion (test command passes at C_final).
# The other two are checked by post_exclusion_size.sh + find_c_test.sh outputs.
#
# Usage:
#   WORKDIR=/tmp/refactor-eq-workdir/v2-wt-24544 \
#   TEST_CMD="npm run test --workspaces --if-present" \
#   BUILD_CMD="npm run build" \
#   LOG_DIR=/Users/junekim/Documents/refactor-equivalence/samples/v2/gemini-cli-24544/gates \
#   ./scripts/feasibility_v2.sh
set -euo pipefail

: "${WORKDIR:?}"
: "${TEST_CMD:?}"
: "${BUILD_CMD:=npm run build}"
: "${LOG_DIR:?}"

mkdir -p "$LOG_DIR"
cd "$WORKDIR"

START=$(date +%s)

echo "[$(date -u +%FT%TZ)] feasibility starting on $WORKDIR" | tee "$LOG_DIR/feasibility.log"

# Step 1: npm ci
echo "[$(date -u +%FT%TZ)] npm ci..." | tee -a "$LOG_DIR/feasibility.log"
if npm ci --prefer-offline --no-audit --no-fund >"$LOG_DIR/npm-ci.log" 2>&1; then
  echo "[$(date -u +%FT%TZ)] npm ci OK ($(($(date +%s)-START))s)" | tee -a "$LOG_DIR/feasibility.log"
else
  echo "[$(date -u +%FT%TZ)] npm ci FAILED" | tee -a "$LOG_DIR/feasibility.log"
  echo FEASIBILITY=FAIL_NPM_CI
  exit 1
fi

# Step 2: build
echo "[$(date -u +%FT%TZ)] $BUILD_CMD ..." | tee -a "$LOG_DIR/feasibility.log"
if eval "$BUILD_CMD" >"$LOG_DIR/build.log" 2>&1; then
  echo "[$(date -u +%FT%TZ)] build OK ($(($(date +%s)-START))s)" | tee -a "$LOG_DIR/feasibility.log"
else
  echo "[$(date -u +%FT%TZ)] build FAILED" | tee -a "$LOG_DIR/feasibility.log"
  echo FEASIBILITY=FAIL_BUILD
  exit 1
fi

# Step 3: test
echo "[$(date -u +%FT%TZ)] $TEST_CMD ..." | tee -a "$LOG_DIR/feasibility.log"
if eval "$TEST_CMD" >"$LOG_DIR/test.log" 2>&1; then
  echo "[$(date -u +%FT%TZ)] test OK ($(($(date +%s)-START))s)" | tee -a "$LOG_DIR/feasibility.log"
  echo FEASIBILITY=PASS
  echo "FEASIBILITY=PASS elapsed=$(($(date +%s)-START))s" >> "$LOG_DIR/feasibility.log"
else
  echo "[$(date -u +%FT%TZ)] test FAILED ($(($(date +%s)-START))s)" | tee -a "$LOG_DIR/feasibility.log"
  echo FEASIBILITY=FAIL_TEST
  exit 1
fi
