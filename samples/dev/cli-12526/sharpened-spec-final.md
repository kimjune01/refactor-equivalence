# Volley Round 1: Sharpened Refactor Claims

## Accepted Claims

1. **`api/queries_pr.go` / `SuggestedAssignableActors`: replace the repeated anonymous suggested-actor node struct with one local `suggestedActorNode` type used by both the Issue and PullRequest GraphQL fragments and by the post-query `nodes` variable.**
   - Testable claim: for mocked Issue and PullRequest responses containing User and Bot nodes, the function returns the same actor IDs, logins, display names, order, and viewer-append behavior as before.
   - Justification: the diff introduced three copies of the same GraphQL node shape, and a local type removes that duplication without changing the query fields.

2. **`api/queries_pr.go` / `SuggestedAssignableActors`: initialize the GraphQL variables map with `"query": (*githubv4.String)(nil)` and only overwrite it with `githubv4.String(query)` when `query != ""`.**
   - Testable claim: an empty query still sends a nil GraphQL query variable, and a non-empty query still sends the exact string value.
   - Justification: the current if/else only selects between two variable values, so a default plus conditional overwrite expresses the same behavior with less branching.

3. **`internal/prompter/prompter.go` / `multiSelectWithSearch`: add a local `labelFor(key string) string` helper inside the function and use it anywhere the code currently repeats `optionKeyLabels[k]` with fallback to `k`.**
   - Testable claim: initial defaults, selected options, search results, and persistent options show the same labels and return the same selected keys.
   - Justification: the diff repeats the same label fallback logic in four loops inside one function.

4. **`internal/prompter/prompter.go` / `multiSelectWithSearch`: consolidate the repeated successful-search state update into a local function that copies `Keys`, `Labels`, and `MoreResults` into local state and records labels in `optionKeyLabels`.**
   - Testable claim: the initial empty search still wraps errors as `failed to search: ...`, later searches still return the raw search error, and successful searches produce the same option list.
   - Justification: the initial search path and the search-sentinel path duplicate the same successful-result assignment while needing only their error handling to remain distinct.

5. **`pkg/cmd/pr/edit/edit.go` / `assigneeSearchFunc`: return the closure directly and simplify the actor loop by storing `login := a.Login()`, continuing on empty login, appending `login`, and appending `a.DisplayName()` without the extra fallback branch.**
   - Testable claim: users with names, users without names, Copilot bots, regular bots, and empty-login actors produce the same `Keys`, `Labels`, `MoreResults`, `Err`, and metadata append behavior.
   - Justification: `api.AssignableActor` is sealed to the repository's implementations, whose `DisplayName` methods already fall back to a non-empty login when needed.

6. **`pkg/cmd/pr/shared/editable.go` / `FetchOptions`: replace the multi-branch `fetchAssignees` block with the equivalent boolean expression `editable.Assignees.Edited && (len(editable.Assignees.Add) > 0 || len(editable.Assignees.Remove) > 0 || editable.AssigneeSearchFunc == nil)`.**
   - Testable claim: metadata fetch requests still set `Assignees` true for edited flag-based assignee changes, true for edited interactive assignees without a search function, false for edited interactive assignees with a search function, and false when assignees are not edited.
   - Justification: the current code encodes one boolean decision with nested conditionals and repeated Add/Remove checks.

7. **`pkg/cmd/preview/prompter/prompter.go` / `runMultiSelectWithSearch`: return `prompter.MultiSelectSearchResult` literals directly from each search branch and remove the temporary `searchResultKeys`, `searchResultLabels`, and `moreResults` variables.**
   - Testable claim: the preview command still registers `multi-select-with-search`, prints the same output for no selections and selected keys, and supplies the same initial and searched keys, labels, and more-result counts.
   - Justification: the preview search function is demonstration code where the temporaries add noise but no state sharing.

## Rejected Claims

1. **Add or preserve `ReviewerSearchFunc` on `pkg/cmd/pr/shared/editable.go` / `Editable`.**
   - Reason: the field is exported, unused, and outside the accepted refactor scope. Adding a field to an exported Go struct changes public API surface and can break external unkeyed `shared.Editable{...}` literals without providing behavior needed by the searchable-assignee flow.

2. **Add or preserve `MultiSelectWithSearch` on `pkg/cmd/pr/shared/survey.go` / `Prompt`.**
   - Reason: `Prompt` is an exported interface, and adding a method is a source-incompatible public API expansion for external implementations. `MetadataSurvey` still does not call the method, so this exported interface change is outside the behavior-preserving refactor scope.

3. **Manually refactor `internal/prompter/prompter_mock.go` around the new `MultiSelectWithSearch` mock plumbing.**
   - Reason: the file is generated by `moq`; manual simplification would create generated-code drift and is not justified unless the source interface changes.

4. **Change `multiSelectWithSearch` to return the initial search error directly instead of wrapping it with `failed to search`.**
   - Reason: this changes observable error text and violates the behavior-unchanged requirement.

5. **Implement the TODOs in `pkg/cmd/pr/shared/survey.go` to use `MultiSelectWithSearch` for issue/PR metadata assignees.**
   - Reason: this is new feature wiring outside the introduced PR-edit behavior, not a simplification of the current diff.

6. **Add or edit tests to cover the new search behavior.**
   - Reason: the task and spec explicitly prohibit editing `*_test.go` files.

7. **Change `pkg/cmd/pr/shared/editable.go` / `EditFieldsSurvey` to remove `editable.Assignees.Options = []string{}` before the searchable assignee prompt.**
   - Reason: the assignment appears redundant today, but removing it is not clearly testable as behavior-preserving because it changes the post-survey state retained on the editable object.

## Suggested Verification

- `gofmt -l api/queries_pr.go internal/prompter/prompter.go pkg/cmd/pr/edit/edit.go pkg/cmd/pr/shared/editable.go pkg/cmd/preview/prompter/prompter.go`
- `go test ./api ./internal/prompter ./pkg/cmd/pr/edit ./pkg/cmd/pr/shared ./pkg/cmd/preview/prompter`
- `go test ./...`
