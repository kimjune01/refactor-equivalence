## Finding F1 — Invocation cleanup starts after synchronous failure points
**Severity**: warning
**Claim**: C4
**What**: The claim says to wrap only the existing child-process wait promise in `try...finally`. In `DiscoveredToolInvocation.execute`, the sandbox cleanup function is assigned before `spawn`, but `spawn`, `child.stdin.write(...)`, and `child.stdin.end()` all occur before the wait promise. If any of those synchronous steps throws, the claimed `finally` will never run, leaving the prepared sandbox cleanup uncalled despite the goal's requirement to cover synchronous throws.
**Evidence**: `packages/core/src/tools/tool-registry.ts:72` assigns `cleanupFunc`; `packages/core/src/tools/tool-registry.ts:84` spawns the child; `packages/core/src/tools/tool-registry.ts:87` writes stdin; `packages/core/src/tools/tool-registry.ts:96` is where the wait promise begins.
**Fix**: Clarify/narrow C4 so the `try...finally` starts immediately after sandbox preparation and includes `spawn`, stdin writes, listener registration, and the wait promise; keep cleanup behavior otherwise unchanged.

## Finding F2 — Streaming cleanup does not cover pre-teardown synchronous failures
**Severity**: warning
**Claim**: C7
**What**: The claim places cleanup in an inner `try...finally` inside the generator's existing teardown block, around only the process-exit wait. That misses synchronous failures after `prepareCommand` but before the generator reaches its `try`/`finally`, such as a synchronous `spawn` failure or a failure while creating the readline interface. Those are exactly the kinds of paths the goal says should be covered by robust cleanup during synchronous throws.
**Evidence**: `packages/core/src/utils/shell-utils.ts:900` prepares the sandboxed command; `packages/core/src/utils/shell-utils.ts:909` calls `spawn`; `packages/core/src/utils/shell-utils.ts:916` creates the readline interface; the existing generator `try` does not begin until `packages/core/src/utils/shell-utils.ts:949`, and C7 only wraps the wait at `packages/core/src/utils/shell-utils.ts:971`.
**Fix**: Clarify C7 to add an outer cleanup guard that covers all work after `prepareCommand`, including `spawn` and readline setup, while still preserving the existing generator teardown behavior and avoiding duplicate cleanup calls.
