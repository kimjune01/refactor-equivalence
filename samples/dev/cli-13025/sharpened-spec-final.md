# Sharpened refactor claims

## Accepted Claims

1. `pkg/cmd/pr/create/create.go`, `NewIssueState`: initialize `shared.IssueMetadataState.ApiActorsSupported` from the existing `apiActorsSupported` parameter when constructing `state`.
   - Testable unchanged behavior: PR creation on hosts with actor APIs still sends assignee/reviewer logins, PR creation on GHES still resolves IDs, and `@copilot` assignee replacement keeps matching the same detected capability.
   - Bound: one struct literal field addition inside `NewIssueState`.
   - Justification: the constructor already receives the capability and uses it for assignee replacement, so it should own the matching state initialization.

2. `pkg/cmd/pr/create/create.go`, `createRun`: remove the post-constructor `if issueFeatures.ApiActorsSupported { state.ApiActorsSupported = true }` assignment block after claim 1 is applied, while keeping the surviving feature-detection branch compliant with the adjacent TODO rule.
   - Testable unchanged behavior: immediately after construction and before any `--recover` state is loaded, the initialized `state.ApiActorsSupported` value remains exactly `issueFeatures.ApiActorsSupported` for both true and false detector results. Recovered PR creation state may still overwrite exported fields, including `ApiActorsSupported`, through the existing `FillFromJSON` path.
   - Bound: delete only the redundant assignment block; move or add the `// TODO ApiActorsSupported` comment directly above the remaining `if issueFeatures.ApiActorsSupported` in `createRun` if that feature-detection branch lacks the required adjacent TODO.
   - Justification: setting the same field immediately after construction duplicates responsibility and creates a temporary partially initialized state.

3. `api/queries_repo.go`, `RepoMetadata`: replace the double type assertion in the `RepoAssignableActors` branch with a single `if user, ok := a.(AssignableUser); ok { users = append(users, user) }`.
   - Testable unchanged behavior: `result.AssignableUsers` still contains only actor values whose dynamic type is `AssignableUser`, in the same order.
   - Bound: only the loop that filters `actors` into `users`.
   - Justification: the current loop asserts the same interface value twice, adding avoidable noise in newly touched code.

4. `pkg/cmd/pr/shared/survey.go`, `MetadataSurvey`: remove `state.ApiActorsSupported` from `useReviewerSearch` and `useAssigneeSearch`, leaving those booleans controlled by whether the corresponding search function is non-nil.
   - Testable unchanged behavior: current callers only pass non-nil actor search functions when `ApiActorsSupported` is true, so metadata fetching and prompt selection stay the same for github.com, ghe.com, and GHES paths.
   - Bound: only the two local boolean assignments in `MetadataSurvey`.
   - Justification: the capability check is already enforced at the call sites that choose whether to wire search functions, making this a duplicate guard inside shared prompting logic.

5. `pkg/cmd/pr/shared/editable.go`, `SpecialAssigneeReplacer`: rename the private `actorAssignees` field and `NewSpecialAssigneeReplacer` parameter to `apiActorsSupported`, while preserving the exported constructor signature shape and all call sites.
   - Testable unchanged behavior: `ReplaceSlice` still applies `MeReplacer` for all hosts and applies `CopilotReplacer` only when the same boolean argument is true.
   - Bound: private field name, constructor parameter name, and internal condition only; no exported type/function names change.
   - Justification: the diff changed the capability from assignee-only to actor-API-wide, and the remaining private name now obscures what the boolean controls.

## Rejected

1. Rename exported fields such as `IssueFeatures.ApiActorsSupported`, `RepoMetadataInput.ApiActorsSupported`, `Editable.ApiActorsSupported`, or `IssueMetadataState.ApiActorsSupported`.
   - Reason: exported field renames change public API surface and would require broad test and caller churn.

2. Edit any `*_test.go` file to update assertions or add coverage for the refactor.
   - Reason: the task explicitly forbids test-file edits; behavior should be verified by existing tests.

3. Remove `// TODO ApiActorsSupported` comments from surviving feature-detection `if` statements, or leave a surviving feature-detection `if` without the required adjacent cleanup TODO.
   - Reason: repository instructions require a cleanup TODO directly above feature-detection conditionals for linter compliance.

4. Collapse all `ApiActorsSupported` branches to the actor-only GraphQL path.
   - Reason: that changes GHES behavior; the current feature flag preserves legacy ID/REST fallbacks.

5. Change `api.ReplaceActorsForAssignableByLogin` to require callers to pass Copilot with the `[bot]` suffix instead of appending it inside the helper.
   - Reason: that pushes mutation-specific normalization into multiple callers and risks changing behavior for existing caller inputs.

6. Skip `RepoMetadata` fetching in `AddMetadataToIssueParams` when only login-based assignees or reviewers are present.
   - Reason: although it may be possible, it would require careful nil-receiver and empty-metadata auditing beyond a bounded clarity refactor.

7. Require recovered PR creation state to preserve the detector-derived `ApiActorsSupported` value after `FillFromJSON`.
   - Reason: recover files currently marshal and restore exported state fields, including `ApiActorsSupported`; changing that behavior would be a separate behavioral decision and risks breaking recovered PR creation flows.
