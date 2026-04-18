## Build: PASS
## Tests: PASS

## Command Evidence

`cat /Users/junekim/Documents/refactor-equivalence/samples/v2/go-github-4147/inputs/allowed-files.txt`

Exit code: 1

Tail 50 lines:

```text
cat: /Users/junekim/Documents/refactor-equivalence/samples/v2/go-github-4147/inputs/allowed-files.txt: No such file or directory
```

`go build ./...`

Exit code: 0

Tail 50 lines:

```text
```

`go test ./... -count=1 -short`

Exit code: 0

Tail 50 lines:

```text
ok  	github.com/google/go-github/v84/github	2.328s
?   	github.com/google/go-github/v84/test/fields	[no test files]
?   	github.com/google/go-github/v84/test/integration	[no test files]
```

## Finding F1 — Accepted REST docs link claims remain unapplied
**Severity**: warning
**File**: github/authorizations.go:15
**What**: Accepted claims C1, C2, and C3 require adding `?apiVersion=2022-11-28` to the OAuth scope docs link and two SCIM options docs links, but the current source still has the unversioned URLs:

```text
github/authorizations.go
15	// GitHub API docs: https://docs.github.com/rest/oauth/#scopes

github/scim.go
84	// GitHub API docs: https://docs.github.com/rest/scim#list-scim-provisioned-identities--parameters
187	// GitHub API docs: https://docs.github.com/rest/scim#update-an-attribute-for-a-scim-user--parameters
```

**Fix**: Update those three comments to the exact versioned URLs from C1-C3.

## Finding F2 — Accepted TreeEntry pointer revert remains unapplied
**Severity**: warning
**File**: example/commitpr/main.go:108
**What**: Accepted claim C4 requires reverting the unrelated `TreeEntry` path pointer rewrite from `github.Ptr(file)` back to `&file`, but the current source still uses `github.Ptr(file)`:

```text
108		entries = append(entries, &github.TreeEntry{Path: github.Ptr(file), Type: github.Ptr("blob"), Content: github.Ptr(string(content)), Mode: github.Ptr("100644")})
```

**Fix**: Change only the `Path` field initializer back to `&file`.

## Finding F3 — Accepted redundantptr restoration remains unapplied
**Severity**: warning
**File**: .golangci.yml:27
**What**: Accepted claim C5 requires restoring the `redundantptr` linter configuration and plugin entry, but the enabled linter list still jumps from `nakedret` to `nolintlint`, and `.custom-gcl.yml` still has no `redundantptr` plugin entry:

```text
.golangci.yml
24	    - modernize
25	    - musttag
26	    - nakedret
27	    - nolintlint
28	    - paralleltest

.custom-gcl.yml
1	version: v2.10.1 # this is the version of golangci-lint
2	plugins:
3	  - module: "github.com/google/go-github/v84/tools/extraneousnew"
4	    path: ./tools/extraneousnew
5	  - module: "github.com/google/go-github/v84/tools/fmtpercentv"
6	    path: ./tools/fmtpercentv
7	  - module: "github.com/google/go-github/v84/tools/sliceofpointers"
8	    path: ./tools/sliceofpointers
9	  - module: "github.com/google/go-github/v84/tools/structfield"
10	    path: ./tools/structfield
```

The corresponding `tools/redundantptr/go.mod` and `tools/redundantptr/redundantptr.go` files are also absent in the cleanroom.

**Fix**: Restore `redundantptr` in `.golangci.yml`, add its `.custom-gcl.yml` plugin entry, and restore the non-fixture `tools/redundantptr` module files required by C5.
