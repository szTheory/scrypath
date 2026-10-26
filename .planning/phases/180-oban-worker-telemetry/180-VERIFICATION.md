---
phase: 180-oban-worker-telemetry
verified: 2026-10-25T23:00:00Z
status: passed
score: 3/3 roadmap success criteria verified (39/39 merged must-haves verified, 3 via documented review-fix deltas)
covered_files: [".planning/phases/180-oban-worker-telemetry/180-01-PLAN.md", ".planning/phases/180-oban-worker-telemetry/180-01-SUMMARY.md", ".planning/phases/180-oban-worker-telemetry/180-02-PLAN.md", ".planning/phases/180-oban-worker-telemetry/180-02-SUMMARY.md", ".planning/phases/180-oban-worker-telemetry/180-03-PLAN.md", ".planning/phases/180-oban-worker-telemetry/180-03-SUMMARY.md", "ARCHITECTURE.md", "docs/search-backend-sre.md", "guides/per-query-tuning-pipeline.md", "guides/related-data-and-reindexing.md", "guides/telemetry.md", "lib/scrypath/oban/delete_worker.ex", "lib/scrypath/oban/upsert_worker.ex", "lib/scrypath/sync/related_worker.ex", "lib/scrypath/telemetry.ex", "mix.exs", "test/release/package_metadata_test.exs", "test/scrypath/docs_contract_test.exs", "test/scrypath/oban/worker_telemetry_test.exs", "test/scrypath/sync/related_worker_test.exs", "test/scrypath/telemetry_contract_test.exs", "test/scrypath/telemetry_test.exs", "test/support/oban_telemetry_scenarios.ex", "test/support/telemetry_capture.ex", "test/support/telemetry_contract.ex"]
covered_digest: "v3:sha256:122872723683aa124c7634adc3018137018398c436951b50feb889c1ba7f3abf"
behavior_unverified: 0
overrides_applied: 0
pending_hosted_evidence:
  - "Hosted CI (mix verify.core --exclude integration --exclude docs_contract) has not run on this branch's exact SHA yet; local runs only. Attach exact-SHA CI evidence at PR time."
---

# Phase 180: Oban worker telemetry Verification Report

**Phase Goal:** Operators can observe every Oban upsert and delete job, including deletes for records that no longer exist, through stable, documented telemetry.
**Verified:** 2026-10-25T23:00:00Z
**Status:** passed
**Re-verification:** No (initial verification)

## Goal Achievement

### Roadmap Success Criteria

| # | Success criterion | Status | Evidence |
|---|-------------------|--------|----------|
| 1 | A test attaching telemetry handlers sees start, stop and exception events from the Oban upsert and delete workers, each carrying schema, index, backend, document count and attempt | VERIFIED | `lib/scrypath/oban/{upsert,delete}_worker.ex` wrap the post-decode work in `Telemetry.span([:scrypath, :oban, :upsert / :delete], ...)` with start metadata from `Telemetry.job_start_metadata/5` (schema, backend, index, `sync_mode: :oban`, attempt, max_attempts, distinct `document_count`, optional repo). `worker_telemetry_test.exs` asserts the exact start map, the stop map (start plus `outcome`), and the raise path (one `:exception`, no `:stop`, error propagates) for both workers. Tests pass. |
| 2 | A test shows that when a job finds ids with no current record and deletes them from the index, an event fires with the count of those ids | VERIFIED | `upsert_worker.ex` emits `[:scrypath, :oban, :upsert, :missing_removed]` with `%{count: Chunks.distinct_count(missing_ids)}` inside a `with` that runs only after the upsert write and every delete chunk returned `:ok`. The `missing_removed event` describe block covers count 1, 1,500 ids over two chunks, repeated ids counted once, no event when nothing is missing, no event when a delete chunk fails (stop reports `:error`/`:timeout`), and no event on the legacy path. |
| 3 | The telemetry guide lists the new events and metadata keys, and its docs contract test fails if a documented event or key drifts from the emitted ones | VERIFIED | `guides/telemetry.md` has 17 event rows, including the three worker events with their keys. It is registered in `mix.exs` extras and the Operations group. `test/scrypath/telemetry_contract_test.exs` (untagged, so CI's core lane runs it) checks name-set equality in both directions against an AST scan of `lib/`, enforces literal event names, checks that the guide is the only event table, and checks the worker-event keys against real worker runs. Its in-memory negative proofs show the test fails on drift. Key-level checks cover only the three new worker events. That scope is documented in the guide (IN-05) and matches D-17. |

### Observable Truths (plan must_haves merged)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Worker spans emitted via `Telemetry.span/3` with literal names (D-01) | VERIFIED | Source read; the contract test's literal-name guard passes |
| 2 | Start metadata: schema, backend, index, sync_mode :oban, attempt, max_attempts, distinct document_count, optional repo (D-05) | VERIFIED (review delta) | Now built by the shared `Telemetry.job_start_metadata/5` (IN-03). `index` is `job.index`, not a recomputed name (WR-01; regression tests in the `index tag` block) |
| 3 | Stop adds outcome, plus error_kind only on :error and cancel_reason only on :cancel (atom head, :invalid_job stripped); no result_kind; document_count unchanged | VERIFIED | `job_stop_metadata/1` and private `cancel_reason/1`. The delete test refutes error_kind, cancel_reason and result_kind on an ok stop. The uncastable-id test checks the `:invalid_arg` head |
| 4 | Upsert stop carries source, upserted_count and missing_count only when a plan exists; legacy missing_count 0 | VERIFIED (review delta) | `upserted_count` is now the distinct written-id count (WR-04, duplicate-row regression test). It is kept on a backend error, which matches D-06 "counts describe the plan" (01-SUMMARY deviation 1) |
| 5 | Decode or config failure returns `{:cancel, {:invalid_job, tag}}` and emits no worker event (D-02) | VERIFIED | `with ... else` sits outside the span. "a job that fails decode emits no worker event" passes for both workers |
| 6 | A raising backend gives exactly one :exception carrying the start metadata, no :stop, and the exception propagates (D-07) | VERIFIED | Raise tests for both workers. The contract key check covers the `:exception` phase |
| 7 | missing_removed fires once, with count equal to the distinct missing ids and metadata equal to the start metadata, after all deletes succeed (D-09/D-10) | VERIFIED | `removed.metadata == without_span_context(start.metadata)`; ordering test `[start, missing_removed, stop]` |
| 8 | One start and one stop per job regardless of chunks; nested Meilisearch spans unchanged (D-03) | VERIFIED | The 1,001-id two-chunk test. `git diff` shows no Meilisearch changes |
| 9 | No tuple or list metadata values outside the exempt keys (D-08) | VERIFIED | The `metadata cardinality` test walks every scenario |
| 10 | Boundary edges: [] ids, 1,001 ids, attempt 8 of 8 | VERIFIED | Named tests in the delete describe block |
| 11 | Precision edge: [1,1,2] gives document_count 2 | VERIFIED | "repeated ids are counted once on start and stop" (the `:a` identity example cannot be built through decode; recorded in 01-SUMMARY) |
| 12 | Idempotency and concurrency edges | VERIFIED | `job independence` describe block |
| 13 | OBS-02 boundary and precision edges (0, 1, 1,500, failing chunk, [404,404,1]) | VERIFIED | `missing_removed event` describe block |
| 14 | Legacy path never emits missing_removed | VERIFIED | Named test |
| 15 | Guide registered in mix.exs extras and the Operations group; package test asserts the list (D-14) | VERIFIED | `mix.exs:217,255`; `package_metadata_test.exs:83,93`; docs_contract plus package tests 79/0 |
| 16 | Guide has exactly 17 rows with the fixed header and grammar (D-15/D-16, `(optional)` suffix) | VERIFIED | grep count 17; header at line 20; the parser in the contract test enforces the grammar and raises on malformed rows |
| 17 | Prose: Oban join, cardinality, counting, outcome authority, cancel_reason and error_kind vocabularies, missing_removed semantics | VERIFIED (review delta) | Sections at guide lines 40-104. The delete row no longer lists `cancel_reason`, and `:cancel` is documented as upsert-only (IN-01). This matches the code: the delete worker never returns `{:cancel, _}` inside the span. Boundedness is scoped to the worker spans (WR-03), and the final-attempt and cancel recipes were corrected (WR-02, WR-05) |
| 18 | SRE and per-query docs have no event rows and link to the guide; the `## Telemetry catalog` heading is kept | VERIFIED | Single-catalog test; links at `search-backend-sre.md:23` and `per-query-tuning-pipeline.md:87` |
| 19 | ARCHITECTURE Observability links the guide | VERIFIED | `ARCHITECTURE.md:172` |
| 20 | RelatedWorker 4xx returns `{:cancel, {:http_error, status}}` with no body; 5xx unchanged (D-18) | VERIFIED | `related_worker.ex:83-84`; related_worker tests pass |
| 21 | CHANGELOG not hand-edited (D-19) | VERIFIED | Not in `git diff cd83c4ac..HEAD` |
| 22 | docs_contract bans OBS-NN IDs; guide is in @guide_paths | VERIFIED | grep finds 0 OBS/D-NN strings in published docs; docs_contract suite green |
| 23-31 | 180-03 contract truths: bidirectional name equality (17), doc-text names ignored, literal guard with a one-entry allowlist, key contract across 9 scenarios with implicit keys, single catalog, untagged/core lane, prefix adjacency, empty/vacuous fixtures, set ordering | VERIFIED | Named tests in `telemetry_contract_test.exs` (event names, literal event names, single catalog, worker event keys); no `moduletag` or `docs_contract` in the file; CI runs `mix verify.core --exclude integration --exclude docs_contract` (`ci.yml:35`) |

**Score:** All 3 roadmap success criteria and all merged plan truths verified. 0 present-but-behavior-unverified.

### Review-fix deltas against PLAN wording (accepted as satisfying intent)

| Delta | Plan wording | Now | Goal impact |
|-------|--------------|-----|-------------|
| IN-03 | private `start_metadata/3` per worker | shared `Telemetry.job_start_metadata/5` | None; the same keys, asserted by an exact-map test |
| WR-01 | index from config | `job.index` (where the job actually writes) | Improves accuracy; regression test |
| WR-04/IN-02 | upserted_count = documents planned | distinct written-id count | Improves accuracy; regression test; guide wording updated |
| IN-01 | delete row lists cancel_reason (optional) | delete row is `outcome`, `error_kind` (optional) only | Correct: the delete span cannot produce `:cancel`, and the key contract would otherwise allow a key that never appears |
| IN-06 (accepted) | — | related 4xx non-auth codes classify `:unknown` in FailedWork | Outside the worker-telemetry goal; intended effect of D-18 |

None of these deltas break the goal.

### Required Artifacts

| Artifact | Status | Details |
|----------|--------|---------|
| `lib/scrypath/telemetry.ex` | VERIFIED | `job_start_metadata/5` and `job_stop_metadata/1` are `@doc false` and Oban-free; module stays `@moduledoc false` |
| `lib/scrypath/oban/delete_worker.ex` | VERIFIED | Span wired at the D-02 boundary |
| `lib/scrypath/oban/upsert_worker.ex` | VERIFIED | Span, facts threading, and the `missing_removed` emit |
| `test/support/telemetry_capture.ex` | VERIFIED | Global handler with `on_exit` detach; documents the async: false requirement (IN-08) |
| `test/support/oban_telemetry_scenarios.ex` | VERIFIED | Used by the worker tests and by the contract key check |
| `test/scrypath/oban/worker_telemetry_test.exs` | VERIFIED | 30+ behavior tests |
| `guides/telemetry.md` | VERIFIED | 17 rows; registered in HexDocs |
| `mix.exs` | VERIFIED | extras and Operations group |
| `lib/scrypath/sync/related_worker.ex` | VERIFIED | `{:cancel, {:http_error, status}}` |
| `test/support/telemetry_contract.ex` | VERIFIED | Pure parse, scan, guard and key functions |
| `test/scrypath/telemetry_contract_test.exs` | VERIFIED | Untagged drift contract |

### Key Link Verification

| From | To | Via | Status |
|------|----|-----|--------|
| upsert_worker.ex | telemetry.ex | `Telemetry.span([:scrypath, :oban, :upsert], ...)` plus `Telemetry.job_stop_metadata(result)` | WIRED |
| delete_worker.ex | telemetry.ex | `Telemetry.span([:scrypath, :oban, :delete], ...)` | WIRED |
| upsert_worker.ex | chunks.ex | `Chunks.distinct_count` for missing_count, upserted_count and the event count (document_count goes through job_start_metadata) | WIRED |
| mix.exs | guides/telemetry.md | extras and groups_for_extras | WIRED |
| docs/search-backend-sre.md | guides/telemetry.md | `../guides/telemetry.md` | WIRED |
| guides/per-query-tuning-pipeline.md | guides/telemetry.md | `(telemetry.md)` | WIRED |
| telemetry_contract_test.exs | guides/telemetry.md | File.read! then parse_guide | WIRED |
| telemetry_contract_test.exs | oban_telemetry_scenarios.ex | `ObanTelemetryScenarios.run` | WIRED |
| .github/workflows/ci.yml | telemetry_contract_test.exs | core lane excludes only integration and docs_contract; the file is untagged | WIRED |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Real data | Status |
|----------|------|--------|-----------|--------|
| Worker start metadata | attempt, max_attempts | `%Oban.Job{}` fields | Yes | FLOWING |
| Worker start metadata | document_count | `job.document_ids` decoded from args | Yes | FLOWING |
| missing_removed count | missing_ids | `Loader.load/3` third element | Yes | FLOWING |
| Upsert stop facts | source, upserted_count, missing_count | load result or legacy snapshot | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Phase-scoped tests | `mix test test/scrypath/telemetry_contract_test.exs test/scrypath/oban/worker_telemetry_test.exs test/scrypath/telemetry_test.exs test/scrypath/oban/worker_test.exs test/scrypath/sync/related_worker_test.exs` | 112 tests, 0 failures | PASS |
| Full non-integration suite (one run) | `mix test --exclude integration` | 5 properties, 1000 tests, 0 failures (27 excluded) | PASS |
| Docs and package contracts | `mix test test/scrypath/docs_contract_test.exs test/release/package_metadata_test.exs --include docs_contract` | 79 tests, 0 failures | PASS |

### Probe Execution

Not applicable: the phase declares no probes.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| OBS-01 | 180-01 | Worker spans (start, stop, exception) with schema, index, backend, document count, attempt | SATISFIED | SC1 evidence |
| OBS-02 | 180-01 | Missing-id deletion emits an event with the count | SATISFIED | SC2 evidence |
| OBS-03 | 180-02, 180-03 | Guide and contract test list the new events and keys | SATISFIED | SC3 evidence |

No orphaned requirements: REQUIREMENTS.md maps only OBS-01..03 to Phase 180, and every one is claimed by a plan. The REQUIREMENTS.md checkboxes and traceability rows still read Pending; the orchestrator should flip them at phase completion.

### Prohibitions (judgment-tier, each backed by deterministic evidence)

| Prohibition | Evidence | Disposition |
|-------------|----------|-------------|
| No ids, bodies, tuples or input-derived atoms in worker metadata | Cardinality test; `cancel_reason/1` only pattern-matches existing atoms (no `String.to_atom`) | resolved |
| No reuse of `[:scrypath, :sync, ...]`, no per-chunk spans, no RelatedWorker job span | `git diff` of related_worker.ex adds no span; contract name equality would fail on any undocumented new event | resolved |
| Decode or config failure emits no Scrypath event | Decode tests for both workers | resolved |
| missing_removed not before all chunks, not per chunk, not on legacy | Chunk-fail, 1,500-id and legacy tests | resolved |
| No Logger line for removals; 4xx retry semantics unchanged for upsert/delete | grep shows `Logger` = 0 in upsert_worker.ex; worker_test.exs green | resolved |
| Only guides/telemetry.md holds an event table | Single-catalog test | resolved |
| No OBS/D-NN IDs in published docs; Telemetry stays @moduledoc false | docs_contract green; grep 0; source read | resolved |
| scrypath_ops not edited | `git diff cd83c4ac..HEAD -- scrypath_ops` is empty | resolved |
| Contract not in a CI-excluded file; no repo mutation in negative proofs | No tag in the file; negative proofs use in-memory fixtures | resolved |

### Anti-Patterns Found

None. No TBD, FIXME or XXX in the phase-modified files, and no stubs or empty implementations in the worker paths.

### Human Verification Required

None. Every truth is backed by an executable test.

### Pending PR Evidence (not a human item)

Hosted CI has not yet run on this branch's exact SHA. All evidence above is local (Elixir 1.19.5 / OTP 28.5). The core lane (`mix verify.core --exclude integration --exclude docs_contract`) will run the new untagged contract test. Attach the exact-SHA run to the PR.

### Gaps Summary

No gaps. The workers emit one span per job with stable tags. Missing-record removals are now visible through a counted point event that fires only after the deletes are confirmed. The guide is the single catalog, and an untagged contract test in the core CI lane keeps it in sync with the code. Review-fix deltas from the PLAN wording are justified, covered by tests, and improve accuracy without weakening the goal.

---

_Verified: 2026-10-25T23:00:00Z_
_Verifier: Claude (gsd-verifier)_
