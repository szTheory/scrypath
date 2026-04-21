---
phase: 48
slug: ia-and-jtbd-alignment
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-21
---

# Phase 48 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution (ScrypathOps / Elixir).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Phoenix 1.8 / LiveView 1.1) |
| **Config file** | `scrypath_ops/config/test.exs` |
| **Quick run command** | `cd scrypath_ops && mix test test/scrypath_ops_web/operator_ia_contract_test.exs` |
| **Full suite command** | `cd scrypath_ops && mix test` |
| **Estimated runtime** | ~30–90 seconds (local; depends on DB setup) |

---

## Sampling Rate

- **After every task commit:** Run the **quick** command when the task only touches contract tests; otherwise run **`cd scrypath_ops && mix test`** for tasks touching LiveViews or router.
- **After every plan wave:** Run **`cd scrypath_ops && mix test`** (full suite).
- **Before `/gsd-verify-work`:** Full suite green.
- **Max feedback latency:** 120 seconds (CI may vary).

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 48-01-01 | 01 | 1 | OPSUX-01 | T-48-01 | Nav labels/paths match IA; no new auth surface | unit | `cd scrypath_ops && mix test test/scrypath_ops_web/operator_ia_contract_test.exs` | ✅ | ⬜ pending |
| 48-01-02 | 01 | 1 | OPSUX-01 | T-48-01 | Same | unit | `cd scrypath_ops && mix test` | ✅ | ⬜ pending |
| 48-02-01 | 02 | 2 | OPSUX-01 | T-48-01 | Doc fence matches code; CI fails on drift | unit + mix | `cd scrypath_ops && mix test && mix scrypath_ops.check_operator_ia` | ⬜ W0 | ⬜ pending |
| 48-03-01 | 03 | 2 | OPSUX-02 | T-48-02 | Read-only copy; no write verbs | LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/live/posture_live_test.exs` | ⬜ W0 | ⬜ pending |
| 48-03-02 | 03 | 2 | OPSUX-02 | T-48-02 | Same | integration | `cd scrypath_ops && mix test` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- **Existing infrastructure covers all phase requirements** — `scrypath_ops` already has ExUnit, Ecto test DB setup via `mix test` alias, and `operator_ia_contract_test.exs`. No new framework install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| On-call readability of posture headline | OPSUX-02 | Copy tone and scannability | Start dev server, open `/ops/posture`, confirm headline + ≤5 next checks read clearly for allowlist empty vs healthy grid |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: contract tests between substantive edits
- [x] Wave 0 covers all MISSING references (none required)
- [x] No watch-mode flags
- [x] Feedback latency target under 120s for local `mix test`
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution
