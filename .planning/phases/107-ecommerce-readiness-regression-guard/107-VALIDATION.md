---
phase: 107
slug: ecommerce-readiness-regression-guard
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-31
---

# Phase 107 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs`; `examples/scrypath_ecommerce/test/test_helper.exs` |
| **Quick run command** | `mix test examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/e2e_controller_test.exs` |
| **Full suite command** | `mix verify.phase107` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/e2e_controller_test.exs`
- **After every plan wave:** Run `mix verify.phase107`
- **Before `$gsd-verify-work`:** `mix verify.phase107` must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 107-01-01 | 01 | 1 | E2E-01 | T-107-01 | `/dev/e2e/search-visible` preserves `tenant_id` when adding `category_id` | controller integration | `mix test examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/e2e_controller_test.exs` | ✅ | ⬜ pending |
| 107-01-02 | 01 | 1 | E2E-01 | T-107-01 / T-107-02 | `mix verify.phase107` runs the focused regression guard service-free | Mix task self-test | `mix test test/mix/tasks/verify.phase107_test.exs` | ❌ W0 | ⬜ pending |
| 107-01-03 | 01 | 1 | E2E-01 | T-107-01 / T-107-02 | Phase gate passes only after the controller regression and task self-test pass | phase gate | `mix verify.phase107` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `lib/mix/tasks/verify.phase107.ex` — focused phase gate task file.
- [ ] `test/mix/tasks/verify.phase107_test.exs` — source/command contract tests for the new task.
- [ ] `mix.exs` — `cli.preferred_envs` entry for `verify.phase107` if the new root task needs test env routing.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | E2E-01 | All phase behavior should be covered by focused automated tests | N/A |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
