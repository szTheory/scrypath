---
phase: 163-findings-and-bounded-follow-up
plan: "01"
subsystem: evidence-validation
tags: [python, unittest, findings, evidence, provenance]

requires:
  - phase: 162-whole-product-evidence-baseline
    provides: Canonical claim-level evidence baseline and checker
provides:
  - Claim-linked triage for C-15, C-16, C-17, and C-21
  - Standard-library checker with selected, staged, and complete validation modes
  - Exact-SHA reconciliation of Mint advisory remediation and mounted cutover evidence
affects: [163-02, 163-03, 164-readiness-gate]

actuals:
  tokens: 12364
  tasks: 2
  commits: 7
  plan_head_before: 5f993bc9167b91f4c4dc33e478e999de7ee2a827

tech-stack:
  added: [Python standard library]
  patterns: [Data-only Markdown contract validation, claim/card cross-reference checks, explicit partial-versus-complete checker output]

key-files:
  created:
    - .planning/phases/163-findings-and-bounded-follow-up/163-FINDINGS.md
    - .planning/phases/163-findings-and-bounded-follow-up/check_findings.py
    - .planning/phases/163-findings-and-bounded-follow-up/test_check_findings.py
  modified:
    - .planning/phases/162-whole-product-evidence-baseline/162-BASELINE.md

key-decisions:
  - "Treat C-21 as a reconciled evidence gap: the named Mint advisories were cleared on the recorded Phase 161 graph, without claiming a current broad audit or host security certification."
  - "Use exact candidate run 36080380783 for C-17 after checking its source SHA, mounted job, selected test, seed, oracle, and environment; run 36082426093 corroborates the same path."
  - "Keep C-15 diagnosis/retry interaction distinct from C-16 successful repair; no decision-changing repair-to-visible-search scenario or new candidate is established."

requirements-completed: [FIND-01, FIND-03]

coverage:
  - id: D1
    description: "A standard-library checker validates claim rows, local links, connected finding/candidate/proof cards, dispositions, and partial versus complete scope."
    requirement: FIND-01
    verification:
      - kind: unit
        ref: .planning/phases/163-findings-and-bounded-follow-up/test_check_findings.py#FindingsContractTests
        status: pass
      - kind: other
        ref: "python3 .planning/phases/163-findings-and-bounded-follow-up/check_findings.py --claims C-15,C-16,C-17,C-21 --stage triage"
        status: pass
    human_judgment: false
  - id: D2
    description: "C-21 links the earlier Mint 1.9.3 advisories to the bounded Mint 1.10.1 remediation and audit record, with current-graph limits retained."
    requirement: FIND-01
    verification:
      - kind: other
        ref: "Phase 161 161-02-SUMMARY.md; run 36082426093 deep-quality result; python3 .planning/phases/162-whole-product-evidence-baseline/check_baseline.py --through 24 --full-coverage"
        status: pass
    human_judgment: false
  - id: D3
    description: "C-15 diagnosis, C-16 repair, and C-17 cutover evidence have distinct boundaries; the exact candidate run proves only the seeded C-17 happy path."
    requirement: FIND-03
    verification:
      - kind: other
        ref: "run 36080380783 exact head 4f020835deaaef2d3fbe5ff237f25511fa629c8d; ecommerce-mounted test e2e/operator.spec.ts:60; corroborating run 36082426093"
        status: pass
      - kind: other
        ref: "python3 .planning/phases/163-findings-and-bounded-follow-up/check_findings.py --claims C-15,C-16,C-17,C-21 --stage triage"
        status: pass
    human_judgment: false

duration: 40min
completed: 2026-09-25
status: complete
---

# Phase 163 Plan 01: Findings and Bounded Follow-up Summary

**Claim-linked triage reconciles the Mint advisory chronology, bounds operator recovery evidence, and provides a tested structural checker without treating missing proof as a defect.**

## Performance

- **Duration:** 40 min (approximate; execution began after the STATE timestamp below)
- **Started:** 2026-09-25T21:05:05Z (approximate, earliest recorded context)
- **Completed:** 2026-09-25T21:44:52Z
- **Tasks:** 2
- **Files modified:** 4 plan artifacts

## Accomplishments

- Added a standard-library checker for the claim table, safe local links, card relationships, rank/disposition rules, proof oracles, and complete inventory/handoff contracts. Subset and early-stage output is explicitly `PARTIAL`; complete mode rejects an incomplete baseline inventory.
- Reconciled C-21's Phase 160 Mint 1.9.3 findings with Phase 161's Mint 1.10.1/hpax 1.1.0 resolution, recorded clean named-advisory audit, and later exact-SHA deep-quality result. The disposition does not claim a current full dependency audit or deployment certification.
- Separated C-15's seeded diagnosis/retry interaction from C-16's unproven repair-to-visible-search outcome. For C-17, run 36080380783 is confirmed on exact candidate SHA `4f020835deaaef2d3fbe5ff237f25511fa629c8d`; its mounted log shows the seeded zero-downtime swap test passed, and run 36082426093 corroborates the same scenario on a later SHA. Rollback and failure handling remain untested.
- Preserved the baseline's 19-column structure and passed its full 24-claim coverage check. No finding or follow-up candidate was created from an evidence gap alone.

## Task Commits

1. **Task 1: Trace C-21 and build the findings checker** — `ec1a633` (RED fixtures), `0daf032` (checker and C-21 reconciliation), `4825b28` (row-order fixture), `2295018` and `ce43759` (full relationship and mode contracts)
2. **Task 2: Reconcile C-15–C-17 operational evidence** — `ffa71d6` (triage boundaries and C-17 receipt), `f8a22d2` (exact candidate run confirmation)

Plan commits were measured from `plan_head_before` and include all seven task-related commits above. The SUMMARY commit is separate.

## Files Created/Modified

- `.planning/phases/163-findings-and-bounded-follow-up/163-FINDINGS.md` — claim-linked triage, evidence boundaries, chronology, and phase handoff context.
- `.planning/phases/163-findings-and-bounded-follow-up/check_findings.py` — data-only structural validator with exact C-ID selection and explicit stages.
- `.planning/phases/163-findings-and-bounded-follow-up/test_check_findings.py` — 12 positive and adversarial standard-library fixtures.
- `.planning/phases/162-whole-product-evidence-baseline/162-BASELINE.md` — source-supported updates for C-15, C-17, and C-21 only.

## Decisions Made

- C-21 is a reconciled named-advisory evidence gap, not a new material finding. Revisit on a new Mint advisory, lock/resolver or audit-workflow change, or concrete host deployment report.
- C-17 is supported only for the named seeded happy-path swap with terminal success and a tenant-filtered visible search hit. The earlier Phase 160 opt-out remains historically accurate; later Phase 161 coverage fills that bounded gap.
- C-15 and C-16 remain nonqualifying without a decision-changing real incident or adopter case. Retry interaction and report/action unit contracts do not establish successful repair or visible recovery.
- Requirements FIND-01 and FIND-03 remain open at the milestone level while Plans 163-02 and 163-03 remain. This executor did not update REQUIREMENTS.md, STATE.md, or ROADMAP.md.

## Deviations from Plan

None — plan executed as written. The originally suggested exact candidate run was verified against its source and mounted log, and the corroborating later run was also inspected.

## Issues Encountered

- The GitHub CLI's default run-log cache path was not writable in this environment. Read-only log retrieval succeeded with `XDG_CACHE_HOME=/tmp`.
- The default full-inventory command correctly rejected the current four-claim slice because the canonical baseline contains 24 claims; partial validation is the expected state until later phase plans finish.

## User Setup Required

None — no external service configuration is required.

## Next Phase Readiness

Ready for Plan 163-02 to continue whole-inventory triage. C-16's concrete repair-to-visible-search proof gap and C-17's untested rollback/failure boundary remain visible for qualification. Phase 164 retains ownership of the six-condition readiness gate.

---
*Phase: 163-findings-and-bounded-follow-up*
*Completed: 2026-09-25*

## Self-Check: PASSED

- Created artifacts exist, the seven task commits resolve, and plan-scoped commits are present.
- The 12-test suite, C-21 and four-claim partial checks, and 24-claim baseline check pass.
- Full mode rejects the intentionally partial four-claim inventory; no task verification remains unrun.
