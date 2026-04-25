---
phase: 66-runner-library-contract
plan: "01"
subsystem: docs
tags: [elixir, scrypath_ops, playbooks, docs, contract]
requires:
  - phase: 65-playbook-run-lifecycle-opsui
    provides: raw runner results plus downstream failure formatting ownership
provides:
  - canonical runner-library contract docs in `ScrypathOps.Playbook.Runner`
  - schema-doc wayfinding from playbook JSON format docs to the runner contract
affects: [phase-66-plan-02, docs-contract-playbooks, opsui-run-contract]
tech-stack:
  added: []
  patterns:
    - canonical runner contract lives in moduledoc; schema docs link out instead of duplicating runtime semantics
key-files:
  created: []
  modified:
    - scrypath_ops/lib/scrypath_ops/playbook/runner.ex
    - scrypath_ops/docs/playbook-schema-v1.md
key-decisions:
  - "Kept `Runner.run_validated/3` on a raw `{:ok, result} | {:error, reason}` seam and documented reason identity as the stable compatibility key."
  - "Left `playbook-schema-v1.md` as the JSON wire-format authority and linked maintainers to the runner moduledoc for execution semantics."
patterns-established:
  - "Runner moduledoc is the single contract source for playbook execution outcomes."
  - "Published schema docs may reference the runner contract but do not restate success or failure tuple semantics."
requirements-completed: [OPS3-03]
duration: 5min
completed: 2026-04-22
---

# Phase 66 Plan 01: Canonical contract and boundary freeze Summary

**Runner moduledoc now names the canonical playbook execution tuple contract, and the schema guide points to it instead of restating runtime result semantics**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-22T22:40:00Z
- **Completed:** 2026-04-22T22:44:49Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added a dedicated `## Runner-library contract` section to `ScrypathOps.Playbook.Runner` that documents validated input shape, `%Scrypath.SearchResult{}` / `%Scrypath.MultiSearchResult{}` success outcomes, raw `{:error, reason}` failures, and downstream formatting ownership.
- Kept the runner boundary guidance explicit about narrow module-resolution rescue scope so the contract does not imply silent normalization beyond the existing `ArgumentError` guard.
- Added a top-level note in `playbook-schema-v1.md` that sends maintainers to `Runner` for execution semantics while preserving the schema doc as the wire-format authority.

## Task Commits

Each task was committed atomically:

1. **Task 1: Freeze the canonical runner-library contract in `Runner`** - `a810364` (docs)
2. **Task 2: Keep the playbook schema doc as wire-format authority only** - `0f3d672` (docs)

**Plan metadata:** pending final docs commit for summary/state artifacts

## Files Created/Modified

- `scrypath_ops/lib/scrypath_ops/playbook/runner.ex` - Canonical runner-library contract wording and narrow boundary guidance.
- `scrypath_ops/docs/playbook-schema-v1.md` - Wire-format-only note linking to the runner contract.

## Decisions Made

- Kept the public execution seam at raw tuples instead of introducing a new `%RunError{}` or UI-ready response shape.
- Treated `RunFailure`, `PlaybookLive`, `Scrypath.Errors`, and Mix/operator tasks as downstream presentation layers that format reasons after the raw reason exists.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Issues Encountered

- `mix test test/scrypath/docs_contract_test.exs` failed on pre-existing out-of-scope planning/docs invariants unrelated to this plan's files. Logged in `.planning/phases/66-runner-library-contract/deferred-items.md`.

## Verification

- `mix test scrypath_ops/test/scrypath_ops/playbook/runner_test.exs` — passed
- `mix test test/scrypath/docs_contract_test.exs` — failed on pre-existing out-of-scope `AUDT-01` and `CONTRIBUTING` contract assertions

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 02 can add parity coverage against this now-explicit runner contract without redefining the public seam.
- The schema guide now points outward to the runner contract, reducing doc drift risk for later verification work.

## Self-Check: PASSED
