## Accepted Claims

### C1 — Name Eventarc wire constants
**File**: server/adkrest/controllers/triggers/eventarc.go:60
**Change**: Introduce file-level constants for `"application/cloudevents+json"` and `"google.cloud.pubsub.topic.v1.messagePublished"`, and use them in `EventarcTriggerHandler` instead of inline string literals.
**Goal link**: This clarifies the CloudEvents structured-mode and Pub/Sub Eventarc branch that the goal adds.
**Justification**: Naming the protocol and event-type values makes the trigger-processing intent explicit without changing parsing, response codes, retries, or agent input.

### C2 — Extract CloudEvent request parsing with explicit error classification
**File**: server/adkrest/controllers/triggers/eventarc.go:56
**Change**: Move the structured-vs-binary request decoding block at the start of `EventarcTriggerHandler` into a private helper in the same file, while preserving the current bad-JSON and body-read error handling semantics at the call site. The helper contract must expose enough information for the handler to keep the exact current responses: structured-mode JSON decode failures still map to `http.Error(w, "Bad Request", http.StatusBadRequest)`, and binary-mode body read failures still map to `http.Error(w, "Failed to read body", http.StatusInternalServerError)`. Acceptable shapes include returning a typed/sentinel error that the handler maps to those responses, or returning explicit status/message classification alongside `models.EventarcTriggerRequest`.
**Goal link**: This isolates CloudEvents trigger ingestion from the later agent-run orchestration required by the goal.
**Justification**: The handler currently mixes wire-format parsing, event-to-message conversion, app/user resolution, concurrency limiting, and runner invocation; extracting only the CloudEvents parsing removes accidental structure from the main workflow.
**Hunt note**: Retained as narrowed for F1 because the helper contract now explicitly requires preserving the two distinct existing `http.Error` status/body mappings at the call site.

### C3 — Extract Eventarc agent message construction
**File**: server/adkrest/controllers/triggers/eventarc.go:87
**Change**: Move the `messageContent` selection block into a private helper in the same file, for example `messageContentFromEventarc(event models.EventarcTriggerRequest) (string, int, error)`, returning the same message strings and status-code choices currently used for Pub/Sub data unmarshal errors, empty Pub/Sub payloads, and generic event marshal errors.
**Goal link**: This clarifies how CloudEvents become the agent input while keeping Pub/Sub-sourced Eventarc events aligned with the existing Pub/Sub trigger behavior.
**Justification**: A dedicated conversion helper removes the mutable local branching from `EventarcTriggerHandler` and makes the only Eventarc-specific data transformation directly testable through the existing handler tests.

### C4 — Reuse the Eventarc endpoint literal in the launcher
**File**: cmd/launcher/web/triggers/eventarc/eventarc.go:129
**Change**: Add a package-level constant for `"/apps/{app_name}/trigger/eventarc"` and use it in both `SetupSubrouters` and `UserMessage`.
**Goal link**: This keeps the newly added Eventarc trigger endpoint registration and user-facing endpoint message tied to one source of truth.
**Justification**: The route is duplicated in the first-pass launcher, and replacing the duplicate literals reduces accidental drift without changing the registered path or printed URL.

### C5 — Normalize the Eventarc default-user identifier name
**File**: server/adkrest/controllers/triggers/eventarc.go:31
**Change**: Rename the unexported constant `eventArcDefaultUserID` to `eventarcDefaultUserID` and update its single use in `EventarcTriggerHandler`.
**Goal link**: This aligns the fallback Eventarc caller identity with the package and launcher spelling used for the new trigger.
**Justification**: The rename is local, behavior-preserving, and removes an inconsistent identifier that does not communicate any separate `EventArc` concept.

## Rejected

- Restore `tool/skilltoolset/skill/source.go` and `tool/skilltoolset/skill/filesystem_source.go`: These deletions are unrelated to Cloud Events trigger processing, but restoring exported APIs and filesystem behavior is not a bounded no-behavior refactor against the Eventarc goal.
- Restore `server/adkrest/handler.go` debug telemetry configuration and `server/adkrest/internal/services/debugtelemetry.go` LRU capacity support: This would cross a public server configuration/API boundary and change debug telemetry retention behavior, even though the first-pass removal appears unrelated to the Eventarc goal.
- Restore the removed token telemetry attributes in `internal/telemetry/telemetry.go`: This is unrelated to Eventarc trigger processing and changes emitted telemetry attributes, which is observable behavior.
- Re-add `github.com/hashicorp/golang-lru/v2` to `go.mod` and `go.sum`: Dependency restoration only makes sense with the rejected debug-telemetry rollback and is outside the Cloud Events trigger goal by itself.
- Change Eventarc structured-mode detection to parse media types such as `application/cloudevents+json; charset=utf-8`: This is likely a correctness improvement, but it expands accepted request behavior and is therefore not a behavior-preserving refactor.
- Convert `EventarcTriggerHandler` structured-mode decode and binary body-read failures from `http.Error` to `respondError`: This would make error response bodies and content type more consistent with other trigger paths, but it changes observable HTTP responses.
- Share one launcher implementation between `cmd/launcher/web/triggers/pubsub/pubsub.go` and `cmd/launcher/web/triggers/eventarc/eventarc.go`: The files are highly similar, but introducing a cross-trigger abstraction would be broader than necessary for one new Eventarc endpoint and risks obscuring the separate sublauncher behavior.
- Move Pub/Sub and Eventarc semaphore acquisition into `RetriableRunner.RunAgent`: This would reduce duplicate controller code, but it changes the runner/controller responsibility boundary and would affect all trigger controllers rather than just clarifying Eventarc trigger processing.
