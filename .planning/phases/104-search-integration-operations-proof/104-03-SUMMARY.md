---
phase: 104
plan: 03
subsystem: "examples/scrypath_ecommerce"
tags: ["liveview", "search", "facets", "tenant-isolation"]
dependency_graph:
  requires: ["104-01", "104-02"]
  provides: ["Storefront Search UI"]
  affects: ["SearchLive", "Product search queries"]
tech_stack:
  added: []
  patterns: ["LiveView URL state", "Scrypath faceted search", "tenant filter isolation"]
key_files:
  created:
    - examples/scrypath_ecommerce/test/scrypath_ecommerce_web/live/search_live_test.exs
  modified:
    - examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/live/search_live.ex
    - examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/live/search_live.html.heex
decisions:
  - "Use handle_params/3 as the single search source of truth; phx-change only pushes URL patches."
  - "Apply tenant isolation as an explicit tenant_id filter in Scrypath.search/3 because the current tenant_scope option is rejected during runtime option validation."
metrics:
  completed_date: "2026-05-30"
---

# Phase 104 Plan 03: LiveView Storefront Search Summary

Implemented the URL-driven storefront search LiveView for the e-commerce example.

## Tasks Completed
- Added `SearchLive.handle_params/3` to parse `q` and `category_id` URL params, resolve the default tenant, and call `Scrypath.search/3` with tenant and category filters plus `category_id` facets.
- Added `handle_event("search", ...)` so the unified form updates the URL through `push_patch/2` and lets `handle_params/3` perform the actual search.
- Built a unified HEEx form with debounced text input, category facet checkboxes, and hit rendering.
- Added LiveView tests covering tenant-scoped search hydration, URL patch behavior, and rendered form/facet/result markup.

## Deviations from Plan
- Used `filter: [tenant_id: tenant.id]` rather than `tenant_scope: tenant.id`. The current library accepts `tenant_scope:` during search option normalization tests, but a real `Scrypath.search/3` call still passes the raw option into runtime validation and raises for unknown `:tenant_scope`. The explicit tenant filter preserves the required isolation behavior and matches the plan's key-link wording.

## Verification
- Passed: `cd examples/scrypath_ecommerce && mix test test/scrypath_ecommerce_web/live/search_live_test.exs`
- Passed: `cd examples/scrypath_ecommerce && mix test`

## Self-Check: PASSED
