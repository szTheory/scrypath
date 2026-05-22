---
phase: 80
plan: 01
slug: public-query-toolkit-contract
status: planned
created: 2026-05-22
updated: 2026-05-22
---

# Phase 80 Validation Ledger

Append-only validation ledger for Phase 80. This phase is still in planning, so the ledger records the required proof seams and the current baseline constraints that execution must satisfy before the phase can be marked complete.

## Evidence Window

- Plan 01 contract proof command: `mix test test/scrypath/query_params_test.exs`
- Plan 02 parity proof command: `mix test test/scrypath/query_params_test.exs test/scrypath/search_test.exs test/scrypath/meilisearch/query_test.exs`
- Phase gate command: `mix test`

## Validation Targets

| ID | Requirement | Proof seam | Automated command | Status |
|----|-------------|------------|-------------------|--------|
| 80-VAL-01 | QTK-01 | Public `Scrypath.QueryParams` returns one stable plain-data contract and does not expose `%Scrypath.Query{}`. | `mix test test/scrypath/query_params_test.exs` | pending |
| 80-VAL-02 | QTK-04 | Toolkit output converts through `to_search_args/1` into the existing `Scrypath.search/3` runtime without a second executor surface. | `mix test test/scrypath/query_params_test.exs test/scrypath/search_test.exs test/scrypath/meilisearch/query_test.exs` | pending |
| 80-VAL-03 | Phase runtime safety | The phase still passes the full repo test gate after the toolkit contract is added. | `mix test` | pending |

## Baseline Notes

- The research baseline already recorded one unrelated docs-contract failure in the current repo state: a root `.planning/REQUIREMENTS.md` assertion expecting `| AUDT-01 |`. Execution should treat that as baseline drift unless the failing assertion changes as part of this phase. [VERIFIED: `.planning/phases/80-public-query-toolkit-contract/80-RESEARCH.md`]
- No Phase 80 execution evidence has been logged yet. All rows remain pending until plan execution produces concrete test results.

## Acceptance Gate

Phase 80 validation can only be marked complete when:

- `80-VAL-01` has passing evidence for the public plain-data contract.
- `80-VAL-02` has passing evidence for runtime parity through `Scrypath.search/3`.
- `80-VAL-03` has either a passing full-suite result or an explicit baseline-drift note limited to pre-existing unrelated failures.
