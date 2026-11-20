---
phase: 187-scrypathops-re-skin
plan: 10
subsystem: testing
tags: [playwright, computed-style, contract-spec, partition, canonical-lane, layout-shift, fonts, ops-ui]

requires:
  - phase: 187-scrypathops-re-skin
    provides: plans 02 to 09 the fonts, palette, status vocabulary, controls, icons, retired CSS, no-alpha text, motion tokens and the P-12 motion proof
provides:
  - ops_reskin_contract.spec.ts, one describe of 30 browser tests that prove UI-SPEC P-01 to P-11, P-13 to P-16 and P-18 to P-21 from computed styles on the six screens at 390 and 1280 px in light, dark and System
  - eight rendered defects the string and ExUnit gates had passed, found by that spec or by the partition and the canonical lane, and fixed (listed under the GATE-02 checkpoint)
  - the whole ordinary e2e partition green on the final commit, locally (352 s) and in the canonical container lane (406 s), well inside the 900 s cap
  - the canonical preservation partition rehearsed once: 57 passed, 4 failed, all four classified as overlay-bound
affects: [187-11]

actuals:
  tokens: 30400
  tasks: 3
  commits: 10

plan_head_before: d519f453d4e10d5292af9580c3ff32a45ffc69e9
plan_head_after: 0504461765e89fc78be1362fcc8462515e912f38

tech-stack:
  added: []
  patterns:
    - "one in-page collector per screen (cached per theme and viewport), expected values resolved from the theme with a probe element, never a hard-coded color"
    - "a reserved-color claim is proved by classifying every element whose text, fill, border side, outline or svg fill computes to the color against a named allow-list"
    - "selection never moves layout: toggle the selected marker in the page and compare the rect"
    - "layout shift is reproduced in the canonical Linux container, not only on the host"

key-files:
  created:
    - examples/scrypath_ecommerce/e2e/ops_reskin_contract.spec.ts
  modified:
    - scrypath_ops/assets/css/app.css
    - scrypath_ops/priv/static/assets/css/app.css
    - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
    - scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex
    - scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs
    - scrypath_ops/test/scrypath_ops_web/reskin_static_contract_test.exs
    - examples/scrypath_ecommerce/e2e/ui_followup.spec.ts
    - examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts
    - .planning/reference/BRAND-ADOPTION-PLAYBOOK.md

key-decisions:
  - "A rule that is reserved for a color is proved by a computed scan of every visible element, not by a list of selectors (a selector list cannot find what nobody listed)"
  - "The Plum fill button's border is read against the page, not against its own Plum fill; a focused control is skipped; native checkboxes and radios are read from pixels because their computed border is 0"
  - "The sheet's loaded saved-search row is told apart from an inactive row by its Selected fill and its `· loaded` marker; its text stays Ink (LD-14 gives Plum or Orchid text only to the current nav item and the active palette item)"
  - "No ops page renders a focusable control inside `.ops-table-scroll`, so P-09 is proved on the real stylesheet with a planted scroller that carries the real classes; any real scroller with a control is measured the same way"
  - "The index promotion confirm is not measured in this spec: the swap fixture it needs fails after the incident seed's Meilisearch tasks, so `operator.spec.ts` (required lane, 320 px, light and dark) remains its browser check"
  - "A preservation failure that only an overlay edit can fix is recorded with evidence, not fixed (the four `loading` cases, below)"

requirements-completed: []

coverage:
  - id: D1
    description: "computed theme roles, type, status colors, Plum scope and reserved colors, row actions, links, Selection Signature, control edges and lockups match the UI-SPEC in light, dark and System at 390 and 1280 px"
    requirement: "SKIN-01, SKIN-02, SKIN-03, SKIN-04, SKIN-06, STAT-01, STAT-03, A11Y-01, A11Y-03"
    verification:
      - kind: e2e
        ref: "ops_reskin_contract.spec.ts P-01 to P-08, P-11, P-13, P-18 (16 tests): host run 30 of 30 passed on the stack built from 8cafca30 and the spec; canonical container lane attempt 3 on 05044617, 235 of 235 ordinary cases passed"
        status: pass
    human_judgment: false
  - id: D2
    description: "focus rings, scroll clearance, fonts, layout shift, flat rows and notices, overlays, scrims, CJK rows and 320 px overflow"
    requirement: "SKIN-02, SKIN-05, STAT-03, A11Y-01, A11Y-02, A11Y-03"
    verification:
      - kind: e2e
        ref: "ops_reskin_contract.spec.ts P-09, P-10, P-14, P-15, P-16, P-19, P-20, P-21 (14 tests), same runs"
        status: pass
    human_judgment: false
  - id: D3
    description: "the whole ordinary partition passes once locally and in the canonical lane on the final commit, inside the 900 s cap"
    requirement: "SKIN-08"
    verification:
      - kind: e2e
        ref: "host partition on a fresh stack: 235 passed, 0 failed, 352 s (3a0342c3); canonical `mix verify.ecommerce_e2e` ordinary partition on 05044617: 235 passed, 0 failed, 406 s"
        status: pass
    human_judgment: false
  - id: D4
    description: "canonical preservation partition on the final commit"
    requirement: "SKIN-08"
    verification:
      - kind: e2e
        ref: "ui_state_preservation and ui_content_preservation: 57 passed, 4 failed (E2, E3, E4, E6 loading), classified overlay-bound; recorded for Plan 11"
        status: fail
    human_judgment: false

duration: 5h
completed: 2026-11-19
status: complete
---

# Phase 187 Plan 10: Computed-style contract and the ordinary partition Summary

**One Playwright spec now proves the rendered re-skin from computed styles, and running it with the whole ordinary e2e partition (locally, then in the canonical Linux container) found and fixed eight rendered defects the earlier gates had passed. On the final commit the ordinary partition is green in 352 s locally and 406 s in the canonical lane; the canonical preservation partition has four failures that only an overlay-file edit could fix, recorded below for Plan 11.**

## GATE-02 stop-and-decide checkpoint

Plan 10 made rendered changes, so this is not a "no rendered change" checkpoint. The rendered fixes (all in ScrypathOps, none in the host app) are:

| Where | Change | Found by |
|---|---|---|
| Control Room intent cards | the arrow is Ink (it was Plum) and the card title is underlined at rest | P-18 |
| Search health counts | the count numbers are Ink (the Failed word and icon beside them still carry the color) | P-18 |
| Sync and index settings table | a missing live setting is no longer Failed-colored text (its words say it) | P-18 |
| Theme toggle | the selected button no longer turns bold, so selecting it does not widen it by about 1 px | P-07 |
| Command palette | the line under its input is the opaque Control Edge, not a 10 percent alpha hairline | P-08 |
| Search health facts line | a repeated time is plain text with no second copy button, and reserves the width of its longest form | phase173 specs, P-14 |
| Font fallbacks (invisible until a font swap) | the fallback faces also name Liberation Sans, Arimo, Liberation Mono and Cousine, so the size adjustment applies on Linux | P-14 in the canonical lane |

No look was reviewed by a person and none is claimed; the evidence is computed styles and counts. The retained preview (compose project `scrypath_ecommerce`, port 4002) was never addressed and stayed up and healthy. The decision the orchestrator records is not pre-written here.

## What was built

- **Task 1, `ops_reskin_contract.spec.ts` first half (tracer; `0ef9f7c3`, fixes `8cafca30`).** One `describe` with an in-page collector injected by `addInitScript`. It resolves every expected value from the theme with a probe element (scoped with `data-theme` for a specific theme), collects the facts for a screen in one `page.evaluate`, and caches them per theme and viewport for the whole file. It covers P-01 (six OS and preference combinations), P-02 (type), P-03 (status colors and 16 px icons), P-04 and P-18 (Plum scope, the reserved-color scan, hover underline), P-05 and P-06 (row actions and links), P-07 (the line, layout invariance by toggling the marker in the page, and overlays), P-08 (control edges), P-11 (one lockup, matching file, at least 136 x 28.8, `flex-shrink: 0`, at 320, 390, 768 and 1280) and P-13 (forced colors). Besides the six screens and the all-statuses fixture it opens the command palette, the mobile drawer (390 px), the Save modal and the Manage sheet with a loaded row.
- **Task 2, second half (`cdd83e64`, `7b98a17d`).** P-09 (a planted scroller with the real classes, first and last control, ring inside the scrollport, scrolled into view), P-10 (Tab traversal clear of the sticky header, 30 or more focus stops), P-14 (both fonts 200, `display.woff2` never requested, layout shift within 3 s, and with the fonts and lockups aborted at 320 px no overflow and the `Scrypath home` name), P-15 (flat Search health rows; Panel notices with a 2 px rule and no shadow), P-16 and P-21 (palette, drawer, Save modal, Manage sheet and the disconnect flash: Panel, 1 px opaque Control Edge, 4.5:1 text, a shadow; four scrims black at 0.5), P-19 (a CJK saved search created through the Save modal within 2 px of a Latin row) and P-20 (320 px overflow on the six screens, the long-name fixture and the all-statuses fixture; the confirm labels of the Save dialog, the saved-search delete and the retry-delete).
- **Task 3.** The whole ordinary partition on a fresh disposable stack with the Phase 173 standalone service published on a loopback port, fixes per failure, then the required mounted lane and the canonical `verify.ecommerce_e2e` on the final commit.

The spec has 30 tests; it takes about 70 to 100 s in a partition.

## Every run attempt and outcome

| # | Run | Result | Cause or classification |
|---|---|---|---|
| 1 | first half, 10 tests, stack `scrypath187-p10-spec` | 9 passed, 1 failed | P-04 and P-18: three product defects (groups 1 to 3 below) |
| 2 | with overlay states | `beforeAll` hung 240 s | spec error: after a save the toolbar offers no Save button (stored state), so each saved search needs a fresh page |
| 3 | same | killed at P-02 | spec error: Manage saved searches is a button, not a link |
| 4 | 16 tests | 12 passed, 4 failed | P-18 (3 defects), P-07 (theme toggle weight, plus an 80 ms transition read mid-flight: spec race), P-08 (spec readings and the palette divider), P-13 (my alpha regex read the last color component as alpha) |
| 5 | 16 tests, stack rebuilt with the CSS fixes | 16 passed (22.8 s) | |
| 6 | 31 tests | 28 passed, 3 failed (6.6 min) | spec: flash border classification, delete locator (the action's accessible name carries the saved search name), promotion fixture 500 |
| 7 | same | 29 passed, 2 failed | spec: regex `/· Delete/` and the promotion test |
| 8 | P-20 alone, twice | failed, then passed (5.4 s) | spec: `/·\s*Delete/`; promotion test dropped (see decisions) |
| 9 | whole file | 30 passed (1.2 min) | |
| 10 | host partition 1, fresh stack, `cdd83e64` | 235 tests: 213 passed, 22 failed, **353 s** | groups 6 to 8 below |
| 11 | targeted rerun, 7 specs in their real order | 67 passed, 2 failed | `ui_followup` x2 (group 7 below) |
| 12 | `ui_followup` alone | 7 passed | |
| 13 | **host partition, fresh stack, `3a0342c3`** | **235 passed, 0 failed, 352 s** | |
| 14 | canonical `verify.ecommerce_e2e` on `3a0342c3` | ordinary 232 passed, 3 failed (436 s); stopped before preservation | groups 9 and 11 below |
| 15 | canonical on `eb500f87` | ordinary 234 passed, 1 failed (419 s) | group 10 below |
| 16 | **canonical on `05044617`** | **ordinary 235 passed, 0 failed (406 s)**; preservation 57 passed, 4 failed (280 s) | group 12 below: four overlay-bound cases |

Container reproductions (not committed): the layout shift was reproduced by a scratch script inside the browser container (0.1587 on Control Room at 390 px, the lane's exact value, and 0.1481 on Search health at 1280 px against 0.1364 in the lane), the missing Arial fallback was shown by measuring text width (`Hanken Grotesk Fallback` equal to `monospace`), the stuck reduced-motion transitions were listed by a patched copy of the spec (dozens of `scrollbar-color` transitions, `pending`, never started), and each fix was shown to remove its cause in the same container.

## Failures found and what fixed them

| Group | Failure | Classification | Fix |
|---|---|---|---|
| 1 | Plum arrow on the Control Room intent cards (P-18) | product defect | `8cafca30`: arrow Ink, title underlined |
| 2 | Failed-colored count numbers on Search health (P-18) | product defect | `8cafca30` |
| 3 | Failed-colored missing live setting on Sync and index (P-18) | product defect | `8cafca30` |
| 4 | selected theme toggle button 0.88 px wider (P-07) | product defect | `8cafca30`: no weight change on selection |
| 5 | palette input line a 10 percent alpha hairline (P-08) | product defect | `8cafca30`: Control Edge |
| 6 | 17 cases (`phase173_copy` x8, `phase173_time` x6, `ui_baseline` shared time preference, `ui_followup` x2): the timestamp locator resolved to two copy buttons | product defect (Plan 04's facts line printed each time through the copyable component, so one exact value had two copy controls with the same name) | `eb474337`: `ops_time` takes `copyable` (default true); the facts line passes false; an ExUnit case pins one copy control per exact value |
| 7 | `ui_followup` copy-feedback case, mounted and standalone: both boxes moved by 312 px | stale spec pin (at 390 px the denser facts line puts the first copy control below the fold, so the click scrolled) | `3a0342c3`: the case scrolls the stamp into view before measuring; no case renamed |
| 8 | `storefront` x5: `invalid_search_filter`, `tenant_id` not filterable | caused by the new spec (it sorts between `operator` and `storefront`, and its incident seed drifts the live index on purpose; `e2e_search_catalog` does not restore it) | `7b98a17d`: `afterAll` reseeds `all_green`, which restores the declared settings |
| 9 | P-14, canonical lane: layout shift 0.1587 (Control Room, 390) and 0.1364 (Search health, 1280) | product defect: `local("Arial")` and `local("Courier New")` match font names, not fontconfig aliases, so on Linux the metric-adjusted fallback was never used and the swap re-wrapped text | `bf86c0ee`: the fallback faces also list Liberation Sans, Arimo, Liberation Mono and Cousine (0.0000 and 0.0002 in the container); the exact-source ExUnit case follows |
| 10 | P-14, canonical lane: Search health 1280, 0.1369 | product defect: the browser rewrites a facts-line time from the server's 24-hour text to 12-hour text one character longer, which flipped where the line wraps (25 px down for everything below) | `05044617`: facts-line times are inline blocks at least 30ch wide |
| 11 | `admin_path_motion` P-12 reduced motion, canonical lane (7 of 24 repetitions in the container, 0 of 38 after the fix) | spec robustness (Plan 09's file): a transition that starts on an idle page stays `pending` until the compositor makes a frame, and the headless container makes none by itself | `eb500f87`: two frames are requested before each reduced-motion sample; what is asserted afterwards is unchanged |
| 12 | `ui_state_preservation` E2, E3, E4, E6 `loading` (canonical preservation) | overlay-bound, not fixed (below) | none |

## Overlay-bound preservation failures (for Plan 11)

`helpers/ui-preservation-states.ts` `assertPendingState` (an overlay file; not edited) requires the page text to be identical while a refresh is in flight. The re-skin intentionally shows `Refreshing…` there (UI-SPEC Motion and Copy, on the copy-diff allowlist; Plan 06 decision; E-11 and E-16 assert it). For each of the four cases (E2 Control Room, E3 Search health fixture, E4 Failed sync work, E6 Sync and index) the route is unchanged, the button carries `phx-click-loading`, and the only text difference is line 21 `Refresh` versus `Refreshing…`. This is not a geometry-class rejection and no baseline was touched. The three expected geometry classes (font swap, the 136 px lockup, hairline rows) did not fail in this partition. The decision is Plan 11's: accept these four as reviewed expectations, or amend the guard in a controlled overlay change. Product behavior stays as the UI-SPEC specifies.

## Duration against the cap

- Host partition (235 tests, one serial invocation, fresh stack): 352 s on the final run (353 s on the first). Per spec the largest are `ops_reskin_contract` 79 s, `admin_shell_chrome` 65 s, `admin_surface_depth` 46 s, `admin_contrast_matrix` 43 s, `admin_path_motion` 26 s and `admin_screenshot_matrix` 26 s. No trimming was needed (the 750 s trigger was never close).
- Canonical lane on `05044617`: ordinary 406 s, preservation 280 s, both inside the 900 s per-partition cap. `ops_host_contract.spec.ts` (Plan 11) is not part of these numbers.

## Gate results (GATE_SHA `0504461765e89fc78be1362fcc8462515e912f38`, the last commit touching non-`.planning` files)

The ten commits are `8cafca30`, `0ef9f7c3`, `cdd83e64`, `7b98a17d`, `eb474337`, `6ef0f3d0` (docs, `.planning/` only), `3a0342c3`, `bf86c0ee`, `eb500f87` and `05044617`. The only commit after `05044617` is the one that adds this SUMMARY, which touches only `.planning/`. All four long gates ran on `05044617`.

| Check | Result |
|---|---|
| `node examples/scrypath_ecommerce/contrast-checker.mjs` | `Contrast check: PASS`, AA failures 0 |
| `node --test --test-reporter=tap examples/scrypath_ecommerce/ui-tokens.test.mjs` | 55 pass, 0 fail (no ceiling moved) |
| root `mix test` on the four `ui_*` contract tests, `--exclude contrast_child` | 29 tests, 0 failures |
| `mix verify.ops_ui` (task-scoped database `scrypath_ops_test_187_10`) | boundary 2 tests; 2 doctests, 508 tests, 0 failures, 204 s (507 before, plus the one-copy-control case) |
| `mix verify.core --exclude integration --exclude docs_contract` | format, clean workspace, warnings-as-errors compile, credo, 5 properties and 1158 tests with 0 failures (103 excluded), Standard Maturity Gate PASSED, 257 s |
| `mix verify.repository_contracts` (escalated route) | 157 tests, 0 failures, 205 s |
| `mix verify.ecommerce_mounted` (`E2E_PROJECT_NAME=p187_plan10_mounted2`, `E2E_DOCKER_TIMEOUT_SECONDS=2700`) | `Docker verifier passed (scope=focused)`; `containers=0 networks=0 volumes=0 cleanup=clean`; 300 s |
| canonical `mix verify.ecommerce_e2e` (`E2E_PROJECT_NAME=p187_plan10_e2e3`) | ordinary partition 235 of 235 passed; preservation 57 passed, 4 failed (overlay-bound); the verifier exits 1 for that reason |

## Deviations from Plan

1. **[Calibration] `E2E_DOCKER_TIMEOUT_SECONDS=2700` cannot be used for the full lane.** `verify-e2e.sh` rejects a value above 900 for `full` scope. The focused mounted lane used 2700; the canonical run used the default 900 per operation and `E2E_DEADLINE_EPOCH` set to start plus 1800 s, which is exactly what `ci.yml` does for the hosted job. Without that variable the local deadline (start plus 900 s, minus a 300 s reserve) leaves 600 s for builds and both partitions.
2. **[Rule 3] The partition runs on the plain stack plus a scratch overlay.** The Phase 173 standalone cases need `standalone_ops`; `compose.phase173.yaml` adds it but extends a `browser` service only `compose.e2e.yaml` defines. A scratch compose file (outside the repository) publishes it on loopback port 4112 and stubs `browser` behind a profile that is never enabled. The canonical lane covers the same cases on the compose network.
3. **[Rule 1] Eight rendered defects were fixed in product files** (the GATE-02 table). Files outside the plan's `files_modified` were also edited, each with its commit: `posture_live.ex` and `posture_live_test.exs` (`eb474337`), `reskin_static_contract_test.exs` (`bf86c0ee`), `ui_followup.spec.ts` (`3a0342c3`), `admin_path_motion.spec.ts` (`eb500f87`) and the brand playbook (`6ef0f3d0`). `layouts.ex` and the five specs the plan lists besides the new one needed no change.
4. **[Judgement] The intent card title is underlined at rest.** P-18 only required the arrow to stop being Plum. The UI-SPEC's per-screen contract for the two intent cards says "underlined title", and it is what keeps the whole-card link visible once the arrow is Ink, so I did it in the same fix. The card's resting Control Edge border and lack of shadow, also in that contract, are not covered by any P-assertion and were left (Plan 08 Deviation 8 recorded them).
5. **[Judgement] Three readings of P-07 and P-08 that a reviewer should see.** The Plum fill button's border is measured against the page (its own fill is the same hue by design); a focused control is skipped (a focus state is not a resting border); the loaded sheet row differs by fill and its `· loaded` marker with Ink text. Each is a comment in the spec.
6. **[Judgement] P-09 uses a planted scroller.** No ops page puts a focusable control inside `.ops-table-scroll` today (the Sync and index settings table holds plain cells), so a literal "first and last control of each scroller" would pass vacuously. The spec plants a scroller with the real classes, measures both ends and the scroll, and also measures any real scroller that gains a control.
7. **[Judgement] The promotion confirm label is not in this spec.** The swap fixture it needs returned HTTP 500 after the incident seed (a Meilisearch task failed on the used stack), twice. `operator.spec.ts` opens that dialog at 320 px in light and dark in the required lane. P-20 here measures three of the four confirm labels.
8. **[Judgement] The P-12 flake was reproduced before the spec was changed.** Attempt 14's reduced-motion failure failed 7 of 24 repetitions in the container, and the fix passed 38 of 38 there (two repetitions of all 19 cases). A single lane failure alone would not have justified a change.
9. **[Process] The swap fixture and the `e2e_search_catalog` seed returned HTTP 500 on a stack that had run the incident seed.** It is a property of the stack history (the incident seed's failed Meilisearch tasks), not of the contract spec, and is why the spec's `afterAll` reseeds `all_green` rather than leaving the incident state for `storefront.spec.ts`.

No overlay file was edited: `git diff 3a21916f..HEAD` over `helpers/`, `package.json`, both preservation specs, `ui-review.mjs`, `ui_state_pairs.cjs` and both `phase173_fixture_source.ex` copies prints nothing.

## Blocked gates

None blocked. One gate is not green and is not fixable here: the canonical preservation partition (four overlay-bound cases, above). `verify.ecommerce_e2e` therefore exits 1 on the final commit even though its ordinary partition passes. Plan 11 decides.

## Docker and database cleanup

Every resource used a task-scoped name: compose projects `scrypath187-p10-spec`, `scrypath187-p10-partition` (twice), `scrypath187-p10-diag`, the verifier projects `p187_plan10_mounted`, `p187_plan10_mounted2`, `p187_plan10_e2e`, `p187_plan10_e2e2` and `p187_plan10_e2e3`. The retained preview (`scrypath_ecommerce`, 4002) was never addressed and ended `Up 10 hours (healthy)`. After the work no container, network or volume with any of those names remains, the seven verifier images and three untagged images (each proven mine by its compose project label) were removed by exact name, and `scrypath_ops_test_187_10` is dropped (verified absent). No dangling volume was created in the work window; I used no `make verify-*` target.

`docker system df` before and after:

| | Before | After |
|---|---|---|
| Images | 316 / 122.8GB | 317 / 123.1GB (one image not attributable to this task: the canonical lane pulled `postgres:16-alpine`) |
| Containers | 109 / 7.892GB | 109 / 7.892GB |
| Local volumes | 384 / 40.11GB | 384 / 40.11GB |
| Build cache | 356 entries / 21.64GB | 469 entries / 26.84GB (shared across projects, not attributable, not pruned) |

## Notes for later plans

- Plan 11: the ordinary partition (235 cases here) is green; add `ops_host_contract.spec.ts` to it and expect one short spec of extra time. The four `loading` preservation cases above need the decision rule. The product tree digest moves again (CSS, `ops_ui.ex`, `posture_live.ex` and the stylesheet changed); no overlay digest file changed.
- `ops_reskin_contract.spec.ts` seeds `incident` in `beforeAll` and `all_green` in `afterAll`, and creates two saved searches (`Reskin latin 187` and a CJK name) through the Save modal. Specs that sort after it and seed `e2e_search_catalog` rely on that cleanup.
- The canonical lane needs `E2E_DEADLINE_EPOCH` set to start plus 1800 when run locally.
- A font fallback change must keep the exact override numbers; `reskin_static_contract_test.exs` pins the `src` list as well.
- Search health facts-line times are `time.ops-time__value` inline blocks at least 30ch wide; a longer time format needs a larger `min-width`.
- The scratch diagnostics (container layout-shift probe, running-animation lister, compose overlay) are in the session scratchpad and not committed.

## Known Stubs

None.

## Threat Flags

None new. T-187-23 (browser claims without a reproducible run): every P-assertion lives in the committed spec, each attempt and its outcome is listed above, and the canonical lane re-ran it on the exact final SHA. T-187-24 (the new spec pushing the partition past its cap): measured at 352 s locally and 406 s in the lane against 900. T-187-SC: no package was added; `npm ci` from the lockfile only.

## Self-Check

PASSED

- Files exist: this SUMMARY, `ops_reskin_contract.spec.ts` (2143 lines, 30 tests) and the files listed under `key-files` (checked with `[ -f ]`).
- Commits are ancestors of HEAD: `8cafca30`, `0ef9f7c3`, `cdd83e64`, `7b98a17d`, `eb474337`, `6ef0f3d0`, `3a0342c3`, `bf86c0ee`, `eb500f87`, `05044617`; `git rev-list --count d519f453d4e10d5292af9580c3ff32a45ffc69e9..HEAD` measured 10 before this SUMMARY.
- Acceptance checks: P-id lines for the first half 31 (at least 11), `forcedColors` 3, P-id lines for the second half 23 (at least 8), `layout-shift` 4, `ops-header` only in the P-10 header measurement, the overlay diff since `3a21916f` empty, `docker ps -a --filter name=scrypath187-p10` 0.
- `git diff --name-only d519f453..HEAD` touches no `STATE.md`, `ROADMAP.md`, `.planning/config.json` or `.planning/state.json`; every file was staged by path.
