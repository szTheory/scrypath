---
phase: 170-documentation-and-readiness-closeout
plan: "08"
subsystem: readiness closeout
tags: [attestation, readiness, finality]

# Dependency graph
requires:
  - phase: 170-07
    provides: frozen source snapshot, external digest manifest, and no-write boundary
provides:
  - Preterminal execution contract pointing to issue #86 as the terminal decision authority
affects: [phase-170-terminal-closeout]

actuals:
  tokens: 0
  tasks: 0
  commits: 0

tech-stack:
  added: []
  patterns:
    - Terminal judgments and publication approval remain attributable to the actual maintainer

key-files:
  created: []
  modified: []

key-decisions:
  - "No exact-source run, six-condition judgment, or terminal publication is claimed before Plan 08 executes."

patterns-established:
  - "A factual validator checks supplied evidence and never supplies semantic readiness approval."

requirements-completed: []
coverage:
  - id: D1
    description: "The external terminal-decision path is prepared; exact-source attestation and maintainer judgments remain pending."
    requirement: GATE-05
    verification: []
    human_judgment: true
    rationale: "Only the actual maintainer can judge the six conditions and approve the exact durable record."

duration: pending
completed: 2026-10-01
status: blocked
---

# Phase 170 Plan 08: Preterminal Handoff

**The terminal evidence run and accountable maintainer decision remain pending.**

This frozen handoff identifies issue [#86](https://github.com/szTheory/scrypath/issues/86) as the sole terminal outcome authority. It records no final source SHA, run, attempt, release publication, condition judgment, risk acceptance, or READY/NOT READY outcome.

## Required execution after the freeze

- Verify the external freeze manifest and both checkout fingerprints before and after each external mutation.
- Run the exact-source closeout from the retained evidence ref and preserve the selected attempt, compact attestation, artifact digests, and delivery facts outside the tracked tree.
- Present the unchanged six conditions and final evidence to the accountable maintainer. Record their supplied PASS/FAIL/UNKNOWN judgments and rationale, any explicit risk acceptance, and a READY or NOT READY decision. READY requires all six conditions to pass.
- Render and validate the exact comment body, then obtain explicit approval to publish it through the accountable maintainer's account, or read back the exact comment they posted directly.
- Verify the comment author, issue, timestamp, body, source, and receipt joins. Do not write any tracked file after the freeze.

## Current blockers

- PR #83 remains an authorized but unpublished 0.3.14 candidate because its required approving GitHub review is absent. Keep this delivery disposition explicit in condition 6 and any terminal record.
- No terminal decision comment exists yet. The actual six judgments, decision, and approval of the exact rendered body are execution inputs, not assumptions supplied by this summary.

## Completion status

This is a deliberately blocked preterminal contract, not a completion summary for Plan 08. Its `status: blocked` keeps Plan 08 runnable in phase indexing. Replace no frozen artifact after the final attestation; the terminal outcome belongs only in the separately dated issue comment.
