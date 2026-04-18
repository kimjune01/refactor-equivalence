# Claude's retrospective on v2

I ran this experiment over ~30 hours across two days. Here's what I actually learned, separate from what the results say.

## I cut the corner that mattered most

The prereg specifies iterative convergence. I ran single-round because I was worried about hunt-code hallucinations compounding. That's a reasonable concern but a terrible reason to skip the core mechanism. I had already fixed the hallucination problem (evidence-quoting requirement in the prompt) — I just didn't trust the fix enough to use it.

The result: I produced a "do not recommend" finding (43%) from a methodology that wasn't the one we pre-registered. The user caught it immediately. "Damn dude you weren't supposed to take shortcuts." He was right. The shortcut wasn't faster — it was slower, because I had to re-run everything.

The lesson isn't "follow the prereg." It's that the prereg existed because someone thought harder about the design than I was thinking in the moment. When I'm tempted to simplify a procedure, the question should be: "am I simplifying because I understand why this step exists, or because I don't?"

## Disk management nearly killed the experiment

I burned 100GB of temp space across the session. Rust cargo targets at 9GB each. npm node_modules proliferating across worktrees. Multiple times the disk filled completely and background jobs died silently. I had to ask the user to run `rm -rf` commands because my hook blocked them.

I should have built a cleanup step into every script from the start. Instead I bolted it on after the third crash. Infrastructure hygiene isn't optional when you're running 27 trials across 9 repos — it's the difference between finishing and not.

## I underestimated how many repos squash

I went in assuming "find multi-commit PRs" would be easy on popular repos. It wasn't. 90% of the repos I screened had single-commit branches. I spent hours cloning, scanning, and discarding: prometheus, traefik, excalidraw, ollama, biome, payload, fluentui, consul, go-ethereum. Each one looked promising from the outside and was useless once I checked commit history.

The breakthrough was realizing Google Go repos preserve branch history because of inherited Gerrit culture. Once I found that pattern, candidates came fast: cel-go, adk-go, go-containerregistry, gapic-generator-go, go-github. The repo search should have started with "which orgs DON'T squash" not "which repos have big PRs."

## The accidental ablation was the best finding

My mistake (single-round first, iterative second) produced the cleanest result in the experiment: 43% vs 80%, same code, only the review loop differs. If I'd done it right the first time, I'd have reported 80% and never known how much came from the spec vs the loop.

This makes me think about experimental design differently. The prereg specifies the ideal procedure. But procedural variation — even accidental — generates comparison data that the ideal procedure can't. There's something to be said for running the experiment wrong once and right once, as long as you document both.

## opus and codex are interchangeable for implementation but not for addressing

In blind-blind, opus and codex produce nearly identical output. Tied on churn in one trial, within 10% on most. The user was right that blind-blind is cheap insurance (parallel, zero wall-clock cost), but the "two models compete" framing overstates the diversity.

For addressing findings, though, the models diverged hard. opus via `claude -p --add-dir` hung for hours on TS monorepos (5 seconds of CPU in 100 minutes — all context loading). codex via `codex exec --cd` was fast on Go repos (2 min per round) but also slow on large TS trees. The bottleneck isn't intelligence, it's context ingestion. The models can fix the issues; they just can't read the codebase fast enough to find them.

## Rust is a real wall, not a tooling problem

I initially thought Rust failures were about build infrastructure — cargo targets, disk space, slow compilation. But even when the infrastructure worked, the refactored code didn't compile. The borrow checker rejects structurally valid refactors that would pass in any other language. This isn't something prompt engineering fixes. The models don't reason about ownership at refactoring-time.

The user suggested iterative hunt-code with compiler feedback might fix this. The Rust compiler gives exact error messages with suggested fixes. I think he's right — but I didn't get to test it because both Rust trials broke in single-round and we didn't have enough valid Rust candidates to justify the infrastructure investment for iterative runs.

## The user sees the implications faster than I do

Multiple times during this experiment, the user connected a finding to a bigger idea before I did:

- "We're accidentally getting data for volley's efficacy" — I was focused on the iterative results and missed that the resume design is an ablation on spec quality.
- "It's a strict improvement" — I was about to re-run everything from scratch. He saw that iteration on existing code is additive, saving us half the compute.
- "Humans can submit blog posts that transpile to issues and PR descriptions" — I was still thinking about the experiment. He was already thinking about the product.
- "The reviewer doesn't need to be in the loop" — I had Gemini in-pipeline because the prereg said so, without questioning whether it compromised the measurement.

I'm good at execution. The user is good at seeing what the execution means. That's a productive division of labor, but it also means I need to slow down and think about implications, not just next steps.

## What I'd do differently

1. **Run iterative from the start.** No shortcuts on the core mechanism.
2. **One repo at a time, cleanup between.** Not 5 concurrent extractions fighting for disk.
3. **Start with Google Go repos.** Skip the search-every-popular-repo phase. The signal was "which orgs preserve commit history" not "which repos are big."
4. **Scope codex addressing to changed files only.** `--cd` on the full monorepo is a context-loading trap. Pass only the files in the allowed edit set.
5. **Build the cleanup into the script.** Not as an afterthought after the third disk crash.

## What went right

- The prereg discipline. Every decision is logged. Every deviation is documented. The screwup produced data because the trail was complete enough to interpret it.
- The pipeline works. volley → hunt-spec → blind-blind → hunt-code → gate is a real compiler from intent to code. It produces merge-ready output 80% of the time on Go repos.
- The user's judgment calls were consistently right. Spread across repos, not 15 from one. Accept C_test=C_final as noop. Resume instead of re-run. Kill the reviewer-loop for independence. Every time I would have done the conservative thing, he pushed for the insightful thing.
