---
phase: 81
slug: edge-normalization-errors-and-phoenix-wrappers
status: validated
nyquist_compliant: true
created: 2026-05-23
updated: 2026-05-23
---

# Phase 81 Validation Ledger

Append-only validation ledger for Phase 81. This file locks the proof seams the phase plans must satisfy and gives the checker a concrete Nyquist artifact before execution begins.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via `mix test` |
| **Config file** | `test/test_helper.exs` via root `mix test` |
| **Core contract command** | `mix test test/scrypath/query_params_test.exs test/scrypath/search_test.exs` |
| **Phoenix helper command** | `mix test test/scrypath/phoenix_test.exs test/support/docs/phoenix_examples_test.exs test/support/docs/phoenix_request_shape_smoke_test.exs` |
| **Docs contract command** | `mix test test/scrypath/docs_contract_test.exs test/support/docs/phoenix_examples_test.exs test/support/docs/phoenix_request_shape_smoke_test.exs` |
| **Full suite command** | `mix test` |

## Validation Targets

| ID | Requirement | Proof seam | Automated command | Status |
|----|-------------|------------|-------------------|--------|
| 81-VAL-01 | QTK-02 | Browser-shaped params normalize once into the existing plain-data `Scrypath.QueryParams` contract for text, page, filters, sort, facets, and facet filters. | `mix test test/scrypath/query_params_test.exs test/scrypath/search_test.exs` | planned |
| 81-VAL-02 | QTK-03 | Invalid owned-namespace input returns aggregate field-scoped plain-data issues with stable machine-readable metadata. | `mix test test/scrypath/query_params_test.exs` | planned |
| 81-VAL-03 | PHX-01 | Optional Phoenix wrappers delegate to the core normalizer, round-trip canonical params, and stay pure. | `mix test test/scrypath/phoenix_test.exs test/support/docs/phoenix_examples_test.exs` | planned |
| 81-VAL-04 | PHX-02 | LiveView/controller docs fixtures use helper-driven edge glue while keeping `handle_params/3` and contexts canonical. | `mix test test/support/docs/phoenix_examples_test.exs test/support/docs/phoenix_request_shape_smoke_test.exs test/scrypath/docs_contract_test.exs` | planned |
| 81-VAL-05 | Phase runtime safety | Phase 81 changes do not introduce a second runtime, Phoenix-required core path, or public `%Scrypath.Query{}` drift. | `mix test` | planned |

## Per-Plan Verification Map

| Task ID | Plan | Wave | Requirement | Automated command | File Exists | Status |
|---------|------|------|-------------|-------------------|-------------|--------|
| 81-01-01 | 01 | 1 | QTK-02, QTK-03 | `mix test test/scrypath/query_params_test.exs` | ✅ | planned |
| 81-01-02 | 01 | 1 | QTK-02, QTK-03 | `mix test test/scrypath/query_params_test.exs` | ✅ | planned |
| 81-01-03 | 01 | 1 | QTK-02 | `mix test test/scrypath/query_params_test.exs test/scrypath/search_test.exs` | ✅ | planned |
| 81-02-01 | 02 | 2 | PHX-01 | `mix test test/scrypath/phoenix_test.exs` | ✅ | planned |
| 81-02-02 | 02 | 2 | PHX-02 | `mix test test/scrypath/phoenix_test.exs test/support/docs/phoenix_examples_test.exs test/support/docs/phoenix_request_shape_smoke_test.exs` | ✅ | planned |
| 81-02-03 | 02 | 2 | PHX-01, PHX-02 | `mix test test/scrypath/docs_contract_test.exs test/support/docs/phoenix_examples_test.exs test/support/docs/phoenix_request_shape_smoke_test.exs` | ✅ | planned |

## Baseline Notes

- The checked-out Phase 80 seam already proves `Scrypath.QueryParams.cast/1` and `to_search_args/1` as the public plain-data bridge, but nested browser-shaped params still raise instead of returning field-scoped errors.
- The current Phoenix docs fixtures still hand-roll page and facet parsing in controller and LiveView examples; Phase 81 exists to remove that duplication while preserving contexts as the search boundary.
- `81-02` is intentionally the broader of the two plans because it combines the optional helper module, fixture adoption, and guide/docs-contract locking in one wave after `81-01` lands the core semantics.

## Manual-Only / Deferred

| Behavior | Requirement | Disposition | Notes |
|----------|-------------|-------------|-------|
| Multi-sort browser grammar beyond `sort[field]` + `sort[dir]` or explicit indexed entries | QTK-02 | discretionary | Only ship if the core normalization plan can support it without ambiguity; otherwise keep the single-sort public grammar and document that choice. |
| Direct Phoenix `to_form/2` coupling in core | PHX-01 | rejected | Keep Phoenix projection outside the core edge contract so Phoenix remains optional. |

## Acceptance Gate

Phase 81 validation can only be marked complete when:

- `81-VAL-01` and `81-VAL-02` are green against the non-raising core normalization and error contract.
- `81-VAL-03` and `81-VAL-04` are green against the optional Phoenix wrapper path and fixture/doc adoption.
- `81-VAL-05` has either a passing full-suite result or an explicit baseline note isolating unrelated failures outside the Phase 81 file set.

## Validation Audit 2026-05-23

| Metric | Count |
|--------|-------|
| Gaps found | 0 planning gaps after ledger creation |
| Resolved | 2 gate-hygiene blockers closed (`81-VALIDATION.md` added, research heading normalized) |
| Escalated | 0 |
| Deferred to execution | 5 automated proof seams |

## Sign-Off

- [x] Requirements `QTK-02`, `QTK-03`, `PHX-01`, and `PHX-02` each map to explicit proof seams
- [x] The validation ledger exists before execution so Nyquist dimension 8 has a concrete artifact
- [x] The ledger does not claim execution evidence that has not yet been produced
- [x] Phase 81 keeps the core edge contract and the optional Phoenix adapter path separately testable
