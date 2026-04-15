# Metaprompt: Generate a repo-specific refactoring prompt

Given a repository, produce a refactoring prompt that an LLM agent will receive after tests pass on a brownfield PR. The agent sees the full repo at the tests-first-pass commit but no git history, no reviewer comments, no internet.

## Input

- Repo name and URL
- Language and build system
- Test command
- 3-5 example diffs from dev-set PRs showing what reviewers pushed for (C_test → C_final deltas)
- Any repo-specific conventions visible in the codebase (linting rules, naming patterns, module structure)

## Output

A refactoring prompt that:

1. Tells the agent to refactor for simplicity, clarity, and local idiom while preserving behavior
2. Names the specific patterns this repo values (from the dev-set examples)
3. Names the specific anti-patterns this repo rejects (from the dev-set examples)
4. Restricts edits to source files only (no tests, no config, no docs)
5. Tells the agent that less code is better, familiar patterns are better, and if unsure, don't change it

## Constraints

- The prompt must converge to a fixed point under repeated application (skill monoidal contract)
- The prompt must not reference specific PRs, reviewer names, or git history
- The prompt must work for any PR in the repo, not just the dev-set examples
