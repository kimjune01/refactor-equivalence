## Accepted Claims

### C1 — Version the OAuth scope docs link
**File**: github/authorizations.go:15
**Change**: In the `Scope` type comment, change `https://docs.github.com/rest/oauth/#scopes` to `https://docs.github.com/rest/oauth?apiVersion=2022-11-28#scopes`.
**Goal link**: The goal asks for GitHub REST API docs links in the draft's accepted source-comment scope to pin the library-supported API version.
**Justification**: This versions the OAuth scope REST docs link in an allowed source file without changing runtime behavior.
**Hunt note**: F1 is safe as narrowed because this claim no longer asserts that C1-C3 exhaust every unversioned `/rest` link in allowed source.

### C2 — Version the SCIM list options docs link
**File**: github/scim.go:84
**Change**: In the `ListSCIMProvisionedIdentitiesOptions` comment, change the docs URL to `https://docs.github.com/rest/scim?apiVersion=2022-11-28#list-scim-provisioned-identities--parameters`.
**Goal link**: The goal asks for GitHub REST API docs links in the draft's accepted source-comment scope to avoid redirecting to the latest API version.
**Justification**: This makes the SCIM list-options comment follow the same versioned docs-link convention as the rest of the refactor while preserving behavior.
**Hunt note**: F1 is safe as narrowed because this claim is limited to this SCIM options comment and does not imply that other allowed-file `/rest` links are covered.

### C3 — Version the SCIM update options docs link
**File**: github/scim.go:187
**Change**: In the `UpdateAttributeForSCIMUserOptions` comment, change the docs URL to `https://docs.github.com/rest/scim?apiVersion=2022-11-28#update-an-attribute-for-a-scim-user--parameters`.
**Goal link**: The goal asks for GitHub REST API docs links in the draft's accepted source-comment scope to pin `2022-11-28`.
**Justification**: This versions the SCIM update-options REST docs link in an allowed source file and keeps the change comment-only.
**Hunt note**: F1 is safe as narrowed because this claim no longer says it removes every remaining unversioned REST docs link.

### C4 — Revert the unrelated TreeEntry path pointer rewrite
**File**: example/commitpr/main.go:108
**Change**: In `getTree`, change the `TreeEntry` literal's `Path` field from `github.Ptr(file)` back to `&file`.
**Goal link**: The goal is only about API-versioned documentation links, not changing example pointer construction.
**Justification**: Restoring the local address expression removes unrelated implementation churn and preserves the same `*string` value observed by `CreateTree`.

### C5 — Restore redundantptr as an unrelated existing linter, excluding fixtures
**File**: .golangci.yml:27
**Change**: Re-add `redundantptr` to the enabled linter list and custom linter settings, re-add its plugin entry in `.custom-gcl.yml`, and restore only the buildable non-fixture linter module files `tools/redundantptr/go.mod` and `tools/redundantptr/redundantptr.go` as they existed before the draft.
**Goal link**: The goal does not require removing custom lint enforcement to add API-version query parameters to docs comments.
**Justification**: Restoring the existing linter configuration and implementation removes off-goal deletion from the draft while leaving library behavior unchanged; fixture restoration is deliberately excluded as separately rejected below.
**Hunt note**: F2 is safe as narrowed because C5 now explicitly restores only the linter configuration and buildable plugin source, while the deleted `tools/redundantptr/testdata` fixtures remain rejected for a non-scope reason.

## Rejected

- Update `tools/metadata/testdata/update-go/valid/github/a.go:17` to include `apiVersion=2022-11-28`: rejected because it is metadata fixture input and not needed for the accepted source-comment claims.
- Restore `tools/redundantptr/testdata/src/has-warnings/github.go` and `tools/redundantptr/testdata/src/no-warnings/github.go`: rejected because C5 intentionally restores only the linter configuration and buildable plugin source; these fixtures are not needed to reverse the off-goal linter deletion identified by the accepted claim.
- Add `apiVersion=2022-11-28` to Enterprise Server, GraphQL, webhook-event, or general GitHub documentation URLs outside `/rest` and `/enterprise-cloud@latest/rest`: rejected because those links are not the public REST/enterprise-cloud docs links targeted by the goal and several are pinned to different documentation products or versions.
- Replace `tools/metadata/metadata.go`'s `normalizeDocURL` helper with ad hoc string concatenation: rejected because the current helper already expresses the goal directly and correctly preserves fragments and existing query parameters.
- Move `metadataDocsAPIVersion` to `github/github.go` by exporting `defaultAPIVersion`: rejected because it would cross a public package boundary for a tooling constant and introduce API surface not required by the goal.
- Add `apiVersion=2022-11-28` to `github/issues.go:68` for `https://docs.github.com/rest/search/#text-match-metadata`: rejected for this reconcile round because F1 identified it as an omitted candidate after round 1 and the reconcile rules forbid adding new accepted refactor claims; it remains outside C1-C3's narrowed per-comment scope.
- Add `apiVersion=2022-11-28` to `github/github.go:139` for `https://docs.github.com/rest/previews/#repository-creation-permissions`: rejected for this reconcile round because F1 identified it as an omitted candidate after round 1 and the reconcile rules forbid adding new accepted refactor claims; it also documents an internal preview media type rather than an exported API operation or options comment like C1-C3.
- Add `apiVersion=2022-11-28` to `github/github.go:142` for `https://docs.github.com/rest/previews/#create-and-use-repository-templates`: rejected for this reconcile round because F1 identified it as an omitted candidate after round 1 and the reconcile rules forbid adding new accepted refactor claims; it also documents an internal preview media type rather than an exported API operation or options comment like C1-C3.
