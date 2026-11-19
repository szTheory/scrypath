---
phase: 187-scrypathops-re-skin
plan: 08
subsystem: ui
tags: [alpha-ban, tint-removal, hairline-rows, muted-text, contrast-manifest, contrast-checker, ops-ui]

requires:
  - phase: 187-scrypathops-re-skin
    provides: plan 03 the palette, Sunken, Selected, Control Edge and the opaque muted token; plan 05 the control rules; plan 07 the retired CSS and the deleted surface-2 role
provides:
  - no brand or status color-mix remains in the stylesheet; the former tints are Selected, Control Edge or deleted
  - Search health rows are hairline rows (radius 0, one 1px Base 300 bottom rule, no shadow, no status variants) under a list with a top hairline
  - secondary text is one opaque class, `.ops-muted`; no template or stylesheet puts alpha on text
  - the muted-alpha manifest (`MUTED_PAIRS`) and its lockstep guard are gone, replaced by two stylesheet bans with planted failures (N-07 alpha on text, N-12 primary or status tints)
  - the contrast clone cases fail for named reasons without the retired manifest
affects: [187-09, 187-10, 187-11]

actuals:
  tokens: 23657
  tasks: 2
  commits: 3

plan_head_before: 8ec195bc8191a047e7f42b0a2af0892546625d9f
plan_head_after: ab5353fecb20aa1e8ff5b5e0e5028f5e0a757be7

tech-stack:
  added: []
  patterns:
    - "a ban on a retired pattern is a stylesheet scan with a planted failure in `--self-test` and a planted clone case in the repository contracts, so it cannot pass by matching nothing"
    - "a data file that feeds a check keeps its thresholds as fixed floors in the checker, so editing the data cannot lower the bar"
    - "a clone case asserts its mutation changed the file and that the checker's own message names the reason it failed"

key-files:
  created: []
  modified:
    - scrypath_ops/assets/css/app.css
    - scrypath_ops/priv/static/assets/css/app.css
    - scrypath_ops/assets/css/contrast-pairs.mjs
    - scrypath_ops/assets/css/DESIGN-TOKENS.md
    - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
    - scrypath_ops/lib/scrypath_ops_web/components/layouts.ex
    - scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
    - scrypath_ops/test/scrypath_ops_web/surface_depth_token_contract_test.exs
    - scrypath_ops/test/scrypath_ops_web/design_tokens_contract_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs
    - examples/scrypath_ecommerce/contrast-checker.mjs
    - test/mix/tasks/ui_contrast_contract_test.exs

key-decisions:
  - "Hover borders on rows, object items and intent cards are the opaque Control Edge; the neutral mid shadow stays, no tint and no glow"
  - "Secondary text is `.ops-muted` in the components layer; a conversion by the plan's rule (alpha of 80 percent or more is Ink, below 80 is muted) gave 28 muted and 2 Ink utilities, and all 9 remaining text declarations were below 80"
  - "The pair matrix's thresholds (4.5, 3.0, 25 degrees) are fixed floors in the checker, because the retired manifest's per-entry roles were the only thing the old role cases attacked"
  - "Base-color alpha that is not text and carries no retired color stays (container borders, shadows, scrims, scroll-edge gradients, near-opaque surface mixes), as the Alpha policy decides"

requirements-completed: []

coverage:
  - id: D1
    description: "no color-mix or relative color in the stylesheet mixes the primary, secondary, info, success, warning, error or a status color; the eight former tints are Selected, Control Edge or deleted"
    requirement: "SKIN-05"
    verification:
      - kind: integration
        ref: "node examples/scrypath_ecommerce/contrast-checker.mjs (N-12, PASS) and --self-test (five planted tints fail, kept base-color alpha passes); clone case 'retired color tint' in mix verify.repository_contracts; surface_depth_token_contract_test.exs hover pins"
        status: pass
    human_judgment: false
  - id: D2
    description: "Search health rows are hairline rows: radius 0, 1px Base 300 bottom border, no shadow, no variant modifiers, no dark twin that brings a shadow back; the list has a top hairline"
    requirement: "STAT-03"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/surface_depth_token_contract_test.exs 'Search health rows are hairline rows'; posture_live_test.exs refutes the variant classes. The computed-style proof (P-15) is Plan 10's"
        status: pass
    human_judgment: false
  - id: D3
    description: "text never uses alpha: no `color` declaration with color-mix, rgba, hsla, slash alpha or a 4 or 8 digit hex; no text color utility with an opacity step and no partial opacity step in a template"
    requirement: "A11Y-01"
    verification:
      - kind: integration
        ref: "contrast-checker.mjs N-07 and --self-test (eight planted forms); design_tokens_contract_test.exs 'muted text is one opaque class and no template puts alpha on text' (shown failing on a planted opacity-75); clone case 'alpha text declaration' in mix verify.repository_contracts"
        status: pass
    human_judgment: false
  - id: D4
    description: "`MUTED_PAIRS` and the direct-mix lockstep are retired; the clone cases fail for named reasons"
    requirement: "A11Y-01"
    verification:
      - kind: cli
        ref: "scratch replay of 15 clone cases (each fails for a contrast reason, the five new ones for the exact message); mix verify.repository_contracts (157 tests, 0 failures)"
        status: pass
    human_judgment: false

duration: 1h
completed: 2026-11-19
status: complete
---

# Phase 187 Plan 08: Tints, text alpha and the muted-alpha manifest Summary

**Every Plum and status tint is gone from the stylesheet, Search health rows are hairline rows, no text in templates or CSS uses alpha (secondary text is the opaque `.ops-muted`), and the muted-alpha manifest is retired in favor of two stylesheet bans that each fail a planted violation.**

GATE-02: this is a rendered-UI plan. Secondary text on every screen is now an opaque muted color instead of an alpha mix of Ink (a little lighter or heavier depending on the old alpha), the breadcrumb separator is now full muted instead of 35 percent, the theme toggle glyphs and the timestamp copy glyph are no longer faded, Search health rows lose their card shape (radius, shadow, border) and keep one bottom hairline, and row, object item and intent card hover borders are Control Edge instead of a Plum tint. No layout, copy or markup structure changed. The retained preview (compose project `scrypath_ecommerce`, port 4002) was not touched and no Docker resource was created.

`requirements-completed` is empty on purpose, as in Plans 03 to 07: SKIN-05, A11Y-01 and STAT-03 are proved here at the stylesheet, template and contract level, but the computed-style browser proofs (P-15 and the alpha check) belong to Plans 09 and 10. The orchestrator decides when to mark them.

## What was built

- **Task 1, tint removal (tracer, `aeb6033a`).**
  - The eight remaining primary or status `color-mix` expressions: the preflight number badge fill is Selected; the intent card, result row and object item hover borders are `--ops-control-edge` (light, explicit dark and system dark, with the paired selectors still mirrored); the three Search health variant rules are deleted.
  - Search health: `.ops-schema-signal-card` is radius 0, `border: 0` plus `border-bottom: 1px solid var(--color-base-300)`, Panel fill, `box-shadow: none`. The list container has `border-top: 1px solid var(--color-base-300)`. The card's transition and its two dark twins (fill and panel-dark shadow) are deleted.
  - `contrast-checker.mjs` gains the N-12 gate (`checkRetiredColorMixes`): it reads comment-free stylesheet text, follows balanced parentheses (so multi-line and nested mixes are found), and fails any `color-mix` or relative color that names the primary, secondary, info, success, warning, error (and their `-content` colors), the four `--ops-status-*` colors or the two status text tokens. Five planted cases and one accept case (base-color border, shadow, scrim, gradient and a commented tint) sit in `--self-test`; each failure names its line.
  - `surface_depth_token_contract_test.exs`: the three hover-border pins now assert the Control Edge declarations in the base, explicit-dark and system-dark rules, and a new test pins the hairline row (radius, shadow, bottom rule, no variants, no dark twin with a shadow, the list's top rule).
- **Task 2, no alpha on text (`689b4967`).**
  - `.ops-muted { color: var(--ops-text-muted); }` is a hand-written class. The 30 `text-base-content/NN` utilities in `lib/` became `ops-muted` (28) or `text-base-content` (2); the nine direct `color: color-mix(...)` declarations became `var(--ops-text-muted)`; `.ops-time__affordance` is muted with Ink on hover and focus, no opacity; the cascade-safe override block for the alpha utility is deleted; the three theme toggle glyphs lose `opacity-75 hover:opacity-100`.
  - `MUTED_PAIRS` is deleted from `contrast-pairs.mjs` (the file now holds `FOCUS_BINDINGS`, `SURFACE_BINDINGS`, `BRAND_PAIR_MATRIX` and `PUBLISHED_PAIR_BINDINGS`). The checker loses Guard 2's direct lockstep, its reverse check and the three self-test fixtures that needed them, and no longer loads or evaluates a muted manifest. N-07 (`checkAlphaTextDeclarations`) fails any `color` property whose value has a `color-mix`, `rgba`, `hsla`, a slash alpha in a color function or a 4 or 8 digit hex, naming the selector and line; it reads only `color`, so alpha stays legal for borders, fills and shadows. Eight planted forms and one accept stylesheet (alpha on every other property, a commented declaration) are in `--self-test`.
  - `design_tokens_contract_test.exs`: the muted test now asserts `.ops-muted` is the opaque token with no mix and no opacity, that no `text-<color>/<n>` utility or partial `opacity-<n>` appears in any template (with planted strings so the matchers are shown to fire), and the neutral-links test splits on the prose-link comment instead of the deleted block.
  - `DESIGN-TOKENS.md` describes N-07, N-12 and the fixed floors, lists the muted consumers, drops the registry section and the alpha note on glyphs.
- **Comment fix (`ab5353fe`).** The plan's acceptance grep counts the retired export name in `contrast-pairs.mjs`; my header comment named it. Comment only (the built stylesheet is byte-identical); the long gates were rerun on this commit.

## Conversion tables

### The nine direct text declarations (plan: eleven)

| Selector | Was | Now |
|---|---|---|
| `.ops-time__label` | 62 percent mix | `var(--ops-text-muted)` |
| `.ops-nav-group__label` | 64 | muted |
| `.ops-nav-item` | 74 | muted |
| `.ops-fieldset__hint` | 70 | muted |
| `.ops-intent-card__summary` | 75 | muted |
| `.ops-empty-hero__body` | 74 | muted |
| `.ops-signal-table th[scope="row"]` | 78 | muted |
| `.ops-cheatsheet__row dd` | 70 | muted |
| `.ops-trail__sep` | 35 (decorative) | muted |

All nine were below 80, so none became Ink. `.ops-tone-chip__value` (75) and `.ops-badge-neutral` (82) from the plan's list no longer exist (Plan 04 removed them).

### The 30 template utilities (plan: 33)

| Former alpha | Count | Sites | Now |
|---|---|---|---|
| `/65` | 5 | `ops_ui.ex` (the inline loader, three field or fieldset hints, one subtitle) | `ops-muted` |
| `/70` | 10 | `ops_ui.ex` x3, `posture_live.ex` x5, `sync_drift_live.ex` x2 | `ops-muted` |
| `/75` | 13 | `ops_ui.ex` x7 (including the unselected segmented option), `control_room_live.ex` x2, `posture_live.ex` x1, `sync_drift_live.ex` x3 | `ops-muted` |
| `/80` | 2 | `ops_ui.ex` (disclosure body, one body paragraph) | `text-base-content` |

`search_live.ex` had none left (Plan 06 moved the Search loader text to the muted token).

## Re-derived numbers

| Plan said | Measured at the plan's base | Why |
|---|---|---|
| 59 brand or status `color-mix` | 8 | Plans 04, 05 and 07 removed the rest |
| 11 `color: color-mix(...)` declarations | 9 | Plan 04 removed `.ops-tone-chip__value` and `.ops-badge-neutral` |
| 33 text utilities (search 1) | 30 | Plans 04 and 06 |
| `MUTED_PAIRS` 11 entries | 9 | same |
| app.css and built CSS allowlist entries | already 0 | Plan 07 removed them at 0 hits; `ALLOWLIST_CEILING` 13 and `HITS_CEILING` 244 are unchanged and the token test passes exactly |
| `@min_token_test_calls` | 46, unchanged | no token-test case was added or removed |
| contrast checker AAA advisory count | 31 before, 25 after | the muted manifest's pairs left the report (advisory only) |
| ops suite | 487 before, 489 after | the surface-depth hover pins stayed two tests and a hairline test was added; the muted test split into two |

## Gate results (GATE_SHA `ab5353fecb20aa1e8ff5b5e0e5028f5e0a757be7`, the last commit touching non-`.planning` files)

The two code commits and the comment fix are the only non-planning changes. The three long gates ran on `689b4967`, then again on `ab5353fe` after the comment fix; both runs passed. `git diff --name-only ab5353fe..HEAD` after the SUMMARY commit shows only `.planning/` paths.

| Check | Run on | Result |
|---|---|---|
| `node examples/scrypath_ecommerce/contrast-checker.mjs` | final stylesheet | `Contrast check: PASS`, AA failures 0, AAA advisory 25, thinnest text pair 4.58 (Retrying on Selected Page) |
| `node examples/scrypath_ecommerce/contrast-checker.mjs --self-test` | final checker | `self-test passed` |
| `node --test --test-reporter=tap examples/scrypath_ecommerce/ui-tokens.test.mjs` | final tree | 52 tests, 0 fail |
| `node --test scripts/ci/ui_bundle_contract.test.cjs` | Task 2 tree | 12 pass (the plain `text-base-content` utility the bundle contract requires is still generated) |
| root `mix test` on the four `ui_*` contract tests, `--exclude contrast_child` | Task 2 tree | 29 tests, 0 failures |
| `scrypath_ops` `mix test` on the surface depth, design tokens, shell chrome, motion and posture tests (task-scoped database `scrypath_ops_test_187_08`) | Task 1 tree | 64 tests, 0 failures |
| `scrypath_ops` `mix test` (whole suite) | Task 2 tree | 2 doctests, 489 tests, 0 failures |
| scratch replay of 15 clone cases | Task 2 tree | every case fails the checker for a contrast or binding reason; the five new ones for the exact message (list below). The 'unsupported token color' case was not replayed: this plan does not touch what it mutates, and it runs in the real gate |
| `mix verify.repository_contracts` (escalated route per AGENTS.md; includes the `contrast_child` clone cases) | `689b4967`, then `ab5353fe` | 157 tests, 0 failures (223.7 s, then 273.7 s), exit 0 both times |
| `mix verify.ops_ui` (task-scoped database) | `689b4967`, then `ab5353fe` | boundary 2 tests; 2 doctests, 489 tests, 0 failures, exit 0 both times |
| `mix verify.core --exclude integration --exclude docs_contract` | `689b4967`, then `ab5353fe` | format, warnings-as-errors compile, credo (3206 mods/funs, no issues), 5 properties and 1158 tests with 0 failures (103 excluded), Standard Maturity Gate PASSED, exit 0 both times |

Scratch replay (script in the session scratchpad, not committed), reasons the checker printed:

| Case | Result |
|---|---|
| unmutated control | `Contrast check: PASS` |
| text role dropped from the matrix | `N-03 expected 56 text pairs` |
| text floor lowered | `N-03 text threshold is 1 in the pair matrix, the floor is 4.5` |
| manifest without bindings | `Required focus/surface bindings are empty` |
| alpha text declaration | `N-07 text color at app.css line N (.planted) uses alpha` |
| retired color tint | `N-12 color-mix at app.css line N mixes a primary, secondary or status color` |
| the ten older cases | unchanged messages (missing theme, decoy, duplicate theme, missing token, muted token drift, dark focus below 3, changed focus background, changed shell background, new unbound focus, broken launch) |

RED before GREEN: the surface-depth pins and the hairline test failed first for the right reason (3 failures: the two hover pins and the card's radius) before the CSS changed; the checker failed on exactly the 8 tints (Task 1) and exactly the 9 text declarations (Task 2, each naming its selector and line) before the stylesheet changed; the template scan was shown failing on a real file by putting `opacity-75` back on one glyph and restoring it. The lib conversion and the muted class were written after those failures.

Tracer note (Task 1): `type="tracer"`, no `gate="blocking-human"`, auto mode off (`auto_advance` false), automated-only `<verify>`. All three Task 1 verify commands passed on the working tree and again unchanged in the committed tree (64 tests, 0 failures; checker PASS; self-test passed); tracer verified end-to-end, expanding.

### Not run

- `mix verify.ecommerce_mounted` (the Docker mounted lane) and the advisory Playwright specs: the plan's verification block does not list them. No markup structure, label or handler changed; the browser proofs for this plan are Plan 09 and 10's. No Docker resource was created, so there is nothing to clean up or measure with `docker system df`; the retained preview (compose project `scrypath_ecommerce`, port 4002) was never addressed. `scrypath_ops_test_187_08` is dropped (verified absent with `psql -l`).

## Deviations from Plan

**1. [Calibration] The measured counts were lower than the plan's** (table above). No check was loosened; every acceptance grep is at its expected value (0).

**2. [Rule 2 - missing correctness] The theme toggle glyphs no longer carry `opacity-75 hover:opacity-100`** (`layouts.ex`, not in the plan's file list). Plan 06's summary handed them to this plan ("belong to the alpha sweep"), the UI-SPEC bans element opacity below 1 on text and RESEARCH bans it on control glyphs. They render at full opacity now, and the design-token test scans every template for any opacity step other than 0 and 100.

**3. [Rule 3 - blocking] `posture_live_test.exs` pinned `class="text-ops-body text-base-content/75"`** (not in the plan's file list). The pin moved to `ops-muted` with the template.

**4. [Rule 1 - a case that could no longer fail] The clone cases "invalid pair role" and "text role laundering" targeted `role: "text"`, a string that existed only inside `MUTED_PAIRS`.** With the manifest retired, both would have mutated nothing and "unexpectedly passed". They now attack the matrix that replaced it: "text role dropped from the matrix" (fewer than the 56 pairs the check counts) and "text floor lowered". The second needed a checker change: the matrix thresholds were read from the manifest, so lowering `min` in the data file lowered the bar. `checkMatrixFloors` fixes 4.5 (text and button labels), 3.0 (control edge and primary) and 25 degrees (status hue) in the checker, with planted self-test cases. The loop also now fails any case whose mutation changed nothing, and checks the checker's own message for the five replaced or added cases (the plan asked only that each still fail for a real reason).

**5. [Judgement] "manifest without bindings" keeps every other export.** The plan's literal content (a manifest holding only the two empty arrays) would fail on the missing matrix export before reaching the bindings check. Emptying only `FOCUS_BINDINGS` and `SURFACE_BINDINGS` makes the case fail for the reason it names. I also added a third new case, "retired color tint" (N-12), beside the two the plan names, so each ban has its own clone proof; it adds one more nested repository-contract run to the existing test.

**6. [Judgement] N-12 is broader than the plan's six names.** It also covers the `-content` colors, the four `--ops-status-*` colors, the two status text tokens and relative color syntax (`rgb(from var(--color-primary) r g b / 14%)`), because those are the same tint written another way. All have zero live hits.

**7. [Judgement] The Search health list keeps its 24 px row gap.** `phase173_status_actions.spec.ts` (advisory) pins `rowGap` of `24px`, and Plan 10 owns that spec. Each row has a Panel fill and a bottom hairline; between rows the page color shows through the gap. If the review prefers contiguous rows, the gap and that pin change together. The card's border and shadow transition was deleted with the border and shadow (a hairline row has no hover state), which removes one consumer of `--duration-ops-status`.

**8. [Judgement] The intent card keeps its hover lift and neutral raised shadow;** only the Plum border tint changed (to Control Edge). UI-SPEC says intent cards have no shadow; that is a resting-state rule outside this plan's list and the card's resting shadow is untouched.

**9. [Judgement] Near-opaque base-color mixes stay.** The result row and Search hit light fill (`base-100` or `surface-1` at 94 percent), the sidebar (97 percent), container borders, shadows, scrims and the table scroll-edge gradients are non-text mixes with no retired color, which the Alpha policy keeps ("a rewrite to an opaque token is welcome but not required"). Plan 07's note assigned the translucent result row fill to this sweep; I left it for that reason and it computes as before. Remaining `color-mix(` count in `app.css`: 38, all of base-content, base-100, surface-1 or black.

**10. [Judgement] Two disabled or inactive states still use element opacity:** `.ops-saved-search-menu__item:disabled` (`opacity: .6`) and `.ops-preflight__card--locked` (`opacity: 0.55`, no template renders it). N-07 as specified reads `color` declarations, not `opacity`, and WCAG exempts inactive controls, so I left them. They are the only element opacity below 1 over text left in the stylesheet, if the maintainer wants the ban to cover inactive states too.

**11. [Resolved] Plan 02's note about an unused `.uppercase` utility.** The two notes that contained the word lived inside `MUTED_PAIRS` entries and are deleted with them; the one remaining use of the word was a table label in `DESIGN-TOKENS.md`, reworded. The rebuilt stylesheet has no `.uppercase` rule.

**12. [Process] `mix format` rewrapped one line of the new hairline test after the first commit;** the formatted file is in the second commit.

## Notes for later plans

- Plan 09: P-12 and E-12 can now rely on `.ops-muted` and on the template scan; `--duration-ops-status` lost the signal card consumer (the motion ledger count is one lower than Plan 07's). The advisory `phase173_status_actions.spec.ts` still expects `rowGap` `24px` (it holds) and reads `.ops-schema-signal-card` background and border colors in `surfaceFingerprint`; the card now has border width 0 on three sides.
- Plan 10: P-15 for Search health should read radius 0, `box-shadow: none` and a 1px bottom `border-bottom-color` of Base 300 on `.ops-schema-signal-card`; the list's `border-top` is Base 300. The computed-color check for N-07 should expect alpha 1 on every text node (the muted class computes `#5e5360` light and `#bbaac0` dark); `.ops-trail__sep`, nav items and group labels moved to full muted, and the time copy glyph computes muted at rest and Ink on hover or focus. The theme toggle glyphs compute opacity 1.
- Plan 11: `scrypath_ops/assets` is a product-source root, so the product tree digest moves with this plan's CSS and `contrast-pairs.mjs` edits (as it did with every earlier CSS plan); nothing pins a byte value.
- `contrast-pairs.mjs` is down to bindings, matrix and published pairs. A new backdrop token still needs a row in `BRAND_PAIR_MATRIX`; a lowered threshold now fails in the checker, not in the data file.
- Plan 07's note that `.ops-result-row` computes `oklch(... / 0.94)` still holds (Deviation 9).

## Known Stubs

None.

## Threat Flags

None new. T-187-20 (alpha text or retired tints returning after the manifest is retired): N-07 and N-12 each fail a planted violation in `--self-test`, the clone cases "manifest without bindings", "alpha text declaration" and "retired color tint" fail the real checker inside `verify.repository_contracts` for the exact message, and a template scan fails any alpha utility. The retired manifest's role-laundering attack is replaced by fixed floors. T-187-SC: no package was added.

## Self-Check

PASSED

- Files exist: this SUMMARY and the 14 files listed under `key-files` (checked with `[ -f ]`); no file was created by this plan except the SUMMARY.
- Commits are ancestors of HEAD: `aeb6033a`, `689b4967`, `ab5353fe`; `git rev-list --count 8ec195bc..HEAD` measured 3 before this SUMMARY.
- Acceptance greps at their expected values on the final tree: primary or status color-mix 0 (was 8 at the base; the plan's 59 predates Plans 04 to 07), signal card variants 0, stylesheet allowlist entries 0, `text-base-content/NN` in `lib/` 0 (was 30), `color: color-mix(` declarations 0 (was 9), `MUTED_PAIRS` in `contrast-pairs.mjs` 0, "empty pairs" in the clone test 0, `opacity: .45` 0.
- `git diff --name-only 8ec195bc..HEAD` touches no `STATE.md`, `ROADMAP.md`, `.planning/config.json` or `.planning/state.json`; every file was staged by path.
