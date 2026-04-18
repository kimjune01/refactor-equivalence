## Build: PASS
`go build ./...` exit code: 0

Tail 50 lines:

```text
<no output>
```

## Tests: PASS
`go test ./... -count=1 -short` exit code: 0

Tail 50 lines:

```text
ok  	github.com/google/go-containerregistry/cmd/crane	0.952s
?   	github.com/google/go-containerregistry/cmd/crane/cmd	[no test files]
?   	github.com/google/go-containerregistry/cmd/crane/help	[no test files]
ok  	github.com/google/go-containerregistry/cmd/gcrane	2.386s
?   	github.com/google/go-containerregistry/cmd/gcrane/cmd	[no test files]
?   	github.com/google/go-containerregistry/cmd/registry	[no test files]
ok  	github.com/google/go-containerregistry/internal/and	0.286s
ok  	github.com/google/go-containerregistry/internal/cmd	0.986s
ok  	github.com/google/go-containerregistry/internal/compression	1.144s
?   	github.com/google/go-containerregistry/internal/depcheck	[no test files]
?   	github.com/google/go-containerregistry/internal/editor	[no test files]
ok  	github.com/google/go-containerregistry/internal/estargz	1.358s
ok  	github.com/google/go-containerregistry/internal/gzip	1.544s
?   	github.com/google/go-containerregistry/internal/httptest	[no test files]
?   	github.com/google/go-containerregistry/internal/redact	[no test files]
ok  	github.com/google/go-containerregistry/internal/retry	1.747s
?   	github.com/google/go-containerregistry/internal/retry/wait	[no test files]
ok  	github.com/google/go-containerregistry/internal/verify	2.138s
ok  	github.com/google/go-containerregistry/internal/windows	0.483s
ok  	github.com/google/go-containerregistry/internal/zstd	1.935s
ok  	github.com/google/go-containerregistry/pkg/authn	2.873s
ok  	github.com/google/go-containerregistry/pkg/authn/github	3.046s
?   	github.com/google/go-containerregistry/pkg/compression	[no test files]
ok  	github.com/google/go-containerregistry/pkg/crane	4.247s
ok  	github.com/google/go-containerregistry/pkg/gcrane	3.540s
?   	github.com/google/go-containerregistry/pkg/legacy	[no test files]
ok  	github.com/google/go-containerregistry/pkg/legacy/tarball	3.308s
?   	github.com/google/go-containerregistry/pkg/logs	[no test files]
ok  	github.com/google/go-containerregistry/pkg/name	2.953s
ok  	github.com/google/go-containerregistry/pkg/registry	3.208s
ok  	github.com/google/go-containerregistry/pkg/v1	3.196s
ok  	github.com/google/go-containerregistry/pkg/v1/cache	3.223s
ok  	github.com/google/go-containerregistry/pkg/v1/compare	3.219s
ok  	github.com/google/go-containerregistry/pkg/v1/daemon	3.250s
ok  	github.com/google/go-containerregistry/pkg/v1/empty	3.261s
?   	github.com/google/go-containerregistry/pkg/v1/fake	[no test files]
ok  	github.com/google/go-containerregistry/pkg/v1/google	3.501s
ok  	github.com/google/go-containerregistry/pkg/v1/layout	3.286s
ok  	github.com/google/go-containerregistry/pkg/v1/match	2.954s
ok  	github.com/google/go-containerregistry/pkg/v1/mutate	3.046s
ok  	github.com/google/go-containerregistry/pkg/v1/partial	2.517s
ok  	github.com/google/go-containerregistry/pkg/v1/random	2.673s
ok  	github.com/google/go-containerregistry/pkg/v1/remote	7.477s
ok  	github.com/google/go-containerregistry/pkg/v1/remote/internal/authchallenge	2.689s
ok  	github.com/google/go-containerregistry/pkg/v1/remote/transport	2.938s
ok  	github.com/google/go-containerregistry/pkg/v1/static	2.986s
ok  	github.com/google/go-containerregistry/pkg/v1/stream	2.982s
ok  	github.com/google/go-containerregistry/pkg/v1/tarball	3.032s
ok  	github.com/google/go-containerregistry/pkg/v1/types	2.931s
?   	github.com/google/go-containerregistry/pkg/v1/validate	[no test files]
```

Note: the exact requested allowed-file command failed because `/Users/junekim/Documents/refactor-equivalence/samples/v2/go-containerregistry-2254/inputs/allowed-files.txt` is not present in this checkout. I used the cleanroom-local `FORGE_ALLOWED_FILES.txt`, which lists the files changed by the vendored dependency bump.

## Finding F1 — Custom headers can still override the default User-Agent
**Severity**: warning
**File**: vendor/github.com/moby/moby/client/request.go:320
**What**: `WithHTTPHeaders` now documents that custom HTTP headers cannot override built-in headers such as `User-Agent`, and `clientConfig.userAgent` documents that `userAgent` takes precedence over `customHTTPHeaders`. The implementation still applies custom headers first and only writes the default `User-Agent` when no `User-Agent` is already present. A caller can pass `WithHTTPHeaders(map[string]string{"User-Agent": "x"})` without `WithUserAgent`, and the request keeps `"x"` instead of the built-in `moby-client/<version> os/arch` default.

Evidence from the current files:

```go
    37		// userAgent is the User-Agent header to use for HTTP requests. It takes
    38		// precedence over User-Agent headers set in customHTTPHeaders, and other
    39		// header variables. When set to an empty string, the User-Agent header
```

```go
   197	// WithHTTPHeaders appends custom HTTP headers to the client's default headers.
   198	// It does not allow overriding built-in headers (such as "User-Agent").
   199	// Also see [WithUserAgent].
```

```go
   312		for k, v := range cli.customHTTPHeaders {
   313			req.Header.Set(k, v)
   314		}
```

```go
   320		if cli.userAgent == nil {
   321			// No custom User-Agent set: use the default.
   322			if req.Header.Get("User-Agent") == "" {
   323				req.Header.Set("User-Agent", defaultUserAgent())
   324			}
```

**Fix**: Reject or ignore `User-Agent` in `WithHTTPHeaders`, or always set the default `User-Agent` after applying custom headers when `cli.userAgent == nil`, so the built-in header consistently wins over `customHTTPHeaders`.
