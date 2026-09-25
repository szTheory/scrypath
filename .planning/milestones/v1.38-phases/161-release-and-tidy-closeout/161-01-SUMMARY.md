---
phase: 161-release-and-tidy-closeout
plan: 01
subsystem: docs
tags: [phoenix, package-proof, release, exdoc, documentation-contract]
requires:
  - phase: 160-package-backed-phoenix-proof
    provides: Package-backed Phoenix integration proof and exact-SHA evidence
provides:
  - Canonical Phoenix package proof runbook with real-service scope and evidence limits
  - Maintainer and release docs aligned with command order and publish evidence boundaries
  - Executable documentation contract for the runbook and release claims
affects: [release-readiness, adopter-proof, maintainer-workflow]
actuals:
  tokens: 1400
  tasks: 2
  commits: 2
tech-stack:
  added: []
  patterns: [Documentation claims tied to executable contracts, Explicit synthetic versus live evidence boundaries]
key-files:
  created: []
  modified:
    - CONTRIBUTING.md
    - docs/releasing.md
    - examples/phoenix_meilisearch/README.md
    - test/scrypath/docs_contract_test.exs
key-decisions:
  - "Keep the example README as the sole detailed service runbook; maintainer docs link to it."
  - "Treat package/docs checks as pre-publish evidence and release_publish/release_parity as post-publish evidence."
patterns-established:
  - "Documentation and synthetic checks state only what their assertions establish; live service proof is identified separately."
requirements-completed: [DOC-01, HYGIENE-01]
coverage:
  - id: D1
    description: "Adopter runbook describes the package artifact, prerequisites, four live scenario classes, and proof limits."
    requirement: DOC-01
    verification:
      - kind: unit
        ref: "test/scrypath/docs_contract_test.exs#Phoenix package runbook states the artifact, scenarios, prerequisites, and evidence limit"
        status: pass
      - kind: other
        ref: "ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.1 mix test test/scrypath/docs_contract_test.exs test/mix/tasks/verify_capability_test.exs test/mix/tasks/verify_phoenix_example_package_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Maintainer docs distinguish advisory/live Phoenix proof and pre-publish checks from post-publish Hex and HexDocs evidence."
    requirement: HYGIENE-01
    verification:
      - kind: unit
        ref: "test/scrypath/docs_contract_test.exs#maintainer and release docs preserve command and evidence boundaries"
        status: pass
      - kind: other
        ref: "ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.1 mix docs --warnings-as-errors"
        status: pass
    human_judgment: false
duration: 30min
completed: 2026-09-24
status: complete
---

# Phase 161 Plan 01: Canonical Proof Documentation Summary

**Phoenix package proof documentation now names the exact adopter workflow, distinguishes four live integration paths, and sets precise limits on what documentation, synthetic checks, and post-publish checks prove.**

## Performance

- **Duration:** 30 min
- **Started:** 2026-09-24T15:00:00Z
- **Completed:** 2026-09-24T15:30:56Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Expanded the canonical Phoenix example README with the package artifact explanation, required environment and reachable services, four scenario classes, and synthetic-versus-live proof boundary.
- Updated contributor and release guidance to point to the canonical runbook and distinguish advisory CI, pre-publish checks, and post-publish Hex/HexDocs evidence.
- Added executable contracts for the adopter and maintainer claims.

## Task Commits

Each task was committed atomically:

1. **Task 1: Bind adopter proof claims to contracts** - `f5e97f5` (test)
2. **Task 2: Align maintainer and release guidance** - `c468ce6` (docs; includes the linked runbook contract)

## Files Created/Modified

- `examples/phoenix_meilisearch/README.md` - Canonical adopter runbook and proof scope.
- `CONTRIBUTING.md` - Maintainer command sequence, advisory/live evidence boundary, and runbook link.
- `docs/releasing.md` - Pre-publish and post-publish evidence distinction.
- `test/scrypath/docs_contract_test.exs` - Executable contracts for the docs claims.

## Decisions Made

- Kept service setup detail in the existing example README and linked to it from maintainer docs.
- Described package and docs-contract gates as pre-publish checks; only post-publish release checks establish published package and docs availability/parity.

## Deviations from Plan

None - plan executed as specified.

## Issues Encountered

- The default `mix` shim had no selected version. Used the installed project toolchain, Elixir 1.19.0 / OTP 28.1.
- The initial added documentation assertions failed as expected; wording was aligned to the observed implementation and the full focused contract set then passed.

## Verification

- `mix test test/scrypath/docs_contract_test.exs` — **PASS**, 73 tests, 0 failures after final wording alignment (run with Elixir 1.19.0 / OTP 28.1).
- `mix test test/scrypath/docs_contract_test.exs test/mix/tasks/verify_capability_test.exs test/mix/tasks/verify_phoenix_example_package_test.exs` — **PASS**, 84 tests, 0 failures.
- `mix docs --warnings-as-errors` — **PASS**.
- `git diff --check` — **PASS**.

## Self-Check: PASSED

- Summary file exists at the expected path.
- Task commits `f5e97f5` and `c468ce6` are present in reachable history.
- Measured plan commit count is 2 from base `34d1d1c1af092f08af6f818ff10fd78966df6987`.

## Next Phase Readiness

- Plan 01 is complete. Plan 02 can proceed with Mint dependency remediation.
- The Phase 160 hosted real-service evidence remains the evidence for the package-backed scenarios; these docs checks do not substitute for it.

---
*Phase: 161-release-and-tidy-closeout*
*Completed: 2026-09-24*
