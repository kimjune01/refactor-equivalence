## Sharpened Claims

1. `api/queries_issue.go:IssueCreate` and `api/queries_pr.go:CreatePullRequest`: replace the duplicated `params["assigneeLogins"]` lookup and `ReplaceActorsForAssignableByLogin` call with one unexported helper in the `api` package, while keeping each caller's existing partial-success return value (`issue, err` or `pr, err`).
   - Testable unchanged behavior: issue and PR creation with non-empty `assigneeLogins` still runs `replaceActorsForAssignable` after the create mutation; empty or absent `assigneeLogins` still skips the mutation; mutation errors still return the created issue/PR plus the error.
   - Justification: the diff introduced the same post-create assignment branch in two create paths, and a helper used by both removes duplication without changing the public API.

2. `pkg/cmd/pr/shared/editable.go:AssigneeIds` and `pkg/cmd/pr/shared/editable.go:AssigneeLogins`: extract the duplicated non-interactive add/remove set computation into a private helper that takes the caller-selected defaults and replacement function, then have both methods use it before their existing ID-resolution or login-return behavior.
   - Testable unchanged behavior: edited assignees still return `nil` when unedited, still apply `@me`, still apply `@copilot` only for actor assignee flows, still use `DefaultLogins` for actor defaults and `Default` for legacy defaults, and still resolve IDs only in `AssigneeIds`.
   - Justification: both methods now contain the same set-add/remove control flow, so isolating only that mechanical part reduces duplication while preserving the distinct actor-vs-legacy rules at the call sites.

3. `api/queries_repo.go:RepoAssignableActors` and `api/queries_repo.go:SearchRepoAssignableActors`: introduce an unexported shared node type and conversion helper for `suggestedActors` User/Bot nodes, and use it in both functions without changing their GraphQL field arguments, pagination, query names, or return signatures.
   - Testable unchanged behavior: paginated repository actor fetches still return all user and bot actors in order; repository actor searches still return up to 10 matching actors plus the same assignable-user total count; unknown node types are still ignored.
   - Justification: the diff added a second copy of the User/Bot node shape and conversion loop, which is local duplication in the same file.

4. `pkg/cmd/pr/shared/survey.go:MetadataSurvey`: use the already-computed `useReviewerSearch` boolean for both metadata-fetch selection and reviewer prompt selection, replacing the later direct `reviewerSearchFunc != nil` check.
   - Testable unchanged behavior: when `state.ActorReviewers` is true and a reviewer search function is supplied, the reviewer prompt still uses `MultiSelectWithSearch`; when actor reviewers are unavailable, the prompt still uses the static reviewer list.
   - Justification: this keeps the two branches that decide "search reviewer path vs static reviewer path" tied to the same condition and avoids a future inconsistent path without expanding scope.

5. `pkg/cmd/pr/shared/survey.go:MetadataSurvey`: in the static assignee prompt branch, factor only the repeated append/default-selection loop body into a small local closure that accepts `login` and `displayName`, leaving the actor and legacy source slices separate.
   - Testable unchanged behavior: actor assignee metadata still displays actor display names and stores selected actor logins; legacy assignee metadata still displays assignable user display names and stores selected user logins; default selections still match `state.Assignees`.
   - Justification: this removes duplicated loop logic while avoiding a new cross-file abstraction or interface for two different source slice types.

## Rejected Claims

1. `*_test.go`: add or update tests for ActorAssignees create/edit behavior.
   - Rejected because the task explicitly forbids editing any `*_test.go` file, even though existing tests can be run for verification.

2. `pkg/cmd/pr/create/create.go:createRun`: extract the inline repository reviewer search closure into a new shared helper.
   - Rejected because the closure has one call site in the diff and extracting it would add indirection rather than remove duplicated code.

3. `api/queries_repo.go:SuggestedAssignableActors` and `api/queries_repo.go:SearchRepoAssignableActors`: merge the two functions into one generalized actor-search API.
   - Rejected because one query is scoped to an existing assignable node and the other is repository-scoped for create flows, so merging them would increase branching and risk query-shape regressions.

4. `pkg/cmd/pr/shared/params.go:AddMetadataToIssueParams`: omit `assigneeIds` or `assigneeLogins` from `params` when `tb.Assignees` is empty.
   - Rejected because the current behavior may intentionally preserve empty assignee metadata in create/update parameter maps, and changing key presence is observable by callers and tests.

5. `pkg/cmd/issue/create/create.go:createRun` and `pkg/cmd/pr/create/create.go:createRun`: move ActorAssignees setup for metadata survey into a new shared create-flow helper.
   - Rejected because the surrounding issue and PR create flows differ substantially, and the common code is only a few assignments around existing shared search helpers.

6. `pkg/cmd/pr/shared/editable.go`: rename `ActorAssignees`, `AssigneeSearchFunc`, or other exported/shared fields for style.
   - Rejected because rename-only cleanup is outside the behavioral refactor goal and would touch public/shared struct fields without reducing complexity.
