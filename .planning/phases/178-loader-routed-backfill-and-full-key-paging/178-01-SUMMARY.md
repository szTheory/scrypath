---
phase: 178-loader-routed-backfill-and-full-key-paging
plan: 01
subsystem: test-harness
status: complete
tags: [testing, ecto, sqlite, postgres, backfill, loader]
requires: []
provides:
  - Scrypath.TestSupport.LoaderBackfillCases (shared __using__ case template parameterized by repo)
  - Scrypath.TestSupport.SQLiteSandboxRepo
  - Scrypath.TestSupport.PostgresRepo
  - Scrypath.TestSupport.LoaderBackfill.{Migration, Post, Category, Product, Article, Membership, Device, KeylessEvent, RecordingBackend}
  - ":postgres ExUnit tag gated on SCRYPATH_POSTGRES_URL"
affects: [178-02, 178-03, 178-04, 178-05]
tech-stack:
  added: ["postgrex ~> 0.22 (only: :test, runtime: false; locked 0.22.4)"]
  patterns:
    - "Shared ExUnit case template via defmacro __using__(repo:) instead of ExUnit parameterize (Elixir 1.17 floor)"
    - "One composed ExUnit exclude list in test_helper.exs"
    - "Test repos start adapter apps (ecto_sql, postgrex) explicitly so runtime: false deps work"
key-files:
  created:
    - test/support/sqlite_sandbox_repo.ex
    - test/support/loader_backfill_fixtures.ex
    - test/support/loader_backfill_cases.ex
    - test/support/postgres_repo.ex
    - test/scrypath/loader_backfill_sqlite_test.exs
    - test/scrypath/loader_backfill_postgres_test.exs
  modified:
    - test/test_helper.exs
    - mix.exs
    - mix.lock
    - compose.yaml
decisions:
  - "PostgresRepo supplies a placeholder database path when SCRYPATH_POSTGRES_URL has none, because Ecto.Repo.Supervisor.parse_url/1 rejects server-only URLs; the database is still forced to scrypath_test<partition>"
  - "postgrex kept runtime: false; setup_repo!/1 calls Application.ensure_all_started(:ecto_sql) and (:postgrex) for the Postgres adapter, resolving RESEARCH Assumption A1 without widening the dep"
  - "Both test repos set log: false so shared-case query logs do not flood test output"
metrics:
  duration: ~25min
  completed: 2026-10-25
actuals:
  tokens: 3550
  tasks: 2
  commits: 2
plan_head_before: fcb9b638329c8d43ae087a5ea956d52c275140fd
plan_head_after: e7bee37be4b4d6366273817560ec209019c9ffee
---

# Phase 178 Plan 01: Real-DB loader/backfill test harness Summary

One `__using__` case template (`Scrypath.TestSupport.LoaderBackfillCases`) runs the same loader/backfill tests against a dedicated SQLite sandbox repo in the core lane and against real Postgres 16 when `SCRYPATH_POSTGRES_URL` is set. A tracer test pages 5 posts in batches of 2 end-to-end on both adapters.

## What was built

- **SQLiteSandboxRepo**: tmp-file database path cached in `:persistent_term`, Sandbox pool, `pool_size: 2` (never 1, Migrator deadlock), WAL, busy_timeout.
- **PostgresRepo**: reads only `SCRYPATH_POSTGRES_URL`, parses it itself, then forces `database: "scrypath_test<MIX_TEST_PARTITION>"`, Sandbox pool, `pool_size: 10`.
- **Fixtures**: portable inline migration (`lb_posts`, `lb_categories`, `lb_products`, `lb_articles`, composite-key `lb_memberships` and `lb_devices` with `primary_key: false`, keyless `lb_keyless_events`); the schemas later plans need (`Product` with `preload: [:category]`, `Article.search_records/2` that returns pinned out-of-batch extras, composite `"<a>:<b>"` document ids); `RecordingBackend` that writes to the mailbox and returns `task: nil`.
- **Case template**: `setup_all` → `setup_repo!/1` (storage_down/up, start_supervised, `Ecto.Migrator.up`, sandbox `:manual`, SQLite file cleanup); `setup` checks out the sandbox; helpers `backfill!/3` and `recorded_upserts/0`; one tracer test.
- **test_helper.exs**: one `ExUnit.configure(exclude: ...)` composing `[:integration, :requires_clean_workspace]` (unless SCRYPATH_INTEGRATION) and `[:postgres]` (unless SCRYPATH_POSTGRES_URL).
- **compose.yaml**: `postgres:16-alpine` on host 5434 with a `pg_isready` healthcheck so `docker compose up -d --wait postgres` gates readiness. The header points at `mix verify.postgres`, which plan 02 adds.

## Verification run

- `mix test test/scrypath/loader_backfill_sqlite_test.exs`: 1 test, 0 failures
- `mix test test/scrypath/backfill_test.exs test/scrypath/reindex_test.exs test/scrypath/oban/worker_test.exs`: 31 tests, 0 failures
- `docker compose up -d --wait postgres` then `SCRYPATH_POSTGRES_URL=postgres://postgres:postgres@127.0.0.1:5434 mix test --include postgres test/scrypath/loader_backfill_postgres_test.exs`: 1 test, 0 failures. Ran twice to confirm drop/recreate is idempotent. Only `scrypath_test` was created on the server.
- With the URL unset: both entry files run as `1 test, 0 failures (1 excluded)`, and `:postgres` shows in the excluded tags
- Full `mix test`: 4 properties, 742 tests, 0 failures (12 excluded)
- `mix format --check-formatted`, `mix credo --strict`, and `mix compile --warnings-as-errors` (dev and test) all exit 0
- Real Postgres was available locally through Docker, so the Postgres result above is a real pass. The compose container was stopped afterward to free port 5434.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Server-only Postgres URL rejected by parse_url/1**
- **Found during:** Task 2 Postgres verify
- **Issue:** `Ecto.Repo.Supervisor.parse_url/1` raises `Ecto.InvalidURLError` ("path should be a database name") on the documented `postgres://postgres:postgres@127.0.0.1:5434`.
- **Fix:** `with_database_path/2` adds `/scrypath_test<partition>` as the path when the URL has none. The forced `database:` override still applies afterward.
- **Files modified:** test/support/postgres_repo.ex
- **Commit:** e7bee37b

**2. [Rule 3 - Blocking] Adapter apps not started with runtime: false**
- **Issue:** `ecto_sqlite3` and `postgrex` are `runtime: false`, so their applications may not be running.
- **Fix:** `setup_repo!/1` calls `Application.ensure_all_started(:ecto_sql)` and, for Postgres, `(:postgrex)` before starting the repo. This kept `runtime: false` (RESEARCH A1 fallback not needed).
- **Commit:** bbffe968 / e7bee37b

**3. [Minor] `log: false` on both test repos** to keep debug query logs out of test output.

## Known Stubs

None. The schemas `Product`, `Article`, `Membership`, `Device`, and `KeylessEvent` are intentional fixtures for plans 03 and 04. No test here exercises them yet.

## Threat Flags

None beyond the plan's register. T-178-01 is mitigated: only the namespaced variable is read, and the database is forced after parsing. T-178-SC: the lock gained only the `postgrex` entry.

## Self-Check: PASSED

- All 6 created files exist. Commits bbffe968 and e7bee37b are ancestors of HEAD.
