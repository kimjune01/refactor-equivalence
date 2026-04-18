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
ok  	github.com/google/go-containerregistry/cmd/crane	0.207s
?   	github.com/google/go-containerregistry/cmd/crane/cmd	[no test files]
?   	github.com/google/go-containerregistry/cmd/crane/help	[no test files]
ok  	github.com/google/go-containerregistry/cmd/gcrane	0.347s
?   	github.com/google/go-containerregistry/cmd/gcrane/cmd	[no test files]
?   	github.com/google/go-containerregistry/cmd/registry	[no test files]
ok  	github.com/google/go-containerregistry/internal/and	0.445s
ok  	github.com/google/go-containerregistry/internal/cmd	0.846s
ok  	github.com/google/go-containerregistry/internal/compression	0.676s
?   	github.com/google/go-containerregistry/internal/depcheck	[no test files]
?   	github.com/google/go-containerregistry/internal/editor	[no test files]
ok  	github.com/google/go-containerregistry/internal/estargz	0.788s
ok  	github.com/google/go-containerregistry/internal/gzip	0.896s
?   	github.com/google/go-containerregistry/internal/httptest	[no test files]
?   	github.com/google/go-containerregistry/internal/redact	[no test files]
ok  	github.com/google/go-containerregistry/internal/retry	1.011s
?   	github.com/google/go-containerregistry/internal/retry/wait	[no test files]
ok  	github.com/google/go-containerregistry/internal/verify	1.094s
ok  	github.com/google/go-containerregistry/internal/windows	1.197s
ok  	github.com/google/go-containerregistry/internal/zstd	1.303s
ok  	github.com/google/go-containerregistry/pkg/authn	1.425s
ok  	github.com/google/go-containerregistry/pkg/authn/github	1.525s
?   	github.com/google/go-containerregistry/pkg/compression	[no test files]
ok  	github.com/google/go-containerregistry/pkg/crane	2.651s
ok  	github.com/google/go-containerregistry/pkg/gcrane	2.075s
?   	github.com/google/go-containerregistry/pkg/legacy	[no test files]
ok  	github.com/google/go-containerregistry/pkg/legacy/tarball	1.805s
?   	github.com/google/go-containerregistry/pkg/logs	[no test files]
ok  	github.com/google/go-containerregistry/pkg/name	1.742s
ok  	github.com/google/go-containerregistry/pkg/registry	1.708s
ok  	github.com/google/go-containerregistry/pkg/v1	1.664s
ok  	github.com/google/go-containerregistry/pkg/v1/cache	1.782s
ok  	github.com/google/go-containerregistry/pkg/v1/compare	1.816s
ok  	github.com/google/go-containerregistry/pkg/v1/daemon	1.852s
ok  	github.com/google/go-containerregistry/pkg/v1/empty	1.859s
?   	github.com/google/go-containerregistry/pkg/v1/fake	[no test files]
ok  	github.com/google/go-containerregistry/pkg/v1/google	2.082s
ok  	github.com/google/go-containerregistry/pkg/v1/layout	1.951s
ok  	github.com/google/go-containerregistry/pkg/v1/match	1.899s
ok  	github.com/google/go-containerregistry/pkg/v1/mutate	1.973s
ok  	github.com/google/go-containerregistry/pkg/v1/partial	1.576s
ok  	github.com/google/go-containerregistry/pkg/v1/random	1.651s
ok  	github.com/google/go-containerregistry/pkg/v1/remote	6.340s
ok  	github.com/google/go-containerregistry/pkg/v1/remote/internal/authchallenge	1.681s
ok  	github.com/google/go-containerregistry/pkg/v1/remote/transport	1.810s
ok  	github.com/google/go-containerregistry/pkg/v1/static	1.709s
ok  	github.com/google/go-containerregistry/pkg/v1/stream	1.750s
ok  	github.com/google/go-containerregistry/pkg/v1/tarball	1.814s
ok  	github.com/google/go-containerregistry/pkg/v1/types	1.753s
?   	github.com/google/go-containerregistry/pkg/v1/validate	[no test files]
```

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
