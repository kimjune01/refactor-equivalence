# Metaprompt: Generate a repo-specific refactoring spec

Given a repository, produce a refactoring spec that serves as input to the [/forge](/forge) pipeline. The spec is sharpened by Volley, implemented independently by two models via blind-blind-merge, verified by bug-hunt, and cleaned by a final Volley pass.

## Input

- Repo name and URL
- Language and build system
- Test command (the CI command that gates merge)
- 3-5 dev-set diffs showing what reviewers pushed for (C_test → C_final deltas). These are for prompt generation only — the agent never sees them at runtime.
- Repo conventions extracted mechanically: linter config, formatter config, CI checks.

## Output

A refactoring spec that:

1. Describes the refactoring goal: reduce complexity, improve clarity, match local idiom, preserve behavior
2. Names recurring patterns this repo values (generalized from dev-set examples, not one-off fixes)
3. Names recurring anti-patterns this repo rejects
4. Specifies the allowed file set (source files changed from `C_base` to `C_test` — no tests, no config, no docs)
5. States the invariant: tests must pass after refactoring. Fewer concepts and branches is better than fewer lines. Don't golf.
6. States the uncertainty rule: if unsure whether a change simplifies, don't make it

The spec must be concrete enough for Volley to sharpen into testable claims in two rounds. If it can't, the spec is underspecified.

## Constraints

- The spec must not reference specific PRs, reviewer names, or git history
- The spec must work for any PR in the repo, not just the dev-set examples
- Renaming for consistency with codebase conventions is allowed. Adding new abstractions or patterns not already in the codebase is not.
