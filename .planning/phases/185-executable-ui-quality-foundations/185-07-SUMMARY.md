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
        ref: /private/tmp/scrypath-phase185-execution/heldout-runs/phase185-candidate-4db097d9-r4/phase105-evidence.json
        status: pass
    human_judgment: false
    rationale: The original handoff below is historical; all four real route cases passed in the final integrated canonical run.
status: completed
duration: "not recorded for this resumed continuation"
completed: 2026-11-01T01:27:26Z
---

# Phase 185 Plan 07: Route and caller-boundary preservation

Current outcome: the four route tests passed in canonical full candidate R4 at `4db097d92dfe8a221da3625d70dc5647831c3864`, including actual layout-requested stylesheet/script responses; deliberate forwarded JS403 protection is preserved. The full run passed 254 cases with zero skips/retries/unexpected outcomes and clean teardown. The fresh hosted run for the later CI-only source change is still pending, so this is local candidate evidence, not terminal hosted acceptance.

**The standalone redirect and test-only secured caller-router proof are committed.** The browser route result below is from the current accepted local full run; hosted closeout remains parent-owned.

## Performance

- **Duration:** Not recorded for this resumed continuation.
- **Tasks:** 2 implemented; local integrated browser acceptance passed in R4.
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
- `mix verify.ecommerce_e2e` was not run by this worker. The parent later ran the integrated Wave 4 gate at R4 within the approved budget; earlier failed attempts remain unchanged.
- Production routers and pipelines were not modified. The ecommerce demo remains public, and the retained preview was not operated.

## Task Commits

1. **Task 1 RED:** `abc30353` — `test(185-07): assert standalone root redirect`
2. **Task 1 GREEN:** `dd1d7237` — `feat(185-07): redirect standalone root and shrink generator ledger`
3. **Task 2:** `346a3620` — `test(185-07): preserve caller auth and mounted route boundaries`

## Decisions Made

- The demo’s real public browser behavior stays unchanged. HTTP authorization is proven using a test-only host pipeline surrounding the actual library mount.
- The route spec reads the route declarations from `ui-review.mjs` as source data. Importing that capture module from Playwright failed because its ESM graph contains top-level await; the source-reading approach keeps the maintained inventory authoritative without changing the capture tool.

## Deviations from Plan

- Task 2 changes only test support and browser assertions; it adds no production behavior. A pre-fixture RED would fail on missing test modules/setup rather than the planned behavior, so no invalid RED was recorded. The HTTP fixture tests passed after implementation. The original handoff recorded browser acceptance as pending; the later R4 integrated run supersedes that state.
- The first targeted Ops test attempt used the worktree’s core-only dependency cache and stopped before test discovery because Phoenix packages were absent. The test then passed using the already-existing Phase 184 Ops dependency cache and build directory; no package was fetched or installed.

## Issues Encountered

- No product or route regression was found in the scoped HTTP checks. The Playwright cases are not yet executed against the disposable stack, so their runtime outcome remains unknown.

## User Setup Required

None.

## Next Phase Readiness

Task 2 source was ready for the integrated Wave 4 candidate run; R4 now records that local browser acceptance. Keep phase requirements incomplete until hosted and terminal verification closeout. No user action is needed.

## Self-Check: PASSED

Summary and both Task 2 files exist; Task 1 RED, Task 1 GREEN, and Task 2 commits are ancestors of this worktree HEAD. The self-check is not itself browser evidence.

---
*Phase: 185-executable-ui-quality-foundations*
*Completed: 2026-11-01*

## Parent handoff reconciliation

The parent reviewed Task 2 source and corrected D3 to automated verification pending. This is a source handoff, not plan completion. The executor attempted its summary commit without Git metadata access and stopped on staging_failed. The parent owns this metadata reconciliation using the already-authorized Git access; no worker retry or broad staging is used.

## Final parent integration

The earlier canonical candidate R3 receipt at `7fa0ab07` remains historical evidence and is not relabeled. The current canonical local candidate receipt is `/private/tmp/scrypath-phase185-execution/heldout-runs/phase185-candidate-4db097d9-r4/phase105-evidence.json`, pinned by `accepted-candidate-r4.json`; its 254-case full run passed, including the four route cases, and teardown was clean. The current mounted local cached retry also passed with exact generated/served bytes and clean teardown (`mounted-r2-acceptance.json`). It is not cold-CI or hosted terminal evidence.

## Task Commits

- **Task 1: local redirect and generator-only ledger reduction** — `abc30353`, `dd1d7237`.
- **Task 2: real caller auth, route preservation and observed layout assets** — `346a3620`, `7fa0ab07`.

No user setup is needed. The global preservation capture/review is recorded at its original source; hosted and terminal acceptance remain separate Plan10 obligations.

## Current hosted closeout

At `4db097d9`, local core and repository gates passed. Hosted run `41295225239` passed core/package/backend/coverage/compatibility but the repository job failed because the existing demo test dependency `pngjs` was absent and the run-owned artifact handoff did not match. The CI-only repair uses the existing locked demo dependencies via `npm ci --ignore-scripts` with browser download disabled and aligns the run-owned paths; it adds no package or version. Fresh hosted acceptance for `e445a2c4` is pending. The terminal exact-SHA receipt remains a Plan 10 requirement.

## Implementation-plan disposition

The actual current local source-bound proof completes this plan. The later af78 hosted CI transport retest and final tracked-source attestation belong to Plan10; neither is silently certified here. Current input equality is recorded in `candidate-input-reconciliation-af78dd8f.json`; original canonical and global receipt sources are preserved.

## Final candidate closeout cutoff

Current candidate [41318243156](https://github.com/szTheory/scrypath/actions/runs/41318243156) at `fa42d99ee3ad5290ea7d8ab089ba076c5e25558c` passed all five required jobs, coverage and exact-source immutable attestation, and its full advisory browser lane succeeded after the diagnosed transport, frame-safe accessibility, runtime-handoff, serial full-suite and cold-start repairs. Original local full/pair/global receipts retain their source identities. Final tracked-source terminal attestation remains mandatory and is not certified by this pre-dispatch record. The earlier pending-hosted statements are historical cutoffs; this plan implementation is complete. No future terminal result is asserted.

## Serial full-suite source and proof boundary

The current source passed the complete serial full lane, immutable archive verification and independent canonical receipt recomputation. The batches preserve one worker, zero retries, original traces, the exact discovered union and clean owned teardown within the existing limits. The cold local path explicitly acquires only the existing service images before startup; failed acquisition prevents execution.

[Source reconciliation](185-SOURCE-AUDIT.md#serial-full-suite-source-and-proof-boundary) records the six changed outer overlay files, unchanged product/capture inputs, preserved original pair/global identities, discarded trace experiment and excluded failed/superseded runs. The actual current receipt is `candidate-r10-full-acceptance.json`. Final tracking-source terminal acceptance remains a separate mandatory external gate; no independent/design/risk approval or retained-preview action is inferred.
