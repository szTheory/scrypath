---
phase: 104
plan: 02
subsystem: "examples/scrypath_ecommerce"
tags: ["search-sync", "oban", "related-data"]
dependency_graph:
  requires: ["104-01"]
  provides: ["Category Product Fan-Out"]
  affects: ["Catalog.update_category/3", "Product search projection"]
tech_stack:
  added: []
  patterns: ["Scrypath related sync", "Ecto.Multi transactional enqueue"]
key_files:
  created: []
  modified:
    - examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog.ex
    - examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog/category.ex
    - examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog/product.ex
    - examples/scrypath_ecommerce/test/scrypath_ecommerce/catalog_test.exs
decisions:
  - "Use Scrypath's built-in related-sync path and Scrypath.Sync.RelatedWorker instead of adding an app-specific CategorySyncWorker."
  - "Include category_name in the Product search document so category renames have visible search-index impact."
metrics:
  completed_date: "2026-05-30"
---

# Phase 104 Plan 02: Related-Data Propagation Summary

Implemented category-to-product fan-out for the e-commerce example.

## Tasks Completed
- Added `Category.__scrypath__(:fan_outs)` and `Category.__scrypath__(:document_id)` so category changes can enqueue product re-sync through Scrypath's existing related-sync worker.
- Added `Catalog.resolve_products_for_categories/1` for both struct and ID payloads, returning category-preloaded products for projection.
- Refactored `Catalog.update_category/3` to use `Ecto.Multi` and enqueue the related product sync transactionally after a successful category update.
- Updated product create/update sync paths to preload category data and added `Product.search_document/1` with `category_name`.
- Added catalog tests for related sync enqueueing, resolver behavior, and category-aware product projection.

## Deviations from Plan
- Did not create `ScrypathEcommerce.Workers.CategorySyncWorker`; the built-in `Scrypath.Sync.RelatedWorker` already provides the intended Oban fan-out behavior and better demonstrates Scrypath's public API.

## Verification
- Passed: `mix test test/scrypath/sync/related_test.exs test/scrypath/sync/related_worker_test.exs`
- Passed after scaffold recovery: `cd examples/scrypath_ecommerce && mix test test/scrypath_ecommerce/catalog_test.exs`
- Passed after scaffold recovery: `cd examples/scrypath_ecommerce && mix test`
