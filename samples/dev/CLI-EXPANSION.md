# cli/cli expansion: PRs 4–10

Triggered by pilot decision #6 (secondary expansion): initial 3-PR batch had wrong-direction rate 2/3 = 67%, above the locked trigger threshold. Expanding cli/cli to the full 10 PRs before interpreting results.

Locked 2026-04-16.

## Added PRs

| PR | Title | LOC (+/-) | Commits | Reviews | Subsystem |
|----|-------|-----------|---------|---------|-----------|
| 12444 | feat: add native copilot command to shim copilot cli | 1163/7 | 6 | 77 | copilot |
| 12859 | Add experimental huh-only prompter gated by GH_EXPERIMENTAL_PROMPTER | 1468/56 | 14 | 2 | prompter |
| 13009 | Use login-based assignee mutation on github.com | 390/271 | 7 | 4 | api/assignee |
| 12774 | fix(licenses): isolate generated licenses per platform | 259/94 | 4 | 8 | build/licenses |
| 12811 | Add `--duplicate-of` flag and duplicate reason to issue close | 352/22 | 3 | 2 | issue |
| 13025 | Consolidate actor-mode signals into ApiActorsSupported | 178/121 | 6 | 2 | api/actors |
| 12677 | Migrate issue triage workflows to shared workflows | 118/179 | 7 | 4 | workflows |

## Rationale

- **Subsystem diversity**: copilot, prompter, api/assignee, build, issue, actors, workflows — minimal overlap with the initial 3-PR batch (pr, workflow run, project)
- **Size distribution**: 2 large (>1000 LOC), 3 medium (350–660), 2 smaller (≤300)
- **Refactor type representation**: PR 13025 (actor-mode consolidation) is an explicitly refactor-labeled PR — balances the feature-heavy batch
- All APPROVED, post-cutoff, ≥3 commits, ≥2 reviews (except 12859 has 2 reviews but 14 commits which more than compensates)

## Combined 10-PR cli/cli batch

Batch 1 (already run): 12567, 12695, 12696.
Batch 2 (this expansion): 12444, 12859, 13009, 12774, 12811, 13025, 12677.

All share the same locked protocol: find_c_test with `go test ./...`, clean-room via `build_cleanroom_go.sh`, full forge pipeline, complexity measurement via `measure_complexity_go.sh`, Phase 7 review via gemini.
