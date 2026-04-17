# v2 registered tooling — locked before first PR

Per PREREG_V2.md §Registered repo tooling: "If a repo's CI reveals a narrower gating shard, the narrower shard may be used only if recorded before that repo's first sampled PR is run."

This file is the single source of truth. Locked 2026-04-16 before v2 forge pipeline runs on any PR.

## google-gemini/gemini-cli (primary)

- **Node**: ≥22 (verified Node v22.21.1)
- **Install**: `npm ci --prefer-offline --no-audit --no-fund`
- **Build**: `npm run build`
- **Test command (correctness gate)**:
  ```bash
  npm run test --workspaces --if-present -- --exclude '**/sandboxManager.integration.test.ts'
  ```
- **Complexity tool**: `scripts/measure_complexity.mjs` (AST walker, @typescript-eslint/typescript-estree)
- **Repo-specific exclusion globs** (appended to cross-repo list): `bundle/**`

### Excluded test — rationale

- `sandboxManager.integration.test.ts`: requires OS-level sandbox enforcement (macOS Seatbelt / Linux landlock). Fails on dev Macs because the sandbox binary cannot actually block file writes. Inherited from v1 per-repo config (prompts/repos/gemini-cli.md). Excludes `SandboxManager Integration > Cross-platform Sandbox Behavior > File System Access > allows dynamic expansion of permissions after a failure` and siblings.

### Feasibility check (C1) scripts

- `scripts/feasibility_v2.sh` — runs npm ci + build + registered test command at C_final

## cli/cli (secondary, Go) — PENDING

To be locked before first cli/cli PR runs (after gemini-cli dev set converges).

## astral-sh/ruff (secondary, Rust) — PENDING

To be locked before first ruff PR runs.
