---
slug: scrypath-product-map
title: Scrypath product map and JTBD crash course
status: resolved
created: 2026-05-08
updated: 2026-05-23
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

- keep the `v1.20` archive/code-drift concern isolated as explicit planning debt rather than product truth
- treat the shipped `v1.21` request-edge toolkit and optional Phoenix helper surface as the current ergonomics boundary
- keep future milestones focused on app-facing ergonomics, not hidden callback magic or a second runtime

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

## Resolution

- This thread now serves as the stable reusable product briefing for future milestone planning.
- The `v1.21` request-edge toolkit and Phoenix-helper work landed without changing the core product boundary: contexts still own search orchestration and `Scrypath.search/3` remains canonical.
- Remaining archive/code-drift follow-up is tracked separately in `.planning/todos/search-module-archive-code-drift.md`.
