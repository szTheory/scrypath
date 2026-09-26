---
phase: 165-public-tenant-and-facet-contracts
verified: 2026-09-26T22:56:05Z
status: passed
score: 12/12 truths verified
covered_files:
  - .planning/REQUIREMENTS.md
  - .planning/ROADMAP.md
  - .planning/STATE.md
  - .planning/phases/165-public-tenant-and-facet-contracts/165-01-PLAN.md
  - .planning/phases/165-public-tenant-and-facet-contracts/165-01-SUMMARY.md
  - .planning/phases/165-public-tenant-and-facet-contracts/165-02-PLAN.md
  - .planning/phases/165-public-tenant-and-facet-contracts/165-02-SUMMARY.md
  - .planning/phases/165-public-tenant-and-facet-contracts/165-CONTEXT.md
  - .planning/phases/165-public-tenant-and-facet-contracts/165-RESEARCH.md
  - .planning/phases/165-public-tenant-and-facet-contracts/165-REVIEW.md
  - .planning/phases/165-public-tenant-and-facet-contracts/165-SECURITY.md
  - .planning/phases/165-public-tenant-and-facet-contracts/165-VALIDATION.md
  - .planning/state.json
  - AGENTS.md
  - lib/scrypath/meilisearch/client.ex
  - lib/scrypath/meilisearch/query.ex
  - lib/scrypath/search/facet_values.ex
  - lib/scrypath/search/many.ex
  - lib/scrypath/search/single.ex
  - test/scrypath/facet_values_contract_test.exs
  - test/scrypath/tenant_scope_contract_test.exs
covered_digest: "v1:sha256:7be9816aa5d4534005578c8fd2303e90840d2df485850e0807581b2e2dfdd003"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 165: Public Tenant and Facet Contracts Verification Report

**Phase Goal:** Consumers can rely on Scrypath's existing public tenant-scope and facet-value input contracts, with corrections only for reproduced compatible defects.
**Verified:** 2026-09-26T22:56:05Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Through `search/3`, `search_many/2`, and `search_facet_values/4`, declared tenant scope composes with ordinary filters; conflicting and undeclared tenant inputs fail before backend dispatch. | VERIFIED | `tenant_scope_contract_test.exs` actively exercises each public path, shared multi-search options, equal and conflicting collisions, undeclared schema, and valid-then-invalid multi-entry preflight. Current focused run: 9 tests, 0 failures. All three runtime option extractors drop `:tenant_scope` only after validation has composed it into the query filter. |
| 2 | Public facet defaults and keyword filters reach a Meilisearch v1.15-compatible facet request; only a reproduced compatible defect receives a correction and regression. | VERIFIED | `facet_values_contract_test.exs` enters via public `search_facet_values/4`, observes the encoded POST body, checks defaults and a rendered keyword predicate, and checks quote/backslash escaping. Current focused run: 8 tests, 0 failures. `Client.facet_search/5` delegates keyword rendering to the existing common filter renderer. The pinned v1.15 parser evidence recorded in `165-RESEARCH.md` says unknown search keys are ignored; defaults alone were not misclassified as invalid. The live/package check for this reproduced keyword scenario is explicitly handed to Phase 166; Phase 165 claims request construction and pinned-parser compatibility, not live service acceptance. |
| 3 | Declared tenant scope and an ordinary status filter reach the backend through all three paths. | VERIFIED | Recorder assertions inspect both predicates in single search, shared multi-search, and facet callback options; Req.Test also decodes both predicates in the facet request. |
| 4 | Omitted and explicitly empty ordinary filters retain tenant scope, while the ordinary-filter example retains both predicates. | VERIFIED | The public-path loop exercises omitted and `filter: []` for all paths; normalized filters are compared by predicate meaning. |
| 5 | Equal-valued and conflicting tenant collisions, plus tenant scope on a schema without a declared tenant field, fail before dispatch. | VERIFIED | Tests assert the collision/declaration error messages, path-specific error forms, and absence of recorder messages. |
| 6 | Single/facet validation retains `ArgumentError`; multi-search returns the schema-associated `validation_failed` tuple and preflights every entry. | VERIFIED | Named active tests assert both return shapes and prove that a valid first entry is not dispatched when a later entry is invalid. |
| 7 | C10-R1 is classified from executed public calls and production changes are limited to reproduced compatible failures. | VERIFIED | Plan 01 records pre-fix public failures at the runtime configuration seam and corrections in only the three runtime extractors; current source preserves the normalized filter and strict config validation. Regression probes pass. |
| 8 | Facet defaults reach the expected endpoint with requested `facetName`, `facetQuery`, valid encoded defaults, and a decorated facet result. | VERIFIED | The default test checks POST path, decoded fields, `filter: []`, and the resulting bucket value/count and facet query. |
| 9 | A nonempty documented keyword filter reaches the facet endpoint as a rendered expression through the real adapter. | VERIFIED | The public test sends `filter: [status: "published"]`; Req.Test captures decoded JSON with `status = "published"`. The recorded pre-fix baseline failed JSON encoding on the raw tuple; the focused regression passes after renderer reuse. |
| 10 | Tenant scope plus an ordinary facet filter retains both predicates in the encoded request. | VERIFIED | Public Req.Test assertion checks both the status and tenant expressions in the encoded request filter. |
| 11 | Invalid common filters fail before HTTP; HTTP/transport failures preserve error tuples and bang errors without unfiltered fallback. | VERIFIED | Active cases assert no request for invalid boolean composition, inspect the submitted filter on HTTP/timeout failures, assert one request, and retain the `Search.Error` reason for the bang wrapper. |
| 12 | Defaults and keyword outcomes are classified separately; unknown default keys alone do not imply parser rejection. | VERIFIED | Defaults pass the encoded request probe without a source correction; the reproduced keyword serialization defect receives the narrow correction. Research cites the pinned Meilisearch 1.15 behavior, and the summaries avoid claiming live acceptance from Req.Test. |

**Score:** 12/12 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `test/scrypath/tenant_scope_contract_test.exs` | Public tenant composition/rejection contract | VERIFIED | Exists, substantive, called through public API; 9 tests pass locally. |
| `lib/scrypath/search/single.ex` | Single search separates validated search inputs from runtime config | VERIFIED | Runtime option extraction excludes `:tenant_scope`; public regression test exercises it. |
| `lib/scrypath/search/many.ex` | Multi-search shared tenant config and complete preflight | VERIFIED | Drops `:tenant_scope` from runtime config; validates all entries before dispatch. |
| `lib/scrypath/search/facet_values.ex` | Facet orchestration with validated options | VERIFIED | Excludes validated tenant option from runtime config; recorder sees composed filter. |
| `test/scrypath/facet_values_contract_test.exs` | Public defaults, keyword rendering and error behavior | VERIFIED | Exists, substantive and reaches Req.Test through public API; 8 tests pass locally. |
| `lib/scrypath/meilisearch/client.ex` | Facet HTTP request construction and normalization | VERIFIED | Builds facet endpoint request and renders keyword filters before JSON encoding. |
| `lib/scrypath/meilisearch/query.ex` | Reusable common filter grammar and JSON literal encoding | VERIFIED | `render_common_filter/1` reuses the existing query renderer and JSON encoder. |

All listed PLAN artifacts passed `verify.artifacts` (7/7). No artifact is a stub or orphan.

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `tenant_scope_contract_test.exs` | `options/search.ex` | Public validation injects tenant into filter | WIRED | Pattern check passes; recorder confirms actual dispatch options. |
| `search/many.ex` | `tenant_scope_contract_test.exs` | Shared tenant option traverses runtime extraction | WIRED | Pattern check passes; shared-option public test observes the filter. |
| `search/facet_values.ex` | `tenant_scope_contract_test.exs` | Recorder observes validated facet callback options | WIRED | Pattern check passes; callback assertion checks both predicates. |
| `facet_values_contract_test.exs` | `search/facet_values.ex` | Public API path | WIRED | Every facet contract case invokes `Scrypath.search_facet_values/4`. |
| `meilisearch.ex` | `meilisearch/client.ex` | Adapter invokes `facet_search/5` | WIRED | Adapter's configured client call and endpoint are present. |
| `meilisearch/client.ex` | `facet_values_contract_test.exs` | Req.Test observes encoded HTTP | WIRED | Test checks POST URL and decodes the request body. |

Both plans' key-link checks passed (6/6).

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| Tenant public search paths | `filter` | Caller options, validated against schema metadata; tenant criterion is inserted by `Options.Search.validate/4` | Yes; tests inspect recorder callback input | FLOWING |
| Facet request | `filter` | Public options → schema validation → facet orchestration → Meilisearch client → Req JSON body | Yes; tests decode actual serialized body | FLOWING |
| Facet result | facet hits/query | Req.Test response used by real adapter/result decorator | Deterministic test response, appropriate at this contract boundary | FLOWING |

No value terminates in a static production return or hardcoded call-site prop. Test responses are local inputs at the external HTTP boundary, not substitutes for the production request path.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Tenant public contracts across all paths | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix test test/scrypath/tenant_scope_contract_test.exs` | 9 tests, 0 failures | PASS |
| Facet public HTTP contracts | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix test test/scrypath/facet_values_contract_test.exs` | 8 tests, 0 failures | PASS |

The supplied exact-candidate hosted closeout is for SHA `384c8839db2f021db421d0dbeff096ee439fd721`, matching this checkout. Workflow run [36277023698](https://github.com/szTheory/scrypath/actions/runs/36277023698) reports five required jobs, advisory coverage, and closeout attestation succeeded; recorded immutable coverage and closeout artifact digests are `sha256:4f1133b5af6a9e61ea5ee7fa013aa49b96e5dd2a1abc7f24e8b8cd7f9c6f12ce` and `sha256:c50b60190690ae233dded02a9cbe1239eaf815b325129908359b4a1dcf9587a0`.

### Probe Execution

Not applicable. This is a library contract phase; its plans and roadmap criteria do not declare script probes.

### Requirements Coverage

| Requirement | Source plan | Description | Status | Evidence |
|---|---|---|---|---|
| API-01 | `165-01-PLAN.md` | Tenant scope composes across public search paths; invalid scope rejects before dispatch. | SATISFIED | Tenant contract file passes 9 tests; source and recorder wiring verified. |
| API-02 | `165-02-PLAN.md` | Public facet defaults/keyword filters produce compatible request construction and preserve errors. | SATISFIED | Facet contract file passes 8 tests; encoded request/body and error behavior verified. |

No additional requirements map to Phase 165 in `REQUIREMENTS.md`; no orphaned requirements found.

### Test Quality Audit

| Test file | Linked requirement | Active | Skipped | Circular | Assertion level | Verdict |
|---|---|---:|---:|---:|---|---|
| `tenant_scope_contract_test.exs` | API-01 | 9 | 0 | No | Behavioral/value | PASS |
| `facet_values_contract_test.exs` | API-01, API-02 | 8 | 0 | No | Behavioral/value | PASS |

The tests use independent expected predicates and encoded request literals; they do not derive expected values by calling the implementation under test. Disabled-test scan found none.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| — | — | None found in the phase implementation or contract tests | — | No unresolved debt markers, placeholders, or empty production implementations. |

### Human Verification Required

None. Automated tests resolve the phase's library boundary claims. The deferred live/package facet scenario is scoped to Phase 166; it is not routine UAT required to decide Phase 165's stated request-construction goal.

### Decision Coverage

All trackable CONTEXT decisions honored (7/7). The decision-coverage check is non-blocking; no decisions were missing from shipped artifacts.

### Gaps Summary

No phase-goal gaps found. EA-02 remains explicit: the test evidence establishes synchronous request construction and bounded error propagation, not interruption or parallel backend execution semantics. The Phase 166 handoff to run the corrected facet keyword scenario against its live Meilisearch/package workflow is consistent with this phase boundary: Phase 165 proves the public construction contract and a compatible narrow correction, while Phase 166 owns host/package service evidence. The code does not claim live service acceptance from Req.Test.

---

_Verified: 2026-09-26T22:56:05Z_  
_Verifier: the agent (gsd-verifier)_
