## Comment 1 — Out-of-scope changes in a2a_agent.go
**Severity**: approve-blocker
**File**: agent/remoteagent/a2a_agent.go:258
**Request**: Revert all changes in `agent/remoteagent/a2a_agent.go`.
**Why**: The modifications to the agent streaming loop's context cancellation behavior are out of scope for adding the `adkgo deploy agentengine` core functionality and should be proposed in a separate PR.

## Comment 2 — Unused field `srcBasePath`
**Severity**: nice-to-have
**File**: cmd/adkgo/internal/deploy/agentengine/agentengine.go:64
**Request**: Remove the unused `srcBasePath string` field from the `sourceFlags` struct and remove its corresponding assignment `dir, file := path.Split(f.source.entryPointPath); f.source.srcBasePath = dir` inside `computeFlags()` (you can simply reassign `f.source.entryPointPath = filepath.Base(...)`).
**Why**: Since `compileEntryPoint` was correctly removed and the build is now handled exclusively within the Docker container, `srcBasePath` is a dead field and no longer used.