---
slug: query-toolkit-phoenix-edge-helpers
title: v1.21 Query Toolkit And Phoenix Edge Helpers
status: shipped
created: 2026-05-08
updated: 2026-05-08
---

# Seed: v1.21 Query Toolkit And Phoenix Edge Helpers

## Trigger

Surface this when the repo reopens internal feature work after the v1.20 cleanup, or when app code starts repeating controller/LiveView param casting, sort/filter/page normalization, or URL round-tripping around Scrypath search flows.

## Why it exists

The core runtime is already explicit and stable. The next leverage move is to reduce Phoenix-edge boilerplate without making the core runtime Phoenix-dependent.

## Scope

- public normalization and casting helpers under the search-module layer
- optional Phoenix-facing helpers for request params, forms, and LiveView round-tripping
- no schema-generated runtime verbs
- no hidden sync or new backend abstraction

## Breadcrumbs

- `.planning/MILESTONE-ARC.md`
- `.planning/milestone-candidates.md`
- `guides/phoenix-contexts.md`
- `guides/phoenix-liveview.md`
- `guides/faceted-search-with-phoenix-liveview.md`
- `Scrypath.search/3`
- `Scrypath.search_many/2`

## Surface when

- query-param glue starts appearing in multiple contexts
- the app-facing search boundary needs a reusable helper layer
- the v1.20 search-module contract is fully reconciled and ready to be extended
