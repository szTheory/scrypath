---
phase: 58
slug: core-library-and-doc-qol-b1
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-21
---

# Phase 58 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) |
| **Config file** | `mix.exs`, `test/test_helper.exs` |
| **Quick run command** | `mix test test/scrypath/sync_test.exs` (example — adjust to touched modules) |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~60–120 seconds (project-dependent) |

## Sampling Rate

- **After every task commit:** Run `mix test` scoped to the subtree touched (e.g. `mix test test/scrypath/sync_test.exs` when `lib/scrypath/sync.ex` changes).
- **After every plan wave:** Run `mix test` from repo root once.
- **Before `/gsd-verify-work`:** Full `mix test` green; when doc anchors change, `mix test test/scrypath/docs_contract_test.exs`.
- **Max feedback latency:** 180 seconds (full suite upper bound on dev laptop).

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 58-01-01 | 01 | 1 | LIB-01 | TM-58-01 / — | N/A — library DX | unit | `mix test test/scrypath/sync_test.exs` (or nearest sync tests) | ✅ | ⬜ pending |
| 58-01-02 | 01 | 1 | LIB-01 | TM-58-01 | N/A | unit | `mix test test/scrypath/` | ✅ | ⬜ pending |
| 58-02-01 | 02 | 1 | LIB-02 | — | N/A | unit | `mix test test/scrypath/query_test.exs` if present else `mix test test/scrypath/` | ✅ | ⬜ pending |
| 58-03-01 | 03 | 1 | LIB-03 | — | N/A | unit | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

## Wave 0 Requirements

- [x] ExUnit + Mix already configured — **no Wave 0 install**.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| EVID-57-02 errata note | LIB-02 | Append-only ledger policy | Open `.planning/EVID-01-b1-v1.14.md`, confirm new errata or row cites **LIB-02** and before/after per **D-12** |

## Validation Sign-Off

- [ ] All tasks have automated `mix test` paths or doc-contract subset
- [ ] Sampling continuity: sync/doc tasks each declare a concrete test path
- [ ] No watch-mode flags in plans
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
