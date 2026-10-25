---
phase: "178"
slug: "loader-routed-backfill-and-full-key-paging"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-25"
validated: "2026-10-25"
---

# Phase 178 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19 CI, 1.17 compat lane) + StreamData 1.3 |
| **Config file** | `test/test_helper.exs`, `mix.exs` (`preferred_envs`, `test_ignore_filters`) |
| **Quick run command** | `mix test test/scrypath/backfill_test.exs test/scrypath/loader_backfill_sqlite_test.exs test/scrypath/reindex_test.exs test/scrypath/oban/worker_test.exs` |
| **Postgres run command** | `docker compose up -d --wait postgres && SCRYPATH_POSTGRES_URL=postgres://postgres:postgres@127.0.0.1:5434 mix verify.postgres` |
| **Full suite command** | `mix verify.core --exclude integration --exclude docs_contract` + `mix verify.backend` (with Meilisearch + Postgres env) + `mix verify.repository_contracts` + `mix verify.package` |
| **Estimated runtime** | ~30 seconds (quick), several minutes (full) |

---

## Sampling Rate

- **After every task commit:** Run the quick run command
- **After every plan wave:** Quick run + `mix verify.postgres` (compose) + `mix credo --strict` + `mix compile --warnings-as-errors`
- **Before `/gsd-verify-work`:** Hosted PR checks green on exact SHA (`core`, `package`, `repository-contracts`, `backend` log shows `loader_backfill_postgres_test.exs` with non-zero tests)
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

Filled by the planner per task; requirement → test map lives in `178-RESEARCH.md` § Validation Architecture.

Per-task map (planner, 2026-10-25):

| Task | Req | Automated Command | Status |
|------|-----|-------------------|--------|
| 178-01-T1 | TEST-06 | `mix test test/scrypath/loader_backfill_sqlite_test.exs` | ✅ green |
| 178-01-T2 | TEST-06 | `SCRYPATH_POSTGRES_URL=… mix test --include postgres test/scrypath/loader_backfill_postgres_test.exs` | ✅ green |
| 178-02-T1 | TEST-06 | `mix test test/mix/tasks/verify_capability_test.exs test/mix/tasks/verify_postgres_test.exs` ; `mix verify.postgres` | ✅ green |
| 178-02-T2 | TEST-06 | `mix test test/mix/tasks/workflow_wiring_test.exs` | ✅ green |
| 178-03-T1 | PAGE-01, PAGE-02 | sqlite shared cases + `mix test test/scrypath/backfill_test.exs` + postgres run | ✅ green |
| 178-03-T2 | PAGE-01, PAGE-02, LOAD-03 | same + postgres run (property) | ✅ green |
| 178-03-T3 | PAGE-01 (D-17) | `mix test test/scrypath/reindex_test.exs` + shared reindex composite case | ✅ green |
| 178-04-T1 | LOAD-01, LOAD-02 | `mix test test/scrypath/loader_test.exs test/scrypath/backfill_test.exs test/scrypath/oban/worker_test.exs` | ✅ green |
| 178-04-T2 | LOAD-02 | `mix test test/scrypath/reindex_test.exs test/scrypath/backfill_test.exs test/scrypath/options_test.exs` | ✅ green |
| 178-04-T3 | LOAD-01, LOAD-02, LOAD-03 | sqlite shared cases + postgres run | ✅ green |
| 178-05-T1 | LOAD-02, PAGE-02 | `mix test test/scrypath/backfill_contract_docs_test.exs` ; `mix docs --warnings-as-errors` | ✅ green |
| 178-05-T2 | LOAD-02, TEST-06 | `mix test test/scrypath/backfill_contract_docs_test.exs` ; `mix test --include docs_contract test/scrypath/docs_contract_test.exs` | ✅ green |

Requirement map (audited 2026-10-25):

| Req | Covering tests | Status |
|-----|----------------|--------|
| LOAD-01 | shared case "backfill, reindex, inline and Oban-loader documents are identical for preload:" (SQLite + Postgres); `loader_test.exs` force-preload / pass-through | COVERED |
| LOAD-02 | shared cases "search_records/2 loads every batch…", "reindex counts what search_records/2 omits and deletes nothing", "an all-omitted backfill still visits and counts every batch"; `backfill_test.exs` delete-order / delete_task cases; `loader_test.exs` custom-loader filtering; `backfill_contract_docs_test.exs` | COVERED |
| LOAD-03 | shared cases "a caller query keeps its where scope while its offset is ignored", fan-out dedupe, search_records scope case; `backfill_test.exs` `:query` override stripping | COVERED |
| PAGE-01 | shared cases pinned `{1,3}` backfill regression, StreamData property (`max_runs: 40`), binary_id key, keyless, single-column SQL shape, empty/single row; **added** "reindex pages a composite key on every key column and creates the index on the document id"; `reindex_test.exs` create_index primaryKey | COVERED (was PARTIAL: reindex clause had no real-DB proof) |
| PAGE-02 | shared composite cases assert keyword `last_primary_key` per batch (`[org_id: 1, seq: 2]`); property asserts full cursor per batch; contract docs test pins cursor-shape docs | COVERED |
| TEST-06 | `loader_backfill_postgres_test.exs` (13 tests incl. property, via `mix verify.postgres`); `verify_postgres_test.exs`; `verify_capability_test.exs`; `workflow_wiring_test.exs` pins postgres:16-alpine service + `SCRYPATH_POSTGRES_URL` in `backend (required)` | COVERED locally; exact-SHA hosted `backend (required)` log is a PR ship-gate check (automated CI, not human UAT) |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/support/postgres_repo.ex`, `test/support/sqlite_sandbox_repo.ex`
- [x] `test/support/loader_backfill_fixtures.ex` (migration + schemas consolidated into one fixture file)
- [x] `test/support/loader_backfill_cases.ex` (shared `__using__` case template)
- [x] `test/scrypath/loader_backfill_sqlite_test.exs`, `test/scrypath/loader_backfill_postgres_test.exs`
- [x] `test/scrypath/loader_test.exs` (`prepare_records/3` unit tests)
- [x] `test_helper.exs` composed exclude list
- [x] `{:postgrex, "~> 0.22", only: :test, runtime: false}` + `mix deps.get`

---

## Manual-Only Verifications

None. All phase behaviors have automated verification.

Decision (validate-phase run without an interactive maintainer, 2026-10-25): the one PARTIAL gap was filled with an automated test rather than marked manual-only. The remaining TEST-06 hosted-evidence item (the `backend (required)` log on the phase PR's exact SHA shows `loader_backfill_postgres_test.exs` with a non-zero test count) is an automated CI check owned by the ship/PR gate, not human UAT. Its wiring is pinned by `test/mix/tasks/workflow_wiring_test.exs`.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s (quick set: 158 tests in ~9s; Postgres lane: 13 tests in ~1s)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-10-25 by gsd-validate-phase (automated audit; evidence below)

### Audit evidence (2026-10-25, Elixir 1.19.5 / OTP 28.5)

- Quick + related set (backfill, loader_backfill_sqlite, reindex, oban/worker, loader, options, backfill_contract_docs, verify_capability, verify_postgres, workflow_wiring): 1 property, 158 tests, 0 failures (pre-gap-fill)
- `MIX_TEST_PARTITION=5 SCRYPATH_POSTGRES_URL=postgres://postgres:postgres@127.0.0.1:5434 mix verify.postgres`: 1 property, 13 tests, 0 failures (real Postgres 16)
- `mix test test/scrypath/loader_backfill_sqlite_test.exs`: 1 property, 13 tests, 0 failures
- Full `mix test`: 5 properties, 774 tests, 0 failures (25 excluded)
- `mix format --check-formatted`, `mix credo --strict`: clean
- Gap-fill test commit: 0c03a83b

## Validation Audit 2026-10-25

| Metric | Count |
|---|---|
| Gaps found | 1 |
| Resolved | 1 |
| Escalated | 0 |
