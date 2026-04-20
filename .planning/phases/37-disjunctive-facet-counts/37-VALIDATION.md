---
phase: 37
slug: disjunctive-facet-counts
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-19
---

# Phase 37 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `mix.exs` test profile |
| **Quick run command** | `mix compile --warnings-as-errors` |
| **Full suite command** | `mix test` |
| **Focused gate command** | `mix verify.phase37` (created in Plan 02) |
| **Estimated runtime** | ~30–120 seconds (machine dependent) |

---

## Sampling Rate

- **After every task commit:** Run the task’s listed `mix test` path or `mix compile --warnings-as-errors`
- **After every plan wave:** Run `mix verify.phase37`
- **Before `/gsd-verify-work`:** `mix test` full suite green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 37-01-01 | 01 | 1 | FACET-02 | T-37-01 / — | Pure functions; no user-controlled eval | unit | `mix test test/scrypath/facets/disjunctive_test.exs` | ⬜ W0 | ⬜ pending |
| 37-01-02 | 01 | 1 | FACET-02 | — | N/A | unit | `mix test test/scrypath/facets/disjunctive_test.exs` | ⬜ W0 | ⬜ pending |
| 37-02-01 | 02 | 1 | FACET-02 | — | Docs only | contract | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |
| 37-02-02 | 02 | 1 | FACET-02 | — | Docs only | contract | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |
| 37-02-03 | 02 | 1 | FACET-02 | — | N/A | integration | `mix verify.phase37` | ⬜ W0 | ⬜ pending |

---

## Wave 0 Requirements

- [ ] `test/scrypath/facets/disjunctive_test.exs` — stubs or full tests for merge helpers (Plan 01 creates)
- [ ] `lib/mix/tasks/verify.phase37.ex` — thin verify entry (Plan 02)

*Wave 0 completes when Plan 01’s first task adds the test file path.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| None baseline | — | All behaviors target ExUnit + docs contract | If executor adds `@tag :meilisearch` live test, document one-time index setup in that test module only |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
