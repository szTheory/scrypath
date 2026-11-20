---
phase: 187-scrypathops-re-skin
plan: 06
subsystem: ui
tags: [icons, control-glyphs, loading, aria-busy, no-infinite-animation, refresh-button, ops-ui]

requires:
  - phase: 187-scrypathops-re-skin
    provides: plan 04 status words and the component contract file; plan 05 the outline button, the utilities-layer control rules, the toast surface on the inner alert
provides:
  - only nine control glyphs render anywhere in ScrypathOps; nav items, the Help link, Help headings, intent cards, the empty hero, flash leading icons, the refresh glyph, the Import upload glyph and the reconnect spinners render no icon
  - E-10, a scan of every quoted `hero-` literal under `lib/` against the LD-6 list (with planted failures), a rendered check that every svg sits in a named control or a sync-status shape, and a ban on icon names taken from a variable
  - loading as a literal word plus `aria-busy="true"`: the refresh button swaps `Refresh` and `Refreshing…` on `[aria-busy="true"]`, `ops_loading` shows its word over static Sunken bars, the settings check carries `aria-busy`
  - no looping animation in ops source: the spin and ops-pulse animations, their keyframes and every animated spinner class are gone
  - E-16, plus a static scan of `app.css` and `lib/` for loops, spinner classes and daisyUI loading components
  - the literal ledger equals the source scan again (the `ops_loading` inline-width row is deleted)
affects: [187-07, 187-08, 187-09, 187-10, 187-11]

actuals:
  tokens: 20700
  tasks: 2
  commits: 4

plan_head_before: 91f7f307b771d83dfa185bdc51078d960e05ffbc
plan_head_after: 37e8485fe87e00901f8f51df80c2ca76e0b19947

tech-stack:
  added: []
  patterns:
    - "a rendered Heroicon carries no name, so the rendered check classifies each svg by its nearest enclosing button or link (tag plus class or id) instead of by icon name; the name scan stays at the source"
    - "two label words share one grid cell and the stylesheet swaps them on an attribute a hook already sets, so the control keeps one width and nothing animates"
    - "an undeclared attribute passed to a component with a `:global` rest lands in the markup as a plain attribute, so a test that reads a new attr must read it from where the component renders it, not from the whole string"

key-files:
  created: []
  modified:
    - scrypath_ops/lib/scrypath_ops_web/components/layouts.ex
    - scrypath_ops/lib/scrypath_ops_web/components/core_components.ex
    - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
    - scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/help_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/search_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
    - scrypath_ops/assets/css/app.css
    - scrypath_ops/priv/static/assets/css/app.css
    - scrypath_ops/assets/css/DESIGN-TOKENS.md
    - scrypath_ops/test/scrypath_ops_web/reskin_static_contract_test.exs
    - scrypath_ops/test/scrypath_ops_web/reskin_component_contract_test.exs
    - scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/help_live_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/search_saved_searches_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs
    - scripts/ci/ui-literal-baseline.json
    - examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts
    - examples/scrypath_ecommerce/e2e/phase173_status_actions.spec.ts

key-decisions:
  - "Icons are control glyphs only: the nine LD-6 names, each inside a button or link with an accessible name; every state is said in words"
  - "Loading is a word plus aria-busy everywhere except the reconnect flashes, which keep role=alert without aria-busy because a busy live region tells assistive technology to hold its announcement"
  - "The refresh button shows both words in one grid cell, so the button keeps one width idle and busy"
  - "The Search loader keeps its existing visible words (`Running search...`) because the copy-diff allowlist does not list a change, and is no longer wrapped in aria-hidden"
  - "daisyUI's own looping components are not used anywhere in lib and a scan keeps it that way; the built stylesheet still carries their definitions"

requirements-completed: []

coverage:
  - id: D1
    description: "only the nine LD-6 control glyphs render; nav, intent cards, empty hero, Help headings, flash, counts, refresh, import and activity render none"
    requirement: "SKIN-05"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/reskin_static_contract_test.exs (E-10 source and rendered describes, with planted failures); ops_shell_contract_test.exs flash pins; control_room_live_test, help_live_test, search_live_test, search_saved_searches_test absence checks"
        status: pass
    human_judgment: false
  - id: D2
    description: "loading is a literal word plus aria-busy; the refresh button swaps its two words on aria-busy; reconnect flashes carry no spinner"
    requirement: "A11Y-03"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/reskin_component_contract_test.exs (E-16) and sync_drift_live_test.exs (checking status carries aria-busy)"
        status: pass
    human_judgment: false
  - id: D3
    description: "nothing in ops source animates infinitely; the literal ledger equals the source scan"
    requirement: "A11Y-03"
    verification:
      - kind: integration
        ref: "reskin_static_contract_test.exs (no infinite animation describe); root test/mix/tasks/ui_literal_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D4
    description: "the required mounted lane is green on this plan's code after the icon and loader change"
    requirement: "SKIN-05"
    verification:
      - kind: e2e
        ref: "mix verify.ecommerce_mounted (harness.spec.ts and operator.spec.ts): 5 passed on 4468871d"
        status: pass
    human_judgment: false

duration: 45m
completed: 2026-11-19
status: complete
---

# Phase 187 Plan 06: Icons and loading Summary

**Every icon that stood in for a word is gone (nav, headings, flash, counts, refresh, import, cards), only nine named control glyphs remain and a scan keeps it that way, and loading is now a literal word plus `aria-busy` with nothing animating or looping anywhere in ops source.**

GATE-02: this is a rendered-UI plan. Nav items, Help headings, the Control Room cards, the Search empty state, every flash, the Import button, the refresh button on four screens and the Search and Sync and index loading states changed. The retained preview (compose project `scrypath_ecommerce`, port 4002) was not touched; it stayed up and healthy throughout.

`requirements-completed` is empty on purpose, as in Plans 04 and 05: SKIN-05 and A11Y-03 are proved here at the markup, stylesheet and source level, and the required mounted lane ran green, but the computed-animation proof in a real browser (P-12, `getAnimations()` under both motion preferences) belongs to Plan 09 and the capture proofs to Plan 10. The orchestrator decides when to mark them.

## What was built

- **Task 1, icons (tracer, `b6ae8bb6`).**
  - `layouts.ex` loses the six nav icons, `nav_item_icon/1` and the Help link icon; the flash group's client toast and both reconnect flashes lose their icons. `core_components.ex` flash loses its leading info and error icons, the close glyph renders at full opacity and both close buttons carry a stable `ops-flash__close` hook; the `@doc` example no longer uses an animated icon.
  - `ops_ui.ex`: `ops_intent_card` loses its `icon` and `recommended` attrs, the "Start here" flag and the icon span; `ops_empty_hero` loses its `icon` attr and mark. `control_room_live.ex`, `search_live.ex`, `help_live.ex` follow: the five Help headings are plain `ops_heading` text (18px, 600, Hanken), the Import button is a word, the empty hero has no mark.
  - The dead CSS for those marks is deleted with them (`.ops-nav-item__icon`, `.ops-help-heading`, the intent-card icon, flag, topline, markers and recommended ring including its two dark rules, and `.ops-empty-hero__mark`).
  - E-10 in `reskin_static_contract_test.exs`: every quoted `"hero-…"` literal under `scrypath_ops/lib` must be one of the nine LD-6 names (an exact match, so `hero-x-mark-solid` fails); no `icon name={…}` may hide a name from that scan; on the six screens plus the all-statuses fixture every svg must sit inside a named control (menu, close, command hint, theme buttons, timestamp copy, code copy, icon buttons, flash close, the Saved searches disclosure, the new-tab help link) or be a sync-status shape, a `data-shape` svg exists only inside `.ops-sync-status`, and nav, counts, refresh, flash, intent card, empty hero and headings carry no icon. Planted failures prove each matcher rejects what it should. `ops_shell_contract_test.exs` now asserts the flash has no leading icon and keeps its text and close button.
- **Task 2, loading (`95399573`).**
  - `ops_refresh_button` and `ops_refresh_control` default to the outline button, render no glyph and show two words, `label` and a new `busy_label` (`Refresh`, `Refreshing…`), in one grid cell; the stylesheet swaps them on `[aria-busy="true"]`, which the existing `OpsRefreshButton` hook sets while LiveView marks the click as loading. No JS change; the server never sets `aria-busy`.
  - `ops_loading` shows its `label` word and marks its region `aria-busy="true"`; the skeleton lines are static Sunken blocks and the last one short through a `--short` class, so the `loading_bar_width` helper and its inline width are gone. The Search run loader is now just the component (the duplicate `<p>` and the `aria-hidden` wrapper are gone, so the word reaches assistive technology). The Sync and index "Checking Meilisearch settings…" status carries `aria-busy="true"`.
  - `app.css` loses the spin animation, the ops-pulse animation and keyframes and the one comment that used the word for endless iteration. `scripts/ci/ui-literal-baseline.json` loses its `ops_loading` inline-style row (32 rows to 31) and equals the source scan.
  - E-16 in `reskin_component_contract_test.exs`: the loader word, `aria-busy`, role, hidden bars, no inline style, no `animate` class, the short last bar and the one-line case; the inline variant; the refresh button and control (outline, two words, no glyph, hook attributes, the server never sets `aria-busy`, a custom busy word read from its own span); the stylesheet swap, shared grid cell and the hook's `setAttribute("aria-busy", "true")`; static Sunken bars with no animation; the reconnect flashes. The static contract file gains the "no infinite animation in source" describe: `app.css` has no loop, spin or pulse (and the built stylesheet has no ops-authored loop), `lib/` has no animated spinner class (including docs), no screen renders an `animate` class, and no template uses a daisyUI loading, skeleton or progress component.
- **Advisory spec follow-ups (`4468871d`, `37e8485f`).** The shell-chrome flash case expects no leading icon and one close glyph; the Search health refresh case checks press feedback by transform (hover and press now share the Sunken fill), the two words, no glyph and no keyframe or looping animation under both motion preferences.

## Gate results (GATE_SHA `37e8485fe87e00901f8f51df80c2ca76e0b19947`, the last commit touching non-`.planning` files)

`4468871d` is the last commit that touched anything but one advisory Playwright spec; `37e8485f` changes only `examples/scrypath_ecommerce/e2e/phase173_status_actions.spec.ts`. Nothing in the root or ops suites reads that file and the mounted lane runs only `harness.spec.ts` and `operator.spec.ts`, so `verify.ops_ui`, `verify.core` and `verify.ecommerce_mounted` were not rerun on `37e8485f`; `verify.repository_contracts` was. Commits after GATE_SHA touch only `.planning/`.

| Check | Run on | Result |
|---|---|---|
| `node examples/scrypath_ecommerce/contrast-checker.mjs` | final stylesheet | `Contrast check: PASS`, AA failures 0, thinnest text pair 4.58 (Retrying on Selected Page); no stale manifest entry |
| `node --test --test-reporter=tap examples/scrypath_ecommerce/ui-tokens.test.mjs` | final stylesheet | 50 tests, 0 fail; ceilings and `@min_token_test_calls` (44) did not move |
| root `mix test` on `workflow_wiring`, `ui_contrast`, `ui_tokens`, `ui_tokens_helper`, `ui_literal` contract tests, `--exclude contrast_child` | after the ledger edit | 102 tests, 0 failures (the literal ledger equals the source scan; it failed first with `inline-style … count 1 exceeds 0` before the row was deleted) |
| Task 1 verify (static, shell, Help, Control Room tests, plus Search and saved-search tests) | Task 1 tree | 120 tests, 0 failures |
| Task 2 verify (component contract, static, motion, posture, Sync and index, Search tests) | Task 2 tree | 216 tests, 0 failures |
| `mix verify.ops_ui` (task-scoped database `scrypath_ops_test_187_06`) | `4468871d` | 2 doctests, 487 tests, 0 failures, exit 0 (ops suite grew 450 to 487; the `start_async` assigns warnings come from untouched `sync_drift_live.ex:541`) |
| `mix verify.core --exclude integration --exclude docs_contract` | `4468871d` | format, workspace cleanliness, credo, 5 properties and 1158 tests with 0 failures (103 excluded), docs, Standard Maturity Gate PASSED, no-optional-deps compile clean, exit 0 |
| `mix verify.repository_contracts` (escalated route per AGENTS.md) | `4468871d`, then `37e8485f` | 157 tests, 0 failures, 301.7 s; 157 tests, 0 failures, 210.1 s |
| `mix verify.ecommerce_mounted` (`E2E_PROJECT_NAME=p187_plan06_mounted`, `E2E_DOCKER_TIMEOUT_SECONDS=2700`, `BUILDX_CONFIG=/private/tmp/scrypath187-buildx`) | `4468871d` | `Docker verifier passed (scope=focused)`: 5 passed (3 `harness.spec.ts`, 2 `operator.spec.ts`); dependency-boundary proof passed for test and prod; `Verifier ownership: project=p187_plan06_mounted containers=0 networks=0 volumes=0 cleanup=clean` |
| advisory pins on a disposable stack (`COMPOSE_PROJECT_NAME=p187_plan06_pins`, lane 4102): `admin_shell_chrome` flash cases, `phase173_status_actions` mounted refresh case | `4468871d` tree, spec refined in `37e8485f` | flash cases 6 passed; the refresh case first failed because the busy button had two finite colour transitions running, then passed after the check was narrowed to keyframe and looping animations |
| broader advisory run on the same stack (`phase173_status_actions`, `ui_followup`, `settings_layout`, `ui_iteration3`, `phase173_shell`, `--grep-invert standalone`) | `37e8485f` tree | 25 passed, 5 failed; the 5 are the ones Plan 05 already recorded as not its own (see below) |
| `git diff --name-only 37e8485f..HEAD` after the SUMMARY commit | n/a | only `.planning/` paths |

Tracer note (Task 1): `type="tracer"`, no `gate="blocking-human"`, auto mode off, `<verify>` automated only. The Task 1 verify command passed on the tree that became the Task 1 commit (120 tests, 0 failures, with Search and saved-search tests added); Tracer verified end-to-end, expanding.

RED before GREEN: each task's tests were written first. Task 1's new tests failed for the right reason (22 failures: icons present, `hero-arrow-path` literals, an old flash svg count). Task 2's tests failed (7 plus the stale ledger and the sync-drift pin). One new test passed by accident (the custom busy-word case) because an undeclared `busy_label` attribute fell into the button's global attributes; I rewrote it to read the word from its own span.

### Advisory failures that are not from this plan

The 5 failures in the broader advisory run are the same cases Plan 05 recorded: `phase173_shell.spec.ts` 181 (three mounted floor-color cases) and 290 still assert the pre-Plan-03 floor colors, and `ui_followup.spec.ts:13` hits a strict-mode locator that resolves to two copies of one timestamp (Plan 04's facts line plus the source group). I did not change them. Plans 09 and 10 should repair or retire them. Standalone cases were excluded because the plain stack has no `standalone_ops` service.

### Docker cleanup

Every resource I created used a `p187_plan06_*` name (`p187_plan06_mounted` from the verifier, `p187_plan06_pins` for the advisory stack on lane 4102). The retained preview (`scrypath_ecommerce`, port 4002) stayed up and healthy (`Up 5 hours (healthy)`) and was never addressed. After the work: no `p187*` container, network, volume or image remains (I removed the two lane images the verifier leaves behind and the pins image through `down --rmi local -v`), and `scrypath_ops_test_187_06` is dropped. `docker system df` before and after: images 315 / 120.3GB and 315 / 120.3GB, containers 109 and 109, local volumes 384 and 384 (40.09GB both). Build cache went from 265 entries / 17.43GB to 297 / 18.97GB; the daemon's cache is shared with other projects, so I did not prune it.

## Numbers and calibration

The plan's grep facts were from an older HEAD and were re-derived: quoted Heroicon literals outside the LD-6 list were 20 at this plan's base, not 37 (Plans 04 and 05 had already removed the verdict, count and activity icons), all gone now. `animate-spin` in `lib/` was 3 and is 0; `infinite` in `app.css` 3 and 0; `ops-pulse` 2 and 0; `aria-busy` in `ops_ui.ex` 0 and 5; `nav_item_icon` 6 and 0; `opacity-40` in `core_components.ex` 1 and 0. `MUTED_PAIRS` stays at 9 direct entries and `FOCUS_BINDINGS` at 10; the two `MUTED_PAIRS` entries for `.ops-intent-card__summary` and `.ops-empty-hero__body` kept their `color:` declarations, as the plan said. `@min_token_test_calls` stays 44 (no token-test case added or removed). The literal ledger went from 32 to 31 rows.

## Deviations from Plan

**1. [Judgement] The intent-card `recommended` attr and the `.ops-intent-card--recommended` rules were removed with the flag.** The plan says to remove the "Start here" flag. No caller passes `recommended`, and the class only existed to ring the card the flag marked. Its light rule and its two dark rules (the Plum ring plus `--shadow-ops-glow`) are deleted, which also removes one dark glow consumer Plan 07 would have deleted. `motion_contract_test.exs` only pins the `.ops-object-item-active` glow, which is untouched, and `DESIGN-TOKENS.md` no longer lists the recommended card as a glow anchor. The `badge` slot stays and renders only when used.

**2. [Judgement] E-10's rendered check classifies each svg by its enclosing control, not by icon name.** A rendered Heroicon carries no name, so the name scan lives at the source and the rendered check proves every svg sits in a named control or a status shape. To make the flash close buttons identifiable I added an `ops-flash__close` class to both. I also added a ban on `icon name={…}` so no name can hide from the scan (nothing used one).

**3. [Judgement] The Search loader keeps its visible words `Running search...`.** The UI-SPEC lists `Running search…` (ellipsis character) only in the Motion section, and the copy-diff allowlist does not list a change to that string, so I kept the existing text, moved it into `ops_loading` and removed the `aria-hidden` wrapper that hid it from assistive technology. If the owner wants the ellipsis character, it is a one-string change and the allowlist needs the new string.

**4. [Judgement] Reconnect flashes carry no `aria-busy`.** The plan's loading words include `Attempting to reconnect`. Setting `aria-busy="true"` on a `role="alert"` region tells assistive technology to hold announcements, which would silence the message the flash exists to deliver. They keep their text, their role and no spinner; a test pins the absence so it is a recorded decision, not an omission.

**5. [Judgement] Both refresh words share one grid cell.** The plan says to swap the words on `aria-busy`. Showing one and hiding the other with `display: none` would make the button resize when it goes busy; stacking them in one cell and switching `visibility` keeps one width (the wider word's) and nothing reflows. `visibility: hidden` keeps the idle word out of the accessibility tree and `innerText`. The button also gained a `busy_label` attr (default `Refreshing…`) and its default variant is now the outline one (the plan said outline; Plan 05 had left it ghost).

**6. [Judgement] The stylesheet half of the "no infinite animation" check landed with Task 2.** Task 1's verify command runs the static contract file and the stylesheet still held its loops until Task 2, so Task 1's commit carries only the `lib/` scan and the pattern test (its icon removals also removed the three animated spinner classes). The stylesheet scan, the rendered `animate` check and the daisyUI component scan arrived with Task 2's CSS change.

**7. [Judgement] The built stylesheet still holds daisyUI's own loops.** Three `infinite` hits remain in `priv/static/assets/css/app.css`, from daisyUI's `.progress` and `.skeleton` component definitions, which no ScrypathOps markup renders. The plan's acceptance targets the source stylesheet and `lib/`, so I did not fight the vendor output; instead a test now fails if any template uses a daisyUI `loading`, `skeleton` or `progress` class, and the built-stylesheet check covers the two ops-authored loops. P-12 in Plan 09 proves the browser has no running animation.

**8. [Rule 1 - Bug] My first advisory refresh check was too strict.** It asserted no running animation of any kind while the button was busy; the real browser had two finite colour transitions (the disabled-state change). The check now fails only on a CSS keyframe animation or an infinite effect, which is what the rule actually bans. Plan 09's P-12 should make the same distinction.

**9. [Judgement] Tests landed beside their fixtures as well as in the two contract files.** E-10's absence checks for the intent cards, Search empty hero, Import button and Help headings live in the LiveView tests that own those fixtures (`control_room_live_test`, `search_live_test`, `search_saved_searches_test`, `help_live_test`); the source and rendered-screen scans are in `reskin_static_contract_test.exs`. No new test file, no new required gate (budget stays 8 of 12).

## Notes for later plans

- Plan 07: the `.ops-intent-card--recommended` rules are already gone. The `.ops-object-item-active` dark glow rules and `.ops-route-mark` glow are still there (and still pinned by `motion_contract_test.exs`); `.ops-intent-card:hover` still lifts with `--shadow-ops-raised` and a Plum alpha border.
- Plan 08: `.ops-loading__label` uses `--ops-text-muted`, but `ops_loading`'s inline variant still carries `text-base-content/65`, and the theme-toggle glyphs (`opacity-75`) and `.ops-time__affordance` (`.45`) still carry alpha; those belong to the alpha sweep. The Search loader text moved from `text-base-content/70` to the muted token.
- Plan 09: P-12 should filter to CSS keyframe animations and infinite effects (finite colour transitions are normal), and should read the refresh button's words from `[data-ops-refresh-label]`.
- Plan 10: expect the refresh button to be wider than a bare `Refresh` (it reserves room for `Refreshing…`), narrower than before only by the glyph; the copy check should see `Refresh` idle and `Refreshing…` in the busy state only (`innerText`), and `Running search...` unchanged.
- The two required-lane specs use the buttons' `aria-label`s, which did not change.

## Known Stubs

None.

## Threat Flags

None new. T-187-16 (a loader that looks busy but hides a loop): E-16 renders the loader and the refresh button, the stylesheet and `lib/` are scanned for loops, spinner classes and daisyUI loading components, and the advisory browser check found no keyframe or looping animation on the busy button; the browser proof for every loader is Plan 09's P-12. T-187-17 (non-control icons reintroduced): E-10 fails on any quoted `hero-` name off the list, any icon name taken from a variable, and any rendered svg outside a named control, each with a planted failure. T-187-SC: no package was added.

## Self-Check

PASSED

- Files exist: this SUMMARY and the 21 files listed under `key-files` (checked with `[ -f ]`); no file was created by this plan except the SUMMARY.
- Commits are ancestors of HEAD: `b6ae8bb6`, `95399573`, `4468871d`, `37e8485f`; `git rev-list --count 91f7f307..HEAD` measures 4 before this SUMMARY.
- Acceptance greps at their expected values: non-allowlisted `hero-` literals 0, `nav_item_icon` 0, `opacity-40` in `core_components.ex` 0, `animate-spin` in `lib/` 0, `infinite` in `app.css` 0, `ops-pulse` in `app.css` 0, `aria-busy` in `ops_ui.ex` 5.
- `git diff --name-only 91f7f307..HEAD` touches no `STATE.md` or `ROADMAP.md`, and neither `.planning/config.json` nor `.planning/state.json` was created or staged.
