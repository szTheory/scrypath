---
phase: "184-explicit-and-lean-dependency-graphs"
plan: "09"
subsystem: documentation
tags: [support, compatibility, req, telemetry, docker, mix]

# Dependency graph
requires:
  - phase: "184-07"
    provides: ["Dependency graph evidence and consumer witness constraints"]
  - phase: "184-08"
    provides: ["Current lock, audit, and boundary-verification decisions"]
provides:
  - "Canonical source-checkout support, Req range, OTP tuple, Sigra tier, and dependency-audit claims"
  - "Accurate dev asset, runtime image, Ops mount, and maintainer verification runbooks"
affects: [support documentation, ScrypathOps, ecommerce demo, repository verification]

# Actuals (#2632)
actuals:
  tokens: 4487
  tasks: 2
  commits: 2
plan_head_before: fa48ad04a571e45b762b7a14263c53acc777b396
plan_head_after: 3ae40002c3d3d3c5b360a42dc850b97c8a035d5d

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Use a canonical support guide for source-versus-release claims and link consumer runbooks to it."
    - "Document independent asset-builder and runtime dependency graphs from their actual targets."

key-files:
  created:
    - .planning/phases/184-explicit-and-lean-dependency-graphs/184-09-SUMMARY.md
  modified:
    - guides/support-and-compatibility.md
    - scrypath_ops/README.md
    - examples/phoenix_meilisearch/README.md
    - test/mix/tasks/dependency_boundary_contract_test.exs
    - examples/scrypath_ecommerce/README.md
    - docs/local-demo-docker-dx.md
    - CONTRIBUTING.md

key-decisions:
  - "Keep Sigra's Elixir 1.18+ requirement as an optional Ops tier without inferring an OTP 27 floor."
  - "Treat compatibility tuples, upstream maintenance, and per-graph dependency audits as separate evidence."
  - "Keep task receipts external by default and the retained preview outside the disposable verification path."

requirements-completed: ["DEP-01", "DEP-02", "DEP-04", "DEP-05", "DEP-06", "DEP-07"]

coverage:
  - id: D1
    description: "Current support guidance distinguishes dependency ranges from witnesses, core test tuples from upstream OTP status, and clean graphs from the remaining Ops advisories."
    verification:
      - kind: unit
        ref: "test/mix/tasks/dependency_boundary_contract_test.exs#current support guidance separates admitted ranges, witnesses, tiers, and audit status"
        status: pass
      - kind: other
        ref: "mix docs --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "Developer and maintainer runbooks describe dev-only asset wrappers, output-only test/production targets, runtime inputs, and expanded verification capabilities."
    verification:
      - kind: other
        ref: "mix verify.repository_contracts"
        status: pass
      - kind: other
        ref: "mix docs --warnings-as-errors"
        status: pass
    human_judgment: true
    rationale: "Repository contracts and ExDoc passed, but automation does not assert every documented command against a live Docker runtime."

duration: 5min
completed: 2026-10-30
status: complete
---

# Phase 184 Plan 09: Explicit and Lean Dependency Graphs Summary

**Support claims now separate Req admission from tested witnesses, OTP compatibility tuples from upstream maintenance, and dev asset generation from independent test and production runtime targets.**

## Performance

- **Duration:** 5 min from first tracked edit; the required context reads preceded that timestamp.
- **Started:** 2026-10-30T07:11:35Z (first tracked edit)
- **Completed:** 2026-10-30T07:17:00Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Centralized current source and released-package boundaries, the exact Req union and two consumer witnesses, tested Elixir/OTP tuples, dated OTP 26 upstream status, the optional Sigra tier, and the remaining Cloak advisories.
- Clarified ScrypathOps host authentication and mount ownership, dev-only asset wrappers, the exact JavaScript/CSS outputs, independent runtime_test / runtime_prod targets, production inputs, and disposable receipt locations.
- Updated maintainer runbooks for the expanded verify.ops_ui and verify.ecommerce_mounted proofs while keeping repository-only commands distinct from Hex package claims.

## Task Commits

Each task was committed atomically:

1. **Task 184-09-01: Explain dependency ranges, support tiers and honest security limits** — 97227b2f (docs)
2. **Task 184-09-02: Document dev-builder/output-only runtime commands and capabilities** — 3ae40002 (docs)

**Plan metadata:** this summary is committed separately after both task commits.


- **Orchestrator repair:** `fbadaefed44274fcfb35a312b0062940f67d3cb7` — docs(184-09): correct the standalone Ops toolchain prerequisite.

## Files Created/Modified

- guides/support-and-compatibility.md — Current source/release support, compatibility, dependency, and audit authority.
- scrypath_ops/README.md — Host mount/auth boundary and dev versus runtime asset requirements.
- examples/phoenix_meilisearch/README.md — Links to canonical support and tuple guidance.
- test/mix/tasks/dependency_boundary_contract_test.exs — Focused assertions for current support claims and working runbook links.
- examples/scrypath_ecommerce/README.md — Asset/runtime boundaries, mounted proof scope, and external receipt guidance.
- docs/local-demo-docker-dx.md — Actual wrapper commands, build targets, static outputs, runtime inputs, and receipt paths.
- CONTRIBUTING.md — Source-only command scope and current Ops/mounted CI proof descriptions.
- .planning/phases/184-explicit-and-lean-dependency-graphs/184-09-SUMMARY.md — This plan summary.

## Decisions Made

- Kept Sigra's Elixir 1.18+ metadata as an optional Ops tier; it does not raise the root Elixir 1.17 floor or imply an OTP 27 minimum.
- Kept upstream OTP maintenance, compatibility test evidence, and per-graph advisory results as separate claims.
- Documented mounted ScrypathOps as using the host Endpoint and Repo; the runtime :standalone flag controls Ops-owned children, not dependency inclusion or compilation.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first focused test invocation found no root test dependencies in the checkout. A lockfile-checked fetch in private Mix, Hex, build, and dependency directories supplied the pinned dependencies without writing to the shared Hex cache.
- The first ExDoc build flagged a ScrypathOps security-file link that was not part of the root docs bundle. The support guide now links to the included Ops production runbook, which links to the detailed security boundary.
- The first run of the newly added source assertion did not account for a line-wrapped dependency tuple. The assertion was corrected; the final focused test passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 184-09 is complete and ready for the orchestrator's next phase action. No UI source, preview state, STATE.md, or ROADMAP.md was changed.

## Self-Check: PASSED

- Plan verification passed: focused contract test (15 tests), ExDoc warnings-as-errors, and repository contracts (121 tests).
- Both task commits exist on this branch and match the two-task evaluation scope.
- Declared task files exist, the new summary path is being checked before commit, and the stub scan returned no matches.
