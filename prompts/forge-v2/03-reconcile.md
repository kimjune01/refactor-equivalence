# Reconcile — apply hunt-spec findings to the spec

You previously authored `{TRIAL_DIR}/volley/round-{N}-claims.md`. A hunt pass produced `{TRIAL_DIR}/volley/hunt-spec-round-{N}.md` listing defects.

Your task: produce the next-round spec at `{TRIAL_DIR}/volley/round-{N+1}-claims.md` (or `{TRIAL_DIR}/volley/sharpened-spec-final.md` if this is the final round).

## Rules

- **Blockers are mandatory-reject.** Any claim with a blocker finding MUST move to `## Rejected` with the hunt finding cited as the reason. You may NOT narrow, clarify, or retain a blocker'd claim.
- **Warnings may be narrowed.** Rewrite the claim with the missing edge cases made explicit, or demote it to rejected if narrowing can't make it specific.
- **Notes are optional.** Act on them if they improve specificity; ignore otherwise.
- **No new claims.** You may not add refactor claims during reconcile. If hunt identified a claim the spec SHOULD have rejected, add it to `## Rejected`.
- **Preserve format.** Keep the `## Accepted Claims` numbered list and the `## Rejected` bullet list. Include ALL previous rejections plus any new ones.
- **Cite each retained warning'd claim against the hunt finding**: add a one-line note explaining why it's safe to retain as-narrowed.

If all accepted claims survived without blockers, the reconciled spec may be identical to the input minus rejected-candidate updates.

## Output

Markdown file only. No code edits. No commentary outside the document.
