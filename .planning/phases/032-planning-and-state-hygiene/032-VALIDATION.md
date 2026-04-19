---
phase: 32
slug: planning-and-state-hygiene
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-18
---

# Phase 32 — Validation Strategy

> Per-phase validation contract for **AUDT-01** — `.planning/` documentation triage only.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (existing repo) |
| **Config file** | `config/test.exs` (unchanged) |
| **Quick run command** | `mix test test/scrypath/docs_contract_test.exs` |
| **Full suite command** | `mix test` (optional before milestone close; not required every task for this phase) |
| **Estimated runtime** | ~30–120 seconds depending on machine |

---

## Sampling Rate

- **After every task commit:** `mix test test/scrypath/docs_contract_test.exs`
- **After plan wave 1 complete:** same quick command + grep audit from plan acceptance criteria
- **Before `/gsd-verify-work`:** quick command green; `STATE.md` has **zero** `pending_triage_v1_6`
- **Max feedback latency:** ~120s

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 32-01-01 | 01 | 1 | AUDT-01 | T-32-DOC-01 | No misleading “open gap” claims | grep + read | `rg 'pending_triage_v1_6' .planning/STATE.md` → expect 0 post-task | ✅ | ⬜ pending |
| 32-01-02 | 01 | 1 | AUDT-01 | T-32-DOC-01 | STATE rows pointer-backed | read + test | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |
| 32-01-03 | 01 | 1 | AUDT-01 | T-32-DOC-01 | REQ traceability honest | grep + test | `grep -F '[x] **AUDT-01**' .planning/REQUIREMENTS.md` | ✅ | ⬜ pending |
| 32-01-04 | 01 | 1 | AUDT-01 | T-32-DOC-01 | Milestone narrative aligned | grep | `rg 'pending_triage_v1_6' .planning/MILESTONES.md` → 0 or explanatory | ✅ | ⬜ pending |
| 32-01-05 | 01 | 1 | AUDT-01 | T-32-DOC-01 | Audit artifact not stale | read | Manual diff vs STATE | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red*

---

## Wave 0 Requirements

- [x] **Existing infrastructure** — `docs_contract_test.exs` already guards CONTRIBUTING/README contracts; no new Wave 0 stubs required.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Readable one-line reasons | AUDT-01 | Subjective brevity | Skim `STATE.md` §Deferred Items — each row ≤ ~1 line reason + pointer |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` or grep verify equivalents
- [ ] No watch-mode flags introduced
- [ ] `nyquist_compliant: true` set in frontmatter after phase VERIFICATION.md passes

**Approval:** pending
