# Prompts

## Structure

- `forge-v2/` — v2 pipeline phase prompts (volley, hunt-spec, reconcile, implement, hunt-code, reviewer-loop). ACTIVE.
- `forge-pilot/` — v1 pilot pipeline prompts (kept for historical A/B comparison).
- `meta/` — metaprompts used to generate per-repo prompts and reviewer-task prompts. v2-aligned.
- `repos/` — per-repo spec templates. Developed on dev set, frozen before test set.
- `refactor-v1.md` — initial generic prompt draft (superseded by `forge-v2/`).

## Workflow

1. Metaprompt (`meta/generate-repo-prompt.md`) + repo context → per-repo v2 spec template at `repos/<repo>.md`
2. Iterate v2 pipeline prompts (`forge-v2/*.md`) on dev-set PRs from that repo
3. Freeze both sets of prompts before evaluating test-set PRs
4. Reviewer Phase 7 uses `meta/reviewer-task.md`
5. `meta/c-random.md` is dropped in v2 (retained for historical reference)
