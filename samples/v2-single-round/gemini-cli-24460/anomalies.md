## 2026-04-16 11:00 — Hunt-code false-positive on all 3 "not-applied" warnings

Attempt 2 hunt-code produced 3 warnings claiming claims C1, C2, C3 were not applied:
- F1: "duplicate JSDoc still present at lines 74-81" — actually removed; verified in merged_dir
- F2: "extra equality check still present" — not verified but likely similarly incorrect
- F3: "suggestions still probed before needsNetwork" — not verified but likely similarly incorrect

Build + tests both PASS. Claims were applied per opus IMPLEMENT_SUMMARY and direct inspection of merged_dir.

Takeaway: codex hunt-code hallucinates warnings even when build+tests pass. In v2 iterative hunt-code (N>1), this could trigger unnecessary iterations. Mitigation: hunt-code prompt should require evidence (quote exact lines) before flagging a claim as unapplied.
