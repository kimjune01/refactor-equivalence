## Finding F1 — Style cleanup is not goal work
**Severity**: warning
**Claim**: C2
**What**: The claim is framed as serving proto2 extension support, but the requested change only replaces `fmt.Fprintf` with direct `strings.Builder` writes. That is a local cleanup of already-selected label strings, not a behavior needed by the stated proto2-extension or JSON-name goals.
**Evidence**: `/Users/junekim/Documents/refactor-equivalence/samples/v2/celgo-1294/goal/GOAL.md:5` lists including proto2 extensions in REPL cel-spec types; `/tmp/refactor-eq-workdir/cleanroom-v2/1294/common/types/object.go:190` through `/tmp/refactor-eq-workdir/cleanroom-v2/1294/common/types/object.go:197` already selects normal field names versus backtick-escaped full extension names and uses the same `name` for lookup.
**Fix**: Narrow C2 to an optional style cleanup, or remove it from accepted goal-linked claims.

## Finding F2 — Required JSON-name and extension lookup order is implicit
**Severity**: warning
**Claim**: global
**What**: The spec rejects two bad `FieldByName` orderings, but it never explicitly states the required preserved behavior: when `JSONFieldNames(true)` is enabled, JSON-name lookup must happen before proto-name fallback and extension lookup. An implementer has to infer the positive rule from rejected alternatives and tests.
**Evidence**: `/Users/junekim/Documents/refactor-equivalence/samples/v2/celgo-1294/goal/GOAL.md:7` says the PR fixes JSON field names when extensions are present. The current required lookup order is in `/tmp/refactor-eq-workdir/cleanroom-v2/1294/common/types/pb/type.go:109`, where JSON names are checked first, proto field names second, and extensions third. Tests exercise the edge cases in `/tmp/refactor-eq-workdir/cleanroom-v2/1294/cel/cel_test.go:3706` and `/tmp/refactor-eq-workdir/cleanroom-v2/1294/cel/cel_test.go:3711`.
**Fix**: Clarify the spec text so the required `FieldByName` order is explicit preserved behavior, not only implied by rejected alternatives.
