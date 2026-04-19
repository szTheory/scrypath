---
phase: 32
slug: planning-and-state-hygiene
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-18
validated: 2026-04-18
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
| 32-01-01 | 01 | 1 | AUDT-01 | T-32-DOC-01 | No misleading “open gap” claims | ExUnit | `mix test test/scrypath/docs_contract_test.exs` (`phase 32 AUDT-01` case) | ✅ | ✅ green |
| 32-01-02 | 01 | 1 | AUDT-01 | T-32-DOC-01 | STATE rows pointer-backed | ExUnit | same | ✅ | ✅ green |
| 32-01-03 | 01 | 1 | AUDT-01 | T-32-DOC-01 | REQ traceability honest | ExUnit | same | ✅ | ✅ green |
| 32-01-04 | 01 | 1 | AUDT-01 | T-32-DOC-01 | Milestone narrative aligned | ExUnit | same | ✅ | ✅ green |
| 32-01-05 | 01 | 1 | AUDT-01 | T-32-DOC-01 | Audit artifact scores + empty req gaps | ExUnit | same | ✅ | ✅ green |

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

- [x] All tasks have automated coverage via **`docs_contract_test.exs`** (`phase 32 AUDT-01 planning hygiene contracts`)
- [x] No watch-mode flags introduced
- [x] `nyquist_compliant: true` set after **`032-VERIFICATION.md`** passed and tests locked literals

**Approval:** complete

---

## Validation Audit 2026-04-18

| Metric | Count |
|--------|-------|
| Gaps found | 5 (per-task rows were pending while verification had passed) |
| Resolved | 5 (mapped to one ExUnit contract test + table refresh) |
| Escalated | 0 |
