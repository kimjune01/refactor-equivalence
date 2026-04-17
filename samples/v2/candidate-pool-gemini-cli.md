# gemini-cli candidate pool (v2)

Source: `samples/candidates-gemini-cli.json` (89 PRs merged 2026-04-01 through 2026-04-15, ≥ training cutoff 2025-10-01).

## Top 15 by raw size — post-exclusion computed

Exclusion globs per PREREG_V2.md + `bundle/**` (gemini-cli repo-specific).
`C_base` = `baseRefOid`; `C_final` = `refs/pull/<N>/head` (not `mergeCommit.oid` — that's the squash on main, inflated).
Range: 500 ≤ post_sum ≤ 5000.

| PR | post_add | post_del | post_sum | post_files | in_range | title |
|----|----------|----------|----------|------------|----------|-------|
| 24834 | 991 | 2929 | 3920 | 89 | ✓ | fix(core): resolve windows symlink bypass and stabilize sandbox integr |
| 24951 | 1154 | 1104 | 2258 | 34 | ✓ | feat(test-utils): add CPU performance integration test harness |
| 24876 | 1132 | 515 | 1647 | 40 | ✓ | feat(test-utils): add memory usage integration test harness |
| 24544 | 777 | 827 | 1604 | 33 | ✓ | feat(memory): add /memory inbox command for reviewing extracted skills |
| 24483 | 674 | 100 | 774 | 18 | ✓ | feat(core): Land ContextCompressionService (v1-dev) |
| 24460 | 624 | 50 | 674 | 13 | ✓ | fix(core): enhance sandbox usability and fix build error |
| 24489 | 470 | 176 | 646 | 28 | ✓ | feat(core): refactor subagent tool to unified invoke_subagent tool (v1-dev) |
| 24512 | 473 | 141 | 614 | 26 | ✓ | feat(ui): enable "TerminalBuffer" mode to solve flicker |
| 24437 | 284 | 193 | 477 | 6 | ✗ | fix(core): complete_task tool calls recorded in chat history (v1-dev; 500 floor miss) |
| 24623 | 259 | 175 | 434 | 12 | ✗ | split context (v1-dev; 500 floor miss) |
| 25053 | 0 | 343 | 343 | 2 | ✗ | refactor(core): remove legacy subagent wrapping tools |
| 25101 | 144 | 111 | 255 | 37 | ✗ | refactor(core): consolidate execute() into ExecuteOptions (v1-dev; 500 floor miss) |
| 25307 | 76 | 48 | 124 | 3 | ✗ | test(core): improve sandbox integration test coverage |
| 24372 | 48 | 73 | 121 | 4 | ✗ | ink 6.6.3 |
| 24381 | 1 | 1 | 2 | 1 | ✗ | fix(ui): removed additional vertical padding for tables |

## In-range (8 candidates, sorted by size desc)

24834, 24951, 24876, 24544, 24483, 24460, 24489, 24512

## Dev-set selection

Picked 3 across change-type axis and size axis:

- **24544** — feat/memory, 1604 lines, 33 files. NEW (not v1-dev). Largest in dev.
- **24460** — fix/core, 674 lines, 13 files. NEW. Smallest in dev.
- **24489** — feat/core refactor, 646 lines, 28 files. v1-dev overlap → direct v1→v2 pipeline comparison.

Deviation logged: v1-dev overlap on 24489 is intentional (infra pre-validated, A/B signal for pipeline improvements), anchoring bias from reading v1 artifacts is acknowledged.

## Test-set (frozen separately — NOT locked yet)

Test set will be drawn from the remaining in-range pool {24834, 24951, 24876, 24483, 24512} + additional candidates from the full 89-pool (not just top 15) after post-exclusion computed. Test-set lock happens AFTER dev-set prompt iteration converges (per prereg §Dev/test separation).
