---
phase: "179"
slug: "bounded-id-lists-and-related-sync-parity"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-25"
---

# Phase 179 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.0 / OTP 28.1) + `Oban.Testing` (new in this phase, SQLite `Oban.Engines.Lite`) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/scrypath/sync_test.exs test/scrypath/oban test/scrypath/sync test/scrypath/loader_test.exs test/scrypath/backfill_test.exs test/scrypath/reindex_test.exs test/scrypath/oban_test.exs test/scrypath/loader_backfill_sqlite_test.exs` |
| **Full suite command** | `mix verify.core --exclude integration --exclude docs_contract` then `mix verify.phase108` |
| **Estimated runtime** | ~30 seconds (quick run well under that) |

Local note: no `.tool-versions`; run with `ASDF_ERLANG_VERSION=28.1 ASDF_ELIXIR_VERSION=1.19.0-otp-28`.

---

## Sampling Rate

- **After every task commit:** Run the quick run command
- **After every plan wave:** Quick run + `mix compile --warnings-as-errors` + `mix credo --strict` + `mix format --check-formatted` + `mix verify.phase108`
- **Before `/gsd-verify-work`:** Full suite green locally, then hosted PR checks green on the exact SHA (`core`, `package`, `repository-contracts`, `backend`, `ecommerce-mounted`)
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

Requirement → test map (task IDs are bound by the planner in PLAN.md `<verify>` blocks):

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| PAGE-03 | 2,500 records → 3 upsert calls ≤1000, `document_count: 2500`, 3 `tasks` | unit | `mix test test/scrypath/sync_test.exs` | ✅ file / ❌ cases | ⬜ pending |
| PAGE-03 | 2,500 ids delete → 3 delete calls, combined result | unit | `mix test test/scrypath/sync_test.exs` | ❌ | ⬜ pending |
| PAGE-03 | chunk-2 failure halts; chunk 3 never sent; inline waits per chunk | unit | `mix test test/scrypath/sync_test.exs` | ❌ | ⬜ pending |
| PAGE-03 | single-chunk result unchanged + one-element `tasks` | regression | `mix test test/scrypath/sync_test.exs` | ✅ | ⬜ pending |
| PAGE-03 | Oban 2,500 ids → 3 jobs, transactional insert (rollback → 0 jobs) | unit + SQLite Oban | `mix test test/scrypath/oban/enqueue_test.exs test/scrypath/oban/enqueue_unique_test.exs` | ❌ W0 | ⬜ pending |
| PAGE-03 | `Loader.load/3` 2,500 ids → `search_records/2` sees ≤1000 per call | unit | `mix test test/scrypath/loader_test.exs` | ❌ case | ⬜ pending |
| PAGE-03 | Upsert/Delete workers chunk legacy >1000-id jobs; missing-id deletes after upserts | unit | `mix test test/scrypath/oban/worker_test.exs` | ❌ case | ⬜ pending |
| PAGE-03 | backfill `batch_size: 5000` → 3 writes; reindex waits on every chunk task | SQLite shared + unit | `mix test test/scrypath/loader_backfill_sqlite_test.exs test/scrypath/reindex_test.exs` | ❌ cases | ⬜ pending |
| FAN-01 | inline resolver gets caller structs; Oban worker loads structs, skips/counts missing, all-missing → `:ok` | unit | `mix test test/scrypath/sync/related_test.exs test/scrypath/sync/related_worker_test.exs` | ❌ cases | ⬜ pending |
| FAN-01 | `sync_related` under Oban fails at call site without repo (D-12) | unit | `mix test test/scrypath/sync/related_test.exs` | ❌ | ⬜ pending |
| FAN-02 | enqueue twice (`[2,1]` then `[1,2]`) → one job, `conflict?: true` | SQLite Oban (`testing: :manual`) | `mix test test/scrypath/oban/enqueue_unique_test.exs` | ❌ W0 | ⬜ pending |
| FAN-03 | worker × applicable bad arg → `{:cancel, {:invalid_job, tag}}`, never raises; nil/unknown opts keys ignored | unit (table-driven) | `mix test test/scrypath/oban/job_args_test.exs test/scrypath/oban/worker_test.exs test/scrypath/sync/related_worker_test.exs` | ❌ W0 | ⬜ pending |
| D-18 / D-22 | unresolvable `"repo"` cancels; 0.3.17 legacy upsert + related args stay `:ok` | unit | `mix test test/scrypath/oban/worker_test.exs test/scrypath/sync/related_worker_test.exs` | ✅ legacy / ❌ new | ⬜ pending |
| D-13 | guide contract strings | docs contract | `mix verify.phase108` | ✅ | ⬜ pending |

| Threat | Secure Behavior | Covered by |
|--------|-----------------|------------|
| Atom exhaustion from job args | no `String.to_atom`; allowlisted opts keys | `job_args_test.exs` |
| Arbitrary module invocation | module must exist and export expected callbacks | `job_args_test.exs` |
| Unbounded payload / SQL params | ≤1000 ids per load, write and job | PAGE-03 rows above |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/support/oban_sqlite_repo.ex` + inline Oban migration (dedicated SQLite repo, WAL + busy_timeout)
- [ ] `test/scrypath/oban/enqueue_unique_test.exs` (`async: false`, `Oban.Testing`, `testing: :manual`, `Oban.Engines.Lite`)
- [ ] `test/scrypath/oban/job_args_test.exs` (pure, table-driven)
- [ ] `FakeRepo.__adapter__/0` stub so D-18 does not cancel existing worker tests
- [ ] Task-returning recording backend for multi-`tasks` assertions
- [ ] Related fixtures rewritten to define `search_records/2` and struct-taking resolvers

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
