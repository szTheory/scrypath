---
phase: 52
slug: actionable-errors-and-onboarding-pitfalls
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-21
---

# Phase 52 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17+) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/scrypath/docs_contract_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~60–120 seconds (project-dependent) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/scrypath/docs_contract_test.exs` when markdown, `mix.exs`, or `docs_contract_test.exs` changed; otherwise run the narrowest test file touched by the task.
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 52-01-01 | 01 | 1 | ONBD-05 | T-52-01 | No secrets in examples | unit | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |
| 52-01-02 | 01 | 1 | ONBD-05 | T-52-01 | N/A | unit | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |
| 52-02-01 | 02 | 2 | ONBD-04 | T-52-02 | Error text has no credentials | unit | `mix test test/scrypath/search_many_test.exs` (and related) | ✅ | ⬜ pending |
| 52-02-02 | 02 | 2 | ONBD-04 | T-52-02 | N/A | unit | `mix test test/scrypath/` | ✅ | ⬜ pending |
| 52-03-01 | 03 | 2 | ONBD-06 | T-52-03 | N/A | unit | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |
| 52-03-02 | 03 | 2 | ONBD-06 | T-52-03 | N/A | manual | `mix help scrypath.status` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing ExUnit infrastructure covers the phase; no new framework install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Mix task help rendering | ONBD-06 | Mix CLI layout | Run `mix help scrypath.status` and confirm `guides/golden-path.md` and `guides/sync-modes-and-visibility.md` appear in the moduledoc summary. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or documented manual step
- [ ] Sampling continuity: doc tasks run `docs_contract_test`
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
