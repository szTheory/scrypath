---
phase: 180-oban-worker-telemetry
plan: 03
subsystem: telemetry
status: complete
requirements-completed: [OBS-03]
tags: [telemetry, contract-test, docs-drift, oban, observability]
requires:
  - "180-01: worker spans, missing_removed event, ObanTelemetryScenarios.run/1"
  - "180-02: guides/telemetry.md 17-row catalog table"
provides:
  - "Scrypath.TestSupport.TelemetryContract (parse_guide/1, scan_event_names/1, diff/2, compare/2, non_literal_sites/1, key_check/3, resolve_event/2)"
  - "test/scrypath/telemetry_contract_test.exs: untagged OBS-03 drift contract in the core CI lane"
affects: [guides/telemetry.md (now enforced), lib/**/*.ex telemetry call sites (literal names enforced)]
tech-stack:
  added: []
  patterns:
    - "Pure contract helpers over strings and {path, source} tuples; the test does the file I/O, so negative proofs run on in-memory fixtures"
    - "AST scan (Code.string_to_quoted/2 + Macro.prewalk/3) for event literals and for computed-name call sites, tagged with the enclosing def name/arity"
    - "compare/2 refuses empty sets on either side so an empty guide or empty scan never passes vacuously"
key-files:
  created:
    - test/support/telemetry_contract.ex
    - test/scrypath/telemetry_contract_test.exs
  modified: []
decisions:
  - "Guide keys are converted with String.to_atom/1, not to_existing_atom: lazy module loading made to_existing_atom seed-dependent (search_scope was not yet loaded in one order). Keys come from the repo's own guide, not user input."
  - "Added compare/2 and resolve_event/2 beyond the planned interface: compare/2 owns the non-vacuous rule and the sorted failure message; resolve_event/2 maps captured names to {row, phase}"
  - "Key contract scenarios are the plan's nine (upsert_missing/ok/legacy/error/cancel/raise, delete_ok/error/raise); a coverage assertion requires start/stop/exception for both spans plus the missing_removed event"
metrics:
  duration: "~25m"
  completed: 2026-10-25
estimate:
  tokens: 45000
  tasks: 3
actuals:
  tokens: 6417
  tasks: 3
  commits: 3
plan_head_before: 472531d179912dcdac5412b6901db3aa458c5fed
plan_head_after: d87aca2e2d702dba5c639259636b6f3e497ba06e
---

# Phase 180 Plan 03: Telemetry drift contract Summary

A new untagged contract test fails when `guides/telemetry.md` and the events Scrypath emits drift apart. It checks three things. Event names must match in both directions: the guide's 17 rows against an AST scan of `lib/**/*.ex`. Every `span`/`execute` call in `lib/` must pass a literal event name; the one exception is the allowlisted `Scrypath.Telemetry.span/3` wrapper. For the three Oban worker events, the metadata keys must match the guide in every phase. Because the file has no tag, the core CI lane (`--exclude integration --exclude docs_contract`) runs it.

## Tasks

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 (tracer) | Guide parser + AST name scan, bidirectional name equality | ca373fbc | test/support/telemetry_contract.ex, test/scrypath/telemetry_contract_test.exs |
| 2 | Literal-name guard + single-catalog check | 87d61edb | same |
| 3 | Key-level contract for the three worker events | d87aca2e | same |

Tracer gate: after Task 1, `mix test test/scrypath/telemetry_contract_test.exs` passed (10 tests) before the expansion tasks started. Running it with the core-lane exclude flags ran the same 10 tests with nothing excluded.

## What the test proves

- **Names:** the guide event set equals the scanned set and has 17 entries. In-memory negative proofs cover these cases:
  - Removing only the longer name of a pair that shares a prefix (`missing_removed`, `search_many.partial`) reports exactly that name as emitted but not documented.
  - An extra `[:scrypath, :nope]` row is reported as documented but not emitted.
  - An empty guide, a single-row guide, and an empty scan each fail with a message.
  - Shuffled rows parse to the same result, and diff output is sorted.
  - Names that appear only in `@moduledoc`/`@doc` text are ignored.
  - Duplicate, wrong-kind, and short rows raise.
- **Guard:** fixtures show that `:telemetry.execute(@prefix ++ [:x], ...)` is reported with its line and `{:emit, 0}`, and that variable names passed to `Telemetry.span`/`Scrypath.Telemetry.span` are reported. `Telemetry.emit(row)` under the FailedWork alias and literal calls are not reported. A stale-allowlist assertion fails if the wrapper site disappears.
- **Single catalog:** no file under `guides/` or `docs/`, and neither `README.md` nor `ARCHITECTURE.md`, has a `` | `[:scrypath `` row, except `guides/telemetry.md`.
- **Keys:** handlers capture real worker runs across nine scenarios. For each event the test checks that the required keys are present and that every emitted key is documented. Implicit keys are allowed: `telemetry_span_context` on span events, plus `kind`, `reason`, and `stacktrace` on `:exception` events. The `missing_removed` measurements must be exactly `count`. A coverage assertion requires every worker phase to fire at least once. Negative proofs: dropping `attempt` from the guide makes it undocumented, and adding a required `bogus` key makes it missing.
- **Manual mutation check (not committed):** removing `` `attempt`, `` from the delete row of the real guide made 2 tests fail with `delete_ok: [:scrypath, :oban, :delete, :start] metadata keys drift from the guide: %{missing_required: [], undocumented: [:attempt]}`. The guide was then restored with `git checkout -- guides/telemetry.md`.

The guide and emitted keys already agreed, including 180-01's upsert backend-error stop that keeps `source`, `upserted_count`, and `missing_count` (all marked `(optional)` in the guide). No guide row needed a fix.

## Verification

- `mix test --warnings-as-errors test/scrypath/telemetry_contract_test.exs test/scrypath/oban/worker_telemetry_test.exs test/scrypath/telemetry_test.exs test/scrypath/oban/worker_test.exs test/scrypath/sync/related_worker_test.exs`: 108 tests, 0 failures
- `mix test --warnings-as-errors --exclude integration --exclude docs_contract test/scrypath`: 720 tests, 5 properties, 0 failures
- `mix test test/scrypath/docs_contract_test.exs test/release/package_metadata_test.exs --include docs_contract`: 79 tests, 0 failures
- `mix format --check-formatted`, `MIX_ENV=test mix compile --warnings-as-errors`, `mix credo --strict` (no issues), `mix verify.no_optional_deps`, `mix docs --warnings-as-errors`: all clean
- Acceptance greps: `moduletag`/`docs_contract` in the test file = 0; `Code.string_to_quoted` in the support module = 2; `File.`/`Path.wildcard` in the support module = 0; `def non_literal_sites` = 1; `def key_check` = 1; the allowlist literal = 1; `ObanTelemetryScenarios.run` = 1
- **Not run here:** the full `mix verify.core`. Its test step runs the unfiltered suite, including `verify_phoenix_example_package_test.exs`, which mutates the shared `deps/` (environment note from wave 1). Its other steps were run individually as listed above. The orchestrator runs the full suite after merge, and hosted CI on the exact SHA covers the core lane.

## Deviations from Plan

**1. [Rule 1 - Bug] Seed-dependent key atom conversion**
- **Found during:** Task 1
- **Issue:** `String.to_existing_atom/1` on guide keys raised for `search_scope` under some seeds, because the module using that atom was not loaded yet.
- **Fix:** Use `String.to_atom/1`. The input is the repo's own guide, and credo passes.
- **Commit:** ca373fbc

**2. [Rule 2 - Correctness] Added `compare/2` and `resolve_event/2`**
- `compare/2` makes empty sets fail explicitly, as the OBS-03 empty edge requires. A plain set diff of two empty sets would pass.
- `resolve_event/2` keeps the mapping from event name to row and phase in the pure module.
- **Commits:** ca373fbc, d87aca2e

## Known Stubs

None.

## Threat Flags

None. The change is test-only. T-180-08 is mitigated because the file is untagged and runs under the core-lane flags with 0 excluded. T-180-09 is mitigated by the AST guard, the one-entry allowlist, and the stale-entry check. T-180-10 is mitigated by the coverage assertion.

## Self-Check: PASSED

- FOUND: test/support/telemetry_contract.ex
- FOUND: test/scrypath/telemetry_contract_test.exs
- FOUND commits: ca373fbc, 87d61edb, d87aca2e (ancestors of HEAD)
