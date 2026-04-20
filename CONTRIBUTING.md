# Contributing

## Verification

Use the normal fast suite during development:

```sh
mix test --exclude integration
```

Run the full integration verification (`mix verify.phase5`) when you change backfill, reindex, Meilisearch integration, or the operator docs:

```sh
SCRYPATH_INTEGRATION=1 \
SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 \
mix verify.phase5
```

That command runs:

- focused backfill/reindex/operator contract tests
- documentation contract tests
- `mix docs --warnings-as-errors`
- live Meilisearch integration verification

If you do not have a Meilisearch instance running locally, you can still run the non-integration portion:

```sh
mix verify.phase5 --skip-integration
```

`mix verify.phase41` is the fast pull-request gate for federation-facing docs and the published-doc contract suite. It stays free of Meilisearch services. Heavier integration paths—including live Meilisearch verification for backfill, reindex, and operator flows—still live on `mix verify.phase5` and the dedicated integration jobs in CI.

## CI

GitHub Actions (see [`.github/workflows/ci.yml`](.github/workflows/ci.yml)) runs these jobs:

| Job | Purpose |
|-----|---------|
| **`test`** | Matrix (Elixir 1.17.3 / OTP 26.2.5 and Elixir 1.19.0 / OTP 28.1): `mix compile --warnings-as-errors`, `mix test --exclude integration --include requires_clean_workspace` |
| **`quality`** | Format, `mix verify.workspace_clean`, Credo, Dialyzer, `mix docs --warnings-as-errors`, `mix hex.audit`, plus focused verify gates (phases **11**, **13** with `--skip-integration`, **14**, **20**, **22**, **26**, **28**, **41** — `mix verify.phase41` and siblings; see `lib/mix/tasks/verify.*`) |
| **`phase5-verification`** | Service: Meilisearch v1.15. `SCRYPATH_INTEGRATION=1`, `mix verify.phase5` (live integration + docs slice for backfill/reindex) |
| **`phase13-verification`** | Service: Meilisearch. `SCRYPATH_INTEGRATION=1`, `mix verify.phase13` (operator integration path) |
| **`meilisearch-smoke`** | Service: Meilisearch. `mix verify.meilisearch_smoke` (curated live suites: `live_meilisearch_verification`, `live_operator_verification`, `search_many_integration`, `settings_hot_apply_integration`) |
| **`phoenix-example-integration`** | Services: Postgres 16 + Meilisearch v1.15. `SCRYPATH_EXAMPLE_INTEGRATION=1`, `PGPORT=5433`, `SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700`; runs **`cd examples/phoenix_meilisearch && mix test`** — proves the Phoenix example **inline** + **Oban** integration tests against live services (consumer-shaped E2E). Approximate locally with Compose + the same env vars (see example README) or **`cd examples/phoenix_meilisearch && ./scripts/smoke.sh`**. |

The root [`compose.yaml`](compose.yaml) is only for **local** Meilisearch when running smoke tasks; CI uses the workflow **`services:`** block instead.

## Example app (Postgres + Meilisearch)

For a **multi-container-shaped** local stack (Postgres + Meilisearch + Phoenix + **Oban**) and a scripted E2E smoke (**inline** and **`:oban`** paths), see [`examples/phoenix_meilisearch/README.md`](examples/phoenix_meilisearch/README.md)—that file is the **canonical env + command** reference for the example. **CI** runs the same **`mix test`** path under **`phoenix-example-integration`** (see table above).
