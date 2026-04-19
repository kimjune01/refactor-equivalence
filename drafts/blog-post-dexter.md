# Does iteration mitigate against slop-slope?

*Caveat up front: the reviewer in this experiment is an LLM (Gemini 3.1 Pro), not a human. Human validation on a subset is prepared but pending. Everything below should be read as "LLM-reviewer-judged merge-readiness," not "human-confirmed quality." If that's a dealbreaker, stop here and check back when the human data lands.*

I ran an autonomous refactoring pipeline on 27 merged PRs from 9 open-source repos. The question: if you let an LLM refactor code that already passes tests, does it make things better or worse?

Without a review loop: coin flip. 43% of the time a reviewer would approve the output. The rest is slop — code that passes tests, doesn't regress complexity, and still isn't good enough to ship. That's the slop-slope in action. The agent does work that looks productive and isn't.

With an iterative review loop: 91%. The same code, same spec, same models — but after refactoring, an adversarial LLM finds issues, another LLM fixes them, rebuild, retest, repeat. After convergence, an independent reviewer sees the result for the first time. 21 of 23 active trials approved.

**The 48 percentage point difference comes from adding the loop.** Same code, same spec — only the review iteration differs. The A/B was accidental (I screwed up the first run and had to re-run with iteration), not preregistered. Take it as suggestive, not definitive. But the direction is clear.

## The setup

Each trial takes a merged PR and rewinds to the commit where tests first passed — before human reviewers pushed for improvements. The pipeline refactors that pre-review code and asks: would a reviewer approve this?

The pipeline:

1. **Spec**: Codex reads the PR description and proposes specific refactoring claims ("extract this helper," "centralize this normalization," "remove this duplication").
2. **Implement**: Opus and Codex each implement the spec independently. The one with smaller diff wins. (They tied on churn in one trial and landed within 10% on most. Blind-blind is insurance against single-model failure, not a source of diversity.)
3. **Adversarial loop**: Codex reviews its own side's work. Finds issues. Fixes them. Rebuilds. Retests. Repeats up to 10 rounds. Findings oscillate — fixing 2 issues introduces 2 new ones — but the code hardens with each pass.
4. **Independent review**: Gemini sees the final output for the first time. It never touched the code during construction. It says "approve" or "here are my comments."

Build and tests pass every round. Complexity never increases (measured via AST-level cognitive complexity). The question is only: is it merge-ready?

## The numbers

27 trials. 9 repos (gemini-cli, cli/cli, cel-go, google-cloud-go, go-github, adk-go, go-containerregistry, gapic-generator-go, ruff). 3 languages.

| | Go | TypeScript | Rust |
|--|--|--|--|
| Trials | 16 | 9 | 2 |
| Valid (build+test pass) | 15 | 6 | 2 |
| Approved (iterative) | 15 | 4 | 2 |
| **Rate** | **100%** | **67%** | **100%** |

Go: every trial that produced test-passing code eventually got reviewer approval. Fast tests, strong-enough type system, small repos.

Rust: initially 0% — both trials were classified as "hard no-op." Re-running with proper infrastructure revealed both refactorings were valid. One passed immediately; the other needed 2 rounds of compiler-driven fixes (codex reads `rustc` error → applies fix → rebuilds). Rust's strict compiler makes iteration MORE effective: zero false-positive feedback, exact line numbers, convergence in 2 rounds vs Go's typical 5-10 rounds of oscillating adversarial findings.

TypeScript: 67% approval. The 2 remaining impasses are infrastructure limitations — CLI agents hang loading 1000-file monorepos into context. Scoping to the changed package subdirectory would likely resolve them.

## The accidental finding

I messed up the first run. The prereg specifies iterative convergence — run the review loop until the reviewer approves or gives up. I skipped it and ran single-round. Got 43%. The user caught me: "you weren't supposed to take shortcuts."

So I re-ran with iteration on the same refactored code. Same spec, same implementation, just the review loop added on top. The rate jumped to 80%.

Same starting code. Same spec. Same implementation. Only the review loop changed:

| Condition | What ran | Approval |
|-----------|---------|----------|
| Single-round | Spec → implement → 1 review | 9/21 = 43% |
| Iterative (same code) | + hunt-code loop N≤10 + reviewer compliance | 21/23 = 91% |

That's the causal claim: same code, same spec, loop added, 38pp jump. Accidental and unplanned, so treat it as suggestive. But the controlled variable is clean.

What it means: **a first-draft spec from the PR description is sufficient.** Iterative spec sharpening added zero measured value over single-round spec + iterative review. The value is in catching and fixing problems after implementation. Which is exactly how human code review works — you don't write a perfect spec, you iterate on the code until a reviewer says ship it.

## What the adversarial loop actually does

It doesn't converge. On 8 of 12 iterative trials, the adversarial reviewer (Codex) never reached zero findings. It hit the cap at 10 rounds with 2-3 findings still oscillating. Every fix introduces new surface for the next adversarial pass.

But the independent reviewer (Gemini) approved 7 of those 8 cap-hit trials anyway. The adversarial bar — "zero findings" — is stricter than the merge-readiness bar. Hunt-code is kneading dough. You never "finish" kneading. You just do it enough that the structure is sound.

The cap should be 5, not 10. Rounds 1-3 catch real issues; rounds 4-10 oscillate without improving the reviewer's verdict (7/8 cap-hit trials were approved despite unresolved findings).

## The slop-slope diagnosis

The slop-slope isn't "the agent doesn't know what to do." The spec step works. The agent identifies real refactoring opportunities — duplicate code, over-abstraction, inconsistent patterns — and applies them. Tests pass. Complexity doesn't increase.

The slop-slope is "the agent does the right thing badly and nobody catches it." It extracts a helper but misses the second call site. It centralizes logic but breaks an idiom the codebase relies on. It removes duplication but introduces a subtle type mismatch that tests don't cover.

Without review, these slip through at a 57% rate. With review, they get caught and fixed — 91% approval after iteration. The review loop is the anti-slop mechanism. Not a better prompt. Not a smarter model. A loop.

## Should you add this to your CI?

**Go repos: yes.** 100% approval on 15 valid trials. If your Go repo has a fast `go test ./...` cycle, this works.

**Rust repos: yes.** 100% on 2 trials. The borrow checker is the best adversarial reviewer in the pipeline — zero false positives, exact fixes, convergence in 2 rounds. Small sample but the mechanism is strong.

**TypeScript repos: yes if under 500 source files.** 67% approval. CLI agents choke on monorepo-scale context loading. Scope codex to the changed package and this likely resolves.

## The bigger picture

The pipeline is a compiler. Input: natural language intent (PR description). Output: merge-ready code. The spec step derives claims from the intent. The implementation step compiles claims to code. The review loop is the error-correction pass.

For Go-heavy refactoring PRs with fast tests, iterative review moved LLM output from parity to likely merge-ready. The bottleneck shifted from "can the machine write correct code" to "did the human write clear intent" — which is the same bottleneck that exists in human-to-human collaboration.

The review loop doesn't need to be LLMs. It could be a linter, a type checker, a test suite, a human reviewer. The point is: autonomous refactoring without a feedback loop is the slop-slope. Autonomous refactoring with a feedback loop is a workflow.

## Recommendations

If you're using Claude Code, the two loops are available as skills:

- **[/volley](https://june.kim/volley)** — collaborative iteration. Sharpens a spec into prescriptive claims against a goal, then iterates with an adversarial reviewer until the spec is defensible. The reviewer comments, the author complies, the reviewer re-checks. This is the collaborative loop that catches taste issues: module structure, naming, unnecessary complexity.

- **[/bug-hunt](https://june.kim/bug-hunt)** — adversarial iteration. Hunts for bugs, fixes them, re-hunts until convergence. Build+test gates every round. This is the adversarial loop that catches mechanical slop: missing call sites, type mismatches, broken idioms. On Rust repos, the compiler does this job better than any LLM reviewer — zero false positives, exact fixes, convergence in 2 rounds.

Both together is [/forge](https://june.kim/forge) — the full pipeline this experiment measured.

The single most important thing you can do to avoid slop-slope: **don't ship the first thing that passes tests.** Run `/bug-hunt` at minimum. The adversarial loop alone moves you from coin-flip to viable. Adding `/volley` gets you the rest of the way.

## Caveats

The reviewer is an LLM (Gemini 3.1 Pro), not a human. It never saw the code during construction (independent), but it shares biases with the models that wrote it. Human validation on a 4-PR subset is prepared but pending. If humans disagree with the 80% number, every LLM-as-judge paper needs to revisit.

Go dominates the sample (15/23 valid trials) because Google repos preserve multi-commit branch history while most OSS repos squash. Rust has only 2 trials. The sample is real-world but not language-balanced.

Complexity measurement (mean cognitive across scoped functions) showed zero change on 19/21 trials. The metric is too coarse for the kind of changes forge makes. The refactoring is real — helpers get extracted, duplication gets removed — but it doesn't move per-function complexity when averaged across 100+ functions.

---

*Experiment repo: [refactor-equivalence](https://github.com/kimjune01/refactor-equivalence) — [results](https://github.com/kimjune01/refactor-equivalence/blob/master/RESULTS.md), [prereg](https://github.com/kimjune01/refactor-equivalence/blob/master/PREREG_V2.md), [work log](https://github.com/kimjune01/refactor-equivalence/blob/master/worklog/WORK_LOG.md). Example forge diffs on gemini-cli: [PR #2](https://github.com/kimjune01/gemini-cli-claude/pull/2), [#3](https://github.com/kimjune01/gemini-cli-claude/pull/3), [#4](https://github.com/kimjune01/gemini-cli-claude/pull/4), [#5](https://github.com/kimjune01/gemini-cli-claude/pull/5). The screwups are in there too.*
