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
ok  	github.com/google/go-containerregistry/cmd/crane	0.299s
?   	github.com/google/go-containerregistry/cmd/crane/cmd	[no test files]
?   	github.com/google/go-containerregistry/cmd/crane/help	[no test files]
ok  	github.com/google/go-containerregistry/cmd/gcrane	0.517s
?   	github.com/google/go-containerregistry/cmd/gcrane/cmd	[no test files]
?   	github.com/google/go-containerregistry/cmd/registry	[no test files]
ok  	github.com/google/go-containerregistry/internal/and	2.532s
ok  	github.com/google/go-containerregistry/internal/cmd	1.009s
ok  	github.com/google/go-containerregistry/internal/compression	1.298s
?   	github.com/google/go-containerregistry/internal/depcheck	[no test files]
?   	github.com/google/go-containerregistry/internal/editor	[no test files]
ok  	github.com/google/go-containerregistry/internal/estargz	0.917s
ok  	github.com/google/go-containerregistry/internal/gzip	2.913s
?   	github.com/google/go-containerregistry/internal/httptest	[no test files]
?   	github.com/google/go-containerregistry/internal/redact	[no test files]
ok  	github.com/google/go-containerregistry/internal/retry	2.129s
?   	github.com/google/go-containerregistry/internal/retry/wait	[no test files]
ok  	github.com/google/go-containerregistry/internal/verify	1.099s
ok  	github.com/google/go-containerregistry/internal/windows	1.932s
ok  	github.com/google/go-containerregistry/internal/zstd	2.718s
ok  	github.com/google/go-containerregistry/pkg/authn	2.347s
ok  	github.com/google/go-containerregistry/pkg/authn/github	1.515s
?   	github.com/google/go-containerregistry/pkg/compression	[no test files]
ok  	github.com/google/go-containerregistry/pkg/crane	2.648s
ok  	github.com/google/go-containerregistry/pkg/gcrane	3.201s
?   	github.com/google/go-containerregistry/pkg/legacy	[no test files]
ok  	github.com/google/go-containerregistry/pkg/legacy/tarball	2.900s
?   	github.com/google/go-containerregistry/pkg/logs	[no test files]
ok  	github.com/google/go-containerregistry/pkg/name	2.612s
ok  	github.com/google/go-containerregistry/pkg/registry	2.825s
ok  	github.com/google/go-containerregistry/pkg/v1	2.861s
ok  	github.com/google/go-containerregistry/pkg/v1/cache	2.918s
ok  	github.com/google/go-containerregistry/pkg/v1/compare	2.872s
ok  	github.com/google/go-containerregistry/pkg/v1/daemon	2.695s
ok  	github.com/google/go-containerregistry/pkg/v1/empty	2.679s
?   	github.com/google/go-containerregistry/pkg/v1/fake	[no test files]
ok  	github.com/google/go-containerregistry/pkg/v1/google	2.886s
ok  	github.com/google/go-containerregistry/pkg/v1/layout	2.742s
ok  	github.com/google/go-containerregistry/pkg/v1/match	2.778s
ok  	github.com/google/go-containerregistry/pkg/v1/mutate	2.972s
ok  	github.com/google/go-containerregistry/pkg/v1/partial	2.987s
ok  	github.com/google/go-containerregistry/pkg/v1/random	2.668s
ok  	github.com/google/go-containerregistry/pkg/v1/remote	7.589s
ok  	github.com/google/go-containerregistry/pkg/v1/remote/internal/authchallenge	2.941s
ok  	github.com/google/go-containerregistry/pkg/v1/remote/transport	2.929s
ok  	github.com/google/go-containerregistry/pkg/v1/static	2.940s
ok  	github.com/google/go-containerregistry/pkg/v1/stream	2.921s
ok  	github.com/google/go-containerregistry/pkg/v1/tarball	2.982s
ok  	github.com/google/go-containerregistry/pkg/v1/types	2.875s
?   	github.com/google/go-containerregistry/pkg/v1/validate	[no test files]
```

## Finding F1 — Custom headers can override the default User-Agent
**Severity**: warning
**File**: vendor/github.com/moby/moby/client/request.go:320
**What**: `WithHTTPHeaders` says custom headers cannot override built-in headers such as `User-Agent`, and `clientConfig.userAgent` says `userAgent` takes precedence over `customHTTPHeaders`. But when no explicit `WithUserAgent` option is set, `addHeaders` first writes all custom headers, then only installs the default User-Agent if the request does not already have one. A caller can therefore pass `WithHTTPHeaders(map[string]string{"User-Agent": "x"})` and suppress the new default `moby-client/<version> os/arch` User-Agent, contrary to the current API contract.

Evidence from the current files:

```go
    37	// userAgent is the User-Agent header to use for HTTP requests. It takes
    38	// precedence over User-Agent headers set in customHTTPHeaders, and other
    39	// header variables. When set to an empty string, the User-Agent header
    40	// is removed, and no header is sent.
```

```go
   197	// WithHTTPHeaders appends custom HTTP headers to the client's default headers.
   198	// It does not allow overriding built-in headers (such as "User-Agent").
   199	// Also see [WithUserAgent].
```

```go
   312	for k, v := range cli.customHTTPHeaders {
   313		req.Header.Set(k, v)
   314	}
```

```go
   320	if cli.userAgent == nil {
   321		// No custom User-Agent set: use the default.
   322		if req.Header.Get("User-Agent") == "" {
   323			req.Header.Set("User-Agent", defaultUserAgent())
   324		}
```

**Fix**: Treat `User-Agent` as reserved in `WithHTTPHeaders`, or always set the default User-Agent after applying custom headers when `cli.userAgent == nil`, so built-in headers consistently win over `customHTTPHeaders`.
