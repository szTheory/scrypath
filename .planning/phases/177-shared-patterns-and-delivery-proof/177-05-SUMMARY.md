---
phase: 177-shared-patterns-and-delivery-proof
plan: 05
subsystem: delivery-evidence
tags: [traceability, release, github-actions, operator-ui]
requires:
  - phase: 177-shared-patterns-and-delivery-proof
    provides: Six-surface implementation, source-bounded local verification, screenshots, and cleanup records from Plans 177-01 through 177-04.
provides:
  - Ordered OPUX-09–OPUX-28 local evidence trace with full product-source SHAs and explicit evidence boundaries.
  - Package validation, release decision, and task-owned cleanup/preview record.
  - Exact PR-head hosted checks, explicit owner waiver of the formal-review gate, and pending final-source attestation boundary.
affects: [phase-177-closeout]
actuals:
  tokens: 5000
  tasks: 3
  commits: 3
  plan_head_before: 8a560ae10263282fafb49e12920df669cbbf0328
  plan_head_after: 38e5752523c9906854af678e5a57f62bbb1d2d25
tech-stack:
  added: []
  patterns:
    - Keep local behavior proof, hosted review/check evidence, owner waiver, and final attestation as separate evidence.
    - Record the maintainer's explicit waiver for the absent formal review without representing it as a review.
key-files:
  created:
    - .planning/phases/177-shared-patterns-and-delivery-proof/177-OPUX-TRACE.md
    - .planning/phases/177-shared-patterns-and-delivery-proof/177-05-SUMMARY.md
  modified:
    - .planning/phases/177-shared-patterns-and-delivery-proof/177-OPUX-TRACE.md
    - .planning/REQUIREMENTS.md
key-decisions:
  - "Do not publish or version-bump Scrypath separately in this phase; the changed lib/ files ship in Hex, so normal Release Please patch cadence applies after merge."
  - "Accept the user's prior CI-conditioned merge authorization as an explicit waiver of the formal-review gate; retain the exact check evidence and make no formal-review claim."
requirements-completed: []
coverage:
  - id: P177-05-A
    description: Every approved OPUX requirement has one ordered local evidence row with a full source SHA, source limits, and shared hosted-evidence boundary.
    requirement: OPUX-28
    verification:
      - kind: other
        ref: "177-OPUX-TRACE.md; 20-row uniqueness/order/SHA/link validator and git diff --check"
        status: pass
    human_judgment: false
  - id: P177-05-B
    description: Package boundary, release decision, owned cleanup, and retained preview state are recorded without conflating the preview with phase evidence.
    requirement: OPUX-28
    verification:
      - kind: integration
        ref: "mix verify.package at 8a560ae10263282fafb49e12920df669cbbf0328; 81 tests passed, package 0.3.15 built and unpacked"
        status: pass
    human_judgment: false
  - id: P177-05-C
    description: Formal-review checkpoint waived by the owner; exact PR-head checks are recorded, while final-source attestation remains a blocking closeout gate.
    requirement: OPUX-28
    verification:
      - kind: other
        ref: "PR #98 audit snapshot at exact head 39e6a44c4a16084ec0738de5ea29a5e61b18b842; five required checks successful; final-source closeout attestation pending"
        status: partial
    human_judgment: true
    rationale: "The user explicitly waived only the formal-review checkpoint using the earlier CI-conditioned merge authorization. The waiver is not represented as a formal review; the final exact-source attestation remains required before OPUX-28 completion."
duration: 25min
completed: 2026-10-12
status: complete
---

# Phase 177 Plan 05: OPUX trace and exact-source delivery closeout

**The 20-row trace, package decision, cleanup ledger, exact PR-head check evidence, and explicit owner waiver are recorded; final-source attestation remains a separate pending phase closeout gate.**

## Accomplishments

- Added one ordered row for every approved requirement OPUX-09 through OPUX-28, with a full local source SHA and a link to its authoritative phase report or Phase 177 evidence.
- Preserved the Phase 173 per-lane source limits and distinguished Phase 177's 90-image direct matrix from its 60 selected interaction-depth images and executable tests.
- Ran `mix verify.package` at `8a560ae10263282fafb49e12920df669cbbf0328` with Elixir 1.19.0 / OTP 28: 81 tests passed, the release contract validated, and Scrypath 0.3.15 built and unpacked.
- Compared the final diff with the package allowlist. `lib/scrypath/operator/state.ex` and `lib/scrypath/operator/status.ex` ship in Hex, so the decision is no separate release or version bump in this phase; the standard Release Please patch train applies after merge.
- Recorded exact Phase 177 disposable-project cleanup, confirmed no Phase 177 containers/networks/volumes remain, and preserved the maintainer preview and its volumes. Read-only inspection found its web container exited; it was not contacted or restarted.
- Validated exactly twenty unique ordered IDs, full SHAs in every row, resolving local links, and a clean `git diff --check`.
- PR [#96](https://github.com/szTheory/scrypath/pull/96) merged at `ab9eb4a28f724c468ef76b4c59355333bc23f174` from exact head `38e5752523c9906854af678e5a57f62bbb1d2d25`. The five required checks and path-scoped Ops UI check passed on that exact head. No formal review exists. The user explicitly waived the formal-review gate using the earlier “mark as ready and squash merge if CI green” authorization; this is owner authorization, not a review.

## Task Commits

1. **Task 1: Create the requirement evidence trace** — `1b53b1a` (`docs(177-05): add OPUX evidence trace`).
2. **Task 2: Join hosted evidence and record package/release and cleanup facts** — package/release and cleanup are in `6ca54e0`; this commit records the actual PR/check snapshot and updates the summary.

The formal-review checkpoint is waived by the user's explicit authorization; no review is fabricated. OPUX-28 remains pending because final exact-source closeout attestation has not run. PR #98's required checks passed at audit snapshot head `39e6a44c4a16084ec0738de5ea29a5e61b18b842`; that snapshot is not evidence for later branch commits. The trace, this summary, and all other completion bookkeeping must be committed before the final exact-source closeout gate.

## Decisions Made

- The package files changed, so this is not Hex-excluded work. Do not publish a separate release from the phase; use the normal pre-1.0 patch train after merge.
- Treat the user's prior CI-conditioned merge instruction as an explicit waiver of the formal-review gate. The PR review API was empty; this waiver is not a formal review and provides no reviewed source SHA.
- Do not run the final `ci_monitor closeout` command until all post-merge bookkeeping is committed and final exact-source checks pass.

## Deviations and issues

- The plain `mix verify.package` invocation exited 126 because this worktree has no `.tool-versions` selection for the `mix` shim. Re-running with the installed `ASDF_ELIXIR_VERSION=1.19.0-otp-28` and `ASDF_ERLANG_VERSION=28.1` completed successfully; no project file or dependency changed.
- The previously retained named Phase 177 Playbooks volumes were removed after image/report collection as part of final cleanup; current Docker inventory confirms the Phase 177 resources are absent. The preview's state is accurately recorded as exited, not healthy.

## Blocking evidence

At PR #98 audit snapshot head `39e6a44c4a16084ec0738de5ea29a5e61b18b842`, the five required checks passed; `deep-quality (advisory)` failed because the root and three application lockfiles resolve `decimal 3.1.1`, while PR-only `coverage (advisory)` and `closeout-attestation` were skipped. Keep the dependency advisory visible as a follow-up; do not change dependency scope as part of this security repair. These check results apply only to that recorded SHA. Refresh them after tracked edits, and keep OPUX-28 incomplete until exact-source closeout succeeds.

## Self-Check: PASSED

- The trace exists and contains exactly twenty ordered unique OPUX-09–OPUX-28 rows with a full local SHA per row.
- The prior plan commits `1b53b1a`, `6ca54e0`, and `38e5752` are present in this worktree history.
- No final-source attestation is claimed; the post-merge bookkeeping and exact-source gate remain pending.

---
*Phase: 177-shared-patterns-and-delivery-proof*
*Plan: 05*
*Recorded: 2026-10-12*
