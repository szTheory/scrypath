---
phase: 36
slug: hierarchical-facets
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-19
---

# Phase 36 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution (Scrypath / ExUnit).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (via `Mix.Tasks.Test`) |
| **Config file** | `mix.exs`, `test/test_helper.exs` |
| **Quick run command** | `mix compile --warnings-as-errors` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | CI-dependent (~1–5 minutes local typical) |

---

## Sampling Rate

- **After every task commit:** `mix compile --warnings-as-errors` when Elixir sources change; add `mix test` on the narrowest file matching the task’s blast radius.
- **After every plan wave:** `mix test` (full suite) before declaring wave done.
- **Before `/gsd-verify-work`:** `mix test` green.
- **Max feedback latency:** Bounded by local `mix test` duration; no watch-mode.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 36-01-01 | 01 | 1 | FACET-01 | T-36-01 / — | Reject user-controlled string keys in schema faceting attrs (compile-time) | unit | `mix test test/scrypath/options_test.exs` | ✅ | ⬜ pending |
| 36-01-02 | 01 | 1 | FACET-01 | — | N/A | unit | `mix test test/scrypath/options_test.exs` | ✅ | ⬜ pending |
| 36-02-01 | 02 | 2 | FACET-01 | — | N/A | unit | `mix test` (drift/settings paths TBD in execution) | ✅ | ⬜ pending |
| 36-03-01 | 03 | 3 | FACET-01 | T-36-DOC-01 | Docs avoid internal REQ IDs in user strings | unit | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- **Existing infrastructure covers all phase requirements.** No new Wave-0 framework install; add `test/support/` schemas as needed in Plan 01/03.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Live Meilisearch hierarchical indexing | FACET-01 | Optional if repo uses containerized integration elsewhere | If integration test spins Meilisearch: `docker compose up` per project docs, then run tagged integration test once |

*If no integration harness: "All phase behaviors verified via unit tests + docs contract."*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or compile gate
- [ ] Sampling continuity: no long stretches without `mix test` after behavior changes
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter when execution completes

**Approval:** pending
