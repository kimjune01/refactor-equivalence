# Volley Round 1: Sharpened Refactor Claims

## Accepted Claims

1. `api/queries_pr.go`: the `SuggestedAssignableActors` GraphQL response shape duplicates the exact same anonymous `suggestedActors` node struct for `Issue` and `PullRequest`. Introduce a local named struct type inside `SuggestedAssignableActors` for those nodes and use it in both branches and in the `nodes` local. This is behavior-preserving if the GraphQL tags, `first: 10`, `query: $query`, and User/Bot field sets remain unchanged. Test by running existing PR edit/API tests and by verifying the generated query still includes both `... on Issue` and `... on PullRequest` fragments.

2. `api/queries_pr.go`: `SuggestedAssignableActors` manually assigns `variables["query"]` in an `if/else` even though both branches only choose between `githubv4.String(query)` and `(*githubv4.String)(nil)`. Replace this with a short `queryArg` local initialized to nil and set only when `query != ""`, then build the variables map once. This keeps blank queries passing GraphQL null and nonblank queries passing the same string. Testable by existing HTTP mock expectations for blank and nonblank suggested-assignee searches.

3. `api/queries_pr.go`: `SuggestedAssignableActors` repeats the viewer-included check in both the User and Bot branches. Track the appended actor login once after appending a non-empty actor, or extract the login before the branch, so the condition `query == "" && viewer.Login != "" && actorLogin == viewer.Login` appears once. This keeps the blank-query viewer fallback semantics unchanged: append viewer only when the blank result set did not already include that login. Test with cases where the viewer is present as a suggested user, absent from suggestions, and query is nonblank.

4. `pkg/cmd/pr/edit/edit.go`: `assigneeSearchFunc` returns a closure via a `searchFunc` local that is called nowhere else. Return the closure literal directly. This removes one level of indirection without changing inputs, captured variables, or return type. Test by compiling `pkg/cmd/pr/edit` and by existing interactive assignee edit tests that invoke the captured search function.

5. `pkg/cmd/pr/edit/edit.go`: the error path in `assigneeSearchFunc` explicitly fills zero values for `Keys`, `Labels`, and `MoreResults`. Return `prompter.MultiSelectSearchResult{Err: err}` instead. This is behavior-preserving because nil slices and zero integers are already the zero values of the struct fields. Test by existing tests or a focused unit check that an API error is propagated from the search function.

6. `pkg/cmd/pr/edit/edit.go`: `assigneeSearchFunc` uses an `if a.Login() != "" { ... } else { continue }` shape before adding display labels. Convert this to an early `if a.Login() == "" { continue }` guard, then append the login and label. This reduces nesting and preserves the behavior that actors with blank logins are skipped and not added to `editable.Metadata.AssignableActors`. Test with a mixed actor list containing a blank-login actor.

7. `pkg/cmd/pr/edit/edit.go`: `assigneeSearchFunc` calls `a.Login()` up to three times and `a.DisplayName()` twice per actor. Store `login := a.Login()` and `label := a.DisplayName()` once per nonblank actor, defaulting `label` to `login` when empty. This is bounded to the closure and preserves result ordering, keys, labels, and metadata append order. Test by asserting the search result contains logins as `Keys`, display names as `Labels`, and login fallback when display name is empty.

8. `pkg/cmd/preview/prompter/prompter.go`: `runMultiSelectWithSearch` constructs `MultiSelectSearchResult` values with temporary `searchResultKeys`, `searchResultLabels`, and `moreResults` locals that are only used once in each branch. Return struct literals directly in the blank-input and nonblank-input branches. This keeps the demo output and `MoreResults` values identical while reducing incidental state. Test by `go test ./pkg/cmd/preview/prompter` or full `go test ./...`.

9. `internal/prompter/prompter.go`: after changing `MultiSelectWithSearch` to use `MultiSelectSearchResult`, the interface comment still describes the old tuple-like return signature. Update only the comment to describe `func(query string) MultiSelectSearchResult` and the meanings of `Keys`, `Labels`, `MoreResults`, and `Err`. This is documentation-only and testable by review; no runtime behavior changes.

10. `pkg/cmd/pr/shared/editable.go`: `FetchOptions` computes `fetchAssignees` with nested `if` blocks and two independent conditions. Replace it with a single boolean expression under `if editable.Assignees.Edited`, equivalent to: fetch when there are add/remove values, or when there are no add/remove values and no `AssigneeSearchFunc`. Preserve `ActorAssignees` in the metadata input. Test with existing PR edit cases that expect no `RepositoryAssignableActors` query during dynamic interactive search, and cases that expect assignee metadata for non-interactive add/remove flows.

11. `pkg/cmd/pr/shared/editable.go`: `EditFieldsSurvey` assigns `editable.Assignees.Options = []string{}` immediately before using `MultiSelectWithSearch`, but that options slice is not read by the search path. Remove this assignment unless a failing test demonstrates it is needed. This is bounded to the dynamic search branch and should preserve behavior because `MultiSelectWithSearch` receives defaults, persistent options, and the search function directly. Test with existing interactive assignee edit tests.

12. `internal/prompter/prompter.go`, `internal/prompter/prompter_mock.go`, `internal/prompter/test.go`, `pkg/cmd/pr/shared/editable.go`, `pkg/cmd/pr/shared/survey.go`, and `pkg/cmd/preview/prompter/prompter.go`: keep the `MultiSelectSearchResult` signature consistent across all non-test call sites and mocks. Any refactor of that type must compile without touching `*_test.go`. Test with `go test ./...`.

## Rejected Claims

1. Do not edit any `*_test.go` files, even where test helpers or expectations could be simplified for the new search-result struct. The allowed edit list includes no test files and the task explicitly forbids them.

2. Do not change `.github/workflows/*.yml`, `go.mod`, `script/licenses`, license files, third-party license files, or license tooling/scripts as part of this Go refactor. They are in the input diff/allowed list, but they are dependency/version pin or license tooling changes rather than complexity in the Go implementation, and changing them risks behavior outside the requested refactor.

3. Do not remove `MultiSelectSearchResult` and revert `MultiSelectWithSearch` to returning multiple values. That would change the feature-facing API introduced by the diff across prompter interfaces and generated mocks rather than refactoring the implementation.

4. Do not add reviewer dynamic search in this round. The diff contains a TODO for reviewer search, but implementing it is new feature work, not simplification of introduced behavior.

5. Do not move `SuggestedAssignableActors` into `api/queries_repo.go` or merge it with `RepoAssignableActors`. The existing functions query different GraphQL roots, limits, pagination behavior, and blank-query viewer fallback semantics; merging them would broaden the behavioral surface.

6. Do not remove the blank-query viewer fallback in `SuggestedAssignableActors`. It is explicit feature behavior introduced by the diff and affects the initial interactive assignee options.

7. Do not deduplicate or sort accumulated `editable.Metadata.AssignableActors` in `assigneeSearchFunc` unless existing tests expose duplicate-ID problems. Deduplication could change which actor ID wins in `MembersToIDs` when multiple search calls return the same login/display name.

8. Do not replace `AssignableActor` with a new exported struct or interface hierarchy. The codebase already has sealed `AssignableUser` and `AssignableBot` implementations; changing public API shape violates the constraint against public API changes.
