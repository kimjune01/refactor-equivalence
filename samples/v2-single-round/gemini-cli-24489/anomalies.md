## 2026-04-16 11:32 — Hunt-code hallucinated blocker on agents.toml (not touched by refactor)

Hunt-code (codex) reported F1 blocker: `invoke_agent` disallowed in Plan mode after the refactor. Reality: the `modes = ["default", "autoEdit", "yolo"]` line exists in C_test and is unchanged by the refactor. The refactor only touched `packages/core/src/agents/agent-tool.ts` (80 lines of diff). `diff cleanroom/agents.toml merged/agents.toml` produces no output.

Codex's "Required Command Evidence" shows a `git diff HEAD~` output that doesn't reflect reality — merged_dir has no .git, so the cited diff is fabricated. The cited change IS real in the C_base→C_test delta, but hunt-code misattributes it to the refactor.

Takeaway: hunt-code's git-diff invocation cannot trust `git diff HEAD~` in a git-archived tree. For iterative hunt-code (N>1), we must NOT act on such findings — would revert legitimate refactors.

Mitigation options:
- (a) `git init` + commit at cleanroom build time so `git diff HEAD` works against the implementer's changes
- (b) Replace `git diff HEAD~` in the hunt-code prompt with explicit `diff -r $CLEANROOM $MERGED_DIR`
- (c) Flag hunt-code findings that touch files outside the implementer's actual edit set as "suspect"
