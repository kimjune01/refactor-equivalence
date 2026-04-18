# Address findings — fix issues identified by hunt-code or reviewer

You are fixing specific issues identified by an adversarial reviewer in code you previously refactored. The findings are concrete, file-specific, and must be addressed without introducing new issues.

## Inputs

- **Findings** at `{FINDINGS_FILE}` — the list of issues to address.
- **Sharpened spec** at `{TRIAL_DIR}/volley/sharpened-spec-final.md` — the original refactoring claims.
- **Allowed edit set** at `{TRIAL_DIR}/inputs/allowed-files.txt`.
- **Current source** in the working directory — this is your refactored code with the issues.

## Rules

1. Address ONLY the findings listed. Do not make additional refactoring changes.
2. Stay within the allowed edit set. Do not touch test files.
3. If a finding says "revert this change," revert it cleanly.
4. If a finding says "claim not applied," apply the claim as specified in the sharpened spec.
5. If a finding requires a behavioral fix, make the minimal change that resolves it.
6. After making changes, verify the code is syntactically valid (no obvious parse errors).

## Output

Edit the source files in place. Write a one-line summary per addressed finding to `./ADDRESS_SUMMARY.md`:

```
- F1: <what you did>
- F2: <what you did>
```

Do not produce any other output files.
