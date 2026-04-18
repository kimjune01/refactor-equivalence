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
ok  	github.com/google/go-containerregistry/cmd/crane	0.325s
?   	github.com/google/go-containerregistry/cmd/crane/cmd	[no test files]
?   	github.com/google/go-containerregistry/cmd/crane/help	[no test files]
ok  	github.com/google/go-containerregistry/cmd/gcrane	0.392s
?   	github.com/google/go-containerregistry/cmd/gcrane/cmd	[no test files]
?   	github.com/google/go-containerregistry/cmd/registry	[no test files]
ok  	github.com/google/go-containerregistry/internal/and	0.575s
ok  	github.com/google/go-containerregistry/internal/cmd	1.280s
ok  	github.com/google/go-containerregistry/internal/compression	1.586s
?   	github.com/google/go-containerregistry/internal/depcheck	[no test files]
?   	github.com/google/go-containerregistry/internal/editor	[no test files]
ok  	github.com/google/go-containerregistry/internal/estargz	0.777s
ok  	github.com/google/go-containerregistry/internal/gzip	1.379s
?   	github.com/google/go-containerregistry/internal/httptest	[no test files]
?   	github.com/google/go-containerregistry/internal/redact	[no test files]
ok  	github.com/google/go-containerregistry/internal/retry	1.195s
?   	github.com/google/go-containerregistry/internal/retry/wait	[no test files]
ok  	github.com/google/go-containerregistry/internal/verify	1.766s
ok  	github.com/google/go-containerregistry/internal/windows	1.958s
ok  	github.com/google/go-containerregistry/internal/zstd	2.137s
ok  	github.com/google/go-containerregistry/pkg/authn	2.343s
ok  	github.com/google/go-containerregistry/pkg/authn/github	2.594s
?   	github.com/google/go-containerregistry/pkg/compression	[no test files]
ok  	github.com/google/go-containerregistry/pkg/crane	3.779s
ok  	github.com/google/go-containerregistry/pkg/gcrane	3.272s
?   	github.com/google/go-containerregistry/pkg/legacy	[no test files]
ok  	github.com/google/go-containerregistry/pkg/legacy/tarball	2.991s
?   	github.com/google/go-containerregistry/pkg/logs	[no test files]
ok  	github.com/google/go-containerregistry/pkg/name	2.917s
ok  	github.com/google/go-containerregistry/pkg/registry	3.001s
ok  	github.com/google/go-containerregistry/pkg/v1	2.730s
ok  	github.com/google/go-containerregistry/pkg/v1/cache	2.884s
ok  	github.com/google/go-containerregistry/pkg/v1/compare	2.958s
ok  	github.com/google/go-containerregistry/pkg/v1/daemon	2.984s
ok  	github.com/google/go-containerregistry/pkg/v1/empty	2.975s
?   	github.com/google/go-containerregistry/pkg/v1/fake	[no test files]
ok  	github.com/google/go-containerregistry/pkg/v1/google	3.199s
ok  	github.com/google/go-containerregistry/pkg/v1/layout	3.057s
ok  	github.com/google/go-containerregistry/pkg/v1/match	2.994s
ok  	github.com/google/go-containerregistry/pkg/v1/mutate	2.999s
ok  	github.com/google/go-containerregistry/pkg/v1/partial	2.452s
ok  	github.com/google/go-containerregistry/pkg/v1/random	2.611s
ok  	github.com/google/go-containerregistry/pkg/v1/remote	7.368s
ok  	github.com/google/go-containerregistry/pkg/v1/remote/internal/authchallenge	2.712s
ok  	github.com/google/go-containerregistry/pkg/v1/remote/transport	2.958s
ok  	github.com/google/go-containerregistry/pkg/v1/static	2.992s
ok  	github.com/google/go-containerregistry/pkg/v1/stream	2.992s
ok  	github.com/google/go-containerregistry/pkg/v1/tarball	3.048s
ok  	github.com/google/go-containerregistry/pkg/v1/types	2.934s
?   	github.com/google/go-containerregistry/pkg/v1/validate	[no test files]
```

## Finding F1 — Custom headers can override the default User-Agent
**Severity**: warning
**File**: vendor/github.com/moby/moby/client/request.go:320
**What**: `WithHTTPHeaders` now documents that custom HTTP headers cannot override built-in headers such as `User-Agent`, and `clientConfig.userAgent` documents that `userAgent` takes precedence over `customHTTPHeaders`. The implementation contradicts that API shape when no explicit `WithUserAgent` option is set: it writes all custom headers first, then only sets the default User-Agent if the request does not already have one. A caller can therefore pass `WithHTTPHeaders(map[string]string{"User-Agent": "x"})` and suppress the default `moby-client/<version> os/arch` User-Agent despite the new contract.

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

**Fix**: Either reject or ignore `User-Agent` in `WithHTTPHeaders`, or always set the default User-Agent after applying custom headers when `cli.userAgent == nil`, so the built-in header consistently wins over `customHTTPHeaders`.
