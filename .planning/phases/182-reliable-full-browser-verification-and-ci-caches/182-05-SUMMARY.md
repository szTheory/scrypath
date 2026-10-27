---
phase: 182-reliable-full-browser-verification-and-ci-caches
plan: "05"
subsystem: ci
tags: [github-actions, docker-buildx, buildkit, compose, ecommerce-e2e]
requires:
  - phase: 182-reliable-full-browser-verification-and-ci-caches
    provides:
      - Existing Compose verifier lifecycle and E2E workflow contract from plan 182-04
provides:
  - Compose-derived Bake preparation and image handoff validation for focused and full E2E verification
  - Trusted, bounded BuildKit GHA v2 cache imports and exports with stable per-recipe scopes
  - CI wiring that checks loaded image identity before running the existing canonical Mix verification commands
affects: [182-08, ci, ecommerce-e2e]
actuals:
  tokens: 13902
  tasks: 2
  commits: 4
  plan_head_before: b80a9c0f3dbff24564303f01c7f98040b397141c
  plan_head_after: a85f4e51ec53849f755790abe6a745e8ce77acef
tech-stack:
  added: []
  patterns:
    - Compose-derived Bake graphs are loaded locally and handed to verification without a second build or registry push.
    - GHA cache readers and writers are selected from trusted event, repository, ref, and job metadata.
key-files:
  created:
    - scripts/ci/ecommerce_build.cjs
    - scripts/ci/ecommerce_build.test.cjs
  modified:
    - .dockerignore
    - .github/workflows/ci.yml
    - examples/scrypath_ecommerce/scripts/verify-e2e.sh
    - test/mix/tasks/workflow_wiring_test.exs
key-decisions:
  - "Keep local Compose builds independent from GitHub credentials; use checked prebuilt images only when the manifest and runtime image IDs match."
  - "Allow full cache export only for schedule or workflow_dispatch events on szTheory/scrypath main; mounted jobs and pull requests import without exporting."
  - "Use stable recipe-specific v2 cache scopes and bound cache operations to 120 seconds; treat exporter failure as a performance warning only after image handoff is valid."
  - "Defer live warm-cache, fresh-builder cold-cache, and exact-SHA hosted E2E acceptance to plan 182-08."
requirements-completed: []
coverage:
  - id: D1
    description: Compose-derived prebuilt images are checked against scope, source, model, tags, and runtime image IDs while local Compose build behavior remains available.
    verification:
      - kind: unit
        ref: "node --test scripts/ci/ecommerce_build.test.cjs scripts/ci/ecommerce_lifecycle.test.cjs"
        status: pass
    human_judgment: false
  - id: D2
    description: Trusted bounded GHA v2 cache policy uses stable scopes per distinct recipe, denies PR exports, and excludes environment secrets from Docker build contexts.
    requirement: CACHE-01
    verification:
      - kind: unit
        ref: "node --test scripts/ci/ecommerce_build.test.cjs"
        status: pass
    human_judgment: true
    rationale: "Live cache import/export receipts and a genuinely fresh import-disabled build are external acceptance evidence assigned to plan 182-08."
  - id: D3
    description: Existing mounted and full CI jobs load and validate Compose-derived local images before invoking the canonical Mix verification paths.
    requirement: BROW-03
    verification:
      - kind: integration
        ref: "HEX_HOME=/private/tmp/scrypath-phase182-hex-home MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/mix/tasks/workflow_wiring_test.exs"
        status: pass
    human_judgment: true
    rationale: "The workflow wiring and repository contracts pass locally, but an exact-SHA hosted full ecommerce-e2e run is required and is not available from this execution."
duration: 28 min
completed: 2026-10-26
status: complete
---

# Phase 182 Plan 05: Trusted BuildKit Cache Summary

**Compose-derived Buildx images with source-checked handoff and trusted, bounded GHA v2 cache reuse**

## Performance

- **Duration:** 28 min
- **Started:** 2026-10-27T00:58:21Z
- **Completed:** 2026-10-27T01:26:59Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added Compose-derived focused/full Bake preparation and an image handoff manifest. Prebuilt verification refuses scope, model, source, tag, image ID, or runtime-image mismatches and does not invoke a second build; ordinary local verification retains its Compose build path.
- Added trusted BuildKit cache policy with stable `scrypath-ecommerce-app-v1`, `scrypath-ecommerce-browser-v1`, and `scrypath-ecommerce-standalone-ops-v1` scopes. Cache uses GHA API v2 and 120-second bounds. Only scheduled or manually dispatched full runs on `szTheory/scrypath` main can export; mounted jobs and pull requests can import but do not export.
- Wired the existing mounted and full CI jobs to build and load the resolved Compose graph, validate the image handoff, then run their existing canonical Mix verification commands. Cache-export failure is reported as a performance warning only when the checked local image handoff remains valid.
- Added behavior and workflow-wiring coverage, including secret/context exclusions and running the build helper suite from the repository-contract ExUnit task.

## Task Commits

Each task was committed atomically:

1. **Task 1: Prove model/tag/source parity before allowing the prebuilt handoff**
   - `3150e8e1` — `test(182-05): cover prebuilt image handoff path`
   - `28c4bbf1` — `feat(182-05): validate prebuilt Compose image handoff`
2. **Task 2: Enable bounded first-party cache import/export in existing Docker jobs**
   - `72670544` — `test(182-05): require trusted bounded cache policy`
   - `a85f4e51` — `feat(182-05): wire trusted BuildKit cache reuse`

## Files Created/Modified

- `scripts/ci/ecommerce_build.cjs` — Compose/Bake preparation, cache policy, local image loading metadata, and handoff validation.
- `scripts/ci/ecommerce_build.test.cjs` — command-double tests for handoff parity, cache policy and scope behavior.
- `examples/scrypath_ecommerce/scripts/verify-e2e.sh` — validates prebuilt manifests and runtime image IDs before no-build verification.
- `.github/workflows/ci.yml` — pins Docker actions and wires checked local Bake images and cache policy into mounted/full jobs.
- `test/mix/tasks/workflow_wiring_test.exs` — checks CI wiring and executes the build helper behavior tests.
- `.dockerignore` — excludes `.env` and `.env.*` files at root and nested paths.

## Verification

- `node --test scripts/ci/ecommerce_build.test.cjs scripts/ci/ecommerce_lifecycle.test.cjs` — **34 tests passed, 0 failed**.
- `node --test scripts/ci/ecommerce_build.test.cjs` — **17 tests passed, 0 failed**.
- `HEX_HOME=/private/tmp/scrypath-phase182-hex-home MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors test/mix/tasks/workflow_wiring_test.exs` — **55 tests passed, 0 failures**, warnings treated as errors.
- `HEX_HOME=/private/tmp/scrypath-phase182-hex-home mix verify.repository_contracts` — **94 tests passed, 0 failures**.
- Ruby parsed `.github/workflows/ci.yml` successfully.
- Generated Compose/Bake output was parsed with local `docker buildx bake --print`; the resolved full graph exposed the expected v2 scopes. This verifies generated configuration only, not a hosted cache hit or export.

## Decisions Made

- Preserve the canonical local Compose build path without GitHub credentials.
- Use explicit event/repository/ref/job checks for cache export; pull requests never write shared cache scopes.
- Keep cache exporter status separate from image and verification correctness. A cache miss or exporter outage cannot stand in for successful verification.
- Leave actual warm-cache and import-disabled cold-build acceptance to plan 182-08.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Excluded environment files from Docker build contexts**
- **Found during:** Task 2
- **Issue:** Existing Dockerfiles copy the build context with `COPY . .`, so root or nested `.env` files could enter built layers and exported cache state.
- **Fix:** Added root and nested `.env` / `.env.*` exclusions to `.dockerignore` and regression coverage for secret/context exclusions.
- **Files modified:** `.dockerignore`, `scripts/ci/ecommerce_build.test.cjs`
- **Verification:** `node --test scripts/ci/ecommerce_build.test.cjs` passed.
- **Committed in:** `a85f4e51`

**Total deviations:** 1 auto-fixed (Rule 2 - Missing Critical).  
**Impact:** Required to keep local build contexts and exported layers from containing environment files; no broader scope change.

## Issues Encountered

The default Hex cache path was not writable in this environment. Dependency fetching succeeded with `HEX_HOME=/private/tmp/scrypath-phase182-hex-home`; locked dependencies were unchanged.

## User Setup Required

None.

## Next Phase Readiness

The checked image handoff and trusted cache policy are ready for hosted evaluation. `CACHE-01` and `BROW-03` remain pending because this execution did not produce real GHA cache import/export receipts, a fresh import-disabled build, or an exact-SHA hosted full `ecommerce-e2e` result. Plan 182-08 owns those acceptance checks.

## Self-Check: PASSED

- All six created/modified implementation files exist.
- All four task commit hashes are ancestors of the current worktree HEAD.
- `STATE.md` and `ROADMAP.md` were left unchanged.

