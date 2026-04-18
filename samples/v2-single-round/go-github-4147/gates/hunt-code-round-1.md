## Build: PASS
Exit code: 0
Tail 50 lines:

```text
(no output)
```

## Tests: PASS
Exit code: 0
Tail 50 lines:

```text
ok  	github.com/google/go-github/v84/github	2.547s
?   	github.com/google/go-github/v84/test/fields	[no test files]
?   	github.com/google/go-github/v84/test/integration	[no test files]
```

## Finding F1 — Accepted OAuth scope docs-link claim is not applied
**Severity**: warning
**File**: github/authorizations.go:15
**What**: Accepted claim C1 requires the `Scope` comment to use `https://docs.github.com/rest/oauth?apiVersion=2022-11-28#scopes`, but the current file still has the unversioned URL:

```go
// GitHub API docs: https://docs.github.com/rest/oauth/#scopes
```

**Fix**: Change that comment URL to include `?apiVersion=2022-11-28` before the `#scopes` fragment.

## Finding F2 — Accepted SCIM options docs-link claims are not applied
**Severity**: warning
**File**: github/scim.go:84
**What**: Accepted claim C2 requires `ListSCIMProvisionedIdentitiesOptions` to use `https://docs.github.com/rest/scim?apiVersion=2022-11-28#list-scim-provisioned-identities--parameters`, but the current file still has the unversioned URL:

```go
// GitHub API docs: https://docs.github.com/rest/scim#list-scim-provisioned-identities--parameters
```

The same issue exists for accepted claim C3 at `github/scim.go:187`, where the current file still has the unversioned URL:

```go
// GitHub API docs: https://docs.github.com/rest/scim#update-an-attribute-for-a-scim-user--parameters
```

**Fix**: Add `?apiVersion=2022-11-28` to both SCIM docs-comment URLs before their fragments.

## Finding F3 — Accepted revert of the TreeEntry path pointer rewrite is not applied
**Severity**: warning
**File**: example/commitpr/main.go:108
**What**: Accepted claim C4 requires the unrelated `TreeEntry` path pointer rewrite to be reverted to `Path: &file`, but the current file still uses `github.Ptr(file)`:

```go
entries = append(entries, &github.TreeEntry{Path: github.Ptr(file), Type: github.Ptr("blob"), Content: github.Ptr(string(content)), Mode: github.Ptr("100644")})
```

**Fix**: Change the `Path` field back to `Path: &file`.

## Finding F4 — Accepted redundantptr linter restoration is not applied
**Severity**: warning
**File**: .golangci.yml:27
**What**: Accepted claim C5 requires restoring `redundantptr` in the enabled linter list and custom linter settings, plus the buildable `tools/redundantptr` module files. The current enabled-linter list still skips directly from `perfsprint` to `revive`, with no `redundantptr` entry:

```yaml
    - perfsprint
    - revive
```

The current custom-linter settings still skip directly from `fmtpercentv` to `sliceofpointers`, with no `redundantptr` settings:

```yaml
      fmtpercentv:
        type: module
        description: Reports usage of %d or %s in format strings.
        original-url: github.com/google/go-github/v84/tools/fmtpercentv
      sliceofpointers:
```

`tools/redundantptr` is also absent from the current tree.

**Fix**: Restore the `redundantptr` linter entries in `.golangci.yml` and `.custom-gcl.yml`, and restore `tools/redundantptr/go.mod` and `tools/redundantptr/redundantptr.go` as specified by C5.
