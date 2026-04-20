---
phase: 39
slug: federation-scoring-weights
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-20
---

# Phase 39 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17+) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/scrypath/multi_search/entries_test.exs test/scrypath/search_many_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~60 seconds (project size dependent) |

---

## Sampling Rate

- **After every task commit:** Run `mix compile --warnings-as-errors`
- **After every plan wave:** Run the quick test command above
- **Before `/gsd-verify-work`:** `mix test` must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 39-01-01 | 01 | 1 | FED-01 | T-39-01-01 / — | Reject non-finite weights before HTTP | unit | `mix test test/scrypath/multi_search/entries_test.exs` | ✅ | ⬜ pending |
| 39-01-02 | 01 | 1 | FED-01 | T-39-01-02 / — | No silent wrong-rank sequential path | unit | `mix test test/scrypath/search_many_test.exs` | ✅ | ⬜ pending |
| 39-02-01 | 02 | 2 | FED-01 | T-39-02-01 / — | String keys only in decode path | unit | `mix test test/scrypath/meilisearch/federated_decode_test.exs` (create or extend) | ❌ W0 → add | ⬜ pending |
| 39-02-02 | 02 | 2 | FED-01 | — / — | N/A | unit | `mix test test/scrypath/search_many_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing ExUnit + `FakeBackend` cover multi-search; no new framework install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| Live Meilisearch weighted merge | FED-01 | Requires running cluster | Optional local smoke against real `/multi-search` — not required for library CI if Req.Test covers contract. |

*Primary behaviors are automated via `FakeBackend` and unit tests.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency under budget
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
