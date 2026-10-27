---
phase: 182-reliable-full-browser-verification-and-ci-caches
plan: "08"
subsystem: ci
tags: [github-actions, docker-buildx, beam-cache, playwright, exact-sha]

# Dependency graph
requires:
  - phase: 182-reliable-full-browser-verification-and-ci-caches-07
    provides: Exact-source acceptance collector and opt-in Docker/BEAM cache probes.
provides:
  - Real current-source Docker warm/cold and BEAM fallback/lock-change/cold acceptance receipts.
  - Full 189-case local and exact-source hosted browser acceptance with measured upload and job timing.
  - Requirement-level evidence records in 182-CACHE-ACCEPTANCE.md and 182-ACCEPTANCE.md.
affects: [ci, contributor-verification, phase-182-closeout]

# Actuals are measured from the realized non-planning diff: 82,143 changed source-line bytes / 4.
actuals:
  tokens: 20536
  tasks: 2
  commits: 37
  plan_head_before: 532686900769264eea618e5c9a1a681014d09b1f
  plan_head_after: b87660a79a10453491bee063558623df2df38a2c

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Manifest-listed receipts bind browser/cache evidence to one exact repository, branch, SHA, attempt, session, and namespace."
    - "BuildKit cache progress is attributed per target and shared only for targets with identical recipe and image identity."
    - "Compatible BEAM dependency restore can coexist with strict compiled-cache invalidation after lock changes."

key-files:
  created:
    - .planning/phases/182-reliable-full-browser-verification-and-ci-caches/182-CACHE-ACCEPTANCE.md
    - .planning/phases/182-reliable-full-browser-verification-and-ci-caches/182-ACCEPTANCE.md
    - .planning/phases/182-reliable-full-browser-verification-and-ci-caches/182-08-SUMMARY.md
  modified:
    - .github/workflows/ci.yml
    - CONTRIBUTING.md
    - examples/scrypath_ecommerce/compose.e2e.yaml
    - examples/scrypath_ecommerce/docker-playwright.sh
    - examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts
    - examples/scrypath_ecommerce/e2e/ui_followup.spec.ts
    - examples/scrypath_ecommerce/scripts/verify-e2e.sh
    - scripts/ci/ecommerce_build.cjs
    - scripts/ci/ecommerce_build.test.cjs
    - scripts/ci/ecommerce_evidence.cjs
    - scripts/ci/ecommerce_evidence.test.cjs
    - scripts/ci/ecommerce_lifecycle.test.cjs
    - scripts/ci/phase182_acceptance.cjs
    - scripts/ci/phase182_acceptance.test.cjs
    - test/mix/tasks/workflow_wiring_test.exs

key-decisions:
  - "Keep stable, bounded cache namespaces while binding each e37 consumer proof to its own source, recipe, image, and runtime identity."
  - "Count duplicated BuildKit cached steps only across targets whose resolved recipe and image IDs match."
  - "Use the approved 1800-second full-job budget with a separate 300-second body-finalization reserve; do not treat remaining time after upload as that reserve."
  - "Retain Playwright traces on failure; passing runs correctly produce no failure trace."

requirements-completed: [BROW-01, BROW-02, BROW-03, CACHE-01, CACHE-02]

coverage:
  - id: D1
    description: "Real Docker warm imports/useful hits/exports and fresh-builder import-disabled mounted cold execution are validated from exact-source hosted receipts."
    requirement: CACHE-01
    verification:
      - kind: integration
        ref: "node scripts/ci/phase182_acceptance.cjs validate --mode caches --repo szTheory/scrypath --branch worktree-agent-p182-08-1793071051075 --sha e37f5bde914d123f0bf7dcb9c12daec64d465657 --session-id phase182-08-e37f5bde-20261027T154542Z --probe-namespace candidate-556416f7 --input <collector-session-root>"
        status: pass
    human_judgment: false
  - id: D2
    description: "BEAM compatible download fallback, strict lock-change compiled miss, and representative no-import cold execution pass with normal Mix commands."
    requirement: CACHE-02
    verification:
      - kind: integration
        ref: "node scripts/ci/phase182_acceptance.cjs validate --mode caches --repo szTheory/scrypath --branch worktree-agent-p182-08-1793071051075 --sha e37f5bde914d123f0bf7dcb9c12daec64d465657 --session-id phase182-08-e37f5bde-20261027T154542Z --probe-namespace candidate-556416f7 --input <collector-session-root>"
        status: pass
    human_judgment: false
  - id: D3
    description: "The canonical local full browser command and exact-source hosted full run execute the complete mounted/standalone route inventory within the approved time budget."
    requirement: BROW-01
    verification:
      - kind: integration
        ref: "node scripts/ci/phase182_acceptance.cjs validate --mode full --repo szTheory/scrypath --branch worktree-agent-p182-08-1793071051075 --sha e37f5bde914d123f0bf7dcb9c12daec64d465657 --session-id phase182-08-e37f5bde-20261027T154542Z --probe-namespace candidate-556416f7 --input <collector-session-root>"
        status: pass
      - kind: integration
        ref: "env BUILDX_CONFIG=/private/tmp/scrypath-phase182-buildx E2E_RUN_ID=20261027T1548-e37f5bde-local E2E_PROJECT_NAME=scrypath_verify_full_e37f5bde_local E2E_DOCKER_TIMEOUT_SECONDS=1800 E2E_FINALIZATION_MARGIN_SECONDS=300 make -C examples/scrypath_ecommerce verify-e2e"
        status: pass
      - kind: other
        ref: ".planning/phases/182-reliable-full-browser-verification-and-ci-caches/182-ACCEPTANCE.md"
        status: pass
    human_judgment: false
  - id: D4
    description: "All intended ui_followup and ui_iteration3 cases execute and pass on their first attempt with run-owned screenshots."
    requirement: BROW-02
    verification:
      - kind: integration
        ref: "node scripts/ci/phase182_acceptance.cjs validate --mode full --repo szTheory/scrypath --branch worktree-agent-p182-08-1793071051075 --sha e37f5bde914d123f0bf7dcb9c12daec64d465657 --session-id phase182-08-e37f5bde-20261027T154542Z --probe-namespace candidate-556416f7 --input <collector-session-root>"
        status: pass
    human_judgment: false
  - id: D5
    description: "The changed-source hosted full workflow has raw-success 189/189 proof, exact source/image joins, complete bounded artifacts, and successful cleanup inside 1800 seconds."
    requirement: BROW-03
    verification:
      - kind: integration
        ref: "node scripts/ci/phase182_acceptance.cjs validate --mode full --repo szTheory/scrypath --branch worktree-agent-p182-08-1793071051075 --sha e37f5bde914d123f0bf7dcb9c12daec64d465657 --session-id phase182-08-e37f5bde-20261027T154542Z --probe-namespace candidate-556416f7 --input <collector-session-root>"
        status: pass
    human_judgment: false

# Metrics
duration: "not recorded across executor handoff"
completed: 2026-10-27
status: complete
---

# Phase 182 Plan 08: Reliable full browser verification and CI caches Summary

**Exact-source Docker/BEAM cache receipts and a complete 189-case browser proof, with the full run inside the approved 1800-second budget**

## Performance

- **Duration:** Not reliably recorded across the interrupted executor handoff. The six-run acceptance batch itself took 1h 24m 21.849s from the persisted control timestamps; this is not the duration of the whole plan.
- **Started:** The original plan start time was not retained.
- **Completed:** 2026-10-27
- **Tasks:** 2
- **Files modified:** 19 across plan implementation, acceptance records, review record, and this summary.
- **Source-diff estimate:** 82,143 changed source-line bytes / 4 = 20,536 estimate tokens; this is not a harness-token count.

## Accomplishments

- Accepted real Docker BuildKit warm import/useful-reuse/export, fresh-builder mounted cold proof, and BEAM compatible fallback, lock-change invalidation, and cold execution. Exact run IDs, target recipe identities, cache keys/scopes, raw log hashes, artifact digests, and prior ineligible attempts are recorded in [182-CACHE-ACCEPTANCE.md](./182-CACHE-ACCEPTANCE.md).
- Accepted full local and exact-source hosted browser proof. All 189 cases ran once and passed, including mounted and standalone Phase 173 cases, all 7 `ui_followup` cases, and all 6 `ui_iteration3` cases. Both Ops readiness routes passed; parity/contrast checks passed; artifacts copied; owned cleanup ended at zero. Run identities, full inventory, immutable digests, timing, and limitations are in [182-ACCEPTANCE.md](./182-ACCEPTANCE.md).
- Reconciled six accepted hosted runs at one e37 source SHA, branch, session, and cache namespace. Both strict cache and full aggregate validators returned eligible with six invocations. The canonical local full command passed with `E2E_DOCKER_TIMEOUT_SECONDS=1800` and a separate `E2E_FINALIZATION_MARGIN_SECONDS=300`.

## Task Commits

Plan source, regression, and review commits, in chronological order (work across the cache and browser acceptance tasks was interleaved):

1. `9ef84888` preserve run-scoped browser evidence
2. `24a97406` align artifact path contract
3. `2ab82a4a` target fields disclosure by structure
4. `770b10e3` disambiguate nested result disclosures
5. `e627e47a` tolerate disclosure label whitespace
6. `4c84ec14` preserve and validate full evidence receipts
7. `2dc1f0b0` await saved-search picker closure
8. `aa637a9e` repair hosted image handoff checks
9. `57d81cd8` stabilize hosted Compose handoffs
10. `f85b960c` pull runtime dependencies for mounted proof
11. `96c23e65` validate hosted artifact contracts
12. `0b62d50e` parse GitHub-prefixed BuildKit cache logs
13. `f4db59b8` bind cache hits to exact recipe outputs
14. `86eff19e` preserve cache probe identity during handoff
15. `dde08b5d` pass cache probe scope to E2E verifier
16. `b8cb4035` namespace trusted BEAM seed caches
17. `9d9ba977` reproduce lagging Actions metadata
18. `5f250d1f` await complete Actions metadata
19. `8ac1c4e8` record early evidence contract review
20. `fc72cb77` reject foreign browser workflow refs
21. `ed6d2f3c` bind browser proof to selected workflow ref
22. `6f2f2970` reproduce unbound cache namespace selection
23. `b35b0441` bind cache evidence to requested namespace
24. `dac69aeb` record follow-up provenance review
25. `4f75605c` reproduce validation CLI namespace loss
26. `d4b8fc0c` preserve namespace in validation CLI
27. `c0cbfa27` close reviewed provenance findings
28. `c5a6840e` reproduce full aggregate receipt selection bug
29. `b309d0d1` validate full aggregate using parsed receipts
30. `556416f7` record full source review and fixed findings
31. `28e1b770` reproduce whole-run log download failure
32. `53f51a8f` download logs directly for selected jobs
33. `2ca0bb05` cover raw REST BuildKit log timestamps
34. `8c2f1f38` parse timestamped job logs without changing raw hashes
35. `e37f5bde` review direct job-log transport

Acceptance task commits:

1. **Task 1 — cache acceptance:** `6c6bbdd3` (`docs(182-08): record actual cache acceptance`)
2. **Task 2 — full browser acceptance:** `b87660a7` (`docs(182-08): record full browser acceptance`)

The plan metadata commit contains this summary and is recorded separately in the final executor return.

## Verification

- `node scripts/ci/phase182_acceptance.cjs validate --mode caches ... --input <collector-session-root>` — **PASS**, eligible, six invocations, exact repo/branch/SHA/session/namespace.
- `node scripts/ci/phase182_acceptance.cjs validate --mode full ... --input <collector-session-root>` — **PASS**, eligible, six invocations, exact repo/branch/SHA/session/namespace.
- Canonical local command `make -C examples/scrypath_ecommerce verify-e2e` with the recorded 1800-second timeout and 300-second finalization reserve — **PASS**, 189/189 first-attempt cases, skips/unexpected/flaky 0, both routes pass, artifacts copied, cleanup 0.
- Six accepted hosted receipts — **PASS**, each raw browser verifier successful at 189 cases/189 attempts and each whole workflow below 1800 seconds. Full hosted run 40545747370 took 826 seconds through workflow completion; 985 seconds remained in the 1800-second budget after upload.
- `node --test` source/collector suite — **PASS**, 109 tests, 0 failures, no skips (`/private/tmp/scrypath-phase182-execution/direct-log-node.log`).
- Warning-as-error root suite — **PASS**, 961 tests plus 5 properties, 0 failures (`/private/tmp/scrypath-phase182-execution/e37-root-tests.log`).
- Repository contracts — **PASS**, 98 tests, 0 failures (`/private/tmp/scrypath-phase182-execution/e37-repository-contracts.log`).
- Elixir 1.19.0 formatting, `actionlint`, and warnings-as-errors docs check — **PASS** before acceptance; those source paths did not change afterward.

The maximum observed browser-stage-end-to-upload interval was 21 seconds. The configured 300-second body-finalization reserve therefore exceeded observation by 279 seconds, including 219 seconds beyond the required 60-second margin. The separate receipt field for remaining 1800-second budget after upload ranged from 884 to 1100 seconds (985 seconds for the full run). See [182-ACCEPTANCE.md](./182-ACCEPTANCE.md) for all six measurements.

## Files Created/Modified

- `182-CACHE-ACCEPTANCE.md` — exact-source Docker/BEAM proof, immutable receipt and cache artifact digests, mode identities, and preserved attempt history.
- `182-ACCEPTANCE.md` — hosted/local browser results, full inventory, archive digests, timing, artifact limits, and requirement mapping.
- `.github/workflows/ci.yml`, `CONTRIBUTING.md`, and `scripts/ci/phase182_acceptance.cjs` — selected workflow cache policy, documented acceptance commands, and source-bound collection/validation.
- `examples/scrypath_ecommerce/compose.e2e.yaml`, `docker-playwright.sh`, `scripts/verify-e2e.sh`, and the listed `scripts/ci/ecommerce_*` modules/tests — full Compose scope, image handoff, evidence collection, artifact copying, and regressions.
- `examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts`, `e2e/ui_followup.spec.ts`, and `test/mix/tasks/workflow_wiring_test.exs` — cross-environment browser guards and executable repository wiring contracts.

## Decisions Made

- Keep the namespace seeded by run 40530439125 stable across revisions, but require each current consumer to prove its own exact source, recipe, image, and runtime identity.
- Treat `web` and `standalone_ops` BuildKit progress as shared only where their resolved recipe and image IDs are identical; retain distinct per-target import/export completion.
- Keep the local full proof on its existing Compose path, within the approved 1800-second ceiling, and account separately for the 300-second body-finalization reserve.
- Preserve Playwright's `retain-on-failure` trace policy. Since every accepted case passed, the current archives contain no trace file; no failure trace is claimed.

## Deviations from Plan

### Acceptance-driven fixes

All fixes stayed within the plan's real-evidence repair-and-rerun flow; no architecture or product scope was added.

1. **[Rule 1 - Bug] Bind cache reuse to exact resolved recipes and target outputs.** BuildKit deduplicates `web` and `standalone_ops`; the evidence now accepts their shared cached vertices only for matching recipe/image identity and retains each target's separate import/export status. Relevant commits include `f4db59b8`, `0b62d50e`, and `8c2f1f38`.
2. **[Rule 3 - Blocking] Preserve cold-mode scope and cache identity across the mounted job handoff.** The mounted cold proof uses a fresh builder with no imports while the workflow's full browser job remains required and successful. Relevant commits include `86eff19e`, `dde08b5d`, and `b35b0441`.
3. **[Rule 1 - Bug] Bind hosted browser/cache receipts to the selected branch, namespace, run attempt, and parsed aggregate receipt.** Regressions and fixes cover job-metadata readiness, foreign refs, namespace forwarding, full receipt selection, direct selected-job log download, and REST timestamp parsing. Relevant commits include `5f250d1f`, `ed6d2f3c`, `d4b8fc0c`, `b309d0d1`, and `53f51a8f`.

**Total deviations:** 3 acceptance-driven auto-fixes (2 Rule 1, 1 Rule 3). **Impact:** Necessary for the prescribed real acceptance; no unrelated scope was added.

## Issues Encountered

Earlier source candidates and attempts remain accurately classified in the acceptance reports. Some prior collectors failed on GH HOME-cache writes, Actions metadata lag, parser limitations, or whole-run log ZIP transport (`HTTP2CANCEL`; later HTTP/1 read `unexpectedEOF`). Earlier 900-second local attempts ended at 77/189 or with incomplete browser execution. These historical outcomes were not rewritten as passes and do not replace the eligible e37 receipts. No clean-stability claim is made over the full historical set.

The deep-quality dependency audit debt remains deferred to Phase 184. No claim is made that all advisory CI jobs are green. The accepted browser archives include JSON, HTML, screenshots, iteration3 journey captures, health/readiness and service logs; they have no traces because all cases passed under the configured retain-on-failure policy. No paid judge, simulated reviewer approval, baseline rewrite, retry/skip masking, preview mutation, or new required lane was used.

## User Setup Required

None.

## Next Phase Readiness

Plan 182-08 acceptance is recorded for the frozen e37 implementation. The child terminal closeout runs after this summary is committed, and root retains ownership of merge, final phase review, shared STATE/ROADMAP/REQUIREMENTS tracking, and exact-root-SHA terminal closeout.

## Self-Check: PASSED

- The cache and browser acceptance documents and all listed source paths exist.
- All 37 pre-summary plan commits are in the current branch history; the cache and browser acceptance docs are separate task commits.
- Both aggregate validators pass against the manifest-listed session root; saved receipt and archive digests match their immutable bytes.
- The current implementation source tree is byte-for-byte unchanged from e37; only planning documentation follows the frozen implementation.
- `STATE.md`, `ROADMAP.md`, `REQUIREMENTS.md`, `PROJECT.md`, configuration, source, workflows, tests, and retained preview were not modified during this finalization.

---
*Phase: 182-reliable-full-browser-verification-and-ci-caches*
*Completed: 2026-10-27*
