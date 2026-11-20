---
phase: 187-scrypathops-re-skin
plan: 03
subsystem: ui
tags: [palette, theme-blocks, token-map, contrast, wcag, design-tokens, ops-ui]

requires:
  - phase: 187-scrypathops-re-skin
    provides: plan 01 exact token ceilings and the wrapper floor; plan 02 fonts, type floor, lockup and the glyph-safe static contract
provides:
  - both daisyUI theme blocks on the plum and orchid palette as literal hexes, 20 color variables each
  - seven new theme roles (sunken, selected, control edge, four sync-status colors) with token-map rows
  - opaque muted text (`--ops-text-muted` is Muted Ink and Muted Pale hexes)
  - the second primary tier deleted from the blocks, token map, DTCG mirror and example theme
  - contrast checker that computes 56 text pairs, the non-text pairs, the book's 14 published pairs and the Failed/Retrying hue gap from the stylesheet
  - DESIGN-TOKENS.md and DESIGN.md on the brand palette with no retired value
affects: [187-04, 187-05, 187-06, 187-07, 187-08, 187-09, 187-10]

actuals:
  tokens: 20100
  tasks: 3
  commits: 4

plan_head_before: 73c1e976f65990e7368c4338e67ca03961e4407b
plan_head_after: 2749a861c03fd26f2a5c1b18683b7f10e5dc5bb6

tech-stack:
  added: []
  patterns:
    - "one atomic commit for theme values, token-map rows and flips, rebuilt built CSS, ceilings, allowlist hit counts, guards and the DTCG mirror"
    - "pair names are custom properties in contrast-pairs.mjs; the checker resolves them from the theme blocks, so a recolor changes the verdict and no hex is repeated"
    - "check functions return failure strings and take their data as arguments, because the --self-test block runs before module-level constants are initialized"

key-files:
  created: []
  modified:
    - scrypath_ops/assets/css/app.css
    - scrypath_ops/priv/static/assets/css/app.css
    - scrypath_ops/assets/css/token-map.json
    - scrypath_ops/assets/css/contrast-pairs.mjs
    - scrypath_ops/assets/css/DESIGN-TOKENS.md
    - examples/scrypath_ecommerce/contrast-checker.mjs
    - examples/scrypath_ecommerce/ui-tokens.test.mjs
    - examples/scrypath_ecommerce/retired-identity-allowlist.json
    - test/mix/tasks/ui_contrast_contract_test.exs
    - test/mix/tasks/ui_tokens_contract_test.exs
    - brandbook/tokens/tokens.json
    - brandbook/tokens/daisyui-theme.example.js
    - DESIGN.md

key-decisions:
  - "`--ops-surface-2` stays a retire row with the Selected hex in each theme (`#ebdfe7`, `#2b2130`) until its 25 consumers go; it keeps the dark order bg < surface-1 < surface-2 and adds no hex outside the brand set"
  - "The opaque-muted guard compares `--ops-text-muted` with the pinned brand token (`color.secondary.muted-ink` light, `color.secondary.muted-pale` dark) and also requires a six-digit hex, so an alpha mix, an eight-digit hex or a wrong hex each fail"
  - "Control Edge on the overlay surface is its own named check even though the overlay uses the `base-100` fill, so a later overlay token change is caught"
  - "The explanatory comment for the interim `--ops-surface-2` sits above the dark theme plugin, not inside it: a comment inside the block makes the root test that wraps the block in a comment close that comment early"

requirements-completed: []

coverage:
  - id: D1
    description: "both theme blocks hold the UI-SPEC palette; seven new roles; strong-primary token gone; muted text opaque; token map 43 rows, 2 pending cells; ceilings exact"
    requirement: "SKIN-01"
    verification:
      - kind: unit
        ref: "node --test --test-reporter=tap examples/scrypath_ecommerce/ui-tokens.test.mjs (48/48)"
        status: pass
      - kind: integration
        ref: "root ui_contrast, ui_tokens, ui_literal, ui_tokens_helper contract tests --exclude contrast_child (29 tests) and mix verify.ui_tokens"
        status: pass
    human_judgment: false
  - id: D2
    description: "contrast checker proves 56 text pairs at 4.5, Control Edge and primary at 3.0, button labels at 4.5, the 14 published pairs to two decimals and the 25 degree hue gap from app.css, with one planted failure per check"
    requirement: "A11Y-01"
    verification:
      - kind: cli
        ref: "node examples/scrypath_ecommerce/contrast-checker.mjs (PASS, thinnest 4.58) and --self-test"
        status: pass
      - kind: integration
        ref: "mix verify.repository_contracts (157 tests; includes the clone tests that mutate the muted token, a dark label pair and the manifest)"
        status: pass
    human_judgment: false
  - id: D3
    description: "DESIGN-TOKENS.md and DESIGN.md describe the brand palette and hold no retired value; their allowlist entries are removed"
    requirement: "SKIN-01"
    verification:
      - kind: unit
        ref: "token test live deny-list scan and allowlist entries (ceilings 15 entries, 252 hits)"
        status: pass
      - kind: integration
        ref: "scrypath_ops design_tokens_contract_test.exs and shell_chrome_token_contract_test.exs (16 tests)"
        status: pass
    human_judgment: false

duration: 1h20m
completed: 2026-11-19
status: complete
---

# Phase 187 Plan 03: Brand palette and contrast proof Summary

**Both ScrypathOps themes now use the plum and orchid palette with seven new roles and opaque muted text, and the contrast checker proves every brand pair (56 text pairs, Control Edge, primary, button labels, the book's 14 published pairs and the Failed/Retrying hue gap) from the stylesheet.**

GATE-02: this is a rendered-UI plan. Colors changed on every screen; shapes, status wording and layout are untouched (later plans). The retained preview was not touched.

`requirements-completed` is empty: SKIN-01 and A11Y-01 are advanced here, but their browser computed-style checks (P-01, P-13, P-18) belong to Plan 10, so the orchestrator decides when to mark them.

## What was built

- **Task 1, the palette commit (`db886c03`, one commit, 11 files).** Both theme blocks carry the UI-SPEC Color table as literal hexes, exactly 20 `--color-*` variables each. New properties in both blocks: `--ops-sunken`, `--ops-selected`, `--ops-control-edge`, `--ops-status-failed|retrying|pending|clear`. `--ops-text-muted` is `#5e5360` light and `#bbaac0` dark. `--color-primary-strong` is deleted from both blocks, the token map, the DTCG mirror and the example theme JS; its one consumer (`.bg-primary.text-primary-content`) points at `--color-primary`. `--ops-surface-2` takes the Selected hex per theme as an interim value. The token map has 43 rows (strong-primary row out, seven in), the eight info/success/warning/error cells per theme are local LD-1 targets with reasons, and every non-retire cell is applied, leaving exactly the two retire cells of `--ops-surface-2` pending. The built CSS was rebuilt with the Tailwind binary. The DTCG mirror (`ops.light`, `ops.dark`) and `daisyui-theme.example.js` were regenerated from the new blocks with throwaway scripts kept outside the repository, then hand-checked (every diff hunk is under `ops`, 43 entries per theme, none for the strong-primary token). The contrast checker's Guard 1 locks 20 and drops the strong-primary requirement, its self-test fixture is a 20-token fixture plus a planted 21st and a planted missing token, the named-muted tracking in Guard 2 is replaced by the opaque-token guard, and all 46 named-token entries are deleted from `MUTED_PAIRS` (57 to 11). `ops-sunken` and `ops-selected` were added to the checker's `surfaces` list only. The two root pins now mutate the live opaque muted hex.
- **Task 2 (`2b7166f2`).** `checkBrandTextPairs`, `checkNonTextPairs`, `checkPublishedPairs` and `checkStatusHueGap`, wired into the normal run (any failure is an AA failure and exits non-zero), data in `contrast-pairs.mjs` (`BRAND_PAIR_MATRIX`, `PUBLISHED_PAIR_BINDINGS`, property names only, still zero hex literals). The run prints `Brand pairs: 56 text, 22 non-text, 28 published (14 pairs)`, the hue gaps and the thinnest text pair. The self-test plants one failure per check: a text role below 4.5, a Control Edge below 3.0, a binding on the wrong custom property, a published pair with no binding (plus a binding naming no published pair), and a Retrying hue within 25 degrees of Failed.
- **Task 3 (`ea5bc23f`).** `DESIGN-TOKENS.md` now holds the 20 color variables with light and dark values, the 60/30/10 table, the Accent and Failed reserved lists, the alpha policy, the contrast checks, the new surface/selection/control-edge/status roles and a "Retired in Phase 187" list (names only). `DESIGN.md` describes the plum/orchid roles, the System-default rule and the type scale Plan 02 shipped. Both are free of retired values, so both allowlist entries are gone.
- **Format fix (`2749a861`).** Whitespace only (see Deviations 2).

## Numbers

Contrast (from the live stylesheet, unrounded compare): 56 text pairs all at or above 4.5; thinnest is Retrying on Selected Page (light) at **4.58**. Failed/Retrying hue gap 29.2 degrees light and 30.0 degrees dark (floor 25). 22 non-text pairs and all 28 published pair values reproduce.

Ceilings (all exact; the test printed each number):

| Ceiling | Before | After |
|---|---|---|
| `PENDING_CEILING` | 38 | 2 |
| `HEX_OUTSIDE_CEILING` | 34 | 0 |
| `ALLOWLIST_CEILING` | 17 | 15 |
| `HITS_CEILING` | 471 | 252 (301 at the palette commit, 252 after Task 3) |
| `app.css` `max_hits` | 34 | 4 |
| built CSS `max_hits` | 51 | 4 |
| `brandbook/` `max_hits` | 270 | 177 |
| `DESIGN.md` entry | 7 | removed |
| `DESIGN-TOKENS.md` entry | 42 | removed |
| `@min_token_test_calls` (wrapper floor) | 42 | 42 (no token-test case added or removed) |

The four hits left in `app.css` and the built CSS are the two glow shadow tokens, each declared twice (`@theme` and the dark media block); the plan that retires glow removes them. `MUTED_PAIRS`: 57 entries to 11 (the 11 direct `color: color-mix(...)` entries stay until Plan 08).

## Gate results (GATE_SHA `2749a861c03fd26f2a5c1b18683b7f10e5dc5bb6`, the last code commit)

| Check | Result |
|---|---|
| `node examples/scrypath_ecommerce/contrast-checker.mjs` | `Contrast check: PASS`, AA failures 0, thinnest 4.58 |
| `node examples/scrypath_ecommerce/contrast-checker.mjs --self-test` | `self-test passed` |
| `node --test --test-reporter=tap examples/scrypath_ecommerce/ui-tokens.test.mjs` | 48 pass, 0 fail |
| root `mix test` on `ui_contrast`, `ui_tokens`, `ui_literal`, `ui_tokens_helper` contract tests, `--exclude contrast_child` | 29 tests, 0 failures |
| `MIX_ENV=test mix verify.ui_tokens` | exit 0 (mirror parity both ways) |
| `scrypath_ops` `mix test` on the four ops CSS tests | 24 tests, 0 failures |
| `mix verify.repository_contracts` (escalated route, includes the `contrast_child` clone tests) | 157 tests, 0 failures, 179 s |
| `mix verify.core --exclude integration --exclude docs_contract` | format, compile, credo, 5 properties and 1158 tests with 0 failures (103 excluded), docs, Standard Maturity Gate PASSED, no-optional-deps compile clean |
| `mix verify.ops_ui` (task-scoped database `scrypath_ops_test_187_03`) | 2 doctests, 350 tests, 0 failures |
| `git diff --name-only GATE_SHA..HEAD` after the SUMMARY commit | only `.planning/` paths |

Mutation checks I ran (scratch copy outside the repository): disabling each of the N-03, N-04, N-05 value, N-05 missing binding, N-05 hue and Guard 1 checks makes `--self-test` fail on the matching planted case; disabling the opaque-muted equality check fails the wrong-hex case. Disabling only the hex-shape test of the opaque guard stays green because the equality check also rejects an alpha mix and an eight-digit hex (defense in depth, not a gap).

Tracer note (Task 1): `type="tracer"`, no `gate="blocking-human"`, auto mode off, automated-only `<verify>`: the contrast checker and token test were re-run on the committed tree before Task 2 started (root and ops tests had passed on the identical tree): Tracer verified end-to-end, expanding.

The task-scoped database `scrypath_ops_test_187_03` was dropped afterwards (verified absent).

## Blocked gates

None. Every gate ran and passed. No Docker resource was created, so there is nothing to clean up or measure with `docker system df`; the retained preview (compose project `scrypath_ecommerce`, port 4002) was not touched.

## Deviations from Plan

**1. [Rule 1 - Bug] A comment inside the dark theme block broke an existing root test.** My first version put the explanation for the interim `--ops-surface-2` value inside the dark `@plugin` block. `ui_tokens_contract_test.exs` "review rejects inactive CSS themes and quoted theme lookalikes" wraps the whole block in `/* ... */`, so my inner comment closed it early and the validator raised "unmatched closing block". I moved the explanation above the plugin (the existing comment) and rebuilt the CSS before committing; no theme block carries a comment now. Found by the first root test run, before the palette commit.

**2. [Rule 3 - Blocking] The palette commit was not `mix format` clean.** `mix verify.core`'s format check flagged one long call in `ui_tokens_contract_test.exs`. I formatted that file and committed it separately (`2749a861`, whitespace only), then re-ran `core`, `ops_ui` and `repository_contracts` on that commit so every receipt is on the final code SHA. The palette itself is still one commit.

**3. [Rule 3 - Blocking] The `PAIR_RULES` row for `primary-content` on `primary-strong` had to go.** The plan names Guard 1 and the fixtures but not this row; with the property deleted the checker threw "Missing required token". Removed in the palette commit.

**4. The plan's `fails_when` text for the token test cannot be used literally.** It fails on output containing "stale pending claim" or "stale built CSS", but the passing run's test names ("planted stale pending claim fails", "planted stale built CSS fails") contain both strings. I checked the failure-message forms instead (`stale pending claim:` and `stale built CSS:`, with the colon), which only a real failure prints, plus `# fail 0`.

**5. `--ops-surface-2` interim values.** As planned (Selected Page, Selected Night). Recorded here because it is the one property whose value no longer matches its old meaning: its 25 consumers in `app.css` and one in `ops_ui.ex` now paint Selected until Plan 07 deletes it.

**6. DESIGN.md went slightly past the palette lines.** I also corrected its Typography paragraph (still said 24px and the system font stack after Plan 02) and its Elevation sentence about glow, both of which the new palette text would otherwise contradict. No test reads those paragraphs.

**7. `mutedFallbackOk` and the `MUTED_MIX` synthetic fixture in `ui-tokens.test.mjs` stay.** The live token is now opaque, so the live path never uses them, but they are generic planted-case fixtures and removing them would change the wrapper's case count for no gain.

### Calibration

All plan numbers held: 37 rows to 43, 38 pending cells to 2, `PENDING_CEILING` 2, 14 new-role declarations, 57 muted entries (46 named, 11 direct), allowlist counts moved as the test printed. The only plan expectation that did not match is item 4 above.

## Decisions / what later plans must know

- Do not put comments inside the two theme plugin blocks (Deviation 1). Put them above the plugin.
- `--ops-surface-2` is still declared and still consumed; Plan 07 deletes it and rewrites the surface-depth test, the `.ops-saved-search-menu__item` surface binding and the "changed focus background" clone case.
- `--ops-selection` and `--ops-theme-selection` are kept at the Selected values on purpose (pins in the shell chrome test, `phase173_shell.spec.ts` and the surface lists); v1.47 collapses them into `--ops-selected`.
- Contrast checks now fail on any text pair below 4.5 or Control Edge below 3.0, so Plan 04 to 08 changes that move a color onto a new backdrop are checked automatically. A new backdrop token has to be added to `BRAND_PAIR_MATRIX` to be covered.
- The 11 direct `color: color-mix(...)` declarations and their `MUTED_PAIRS` entries are untouched; Plan 08 converts them and retires the manifest.
- Interim visual state until the later plans land: `--color-secondary` is a quiet neutral, so anything still painting it as an accent (the unwired `.ops-copper-*` classes, two decorative gradients) looks pale; `.ops-copper-*` is wired to no template, so no screen text is affected. Info and warning tints that mix `--color-info` or `--color-warning` with transparency now mix the new palette hexes; the Plum and status alpha tints are Plan 08's removal.
- Required-gate budget unchanged at 7 of 12 (this plan adds no gate, only assertions inside existing required files).

## Known Stubs

None.

## Threat Flags

None. No router, plug, endpoint, schema or dependency change. T-187-08 (data edits hiding a mismatch): ceilings are exact in both directions and the palette, flips, ceilings, built CSS and mirror are one commit whose file list is recorded above. T-187-09 (contrast claims not backed by the stylesheet): pairs resolve custom properties from `app.css`, published pairs are read from `brand/brand.json`, and each check has a planted failure. T-187-10 (mirror drift): `verify.ui_tokens` and the root token contract test keep both-way parity; the regeneration scripts are not committed and the diff was hand-checked. No package was added.

## Self-Check: PASSED

- Files exist: this SUMMARY, the 13 modified files listed above.
- Commits are ancestors of HEAD: `db886c03`, `2b7166f2`, `ea5bc23f`, `2749a861`.
- `git show --stat db886c03` lists both theme sources, the built CSS, `token-map.json`, `ui-tokens.test.mjs`, `retired-identity-allowlist.json`, `contrast-checker.mjs`, `contrast-pairs.mjs`, the two root tests and the two `brandbook/tokens/` files in the one commit.
- `git diff --name-only 73c1e976..HEAD` touches no `STATE.md` or `ROADMAP.md`, and neither `.planning/config.json` nor `.planning/state.json` was created or staged.
