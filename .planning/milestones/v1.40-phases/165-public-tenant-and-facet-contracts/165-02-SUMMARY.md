---
phase: 165-public-tenant-and-facet-contracts
plan: "02"
subsystem: search
tags: [facet_search, meilisearch, filters, req_test]

# Dependency graph
requires:
  - phase: 165-01
    provides: Public tenant scope is retained as a validated filter across search, multi-search, and facet search.
provides:
  - Public facet defaults and common keyword filter request evidence
  - Narrow reuse of the existing Meilisearch common-filter renderer for facet search
  - Public facet error and no-fallback behavior evidence
affects: [phase-166-host-tenant-and-repair-evidence]

# Actuals (#2632)
actuals:
  tokens: 2460
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Reuse the ordinary Meilisearch filter renderer when a facet endpoint receives common keyword filters.
    - Observe public request bodies after JSON encoding and distinguish pre-HTTP serialization errors from backend responses.

key-files:
  created:
    - test/scrypath/facet_values_contract_test.exs
  modified:
    - lib/scrypath/meilisearch/client.ex
    - lib/scrypath/meilisearch/query.ex

key-decisions:
  - Keep the defaults and keyword outcomes separate. The defaults probe passed its encoded-HTTP check; the keyword probe reproduced a Jason tuple-encoding failure before HTTP.
  - Render only nonempty keyword-shaped facet filters through the existing renderer; preserve empty defaults and already-rendered string-list filters.
  - Require Phase 166 to exercise this exact common-filter facet scenario against the live service and freshly built package because the construction defect was reproduced; Req.Test alone is not service or package acceptance.
  - Carry EA-02: evidence covers synchronous request construction and bounded no-fallback errors only; interruption and parallel backend execution semantics remain unclaimed.

patterns-established:
  - Public HTTP contract probes assert encoded request semantics independently of the production renderer.
  - Error probes count dispatches and inspect the submitted filter to rule out unfiltered fallback.

requirements-completed: [API-02, API-01]
coverage:
  - id: D1
    description: Public facet defaults reach the facet-search route and decorate a valid response as FacetSearchResult.
    requirement: API-02
    verification:
      - kind: integration
        ref: test/scrypath/facet_values_contract_test.exs#search_facet_values/4 forwards supported defaults through encoded HTTP
        status: pass
    human_judgment: false
  - id: D2
    description: Public keyword filters and escaped literals are rendered into Meilisearch filter expressions.
    requirement: API-02
    verification:
      - kind: integration
        ref: test/scrypath/facet_values_contract_test.exs#search_facet_values/4 renders a common keyword filter in the encoded request
        status: pass
      - kind: integration
        ref: test/scrypath/facet_values_contract_test.exs#search_facet_values/4 escapes common filter string literals in encoded HTTP
        status: pass
    human_judgment: false
  - id: D3
    description: Invalid common filters fail before dispatch; HTTP and transport failures preserve public reasons without retry or filter loss.
    requirement: API-02
    verification:
      - kind: integration
        ref: test/scrypath/facet_values_contract_test.exs#invalid boolean filter raises before HTTP dispatch
        status: pass
      - kind: integration
        ref: test/scrypath/facet_values_contract_test.exs#HTTP rejection preserves its error tuple and submitted filter
        status: pass
      - kind: integration
        ref: test/scrypath/facet_values_contract_test.exs#transport timeout preserves its error tuple and submitted filter
        status: pass
      - kind: integration
        ref: test/scrypath/facet_values_contract_test.exs#bang wrapper retains operational error reason without retrying or dropping filter
        status: pass
    human_judgment: false
  - id: D4
    description: A public facet request retains both tenant_scope and an ordinary status filter.
    requirement: API-01
    verification:
      - kind: integration
        ref: test/scrypath/facet_values_contract_test.exs#search_facet_values/4 combines tenant scope with the ordinary filter in encoded HTTP
        status: pass
      - kind: unit
        ref: test/scrypath/tenant_scope_contract_test.exs#search_facet_values/4 composes tenant scope with an ordinary filter
        status: pass
    human_judgment: false

# Metrics
duration: 16 min
completed: 2026-09-26
status: complete
plan_head_before: 9d3bf26466861d55fdc4eccd46546135b1d7589f
commits: 2
---

# Phase 165 Plan 02: Public Facet Filter Contract Summary

**Public facet defaults retain their encoded request shape, and common keyword filters now use the existing Meilisearch renderer before the real adapter sends JSON.**

## Performance

- **Duration:** 16 min, approximate from the Plan 01 handoff at 22:15 UTC through completion at 22:31 UTC.
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Proved the supported public defaults through `Scrypath.search_facet_values/4`, the real Meilisearch adapter, an encoded Req.Test request, and a decorated facet result.
- Reproduced and fixed the common keyword filter serialization failure. The correction reuses the ordinary Meilisearch renderer and preserves empty defaults and already-rendered string-list filters.
- Proved escaping, invalid-filter preflight, HTTP and timeout tuples, bang error reasons, one-request/no-fallback behavior, and the joined tenant/status filter body.

## Task Commits

1. **Task 1: Trace public facet defaults through encoded HTTP** — `9d3bf26` (`test(165-02): trace public facet defaults`)
2. **Task 2: Prove keyword filters and error behavior** — `a883958` (`fix(165-02): render public facet filters`)

## Files Created/Modified

- `test/scrypath/facet_values_contract_test.exs` — public defaults, keyword/escaped filters, preflight, error, no-fallback, and tenant composition cases.
- `lib/scrypath/meilisearch/client.ex` — renders nonempty keyword filters at the facet payload boundary while preserving the existing empty and rendered-list forms.
- `lib/scrypath/meilisearch/query.ex` — exposes a doc-hidden internal function that reuses the existing common filter grammar and JSON literal encoder.

## Baseline and Corrected Evidence

The task-1 tracer commit `9d3bf26466861d55fdc4eccd46546135b1d7589f` first passed the defaults probe before any production edit:

- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix test test/scrypath/facet_values_contract_test.exs --only facet_defaults` — 1 test, 0 failures (ExUnit 0.08 s). The public call reached `POST /indexes/facet_contract_facet_post/facet-search`; the test decoded the body, checked `facetName`, `facetQuery`, and `filter: []`, and received a `FacetSearchResult` with a bucket hit. The pinned Meilisearch 1.15 research says unknown search keys are ignored, so this passing construction probe does not infer a failure from extra defaults.
- The separately named keyword baseline at the same source SHA, `... mix test test/scrypath/facet_values_contract_test.exs --only facet_keyword`, ran 1 test and failed (ExUnit 0.07 s) with `Protocol.UndefinedError`: Jason could not encode the raw `{:status, "published"}` tuple. The stack failed in JSON body encoding before Req.Test observed a request; this was a library serialization defect, not a live Meilisearch rejection.

At corrected source commit `a883958c73d7f102a7404a317e0d13b7c15ccbd9`:

- The same keyword-tag command passed 1 test, 0 failures (ExUnit 0.09 s); the decoded request contained the rendered equality expression `status = "published"`.
- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix test test/scrypath/facet_values_contract_test.exs` passed all 8 cases (ExUnit 0.1 s). The escaping case preserved both embedded quotes and a backslash. The boolean filter raised before dispatch. HTTP rejection returned `{:error, {:http_error, 400, body}}`; transport timeout returned `{:error, {:transport_error, %Req.TransportError{reason: :timeout}}}`. The bang wrapper retained its `{:http_error, 503, body}` reason. Each backend failure captured one request with its filter and ruled out a fallback request.
- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix test test/scrypath/meilisearch/client_test.exs test/scrypath/meilisearch/query_test.exs` passed 14 tests, 0 failures (ExUnit 0.07 s).

## Contributor Verification

All Plan 02 gates below ran against source commit `a883958c73d7f102a7404a317e0d13b7c15ccbd9`:

- `... mix verify.phase96` — exit 0; 110 tests, 0 failures (ExUnit 0.8 s), then docs built with warnings as errors.
- `... mix verify.backend --skip-integration` — exit 0; the non-integration backend wrapper passed and explicitly skipped the Meilisearch smoke. No `SCRYPATH_INTEGRATION`, `SCRYPATH_MEILISEARCH_URL`, or Phoenix example service variables were present, so there is no live-service or package receipt from this run.
- `... mix verify.core --exclude integration --exclude docs_contract` — exit 0; format, clean packaged-path workspace, warnings-as-errors compilation, Credo, 4 properties and 591 tests (0 failures; 82 excluded), and warnings-as-errors docs build all passed. ExUnit runtime was 19.0 s; gate wall time was 21.0 s.

Plan 01's tenant and multi-search contributor receipts remain recorded separately in `165-01-SUMMARY.md` at its then-current source SHA; this plan did not rerun them.

## Decisions Made

- C11-R1 defaults and keyword inputs have different outcomes: defaults passed the encoded-body probe without a source correction; keyword filters failed before HTTP and received a narrow correction.
- The client changes only a nonempty keyword-shaped `filter`. Empty `filter: []` and already-rendered string lists retain their prior forms; ordinary search payload construction and the public input shape are unchanged.
- Error-body inspection and request counts establish bounded synchronous propagation with no unfiltered fallback. They do not claim cancellation, interruption, or parallel backend execution semantics (EA-02).

## Deviations from Plan

None. The keyword correction followed the planned baseline reproduction and reused the existing renderer. A first full-suite run exposed only an order-sensitive test expectation; the assertion was changed to compare both predicates without claiming ordering, then all cases passed.

## Issues Encountered

The baseline keyword request failed during JSON encoding because raw keyword tuples reached `Jason.Encoder`. The added renderer reuse fixed that exact boundary failure. No live Meilisearch service was configured, so service acceptance remains outside these local receipts.

## Next Phase Readiness

Phase 166 can proceed. Add this exact scenario to the existing live path-backed and package-backed Phoenix proof: call public `search_facet_values/4` with `filter: [status: "published"]` against Meilisearch 1.15, assert expected facet results under that predicate, and verify that excluded values do not appear. Reuse the existing advisory `phoenix-example` lane; this handoff does not request a new required CI lane or a release. Req.Test proves request construction and error propagation only, not service or package behavior.

---
*Phase: 165-public-tenant-and-facet-contracts*
*Completed: 2026-09-26*
