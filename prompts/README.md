# Prompts

## Structure

- `meta/` — metaprompts used to generate repo-specific prompts
- `repos/` — per-repo refactoring prompts (developed on dev set, frozen before test set)
- `refactor-v1.md` — initial generic prompt draft (superseded by repo-specific prompts)

## Workflow

1. Metaprompt + repo context → repo-specific refactoring prompt
2. Iterate prompt on dev-set PRs from that repo
3. Freeze prompt before evaluating test-set PRs
