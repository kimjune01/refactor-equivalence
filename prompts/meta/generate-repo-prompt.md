# Metaprompt: Generate a repo-specific refactoring prompt

Given a repository, produce a refactoring prompt that an LLM agent will receive after tests pass on a brownfield PR. The agent sees the full repo at the tests-first-pass commit, the diff from base to that commit, but no git history, no reviewer comments, no internet.

## Input

- Repo name and URL
- Language and build system
- Test command
- 3-5 dev-set diffs showing what reviewers pushed for (C_test → C_final deltas). These are for prompt generation only — the agent never sees them at runtime.
- Repo conventions extracted mechanically: linter config, formatter config, CI checks. Not hand-curated.

## Output

A refactoring prompt that:

1. Tells the agent to refactor for simplicity, clarity, and local idiom while preserving behavior
2. Names recurring patterns this repo values (generalized from dev-set examples, not one-off fixes)
3. Names recurring anti-patterns this repo rejects
4. Restricts edits to the allowed file set (provided at runtime)
5. Tells the agent: fewer concepts and branches is better than fewer lines. Don't golf.
6. If unsure whether a change simplifies, don't make it

## Constraints

- The prompt must not reference specific PRs, reviewer names, or git history
- The prompt must work for any PR in the repo, not just the dev-set examples
- The prompt must not ban renaming or error-handling changes categorically — reviewers request these. Ban adding new abstractions or patterns not already in the codebase.
