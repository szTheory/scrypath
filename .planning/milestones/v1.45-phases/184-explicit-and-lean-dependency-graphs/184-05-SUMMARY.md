---
phase: "184-explicit-and-lean-dependency-graphs"
plan: "05"
subsystem: dependencies
tags: ["Elixir", "Mix", "Req", "Telemetry", "Phoenix"]
requires:
  - phase: "184-03"
    provides:
      - "Dev-only optional Ops diagnostics with compile-safe capability guards."
  - phase: "184-04"
    provides:
      - "Optional Sigra integration and fail-closed sensitive-action gating."
provides:
  - "Dev-only asset tools and host diagnostics with preserved Mix aliases."
  - "Matching approved Req ranges and a mandatory direct Ops Telemetry dependency."
  - "Explicit ecommerce production static-manifest, Repo, and Endpoint configuration."
affects: ["184-06", "184-07", "184-12", "dependency-boundary-verification"]
actuals:
  tokens: 4592
  tasks: 2
  commits: 2
  plan_head_before: "25db7f26fbfdc7e752875a03f2bff5d09d135520"
  plan_head_after: "abcbc3c6935a85cc8e6a55091b1383b29496c4ec"
tech-stack:
  added: []
  patterns:
    - "Mix asset aliases select the dev environment and preserve configured tool versions and output paths."
    - "Production dependency and runtime boundaries are protected by parsed-source mutation contracts."
key-files:
  created:
    - "examples/scrypath_ecommerce/config/prod.exs"
  modified:
    - "scrypath_ops/mix.exs"
    - "examples/scrypath_ecommerce/mix.exs"
    - "examples/scrypath_ecommerce/config/runtime.exs"
    - "test/mix/tasks/dependency_boundary_contract_test.exs"
key-decisions:
  - "Keep esbuild and Tailwind as dev-only Mix tools, using the existing 0.25.4 and 4.1.12 authorities and output paths."
  - "Use the approved Req union in root, Ops, and ecommerce manifests; declare Ops Telemetry directly and mandatorily."
  - "Use DATABASE_URL or explicit PG* inputs for the host Repo and require SECRET_KEY_BASE at production boot."
  - "Leave host ownership of Repo and Endpoint intact; defer production image and serving proof to plans 184-12 and 184-06."
requirements-completed: ["DEP-04", "DEP-05"]
coverage:
  - id: D1
    description: "Ops and ecommerce keep asset tooling and host diagnostics in development, preserve configured Mix asset commands, and declare the approved direct Req and Ops Telemetry contracts."
    requirement: "DEP-04"
    verification:
      - kind: unit
        ref: "test/mix/tasks/dependency_boundary_contract_test.exs#asset tools and host diagnostics stay development-only"
        status: pass
      - kind: unit
        ref: "test/mix/tasks/dependency_boundary_contract_test.exs#direct Req and Ops Telemetry requirements match the approved public contract"
        status: pass
      - kind: unit
        ref: "test/mix/tasks/dependency_boundary_contract_test.exs#dev asset aliases preserve the configured Mix tools and output paths"
        status: pass
    human_judgment: false
  - id: D2
    description: "Ecommerce production source names its static manifest and explicit Repo and Endpoint runtime inputs while keeping test secrets and sandbox settings out of production."
    requirement: "DEP-05"
    verification:
      - kind: unit
        ref: "test/mix/tasks/dependency_boundary_contract_test.exs#ecommerce production configuration uses a static manifest and explicit runtime inputs"
        status: pass
      - kind: unit
        ref: "test/mix/tasks/dependency_boundary_contract_test.exs#production configuration mutations reject copied secrets, sandbox settings, and missing inputs"
        status: pass
    human_judgment: false
duration: "7 min"
completed: "2026-10-30"
status: complete
---

# Phase 184 Plan 05: Explicit and Lean Dependency Graphs Summary

**Dev-only asset and diagnostics graphs, aligned Req and Telemetry dependencies, and explicit ecommerce production boot inputs**

## Performance

- **Duration:** 7 min
- **Started:** 2026-10-30T00:23:48Z
- **Completed:** 2026-10-30T00:31:04Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Scoped Ops and ecommerce esbuild/Tailwind dependencies to development; scoped ecommerce dashboard and telemetry diagnostics to development.
- Preserved the existing esbuild and Tailwind versions, asset inputs, output paths, and Ops aliases; added ecommerce setup/build aliases using those Mix tools.
- Aligned root, Ops, and ecommerce direct Req requirements to `~> 0.6.1 or ~> 0.7`, and declared mandatory direct Telemetry in Ops.
- Added ecommerce production configuration for the static cache manifest, Repo database inputs, Endpoint secret, server flag, and port.
- Extended the root dependency-boundary contract with direct requirement, alias, output-path, production configuration, sandbox, and secret mutation assertions.

## Verification

- **Toolchain:** Elixir 1.19.5 / OTP 28.5.
- **Task 1:** `MIX_ENV=test asdf exec mix test test/mix/tasks/dependency_boundary_contract_test.exs --warnings-as-errors` — **PASS**, 11 tests, 0 failures; `mix format --check-formatted` — **PASS**.
- **Task 2 and final plan verification:** `MIX_ENV=test asdf exec mix test test/mix/tasks/dependency_boundary_contract_test.exs --warnings-as-errors` — **PASS**, 13 tests, 0 failures; `mix format --check-formatted` — **PASS**.
- Build and dependency outputs were isolated under `/private/tmp/scrypath-phase184-05-20261029/`. `mix deps.get` populated only versions already present in the root lock; no lockfile changed.
- **Source range:** plan base `25db7f26fbfdc7e752875a03f2bff5d09d135520`; task-code head `abcbc3c6935a85cc8e6a55091b1383b29496c4ec`; 2 task commits.
- **Lock identities (SHA-256):**
  - `mix.lock`: `bd30554574b9b902df5e28f027db4dfc04afcb7a7fd8c93b757391e5337d20f8`
  - `scrypath_ops/mix.lock`: `a9685eba8236f7925d30044db9b2bf96a3c644d61c5f4a13db66af037f4dc95c`
  - `examples/scrypath_ecommerce/mix.lock`: `9c30fb79d83a5e6ce8b97f583bd62774aff9fd466ec998c4070c4d903b5cb4e1`
- These checks establish the bounded source/config slice only. No production image compile, digest, or server start was performed; those remain with plans 184-12 and 184-06.

## Task Commits

1. **Task 1: Scope wrappers and preserve host dev commands** — `f5edf876` (`chore(184-05)`).
2. **Task 2: Provide explicit production host boot/static configuration** — `abcbc3c6` (`chore(184-05)`).

## Files Created/Modified

- `scrypath_ops/mix.exs` — dev-only asset tools, preferred dev asset environments, approved Req range, and direct Telemetry dependency.
- `examples/scrypath_ecommerce/mix.exs` — dev-only wrappers/diagnostics, approved Req range, and configured asset aliases.
- `examples/scrypath_ecommerce/config/prod.exs` — production static manifest and disabled dev reload/debug/watchers.
- `examples/scrypath_ecommerce/config/runtime.exs` — production Repo and Endpoint inputs while retaining the test sandbox override.
- `test/mix/tasks/dependency_boundary_contract_test.exs` — dependency, alias, asset output, production input, and mutation contracts.

## Decisions Made

- The ecommerce app has no documented `assets.deploy` command, so it receives `assets.setup` and `assets.build` aliases only; the existing Ops deploy alias remains intact.
- Production database configuration accepts `DATABASE_URL` or the explicit `PGUSER`, `PGPASSWORD`, `PGHOST`, `PGPORT`, and `PGDATABASE` path.
- Production boot reads the secret and host endpoint controls at runtime; the test secret and sandbox behavior remain in test-specific configuration.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The fresh worktree had no root dependency checkout for the initial focused test. Fetching its already locked Hex dependencies into the disposable `/private/tmp` paths resolved setup; the final focused test and format checks passed without changing any lockfile.
- The retained-preview preflight refused the named `ui/next` checkout because it does not include `origin/main`; that checkout also had unrelated pending files. No preview files, container state, or data were changed, and no visual review claim is made for this source/config task.
- Direct shell writes to this worktree's Git metadata were denied by the sandbox. The measured plan base was recorded at `/private/tmp/scrypath-phase184-05-20261029/plan-head-before-184-05`; both task commits ran normally with hooks after the authorized Git operation was approved.

## User Setup Required

None - no external service configuration was performed.

## Next Phase Readiness

- The source and contract slice is ready for 184-06 runtime serving proof, 184-07 lock resolution, and 184-12 asset bundle handoff.
- The requirement-readiness query reports DEP-04 and DEP-05 blocked by sibling plans; no shared requirement marker was changed.
- `STATE.md` and `ROADMAP.md` were not modified.

## Self-Check: PASSED

- All five task files exist, including the new production config.
- Task commits `f5edf876` and `abcbc3c6` are ancestors of the plan head.
- Evaluation scope resolved 2 task commits on this branch.
- Final plan verification passed: 13 focused tests, 0 failures; formatter check passed.

---
*Phase: 184-explicit-and-lean-dependency-graphs*
*Completed: 2026-10-30*
