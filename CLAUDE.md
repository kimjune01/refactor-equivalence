# refactor-equivalence

Experiment repo. Prereg in `PREREG.md`. Trail in `worklog/WORK_LOG.md`.

## Conventions

- Use `/worklog` after every commit, decision, or direction change
- Dev-set and test-set PRs must not overlap. Prompt frozen before test set.
- No-op = agent failed to produce test-passing output; scored as C_test
- Three trajectory classes: past C_final, short of C_final, wrong direction
- Batch expansion: stop on confidence, log every expansion decision before next batch
- Never commit credentials
