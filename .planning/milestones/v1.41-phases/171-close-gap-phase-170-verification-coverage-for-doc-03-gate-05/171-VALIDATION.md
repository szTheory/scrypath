---
phase: "171"
slug: close-gap-phase-170-verification-coverage-for-doc-03-gate-05
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-02"
---

# Phase 171 — Validation Strategy

> Per-phase validation contract for the additive requirement-evidence closure.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | GSD CLI, Node.js, ripgrep, and shasum |
| **Config file** | `.planning/config.json` |
| **Quick run command** | `for id in DOC-03 GATE-05 CLOSE-04; do rg -Fq "| $id |" .planning/phases/171-close-gap-phase-170-verification-coverage-for-doc-03-gate-05/171-VERIFICATION.md || exit 1; done` |
| **Full suite command** | `$gsd-audit-milestone 1.41` |
| **Estimated runtime** | Quick structural check under 2 seconds; milestone audit about 1 minute |

## Sampling Rate

- **After every task commit:** Run the quick structural check and `git diff --check` on changed planning files.
- **After the plan wave:** Run the phase metadata checks, then the full v1.41 milestone audit.
- **Before milestone archive:** The milestone audit must report no unsatisfied or orphaned requirement.
- **Max feedback latency:** 2 seconds for the local structural check.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 171-01-01 | 01 | 1 | DOC-03, GATE-05, CLOSE-04 | — | Requirement rows exist; frozen Phase 170 evidence remains byte-identical | structural | requirement row checks, exact-source path comparison, and `shasum -a 256 -c -` against pre-phase digests | ✅ existing shell tools | ✅ green |
| 171-01-02 | 01 | 1 | DOC-03, GATE-05, CLOSE-04 | — | Requirement IDs join across verification, summary, and REQUIREMENTS.md | structural | summary metadata extraction plus GSD state snapshot for Phase171 and one plan | ✅ existing GSD tools | ✅ green |

## Wave 0 Requirements

Existing GSD CLI, Node.js, and ripgrep cover all phase requirements; no new test infrastructure or fixtures are needed.

## Manual-Only Verifications

All phase behaviors have automated verification. No human UAT or new semantic decision is part of this phase.

## Validation Sign-Off

- [x] All tasks have `<automated>` verify commands with stated failing directions.
- [x] Sampling continuity: both tasks have an automated structural check.
- [x] Wave 0 covers all missing infrastructure references; none are missing.
- [x] No watch-mode flags.
- [x] Feedback latency is under 30 seconds.
- [x] `nyquist_compliant: true` set after task checks passed.

**Approval:** approved 2026-10-02

## Validation Audit 2026-10-02

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 3 requirement-to-verification cross-references |
| Escalated | 0 |

All planned verification items are deterministic record/source checks. No runtime behavior, service, or human UAT is in this phase.
