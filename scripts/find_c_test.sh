#!/usr/bin/env bash
# Find C_test: earliest commit in PR branch where merge-time tests pass.
#
# Strategy (per PREREG.md):
#   1. Extract test files from C_final.
#   2. Traverse PR commits in chronological order from C_base.
#   3. At each commit, overlay C_final test files onto working tree.
#   4. Run the locked test command.
#   5. Record pass/fail. Earliest passing = C_test.
#
# Usage:
#   REPO=/tmp/refactor-eq-workdir/gemini-cli \
#   C_BASE=7d1848d578b644c274fcd1f6d03685aafc19e8ed \
#   C_FINAL=e169c700911f5d2161b3fc94006f911355aeca1a \
#   TEST_FILES="packages/core/src/agents/local-executor.test.ts packages/core/src/tools/complete-task.test.ts" \
#   TEST_CMD="npm run test --workspace @google/gemini-cli-core" \
#   OUT_DIR=/tmp/refactor-eq-workdir/c_test-24437 \
#   ./scripts/find_c_test.sh
set -euo pipefail

: "${REPO:?}"
: "${C_BASE:?}"
: "${C_FINAL:?}"
: "${TEST_FILES:?}"
: "${TEST_CMD:?}"
: "${OUT_DIR:?}"
: "${PRE_CMD:=true}"

mkdir -p "$OUT_DIR"
LOG="$OUT_DIR/find_c_test.log"
: > "$LOG"

cd "$REPO"
git checkout --quiet "$C_FINAL"

# Stash the test files from C_final
STAGE=$(mktemp -d)
for f in $TEST_FILES; do
  mkdir -p "$STAGE/$(dirname "$f")"
  cp "$f" "$STAGE/$f"
done
echo "Staged test files from $C_FINAL into $STAGE" | tee -a "$LOG"

# Walk PR commits in chronological order (oldest → newest)
COMMITS=$(git log --reverse --format=%H "$C_BASE..$C_FINAL")

for C in $COMMITS; do
  echo "=== commit $C ===" | tee -a "$LOG"
  git checkout --quiet "$C"
  # Overlay C_final tests
  for f in $TEST_FILES; do
    mkdir -p "$(dirname "$f")"
    cp "$STAGE/$f" "$f"
  done
  # Build, then run tests
  if (cd "$REPO" && eval "$PRE_CMD" && eval "$TEST_CMD") >>"$LOG" 2>&1; then
    echo "PASS $C" | tee -a "$LOG"
    echo "$C" > "$OUT_DIR/c_test_commit.txt"
    echo "Earliest passing commit: $C"
    # Restore working tree before exit
    git checkout --quiet -- .
    exit 0
  else
    echo "FAIL $C" | tee -a "$LOG"
  fi
  git checkout --quiet -- .
done

echo "No passing commit found in range $C_BASE..$C_FINAL" | tee -a "$LOG"
exit 1
