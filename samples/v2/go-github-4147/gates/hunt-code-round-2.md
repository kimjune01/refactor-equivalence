## Build: PASS
## Tests: PASS

Command records:

```text
cat /Users/junekim/Documents/refactor-equivalence/samples/v2/go-github-4147/inputs/allowed-files.txt
exit code: 1
tail 50 lines:
cat: /Users/junekim/Documents/refactor-equivalence/samples/v2/go-github-4147/inputs/allowed-files.txt: No such file or directory
```

The required allowed-edit-set path is absent in the provided `v2/go-github-4147` artifact directory. The cleanroom contains `FORGE_ALLOWED_FILES.txt`, and the matching full artifact set exists under `/Users/junekim/Documents/refactor-equivalence/samples/v2-single-round/go-github-4147/inputs/allowed-files.txt`; I used those to check scope after the required path failed.

```text
go build ./...
exit code: 0
tail 50 lines:
<no output>
```

```text
go test ./... -count=1 -short
exit code: 0
tail 50 lines:
ok  	github.com/google/go-github/v84/github	2.407s
?   	github.com/google/go-github/v84/test/fields	[no test files]
?   	github.com/google/go-github/v84/test/integration	[no test files]
```

## Finding F1 — OAuth scope docs link remains unversioned
**Severity**: warning
**File**: github/authorizations.go:15
**What**: Accepted claim C1 was not applied. The current `Scope` comment still points at the unversioned REST docs URL, so this accepted part of the refactor is missing:

```go
// GitHub API docs: https://docs.github.com/rest/oauth/#scopes
```

**Fix**: Change the link to `https://docs.github.com/rest/oauth?apiVersion=2022-11-28#scopes`.

## Finding F2 — SCIM list options docs link remains unversioned
**Severity**: warning
**File**: github/scim.go:84
**What**: Accepted claim C2 was not applied. The current `ListSCIMProvisionedIdentitiesOptions` comment still points at the unversioned REST docs URL:

```go
// GitHub API docs: https://docs.github.com/rest/scim#list-scim-provisioned-identities--parameters
```

**Fix**: Change the link to `https://docs.github.com/rest/scim?apiVersion=2022-11-28#list-scim-provisioned-identities--parameters`.

## Finding F3 — SCIM update options docs link remains unversioned
**Severity**: warning
**File**: github/scim.go:187
**What**: Accepted claim C3 was not applied. The current `UpdateAttributeForSCIMUserOptions` comment still points at the unversioned REST docs URL:

```go
// GitHub API docs: https://docs.github.com/rest/scim#update-an-attribute-for-a-scim-user--parameters
```

**Fix**: Change the link to `https://docs.github.com/rest/scim?apiVersion=2022-11-28#update-an-attribute-for-a-scim-user--parameters`.

## Finding F4 — Unrelated TreeEntry pointer rewrite was not reverted
**Severity**: warning
**File**: example/commitpr/main.go:108
**What**: Accepted claim C4 was not applied. The merged tree still contains the off-goal pointer construction rewrite instead of restoring the original local address expression:

```go
entries = append(entries, &github.TreeEntry{Path: github.Ptr(file), Type: github.Ptr("blob"), Content: github.Ptr(string(content)), Mode: github.Ptr("100644")})
```

**Fix**: Restore `Path: &file` for this `TreeEntry` literal.

## Finding F5 — redundantptr linter restoration was not applied
**Severity**: warning
**File**: .golangci.yml:29
**What**: Accepted claim C5 was not applied. The current enabled linter list skips directly from `perfsprint` to `revive`, so `redundantptr` remains removed:

```yaml
    - perfsprint
    - revive
```

The custom linter settings also still skip directly from `fmtpercentv` to `sliceofpointers`, so the `redundantptr` module settings remain absent:

```yaml
      fmtpercentv:
        type: module
        description: Reports usage of %d or %s in format strings.
        original-url: github.com/google/go-github/v84/tools/fmtpercentv
      sliceofpointers:
```

The custom plugin list likewise still omits the `redundantptr` module:

```yaml
  - module: "github.com/google/go-github/v84/tools/fmtpercentv"
    path: ./tools/fmtpercentv
  - module: "github.com/google/go-github/v84/tools/sliceofpointers"
    path: ./tools/sliceofpointers
```

**Fix**: Re-add `redundantptr` to `.golangci.yml`, re-add its `.custom-gcl.yml` plugin entry, and restore `tools/redundantptr/go.mod` plus `tools/redundantptr/redundantptr.go` as specified by C5.
