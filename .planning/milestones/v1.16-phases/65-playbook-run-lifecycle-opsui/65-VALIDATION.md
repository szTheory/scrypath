---
phase: 65
slug: playbook-run-lifecycle-opsui
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-22
---

# Phase 65 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17+) |
| **Config file** | `scrypath_ops/config/config.exs` (test env), `scrypath_ops/test/test_helper.exs` |
| **Quick run command** | `mix test scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` |
| **Full suite command** | `mix verify.opsui` |
| **Estimated runtime** | ~30–120 seconds (machine dependent) |

---

## Sampling Rate

- **After every task commit:** Run the quick LiveView test path above when the task touched `PlaybookLive` or playbook tests.
- **After every plan wave:** Run `mix verify.opsui` when any plan modified `scrypath_ops/` application or test code.
- **Before `/gsd-verify-work`:** Full `mix verify.opsui` must be green.
- **Max feedback latency:** Target under 3 minutes for quick path on laptop CI class hardware.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 65-01-01 | 01 | 1 | OPS3-01 | — | N/A | unit | `mix test scrypath_ops/test/scrypath_ops/playbook/run_failure_test.exs` | ⬜ W0 | ⬜ pending |
| 65-02-01 | 02 | 2 | OPS3-01 | — | Cancel does not leak partial secrets in assigns | LV | `mix test scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` | ✅ | ⬜ pending |
| 65-03-01 | 03 | 3 | OPS3-02 | — | Copy map allowlisted — no raw env | LV | `mix test scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` | ✅ | ⬜ pending |
| 65-04-01 | 04 | 4 | OPS3-01, OPS3-02 | — | N/A | integration | `mix verify.opsui` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scrypath_ops/test/scrypath_ops/playbook/run_failure_test.exs` — unit tests for enrichment + doc map (created in Plan 01 if missing).
- [ ] Existing `SearchPlaygroundStubAdapter` + `:search_stub_variant` used for forced failure paths.

*Wave 0 is satisfied once Plan 01 adds the unit test file.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| Doc link opens in browser | OPS3-02 | HTTP client not in unit tests | Click primary link from failure fixture; confirm 200 and anchor present |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency acceptable on representative hardware
- [ ] `nyquist_compliant: true` set in frontmatter when phase execution completes

**Approval:** pending
