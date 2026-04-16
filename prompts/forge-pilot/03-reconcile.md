# Reconcile sharpened spec against hunt findings

You previously authored `/tmp/refactor-eq-workdir/forge/24483/volley-round1.md`. A hunt pass then produced `/tmp/refactor-eq-workdir/forge/24483/hunt-spec-findings.md` listing defects.

Your task: produce a final sharpened spec at `/tmp/refactor-eq-workdir/forge/24483/sharpened-spec-final.md` that addresses every finding. For each problematic claim:
- If the finding is test-breaking or behavior-changing, MOVE the claim to a "## Rejected" section with a one-line reason.
- If the finding is under-specification, NARROW the claim: rewrite it with the missing edge cases explicit.
- If the finding is about a missing rejection (a change that shouldn't be refactored away), ADD it to the "## Rejected" section.

Do NOT add new refactoring claims. Only reconcile existing ones against the findings.

Preserve the numbered "## Accepted Claims" format. Include the full "## Rejected" list (previous rejections + new ones). Output is only the markdown file; no code edits.
