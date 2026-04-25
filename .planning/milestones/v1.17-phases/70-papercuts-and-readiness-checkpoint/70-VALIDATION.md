---
phase: 70
slug: papercuts-and-readiness-checkpoint
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-22
---

# Phase 70 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via `mix test`, plus bounded planning-file shell checks |
| **Config file** | `test/test_helper.exs` via root `mix test` |
| **Quick run command** | `mix test test/scrypath/docs_contract_test.exs` |
| **Full suite command** | `mix verify.adopter && mix test --exclude integration` |
| **Estimated runtime** | ~60-120 seconds |

---

## Sampling Rate

- **After every task commit:** Run the narrowest command from the per-task map below.
- **After every plan wave:** Run `mix test test/scrypath/docs_contract_test.exs`.
- **Before `$gsd-verify-work`:** Run `mix verify.adopter` and `mix test --exclude integration`.
- **Max feedback latency:** 120 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 70-01-01 | 01 | 1 | INTG-05 | T-70-01 | Repo-vs-package example boundary stays explicit across public docs and package facts | contract | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |
| 70-01-02 | 01 | 1 | INTG-05 | T-70-02 | Support guide keeps narrow Ecto/Phoenix expectation anchors without broadening the support promise | contract | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |
| 70-01-03 | 01 | 1 | INTG-05 | T-70-03 | Maintainer docs teach `mix verify.adopter` before specialist verification commands | contract | `mix verify.adopter` | ✅ | ⬜ pending |
| 70-02-01 | 02 | 2 | INTG-06 | T-70-04 | Rolling planning truth updates only after papercut evidence exists | unit | `rg -n "INTG-05|INTG-06|Phase 70|v1.17|readiness checkpoint|outside integration feedback" .planning/PROJECT.md .planning/ROADMAP.md .planning/REQUIREMENTS.md .planning/STATE.md .planning/milestone-candidates.md` | ✅ planned | ⬜ pending |
| 70-02-02 | 02 | 2 | INTG-06 | T-70-05, T-70-06 | Frozen `v1.17` archive trio exists and records the readiness-checkpoint plus outside-feedback-next verdict | unit | `test -f .planning/milestones/v1.17-ROADMAP.md && test -f .planning/milestones/v1.17-REQUIREMENTS.md && test -f .planning/milestones/v1.17-MILESTONE-AUDIT.md && rg -n "v1.17|INTG-05|INTG-06|readiness checkpoint|outside integration feedback|outside_feedback_next" .planning/milestones/v1.17-ROADMAP.md .planning/milestones/v1.17-REQUIREMENTS.md .planning/milestones/v1.17-MILESTONE-AUDIT.md` | ✅ planned | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing docs-contract and maintainer verify infrastructure cover the three papercut recurrence guards.
- [x] Rolling planning and archive verification can be validated with bounded shell checks; no new harness is required.
- [x] Validation stays inside docs/example/verify/planning surfaces and does not require service-backed integration expansion.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Read the `v1.17-MILESTONE-AUDIT.md` verdict for wording honesty before milestone close | INTG-06 | The archive needs a human judgment that the outside-feedback-next conclusion matches the actual evidence, not just the presence of strings | Review the audit body after creation and confirm it explains why external integration feedback is or is not the next default step |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-22
