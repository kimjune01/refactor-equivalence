## Accepted Claims

### C1 — Remove the unused stale lifecycle reason
**File**: spanner/endpoint_lifecycle_manager.go:34
**Change**: Delete the `lifecycleEvictionReasonStale` constant from the `lifecycleEvictionReason` const block, leaving the existing transient-failure, shutdown, and idle reasons unchanged.
**Goal link**: Endpoint lifecycle management only needs reasons that are currently emitted by probing and idle eviction.
**Justification**: Removing the unused stale reason makes the lifecycle eviction model match the implemented resilience paths without changing any eviction behavior.

### C2 — Drop the unused first-response stream callback
**File**: spanner/location_aware_client.go:391
**Change**: Remove `latencyOnce` and `onFirstResponse` from `affinityTrackingStream`, remove the `onFirstResponse func()` parameter from `newAffinityTrackingStream`, delete the `latencyOnce.Do` block in `Recv`, and remove the two `nil` arguments at the `StreamingRead` and `ExecuteStreamingSql` constructor call sites.
**Goal link**: Route-selection observability and retry exclusion are handled through explicit tracing and error callbacks, not through an unpopulated first-response hook.
**Justification**: The callback is never supplied by production code, so deleting it removes an inert latency/observability indirection while preserving streaming behavior.

### C3 — Remove the obsolete tablet skip wrapper
**File**: spanner/key_range_cache.go:610
**Change**: Delete `cachedTablet.shouldSkip` and `cachedTablet.shouldSkipWithExclusions`, keeping `shouldSkipForRouting` and `recordKnownTransientFailure` as the only tablet skip paths.
**Goal link**: The goal distinguishes explicit skips, endpoint exclusions, unhealthy endpoints, transient failures, and recent transient-failure evictions.
**Justification**: The older wrapper is no longer called and lacks the lifecycle-aware skip semantics, so removing it reduces duplicate skip logic without changing routing behavior.

### C4 — Inline the unused affinity-client exclusion wrapper
**File**: spanner/location_aware_client.go:157
**Change**: Change `affinityClient` to call `affinityEndpoint(txID, nil)` followed by `clientForEndpoint`, then delete `affinityClientWithExclusions`.
**Goal link**: Affinity fallback with endpoint exclusions is now expressed directly through `affinityEndpoint`.
**Justification**: The wrapper has no production caller besides `affinityClient`, so inlining it removes a layer that does not clarify retry-aware affinity routing.

## Rejected

- Remove all latency tracker fields and helpers from `spanner/key_range_cache.go`: rejected because latency-aware replica selection is an explicit goal aspect, and deleting the underlying scoring machinery would move the implementation away from that goal even if endpoint latency recording is not yet wired through production RPCs.
- Wire `recordEndpointLatency` and `recordEndpointError` into unary and streaming RPC paths: rejected because it would change observable routing decisions by introducing new latency scores, which is outside a behavior-preserving refactor claim.
- Replace `lifecycleEvictionReason` with a boolean argument to `evictEndpoint`: rejected because the existing enum names make transient-failure retention versus ordinary eviction clear, and the smaller unused-constant removal captures the accidental complexity without weakening readability.
- Merge `prepareReadRequestWithExclusions` and `prepareExecuteSQLRequestWithExclusions` in `spanner/location_router.go` behind a higher-order helper: rejected because the helper would obscure request-specific channel-finder calls for a modest duplication reduction.
- Change `isExperimentalLocationAPIEnabledForConfig` to fall back to `config.IsExperimentalHost` when `GOOGLE_SPANNER_EXPERIMENTAL_LOCATION_API` contains an invalid boolean: rejected because the current code treats any non-empty unparsable env var as false, and changing that would alter override behavior.
- Remove the `recordEndpointLatency` and `recordEndpointError` forwarding methods from `spanner/channel_finder.go`: rejected because they are plausible integration points for the explicit latency-aware selection goal, and removing only the forwarding methods while retaining the lower-level tracker would make the latency path less coherent.
