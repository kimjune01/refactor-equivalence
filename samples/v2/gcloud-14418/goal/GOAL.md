# PR #14418 — feat(spanner): complete location-aware routing resilience and observability

## PR body

## Summary

  This change expands the location-aware routing path in the Spanner Go client with endpoint lifecycle management,
  stronger endpoint health handling, retry-aware exclusion, latency-aware replica selection, and route-selection tracing.

  ## What Changed

  - enabled location-aware routing automatically for experimental-host configurations while preserving env-var override
    behavior
  - added endpoint cache support for GetIfPresent, Evict, and DefaultChannel
  - switched endpoint health evaluation to real gRPC connectivity state, including transient-failure detection
  - added an endpoint lifecycle manager with:
      - background probing
      - idle eviction
      - endpoint recreation requests
      - recent transient-failure eviction tracking
  - integrated lifecycle handling into routing and affinity fallback paths
  - added request-id keyed one-shot endpoint exclusion for RESOURCE_EXHAUSTED retries
  - expanded skipped_tablet_uid reporting for transient failures and recent transient-failure evictions, with
    deduplication
  - added OpenTelemetry route-selection span attributes and events
  - updated focused tests and goldens for the new routing behavior

  ## Behavioral Notes

  - stopped or transient-failure endpoints are now treated differently from simply non-ready endpoints during tablet
    selection
  - retry attempts can avoid previously selected routed endpoints after RESOURCE_EXHAUSTED
  - leader-preferred requests still favor close leaders, but can fall back to a closer non-leader replica when the leader
    is too far away
  - route selection is now observable through tracing attributes and events
