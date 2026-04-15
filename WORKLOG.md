# Work Log

All decisions, attempts, exclusions, and dead ends. Published alongside results.

---

## 2026-04-14

### Session 1: Prereg design

**Context:** Discussing the prework blog post with Dexter Horthy. The third axis — complexity trajectory — emerged from the conversation. Predicate, transformation, and slop-slope. Most agents skip the third axis.

**Key decisions:**
- Framed as equivalence class: multiple test-passing implementations exist, first one is rarely simplest
- Three-class directional model: past C_final, short of C_final, wrong direction
- C_final is a lossy oracle — satisficing threshold, not optimum
- Reviewer-judged trajectory is the primary classification, scalar complexity is calibration
- Failed refactors (test-breaking) are no-ops, not data. Either you're in the equivalence class or you produced nothing
- The interesting failure is the slop-slope: passing tests while making things worse

**Repo selection:**
- Primary: google/gemini-cli (TypeScript) — 15 PRs
- Secondary candidates: kubernetes/kubernetes (Go), rust-lang/rust (Rust), llvm/llvm-project (C++), django/django (Python) — 3 PRs each, expandable to 10
- Repos are candidates, not locked. Caliber bar is locked. May swap for faster build/test pipelines of equal quality
- Queen's-table argument: if it works on the strictest repos, down-induction to simpler ones

**C_test definition:**
- Backport C_final tests onto earlier commits
- C_test = earliest commit where merge-time tests pass
- Ensures same behavioral contract across all snapshots

**PR selection:**
- Bias toward larger PRs — maximal surprise, strongest evidence
- 100-2000 changed source lines
- Post-cutoff only

**Measurement confidence:**
- Reviewer-judged trajectory is headline (Phase 2 of review task)
- Scalar (mean cognitive complexity) calibrates, doesn't determine
- Boundary threshold δ set after pilot
- Sensitivity analysis across multiple metrics
- Disagreements between reviewer and scalar are findings, not errors

**Scientific method audit (20 questions):**
- Popper: raised P2 from 30% to 50%, added wrong-direction cap at 20%
- Feynman: dev/test non-overlap required, prompt frozen before test set
- Gwern: trail commitment — publish everything including failures and prompt iterations
- Chamberlin: memorization vs. reasoning is irrelevant (Chinese Room) — output quality is what matters
- Hume: down-induction from strict repos to relaxed ones, not induction from sample to all PRs

**Codex (GPT-5.4) review rounds:**
1. Initial review: separate three claims, include failed refactors, lock down environment
2. Failure modes and futility: C_test selection rules, reviewer blinding, convergence stratification
3. Final revision: incorporated all adopt items, deferred pilot decisions
4. Convergence check: one issue (failed-output handling for review) — resolved
5. Sniff after simplification: sample size fix, PR cap, no-op consistency, edit scope
6. Sniff after directional model: edit scope to full PR, scalar for 3-class, enrichment statement
7. Prompt sniff: neutral reviewer labels, mechanical conventions, no categorical bans

**Prompts created:**
- `prompts/meta/generate-repo-prompt.md` — metaprompt for repo-specific refactoring prompts
- `prompts/meta/reviewer-task.md` — two-phase reviewer instructions (forced choice + trajectory classification)
- `prompts/refactor-v1.md` — generic refactoring prompt (to be superseded by repo-specific versions)

**Blog output:**
- New page: `/reading/scientific-method/prereg-audit/` — twenty questions from four centuries of methodology

**Next:**
- Pull dev-set PRs from gemini-cli
- Iterate refactoring prompt on dev set
- Pilot 5 PRs from primary repo
