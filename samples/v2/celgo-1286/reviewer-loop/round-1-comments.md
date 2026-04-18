## Comment 1 — Remove `appliedFeatures` mutation from `features()`
**Severity**: approve-blocker
**File**: cel/options.go:912
**Request**: Remove the `if flag == featureJSONFieldNames { e.appliedFeatures[flag] = true }` block from `features()`.
**Why**: The `appliedFeatures` map is intended to track idempotent side-effects during `configure()`, not to record which options were provided by the user; mutating it inside the generic `features` option builder breaks this convention.

## Comment 2 — Use `isSet` from `e.features` instead of `e.appliedFeatures`
**Severity**: approve-blocker
**File**: cel/env.go:852
**Request**: Replace `if e.appliedFeatures[featureJSONFieldNames]` with `if enabled, isSet := e.features[featureJSONFieldNames]; isSet {`, and update the inner block to use `reg.WithJSONFieldNames(enabled)`.
**Why**: Checking the second return value of the `e.features` map lookup (`isSet`) is the idiomatic way to determine if an option was explicitly provided, removing the need for the hacky `appliedFeatures` modification.