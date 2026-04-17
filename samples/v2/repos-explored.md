# v2 repos explored

All repos screened during v2 candidate selection. Sorted by outcome.

## Repos with valid trials

| Repo | Lang | Stars | Valid | Hard no-op | Notes |
|------|------|-------|-------|------------|-------|
| google-gemini/gemini-cli | TS | 101k | 5 | 2 | Primary repo. Pool exhausted ≥500 lines. |
| cli/cli | Go | ~40k | 2 | 0 | Few large PRs. Fast Go tests. |
| google/cel-go | Go | ~2k | 2 | 0 | Google review culture. Instant tests. |
| googleapis/google-cloud-go | Go | ~4k | 2 | 0 | Google review culture. Fast tests. |

## Repos attempted but zero valid

| Repo | Lang | Stars | Candidates tested | Failure mode |
|------|------|-------|-------------------|-------------|
| astral-sh/ruff | Rust | ~35k | 4 extracted, 2 pipelined | Both pipelines hard no-op (build/test fail). Disk pressure from cargo target/ (~9GB each). |
| biomejs/biome | Rust | ~15k | 7 extracted | 3 NO-PASS, 4 failed from disk pressure. Shared cargo target grew to 38GB. |
| payloadcms/payload | TS | ~30k | 4 extracted | All NO-PASS. pnpm monorepo; C_final tests don't pass at earlier commits. |
| microsoft/fluentui | TS | ~18k | 3 extracted | 2 NO-PASS (build infra too complex for cleanroom), 1 too small. yarn monorepo. |
| ollama/ollama | Go | 169k | 7 screened | All single-commit PRs (force-push culture). Zero multi-commit branches. |
| hashicorp/consul | Go | ~28k | 1 attempted | `go test ./...` too slow (~20+ min per commit). Killed. |
| ethereum/go-ethereum | Go | ~48k | 0 completed | Disk filled before extraction finished. `go test ./...` slow. |

## Repos screened but not cloned (insufficient multi-commit big PRs)

### Go (stars >5000, merged post 2025-10-01)
| Repo | Multi-commit big PRs | Reason skipped |
|------|---------------------|----------------|
| kubernetes/kubernetes | 0/5 | Single-commit (force-push) |
| moby/moby | 0/5 | Single-commit |
| docker/compose | 0/5 | Single-commit |
| prometheus/prometheus | 0/5* | Cloned, then dropped — PRs mostly single-commit |
| traefik/traefik | 0/5* | Cloned, then dropped |
| gohugoio/hugo | 0/5 | Only 7 reviewed PRs post-cutoff |
| junegunn/fzf | 0/5 | 11 reviewed PRs, mostly small |
| jesseduffield/lazygit | 0/5 | 3 reviewed PRs |
| pocketbase/pocketbase | 0/5 | 0 reviewed PRs post-cutoff |
| hashicorp/terraform | 2-3 multi-commit | PRs viable but most are dep bumps; did not clone |
| hashicorp/nomad | 0/5 | Single-commit |
| grafana/grafana | 0/5* | Cloned briefly, 1-commit PRs |
| grafana/loki | 0/5 | Not checked in detail |
| cockroachdb/cockroach | 0/5 | Single-commit |
| cockroachdb/pebble | 0/5 | Single-commit |
| minio/minio | 0/5 | Single-commit |
| rclone/rclone | — | Not checked |
| syncthing/syncthing | — | Not checked |
| caddyserver/caddy | 0/5 | Single-commit |
| nats-io/nats-server | 0/5 | Single-commit |
| gravitational/teleport | 0/5 | Single-commit |
| pulumi/pulumi | 0/5 | Single-commit |
| bufbuild/buf | 0/5 | Single-commit |
| charmbracelet/bubbletea | 0/0 | No big reviewed PRs |
| charmbracelet/lipgloss | 2/3 multi | Too few candidates |
| gofiber/fiber | 1/1 multi | Only 1 candidate |
| labstack/echo | 1/1 multi | Only 1 candidate |
| spf13/cobra | 0/0 | No big reviewed PRs |
| gorilla/mux | 0/0 | No big reviewed PRs |
| gin-gonic/gin | 0/0 | No big reviewed PRs |
| go-chi/chi | 0/0 | No big reviewed PRs |
| urfave/cli | 0/0 | No big reviewed PRs |
| vitessio/vitess | 1/5 | Too few multi-commit |

### Rust (stars >3000)
| Repo | Multi-commit big PRs | Reason skipped |
|------|---------------------|----------------|
| rust-lang/rust | 0/5 | Single-commit |
| denoland/deno | 0/5 | Single-commit; also checked deeper, only 2 big PRs |
| tauri-apps/tauri | 1/5 | Too few |
| tokio-rs/tokio | 0/5 | Single-commit |
| servo/servo | 0/5 | Single-commit |
| alacritty/alacritty | — | Not checked |
| BurntSushi/ripgrep | — | Not checked |
| astral-sh/uv | — | Not checked (same team as ruff) |
| zed-industries/zed | — | Not checked |
| apache/arrow-rs | 0/5 | Single-commit |
| influxdata/influxdb | 0/5 | Single-commit |
| tikv/tikv | 0/5 | Single-commit |

### TypeScript / JavaScript (stars >5000)
| Repo | Multi-commit big PRs | Reason skipped |
|------|---------------------|----------------|
| microsoft/TypeScript | 0/5 | Single-commit |
| facebook/react | 0/5 | Single-commit |
| sveltejs/svelte | 0/5 | Single-commit |
| vuejs/core | 0/5 | Single-commit |
| microsoft/playwright | 0/6 | All 1-2 commits on big PRs |
| vercel/next.js | 2 multi-commit | Huge repo; 2 candidates only |
| shopify/hydrogen | 1 multi-commit | 1 viable candidate, too few |
| n8n-io/n8n | 0/5 | Single-commit; also only 2 PRs ≥500 |
| supabase/supabase | 0/5 | Single-commit |
| directus/directus | 0/5 | Single-commit |
| medusajs/medusa | 0/5 | Single-commit |
| cloudflare/workers-sdk | 0/5 | Single-commit |
| excalidraw/excalidraw | — | Cloned briefly, dropped |
| shadcn-ui/ui | — | Not checked |
| tailwindlabs/tailwindcss | 0/0 | No big reviewed PRs |
| trpc/trpc | 0/0 | No big reviewed PRs |
| effect-ts/effect | 0/0 | No big reviewed PRs |
| hono-dev/hono | 0/0 | No big reviewed PRs |
| calcom/cal.com | 0/0 | 0 reviewed PRs post-cutoff |
| refinedev/refine | 3/5 multi | Didn't pursue (TS framework, similar niche to gemini-cli) |
| strapi/strapi | 2 multi-commit | 2 viable but didn't clone |

### Java
| Repo | Multi-commit big PRs | Reason skipped |
|------|---------------------|----------------|
| elastic/elasticsearch | 5 commits on 1 PR | Didn't pursue (Java not in v2 scope) |
| apache/kafka | 4 commits on 1 PR | Didn't pursue (Java) |
| apache/spark | 0/5 | Single-commit |
| apache/flink | 0/5 | Single-commit |
| apache/pulsar | 6 commits on 1 PR | Didn't pursue (Java) |

### Other
| Repo | Lang | Notes |
|------|------|-------|
| neovim/neovim | Vim Script/C | 0/5 single-commit |
| tree-sitter/tree-sitter | Rust | 0/5 single-commit |

## Key structural finding

~90% of popular OSS repos have single-commit PR branches due to force-push/rebase culture. The v2 C_test extraction methodology requires multi-commit branches to find "earliest C_final-tests-passing commit." This structural constraint limits the viable repo pool to ~5-10% of active open-source projects.

Repos with multi-commit branches tend to share: Google-internal review culture (gemini-cli), GitHub's own repos (cli/cli), or Microsoft enterprise-style repos (fluentui — though build infra was too complex).

**v3 recommendation:** Use GitHub Review API (`PullRequestReview.commit_id`) to find C_test instead of git commit traversal. This unlocks all repos regardless of force-push culture.
