---
phase: 57
slug: evidence-triage-and-b1-scope-lock
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-21
---

# Phase 57 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (existing) — Phase 57 does **not** add tests |
| **Config file** | `mix.exs` (unchanged for this phase) |
| **Quick run command** | `mix format --check-formatted` |
| **Full suite command** | `mix test --exclude integration` (optional sanity if any Elixir file touched) |
| **Estimated runtime** | < 120 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix format --check-formatted` when any `.ex` / `.exs` file was modified; otherwise **grep + read** acceptance only.
- **After every plan wave:** Full **grep** checklist from **`<verification>`** in **57-PLAN-01.md**.
- **Before `/gsd-verify-work`:** All **EVID-01** / **STATE** / **REQUIREMENTS** strings from acceptance criteria present.
- **Max feedback latency:** under 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 57-01-01 | 01 | 1 | EVID-01 | — | N/A (docs) | grep | `rg -n 'EVID-57-01' .planning/EVID-01-b1-v1.14.md` | ✅ | ⬜ pending |
| 57-01-02 | 01 | 1 | EVID-01 | — | N/A | grep | `rg -n 'LIB-01' .planning/EVID-01-b1-v1.14.md` | ✅ | ⬜ pending |
| 57-01-03 | 01 | 1 | EVID-01 | — | N/A | grep | `rg -n 'EVID-01-b1-v1.14' CONTRIBUTING.md` | ✅ | ⬜ pending |
| 57-01-04 | 01 | 1 | EVID-01 | — | N/A | grep | `rg -n 'Evidence:' .github/pull_request_template.md` | ✅ | ⬜ pending |
| 57-01-05 | 01 | 1 | EVID-01 | — | N/A | grep | `rg -n 'lib/scrypath/' CODEOWNERS` | ✅ | ⬜ pending |
| 57-01-06 | 01 | 1 | EVID-01 | — | N/A | grep | `rg -n 'EVID-01-b1-v1.14' .planning/REQUIREMENTS.md` | ✅ | ⬜ pending |
| 57-01-07 | 01 | 1 | EVID-01 | — | N/A | grep | `rg -n 'B1 scope frozen' .planning/STATE.md` | ✅ | ⬜ pending |
| 57-01-08 | 01 | 1 | EVID-01 | — | N/A | grep | `rg -n 'EVID-01-b1-v1.14' .planning/ROADMAP.md` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

**Existing infrastructure covers all phase requirements.** No new **`mix test`** modules for Phase 57.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| Async maintainer review | EVID-01 | Human judgment on evidence quality | Maintainer confirms **48–72h** review window satisfied before merge (**D-09**). |

---

## Validation Sign-Off

- [ ] All tasks have grep-verifiable acceptance criteria
- [ ] Sampling continuity: doc tasks use **grep**, not watch-mode
- [ ] No watch-mode flags
- [ ] Feedback latency under 120s
- [ ] `nyquist_compliant: true` set in frontmatter after execution

**Approval:** pending
