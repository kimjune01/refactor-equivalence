# C_random generator spec — DROPPED IN v2

**Status:** dropped from v2. Retained here for historical reference; see `PREREG_V2.md` §Snapshot Definitions > `C_random` — DROPPED.

Reason for drop (v2 round 6, codex hostile-review concern #1): the proposed `C_random` transformations (local renames, redundant parentheses, statement reordering) don't approximate what the LLM actually does (multi-file structural reshaping). Even a clean `C_random` measures noise, not the alternative-intervention shape. The intended inference — "metrics reward simplification specifically vs. any change" — isn't supported by this control.

Trade-off accepted in v2: P1 measures direction-of-change only, not simplification-specificity.

---

(original v1 text preserved below for historical trail)

# C_random generator spec

Semantics-preserving but non-simplifying transformation of `C_test`. Purpose: control for "metrics reward any change" vs. "metrics reward simplification specifically."

## Constraints

- Must preserve observable behavior (tests pass)
- Must NOT intentionally reduce complexity
- Edit budget comparable to typical `C_llm` (proportional to diff size — TBD after pilot observes `C_llm` magnitudes)
- Applied only to files in the `C_test` allowed edit set (same file scope as `C_llm`)

## Transformation family (TypeScript)

For the TypeScript pilot repo:

1. **Local variable renaming** — rename local `let`/`const` identifiers to semantically-neutral alternates drawn from a fixed suffix pool (`_a`, `_b`, `_c`, …). Exported symbols, class members, and parameters listed in JSDoc are untouched.
2. **Independent statement reordering** — within a basic block, swap pairs of statements whose data dependencies don't require the original order (no shared writes, no call-site ordering constraints). Use an AST-aware reordering pass; skip when unsure.
3. **Formatting-preserving syntactic noise** — inject redundant parentheses around already-parenthesizable sub-expressions.

Operations 1–3 compose; apply each operation with bounded frequency (configurable seed + per-operation budget).

## Validation

1. Run the locked test command. If fails → record `C_random` as invalid for that PR.
2. Compare cognitive complexity before/after. If the operation *reduced* complexity by more than δ, that transformation is rejected and the step is redone with a different random seed. (Prevents accidental simplification.)

## Seeding

Single seed per PR, recorded alongside snapshot metadata. Deterministic output given the same `C_test` + seed + edit budget.

## Out of scope for pilot

Language-generic AST tooling for the four secondary repos (Go, Rust, Python). The transformation family must be re-instantiated per-language. Pilot validates feasibility in TypeScript only; secondary repos decide after pilot.
