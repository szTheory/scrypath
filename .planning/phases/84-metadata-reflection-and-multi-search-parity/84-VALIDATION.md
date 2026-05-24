---
phase: 84
slug: metadata-reflection-and-multi-search-parity
status: validated
nyquist_compliant: true
created: 2026-05-23
updated: 2026-05-23
---

# Phase 84 Validation Ledger

Append-only validation ledger for Phase 84. This file locks the proof seams the phase plans must satisfy before execution starts.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via `mix test` plus `mix docs` |
| **Config file** | `test/test_helper.exs` and `mix.exs` docs config |
| **Quick phase gate** | `mix verify.phase84` after Wave 0 adds it |
| **Focused metadata command** | `mix test test/scrypath/metadata_test.exs` |
| **Focused lowering command** | `mix test test/scrypath/composition_many_test.exs` |
| **Docs build command** | `mix docs --warnings-as-errors` |
| **Fast suite command** | `mix test --exclude integration --exclude docs_contract` |
| **Full suite command** | `mix test` |

## Validation Targets

| ID | Requirement | Proof seam | Automated command | Status |
|----|-------------|------------|-------------------|--------|
| 84-VAL-01 | META-01 | Capability metadata matches declaration and validator truth for filters, sorts, facets, and paging. | `mix test test/scrypath/metadata_test.exs` | planned |
| 84-VAL-02 | META-02 | Resolved metadata preserves `applied`, `defaulted`, `fixed`, and `unsupported` as field-scoped plain data suitable for host UIs. | `mix test test/scrypath/metadata_test.exs` | planned |
| 84-VAL-03 | META-03 | Public docs and root moduledocs keep tenant policy, authorization, and related-data concerns explicitly host-owned. | `mix test test/scrypath/docs_contract_test.exs` | planned |
| 84-VAL-04 | MSCH-01 | Multi-search composition lowers to the existing tuple/shared-option contract without adding a second DSL or executor. | `mix test test/scrypath/composition_many_test.exs` | planned |
| 84-VAL-05 | MSCH-02 | Multi-search lowering and reflection preserve entry/shared precedence, `:all` honesty, and existing failure boundaries. | `mix test test/scrypath/composition_many_test.exs test/scrypath/search_many_test.exs` | planned |
| 84-VAL-06 | Phase docs hygiene | Published docs compile cleanly after metadata/reflection guidance is added. | `mix docs --warnings-as-errors` | planned |
| 84-VAL-07 | Phase workflow gate | A dedicated `mix verify.phase84` exists and runs the intended metadata/lowering/docs proof seams. | `mix test test/scrypath/docs_contract_test.exs` | planned |

## Per-Plan Verification Map

| Task ID | Plan | Wave | Requirement | Automated command | File Exists | Status |
|---------|------|------|-------------|-------------------|-------------|--------|
| 84-01-01 | 01 | 1 | META-01, META-02 | `rg -n "schema_capabilities|reflect_search|reflect_search_many" lib/scrypath.ex lib/scrypath/metadata.ex` | ❌ Wave 0 | planned |
| 84-01-02 | 01 | 1 | MSCH-01, MSCH-02 | `rg -n "compose_many|to_search_many_args" lib/scrypath/composition.ex` | ❌ Wave 0 | planned |
| 84-01-03 | 01 | 1 | META-03, docs hygiene | `rg -n "host-owned|tenant|authorization|related-data" lib/scrypath.ex guides/multi-index-search.md guides/faceted-search-with-phoenix-liveview.md && mix docs --warnings-as-errors` | ✅ / ✅ / ✅ | planned |
| 84-02-01 | 02 | 1 | META-01, META-02 | `mix test test/scrypath/metadata_test.exs` | ❌ Wave 0 | planned |
| 84-02-02 | 02 | 1 | MSCH-01, MSCH-02 | `mix test test/scrypath/composition_many_test.exs` | ❌ Wave 0 | planned |
| 84-02-03 | 02 | 1 | META-03, 84-VAL-07 | `mix test test/scrypath/docs_contract_test.exs` | ✅ | planned |
| 84-03-01 | 03 | 2 | META-01, META-02 | `mix test test/scrypath/metadata_test.exs --seed 0` | ❌ Wave 0 | planned |
| 84-03-02 | 03 | 2 | MSCH-01, MSCH-02 | `mix test test/scrypath/composition_many_test.exs test/scrypath/search_many_test.exs` | ❌ / ✅ | planned |
| 84-03-03 | 03 | 2 | META-01, META-02, META-03, MSCH-01, MSCH-02 | `mix verify.phase84` | ❌ Wave 0 | planned |

## Baseline Notes

- The checked-out repo already has one canonical single-search composition seam and one canonical `search_many/2` executor.
- The new risk surface is drift between declaration metadata, validator truth, and what host UIs are told they can render.
- The second new risk surface is semantic widening in multi-search composition, especially around shared `fixed`, merged global capability views, or hidden precedence changes.
- Existing `search_many/2` tests already pin core precedence and failure behavior; Phase 84 should reuse and extend those seams rather than replace them.

## Manual-Only / Deferred

| Behavior | Requirement | Disposition | Notes |
|----------|-------------|-------------|-------|
| Generated widgets or control components | META-02 | rejected | Host-owned rendering only. |
| Tenant-safe authz enforcement or related-data propagation | META-03 | deferred | Explicitly out of scope. |
| Shared `fixed` policy semantics for multi-search | MSCH-01, MSCH-02 | rejected | Would widen semantics beyond the current contract. |
| One merged cross-schema capability surface | MSCH-02 | rejected | Entry-scoped honesty is required. |

## Acceptance Gate

Phase 84 validation can only be marked complete when:

- `84-VAL-01` and `84-VAL-02` prove metadata is derived honestly and resolved state stays field-scoped.
- `84-VAL-03` proves public docs preserve host-owned boundaries.
- `84-VAL-04` and `84-VAL-05` prove multi-search composition lowers to the existing executor contract without semantic widening.
- `84-VAL-06` and `84-VAL-07` prove the docs build and focused verify task stay healthy.

## Sign-Off

- [x] Requirements `META-01` through `MSCH-02` each map to explicit proof seams
- [x] The validation ledger exists before execution so Nyquist dimension 8 has a concrete artifact
- [x] The ledger does not claim execution evidence that has not yet been produced
- [x] The highest-risk drift areas are called out directly: capability truth, resolved-vs-fixed semantics, and multi-search semantic widening
