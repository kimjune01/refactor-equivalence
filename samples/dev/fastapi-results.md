# fastapi (Python) — 3-PR secondary batch

## Results

| PR | Title | Size | Status | Notes |
|----|-------|------|--------|-------|
| 14978 | Refactor router logic | 146 LOC | **Excluded** | C_test == C_final (no post-tests-pass revision) |
| 14962 | Serialize JSON with Pydantic | 270 LOC | **No-op** | Volley produced preservation claims; both opus and codex made 0 changes |
| 15022 | Add JSONL/binary streaming | 1239 LOC | **Wrong direction** | codex refactored but scalar complexity increased (C_llm meanCC 6.07 vs C_test 6.01) |

## Scoring

- P3 (reviewer preference): not measured (no active trial warranted review)
- P2 trajectory: 0 past / 0 short / 1 wrong (+ 1 no-op auto-wrong + 1 exclusion)
- No-op rate: 1/2 eligible = 50% (above futility 40%)
- Exclusion rate: 1/3 = 33%

## Forge failure mode observed

**Descriptive-vs-prescriptive volley confusion.** For the two eligible fastapi PRs, codex's volley produced "preservation claims" (descriptions of what the PR does and why it should be preserved) rather than "refactoring claims" (specific simplifications to apply on top of the PR's changes).

Example from PR 14962 volley claim 1: "In `fastapi/_compat/v2.py`, keep the new Pydantic v2 JSON-byte serialization behavior on `ModelField`..." — this is a preservation claim.

Opus interpreted claims correctly per prompt and applied them verbatim — but since the claims describe what already exists, this resulted in no changes.

Why this happened on fastapi but not gemini-cli or cli/cli: speculation, not certainty.
- fastapi's PRs are typeset-heavy with Pydantic models and strict typing — codex may have judged the changes already minimal
- fastapi's author (Sebastián Ramírez) has a distinctive style codex has seen in training, which it may read as "already optimal"
- The REFACTOR_SPEC.md I used for fastapi was shorter than the gemini-cli/cli-cli one and didn't have as many focus examples

**Recommendation for v2:** spec must explicitly instruct codex "propose simplifications that do not already exist in the diff" to avoid descriptive drift. The instruction in `REFACTOR_SPEC.md` should be phrased as a verb ("simplify X") not a preservation ("ensure X behavior").

## Environment setup cost

fastapi required ~90 minutes of dep-install iteration before tests would pass:
- Python 3.13 (3.9 default didn't meet fastapi's >=3.10)
- pytest-timeout, pytest-cov, pytest-sugar, pytest-codspeed, pytest-xdist, pytest-asyncio
- pyjwt, pwdlib[argon2], orjson, ujson, pyyaml, typer, starlette, email-validator, uvicorn, fastapi[standard]
- Deselect `test_traceback_for_dependency_with_yield` and `scripts/tests/test_translation_fixer` for env-independence

This cost limits how many Python-ecosystem secondary repos can fit in an experiment timeline.

## Snapshots

- `/tmp/refactor-eq-workdir/snapshots-fastapi/14962/{c_test,c_llm,c_final}` — C_test identical to C_llm (no-op)
- `/tmp/refactor-eq-workdir/snapshots-fastapi/15022/{c_test,c_llm,c_final}`
