#!/usr/bin/env bash
# Compute post-exclusion source-line count for a PR (C_base to C_final).
#
# Prints: additions  deletions  sum  files   (tab-separated)
#
# Usage:
#   REPO=/tmp/refactor-eq-workdir/gemini-cli \
#   C_BASE=<sha> \
#   C_FINAL=<sha> \
#   REPO_EXCLUDES="bundle" \
#   ./scripts/post_exclusion_size.sh
#
# REPO_EXCLUDES is a space-separated list of repo-specific exclude dir globs
# (appended to the registered cross-repo list).
set -euo pipefail

: "${REPO:?}"
: "${C_BASE:?}"
: "${C_FINAL:?}"
: "${REPO_EXCLUDES:=}"

# Registered exclusion globs (PREREG_V2.md)
EXCLUDES=(
  # tests
  ':(exclude)**/*_test.go'
  ':(exclude)**/*.test.ts'
  ':(exclude)**/*.test.tsx'
  ':(exclude)tests/**'
  ':(exclude)**/test_*.py'
  ':(exclude)**/*_test.py'
  ':(exclude)**/__snapshots__/**'
  ':(exclude)**/*.snap'
  # docs
  ':(exclude)docs/**'
  ':(exclude)**/*.md'
  ':(exclude)**/README*'
  # schemas
  ':(exclude)schemas/**'
  ':(exclude)**/*.schema.json'
  # lockfiles
  ':(exclude)**/package-lock.json'
  ':(exclude)**/yarn.lock'
  ':(exclude)**/Cargo.lock'
  ':(exclude)**/uv.lock'
  ':(exclude)**/poetry.lock'
  ':(exclude)**/go.sum'
  # generated
  ':(exclude)**/dist/**'
  ':(exclude)**/build/**'
  ':(exclude)**/target/**'
  ':(exclude)**/__pycache__/**'
  ':(exclude)**/.next/**'
  ':(exclude)**/_generated.go'
  ':(exclude)**/*.pb.go'
  # vendored
  ':(exclude)**/vendor/**'
  ':(exclude)**/third_party/**'
  ':(exclude)**/node_modules/**'
)

# Append repo-specific excludes
for d in $REPO_EXCLUDES; do
  EXCLUDES+=(":(exclude)${d}/**")
done

cd "$REPO"

# git diff --numstat <c_base> <c_final> -- . <excludes>
OUTPUT=$(git diff --numstat "$C_BASE" "$C_FINAL" -- . "${EXCLUDES[@]}" 2>/dev/null || true)

if [ -z "$OUTPUT" ]; then
  printf "0\t0\t0\t0\n"
  exit 0
fi

ADD=$(echo "$OUTPUT" | awk '$1 != "-" { a += $1 } END { print a+0 }')
DEL=$(echo "$OUTPUT" | awk '$2 != "-" { d += $2 } END { print d+0 }')
FILES=$(echo "$OUTPUT" | wc -l | tr -d ' ')
SUM=$((ADD + DEL))

printf "%d\t%d\t%d\t%d\n" "$ADD" "$DEL" "$SUM" "$FILES"
