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
  - Exact PR-head hosted checks, explicit owner waiver of the formal-review gate, and immutable exact-source closeout evidence.
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
requirements-completed: [OPUX-28]
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
    description: Formal-review checkpoint waived by the owner; exact PR-head checks and an exact-source closeout attestation are recorded.
    requirement: OPUX-28
    verification:
      - kind: other
        ref: "PR #98 run 38318747952 and closeout run 38319195947 at exact head dd0f89ebdb21e991b3831b98ba84713d3460fb1a; five required jobs, coverage, and closeout-attestation successful"
        status: pass
    human_judgment: true
    rationale: "The user explicitly waived only the formal-review checkpoint using the earlier CI-conditioned merge authorization. The waiver is not represented as a formal review. A separate exact-source closeout attestation passed; the terminal merge-source attestation follows final roadmap/state bookkeeping."
duration: 25min
completed: 2026-10-12
status: complete
---

# Phase 177 Plan 05: OPUX trace and exact-source delivery closeout

**The 20-row trace, package decision, cleanup ledger, exact PR-head checks, explicit owner waiver, and exact-source closeout evidence are recorded.**

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

The formal-review checkpoint is waived by the user's explicit authorization; no review is fabricated. PR #98 run [38318747952](https://github.com/szTheory/scrypath/actions/runs/38318747952) tested exact head `dd0f89ebdb21e991b3831b98ba84713d3460fb1a`; all five required checks and `ops-ui-path` passed. Exact-source closeout run [38319195947](https://github.com/szTheory/scrypath/actions/runs/38319195947) on that same SHA passed all required jobs, coverage, and `closeout-attestation`. Its immutable artifacts are coverage `11778055844` (`sha256:2cc8b21a75c844531a1e4545827fb6dae41607838478af6bfc83dd40290240e1`) and closeout `11778310823` (`sha256:6184b3afaeabff682321903d1a834f653b673df0a2bc31f96e27120ffe0ed3ab`, expires 2026-10-19). This snapshot is not evidence for later bookkeeping commits; after all phase and roadmap records are committed, run the terminal attestation on the final merge source. Keep its receipt external to the frozen source.

## Decisions Made

- The package files changed, so this is not Hex-excluded work. Do not publish a separate release from the phase; use the normal pre-1.0 patch train after merge.
- Treat the user's prior CI-conditioned merge instruction as an explicit waiver of the formal-review gate. The PR review API was empty; this waiver is not a formal review and provides no reviewed source SHA.
- Keep the terminal `ci_monitor closeout` after all phase, roadmap, and state bookkeeping is committed. Its receipt is external; do not add tracked changes after it runs.

## Deviations and issues

- The plain `mix verify.package` invocation exited 126 because this worktree has no `.tool-versions` selection for the `mix` shim. Re-running with the installed `ASDF_ELIXIR_VERSION=1.19.0-otp-28` and `ASDF_ERLANG_VERSION=28.1` completed successfully; no project file or dependency changed.
- The previously retained named Phase 177 Playbooks volumes were removed after image/report collection as part of final cleanup; current Docker inventory confirms the Phase 177 resources are absent. The preview's state is accurately recorded as exited, not healthy.

## Advisory evidence

On run 38319195947 at exact SHA `dd0f89ebdb21e991b3831b98ba84713d3460fb1a`, `deep-quality (advisory)` and `ecommerce-e2e (advisory)` failed. The five required checks, coverage, and closeout attestation succeeded. The dependency advisory concerns `decimal 3.1.1` in existing lockfiles; keep it visible as a follow-up and do not change dependency scope as part of this phase security repair. These outcomes apply only to that SHA. The terminal main-source attestation will be run after the final planning commits and its artifacts retained externally.

## Self-Check: PASSED

- The trace exists and contains exactly twenty ordered unique OPUX-09–OPUX-28 rows with a full local SHA per row.
- The prior plan commits `1b53b1a`, `6ca54e0`, and `38e5752` are present in this worktree history.
- Exact-source closeout evidence and artifact digests are recorded above; no claim is made that its artifact covers later bookkeeping commits.

---
*Phase: 177-shared-patterns-and-delivery-proof*
*Plan: 05*
*Recorded: 2026-10-12*
