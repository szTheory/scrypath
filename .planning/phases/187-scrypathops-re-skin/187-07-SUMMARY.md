---
phase: 187-scrypathops-re-skin
plan: 07
subsystem: ui
tags: [retired-code, glow, path-motion, copper, surface-2, token-map, contrast-manifest, select-chevron, ops-ui]

requires:
  - phase: 187-scrypathops-re-skin
    provides: plan 03 the palette, the Sunken and Selected roles and the interim surface-2 value; plan 05 the utilities-layer control rules and the Selection Signature; plan 06 no looping animation in ops source
provides:
  - the old identity's CSS is gone from source and the built stylesheet: the path-motion family, the code-block shimmer, the glow utility, the copper classes, the route mark and its dark glow, the active-saved-search dark glow, both glow tokens and the two retired rgba triplets
  - the select chevron is one currentColor two-layer gradient rule with no dark or System twin
  - `--ops-surface-2` is deleted from the theme blocks, the token map, the DTCG mirror and the example theme; every consumer is reclassified to Panel or Sunken
  - the token map is fully applied (`PENDING_CEILING` 0, 84 of 84 cells applied)
  - the contrast manifest and checker follow the deletion, and the clone-based "changed focus background" case mutates a surviving surface
  - the motion contract asserts the retired families are absent (with a planted stylesheet), and N-08 checks every hex literal in `app.css`
affects: [187-08, 187-09, 187-10, 187-11]

actuals:
  tokens: 19152
  tasks: 2
  commits: 2

plan_head_before: b2c873b54730810832bf62d6cee123e9e0ed26c9
plan_head_after: 2bb2284af6c0658e5d660a0dd57f4f2d356d081d

tech-stack:
  added: []
  patterns:
    - "a retired family is guarded by an absence test with a planted stylesheet, so the matcher cannot pass by matching nothing"
    - "a control glyph that daisyUI draws in the utilities layer is owned by a rule in the same layer, selected by a more specific selector (`select.ops-form-control` beats `.select`)"
    - "a clone-based contrast mutation is replayed on a scratch copy of the checker, the manifest and the stylesheet to prove it still fails for a contrast reason before the long gate runs"

key-files:
  created: []
  modified:
    - scrypath_ops/assets/css/app.css
    - scrypath_ops/priv/static/assets/css/app.css
    - scrypath_ops/assets/css/DESIGN-TOKENS.md
    - scrypath_ops/assets/css/token-map.json
    - scrypath_ops/assets/css/contrast-pairs.mjs
    - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
    - scrypath_ops/test/scrypath_ops_web/motion_contract_test.exs
    - scrypath_ops/test/scrypath_ops_web/surface_depth_token_contract_test.exs
    - examples/scrypath_ecommerce/contrast-checker.mjs
    - examples/scrypath_ecommerce/ui-tokens.test.mjs
    - examples/scrypath_ecommerce/retired-identity-allowlist.json
    - test/mix/tasks/ui_contrast_contract_test.exs
    - brandbook/tokens/tokens.json
    - brandbook/tokens/daisyui-theme.example.js

key-decisions:
  - "Raised surfaces are Panel (`--color-base-100`); hover and recessed surfaces are `--ops-sunken`; there is no second raised tier"
  - "The code-block shimmer is deleted with the path family (it sits inside the UI-SPEC retire range, and its glint rode a Plum alpha ring), together with the `shimmer` attribute of `ops_code_block/1`"
  - "The select chevron lives in the utilities layer block, because daisyUI draws its own chevron on `.select` there and a components-layer rule never reaches it; the geometry is daisyUI's, so nothing moves"
  - "The dark theme toggle's own background rule is deleted instead of re-pointed, because its unlayered base rule already fills the track with Sunken in both themes"
  - "The dark card, row and signal-card fills stay as explicit rules on the Panel token (the plan keeps the two pins), even though they now equal the light base"

requirements-completed: []

coverage:
  - id: D1
    description: "no path, copper, glow, shimmer or route-mark rule and no glow token in source CSS; the two retired rgba triplets and the hard-coded chevron colors are gone"
    requirement: "SKIN-05"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/motion_contract_test.exs (absence test and planted stylesheet); examples/scrypath_ecommerce/ui-tokens.test.mjs live deny-list scan (app.css and built CSS entries removed at 0 hits)"
        status: pass
    human_judgment: false
  - id: D2
    description: "`--ops-surface-2` is deleted everywhere it was bound; token map fully applied; N-08 holds"
    requirement: "SKIN-01"
    verification:
      - kind: integration
        ref: "ui-tokens.test.mjs (PENDING_CEILING 0, live app.css hex literals are brand or declared, planted retired hex in app.css fails); mix verify.ui_tokens (mirror parity); surface_depth_token_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "contrast manifest and checker follow the deletion; every clone-based mutation case still fails the checker for a contrast reason"
    requirement: "SKIN-01"
    verification:
      - kind: cli
        ref: "node examples/scrypath_ecommerce/contrast-checker.mjs (PASS) and --self-test; scratch replay of the nine mutation cases; mix verify.repository_contracts (includes the contrast_child clone cases)"
        status: pass
    human_judgment: false

duration: 1h 50m
completed: 2026-11-19
status: complete
---

# Phase 187 Plan 07: Retired CSS and the old raised surface Summary

**The old identity's glow, path, copper, route-mark and shimmer CSS and the hard-coded select chevron are deleted, `--ops-surface-2` is gone from the stylesheet, token map, mirror, manifest and checker with every consumer moved to Panel or Sunken, and the token map is fully applied with guards that fail if any of it returns.**

GATE-02: this is a rendered-UI plan. Cards, key caps, the command hint, the muted panels, code blocks, the theme toggle, the saved-search menu hover and every select changed appearance (surfaces and the chevron's authoring, not layout or copy). The retained preview (compose project `scrypath_ecommerce`, port 4002) was not touched and no Docker resource was created.

`requirements-completed` is empty on purpose, as in Plans 03 to 06: SKIN-05 and SKIN-01 are proved here at the stylesheet, token-map and contract level, and I checked the computed styles in headless Chromium with a throwaway probe, but the committed browser proofs belong to Plans 09 and 10. The orchestrator decides when to mark them.

## What was built

- **Task 1, retired families (tracer, `972ac988`).**
  - `app.css` loses `.ops-glow`, the four `.ops-copper-*` classes, `.ops-route-mark` with its two dark glow rules, the whole `.ops-path-*` block, `.ops-code-block--shimmer`, the active saved search's two dark glow rules, both glow tokens in `@theme` and in the two dark blocks, and with them the four rgba triplet sites. `ops_code_block/1` loses its `shimmer` attribute and class. The file goes from 2787 to 2629 lines.
  - The select chevron is one rule, `select.ops-form-control`, with two `linear-gradient` triangles painted in `currentColor`. It sits in the `@layer utilities` block beside the other control rules because daisyUI draws its own chevron on `.select` in that layer. The three data-URI rules (light, dark, System) are deleted.
  - `motion_contract_test.exs` is rewritten: it asserts that none of the six retired families or the glow tokens appears in `app.css`, and a second test feeds a planted stylesheet through the same matchers so each one is proved to fire. Its moduledoc says the duration-token rule arrives in Plan 09.
  - The `app.css` and built-CSS allowlist entries reached 0 hits and are removed (`ALLOWLIST_CEILING` 15 to 13, `HITS_CEILING` 252 to 244). The built stylesheet is rebuilt. `DESIGN-TOKENS.md` describes the retired families as deleted.
- **Task 2, the old raised surface (`2bb2284a`).**
  - `--ops-surface-2` is deleted from both theme blocks, its token-map row, its two `ops.*` entries in `brandbook/tokens/tokens.json` and its two lines in `daisyui-theme.example.js`. `contrast-pairs.mjs` binds `.ops-command-hint` to `background: var(--color-base-100)` and the saved-search menu item to `background: var(--ops-sunken)`, in the exact declaration forms the checker requires; the checker drops the surface from its list.
  - `ui_contrast_contract_test.exs`: the "changed focus background" clone case now mutates the light `--ops-selection` to the primary color, and the comment deferring it is gone.
  - `surface_depth_token_contract_test.exs` asserts the dark order `--ops-sunken` < `--ops-bg` < `--ops-surface-1`, that `ops-surface-2` appears nowhere in `app.css`, and that the dark data card and the dark result row fill from `--color-base-100`. The three hover-border assertions and their rules are untouched (Plan 08).
  - `ui-tokens.test.mjs`: `PENDING_CEILING` is 0, and two cases are added: "live app.css hex literals are brand or declared" (N-08, over the whole stylesheet with comments stripped; brand hexes, declared targets and black or white pass, an eight-digit alpha form or an arbitrary short hex fails) and "planted retired hex in app.css fails" (plain, percent-encoded in a data URI, upper case, alpha form, short form). `@min_token_test_calls` is 46.

## Surface-2 reclassification

Measured at the plan's base commit: 19 lines of `app.css` and 1 line of `ops_ui.ex` mentioned the property (the plan's 25 and 26 predate Plans 05 and 06, which removed the nav, intent-card, schema-picker and similar consumers).

| Site | Was | Now | Class |
|---|---|---|---|
| comment above the dark theme block | described the interim value | describes the two roles | n/a |
| dark and light theme declarations (2 lines) | `#2b2130`, `#ebdfe7` | deleted | n/a |
| `.ops-command-hint` | 56 percent mix | `var(--color-base-100)` | raised (Panel control with its Control Edge) |
| `.ops-muted-panel` | 64 percent mix | `var(--ops-sunken)` | recessed |
| `.ops-preflight__card--locked` | 60 percent mix | `var(--ops-sunken)` | recessed |
| `.ops-kbd` | 70 percent mix | `var(--ops-sunken)` | recessed key cap |
| `.bg-ops-surface-2` helper (and its comment) | `var(--ops-surface-2)` | renamed `.bg-ops-sunken`, `var(--ops-sunken)`; its one consumer is the default `ops_code_block` `pre` in `ops_ui.ex` | recessed |
| `.ops-theme-toggle`, explicit dark and System dark (2 rules) | 72 percent mix | background declaration deleted; the unlayered base rule fills the track with Sunken | recessed |
| `.ops-data-card`, explicit dark and System dark (2 rules) | `var(--ops-surface-2)` | `var(--color-base-100)` | raised |
| `.ops-result-row:not(.ops-search-hit)`, 2 rules | `var(--ops-surface-2)` | `var(--color-base-100)` | raised |
| `.ops-schema-signal-card`, 2 rules | `var(--ops-surface-2)` | `var(--color-base-100)` | raised |
| `.ops-saved-search-menu__item:hover, :focus-visible` | `var(--ops-surface-2)` | `var(--ops-sunken)` | hover |

## Contrast mutation cases, re-checked

The clone cases read committed HEAD and run only inside `verify.repository_contracts`, so before the long gate I replayed them on a scratch copy of the checker, the manifest and the stylesheet (script in the session scratchpad, not committed). Every case still targets a live string and fails the checker for a contrast or binding reason:

| Case | Result on the scratch copy |
|---|---|
| unmutated control | `Contrast check: PASS` |
| changed focus background (light `--ops-selection` to the primary hex) | `Contrast check: FAIL`, 11 AA failures (the focus ring on its own color) |
| the old form (light `--ops-surface-2`) | the property is gone, so the helper raises: that is why the case had to move |
| dark focus below 3 | `Stale focus binding :focus-visible` |
| changed shell background declaration | `Stale focus background binding .ops-shell` |
| new unbound focus | `Stale or duplicate focus binding inventory` |
| missing required token | `Missing required token warning-content/warning in dark` |
| menu item hover re-pointed to Selected | `Stale focus background binding` for the menu item |
| command hint back to a translucent mix | `Stale focus background binding .ops-command-hint` |

## Printed ceilings

| Ceiling | Before | After |
|---|---|---|
| `PENDING_CEILING` | 2 | 0 (84 of 84 cells applied; the token map has 42 rows) |
| `HEX_OUTSIDE_CEILING` | 0 | 0 (printed value unchanged) |
| `ALLOWLIST_CEILING` | 15 | 13 |
| `HITS_CEILING` | 252 | 244 |
| `app.css` entry `max_hits` | 4 | entry removed (0 live hits) |
| built CSS entry `max_hits` | 4 | entry removed (0 live hits) |
| `brandbook/` entry `max_hits` | 177 | 177 (the two deleted DTCG entries held brand values, not retired ones) |
| `@min_token_test_calls` | 44 | 46 (two cases added) |
| `MUTED_PAIRS` / `FOCUS_BINDINGS` | 9 / 10 | 9 / 10 |
| contrast checker AAA advisory count | 34 | 31 (the surface-2 pairs left with the surface) |

## Gate results (GATE_SHA `2bb2284af6c0658e5d660a0dd57f4f2d356d081d`, the last commit touching non-`.planning` files)

Both task commits and the three long gates ran on this one SHA; `git diff --name-only 2bb2284a..HEAD` after the SUMMARY commit shows only `.planning/` paths.

| Check | Run on | Result |
|---|---|---|
| `node examples/scrypath_ecommerce/contrast-checker.mjs` | final stylesheet | `Contrast check: PASS`, AA failures 0, thinnest text pair 4.58 (Retrying on Selected Page); no stale binding message |
| `node examples/scrypath_ecommerce/contrast-checker.mjs --self-test` | final checker | `self-test passed` |
| `node --test --test-reporter=tap examples/scrypath_ecommerce/ui-tokens.test.mjs` | final stylesheet | 52 tests, 0 fail (50 before; +N-08 live and planted); "token map pending cells: 0 of 84" |
| root `mix test` on `ui_contrast`, `ui_tokens`, `ui_literal`, `ui_tokens_helper` contract tests, `--exclude contrast_child` | final tree | 29 tests, 0 failures (the literal ledger equals the source scan) |
| `MIX_ENV=test mix verify.ui_tokens` | final tree | exit 0 (mirror parity both ways after the two DTCG entries and two example lines were deleted) |
| `scrypath_ops` `mix test` on `motion_contract`, `design_tokens_contract`, `shell_chrome_token_contract`, `surface_depth_token_contract` (task-scoped database `scrypath_ops_test_187_07`) | Task 1 tree, then final tree | 23 tests, 0 failures; 24 tests, 0 failures |
| scratch replay of the nine contrast mutation cases | final tree | all as listed above |
| `mix verify.repository_contracts` (escalated route per AGENTS.md; includes the `contrast_child` clone cases and mirror parity) | `2bb2284a` | 157 tests, 0 failures, 235.6 s, exit 0 |
| `mix verify.ops_ui` (task-scoped database `scrypath_ops_test_187_07`) | `2bb2284a` | boundary 2 tests; 2 doctests, 487 tests, 0 failures, exit 0 (the suite stays at 487: the motion contract went from 3 tests to 2 and the surface depth test from 5 to 6) |
| `mix verify.core --exclude integration --exclude docs_contract` | `2bb2284a` (run with the SUMMARY moved out of the tree, so the clean-workspace step saw a clean tree) | format, warnings-as-errors compile, credo (3206 mods/funs, no issues), 5 properties and 1158 tests with 0 failures (103 excluded), docs, Standard Maturity Gate PASSED, exit 0 |

Tracer note (Task 1): `type="tracer"`, no `gate="blocking-human"`, auto mode off, automated-only `<verify>`. Both Task 1 verify commands ran on the working tree and again on the committed tree (23 tests, 0 failures; 50 token tests, 0 fail); Tracer verified end-to-end, expanding.

RED before GREEN: Task 1's absence test failed first for the right reason (all six families found) with its planted-stylesheet test passing. Task 2's new surface-depth tests failed 3 of 6 and `PENDING_CEILING` 0 failed with `pending count 2 exceeds PENDING_CEILING 0` before the CSS and token map changed (see Deviation 6 for what could not be RED).

### Not run

- `mix verify.ecommerce_mounted` (the Docker mounted lane): the plan's verification block does not list it, and nothing it exercises changed (no markup, label, handler or behavior change; the only template edit renames a class and drops an unused attribute). No Docker resource was created, so there is nothing to clean up or measure with `docker system df`; the retained preview (compose project `scrypath_ecommerce`, port 4002) was never addressed. `scrypath_ops_test_187_07` is dropped (verified absent).
- The advisory Playwright specs (`admin_path_motion`, `admin_surface_depth`, `phase173_shell`): left to Plan 09 as the plan and the allowlist say (see Notes for later plans).

## Browser check (throwaway, not committed)

A scratch Chromium probe loaded the rebuilt stylesheet in light, dark, System dark and System light (script in the session scratchpad). It confirmed: both a `.select` and a plain `select.ops-form-control` compute the two-layer gradient with the chevron color equal to the select's own text color (`rgb(30, 18, 32)` light, `rgb(244, 237, 243)` dark), the same 4px geometry daisyUI drew, and 36px right padding on the plain select; the command hint, data card, schema-signal card and the dark result row compute Panel (`#ffffff`, `#201624`); the key cap, muted panel, locked preflight card, code block and theme toggle compute Sunken (`#f0e9e6`, `#110a14`); the saved-search menu item computes Sunken on hover once its 120 ms transition settles. These are evidence for the later P checks, not a replacement for them.

## Deviations from Plan

**1. [Calibration] The measured counts were lower than the plan's.** At the base commit `app.css` had 19 `ops-surface-2` lines (plan: 25), the retired-family grep was 33 (plan: 37), and `ops_ui.ex` had 1. The 4 rgba sites, 3 `path_motion_blocks` and the three hover-border assertions matched. Plans 05 and 06 had already removed the nav, intent-card and schema-picker consumers. No check was loosened; every acceptance grep is at its expected 0.

**2. [Judgement] The code-block shimmer is deleted, not kept.** The plan says to keep it only if its animation is finite and timed by a motion token. It is (an opacity transition on `--duration-ops-fast`), but it sits inside the UI-SPEC retire range for `.ops-path-*`, its glint is a Plum 35 percent alpha ring that Plan 08 would remove anyway, no template sets `shimmer`, and the plan's own family-absence test names "shimmer". The `shimmer` attribute and class are removed from `ops_code_block/1`.

**3. [Judgement] The select chevron is authored in the utilities layer.** The plan says one `currentColor` gradient rule on `select.ops-form-control`. daisyUI's `.select` already draws a `currentColor` chevron in the `utilities` layer, and that layer beats the components layer where the old data-URI rule lived, so by cascade order the old hard-coded chevron could not have shown on a `.select` (I did not render the old stylesheet to confirm), and only the plain time-zone select in the header, which has no `.select` class, would have used it. I put the new rule in the existing utilities block with daisyUI's own geometry, so it wins on both kinds of select, nothing moves, and a probe shows the chevron follows the text color in all four theme paths. The components-layer rule keeps only `appearance` and padding.

**4. [Judgement] The dark theme toggle rule loses its background instead of being re-pointed.** Plan 05 already fills the toggle track with Sunken in an unlayered base rule that applies in both themes. The dark override only existed to lift it with surface-2, so re-pointing it would duplicate the base. Its border and shadow declarations stay.

**5. [Judgement] The dark card, row and signal-card fills stay as explicit rules.** They now equal the light base (Panel), so they are redundant in effect. The plan asks for the two fill pins to be re-pointed to the chosen role, so the rules and pins stay; deleting them is a candidate for the dual-rule ratchet work later (the rule count only falls).

**6. [Judgement] The surface-depth order test passed before the CSS change.** It only reads the existing `--ops-sunken`, `--ops-bg` and `--ops-surface-1` values, so it could not fail first. RED came from the data-card pin, the result-row pin and the new "retired role is neither declared nor consumed" test (3 failures). The `PENDING_CEILING` 0 edit failed for the right reason (pending 2). The N-08 live test could not be RED: Task 1 had already deleted the only offending literals (the chevron data URIs).

**7. [Judgement] `HEX_OUTSIDE_CEILING` and the `brandbook/` `max_hits` did not move.** The plan expected the printed values; the exact-both-ways checks passed at 0 and 177, so those are the printed numbers.

**8. The plan's `fails_when` text "contains stale" cannot be used literally** (same as Plan 03): the passing TAP output carries test names such as "planted stale pending claim fails". I checked `# fail 0` and the failure-message forms with a colon instead.

**9. `design_tokens_contract_test.exs` and `shell_chrome_token_contract_test.exs` needed no edit.** The plan lists them for any assertion that names a deleted selector or token; neither names one. Both pass on the final tree.

## Notes for later plans

- Plan 08: the dark hover-border rules and `.ops-intent-card:hover` and `.ops-result-row:hover` still carry Plum alpha tints and are untouched, as planned. `.ops-result-row` and `.ops-search-hit` keep their `color-mix(... base-100 94%, transparent)` light fill (a translucent Panel mix), which belongs to the alpha sweep. The light `.ops-result-row` computes `oklch(... / 0.94)`.
- Plan 09: `admin_surface_depth.spec.ts:270` still resolves `var(--ops-surface-2)` (its two dark-surface cases, about lines 286 and 357, will resolve to transparent), `admin_path_motion.spec.ts` still asserts the deleted path, shimmer and glow families, and `phase173_shell.spec.ts` still pins old colors. They are the plan's advisory pins tagged in the allowlist (`p187`) and belong to Plan 09; I did not edit them. Plan 09 should also update the "Path motion (retired in Phase 187)" paragraph in `DESIGN-TOKENS.md` and the moduledoc of `motion_contract_test.exs` when the duration-token assertions land.
- Plan 10: the key cap, muted panel, locked card and code block are now Sunken, and the command hint, cards and dark rows are Panel. The code block is darker than its Panel surround in dark (`#110a14` on `#201624`). The theme toggle track is Sunken in dark too (it was a translucent lift).
- The Task 1 commit's `DESIGN-TOKENS.md` already says `--ops-surface-2` is deleted, one commit before the stylesheet stops declaring it (the doc was rewritten once for both). No test reads that sentence between the two commits.

## Known Stubs

None.

## Threat Flags

None new. T-187-18 (retired values re-entering through a new file or a raised ceiling): both allowlist entries are removed at 0 hits, ceilings are exact in both directions, and N-08 reads every hex literal in `app.css` with a planted failure. T-187-19 (a contrast mutation turning vacuous after a deletion): the old case could not run on the new CSS (the property is gone), the new case fails the checker with 11 AA failures on the scratch replay, every other case was replayed and re-checked above, and the clone run in `verify.repository_contracts` exercises them for real. T-187-SC: no package was added.

## Self-Check

PASSED

- Files exist: this SUMMARY and the 14 files listed under `key-files` (checked with `[ -f ]`); no file was created by this plan except the SUMMARY.
- Commits are ancestors of HEAD: `972ac988`, `2bb2284a`; `git rev-list --count b2c873b5..HEAD` measures 2 before this SUMMARY.
- Acceptance greps at their expected values: `ops-surface-2` in `app.css` 0 (was 19) and in `contrast-pairs.mjs`, `contrast-checker.mjs` and `ui_contrast_contract_test.exs` 0 (was 5 in the plan's count); the retired-family grep in `app.css` 0 (was 33); rgba triplets 0 (was 4); `path_motion_blocks` in the motion contract 0 (was 3); `PENDING_CEILING = 0;`; the `app.css` allowlist entry 0.
- `git diff --name-only b2c873b5..HEAD` touches no `STATE.md`, `ROADMAP.md`, `.planning/config.json` or `.planning/state.json`, none of them was created or staged, and every file was staged by path.
