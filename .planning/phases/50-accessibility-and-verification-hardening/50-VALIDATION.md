---
phase: 50
slug: accessibility-and-verification-hardening
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-21
---

# Phase 50 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix.LiveViewTest (Phoenix 1.7+) |
| **Config file** | `scrypath_ops/config/test.exs` |
| **Quick run command** | `cd scrypath_ops && mix test test/scrypath_ops_web/live/<one>_live_test.exs` |
| **Full suite command** | `mix verify.opsui` (repo root) |
| **Estimated runtime** | ~60–120 seconds (full ops app tests; varies by machine) |

---

## Sampling Rate

- **After every task commit:** Run the smallest relevant `mix test` path touched by that task (single file or `--only` tag when tags exist).
- **After every plan wave:** Run `mix verify.opsui` from repo root.
- **Before `/gsd-verify-work`:** `mix verify.opsui` must be green.
- **Max feedback latency:** 180 seconds for full verify (revisit if CI budget changes).

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 50-XX-01 | TBD | 1 | OPSUX-06 | — | N/A (read-only ops UI) | integration | `cd scrypath_ops && mix test test/scrypath_ops_web/ops_a11y_contract_test.exs` (planned path) | ❌ W0 | ⬜ pending |
| 50-XX-02 | TBD | 1 | OPSUX-07 | — | N/A | integration | `mix verify.opsui` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] New **`ops_a11y_contract_test.exs`** (or equivalent name from plans) — stubs or first assertions for OPSUX-06 DOM contracts on the four critical `/ops` routes.
- [ ] ExUnit **`:opsui_a11y`** tag applied to new a11y contract tests (enables `mix test --only opsui_a11y` once landed).

*Wave 0 closes when the new contract file exists and at least one green assertion runs in CI.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| Screen reader + keyboard pass on operator spine | OPSUX-06 | AT behavior and reading order are not fully encoded in server HTML snapshots | Follow **50-CONTEXT** D-22: posture → failed-sync → sync/drift → search; record outcome in **`50-VERIFICATION.md`** |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s for full verify
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
