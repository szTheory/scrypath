---
phase: 25
slug: settings-hot-apply-narrow
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-17
---

# Phase 25 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution (Elixir / ExUnit).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17+) |
| **Config file** | `test/test_helper.exs` (`:integration` tag + `SCRYPATH_INTEGRATION`) |
| **Quick run command** | `mix test test/scrypath/meilisearch/settings_test.exs test/mix/tasks/scrypath_settings_hot_apply_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30–120s (full suite; integration +60s when enabled) |

---

## Sampling Rate

- **After every task commit:** Run the **quick run command** for files touched by that plan.
- **After wave 1 (plan 01):** `mix test test/scrypath/meilisearch/settings_test.exs`
- **After wave 2 (plans 02–03):** Quick run + `mix test test/scrypath/meilisearch/settings_hot_apply_integration_test.exs` when `SCRYPATH_INTEGRATION=1`
- **Before `/gsd-verify-work`:** `mix format --check-formatted` and `mix test` green

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 25-01-01 | 01 | 1 | TUNE14-01 | T-25-API | No HTTP without ack + allowlist | unit | `mix test test/scrypath/meilisearch/settings_test.exs` | ✅ | ⬜ pending |
| 25-01-02 | 01 | 1 | TUNE14-01 | T-25-API | Telemetry emits without secrets | unit | grep + `mix test` subset | ✅ | ⬜ pending |
| 25-02-01 | 02 | 2 | TUNE14-01 | T-25-CLI | `--ack-live` maps to ack opt only | unit | `mix test test/mix/tasks/scrypath_settings_hot_apply_test.exs` | ❌ W0 | ⬜ pending |
| 25-02-02 | 02 | 2 | TUNE14-01 | T-25-API | Live Meilisearch PATCH + wait | integration | `SCRYPATH_INTEGRATION=1 mix test ...integration...` | ❌ W0 | ⬜ pending |
| 25-03-01 | 03 | 2 | TUNE14-02 | — | Docs only | doc | `grep` anchors in `guides/relevance-tuning.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing ExUnit + `MeilisearchIntegration` cover Meilisearch HTTP — no new framework install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Production `release eval` one-liner | TUNE14-02 | Needs real release node | Run eval snippet from guide against staging index with API key in env |

*If none for code paths: "Automated coverage sufficient for library CI."*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or documented manual row
- [ ] Sampling continuity: settings tests run after each wave touching `Settings`
- [ ] No watch-mode flags in verify commands
- [ ] `nyquist_compliant: true` set in frontmatter when phase executes

**Approval:** pending
