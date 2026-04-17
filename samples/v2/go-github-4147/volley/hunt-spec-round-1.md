## Finding F1 — Spec misses in-scope unversioned REST docs links
**Severity**: warning
**Claim**: global
**What**: The accepted claims say they close remaining unversioned REST docs links, but allowed non-test source still contains unversioned `docs.github.com/rest` links outside C1-C3. Following the spec as written would leave the stated goal incomplete, or force the implementer to guess whether these links are intentionally out of scope.
**Evidence**: `github/issues.go:68` has `https://docs.github.com/rest/search/#text-match-metadata`; `github/github.go:139` has `https://docs.github.com/rest/previews/#repository-creation-permissions`; `github/github.go:142` has `https://docs.github.com/rest/previews/#create-and-use-repository-templates`. Both `github/issues.go` and `github/github.go` are in `allowed-files.txt:84` and `allowed-files.txt:79`.
**Fix**: Clarify the scope boundary for these `/rest` links explicitly: either include them in the versioning work, or reject them with a concrete rationale that distinguishes them from C1-C3.

## Finding F2 — redundantptr testdata rejection conflicts with the restore claim
**Severity**: warning
**Claim**: C5
**What**: C5 says to restore `redundantptr` as existing linter tooling, but the rejected section forbids restoring the linter's deleted `testdata` files on the grounds that they are test files. The task's scope rule forbids `*.test.{ts,tsx,py,go,rs}` files, not arbitrary Go files under `testdata`, and these two paths are explicitly present in the allowed edit set. This makes the intended restoration boundary ambiguous: either restore the linter package only, or restore the linter tooling as it existed before the draft.
**Evidence**: `round-1-claims.md:29` requests restoring the `redundantptr` linter module files; `round-1-claims.md:36` rejects `tools/redundantptr/testdata/src/has-warnings/github.go` and `tools/redundantptr/testdata/src/no-warnings/github.go` because they are testdata. The artifact deletes those files, and `allowed-files.txt:185` and `allowed-files.txt:186` explicitly allow them.
**Fix**: Clarify whether C5 intentionally restores only the buildable linter plugin and excludes fixtures, or restore the full deleted linter tooling; do not justify the exclusion as a forbidden test-file edit unless the task's scope rule is tightened.
