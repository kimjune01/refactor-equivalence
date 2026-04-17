# Metaprompt: Generate a repo-specific v2 spec template

Given a repository, produce a **short idiomatic-notes spec template** that the v2 forge pipeline uses as per-repo context. Short, not exhaustive. Per PREREG_V2.md V4 (locked, simplified): each repo's spec template is committed to the trail before its first PR runs.

## Input

- Repo name and URL
- Language and build system
- Registered test command (locked in `samples/v2/registered-tooling.md`)
- Registered build command
- Registered complexity tool
- Dev-set diffs for the repo (C_test → C_final deltas). **These are used only during the metaprompt run; the pipeline never sees them at trial-time.**
- Repo conventions extracted mechanically: linter config, formatter config, CI checks.

## Output

A per-repo v2 spec template at `prompts/repos/<repo>.md` containing:

1. **Language and tooling summary** (1–2 lines: "TypeScript monorepo, Node 22, vitest, npm workspaces")
2. **Registered commands** (install/build/test, copy-paste from `samples/v2/registered-tooling.md`)
3. **Short idiom notes** (5–10 bullets max):
   - Language-standard idioms to prefer (e.g., "TypeScript: prefer `readonly` for immutable fields; no `any` unless commented; keep JSX components free of `useEffect` when derivable")
   - Repo-standard idioms visible in C_test (e.g., "uses `CoreEvents.emit` for telemetry; extract helpers into the nearest file of the feature area, not a shared `utils/`")
4. **Repo-specific excluded files / tests** (inherited from `samples/v2/registered-tooling.md`)
5. **Allowed edit set policy**: source files changed from C_base to C_test, post-exclusion. Mechanically enforced after generation.

Keep the whole document under ~60 lines. It is a grounding note, not a style guide.

## Hard rules on content

- Do NOT reference specific PRs, reviewers, or git history.
- Do NOT introduce NEW patterns that aren't already visible in the dev-set diffs.
- Renaming for consistency with existing codebase conventions is fine; net new abstractions are not.
- Do NOT reference `C_random` (dropped in v2).
- Simpler is better: if an idiom note doesn't affect at least one likely claim, cut it.

## v2 changes from v1

- Shorter (v1 was ~40-line spec; v2 targets ~30 lines + short idiom notes).
- No longer defines "the refactoring goal" broadly — the per-trial goal anchor (PR title + body + linked issue) carries that job now.
- No `C_random` / random-control mention.
- Uncertainty rule kept: "if unsure whether a change simplifies, don't make it."
