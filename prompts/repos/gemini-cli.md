# Per-repo pilot config — google-gemini/gemini-cli

Locked 2026-04-15 during pilot feasibility work.

## Language and tooling

- TypeScript monorepo (npm workspaces)
- Node ≥20 (verified with Node 22)
- Test runner: vitest
- Primary target package: `packages/core`

## Test command (correctness gate)

All pilot PRs in `samples/dev/PILOT.md` touch `packages/core`. The locked test command for a PR touching only core is:

```bash
cd packages/core
npx vitest run --exclude '**/sandboxManager.integration.test.ts'
```

### Pre-test build

The core workspace is self-importing (several tests resolve `@google/gemini-cli-core`), so the package must be built before tests:

```bash
npm run build --workspace @google/gemini-cli-core
```

### Excluded tests

- `sandboxManager.integration.test.ts` — requires OS-level sandbox enforcement (seatbelt/landlock). Fails on clean developer Macs where the sandbox binary cannot actually block file writes. Exclusion does not affect the PRs in the pilot set (none touch sandboxManager).

Document any further exclusions here with a pointer to the failure mode.

## PR-touched files policy

The LLM may edit any source file changed from `C_base` to `C_test`. Mechanically enforced by diffing file paths after generation.

## Snapshot commits for pilot PRs

Populated as extraction progresses.

| PR | C_base | C_test | C_final |
|----|--------|--------|---------|
| 24437 | `7d1848d` | `ffd11f5f` | `e169c700` |
| 24483 | tbd | tbd | tbd |
| 24489 | tbd | tbd | tbd |
| 24623 | tbd | tbd | tbd |
| 25101 | tbd | tbd | tbd |
