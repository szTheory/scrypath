---
phase: 178-loader-routed-backfill-and-full-key-paging
verified: 2026-10-26T19:49:36Z
status: passed
score: "4/4 roadmap truths; 6/6 requirements satisfied"
source_sha: f718c4a92de95277d6859b134121083448335271
refresh_of: "2026-10-25 prior report; current source rechecked"
covered_files: [".github/workflows/ci.yml", ".planning/phases/178-loader-routed-backfill-and-full-key-paging/178-01-PLAN.md", ".planning/phases/178-loader-routed-backfill-and-full-key-paging/178-01-SUMMARY.md", ".planning/phases/178-loader-routed-backfill-and-full-key-paging/178-02-PLAN.md", ".planning/phases/178-loader-routed-backfill-and-full-key-paging/178-02-SUMMARY.md", ".planning/phases/178-loader-routed-backfill-and-full-key-paging/178-03-PLAN.md", ".planning/phases/178-loader-routed-backfill-and-full-key-paging/178-03-SUMMARY.md", ".planning/phases/178-loader-routed-backfill-and-full-key-paging/178-04-PLAN.md", ".planning/phases/178-loader-routed-backfill-and-full-key-paging/178-04-SUMMARY.md", ".planning/phases/178-loader-routed-backfill-and-full-key-paging/178-05-PLAN.md", ".planning/phases/178-loader-routed-backfill-and-full-key-paging/178-05-SUMMARY.md", "CONTRIBUTING.md", "README.md", "compose.yaml", "guides/related-data-and-reindexing.md", "guides/sync-modes-and-visibility.md", "lib/mix/tasks/verify.all.ex", "lib/mix/tasks/verify.phase5.ex", "lib/mix/tasks/verify.postgres.ex", "lib/mix/tasks/verify/capability.ex", "lib/scrypath.ex", "lib/scrypath/backfill.ex", "lib/scrypath/loader.ex", "lib/scrypath/options.ex", "lib/scrypath/reindex.ex", "mix.exs", "mix.lock", "test/mix/tasks/verify_capability_test.exs", "test/mix/tasks/verify_postgres_test.exs", "test/mix/tasks/workflow_wiring_test.exs", "test/scrypath/backfill_contract_docs_test.exs", "test/scrypath/backfill_test.exs", "test/scrypath/loader_backfill_postgres_test.exs", "test/scrypath/loader_backfill_sqlite_test.exs", "test/scrypath/loader_test.exs", "test/scrypath/options_test.exs", "test/scrypath/reindex_test.exs", "test/support/loader_backfill_cases.ex", "test/support/loader_backfill_fixtures.ex", "test/support/postgres_repo.ex", "test/support/sqlite_sandbox_repo.ex", "test/test_helper.exs"]
covered_digest: "v3:sha256:6de4bf3d196f653f085b17a5e81017fb810b830ff769c0b0f68f195496e48e9a"
behavior_unverified: 0
overrides_applied: 0
decision_coverage: {honored: 17, total: 17, not_honored: []}
human_verification: []
historical_pr_gate_evidence:
  - criterion: "SC4 / TEST-06: the Postgres loader/backfill suite passes on the phase PR"
    gate: "hosted `backend (required)` on the exact phase-PR head SHA"
    current: "PR #122 head is 93502339 (pre-phase base); phase commits 93502339..487a4588 are not pushed, so no hosted run of the new lane exists yet"
    local_reproduction: "MIX_TEST_PARTITION=6 SCRYPATH_POSTGRES_URL=postgres://postgres:postgres@127.0.0.1:5434 mix verify.postgres -> 1 property, 13 tests, 0 failures"
    ship_check: "backend (required) log on the pushed SHA shows test/scrypath/loader_backfill_postgres_test.exs with 1 property, 13 tests, 0 failures"
    classification: "deterministic PR gate, not human verification"
advisory:
  - finding: "WR-01: a :query with distinct/group_by/having/windows/union is passed through to the keyset loop; on Postgres DISTINCT ON exprs are prepended to ORDER BY, so paging can skip rows silently"
    category: other
    reason: "Outside the documented :query contract (guide: only where/join apply) and pre-existing (the 93502339 base already paged distinct queries the same way). Does not defeat a stated must-have, but contradicts the @doc wording 'every row in scope is visited exactly once' for such queries. Resolve by rejecting those clauses with ArgumentError (or exclude(:distinct)) plus a Postgres case."
    evidence_status: "reasoned from Ecto Postgres adapter semantics; not executed"
  - finding: "WR-02: _scrypath_fresh_target is accepted by the public Scrypath.backfill/2 option schema (doc: false only), letting a caller disable live-index deletes"
    category: security
    reason: "Not a must-have violation (reindex is the only internal caller and the flag is undocumented), but an unsafe public surface. Move to a private entry point."
    evidence_status: "code read: lib/scrypath/options.ex, lib/scrypath/backfill.ex:38"
  - finding: "WR-03: live backfill now deletes ids search_records/2 omits; no explicit upgrade note and fix: commit types"
    category: other
    reason: "Behavior is documented in guides and @doc (must-have satisfied); upgrade/changelog visibility is a release concern for the PR title or release notes."
    evidence_status: "code/docs read"
historical_prohibition_verdicts:
  authority: "judgment-tier; non-authoritative verifier verdicts, each backed by deterministic grep/diff/test evidence below"
  flagged: 0
  items:
    - {statement: "PostgresRepo never reads the generic database URL", verdict: held, evidence: "grep DATABASE_URL test/support -> none; postgres_repo.ex reads only SCRYPATH_POSTGRES_URL and forces database scrypath_test<partition>"}
    - {statement: "postgrex only: :test, no other new package", verdict: held, evidence: "mix.exs:118 {:postgrex, \"~> 0.22\", only: :test, runtime: false}; mix.lock diff adds only postgrex"}
    - {statement: "core lane stays service-free", verdict: held, evidence: "mix test with SCRYPATH_POSTGRES_URL unset: 774 tests, 0 failures, :postgres excluded"}
    - {statement: "no new required CI job or check name", verdict: held, evidence: "ci.yml diff is +12 lines inside backend (required); job names unchanged"}
    - {statement: "verify.postgres in lib/ has no Postgrex/test-support reference", verdict: held, evidence: "grep -i postgrex|TestSupport lib/mix/tasks/verify.postgres.ex -> none"}
    - {statement: "Postgres suite not folded into meilisearch_smoke nor tagged :integration", verdict: held, evidence: "separate Mix.Tasks.Verify.Postgres; @moduletag :postgres"}
    - {statement: "no row-value/raw SQL fragment or distinct: true in paging", verdict: held, evidence: "grep fragment|distinct lib/scrypath/backfill.ex -> none; predicate built with dynamic/2"}
    - {statement: "no :cursor key in backfill results", verdict: held, evidence: "pinned regression asserts result keys == [:batch_results, :batches, :documents, :index, :mode, :removed]"}
    - {statement: "no new runtime dependency for keyset", verdict: held, evidence: "mix.lock diff"}
    - {statement: "never index a record returned for an id outside the batch", verdict: held, evidence: "Loader.prepare_records/3 filters by batch MapSet; shared case with pinned out-of-scope Article asserts no us ids upserted (SQLite + Postgres)"}
    - {statement: "deletes limited to omitted batch ids; fresh-target reindex makes no delete calls", verdict: held, evidence: "backfill.ex:65 removals = [] when fresh_target?; case 'reindex counts what search_records/2 omits and deletes nothing' refute_received delete"}
    - {statement: "inline sync not routed through the loader", verdict: held, evidence: "no lib/scrypath/sync.ex change in 93502339..HEAD"}
    - {statement: "no id lists in results, no new telemetry", verdict: held, evidence: "batch result map has counts only; no +telemetry lines in lib diff"}
    - {statement: "Loader.load/3 signature and semantics unchanged", verdict: held, evidence: "no -/+ def load lines in loader.ex diff"}
    - {statement: "docs do not imply whole-index prune", verdict: held, evidence: "both guides and @doc say 'not a whole-index prune' / only visited ids"}
    - {statement: "public docs do not mention _scrypath_fresh_target or prepare_records", verdict: held, evidence: "grep README guides lib/scrypath.ex CONTRIBUTING -> none; mix docs --warnings-as-errors clean"}
    - {statement: "CHANGELOG.md not hand-edited", verdict: held, evidence: "CHANGELOG.md absent from 93502339..HEAD diff"}
---

## Historical Verification (prior report, retained as history)

# Phase 178: Loader-routed backfill and full-key paging — Verification Report

## Shipping Evidence — 2026-10-26

The original pending PR gate below is closed for candidate
`cd3eb07f037b73e8c1f4e0d579513f18ec17f50e` by
[backend job 121732151437](https://github.com/szTheory/scrypath/actions/runs/40368375825/job/121732151437)
on PR #122. Its log runs `mix verify.postgres` and reports 1 property,
15 tests, 0 failures (the shared suite grew after this phase's original report).
All five required jobs pass on that source; see
`../../reference/v1.44-ship-candidate.json`. Original phase-time evidence and
findings below remain historical; this addendum does not extend the covered-file
fingerprint to later implementation changes or claim merged-main evidence.

## Original Verification

**Phase Goal:** A backfill or reindex produces exactly the documents inline and Oban sync would produce, for every row of the schema, whatever its primary-key shape.
**Verified:** 2026-10-25T20:05:00Z
**Status:** passed (hosted exact-SHA `backend (required)` evidence for SC4 is a pending PR gate; see below)
**Re-verification:** No (initial verification)

## Goal Achievement

### Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | For a schema declaring `preload:`, backfill and reindex documents equal the documents inline sync builds | VERIFIED | Shared case "backfill, reindex, inline and Oban-loader documents are identical for preload:" asserts backfill == inline (`Scrypath.sync_records` on caller-preloaded rows) == Oban path (`Loader.load/3` + `Projection.document/2`, the same calls `oban/upsert_worker.ex:23-25` makes) == reindex target docs, with category names loaded. Ran green on SQLite and on real Postgres. Wiring: `backfill.ex:63` calls `Loader.prepare_records/3`, which applies `Metadata.preload/1` via `repo.preload(..., force: true)`. |
| 2 | For a `search_records/2` schema, every backfill batch goes through it, omitted records are absent from the index, and `:query` still decides which rows are visited | VERIFIED | Case "search_records/2 loads every batch; the :query scope decides rows" asserts `{:search_records, batch_ids}` per eu-scoped batch and no others, no us-region (out-of-scope, pinned) id upserted, unpublished ids deleted, `removed` count. "all-omitted backfill" proves the cursor still advances. "reindex counts what search_records/2 omits and deletes nothing" covers the fresh target. Green on both adapters. |
| 3 | Property test over a composite PK with repeated leading values across batch boundaries: every row once, full composite cursor per batch | VERIFIED | `property "composite keys: every row visited once, full cursor per batch"` (leading key 1..3, up to 30 keys, batch_size 1..12, max_runs 40) asserts exact id set, no duplicates, batch count = ceil(n/bs), `last_primary_key == [org_id:, seq:]` matching each chunk's max, strictly increasing. Pinned `{1,3}` regression and a binary_id second-column case also pass. `keyset_after/2` (backfill.ex:193-204) builds `c1 >= v1 AND (c1 > v1 OR (c1 = v1 AND ...))` via `dynamic/2`. |
| 4 | Loader/backfill tests incl. composite and `preload:` run against real Postgres in an existing CI lane and pass on the phase PR | VERIFIED (code + local lane); hosted PR run pending as PR gate | `loader_backfill_postgres_test.exs` (`@moduletag :postgres`) shares the same 14 cases. `verify.backend` -> `verify.meilisearch_smoke` then `verify.postgres` (capability.ex:58-59); `backend (required)` has a postgres:16-alpine service and `SCRYPATH_POSTGRES_URL` (ci.yml:80-92), pinned by `workflow_wiring_test.exs:394`. I ran the lane command locally: 1 property, 13 tests, 0 failures. PR #122's head is still the pre-phase base 93502339, so the hosted exact-SHA log cannot exist until the branch is pushed. This is recorded under `pr_gate_evidence`, not as a human item. |

**Score:** 4/4 roadmap truths verified (0 present, behavior-unverified). All 40 plan-frontmatter truths across 178-01 to 178-05 are covered by the cases and code above, the verify-task tests, and the docs contract test. Notable ones checked directly: the single-column SQL shape test (one `>` comparison), the scalar cursor for single keys, the query stripping of order_by/limit/offset/select/preload, fan-out dedupe with `Enum.uniq_by`, the keyless nil guard, `create_index(schema, Metadata.document_id(schema), ...)` in reindex.ex:38-41, `delete_task:` on batch results, and empty upserts or deletes never being sent (backfill.ex:107).

### Required Artifacts

| Artifact | Status | Details |
|----------|--------|---------|
| `lib/scrypath/backfill.ex` | VERIFIED | Keyset paging, Loader routing, delete dispatch, removed/omitted, delete_task |
| `lib/scrypath/loader.ex` | VERIFIED | `prepare_records/3` (@doc false), batch-scope filter, preload force |
| `lib/scrypath/reindex.ex` | VERIFIED | document_id primaryKey, `_scrypath_fresh_target` pass-through, `omitted:` |
| `lib/scrypath/options.ex` | VERIFIED | internal flag, default false |
| `lib/mix/tasks/verify.postgres.ex` | VERIFIED | Curated list, `--include postgres`, Mix.raise on missing URL |
| `lib/mix/tasks/verify/capability.ex`, `verify.all.ex`, `verify.phase5.ex` | VERIFIED | Dispatch order and SQLite file inclusion |
| `.github/workflows/ci.yml`, `compose.yaml` | VERIFIED | Postgres service on 5434 in backend (required) and in compose |
| `test/support/{postgres_repo,sqlite_sandbox_repo,loader_backfill_fixtures,loader_backfill_cases}.ex` | VERIFIED | Shared `__using__` template run by both entry files |
| `lib/scrypath.ex` @doc, README, guides, CONTRIBUTING | VERIFIED | Pinned by `backfill_contract_docs_test.exs` (green) |

### Key Link Verification

| From | To | Via | Status |
|------|----|-----|--------|
| backfill.ex | loader.ex | `Loader.prepare_records(schema_module, rows, config)` (line 63) | WIRED |
| backfill.ex | Meilisearch operations | `MeilisearchOperations.delete_documents/3` (line 223) | WIRED |
| backfill.ex | Ecto.Query.dynamic/2 | `keyset_predicate/expand` | WIRED |
| reindex.ex | backfill.ex | `Keyword.put(:_scrypath_fresh_target, true)` (line 54) | WIRED |
| reindex.ex | schema metadata | `Metadata.document_id(schema_module)` -> `create_index` | WIRED |
| capability.ex | verify.postgres.ex | `run_task!("verify.postgres", task_args)` | WIRED |
| verify.postgres.ex | loader_backfill_postgres_test.exs | `@postgres_tests` | WIRED |
| ci.yml | verify.backend | `SCRYPATH_POSTGRES_URL` env + `mix verify.backend` | WIRED |
| both entry tests | loader_backfill_cases.ex | `use ...LoaderBackfillCases, repo:` | WIRED |
| test_helper.exs | :postgres tag | excluded unless `SCRYPATH_POSTGRES_URL` set | WIRED |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Real data | Status |
|----------|------|--------|-----------|--------|
| Backfill batch documents | `records` | `repo.all(keyset query)` -> `Loader.prepare_records` -> `search_records/2` or `repo.preload` | Yes (real SQLite/Postgres rows) | FLOWING |
| `last_primary_key` | `values` | last DB-ordered row's PK columns | Yes | FLOWING |
| reindex `omitted` | backfill `omitted` sum | `Loader.load/3` missing ids | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Real-Postgres lane | `MIX_TEST_PARTITION=6 SCRYPATH_POSTGRES_URL=postgres://postgres:postgres@127.0.0.1:5434 mix verify.postgres` | 1 property, 13 tests, 0 failures | PASS |
| SQLite shared cases | `mix test test/scrypath/loader_backfill_sqlite_test.exs` | 1 property, 13 tests, 0 failures | PASS |
| Full core lane, no Postgres env (single full run) | `MIX_TEST_PARTITION=6 mix test` | 5 properties, 774 tests, 0 failures (25 excluded) | PASS |
| Warnings-clean build | `mix compile --warnings-as-errors --force`; `MIX_ENV=test mix compile --warnings-as-errors` | clean | PASS |
| Docs | `mix docs --warnings-as-errors` | clean | PASS |
| Credo on changed lib files | `mix credo --strict` (backfill, loader, reindex, verify.postgres) | no issues | PASS |

### Probe Execution

No probes are declared or implied for this phase. Step 7c does not apply.

### Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
|-------------|------------|--------|----------|
| LOAD-01 | 178-04, 178-05 | SATISFIED | SC1 parity case on both adapters |
| LOAD-02 | 178-04, 178-05 | SATISFIED | SC2 cases; batch-scope filter; deletes on live, counts on reindex |
| LOAD-03 | 178-03, 178-04 | SATISFIED | eu-scoped `:query` decides visited rows; offset-ignored case |
| PAGE-01 | 178-03 | SATISFIED | Full-key keyset, property test, pinned regression, binary_id |
| PAGE-02 | 178-03, 178-05 | SATISFIED | Keyword composite cursor per batch; documented in @doc |
| TEST-06 | 178-01, 178-02, 178-05 | SATISFIED in code and locally; hosted PR log is a pending PR gate | Postgres lane inside backend (required), contract-tested |

There are no orphaned requirements. REQUIREMENTS.md maps exactly these six IDs to Phase 178, and every plan's `requirements:` field is accounted for. The REQUIREMENTS.md checkboxes and traceability rows still read Pending. Updating them is a tracking task for the orchestrator.

### Anti-Patterns Found

No TBD, FIXME, XXX, TODO or HACK markers were added in any changed file. There are no stubs.

### Code review findings: independent judgment

- **WR-01 (`distinct`, union and similar clauses survive in `:query`).** This is a real silent-skip hazard for such queries on Postgres. It does not defeat a stated must-have or the phase goal:
  - The must-have truth and the guide define `:query` scope as its `where`/`join` clauses.
  - The goal is about every row of the schema. A full-schema backfill or reindex never carries these clauses, and reindex takes no `:query`.
  - The behavior predates this phase; the base commit already paged a `distinct` query this way.

  The new `@doc` sentence "every row in scope is visited exactly once" does overstate the guarantee for these unsupported clauses. I classify it as a WARNING, not a BLOCKER. The recommended follow-up is to reject these clauses with an `ArgumentError` and add a Postgres case.
- **WR-02 (public `_scrypath_fresh_target`).** WARNING. This is an unsafe option surface, but it is undocumented, and no must-have or prohibition covers caller misuse.
- **WR-03 (upgrade note).** WARNING, release-notes concern. The behavior itself is documented as the must-haves require.
- IN-01 to IN-06 are informational. None changes a truth's status. IN-04 is limited to nullable composite key columns on SQLite. IN-06 means no real-Meilisearch composite-id test exists, which is outside the stated success criteria.

### Human Verification Required

None. SC4's hosted exact-SHA run is a deterministic PR gate (see `pr_gate_evidence`), not a human check, as AGENTS.md requires.

### Gaps Summary

There are no blocking gaps. The phase goal holds in code and in executed tests on SQLite and real Postgres. One item remains before merge: push the phase commits and confirm that `backend (required)` on that exact SHA logs `loader_backfill_postgres_test.exs` with 1 property, 13 tests, 0 failures. WR-01 and WR-02 are recommended hardening for this PR or a follow-up.

---

_Verified: 2026-10-25T20:05:00Z_
_Verifier: Claude (gsd-verifier)_

## Current Verification — refreshed 2026-10-26

**Phase Goal:** A backfill or reindex produces exactly the documents inline and Oban sync would produce, for every row of the schema, whatever its primary-key shape.

**Current source:** `f718c4a92de95277d6859b134121083448335271`. No application, test, dependency, CI, example, or documentation files are dirty. The implementation files are identical to hosted source `433c8343f92df761398eac07c4c92298e4b9b160`; the v1.44 backend job 121736431228 passed the Postgres suite there (1 property, 15 tests, 0 failures). This report also records a fresh local Postgres run below. The hosted receipt remains bound to `433c8343`, not claimed as a run on planning-only HEAD `f718c4a`.

### Observable Truths

| # | Roadmap truth | Status | Current evidence |
|---|---|---|---|
| 1 | `preload:` backfill and reindex documents equal inline sync documents | VERIFIED | Shared case `backfill, reindex, inline and Oban-loader documents are identical for preload:` in `test/support/loader_backfill_cases.ex`; `backfill.ex` routes batches through `Loader.prepare_records/3`, whose default loader force-preloads the schema declaration. The targeted suite and real-Postgres suite passed. |
| 2 | `search_records/2` loads each batch, omitted rows are removed, and caller `:query` scope controls visited rows | VERIFIED | Shared case `search_records/2 loads every batch; the :query scope decides rows` checks loader calls, scoped IDs, omitted-row deletion, and the public index result. `backfill.ex` advances on the database page cursor and filters returned records to that page. SQLite and Postgres runs passed. |
| 3 | Composite keyset paging visits each row once and reports a full cursor | VERIFIED | The shared composite-key property exercises repeated leading keys across page boundaries, exact visitation, and keyword cursors; current SQLite and Postgres runs each reported 1 property passing. `backfill.ex` builds the portable lexicographic Ecto predicate and shapes the cursor from all primary-key columns. |
| 4 | Real Postgres loader/backfill cases run through the existing backend CI lane | VERIFIED | Fresh local `mix verify.postgres`: 1 property, 15 tests, 0 failures. `verify.backend` dispatches to `verify.postgres`; `.github/workflows/ci.yml` sets the dedicated URL in the existing `backend (required)` job. Hosted exact-implementation evidence is the backend job cited above. |

### Required Artifacts and Key Links

| Artifact/link | Status | Evidence |
|---|---|---|
| `lib/scrypath/backfill.ex` → `lib/scrypath/loader.ex` | VERIFIED / WIRED | Page query rows flow into `Loader.prepare_records/3`; same path is exercised by preload, custom loader, omission, and Postgres shared cases. |
| Composite keyset and cursor | VERIFIED / WIRED | `keyset_after/2` builds all-column Ecto predicates; shared property plus pinned `{1,3}` regression and binary-ID key case pass. |
| `lib/scrypath/reindex.ex` → `lib/scrypath/backfill.ex` | VERIFIED / WIRED | Managed reindex passes the fresh-target option, waits on write/delete task lists, and reports omissions; `reindex_test.exs` is in the passing targeted run. |
| `verify.backend` → `verify.postgres` → real Postgres test module | VERIFIED / WIRED | `verify_capability_test.exs`, `verify_postgres_test.exs`, workflow contract, and the live local Postgres command all pass. |
| Test/report pattern checks | VERIFIED | GSD artifact query passed all 21 plan artifacts; all 13 plan key links passed. The shared cases are called by both SQLite and Postgres test entry modules. |

### Requirements Coverage

| Requirement | Status | Current evidence |
|---|---|---|
| LOAD-01 | SATISFIED | Preload parity case compares backfill, reindex, inline and Oban-loader documents. |
| LOAD-02 | SATISFIED | Custom-loader batch, omitted-ID removal and outside-page filtering cases pass on both adapters. |
| LOAD-03 | SATISFIED | Scoped query case preserves where/join selection while removing paging-conflicting query clauses. |
| PAGE-01 | SATISFIED | Composite-key property, boundary regression and binary-ID second-key case pass on SQLite and Postgres. |
| PAGE-02 | SATISFIED | Property asserts a full ordered keyword cursor for every composite batch; single-key cases retain scalar cursors. |
| TEST-06 | SATISFIED | Fresh Postgres lane passed locally; the existing required backend lane is wired and has hosted evidence on identical implementation bytes. |

No phase-mapped requirement is orphaned. All 5 phase plans' artifact and key-link checks were run; the roadmap criteria remain the score basis.

### Data-Flow Trace

| Output | Source | Status |
|---|---|---|
| Backfill documents | Scoped Ecto page query → `Loader.prepare_records/3` (custom loader or declared preload) → projection → backend writes | FLOWING; same cases pass on SQLite and Postgres. |
| Composite cursor | Last database-ordered row → every primary-key column in schema order → batch result | FLOWING; property asserts the complete keyword cursor and increasing pages. |
| Omitted/removal counts | Batch IDs compared to `search_records/2` output → live delete calls or fresh-target omission count | FLOWING; shared cases assert actual IDs and removal counts. |

### Behavioral Spot-Checks

| Command | Result |
|---|---|
| `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test MIX_TEST_PARTITION=6 mix test test/scrypath/loader_backfill_sqlite_test.exs test/scrypath/backfill_test.exs test/scrypath/reindex_test.exs test/scrypath/loader_test.exs test/scrypath/chunks_test.exs test/scrypath/sync_test.exs test/scrypath/oban/enqueue_test.exs test/scrypath/oban/enqueue_unique_test.exs test/scrypath/oban/job_args_test.exs test/scrypath/oban/worker_test.exs test/scrypath/sync/related_test.exs test/scrypath/sync/related_worker_test.exs test/scrypath/oban/worker_telemetry_test.exs test/scrypath/telemetry_test.exs test/scrypath/telemetry_contract_test.exs test/scrypath/backfill_contract_docs_test.exs test/scrypath/docs_contract_test.exs test/release/package_metadata_test.exs --include docs_contract --exclude integration` | 1 property, 405 tests, 0 failures. |
| `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test MIX_TEST_PARTITION=6 SCRYPATH_POSTGRES_URL=postgres://postgres:postgres@127.0.0.1:5434 mix verify.postgres` | 1 property, 15 tests, 0 failures. |

### Anti-Patterns, Decision Coverage, and Human Verification

No unresolved `TBD`, `FIXME`, or `XXX` debt markers, stubs, or unwired artifacts were found in covered files. The marker scan's `JTBD` matches are guide names, not debt markers. No disabled requirement test or test-side expected-value file writer was found. This is an infrastructure/library phase; all roadmap truths have executable evidence, so there is no manual verification item.

### Decision Coverage

17/17 decisions honored. All trackable CONTEXT.md decisions are honored by shipped artifacts.

### Probe Execution

No probes are declared or implied by these phase plans; not applicable.

### Recorded Limits and Debt

The earlier three warnings and six informational items remain carried forward, not erased by this refresh: unsupported query clauses such as `distinct`/`group_by` remain outside the documented where/join scope; `_scrypath_fresh_target` remains accepted by the public option schema; visited IDs omitted by `search_records/2` need release-facing upgrade notice. The historical report above retains the individual WR/IN details. These do not contradict the scoped phase truths.

**Current result:** PASSED — 4/4 roadmap truths and all 6 phase requirements are verified. No overrides were applied; no human approval or independent review is implied.
