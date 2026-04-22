---
phase: 62
slug: playground-capture-and-playbook-catalog
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-22
---

# Phase 62 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution (Elixir / ExUnit).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `scrypath_ops/config/test.exs` |
| **Quick run command** | `mix test scrypath_ops/test/scrypath_ops/playbook/v1_test.exs scrypath_ops/test/scrypath_ops/playbook/store_test.exs` |
| **Full suite command** | `mix verify.opsui` |
| **Estimated runtime** | ~30–120 seconds (machine dependent) |

---

## Sampling Rate

- **After every task commit:** Run the **quickest** relevant `mix test path/to/file_test.exs` named in that plan’s verification.
- **After every plan wave:** Run **quick run command** above (or broader path set listed in the wave’s plans).
- **Before `/gsd-verify-work`:** `mix verify.opsui` must exit **0**.
- **Max feedback latency:** Target under **120s** on CI-class hardware for quick command.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 62-01-01 | 01 | 1 | OPS2-03 | T-62-01 | No atom keys from JSON; unknown keys rejected | unit | `mix test scrypath_ops/test/scrypath_ops/playbook/v1_test.exs` | ✅ | ⬜ pending |
| 62-02-01 | 02 | 1 | OPS2-02 | T-62-02 | Basename-only paths; no traversal | unit | `mix test scrypath_ops/test/scrypath_ops/playbook/store_test.exs` | ✅ | ⬜ pending |
| 62-03-01 | 03 | 2 | OPS2-01 | T-62-03 | Capture uses validated dispatch inputs only | integration | `mix test scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs` | ✅ | ⬜ pending |
| 62-04-01 | 04 | 3 | OPS2-02, OPS2-03 | T-62-04 | Typed confirm for destructive ops; no silent overwrite on rename | integration | `mix test scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Existing ExUnit + `mix verify.opsui` cover the repo — **no new framework install**.

*Wave 0: existing infrastructure covers phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual hierarchy vs honesty panel | OPS2-01 | LV tests do not assert pixel-perfect layout | Open `/ops/search` in dev: confirm capture card sits below honesty panel per **62-UI-SPEC.md** |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency under target
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
