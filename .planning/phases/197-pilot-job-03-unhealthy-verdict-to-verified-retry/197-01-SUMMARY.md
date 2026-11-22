---
phase: 197-pilot-job-03-unhealthy-verdict-to-verified-retry
plan: 01
subsystem: testing
tags: [liveview-test, journey, sudo, return-to, storybook, catalog-server, font, fidelity-probe, dependency-boundary, ops-ui]
status: complete

requires:
  - phase: 195-mount-and-prove
    provides: "phoenix_storybook mounted in dev and test only, the iframe route, the storybook.js hook bundle and the dependency-boundary tests this plan extends"
  - phase: 196-fixtures-and-three-adopters
    provides: "fixtures/scrypath_fixtures, the Shopadelic failed_journey scenario, FixtureEnv and the fake client and inspector"
provides:
  - "JOB-03 mounted journey on Shopadelic failed_journey: Search health to Failed sync to Retry queued to Sync and index and back, green on unmodified LiveView code (baseline for Plans 02 to 05)"
  - "Allowlist denial and stale-sudo denial, each with a positive control and an absence check"
  - "Recovery verified in the same journey file (kept, not cut), with test-local queue, repo, Meilisearch client and worker-telemetry seams"
  - "Defect D1 fixed: OnMount assigns return_to from the parsed request path and query, so a stale-sudo operator comes back to the page they left"
  - "mix scrypath_ops.catalog.serve: dedicated catalog endpoint on 127.0.0.1 (CATALOG_PORT, default 4003), no Repo, no reloader, no watchers, port-holder check with public port_verdict/2"
  - "Storybook iframe body in the product sans font (storybook.js), product stylesheet untouched"
  - "Local, non-gating computed-style probe (font mode and real-page compare mode)"
  - "Boundary rows: every catalog/lib module in both probe lists with a gap check, endpoint loopback-bind pin, runtime-probe forbids the endpoint"
affects: [197-02, 197-03, 197-04, 197-05]

actuals:
  tokens: 15600
  tasks: 3
  commits: 4
commits: 4
plan_head_before: a8125e8560d7c4f9a4cdd67acab74b001466b4c3
plan_head_after: 4d048cd20e7d4333e5b9bab55ade2f6a987c80ea

tech-stack:
  added: []
  patterns:
    - "Journey seams live in the journey file (Queue, JobRepo, Client modules at its bottom); copy_stubs/failed_sync.ex is untouched"
    - "Global observation state (RecoveryObservation) is reset in setup and on_exit because every journey test queues job 991"
    - "A catalog server that owns its own endpoint so the review surface never depends on Postgres or the code reloader"
    - "One pure function decides the port verdict, so the serve task's refusal is testable without a socket"

key-files:
  created:
    - scrypath_ops/test/scrypath_ops_web/live/catalog_journey_test.exs
    - scrypath_ops/catalog/lib/scrypath_ops/catalog/endpoint.ex
    - scrypath_ops/catalog/lib/scrypath_ops/catalog/router.ex
    - scrypath_ops/catalog/lib/mix/tasks/scrypath_ops.catalog.serve.ex
    - examples/scrypath_ecommerce/e2e/catalog-fidelity-probe.mjs
  modified:
    - scrypath_ops/lib/scrypath_ops_web/live/on_mount.ex
    - scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/shopadelic/product.ex
    - scrypath_ops/assets/js/storybook.js
    - scrypath_ops/priv/static/assets/js/storybook.js
    - scrypath_ops/config/dev.exs
    - test/release/ops_dependency_boundary_test.exs
    - test/mix/tasks/dependency_boundary_contract_test.exs
    - examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh

key-decisions:
  - "The journey's queue and repo seams live in the journey file, not in copy_stubs/failed_sync.ex, so the copy-rules and a11y tests keep their stub"
  - "Recovery verified is kept: it cost well under a quarter of the plan, so the cut rule did not fire"
  - "return_to_path/1 also refuses backslash and control-character paths, beyond the plan's list, because browsers treat /\\host as //host"
  - "The serve task resolves and validates CATALOG_PORT itself and writes it into the endpoint config at run time, so the printed URL and the bound port cannot disagree; dev.exs falls back to 4003 on a bad value instead of failing every dev mix command"
  - "A catalog 4003 holder is never probed by this plan's local proof; a spare port (4013) was used and port 4003 (another project's server) was left alone"

patterns-established:
  - "Plant one cause, assert that cause: every new check here was proven against a planted failure that reports its own message"
  - "Local proofs that are not gates are recorded with their exact outputs in the SUMMARY, not turned into CI"

requirements-completed: [PILOT-01, PILOT-02, PILOT-06, FLOW-03]

coverage:
  - id: C1
    description: "Search health shows the degraded verdict and a link to failed sync for the schema; the link opens Failed sync scoped to that schema; retrying job 101 gives the receipt, one insert and the info flash; the receipt hands off to Sync and index with status Retry queued and the evidence line; the return links carry the schema"
    requirement: "PILOT-01"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/catalog_journey_test.exs#JOB-03: the on-call engineer goes from an unhealthy Search health row to a queued retry and back"
        status: pass
    human_judgment: false
  - id: C2
    description: "Allowlist denial shows 'That schema is unavailable.' with zero inserts and no SPD-2041 or SPD-2042; stale sudo redirects to the confirm page with zero inserts and the row still retryable; each has a positive control"
    requirement: "PILOT-01"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/catalog_journey_test.exs#allowlist denial shows no protected values and inserts nothing"
        status: pass
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/catalog_journey_test.exs#stale sudo redirects without inserting and keeps the row"
        status: pass
    human_judgment: false
  - id: C3
    description: "The stale-sudo test that used to hand-build a socket now drives a mounted view and clicks the rendered retry button of a row that exists"
    requirement: "PILOT-01"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs#stale sudo sends a click on a rendered retry button to the confirm page and keeps the row"
        status: pass
    human_judgment: false
  - id: C4
    description: "A stale-sudo operator returns to the exact path and query they left; the host and protocol-relative, backslash and control-character paths are never a return target"
    requirement: "PILOT-02"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs#stale sudo returns the operator to the filtered page they left"
        status: pass
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs#OnMount.return_to_path/1 (3 tests)"
        status: pass
    human_judgment: false
  - id: C5
    description: "The retry reaches Recovery verified with the evidence line when the simulated worker, the Meilisearch task and the document check agree"
    requirement: "PILOT-01"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/catalog_journey_test.exs#JOB-03: the retry reaches Recovery verified once the worker, the task and the documents agree"
        status: pass
    human_judgment: false
  - id: C6
    description: "The catalog serves on 127.0.0.1 without a database, refuses a held port naming the holder, and gives identical canonical iframe documents across a stop and start"
    requirement: "PILOT-06"
    verification:
      - kind: command
        ref: "local proof recorded in this SUMMARY (CATALOG_PORT=4013 mix scrypath_ops.catalog.serve with PGPORT=1, curl, normalized document comparison, second start exit 1); the standing check (port_verdict test, landing page marker) lands in Plan 05"
        status: pass
    human_judgment: false
  - id: C7
    description: "Every story renders in the product sans font: the iframe body family equals the html family, light and dark, and the probe reports serif when the fix is reverted"
    requirement: "PILOT-06"
    verification:
      - kind: command
        ref: "node e2e/catalog-fidelity-probe.mjs --font primitives/ops_button:default (exit 0 with the fix, exit 1 naming serif without it); the standing CI bundle check with a plant lands in Plan 05's catalog contract test"
        status: pass
    human_judgment: false
  - id: C8
    description: "Every catalog/lib module is in the direct and mounted probe lists; the dev endpoint binds loopback; the Docker runtime probe forbids the endpoint"
    requirement: "PILOT-06"
    verification:
      - kind: integration
        ref: "test/release/ops_dependency_boundary_test.exs#every catalog/lib module is in the direct probe list and the mounted probe list"
        status: pass
      - kind: unit
        ref: "test/mix/tasks/dependency_boundary_contract_test.exs#the catalog server endpoint binds loopback in dev and is never started by the test config"
        status: pass
      - kind: unit
        ref: "test/mix/tasks/dependency_boundary_contract_test.exs#the Docker boundary script forbids the catalog in prod and host graphs and requires a 404"
        status: pass
    human_judgment: false
---

# Phase 197 Plan 01: Journey, D1 fix, catalog server and font fix Summary

**The JOB-03 journey is green on the unmodified LiveView code, the stale-sudo return defect (D1) is fixed with a test that fails without the fix, and the storybook now serves from a database-free loopback server in the product font.**

## Performance

- **Duration:** about 31 minutes (2026-11-22T13:38Z to 14:09Z), most of it waiting on the two long local lanes
- **Tasks:** 3 of 3 (Task 1 was the tracer)
- **Files:** 14 (5 created, 9 modified); realized diff about 15.6k tokens by chars/4 against the 80k estimate
- **Commits:** 4 task commits (measured from the plan ledger: `a8125e85..4d048cd2`)

## Commits and the journey baseline

| Commit | Subject |
|--------|---------|
| `0dceb523` | test(ops-ui): add the JOB-03 mounted journey on current code (Task 1; touches only the journey file) |
| `364a22eb` | test(ops-ui): return stale-sudo operators to the page they left (fixes defect D1) |
| `d913b8b6` | test(ops-ui): reach Recovery verified in the JOB-03 journey |
| `4d048cd2` | chore(ops-ui): serve the storybook on loopback without a database and fix its sandbox font |

**Journey baseline sha for Plans 02 to 05: `d913b8b6`** (the last commit that touches `catalog_journey_test.exs`). The pure "queued" journey was first committed green at `0dceb523`, and that commit changes no file under `scrypath_ops/lib` or root `lib/`. No root `lib/` file changed in this plan.

## Accomplishments

- **Journey on current code (PILOT-01).** One mounted test walks Search health (degraded verdict, `Failed`, headline about failed sync jobs and Meilisearch tasks, 3 jobs and 1 task failed, the Failed sync link read from the page) to Failed sync for the same schema (five rows 102, 43, 103, 101, 104; Retry on 102, 103, 101, 104 and none on the Meilisearch task 43; summary "4 failed, 1 retrying"), retries job 101 (receipt "Oban job #991", "Original job #101 is retained", one insert, the info flash), follows "Check sync status" to Sync and index (status Retry queued, evidence "Queue job 991 · attempt 1 · Active index shopadelic_product"), and follows the return links (both carry the schema). It runs in basic mode, as research Pitfall 4 requires. What row 101 shows after the return trip is deliberately not asserted (finding D2).
- **Denials with controls.** Allowlist denial shows "That schema is unavailable.", zero inserts, no `SPD-2041` or `SPD-2042` anywhere in the rendered text, and the unknown-schema URL does not echo the requested name. Stale sudo redirects to `/sudo/confirm` with a query holding only `return_to` and no record id, zero inserts, and a fresh mount still offers the retry. Each has a positive control (counter 1).
- **`failed_sync_live_test.exs:540` repaired.** The hand-built socket (no loaded rows, a `host_uri` path real LiveView never provides) is replaced by a mounted view that clicks the rendered retry button, with a positive control.
- **D1 fixed.** `OnMount` assigns `:return_to` from the parsed request path and query in its existing `handle_params` hook. `return_to_path/1` keeps path and query, never the host, and returns nil for a `//` path, a backslash, a control character, a missing path or a relative string. `SearchLive` still wins because its own assign runs after the hook (its existing test stayed green).
- **Recovery verified kept.** About 90 lines of test-local seams plus `Product.search_records/2` in the fixtures project reach "Recovery verified" with evidence "Queue job 991 · attempt 1 · Meilisearch task 44 · Active index shopadelic_product" and "Expected documents observed".
- **Catalog server (PILOT-06 serving part).** `mix scrypath_ops.catalog.serve` starts `ScrypathOps.Catalog.Endpoint` with no Repo, no code reloader and no watchers.
- **Font.** The sandbox class set `font-family: serif` on `<body>` and beat the product stylesheet. `storybook.js` now sets the body family to `var(--font-sans)`; `app.css` is untouched.
- **Probe.** `catalog-fidelity-probe.mjs` (font mode and compare mode), a `.mjs` script that Playwright does not list as a spec (`playwright test --list`: 300 tests in 25 files, 0 mention it).
- **Boundary rows.** Every `defmodule` under `scrypath_ops/catalog/lib` (Storybook, Endpoint, Router, the Mix task) is in both probe lists, with a source-scan gap check; the dev endpoint's loopback bind is pinned; the Docker runtime probe forbids the endpoint.

## D1 evidence

| Run | Result |
|-----|--------|
| New test on current code, before the fix | red: `left: %{"return_to" => ^left}`, `right: %{"return_to" => "/"}` (the redirect was `/sudo/confirm?return_to=%2F`) |
| Planted: the `assign(:return_to, ...)` line removed from `on_mount.ex` | red with the same `right: %{"return_to" => "/"}`; 1 failure of 34 |
| Fix restored | green: 34 tests, 0 failures; the whole `test/scrypath_ops_web/live/` directory 222 then 223 tests, 0 failures |

The red test was committed together with the fix (the branch never carries a red commit).

## Recovery verified outcome

Kept, not cut. Three-plus green runs of the whole journey file in different seeds (`636694`, `525376`, `390179`, `681299`) and `--seed 0`, 4 tests each, 0 failures. Plant: removing the simulated worker makes it fail on its cause ("Queue job completed; backend evidence pending", not "Recovery verified"). `operator.spec.ts` stays the real-browser proof of the same chain; this test does not replace it.

## Server proof (local, recorded, not a gate)

Run with `PGPORT=1` (nothing listening), `CATALOG_PORT=4013`, warm `_build/dev`:

| Check | Result |
|-------|--------|
| `/storybook` | 302 in 0.0008 s; first 302 within 0 to 3 s of start |
| `/storybook/primitives/ops_button` | 200 in 0.09 s |
| `/storybook/iframe/primitives/ops_button?variation_id=default&theme=light` | 200 in 0.015 s |
| `/assets/css/app.css`, `/assets/js/storybook.js` | 200 in under 1 ms |
| Bound address (`lsof`) | `127.0.0.1:4013` only |
| Restart stability | three canonical iframe documents (`ops_button` default light and dark, `ops_sync_status` failed dark) byte-identical after normalizing `phx-` ids, `data-phx-session`, `data-phx-static`, csrf and `ops-time-<n>`, across two stop-and-start cycles (the first cycle's `ops_button` pair also identical) |
| Database errors in the three server logs | 0 matches for `DBConnection`, `econnrefused`, `Postgrex` |
| Second start on the same port | exit 1: `Port 4013 on 127.0.0.1 is already in use by beam.smp (pid 83942). Nothing was stopped.`; the first instance kept answering 302 |
| `CATALOG_PORT=abc` | `Mix` error naming the bad value; nothing started |
| Cleanup | server stopped by pid, `lsof` shows no listener on 4013, no `catalog.serve` process left; port 4003 (another project's `beam.smp`) was never contacted or touched |

A first comparison used `variation_id=default` for `ops_sync_status`, which has no such variation, so it compared a debug error page; the valid id is `failed`. Only the valid captures are counted above.

## Probe outputs

`node e2e/catalog-fidelity-probe.mjs --font primitives/ops_button:default --base http://127.0.0.1:4013`

- **With the fix:** exit 0.
  `same light html: "Hanken Grotesk", "Hanken Grotesk Fallback", system-ui, sans-serif | body: <same>` and the same line for dark; `RESULT: no differences (550 ms)`.
- **Without the fix** (bundle rebuilt from the committed source, then restored byte-identical): exit 1.
  `DIFFERENT light html: "Hanken Grotesk", ... | body: serif, system-ui, sans-serif`, the same for dark; `RESULT: differences found`.

Compare mode was smoke-run on a synthetic page to prove the code path (light identical; the dark difference came from the synthetic dump carrying the light wrapper); its first real run against a mounted-page dump is Plan 05's.

## Planted results

- **Catalog-module gap check** (`catalog_module_gaps/3`, source scan of `catalog/lib`): real lists give `[]`; endpoint removed from the direct list gives exactly `[{:missing_direct, ScrypathOps.Catalog.Endpoint}]`; removed from the mounted list gives exactly `[{:missing_mounted, ScrypathOps.Catalog.Endpoint}]`; an unknown module is reported against both.
- **Endpoint bind check:** dev reads `{127, 0, 0, 1}`; planted `{0, 0, 0, 0}`, `{10, 0, 0, 5}`, `{0, 0, 0, 0, 0, 0, 0, 0}` and `nil` each report a message naming `ScrypathOps.Catalog.Endpoint` and "loopback"; the test config sets no `server: true` for it. Real-file plant: `dev.exs` edited to bind `{0, 0, 0, 0}` made the test fail (`left: {0, 0, 0, 0}`), then restored.
- **Script mutant:** removing `ScrypathOps.Catalog.Endpoint` from `forbidden_modules` is well-formed shell and is reported as exactly `["the runtime probe must forbid ScrypathOps.Catalog.Endpoint"]`; the existing storybook and fixtures mutants still match their text. Real-file plant on the script: contract test failed, then restored.

## Verification

- `mix verify.ops_ui` (phase gate, run here on the committed head, `HEX_HTTP_TIMEOUT=120`): exit 0 in 6 min 7 s. The boundary integration test ran 3 tests, 0 failures (the new module lists exercised against real dev, test, prod and mounted builds), then the ops suite 2 doctests and 735 tests, 0 failures.
- Root `mix test test/mix/tasks/dependency_boundary_contract_test.exs`: 35 tests, 0 failures. `mix format --check-formatted` clean in root, `scrypath_ops` and the fixtures project. `bash -n` on the boundary script and `node --check` on the probe pass. `MIX_ENV=dev mix compile --warnings-as-errors` clean. `PGPORT=1 mix scrypath_fixtures.check_fixtures`: "Fixtures OK: 11 scenario(s)".
- `node --test scripts/ci/ecommerce_lifecycle.test.cjs` (the Node step file that copies the boundary script): 35 tests, 0 failures, 587 s.
- **Not run here, a known risk:** the rest of the repository-contracts lane (`mix verify.repository_contracts` and the other four Node test files) and the Docker lane `ecommerce-mounted`. Plan 05 runs the full pre-push mirror before the push. The new boundary probe entries were exercised by the integration test above, but the Docker runtime probe line that forbids the endpoint is covered statically (`bash -n` plus the root contract test) until `ecommerce-mounted` runs it.

## Deviations from Plan

### Auto-fixed issues

**1. [Rule 1 - Bug] Journey tests polluted each other through the global observation server**
- **Found during:** Task 2, when the verified test and the linear journey ran in the same module
- **Issue:** `ScrypathOps.RecoveryObservation` is one global process keyed by queue job identity, and every journey test queues job 991. Telemetry evidence from the verified test (task 44) survived into the linear test, which then showed `:task_unavailable`.
- **Fix:** `reset_observations/0` clears `recent` and `observations` through `:sys.replace_state/2` in setup and in `on_exit`.
- **Files modified:** `scrypath_ops/test/scrypath_ops_web/live/catalog_journey_test.exs`
- **Commit:** `d913b8b6`

**2. [Rule 2 - Missing critical functionality] Wider open-redirect refusal in `return_to_path/1`**
- **Found during:** Task 2 (threat T-197-01)
- **Issue:** the plan listed `//` and non-`/` paths. Browsers also treat `/\host` as `//host`, and a control character can split a header.
- **Fix:** the function also returns nil for a backslash or a control character in the path, with a unit case for each.
- **Files modified:** `scrypath_ops/lib/scrypath_ops_web/live/on_mount.ex`, `failed_sync_live_test.exs`
- **Commit:** `364a22eb`

**3. [Rule 3 - Blocking] Catalog endpoint needed more dev config than the plan listed**
- **Found during:** Task 3
- **Issue:** the plan named `ip`, `port`, `server`, `adapter`, `pubsub_server`, `check_origin`, `code_reloader`, a secret. A working endpoint also needs `live_view: [signing_salt: ...]`, and `render_errors` so a failing story shows its own error.
- **Fix:** added `live_view`, `render_errors` and `debug_errors` under the same `ScrypathOps.Catalog.Endpoint` key in `dev.exs` only. The bind stays `{127, 0, 0, 1}`.
- **Commit:** `4d048cd2`

**4. [Design] The serve task writes the validated port into the endpoint config at run time**
- The plan had the port only in `dev.exs`. A bad `CATALOG_PORT` there would break every dev mix command, so `dev.exs` falls back to 4003 on a bad value and the task validates and raises on its own, then overrides the config so the printed URL and the bound port always agree.

Total deviations: 4 (1 bug, 1 missing critical, 1 blocking, 1 design). Impact: none on scope; no root `lib/` file, no dependency and no `mix.lock` changed.

## Authentication gates

None.

## Known Stubs

None. `Queue`, `JobRepo` and `Client` in the journey file are test doubles, not shipped stubs. The holder check in the serve task only sees listeners reachable on 127.0.0.1; it names the holder through `lsof` when `lsof` exists and otherwise says only that the port is taken.

## Threat Flags

None beyond the plan's register: T-197-01 (open redirect, mitigated and tested), T-197-02 (catalog endpoint loopback bind and absence outside dev and test, mitigated and tested), T-197-03 (held port refusal, mitigated and proven), T-197-04 (denial echoes, mitigated and tested), T-197-05 (probe loopback-only, mitigated).

## Issues Encountered

- This machine's shared Postgres prints `too_many_connections` noise during `mix test`; tests passed and no task-scoped Postgres was needed.
- Port 4003 is held by another project's server, so every local catalog proof used 4013.
- The `ecommerce_lifecycle` Node file takes about 10 minutes locally on its own; run it only when the boundary script or another copied file changes.

## Next Phase Readiness

Plan 02 starts from the journey baseline `d913b8b6`: extract `Posture` into `scan/2` and `build/3`, build Search health components and stories, and keep the journey unmodified. Plan 05 owns the landing page with `main@sha`, the `UI-PREVIEW.json` storybook block, the standing bundle-font check with its plant in `catalog_contract_test.exs`, the first compare-mode run against a real page dump, and the push.

## Self-Check: PASSED

All 14 plan files exist on disk, the four task commits are ancestors of HEAD, `catalog-fidelity-probe.mjs` is tracked exactly once, and the task acceptance greps pass (`font-sans` in source and bundle, product stylesheet untouched against `origin/main`, `"Catalog", "Endpoint"` twice in the release test, the endpoint named once in the boundary script and eight times in the contract test, no root `lib/` change, `loads: nil` gone from the repaired test).
