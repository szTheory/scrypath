---
phase: 165-public-tenant-and-facet-contracts
plan: "01"
subsystem: search
tags: [tenant_scope, search, multi_search, facet_values]

# Dependency graph
requires: []
provides:
  - Public tenant-scope composition and rejection evidence for search, multi-search, and facet search
  - Runtime option separation that keeps the validated tenant predicate while excluding tenant_scope from strict runtime configuration
affects: [phase-166-host-tenant-and-repair-evidence]

# Actuals (#2632)
actuals:
  tokens: 2694
  tasks: 2
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Exclude search-only options from runtime configuration after public validation

key-files:
  created:
    - test/scrypath/tenant_scope_contract_test.exs
  modified:
    - lib/scrypath/search/single.ex
    - lib/scrypath/search/many.ex
    - lib/scrypath/search/facet_values.ex

key-decisions:
  - Keep tenant_scope in the validated filter and remove it from all three runtime configuration inputs.
  - Treat recording-backend evidence as library filter composition only; host identity and authorization remain host-owned.

patterns-established:
  - Observe public search dispatch with a local recorder and assert predicate meaning independently of predicate order.

requirements-completed: [API-01]
coverage:
  - id: D1
    description: Tenant scope composes with ordinary, omitted, and empty filters across the three public search paths.
    requirement: API-01
    verification:
      - kind: unit
        ref: test/scrypath/tenant_scope_contract_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Equal and conflicting tenant filter collisions, undeclared tenant scope, and invalid later multi-search entries are rejected before dispatch.
    requirement: API-01
    verification:
      - kind: unit
        ref: test/scrypath/tenant_scope_contract_test.exs
        status: pass
    human_judgment: false

# Metrics
duration: 9 min
completed: 2026-09-26
status: complete
plan_head_before: 953e62e9a874545d4022669b1a5af883938943e5
commits: 3
---

# Phase 165 Plan 01: Public Tenant Contract Summary

The public tenant probes confirmed a runtime-option leak in all three shared-option paths. Excluding `tenant_scope` from runtime configuration preserves the already validated tenant predicate and restores public search dispatch.

## Performance

- **Duration:** 9 min from the Phase 165 start marker; plan-only start was not separately recorded.
- **Started:** 2026-09-26T22:06:29Z (phase execution start marker)
- **Completed:** 2026-09-26T22:15:26Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added independent public recorder coverage for `search/3`, shared and entry-option `search_many/2`, and `search_facet_values/4`.
- Reproduced `tenant_scope` reaching strict runtime configuration validation in Single, Many, and FacetValues, then excluded only that search-only option from each runtime config input.
- Verified omitted and empty filters retain the tenant predicate; equal-value and differing-value collisions, undeclared tenant scope, and a valid-then-invalid multi-search list dispatch nothing.

## Task Commits

1. **Task 1: Trace public single-search tenant composition** — `89d4209` (`fix(165-01): preserve tenant scope in public search`)
2. **Task 2: Extend tenant proof to multi-search, facet search, and rejection** — `493ca34` (`fix(165-01): preserve tenant scope across search paths`)

Plan metadata is committed with this summary.

## Files Created/Modified

- `test/scrypath/tenant_scope_contract_test.exs` — nine public-path, composition, and rejection cases using a process-local recording backend.
- `lib/scrypath/search/single.ex` — excludes validated `tenant_scope` from runtime configuration.
- `lib/scrypath/search/many.ex` — excludes shared `tenant_scope` from runtime configuration.
- `lib/scrypath/search/facet_values.ex` — excludes validated `tenant_scope` from runtime configuration.

## Baseline and Corrected Evidence

- **Task 1 baseline:** source HEAD `953e62e9a874545d4022669b1a5af883938943e5`; `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix test test/scrypath/tenant_scope_contract_test.exs --only tenant_tracer` ran one test and failed with `ArgumentError: unknown options [:tenant_scope]` in `Scrypath.Search.Single.run/5` before backend dispatch (ExUnit 0.07 s).
- **Task 1 corrected probe:** the same command passed 1 test, 0 failures (ExUnit 0.05 s); the correction and tracer are in `89d4209`.
- **Task 2 baseline:** production source HEAD `89d42095ed2dda6797fac7f1737da98b78ef955e`, with the expanded test file present as a local uncommitted test addition; the full file ran 9 tests with 3 failures. Shared multi-search and facet search raised the same unknown-option error. Entry-level multi-search scope and the rejection/preflight checks passed.
- **Corrected suite:** at the working-tree content committed as `493ca34`, `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix test test/scrypath/tenant_scope_contract_test.exs` passed 9 tests, 0 failures (ExUnit 0.7 s).

The passing suite exercised these exact cases:

1. `search/3 composes tenant scope with an ordinary filter before backend dispatch`
2. `search_many/2 applies shared tenant scope with an ordinary filter`
3. `search_many/2 applies tenant scope from an entry while preserving shared options`
4. `search_facet_values/4 composes tenant scope with an ordinary filter`
5. `all public search paths preserve tenant scope with omitted and empty filters`
6. `single and facet search reject equal and conflicting tenant filter collisions before dispatch`
7. `single and facet search reject undeclared tenant scope before dispatch`
8. `search_many/2 rejects collisions and undeclared scope before dispatch`
9. `search_many/2 preflights every entry before dispatching any search`

## Contributor Verification

Both contributor gates ran against source commit `493ca34024ae4909c771a99eb42e86f3392383e3`:

- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix verify.phase94` — exit 0; 137 tests passed and documentation built with warnings as errors. The first invocation's terminal session expired before its exit status was returned; a repeat confirmed exit 0 (test runtime 1.1 s).
- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix verify.phase41` — exit 0; 116 tests passed (test runtime 1.3 s).

The project emitted existing schema/settings advisory warnings; neither gate reported a failure. Plan 02 owns the single consolidated core verification after both proof units.

## Decisions Made

- `tenant_scope` remains a schema-validated search input. Each runtime extractor omits it from strict runtime configuration after validation has composed it into `filter`.
- Assertions compare predicate meaning without creating a filter-list ordering or result tie-order stability claim (EA-01).
- `nil` or absent tenant identity policy remains unresolved and host-owned (EA-03). This evidence does not prove identity, membership, trusted tenant selection, authorization, or database response scoping.

## Deviations from Plan

None. Each production correction followed the plan's public reproduction gate and changed only the responsible runtime-option extractor.

## Issues Encountered

The three original shared-option paths reproduced the planned runtime-option leak. The narrow corrections passed the public contract suite; no unresolved implementation issue remains.

## Next Phase Readiness

Plan 02 is ready to run. This recording-backend evidence does not imply live Meilisearch, package, or host-policy acceptance. Any Phase 166 facet service/package implication remains conditional on Plan 02 reproducing a compatible public facet defect; historical opt-outs alone do not create that requirement.

## Self-Check: PASSED

Both tasks, all nine contract cases, the focused tenant and multi-search contributor gates, the expected task commits, exact baseline outcomes, and the bounded evidence claims are recorded.

---
*Phase: 165-public-tenant-and-facet-contracts*
*Completed: 2026-09-26*
