# Phoenix + Postgres + Meilisearch (Scrypath example)

Minimal API-only Phoenix app that depends on Scrypath via **`path: "../.."`** from the monorepo root. It shows the same patterns as the main README (searchable schema, `Scrypath.sync_record/3`, `Scrypath.search/3` with `repo:`) against **real Postgres** and **real Meilisearch**, plus **Oban** wired for a second integration path (`sync_mode: :oban`) so the example matches queue-backed production apps.

## Prerequisites

- Elixir **1.17+** and Erlang/OTP as in the parent project
- Docker with Compose v2

## Stack (Docker)

[`compose.yaml`](compose.yaml) starts:

- **Postgres 16** on host port **5433** (avoids colliding with a local Postgres on 5432). Override with **`PGPORT`** if you change the mapping.
- **Meilisearch v1.15** on host port **7700** (same image tag as library CI).

Both services attach to an explicit bridge network **`scrypath_phx_meili_net`** so you can add an app container later without reworking the layout.

```bash
docker compose up -d
```

## Configure ports and flags (authoritative)

| Variable | Purpose | Default |
|----------|---------|---------|
| **`PGPORT`** | Postgres TCP port on `localhost` | **5433** (`config/dev.exs`, `config/test.exs`) |
| **`SCRYPATH_MEILISEARCH_URL`** | Meilisearch base URL | **`http://127.0.0.1:7700`** |
| **`SCRYPATH_EXAMPLE_INTEGRATION`** | When `1` / `true`, ExUnit runs **`@moduletag :integration`** smoke tests (inline + Oban paths) | unset (those tests **excluded**) |

CI uses the same **Meilisearch v1.15** image tag as this `compose.yaml` (see root **`CONTRIBUTING.md`** for which GitHub Actions jobs run live Meilisearch). This README is the **single detailed** runbook for the example; the golden path links here instead of duplicating the table.

## End-to-end smoke

From this directory (with Compose running or let the script start it):

```bash
./scripts/smoke.sh
```

**CI-shaped default:** the script always runs **`docker compose down`** on exit (trap), so machines do not leak containers—best for automation and first-time contributors.

**Local iteration:** pass **`--keep-up`** to skip teardown and reuse the same Postgres/Meilisearch while you edit tests (`./scripts/smoke.sh --keep-up`). When finished, run **`docker compose down`** from this directory.

The script:

1. Runs **`docker compose up -d`** and **fails fast** if Postgres or Meilisearch is not healthy within 60s.
2. Sets **`SCRYPATH_EXAMPLE_INTEGRATION=1`** so ExUnit includes **`@moduletag :integration`** smoke tests.
3. Runs **`mix deps.get`** and **`mix test`** (the `test` alias creates the test DB and migrates, including **Oban** migrations).

Integration coverage:

- **Inline** — insert row, **`Scrypath.sync_record`** with **`sync_mode: :inline`**, then **`Scrypath.search`** with hydration via **`ScrypathDemo.Repo`**.
- **Oban** — same shape with **`sync_mode: :oban`** and **`ScrypathDemo.Oban`**; tests use **`config :scrypath_demo, Oban, testing: :inline`** so jobs run in-process deterministically while still exercising enqueue metadata and **`Scrypath.Oban.UpsertWorker`** against live Meilisearch.

## Tests without integration

With Compose **Postgres** still required (Sandbox + `ConnCase`):

```bash
docker compose up -d
export PGPORT=5433
mix deps.get
mix test
```

Integration tests are **excluded** unless **`SCRYPATH_EXAMPLE_INTEGRATION=1`** (or `true`). That loop is what you want when iterating quickly without tearing Compose down each time (contrast with **`./scripts/smoke.sh`** default, which always stops Compose on exit).

## Development

```bash
docker compose up -d
export PGPORT=5433
mix deps.get
mix ecto.create
mix ecto.migrate
mix phx.server
```

## Learn more

- [Phoenix guides](https://hexdocs.pm/phoenix/overview.html)
- [Scrypath README](../../README.md) in the repository root
