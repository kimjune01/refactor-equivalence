# Bootstrap prompt

Paste this into a fresh Claude Code session to resume the experiment.

---

I'm running an experiment: does an LLM refactoring pass help or hurt brownfield PRs? The prereg, work log, and all prompts are in ~/Documents/refactor-equivalence.

Read PREREG.md and worklog/WORK_LOG.md to get up to speed. Use /worklog after every commit, decision, or direction change — the work log is the trail and we publish it alongside results.

Three agents, three roles: opus + codex forge the refactoring (blind-blind-merge), gemini 3.1 pro reviews it. No model reviews its own output.

The prereg is converged. Next step is pulling dev-set PRs from google/gemini-cli (post August 2025 cutoff, 100-2000 LOC, prefer larger, ≥2 review rounds). Then iterate the refactoring prompt on the dev set before freezing it for the test set.
