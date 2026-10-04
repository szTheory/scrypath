---
phase: 172-consistent-operator-ui-and-verified-recovery
plan: "08"
subsystem: delivery
completed: 2026-10-04
tasks_completed: 3
status: complete
requirements-completed: [OPUX-01, OPUX-02, OPUX-03, OPUX-04, OPUX-05, OPUX-06, OPUX-07, OPUX-08]
requirements-addressed: [OPUX-01, OPUX-02, OPUX-03, OPUX-04, OPUX-05, OPUX-06, OPUX-07, OPUX-08]
requires: [172-07]
provides:
  - Reviewed operator UI and core correctness delivery with executable acceptance.
  - Exact-source candidate evidence and completion-before-attestation bookkeeping.
key-files:
  created:
    - .planning/phases/172-consistent-operator-ui-and-verified-recovery/172-EVIDENCE.md
    - .planning/phases/172-consistent-operator-ui-and-verified-recovery/172-VERIFICATION.md
  modified:
    - test/mix/tasks/workflow_wiring_test.exs
    - .planning/phases/172-consistent-operator-ui-and-verified-recovery/172-VALIDATION.md
    - .planning/phases/172-consistent-operator-ui-and-verified-recovery/172-SECURITY.md
    - .planning/PROJECT.md
    - .planning/STATE.md
    - .planning/ROADMAP.md
---

# Phase 172 Plan 08 summary

## Reviewed behavior

Independent source review resolved two HIGH and three MEDIUM findings in a bounded 39-file review. Root task readiness now treats cancelled/unknown/deletion work correctly; current Oban failure causes remain actionable. File-dialog validation stays inside the active modal, successful rename restores stable focus, and promotion polling errors remain unconfirmed until exact-UID terminal evidence is observed. `172-REVIEW.md`, `172-REVIEW-DISPOSITION.md` and `172-SECURITY.md` preserve findings, evidence and limits.

All six operator surfaces use the existing token/component system. Direct before/after image findings are recorded in `172-EVIDENCE.md`, including the non-identical Sync/Drift fixture-state limitation. The redundant shortcut copy is removed; no paid visual judge, new framework/dependency or extra required CI lane was introduced.

## Executed checks and delivery

- Root core: 657 tests, four properties, zero failures; formatting, clean packaged paths, compile, Credo and docs passed. Ops and precommit: 233 tests plus two doctests each, zero failures.
- First hosted candidate `489f4e3` failed because a repository test still required one browser retry. Test-only commit `135517b` updates that contract to zero retries, one worker and retained failure traces. Focused wiring: 45/45. The failed run remains recorded as failed.
- Corrected candidate `135517b2aa7d1515a4be71c4f9d53aa8dd60c341`, run [37178388184](https://github.com/szTheory/scrypath/actions/runs/37178388184): all five required jobs, coverage, full browser and attestation passed. Browser 104/104; mounted 4/4; static AA failures 0; light screenshot inventory 20/20. Candidate watcher lost its GitHub connection; read-only receipt collection then exited 0 and verified the exact run/attempt and artifact/archive/member digests. No suite was repeated for that transport error.
- PR [#91](https://github.com/szTheory/scrypath/pull/91) passed required and scoped Ops checks in run37178390800, then squash merged as `3ad154a33f99cb200b791577aadc5970adc70ca2`. Post-merge main run37180290165 also passed all required and scoped Ops checks.
- Core package fixes warrant a patch release. Release Please PR [#92](https://github.com/szTheory/scrypath/pull/92) proposes 0.3.15; its three-file version/manifest/changelog diff is coherent. Candidate `7caba7bd398a0c8dba0fd3141d9f708b7f1d2f64` passed canonical closeout run37180335392 (exit 0). PR92 then passed normal PR CI37181241295, merged8dd20e8966acd17a4ef5acec653c00dc31faab49 and published `scrypath-v0.3.15`. Run37181522723 passed actual publish, live Hex/HexDocs/consumer checks and package/tag parity.

## Cleanup and preservation

Both task-owned disposable verifier projects, their networks and volumes were removed after artifact collection. Preview `scrypath-ui-v142` remains healthy at http://127.0.0.1:4012/admin/search for optional feedback and was refreshed without reseeding. Its bind-mounted worktree is deliberately retained. Original checkout and the pre-existing stash remain untouched. Exact ownership and stop command are in EVIDENCE.

## Completion ordering and current boundary

Candidate evidence precedes requirement/phase/milestone completion records. All summaries, validation, independent verification, audit and archive writes must be committed before final exact-source attestation. The final receipt stays outside that source; there will be no post-attestation summary stamping. Publication and candidate proof are complete. This summary and all remaining verification/audit/archive bookkeeping are prepared in the final completion transaction; the enclosing final exact-source attestation happens after commit and its receipt is external. This record does not claim a future final run passed. Historical Phase170 and issue86 records remain unchanged.

## Durable lessons

- Update workflow-wiring expectations when intentionally changing browser retry/trace policy; tests and configuration must describe the same acceptance contract.
- A failed local broad run plus a corrected subset is recorded honestly; one clean hosted full run establishes final suite acceptance.
- Preserve current fixture/error identity and inspect screenshots directly; screenshot counts are not visual judgment or pixel parity.
- Same-node recovery observations remain bounded; missing/remote/expired evidence is unknown. Retained failures are evidence, not cleanup targets.
- Bot-created release PRs may need a normal PR event before branch protection sees checks; do not bypass the required gates.
