# Secondary repo: cli/cli (Go) — 3-PR batch

Locked 2026-04-15. Prereg secondary-repo allocation: 3 PRs, expandable to 10.

| PR | Title | LOC (+/-) | Files | Commits | Reviews | Merged |
|----|-------|-----------|-------|---------|---------|--------|
| [12567](https://github.com/cli/cli/pull/12567) | `gh pr edit`: Add Copilot as reviewer with search, performance, a11y | 965/85 | 9 | 14 | 12 | 2026-02-06 |
| [12695](https://github.com/cli/cli/pull/12695) | feat(workflow run): retrieve workflow dispatch run details | 580/54 | 5 | 12 | 19 | 2026-02-17 |
| [12846](https://github.com/cli/cli/pull/12846) | feat(repo): add --squash-merge-commit-message flag to gh repo edit | 281/21 | 2 | 3 | 17 | 2026-03-10 |

## Diversity

- All APPROVED, post-cutoff, multiple reviews, multiple commits (substantive post-tests-pass revision likely)
- Size range: 302 → 634 → 1050 (small → medium → large)
- Subsystem coverage: `pr` (review workflow), `workflow run` (CI data fetching), `repo` (settings mutation)
- All feature additions. Pilot intentionally omits Go refactor-type PRs from this initial batch; if any subsystem reveals strong or anomalous patterns, expansion to 10 will mix refactor + fix cases.

## Remaining pool

All other eligible candidates in the 2025-09-01+ merged pool (reserved for any future expansion within cli/cli).
