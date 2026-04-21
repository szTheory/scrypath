---
phase: 49
slug: visual-hierarchy-theming-and-phoenix-ergonomics
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-21
---

# Phase 49 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17+) |
| **Config file** | `scrypath_ops/test/test_helper.exs` |
| **Quick run command** | `cd scrypath_ops && mix test test/scrypath_ops_web/ops_shell_contract_test.exs` |
| **Full suite command** | `cd scrypath_ops && mix test` |
| **Estimated runtime** | ~30–120 seconds (environment dependent) |

---

## Sampling Rate

- **After every task commit:** Run `cd scrypath_ops && mix compile` and the **quick** test path when tests exist for touched behavior.
- **After every plan wave:** Run `cd scrypath_ops && mix test`.
- **Before `/gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** Target under 120s for full `mix test` on developer laptop.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 49-01-01 | 01 | 1 | OPSUX-03 | T-49-01 / — | Read-only roadmap/docs edits | compile | `cd scrypath_ops && mix compile` | ✅ | ⬜ pending |
| 49-01-02 | 01 | 1 | OPSUX-03 | — | N/A | compile | `cd scrypath_ops && mix compile` | ✅ | ⬜ pending |
| 49-02-01 | 02 | 2 | OPSUX-04 | T-49-02 / — | No new external endpoints | compile + unit | `cd scrypath_ops && mix test test/scrypath_ops_web/theme_contract_test.exs` (if introduced) | ❌ W0 | ⬜ pending |
| 49-03-01 | 03 | 3 | OPSUX-03 | — | N/A | LiveViewTest | `cd scrypath_ops && mix test test/scrypath_ops_web/live/` | ✅ | ⬜ pending |
| 49-04-01 | 04 | 4 | OPSUX-05 | — | N/A | unit | `cd scrypath_ops && mix test test/scrypath_ops_web/ops_shell_contract_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs` — stubs or first cases for structural `/ops` wiring (created in Plan 04 unless pulled earlier).

*Existing infrastructure: `operator_ia_contract_test.exs`, LiveView tests under `test/scrypath_ops_web/` — extend, do not fork IA assertions.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Light/dark/system contrast | OPSUX-04 | Perceptual + OS integration | Visit `/ops/posture`, `/ops/failed-sync`, `/ops/sync-drift`, `/ops/search`; toggle **system / light / dark**; confirm readable panels, borders, focus rings. |
| First paint flash | OPSUX-04 | Browser paint timing | Hard-refresh with throttling: theme should match stored/OS before content flash. |

---

## Validation Sign-Off

- [ ] All tasks have `<verify>` or documented manual steps
- [ ] Sampling continuity: compile/test between waves
- [ ] No watch-mode flags in commands
- [ ] `nyquist_compliant: true` set in frontmatter when phase execution completes

**Approval:** pending
