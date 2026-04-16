# Forge pilot prompts

Five prompts, one per phase of the forge pipeline as run during the 5-PR pilot on `google-gemini/gemini-cli`. Paths are absolute (`/tmp/refactor-eq-workdir/...`) because each prompt was fed to the relevant model verbatim with those paths filled in.

Order of execution per PR:

| # | Phase | Model | Prompt | Output |
|---|-------|-------|--------|--------|
| 1 | Volley (sharpen) round 1 | codex GPT-5.4 | `01-volley-round1.md` | `volley-round1.md` — sharpened claim list |
| 2 | Hunt-spec | codex GPT-5.4 | `02-hunt-spec.md` | `hunt-spec-findings.md` |
| 3 | Reconcile (if findings) | codex GPT-5.4 | `03-reconcile.md` | `sharpened-spec-final.md` |
| 4 | Blind-blind-merge | opus (agent) + codex | `04-implement.md` | `opus-dir/` and `codex-dir/` diffs |
| 5 | Hunt-code | codex GPT-5.4 | `05-hunt-code.md` | `hunt-code-findings.md` |

Between steps 4 and 5, the merge-picker script (`scripts/merge_blind_outputs.sh` — TODO) chose the smaller-churn version per file.

## Known deviations in the pilot

See `worklog/WORK_LOG.md` for full narrative. In brief:

- **PR 24437**: hunt-code used gemini instead of codex (out of compliance with `/bug-hunt` skill default). Outcome unchanged (zero findings).
- **PR 24483**: TS type error was caught by `npm run build`, not by hunt-code. Fixed with a 1-line manual patch. Hunt-code claimed to have run typecheck and seen no issues — but ran *after* the patch, so the broken pre-patch state was never reviewed by the intended phase.

Both are procedural, not outcome-altering. Noted so future runs can correct:
1. Always use codex for hunt-code.
2. Always run hunt-code **before** any manual fix; include `npm run build` (not just typecheck) in the hunt-code checks, or add a separate "build gate" step between merge and hunt-code.

## Re-running this pilot

Given clean clones at the same commits + same models + same prompts, this should reproduce within noise. Noise sources worth listing: codex/opus non-determinism, volley claim ordering, blind-merge tie-breaking on equal-churn files.

Invariants worth protecting:
- Always use separate `/tmp` dirs for opus-dir and codex-dir.
- Always `npm ci` inside each cleanroom, do not symlink node_modules (relative workspace links resolve outside the cleanroom).
- Tests MUST run sequentially across PRs; `~/.gemini` and `/tmp` state collide.
