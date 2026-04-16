## Accepted Claims

### 1. Share repository query execution plumbing

- File: `api/queries_repo.go`
- Functions: `FetchRepository`, `IssueRepoInfo`, `GitHubRepo`; new unexported helper local to this file.
- Change: Extract the duplicated GraphQL execution path into a private helper that accepts the already-built query string and `ghrepo.Interface`, builds the `owner`/`name` variables, executes `client.GraphQL`, converts a nil `result.Repository` into the existing `GraphQLError`, and returns `InitRepoHostname(result.Repository, repo.RepoHost())`; have the three functions keep their current query strings and delegate only the shared execution/error/hostname code.
- Behavior unchanged: The emitted GraphQL operation names and selected fields remain unchanged (`RepositoryInfo` for `FetchRepository`/`GitHubRepo`, `IssueRepositoryInfo` for `IssueRepoInfo`), successful repository values retain the same populated fields and hostname, GraphQL errors still pass through unchanged, and nil repository responses still produce the same `GraphQL: Could not resolve to a Repository with the name 'OWNER/REPO'.` error.
- Boundedness: Touch only `api/queries_repo.go`; do not edit tests, call sites, query field lists, exported names, or public types.
- Justification: `IssueRepoInfo` introduced a third copy of the same variable construction, result unmarshalling, nil-repository error, and hostname initialization logic, and a private helper removes that duplication without changing the permission-sensitive query shape.
- Verification: `go test ./api ./pkg/cmd/issue/create`. Do not require `go test ./pkg/cmd/issue/transfer` or `go test ./...` unless the stale transfer test fixture is separately updated outside this refactor's bounded file set.

## Rejected

- Reject: Replace `IssueRepoInfo` with `FetchRepository(client, repo, []string{"id", "name", "owner", "hasIssuesEnabled", "viewerPermission"})`.
  - Reason: This would change the operation name from `IssueRepositoryInfo` to `RepositoryInfo` and route through `RepositoryGraphQL`, which is observable by existing HTTP mocks/tests and risks weakening the explicit permission-focused contract of the new function.

- Reject: Revert the `createRun` call in `pkg/cmd/issue/create/create.go` from `api.IssueRepoInfo` back to `api.GitHubRepo`.
  - Reason: That changes the feature behavior by requesting `defaultBranchRef` again, the exact permission-sensitive field the diff is avoiding.

- Reject: Revert the `issueTransfer` call in `pkg/cmd/issue/transfer/transfer.go` from `api.IssueRepoInfo` back to `api.GitHubRepo`.
  - Reason: That changes the feature behavior for destination repository lookup by restoring the broader repository query and its extra permission requirements.

- Reject: Rename exported `IssueRepoInfo` to a more general name such as `IssueCommandRepoInfo`.
  - Reason: The constraints forbid public API surface changes, and the current exported function is already used by two allowed call sites.

- Reject: Add or edit `*_test.go` coverage for `IssueRepoInfo` or its issue command call sites.
  - Reason: The task explicitly forbids editing test files even though tests can be used to verify behavior.

- Reject: Require `go test ./pkg/cmd/issue/transfer` or `go test ./...` as verification for the accepted `api/queries_repo.go`-only refactor.
  - Reason: The current transfer test fixture still registers `query RepositoryInfo`, while `pkg/cmd/issue/transfer/transfer.go` now calls `api.IssueRepoInfo`, which emits `query IssueRepositoryInfo`; without editing the stale transfer test stub to use `IssueRepositoryInfo`/`StubIssueRepoInfoResponse`, those commands fail with an unmatched HTTP stub even if the accepted production refactor is correct.

- Reject: Extract a JSON response formatter from `pkg/httpmock/legacy.go` for `StubRepoInfoResponse` and `StubIssueRepoInfoResponse`.
  - Reason: The shared fixture text is small and differs in meaningful fields and matcher operation name, so a helper would add low-value indirection outside the production refactor.

- Reject: Change the `IssueRepoInfo` comment only to mention transfer as well as creation.
  - Reason: The comment is slightly narrow but a comment-only edit is not a testable behavior-preserving refactor claim.
