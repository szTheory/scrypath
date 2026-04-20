---
phase: 41
slug: federation-docs-contracts
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-20
---

# Phase 41 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix verify.phase41` |
| **Full suite command** | `mix test --exclude integration` |
| **Estimated runtime** | ~30–90 seconds (depends on focused file list) |

---

## Sampling Rate

- **After every task commit:** Run `mix verify.phase41`
- **After every plan wave:** Run `mix verify.phase41`
- **Before `/gsd-verify-work`:** `mix test --exclude integration` green
- **Max feedback latency:** ~120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 41-01-01 | 01 | 1 | FED-03 | — | N/A (build-only) | compile | `mix compile --warnings-as-errors` | ✅ | ⬜ pending |
| 41-01-02 | 01 | 1 | FED-03 | — | N/A | unit | `mix verify.phase41` | ✅ after W1 | ⬜ pending |
| 41-02-01 | 02 | 2 | FED-03 | — | N/A (markdown) | unit | `mix verify.phase41` | ✅ | ⬜ pending |
| 41-03-01 | 03 | 2 | FED-03 | — | N/A | unit | `mix verify.phase41` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements — no Wave 0 stubs.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| ExDoc readability | FED-03 | Not asserted in CI | `mix docs && open doc/index.html` optional |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
