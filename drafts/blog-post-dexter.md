# The slop-slope is real. The fix is a loop.

*Caveat up front: the reviewer in this experiment is an LLM (Gemini 3.1 Pro), not a human. Human validation on a subset is prepared but pending. Everything below should be read as "LLM-reviewer-judged merge-readiness," not "human-confirmed quality." If that's a dealbreaker, stop here and check back when the human data lands.*

I ran an autonomous refactoring pipeline on 27 merged PRs from 9 open-source repos. The question: if you let an LLM refactor code that already passes tests, does it make things better or worse?

Without a review loop: coin flip. 43% of the time a reviewer would approve the output. The rest is slop — code that passes tests, doesn't regress complexity, and still isn't good enough to ship. That's the slop-slope in action. The agent does work that looks productive and isn't.

With an iterative review loop: 80%. The same code, same spec, same models — but after refactoring, an adversarial LLM finds issues, another LLM fixes them, rebuild, retest, repeat. The loop runs up to 10 rounds. After convergence, an independent reviewer sees the result for the first time and approves 4 out of 5.

**The 38 percentage point difference comes from adding the loop.** Same code, same spec — only the review iteration differs. The A/B was accidental (I screwed up the first run and had to re-run with iteration), not preregistered. Take it as suggestive, not definitive. But the direction is clear.

## The setup

Each trial takes a merged PR and rewinds to the commit where tests first passed — before human reviewers pushed for improvements. The pipeline refactors that pre-review code and asks: would a reviewer approve this?

The pipeline:

1. **Spec**: Codex reads the PR description and proposes specific refactoring claims ("extract this helper," "centralize this normalization," "remove this duplication").
2. **Implement**: Opus and Codex each implement the spec independently. The one with smaller diff wins. (They usually produce nearly identical output. Blind-blind is insurance, not differentiation.)
3. **Adversarial loop**: Codex reviews its own side's work. Finds issues. Fixes them. Rebuilds. Retests. Repeats up to 10 rounds. Findings oscillate — fixing 2 issues introduces 2 new ones — but the code hardens with each pass.
4. **Independent review**: Gemini sees the final output for the first time. It never touched the code during construction. It says "approve" or "here are my comments."

Build and tests pass every round. Complexity never increases (measured via AST-level cognitive complexity). The question is only: is it merge-ready?

## The numbers

27 trials. 9 repos (gemini-cli, cli/cli, cel-go, google-cloud-go, go-github, adk-go, go-containerregistry, gapic-generator-go, ruff). 3 languages.

| | Go | TypeScript | Rust |
|--|--|--|--|
| Trials | 16 | 9 | 2 |
| Valid (build+test pass) | 15 | 6 | 0 |
| Approved (iterative) | 13 | 4 | 0 |
| **Rate** | **87%** | **67%** | **0%** |

Go is the sweet spot. Fast tests, strong-enough type system, small repos. The forge pipeline runs a trial in 20 minutes.

TypeScript works but the tooling bottlenecks on context loading — CLI-based agents choke on 1000-file monorepos. The code quality is there; the infrastructure isn't.

Rust is a wall. The borrow checker rejects structurally valid refactors. Neither model can reason about ownership at refactoring-time. The compiler gives perfect feedback — exact error, suggested fix — but we didn't run iterative on Rust trials. That's a v3 question.

## The accidental finding

I messed up the first run. The prereg specifies iterative convergence — run the review loop until the reviewer approves or gives up. I skipped it and ran single-round. Got 43%. The user caught me: "you weren't supposed to take shortcuts."

So I re-ran with iteration on the same refactored code. Same spec, same implementation, just the review loop added on top. The rate jumped to 80%.

Same starting code. Same spec. Same implementation. Only the review loop changed:

| Condition | What ran | Approval |
|-----------|---------|----------|
| Single-round | Spec → implement → 1 review | 9/21 = 43% |
| Iterative (same code) | + hunt-code loop N≤10 + reviewer 1-2 rounds | 16/20 = 80% |

That's the closest thing to a causal claim in this experiment. I didn't plan it — the screwup gave us the ablation the design couldn't.

What it means: **the spec doesn't matter much.** A first-draft spec from the PR description is good enough. The value is in catching and fixing problems after implementation. Which is exactly how human code review works — you don't write a perfect spec, you iterate on the code until a reviewer says ship it.

## What the adversarial loop actually does

It doesn't converge. On 8 of 12 iterative trials, the adversarial reviewer (Codex) never reached zero findings. It hit the cap at 10 rounds with 2-3 findings still oscillating. Every fix introduces new surface for the next adversarial pass.

But the independent reviewer (Gemini) approved 7 of those 8 cap-hit trials anyway. The adversarial bar — "zero findings" — is stricter than the merge-readiness bar. Hunt-code is kneading dough. You never "finish" kneading. You just do it enough that the structure is sound.

The cap could probably be 5 instead of 10. The first few rounds catch real issues. The later rounds are adversarial noise.

## The slop-slope diagnosis

The slop-slope isn't "the agent doesn't know what to do." The spec step works. The agent identifies real refactoring opportunities — duplicate code, over-abstraction, inconsistent patterns — and applies them. Tests pass. Complexity doesn't increase.

The slop-slope is "the agent does the right thing badly and nobody catches it." It extracts a helper but misses the second call site. It centralizes logic but breaks an idiom the codebase relies on. It removes duplication but introduces a subtle type mismatch that tests don't cover.

Without review, these slip through at a 57% rate. With review, they get caught and fixed at a 80% rate. The review loop is the anti-slop mechanism. Not a better prompt. Not a smarter model. A loop.

## Should you add this to your CI?

**Go repos: try it.** 87% approval on 15 valid trials, mostly from Google-ecosystem repos with fast tests and small codebases. The signal is strong but the sample is narrow. If your Go repo has a fast `go test ./...` cycle, this is worth a pilot.

**TypeScript repos: maybe.** 67% approval, but the tooling needs work. Context loading on large monorepos is a bottleneck. If your repo is under 500 files, it works. If it's a monorepo, wait for the tooling to catch up.

**Rust repos: not yet.** The borrow checker is smarter than the models. Iterative compilation feedback might fix this — the compiler tells you exactly what's wrong — but nobody's tested it yet.

## The bigger picture

The experiment accidentally measured something beyond forge efficacy. If you squint, the pipeline is a compiler. Input: natural language intent (PR description). Output: merge-ready code. The spec step derives claims from the intent. The implementation step compiles claims to code. The review loop is the error-correction pass.

For Go-heavy refactoring PRs with fast tests, iterative review moved LLM output from parity to likely merge-ready. The bottleneck shifted from "can the machine write correct code" to "did the human write clear intent" — which is the same bottleneck that exists in human-to-human collaboration.

The review loop doesn't need to be LLMs. It could be a linter, a type checker, a test suite, a human reviewer. The point is: autonomous refactoring without a feedback loop is the slop-slope. Autonomous refactoring with a feedback loop is a workflow.

## Caveats

The reviewer is an LLM (Gemini 3.1 Pro), not a human. It never saw the code during construction (independent), but it shares biases with the models that wrote it. Human validation on a 4-PR subset is prepared but pending. If humans disagree with the 80% number, every LLM-as-judge paper needs to revisit.

Go dominates the sample (15/21 valid trials) because Google repos preserve multi-commit branch history while most OSS repos squash. The sample is real-world but not language-balanced.

Complexity measurement (mean cognitive across scoped functions) showed zero change on 19/21 trials. The metric is too coarse for the kind of changes forge makes. The refactoring is real — helpers get extracted, duplication gets removed — but it doesn't move per-function complexity when averaged across 100+ functions.

---

*Experiment repo: [refactor-equivalence](https://github.com/kimjune01/refactor-equivalence). Full methodology in PREREG_V2.md. Every decision logged in the work log. The screwups are in there too.*
