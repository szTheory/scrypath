---
phase: 180-oban-worker-telemetry
plan: 02
subsystem: observability-docs
status: complete
tags: [telemetry, docs, hexdocs, oban, related-worker]
requires: []
provides:
  - guides/telemetry.md canonical catalog (17 events, six fixed columns) for the 180-03 contract test
  - RelatedWorker 4xx cancel reason {:cancel, {:http_error, status}}
affects:
  - docs/search-backend-sre.md
  - guides/per-query-tuning-pipeline.md
  - ARCHITECTURE.md
  - guides/related-data-and-reindexing.md
tech-stack:
  added: []
  patterns:
    - "Telemetry catalog table grammar: | Event | Kind | Measurements | Start metadata | Stop-only metadata | When |, backticked keys with literal ' (optional)' suffix, em dash for none"
key-files:
  created:
    - guides/telemetry.md
  modified:
    - mix.exs
    - test/release/package_metadata_test.exs
    - test/scrypath/docs_contract_test.exs
    - docs/search-backend-sre.md
    - guides/per-query-tuning-pipeline.md
    - ARCHITECTURE.md
    - lib/scrypath/sync/related_worker.ex
    - test/scrypath/sync/related_worker_test.exs
    - guides/related-data-and-reindexing.md
decisions:
  - "Existing-event rows list keys from current lib behavior; keys that only appear conditionally (common_metadata sync_mode/repo, result-derived stop keys, request extras) are marked (optional)"
  - "Stop-only columns omit keys that already appear in start metadata (for example document_count on sync spans, schema_count on search_many); the Reading the table section says stop can repeat start keys with final values"
  - "CHANGELOG.md not hand-edited (Release Please owns it); release-note lines recorded below for the squash commit"
metrics:
  duration: ~35m
  completed: 2026-10-25
estimate:
  tokens: 50000
  tasks: 3
actuals:
  tokens: 6000
  tasks: 3
  commits: 4
plan_head_before: cd83c4acdd88d03bbacd398f9a84cc2bb98d23e6
plan_head_after: ba7a66867399c32aee76e54f1e85d4745c93f1fd
---

# Phase 180 Plan 02: Telemetry guide and related-worker cancel shape Summary

New `guides/telemetry.md` is now the only Scrypath event catalog. It has one parseable 17-row table, with prose on joining Oban events, outcome and cancel vocabularies, missing-record removals, cardinality, and dashboards. The SRE doc and per-query guide now link to it instead of keeping their own tables. The related worker now cancels a backend 4xx with `{:http_error, status}` and drops the response body.

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Tracer: telemetry guide registered in HexDocs and package/docs tests | eecb40ba | guides/telemetry.md, mix.exs, test/release/package_metadata_test.exs, test/scrypath/docs_contract_test.exs |
| 2 | Collapse duplicate tables into pointers; ARCHITECTURE observability bullet | 75b35c1a | docs/search-backend-sre.md, guides/per-query-tuning-pipeline.md, ARCHITECTURE.md, test/scrypath/docs_contract_test.exs |
| 3 (RED) | Pin 4xx cancel reason without body | 4963a8e4 | test/scrypath/sync/related_worker_test.exs |
| 3 (GREEN) | RelatedWorker 4xx cancel `{:http_error, status}` + guide row | ba7a6686 | lib/scrypath/sync/related_worker.ex, guides/related-data-and-reindexing.md |

Tracer gate: `mix docs --warnings-as-errors` and the package and docs-contract tests were re-run and passed before the expansion tasks.

## Verification

- `mix docs --warnings-as-errors`: exit 0, no doc warnings. `doc/telemetry.html` is generated in the Operations group.
- `mix test test/release/package_metadata_test.exs test/scrypath/sync/related_worker_test.exs test/scrypath/docs_contract_test.exs --include docs_contract`: 101 tests, 0 failures.
- `mix verify.phase108`: 6 tests, 0 failures.
- `MIX_ENV=test mix compile --warnings-as-errors --force`: clean.
- `mix format --check-formatted`: clean.
- Acceptance greps:
  - telemetry.md has 17 `| \`[:scrypath` rows, 1 exact header, 14 `(optional)` markers, and 0 OBS-NN/(D-NN) strings.
  - mix.exs has 2 references, the package test 2, and the OBS- hygiene pattern is present.
  - The SRE and per-query docs have 0 event rows. `## Telemetry catalog` is kept. ARCHITECTURE links the guide, and the old Oban sentence is gone.
  - The related-worker and guide tuple greps each return 1, and the `HTTP #{status}` grep returns 0. CHANGELOG.md is not in the plan diff.

## Read-only scrypath_ops check (D-18)

`grep -rn "HTTP 4" scrypath_ops/lib` found no matches. `grep -rn "http_error" scrypath_ops/lib` found only `document_observation.ex`'s own `:document_observation_http_error` / `:index_observation_http_error` atoms and `posture_live.ex:617` `fetch_error_copy({:http_error, status, _body})`, which matches its own fetch errors and not the related-worker cancel reason. Nothing parses the old cancel string, so there is no follow-up.

Note: `Scrypath.Operator.FailedWork.Translation` classifies by regex on status codes in the error text (`\b(401|403|408|429|50x)\b`). The new inspected reason `{:http_error, 403}` still contains the code, so classification is the same. The one difference is that backend body text such as `invalid_state` is no longer present to trigger `:backend_rejected` for a related-worker 4xx cancel. That follows directly from dropping the body.

## Release note

CHANGELOG.md was not hand-edited because Release Please owns it. Use these verbatim lines at ship time:

- Squash subject: `feat(telemetry): Oban upsert and delete job spans, missing-record removal event, and a telemetry guide`
- Extra conventional line for the squash body: `fix(sync): related worker cancels backend 4xx with {:http_error, status} and no longer stores the response body`

## Deviations from Plan

None. The plan was executed as written. One environment note: the worktree had no `deps/`, so `deps` was symlinked to the main checkout's deps for local builds. The symlink is untracked and not committed.

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: guides/telemetry.md
- FOUND: eecb40ba, 75b35c1a, 4963a8e4, ba7a6686 (all ancestors of HEAD)
