---
phase: 187-scrypathops-re-skin
plan: 09
subsystem: ui
tags: [motion-tokens, duration-tokens, daisyui-overrides, topbar, grep-gates, spacing-grid, p-12, advisory-specs, ops-ui]

requires:
  - phase: 187-scrypathops-re-skin
    provides: plan 06 no looping animation in ops source; plan 07 the retired CSS and the deleted surface-2 role; plan 08 no tints, no alpha text and the retired muted manifest
provides:
  - the four brand durations (80, 160, 240, 600 ms) and six brand easings are the source tokens; the old names are `var()` aliases for one milestone; no rule consumes `advance` and no 1650 ms value exists
  - Tailwind's default transition duration and every daisyUI component duration ops renders (`.btn`, `.checkbox`, `.radio`, `.card`, `.modal`, `.modal-box`) compute to a brand token
  - `JS.transition` timings use `duration-(--duration-ops-quick|base)` with `time: 160` or `240`; the nav drawer's close delay matches the 240 ms base token
  - the navigation progress bar takes the computed `--color-primary` each time it shows; no color literal remains in ops JavaScript
  - `motion_contract_test.exs` asserts every transition and animation duration is a token or zero (E-18 scans `lib/` for retired duration literals); `reskin_static_contract_test.exs` gains the E-12 grep gate with planted failures
  - N-13: spacing custom properties stay on the 4 px grid and the 37 off-grid padding, margin and gap literals can only fall
  - `admin_path_motion.spec.ts` is the P-12 computed motion proof (19 tests, all green in a browser); `admin_surface_depth`, `phase173_shell` and `admin_shell_wash` read the page floor and surface roles from the theme; no `p187` allowlist entry remains
affects: [187-10, 187-11]

actuals:
  tokens: 36654
  tasks: 3
  commits: 3

plan_head_before: 7763165272d5298f93a3d33361e81043a3f28ab8
plan_head_after: b444283019bf8e55e3c28cd0669723770ef4fd77

tech-stack:
  added: []
  patterns:
    - "a Tailwind duration utility in a template is the token form `duration-(--duration-ops-…)`, and a test fails any other form"
    - "a vendor component's literal duration is overridden by a longhand in the same layer after the vendor rule, so the component keeps its own properties and delays"
    - "a browser probe is proven able to fail by planting an off-scale duration, a loop and a 600 ms duration in the page it scans"
    - "a visual probe resolves its expected color from the theme in the page, and measures a wash as a deviation from that resolved floor"

key-files:
  created: []
  modified:
    - scrypath_ops/assets/css/app.css
    - scrypath_ops/priv/static/assets/css/app.css
    - scrypath_ops/assets/css/DESIGN-TOKENS.md
    - scrypath_ops/assets/js/app.js
    - scrypath_ops/assets/js/ops_hooks.js
    - scrypath_ops/priv/static/assets/js/app.js
    - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
    - scrypath_ops/lib/scrypath_ops_web/components/core_components.ex
    - scrypath_ops/test/scrypath_ops_web/motion_contract_test.exs
    - scrypath_ops/test/scrypath_ops_web/design_tokens_contract_test.exs
    - scrypath_ops/test/scrypath_ops_web/reskin_static_contract_test.exs
    - scripts/ci/ui-literal-baseline.json
    - examples/scrypath_ecommerce/ui-tokens.test.mjs
    - examples/scrypath_ecommerce/retired-identity-allowlist.json
    - examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts
    - examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts
    - examples/scrypath_ecommerce/e2e/phase173_shell.spec.ts
    - examples/scrypath_ecommerce/e2e/admin_shell_wash.spec.ts
    - test/mix/tasks/ui_contrast_contract_test.exs

key-decisions:
  - "The brand book's names are the source and the old names are aliases: `fast` is `instant` (80 ms), `status` is `quick` (160), `standard` and `slow` are `base` (240); `out` is `resolve` and `in-out` is `sweep`, so existing consumers did not move"
  - "A dialog or flash entering uses the 240 ms base token and everything leaving or small uses the 160 ms quick token, each with a `JS.transition` `time` equal to its duration"
  - "daisyUI durations are overridden with a `transition-duration` longhand (`quick` for controls, `base` for dialogs) in the utilities layer after the vendor rules, not by rewriting each vendor shorthand"
  - "The progress bar reads `--color-primary` at show time and, with no computed value, keeps the library's own colors rather than carrying a fallback literal"
  - "The advisory specs read the page floor and surface roles from the theme through a probe element; a wash is judged only on the part of the shell inside the viewport"

requirements-completed: []

coverage:
  - id: D1
    description: "every transition and animation duration in the source stylesheet is a brand token or zero; the old names alias the brand tokens; `advance` has no consumer and no 1650 ms value exists; Tailwind's default and the daisyUI component durations ops renders are tokens"
    requirement: "SKIN-05"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/motion_contract_test.exs (duration offender scan with a planted stylesheet, alias and easing tests, daisyUI override test on the source and the built stylesheet, reduced-motion rule test); design_tokens_contract_test.exs alias pins"
        status: pass
    human_judgment: false
  - id: D2
    description: "`lib/` holds no `duration-100`, `duration-200`, `time: 120` or animated spinner, and every Tailwind duration utility and `JS.transition` time is a brand token"
    requirement: "SKIN-05"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/reskin_static_contract_test.exs 'E-18 durations in lib are brand tokens' (planted literals, accepted token forms, the four JS.transition sites)"
        status: pass
    human_judgment: false
  - id: D3
    description: "the retired patterns of the UI-SPEC gate list are absent from the ops stylesheet, lib, the ops JavaScript and the host app.js, and a gradient appears only in the table scroller and the select chevron, up to their counts"
    requirement: "SKIN-05"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/reskin_static_contract_test.exs 'E-12 retired patterns' (live scan, scope check, one planted occurrence per family, gradient allowance); shown failing on a planted real-file occurrence and restored"
        status: pass
    human_judgment: false
  - id: D4
    description: "the progress bar takes the computed `--color-primary` at show time; the built bundle has no old hex; the literal ledger equals the source scan"
    requirement: "SKIN-05"
    verification:
      - kind: integration
        ref: "mix test test/mix/tasks/ui_literal_contract_test.exs (ledger equals scan); E-12 old-topbar-hex family; scratch Chromium probe of `--color-primary` in light, dark and System (#7b2d6b and #d58bc4)"
        status: pass
    human_judgment: false
  - id: D5
    description: "spacing custom properties are multiples of 4 px except the two named exceptions, and the off-grid padding, margin and gap literals are ratcheted at 37"
    requirement: "SKIN-06"
    verification:
      - kind: integration
        ref: "node --test examples/scrypath_ecommerce/ui-tokens.test.mjs: 'live spacing tokens stay on the 4 px grid', 'live off-grid spacing literals stay at the ceiling', 'planted off-grid spacing token fails'"
        status: pass
    human_judgment: false
  - id: D6
    description: "in a real browser, on the six screens at 390 and 1280 px in light, dark and System, no animation loops and every computed duration is 0, 80, 160 or 240 ms, also after a refresh, the Save search dialog and the Manage sheet; under reduced motion durations are at most 1 ms and nothing runs"
    requirement: "A11Y-03"
    verification:
      - kind: e2e
        ref: "make verify-path-motion on disposable stack scrypath187-p09-motion: admin_path_motion.spec.ts 19 passed (includes the planted-probe test)"
        status: pass
    human_judgment: false
  - id: D7
    description: "the four advisory specs read the page floor and surface roles from the theme; the shell chrome and wash proofs pass; no `p187` allowlist entry remains"
    requirement: "SKIN-05"
    verification:
      - kind: e2e
        ref: "make verify-shell-wash on scrypath187-p09-wash: 38 shell chrome and 4 wash passed; admin_surface_depth 37 passed and phase173_shell mounted 7 passed on scrypath187-p09-specs; scripts/verify-phase173.sh shell 14 passed (mounted and standalone) on the committed SHA; token test 55 passed (ceilings 10 and 238)"
        status: pass
    human_judgment: false

duration: 50m
completed: 2026-11-19
status: complete
---

# Phase 187 Plan 09: Motion tokens, progress bar, grep gates and the advisory specs Summary

**Every transition and animation duration in ScrypathOps is now one of the brand's 80, 160 or 240 ms tokens (the old names alias them), the progress bar takes its color from the theme, one test fails any retired pattern, spacing is ratcheted on the 4 px grid, and the old motion spec became a browser proof that nothing loops and every duration is on the scale, with reduced motion honored.**

GATE-02: this is a rendered-UI plan. Hover and color shifts are faster (80 ms instead of 120), status and tone settle in 160 ms (was 200), disclosure, drawer and overlay motion runs 240 ms (was 180 and 240), the overlay easing is the brand's `resolve` curve, daisyUI buttons, check boxes and dialogs run on the same scale, and the navigation progress bar is Plum (the theme's primary) instead of the old blue. No layout, copy or markup structure changed. The retained preview (compose project `scrypath_ecommerce`, port 4002) was not touched.

`requirements-completed` is empty on purpose, as in Plans 03 to 08. SKIN-05 (motion tokens, grep gates), A11Y-03 (no infinite animation and reduced motion, in a browser) and SKIN-06 (spacing grid) are proved here by the checks below, but the capture evidence (SKIN-08) and the computed-style proofs of Plan 10 are still to come, so the orchestrator decides when to mark them.

## What was built

- **Task 1, motion tokens (tracer, `e18bb945`).**
  - `app.css` declares `--duration-ops-instant|quick|base|advance` at 80, 160, 240 and 600 ms, the six brand easings (`strike`, `resolve`, `settle`, `sweep`, `exit`, `advance`), and the old names as `var()` aliases. `@theme inline { --default-transition-duration: var(--duration-ops-quick); }` puts Tailwind's `transition`, `transition-all` and `transition-opacity` on the quick token (the built utilities read `var(--tw-duration, var(--duration-ops-quick))`).
  - One block at the end of the utilities layer sets each daisyUI component duration ops renders: `.btn`, `.checkbox`, `.checkbox::before`, `.radio` and `.card` to quick, `.modal` and `.modal-box` to base, and the `.radio` checked animation to quick.
  - `ops_ui.ex` and `core_components.ex`: the two modal exits and the flash exit use `duration-(--duration-ops-quick)` with `time: 160`; the flash enter uses `duration-(--duration-ops-base)` with `time: 240`. `ops_hooks.js`: the mobile drawer closes after 240 ms to match its transition's alias of the base token (it was 180 ms when that token was 180 ms).
  - Tests: `motion_contract_test.exs` fails any raw duration literal, unknown token or `advance` consumer in a `transition` or `animation` declaration (with a planted stylesheet and the accepted real forms), pins the brand durations, easings and aliases, the `@theme inline` default, the daisyUI overrides (on the source and the built stylesheet) and the reduced-motion rule. `design_tokens_contract_test.exs` pins the alias form. `reskin_static_contract_test.exs` adds E-18: no `duration-100|200`, `time: 120` or `animate-spin` in `lib/`, every duration utility and `time:` is a token, and the four `JS.transition` sites. `DESIGN-TOKENS.md` has the new motion table and the updated retired-motion paragraph.
- **Task 2, progress bar, E-12 and N-13 (`ce415107`).**
  - `assets/js/app.js` reads `getComputedStyle(document.documentElement).getPropertyValue("--color-primary")` before each `topbar.show` and passes it as `barColors`; with no value it leaves the library's colors. The old topbar row is gone from `scripts/ci/ui-literal-baseline.json`, and the rebuilt bundle has no old hex.
  - E-12 (`scan_retired/2`) scans the stylesheet, `lib/**`, `assets/js/app.js`, `assets/js/ops_*.js` and the host's `app.js` (never `vendor/`) for the seven UI-SPEC pattern families and allows `gradient(` only in `.ops-table-scroll` (4) and `select.ops-form-control` (2), exact selector match, comment-free. Planted cases cover every family and the gradient allowance, and a plant in the real stylesheet was shown failing (then reverted).
  - N-13 in `ui-tokens.test.mjs`: every `--spacing-*`, `--control-h-*`, `--control-pad-*` and `--ops-sidebar-width` is a multiple of 4 px except `--spacing-ops-field` (6) and `--control-pad-x-sm` (10), each pinned to its value; the 14 px literal is exempt only as block padding of `.ops-failed-row` and `.ops-saved-search-row`; `SPACING_OFFGRID_CEILING` is 37, exact in both directions. `@min_token_test_calls` is 49 (three cases added).
- **Task 3, the advisory specs (`b4442830`).**
  - `admin_path_motion.spec.ts` keeps its name and becomes "admin motion tokens — P-12": 19 tests. For each of three theme modes and two viewports: the six screens (no loop, every duration on the scale), a refresh, the Save search dialog and the Manage sheet (the same), and reduced motion (every duration at most 1 ms, nothing running, polled for settle). One more test plants an off-scale duration, an infinite loop and a 600 ms duration into the page and proves the probe reports each by selector path (and that the reduced-motion rule neutralizes them).
  - `admin_surface_depth.spec.ts` resolves the page floor and the Panel through its own `resolveCssColor` (`--ops-bg`, `--ops-surface-1`, `--ops-sunken`, `--ops-selected`); the copper filter, the glow test, the dead `expectFlatSurface2`, `expectPrimaryHover55` and `expectNoStatusCopper` helpers and the unused locator helper are deleted. `phase173_shell.spec.ts` resolves `--color-base-200` for the active theme and keeps every test name and the `--ops-selection` read. `admin_shell_wash.spec.ts` resolves the floor from the theme before the screenshot and measures a violet shift against it at five points inside the visible shell.
  - The three `p187` entries are removed from `retired-identity-allowlist.json`; the token test printed the new ceilings (10 and 238).

## The e2e sweep

Grepped every `e2e/*.spec.ts`, `e2e/helpers/*.ts` and `e2e/*.mjs` for old color tuples in string and array form, old confirm labels and retired selectors, before and after the edits. Overlay files (`helpers/*.ts`, the preservation specs) were read only.

| File and line (before) | Hit | Owner |
|---|---|---|
| `admin_path_motion.spec.ts` 4-36, 167-254 | `.ops-path-*` prose and probes, `GLOW_RGB` `108, 92, 231`, `rgba(108,92,231,…)`, `--shadow-ops-glow`, shimmer | fixed in this task: file rewritten as P-12 |
| `admin_surface_depth.spec.ts` 47-49 | `GLOW_RGB`, `DARK_SURFACE_2_RGB` `rgb(34, 40, 49)`, `COPPER_RGB` | fixed in this task: deleted, the Panel is resolved from `--ops-surface-1` |
| `admin_surface_depth.spec.ts` 270, 284-286, 357 | `--ops-surface-2` | fixed in this task (the role is deleted; the card expectation resolves Panel) |
| `admin_surface_depth.spec.ts` 311-348 | copper badge filter, `ops-tone-`, `ops-badge-*`, `--color-secondary` copper mixes | fixed in this task: `expectNoStatusCopper` and its call deleted |
| `admin_surface_depth.spec.ts` 927-936 | glow test | fixed in this task: deleted |
| `phase173_shell.spec.ts` 188 (two), 311 | `rgb(17, 20, 25)`, `rgb(243, 245, 248)` | fixed in this task: `--color-base-200` resolved for the active theme |
| `admin_shell_wash.spec.ts` 171 and 6 | `[17, 20, 25]`, "ambient glow" prose | fixed in this task: resolved floor, header reworded |
| `admin_shell_wash.spec.ts` 141 (now 145) | `[0, 0, 0]` | not an identity value: the channel accumulator of the pixel sampler |
| `helpers/ui-preservation-states.ts` 556 | `[0, 1, 3]` | not an identity value: saved-search counts (overlay, unedited) |
| `ui-review.selftest.mjs` 544-545 | `[0, 1, 2]` | not an identity value: file indexes |
| `ui-review.selftest.mjs` 79, 211, 299, 346, 383 | `rgb(0, 0, 0)`, `rgba(0, 0, 0, 0)` | not identity values: fake-DOM fixtures for the focus-ring self-test |
| `admin_surface_depth` 375, 530; `admin_shell_chrome` 211, 236, 297, 298, 771, 772; `phase173_status_actions` 277; `phase173_shell` 77; `ui_followup` 161; `ui_reconciliation` 94 | `rgba(0, 0, 0, 0)` | not identity values: the computed value of "transparent" |
| `operator.spec.ts` 265, 266, 322 | `Promote target index` | already correct in Plan 05: it is the row trigger's name (still the template text at `sync_drift_live.ex:2342`); the confirm label is `Replace live index with target` (`operator.spec.ts:280`) |
| `"Delete", exact: true`, `Retry delete sync work` | none left | already fixed in Plans 04 and 05 (`Delete saved search permanently` in `admin_surface_depth`, `admin_shell_chrome`, `ui_baseline`); the overlay regex at `helpers/ui-preservation-states.ts:39` accepts both and was not edited |

After the edits no retired selector, no old RGB tuple and no `p187` allowlist entry remains. Left for other owners: `ui_followup.spec.ts` strict-mode locator on the duplicate timestamp (Plan 05's note, not one of the four specs) and the specs Plan 10 owns.

## Printed ceilings

| Ceiling | Before | After |
|---|---|---|
| `ALLOWLIST_CEILING` | 13 | 10 (three `p187` entries removed) |
| `HITS_CEILING` | 244 | 238 (6 hits: 2 in the motion spec, 1 in the depth spec, 3 in the shell spec) |
| `SPACING_OFFGRID_CEILING` | none | 37 (first run; it includes one 14 px `column-gap` on `.ops-failed-row__facts`, which is not the named block-padding exception) |
| `@min_token_test_calls` | 46 | 49 |
| `PENDING_CEILING`, `HEX_OUTSIDE_CEILING` | 0, 0 | 0, 0 |
| ops suite | 489 | 507 (13 in Task 1, 5 E-12 in Task 2) |
| contrast checker AAA advisory | 25 | 25 (the checker is untouched) |

## Gate results (GATE_SHA `b444283019bf8e55e3c28cd0669723770ef4fd77`, the last commit touching non-`.planning` files)

All three code commits are the only non-planning changes; `git diff --name-only b4442830..HEAD` after the SUMMARY commit shows only `.planning/` paths.

| Check | Run on | Result |
|---|---|---|
| `node examples/scrypath_ecommerce/contrast-checker.mjs` and `--self-test` | final tree | `Contrast check: PASS`, AA failures 0, AAA advisory 25; `self-test passed` |
| `node --test --test-reporter=tap examples/scrypath_ecommerce/ui-tokens.test.mjs` | final tree | 55 tests, 0 fail (the three N-13 cases included) |
| `node --test scripts/ci/ui_bundle_contract.test.cjs` | final tree | 12 pass |
| root `mix test` on the literal, contrast, tokens and tokens-helper contract tests, `--exclude contrast_child` | final tree | 29 tests, 0 failures (the ledger equals the scan) |
| scratch Chromium probe of the built stylesheet (button, check box, radio, card, dialog, dialog box, Tailwind transition utilities) | after Task 1 | every computed duration is 0.08, 0.16 or 0.24 s; under reduced motion 0.01 ms |
| `mix verify.ops_ui` (task-scoped database `scrypath_ops_test_187_09`) | `b4442830` | boundary 2 tests; 2 doctests, 507 tests, 0 failures, exit 0 |
| `mix verify.core --exclude integration --exclude docs_contract` | `b4442830` | format, clean workspace, warnings-as-errors compile, credo (3206 mods/funs, no issues), 5 properties and 1158 tests with 0 failures (103 excluded), docs, Standard Maturity Gate PASSED, exit 0 |
| `mix verify.repository_contracts` (escalated route per AGENTS.md) | `b4442830` | 157 tests, 0 failures, 209.0 s, exit 0 |
| `mix verify.ecommerce_mounted` (`E2E_PROJECT_NAME=p187_plan09_mounted`, `E2E_DOCKER_TIMEOUT_SECONDS=2700`, `BUILDX_CONFIG=/private/tmp/scrypath187-buildx`) | `b4442830` | `Docker verifier passed (scope=focused)`: 5 passed; `containers=0 networks=0 volumes=0 cleanup=clean`; the runtime dependency boundary proof passed |

RED before GREEN: the duration, alias, override, `@theme inline`, E-18 and design-token alias tests failed first (8 failures) and passed after the stylesheet, `lib/` and token edits; the planted-matcher tests passed from the start, as they only exercise the matchers. A plant in the real stylesheet failed E-12 for both the capital transform and the stray gradient and was reverted. The spacing live cases passed from the start (the tokens were already on the grid) apart from the ceiling, which failed with the printed 37 until set; the planted case proves the matchers. A shifted floor in a copy of the wash spec failed at the first sample point (the copy is deleted).

### Browser runs (each on its own disposable stack, lane port 4102)

| Run | Stack | Result |
|---|---|---|
| `make verify-path-motion` | `scrypath187-p09-motion` | 19 passed in 26.4 s on the first attempt; no stylesheet fix was needed, so there was no second attempt |
| `make verify-shell-wash` (first) | `scrypath187-p09-wash` | shell chrome 38 passed; wash 4 failed (a test bug, Deviation 6) |
| debug probe against the running third stack | `scrypath187-p09-specs` | found the failing samples were below the viewport |
| `make verify-shell-wash` (after the fix) | `scrypath187-p09-wash` | shell chrome 38 passed, wash 4 passed |
| `npx playwright test e2e/admin_surface_depth.spec.ts e2e/phase173_shell.spec.ts --workers=1 --retries=0` | `scrypath187-p09-specs` | 44 passed, 7 failed: all seven need the `standalone_ops` service that only `compose.phase173.yaml` adds (`ERR_NAME_NOT_RESOLVED`); surface depth 37 passed, phase173 mounted cases 7 passed |
| `bash scripts/verify-phase173.sh shell` (the lane `closeout-attestation` requires) | `scrypath_phase173_shell_b4442830_45058` | 14 passed on the committed SHA, mounted and standalone, so the seven plain-stack failures are environmental and the edited floor logic is proved on the standalone entry too |

## Deviations from Plan

**1. [Calibration] Facts at the plan's HEAD were stale.** The allowlist held 3 `p187` entries (the plan: 12), the motion consumers and line numbers had moved, `@min_token_test_calls` was 46. Every count was re-derived; the printed ceilings are in the table above and no check was loosened.

**2. [Rule 3 - Blocking] The tracked ops bundle was rebuilt from the current lockfile.** `scrypath_ops/priv/static/assets/js/app.js` had not been rebuilt since PR #110, so a faithful `mix esbuild scrypath_ops` also carries the Phoenix and LiveView client changes of the locked versions (80 hunks when I first rebuilt it; the only ops-code lines in that diff are the drawer delay and a comment, checked by grep, and the progress bar came with the next rebuild). The acceptance check needs the bundle rebuilt, and hand-patching a generated file would leave it different from its source. A second rebuild changes nothing. Plan 10 or 11 should expect this diff, and the standalone lane (which serves the tracked bundle) ran green on it (`verify-phase173.sh shell`, 14 passed).

**3. [Rule 1 - Bug] The mobile drawer closed before its slide-out ended.** `--duration-ops-standard` (180 ms) now aliases the 240 ms base token while `OpsNavDrawer.close` hid the panel after a literal 180 ms. `ops_hooks.js` (not in the plan's file list) waits 240 ms, with a comment. The palette's 160 ms close delay still covers its 80 ms exit animation.

**4. [Rule 3 - Blocking] `ui_contrast_contract_test.exs` was edited** (not in the plan's file list): the token-test floor follows the three new N-13 cases, 46 to 49, as the executor rules require.

**5. [Judgement] The flash and banner enter uses the base token, not quick.** The plan says to replace the 100 and 200 utilities with the quick token. The enter transition has `time: 240`, which the plan keeps, so its class duration is `duration-(--duration-ops-base)`; the exits and both modal removals use quick with `time: 160`. A test pins the four sites.

**6. [Rule 1 - Bug] The shell wash probe sampled rows below the viewport.** The probe hides the header but its space stays, so the shell's screenshot is taller than the part in the viewport, and the rows below are the document canvas (the Panel color, `rgb(32, 22, 36)`), not the shell. The old spec only passed because the canvas and the shell had the same color before the re-skin. The spec now judges the wash on the visible rows. The first `make verify-shell-wash` failed on exactly that sample (distance 16.9 at the bottom-right point), and a debug probe confirmed it before the fix.

**7. [Judgement] Unused helpers pinned to retired values were deleted rather than re-pointed** in `admin_surface_depth.spec.ts` (`expectFlatSurface2`, `expectPrimaryHover55`, `expectNoStatusCopper`, the unused locator helper and `colorsEquivalent`): none had a live call site except the copper check, and each asserted a retired value (the surface-2 role, a primary 55 percent hover border that Plan 08 replaced with Control Edge, copper). The Search health row assertion now expects the Panel fill and `box-shadow: none` (UI-SPEC P-15, Plan 08) instead of seated depth.

**8. [Judgement] The built stylesheet declares the unused brand tokens.** Tailwind scans `DESIGN-TOKENS.md`, which names `--duration-ops-advance`, `--ease-ops-strike`, `--ease-ops-settle` and `--ease-ops-advance`, so those four custom properties are emitted although no rule consumes them. The computed proof reads durations, not custom properties, the contract reads the source, and nothing computes 600 ms. Reword the doc if a stricter built-output check is wanted.

**9. [Judgement] Easings.** `standard` is kept as an alias of `resolve` (the same curve); `out` now means `resolve` (0.2, 0.8, 0.2, 1) instead of the old stronger ease-out (0.16, 1, 0.3, 1), as the plan's alias mapping says.

**10. [Judgement] Gate wording.** The plan's `fails_when` "Playwright summary reports any failed count above 0" cannot be read literally for the plain-stack phase173 run: its seven standalone cases need a service the plain compose file does not have. They are covered by the phase173 lane run above.

**Total deviations:** 10 (1 calibration, 1 bug in the drawer delay, 1 bug in the wash probe, 2 blocking, 5 judgement). **Impact:** none changes a gate or a plan outcome; deviation 2 adds a vendor-client diff to the tracked bundle.

## Docker and database cleanup

Every resource used a task-scoped name: compose projects `scrypath187-p09-motion`, `scrypath187-p09-wash` (twice) and `scrypath187-p09-specs` on lane port 4102, the verifier project `p187_plan09_mounted`, and the phase173 lane's own SHA-and-pid project `scrypath_phase173_shell_b4442830_45058`. The retained preview (`scrypath_ecommerce`, port 4002) stayed up and healthy and was never addressed.

After the work no container, network, volume or image with any of those names remains (checked by name and by compose project label), and `scrypath_ops_test_187_09` is dropped. One thing needed a manual step: the `make verify-*` targets stop their stack with `down` and no `-v`, which leaves the Postgres container's anonymous data volume. Three such volumes (created during my runs, each a Postgres 16 data directory holding `scrypath_ecommerce_test`) were inspected read-only and removed by exact id. Anyone running those targets should expect one dangling volume per run.

`docker system df` before and after: images 316 / 122.8GB and 316 / 122.8GB, containers 109 and 109, local volumes 384 (40.11GB) and 384 (40.11GB). Build cache went from 303 entries / 19.29GB to 350 entries / 21.32GB; the daemon's cache is shared with other projects and cannot be attributed to this task, so I did not prune it.

## Notes for later plans

- Plan 10: P-12 is done and green; do not duplicate it. The computed-style specs for P-15 (Search health rows: radius 0, `box-shadow: none`, 1 px Base 300 bottom rule) and the capture inventory remain. `admin_surface_depth` now asserts the Search health row is the Panel fill with no shadow in the dark modes. `phase173_status_actions.spec.ts` (24 px row gap) and `ui_followup.spec.ts` (duplicate-timestamp locator) were not touched.
- Plan 10 and 11: the tracked ops bundle now matches the locked Phoenix and LiveView client (Deviation 2). Plan 11's product tree digest moves with the stylesheet, bundle and test edits, as in every earlier plan; no fixture-overlay file was edited (no path in `PRESERVATION_FIXTURE_FILES` appears in this plan's diff, so there is no overlay digest implication beyond the product tree).
- `make verify-path-motion` and `make verify-shell-wash` boot their own stack from the working tree and need `WEB_PORT` and a task-scoped `COMPOSE_PROJECT_NAME`; each leaves one anonymous Postgres volume (see cleanup).
- The new N-13 ceiling means a change that adds an off-grid padding, margin or gap literal fails the token test, and one that removes a literal fails it until `SPACING_OFFGRID_CEILING` is lowered to the printed count.
- `scripts/ci/ui_literal_policy.test.cjs` is not wired into any gate and two of its history cases (`a valid reduction passes…`, `trusted target cleanup…`) fail in this sandbox at the `git commit` inside their temporary clone; I did not investigate beyond that, and no gate this plan names runs it.

## Known Stubs

None.

## Threat Flags

None new. T-187-21 (retired patterns re-entering ops code): E-12 fails each family and the gradient allowance on a planted occurrence, was shown failing on a planted real-file occurrence, and the literal ledger equals the source scan. T-187-22 (stacks left running or other projects pruned): task-scoped names, `down -v --rmi local` or exact-name removal, no global prune, the retained preview untouched, `docker system df` recorded. T-187-SC: no package was added; topbar 3.0.0 stays vendored and unchanged.

## Self-Check

PASSED

- Files exist: this SUMMARY and the 19 files listed under `key-files` (checked with `[ -f ]`); no file was created by this plan except the SUMMARY.
- Commits are ancestors of HEAD: `e18bb945`, `ce415107`, `b4442830`; `git rev-list --count 7763165272d5298f93a3d33361e81043a3f28ab8..HEAD` measured 3 before this SUMMARY.
- Acceptance greps at their expected values on the final tree: brand duration declarations 4; `duration-100|200` in `lib/` 0; `time: 120` in `lib/` 0; the `@theme inline` default 1; `1650` or `duration-ops-sting` in `app.css` 0; `#29d` in the ops source and built bundle 0 and 0; `barColors` in the ledger 0; `scan_retired` 12; `SPACING_OFFGRID_CEILING` 6; `"tag": "p187"` in the allowlist 0; the old shell floors in `phase173_shell.spec.ts` 0; `[17, 20, 25]` in `admin_shell_wash.spec.ts` 0; `getAnimations` in the motion spec 2; `docker ps -a --filter name=scrypath187-p09` 0.
- `git diff --name-only 7763165272d5298f93a3d33361e81043a3f28ab8..HEAD` touches no `STATE.md`, `ROADMAP.md`, `.planning/config.json` or `.planning/state.json`, none of them was created or staged, and every file was staged by path.
