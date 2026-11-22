---
phase: 196-fixtures-and-three-adopters
plan: 04
subsystem: testing
tags: [fixtures, shopadelic, wikily, logistify, meilisearch, index-contract-drift, check-task, child-mix, adr-0002]

requires:
  - phase: 196-fixtures-and-three-adopters
    provides: "plan 01's builders, fake client, Scenario, FixtureEnv and the check skeleton; plan 03's recordings (the default settings and the 404 body) and the closed failure table"
provides:
  - "Ten registered scenarios across the three adopters, built from raw wire shapes only: Logistify deep_queue, steady and a labelled F1 stress variation; Shopadelic settings_aligned, settings_drift and failed_journey; Wikily unconfigured, missing_backend, index_not_created and first_delete_failed"
  - "ScrypathFixtures.AppliedSettings: applied index settings served by each scenario's .invalid meilisearch_url through the fake client's get_settings/2, derived from the recorded default; an unknown url is the recorded 404"
  - "ScrypathFixtures.Scenarios: the one registry (builders/0, all/1, ids/0, get!/2); Check now runs every registered scenario"
  - "Five new check invariants (duplicate_id, job_schema, time_not_relative, unlabelled, stress_unmarked) and a :builders option; 21 invariants in all, each with a cause-pinned plant and a coverage test that reads Check.invariants/0"
  - "A posture round trip for every scenario through FixtureEnv and ScrypathOps.Posture.summary/4, and a child-mix proof that check_fixtures is DB-free and runs first in the test alias"
affects: [196-05, 197-catalog-and-pilot, 198-chatly-and-clinicly]

actuals:
  tokens: 17727
  tasks: 3
  commits: 3
commits: 3
plan_head_before: 94348746e68daf2982bf8817c7f41eabf0ef93cc
plan_head_after: 6231a772a97f067689a32a008582385ec51b9404

tech-stack:
  added: ["no package added, removed or upgraded; no lock file touched; no root lib/ change"]
  patterns:
    - "A scenario that must carry data through a channel the library validates (index_contract_drift/2 accepts no operator-only key) carries a url, and the fake client looks the url up in a pure module"
    - "expect.posture is %{state, headline}; the fixtures project cannot call the operator UI, so the ops round-trip test checks it"
    - "The time check builds one scenario at two clocks three days apart and walks both builds in parallel: every DateTime and every stamp inside any string must move by exactly the shift, everything else must be equal"
    - "Every plant lists the tags its cause legitimately drags along (only wire_guard needed one) and fails on any other tag"

key-files:
  created:
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/shopadelic.ex
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/shopadelic/product.ex
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/wikily.ex
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/wikily/page.ex
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/applied_settings.ex
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/scenarios.ex
    - scrypath_ops/test/scrypath_ops/fixtures_round_trip_test.exs
    - scrypath_ops/test/scrypath_ops/fixtures_check_test.exs
    - scrypath_ops/test/scrypath_ops/fixtures_check_task_test.exs
  modified:
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/logistify.ex
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/fake_meilisearch_client.ex
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/scenario.ex
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/check.ex
    - scrypath_ops/test/scrypath_ops_web/live/fixtures_tracer_test.exs
    - .planning/phases/196-fixtures-and-three-adopters/196-FINDINGS.md

key-decisions:
  - "AppliedSettings (a url lookup in the fake client) worked, so research Pattern 3 (one client module per settings state) was not needed"
  - "Without a :backend, Scrypath.sync_status/2 raises ArgumentError and returns no tag, so the missing_backend scenario states no per-schema expectation; a test pins the raise and the posture's guard is the only thing in front of it"
  - "The coverage test for the check's invariants lives in the one file that holds every plant, because ExUnit loads only the files it is given and a call into another test module cannot run when this file runs alone"
  - "The cancelled job in failed_journey carries the schema it was enqueued for (Shopadelic's own) and the table's unknown_schema text, which is what a rolling deploy produces when the running node has not loaded the schema yet; the inspector scopes jobs by args, so no other story is consistent with the closed table"
  - "expect.posture became %{state, headline} so the round-trip test can compare both against the real posture"

patterns-established:
  - "Logistify's aligned applied settings include the schema's sortable list, because the drift report compares it and Scrypath's own settings apply does not send it (finding F4)"
  - "A stress scenario carries kind :stress, 'stress' in its label and its finding id in its scenario id; the registry puts ordinary states before it and a test pins that"

requirements-completed: [FIX-01, FIX-03, FIX-04, FLOW-02, FLOW-04]

coverage:
  - id: D1
    description: "Shopadelic settings_aligned, settings_drift and failed_journey: the real index_contract_drift/2 reports match: true everywhere for aligned and only_declared storeId for drift, and the failed journey yields the five failed-work rows (one failed task, discarded, retryable, cancelled and discarded delete jobs), all failure text from the closed table"
    requirement: "FIX-03"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops/fixtures_round_trip_test.exs#Shopadelic settings, through the real index_contract_drift/2 (5 tests) and #Shopadelic failed_journey, through the real failed_sync_work/2 (7 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Wikily unconfigured (Not configured), missing_backend (Broken), index_not_created (empty page, drift index_not_found) and first_delete_failed (one failed delete from index_not_found)"
    requirement: "FIX-03"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops/fixtures_round_trip_test.exs#Wikily, an empty install (5 tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Logistify steady (clear) and the separately named, labelled stress variation that reproduces finding F1 with the real truncation shape asserted field by field; it is the only stress scenario and is registered after its adopter's ordinary states"
    requirement: "FIX-03"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops/fixtures_round_trip_test.exs#Logistify, ordinary states (3 tests) and #Logistify history_over_limit, the labelled F1 stress variation (6 tests)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Every registered scenario passes through the real sync_status/2, failed_sync_work/2, index_contract_drift/2 (with runtime options only) and Posture.summary/4 with a nil previous summary, and produces its designed state and headline; every stamp moves by exactly the change in now"
    requirement: "FIX-01"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops/fixtures_round_trip_test.exs#posture round trip, one test per registered scenario (10 tests); mix scrypath_fixtures.check_fixtures prints Fixtures OK: 10 scenario(s)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Each of the 21 check invariants has a planted failure that returns exactly its own tag beside a positive control, and a coverage test reads Check.invariants/0 so a new invariant without a plant fails"
    requirement: "FIX-04"
    verification:
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops/fixtures_check_test.exs (11 tests); five deliberate breakages of the check each failed their own plant"
        status: pass
    human_judgment: false
  - id: D6
    description: "mix scrypath_fixtures.check_fixtures runs with no database and prints the registered count; mix test prints Fixtures OK before Nav contract OK and both before the first connection error, with the database really down"
    requirement: "FIX-04"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops/fixtures_check_task_test.exs (2 child-mix tests); moving the check after the nav contract, and removing it from the alias, each fail the ordering test"
        status: pass
    human_judgment: false
  - id: D7
    description: "Finding F1 is reproduced only as a labelled stress state and handed to the maintainer, not fixed; a new finding F4 (a schema's sortable list is never sent to Meilisearch) is recorded and not fixed"
    requirement: "FLOW-04"
    verification:
      - kind: other
        ref: "git diff --name-only over the plan range lists no root lib/ file; grep -c F4 over 196-FINDINGS.md is 3"
        status: pass
    human_judgment: false

duration: 24min
completed: 2026-11-21
status: complete
---

# Phase 196 Plan 04: Three adopters and the registry-driven check Summary

**Ten named scenarios across Shopadelic, Logistify and Wikily, all built from raw wire shapes and checked through the real normalizers, drift code and operator posture, with an F1 stress state kept apart and labelled, and every one of 21 check invariants planted and proven to fail for its own cause.**

## Performance

- **Duration:** about 24 min (the start time was not captured; reconstructed from the end of Plan 03 and the first scratchpad file)
- **Completed:** 2026-11-22T02:35Z
- **Tasks:** 3
- **Files:** 15 (9 created, 6 modified), 1,768 lines added across the three task commits

## Accomplishments

- **Shopadelic.** `settings_aligned` and `settings_drift` differ in exactly one applied key (`filterableAttributes`). The real `Scrypath.index_contract_drift/2` reports `match: true` in all five dimensions for the first and `only_declared: "storeId"` (filterable) plus one settings detail for the second. `failed_journey` gives five real failed-work rows: a failed `invalid_document_id` task, a discarded upsert at its last attempt, a retryable upsert at attempt 3 with its next attempt in the future, a cancelled upsert and a discarded delete.
- **Wikily.** The four stages a new operator passes through: an empty allowlist, a missing backend, an allowlisted schema whose index was never created, and the first failed delete.
- **Logistify.** `steady` reads clear; `history_over_limit` (id `logistify_history_over_limit_f1`) renders finding F1 with the real `{:task_history_truncated, %{index_uid: "logistify_shipment", limit: 1000, observed: 1000, next: 200}}` and is the only stress scenario.
- **Registry and check.** `Scenarios.builders/0` is the one list; `Check` runs all of it, calls `index_contract_drift/2` with runtime options only, and has five new invariants. The relative-time check builds each scenario at two clocks three days apart and walks both builds: every `DateTime` and every stamp inside any string (including the raw task a failed Oban delete embeds in its error text) must move by exactly three days and nothing else may change.
- **Proofs.** Every invariant has a plant that returns its own tag; a child `mix` shows the check runs with the database down and before the nav contract.

## Task Commits

1. **Task 1: Shopadelic states, applied settings, registry, posture round trip** - `d996a15d` (test, 10 paths)
2. **Task 2: Wikily states, Logistify steady and the F1 stress variation** - `5ec1a4ce` (test, 6 paths)
3. **Task 3: A plant per invariant, the :builders option and the child-mix proof** - `6231a772` (test, 3 paths)

**Plan metadata:** the `docs(196-04)` commits that hold this file, FINDINGS, STATE.md and ROADMAP.md. The task commits keep the plan's prescribed `test(ops-ui)` subjects, so a resolver that matches the `(196-04)` scope sees only the docs commits.

## Results the plan asked to keep

### Scenarios, with each posture as observed

| Scenario id | Kind | Posture state | Headline | What the real code reports |
|-------------|------|---------------|----------|----------------------------|
| `logistify_deep_queue` | ordinary | ok | No sync failures found | backend pending 7, queue pending 195, row `:pending` |
| `logistify_steady` | ordinary | ok | No sync failures found | nothing pending or failed, queue observed, row `:clear` |
| `logistify_history_over_limit_f1` | stress | degraded | Search health could not be fully checked | `sync_status` and `failed_sync_work` return the truncation error; row reads "Not checked" |
| `shopadelic_settings_aligned` | ordinary | ok | No sync failures found | drift: every dimension matches |
| `shopadelic_settings_drift` | ordinary | ok | No sync failures found | drift: `only_declared: "storeId"` (posture does not include drift) |
| `shopadelic_failed_journey` | ordinary | degraded | Sync jobs and Meilisearch tasks failed | one failed task, three failed jobs, one retrying job |
| `wikily_unconfigured` | ordinary | unconfigured | Not configured | empty allowlist |
| `wikily_missing_backend` | ordinary | missing_backend | Broken | no `:backend` |
| `wikily_index_not_created` | ordinary | ok | No sync failures found | empty page; drift `{:error, :index_not_found}` |
| `wikily_first_delete_failed` | ordinary | degraded | 1 Meilisearch task failed | one failed delete, `Index \`wikily_page\` not found.`; drift `{:error, :index_not_found}` |

### Other results

| Item | Result |
|------|--------|
| `sync_status/2` without a backend | **No tag: it raises** `ArgumentError` "required :backend option not found" (the same for `failed_sync_work/2` and `index_contract_drift/2`). The posture's own guard is what keeps the operator UI from calling it, so `wikily_missing_backend` states only a posture expectation, and a test pins the raise with a positive control |
| AppliedSettings versus Pattern 3 | The url lookup worked. `Config.resolve!/1` keeps `meilisearch_url` in the config the fake client receives, so three `.invalid` urls give three different drift reports and an unknown url gives `{:error, :index_not_found}`. No fallback to one client module per state |
| Planted-revert, Task 1 | Drifted state no longer drifts: 2 tests fail. Aligned loses a recorded key: the "recorded default plus the one declared key" test fails |
| Planted-revert, Task 2 | History cut to 1,000 tasks: the check task itself fails before any test (`unexpected_outcome` for both calls). `missing_backend` keeps its backend: 3 tests fail. Aligned drops sortable: the Logistify all-dimensions test fails |
| Planted-revert, Task 3 | `time_not_relative` body deleted: its three plants and the coverage tests fail. `duplicate_id`, `job_schema`, `unlabelled` and `stress_unmarked` each made to never fire: exactly their plant (and the all-plants test) fails. Check moved after the nav contract, and removed from the alias: the child-mix ordering test fails. The one allowance in the table (`wire_guard` also yields `unexpected_outcome`, because the real normalizer rejects the task) is needed: without it that plant fails. Every file was restored from a copy and byte-compared |
| Combined fixtures tests | The six fixtures test files together (round trip, check, check task, tracer, recordings, determinism): 117 tests, 0 failures, 2.7 s of ExUnit time and 4 s wall on a warm build, including the alias checks and the child mix's compile check. A cold hosted build will pay more |
| Wider local mirrors | Whole `scrypath_ops` suite 2 doctests, 684 tests, 0 failures (23.4 s); `mix precommit` exit 0 (compile with warnings as errors, unlock check, format, test); root and ops `mix format --check-formatted`; root fixtures project contract, package metadata, namespace fence, dependency boundary and workflow wiring tests 186, 0 failures; `mix verify.namespace_fence`; `mix deps.compile scrypath_fixtures --force` with 0 warning lines |
| Guard row | `git diff --exit-code origin/main` over both `phase173_fixture_source.ex` copies and `posture_live.ex` exits 0; the three lock files identical to `origin/main`; no root `lib/` file changed in the plan range |

## Decisions Made

See `key-decisions` above. The two that matter to Phase 197: a story that shows `wikily_missing_backend` must not call `Scrypath.sync_status/2` itself, and `wikily_index_not_created` and `wikily_first_delete_failed` get their "never created" index from a url that `AppliedSettings` deliberately does not list.

## Deviations from Plan

### Design deviations

**1. [Rule 3 - Blocking] The coverage test does not call `planted_tags/0` on other test modules**
- **Found during:** Task 3
- **Issue:** The plan had the tracer, recordings and check test files each export `planted_tags/0` and had the check test assert the union equals `Check.invariants/0`. ExUnit loads only the test files it is given, and the plan's own verify command runs the check test beside two unrelated files, so the tracer and recordings modules would not be loaded and the union could not be computed.
- **Fix:** `fixtures_check_test.exs` holds a plant for every one of the 21 invariants in one table, a coverage test compares that table's tags with `Check.invariants/0`, and `planted_tags/0` is exported from this module only. The tracer and recordings tests keep their own plants unchanged (a few are now planted twice, which costs nothing).
- **Files modified:** `scrypath_ops/test/scrypath_ops/fixtures_check_test.exs`
- **Commit:** `6231a772`

**2. [Rule 3 - Blocking] `ExUnit.Case` instead of `DataCase` for the round-trip test**
- **Issue:** The plan said `use ScrypathOps.DataCase, async: false` "because it needs the started app". Nothing in the file touches the database; the started application (for the posture's task supervisor) is all it needs, and `DataCase` adds a sandbox owner and a database connection per test.
- **Fix:** `use ExUnit.Case, async: false`, with the reason in the file header. `FixtureEnv.put/1` still restores the app env in `on_exit`.
- **Commit:** `d996a15d`

### Auto-fixed Issues

**3. [Rule 3 - Blocking] The tracer test counted one scenario**
- **Found during:** Task 1
- **Issue:** `Check.run()` now runs the whole registry, so `assert {:ok, %{scenarios: 1}} = Check.run()` in the Plan 01 tracer test failed.
- **Fix:** it asserts the count equals `length(Scenarios.ids())`.
- **Files modified:** `scrypath_ops/test/scrypath_ops_web/live/fixtures_tracer_test.exs`
- **Commit:** `d996a15d`

**4. [Rule 2 - Missing critical] `expect.posture` and the Scenario docs**
- **Found during:** Task 1
- **Issue:** The plan compared the posture "with `scenario.expect.posture`", but Plan 01 stored a bare `:ok` there, which cannot say both a state and a headline, and the docs listed `:posture` as `:ok | {:error, tag}`.
- **Fix:** `expect.posture` is `%{state, headline}` for every scenario, `scenario.ex` documents it (and that a call with no expectation is not made), and `logistify.ex` was updated for deep_queue. `index_contract_drift: :ok` was also added to the Logistify expectations so its aligned url is exercised.
- **Files modified:** `scenario.ex`, `logistify.ex`
- **Commit:** `d996a15d`

**5. [Rule 1 - Bug] Aligned settings for Logistify were not aligned**
- **Found during:** Task 2 (the Logistify drift check printed `match: false`)
- **Issue:** The first `aligned/1` merged only what the settings resolver returns, so Logistify's declared `sortable: [:updated_at]` showed as `only_declared`. Reading the library showed why: `Settings.apply/3` never sends a schema's `sortable:` list (finding F4).
- **Fix:** `aligned/1` also writes the schema's sortable list, and a test asserts every dimension matches for both ordinary Logistify states.
- **Commit:** `5ec1a4ce`

### Reading notes

- **The failed delete embeds an `index_not_found` task.** The closed table has exactly one error for a failed deletion task, so Shopadelic's discarded delete uses it, even though its index exists. It is a delete that ran when the index was not there; no other table entry is valid for that task type.
- **The cancelled job names Shopadelic's own schema.** The table's `oban_cancel_invalid_job` text is `unknown_schema`, and the inspector only shows a job under the schema in its args, so the job's text names the schema it belongs to. The code comment records the rolling-deploy reading.
- **The relative-time check is skipped when a caller passes only `:scenarios`**, because it needs builders. The default run and any `:builders` run do it.

**Total deviations:** 2 design changes, 3 auto-fixes (2 blocking, 1 missing-critical, 1 bug counted once each above). **Impact:** none on scope; the changes make the proofs run standalone and keep the expectations honest.

## Issues Encountered

- The shared local Postgres logged `too_many_connections` during test runs (other projects' connections). It did not affect any result and the new tests that need no database do not touch it.
- `gsd-tools check evaluation-scope` finds commits by a `(196-04)` subject scope; the task commits use the plan's `test(ops-ui)` subjects, so the measured instrument is the ledger above, as in Plans 01 and 03.
- Hosted CI was not run (nothing is pushed). The local mirrors above are the evidence. Not run here: `ops_dependency_boundary_test --include integration` (reads committed HEAD and takes about three minutes) and the Docker lanes; Plan 05 owns the push and those lanes.

## Known Stubs

None. No placeholder text, empty-value-to-UI data or unwired data source in the files this plan created or changed.

## Threat Flags

None. No new network endpoint, auth path or file-access pattern: every `meilisearch_url` is an RFC 2606 `.invalid` name that never resolves, and the check task and the child mix touch no database. T-196-14 is mitigated by the `:stress` kind, the label naming finding F1 and the `stress_unmarked` invariant with its plant; T-196-15 by drift coming from the real `index_contract_drift/2` over recorded settings, failure text from the closed table and the realism grep over `shopadelic.ex`; T-196-16 by `async: false`, the nonexistent test path, `PGPORT=1` and the existing child-mix guard; T-196-17 by `FixtureEnv` restore in `on_exit` or `try/after` for every test that puts a scenario.

## Next Phase Readiness

Plan 05 can add the hostile set and the bulk generator on this registry: a new scenario is one builder line in `Scenarios.builders/0`, a new check is a tag in `Check.invariants/0` plus a plant in `fixtures_check_test.exs`, and the coverage test fails if the plant is missing. The fixtures' share of the `ops-ui` lane, measured warm: about 2.7 s of ExUnit time for the six fixtures files, plus the child mix's compile check; Plan 05 should attribute the cold excess to the existing cache finding. Phase 197 should read `196-FINDINGS.md` (F4 and the missing-backend raise) before it renders those states. Nothing blocks Plan 05.

## Self-Check: PASSED

- All 12 plan files exist on disk (`[ -f ]`).
- Commits `d996a15d`, `5ec1a4ce` and `6231a772` are ancestors of HEAD (`git merge-base --is-ancestor`); `rev-list --count` over the ledger range is 3.
- Every task `<acceptance_criteria>` re-run and passing: `only_declared` 1, `filterableAttributes` 1, no hand-typed settings keys, `runtime_opts` 3 and `:meilisearch_tasks/` 1, realism grep empty; `kind: :stress` 1, `finding F1` 3, `"Not configured"` or `"Broken"` 2, `index_not_found` 4, `observed: 1000` 2; new tags in `check.ex` 10, `async: false` 1, `does_not_exist_test.exs` 1, `Check.invariants()` 3; the time-invariant revert recorded above.
- Plan-level `<verification>` re-run on the final head: round-trip and check files, `Fixtures OK: 10 scenario(s)` with `PGPORT=1`, the child-mix file, root `mix format --check-formatted`, and the staged-file guard before every commit.
- No protected config file (`.planning/config.json`, `.planning/state.json`, `.impeccable/config.json`) is in any commit of the plan range; no commit deleted a tracked file.
