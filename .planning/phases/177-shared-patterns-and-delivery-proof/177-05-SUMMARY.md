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
  - Explicit unresolved boundary for reviewed PR source, hosted checks, and final-source attestation.
affects: [phase-177-closeout]
actuals:
  tokens: 5000
  tasks: 2
  commits: 3
tech-stack:
  added: []
  patterns:
    - Keep local behavior proof, hosted review/check evidence, and final attestation as separate source identities.
    - Stop at the exact-source review gate when a reviewer or required check is absent; never infer approval.
key-files:
  created:
    - .planning/phases/177-shared-patterns-and-delivery-proof/177-OPUX-TRACE.md
    - .planning/phases/177-shared-patterns-and-delivery-proof/177-05-SUMMARY.md
  modified: []
key-decisions:
  - "Do not publish or version-bump Scrypath separately in this phase; the changed lib/ files ship in Hex, so normal Release Please patch cadence applies after merge."
  - "Keep OPUX-28 incomplete until an actual reviewed PR source and every required hosted check match the exact source selected for attestation."
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
    description: Reviewed PR source, required hosted checks, and final source attestation remain an explicit human/external checkpoint.
    requirement: OPUX-28
    verification: []
    human_judgment: true
    rationale: "The plan requires a real review record and successful required CI runs for an exact full source SHA. None existed when the trace was drafted; local verification cannot substitute for those hosted records."
duration: 25min
completed: 2026-10-12
status: halted
---

# Phase 177 Plan 05: OPUX trace and exact-source delivery closeout

**The 20-row local evidence trace, package decision, and scoped cleanup ledger are ready; OPUX-28 remains open at the reviewed-PR and exact-SHA hosted-check gate.**

## Accomplishments

- Added one ordered row for every approved requirement OPUX-09 through OPUX-28, with a full local source SHA and a link to its authoritative phase report or Phase 177 evidence.
- Preserved the Phase 173 per-lane source limits and distinguished Phase 177's 90-image direct matrix from its 60 selected interaction-depth images and executable tests.
- Ran `mix verify.package` at `8a560ae10263282fafb49e12920df669cbbf0328` with Elixir 1.19.0 / OTP 28: 81 tests passed, the release contract validated, and Scrypath 0.3.15 built and unpacked.
- Compared the final diff with the package allowlist. `lib/scrypath/operator/state.ex` and `lib/scrypath/operator/status.ex` ship in Hex, so the decision is no separate release or version bump in this phase; the standard Release Please patch train applies after merge.
- Recorded exact Phase 177 disposable-project cleanup, confirmed no Phase 177 containers/networks/volumes remain, and preserved the maintainer preview and its volumes. Read-only inspection found its web container exited; it was not contacted or restarted.
- Validated exactly twenty unique ordered IDs, full SHAs in every row, resolving local links, and a clean `git diff --check`.
- Published draft [PR #96](https://github.com/szTheory/scrypath/pull/96). At head `6ca54e08b24bff993b4645b6db1e402ef0705fde`, the review API returned no reviews and the five required checks were in progress with matching full `head_sha` values; the trace records those actual run URLs and results.

## Task Commits

1. **Task 1: Create the requirement evidence trace** — `1b53b1a` (`docs(177-05): add OPUX evidence trace`).
2. **Task 2: Join hosted evidence and record package/release and cleanup facts** — package/release and cleanup are in `6ca54e0`; this commit records the actual PR/check snapshot and updates the summary.

The trace update is a tracked change after the `6ca54e0` PR head and will advance the branch again when committed. The new head's review and five required checks must be inspected independently. Because no review exists and all checks at `6ca54e0` were still in progress, this plan remains halted and OPUX-28 remains incomplete.

## Decisions Made

- The package files changed, so this is not Hex-excluded work. Do not publish a separate release from the phase; use the normal pre-1.0 patch train after merge.
- Keep the PR draft until a maintainer performs the actual review. Do not substitute local checks or this execution record for review.
- Do not run the final `ci_monitor closeout` command while reviewed-source or exact-SHA required-check evidence is unresolved.

## Deviations and issues

- The plain `mix verify.package` invocation exited 126 because this worktree has no `.tool-versions` selection for the `mix` shim. Re-running with the installed `ASDF_ELIXIR_VERSION=1.19.0-otp-28` and `ASDF_ERLANG_VERSION=28.1` completed successfully; no project file or dependency changed.
- The previously retained named Phase 177 Playbooks volumes were removed after image/report collection as part of final cleanup; current Docker inventory confirms the Phase 177 resources are absent. The preview's state is accurately recorded as exited, not healthy.

## Blocking evidence

The initial local trace was drafted before a PR existed. Draft PR #96 now provides a real review/check boundary, but the review API is empty and the five checks on `6ca54e08b24bff993b4645b6db1e402ef0705fde` were in progress. This trace/summary update will create a new PR head, so the earlier runs do not prove the new source. The final source attestation is intentionally not run. Continue only after the actual review and all required checks are present for one exact full SHA, with no later tracked writes.

---
*Phase: 177-shared-patterns-and-delivery-proof*
*Plan: 05*
*Recorded: 2026-10-12*
