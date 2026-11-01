---
phase: 185-executable-ui-quality-foundations
plan: "08"
subsystem: ui-testing
tags: [playwright, ui-evidence, exact-pixels, source-pairing]

requires:
  - phase: 185-05
    provides:
      - Qualified browser image and entry-state capture recipe for the pre-UI source.
provides:
  - Strict full-run validator contract for 61 exact held-out UI state identities and their same-source evidence artifacts.
  - Source-pair comparator that checks independent source, fixture, runtime, recipe, image, geometry, copy, and assertion identities.
affects: [185-09, ui-preservation-evidence]

actuals:
  tokens: 16227
  tasks: 0
  commits: 5
plan_head_before: 19e26118a59ceb3217e052458ab2e6ebd5f7aedf
plan_head_after: 56acda005d56a35a158e29bf7d8dddf061018daf

tech-stack:
  added: []
  patterns:
    - Contract tests use synthetic fixtures only to test evidence validation; they do not count as product receipts.
    - Paired image comparison recomputes both validated bundles against independently supplied source authority.

key-files:
  created:
    - scripts/ci/ui_state_pairs.cjs
    - scripts/ci/ui_state_pairs.test.cjs
  modified:
    - scripts/ci/ecommerce_evidence.cjs
    - scripts/ci/ecommerce_evidence.test.cjs

key-decisions:
  - "Keep ordinary same-source receipt validation separate from historical before-source comparison."
  - "Treat synthetic unit fixtures as validator tests only; missing browser executions remain blocking evidence gaps."
  - "Do not represent the shared health fixture screen as proof of storefront, Control Room, search, or settings behavior."

requirements-completed: []
requirements-declared: ["UIF-02", "UIF-03"]

coverage:
  - id: D1
    description: "The full-run evidence contract rejects incomplete, duplicate, relocated, or tampered 61-case same-source receipt claims."
    verification:
      - kind: unit
        ref: scripts/ci/ecommerce_evidence.test.cjs#full inventory requires the exact held-out preservation case identities
        status: pass
      - kind: unit
        ref: scripts/ci/ecommerce_evidence.test.cjs#held-out receipts bind source, fixture, runtime, recipe, state, transport and measured geometry
        status: pass
    human_judgment: false
  - id: D2
    description: "The source-pair comparator's unit-tested contract requires complete, exact 61-case bundles and exact pixel, state, geometry, copy, and assertion matches."
    verification:
      - kind: unit
        ref: scripts/ci/ui_state_pairs.test.cjs#source-paired comparator requires exact matched state receipt pairs
        status: pass
      - kind: unit
        ref: scripts/ci/ui_state_pairs.test.cjs#pair output is atomic, deterministic and never overwritten by different bytes
        status: pass
    human_judgment: false
  - id: D3
    description: "Actual held-out product-state executions and pre-UI source-paired before receipts for all 61 obligations."
    verification:
      - kind: e2e
        ref: "mix verify.ecommerce_e2e (900-second bound; timed out with strict aggregation failure and missing held-out cases/artifacts)"
        status: fail
      - kind: e2e
        ref: "Playwright list: e2e/ui_state_preservation.spec.ts and e2e/ui_content_preservation.spec.ts (both report no tests found)"
        status: fail
    human_judgment: true
    rationale: "The missing evidence is an automated implementation and execution gap. Human visual critique cannot substitute for the required held-out assertions or actual source-paired receipts; verification must keep this deliverable blocked."

duration: "At least 23 min from the first task commit through the final verifier result; earlier inspection and RED work were not timed."
completed: 2026-10-31
status: halted
---

# Phase 185 Plan 08: Held-Out UI Evidence Contracts Summary

**The 61-case receipt validator and exact source-pair comparator are implemented and unit-tested, but the held-out product tests and actual before receipts were not produced.**

## Performance

- **Duration:** At least 23 min from first task commit through the final verifier result; earlier inspection and RED work were not timed.
- **Started:** 2026-10-31T20:13:18-04:00 (first task commit; inspection preceded it)
- **Completed:** 2026-11-01T00:36:04Z
- **Tasks:** 0/3 met their complete plan acceptance criteria; implementation portions for Tasks 02 and 03 were committed.
- **Files modified:** 4

## Accomplishments

- The ordinary run validator now requires each canonical held-out identity exactly once and validates per-case state, assertions, exact visible copy, image bytes, and separate product, fixture, runtime, and recipe identities.
- The independent comparator validates both receipt bundles against supplied authority, compares exact decoded PNG pixels and all matched state evidence, and writes deterministic output without overwriting a differing prior result.
- Unit suites cover missing, duplicate, relocated, and tampered cases and artifacts, plus source, fixture, runtime, recipe, pixels, geometry, copy, output, and authority mismatches.

These are code-contract results only. Unit tests use synthetic receipts and do not establish that any product route was exercised or that a real paired comparison passed.

## Task Commits

1. **Task 02 RED:** `58e859cf` — require complete held-out preservation receipts.
2. **Task 02 implementation:** `c88578af` — enforce held-out UI evidence receipts.
3. **Task 03 RED:** `d0167af7` — require exact held-out source pairs.
4. **Task 03 implementation:** `56acda00` — compare source-paired UI state receipts.
5. **Task 03 correction:** `10c9138e` — revalidate historical source-paired receipts.

The five task commits are measured from `plan_head_before` through `plan_head_after`; the plan-summary commit follows this summary.

## Files Created/Modified

- `scripts/ci/ecommerce_evidence.cjs` — requires the 61 exact case identities and validates actual per-case state, assertion, copy, image, and source-bound evidence.
- `scripts/ci/ecommerce_evidence.test.cjs` — exercises the contract with synthetic fixtures and tampering cases.
- `scripts/ci/ui_state_pairs.cjs` — independently validates and exactly compares two source-pinned receipt bundles.
- `scripts/ci/ui_state_pairs.test.cjs` — checks comparator and output behavior with synthetic bundles.

No E2E specs, fixture helper, or fixture-source extensions were created.

## Decisions Made

- Kept same-source validation independent from the historical source-pair comparator so ordinary E2E runs do not depend on the old baseline.
- Preserved the boundary between test-only health fixtures and actual storefront, Control Room, search, settings, saved-search, navigation, and shared-control behavior.
- Marked no requirements complete because the actual required product tests and receipts remain missing; the plan declares UIF-02 and UIF-03.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Revalidate historical source-paired receipts against independent source expectations**

- **Found during:** Task 03.
- **Issue:** A historical receipt must be verifiable after the current checkout's product source has advanced; validating only against the current source would either reject a legitimate archived source or trust its self-declared identity.
- **Fix:** Added an independent expected-source input and recompute the archived bundle against that authority before comparing it.
- **Files modified:** `scripts/ci/ecommerce_evidence.cjs`, `scripts/ci/ecommerce_evidence.test.cjs`.
- **Verification:** `node --test scripts/ci/ecommerce_evidence.test.cjs` passed; commit `10c9138e`.

**Total deviations:** 1 auto-fixed (Rule 1).
**Impact:** The fix closes a source-verification gap in the planned comparator; no package, production UI behavior, or aesthetic approval was added.

## Issues Encountered

- The named state and content Playwright specs are absent. Both `npm --prefix examples/scrypath_ecommerce run test:e2e:list -- e2e/ui_state_preservation.spec.ts` and the equivalent `ui_content_preservation.spec.ts` command exited 1 with “No tests found” and zero discovered tests.
- The preparation map states that the existing Phase173 fixture source provides health observations rendered on the test-only Posture screen. The shared fixture LiveView does not exercise the actual storefront, Control Room, search, settings, saved-search, Help, navigation, or shared-control routes, and those routes do not have the listed held-out tests or per-case browser receipt emitter. Treating the component/health fixture screen as product-state evidence would violate the plan's trust boundary.
- The plan's bounded `mix verify.ecommerce_e2e` command was attempted with the prescribed toolchain. The initial sandboxed attempt could not write Docker Buildx activity state; the isolated verifier cleaned up. The same command was retried with host permission. It reached strict full-run aggregation but exceeded the 900-second command bound (exit 124); aggregation reported the held-out cases and required evidence artifacts missing (strict aggregate exit 78). A read-only check found no leftover containers for the timed-out verifier project. No actual held-out receipts were produced, and the command was not retried.
- Plan05 qualification identifies the pre-UI source as `7886eb10449dcb55945d1ab886e6c78752cc73cf` and the qualified browser image as `sha256:8be4cc26927d7c2520ebc6708ec6f5e1ee0789a1750b2513ca02ff6c4fa66272` in `/private/tmp/scrypath-phase185-execution/185-05-qualification.json`. This qualifies the capture environment, not held-out states. No Plan08 fixture-overlay digest, effective runtime digest, per-case before bundle, or before/after pair exists.
- The evidence contract suite passed 31/31 tests; the comparator syntax check passed and its suite passed 9/9 tests. These synthetic unit results do not replace the failed E2E acceptance criteria.

## User Setup Required

None.

## Next Phase Readiness

**Plan 185-08 is halted and its declared UIF requirements remain incomplete.** The parent/orchestrator should keep the existing stop on Plans 06/07 source changes until real before-side held-out receipts are generated. The next executor needs to implement the test-only route/data support and named Playwright specs within the plan's declared files, run all 61 actual cases in a disposable source-pinned baseline stack with a committed harness overlay, and record its product, overlay, runtime, browser-recipe, and per-case artifact identities. Plan09 can then provide the integrated candidate bundle and invoke the comparator. Do not use the retained preview or parent-owned capture session.

## Self-Check: PASSED

All four listed files exist; all five listed task commits were verified as ancestors of `plan_head_after`; and the worktree was clean before this summary was written. This checks summary consistency only and does not indicate that the plan's held-out acceptance criteria passed.

---
*Phase: 185-executable-ui-quality-foundations*
*Completed: 2026-10-31 (halted with held-out evidence incomplete)*
