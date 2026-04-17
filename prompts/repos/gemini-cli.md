# Per-repo spec template — google-gemini/gemini-cli (v2)

Locked 2026-04-16 before first v2 trial. See `samples/v2/registered-tooling.md` for the authoritative commands.

## Language and tooling

- TypeScript monorepo, npm workspaces, Node ≥22 (verified 22.21.1), vitest.
- Primary package: `packages/core`. UI: `packages/cli`. Additional: `packages/sdk`, `packages/vscode-ide-companion`.
- Complexity tool: `scripts/measure_complexity.mjs` (AST walker, `@typescript-eslint/typescript-estree`). Metric: mean cognitive across scoped functions.

## Registered commands

```bash
# install
npm ci --prefer-offline --no-audit --no-fund
# build (required before tests: core is self-importing)
npm run build
# test (registered correctness gate)
npm run test --workspaces --if-present -- --exclude '**/sandboxManager.integration.test.ts'
```

## Short idiom notes

- Prefer `readonly` on immutable class fields and interface properties.
- Avoid `any` unless an inline `// eslint-disable-next-line @typescript-eslint/no-explicit-any` with reason is present.
- Telemetry: emit via `CoreEvents` / `coreEvents.emitFeedback` — don't log-then-emit duplicates.
- Keep tool-specific helpers colocated with the tool; a catch-all `utils/` is an anti-pattern here.
- React components in `packages/cli/src/ui`: use `BaseSelectionList` for selection UIs; don't reinvent keyboard handlers.
- Error objects: include a stable code or category; reviewers flag opaque `throw new Error(...)` calls lacking context.
- Async handlers: always wire `AbortSignal` through when the call chain already supports it; reviewers push back on orphan timers/listeners.
- Prefer `.ts` over `.tsx` unless JSX is present in the file.

## Repo-specific exclusions

Appended to cross-repo exclusion globs (applied at post-exclusion size computation + allowed-edit-set determination):

- `bundle/**` — build output
- `**/*.snap` — vitest snapshots

## Excluded tests (registered)

- `sandboxManager.integration.test.ts` — requires OS-level sandbox enforcement (macOS Seatbelt / Linux landlock). Fails on clean dev Macs because the sandbox binary cannot actually block file writes. Excluded from the registered test command.

## Allowed edit set policy

Per PREREG_V2.md §4d: LLM may edit any source file changed from `C_base` to `C_test`. It may NOT edit tests. Enforced mechanically after generation.

## Uncertainty rule

If unsure whether a change simplifies, don't make it. Claims that shuffle code without reducing concept count are wrong-direction.
