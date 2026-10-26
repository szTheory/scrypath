---
phase: "179"
slug: "bounded-id-lists-and-related-sync-parity"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-25"
---

# Phase 179 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5 / OTP 28.5) + `Oban.Testing` (new in this phase, SQLite `Oban.Engines.Lite`) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/scrypath/sync_test.exs test/scrypath/oban test/scrypath/sync test/scrypath/loader_test.exs test/scrypath/backfill_test.exs test/scrypath/reindex_test.exs test/scrypath/oban_test.exs test/scrypath/loader_backfill_sqlite_test.exs test/scrypath/chunks_test.exs` |
| **Full suite command** | `mix verify.core --exclude integration --exclude docs_contract` then `mix verify.phase108` |
| **Estimated runtime** | ~30 seconds (quick run well under that) |

Local note: no `.tool-versions`; run with `ASDF_ERLANG_VERSION=28.5 ASDF_ELIXIR_VERSION=1.19.5-otp-28`.

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
| PAGE-03 | 2,500 records → 3 upsert calls ≤1000, `document_count: 2500`, 3 `tasks` | unit | `mix test test/scrypath/sync_test.exs` ("inline sync of 2,500 records sends three bounded upserts…") | ✅ | ✅ green |
| PAGE-03 | 2,500 ids delete → 3 delete calls, combined result | unit | `mix test test/scrypath/sync_test.exs` ("delete_documents of 2,500 ids…") | ✅ | ✅ green |
| PAGE-03 | chunk-2 failure halts; chunk 3 never sent; inline waits per chunk | unit | `mix test test/scrypath/sync_test.exs` ("a failed chunk halts later chunks…", "a failed inline chunk task halts later chunks") | ✅ | ✅ green |
| PAGE-03 | single-chunk result keeps the map + one-element `tasks` | regression | `mix test test/scrypath/sync_test.exs` ("a single-chunk call keeps today's map…") | ✅ | ✅ green |
| PAGE-03 | Chunks: 1000/1001 adjacency, dedupe, order-independence, id_key | unit | `mix test test/scrypath/chunks_test.exs` | ✅ | ✅ green |
| PAGE-03 | Oban 2,500 ids → 3 jobs; transactional insert (rollback → 0 jobs); nested-transaction path (WR-01) | unit + SQLite Oban | `mix test test/scrypath/oban/enqueue_test.exs test/scrypath/oban/enqueue_unique_test.exs` | ✅ | ✅ green |
| PAGE-03 | `Loader.load/3` 2,500 ids → ≤1000 per call; uncastable / non-dumpable ids → invalid arg (WR-07/WR-08) | unit + SQLite | `mix test test/scrypath/loader_test.exs test/scrypath/loader_backfill_sqlite_test.exs` | ✅ | ✅ green |
| PAGE-03 | Upsert/Delete workers chunk >1000-id jobs | unit | `mix test test/scrypath/oban/worker_test.exs` ("delete worker sends 2,500 ids as three chunks…") | ✅ | ✅ green |
| PAGE-03 | backfill 2,500-row page → 3 write chunks + `delete_tasks:` (WR-04); reindex waits on every chunk task | unit | `mix test test/scrypath/backfill_test.exs test/scrypath/reindex_test.exs` | ✅ | ✅ green |
| FAN-01 | Oban worker loads structs, passes only loaded, `missing_count`, soft-deleted excluded, all-missing → `:ok`; inline dedupes triggers (IN-06) | unit | `mix test test/scrypath/sync/related_worker_test.exs test/scrypath/sync/related_test.exs` | ✅ | ✅ green |
| FAN-01 | `sync_related` under Oban raises at call site without repo / `search_records/2` (D-12); nil id raises (WR-06) | unit | `mix test test/scrypath/sync/related_test.exs` | ✅ | ✅ green |
| FAN-02 | `[2,1]` then `[1,2]` → one job, `conflict?: true` (direct + related) | SQLite Oban (`testing: :manual`) | `mix test test/scrypath/oban/enqueue_unique_test.exs` | ✅ | ✅ green |
| FAN-02 | Multi helpers insert without `unique:`; direct enqueue keeps it (189cef0f) | unit | `mix test test/scrypath/oban_test.exs` | ✅ | ✅ green |
| FAN-03 | table-driven bad related args → `{:cancel, {:invalid_job, tag}}`, never raises; non-list `search_records/2` cancels (IN-04) | unit (table-driven) | `mix test test/scrypath/oban/job_args_test.exs test/scrypath/oban/worker_test.exs test/scrypath/sync/related_worker_test.exs` | ✅ | ✅ green |
| FAN-03 | release-safe module resolution (CR-01): runtime-built module whose segments are not atoms decodes; unknown names create no atoms | unit | `mix test test/scrypath/oban/job_args_test.exs` | ✅ | ✅ green |
| D-18 / D-22 | unresolvable `"repo"` cancels; 0.3.17 legacy upsert + related args run; 0.3.17 unloadable related → `:repo_required` (WR-03) | unit | `mix test test/scrypath/oban/worker_test.exs test/scrypath/sync/related_worker_test.exs` | ✅ | ✅ green |
| WR-09 | operator retry of stored bad ids returns `{:error, {:invalid_retry_input, :document_ids}}` | unit | `mix test test/scrypath/operator/failed_work_test.exs` | ✅ | ✅ green |
| D-13 | guide contract strings | docs contract | `mix verify.phase108` + `mix test --include docs_contract test/scrypath/docs_contract_test.exs` | ✅ | ✅ green |

| Threat | Secure Behavior | Covered by |
|--------|-----------------|------------|
| Atom exhaustion from job args | no `String.to_atom`; allowlisted opts keys | `job_args_test.exs` |
| Arbitrary module invocation | module must exist and export expected callbacks | `job_args_test.exs` |
| Unbounded payload / SQL params | ≤1000 ids per load, write and job | PAGE-03 rows above |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/support/oban_sqlite_repo.ex` + inline Oban migration (dedicated SQLite repo, WAL + busy_timeout)
- [x] `test/scrypath/oban/enqueue_unique_test.exs` (`async: false`, `Oban.Testing`, `testing: :manual`, `Oban.Engines.Lite`)
- [x] `test/scrypath/oban/job_args_test.exs` (pure, table-driven)
- [x] `FakeRepo.__adapter__/0` stub so D-18 does not cancel existing worker tests
- [x] Task-returning recording backend for multi-`tasks` assertions
- [x] Related fixtures rewritten to define `search_records/2` and struct-taking resolvers

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s (quick run 8.7s)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-10-25 at b258bd31 (automated: quick run 267/0, `mix verify.phase108` 6/0; full suite 871/0). Hosted PR lanes (`phoenix-example`, `ecommerce-mounted`) still owed on the PR SHA.

## Validation Audit 2026-10-25

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
