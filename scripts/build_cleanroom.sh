#!/usr/bin/env bash
# Build a clean-room workspace for a pilot PR at C_test.
#
# Per PREREG.md §Procedure.2: exclude .git, PR metadata, reviewer comments,
# subsequent commits. Disable network at generation time (caller's responsibility).
# Share node_modules from the source clone — only source files differ between trials.
#
# Usage:
#   SRC_REPO=/tmp/refactor-eq-workdir/gemini-cli \
#   C_TEST=ffd11f5f1268b90351b3375977a243e457251f6e \
#   WORKSPACE=/tmp/refactor-eq-workdir/cleanroom/24437 \
#   ./scripts/build_cleanroom.sh
set -euo pipefail

: "${SRC_REPO:?}"
: "${C_TEST:?}"
: "${WORKSPACE:?}"

rm -rf "$WORKSPACE"
mkdir -p "$WORKSPACE"

cd "$SRC_REPO"

# Snapshot source tree at C_test. Use git archive to strip .git metadata and
# uncommitted files cleanly.
git archive --format=tar "$C_TEST" | tar -x -C "$WORKSPACE"

# Resolve deps INSIDE the clean-room. npm workspaces creates relative symlinks
# (node_modules/@google/* -> ../../packages/*); if node_modules were symlinked
# from the source clone, those relative paths would resolve to the source
# clone's packages, breaking isolation. Running `npm ci` here is ~20s warm.
cd "$WORKSPACE"
npm ci --prefer-offline --no-audit --no-fund >/dev/null 2>&1

echo "Clean-room at $WORKSPACE"
echo "Files: $(find "$WORKSPACE" -type f -not -path '*/node_modules/*' | wc -l)"
