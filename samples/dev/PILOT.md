# Pilot dev set — google-gemini/gemini-cli

5 PRs for feasibility pilot. Locked 2026-04-15. All merged post-cutoff (GPT-5.4: 2025-08-31), APPROVED, 100–2000 LOC, multiple reviews and commits.

| PR | LOC (+/-) | Files | Commits | Reviews | Merged | Title |
|----|-----------|-------|---------|---------|--------|-------|
| [24483](https://github.com/google-gemini/gemini-cli/pull/24483) | 1160/229 | 32 | 2 | 4 | 2026-04-02 | feat(core): Land ContextCompressionService |
| [25101](https://github.com/google-gemini/gemini-cli/pull/25101) | 849/527 | 69 | 5 | 4 | 2026-04-10 | refactor(core): consolidate execute() arguments into ExecuteOptions |
| [24489](https://github.com/google-gemini/gemini-cli/pull/24489) | 926/342 | 47 | 10 | 16 | 2026-04-09 | feat(core): refactor subagent tool to unified invoke_subagent tool |
| [24437](https://github.com/google-gemini/gemini-cli/pull/24437) | 819/316 | 8 | 4 | 7 | 2026-04-01 | fix(core): ensure complete_task tool calls recorded in chat history |
| [24623](https://github.com/google-gemini/gemini-cli/pull/24623) | 651/400 | 20 | 3 | 4 | 2026-04-06 | split context |

## Diversity

- 2 feat, 1 refactor, 1 fix, 1 untyped
- All touch `core` module (primary experiment target area)
- Ranges from focused (8 files) to sprawling (69 files)

## Remaining pool

84 other eligible candidates in `samples/candidates-gemini-cli.json`, reserved for test set. No overlap permitted before prompt freeze.
