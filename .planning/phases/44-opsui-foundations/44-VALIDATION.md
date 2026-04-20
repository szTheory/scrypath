---
phase: 44
slug: opsui-foundations
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-20
---

# Phase 44 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Elixir / ExUnit (library + OPSUI app) |
| **Config file** | `scrypath_ops/config/*.exs` (once app exists) |
| **Quick run command** | `cd scrypath_ops && mix compile` |
| **Full suite command** | `mix compile && cd scrypath_ops && mix test` |
| **Estimated runtime** | ~30–90 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd scrypath_ops && mix compile` when the task touched `scrypath_ops/`; otherwise `mix compile` from repo root.
- **After every plan wave:** Run `mix compile && cd scrypath_ops && mix test` (tests may be minimal until security plan adds ExUnit for prod guard).
- **Before `/gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 44-01-01 | 01 | 1 | OPSUI-09 | T-44-01 | N/A (layout) | shell | `test -d scrypath_ops && cd scrypath_ops && mix compile` | ⬜ W1 | ⬜ pending |
| 44-02-01 | 02 | 2 | OPSUI-06 | T-44-02 | N/A | grep | `rg -n "operator-ia" scrypath_ops/docs/operator-ia.md` | ⬜ W1 | ⬜ pending |
| 44-03-01 | 03 | 3 | OPSUI-07 | T-44-03 | session boundary | shell | `cd scrypath_ops && mix compile` | ⬜ W2 | ⬜ pending |
| 44-04-01 | 04 | 3 | OPSUI-08 | T-44-04 | fail-closed prod | unit | `cd scrypath_ops && mix test` | ⬜ W2 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scrypath_ops/test/**/*_test.exs` — minimal ExUnit proving prod fail-closed path (added in Plan 04 tasks).
- [ ] Existing infrastructure: root `mix compile` must stay green after doc-only edits.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| Browser reaches `/ops` in dev | OPSUI-07 | Needs running server | `cd scrypath_ops && mix phx.server`, open `/ops`, confirm stub page renders |
| Prod refusal with unset auth | OPSUI-08 | Env matrix | `MIX_ENV=prod` (or release) with `OPSUI_AUTH_MODE` unset—expect documented failure or absent routes |

---

## Validation Sign-Off

- [ ] All tasks have automated verify commands or manual table above
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
