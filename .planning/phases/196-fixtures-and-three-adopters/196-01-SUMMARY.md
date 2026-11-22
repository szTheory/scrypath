---
phase: 196-fixtures-and-three-adopters
plan: 01
subsystem: testing
tags: [fixtures, elixir, mix-path-dependency, meilisearch, oban, liveview-test, ops-ui, adr-0002]

requires:
  - phase: 195-mount-and-prove
    provides: "the mounted scrypath_ops test graph, ops dependency-boundary tests and the catalog lane this dev/test-only dependency must respect"
provides:
  - "fixtures/scrypath_fixtures Mix project (ADR 0002): deps exactly [{:scrypath, path: \"../..\"}], no lock, no test dir, one real module for later prod-absence probes"
  - "Pure closed-enum builders for raw Meilisearch task maps (12 keys) and Oban job maps (11 keys); strings for worker names, never worker modules"
  - "ScrypathFixtures.FakeMeilisearchClient and FakeObanInspector that hand raw maps to the real Scrypath code"
  - "ScrypathFixtures.Scenario struct plus the one list of operator-only option keys and the one split function"
  - "Logistify deep_queue scenario (647 tasks, 195 jobs, nothing failed) as the tracer"
  - "ScrypathFixtures.Check.run/1 (eleven invariants, invariants/0 as the tag list) and Mix task scrypath_fixtures.check_fixtures, DB-free and first in the ops test alias"
  - "The single scrypath_ops/mix.exs edit of the phase (dependency, alias, preferred_envs); mix.lock files untouched"
  - "ScrypathOps.Test.FixtureEnv and a rendered /ops/health tracer test"
affects: [196-02, 196-03, 196-04, 196-05, 197-catalog-and-pilot]

actuals:
  tokens: 11229
  tasks: 2
  commits: 2
commits: 2
plan_head_before: 176f5e8470a22be4b8ccf87bdc9083ab0bc873fe
plan_head_after: 2562fe68630e72ff53043129bf15fb0d245dd674

tech-stack:
  added: ["scrypath_fixtures (in-repository path project, dev/test only); no Hex package added, removed or upgraded"]
  patterns:
    - "Builders emit raw wire shapes only; the real Scrypath code normalizes them, so only reachable states exist"
    - "Scenario is plain data; app env is the test's business (FixtureEnv puts and restores it)"
    - "The check is a function; the Mix task is a ten-line shell that starts no app and no Repo"
    - "Every plant changes one field of the real scenario and asserts its exact problem tag beside a positive control"

key-files:
  created:
    - fixtures/scrypath_fixtures/mix.exs
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures.ex
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/meili.ex
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/oban_job.ex
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/scenario.ex
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/fake_meilisearch_client.ex
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/fake_oban_inspector.ex
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/logistify.ex
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/logistify/shipment.ex
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/check.ex
    - fixtures/scrypath_fixtures/lib/mix/tasks/scrypath_fixtures.check_fixtures.ex
    - scrypath_ops/test/support/fixture_env.ex
    - scrypath_ops/test/scrypath_ops_web/live/fixtures_tracer_test.exs
  modified:
    - scrypath_ops/mix.exs

key-decisions:
  - "Check.run/1 matches an expectation {:error, tag} against both {:error, tag} and {:error, {tag, _}} so designed error tags work for the Scrypath tuple reasons (for example :task_history_truncated)"
  - "FixtureEnv exposes keys/0 so the restore tests snapshot exactly the keys the helper touches"
  - "The tracer's setup lives inside its own describe so the FixtureEnv restore tests start from a pristine app env"

patterns-established:
  - "Operator-only key list lives once in ScrypathFixtures.Scenario and is pinned to lib/scrypath/operator.ex by an AST test; anything reaching Config.resolve!/1 or index_contract_drift/2 gets Scenario.runtime_opts/1"
  - "Plants build on the real deep-queue scenario with update_in, then assert the exact tuple and refute :wire_guard, so a plant cannot pass by failing in the builder"

requirements-completed: [FIX-01, FIX-04, FLOW-01, FLOW-02, FLOW-03]

coverage:
  - id: D1
    description: "Logistify deep queue goes from pure builders through the fake client and the real Scrypath code to a rendered /ops/health with a neutral pending verdict and nothing failed"
    requirement: "FIX-01"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/fixtures_tracer_test.exs#Logistify deep queue renders a neutral pending verdict with nothing failed"
        status: pass
    human_judgment: false
  - id: D2
    description: "Builders are pure and closed: foreign task type or status, Oban state or worker, and a swap that names an index all raise FunctionClauseError from the function head"
    requirement: "FIX-01"
    verification:
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops_web/live/fixtures_tracer_test.exs#closed enums (7 tests)"
        status: pass
      - kind: other
        ref: "grep for DateTime.utc_now, Date.utc_today, :rand., System., Repo. over fixtures lib exits 1 (no match); ~U[ appears only in lib/scrypath_fixtures.ex"
        status: pass
    human_judgment: false
  - id: D3
    description: "scrypath_ops/mix.exs edited once (path dependency only: [:dev, :test], check task first in the test alias, preferred_envs entry); all three mix.lock files byte-identical"
    requirement: "FIX-01"
    verification:
      - kind: other
        ref: "mix deps.get --check-locked in root, scrypath_ops and the ecommerce host, then git diff --quiet origin/main -- the three lock files (exit 0)"
        status: pass
      - kind: other
        ref: "MIX_ENV=dev|test|prod mix deps lists scrypath_fixtures 1|1|0 times; MIX_ENV=prod mix compile --warnings-as-errors exits 0 and builds no _build/prod/lib/scrypath_fixtures"
        status: pass
    human_judgment: false
  - id: D4
    description: "mix scrypath_fixtures.check_fixtures runs with no database before the nav contract and before ecto.create fails; each of eleven invariants has a plant that returns its own tag"
    requirement: "FIX-04"
    verification:
      - kind: other
        ref: "PGPORT=1 MIX_ENV=test mix test: Fixtures OK on line 1, Nav contract OK on line 2, first econnrefused on line 26, exit 1"
        status: pass
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops_web/live/fixtures_tracer_test.exs#check skeleton (7 tests)"
        status: pass
    human_judgment: false
  - id: D5
    description: "FixtureEnv restores every key it touched (put or delete) and deletes keys a scenario omits while it is in effect"
    requirement: "FIX-01"
    verification:
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops_web/live/fixtures_tracer_test.exs#FixtureEnv (2 tests)"
        status: pass
    human_judgment: false
  - id: D6
    description: "One list of operator-only keys and one split function; an unsplit plant to index_contract_drift/2 raises ArgumentError naming :meilisearch_tasks"
    requirement: "FIX-01"
    verification:
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops_web/live/fixtures_tracer_test.exs#operator-only keys (4 tests)"
        status: pass
    human_judgment: false

duration: 7min
completed: 2026-11-21
status: complete
---

# Phase 196 Plan 01: Fixtures project and Logistify tracer Summary

**A dev/test-only `fixtures/scrypath_fixtures` project whose pure closed-enum builders feed raw Meilisearch task maps and Oban job maps through a fake client to the real `Scrypath.sync_status/2`, rendered by LiveViewTest on `/ops/health` as a neutral pending verdict with nothing failed, plus a DB-free eleven-invariant check that runs first in the ops `test` alias.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-11-22T01:24:23Z
- **Completed:** 2026-11-22T01:32:06Z
- **Tasks:** 2 (tracer, then TDD controls)
- **Files modified:** 14 (13 created, 1 edited)

## Accomplishments

- The Logistify deep queue (647 Meilisearch tasks, 195 Oban jobs, nothing failed) travels builders, fake client, real `Scrypath.sync_status/2` and `failed_sync_work/2`, then `/ops/health`. The tracer test asserts the neutral verdict, the pending status marker, no failed marker, and the headline text inside its own element.
- `scrypath_ops/mix.exs` has its one edit of the phase. The three `mix.lock` files are byte-identical to `origin/main`, the dependency is in the dev and test graphs and absent from prod, and the check task runs with the database down.
- Every closed enum and every check invariant has a control that fails for its own cause. Four deliberate breakages confirmed that (see "Planted-revert results").
- The full `scrypath_ops` suite passes with the new alias step and support module: 2 doctests, 588 tests, 0 failures.

## Task Commits

1. **Task 1: Tracer, Logistify builders through the fake client to a rendered /ops/health** - `bb2754a7` (chore, 14 files)
2. **Task 2: Check skeleton invariants, closed-enum raises and FixtureEnv restore** - `2562fe68` (test, 2 files changed: `check.ex`, the test file)

**Plan metadata:** the `docs(196-01)` commit that holds this file, STATE.md and ROADMAP.md.

## Files Created/Modified

- `fixtures/scrypath_fixtures/mix.exs` - ADR 0002 Mix project; deps exactly `[{:scrypath, path: "../.."}]`, no lock, no `test/`
- `fixtures/scrypath_fixtures/lib/scrypath_fixtures.ex` - the real module for prod-absence probes; `preview_epoch/0` holds the only datetime literal
- `.../meili.ex`, `.../oban_job.ex` - pure closed-enum builders (12-key task map, 11-key job map)
- `.../scenario.ex` - the `Scenario` struct, the one `@operator_keys` list, `split_opts/1`, `runtime_opts/1`
- `.../fake_meilisearch_client.ex`, `.../fake_oban_inspector.ex` - what the real Scrypath code calls
- `.../logistify.ex`, `.../logistify/shipment.ex` - the `:deep_queue` tracer scenario and its schema
- `.../check.ex`, `lib/mix/tasks/scrypath_fixtures.check_fixtures.ex` - the check function and its ten-line Mix shell
- `scrypath_ops/mix.exs` - dependency, check task first in the `test` alias, `preferred_envs`
- `scrypath_ops/test/support/fixture_env.ex`, `scrypath_ops/test/scrypath_ops_web/live/fixtures_tracer_test.exs` - env injection with restore, and the tracer and controls (21 tests)

## Phase-gate outputs

| Gate | Result |
|------|--------|
| `mix deps` lists `scrypath_fixtures` | dev 1, test 1, prod 0 |
| `MIX_ENV=prod mix compile --warnings-as-errors` | exit 0; `_build/prod/lib/scrypath_fixtures` absent; `scrypath_ops.app` (prod) has 0 mentions |
| `MIX_ENV=test mix deps.compile scrypath_fixtures --force` | exit 0; 0 lines containing `warning:` |
| DB-free order (`PGPORT=1 MIX_ENV=test mix test`, 51 lines) | `Fixtures OK: 1 scenario(s)` line 1, `Nav contract OK` line 2, first `econnrefused` line 26, exit 1 |
| Lock files | `mix deps.get --check-locked` exit 0 in root, `scrypath_ops/`, `examples/scrypath_ecommerce/`; `git diff --quiet origin/main -- <three locks>` exit 0; local `shasum` unchanged after `deps.get` |
| Protected sources | `phase173_fixture_source.ex` (both copies) and `posture_live.ex` byte-identical to `origin/main` |
| Full ops suite (`mix test`, includes the new alias step) | 2 doctests, 588 tests, 0 failures, 21.5 s |
| Cheap mirrors | root and ops `mix format --check-formatted` exit 0; `verify_namespace_fence_test.exs` 3 tests, 0 failures |

## Planted-revert results (Task 2 controls)

| Broken on purpose | Test that failed (and nothing else for its own cause) |
|-------------------|--------------------------------------------------------|
| `job_index` invariant returns `[]` (required by the plan) | "a job that names a foreign index is a job_index problem" and the tag-coverage test that includes that plant |
| `time_order` never fires | "a task that finishes before it was enqueued is a time_order problem" and the tag-coverage test |
| `:task_history_limit` dropped from `Scenario.operator_keys/0` | "the fixtures list equals @operator_only_opts in lib/scrypath/operator.ex" |
| `FixtureEnv` restore stops deleting keys that were absent | "restores every key it touched, including keys that were absent" |

Each file was restored from a saved copy and checked byte-identical before the commit. The RED run before the invariants existed showed the four plant tests failing because `Check.run/1` returned `{:ok, ...}` for planted bad data.

## Decisions Made

- `Check` matches an expectation `{:error, tag}` against `{:error, tag}` and against tuple reasons `{:error, {tag, _}}`, because Scrypath returns reasons such as `{:task_history_truncated, %{...}}`.
- `FixtureEnv.keys/0` is public so restore tests snapshot exactly what the helper touches.
- The `:test_clock_file` and `:repo` keys are the absent-before keys that prove the restore deletes (the config sets `:backend` to `nil`, so omitting it exercises delete-while-in-effect instead).

## Deviations from Plan

No Rule 1 to 3 auto-fixes were needed. Notes on how the plan was read:

- **Extra controls (inside Task 2's own heading).** The plan lists two plants (`job_index`, `time_order`). I also added plants for `wire_guard`, `unexpected_outcome` and the seven remaining invariants, because Task 1 shipped the first two with no plant of their own and the task is titled "each with a control that can fail for its own cause". They cost one table-driven test.
- **Test file shape.** The tracer's `setup` sits inside `describe "tracer"` so the FixtureEnv restore tests begin from an untouched app env; a module-level setup would have put a scenario in place before the "before" snapshot.
- **Task 2 commit touched two files, not five.** `meili.ex`, `oban_job.ex` and `scenario.ex` needed no change (the plan said "only if a behavior test shows a gap"; none did).
- **Task 1 `check.ex` held only the two invariants the plan names** (wire guard and round trip); `invariants/0` and the other nine arrived in Task 2 behind failing tests.
- **Selectors.** The research selectors for the verdict, the pending marker and the failed marker worked unchanged. The headline paragraph has no id (`headline_id` is `nil`), so the headline text is read from `.ops-posture-verdict p.text-ops-h2`, scoped to that one element.

**Total deviations:** 0 auto-fixed. **Impact:** none on scope; the extra plants add test coverage only.

## Issues Encountered

- **Local Postgres connection limit.** Every local `mix test` run prints `FATAL 53300 (too_many_connections)` lines at start-up because the ops sandbox pool is `schedulers_online * 2` (36 here) and the local server's limit is already partly used. Tests still pass (588/588); it is machine noise, not caused by this plan. Not fixed.
- **`gsd-tools check evaluation-scope --plan 196-01 --commits-only` returns no commits.** It finds commits by a `(196-01)` subject scope, and the plan's required subjects use `chore(ops-ui):` and `test(ops-ui):`. The measured instrument is the ledger above (`plan_head_before` to `plan_head_after`, 2 commits), which `/gsd-verify-work` compares. The `docs(196-01)` plan-metadata commit does carry the plan scope.

## Known Stubs

None. No placeholder text, empty-value-to-UI data or unwired data source in the files this plan created.

## Threat Flags

None. No new network endpoint, auth path or file-access pattern: the Meilisearch URL is `https://logistify.fixtures.invalid` (RFC 2606, never resolves) and the only file written is a per-call temp clock file in test builds. T-196-01 is mitigated and checked by the phase gate (dependency `only: [:dev, :test]`, absent from the prod graph, prod build and prod `.app`); T-196-02 by closed enums, raw-shape-only builders and the invariants; T-196-03 by `async: false`, FixtureEnv restore and its restore tests.

## Hosted-CI notes (not measured here)

- Editing `scrypath_ops/mix.exs` is in the `manifests` of the `ops` and `ecommerce` BEAM cache graphs, so the first `ops-ui` and `ecommerce-mounted` runs after this lands will miss both caches even though no lock changed (research N3; Phase 195 saw about +135 s). All `scrypath_ops/mix.exs` changes for the phase are in this plan, so later plans do not repeat it. Nothing is pushed before Plan 05.
- Known transient reds the plan told me not to fix: `compat_path_classifier.test.cjs` will report `unclassified: ['fixtures']`, and the direct dev/test cases of `test/release/ops_dependency_boundary_test.exs` will fail with "the dependency is not available" until Plan 02 lands. I did not run them.

## Next Phase Readiness

Plan 02 can add the root-side boundary work (archive path list, probes, script lists, Dockerfile and `.dockerignore`, classifier inventory, formatter input, `.gitignore`, `README.md`, package refute) against a project that already exists. Plans 03 to 05 add scenarios by appending to `Check.scenarios/1` and tags to `Check.invariants/0` without changing the `Scenario` struct. Nothing blocks them.

## Self-Check: PASSED

- All 14 plan files exist on disk (`[ -f ]`).
- Commits `bb2754a7` and `2562fe68` are ancestors of HEAD (`git merge-base --is-ancestor`).
- Task 1 and Task 2 `<acceptance_criteria>` re-run and pass (grep counts 1, 2, 1, 22 >= 11, 6 >= 6, 1, 1, 4 >= 1; impure-call grep no match; `~U[` only in `lib/scrypath_fixtures.ex`; no worker module reference; locks identical; tracer passes; DB-free line prints `Fixtures OK: 1 scenario(s)` with `PGPORT=1`).
- Plan-level `<verification>`: tracer file 21 tests, 0 failures; check task with `PGPORT=1` exits 0; lock drift check passes; protected sources unchanged; no protected config file staged in either commit.
- Post-commit deletion check: neither commit deleted a tracked file.
