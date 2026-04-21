---
phase: 46
slug: search-federation-honesty
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-21
---

# Phase 46 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution (Scrypath OPSUI / Elixir).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Phoenix `ConnCase` + `Phoenix.LiveViewTest`) |
| **Config file** | `scrypath_ops/config/test.exs` (existing) |
| **Quick run command** | `cd scrypath_ops && mix test test/scrypath_ops/search_playground_test.exs test/scrypath_ops_web/live/search_live_test.exs` |
| **Full suite command** | `cd scrypath_ops && mix test` |
| **Estimated runtime** | ~30–90 seconds (project size dependent) |

---

## Sampling Rate

- **After every task commit:** Run the **quick run command** when the task touched `search_playground`, `SearchLive`, or either test file; otherwise `mix compile` only.
- **After every plan wave:** Run **`cd scrypath_ops && mix test`**.
- **Before `/gsd-verify-work`:** Full **`mix test`** for **`scrypath_ops`** green.
- **Max feedback latency:** Target under 120 seconds on CI-class hardware.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 46-01-01 | 01 | 1 | OPSUI-04 | T-46-01 | Config bounds only; no query logging in new code | unit | `mix test test/scrypath_ops/search_playground_test.exs` | ✅ | ⬜ pending |
| 46-01-02 | 01 | 1 | OPSUI-04 | T-46-01 | Adapter default = real `Scrypath` only | unit | `mix test test/scrypath_ops/search_playground_test.exs` | ✅ | ⬜ pending |
| 46-02-01 | 02 | 2 | OPSUI-04, OPSUI-05 | T-46-02 | No raw query in telemetry metadata | manual grep + compile | `rg 'telemetry\\.execute\\(.*query' scrypath_ops/lib/scrypath_ops_web/live/search_live.ex`; `mix compile` | ✅ | ⬜ pending |
| 46-02-02 | 02 | 2 | OPSUI-05 | — | Inspector reads `ordered` only | LiveView | `mix test test/scrypath_ops_web/live/search_live_test.exs` | ✅ | ⬜ pending |
| 46-03-01 | 03 | 2 | OPSUI-04, OPSUI-05 | — | Copy contract pinned | LiveView | `mix test test/scrypath_ops_web/live/search_live_test.exs` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

- [x] ExUnit + Phoenix test stack present under **`scrypath_ops/`**
- [x] **`ConnCase`** and LiveView test patterns from phase 45 (**`posture_live_test.exs`**)

*No new framework install.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| Visual focal order | OPSUI-04 | Layout/spacing tokens need human skim | Dev server: open `/ops/search`, confirm strip → controls → results order matches **46-UI-SPEC** |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or explicit grep acceptance
- [ ] Sampling continuity: compile or test between tasks
- [ ] No watch-mode flags in verification commands
- [ ] `nyquist_compliant: true` set after wave 1–2 green

**Approval:** pending
