---
phase: 185-executable-ui-quality-foundations
plan: "07"
subsystem: ui
tags: [phoenix, playwright, routes, caller-auth]
requires:
  - phase: 185-02
    provides: [pinned UI literal baseline and bootstrap history]
  - phase: 185-05
    provides: [qualified pre-change disposable capture and ownership boundary]
provides:
  - Standalone root redirect and generator-ledger reduction
  - Test-only secured caller-router HTTP proof around the real Ops mount macro
  - Browser route-preservation spec driven by the maintained capture inventory
affects: [185-06, 185-08, 185-09, 185-wave4-integration]
actuals:
  tokens: 8146
  tasks: 2
  commits: 12
  plan_head_before: 19e26118a59ceb3217e052458ab2e6ebd5f7aedf
  plan_head_after: 346a3620b87be0bdd5d379d4b3d944c7505f801a
tech-stack:
  added: []
  patterns:
    - Test-only caller plug wraps the real Scrypath Ops mount macro in a host router.
    - Route preservation tests derive mounted and standalone paths from the maintained UI capture inventory.
key-files:
  created:
    - examples/scrypath_ecommerce/e2e/ui_routes_preservation.spec.ts
  modified:
    - scrypath_ops/test/scrypath_ops_web/router_test.exs
key-decisions:
  - Keep the public ecommerce demo browser pipeline unchanged; demonstrate secured caller behavior only in test support.
  - Use the real Ops LiveView mount for authorized-entry evidence; do not substitute route metadata or a fake endpoint.
requirements-completed: []
coverage:
  - id: D1
    description: Standalone root redirects locally and generator scaffolding is removed with only its ledger findings reduced.
    verification:
      - kind: integration
        ref: mix verify.ops_ui (Task 1 receipt carried forward)
        status: pass
      - kind: other
        ref: mix verify.repository_contracts and the Task 1 Node history suite (Task 1 receipts carried forward)
        status: pass
    human_judgment: false
  - id: D2
    description: Missing and invalid caller identities are denied, while a valid identity reaches the actual mounted Ops LiveView over HTTP.
    verification:
      - kind: integration
        ref: scrypath_ops/test/scrypath_ops_web/router_test.exs#secured caller router
        status: pass
    human_judgment: false
  - id: D3
    description: The public demo, standalone routes, mount prefixes, redirect and assets have a browser preservation spec based on the maintained capture inventory.
    verification:
      - kind: other
        ref: npm run --silent test:e2e:list -- e2e/ui_routes_preservation.spec.ts
        status: pass
      - kind: automated_ui
        ref: examples/scrypath_ecommerce/e2e/ui_routes_preservation.spec.ts (parent-owned integrated Wave 4 run pending)
        status: unknown
    human_judgment: false
    rationale: The new cases are discovered, but their disposable browser behavior has not run; the parent must record the consolidated integrated candidate receipt first.
status: source_ready_full_verification_pending
duration: "not recorded for this resumed continuation"
completed: 2026-11-01T01:27:26Z
---

# Phase 185 Plan 07: Route and caller-boundary preservation

**The standalone redirect and test-only secured caller-router proof are committed; the consolidated browser route run remains a parent-owned Wave 4 gate.**

## Performance

- **Duration:** Not recorded for this resumed continuation.
- **Tasks:** 2 implemented; the parent-owned integrated browser acceptance remains pending.
- **Files modified:** 9 across Task 1 and Task 2 commits.

## Accomplishments

- Preserved Task 1’s fixed standalone `/` → `/ops` redirect, deleted generator view/template, and actual ledger reduction in commits `abc30353` and `dd1d7237`.
- Added a secured test host router that wraps `scrypath_ops_routes/2`. HTTP requests without identity return 401, invalid identity returns 403, and a valid identity renders the real Ops Control Room LiveView.
- Added a Playwright route spec that reads the maintained capture surface and standalone route inventory, checks the exact standalone redirect, public storefront root, route prefixes, and host/mounted/standalone CSS and JavaScript assets.

## Verification

- Task 1’s carried-forward receipts report the canonical Ops suite passed, repository contracts passed 145/0, and the Node history suite passed 14/0. This continuation preserved commits `abc30353` and `dd1d7237` and did not rerun those earlier suites.
- From `scrypath_ops/`, `MIX_DEPS_PATH=/private/tmp/scrypath-phase184-10-20261030T072352Z/deps/ops MIX_BUILD_PATH=/private/tmp/scrypath-phase184-10-20261030T072352Z/build/ops ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' asdf exec mix test test/scrypath_ops_web/router_test.exs` passed: 6 tests, 0 failures. The output was tee'd to the linked log. It emitted warnings that optional `:esbuild` and `:tailwind` applications are unavailable in test config.
- From the repository root, `MIX_DEPS_PATH=/Users/jon/projects/scrypath/.claude/worktrees/agent-p185-07-1zmhv7id/deps MIX_BUILD_PATH=/Users/jon/projects/scrypath/.claude/worktrees/agent-p185-07-1zmhv7id/_build ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' asdf exec mix format --check-formatted scrypath_ops/test/scrypath_ops_web/router_test.exs` passed.
- `npm run --silent test:e2e:list -- e2e/ui_routes_preservation.spec.ts` discovered 4 cases in 1 file. This validates test parsing and discovery only; it is not browser behavior evidence.
- The actual Task 2 router-test log is `/private/tmp/scrypath-phase185-execution/task02-router-test.log` (SHA-256 `5f71a08ac1d9c13954d7b71b7b41565819a6ce7ab18debcbf31f32c91a59735e`). The inventory log is `/private/tmp/scrypath-phase185-execution/task02-playwright-inventory.log` (SHA-256 `941a167312e7046a3c58271dc35cfc10b2cd4fefee2787b3c6fdf37e9ca39141`).
- `mix verify.ecommerce_e2e` was not run by this worker. The parent consolidated the complete browser inventory into one integrated Wave 4 gate, with the approved 900-second total cap and 300-second reserve; earlier over-budget attempts remain failed and unchanged.
- Production routers and pipelines were not modified. The ecommerce demo remains public, and the retained preview was not operated.

## Task Commits

1. **Task 1 RED:** `abc30353` — `test(185-07): assert standalone root redirect`
2. **Task 1 GREEN:** `dd1d7237` — `feat(185-07): redirect standalone root and shrink generator ledger`
3. **Task 2:** `346a3620` — `test(185-07): preserve caller auth and mounted route boundaries`

## Decisions Made

- The demo’s real public browser behavior stays unchanged. HTTP authorization is proven using a test-only host pipeline surrounding the actual library mount.
- The route spec reads the route declarations from `ui-review.mjs` as source data. Importing that capture module from Playwright failed because its ESM graph contains top-level await; the source-reading approach keeps the maintained inventory authoritative without changing the capture tool.

## Deviations from Plan

- Task 2 changes only test support and browser assertions; it adds no production behavior. A pre-fixture RED would fail on missing test modules/setup rather than the planned behavior, so no invalid RED was recorded. The HTTP fixture tests passed after implementation. Full browser acceptance remains pending at the parent-owned integrated gate.
- The first targeted Ops test attempt used the worktree’s core-only dependency cache and stopped before test discovery because Phoenix packages were absent. The test then passed using the already-existing Phase 184 Ops dependency cache and build directory; no package was fetched or installed.

## Issues Encountered

- No product or route regression was found in the scoped HTTP checks. The Playwright cases are not yet executed against the disposable stack, so their runtime outcome remains unknown.

## User Setup Required

None.

## Next Phase Readiness

Task 2 source is ready for the parent-owned integrated Wave 4 candidate run. Keep this plan pending full verification and `requirements-completed` empty until that full receipt is recorded. The parent acts next; no user action is needed.

## Self-Check: PASSED

Summary and both Task 2 files exist; Task 1 RED, Task 1 GREEN, and Task 2 commits are ancestors of this worktree HEAD. Full browser acceptance is explicitly pending, not included in this self-check.

---
*Phase: 185-executable-ui-quality-foundations*
*Completed: 2026-11-01*

## Parent handoff reconciliation

The parent reviewed Task 2 source and corrected D3 to automated verification pending. This is a source handoff, not plan completion. The executor attempted its summary commit without Git metadata access and stopped on staging_failed. The parent owns this metadata reconciliation using the already-authorized Git access; no worker retry or broad staging is used.
