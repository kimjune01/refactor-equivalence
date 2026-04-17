# PR #13084 — Add `discussion list` command

## PR body

## Summary

Implements `gh discussion list` — the first user-facing command in the discussion group (PR 2 of 11).

### Features

- **Listing:** `repository.discussions` GraphQL query with state, category, answered, sort, and order filters
- **Search:** Falls back to `search(type: DISCUSSION)` when `--author`, `--label`, or `--search` are provided (same dual-path pattern as `gh issue list`)
- **Pagination:** `--after` cursor flag for paginating through results; `next` cursor in JSON output envelope
- **Category resolution:** Matches `--category` by slug first, then name (case-insensitive). Errors with sorted available slugs on mismatch. Lives in `shared/` for reuse by other commands.
- **TTY output:** Colored table with ID, TITLE, CATEGORY, LABELS, ANSWERED (✓), UPDATED columns
- **Non-TTY output:** Tab-separated with STATE as second field
- **JSON output:** Envelope `{"totalCount": N, "discussions": [...], "next": "<cursor>"}` with `--jq` and `--template` support
- **Web mode:** `--web` opens discussions in browser, populates search box when filters are present
- **Preview annotations:** Top-level `discussion` and `list` commands marked as `(preview)`

### Flags

```
  -A, --author string     Filter by author
  -c, --category string   Filter by category name or slug
  -l, --label strings     Filter by label
  -L, --limit int         Maximum number of discussions to fetch (default 30)
  -s, --state string      Filter by state: {open|closed|all} (default "open")
  -S, --search string     Search discussions with query
      --answered           Filter to answered discussions only
      --sort string        Sort by field: {created|updated} (default "updated")
      --order string       Order of results: {asc|desc} (default "desc")
      --after string       Cursor for the next page of results
  -w, --web               Open in browser
      --json fields        Output JSON with specified fields
  -q, --jq expression     Filter JSON output
  -t, --template string   Format JSON output
```

### Client implementation

Implements `List`, `Search`, and `ListCategories` on the `DiscussionClient`:
- `List` and `Search` accept `after` cursor param and return `DiscussionListResult` (discussions + total count + next cursor)
- Guard clauses for `limit <= 0`
- Domain-level consts for state (`FilterStateOpen`/`FilterStateClosed`), order-by (`OrderByCreated`/`OrderByUpdated`), and direction (`OrderDirectionAsc`/`OrderDirectionDesc`)
- `switch` statements with `default` error clauses for all enum mappings (no `strings.ToUpper`)
- Search uses qualifier/keyword terminology with `%q` quoting for whitespace safety
- `ListCategories` checks `hasDiscussionsEnabled` and returns a clear error for repos with discussions disabled
- Private API response types with json tags, mapped field-by-field to domain types

### Tests

17 test cases covering TTY/non-TTY/JSON output (including `next` cursor), web mode, empty results, category resolution, category not found, author filter, label filter, search filter, after cursor, closed state, `toFilterState` helper, and flag parsing (including `--sort`, `--order`, `--search`, `--after`, and invalid values).

### What's next

PR 3: `discussion view` (without comments)

Refs: https://github.com/cli/cli/issues/12810,

## Linked issues
(none)
