---
phase: 14
slug: mix-tasks-and-guides
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-16
---

# Phase 14 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Mix |
| **Config file** | `mix.exs`, `test/test_helper.exs` |
| **Quick run command** | `mix test test/scrypath/mix_tasks/operator_tasks_test.exs test/scrypath/docs_contract_test.exs test/release/package_metadata_test.exs` |
| **Full suite command** | `mix verify.phase14` |
| **Estimated runtime** | ~30-45 seconds |

---

## Source Audit

### Goal Coverage

| Source | Item | Covered By | Status |
|--------|------|------------|--------|
| GOAL | Operators get thin `mix scrypath.*` ergonomics over the existing root APIs | `14-01-PLAN.md` | ✅ |
| GOAL | Developers get first-class sync-mode guides for `:inline`, `:oban`, and `:manual` | `14-02-PLAN.md` | ✅ |
| GOAL | Backend-native Meilisearch power stays namespaced and out of the common CLI/search surface | `14-01-PLAN.md`, `14-02-PLAN.md` | ✅ |
| GOAL | Maintainers can relate operator APIs, Mix tasks, and the release contract | `14-02-PLAN.md` | ✅ |

### Requirement Coverage

| Requirement | Planned In | Status |
|-------------|------------|--------|
| OPS-04 | `14-02-PLAN.md` | ✅ |
| SEAM-03 | `14-01-PLAN.md`, `14-02-PLAN.md` | ✅ |

### Research / Pattern Coverage

| Constraint or Pattern | Planned In | Status |
|-----------------------|------------|--------|
| Thin Mix task wrappers only | `14-01-PLAN.md` | ✅ |
| Exact task names lock to `status`, `failed`, `retry`, `reconcile` | `14-01-PLAN.md` | ✅ |
| Reindex visibility stays under reconcile, not a separate task | `14-01-PLAN.md` | ✅ |
| Human-readable CLI output only in Phase 14 | `14-01-PLAN.md`, `14-02-PLAN.md` | ✅ |
| One canonical sync-mode guide with explicit per-mode sections | `14-02-PLAN.md` | ✅ |
| One `mix verify.phase14` gate | `14-02-PLAN.md` | ✅ |
| Meilisearch-native power remains under `Scrypath.Meilisearch.*` | `14-01-PLAN.md`, `14-02-PLAN.md` | ✅ |

No unplanned source items found.

---

## Sampling Rate

- **After every task commit:** Run the focused command for the touched Phase 14 files
- **After every plan wave:** Run the relevant plan verification command
- **Before `$gsd-verify-work`:** Run `mix verify.phase14`
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 14-01-01 | 01 | 1 | SEAM-03 | T-14-01 / T-14-02 / T-14-03 | Status and failed-work tasks validate argv, delegate only through `Scrypath.*`, and summarize operator state without raw backend or queue payload leakage | unit | `mix test test/scrypath/mix_tasks/operator_tasks_test.exs` | ❌ Wave 0 | ⬜ pending |
| 14-01-02 | 01 | 1 | SEAM-03 | T-14-01 / T-14-02 / T-14-03 | Retry and reconcile tasks keep retry explicit, reconcile report-first, and avoid widening `Scrypath.search/3` or backend-native CLI behavior | unit/integration | `mix test test/scrypath/mix_tasks/operator_tasks_test.exs test/scrypath/operator/failed_work_test.exs test/scrypath/operator/reconcile_test.exs` | ✅ partial | ⬜ pending |
| 14-02-01 | 02 | 2 | OPS-04 | T-14-04 / T-14-05 | Guides and maintainer docs explicitly cover `:inline`, `:oban`, `:manual`, the new Mix tasks, and the release-support handoff without leaking backend-native surface | docs-contract | `mix test test/scrypath/docs_contract_test.exs test/release/package_metadata_test.exs` | ✅ partial | ⬜ pending |
| 14-02-02 | 02 | 2 | OPS-04 / SEAM-03 | T-14-04 / T-14-05 / T-14-06 | `mix verify.phase14` is auth-free, deterministic, and validates task tests, docs contract, package metadata, and docs build in one gate | phase verifier | `mix verify.phase14` | ❌ Wave 0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/scrypath/operator/failed_work_test.exs` — existing retry behavior contract
- [x] `test/scrypath/operator/reconcile_test.exs` — existing reconcile report-first contract
- [x] `test/scrypath/docs_contract_test.exs` — docs boundary enforcement baseline
- [x] `test/release/package_metadata_test.exs` — package metadata baseline
- [ ] `test/scrypath/mix_tasks/operator_tasks_test.exs` — new task delegation and output contract coverage
- [ ] `lib/mix/tasks/verify.phase14.ex` — new phase verifier gate
- [ ] `guides/operator-mix-tasks.md` — new operator guide covered by docs contract
- [ ] `docs/operator-support.md` — new maintainer support guide covered by docs contract

*Existing infrastructure already covers the operator boundary and public docs contract. Phase 14 adds the CLI task test file, the guide pages, and the phase verifier as the new Wave 0 artifacts.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Operator readability of task output in a real app shell | OPS-04 | Automated tests can assert stable strings, but a maintainer should still spot-check that the summaries remain concise and legible when pointed at a configured app | After implementing Wave 1, run each `mix scrypath.*` task against a local sample app or test fixture and confirm the output highlights mode, pending/failed state, retryability, and recommended actions without raw backend payloads |

---

## Validation Sign-Off

- [x] All tasks have an automated verify path or an explicit manual-only boundary
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 identifies the new task tests, guides, and verifier required before feature completion
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
