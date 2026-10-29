---
phase: 184-explicit-and-lean-dependency-graphs
plan: "04"
subsystem: security
tags: ["Elixir", "Sigra", "Phoenix LiveView", "optional dependency", "authorization"]
requires:
  - phase: "184-03"
    provides:
      - "Optional Sigra integration and compile-time module-gating baseline"
provides:
  - "Optional Sigra ~> 1.5 dependency with capability-aware startup validation"
  - "Fail-closed Sigra-mode gating for sensitive Ops actions"
affects: ["184-06", "184-07", "184-09", "184-10", "ScrypathOps"]
actuals:
  tokens: 5621
  tasks: 2
  commits: 4
  plan_head_before: "c9912a50813ba38243b622e36800a2d5fb8433dd"
  plan_head_after: "da4a5b89bfde1846c14722d008d9cc74a953ae99"
tech-stack:
  added: []
  patterns:
    - "Validate explicitly requested optional integrations against the runtime modules and functions the integration uses."
    - "Gate sensitive callbacks by selected auth mode and a typed identity with a valid, fresh sudo timestamp."
key-files:
  created:
    - "scrypath_ops/lib/scrypath_ops/integrations/sigra/capability.ex"
  modified:
    - "scrypath_ops/mix.exs"
    - "scrypath_ops/lib/scrypath_ops/security.ex"
    - "scrypath_ops/test/scrypath_ops/security_validation_test.exs"
    - "scrypath_ops/test/scrypath_ops/security_test.exs"
    - "scrypath_ops/lib/scrypath_ops/integrations/sigra/gating.ex"
    - "scrypath_ops/test/scrypath_ops/integrations/sigra/gating_test.exs"
    - "scrypath_ops/test/scrypath_ops/integrations/sigra/on_mount_test.exs"
    - "scrypath_ops/test/scrypath_ops_web/live/search_saved_searches_test.exs"
key-decisions:
  - "Keep Sigra optional at ~> 1.5 and validate both integration capability and the local sudo confirmation path before Ops startup."
  - "In requested Sigra mode, sensitive callbacks require complete operator identity and fresh sudo; basic and proxy modes retain host-owned authentication behavior."
requirements-completed: ["DEP-06"]
coverage:
  - id: D1
    description: "Ops accepts the approved optional Sigra 1.x range and validates loaded integration capability plus a local sudo confirmation path."
    requirement: "DEP-06"
    verification:
      - kind: integration
        ref: "mix verify.ops_ui (316 Ops tests; Sigra 1.5.0 on Elixir 1.19.5 / OTP 28.4.1)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Sigra-mode sensitive actions fail closed for missing or malformed identity, impersonation, and invalid, future, or stale sudo context while preserving valid audit identity."
    requirement: "DEP-06"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops/integrations/sigra/gating_test.exs and on_mount_test.exs via mix verify.ops_ui"
        status: pass
    human_judgment: false
duration: "1h 12m"
completed: "2026-10-29"
status: complete
---

# Phase 184 Plan 04: Explicit and Lean Dependency Graphs Summary

**ScrypathOps now uses the optional Sigra ~> 1.5 line with capability-aware startup checks and identity-plus-sudo gating for sensitive actions.**

## Performance

- **Duration:** 1h 12m
- **Started:** 2026-10-29T21:55:04Z
- **Completed:** 2026-10-29T23:07:32Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Changed the Ops dependency declaration to `{:sigra, "~> 1.5", optional: true}`; the current Ops lock resolved Sigra 1.5.0 without a lockfile update on Elixir 1.19.5 / OTP 28.4.1. The root library's Elixir `~> 1.17` floor remains in force.
- Added `Security.auth_mode/0` and `sigra_available?/0`; requested Sigra mode now checks Session, Audit, OnMount, and OperatorContext capabilities before accepting a local sudo confirmation path. Startup validation still runs before the supervisor starts.
- Made the sensitive-action gate total for requested Sigra mode: malformed or absent identity, missing actor/organization, impersonation, invalid/future sudo timestamps, and stale sudo cannot invoke the callback. Valid fresh context passes its actor, organization, impersonator, and sudo values through the shared audit-argument path.

## Task Commits

Each task followed RED then GREEN:

1. **Task 1 RED: Validate exact optional Sigra capability** — `37ce82b7` (`test(184-04): add failing Sigra validation tests`)
2. **Task 1 GREEN: Validate exact optional Sigra capability** — `59fe9b9e` (`feat(184-04): validate optional Sigra capability`)
3. **Task 2 RED: Make sensitive actions total and fail closed** — `15ee4890` (`test(184-04): add fail-closed Sigra gating tests`)
4. **Task 2 GREEN: Make sensitive actions total and fail closed** — `da4a5b89` (`feat(184-04): fail closed sensitive Sigra actions`)

## TDD Gate Compliance

- Task 1 RED evidence was accepted by the GSD classifier as `RED_EVIDENCE_OK`; the named path-validation assertion failed against the prior implementation. The receipt is at `/private/tmp/scrypath-phase184-04/task1-red-record.json`.
- Task 2 RED evidence was accepted as `RED_EVIDENCE_OK`; the named nil-context assertion failed because the prior gate invoked the callback. The receipt is at `/private/tmp/scrypath-phase184-04/task2-red-record.json`.
- Both RED commits precede their corresponding GREEN commits. No refactor commit was needed.

## Verification

- From the repository root: `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 HEX_HOME=/private/tmp/scrypath-phase184-04/hex ELIXIR_ERL_OPTIONS='+S 4:4' SCRYPATH_OPS_TEST_DATABASE=scrypath_ops_plan18404_test mix verify.ops_ui` — **PASS**, 316 tests, 0 failures. Sigra resolved to the existing locked 1.5.0 release.
- From `scrypath_ops/`: `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 HEX_HOME=/private/tmp/scrypath-phase184-04/hex ELIXIR_ERL_OPTIONS='+S 4:4' mix format --check-formatted` — **PASS**.
- Focused Sigra Gating and OnMount suite — **PASS**, 10 tests, 0 failures.
- Runtime module-absence proof remains with plan 184-06, as specified; this plan verified the Sigra-present tuple and implemented the unavailable-capability startup failure.

## Files Created/Modified

- `scrypath_ops/mix.exs` — widened the optional Sigra requirement to `~> 1.5`.
- `scrypath_ops/lib/scrypath_ops/security.ex` — shared mode selection, integration capability checks, and local confirmation-path validation.
- `scrypath_ops/test/scrypath_ops/security_validation_test.exs` — mode and path validation cases.
- `scrypath_ops/test/scrypath_ops/security_test.exs` — updated expectations for the actionable support references.
- `scrypath_ops/lib/scrypath_ops/integrations/sigra/gating.ex` — mode-specific callback gate, identity/sudo checks, and audit arguments.
- `scrypath_ops/test/scrypath_ops/integrations/sigra/gating_test.exs` — action matrix, context, sudo-window, redirect, host-mode, and audit argument coverage.
- `scrypath_ops/test/scrypath_ops/integrations/sigra/on_mount_test.exs` — route continuation and identity-to-gate coverage.
- `scrypath_ops/test/scrypath_ops_web/live/search_saved_searches_test.exs` — UI behavior fixture uses basic mode because its test router does not install the host Sigra OnMount context.

## Decisions Made

- Keep Sigra optional and validate the integration pieces actually used by Ops; do not equate dependency presence with authentication.
- Require a complete `OperatorContext`, nonempty actor and organization identifiers, no impersonator, and a valid nonfuture sudo timestamp before running a sensitive callback.
- Keep host authentication responsibility in basic and proxy modes; the Sigra selector does not authenticate routes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Align the saved-search UI fixture with its host-owned authentication setup**

- **Found during:** Task 2 verification.
- **Issue:** The existing saved-search UI test requested Sigra without the Sigra OnMount context; the new fail-closed gate correctly blocked its delete callback.
- **Fix:** Set that UI-only test fixture to basic mode. Sigra identity and callback behavior remain covered by the dedicated Gating and OnMount suites.
- **Files modified:** `scrypath_ops/test/scrypath_ops_web/live/search_saved_searches_test.exs`.
- **Verification:** Canonical `mix verify.ops_ui` passed with 316 tests and 0 failures.
- **Committed in:** `da4a5b89`.

**Total deviations:** 1 auto-fixed (1 task-caused test-fixture correction). **Impact:** The saved-search test exercises its intended UI flow under the authentication mode its test router provides.

## Issues Encountered

The first broad denial assertion required the word “Sigra” in every flash message, but the intended impersonation denial has a specific message. The matcher now checks for nonempty denial feedback, while the impersonation-specific test verifies its exact message.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plans 184-06 and 184-07 can continue with unavailable-dependency proof and final dependency metadata/lock checks.
- Shared requirement DEP-06 is also declared by plans 184-06, 184-07, 184-09, and 184-10. The readiness query reported it blocked, so its global completion marker remains for the phase/orchestrator to resolve after those plans produce summaries.

## Self-Check: PASSED

- All eight modified source/test files exist.
- All four task commits are ancestors of the plan worktree HEAD.
- Evaluation scope resolved four commits for plan 184-04.
- Acceptance criteria and final Ops verification passed; formatting check passed.


## Post-merge integration repair — 2026-10-29

The first root wave gate failed the namespace-fence canary: direct external Sigra module references in `ScrypathOps.Security` crossed the existing integration boundary. The orchestrator moved the same capability predicate and unavailable message into the always-defined `ScrypathOps.Integrations.Sigra` module in `integrations/sigra/capability.ex`; Security delegates through its integration alias. The namespace allowlist was preserved.

Fresh checks after this repair: namespace-fence tests **3 tests, 0 failures**; formatting of both changed source files passed; an isolated Elixir process with no dependency code paths rejected explicit Sigra and accepted basic/proxy modes; the root warning-as-error compile and fast suite passed **1005 tests plus 5 properties, 0 failures**. Tuple: Elixir 1.19.5 / OTP 28.5. Runtime receipts remain outside the checkout at `/private/tmp/scrypath-phase184-execution/wave5-capability-absence.log` and `wave5-merged-tests-repaired.log`. The original failure remains in `wave5-merged-tests.log`; no failed result was relabeled. Broader with/without dependency consumers and final-lock acceptance remain owned by plans 184-06/07/10.
