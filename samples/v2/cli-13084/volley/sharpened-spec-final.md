## Accepted Claims

### C1 — Remove first-page state from discussions-enabled check
**File**: pkg/cmd/discussion/client/client_impl.go:240
**Change**: In `discussionClient.List`, remove the `firstPage` local variable and check `!data.Repository.HasDiscussionsEnabled` directly after each GraphQL response before reading `data.Repository.Discussions`.
**Goal link**: This clarifies the client requirement that repositories with discussions disabled return a clear error.
**Justification**: `hasDiscussionsEnabled` is repository-level data returned by the same query on every page, so the extra loop state does not serve pagination or filtering and can be removed without changing the command's intended behavior.

### C2 — Build search keywords through the qualifier slice
**File**: pkg/cmd/discussion/client/client_impl.go:348
**Change**: In `discussionClient.Search`, append `filters.Keywords` to `qualifiers` when non-empty and then compute `searchQuery` once with `strings.Join(qualifiers, " ")`, replacing the separate `searchQuery += " " + filters.Keywords` branch.
**Goal link**: This clarifies the search-query construction described by the goal as qualifiers plus keywords.
**Justification**: Treating keywords as the final query component removes a special-case string concatenation while preserving the exact search query produced for all existing inputs.

### C3 — Share state qualifier formatting for list output messages
**File**: pkg/cmd/discussion/list/list.go:276
**Change**: Add a small unexported helper in `list.go`, for example `stateQualifier(state string) string`, and use it from both `noResults` and `listHeader` instead of duplicating the same `switch state` block.
**Goal link**: This clarifies the list command's user-facing state filtering in empty-result and header output.
**Justification**: The two functions currently encode identical open/closed/all display rules, so one helper reduces accidental duplication without touching command behavior or output text.

## Rejected

- Replace `discussionListFields` with `shared.DiscussionFields` in `pkg/cmd/discussion/list/list.go`: `shared.DiscussionFields` includes `comments`, while the list command intentionally excludes fields only populated by view, so this would change `--json` validation and the command's public surface.
- Add `Body` to `discussionNode` and map it in `mapDiscussion`: the query already requests `body`, but populating `Discussion.Body` would change observable `--json body` output rather than being a behavior-preserving refactor.
- Extract one generic pagination helper for both `discussionClient.List` and `discussionClient.Search`: although both loops are similar, the response shapes and disabled-discussions check differ enough that a callback-based helper would add indirection for only two call sites.
- Move browser query qualifier construction from `openInBrowser` into the client search-query code: the browser URL intentionally omits repository and sort qualifiers while `Search` requires them, so sharing the whole builder would either change the generated URL or require a broader abstraction than this goal needs.
- Manually simplify `pkg/cmd/discussion/client/client_mock.go`: this file is generated mock-style plumbing for the interface shape, and edits there would not make the user-facing discussion list implementation express the goal more directly.
