---
status: complete
phase: 20-faceted-search-liveview-guide
source: 20-01-SUMMARY.md, 20-02-SUMMARY.md, 20-03-SUMMARY.md, 20-04-SUMMARY.md
started: 2026-04-17T12:00:00Z
updated: 2026-04-17T18:00:00Z
automation: ci
---

## Current Test

[testing complete]

## Automation

Phase 20 acceptance is enforced in CI and locally by **`mix verify.phase20`** (focused tests from the phase SUMMARYs plus `mix docs --warnings-as-errors`). The default **`mix test`** job already runs these test modules; the Mix task names the gate and matches the phase self-check file list.

## Tests

### 1. Schema faceting configuration
expected: Valid `faceting:` compiles and surfaces via `__scrypath__(:faceting)`; invalid configs error clearly; options/schema tests pass.
result: pass
verification: mix verify.phase20 (options + schema tests)

### 2. Facet search requests and decoded results
expected: Search accepts `:facets` and `:facet_filter`; Meilisearch query payload includes facet fields when used; `%SearchResult{}` decodes facet data; relevant tests pass.
result: pass
verification: mix verify.phase20 (search, query, backend tests)

### 3. Meilisearch settings merge for facet filterables
expected: `Scrypath.Meilisearch.Settings.resolve/2` merges facet-derived `filterableAttributes` (including `features: ["facetSearch"]`) with explicit schema settings without losing intended precedence; settings tests pass.
result: pass
verification: mix verify.phase20 (settings tests)

### 4. Faceted LiveView guide and documentation contract
expected: `guides/faceted-search-with-phoenix-liveview.md` is present as a full guide; it appears in ExDoc extras (Phoenix group); `guides/phoenix-liveview.md` links to it; docs contract + Phoenix example tests pass; `FacetedBrowseLive` compile fixture builds cleanly; ExDoc builds without doc warnings.
result: pass
verification: mix verify.phase20 (docs_contract, phoenix_examples, docs build)

## Summary

total: 4
passed: 4
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none]
