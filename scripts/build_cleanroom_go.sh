#!/usr/bin/env bash
# Build a clean-room workspace for a Go PR at C_test.
#
# Usage:
#   SRC_REPO=/tmp/refactor-eq-workdir/cli \
#   C_TEST=<sha> \
#   WORKSPACE=/tmp/refactor-eq-workdir/cleanroom-cli/12567 \
#   ./scripts/build_cleanroom_go.sh
set -euo pipefail

: "${SRC_REPO:?}"
: "${C_TEST:?}"
: "${WORKSPACE:?}"

# Use mv-to-/tmp rather than rm -rf per project safety rules
if [ -d "$WORKSPACE" ]; then
  mv "$WORKSPACE" "/tmp/_cleanroom_trash_$(date +%s)"
fi
mkdir -p "$WORKSPACE"

cd "$SRC_REPO"
git archive --format=tar "$C_TEST" | tar -x -C "$WORKSPACE"

# Resolve Go module cache (shared across cleanrooms via $GOPATH/pkg/mod).
# go mod download writes to $GOMODCACHE which defaults to $GOPATH/pkg/mod.
cd "$WORKSPACE"
go mod download 2>&1 | tail -3 || true

echo "Clean-room at $WORKSPACE"
echo "Files: $(find "$WORKSPACE" -type f -not -path '*/vendor/*' | wc -l)"
