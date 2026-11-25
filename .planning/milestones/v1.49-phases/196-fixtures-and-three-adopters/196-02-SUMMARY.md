---
phase: 196-fixtures-and-three-adopters
plan: 02
subsystem: testing
tags: [fixtures, dependency-boundary, path-dependency, docker, classifier, namespace-fence, hex-package, adr-0002]

requires:
  - phase: 196-fixtures-and-three-adopters
    provides: "plan 01's fixtures/scrypath_fixtures project, the scrypath_ops path dependency (only: [:dev, :test]), the check-first test alias and the preferred_envs entry"
  - phase: 195-mount-and-prove
    provides: "the root dependency-boundary contract, the ops integration probes and the storybook text-check style this plan copies"
provides:
  - "fixtures/ classified everywhere the repository draws a boundary: compat classifier inventory, root formatter, namespace fence, package refute, Dockerfile, .dockerignore"
  - "A path-dependency-aware manifest reader and a fixtures dependency row (path and only: [:dev, :test]) with seven planted manifests"
  - "Mention guards: root lib/ and scrypath_ops/lib never name the fixtures project"
  - "Integration probes that prove the path dependency is present only in direct dev and test Ops builds (.app requirement and loadable module), and absent from direct prod and mounted consumers"
  - "Docker verify script forbids scrypath_fixtures in the prod image and the host project, forbids the ScrypathFixtures module in the runtime probe, and checks _build/prod"
  - "fixtures README with the exit rule, second-consumer definition, phase173 deletion trigger and every boundary decision, pinned by a root contract test"
affects: [196-03, 196-04, 196-05, 197-catalog-and-pilot]

actuals:
  tokens: 10104
  tasks: 3
  commits: 3
commits: 3
plan_head_before: bec91311fe1bff02bb0ed3269b52bb6615ff21cb
plan_head_after: 0b6cde7c35b56e0a9352132b1b5973c8972c94da

tech-stack:
  added: ["no package added, removed or upgraded; no lock file touched"]
  patterns:
    - "A path dependency is in no lock, so absence is proven from the manifest options, the .app requirement list, the loadable module and the _build tree, never from the lock"
    - "A new text check on a shared shell script gets its own block and its own regex, so the existing check keeps reading a single statement"
    - "Every plant asserts the exact message or the single offending entry, and the real-file breakages below were run once to confirm each row fails for its own cause"

key-files:
  created:
    - fixtures/scrypath_fixtures/README.md
    - fixtures/scrypath_fixtures/.formatter.exs
    - fixtures/scrypath_fixtures/.gitignore
    - test/mix/tasks/fixtures_project_contract_test.exs
  modified:
    - scripts/ci/compat_path_classifier.test.cjs
    - .formatter.exs
    - dev/mix/tasks/verify.namespace_fence.ex
    - test/mix/tasks/verify_namespace_fence_test.exs
    - test/release/package_metadata_test.exs
    - test/mix/tasks/dependency_boundary_contract_test.exs
    - test/release/ops_dependency_boundary_test.exs
    - examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh
    - examples/scrypath_ecommerce/Dockerfile
    - .dockerignore

key-decisions:
  - "The fixtures check in the Docker script is a separate if block after the catalog block, because the existing storybook regex requires its forbidden_deps line to be the only statement between then and fi"
  - "ScrypathFixtures goes into the runtime probe's forbidden_modules directly before PhoenixStorybook, so the existing storybook mutant literal ', PhoenixStorybook, MDEx]' still finds its text"
  - "The mounted probe gets its own .app requirement assertion for scrypath_fixtures, because the lock check passes vacuously for a path dependency and the existing probe had no .app check for any forbidden app"
  - "A root contract row (not only the Plan 05 Docker lane) guards the .dockerignore rule that fixtures/ itself must never be excluded"

patterns-established:
  - "path_dependency_options!/2 matches {dep, keyword} before any generic two-tuple clause; dependency_options!/2 stays unchanged for its three-tuple callers"
  - "Dockerfile stage checks split on FROM, name each stage from its AS clause, and report one message per stage per problem"

requirements-completed: [FIX-01, FIX-04, FLOW-01, FLOW-03, FLOW-04]

coverage:
  - id: D1
    description: "fixtures/ is classified for CI: the compat inventory lists it as irrelevant with its reason, ops-ui-path and the ecommerce classifier already run the right lanes for it"
    requirement: "FIX-04"
    verification:
      - kind: unit
        ref: "node --test scripts/ci/compat_path_classifier.test.cjs scripts/ci/ecommerce_path_classifier.test.cjs (before: 51 pass, 1 fail with unclassified: ['fixtures']; after: 52 pass, 0 fail)"
        status: pass
      - kind: unit
        ref: "test/mix/tasks/workflow_wiring_test.exs (ops-ui-path keeps fixtures/, unchanged and green)"
        status: pass
    human_judgment: false
  - id: D2
    description: "fixtures/ never ships: the literal refutes stay, a directory-exists positive control and fixtures_reaching_entries/1 prove no files: entry reaches the tree, with six planted lists that each return exactly their offending entry"
    requirement: "FIX-04"
    verification:
      - kind: unit
        ref: "test/release/package_metadata_test.exs#the fixtures project exists and no package entry reaches it; fixtures_reaching_entries/1 names exactly the entry that reaches the fixtures tree"
        status: pass
    human_judgment: false
  - id: D3
    description: "The root and ops formatter and the namespace fence cover fixtures/; the fence reports a planted Sigra reference by file and line and tolerates an absent tree"
    requirement: "FIX-04"
    verification:
      - kind: unit
        ref: "test/mix/tasks/verify_namespace_fence_test.exs (5 tests)"
        status: pass
      - kind: other
        ref: "mix format --check-formatted reports a deliberately misformatted fixtures/scrypath_fixtures/lib file, then passes after removal"
        status: pass
    human_judgment: false
  - id: D4
    description: "A path-aware reader and a fixtures dependency row read path and only: [:dev, :test] from scrypath_ops/mix.exs; seven planted manifests and two mention plants fail for their exact causes; root lib/ and scrypath_ops/lib never mention the project"
    requirement: "FIX-04"
    verification:
      - kind: unit
        ref: "test/mix/tasks/dependency_boundary_contract_test.exs#fixtures boundary (ADR 0002, v1.49 Phase 196) (8 tests)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Direct dev and test Ops builds archive fixtures/ from HEAD and list scrypath_fixtures in the .app with the module loadable; direct prod and mounted test, prod and metrics-only consumers lack the app, its .app listing and the module"
    requirement: "FIX-04"
    verification:
      - kind: integration
        ref: "mix test test/release/ops_dependency_boundary_test.exs --include integration --warnings-as-errors on committed head 9dce3914: 2 tests, 0 failures, 187.2 s"
        status: pass
    human_judgment: false
  - id: D6
    description: "Docker verify script, Dockerfile and .dockerignore are consistent with the boundary: fixtures forbidden in the prod image and host graphs and runtime probe, manifest copied in the three early blocks, sources kept and build output ignored; each edit mutation-tested statically"
    requirement: "FIX-04"
    verification:
      - kind: unit
        ref: "test/mix/tasks/dependency_boundary_contract_test.exs (script: 5 mutants; Dockerfile: removed, late and doubled per stage; .dockerignore: 4 plants)"
        status: pass
      - kind: other
        ref: "bash -n examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh; --static-contract-only prints 'Static dependency boundary contract passed'"
        status: pass
      - kind: other
        ref: "node --test --test-name-pattern 'static dependency boundary mode' scripts/ci/ui_bundle_contract.test.cjs (1 pass)"
        status: pass
    human_judgment: false
  - id: D7
    description: "The fixtures README records the exit rule, the second-consumer definition, the phase173 deletion trigger and the boundary decisions; a root contract test pins them with the alias order, the preferred_envs entry, the deps shape and the tracked-file shape, each by planted failure"
    requirement: "FIX-01"
    verification:
      - kind: unit
        ref: "test/mix/tasks/fixtures_project_contract_test.exs (9 tests)"
        status: pass
    human_judgment: false

duration: 12min
completed: 2026-11-21
status: complete
---

# Phase 196 Plan 02: Fixtures boundary Summary

**The new top-level `fixtures/` is now accounted for in every boundary the repository draws: CI classifier, formatter, namespace fence, Hex package, a path-dependency-aware boundary row, the direct and mounted integration probes, the Docker verify script, the Dockerfile and `.dockerignore`. The README records the exit rule and the phase173 deletion trigger, and a root contract test pins them. Every new check has a planted failure that asserts its own cause.**

## Performance

- **Duration:** about 12 min (3 min of it the integration test)
- **Completed:** 2026-11-21
- **Tasks:** 3
- **Files:** 14 (4 created, 10 modified). `scrypath_ops/mix.exs` and all three `mix.lock` files are untouched by this plan.

## Accomplishments

- `fixtures/` is classified. The compat inventory lists it as irrelevant with its reason, `ops-ui-path` already covered it, and the ecommerce classifier already runs the Docker lanes for it. The root formatter and namespace fence now cover it, and the fixtures project has its own `.formatter.exs` and `.gitignore` (the root ignores are anchored to the root).
- `fixtures/` provably never ships. The two literal refutes stay and a test now also checks the directory exists and that no `files:` entry reaches it (`.`, `fixtures`, `fixtures/`, the project path, something below it, or a glob such as `fix*`).
- The boundary row can read the dependency. `dependency_options!/2` returns `[]` for a path dependency, so a new reader and row check `path: "../fixtures/scrypath_fixtures"` and `only: [:dev, :test]`, with seven planted manifests (absent, unrestricted, dev-only, all-env, wrong path, Hex two-tuple and Hex three-tuple). Root `lib/` and `scrypath_ops/lib` are guarded against naming the project.
- The integration probes cover a dependency that is in no lock. The archive list now includes `fixtures`, so the direct dev and test builds resolve it. The direct probe asserts the `.app` requirement and the loadable module per environment, and the mounted probe asserts the `.app` list, the loaded and started apps and the module code path are all clear.
- The Docker side is consistent and statically proven. The verify script forbids `scrypath_fixtures` in the prod image and the host project, forbids the `ScrypathFixtures` module in the runtime probe, and fails if `_build/prod/lib/scrypath_fixtures` exists. The Dockerfile copies the fixtures `mix.exs` in its three early blocks. `.dockerignore` keeps the sources and ignores their `_build` and `deps`.
- The README and a root contract test record and pin the exit rule, the second-consumer definition, the phase173 deletion trigger and the boundary decisions.

## Task Commits

1. **Task 1: Classifier inventory, formatter, fence, ignore files, tarball refute** - `ffb23954` (test, 7 files)
2. **Task 2: Dependency boundary for a path dependency** - `9dce3914` (test, 5 files)
3. **Task 3: README with exit rule and trigger, pinned by a contract test** - `0b6cde7c` (test, 2 files)

**Plan metadata:** the `docs(196-02)` commits that hold this file, STATE.md and ROADMAP.md.

## Results the plan asked to keep

| Item | Result |
|------|--------|
| Compat classifier test, before the inventory edit | `node --test` on both classifier files: 52 tests, 51 pass, 1 fail: `unclassified: ['fixtures']` |
| Same, after the edit | 52 tests, 52 pass, 0 fail |
| Integration boundary test (committed head `9dce3914`) | `mix test test/release/ops_dependency_boundary_test.exs --include integration --warnings-as-errors`: 2 tests, 0 failures, 187.2 s, exit 0. The two tests assert a `result=passed` line for each of the six cases (`mounted` env `test`, `prod`, `test` with metrics only; `direct` env `dev`, `test`, `prod`) and that the lock file is unchanged. ExUnit does not echo the captured `OPS_DEPENDENCY_BOUNDARY` lines, so the passing run is the evidence for them, not a pasted copy |
| Static contract | `Static dependency boundary contract passed (4 current-source assets, output-only handoff, clean runtime entrypoints).` after `bash -n` exit 0 |
| Guard row (ruling 7) | `git diff --exit-code origin/main -- scrypath_ops/test/support/phase173_fixture_source.ex examples/scrypath_ecommerce/test/support/phase173_fixture_source.ex scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex` exit 0 |
| Plan-level focused tests | verify_namespace_fence, package_metadata, dependency_boundary_contract, fixtures_project_contract, workflow_wiring: 186 tests, 0 failures |
| Cheap mirrors | `mix format --check-formatted` exit 0 (now covers `fixtures/`); `MIX_ENV=test mix credo --strict` over 290 files: no issues; the three lock files identical to `origin/main` |

## Boundary decisions as written in the fixtures README

- The compatibility path classifier lists `fixtures` as irrelevant: the root `mix test` never compiles it, so a fixtures-only change rightly skips the advisory matrix.
- `ops-ui-path` already covers `fixtures/`, so ops-ui runs for a fixtures change.
- The ecommerce classifier runs the Docker lanes for it, because the images copy and compile it.
- `package_contents_test` needs no change: `allowed_top_level` is derived from `files:` in the root `mix.exs`, so `fixtures` can never be allowed.
- `package_metadata_test` refutes it from the package non-vacuously: it checks that the tree exists and that no `files:` entry reaches it.
- `.dockerignore` keeps the sources (the builder and test stages compile them) and ignores `_build` and `deps` under `fixtures/`.
- The Dockerfile copies this project's `mix.exs` in its three early blocks, so `deps.get` sees the manifest.
- The Docker verify script forbids `scrypath_fixtures` in the prod image and in the host project, and forbids the `ScrypathFixtures` module in its runtime probe.
- There is no Dependabot entry and no lock file: the project has no Hex dependency of its own.
- The UI literal policy does not scan it.
- The root formatter and the namespace fence cover it.

The exit rule (fold into `scrypath_ops/catalog/` if no second consumer appears by Phase 197, evaluated at the start of Phase 197 planning; a second consumer is a Mix project other than `scrypath_ops` listing `scrypath_fixtures`) and the phase173 deletion trigger (four host specs ported or retired, with `PRESERVATION_FIXTURE_FILES` and its receipts updated in the same change) are in the README's "Exit rule" and "Phase 173 deletion trigger" sections.

## Planted-revert results (real files broken on purpose, then restored)

| Broken on purpose | Row that failed, and why |
|-------------------|--------------------------|
| `scrypath_ops/mix.exs` fixtures dependency `only: :dev` | the Ops manifest row: left `[path: ..., only: :dev]` against `only: [:dev, :test]` |
| Docker script without `ScrypathFixtures` in `forbidden_modules` | the script row: exactly "the runtime probe must forbid the ScrypathFixtures module" |
| Dockerfile missing the fixtures `COPY` in `runtime_test` | the Dockerfile row: exactly "stage runtime_test copies scrypath_ops/mix.exs but has no ... line" |
| `.dockerignore` gains `fixtures/` | the ignore row: exactly "excludes the fixtures sources: fixtures/" |
| `scrypath_ops/mix.exs` check task moved to second in the `test` alias | "must be the first step of the test alias, found it at position 2" |
| `fixtures/scrypath_fixtures/mix.exs` scrypath dependency gets `only:` | "found extra option only: [:dev, :test]" |
| README `second consumer` reworded | "the README must say \"second consumer\"" |
| a tracked `fixtures/scrypath_fixtures/mix.lock` | "the fixtures project has no Hex dependency, so it keeps no lock file" |
| `reaches_fixtures?` made blind to `"."` | the package plant: `expected "." to be reported as reaching fixtures/scrypath_fixtures` |
| a misformatted file under `fixtures/scrypath_fixtures/lib` | `mix format --check-formatted` named it (so the formatter input is live) |

Every file was restored and the focused tests re-run green before the next step.

## Decisions Made

- Separate `if` block for the fixtures check in the Docker script (plan correction to research N6), with its own regex and five mutants; each mutant also asserts `storybook_script_violations/1` stays `[]`, so the two checks cannot mask each other.
- `ScrypathFixtures` inserted before `PhoenixStorybook` in the probe's `forbidden_modules` (plan-specified), keeping the existing catalog mutant literal intact.
- The mounted probe gets an explicit `.app` assertion for `scrypath_fixtures` (see Deviations).

## Deviations from Plan

### Auto-added

**1. [Rule 2 - Missing critical] Mounted probe `.app` assertion for the fixtures app**
- **Found during:** Task 2
- **Issue:** The plan adds `:scrypath_fixtures` to the mounted probe's forbidden-apps substitution, but that list is checked against the lock (vacuous for a path dependency) and against loaded and started apps. The probe never checked the Ops `.app` requirement list for any forbidden app, so "the mounted consumer lacks the app" was not proven for the `.app` file, which research Pitfall 3 names as part of the proof.
- **Fix:** A `@fixtures_apps` list feeds an assertion that `:scrypath_fixtures` is in neither `applications` nor `optional_applications` of the mounted Ops `.app`, with a comment saying the lock check is vacuous. The forbidden-apps list also includes it, as planned.
- **Files modified:** `test/release/ops_dependency_boundary_test.exs`
- **Commit:** `9dce3914`

**2. [Rule 2 - Missing critical] `.dockerignore` contract row**
- **Found during:** Task 2
- **Issue:** The acceptance criteria name "excluding the tree" as a guard mutation that only the Plan 05 Docker lane would catch (a 15 to 20 minute hosted run).
- **Fix:** A cheap root row reads `.dockerignore`: the fixtures sources must not be excluded (`fixtures`, `fixtures/`, `fixtures/*`, `fixtures/**` and nested forms) and `fixtures/*/_build` and `fixtures/*/deps` must be present, with four plants that assert exact messages.
- **Files modified:** `test/mix/tasks/dependency_boundary_contract_test.exs`
- **Commit:** `9dce3914`

### Small extensions inside the planned checks

- `fixtures_reaching_entries/1` also expands glob entries (a `files:` entry such as `fix*` reaches the tree through Hex's glob rules), with a plant. Near-miss names (`fixtures_notes.md`, `fixturesx`, `lib/fixtures`) are asserted clean so the check cannot pass by flagging everything.
- The Dockerfile rows add a "moved after `deps.get`" and a "copied twice" mutant per stage beside the planned "removed" mutant, and assert the three stages that copy the Ops manifest are exactly `asset_builder`, `runtime_prod` and `runtime_test`.
- The script rows have five mutants, not four: the prod `_build` check is mutated twice (wrong environment in the condition, wrong path).
- The README test also pins that the compliance-claim words are absent, with a plant proving the scan can find them (the plan's Plan 05 denylist covers the same README).

**Total deviations:** 2 auto-added (Rule 2), 0 auto-fixed bugs. **Impact:** none on scope; both additions are tests.

## Issues Encountered

- The acceptance count `grep -c 'forbidden_deps="$forbidden_deps scrypath_fixtures"'` prints 0 with BSD grep because `$` is read as an anchor; `grep -Fc` and the escaped form both print 1. The line is present; only the criterion's quoting differs by grep flavor.
- Not run here, by plan: the `ecommerce-mounted` Docker lane (Plan 05 runs it, or records a skip reason). The script, Dockerfile and `.dockerignore` edits are proven by the static contract, `bash -n`, the contract rows with their mutants, and the static node test, not by a built image.
- The README's "Recordings" section points at `recordings/meilisearch-v1.15/PROVENANCE.md`, which Plan 03 writes. No test pins that link yet; until Plan 03 lands the pointer leads nowhere.

## Known Stubs

None. No placeholder text, empty-value-to-UI data or unwired data source in the files this plan created or changed.

## Threat Flags

None. No new endpoint, auth path or file-access pattern. The Docker script changes add forbid checks only. Mitigations recorded for T-196-04 (package refute and `fixtures_reaching_entries/1`), T-196-05 (probes, script lists, mention guards), T-196-06 (path-aware reader and seven plants), T-196-07 (compat inventory; `ops-ui-path` and the ecommerce classifier unchanged) and T-196-08 (no edit to either phase173 copy or `posture_live.ex`, guard row exit 0, deletion trigger recorded).

## Hosted-CI notes (not measured here)

- Plan 01's `scrypath_ops/mix.exs` edit already makes the first `ops-ui` and `ecommerce-mounted` runs miss both BEAM caches. This plan adds no further manifest edit to the cache graphs, but it does edit the Dockerfile and the verify script, which the `ecommerce-mounted` lane runs, so that lane is the one to watch on the first push.
- The local `ops_dependency_boundary_test` integration run took 187 s on this machine. I did not check which hosted lane runs it or how long it takes there. Nothing was pushed.

## Next Phase Readiness

Plan 03 can add the recordings directory and `Recordings` module against a project whose boundaries are already accounted for; the README's recordings pointer will resolve then. Plan 05 owns the Docker lane run and the final pre-push mirror (including the phase gate above on the committed head). Nothing blocks Plan 03.

## Self-Check: PASSED

- All 14 plan files exist on disk (`[ -f ]`).
- Commits `ffb23954`, `9dce3914` and `0b6cde7c` are ancestors of HEAD (`git merge-base --is-ancestor`).
- Every task `<acceptance_criteria>` grep re-run and passing (counts as listed in the commit checks; `grep -F` for the `$`-containing one); the README denylist grep is clean.
- Plan-level `<verification>` re-run on the final state (node classifier tests 52/52, five root test files 186/0, `bash -n`, static contract, `mix format --check-formatted`, whole-repo Credo, guard row exit 0, locks identical to `origin/main`).
- No protected config file (`.planning/config.json`, `.planning/state.json`, `.impeccable/config.json`) staged in any of the three commits; no commit deleted a tracked file.
