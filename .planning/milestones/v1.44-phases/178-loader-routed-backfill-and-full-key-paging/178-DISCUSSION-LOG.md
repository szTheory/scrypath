# Phase 178: Loader-routed backfill and full-key paging - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-25
**Phase:** 178-loader-routed-backfill-and-full-key-paging
**Areas discussed:** Loader integration shape, Omitted records, Composite keyset query, Cursor shape, Real-Postgres CI lane, Test tagging and harness, SQLite parity

The maintainer asked for a research fan-out with one-shot coherent recommendations ("so I don't have to think"). Three advisor-researcher subagents researched the areas in parallel, and Claude synthesized and selected the options. No interactive questions were asked.

---

## Loader integration shape

| Option | Description | Selected |
|--------|-------------|----------|
| Ids-then-`Loader.load/3` | Keyset-select key columns, reload by id | |
| Hybrid records-in Loader entry point | Scoped full rows, then shared preload or `search_records/2` | ✓ |
| Compose preload into base query | `preload(^declared)` on the query | |

**Choice:** Hybrid. It avoids regressing custom-id schemas with no `search_records/2`, keeps one query on the default path, and matches searchkick, meilisearch-rails, elasticsearch-model and Scout.

## Omitted records in a live backfill

| Option | Description | Selected |
|--------|-------------|----------|
| Silently skip | Never delete | |
| Skip and report | Counts only | |
| Delete like Oban, and report; reindex counts only | Matches the documented contract | ✓ |

**Choice:** Delete within scope, report `removed`; reindex reports `omitted`. Prior art: searchkick `full:` and meilisearch-rails `if:`/`unless:`.

## Composite keyset query

| Option | Description | Selected |
|--------|-------------|----------|
| OR-expansion | Rails/paginator shape; O(n²) on Postgres | |
| OR-expansion + redundant leading bound | Portable, index-usable leading range | ✓ |
| Row-value fragment | Best Postgres plan; per-arity, loses type inference, not portable | |
| Decomposed seek | Optimal index use, extra round trips, novel | |

**Choice:** OR-expansion plus a leading bound, behind a private builder seam.

## Cursor shape

| Option | Description | Selected |
|--------|-------------|----------|
| Scalar for single, keyword for composite | Non-breaking, Ecto-shaped | ✓ |
| Always keyword | Breaking | |
| New `:cursor` key | Redundant; reserves the name | |
| Map/tuple | Unordered or unnamed | |

## Real-Postgres CI lane

| Option | Description | Selected |
|--------|-------------|----------|
| Postgres service in `backend (required)` + new `verify.postgres` | Gates the PR, core stays service-free | ✓ |
| Fold into `verify.meilisearch_smoke` | Misnames the task | |
| `core (required)` | Breaks the service-free contract | |
| phoenix-example (advisory) | Doesn't gate | |

## Test tagging and harness

**Choice:** a `:postgres` tag gated on `SCRYPATH_POSTGRES_URL`; postgrex only in `:test`; the ecto_sql-style `Migrator.up` with an inline migration; Sandbox manual mode; savepoint rollback per StreamData iteration.

## SQLite parity

**Choice:** Yes. The same parameterized suite runs on a dedicated SQLite repo in core.

## Claude's Discretion

Function, flag and module names; whether omitted-id deletes share a helper with the Oban worker; the layout of the verify task and the test module.

## Deferred Ideas

The Postgres row-value fast path or decomposed seek; resume-from-cursor; inline sync through the loader; whole-index pruning (reconcile owns it).
