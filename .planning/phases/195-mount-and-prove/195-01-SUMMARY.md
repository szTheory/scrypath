---
phase: 195-mount-and-prove
plan: 01
subsystem: testing
tags: [phoenix_storybook, scrypath_ops, route-guard, dependency-boundary, docker-verify, mix-lock]

requires:
  - phase: 194-discovery-and-onboarding
    provides: green main release train; scrypath_ops ops-ui lane and boundary ledger rows
provides:
  - phoenix_storybook ~> 1.5 as a dev/test-only dependency of scrypath_ops (nine new lock entries)
  - /storybook mount behind a route macro whose guard sits outside the quote and reads the flag as a value
  - first primitive story (ops_button) rendered through the real iframe route with the built stylesheet
  - flipped "Storybook boundary" row plus guard, loopback, script and tarball proofs, each with a planted failing case
affects: [195-02, 195-03, 196, 197]

actuals:
  tokens: 11800
  tasks: 3
  commits: 3

tech-stack:
  added: [phoenix_storybook 1.5.0, mdex 0.14.7, mdex_native 0.3.2, rustler_precompiled 0.10.1, makeup, makeup_eex, makeup_html, makeup_elixir, nimble_parsec]
  patterns:
    - "route guard as an if outside the quote, flag read with Application.get_env at expansion"
    - "AST mutants (delete, move inside quote, drop flag read) over the real macro source"
    - "text check of a Docker verify script with planted String.replace mutants as the cheap local mirror"

key-files:
  created:
    - scrypath_ops/lib/scrypath_ops_web/optional_catalog_routes.ex
    - scrypath_ops/catalog/lib/scrypath_ops/catalog/storybook.ex
    - scrypath_ops/storybook/primitives/ops_button.story.exs
    - scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs
    - scrypath_ops/test/scrypath_ops_web/catalog_routes_test.exs
  modified:
    - scrypath_ops/mix.exs
    - scrypath_ops/mix.lock
    - scrypath_ops/config/dev.exs
    - scrypath_ops/config/test.exs
    - scrypath_ops/lib/scrypath_ops_web/dev_router.ex
    - scrypath_ops/.formatter.exs
    - .formatter.exs
    - test/mix/tasks/dependency_boundary_contract_test.exs
    - test/release/ops_dependency_boundary_test.exs
    - test/release/package_metadata_test.exs
    - examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh

key-decisions:
  - "Route flag read with Application.get_env at expansion, never Macro.expand(Application.compile_env(...)): the latter yields a call AST that is always truthy (Research Finding 1)"
  - "Test-env catalog flag is System.get_env(PHX_SERVER) != true, so the Docker runtime_test image (all-interfaces bind) never mounts /storybook"
  - "Backend module lives in scrypath_ops/catalog/lib, compiled only by elixirc_paths(:dev) and (:test); prod and every mounted consumer compile lib only"
  - "The latent dashboard_routes guard defect in OptionalDevRoutes was left untouched for the maintainer (FLOW-04, recorded by Plan 03)"

patterns-established:
  - "Every new boundary check ships with a planted failing case or a positive control"
  - "New modules get their own file (scrypath_ops/AGENTS.md); no storybook name appears in dev_router.ex itself"

requirements-completed: [MOUNT-01, MOUNT-02, FLOW-01, FLOW-02, FLOW-03, FLOW-04]

coverage:
  - id: D1
    description: "phoenix_storybook ~> 1.5 declared only: [:dev, :test]; the Storybook boundary row fails for absent, unrestricted, dev-only, all-envs and wrong-requirement manifests"
    requirement: MOUNT-01
    verification:
      - kind: unit
        ref: "test/mix/tasks/dependency_boundary_contract_test.exs#planted storybook mention and unrestricted dependency are flagged"
        status: pass
      - kind: unit
        ref: "test/mix/tasks/dependency_boundary_contract_test.exs#ScrypathOps storybook dependency is dev and test only"
        status: pass
    human_judgment: false
  - id: D2
    description: "GET /storybook/iframe/primitives/ops_button renders the production ops_button inside [data-phx-main] with the stylesheet import hashed"
    requirement: MOUNT-02
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs#mount"
        status: pass
    human_judgment: false
  - id: D3
    description: "Route guard sits outside the quote and reads the flag as a value; deleted, moved and flag-blind mutants and a guard-stripped router all fail the checks"
    requirement: MOUNT-02
    verification:
      - kind: unit
        ref: "test/mix/tasks/dependency_boundary_contract_test.exs#catalog route guard sits outside the quote and fails when moved, deleted or flag-blind"
        status: pass
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops_web/catalog_routes_test.exs#planted: a guard-stripped copy of the macro mounts the storybook with the flag off"
        status: pass
    human_judgment: false
  - id: D4
    description: "Catalog flag is off whenever the test endpoint binds non-loopback; dev binds 127.0.0.1"
    requirement: MOUNT-02
    verification:
      - kind: unit
        ref: "test/mix/tasks/dependency_boundary_contract_test.exs#catalog flag is off whenever the test endpoint is not loopback"
        status: pass
    human_judgment: false
  - id: D5
    description: "Mounted test/prod consumers and direct prod lack the storybook apps, modules and route; direct dev/test have them (positive control)"
    requirement: MOUNT-01
    verification:
      - kind: integration
        ref: "mix verify.ops_ui (test/release/ops_dependency_boundary_test.exs, 2 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D6
    description: "verify-dependency-boundaries.sh forbids the catalog in prod and host graphs, in the runtime module probe, and requires HTTP 404 for /storybook; mutation-tested text check mirrors it locally"
    requirement: MOUNT-02
    verification:
      - kind: unit
        ref: "test/mix/tasks/dependency_boundary_contract_test.exs#the Docker boundary script forbids the catalog in prod and host graphs and requires a 404"
        status: pass
      - kind: other
        ref: "bash examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh --static-contract-only"
        status: pass
    human_judgment: true
    rationale: "The Docker-image half (real 404 from the test and prod images, image dependency lists) only runs in the 15 to 20 minute ecommerce-mounted lane, which Plan 03 mirrors before the first push; locally it is covered by the text check and bash -n only."
  - id: D7
    description: "Hex package file list refutes fixtures and storybook"
    requirement: MOUNT-01
    verification:
      - kind: unit
        ref: "test/release/package_metadata_test.exs#package file allowlist only targets root library surfaces"
        status: pass
    human_judgment: false

duration: 12min
completed: 2026-11-21
status: complete
commits: 3
plan_head_before: 574506b4fdb3010dc7d53945f9b5c30a2bf14392
plan_head_after: a95e965704bb1a97816c15b2a74c7b9d4188a250
---

# Phase 195 Plan 01: Mount and prove (dependency, route guard, absence proofs) Summary

**phoenix_storybook 1.5 mounted at /storybook in dev and test only, behind an outside-the-quote route guard, with prod graph, route table, Docker script and tarball absence proofs that each have a planted failing case.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-11-21T21:19:38Z
- **Completed:** 2026-11-21T21:31:39Z
- **Tasks:** 3
- **Files modified:** 16 (5 created, 11 modified)

## Accomplishments

- The first primitive story renders through the real `/storybook/iframe/primitives/ops_button` route with the built `app.css` (`@import "/assets/css/app.css?hash=<md5>" layer(app)`) inside `[data-phx-main]`, on the first run.
- A prod compile has no `/storybook` route and cannot load `PhoenixStorybook`, `MDEx` or `ScrypathOps.Catalog.Storybook`; the test compile has 8 storybook routes (positive control).
- The route guard, the flag truth table, the loopback rule, the storybook dependency row, the Docker script edits and the tarball are each proven by a check with a planted case that fails (or a positive control for the tarball refutes).
- `mix verify.ops_ui` is green locally on the committed head.

## Task Commits

1. **Task 1: Tracer, dependency to one story through the real iframe route** - `6576fd67` (chore)
2. **Task 2: Guard and route proofs that can fail** - `ba2f1044` (test)
3. **Task 3: Production-graph, Docker-image and tarball absence proofs** - `a95e9657` (test)

**Plan metadata:** the docs commit that carries this file and the STATE and ROADMAP updates.

## Evidence

- **Lock growth:** `scrypath_ops/mix.lock` 56 to 65 lines. Added: `phoenix_storybook`, `mdex`, `mdex_native`, `rustler_precompiled`, `makeup`, `makeup_eex`, `makeup_html`, `makeup_elixir`, `nimble_parsec`. No existing entry changed. `mix deps.get --check-locked` exits 0 in the repo root, `scrypath_ops/` and `examples/scrypath_ecommerce/`; the root and host lock files are byte-identical to HEAD.
- **NIF:** `mdex_native` precompiled NIF for `aarch64-apple-darwin` downloaded and cached during the first test compile (log lines 16:20:13.323 to 16:20:14.101, about 0.8 s). Not a hosted measurement; Plan 03 owns the hosted number.
- **Prod absence probe:** `PROD_PROBE routes=14 storybook=0 loaded=[]` (`MIX_ENV=prod mix compile --warnings-as-errors` clean).
- **Test positive control:** `TEST_PROBE storybook=8`.
- **Planted revert (Task 2 acceptance):** with `storybook_dependency_violation/1` restored to its HEAD body, the planted-manifest test failed at `storybook_dependency_violation(wrong_requirement) =~ "~> 1.5"` (the HEAD body returns nil, so the match raises `FunctionClauseError`); the absent case returns nil under that body for the same reason. The flipped body was restored and the file is green (25 tests). The same RED was observed before the flip when the new assertions were written first.
- **Formatter coverage proof:** appending a badly formatted module to the story file made both `mix format --check-formatted` runs (root and `scrypath_ops/`) exit 1; restored, both exit 0.
- **`mix verify.ops_ui`:** exit 0, 226 s wall on the committed head (`a95e9657`). Root boundary integration `test/release/ops_dependency_boundary_test.exs` 2 tests, 0 failures; isolated ops suite 2 doctests, 563 tests, 0 failures. The `OPS_DEPENDENCY_BOUNDARY case=... result=passed` markers are asserted inside those two tests (they fail without the markers) and are not echoed to the lane output.
- **`mix precommit` in `scrypath_ops/`:** exit 0, 23 s (compile with warnings as errors, unused unlock, format, test). The `start_async` assigns warnings in its output come from existing code, not from this plan.
- **Core mirror (partial):** `mix format --check-formatted` plus `dependency_boundary_contract_test.exs`, `package_metadata_test.exs`, `verify_namespace_fence_test.exs` (64 tests, 0 failures); `verify-dependency-boundaries.sh --static-contract-only` passes; `bash -n` clean.

Fidelity and wiring hours: 0.0 h (none; the mount rendered correctly on the first run, and the only adjustment was tightening the stylesheet assertion to the exact `@import` shape after a throwaway peek at the rendered HTML)

## Files Created/Modified

- `scrypath_ops/lib/scrypath_ops_web/optional_catalog_routes.ex` - `catalog_routes/0` macro (guard outside the quote) and `enabled?/2`
- `scrypath_ops/catalog/lib/scrypath_ops/catalog/storybook.ex` - backend module, compiled in dev and test only
- `scrypath_ops/storybook/primitives/ops_button.story.exs` - tracer story, three variations
- `scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs` - mount describe (Plan 02 and Phase 197 extend it)
- `scrypath_ops/test/scrypath_ops_web/catalog_routes_test.exs` - truth table, flag-off, flag-unset, flag-on and guard-stripped routers
- `scrypath_ops/mix.exs`, `mix.lock`, `config/dev.exs`, `config/test.exs`, `lib/scrypath_ops_web/dev_router.ex` - dependency, `elixirc_paths`, flag, one macro call
- `test/mix/tasks/dependency_boundary_contract_test.exs` - flipped storybook row, AST guard test with mutants, dev router check, loopback subprocess test, Docker script text check with mutants
- `test/release/ops_dependency_boundary_test.exs`, `test/release/package_metadata_test.exs` - mounted and direct probes, tarball refutes
- `examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh` - env-aware forbidden list, runtime module probe, HTTP 404 probe for `/storybook`
- `.formatter.exs`, `scrypath_ops/.formatter.exs` - inputs cover `catalog/` and `storybook/`

## Decisions Made

- Followed the plan's decisions as written (see `key-decisions` in the frontmatter). Added two small checks the plan did not list: a flag-unset router case in `catalog_routes_test.exs` and an `nil` bind case for `catalog_bind_violation/1`, because an absent setting is the likeliest drift.

## Deviations from Plan

None - plan executed exactly as written.

The plan's phase-gate text for `mix verify.ops_ui` says the output must contain the `OPS_DEPENDENCY_BOUNDARY` markers. The lane does not print them (the test captures the probe output and asserts it), so the pass is the two green integration tests rather than a grep of the lane log. This is a wording gap in the plan, not a behavior change.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** none.

## Issues Encountered

- First draft of the Task 2 mutant helper used `Macro.prewalk` to wrap the guard in a quote, which would loop (the wrapped node is revisited); the written version uses `Macro.postwalk`. Caught while designing, never run.

## Known Stubs

None.

## Threat Flags

None. The new network surface (`/storybook`, dev and test only) is the one T-195-01 and T-195-02 already cover, and the Docker 404 probe, the loopback subprocess test and the prod probes are the mitigations built here. Residuals for Plan 03 to record: T-195-05 (a stale local test build compiled without `PHX_SERVER=true` and then served with it), and the Docker half of D6, which runs only in the hosted `ecommerce-mounted` lane.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 02 can add `storybook.js` (`js_path` is intentionally omitted from the backend until the bundle exists), four more primitive stories, render-all and the planted failing tree on top of this mount.
- Plan 03 owns the hosted `ops-ui` and `ecommerce-mounted` measurements, the full lane mirror before the first push, and the `dashboard_routes` finding for the maintainer.
- Nothing blocks. No push, PR or Hex release was made.

## Self-Check: PASSED

- Created files exist: `optional_catalog_routes.ex`, `catalog/lib/scrypath_ops/catalog/storybook.ex`, `ops_button.story.exs`, `catalog_contract_test.exs`, `catalog_routes_test.exs` (all FOUND).
- Commits `6576fd67`, `ba2f1044`, `a95e9657` are ancestors of HEAD (all FOUND); `git rev-list --count` from `plan_head_before` is 3.
- No protected config file was staged in any commit.

---
*Phase: 195-mount-and-prove*
*Completed: 2026-11-21*
