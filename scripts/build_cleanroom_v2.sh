#!/usr/bin/env bash
# Build a v2 clean-room workspace for a PR at C_test.
#
# Sets up:
#   $WORKSPACE/                   — source tree at C_test (no .git)
#   $WORKSPACE/node_modules       — from npm ci
#   $WORKSPACE/GOAL.md            — goal anchor (PR title + body + linked issues)
#   $WORKSPACE/FORGE_INPUT_DIFF.patch — C_base → C_test diff (source-only, post-exclusion)
#   $WORKSPACE/FORGE_ALLOWED_FILES.txt — source files changed C_base→C_test, post-exclusion
#
# Usage:
#   SRC_REPO=/tmp/refactor-eq-workdir/gemini-cli \
#   C_BASE=<sha> \
#   C_TEST=<sha> \
#   GOAL_FILE=/path/to/GOAL.md \
#   REPO_EXCLUDES="bundle" \
#   WORKSPACE=/tmp/refactor-eq-workdir/cleanroom-v2/24460 \
#   ./scripts/build_cleanroom_v2.sh
set -euo pipefail

: "${SRC_REPO:?}"
: "${C_BASE:?}"
: "${C_TEST:?}"
: "${GOAL_FILE:?}"
: "${WORKSPACE:?}"
: "${REPO_EXCLUDES:=}"

if [ -d "$WORKSPACE" ]; then
  mv "$WORKSPACE" "/tmp/cleanroom-backup-$(basename "$WORKSPACE")-$(date +%s)"
fi
mkdir -p "$WORKSPACE"

cd "$SRC_REPO"

# 1. Source tree at C_test (no .git)
git archive --format=tar "$C_TEST" | tar -x -C "$WORKSPACE"

# 2. Install deps (language-aware)
cd "$WORKSPACE"
if [ -f pnpm-lock.yaml ]; then
  pnpm install --frozen-lockfile --ignore-scripts >/dev/null 2>&1
elif [ -f package-lock.json ] || [ -f package.json ]; then
  npm ci --prefer-offline --no-audit --no-fund >/dev/null 2>&1
elif [ -f go.mod ]; then
  go mod download >/dev/null 2>&1
elif [ -f Cargo.toml ]; then
  true  # Rust deps resolved at build time
fi

# 3. Goal
cp "$GOAL_FILE" "$WORKSPACE/GOAL.md"

# 4. Input diff — C_base → C_test, source-only (post-exclusion globs applied)
cd "$SRC_REPO"

EXCLUDES=(
  ':(exclude)**/*_test.go' ':(exclude)**/*.test.ts' ':(exclude)**/*.test.tsx'
  ':(exclude)tests/**' ':(exclude)**/test_*.py' ':(exclude)**/*_test.py'
  ':(exclude)**/__snapshots__/**' ':(exclude)**/*.snap'
  ':(exclude)docs/**' ':(exclude)**/*.md' ':(exclude)**/README*'
  ':(exclude)schemas/**' ':(exclude)**/*.schema.json'
  ':(exclude)**/package-lock.json' ':(exclude)**/yarn.lock'
  ':(exclude)**/Cargo.lock' ':(exclude)**/uv.lock' ':(exclude)**/poetry.lock'
  ':(exclude)**/go.sum'
  ':(exclude)**/dist/**' ':(exclude)**/build/**' ':(exclude)**/target/**'
  ':(exclude)**/__pycache__/**' ':(exclude)**/.next/**'
  ':(exclude)**/_generated.go' ':(exclude)**/*.pb.go'
  ':(exclude)**/vendor/**' ':(exclude)**/third_party/**'
  ':(exclude)**/node_modules/**'
)
for d in $REPO_EXCLUDES; do
  EXCLUDES+=(":(exclude)${d}/**")
done

git diff "$C_BASE" "$C_TEST" -- . "${EXCLUDES[@]}" > "$WORKSPACE/FORGE_INPUT_DIFF.patch"

# 5. Allowed edit set (source files changed C_base→C_test, post-exclusion)
git diff --name-only "$C_BASE" "$C_TEST" -- . "${EXCLUDES[@]}" > "$WORKSPACE/FORGE_ALLOWED_FILES.txt"

# Summary
ALLOWED_COUNT=$(wc -l < "$WORKSPACE/FORGE_ALLOWED_FILES.txt" | tr -d ' ')
DIFF_LINES=$(wc -l < "$WORKSPACE/FORGE_INPUT_DIFF.patch" | tr -d ' ')
echo "cleanroom-v2 ready at $WORKSPACE"
echo "  source tree at $C_TEST"
echo "  allowed-edit files: $ALLOWED_COUNT"
echo "  input diff lines (incl headers): $DIFF_LINES"
