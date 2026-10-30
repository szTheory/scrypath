---
phase: 184-explicit-and-lean-dependency-graphs
plan: "10"
subsystem: dependencies
tags: [elixir, mix, hex, dependency-audit, ci]

requires:
  - phase: 184-09
    provides:
      - Final dependency locks and supported integration boundaries
provides:
  - Source-bound four-graph audit evidence and all ten proposal dispositions
  - Negative contracts for graph and proposal evidence completeness
  - Candidate acceptance and validation records with known gate limits
affects: [phase-184-closeout, release-readiness, future-dependency-updates]

actuals:
  tokens: 20920
  tasks: 2
  commits: 7
  plan_head_before: f1384a7323f1ac69cf813a463e479df68bc6a9bf
  plan_head_after: a109ff27ae369e19f88691f99a0163479bbee3ff

tech-stack:
  added: []
  patterns:
    - Per-graph evidence records bind source, manifest, lock, toolchain, audit result, and raw receipts.
    - Completeness contracts reject missing or duplicate graph and proposal identities.

key-files:
  created:
    - .planning/phases/184-explicit-and-lean-dependency-graphs/184-ACCEPTANCE.md
    - .planning/phases/184-explicit-and-lean-dependency-graphs/184-10-SUMMARY.md
  modified:
    - .planning/phases/184-explicit-and-lean-dependency-graphs/184-ACTIONS-DISPOSITIONS.md
    - .planning/phases/184-explicit-and-lean-dependency-graphs/184-DEPENDENCY-EVIDENCE.md
    - .planning/phases/184-explicit-and-lean-dependency-graphs/184-VALIDATION.md
    - examples/scrypath_ecommerce/Dockerfile
    - test/mix/tasks/verify_capability_test.exs
    - test/mix/tasks/dependency_audit_test.exs
    - test/mix/tasks/dependency_boundary_contract_test.exs

key-decisions:
  - Keep the two Ops Cloak advisories visible and unaccepted; do not add ignores or infer risk acceptance.
  - Serialize Docker Hex cache writes with BuildKit `sharing=locked` after the first hosted ecommerce candidate exposed concurrent cache corruption.
  - Use a direct verifier contract call to satisfy the core Credo gate without changing the optional-dependency boundary.
  - Record only Elixir 1.19.5 / OTP 28.5 as locally exercised; hosted compatibility passed on the first candidate and must be rechecked for the corrected candidate.
  - Do not collect retained-preview evidence while its required source preflight rejects stale main provenance.

patterns-established:
  - Each graph audit stores raw output and exact manifest/lock/source identities alongside its true exit status.
  - Proposal disposition contracts require every proposal to have a unique complete evidence and revisit record.

requirements-completed: [DEP-01, DEP-02, DEP-03, DEP-04, DEP-05, DEP-06, DEP-07]

coverage:
  - id: D1
    description: Negative contract tests reject incomplete, duplicate, and mismatched graph and proposal evidence identities.
    requirement: DEP-07
    verification:
      - kind: unit
        ref: "/private/tmp/scrypath-phase184-10-20261030T072352Z/bin/mix test test/mix/tasks/dependency_audit_test.exs test/mix/tasks/dependency_boundary_contract_test.exs test/mix/tasks/verify_capability_test.exs --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: Four graph audit outcomes and ten proposal dispositions preserve exact identities and visible residual findings.
    requirement: DEP-07
    verification:
      - kind: other
        ref: "/private/tmp/scrypath-phase184-10-20261030T072352Z/receipts/dependency-audit-final.exit"
        status: fail
      - kind: other
        ref: ".planning/phases/184-explicit-and-lean-dependency-graphs/184-ACTIONS-DISPOSITIONS.md"
        status: pass
    human_judgment: true
    rationale: "Ops still reports two unaccepted Cloak advisories; the evidence must not convert that result into accepted risk."
  - id: D3
    description: Candidate acceptance and validation records state local gate outcomes and the exact-source hosted closeout boundary.
    requirement: DEP-01
    verification:
      - kind: other
        ref: "/private/tmp/scrypath-phase184-10-20261030T072352Z/receipts/core-final-candidate-mixenv-test.exit"
        status: pass
      - kind: integration
        ref: "/private/tmp/scrypath-phase184-10-20261030T072352Z/ecommerce-mounted-artifacts/20261030T084825Z-88898-217393799/lifecycle.json"
        status: pass
      - kind: other
        ref: "https://github.com/szTheory/scrypath/actions/runs/41024777215 (first candidate failed); corrected candidate closeout receipt under /private/tmp/scrypath-phase184-10-20261030T072352Z/receipts/"
        status: fail
    human_judgment: true
    rationale: "The first exact-SHA hosted candidate failed two required jobs; the corrected candidate closeout runs after this Summary commit and its result is external by design."
  - id: D4
    description: Retained-preview source and data preservation limits are recorded without claiming rendered UI review.
    requirement: DEP-04
    verification:
      - kind: other
        ref: "PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 npm run ui:preflight"
        status: fail
    human_judgment: true
    rationale: "The named UI checkout does not include origin/main, so current rendered screens and keyboard behavior could not be reviewed safely."

duration: 1h 27m
completed: 2026-10-30
status: complete
---

# Phase 184 Plan 10: Final Graph Evidence and Candidate Closeout Summary

**Four graph audits and ten dependency proposal dispositions are source-bound; two scoped fixes clear local core and mounted checks, while the first hosted candidate's failures remain recorded.**

## Performance

- **Duration:** 1h 27m through final tracked candidate preparation
- **Started:** 2026-10-30T07:23:52Z
- **Completed:** 2026-10-30T08:50:51Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Recorded final root, Phoenix, ecommerce, and ScrypathOps graph identities and raw Hex audit results at code source `6838085626174c8016e9cf57aa9af84dccab20df`; all four lockfiles remained byte-stable.
- Completed source, version, status, evidence, rationale, and revisit records for PR #65 and #68–#76 without modifying the upstream proposals.
- Added negative contract coverage for incomplete graph identities and proposal dispositions, and committed acceptance/validation records that distinguish passing proofs from unresolved gates.
- Fixed the first candidate's core Credo blocker and Docker Hex cache writer race; the 45-test contract suite, core verifier, and cold mounted ecommerce proof pass at source `a109ff27ae369e19f88691f99a0163479bbee3ff`.

## Verification Results

All local Mix commands used the selected supported Elixir 1.19.5 / OTP 28.5 toolchain through `/private/tmp/scrypath-phase184-10-20261030T072352Z/bin/mix` with independent build/dependency paths.

| Verification | Result |
| --- | --- |
| Focused dependency audit, boundary, and verifier contract tests with warnings as errors | PASS — 45 tests, 0 failures |
| `mix verify.repository_contracts` | PASS |
| `mix verify.core --exclude integration --exclude docs_contract` | PASS after direct-call fix; no-Oban proof included |
| `mix verify.package` | PASS |
| `mix verify.backend` | PASS; disposable Compose services were removed |
| `mix verify.ops_ui` | PASS with isolated paths |
| `mix verify.ecommerce_mounted` | PASS after cache serialization fix; four focused browser checks, disposable proof services removed |
| `mix verify.compatibility` local run | PASS on 1.19.5 / OTP 28.5 only |
| `actionlint .github/workflows/ci.yml .github/workflows/workflow-security.yml` | PASS |
| Independent `mix dialyzer` | PASS — zero errors |
| Four-graph aggregate dependency audit | EXIT 1 — three graphs clean; Ops affected by two unaccepted Cloak advisories |
| First canonical hosted candidate closeout | FAIL — run `41024777215`, candidate SHA `2d6987f5620b53f6f5bc4968f72f77983eaa3148`; required `core` and `ecommerce-mounted` failed, so no attestation was produced |
| Corrected candidate canonical closeout | Runs immediately after this Summary commit; exact run, job and immutable artifact receipts are external |
| Named preview `npm run ui:preflight` | REFUSED — checkout does not include `origin/main` |

The core Credo finding was fixed in the declared verification-test seam by replacing `apply/3` with the direct contract call. The first hosted ecommerce failure was caused by Hex cache file-renames colliding between Docker build targets; BuildKit `sharing=locked` now serializes writers. The second local mounted proof used its unique project `scrypath_ecommerce_verify_focused_a109ff27_88898`, external artifact root, and cleaned all owned containers/networks/volumes. The retained `scrypath_ecommerce` services remained healthy and untouched. The Ops audit findings remain EEF-CVE-2026-95105 / CVE-2026-95105 and EEF-CVE-2026-94206 / CVE-2026-94206; no Hex findings were ignored or accepted.

The first hosted candidate's five required jobs were: `package`, `repository-contracts`, and `backend` passed; `core` and `ecommerce-mounted` failed. Its coverage artifact passed with digest `sha256:1d4a9aabe02c13d066eaee920788e6d79c89e2f026ad35be7b879bb6457c9215`; closeout-attestation failed because required jobs did not pass. All four compatibility tuples and the Phoenix example passed in that run. Full run receipts are external at `/private/tmp/scrypath-phase184-10-20261030T072352Z/`. The available local toolchain proves only Elixir 1.19.5 / OTP 28.5; the corrected candidate's hosted run must re-establish the matrix at its exact SHA.

The required read-only preview preflight was run against the checkout named by `.planning/UI-PREVIEW.json`, branch `ui/next`, URL `http://127.0.0.1:4002`. It refused review because `origin/main` is absent. The checkout's tracked CSS edit and untracked playbooks directory were preserved. No screenshots were collected and no independent UI review is claimed.

## Task Commits

1. **Task 1: Enforce graph and proposal evidence contracts** — `ded20101` (`test(184-10): enforce graph and proposal evidence contracts`)
2. **Task 1: Split graph evidence contract checks** — `6838085` (`refactor(184-10): split graph evidence contract checks`)
3. **Task 1: Bind audit receipts to final source** — `da64e0a7` (`docs(184-10): bind audit receipts to final source`)
4. **Task 2: Record candidate acceptance limits** — `b5cfdfbd` (`docs(184-10): record candidate acceptance limits`)
5. **Task 1 deviation: Serialize Hex cache writers across image targets** — `4022f26e` (`fix(184-10): serialize Hex cache writers across image targets`)
6. **Task 1 deviation: Call verifier contract directly** — `a109ff27` (`fix(184-10): call verifier contract directly`)

The earlier pre-closeout Summary candidate was committed as `2d6987f5`. This refreshed Summary is committed before the corrected candidate closeout; its run identity and immutable artifacts are stored externally.

## Files Created/Modified

- `.planning/phases/184-explicit-and-lean-dependency-graphs/184-ACTIONS-DISPOSITIONS.md` — ten proposal dispositions and revisit triggers.
- `.planning/phases/184-explicit-and-lean-dependency-graphs/184-DEPENDENCY-EVIDENCE.md` — exact graph identities and external raw audit/Dialyzer receipts.
- `.planning/phases/184-explicit-and-lean-dependency-graphs/184-ACCEPTANCE.md` — evidence status, residual findings, and delivery limits.
- `.planning/phases/184-explicit-and-lean-dependency-graphs/184-VALIDATION.md` — execution status for Plan 10 tasks; Nyquist remains false.
- `examples/scrypath_ecommerce/Dockerfile` — serializes Hex writes through shared BuildKit cache mounts.
- `test/mix/tasks/dependency_audit_test.exs` — wrong-source evidence rejection coverage.
- `test/mix/tasks/dependency_boundary_contract_test.exs` — full graph/proposal evidence completeness and negative cases.
- `test/mix/tasks/verify_capability_test.exs` — direct verifier contract invocation satisfying Credo.
- `.planning/phases/184-explicit-and-lean-dependency-graphs/184-10-SUMMARY.md` — this execution record.

## Decisions Made

- The Ops Cloak findings remain visible and unaccepted; no ignore rule or risk policy was introduced.
- Docker Hex cache sharing is locked to prevent concurrent build targets from corrupting Hex's cache index.
- The known-argument verifier uses a direct call so the core Credo gate stays clean.
- Local compatibility evidence is limited to Elixir 1.19.5 / OTP 28.5 until the corrected candidate's hosted matrix is inspected.
- Preview evidence was not collected after the required preflight rejected stale source provenance.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Serialize concurrent Hex cache writers in ecommerce image builds**
- **Found during:** Task 2 candidate closeout, run `41024777215`
- **Issue:** Concurrent Docker targets sharing the default Hex cache raced on `cache.bin` rename, causing the required mounted ecommerce job to fail.
- **Fix:** Set all three Hex BuildKit cache mounts in the ecommerce Dockerfile to `sharing=locked`.
- **Files modified:** `examples/scrypath_ecommerce/Dockerfile`
- **Verification:** `mix verify.ecommerce_mounted` passed; external lifecycle receipt records clean cleanup.
- **Committed in:** `4022f26e`

**2. [Rule 3 - Blocking] Clear the core Credo violation in the verifier contract test**
- **Found during:** Task 2 candidate closeout, run `41024777215`
- **Issue:** The required core job rejected `apply/3` with a statically known verifier-contract function.
- **Fix:** Replace dynamic `apply/3` with the direct module call.
- **Files modified:** `test/mix/tasks/verify_capability_test.exs`
- **Verification:** The 45 focused contract tests and `mix verify.core --exclude integration --exclude docs_contract` both passed.
- **Committed in:** `a109ff27`

## Issues Encountered

- The first hosted candidate failed the two required jobs described above. Both directly scoped causes were fixed, locally reverified, and included in the corrected candidate.
- The final Hex audit exits 1 because the two Ops Cloak advisories remain active and unaccepted.
- The retained UI preflight refuses current review because the named checkout does not include `origin/main`; the preview was left untouched.
- An initial local mounted-proof attempt was interrupted after it wrote only a transient `source.json` into the checkout. That single run directory was moved outside the checkout; the corrected run used an external artifact root and passed.
- The corrected candidate closeout is intentionally run only after this Summary commit. The exact source, run identity, job outcomes, and immutable artifact digests are stored externally. This Summary does not claim the corrected candidate closeout has passed.

## User Setup Required

None.

## Next Phase Readiness

The corrected candidate is ready for the required post-summary hosted closeout; the candidate's exact run and artifacts are external, and the first failed run remains historical evidence. The orchestrator owns phase integration and must run terminal closeout again against the exact final `planning/v1.45-foundation-ci` HEAD after merge and phase tracking writes. Do not treat this candidate as merged or as phase completion.

---
*Phase: 184-explicit-and-lean-dependency-graphs*
*Completed: 2026-10-30*

## Self-Check: PASSED

- The plan-owned acceptance/evidence/disposition/test/validation files exist.
- All six task and scoped-fix commits plus the earlier pre-closeout Summary commit are reachable on this branch; the plan commit ledger resolves seven commits before this refreshed Summary commit.
- Focused contract verification passed with 45 tests and 0 failures; corrected core and mounted ecommerce checks passed.
- The Ops audit findings, first failed hosted candidate, stale-preview preflight, and corrected candidate's post-summary closeout boundary are recorded without claiming phase acceptance.
