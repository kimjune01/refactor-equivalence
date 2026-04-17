# v2 exclusions log

Per-PR include/exclude decisions with reason. Appended chronologically.

Exclusion globs applied per PREREG_V2.md:

- tests: `**/*_test.go`, `**/*.test.ts`, `**/*.test.tsx`, `tests/**/*.py`, `**/test_*.py`, `**/*_test.py`, `**/__snapshots__/**`, `**/*.snap`
- docs: `docs/**`, `**/*.md`, `**/README*`
- schemas: `schemas/**`, `**/*.schema.json`
- lockfiles: `**/package-lock.json`, `**/yarn.lock`, `**/Cargo.lock`, `**/uv.lock`, `**/poetry.lock`, `**/go.sum`
- generated: `**/dist/**`, `**/build/**`, `**/target/**`, `**/__pycache__/**`, `**/.next/**`, `**/_generated.go`, `**/*.pb.go`
- vendored: `**/vendor/**`, `**/third_party/**`, `**/node_modules/**`
- gemini-cli repo-specific: `bundle/**`

## Pre-selection feasibility criteria (C1)

A candidate is eligible if:
1. Registered test command passes at `C_final`.
2. `git diff C_test C_final -- <source globs except tests>` is non-empty.
3. ≥1 source file remains after exclusions.

## Log

(entries appended as candidates are evaluated)
