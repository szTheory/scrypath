# Contributing

## Maintainer: B1 evidence

- **B1** library work is **frozen** against the in-repo ledger **`.planning/EVID-01-b1-v1.14.md`**: cite **`EVID-57-*`** row IDs on PRs that touch **`lib/scrypath/`** or implement **LIB-01** / **LIB-02** / **LIB-03** for **v1.14** (see the PR template). The ledger is **append-only after freeze**—do not rewrite shipped rows.

## First hour and canonical docs

- New contributors: follow the README **Quick Path** into [`guides/golden-path.md`](guides/golden-path.md) for the linear **`:inline`** first-hour story.
- **Sync modes, visibility, and operator lifecycle** live in [`guides/sync-modes-and-visibility.md`](guides/sync-modes-and-visibility.md)—update that guide instead of duplicating semantics in README or here.
- Changing published docs should keep **`mix docs --warnings-as-errors`** green. The optional docs contract suite remains available via **`mix test test/scrypath/docs_contract_test.exs`**, but it is no longer part of the default CI and release gates.

## Integrators: pitfalls before you file an issue

Skim [`guides/common-mistakes.md`](guides/common-mistakes.md) when search or sync “feels wrong” but the database write succeeded—most first-hour confusion is a mismatch between sync mode expectations and search visibility, not silent data loss.

## Verification

Use the normal fast suite during development:

```sh
mix test --exclude integration --exclude docs_contract
```

Run the full integration verification (`mix verify.phase5`) when you change backfill, reindex, Meilisearch integration, or the operator docs:

```sh
SCRYPATH_INTEGRATION=1 \
SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 \
mix verify.phase5
```

That command runs:

- focused backfill/reindex/operator contract tests
- `mix docs --warnings-as-errors`
- live Meilisearch integration verification

If you do not have a Meilisearch instance running locally, you can still run the non-integration portion:

```sh
mix verify.phase5 --skip-integration
```

The fast pull-request gate for federation and multi-search runtime behavior is the Phase 41 verify alias. It stays free of Meilisearch services. Heavier integration paths, including live Meilisearch verification for backfill, reindex, and operator flows, still live on the Phase 5 verify alias and the dedicated integration jobs in CI.

The Phase 43 verify alias is the complementary fast gate for **per-query Plane B** runtime tests (allowlisted `:per_query` options, `search_many/2` merge semantics). Run that alias when you touch those paths locally; CI enforces the same gate in the **`quality`** job alongside the other phase verify tasks.

Run **`mix verify.opsui`** from the repository root when you change the optional **`scrypath_ops`** operator Phoenix app or its path dependency on the core library. It runs **`cd scrypath_ops && mix deps.get && mix test`**, and the dedicated **`scrypath-ops`** CI job now invokes this same root task (Postgres-backed Ecto setup, no Meilisearch service).

When you change **`scrypath_ops/docs/*.json`** playbook fixtures, golden workspace playbooks, or other flat `*.json` catalogs that ship beside **`scrypath_ops`**, also run **`cd scrypath_ops && mix scrypath_ops.playbooks.validate PATH`** from the repository root, where **`PATH`** is the directory containing those JSON files (non-recursive; same invocation shape as the Mix task **`Mix.Tasks.ScrypathOps.Playbooks.Validate`**).

## CI

GitHub Actions (see [`.github/workflows/ci.yml`](.github/workflows/ci.yml)) runs these jobs:

| Job | Purpose |
|-----|---------|
| **`test`** | Matrix (Elixir 1.17.3 / OTP 26.2.5 and Elixir 1.19.0 / OTP 28.1): `mix compile --warnings-as-errors`, `mix test --exclude integration --include requires_clean_workspace` |
| **`quality`** | Format, `mix verify.workspace_clean`, Credo, Dialyzer, `mix docs --warnings-as-errors`, `mix hex.audit`, plus focused verify gates for release, operator, faceting, drift, federation, and per-query runtime paths. |
| **`phase5-verification`** | Service: Meilisearch v1.15. `SCRYPATH_INTEGRATION=1`, `mix verify.phase5` (live integration + docs slice for backfill/reindex) |
| **`phase13-verification`** | Service: Meilisearch. `SCRYPATH_INTEGRATION=1`, `mix verify.phase13` (operator integration path) |
| **`meilisearch-smoke`** | Service: Meilisearch. `mix verify.meilisearch_smoke` (curated live suites: `live_meilisearch_verification`, `live_operator_verification`, `search_many_integration`, `settings_hot_apply_integration`) |
| **`phoenix-example-integration`** | Services: Postgres 16 + Meilisearch v1.15. `SCRYPATH_EXAMPLE_INTEGRATION=1`, `PGPORT=5433`, `SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700`. **CI** runs **`cd examples/phoenix_meilisearch`**, then **`mix deps.get`**, then **`mix test`** (same sequence as `.github/workflows/ci.yml`)—**not** `./scripts/smoke.sh`. **`./scripts/smoke.sh`** is a **local DX harness** under `examples/phoenix_meilisearch/` (Compose + env defaults aligned to CI); use it for interactive runs, not as the Actions test driver. See the example README for env tables. |
| **`scrypath-ops-path-check` / `scrypath-ops`** | Service: Postgres 16 only (no Meilisearch). Path gate: runs on **`push` to `main`** unconditionally, and on **`pull_request`** when **`scrypath_ops/**`**, **`lib/**`**, **`mix.exs`**, **`mix.lock`**, or **`scrypath_ops/mix.lock`** change. Executes **`mix verify.opsui`** from the repo root, which shells into **`scrypath_ops`** for **`mix deps.get`** and **`mix test`**. |

The root [`compose.yaml`](compose.yaml) is only for **local** Meilisearch when running smoke tasks; CI uses the workflow **`services:`** block instead.

## Example app (Postgres + Meilisearch)

For a **multi-container-shaped** local stack (Postgres + Meilisearch + Phoenix + **Oban**) and a scripted E2E smoke (**inline** and **`:oban`** paths), see [`examples/phoenix_meilisearch/README.md`](examples/phoenix_meilisearch/README.md)—that file is the **canonical env + command** reference for the example. **CI** under **`phoenix-example-integration`** runs **`mix deps.get`** then **`mix test`** in the example directory (see **CI** table); **`./scripts/smoke.sh`** remains a **local** orchestration path, not the GitHub Actions entrypoint.
