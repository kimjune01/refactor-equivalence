# v2 samples

Per-trial forge-pipeline artifacts for v2. See PREREG_V2.md §Trail commitment.

## Layout

```
samples/v2/
  candidates-<repo>.json        # pre-selection logs (raw gh output)
  candidate-pool-<repo>.md      # per-candidate post-exclusion size + feasibility
  exclusions.md                 # rolling per-PR include/exclude log
  dev-set.md                    # locked dev-set PRs (frozen before test)
  test-set.md                   # locked test-set PRs (frozen before extraction)
  <repo>-<pr>/                  # per-trial artifact dir
    meta.json
    goal/
    inputs/
    volley/
    blind-blind/
    gates/
    reviewer-loop/
    c_llm/
    measurements/
    phase7/
    anomalies.md
    deviations.md
    no-op-class.txt
```
