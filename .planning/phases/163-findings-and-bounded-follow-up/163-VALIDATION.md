---
phase: "163"
slug: "findings-and-bounded-follow-up"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-25"
---

# Phase 163 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Python standard library; documentation-contract checker (proposed) |
| **Config file** | None required |
| **Quick run command** | `python3 .planning/phases/163-findings-and-bounded-follow-up/check_findings.py` (after Wave 0 creates it) |
| **Full suite command** | Same focused checker; run the Phase 162 baseline checker only when its artifact changes |
| **Estimated runtime** | Under 30 seconds |

---

## Sampling Rate

- **After every task commit:** Run the focused checker once it exists; review diff and links
- **After every plan wave:** Run the focused checker and requirement traceability review
- **Before `$gsd-verify-work`:** Focused checker must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 163-01-01 | 01 | 1 | FIND-01, FIND-03 | T-163-01, T-163-02 | Bounded C-21 chronology; data-only checker; positive/negative contract fixtures | documentation contract | `python3 -m unittest discover -s .planning/phases/163-findings-and-bounded-follow-up -p 'test_check_findings.py' -v`; `python3 .planning/phases/163-findings-and-bounded-follow-up/check_findings.py --claims C-21` | ❌ W0 in tracer | ⬜ pending |
| 163-01-02 | 01 | 1 | FIND-01, FIND-03 | T-163-01, T-163-03 | Match receipt to source/oracle; secret-safe diagnosis versus repair claims | documentation contract | `python3 .planning/phases/163-findings-and-bounded-follow-up/check_findings.py --claims C-15,C-16,C-17,C-21 --stage triage` | ❌ created by 01-01 | ⬜ pending |
| 163-02-01 | 02 | 2 | FIND-01, FIND-02 | T-163-04 | Complete baseline coverage and independent materiality/rank factors | documentation contract | `python3 .planning/phases/163-findings-and-bounded-follow-up/check_findings.py --stage triage` | ❌ created by 01-01 | ⬜ pending |
| 163-02-02 | 02 | 2 | FIND-02, FIND-03 | T-163-05, T-163-06 | Real owner authority, event-based deferral, visible unresolved risk | documentation contract | `python3 .planning/phases/163-findings-and-bounded-follow-up/check_findings.py --stage dispositions` | ❌ created by 01-01 | ⬜ pending |
| 163-03-01 | 03 | 3 | CLOSE-01, CLOSE-02 | T-163-07, T-163-08 | Authorized bounded outcomes and owned claim-proof records | documentation contract | `python3 .planning/phases/163-findings-and-bounded-follow-up/check_findings.py` | ❌ created by 01-01 | ⬜ pending |
| 163-03-02 | 03 | 3 | CLOSE-01, CLOSE-02 | T-163-08, T-163-09 | Complete linkage and honest Phase 164 handoff | documentation contract | `python3 -m unittest discover -s .planning/phases/163-findings-and-bounded-follow-up -p 'test_check_findings.py' -v`; `python3 .planning/phases/163-findings-and-bounded-follow-up/check_findings.py` | ❌ created by 01-01 | ⬜ pending |

When a task amends the canonical baseline, reuse `python3 .planning/phases/162-whole-product-evidence-baseline/check_baseline.py --through 24 --full-coverage`. Selected-ID and earlier-stage results are explicitly partial; the no-argument findings command requires complete coverage, final qualification, and the handoff. All task commands have failing-direction statements in the plans. Structural success is not product proof, source-truth certification, owner approval, or readiness.

---

## Wave 0 Requirements

- [ ] `.planning/phases/163-findings-and-bounded-follow-up/check_findings.py` — checks finite cross-artifact invariants and discriminating negative fixtures for FIND-01 through CLOSE-02
- [ ] `.planning/phases/163-findings-and-bounded-follow-up/test_check_findings.py` — positive controls and discriminating negative fixtures; created with the first real C-21 tracer, not a separate foundation task
- [ ] Define the compact findings, claim-proof, and disposition layout in the first artifact slice

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|-----------|-------------------|
| Owner's explicit risk acceptance or business disposition | FIND-03 | This is an irreducible owner decision, not software behavior or UAT | Record the actual decision source; leave unresolved decisions visibly pending |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
