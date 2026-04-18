# Draft: gemini-cli maintainer outreach

**Status:** DRAFT — waiting for initial response before sending

**Context:** We ran a forge-wrapped LLM refactoring pipeline on 5 merged gemini-cli PRs. 4 produced non-trivial diffs. Each PR on the fork shows the refactored version vs the first-tests-passing state. The ask: would you approve these diffs?

---

**Subject:** Would you review 4 LLM-refactored diffs from your PRs? (10 min, for science)

Hi — I'm running an experiment on whether an autonomous refactoring pipeline can improve brownfield PRs before human review. I tested it on 4 merged gemini-cli PRs and would love your take on the results.

Each link shows a diff: the forge pipeline's refactored version of the code at the point where tests first passed, before your review feedback shaped the final version.

**The diffs:**

1. **PR #24489** — refactor subagent tool to unified invoke_subagent
   https://github.com/kimjune01/gemini-cli-claude/pull/2

2. **PR #25077** — optimize Windows sandbox initialization via native ACL
   https://github.com/kimjune01/gemini-cli-claude/pull/3

3. **PR #24941** — generalize evals infra
   https://github.com/kimjune01/gemini-cli-claude/pull/4

4. **PR #24763** — ensure robust sandbox cleanup
   https://github.com/kimjune01/gemini-cli-claude/pull/5

**The question:** For each diff, would you approve it for merge? A simple 👍 / 👎 / "would approve with these changes: ..." is plenty.

**What the pipeline does:** Takes the PR's code at first-tests-passing, runs it through goal-anchored spec sharpening → blind-blind implementation (Opus 4.6 + Codex GPT-5.4) → adversarial hunt-code with full build+tests → Gemini reviewer-loop → complexity gate. All 4 passed build, tests, and the complexity gate.

**Why this matters:** If your judgment aligns with the Gemini reviewer's (which approved 3/4), it validates using LLM review as a proxy for human review in automated pipelines — which is already how gemini-cli's own review process works.

Experiment repo: https://github.com/kimjune01/refactor-equivalence

Thanks for your time 🙏

---

**Notes to self:**
- Wait for initial contact/response before sending this
- The 4th PR (24476) had zero diff — excluded from the ask
- If they say yes to reviewing, follow up with the iterative results once the batch finishes

**Blinding: EXCLUDE these reviewers (reviewed the original PRs):**
abhipatel12, gundermanc, spencer426, alisa-alisa, scidomino, ehedlund, kschaab

**Eligible blind reviewers (active contributors, did NOT review these PRs):**
1. NTaylorMullen (332 commits) — top pick
2. jacob314 (273)
3. SandyTao520 (213)
4. mattKorwel (172)
5. olcan (170)
6. jerop (167)
7. chrstnb (156)

Target: 2-3 reviewers for a credible panel. Personalize outreach per person.
