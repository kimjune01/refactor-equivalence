#!/usr/bin/env bash
# find_c_test variant for Python projects (specifically fastapi-style layout).
# Overlays both test files and docs_src examples from C_final, since fastapi
# tests import from docs_src.
set -euo pipefail

: "${REPO:?}"
: "${C_BASE:?}"
: "${C_FINAL:?}"
: "${OVERLAY_PATHS:?}"    # space-separated globs like 'tests/*.py docs_src/**/*.py'
: "${TEST_CMD:?}"
: "${OUT_DIR:?}"
: "${PRE_CMD:=true}"

mkdir -p "$OUT_DIR"
LOG="$OUT_DIR/find_c_test.log"
: > "$LOG"

cd "$REPO"

# Collect overlay files list
STAGE=$(mktemp -d)
git checkout --quiet "$C_FINAL"
OVERLAY_FILES=()
for pattern in $OVERLAY_PATHS; do
  for f in $(git diff --name-only "$C_BASE" "$C_FINAL" -- "$pattern"); do
    OVERLAY_FILES+=("$f")
    if [ -f "$f" ]; then
      mkdir -p "$STAGE/$(dirname "$f")"
      cp "$f" "$STAGE/$f"
    fi
  done
done
echo "Staged ${#OVERLAY_FILES[@]} overlay files from $C_FINAL" | tee -a "$LOG"

COMMITS=$(git log --reverse --format=%H "$C_BASE..$C_FINAL")
TRASH_ROOT=$(mktemp -d)

clean_untracked_overlays() {
  for f in "${OVERLAY_FILES[@]}"; do
    if [ -f "$f" ]; then
      if ! git ls-files --error-unmatch "$f" >/dev/null 2>&1; then
        local d="$TRASH_ROOT/$(date +%s%N)-$RANDOM"
        mkdir -p "$(dirname "$d/$f")"
        mv "$f" "$d/$(basename "$f")" 2>/dev/null || true
      fi
    fi
  done
}

for C in $COMMITS; do
  echo "=== commit $C ===" | tee -a "$LOG"
  # First reset tracked files
  git checkout --quiet -- . 2>/dev/null || true
  # Then clean any untracked overlay files still lingering from previous iter
  clean_untracked_overlays
  # Now safe to switch
  git checkout --quiet "$C"
  # Clean again post-checkout (overlay files that existed at C_FINAL may now be untracked)
  clean_untracked_overlays
  # Overlay C_final versions
  for f in "${OVERLAY_FILES[@]}"; do
    if [ -f "$STAGE/$f" ]; then
      mkdir -p "$(dirname "$f")"
      cp "$STAGE/$f" "$f"
    fi
  done
  if (cd "$REPO" && eval "$PRE_CMD" && eval "$TEST_CMD") >>"$LOG" 2>&1; then
    echo "PASS $C" | tee -a "$LOG"
    echo "$C" > "$OUT_DIR/c_test_commit.txt"
    git checkout --quiet -- .
    # Clean up untracked overlay files
    for f in "${OVERLAY_FILES[@]}"; do
      if [ -f "$f" ] && ! git ls-files --error-unmatch "$f" >/dev/null 2>&1; then
        TRASH=$(mktemp -d); mv "$f" "$TRASH/" 2>/dev/null || true
      fi
    done
    echo "Earliest passing: $C"
    exit 0
  else
    echo "FAIL $C" | tee -a "$LOG"
  fi
  git checkout --quiet -- .
done

echo "No passing commit found in range $C_BASE..$C_FINAL" | tee -a "$LOG"
exit 1
