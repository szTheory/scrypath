---
slug: scrypath-product-map
title: Scrypath product map and JTBD crash course
status: open
created: 2026-05-08
updated: 2026-05-08
---

# Thread: Scrypath product map and JTBD crash course

## Goal

Keep one durable reference for what Scrypath is, how it works, who it serves, how it evolved, and where the next useful work is likely to land.

## Context

Created from a repo review focused on architecture, personas, user flows, and the current milestone arc.

## Architecture

Scrypath is easiest to think about as four layers:

- declaration: `use Scrypath` is metadata-only on the schema
- sync orchestration: explicit `sync_record/3`, `sync_records/3`, `delete_record/3`, `backfill/2`, and `reindex/2`
- search runtime: `Scrypath.search/3`, `search!/3`, `search_many/2`, `search_within_facet/4`
- operator recovery: `sync_status/2`, `failed_sync_work/2`, `retry_sync_work/2`, `reconcile_sync/2`, plus `scrypath_ops`

The system boundary stays explicit: Phoenix contexts own the app-facing search flow, `Scrypath` owns the runtime, and Meilisearch remains the v1 backend target.

## Personas / JTBD

- App developer: "I want search to feel like a normal Ecto feature."
- Search owner: "I need explicit sync semantics, predictable query behavior, and clean docs."
- Operator / on-call engineer: "I need to inspect drift, retry failures, and recover safely."

The recurring jobs are:

- declare a searchable schema
- sync after successful writes
- search and hydrate records back through the repo
- inspect and recover failed or stale search work
- keep the operator surface honest instead of hiding consistency problems

## Evolution

- early milestones: Meilisearch-first indexing, sync modes, search/hydration, reindexing
- middle milestones: faceting, federation, per-query tuning, verification gates
- later milestones: operator UI, playbooks, adopter proof, support contracts, production hardening
- current pause posture: do not widen scope without outside-adopter evidence or a clearly leverage-positive release need

## Current Gaps / Next Work

- reconcile the `v1.20` search-module archive with the checked-out code
- continue the `v1.21` query-toolkit / Phoenix edge-helper direction if the gap is resolved or intentionally respecified
- keep future milestones focused on app-facing ergonomics, not hidden callback magic

## References

- `README.md`
- `guides/overview.md`
- `guides/phoenix-contexts.md`
- `guides/phoenix-liveview.md`
- `.planning/PROJECT.md`
- `.planning/STATE.md`
- `.planning/MILESTONE-ARC.md`
- `.planning/milestone-candidates.md`
- `scrypath_ops/docs/operator-ia.md`

## Next Steps

- Use this thread as the reusable product briefing for future milestone planning.
- Update it whenever the architecture map or JTBD set changes materially.
