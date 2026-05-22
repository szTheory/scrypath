---
phase: 80
slug: public-query-toolkit-contract
status: validated
nyquist_compliant: true
created: 2026-05-22
updated: 2026-05-22
---

# Phase 80 Validation Ledger

Append-only validation ledger for Phase 80. This audit reconciles the original proof seams against the executed plans, current verification artifacts, and live test results.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via `mix test` |
| **Config file** | `test/test_helper.exs` via root `mix test` |
| **Quick run command** | `mix test test/scrypath/query_params_test.exs` |
| **Phase proof command** | `mix test test/scrypath/query_params_test.exs test/scrypath/search_test.exs test/scrypath/meilisearch/query_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~1-30 seconds depending on proof scope |

## Evidence Window

- Plan 01 contract proof command: `mix test test/scrypath/query_params_test.exs` -> `4 tests, 0 failures`
- Plan 02 parity proof command: `mix test test/scrypath/query_params_test.exs test/scrypath/search_test.exs test/scrypath/meilisearch/query_test.exs` -> `26 tests, 0 failures`
- Phase gate command: `mix test` -> `436 tests, 2 failures (9 excluded)`

## Validation Targets

| ID | Requirement | Proof seam | Automated command | Status |
|----|-------------|------------|-------------------|--------|
| 80-VAL-01 | QTK-01 | Public `Scrypath.QueryParams` returns one stable plain-data contract and does not expose `%Scrypath.Query{}`. | `mix test test/scrypath/query_params_test.exs` | covered |
| 80-VAL-02 | QTK-04 | Toolkit output converts through `to_search_args/1` into the existing `Scrypath.search/3` runtime without a second executor surface. | `mix test test/scrypath/query_params_test.exs test/scrypath/search_test.exs test/scrypath/meilisearch/query_test.exs` | covered |
| 80-VAL-03 | Phase runtime safety | The phase still passes the full repo test gate after the toolkit contract is added. | `mix test` | partial (baseline drift outside phase scope) |

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Automated command | File Exists | Status |
|---------|------|------|-------------|-------------------|-------------|--------|
| 80-01-01 | 01 | 1 | QTK-01 | `mix test test/scrypath/query_params_test.exs` | ✅ | ✅ green |
| 80-01-02 | 01 | 1 | QTK-01 | `mix test test/scrypath/query_params_test.exs` | ✅ | ✅ green |
| 80-02-01 | 02 | 2 | QTK-04 | `mix test test/scrypath/query_params_test.exs test/scrypath/search_test.exs test/scrypath/meilisearch/query_test.exs` | ✅ | ✅ green |
| 80-02-02 | 02 | 2 | QTK-04 | `mix test test/scrypath/query_params_test.exs test/scrypath/search_test.exs test/scrypath/meilisearch/query_test.exs` | ✅ | ✅ green |

## Baseline Notes

- `80-VAL-01` is covered for the locked Phase 80 scope: plain-data top-level envelope casting, stable key vocabulary, no public `%Scrypath.Query{}` contract, and no `search/*` helper exports.
- Nested browser-style normalization remains intentionally deferred to Phase 81. Phase 80 tests explicitly reject request-style nested maps for `filter`, `page`, and `per_query` rather than pretending that support already exists.
- `80-VAL-03` is partial only because the full-suite run still contains unrelated repo drift outside Phase 80's file set:
  - `test/release/package_metadata_test.exs:32` expects an older `:Maintainers` docs group shape.
  - `test/scrypath/docs_contract_test.exs:839` still expects `| AUDT-01 |` in requirements traceability.
- No Phase 80 file participated in the observed full-suite failures.

## Manual-Only / Deferred

| Behavior | Requirement | Disposition | Notes |
|----------|-------------|-------------|-------|
| Nested browser-style request param normalization for maps like `%{"filter" => %{"status" => "published"}}` | QTK-01 | deferred to Phase 81 | Phase 80 intentionally freezes only the top-level public contract and runtime bridge; later normalization work is explicitly tracked in the roadmap and verification artifacts. |

## Acceptance Gate

Phase 80 validation can only be marked complete when:

- `80-VAL-01` has passing evidence for the public plain-data contract. ✅
- `80-VAL-02` has passing evidence for runtime parity through `Scrypath.search/3`. ✅
- `80-VAL-03` has either a passing full-suite result or an explicit baseline-drift note limited to pre-existing unrelated failures. ✅

## Validation Audit 2026-05-22

| Metric | Count |
|--------|-------|
| Gaps found | 0 actionable |
| Resolved | 0 |
| Escalated | 0 |
| Deferred to later phase | 1 |

## Sign-Off

- [x] PLAN and SUMMARY artifacts were reconciled against live code and tests
- [x] Existing automated proof seams still run green for Phase 80 coverage
- [x] Full-suite baseline drift was isolated to non-Phase-80 files
- [x] No new test files were required to close actionable Nyquist gaps
- [x] `nyquist_compliant: true` reflects the locked Phase 80 scope, with the remaining nested-param work explicitly deferred
