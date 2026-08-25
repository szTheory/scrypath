---
phase: 147-ecommerce-mounted-ops-remediation-and-closure-evidence
plan: "02"
subsystem: exact-sha-evidence
tags: [worktree, docker, playwright, audit, cleanup]
provides:
  - exact-SHA fresh-resolution and service proof
  - classified focused browser evidence
requirements-completed: [SEC-04, COMPAT-03]
completed: 2026-08-25
status: complete
---

# Phase 147 Plan 02: Exact-SHA and Browser Evidence Summary

Candidate `fca4c827a59596e2a66bc2d1ac3516b4c0c5681e` passed fresh isolated resolution, all nine approved package ranges, canonical mounted-source checks, warning-clean compilation, controller and precommit tests, service preparation, and the unsuppressed Hex audit.

`make verify-mounted` then passed 4/4 focused Chromium tests on the exact committed candidate without retries. Guarded cleanup removed all disposable worktree, Mix, service, network, and volume state while preserving the primary locks, dirty baseline, and protected audit hash. The compact receipt is in `147-CLOSURE-EVIDENCE.md`.

## Deviations

- Replaced an unavailable Elixir realpath helper with physical shell path canonicalization.
- Used guarded `git worktree remove --force` because the deliberately regenerated disposable lock marks the probe worktree dirty; every ownership, non-symlink, exact-child, canonical-registration, and prefix assertion remained enforced.

## Self-Check: PASSED

- Focused browser classification appears once and is separate from deterministic and service proof.
- No generated browser or service artifact was committed.
