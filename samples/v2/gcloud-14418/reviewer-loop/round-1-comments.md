## Comment 1 — Implement missing latency tracking instead of deleting the scaffolding
**Severity**: approve-blocker
**File**: spanner/location_aware_client.go:255
**Request**: Instead of removing `onFirstResponse` and `latencyOnce` from `affinityTrackingStream`, use them to actually implement the latency tracking. Record the RPC start time before `StreamingRead`/`ExecuteStreamingSql` and replace the `nil` argument with a callback for `onFirstResponse` that calls `c.router.finder.recordEndpointLatency(ep.Address(), time.Since(startTime))`. (Unary RPCs like `ExecuteSql` should similarly record and report their latency).
**Why**: The PR description explicitly mentions "latency-aware replica selection", but by removing these hooks instead of implementing them, the latency tracking mechanism remains completely unhooked and the feature non-functional.

## Comment 2 — Hook up or remove unused `recordEndpointError` penalty logic
**Severity**: approve-blocker
**File**: spanner/channel_finder.go:61
**Request**: The `recordEndpointError` function (and its counterpart in `key_range_cache.go`) was introduced in this PR to apply a latency penalty on errors, but it is currently never called anywhere in the codebase. Either hook it up in `location_aware_client.go` (e.g., inside the `onError` callbacks alongside `maybeExcludeEndpointOnNextCall`) or remove the unused error penalty logic entirely.
**Why**: Dead code should not be merged, especially when it represents a missing piece of the advertised latency-aware routing resilience feature.
