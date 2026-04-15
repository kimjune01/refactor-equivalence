#!/bin/bash
# Extract C_test and C_merge snapshots for a given PR
# Usage: ./extract_snapshots.sh <repo_path> <pr_number> <output_dir>

set -euo pipefail

REPO="$1"
PR_NUMBER="$2"
OUTPUT_DIR="$3"

mkdir -p "$OUTPUT_DIR"/{c_test,c_merge,c_llm}

cd "$REPO"

# Get merge commit for the PR
MERGE_COMMIT=$(gh pr view "$PR_NUMBER" --json mergeCommit --jq '.mergeCommit.oid')
if [ -z "$MERGE_COMMIT" ]; then
  echo "PR #$PR_NUMBER not merged or merge commit not found"
  exit 1
fi

echo "Merge commit: $MERGE_COMMIT"

# Get all commits in the PR
PR_COMMITS=$(gh pr view "$PR_NUMBER" --json commits --jq '.commits[].oid')
echo "PR commits:"
echo "$PR_COMMITS"

# Get the files changed in this PR
CHANGED_FILES=$(gh pr diff "$PR_NUMBER" --name-only)
echo "Changed files:"
echo "$CHANGED_FILES"

# For each commit in the PR, check if tests pass
# This is repo-specific — override TEST_COMMAND for different repos
TEST_COMMAND="${TEST_COMMAND:-npm test}"

echo ""
echo "=== Finding C_test (first commit where tests pass) ==="
echo "Manual step: for each commit below, checkout and run: $TEST_COMMAND"
echo "Record the first passing commit in $OUTPUT_DIR/c_test_commit.txt"
echo ""

for COMMIT in $PR_COMMITS; do
  echo "  $COMMIT  $(git log --oneline -1 "$COMMIT" 2>/dev/null || echo '(not fetched)')"
done

# Export merge snapshot
echo ""
echo "=== Exporting C_merge snapshot ==="
git checkout "$MERGE_COMMIT" -- $CHANGED_FILES 2>/dev/null
for f in $CHANGED_FILES; do
  mkdir -p "$OUTPUT_DIR/c_merge/$(dirname "$f")"
  cp "$f" "$OUTPUT_DIR/c_merge/$f" 2>/dev/null || echo "  skipped (deleted): $f"
done
git checkout HEAD -- $CHANGED_FILES 2>/dev/null

echo ""
echo "Next steps:"
echo "  1. Find C_test commit and record in $OUTPUT_DIR/c_test_commit.txt"
echo "  2. Export C_test snapshot the same way"
echo "  3. Run the LLM refactoring prompt on C_test"
echo "  4. Run tests on C_llm to verify correctness"
echo "  5. Run measure.sh to compute metrics"
