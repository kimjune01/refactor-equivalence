## Finding F1 — Rejected rationale misstates eval file scope
**Severity**: warning
**Claim**: global
**What**: The rejected item says editing existing `*.eval.ts` files is "explicitly outside the permitted claim scope", but the allowed edit set includes multiple `evals/*.eval.ts` files. That rationale misrepresents the scope rules and could incorrectly constrain a later reconcile step. The prompt forbids `*.test.{ts,tsx,py,go,rs}`, not `*.eval.ts`.
**Evidence**: `/Users/junekim/Documents/refactor-equivalence/samples/v2/gemini-cli-24941/inputs/allowed-files.txt` lists entries such as `evals/plan_mode.eval.ts`, `evals/tracker.eval.ts`, `evals/update_topic.eval.ts`, `evals/unsafe-cloning.eval.ts`, and `evals/background_processes.eval.ts`; `/Users/junekim/Documents/refactor-equivalence/samples/v2/gemini-cli-24941/volley/round-1-claims.md` rejected section says "eval files are test files and are explicitly outside the permitted claim scope."
**Fix**: Clarify the rejection to say suite/category tagging should be rejected because it changes the eval API/behavior or exceeds the bounded cleanup, not because all `*.eval.ts` files are outside the allowed file set.
