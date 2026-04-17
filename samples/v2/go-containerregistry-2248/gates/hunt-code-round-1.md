## Build: PASS
## Tests: PASS
No findings.

## Command Evidence

`cat /Users/junekim/Documents/refactor-equivalence/samples/v2/go-containerregistry-2248/inputs/allowed-files.txt`

Exit code: 0

Tail:

```text
cmd/krane/go.mod
go.mod
go.sum
pkg/authn/k8schain/go.mod
pkg/v1/remote/internal/authchallenge/authchallenge.go
pkg/v1/remote/transport/bearer.go
pkg/v1/remote/transport/ping.go
vendor/github.com/docker/distribution/LICENSE
vendor/github.com/docker/distribution/registry/client/auth/challenge/addr.go
vendor/modules.txt
```

`go build ./...`

Exit code: 0

Tail:

```text
```

`go test ./... -count=1 -short`

Exit code: 0

Tail:

```text
ok  	github.com/google/go-containerregistry/cmd/crane	0.350s
?   	github.com/google/go-containerregistry/cmd/crane/cmd	[no test files]
?   	github.com/google/go-containerregistry/cmd/crane/help	[no test files]
ok  	github.com/google/go-containerregistry/cmd/gcrane	0.564s
?   	github.com/google/go-containerregistry/cmd/gcrane/cmd	[no test files]
?   	github.com/google/go-containerregistry/cmd/registry	[no test files]
ok  	github.com/google/go-containerregistry/internal/and	1.120s
ok  	github.com/google/go-containerregistry/internal/cmd	1.587s
ok  	github.com/google/go-containerregistry/internal/compression	0.933s
?   	github.com/google/go-containerregistry/internal/depcheck	[no test files]
?   	github.com/google/go-containerregistry/internal/editor	[no test files]
ok  	github.com/google/go-containerregistry/internal/estargz	0.749s
ok  	github.com/google/go-containerregistry/internal/gzip	2.712s
?   	github.com/google/go-containerregistry/internal/httptest	[no test files]
?   	github.com/google/go-containerregistry/internal/redact	[no test files]
ok  	github.com/google/go-containerregistry/internal/retry	1.531s
?   	github.com/google/go-containerregistry/internal/retry/wait	[no test files]
ok  	github.com/google/go-containerregistry/internal/verify	1.727s
ok  	github.com/google/go-containerregistry/internal/windows	2.329s
ok  	github.com/google/go-containerregistry/internal/zstd	1.947s
ok  	github.com/google/go-containerregistry/pkg/authn	2.539s
ok  	github.com/google/go-containerregistry/pkg/authn/github	2.134s
?   	github.com/google/go-containerregistry/pkg/compression	[no test files]
ok  	github.com/google/go-containerregistry/pkg/crane	3.725s
ok  	github.com/google/go-containerregistry/pkg/gcrane	3.113s
?   	github.com/google/go-containerregistry/pkg/legacy	[no test files]
ok  	github.com/google/go-containerregistry/pkg/legacy/tarball	2.888s
?   	github.com/google/go-containerregistry/pkg/logs	[no test files]
ok  	github.com/google/go-containerregistry/pkg/name	2.813s
ok  	github.com/google/go-containerregistry/pkg/registry	2.927s
ok  	github.com/google/go-containerregistry/pkg/v1	2.884s
ok  	github.com/google/go-containerregistry/pkg/v1/cache	2.709s
ok  	github.com/google/go-containerregistry/pkg/v1/compare	2.840s
ok  	github.com/google/go-containerregistry/pkg/v1/daemon	2.930s
ok  	github.com/google/go-containerregistry/pkg/v1/empty	2.876s
?   	github.com/google/go-containerregistry/pkg/v1/fake	[no test files]
ok  	github.com/google/go-containerregistry/pkg/v1/google	3.015s
ok  	github.com/google/go-containerregistry/pkg/v1/layout	2.989s
ok  	github.com/google/go-containerregistry/pkg/v1/match	2.919s
ok  	github.com/google/go-containerregistry/pkg/v1/mutate	3.043s
ok  	github.com/google/go-containerregistry/pkg/v1/partial	2.524s
ok  	github.com/google/go-containerregistry/pkg/v1/random	2.692s
ok  	github.com/google/go-containerregistry/pkg/v1/remote	7.428s
ok  	github.com/google/go-containerregistry/pkg/v1/remote/internal/authchallenge	2.791s
ok  	github.com/google/go-containerregistry/pkg/v1/remote/transport	2.997s
ok  	github.com/google/go-containerregistry/pkg/v1/static	2.976s
ok  	github.com/google/go-containerregistry/pkg/v1/stream	2.976s
ok  	github.com/google/go-containerregistry/pkg/v1/tarball	3.015s
ok  	github.com/google/go-containerregistry/pkg/v1/types	2.905s
?   	github.com/google/go-containerregistry/pkg/v1/validate	[no test files]
```
