---
phase: "178"
slug: "loader-routed-backfill-and-full-key-paging"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-25"
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
| **Postgres run command** | `docker compose up -d postgres && SCRYPATH_POSTGRES_URL=postgres://postgres:postgres@127.0.0.1:5434 mix verify.postgres` |
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

| Req | Test Type | Automated Command | File Exists |
|-----|-----------|-------------------|-------------|
| LOAD-01 | integration (both adapters) + unit | `mix test test/scrypath/loader_backfill_sqlite_test.exs test/scrypath/loader_test.exs` ; `mix verify.postgres` | ❌ W0 |
| LOAD-02 | integration + unit | same + `mix test test/scrypath/reindex_test.exs` | ❌ W0 |
| LOAD-03 | integration + unit | `mix test test/scrypath/backfill_test.exs` + shared cases | partial ✅ |
| PAGE-01 | property + example (real DB) | shared cases via SQLite file and `mix verify.postgres` | ❌ W0 |
| PAGE-02 | property + unit | shared cases; `mix test test/scrypath/backfill_test.exs` | partial ✅ |
| TEST-06 | contract + hosted CI | `mix test test/mix/tasks/workflow_wiring_test.exs test/mix/tasks/verify_capability_test.exs` | ❌ new asserts |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/support/postgres_repo.ex`, `test/support/sqlite_sandbox_repo.ex`
- [ ] `test/support/loader_backfill_migration.ex`, `test/support/loader_backfill_schemas.ex`
- [ ] `test/support/loader_backfill_cases.ex` (shared `__using__` case template)
- [ ] `test/scrypath/loader_backfill_sqlite_test.exs`, `test/scrypath/loader_backfill_postgres_test.exs`
- [ ] `test/scrypath/loader_test.exs` (`prepare_records/3` unit tests)
- [ ] `test_helper.exs` composed exclude list
- [ ] `{:postgrex, "~> 0.22", only: :test, runtime: false}` + `mix deps.get`

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
