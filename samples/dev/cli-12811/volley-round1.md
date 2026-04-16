# Volley round 1: sharpened refactor claims

## Accepted claims

1. `pkg/cmd/api/api.go:processResponse` should replace the per-call `regexp.MatchString("[/+]json(;|$)", ...)` with a package-level compiled regexp and call `jsonContentTypeRE.MatchString`.
   - Testable unchanged behavior: content types containing `/json`, `+json`, and non-JSON values are classified the same by existing `pkg/cmd/api` response-processing tests.
   - Justification: the diff introduced repeated regexp compilation and ignored an impossible static-pattern error where the previous package-level regexp was simpler and idiomatic.

2. `internal/licenses/licenses.go:content` should use slash-path operations for embedded filesystem paths instead of converting through `filepath.FromSlash`, `filepath.Dir`, and `filepath.Rel`.
   - Testable unchanged behavior: `go test ./internal/licenses` and `licenses.Content()` output ordering/content remain unchanged for embedded `embed/third-party` files.
   - Justification: `embed.FS` and `io/fs` paths are slash-separated on every platform, so `path`/string-relative handling removes unnecessary OS-specific path conversion.

3. `pkg/cmd/issue/close/close.go:NewCmdClose` and `pkg/cmd/issue/close/close.go:closeRun` should share one unexported normalization/validation helper for `--duplicate-of` and `--reason`.
   - Testable unchanged behavior: invoking `gh issue close <n> --duplicate-of <m>` still defaults the close reason to `duplicate`, and combining `--duplicate-of` with any non-`duplicate` reason still returns the same flag error both through Cobra execution and direct `closeRun` tests.
   - Justification: the diff introduced the same conditional validation twice, which risks divergence between command parsing and direct runner behavior.

4. `pkg/cmd/issue/close/close.go:apiClose` should collapse the repeated unsupported-duplicate error branches in issue feature detection into a single local condition while preserving the same reason fallback.
   - Testable unchanged behavior: when `StateReason` or `StateReasonDuplicate` is unsupported, duplicate closes with `duplicateIssueID` still return `closing as duplicate is not supported on <host>`, while non-duplicate reason closes still silently omit unsupported state reasons.
   - Justification: the two branches differ only by the feature predicate and duplicate guard, so the duplicate-specific error handling can be expressed once without changing the mutation input.

5. `pkg/cmd/project/item-edit/item_edit.go:updateDraftIssue` should inline the single-use `buildEditDraftIssue` helper and remove that helper.
   - Testable unchanged behavior: draft issue updates still call the `EditDraftIssueItem` mutation with the same `githubv4.UpdateProjectV2DraftIssueInput` fields and produce the same exporter/TTY output.
   - Justification: after the diff removed the previous preservation logic, `buildEditDraftIssue` became a one-call wrapper around a small literal and adds indirection without reducing complexity.

6. `pkg/cmd/repo/clone/clone.go:cloneRun` should inline the `connectedToTerminal := opts.IO.IsStdoutTTY()` temporary into the following `if`.
   - Testable unchanged behavior: cloning a fork still emits the default-repository warning only when stdout is a TTY and performs the same upstream remote setup.
   - Justification: the temporary is used once and does not clarify the surrounding control flow.

## Rejected claims

1. Do not refactor `.github/workflows/deployment.yml`, `go.mod`, `.gitignore`, or `script/licenses`.
   - Reason: these are workflow, dependency, ignore-rule, and generation-script changes rather than Go complexity introduced inside functions; dependency edits are also outside the refactor goal.

2. Do not restore or redesign removed command features such as `pkg/cmd/browse/browse.go` `--blame`, `pkg/cmd/repo/clone/clone.go` `--no-upstream`, `pkg/cmd/agent-task/list/list.go` JSON output, or `pkg/cmd/agent-task/view/view.go` JSON output.
   - Reason: those would change the behavior established by the input diff rather than refactor it.

3. Do not reintroduce `api/client.go:GenerateScopeErrorForGQL`, `api/client.go:requiredScopesFromServerMessage`, or the removed `api.PullRequestFile.ChangeType` field and `api/query_builder.go` `changeType` query field.
   - Reason: these are removed API/query surface changes from the diff, and restoring them would be behavioral or public-surface work rather than behavior-preserving simplification.

4. Do not change `pkg/cmd/copilot/copilot.go:runCopilot` to set `COPILOT_GH=true`, `pkg/cmd/issue/list/http.go:searchIssues` to reject pull request qualifiers, or `pkg/cmd/repo/fork/fork.go:NewCmdFork` to reject `--remote` with a repository argument.
   - Reason: each would restore validation/environment behavior removed by the diff, so the observable CLI behavior would not remain unchanged.

5. Do not alter the ANSI color constants in `pkg/cmd/pr/diff/diff.go` or `pkg/jsoncolor/jsoncolor.go`.
   - Reason: the changed escape codes directly affect terminal output and are not complexity refactors.

6. Do not refactor `pkg/cmd/issue/view/http.go:preloadIssueComments` by skipping the GraphQL call when `HasNextPage` is false or by preserving the initially loaded comments.
   - Reason: that would change the current fetch and comment-node behavior introduced by the diff; the existing `FIXME` in `pkg/cmd/issue/view/view.go:viewRun` identifies it as behavioral debt, not a safe refactor claim.

7. Do not restore `pkg/cmd/project/item-edit/item_edit.go` title/body changed-flag tracking or `pkg/cmd/project/shared/queries/queries.go:Client.Query`.
   - Reason: that would change how empty `--title`/`--body` values and draft issue field preservation behave, and the query method is only needed by the removed preservation path.

8. Do not edit `internal/licenses/embed/*` placeholder/report files or deleted per-platform embed files.
   - Reason: these files are generated/embed payload structure, not function-level Go refactor targets, and changing them risks release artifact behavior.

9. Do not edit any `*_test.go` file.
   - Reason: tests are explicitly frozen by the task and excluded even when they would make a claim easier to verify.
