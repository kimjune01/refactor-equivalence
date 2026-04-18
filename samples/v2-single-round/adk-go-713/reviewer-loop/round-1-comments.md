## Comment 1 — Unidiomatic error return type
**Severity**: approve-blocker
**File**: server/adkrest/controllers/triggers/eventarc.go:96
**Request**: Change the signature of `parseEventarcRequest` to return an `error` interface instead of a string for the error message, e.g., `func parseEventarcRequest(r *http.Request) (models.EventarcTriggerRequest, int, error)`. Update the call site in `EventarcTriggerHandler` accordingly.
**Why**: Returning a string to indicate an error condition is unidiomatic in Go.

## Comment 2 — Restore dropped comment
**Severity**: nice-to-have
**File**: server/adkrest/controllers/triggers/eventarc.go:82
**Request**: Restore the comment `// Semaphore limits concurrent agent calls based on the TriggerConfig.` immediately before the `if c.semaphore != nil {` block.
**Why**: It provides useful context about the purpose of the semaphore that was present before the refactoring.