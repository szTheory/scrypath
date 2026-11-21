---
phase: 195-mount-and-prove
plan: 02
subsystem: testing
tags: [phoenix_storybook, scrypath_ops, render-all, planted-failure, storybook-js, esbuild, hook-parity]

requires:
  - phase: 195-mount-and-prove
    provides: "Plan 01 mount: dependency, route macro, backend module, ops_button tracer story, catalog_contract_test mount describe"
provides:
  - storybook.js (html theme attribute plus window.storybook.Hooks with the nine operator hooks), its own dev esbuild profile and a tracked 37,937-byte bundle
  - backend js_path, so the iframe loads the bundle with a resolved ?hash=
  - pure render-all helpers (targets/1, url/4, problems/1, theme_problem/2) run against the real route and a test-only planted tree
  - five primitive stories (ops_button, ops_badge, ops_panel, ops_empty_state, ops_sync_status), 17 variations, each rendered in light and dark
  - hook parity asserted across app.js, storybook.js and the tracked bundle
affects: [195-03, 196, 197]

actuals:
  tokens: 15600
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "render-all as pure helpers plus one render_target/3 loop shared by the real endpoint and a planted endpoint"
    - "a crash result carries its cause, so a mistyped route or missing error view cannot pass as the planted failure"
    - "test-only endpoint, router and backend under test/support; nothing in lib references them"
    - "hand-built tracked bundle with a dev-only esbuild profile kept out of assets.build"

key-files:
  created:
    - scrypath_ops/assets/js/storybook.js
    - scrypath_ops/priv/static/assets/js/storybook.js
    - scrypath_ops/test/support/catalog_render_all.ex
    - scrypath_ops/test/support/catalog/planted_storybook.ex
    - scrypath_ops/test/support/catalog/planted_router.ex
    - scrypath_ops/test/support/catalog/planted_endpoint.ex
    - scrypath_ops/test/support/storybook_planted/failing/boom.story.exs
    - scrypath_ops/test/support/storybook_planted/failing/empty.story.exs
    - scrypath_ops/storybook/primitives/ops_badge.story.exs
    - scrypath_ops/storybook/primitives/ops_panel.story.exs
    - scrypath_ops/storybook/primitives/ops_empty_state.story.exs
    - scrypath_ops/storybook/primitives/ops_sync_status.story.exs
  modified:
    - scrypath_ops/config/config.exs
    - scrypath_ops/config/test.exs
    - scrypath_ops/catalog/lib/scrypath_ops/catalog/storybook.ex
    - scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs
    - scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs

key-decisions:
  - "The planted endpoint is a full request pipeline, not a stub: it needs Plug.Parsers and render_errors, or every plant renders the first variation with no theme and every crash reads as a missing error view"
  - "A crash result is {:crashed, kind, cause}; the planted test pins the cause of each crash, not only that one happened"
  - "ops_sync_status replaced the form-field story: a server-side render-all cannot exercise ops_field's phx-hook, so its story would claim more than its test proves; the form-field story moves to Phase 197's patterns tier where a browser-level check can cover it"
  - "ops_panel has one variation: its class attribute only appends a caller class and has no visible effect of its own"

patterns-established:
  - "Every new check ships with a planted case or a negative control that was seen to fail (emptied check, stripped hashes, removed bundle, dropped hook)"
  - "Story files live under scrypath_ops/storybook, outside the UI literal ratchet roots; storybook.js sits under a scanned root and carries no literal"

requirements-completed: [MOUNT-03, FLOW-01, FLOW-03]

coverage:
  - id: D1
    description: "Every variation of five primitives renders through GET /storybook/iframe/<path>?variation_id=<id>&theme=<light|dark> with a non-empty sandbox inside [data-phx-main], app.css?hash=<md5>, storybook.js?hash=<md5> and the requested body data-theme"
    requirement: MOUNT-03
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs#render-all every variation of every story renders non-empty with real css, js and theme"
        status: pass
    human_judgment: false
  - id: D2
    description: "The same render path reports a planted raising story, an empty story and unknown variation ids; problems/1 flags stripped hashes and a data-phx-error marker on real production output"
    requirement: MOUNT-03
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs#planted tree the same render-all path reports the planted crash, empty story and unknown variation"
        status: pass
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs#planted tree problems/1 flags a missing sandbox, stripped hashes and a data-phx-error marker"
        status: pass
    human_judgment: false
  - id: D3
    description: "storybook.js sets the html theme attribute and registers exactly the nine app.js operator hooks; the tracked bundle carries them and equals a fresh build"
    requirement: MOUNT-03
    verification:
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs#standalone and mounted LiveSockets share all operator hooks"
        status: pass
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs#the tracked storybook bundle carries the hooks and the theme hook"
        status: pass
      - kind: other
        ref: "MIX_ENV=dev mix esbuild scrypath_ops_storybook && git diff --exit-code -- scrypath_ops/priv/static/assets/js/storybook.js"
        status: pass
    human_judgment: false
  - id: D4
    description: "Stories sit outside the UI literal ratchet roots and storybook.js passes the UI literal policy; no brand color, inline style or size xs in any story"
    requirement: MOUNT-03
    verification:
      - kind: other
        ref: "node scripts/ci/ui_literal_policy.cjs (UI literal policy: PASS) and node --test examples/scrypath_ecommerce/ui-tokens.test.mjs (90 pass, 0 fail)"
        status: pass
    human_judgment: false
  - id: D5
    description: "assets.build and assets.deploy aliases and the Docker asset_builder commands are unchanged; the storybook bundle is built only by its own dev profile"
    requirement: MOUNT-03
    verification:
      - kind: unit
        ref: "test/mix/tasks/dependency_boundary_contract_test.exs (26 tests, 0 failures, aliases pinned verbatim)"
        status: pass
    human_judgment: false

duration: 13min
completed: 2026-11-21
status: complete
commits: 3
plan_head_before: 39da35fe2dd6affc2125a5dbae232eee1ac2bc39
plan_head_after: adfe902f08272b3822f9351894f1441c3b406709
---

# Phase 195 Plan 02: Mount and prove (real styling, hooks, render-all and a planted failing tree) Summary

**Five primitives render through the real storybook iframe route in light and dark with the production stylesheet and the nine operator hooks, and the same render-all code is proven to fail on a raising story, an empty story and unknown variation ids.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-11-21T21:34:08Z
- **Completed:** 2026-11-21T21:47:00Z
- **Tasks:** 3
- **Files modified:** 17 (12 created, 5 modified)

## Accomplishments

- `storybook.js` sets `html[data-theme]` for `light` and `dark` (System sets none) and exposes `window.storybook.Hooks` with the nine app.js operator hooks. It has its own dev esbuild profile, `scrypath_ops_storybook`; the 37,937-byte bundle is tracked like `app.js` and a fresh build is byte-identical. `assets.build` and `assets.deploy` are untouched, so the Docker asset_builder commands are unchanged.
- Render-all walks every story variation through the real iframe route: **5 stories, 17 variations** (button 3, badge 7, panel 1, empty state 2, sync status 4), 34 renders in two themes, in 36.6 ms. Each render must have a non-empty sandbox inside `[data-phx-main]`, `app.css?hash=<md5>`, `storybook.js?hash=<md5>` and the requested body theme.
- A test-only endpoint, router and backend (nothing in `lib` references them) plant three failures. The same `render_target/3` plus `RenderAll.problems/1` path reports all of them, each with its own cause.
- Hook parity is asserted across `app.js`, `storybook.js` and the tracked bundle.

## Task Commits

1. **Task 1: Tracer, real styling and hooks through render-all on the first story** - `c4909dd0` (chore)
2. **Task 2: Planted failing tree proves render-all can fail** - `c4c020e2` (test)
3. **Task 3: Remaining four primitives and hook parity** - `adfe902f` (chore)

**Plan metadata:** the docs commit that carries this file and the STATE, ROADMAP and REQUIREMENTS updates.

## Evidence

- **Planted-loop result map** (planted endpoint, light theme):
  - `{"/failing/boom", "boom"}` is `{:crashed, :error, "** (RuntimeError) planted render failure"}`
  - `{"/failing/empty", "empty"}` is `{:rendered, ["empty output"]}`
  - `{"/failing/boom", "no_such_variation"}` is `{:crashed, :error, ":function_clause"}`
  - `{"/failing/empty", "no_such_variation"}` is `{:crashed, :error, ":function_clause"}` (the story renders fine on its own, so this crash can only come from the unknown id)
- **Planted revert (Task 2 acceptance):** with the `problems/1` "empty output" check replaced by `{false, "empty output"}`, the planted test went red (4 tests, 1 failure, the empty target returned `{:rendered, []}`); restored, 4 tests, 0 failures.
- **Other negative controls, each seen to fail and restored:** the bundle moved away turned the real render-all red with "js_path did not resolve (no ?hash=)" for every ops_button target plus the storybook "Can't resolve js_path" log warning; `?hash=` stripped from a real render flagged both css and js labels; a `data-phx-error` attribute added to the real render's `[data-phx-main]` element was flagged; dropping `OpsToast` from `storybook.js` failed the hook parity test.
- **`live/1` on a dispatched conn worked** (`Phoenix.ConnTest.dispatch/5` against the chosen endpoint, then `live(conn)`); the `live(conn, url)` fallback was not needed and the planted describe stays in the one module.
- **Render-all wall time:** 36.6 ms for the real tree (34 renders); the planted loop took 93.9 ms (it includes the expected crash logs).
- **Bundle:** 37,937 bytes; `git check-ignore` exits 1 (not ignored); `git ls-files --error-unmatch` exits 0 after the commit.
- **Which `<style>` holds the css import:** the `@import "/assets/css/app.css?hash=<md5>" layer(app)` is inside a `style` element, as the plan assumed, so the helper reads the text of `style` elements and applies one regex to that extracted text only.
- **Phase gate:** `MIX_ENV=test mix compile --warnings-as-errors --force` and `MIX_ENV=prod mix compile --warnings-as-errors --force` both exit 0 with no "cannot compile module" (the planted modules never reach a prod-compiled path); `git show --name-only HEAD -- scrypath_ops/lib` printed nothing for the Task 2 commit and `grep -rn PlantedEndpoint scrypath_ops/lib` finds nothing. `mix precommit` in `scrypath_ops/`: exit 0, 23 s wall, 2 doctests, 567 tests, 0 failures, `mix.lock` unchanged.
- **Early lane mirror:** `mix verify.ops_ui` on head `adfe902f` exited 0 in 233 s (root boundary integration 2 tests, isolated ops suite 2 doctests, 567 tests, 0 failures). Plan 03 still owns the full required-lane mirror and the hosted measurement.
- **Root-side checks at the final head:** `mix format --check-formatted` (root and `scrypath_ops/`), `dependency_boundary_contract_test.exs`, `verify_namespace_fence_test.exs` and `package_metadata_test.exs` (64 tests, 0 failures), `ui-tokens.test.mjs` (90 pass), UI literal policy PASS, `verify-dependency-boundaries.sh --static-contract-only` passes.

Fidelity and wiring hours: 0.1 h (planted endpoint wiring: it first had no Plug.Parsers, so `variation_id` and `theme` were silently dropped, and no render_errors, so every crash read as a missing error view; both found and fixed within minutes, see Deviations)

data-phx-error is never emitted by the server (LiveView 1.1.34, phoenix_storybook 1.5.0); the selector check is kept for the requirement wording, and the real failure signals are the crash, empty and unknown-variation plants.

## Files Created/Modified

- `scrypath_ops/assets/js/storybook.js` and `scrypath_ops/priv/static/assets/js/storybook.js` - source and tracked bundle
- `scrypath_ops/config/config.exs` - `scrypath_ops_storybook` esbuild profile (not in `assets.build`)
- `scrypath_ops/catalog/lib/scrypath_ops/catalog/storybook.ex` - `js_path: "/assets/js/storybook.js"`
- `scrypath_ops/test/support/catalog_render_all.ex` - `ScrypathOps.Catalog.RenderAll`
- `scrypath_ops/test/support/catalog/planted_{storybook,router,endpoint}.ex`, `scrypath_ops/config/test.exs` - the test-only planted tree and its endpoint config
- `scrypath_ops/test/support/storybook_planted/failing/{boom,empty}.story.exs` - the two planted stories
- `scrypath_ops/storybook/primitives/ops_{badge,panel,empty_state,sync_status}.story.exs` - four stories beside the Plan 01 button
- `scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs` - render-all and planted describes, with the Phase 197 handoff note at the top
- `scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs` - hook parity for `storybook.js` and the bundle

## Decisions Made

- **Sync status over form field:** the plan chose `ops_sync_status` for the fifth story instead of the suggested form-field class. The research spike rendered it through the real iframe route, whereas `ops_field` is mostly behavior (`phx-hook="OpsFieldValidation"`) that a server-side render-all cannot exercise, so its story would claim more than its test proves. The form-field story moves to Phase 197's patterns tier, where a browser-level check can cover it.
- **Phase 197 handoff:** `catalog_contract_test.exs` renders every story under `scrypath_ops/storybook` automatically, so a new story needs no edit there. The note at the top of that file says to keep the planted-tree describe green when either helper changes.
- **Stories stay outside the literal roots** (`scrypath_ops/storybook`), which is where Phase 196 adopter colors will be allowed; none appear in this phase.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Planted endpoint silently dropped the query string**
- **Found during:** Task 2
- **Issue:** the endpoint as specified had no `Plug.Parsers`, so the router never read the query string. Every planted URL rendered the first variation with `theme` nil. The new `theme_problem/2` check caught it ("body data-theme is not light" on a story that rendered fine), and a probe showed `conn.assigns.theme` and `variation_id` were nil. Without the fix the unknown-variation plant would have crashed on the raising story instead of on the unknown id.
- **Fix:** `plug(Plug.Parsers, parsers: [:urlencoded], pass: ["*/*"])` in `ScrypathOps.Catalog.PlantedEndpoint`, with a comment saying why.
- **Files modified:** `scrypath_ops/test/support/catalog/planted_endpoint.ex`
- **Commit:** `c4c020e2`

**2. [Rule 1 - Bug] Every crash read as a missing error view, and the crash kind differed from the plan**
- **Found during:** Task 2
- **Issue:** without `render_errors`, a raising story surfaced as an `ArgumentError` about a missing `ScrypathOps.ErrorView`, hiding the real cause (a mistyped route would have read the same). With the endpoint configured, a crash is raised out of the request (kind `:error`) rather than the plan's `{:crashed, :exit}`.
- **Fix:** `render_errors: [formats: [html: ScrypathOpsWeb.ErrorHTML], layout: false]` for the planted endpoint in `config/test.exs`; `render_target/3` returns `{:crashed, kind, cause}` and the planted test pins each cause. The plan's `{:crashed, :exit}` was replaced by the observed `{:crashed, :error, <cause>}`.
- **Files modified:** `scrypath_ops/config/test.exs`, `scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs`
- **Commit:** `c4c020e2`

**3. [Rule 2 - Missing critical] Stricter unknown-variation plant**
- **Found during:** Task 2
- **Issue:** the plan's only unknown-variation case sits on the raising story, so a crash there cannot be attributed to the unknown id.
- **Fix:** added `{"/failing/empty", "no_such_variation"}` beside the plan's boom case; the empty story renders fine alone, so its crash is the unknown id's.
- **Files modified:** `scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs`
- **Commit:** `c4c020e2`

**Total deviations:** 3 auto-fixed (2 bugs in the planted harness, 1 added check).
**Impact on plan:** none on scope or files. The planted loop is stronger than specified.

## Issues Encountered

- The two planted stories log `cannot load source for component defined in story ...` at test compile time. These are Logger warnings from the storybook backend (the component lives in the `.exs` story itself), not compiler warnings, so `--warnings-as-errors` exits 0. Left as is: moving the components into a support module would depart from the plan's "own `boom/1`" shape for no check value.
- `ops_panel` has one variation (the plan's allowed fallback).

## Known Stubs

None. The `href="#"` in the empty-state story is a story fixture, not a wired-later stub.

## Threat Flags

None. The planted endpoint binds no port (`server: false`), lives only in `test/support`, and no `lib` file references it (T-195-06, checked by the prod compile and the grep above). The tracked bundle is reproducible from the dev profile and its hook names are asserted (T-195-09). Residuals for Plan 03 are unchanged: T-195-05, and the Docker half of Plan 01's script check, which runs only in the hosted `ecommerce-mounted` lane.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 03 can run the full local lane mirror, open the phase PR for the hosted cold and warm `ops-ui` measurement, and write `GO-NO-GO.md` and the ADR 0001 amendment. This plan's `Fidelity and wiring hours` figure (0.1 h) feeds the "isolation work over a day" trigger: nothing near it.
- Plan 01 left MOUNT-01 and MOUNT-02 unchecked until Plan 03's `ecommerce-mounted` run; that is unchanged. FLOW-01 and FLOW-03 stay pending by the shared-ID rule until Plan 03.
- Nothing blocks. No push, PR or Hex release was made.

## Self-Check: PASSED

- All 12 created files exist (FOUND), including the tracked bundle.
- Commits `c4909dd0`, `c4c020e2`, `adfe902f` are ancestors of HEAD (FOUND); `git rev-list --count` from `plan_head_before` is 3.
- No protected config file was staged in any commit (`git show --name-only` for each task commit lists none).

---
*Phase: 195-mount-and-prove*
*Completed: 2026-11-21*
