## Accepted Claims

### C1 — Remove unused local compile path
**File**: cmd/adkgo/internal/deploy/agentengine/agentengine.go:57
**Change**: Delete the unused `buildFlags.execPath` field, remove the `f.build.execPath` assignment in `computeFlags`, and delete the uncalled `compileEntryPoint` method; keep only the `execFile` derivation needed by the generated Dockerfile.
**Goal link**: The goal is to package local Go source and deploy it through Agent Engine source-code deployment, so the unused local binary build path is not part of that workflow.
**Justification**: Removing this dead branch makes the implementation express the Dockerfile/source-archive deployment path directly while preserving behavior because `deployOnagentEngine` never calls `compileEntryPoint`.

### C2 — Use the receiver in flag computation
**File**: cmd/adkgo/internal/deploy/agentengine/agentengine.go:112
**Change**: In `(*deployAgentEngineFlags).computeFlags`, replace package-global `flags.source` and `flags.build` reads/writes with the receiver `f.source` and `f.build` for the same fields.
**Goal link**: The goal depends on a computed deployment configuration for the current command invocation, and receiver-local computation makes that configuration explicit.
**Justification**: This removes unnecessary global coupling from the preparation step without changing command behavior, because the command still invokes the method on `&flags`.

### C3 — Generate the Dockerfile from receiver state
**File**: cmd/adkgo/internal/deploy/agentengine/agentengine.go:184
**Change**: In `prepareDockerfile`, replace `flags.agentEngine.serverPort`, `flags.agentEngine.api`, `flags.agentEngine.a2a`, `flags.agentEngine.a2aAgentCardURL`, and `flags.agentEngine.webui` with the receiver fields under `f.agentEngine`.
**Goal link**: The generated Dockerfile is the concrete deployment artifact for Agent Engine, so it should be derived from the deployment config held by the receiver.
**Justification**: This removes accidental dependency on package-global state while preserving the generated Dockerfile for the existing CLI path.

### C4 — Use idiomatic Agent Engine method casing
**File**: cmd/adkgo/internal/deploy/agentengine/agentengine.go:89
**Change**: Rename `deployOnagentEngine` to `deployOnAgentEngine` and update the cobra `RunE` call site to match.
**Goal link**: The goal introduces the Agent Engine deployment command, and idiomatic naming makes that command workflow clearer in the implementation.
**Justification**: This is a private-name cleanup that preserves behavior while aligning the new command code with Go initialism/camel-case conventions.

## Rejected

- Add a blank import for `google.golang.org/adk/cmd/adkgo/internal/deploy/agentengine` in `cmd/adkgo/adkgo.go`: this appears necessary for the new cobra command to register, but `cmd/adkgo/adkgo.go` is outside the allowed edit set.
- Re-enable `os.RemoveAll` in `cmd/adkgo/internal/deploy/agentengine/agentengine.go` `cleanTemp`: it would reduce leftover build artifacts, but deleting the temporary directory is an observable filesystem side effect and is not a behavior-preserving refactor claim.
- Always close the generated Dockerfile `CMD` array in `prepareDockerfile` when `--webui=false`: this looks like a real bug in the first-pass implementation, but it changes the behavior of a non-default flag combination rather than merely refactoring existing behavior.
- Restore the deleted Eventarc launcher/controller/model files: restoring Eventarc support would cross beyond the Agent Engine deployment goal and would deliberately change the observable REST/launcher surface.
- Reintroduce configurable debug telemetry capacity and the LRU store in `server/adkrest/internal/services/debugtelemetry.go`: that would change the debug telemetry retention contract and dependency set, and it is not tied to the Agent Engine deployment goal.
