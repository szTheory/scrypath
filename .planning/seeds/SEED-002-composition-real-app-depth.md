---
slug: composition-real-app-depth
title: v1.22 Composition And Real-App Depth
status: open
created: 2026-05-08
updated: 2026-05-08
---

# Seed: v1.22 Composition And Real-App Depth

## Trigger

Surface this after the query-toolkit edge helpers are in place, or when real apps need reusable presets, scopes, or composition patterns across multiple search flows.

## Why it exists

Scrypath already covers the core query path. The next layer of value is letting SaaS apps compose search behavior cleanly instead of rebuilding the same combinations in every context.

## Scope

- reusable presets and scopes where they reduce repeated app glue
- composition support that stays aligned with `search_many/2`
- richer UI metadata for declared filters, sorts, facets, and paging
- stronger guidance for real app adoption patterns

## Breadcrumbs

- `.planning/MILESTONE-ARC.md`
- `.planning/milestone-candidates.md`
- `README.md`
- `guides/overview.md`
- `guides/multi-index-search.md`
- `guides/faceted-search-with-phoenix-liveview.md`
- `scrypath_ops/docs/operator-ia.md`

## Surface when

- multiple contexts need the same search presets
- real-app adopters ask for fewer repeated declarations
- the product needs more batteries-included ergonomics without expanding the backend surface
