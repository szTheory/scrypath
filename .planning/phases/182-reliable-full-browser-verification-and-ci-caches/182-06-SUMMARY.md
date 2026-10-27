---
phase: 182-reliable-full-browser-verification-and-ci-caches
plan: "06"
subsystem: ci
tags: [github-actions, beam, caching, elixir, mix]

# Dependency graph
requires:
  - phase: 182-05
    provides: [verification and CI workflow baseline]
provides:
  - Graph-aware BEAM cache identities and allowlisted restore paths
  - Compatible Hex archive fallback separated from strict resolved build state
  - Path-specific cache wiring for Ops, Phoenix, ecommerce, and deep-quality jobs
affects: [182-08, ci]

# Actuals measured from the plan ledger through the four task commits.
actuals:
  tokens: 9336.25
  tasks: 2
  commits: 4
  plan_head_before: 10cc88dde950d6750f7a5666d44a3bb112653921
  plan_head_after: 445ad20d5869d37b67e45ec1d761b5a546039733

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Graph allowlists fingerprint each consuming Mix manifest, lock, and source tree.
    - Hex archives use a compatible fallback; resolved build output restores require matching locks and runtime identity.

key-files:
  created:
    - scripts/ci/beam_cache.cjs
  modified:
    - scripts/ci/beam_cache.test.cjs
    - .github/workflows/ci.yml
    - test/mix/tasks/workflow_wiring_test.exs

key-decisions:
  - "Only ~/.hex/packages receives lock-omitting fallback; graph, runner image, OS/architecture, Elixir/OTP, environment, target, profile, and manifests remain compatible."
  - "Resolved deps and _build/test keys include exact graph manifests and locks; restore prefixes omit only source digest."
  - "PLTs use a separate exact key, while no-optional and isolated package-consumer builds remain outside ordinary archives."
  - "CACHE-02 is not marked complete until the hosted fallback, lock-change, and cold-cache evidence from plan 182-08 exists."

requirements-completed: []

# Coverage metadata for locally proven plan deliverables. Hosted acceptance remains in 182-08.
coverage:
  - id: D1
    description: "Graph-aware cache keys separate compatible Hex downloads from strict resolved build outputs."
    requirement: CACHE-02
    verification:
      - kind: unit
        ref: "scripts/ci/beam_cache.test.cjs#every platform, toolchain, environment, target, profile and graph boundary changes compatible prefixes"
        status: pass
      - kind: unit
        ref: "scripts/ci/beam_cache.test.cjs#lock changes retain only compatible Hex download fallback, and source changes retain rebuild compatibility"
        status: pass
      - kind: unit
        ref: "scripts/ci/beam_cache.test.cjs#identity inputs fail closed when required runtime or graph data is missing or invalid"
        status: pass
    human_judgment: false
  - id: D2
    description: "All runner-side Mix cache consumers use their actual dependency graph and keep deps.get before canonical verification."
    requirement: CACHE-02
    verification:
      - kind: integration
        ref: "scripts/ci/beam_cache.test.cjs#path-dependent CI cache consumers use their dependency graph and resolve before verification"
        status: pass
      - kind: integration
        ref: "test/mix/tasks/workflow_wiring_test.exs#path-dependent CI consumers key their graph before normal dependency resolution and verification"
        status: pass
    human_judgment: false
  - id: D3
    description: "Deep-quality PLTs use a separate exact cache key, and the existing workflow contract lane executes the Node boundary suite."
    requirement: CACHE-02
    verification:
      - kind: unit
        ref: "scripts/ci/beam_cache.test.cjs#path-dependent CI cache consumers use their dependency graph and resolve before verification"
        status: pass
      - kind: integration
        ref: "test/mix/tasks/workflow_wiring_test.exs#deep-quality resolves dependencies and caches PLTs separately with a strict key"
        status: pass
      - kind: integration
        ref: "test/mix/tasks/workflow_wiring_test.exs#Node BEAM cache boundaries execute inside the existing wiring contract lane"
        status: pass
    human_judgment: false

# Metrics
duration: 15 min
completed: 2026-10-27
status: complete
---

# Phase 182 Plan 06: Safe BEAM Cache Boundaries Summary

**Graph-aware BEAM cache keys separate compatible Hex archives from strict compiled state across all CI cache consumers.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-10-27T01:36:12Z
- **Completed:** 2026-10-27T01:50:45Z
- **Tasks:** 2
- **Files modified:** 4

## Execution Refs

- Execution branch: `worktree-agent-p182-06-1793064668465`
- Execution base: `10cc88dde950d6750f7a5666d44a3bb112653921`
- Fetched `origin/main`: `6b65f8a019ab467c11357ab59942ce67feb62735`, an ancestor of the execution base; no merge was needed.

## Accomplishments

- Added `beam_cache.cjs` with explicit root, Ops, ecommerce, and Phoenix graphs. It hashes actual runner image, platform, Elixir/OTP runtime, Mix environment, target, profile, manifests, locks, and source, and rejects missing identity inputs.
- Split cache restores: only `~/.hex/packages` has a lock-omitting compatible fallback; resolved dependency and `_build/test` paths retain exact graph/lock/runtime boundaries and refresh their primary key when source changes.
- Reconciled the 11 runner-side cache jobs. Deep-quality now resolves dependencies unconditionally and stores `priv/plts` under a separate exact key. Docker layer caches, no-optional builds, and isolated package consumers remain separate.
- Added graph, lock, source, runtime, path, and workflow-order tests; the existing ExUnit workflow contract now runs the Node behavior suite.

## Task Commits

1. **Task 1 RED:** `e940b427` — `test(182-06): require safe BEAM cache boundaries`
2. **Task 1 GREEN:** `9a0e6fd4` — `feat(182-06): add strict root BEAM cache planning`
3. **Task 2 RED:** `af7b93ee` — `test(182-06): cover path graph CI cache boundaries`
4. **Task 2 GREEN:** `445ad20d` — `feat(182-06): reconcile path-specific CI cache graphs`

Both RED targets failed on their intended missing workflow behavior and were accepted by the TDD evidence classifier before implementation. The final Node suite reported 8 tests with 0 failures.

## Files Created/Modified

- `scripts/ci/beam_cache.cjs` — cache identity, graph fingerprints, restore keys, and allowlisted paths.
- `scripts/ci/beam_cache.test.cjs` — key-boundary, missing-input, path-allowlist, and workflow wiring behavior tests.
- `.github/workflows/ci.yml` — separate Hex/resolved caches and explicit graph/environment/profile identities across 11 jobs.
- `test/mix/tasks/workflow_wiring_test.exs` — deep-quality and path-consumer assertions plus the Node suite harness.

## Verification

- `node --test scripts/ci/beam_cache.test.cjs` — 8 tests passed, 0 failures.
- `MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/mix/tasks/workflow_wiring_test.exs` — 58 tests passed, 0 failures. `HEX_HOME` and `MIX_HOME` were directed to `/private/tmp` for this invocation.
- `actionlint .github/workflows/ci.yml` — passed.
- `git diff --check` — passed.
- `gsd_run check evaluation-scope --plan "182-06" --commits-only --raw` — resolved all 4 task commits on this branch.

## Decisions Made

- Keep download fallback limited to Hex package archives and preserve graph, manifests, platform, toolchain, environment, target, and profile compatibility.
- Keep compiled restores lock-strict and source-refreshable only within the same compatible resolved prefix.
- Keep PLTs in a separate exact-key action. Retain distinct Ops, Phoenix, and ecommerce graph identities, with Docker image caching separate from runner-side BEAM caches.
- Leave `CACHE-02` uncompleted because this plan does not contain the hosted cache receipts required to prove actual fallback, lock-change, and cold-cache behavior.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

- Initial `mix` verification could not start because dependencies had not been fetched. The default `mix deps.get` then failed when Hex tried to write `/Users/jon/.hex/cache.ets` (`:eaccess`). Redirecting `HEX_HOME` and `MIX_HOME` to `/private/tmp/scrypath-phase182-06-*` allowed the locked dependency fetch and warning-as-error checks to complete; no lockfile changes were made.
- An optional `mix format --check-formatted test/mix/tasks/workflow_wiring_test.exs` check still reports two unchanged formatting issues already present before this plan. It did not report the lines changed by this plan. The plan’s compile/test verification passed.
- No hosted cache fallback, changed-lock miss, or cold-cache execution was claimed; those receipts remain assigned to 182-08.

## User Setup Required

None.

## Next Phase Readiness

The local key and workflow contracts are ready for the remaining phase work. `CACHE-02` still requires the representative hosted fallback, lock-change, and cold-cache evidence planned in 182-08 before the requirement can be marked complete.

## Self-Check: PASSED

- All four changed source/test/workflow files exist.
- All four task commits are ancestors of the execution HEAD.
- The evaluation-scope check resolved 4 commits on this branch.
- The Node and warning-as-error ExUnit verification commands passed with nonzero test counts.

---
*Phase: 182-reliable-full-browser-verification-and-ci-caches*
*Completed: 2026-10-27*
