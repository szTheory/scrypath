---
phase: 60
slug: playbook-liveview-and-ia
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-22
---

# Phase 60 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution (ScrypathOps / ExUnit).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17+) |
| **Config file** | `scrypath_ops/test/test_helper.exs`, `scrypath_ops/mix.exs` |
| **Quick run command** | `cd scrypath_ops && mix test test/scrypath_ops/playbook/ test/scrypath_ops_web/live/playbook_live_test.exs` |
| **Full suite command** | `cd scrypath_ops && mix test` |
| **Estimated runtime** | ~30–120 seconds (environment dependent) |

---

## Sampling Rate

- **After every task commit:** Run quick command covering new/changed modules.
- **After every plan wave:** Run `cd scrypath_ops && mix test` for the app.
- **Before `/gsd-verify-work`:** Full suite green; `mix scrypath_ops.check_nav_contract` exits 0.
- **Max feedback latency:** Target under 3 minutes on laptop CI class hardware.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 60-01-01 | 01 | 1 | OPS-PB-02 | T-path | Basename + root containment only | unit | `mix test test/scrypath_ops/playbook/store_test.exs` | ⬜ W0 | ⬜ pending |
| 60-01-02 | 01 | 1 | OPS-PB-02 | T-runner | No dispatch without validate | unit | `mix test test/scrypath_ops/playbook/runner_test.exs` | ⬜ W0 | ⬜ pending |
| 60-02-01 | 02 | 2 | OPS-PB-02 | T-xss | Escaped preview / no raw HTML | feature | `mix test test/scrypath_ops_web/live/playbook_live_test.exs` | ⬜ W0 | ⬜ pending |
| 60-03-01 | 03 | 3 | OPS-PB-04 | T-nav | Nav JSON matches `Nav.primary/0` | mix | `mix scrypath_ops.check_nav_contract` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scrypath_ops/test/scrypath_ops/playbook/store_test.exs` — path safety for workspace root
- [ ] `scrypath_ops/test/scrypath_ops/playbook/runner_test.exs` — dispatch wiring with **`SearchPlaygroundStubAdapter`**
- [ ] `scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` — mount, honesty strip, stub run

*Create missing files in Plan 01 / 02 waves as listed in PLAN.md tasks.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Save → reload → run on real adapter | OPS-PB-02 (1) | Needs configured Meilisearch / schemas | In dev, set env + backend, save playbook JSON, reload page, run; confirm hits or honest errors |

---

## Validation Sign-Off

- [ ] All tasks have `<acceptance_criteria>` with `mix test` or `mix scrypath_ops.check_nav_contract`
- [ ] Sampling continuity: no three consecutive tasks without automated verify
- [ ] Wave 0 covers new playbook modules
- [ ] No watch-mode flags in commands
- [ ] `nyquist_compliant: true` set in frontmatter when phase execution completes

**Approval:** pending
