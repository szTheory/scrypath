# Phase 47 — Pattern map

Analog files for executor **`read_first`** lists.

| Planned artifact / concern | Role | Closest analog | Notes |
|----------------------------|------|----------------|-------|
| New GitHub Actions job | CI orchestration | `.github/workflows/ci.yml` → **`phoenix-example-integration`** job (lines ~273–343) | Copy Postgres wait; **drop** Meilisearch service + wait for OPSUI |
| Dual lockfile cache | Cache invalidation | Same job: `hashFiles('examples/phoenix_meilisearch/mix.lock', 'mix.lock')` | Replace paths with **`scrypath_ops/mix.lock`** + **`mix.lock`** |
| Root verify alias | Maintainer entry | `mix.exs` **`preferred_envs`** + `lib/mix/tasks/verify.phase*.ex` | Simplest: new **`lib/mix/tasks/verify.opsui.ex`** mirroring **`verify.phase14.ex`** structure (deps + shell to subdirectory) — planner chooses |
| Doc contract tests | Anti-drift | `test/scrypath/docs_contract_test.exs` | `@operator_ia = File.read!("scrypath_ops/docs/operator-ia.md")` style; substring / ordering asserts |
| LiveView env restore | Test isolation | `scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs` **`setup` / `on_exit`** | Same pattern for new cases |
| Posture / errors UI | Injection + rows | `scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs` | **`PostureFakeClient`** pattern for **`{:error, _}`** rows |
| Failed sync counts | Snapshot tests | `scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs` | Extend for **`reason_class_counts`** header consistency |
| Router truth | Routes | `scrypath_ops/lib/scrypath_ops_web/router.ex` | Doc contract compares **`~p"/ops/...`** strings to **`operator-ia.md`** table |

---

## PATTERN MAPPING COMPLETE
