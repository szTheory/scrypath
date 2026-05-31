---
phase: 103
slug: e-commerce-host-app-foundation
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-30
---

# Phase 103 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | test/test_helper.exs |
| **Quick run command** | `mix test --stale` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test --stale`
- **After every plan wave:** Run `mix test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 103-01-01 | 01 | 1 | APP-01, APP-02 | — | N/A | unit | `mix test test/scrypath_ecommerce/catalog_test.exs` | ❌ W0 | ⬜ pending |
| 103-02-01 | 02 | 2 | APP-02 | — | N/A | unit | `mix test test/scrypath_ecommerce/catalog_test.exs` | ❌ W0 | ⬜ pending |
| 103-03-01 | 03 | 3 | APP-03 | — | N/A | unit | `mix test test/scrypath_ecommerce_web/controllers/e2e_controller_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/scrypath_ecommerce/catalog_test.exs` — stubs for APP-02
- [ ] `test/scrypath_ecommerce_web/controllers/e2e_controller_test.exs` — stubs for APP-03

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | All phase behaviors have automated verification. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-30