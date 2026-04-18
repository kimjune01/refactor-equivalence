## Comment 1 — Inconsistent and unidiomatic error handling signature
**Severity**: approve-blocker
**File**: server/adkrest/controllers/triggers/eventarc.go:94
**Request**: Update `parseEventarcRequest` to return `(models.EventarcTriggerRequest, int, error)` to match standard Go idioms and unify it with the signature of `messageContentFromEventarc`. 
**Why**: Returning a string for an error condition instead of an `error` interface is unidiomatic in Go, and having inconsistent error-return patterns between the two new helper functions makes the code harder to follow.

## Comment 2 — Removed CloudEvents specification context
**Severity**: nice-to-have
**File**: server/adkrest/controllers/triggers/eventarc.go:94
**Request**: Restore the inline comments explaining "STRUCTURED MODE" vs "BINARY MODE" and how the HTTP body and headers map to the payload in `parseEventarcRequest`.
**Why**: The CloudEvents HTTP binding rules (headers vs. JSON body) are not immediately obvious, and these comments provide critical context for future maintainers.

## Comment 3 — Removed semaphore comment
**Severity**: optional
**File**: server/adkrest/controllers/triggers/eventarc.go:79
**Request**: Restore the `// Semaphore limits concurrent agent calls based on the TriggerConfig.` comment before the `if c.semaphore != nil` block.
**Why**: This comment provides useful reasoning for why the channel operation is being performed.
