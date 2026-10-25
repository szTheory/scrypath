---
phase: "178"
slug: "loader-routed-backfill-and-full-key-paging"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
created: "2026-10-25"
---

# Phase 178 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| developer/CI env → test repo | `SCRYPATH_POSTGRES_URL` decides which server the harness drops and recreates a database on | Connection URL (test credentials) |
| Hex registry → mix.lock | A new test dependency (postgrex) enters the build | Third-party package code |
| CI runner → service container | Throwaway Postgres with fixed local credentials | Fixed `postgres:postgres` credentials, non-secret |
| lib/ → Hex package | Mix task source ships to adopters | Library code |
| database rows → keyset cursor | Last-row key values become query parameters for the next batch | Primary-key values |
| library → Meilisearch index | Target index primaryKey decides document identity | Index settings |
| adopter `search_records/2` → backfill | Adopter code may return records beyond the requested ids | Application records (potentially tenant-scoped) |
| caller `:query` → backfill | Caller scope (e.g. tenant `where`) defines which rows may be indexed | Row-selection scope |
| backfill → live index deletes | Omitted ids are removed from a production index | Document ids |
| docs → operator decisions | Operators choose backfill vs reindex and trust removal semantics from the guides | Documentation claims |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation / Evidence | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-178-01 | Tampering | `test/support/postgres_repo.ex` init/2 | high | mitigate | `init/2` reads only `System.fetch_env!("SCRYPATH_POSTGRES_URL")` and merges `database: "scrypath_test#{MIX_TEST_PARTITION}"` after `parse_url/1`, so any URL path is overridden; no generic `DATABASE_URL` read in `postgres_repo.ex` or `test/test_helper.exs` | closed |
| T-178-02 | Denial of Service | `test/test_helper.exs` exclude list | low | mitigate | Single composed `exclude` list adds `:postgres` unless `SCRYPATH_POSTGRES_URL` is non-empty, independent of `SCRYPATH_INTEGRATION` | closed |
| T-178-SC | Tampering | `mix deps.get` adding postgrex (plans 01–05) | high | mitigate | `mix.exs:118` `{:postgrex, "~> 0.22", only: :test, runtime: false}`; commit e7bee37b adds exactly one `mix.lock` line (`postgrex` 0.22.4, hexpm checksum). Plans 02–05 install no packages | closed |
| T-178-03 | Information Disclosure | `.github/workflows/ci.yml` backend postgres credentials | low | accept | See Accepted Risks Log AR-178-01 | closed |
| T-178-04 | Elevation of Privilege | `lib/mix/tasks/verify.postgres.ex` shipped in Hex | low | mitigate | Task only calls `Mix.Task.run("test", ["--include", "postgres", path])`; no reference to `Postgrex` or `TestSupport` in `verify.postgres.ex` or `verify/capability.ex` | closed |
| T-178-05 | Repudiation | CI lane silently dropping the Postgres suite | medium | mitigate | `workflow_wiring_test.exs:394` pins `postgres:16-alpine`, `pg_isready`, `SCRYPATH_POSTGRES_URL: ...:5434`, `mix verify.backend`; `verify/capability.ex:59` dispatches `verify.postgres`; `verify_postgres_test.exs` pins Meilisearch-before-Postgres order. Hosted `backend` log proof is an exact-SHA PR gate (see Notes) | closed |
| T-178-06 | Tampering | `Backfill.keyset_after/2` | medium | mitigate | `keyset_predicate/1` and `expand/1` build `dynamic([r], field(r, ^col) > ^value ...)` only; `grep fragment( lib/scrypath/backfill.ex` returns nothing | closed |
| T-178-07 | Denial of Service | Backfill loop on nil / non-advancing cursor | medium | mitigate | `exclude_nil_document_ids/3` adds `not is_nil(field(r, ^col))` on the keyless fallback; `cursor_values/2` raises `ArgumentError` on a nil cursor column; cursor taken from scoped rows, not loader output | closed |
| T-178-08 | Tampering | `Reindex` create_index primaryKey | medium | mitigate | `reindex.ex:38` `document_id = Metadata.document_id(schema_module)` passed to `create_index/3`; `reindex_test.exs:462` composite-key assertion | closed |
| T-178-09 | Information Disclosure | `Loader.prepare_records/3` custom path | high | mitigate | `loader.ex:111-117` builds `MapSet` of batch ids via `to_string` and filters returned records to it before projection; unit test (`loader_test.exs:16`, extra id 99) and shared real-DB case (`loader_backfill_cases.ex:350`, pinned out-of-batch article refuted from upserts) | closed |
| T-178-10 | Tampering | `Backfill.delete_documents/5` | medium | mitigate | `run_batch/2` deletes only `omitted` from the current batch, on the same resolved `index`, sequenced after the upsert in one `with`; `write/5` skips `[]`; `fresh_target?` forces removals to `[]`; `delete_task:` surfaced per batch | closed |
| T-178-11 | Elevation of Privilege | Caller `:query` scope | medium | mitigate | `base_query/3` keeps caller `where`/`join` (excludes only order_by/limit/offset/select/preload); real-DB case asserts `search_records/2` receives only in-scope batch ids and no `us` id is upserted | closed |
| T-178-12 | Tampering | `_scrypath_fresh_target` passed by an adopter | low | accept | See Accepted Risks Log AR-178-02 | closed |
| T-178-13 | Repudiation | Guides overpromising pruning | low | mitigate | "not a whole-index prune" + `Scrypath.reconcile_sync/2` text in `guides/sync-modes-and-visibility.md:114` and `guides/related-data-and-reindexing.md:404`; pinned by `backfill_contract_docs_test.exs:46-65` | closed |
| T-178-14 | Information Disclosure | HexDocs exposing internal flag / loader entry point | low | mitigate | `backfill_contract_docs_test.exs:41-42` refutes `_scrypath_fresh_target` and `prepare_records` in the `backfill/2` doc; option is `doc: false`; `prepare_records/3` is `@doc false` | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

T-178-SC appears in every plan's register; it is tracked once here.

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-178-01 | T-178-03 | `postgres:postgres` belongs to a throwaway CI service container bound to the runner, the same pattern as the existing ops-ui lane. No secret is involved and the database holds only test fixtures. | Plan 178-02 threat model (accept disposition); confirmed by gsd-secure-phase agent | 2026-10-25 |
| AR-178-02 | T-178-12 | `_scrypath_fresh_target` is an undocumented internal key (`doc: false`, boolean-typed by NimbleOptions). Its only effect when an adopter passes it is skipping omitted-id deletes, which equals pre-phase-178 backfill behavior, so it grants no capability the adopter lacked before. | Plan 178-04 threat model (accept disposition); confirmed by gsd-secure-phase agent | 2026-10-25 |

*Accepted risks do not resurface in future audit runs.*

---

## Notes

- Verification depth is ASVS L1 (grep and code-read against the plan register). The register was authored at plan time and all threats closed, so the auditor subagent was not required (short-circuit rule).
- T-178-05 includes a hosted-evidence component: the exact-SHA `backend (required)` CI log should show `test/scrypath/loader_backfill_postgres_test.exs` running with a non-zero test count. The branch is not pushed, so this cannot be checked locally; it belongs to the PR gate. The local wiring tests that guard against silent drop are in place.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-25 | 15 | 15 | 0 | gsd-secure-phase (agent, ASVS L1) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-25
