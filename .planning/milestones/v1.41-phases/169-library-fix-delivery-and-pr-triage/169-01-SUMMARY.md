---
phase: 169-library-fix-delivery-and-pr-triage
plan: "01"
subsystem: search
tags: [tenant-scope, facet-search, meilisearch, ecto, regression-tests]

requires:
  - phase: 168-dependency-security-and-reliable-verification
    provides: refreshed public-main base with Phase 168 security, package graph, audit, and mounted-readiness work
provides:
  - validated tenant scope is removed from strict runtime configuration in Single, Many, and FacetValues
  - facet keyword filters reuse the existing Meilisearch query renderer
  - public recorder and encoded-request regression coverage for tenant and facet contracts
  - dated local-to-public source baseline and candidate handoff identity
affects: [169-02, 169-03, 169-04, 169-05]

actuals:
  tokens: 5503.25
  tasks: 3
  commits: 3
  plan_head_before: 2832e91d725d70eff9ba11d08052260ba17e2747

tech-stack:
  added: []
  patterns:
    - validated search-only options are dropped only at strict runtime configuration boundaries
    - facet filter requests reuse the existing common-filter renderer and assert literal encoded grammar

key-files:
  created:
    - test/scrypath/facet_values_contract_test.exs
    - test/scrypath/tenant_scope_contract_test.exs
  modified:
    - lib/scrypath/search/facet_values.ex
    - lib/scrypath/meilisearch/client.ex
    - lib/scrypath/meilisearch/query.ex
    - lib/scrypath/search/single.ex
    - lib/scrypath/search/many.ex

key-decisions:
  - "Keep tenant_scope out of strict runtime configuration after schema-aware validation has composed its predicate."
  - "Render only nonempty keyword facet filters through the existing internal Meilisearch renderer; preserve empty and pre-rendered forms."
  - "Treat Req.Test and recorder assertions as request-construction and library-composition evidence, not service or package evidence."

requirements-completed: [DELIV-02]
coverage:
  - id: D1
    description: "FacetValues sends an encoded request containing tenant and ordinary keyword predicates."
    requirement: DELIV-02
    verification:
      - kind: unit
        ref: test/scrypath/facet_values_contract_test.exs#facet_tenant_tracer
        status: pass
    human_judgment: false
  - id: D2
    description: "Single, Many, and FacetValues preserve validated tenant predicates and reject invalid collisions before dispatch."
    requirement: DELIV-02
    verification:
      - kind: unit
        ref: test/scrypath/tenant_scope_contract_test.exs
        status: pass
    human_judgment: false
  - id: D3
    description: "Facet defaults, escaping, bounded error propagation, and scoped facet composition remain compatible."
    requirement: DELIV-02
    verification:
      - kind: unit
        ref: "mix test test/scrypath/facet_values_contract_test.exs test/scrypath/search_within_facet_test.exs"
        status: pass
    human_judgment: false

duration: 19 min
completed: 2026-09-29
status: complete
commits: 3
---

# Phase 169 Plan 01: Library Fix Delivery and PR Triage Summary

**Tenant-scoped facet and search requests now preserve validated scope, and facet keyword filters use the existing Meilisearch filter grammar.**

## Performance

- **Duration:** 19 min
- **Started:** 2026-09-29T19:10:36Z
- **Completed:** 2026-09-29T19:29:48Z
- **Tasks:** 3
- **Files modified:** 8, including this summary

## Accomplishments

- Restored the tenant option partition in `Single`, `Many`, and `FacetValues` without changing the strict runtime option schema or pre-dispatch validation.
- Routed nonempty keyword filters for facet search through `Meilisearch.Query.render_common_filter/1`; empty filters and pre-rendered string lists retain their existing handling.
- Added a public encoded-request tracer and recorder coverage for all three public search paths, collision rejection, omitted/empty filters, and Many's all-entry preflight.
- Established the implementation candidate from refreshed public `main` at `2832e91d725d70eff9ba11d08052260ba17e2747`. The final candidate source is `2089bd8ea27a793985669e15b7a00a5eb6074562` on the plan candidate branch.
- Captured the dated baseline in `baseline.json` under `$SCRYPATH_PHASE169_EVIDENCE_DIR`; its SHA-256 is `52ad99d0cb5ac08577388a653fead31714a43982f19093f7dd5f5e3b3df44d1a`. It records the preserved local source identity `aadc06a8833a0132e8c3a0bc7e47c49994ac7e25`, both-direction blob differences, and 21 pre-existing dirty paths. A post-run comparison confirmed all 21 dirty fingerprints were unchanged.
- The candidate's four tracked lockfiles match the selected public-main base. Phase 168 inputs remain present through the exact public-main base; no lockfile or dependency change was selected.

## Verification

- `mix test test/scrypath/facet_values_contract_test.exs --only facet_tenant_tracer` on the test-only baseline commit `17ba14c` ran the named test and failed at the expected strict runtime-option rejection (`unknown options [:tenant_scope]`); the same tracer passes in the final candidate suite.
- `mix test test/scrypath/tenant_scope_contract_test.exs` — 9 tests, 0 failures.
- `mix test test/scrypath/facet_values_contract_test.exs test/scrypath/search_within_facet_test.exs` — 12 tests, 0 failures.
- `mix test --exclude integration --exclude docs_contract` — 4 properties, 628 tests, 0 failures, 82 excluded; ExUnit runtime 19.9 s. The suite ran against candidate source `2089bd8ea27a793985669e15b7a00a5eb6074562`.
- `mix format --check-formatted` on changed Elixir files and `git diff --check` passed. The public-main lockfile comparison passed, and the candidate working tree is clean.
- The red tenant recorder run before the `Single`/`Many` correction reported 3 failures out of 9, each at strict runtime option validation. After the correction all 9 cases passed.

These checks prove local library composition and encoded request construction. They do not establish Meilisearch service behavior, package-backed behavior, merge status, or publication.

## Task Commits

1. **Task 1: Trace a tenant-scoped keyword facet request on the clean candidate** — `17ba14c` (RED test), `4ef6a68` (implementation).
2. **Task 2: Restore tenant composition and rejection across all public paths** — `2089bd8`.
3. **Task 3: Preserve facet defaults, escaping and bounded error behavior** — no additional source delta; its 12-test focused verification and the plan fast suite passed.

## Files Created/Modified

- `lib/scrypath/search/facet_values.ex` — excludes validated `tenant_scope` at the runtime boundary.
- `lib/scrypath/search/single.ex` and `lib/scrypath/search/many.ex` — apply the same narrow runtime option partition.
- `lib/scrypath/meilisearch/client.ex` and `lib/scrypath/meilisearch/query.ex` — reuse the existing common filter grammar for keyword facet filters.
- `test/scrypath/facet_values_contract_test.exs` — encoded request, defaults, escaping, validation, and bounded error contracts.
- `test/scrypath/tenant_scope_contract_test.exs` — public search-path composition, rejection, and preflight contracts.

## Decisions Made

- Keep validated tenant scope in the composed filter and drop only the search-only option before strict runtime configuration.
- Keep expected encoded filter strings independent from the production renderer so the request oracle can catch serializer regressions.
- Preserve the evidence boundary: recorder and Req.Test results are local contract evidence only.

## Deviations from Plan

The refreshed public-main candidate did not contain the historical facet and tenant contract test modules. Task 1 restored the existing facet contract module together with the joined tracer, including cases called out for Task 3. Task 3 therefore required verification but no additional facet test-file change. The scoped-facet test already matched refreshed public `main`, so no delta was copied. No production scope was added.

**Total deviations:** 0 correctness fixes outside planned scope.
**Impact on plan:** All planned contracts were implemented and verified; the test-file sequencing avoided importing unrelated source or dependency changes.

## Issues Encountered

- The first test attempt lacked fetched Hex dependencies. Fetching the dependencies declared by the candidate lockfile succeeded after directing Hex's cache to the task evidence area; no lockfile changed.
- The preserved maintainer checkout has rewritten history and unrelated dirty files, so its source comparison used recorded blob identities rather than ancestry-based diff ranges. All original dirty fingerprints were confirmed unchanged.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plans 02 and 03 can branch from candidate source `2089bd8ea27a793985669e15b7a00a5eb6074562` for their separately owned proof slices.
- Plan 04 can integrate this candidate with their reviewed commits. Phase 170 remains responsible for any release or publication decision.

## Self-Check: PASSED

- Created regression modules exist in the candidate.
- Candidate commits `17ba14c`, `4ef6a68`, and `2089bd8` exist on the plan candidate branch.
- Candidate source is clean at `2089bd8ea27a793985669e15b7a00a5eb6074562`.

---
*Phase: 169-library-fix-delivery-and-pr-triage*
*Completed: 2026-09-29*
