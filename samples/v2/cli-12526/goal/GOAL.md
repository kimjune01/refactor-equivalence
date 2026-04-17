# PR #12526 — `gh pr edit`: new interactive prompt for assignee selection, performance and accessibility improvements

## PR body

## Description

Implements multiselect with search for `gh pr edit` assignees, addressing performance and accessibility issues in large organizations. Part of larger work to improve the reviewer and assignee experience in `gh`.

## Key changes

- **New `MultiSelectWithSearch` prompter**: Adds a search sentinel option to multiselect lists, allowing dynamic fetching of assignees via API search rather than loading all org members upfront
- **`SuggestedAssignableActors` API**: New GraphQL query to fetch suggested actors for an assignable (Issue/PR) node with optional search filtering
- **`gh pr edit` assignee flow**: Wires up the new prompter for interactive assignee selection when `ActorIsAssignable` feature is detected
- **Prompter interface expansion**: Both `surveyPrompter` and `accessiblePrompter` implement the new method, with full test coverage
- **Preview command**: Adds `multi-select-with-search` to `gh preview prompter` for testing

## Notes for reviewers

- This PR only covers assignees for `gh pr edit`; reviewers will follow in a subsequent PR

## Linked issues
(none)
