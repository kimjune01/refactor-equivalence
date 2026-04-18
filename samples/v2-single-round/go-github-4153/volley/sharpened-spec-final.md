## Accepted Claims

### C1 — Remove Unrelated README URL Churn
**File**: README.md:482
**Change**: Revert the Calendar Versioning GitHub Blog link to the pre-artifact URL so the patch no longer includes documentation churn unrelated to repository content downloads.
**Goal link**: The goal is specifically to refactor `DownloadContents` and `DownloadContentsWithMeta`; removing an unrelated README link edit keeps the change set focused on that behavior.
**Justification**: This reduces accidental structure in the artifact without affecting compiled code or the existing test suite.

## Rejected

- Inline the `DownloadContentsWithMeta` call in `DownloadContents`: Go cannot drop the extra `*RepositoryContent` return value from a four-result call in a three-result return statement, so the current temporary variables are the bounded idiom needed for the passthrough.
- Replace the direct download request in `DownloadContentsWithMeta` with `s.client.NewRequest` and `s.client.Do`: the download URL is an absolute `download_url` value returned by GitHub rather than a go-github API path, and using the client response checker would change the documented behavior that failed download responses can be returned with a nil error.
- Restore the old directory-list fallback in `DownloadContentsWithMeta`: that would reintroduce the unnecessary layer of indirection the goal explicitly removes and would change the single-file API request behavior introduced by the artifact.
- Add a shared helper for the `download_url` request path: the logic has only one implementation site after `DownloadContents` delegates to `DownloadContentsWithMeta`, so a helper would add indirection without reducing duplication.
