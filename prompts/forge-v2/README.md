# v2 forge prompts

Per PREREG_V2.md §Procedure.4. Prompts are **frozen** before any v2 test-set PR is evaluated. Dev-set iteration may edit these; each change committed.

## Pipeline

| # | Phase | Model | Prompt | Artifact |
|---|-------|-------|--------|----------|
| 4a | Volley (goal-anchored) | codex GPT-5.4 | `01-volley.md` | `volley/round-N-claims.md` |
| 4b | Hunt-spec (iterative, N≤10) | codex GPT-5.4 | `02-hunt-spec.md` | `volley/hunt-spec-round-N.md` |
| 4c | Reconcile (mandatory-reject blockers) | codex GPT-5.4 | `03-reconcile.md` | `volley/sharpened-spec-final.md` |
| 4d | Blind-blind-merge | opus 4.6 + codex GPT-5.4 | `04-implement.md` | `blind-blind/*.diff` |
| 4e | Implementation evidence check | (automation) | — | — |
| 4f | Hunt-code (iterative, full build+tests, N≤10) | codex GPT-5.4 | `05-hunt-code.md` | `gates/hunt-code-round-N.md` |
| 4g | Reviewer-loop (Gemini, N≤10) | gemini 3.1 Pro | `06-reviewer-loop.md` | `reviewer-loop/round-N-comments.md` |
| 4h | Ship-time complexity gate | (automation) | — | `gates/complexity-gate.json` |

## Changes vs v1 (forge-pilot)

- **Volley is goal-anchored.** Inputs include goal (PR title + body + linked issues) as well as diff.
- **Hunt-spec iterates** (v1 was single-pass).
- **Reconcile cannot narrow blockers** — only rejects them.
- **Blind-blind merge is whole-model** (not per-file). Sum-of-churn across all allowed-edit files; tie → alpha (codex before opus).
- **Hunt-code runs full build + tests** (not just typecheck). Iterates to zero findings with cap N=10.
- **Reviewer-loop added.** Gemini reviews post-hunt-code; iterates to zero comments or shrinkage stops; cap N=10.
- **Complexity gate at ship-time** (after reviewer-loop converges), not mid-pipeline. δ=0.05 on scoped mean cognitive.

## Invocations

- Claude Opus 4.6: agent in this Claude Code session, OR spawn subagent
- Codex GPT-5.4: `codex exec -c model="gpt-5.4" -s danger-full-access "<prompt>"`
- Gemini 3.1 Pro Preview: `gemini -m gemini-3.1-pro-preview --approval-mode yolo "<prompt>"`
