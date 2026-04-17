---
phase: 27
slug: schema-index-drift-report
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-17
---

# Phase 27 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17+) |
| **Config file** | `mix.exs`, `test/test_helper.exs` |
| **Quick run command** | `mix format --check-formatted && mix compile --warnings-as-errors` |
| **Full suite command** | `mix test test/scrypath/operator/index_contract_drift_test.exs` (plus any paths added in PLAN frontmatter) |
| **Estimated runtime** | ~15–45 seconds |

---

## Sampling Rate

- **After every task commit:** Run the quick run command
- **After every plan wave:** Run the focused `mix test` path for Phase 27
- **Before `/gsd-verify-work`:** Operator test subtree green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 27-01-01 | 01 | 1 | DRIFT15-01 | T-27-API | No mutation calls from report path | unit | `mix test test/scrypath/operator/index_contract_drift_test.exs --only line:NN` | ✅ W0 | ⬜ pending |
| 27-01-02 | 01 | 1 | DRIFT15-02 | T-27-API | Named dimensions in struct | unit | same file | ✅ W0 | ⬜ pending |
| 27-01-03 | 01 | 1 | OPS15-01 | T-27-API | Delegate on `Scrypath` | unit | grep + compile | ✅ W0 | ⬜ pending |
| 27-02-01 | 02 | 2 | OPS15-01 | T-27-OPT | Default reconcile unchanged | unit | `mix test` (reconcile tests) | ✅ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] ExUnit + existing `Scrypath.Config` test patterns — no new framework install
- [x] Existing searchable schema fixtures under `test/support` / test schemas — reuse for drift scenarios

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Live cluster shape quirks | DRIFT15-02 | Vendor returns extra keys | Spot-check against staging Meilisearch once after automated tests pass |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency under target
- [ ] `nyquist_compliant: true` set in frontmatter after execution

**Approval:** pending
