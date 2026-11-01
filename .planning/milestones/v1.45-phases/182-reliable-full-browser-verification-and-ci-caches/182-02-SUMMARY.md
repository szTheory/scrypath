---
phase: 182-reliable-full-browser-verification-and-ci-caches
plan: "02"
subsystem: testing
tags: [playwright, docker-compose, node-test, exunit]

requires:
  - phase: 182-01
    provides:
      - "Isolated full-stack E2E readiness and owned Compose lifecycle cleanup."
provides:
  - "A hostname-aware Playwright target guard that permits Docker web:4002 and refuses the retained loopback preview before mutations."
  - "Counted lifecycle and target behavior checks in the existing repository-contract test lane."
  - "A failed-sync screenshot assertion aligned with the current unknown_backend decoder error and failed row state."
affects: [182-03, 182-04, 182-08, ecommerce-e2e-verification]

actuals:
  tokens: 2247
  tasks: 2
  commits: 3
plan_head_before: 1eec7e22acf5551eab6e3b4e12e5024df043c238
plan_head_after: 161c7cf40d2d892fff1fdb53b4a4edf18ddf371b

tech-stack:
  added: []
  patterns:
    - "Resolve browser target eligibility by URL hostname and port, then guard setup mutations before they run."
    - "Run Node behavior suites from ExUnit and require TAP to report a nonzero test count and zero failures."

key-files:
  created:
    - examples/scrypath_ecommerce/e2e/helpers/verification-target.mjs
    - scripts/ci/ecommerce_target.test.cjs
  modified:
    - examples/scrypath_ecommerce/e2e/ui_followup.spec.ts
    - examples/scrypath_ecommerce/e2e/ui_iteration3.spec.ts
    - examples/scrypath_ecommerce/e2e/admin_screenshots.spec.ts
    - test/mix/tasks/workflow_wiring_test.exs

key-decisions:
  - "Use URL hostname and port semantics so Docker web:4002 is allowed while localhost and 127.0.0.1 on port 4002 remain refused; preserve explicitly isolated local port 4014."
  - "Keep full rendered-browser and hosted exact-source acceptance for the later phase plan that owns those checks."

requirements-completed: []

coverage:
  - id: D1
    description: "One tested target guard permits Docker and isolated local hosts, refuses the retained preview, and refuses before a mutating callback."
    verification:
      - kind: unit
        ref: "scripts/ci/ecommerce_target.test.cjs#verification target accepts Docker and explicitly isolated local hosts"
        status: pass
      - kind: unit
        ref: "scripts/ci/ecommerce_target.test.cjs#verification target refuses the retained preview and missing or malformed URLs"
        status: pass
      - kind: unit
        ref: "scripts/ci/ecommerce_target.test.cjs#verification target refusal callback runs before any guarded mutation"
        status: pass
      - kind: other
        ref: "Disposable Compose Playwright discovery: 13 tests across ui_followup.spec.ts and ui_iteration3.spec.ts, Chromium, one worker, zero retries"
        status: pass
    human_judgment: false
  - id: D2
    description: "The required repository-contract lane runs both Node behavior suites and rejects zero-test or nonzero child results."
    verification:
      - kind: unit
        ref: "test/mix/tasks/workflow_wiring_test.exs#repository contracts execute counted browser lifecycle and target behavior tests"
        status: pass
      - kind: integration
        ref: "MIX_ENV=test mix verify.repository_contracts"
        status: pass
      - kind: integration
        ref: "MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/mix/tasks/workflow_wiring_test.exs test/mix/tasks/verify_capability_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "The admin screenshot scenario now asserts the unknown_backend error and failed row state while preserving its historical capture path."
    verification:
      - kind: e2e
        ref: "examples/scrypath_ecommerce/e2e/admin_screenshots.spec.ts#captures canonical ScrypathOps admin UI states"
        status: unknown
    human_judgment: true
    rationale: "The admin screenshot browser journey was not run in this plan. Plan 182-08 owns the full rendered-browser acceptance needed to confirm the live row."

duration: 14min
completed: 2026-10-27
status: complete
---

# Phase 182 Plan 02: Safe Browser Verification Targets Summary

**Hostname-aware Playwright targets, truthful failed-sync assertions, and counted lifecycle and guard tests in the required repository-contract lane**

## Performance

- **Duration:** 14 min
- **Started:** 2026-10-26T23:52:17Z
- **Completed:** 2026-10-27T00:06:47Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added a shared hostname-aware URL guard: Docker `web:4002` and an explicitly isolated local port are eligible; retained `localhost:4002` and `127.0.0.1:4002` are refused before fixture mutation or directory creation.
- Wired both browser suites to the same guard and kept the intended case selection. Disposable Playwright discovery found 13 Chromium cases across the two suites with one worker and zero retries; this was discovery evidence, not a browser acceptance run.
- Updated the admin screenshot assertion to require the `failed` row state and current `unknown_backend` decoder reason, retaining the existing expanded-row capture.
- Added an ExUnit bridge that runs the lifecycle and target Node suites, requires a nonzero TAP test count and zero failures, and propagates child failure through `mix verify.repository_contracts`.

## Task Commits

1. **Task 1 RED:** `1aa1273b` — `test(182-02): add safe verification target behavior tests`
2. **Task 1 GREEN:** `59fa9d91` — `feat(182-02): allow safe docker browser targets`
3. **Task 2:** `161c7cf4` — `test(182-02): correct backend expectation and wire behavior checks`

**Plan metadata:** recorded after summary self-check.

## Files Created/Modified

- `examples/scrypath_ecommerce/e2e/helpers/verification-target.mjs` — shared host/port refusal rule and pre-mutation guard.
- `examples/scrypath_ecommerce/e2e/ui_followup.spec.ts` — uses the shared guard before fixture setup.
- `examples/scrypath_ecommerce/e2e/ui_iteration3.spec.ts` — uses the shared guard before directory creation and fixture setup.
- `scripts/ci/ecommerce_target.test.cjs` — guard truth table, refusal ordering, and suite wiring checks.
- `examples/scrypath_ecommerce/e2e/admin_screenshots.spec.ts` — asserts the decoded backend tag and failed state without changing captures.
- `test/mix/tasks/workflow_wiring_test.exs` — runs both Node behavior suites and rejects zero-count or failing results.

## Decisions Made

- URL hostname plus port is the target identity. It permits Docker web:4002 without opening the retained loopback preview.
- Full browser execution and hosted exact-source acceptance remain owned by later Phase 182 work; discovery and synthetic checks are not presented as those proofs.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first Mix dependency fetch could not write Hex default user cache (`:eaccess`). Fetching the existing locked dependencies with `HEX_HOME=/private/tmp/scrypath-phase182-02-hex` succeeded; no dependency or lockfile changes were made.
- Local Playwright discovery could not write the user's npm cache. Discovery then passed in the repository disposable E2E image. No retained preview, application services, or retained Docker data were touched.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 182-03 can build on the guard and required test wiring. BROW-02 remains open until the complete intended browser cases are executed and reconciled; BROW-03 remains open until the required exact-source hosted full-browser evidence is available. No hosted acceptance is claimed here.

## Self-Check: PASSED

- All six task files exist, and the three task commits are ancestors of the current plan head.
- `gsd_run check evaluation-scope --plan "182-02" --commits-only --raw` resolved all three commits on this branch.
- Coverage metadata classifies all deliverables; the unrun admin browser journey is explicitly marked unknown and reserved for plan 182-08.

---
*Phase: 182-reliable-full-browser-verification-and-ci-caches*
*Completed: 2026-10-27*
