---
phase: 174-recovery-entry-and-diagnosis
plan: 05
subsystem: ui
tags: [phoenix-liveview, failed-sync, recovery, accessibility]

# Dependency graph
requires:
  - phase: 174-03
    provides: Current-schema recovery target and operator status contracts
  - phase: 174-04
    provides: Source-keyed recovery and host/server gating contracts
provides:
  - Source/schema/full-ID qualified row, retry, receipt, and delete-confirmation identities
  - Failed-work diagnosis and manual replay facts before collapsed diagnostics
  - Accepted replacement copy that preserves original history and unknown terminal state
affects: [174-06, 174-08, OPUX-18, OPUX-19]

# Actuals (#2632): chars/4 over the realized diff from the persisted plan base.
actuals:
  tokens: 33375
  tasks: 2
  commits: 4

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Opaque length-prefixed UTF-8 schema/source/full-ID key resolved only against current inspection
    - Source-specific recovery availability and receipt copy in the normal row reading order

key-files:
  created:
    - .planning/phases/174-recovery-entry-and-diagnosis/174-05-T1-RED.json
    - .planning/phases/174-recovery-entry-and-diagnosis/174-05-T1-RED.tap
    - .planning/phases/174-recovery-entry-and-diagnosis/174-05-T2-RED.json
    - .planning/phases/174-recovery-entry-and-diagnosis/174-05-T2-RED.tap
  modified:
    - scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex
    - scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/recovery_journey_live_test.exs
    - scrypath_ops/test/scrypath_ops_web/operator_ia_contract_test.exs
    - scrypath_ops/assets/css/app.css
    - scrypath_ops/priv/static/assets/css/app.css

key-decisions:
  - "Only the encoded current-schema/source/full-ID key identifies an action; legacy numeric IDs are not resolved."
  - "Manual replay is described from RecoveryAction data, separately from Oban retry state and subject to existing server/host gates."
  - "OPUX-18 and OPUX-19 remain pending until the dependent phase evidence is ready."

requirements-completed: []
coverage:
  - id: D1
    description: Source-qualified row and retry identity prevents equal backend-task and queue-job IDs from crossing.
    requirement: OPUX-18
    verification:
      - kind: unit
        ref: scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs#every source-qualified work row uses an opaque stable DOM and action key
        status: pass
      - kind: integration
        ref: scrypath_ops/test/scrypath_ops_web/live/recovery_journey_live_test.exs#retry identifies the queue row when a backend task has the same numeric id
        status: pass
      - kind: automated_ui
        ref: Phase 174 plan 08 responsive mounted and standalone browser proof
        status: unknown
    human_judgment: false
  - id: D2
    description: Work cause, exact source facts, manual recovery availability, and non-terminal replacement receipt are shown before Diagnostics.
    requirement: OPUX-18
    verification:
      - kind: unit
        ref: scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs#diagnosis and current recovery availability precede collapsed diagnostics
        status: pass
      - kind: integration
        ref: scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs#sigra retry refreshes the inspection in place without losing local state
        status: pass
      - kind: automated_ui
        ref: Phase 174 plan 08 responsive mounted and standalone browser proof
        status: unknown
    human_judgment: false
  - id: D3
    description: Retry and delete-confirmation events remain bound to the current allowlisted schema and exact inspected work.
    requirement: OPUX-19
    verification:
      - kind: integration
        ref: scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs#explicit invalid or removed selections show unavailable and refuse retry
        status: pass
      - kind: integration
        ref: scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs#delete retry requires confirmation and Cancel keeps the failed row
        status: pass
      - kind: automated_ui
        ref: Phase 174 plan 08 responsive mounted and standalone browser proof
        status: unknown
    human_judgment: false

metrics:
  duration: 21m
  completed: 2026-10-07
status: complete
plan_head_before: ee7e4e4f638e65479a368352aec42f79b59afa2c
plan_head_after: d26df4a61809af81aa80715bed152610fa204cdd
commits: 4
---

# Phase 174 Plan 05: Recovery Entry and Diagnosis Summary

**Failed sync records now bind actions and receipts to the current schema, source, and full ID while explaining supported manual recovery before Diagnostics.**

## Performance

- **Duration:** 21 min
- **Started:** 2026-10-07T14:20:49Z
- **Completed:** 2026-10-07T14:41:14Z
- **Tasks:** 2
- **Files modified:** 10, including four committed RED evidence artifacts

## Accomplishments

- Added source-qualified opaque identities to each rendered work row, action, receipt, and delete confirmation. Retry events now resolve only the exact key against the current selected-schema inspection and current live allowlist; a bare numeric ID is refused.
- Put selected schema, operation, index, source/queue/worker, source time, attempt data when present, bounded reason, and recovery availability before Diagnostics. Backend tasks have no invented replay action; supported queue actions use the standard 40px Ops button.
- Made accepted replacements say “Replacement accepted — queue job 991. Terminal completion has not been observed.” while keeping the original failed row, operation/index evidence, and Check sync status handoff.
- Added local wrapping and scrollable delete-confirmation styles, then rebuilt the existing Ops CSS asset.

## Task Commits

1. **Task 1: Qualify every rendered work identity and revalidate every action** — `3758692` (test-only RED), `881147d` (implementation).
2. **Task 2: Put work cause and supported recovery before verbose diagnostics** — `bf7e318` (test-only RED), `d26df4a` (implementation).

Each RED report passed `check tdd-red-evidence` as `RED_EVIDENCE_OK` after semantic inspection. The corresponding TAP and JSON reports are committed at `.planning/phases/174-recovery-entry-and-diagnosis/174-05-T1-RED.{tap,json}` and `174-05-T2-RED.{tap,json}`.

## Verification

- Focused FailedSyncLive, recovery journey, and operator contract tests: **26 tests, 0 failures**.
- Ops `mix precommit`: **2 doctests, 268 tests, 0 failures**; Nav contract passed. The build still emits the known `Scrypath.Sync.sync_related/3` compiler warning; this run was not a Dialyzer check.
- `mix assets.build`: passed; generated CSS matches the edited source asset.
- `make contrast`: passed with **0 AA failures** and **35 AAA advisory pairs**.

Behavioral tests explicitly cover equal-ID Backend task 501 / Queue job 501, rejection of the wrong-source token and bare numeric ID, stale allowlist selection, duplicate acceptance, receipt binding to the queue row, and delete confirmation with exact schema, index, document count, and every document ID. The discarded queue-job delete fixture still reaches the existing confirmation path when its replay payload is present.

The accepted static references are `.planning/phases/174-recovery-entry-and-diagnosis/174-failed-work-light-1440.png`, `174-failed-work-light-390.png`, and `174-comp-evidence.json`. They provide design direction and static geometry evidence only. This plan did not capture or claim runtime browser layout; mounted/standalone responsive browser evidence remains with plan 08.

## Decisions Made

- Client action values are opaque candidates only. Every retry and delete-confirmation lookup must match the current selected schema, source, full ID, and inspection before existing authorization and recovery gates run.
- Manual replay availability follows actual recovery data, not Oban's automatic retry badge/state. The visible explanation keeps existing host and server gates explicit.
- `OPUX-18` and `OPUX-19` remain pending: the readiness query returned **0/2 ready** while dependent plan 08 browser proof remains outstanding. All four Phase 174 OPUX requirements therefore remain pending.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Correctness] Removed the remaining numeric-ID retry fallback**
- **Found during:** Task 2 integration verification
- **Issue:** The fallback enumerated rows by numeric ID alone, so it did not honor the plan's exact source-qualified client-key contract.
- **Fix:** Retry now accepts only the rendered opaque `phx-value-id`; stale events still fail through the existing generation and live-allowlist guards. Updated the journey and static source-contract tests to use the rendered key and source-specific wording.
- **Files modified:** `failed_sync_live.ex`, `failed_sync_live_test.exs`, `recovery_journey_live_test.exs`, `operator_ia_contract_test.exs`
- **Verification:** Focused cross-surface run 26/26 and full Ops precommit 270/270 (including doctests).
- **Committed in:** `d26df4a`

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** This closes an existing path that would have bypassed the newly required source-qualified identity; public IDs and recovery contracts remain unchanged.

## Issues Encountered

- The clone has no `.tool-versions` file, so the asdf shims did not select Elixir/OTP even when the documented version variables were set. Using the already installed Elixir 1.19.5 and Erlang 28.4.1 binaries directly allowed formatting, asset build, and test commands to run; no dependency installation was needed.
- Initial adjacent tests contained old retry copy, payload, and receipt-key assumptions. They were updated to assert the current rendered identity and accepted/non-terminal receipt; the full suite then passed.

## User Setup Required

None.

## Next Phase Readiness

Plan 05 implementation and executable checks are complete. Continue the authorized Phase 174 sequence with the remaining dependent plans; keep OPUX-18/19 pending until the plan 08 runtime evidence is ready. Do not treat the static comps as runtime visual approval.

## TDD Gate Compliance

- **Task 1 RED:** `174-05-T1-RED.tap` records the focused equal-ID identity test failing against the old DOM key; classifier result `RED_EVIDENCE_OK`. Test/evidence-only commit: `3758692`.
- **Task 1 GREEN:** The focused source-qualified identity suite passed before implementation commit `881147d`.
- **Task 2 RED:** `174-05-T2-RED.tap` records one focused rendered-row diagnosis test failing because selected schema and source/index/recovery facts were absent before Diagnostics; classifier result `RED_EVIDENCE_OK`. Test/evidence-only commit: `bf7e318`.
- **Task 2 GREEN:** Focused and full Ops verification passed before implementation commit `d26df4a`.

## Self-Check: PASSED

- Summary file exists at the required phase path.
- All four task commits (`3758692`, `881147d`, `bf7e318`, `d26df4a`) are ancestors of the current plan HEAD.
- The persisted plan ledger measures four task commits from `ee7e4e4f638e65479a368352aec42f79b59afa2c` to `d26df4a61809af81aa80715bed152610fa204cdd`.

---
*Phase: 174-recovery-entry-and-diagnosis*
*Completed: 2026-10-07*
