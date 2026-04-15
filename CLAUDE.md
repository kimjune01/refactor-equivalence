# refactor-equivalence

Experiment: does an LLM refactoring pass help or hurt brownfield PRs?

## Quick start

Read `PREREG.md` for the full design. Read `worklog/WORK_LOG.md` for decisions made so far.

## Key files

- `PREREG.md` — pre-registration (the experiment spec)
- `worklog/WORK_LOG.md` — append-only work log, full trail
- `prompts/` — refactoring specs and metaprompts for the forge pipeline
- `prompts/meta/reviewer-task.md` — two-phase blind reviewer instructions
- `prompts/meta/generate-repo-prompt.md` — metaprompt for repo-specific refactoring specs
- `samples/dev/` — dev-set PRs (used for prompt iteration)
- `samples/test/` — test-set PRs (held out, never seen during prompt development)
- `scripts/` — extraction and measurement tooling

## Three agents

| Role | Model | Command |
|------|-------|---------|
| Forge (agent A) | Claude Opus 4.6 | `claude` (auto-edit) |
| Forge (agent B) | Codex GPT-5.4 | `codex exec -s danger-full-access` |
| Reviewer | Gemini 3.1 Pro Preview | `gemini --approval-mode yolo --include-directories <workspace>` |

Opus + codex produce independent refactors (blind-blind-merge). Gemini reviews. No model reviews its own output.

## Workflow

1. Pull eligible PRs from source repos (post August 2025 cutoff)
2. Split into dev set and test set (no overlap)
3. Iterate refactoring prompt on dev set
4. Freeze prompt
5. Run forge pipeline on test-set PRs
6. Gemini reviews (Phase 1: forced choice, Phase 2: trajectory classification)
7. Measure complexity, classify trajectory, report

## Work log

Use `/worklog` after every commit, decision, or direction change. The work log is the trail — publish it alongside results. This is a Gwern Q18 commitment.

## Conventions

- Prefer larger PRs when selecting samples
- C_test = earliest commit where C_final tests pass (backported)
- No-op = agent failed to produce test-passing output; scored as C_test for all metrics
- Three trajectory classes: past C_final, short of C_final, wrong direction (slop-slope)
- Batch expansion: run batches, stop on confidence, log every expansion decision before next batch
