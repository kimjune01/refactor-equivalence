# refactor-equivalence

Can LLMs reduce codebase complexity through refactoring, making PRs easier to merge?

## The question

Every correct PR belongs to an equivalence class: many implementations pass the same tests. The first one that passes is rarely the simplest. Reviewers push toward simpler members through feedback rounds. Can an LLM do that push autonomously?

## Design

For each sampled PR:
1. Find `C_test` — the commit where tests first pass
2. Find `C_merge` — the final merged version
3. Apply an LLM refactoring prompt to `C_test` → `C_llm`
4. Measure whether `C_llm` is closer to `C_merge` than `C_test` was

See [PREREG.md](PREREG.md) for the full pre-registration.

## Structure

```
prompts/          # Refactoring prompts (developed on dev set, frozen before test set)
  refactor-v1.md  # Current prompt draft
scripts/          # Extraction and measurement tooling
  extract_snapshots.sh
samples/          # PR snapshots
  dev/            # Development set (used for prompt tuning)
  test/           # Test set (frozen, never seen during prompt development)
```

## Prompt development

Samples in `samples/dev/` are used to iterate the refactoring prompt. Samples in `samples/test/` are held out. The prompt is frozen before any test-set PR is evaluated.

## Source repos

- `google/gemini-cli` — TypeScript monorepo, active review culture, 20+ contributors
