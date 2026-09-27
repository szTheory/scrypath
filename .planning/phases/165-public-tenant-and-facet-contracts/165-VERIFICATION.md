---
phase: 165-public-tenant-and-facet-contracts
verified: 2026-09-27T23:27:13Z
status: passed
score: 12/12 truths verified
covered_files:
  - .planning/REQUIREMENTS.md
  - .planning/phases/165-public-tenant-and-facet-contracts/165-01-PLAN.md
  - .planning/phases/165-public-tenant-and-facet-contracts/165-01-SUMMARY.md
  - .planning/phases/165-public-tenant-and-facet-contracts/165-02-PLAN.md
  - .planning/phases/165-public-tenant-and-facet-contracts/165-02-SUMMARY.md
  - .planning/phases/165-public-tenant-and-facet-contracts/165-CONTEXT.md
  - .planning/phases/165-public-tenant-and-facet-contracts/165-RESEARCH.md
  - .planning/phases/165-public-tenant-and-facet-contracts/165-REVIEW.md
  - .planning/phases/165-public-tenant-and-facet-contracts/165-SECURITY.md
  - .planning/phases/165-public-tenant-and-facet-contracts/165-VALIDATION.md
  - AGENTS.md
  - lib/scrypath/meilisearch/client.ex
  - lib/scrypath/meilisearch/query.ex
  - lib/scrypath/options/search.ex
  - lib/scrypath/search/facet_values.ex
  - lib/scrypath/search/many.ex
  - lib/scrypath/search/single.ex
  - test/scrypath/facet_values_contract_test.exs
  - test/scrypath/tenant_scope_contract_test.exs
covered_digest: "v1:sha256:634b1095fb929517c65789b79a385968e9237413b92909eb684357c3d4d88738"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 12/12
  gaps_closed: []
  gaps_remaining: []
  regressions: []
---

# Phase 165: Public Tenant and Facet Contracts Verification Report

**Phase Goal:** Consumers can rely on Scrypath's existing public tenant-scope and facet-value input contracts, with corrections only for reproduced compatible defects.
**Verified:** 2026-09-27T23:27:13Z at source HEAD `03d8e63de5f0c60e5bd46d29ba375b1770b6b7cc`.
**Status:** passed
**Verification mode:** Initial goal-backward pass. The prior report had no `gaps:` section; its canonical freshness was stale.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | `tenant_scope:` composes with ordinary filters through `search/3`, shared-option `search_many/2`, and `search_facet_values/4`; collision and undeclared-scope inputs fail before dispatch. | VERIFIED | `tenant_scope_contract_test.exs` exercises the three public paths, records dispatched filters, and asserts no dispatch on invalid calls. Included in the focused run below. |
| 2 | Public facet defaults and keyword filters reach the facet endpoint in a Meilisearch-compatible request shape; only a reproduced compatible defect receives a correction and regression. | VERIFIED | The public Req.Test suite decodes the POST body for defaults, keyword filters, escaped values, and tenant composition. The independent baseline and narrow regression are documented in Plan 02's summary. This proves local request construction, not live service acceptance. |
| 3 | Declared tenant scope and ordinary status reach the backend together through all three paths. | VERIFIED | Recorder assertions observe normalized filter predicates for single, multi, and facet search. |
| 4 | Omitted and explicitly empty ordinary filters preserve tenant scope. | VERIFIED | Public-path loop covers omitted and `filter: []` for single, multi, and facet paths. |
| 5 | Equal/conflicting collisions and tenant scope on a schema without a tenant field fail before backend dispatch. | VERIFIED | Active cases assert public error shapes and absence of recorder messages for both collision values and undeclared schema. |
| 6 | Single/facet validation preserves `ArgumentError`; multi-search preserves its schema-associated validation tuple and preflights all entries. | VERIFIED | Named tests assert both error forms and show a valid first entry is not dispatched when a later entry is invalid. |
| 7 | Tenant-scope correction is limited to the reproduced runtime-option defect. | VERIFIED | Current Single, Many, and FacetValues runtime option extractors exclude `:tenant_scope` only after validation; the validated filter reaches the backend. The phase's reproduction/regression test passes. |
| 8 | Facet defaults use the expected endpoint and return a decorated facet result. | VERIFIED | Test asserts POST path, decoded `facetName`, `facetQuery`, and `filter: []`, then checks the returned bucket and query. |
| 9 | A documented nonempty keyword filter reaches the endpoint as a rendered expression through the real adapter. | VERIFIED | Public call is handled by `Scrypath.Meilisearch`; Req.Test decodes `status = "published"` from the actual request body. |
| 10 | Tenant scope and an ordinary facet filter both remain in the encoded request. | VERIFIED | Public Req.Test assertion finds both `status = "published"` and `tenant_id = 123`. |
| 11 | Invalid filters fail before HTTP; HTTP/transport errors preserve public errors without unfiltered fallback. | VERIFIED | Active tests cover preflight, HTTP 400, timeout, and bang-wrapper 503 behavior; error requests preserve the filter and are observed once. |
| 12 | Defaults and keyword inputs are classified separately, without treating unknown defaults alone as parser rejection. | VERIFIED | Defaults are accepted at the encoded-request boundary; keyword tuple serialization was independently reproduced and fixed by reusing the common filter renderer. Research and summaries distinguish Req.Test construction from live parser/service proof. |

**Score:** 12/12 truths verified (0 behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `test/scrypath/tenant_scope_contract_test.exs` | Independent public tenant contract | VERIFIED | Substantive recorder tests call the public API and inspect dispatched query/filter values. |
| `lib/scrypath/search/single.ex` | Validated search data separated from runtime config | VERIFIED | Excludes `:tenant_scope` from runtime config after validation; public regression exercises the path. |
| `lib/scrypath/search/many.ex` | Shared tenant config and complete preflight | VERIFIED | Excludes search-only options from runtime config and validates all entries before dispatch. |
| `lib/scrypath/search/facet_values.ex` | Facet orchestration with validated inputs | VERIFIED | Excludes `:tenant_scope` from runtime config; recorder observes composed filter. |
| `test/scrypath/facet_values_contract_test.exs` | Public defaults, keyword rendering, and error proof | VERIFIED | Substantive Req.Test suite enters through `search_facet_values/4` and decodes actual request bodies. |
| `lib/scrypath/meilisearch/client.ex` | Facet HTTP request construction | VERIFIED | Builds the facet endpoint payload and routes keyword filter input through the common renderer. |
| `lib/scrypath/meilisearch/query.ex` | Shared filter grammar and literal encoding | VERIFIED | Internal renderer reuses the existing query filter grammar and JSON literal encoding. |

Both plan artifact checks passed: Plan 01 4/4; Plan 02 3/3. No artifact is missing, stubbed, or orphaned.

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `tenant_scope_contract_test.exs` | `options/search.ex` | Public validation injects declared tenant scope | WIRED | Plan 01 key-link query verified; recorder observes dispatched predicates. |
| `search/many.ex` | `tenant_scope_contract_test.exs` | Shared tenant option survives runtime extraction | WIRED | Plan 01 key-link query verified; shared-option test observes it. |
| `search/facet_values.ex` | `tenant_scope_contract_test.exs` | Validated facet callback options reach recorder | WIRED | Plan 01 key-link query verified; callback assertion checks both predicates. |
| `facet_values_contract_test.exs` | `search/facet_values.ex` | Public API path | WIRED | Plan 02 key-link query verified; cases invoke `Scrypath.search_facet_values/4`. |
| `meilisearch.ex` | `meilisearch/client.ex` | Adapter invokes configured facet client | WIRED | Plan 02 key-link query verified; adapter call and endpoint are present. |
| `meilisearch/client.ex` | `facet_values_contract_test.exs` | Req.Test observes encoded HTTP | WIRED | Plan 02 key-link query verified; tests decode request bodies. |

Both plans' key-link checks passed: 6/6.

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| Tenant public search paths | `filter` | Caller options validated against schema metadata; tenant criterion is injected before query dispatch | Yes; recorder observes callback/query arguments | FLOWING |
| Facet request | `filter` | Public options → validation → orchestration → Meilisearch client → encoded Req body | Yes; test decodes actual serialized request | FLOWING |
| Facet result | hits/query | HTTP response decoded and decorated by the real adapter path | Test response supplies deterministic boundary input | FLOWING |

The repository's scope boundaries remain explicit: tenant composition does not establish host identity, authorization, trusted tenant selection, or database response scoping. Req.Test does not establish live service or package acceptance.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Tenant and facet public contracts | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix test test/scrypath/tenant_scope_contract_test.exs test/scrypath/facet_values_contract_test.exs` | 17 tests, 0 failures at `03d8e63de5f0c60e5bd46d29ba375b1770b6b7cc` | PASS |

### Probe Execution

Not applicable. Neither roadmap criterion nor plan declares a script probe; this is a library API contract phase.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| API-01 | `165-01-PLAN.md` | Tenant scope composes across public search paths; invalid scope rejects before dispatch. | SATISFIED | Public recorder tests cover each path, filter composition, rejection, and preflight; all pass. |
| API-02 | `165-02-PLAN.md` | Public facet inputs produce compatible request construction and preserve established errors. | SATISFIED | Public Req.Test assertions decode defaults, keyword filters, tenant composition, and error paths; all pass. |

No other requirements map to Phase 165; no orphaned requirements found.

### Prohibition Checks

| Prohibition | Status | Evidence |
|---|---|---|
| Do not represent tenant filter composition as authentication, authorization, trusted tenant selection, or database response scoping. | VERIFIED | Plan 01 summary explicitly keeps identity/membership and authorization host-owned; tests assert only composition/rejection at the library boundary. |
| Do not represent Req.Test or ignored default fields as live-service acceptance or broad compatibility. | VERIFIED | Plan 02 summary explicitly limits Req.Test to request construction/error propagation and hands the exact live/package scenario to Phase 166 conditionally. |

### Test Quality Audit

| Test File | Linked Req | Active | Skipped | Circular | Assertion Level | Verdict |
|---|---|---:|---:|---|---|---|
| `tenant_scope_contract_test.exs` | API-01 | 9 | 0 | No | Behavioral/value | PASS |
| `facet_values_contract_test.exs` | API-01, API-02 | 8 | 0 | No | Behavioral/value | PASS |

Disabled-test scan found none. Expected predicates and encoded literals are asserted independently of the production renderer; no circular fixture generation found. No test-quality blocker or insufficient assertion finding.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| — | — | No debt markers, placeholders, or empty production implementations found in phase implementation/test files. | — | None |

### Human Verification Required

N/A — infrastructure/library contract phase with no user-facing UX. The success criteria are resolved by focused executable tests and source wiring. Live Meilisearch/package acceptance is outside these criteria and is separately claim-bounded in the artifacts.

### Decision Coverage

All trackable CONTEXT decisions honored (7/7). `check.decision-coverage-verify` returned `blocking: false`, `not_honored: []`.

### Gaps Summary

No Phase 165 goal gaps found. The tests prove tenant filter composition/rejection and public facet request construction/error behavior. They do not claim tenant authorization or live-service acceptance. The Phase 166 service/package handoff remains explicit and conditional on the reproduced keyword correction.

---

_Verified: 2026-09-27T23:27:13Z_
_Verifier: gsd-verifier_
