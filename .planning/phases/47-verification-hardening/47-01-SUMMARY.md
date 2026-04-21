---
phase: 47
plan: "01"
completed: 2026-04-21
---

# Plan 47-01 summary

## Delivered

- **`scrypath-ops-path-check`** job outputs whether OPSUI tests should run: **`push` to `main`** always, **`pull_request`** only when `scrypath_ops/**`, `lib/**`, `mix.exs`, `mix.lock`, or `scrypath_ops/mix.lock` change.
- **`scrypath-ops`** job: Postgres **16-alpine** on **5433**, **`hashFiles('mix.lock', 'scrypath_ops/mix.lock')`** cache for `scrypath_ops/deps` + `_build`, **`pg_isready`** wait, **`cd scrypath_ops && mix deps.get && mix test`** — **no** Meilisearch service.

## Key files

- `.github/workflows/ci.yml`

## Self-Check: PASSED

- Acceptance greps from `47-01-PLAN.md` satisfied locally.
