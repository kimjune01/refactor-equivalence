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
ok  	github.com/google/go-containerregistry/cmd/crane	0.250s
?   	github.com/google/go-containerregistry/cmd/crane/cmd	[no test files]
?   	github.com/google/go-containerregistry/cmd/crane/help	[no test files]
ok  	github.com/google/go-containerregistry/cmd/gcrane	0.360s
?   	github.com/google/go-containerregistry/cmd/gcrane/cmd	[no test files]
?   	github.com/google/go-containerregistry/cmd/registry	[no test files]
ok  	github.com/google/go-containerregistry/internal/and	0.451s
ok  	github.com/google/go-containerregistry/internal/cmd	0.856s
ok  	github.com/google/go-containerregistry/internal/compression	0.698s
?   	github.com/google/go-containerregistry/internal/depcheck	[no test files]
?   	github.com/google/go-containerregistry/internal/editor	[no test files]
ok  	github.com/google/go-containerregistry/internal/estargz	0.821s
ok  	github.com/google/go-containerregistry/internal/gzip	0.923s
?   	github.com/google/go-containerregistry/internal/httptest	[no test files]
?   	github.com/google/go-containerregistry/internal/redact	[no test files]
ok  	github.com/google/go-containerregistry/internal/retry	1.039s
?   	github.com/google/go-containerregistry/internal/retry/wait	[no test files]
ok  	github.com/google/go-containerregistry/internal/verify	1.138s
ok  	github.com/google/go-containerregistry/internal/windows	1.240s
ok  	github.com/google/go-containerregistry/internal/zstd	1.341s
ok  	github.com/google/go-containerregistry/pkg/authn	1.465s
ok  	github.com/google/go-containerregistry/pkg/authn/github	1.553s
?   	github.com/google/go-containerregistry/pkg/compression	[no test files]
ok  	github.com/google/go-containerregistry/pkg/crane	2.683s
ok  	github.com/google/go-containerregistry/pkg/gcrane	2.073s
?   	github.com/google/go-containerregistry/pkg/legacy	[no test files]
ok  	github.com/google/go-containerregistry/pkg/legacy/tarball	1.802s
?   	github.com/google/go-containerregistry/pkg/logs	[no test files]
ok  	github.com/google/go-containerregistry/pkg/name	1.737s
ok  	github.com/google/go-containerregistry/pkg/registry	1.700s
ok  	github.com/google/go-containerregistry/pkg/v1	1.655s
ok  	github.com/google/go-containerregistry/pkg/v1/cache	1.784s
ok  	github.com/google/go-containerregistry/pkg/v1/compare	1.814s
ok  	github.com/google/go-containerregistry/pkg/v1/daemon	1.846s
ok  	github.com/google/go-containerregistry/pkg/v1/empty	1.845s
?   	github.com/google/go-containerregistry/pkg/v1/fake	[no test files]
ok  	github.com/google/go-containerregistry/pkg/v1/google	2.073s
ok  	github.com/google/go-containerregistry/pkg/v1/layout	1.943s
ok  	github.com/google/go-containerregistry/pkg/v1/match	1.889s
ok  	github.com/google/go-containerregistry/pkg/v1/mutate	1.964s
ok  	github.com/google/go-containerregistry/pkg/v1/partial	1.573s
ok  	github.com/google/go-containerregistry/pkg/v1/random	1.649s
ok  	github.com/google/go-containerregistry/pkg/v1/remote	6.336s
ok  	github.com/google/go-containerregistry/pkg/v1/remote/internal/authchallenge	1.681s
ok  	github.com/google/go-containerregistry/pkg/v1/remote/transport	1.804s
ok  	github.com/google/go-containerregistry/pkg/v1/static	1.701s
ok  	github.com/google/go-containerregistry/pkg/v1/stream	1.740s
ok  	github.com/google/go-containerregistry/pkg/v1/tarball	1.892s
ok  	github.com/google/go-containerregistry/pkg/v1/types	1.795s
?   	github.com/google/go-containerregistry/pkg/v1/validate	[no test files]
```

## Finding F1 — Custom headers can override the default User-Agent
**Severity**: warning
**File**: vendor/github.com/moby/moby/client/request.go:320
**What**: `WithHTTPHeaders` says custom headers cannot override built-in headers such as `User-Agent`, and `clientConfig.userAgent` says `userAgent` takes precedence over `customHTTPHeaders`. But when no explicit `WithUserAgent` option is set, `addHeaders` first writes all custom headers, then only installs the default User-Agent if the request does not already have one. A caller can therefore pass `WithHTTPHeaders(map[string]string{"User-Agent": "x"})` and suppress the default `moby-client/<version> os/arch` User-Agent, contrary to the current API contract.

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
