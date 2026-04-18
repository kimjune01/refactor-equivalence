# Implementation Summary

## Files modified

- `server/adkrest/controllers/triggers/eventarc.go`
- `cmd/launcher/web/triggers/eventarc/eventarc.go`

## Claims applied

### C1 — Name Eventarc wire constants
Added `cloudEventsContentType` and `pubsubMessagePublishedType` package-level constants, replacing inline string literals in the handler and new helpers.

### C2 — Extract CloudEvent request parsing with explicit error classification
Extracted `parseEventarcRequest(r *http.Request) (models.EventarcTriggerRequest, string, int)` — returns the parsed event plus an error message/status pair that the handler maps directly to `http.Error`, preserving the exact existing `"Bad Request"/400` and `"Failed to read body"/500` responses.

### C3 — Extract Eventarc agent message construction
Extracted `messageContentFromEventarc(event models.EventarcTriggerRequest) (string, int, error)` — returns message content plus status code and error, preserving the existing Pub/Sub unmarshal (500), empty payload (400), and generic marshal (500) error paths.

### C4 — Reuse the Eventarc endpoint literal in the launcher
Added `eventarcTriggerEndpoint` constant in the launcher package, used by both `SetupSubrouters` and `UserMessage`.

### C5 — Normalize the Eventarc default-user identifier name
Renamed `eventArcDefaultUserID` → `eventarcDefaultUserID` and updated its single use.
