---
phase: 86-support-truth-and-proof-surface-reconciliation
plan: 01
subsystem: docs
tags: [docs, exdoc, support, readiness]
requires: []
provides:
  - canonical support and compatibility guide restored on branch tip
  - README and CONTRIBUTING support/readiness routing aligned to one authority
  - ExDoc and guide index wayfinding for the restored guide
affects: [phase-86, docs, exdoc]
tech-stack:
  added: []
  patterns: [single canonical guide, short-doc wayfinding, branch-tip truth]
key-files:
  created: [guides/support-and-compatibility.md]
  modified: [README.md, CONTRIBUTING.md, guides/overview.md, mix.exs]
key-decisions:
  - "Restored the historical support guide path instead of inventing a new authority name so active planning and docs can converge on one stable surface."
  - "Kept sync semantics and live-runbook detail delegated to their existing authorities instead of duplicating them in the support guide."
patterns-established:
  - "README and CONTRIBUTING route support/readiness questions to one current guide instead of becoming competing contract surfaces."
requirements-completed: [TRUTH-01]
duration: 1 session
completed: 2026-05-24
---

# Phase 86 Plan 01: Support Truth And Proof Surface Reconciliation Summary

**The canonical support/readiness guide is restored and discoverable again**

## Accomplishments

- Recreated `guides/support-and-compatibility.md` as the single current support/readiness authority for runtime posture, the defended Phoenix + Meilisearch path, sync-mode support posture, the maintainer proof-command family, the repo-clone vs Hex boundary, and the in-repo-proof vs outside-adopter-evidence distinction.
- Rewired README and CONTRIBUTING so they point support/readiness questions back to that guide instead of carrying their own partial support matrices.
- Added the guide back to ExDoc extras/groups and the guide index so branch-tip docs publish the same authority they reference.

## Files Created/Modified

- `guides/support-and-compatibility.md` - Restored canonical support/readiness authority.
- `README.md` - Added support/readiness wayfinding and narrowed sync-authority wording.
- `CONTRIBUTING.md` - Added maintainer-facing pointer back to the canonical guide.
- `guides/overview.md` - Added guide-index routing for the restored authority.
- `mix.exs` - Restored the guide to ExDoc extras and ordering.

## Verification

- `rg -n "support-and-compatibility\.md" README.md CONTRIBUTING.md guides/overview.md mix.exs`
- `rg -n "Phoenix \+ Meilisearch|Elixir|OTP|:inline|:manual|:oban|verify\.adopter|outside-adopter evidence|Hex" guides/support-and-compatibility.md`
- `mix docs --warnings-as-errors`

## Task Commits

No commits were created during this execution run.

## Issues Encountered

None.

## Next Phase Readiness

The branch tip has one current support/readiness authority again and is ready for `mix verify.adopter` contract repair.

---
*Phase: 86-support-truth-and-proof-surface-reconciliation*
*Completed: 2026-05-24*
