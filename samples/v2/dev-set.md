# v2 dev-set (locked)

**Repo:** google-gemini/gemini-cli
**Locked:** 2026-04-16
**Purpose:** pipeline validation + prompt iteration. Results do NOT contribute to primary analysis (per PREREG_V2.md §Dev/test separation).

## PRs

| PR | type | post_sum | post_files | title | C_base | C_final |
|----|------|----------|------------|-------|--------|---------|
| 24544 | feat | 1604 | 33 | add /memory inbox command for reviewing extracted skills | b80234aa | 12149132 |
| 24460 | fix  | 674  | 13 | enhance sandbox usability and fix build error | 0d7e778e | 1c7c5efe |
| 24489 | feat/refactor | 646 | 28 | refactor subagent tool to unified invoke_subagent tool | 615e0783 | 234ad867 |

## Deviation note

24489 is a v1-pilot dev PR. Reusing as v2-dev is intentional:
- v1 infrastructure (clean-room, snapshots, test command) is validated.
- Same-PR A/B between v1 and v2 forge pipelines provides direct improvement signal.
- Cost: anchoring bias from having seen v1 artifacts.
Bias direction: I may unconsciously tune v2 prompts toward v1's observed failure modes on 24489. Mitigation: log all prompt iterations to trail; re-read v2 output fresh on 24544 and 24460 before judging convergence.

## Prompt freeze

Prompts frozen 2026-04-16 after dev-set iteration. Changes from initial draft:
- `05-hunt-code.md`: added evidence-quoting requirement, removed `git diff HEAD~` instruction (cleanroom has no .git; codex hallucinated diffs in dev-set runs)
- All other forge-v2 prompts unchanged from initial draft.

## Deviation: C_test = C_final accepted

2/3 dev PRs had C_test = C_final (feature-PR pathology). Prereg C2 would exclude these. Accepted as deviation: pipeline runs on C_test = C_final with P2 trajectory noted as degenerate. Logged to v3_questions.md.
