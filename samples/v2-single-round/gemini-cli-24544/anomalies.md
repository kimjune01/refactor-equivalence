## 2026-04-16 11:55 — Flaky integration test caused hard no-op

Single test failure: `shellBackgroundTools.integration.test.ts > Background Tools Integration > should support interaction cycle: start background -> list -> read logs`. 1 of 6716 tests failed.

Opus (winner) only touched: packages/core/src/commands/memory.ts, packages/cli/src/ui/components/SkillInboxDialog.tsx, packages/cli/src/ui/commands/memoryCommand.ts. None of these are related to shell background tools.

Test is a background-process integration test — known-flaky pattern (timing-sensitive). Our registered test command doesn't currently exclude it. v3 question: should we register a broader set of known-flaky integration tests for exclusion, or run integration tests N times for convergence?

Manual complexity gate re-ran post-pipeline: PASS, Δ=-0.0281 on 716 scoped functions. Complexity gate would have passed had the flaky test not blocked.
