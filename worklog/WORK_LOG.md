# Work Log

## 2026-04-14

### 19:30 — Session start: prereg design with Dexter Horthy

Discussion about the prework blog post surfaced a third axis for PR review: complexity trajectory (the slop-slope). Predicate and transformation are axes 1 and 2; most agents skip axis 3. Decided to design an experiment testing whether an LLM refactoring pass after tests pass can control this axis.

### 19:45 — Repo and prereg scaffolding

Created `~/Documents/refactor-equivalence/`. Initial prereg: equivalence class framing, three claims (simplification, convergence, merge-readiness), 30 PRs from gemini-cli. Refactoring prompt v1 drafted. Extraction script scaffolded.

### 20:00 — Codex review rounds 1-3

Volleyed prereg with GPT-5.4 three times. Major changes: separated three claims, failed refactors stay in dataset, clean-room procedure (strip .git, no network), post-cutoff PRs only, C_final renamed from C_merge, operational C_test definition, multiple reviewers per PR, mixed-effects model, pilot for feasibility only, futility conditions.

### 20:15 — Simplified failure model

Test-passing is a precondition, not a variable. Agent either produces a member of the equivalence class (measure it) or doesn't (no-op, scored as C_test). Dropped the five-category failure taxonomy. The interesting failure is the slop-slope: passing tests while increasing complexity.

### 20:25 — Repo selection

Primary: google/gemini-cli (15 PRs). Secondary candidates: kubernetes (Go), rust-lang/rust (Rust), llvm (C++), django (Python) — 3 PRs each, expandable to 10. Caliber bar locked, specific repos not locked. Queen's-table argument: if it works on the strictest repos, down-induction to simpler ones is plausible.

### 20:30 — C_test definition fix

Backport C_final tests onto earlier commits. C_test = earliest commit where merge-time tests pass. Ensures same behavioral contract across all snapshots.

### 20:35 — Bias toward larger PRs

Minimum 100 LOC, maximum 2000 LOC. Prefer larger within range. Maximal surprise: if refactoring works on large PRs, small ones are implied.

### 20:40 — Cut convergence, add three-class directional model

Dropped distance-to-C_final as a metric. C_final is a directional proxy, not ground truth. Each trial classified: past C_final (strongest evidence), short of C_final (improved but not enough), wrong direction (slop-slope). Reviewer-judged trajectory is headline; scalar complexity calibrates.

### 20:50 — Measurement confidence: reviewer-judged + scalar calibration

Codex recommended (and we adopted): reviewer classification is primary, scalar is calibration. Boundary threshold δ set after pilot. Sensitivity analysis across multiple metrics. Disagreements are findings about metric validity.

### 20:55 — Prompts directory

Created `prompts/meta/generate-repo-prompt.md` (metaprompt for repo-specific prompts), `prompts/meta/reviewer-task.md` (two-phase reviewer instructions), updated `prompts/refactor-v1.md` (agent gets diff + allowed files, fewer concepts > fewer lines).

### 21:00 — Scientific method audit pass

Walked the prereg through all 20 thinkers from the /reading/scientific-method/ collection. Two real catches: Popper (P2 bar too low, raised from 30% to 50%) and Feynman (dev/test circularity, added non-overlap requirement). Added trail commitment, acknowledged narrow causal claim, dropped memorization threat per Chinese Room.

### 21:05 — Blog: prereg audit page

Created `/reading/scientific-method/prereg-audit/` with 20 questions from the collection. Each maps to a thinker + failure mode. Then moved it to `/methodology` as blog post `2026-04-14-prereg-audit.md`. Renamed to "Prereg Checklist." Copyedited: agent audience explicit, questions 3/5/12/18 sharpened, closing rewrites.

### 21:15 — Ran own checklist against own prereg

Five gaps fixed: Q3 assumptions listed, Q8 competing explanations, Q12 paradigm assumption, Q16 PPV estimate, Q20 expansion is exploratory not confirmatory.

### 21:25 — Final codex sniff: edit-set leak fixed

Reverted LLM edit scope from C_base→C_final to C_base→C_test. Giving the LLM the C_final file list was information leakage (which files reviewers changed). Two-analysis rule for no-ops: intent-to-treat for P3, observed-only for mixed model. Operational definitions for trajectory classes. Down-induction softened to "plausible, not guaranteed."

### 21:30 — Migrated from WORKLOG.md to worklog/WORK_LOG.md

Previous work log in WORKLOG.md consolidated into structured worklog format. Session-persistent logging activated.

**Status:** Prereg converged after 7 codex rounds + checklist audit. Ready to start pulling dev-set PRs from gemini-cli.
