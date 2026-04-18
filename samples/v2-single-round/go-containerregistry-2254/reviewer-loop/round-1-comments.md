## Comment 1 — Update `docker/cli` dependency in `cmd/krane`
**Severity**: approve-blocker
**File**: cmd/krane/go.mod:47
**Request**: Update the indirect dependency `github.com/docker/cli` to `v29.4.0+incompatible` (e.g. by running `./hack/bump-deps.sh` or manually updating and running `go mod tidy`).
**Why**: Since `cmd/krane` uses a `replace` directive pointing to the root module, failing to sync this indirect dependency causes `go build ./...` (run by `presubmit.sh`) to fail with "updates to go.mod needed".

## Comment 2 — Update `docker/cli` dependency in `pkg/authn/kubernetes`
**Severity**: approve-blocker
**File**: pkg/authn/kubernetes/go.mod:22
**Request**: Update the indirect dependency `github.com/docker/cli` to `v29.4.0+incompatible` (and run `go mod tidy`).
**Why**: To keep dependencies in sync with the root module and prevent `presubmit.sh` from failing during `go test ./...` in this submodule.

## Comment 3 — Update `docker/cli` dependency in `pkg/authn/k8schain`
**Severity**: approve-blocker
**File**: pkg/authn/k8schain/go.mod:54
**Request**: Update the indirect dependency `github.com/docker/cli` to `v29.4.0+incompatible` (and run `go mod tidy`).
**Why**: To keep dependencies in sync with the root module and prevent `presubmit.sh` from failing during `go build ./...` in this submodule.
