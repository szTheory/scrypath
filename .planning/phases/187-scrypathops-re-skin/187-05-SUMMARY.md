---
phase: 187-scrypathops-re-skin
plan: 05
subsystem: ui
tags: [buttons, destructive-confirms, row-actions, selection-signature, control-edge, focus, scroll-padding, overlays, scrim, ops-ui]

requires:
  - phase: 187-scrypathops-re-skin
    provides: plan 03 palette, status tokens and `--ops-control-edge`, `--ops-sunken`, `--ops-selected`; plan 04 status vocabulary, notice surface, the component contract file
provides:
  - one Plum button per scope: the danger variant and the error button class are gone, `:secondary` reads like the default outline button
  - destructive confirms named by consequence with Cancel focused (`Retry deleting N document(s)`, `Replace live index with target`, `Delete saved search permanently`)
  - row actions (`Retry`, `Load`, `Rename`, `Export`, `Delete`, the Sync and index activity links) as one underlined Ink text style; prose links Plum and underlined at rest
  - the Selection Signature (2px Plum line on the Selected fill, reserved at rest) on every selected or current element, replacing the nav glow
  - opaque Control Edge on every control, Sunken hover fills
  - inset focus ring inside table scrollers, `--ops-header-h` and scroll padding under the sticky header
  - overlays as Panel with a Control Edge border and the overlay shadow; one black 50 percent scrim
  - N-09 in the token test, with planted failures
affects: [187-06, 187-07, 187-08, 187-09, 187-10, 187-11]

actuals:
  tokens: 25100
  tasks: 3
  commits: 6

plan_head_before: 8b71e2d216fb351c97f4643d8f38b8a15dd34e0a
plan_head_after: 6e36ee4112d6d4f487ea114a76a4c4192d829b3f

tech-stack:
  added: []
  patterns:
    - "daisyUI sets .btn, .input, .select, .textarea and .modal colors in the `utilities` layer, so Control Edge, Sunken hover, the Plum underline and the modal backdrop are authored in a later `@layer utilities` block, not the components layer"
    - "one shared unlayered rule lists every Selection Signature selector; the resting rules reserve the 2px start edge"
    - "the sticky header height is one custom property scoped by `html:has(.ops-shell)`"

key-files:
  created: []
  modified:
    - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
    - scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/search_live.ex
    - scrypath_ops/assets/css/app.css
    - scrypath_ops/priv/static/assets/css/app.css
    - scrypath_ops/assets/css/contrast-pairs.mjs
    - scrypath_ops/assets/css/DESIGN-TOKENS.md
    - scripts/ci/ui-literal-baseline.json
    - examples/scrypath_ecommerce/ui-tokens.test.mjs
    - examples/scrypath_ecommerce/e2e/operator.spec.ts
    - examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts
    - examples/scrypath_ecommerce/e2e/ui_baseline.spec.ts
    - examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts
    - scrypath_ops/test/scrypath_ops_web/reskin_component_contract_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/search_saved_searches_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs
    - scrypath_ops/test/scrypath_ops_web/design_tokens_contract_test.exs
    - scrypath_ops/test/scrypath_ops_web/shell_chrome_token_contract_test.exs
    - test/mix/tasks/ui_contrast_contract_test.exs

key-decisions:
  - "A destructive confirm is the dialog's one Plum button, named by its consequence, with Cancel as initial focus; no danger fill exists anywhere"
  - "daisyUI colors live in the utilities layer, so every button, input and modal color override is authored in a later utilities block"
  - "A bordered control keeps its opaque Control Edge on the start side at rest (only the width is reserved); elements with no resting border reserve a transparent 2px"
  - "The toast surface is the inner `.alert`, so the Panel fill, edge, 2px rule and overlay shadow sit on one element instead of two nested boxes"
  - "The `.ops-object-item-active` dark glow rules stay until Plan 07, because `motion_contract_test.exs` pins them and Plan 07 deletes the glow family and rewrites that test"

requirements-completed: []

coverage:
  - id: D1
    description: "danger variant and error button class removed; one Plum button per page and per open dialog or sheet"
    requirement: "SKIN-04"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/reskin_component_contract_test.exs (E-07) and the failed sync, sync and index, saved-search and Control Room LiveView tests"
        status: pass
    human_judgment: false
  - id: D2
    description: "three destructive confirm labels, Cancel focused in both sync dialogs, required-lane pin and three advisory pins follow the labels"
    requirement: "SKIN-04"
    verification:
      - kind: integration
        ref: "failed_sync_live_test.exs, sync_drift_live_test.exs, search_saved_searches_test.exs (E-08); operator.spec.ts confirm locator"
        status: pass
    human_judgment: false
  - id: D3
    description: "row actions share one underlined style; prose links Plum and underlined at rest"
    requirement: "SKIN-04"
    verification:
      - kind: integration
        ref: "reskin_component_contract_test.exs (E-09 and stylesheet describes); throwaway Chromium probe of computed styles in both themes"
        status: pass
    human_judgment: false
  - id: D4
    description: "Selection Signature, Control Edge and Sunken hover on every selected, current and control element"
    requirement: "A11Y-01"
    verification:
      - kind: integration
        ref: "reskin_component_contract_test.exs (Selection Signature and control edge); design_tokens and shell_chrome token tests; node examples/scrypath_ecommerce/contrast-checker.mjs"
        status: pass
    human_judgment: false
  - id: D5
    description: "inset focus ring in table scrollers, scroll padding below the sticky header, overlays and one scrim"
    requirement: "A11Y-02"
    verification:
      - kind: unit
        ref: "examples/scrypath_ecommerce/ui-tokens.test.mjs (live scroll padding clears the sticky header, planted missing scroll padding fails); contrast checker FOCUS_BINDINGS entry with a mutation check"
        status: pass
    human_judgment: false

duration: 1h 5m
completed: 2026-11-19
status: complete
---

# Phase 187 Plan 05: Buttons, actions, selection, focus and overlays Summary

**Every destructive confirm is now the dialog's single Plum button named by what it does, row actions and prose links are underlined, every selected or current element carries one 2px Plum line, every control has an opaque edge, table scrollers keep their focus ring, the page scrolls focus below the sticky header, and overlays share one Panel surface and one scrim.**

GATE-02: this is a rendered-UI plan. Buttons, row actions, links, selection marks, control borders, focus, overlays and the modal scrim changed on all six screens. The retained preview (compose project `scrypath_ecommerce`, port 4002) was not touched.

`requirements-completed` is empty on purpose: SKIN-04, A11Y-01 and A11Y-02 are proved here at the HTML and stylesheet level, and I also checked the computed styles in headless Chromium with a throwaway probe (see "Browser check" below). The committed browser proofs (P-04 to P-10, P-16, P-21) belong to Plan 10. The orchestrator decides when to mark them.

## What was built

- **Task 1, destructive confirms and the one-Plum rule (tracer, `63bdfb45`).**
  - `ops_ui.ex` no longer has a danger variant: the four button `values:` lists, the `button_classes` branch and the `ops_action_group` tone list drop it, and `:secondary` renders the default outline button. The segmented control's selected option has no primary fill.
  - Retry-delete confirm reads `Retry deleting 1 document` / `Retry deleting 3 documents`; one helper (`document_count_label/1`) also builds the description and the count line. The promotion confirm reads `Replace live index with target` (the page trigger stays `Promote target index`, outline), and the saved-search delete confirm reads `Delete saved search permanently`. Both sync dialogs set `initial_focus="[data-ops-modal-cancel]"`. Cancel and Rename moved from ghost or Plum to the outline button.
  - `operator.spec.ts` (required lane), `admin_shell_chrome.spec.ts`, `ui_baseline.spec.ts` and `admin_surface_depth.spec.ts` follow the new labels in the same commit. No other spec or helper had a hit outside the overlay helper, which already accepts both labels.
  - E-07 and E-08 tests: component attr lists, page-scope Plum counts for all six routes, one Plum button inside each open dialog, the exact labels, `data-ops-modal-initial-focus`, Cancel present and outline.
- **Task 2, actions, links, selection and control edges (`639db84d`).**
  - `.ops-text-action` is one rule (14px 600 Ink, underlined at rest 1px offset `.2em`, 2px on hover, 40px target, muted when disabled). The three Help overrides, the `.ops-sync-work` override, `.ops-sync-activity-link` and the red destructive row-action rule are gone. Failed sync `Retry` is a `<button class="ops-text-action">` with its test id and events; Load, Rename, Delete are text buttons, Export is `<a download class="ops-text-action">`, and the Sync and index activity and related links use the same class. Load carries `disabled` and `aria-disabled="true"` when it cannot run.
  - Prose links (`a.link`, `.link-primary`, `.ops-help-link`, handoff link, help topic links) are Plum (Orchid in dark) and underlined at rest; the Ink `a.link-primary` and `a.link:not(...)` overrides are deleted.
  - One shared unlayered rule draws `border-inline-start: 2px solid var(--color-primary)` on `.ops-nav-item-active`, `.ops-nav-item[aria-current="page"]`, the loaded saved-search row, `.ops-object-item-active`, the selected filter chip, the checked schema option, pressed segmented and theme-toggle buttons and the active palette item. Each resting rule reserves the 2px so selection never moves layout. The current nav item and active palette item take Plum or Orchid text; the dark nav glow is deleted. The loaded saved-search row and the active object item carry `aria-current="true"`.
  - Buttons: Panel fill, Ink text, opaque Control Edge border, no shadow; hover and press `--ops-sunken`; the Plum button underlines on hover and keeps its fill; disabled is muted and opaque. Inputs, selects, textareas, checkboxes, radios, chips, command hint, nav trigger and close, the theme toggle and the time zone select use `--ops-control-edge`.
- **Task 3, focus, scroll padding and overlays (`da33defe`).**
  - `.ops-table-scroll :focus-visible` draws the ring inward (offset `-2px`) and is bound in `FOCUS_BINDINGS`; `--shadow-ops-focus` is deleted.
  - `--ops-header-h` is 4rem (7rem at 640px and below) and `html:has(.ops-shell)` sets `scroll-padding-top: calc(var(--ops-header-h) + 1rem)`; the header's `min-height` uses the variable; Help's two scroll-margin rules are gone.
  - `.modal-box`, `.ops-sheet__panel`, `.ops-cmdk__panel`, `.ops-mobile-nav__panel` and `.ops-flash > .alert` are `--color-base-100` with a 1px Control Edge border and `--shadow-ops-overlay`; the toast keeps a 2px start rule (neutral info, Failed error) and no tint. Sheet, palette, drawer and modal backdrops are `color-mix(in oklch, var(--color-black) 50%, transparent)`, the dark-only drawer scrim is gone, and the stale `.ops-sheet__backdrop` `#000` ledger row is deleted.
  - N-09 in `ui-tokens.test.mjs`: "live scroll padding clears the sticky header" plus "planted missing scroll padding fails" (missing rule, hard-coded value, missing narrow override, detached header height, Help scroll margin, commented-out rule).
- **Docs, floor and one advisory pin (`0babf3f2`, `8311f517`, `6e36ee41`).** `DESIGN-TOKENS.md` drops the danger tone, the reserved focus shadow and the nav glow and documents the one-Plum rule, row actions, the Selection Signature, overlays and the header height. `@min_token_test_calls` is 44 (two N-09 cases added). The advisory shell-chrome flash cases now read the toast surface from the inner alert (see Deviation 4).

## Browser check (throwaway, not committed)

I ran two scratch probes in headless Chromium against the rebuilt stylesheet (light, dark, 1280 and 390 wide; scripts in the session scratchpad, not in the repo). They confirmed: default and disabled buttons computed Panel fill, Ink or muted text and the opaque edge in both themes; Sunken hover; Plum hover underline with the fill unchanged; text actions computed one tuple (Hanken, 14px, 600, Ink, underline) with a 40px target and 2px hover; prose links Plum and Orchid; every Selection Signature element computed a 2px primary start line with the Selected fill and its unselected twin the same 2px transparent (or Control Edge on the chip); inputs, checkboxes and the command hint computed the opaque edge (the daisyUI alpha border was winning until I moved the override into the utilities layer); overlays computed Panel plus edge plus overlay shadow; scrims computed black at 0.5; `html` scroll padding was 80px at 1280 and 128px at 390; a focused link inside `.ops-table-scroll` computed `outline-offset: -2px`. These are evidence for the later P checks, not a replacement for them.

## Gate results

GATE_SHA is `6e36ee4112d6d4f487ea114a76a4c4192d829b3f`, the last commit touching non-`.planning` files. It differs from the SHA four of the gates ran on (`8311f517d4d9b804ed5609b2ccff5ae828e2acde`) by one file, the advisory Playwright spec `examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts`. No root or ops test reads that file and the mounted lane runs only `harness.spec.ts` and `operator.spec.ts`, so `verify.ops_ui`, `verify.core` and `verify.ecommerce_mounted` were not rerun; `verify.repository_contracts` was, on GATE_SHA. Commits after GATE_SHA touch only `.planning/`.

| Check | Run on | Result |
|---|---|---|
| `node examples/scrypath_ecommerce/contrast-checker.mjs` | `da33defe` (stylesheet and manifest final) | `Contrast check: PASS`, AA failures 0, thinnest text pair Retrying on Selected Page 4.58; the new `FOCUS_BINDINGS` entry is evaluated (a planted `-3px` offset prints `Stale focus binding .ops-table-scroll :focus-visible` and fails) |
| `node --test --test-reporter=tap examples/scrypath_ecommerce/ui-tokens.test.mjs` | `da33defe` | 50 tests, 0 fail, including "live scroll padding clears the sticky header"; ceilings did not move |
| root `mix test` on `workflow_wiring`, `ui_contrast`, `ui_tokens`, `ui_tokens_helper`, `ui_literal` contract tests, `--exclude contrast_child` | `da33defe` | 102 tests, 0 failures (the literal ledger equals the source scan) |
| `scrypath_ops` focused ExUnit for each task (contract, token, shell, LiveView files) | each task commit | 0 failures; whole ops suite grew 412 to 450 tests |
| `mix verify.ops_ui` (task-scoped database `scrypath_ops_test_187_05`) | `0babf3f2` and `8311f517` | boundary 2 tests; 2 doctests, 450 tests, 0 failures, exit 0 (the Postgres `too_many_connections` lines in the log come from other projects sharing the server) |
| `mix verify.repository_contracts` (escalated route per AGENTS.md) | `8311f517`, then `6e36ee41` | 157 tests, 0 failures, 316.1 s; 157 tests, 0 failures, 307.9 s |
| `mix verify.core --exclude integration --exclude docs_contract` | `8311f517` | format, clean workspace, warnings-as-errors compile, credo, 5 properties and 1158 tests with 0 failures (103 excluded), docs with warnings as errors, Standard Maturity Gate PASSED, exit 0 |
| `mix verify.ecommerce_mounted` (`E2E_PROJECT_NAME=p187_plan05_mounted`, `E2E_DOCKER_TIMEOUT_SECONDS=2700`, `BUILDX_CONFIG=/private/tmp/scrypath187-buildx`) | `8311f517` | `Docker verifier passed (scope=focused)`: 5 passed (3 `harness.spec.ts`, 2 `operator.spec.ts` including the promotion test with `Replace live index with target`); the verifier reports `containers=0 networks=0 volumes=0 cleanup=clean` |
| three advisory confirm-label pins on a disposable stack (`docker compose -p p187_plan05_pins`, lane 4102): `admin_shell_chrome` Manage sheet focus lifecycle, `admin_surface_depth` "Saved search management keeps focus on visible names", `ui_baseline` "a saved search with options the form can't show" | `8311f517` | 3 passed |
| `npx playwright test e2e/operator.spec.ts e2e/admin_shell_chrome.spec.ts e2e/ui_baseline.spec.ts e2e/admin_surface_depth.spec.ts --list` | `639db84d` | 85 tests in 4 files, no error |
| `git diff --name-only 6e36ee41..HEAD` after the SUMMARY commit | n/a | only `.planning/` paths |

Tracer note (Task 1): `type="tracer"`, no `gate="blocking-human"`, auto mode off, `<verify>` automated only. I reran the Task 1 verify command on the committed Task 1 tree (164 tests, 0 failures) and listed the four specs; Tracer verified end-to-end, expanding.

RED before GREEN: each task's new tests were written first and failed for the stated reason (9 failures after Task 1's tests, none passing by accident). Mutation checks: a wrong `FOCUS_BINDINGS` offset fails the contrast checker, and a computed-style probe in Chromium caught two real CSS-layer mistakes before commit (disabled default button and input borders lost to daisyUI's utilities-layer rules).

### Broader advisory run (not a gate; the cases this plan can affect)

I ran five advisory specs (`admin_shell_chrome`, `phase173_status_actions`, `ui_reconciliation`, `phase173_shell`, `ui_followup`) once against the disposable stack: 57 passed, 22 failed.

- **6 failures were mine** (`admin_shell_chrome.spec.ts:741`, the flash cases) and are fixed in `6e36ee41`: they read the shadow, border and fill from the outer `.ops-flash`, and the surface now sits on the inner alert. All six pass after the fix.
- **16 failures are not from this plan, as far as I checked.** The standalone cases (`phase173_shell` 181 standalone, 203, 237, 266, 323; `phase173_status_actions` 80, 202, 268; `ui_followup` standalone) need the `standalone_ops` service that only the e2e compose adds (`ERR_CONNECTION_REFUSED` and `ERR_NAME_NOT_RESOLVED` in the checked cases). `phase173_shell` 181 mounted (three cases) and 290 still assert the pre-Plan-03 floor colors (`rgb(243, 245, 248)`, `rgb(17, 20, 25)`) against the new Page and Night values (checked for the light and dark mounted cases). `ui_followup` mounted fails on a strict-mode locator that resolves to two copies of the same timestamp (Plan 04's facts line plus the source group). Plans 09 and 10 should rerun these in `mix verify.ecommerce_e2e`, where the standalone service exists.

### Docker cleanup

Every resource I created used a `p187_plan05_*` name (`p187_plan05_mounted`, `p187_plan05_pins`); the retained preview (`scrypath_ecommerce`, port 4002) stayed up and healthy for the whole run and was never stopped, rebuilt or addressed. After the work: no `p187*` container, network, volume or image remains (the lane images and the stack images were removed), and `scrypath_ops_test_187_05` is dropped. `docker system df` before and after: images 315 / 120.3GB and 315 / 120.3GB, containers 109 and 109, local volumes 384 and 384 (40.08GB and 40.09GB). Build cache went from 224 entries / 15.5GB to 265 entries / 17.43GB; the daemon's cache is shared with other projects and cannot be attributed to this task, so I did not prune it.

## Deviations from Plan

**1. [Rule 3 - Blocking] The danger value also had to leave `ops_action_group`.** The plan's acceptance count (`:danger` in `lib/` goes 9 to 0) includes the `tone` list of `ops_action_group/1`, which has no callers. It now accepts `:default`, `:secondary` and `:advanced`.

**2. [Judgement] A bordered control keeps its opaque Control Edge on the start side at rest.** The plan says resting start edges are `2px solid transparent`. That holds for the nav item, saved-search row, object item, checked schema option, segmented and theme-toggle buttons and palette item (none has a resting border of its own). The filter chip does have one, so a transparent start edge would leave one side of a control without its LD-15 edge; it reserves a 2px start edge in the Control Edge color instead (only the width differs from its other sides). The contract test asserts both forms.

**3. [Judgement] The `.ops-object-item-active` dark glow rules were left.** The UI-SPEC says the Selection Signature replaces glow shadows, but `motion_contract_test.exs` ("every dark-only path glow end state is mirrored in both dark paths") requires at least one active-path dark glow, and Plan 07 deletes the glow family and rewrites that test. Plan 05 verifies `motion_contract_test.exs`, so I removed only the light-theme tint and ring from `.ops-object-item-active` and the nav glow (whose pin I was told to rewrite). Plan 07 must delete the two dark `.ops-object-item-active` rules (they still hold a Plum 20 percent ring and `--shadow-ops-glow`).

**4. [Rule 3 - Blocking] The toast surface moved from `.ops-flash` to its inner `.alert`.** The plan names `.ops-flash > .alert` as the overlay element, but the outer `.ops-flash` also drew a border, fill and shadow (two nested surfaces). The outer wrapper now only rounds the corners; the alert carries Panel, edge, 2px rule and shadow. The pinned dark composition (overlay shadow then panel-dark) moved with it, and `shell_chrome_token_contract_test.exs` now checks `.ops-flash > .alert`. The tinted `.ops-flash--info`/`--error` backgrounds are gone with it. A real-browser run showed the advisory shell-chrome flash cases (`admin_shell_chrome.spec.ts:741`, six cases) measured the outer element, so I pointed those three style reads at the alert (`6e36ee41`); the spec's `svg` expectation for the info icon is untouched and Plan 06, which removes that icon, will need to update it.

**5. [Judgement] The handoff link is a prose link.** `.ops-handoff__link` (`Check sync and index`) was an Ink underlined link that the UI-SPEC list does not name. It is a text link in the accent list (text links, underlined at rest), so it is Plum.

**6. [Judgement] Stylesheet and tests landed beside their contracts, not only in the contract file.** The plan puts E-07 to E-09 in `reskin_component_contract_test.exs`. The contract file holds the component, stylesheet, page-scope and empty-sheet assertions. The open-dialog, label and row-action assertions live in the LiveView test files that already own the fixtures (`failed_sync_live_test.exs`, `sync_drift_live_test.exs`, `search_saved_searches_test.exs`, `control_room_live_test.exs`), because those need the delete job, prepared target index, saved-search and degraded-posture fixtures. No new test file and no new required gate.

**7. [Rule 3 - Blocking] `@min_token_test_calls` is now 44.** Two N-09 cases were added to `ui-tokens.test.mjs`; the floor follows, as the executor rules require. `MUTED_PAIRS` stays at 9 entries; `FOCUS_BINDINGS` gained one entry (10); the literal ledger lost its one raw-hex row (33 to 32 rows) and equals the source scan. Token ceilings and allowlist counts did not move (this plan removes no retired hex or rgb triplet).

**8. [Judgement] The prose-link selector avoids the text `a.link-primary`.** The acceptance count for that string is 0 and daisyUI's `.link-primary` already sets Plum, so the rule selects `.ops-shell .link-primary` and `.ops-shell a.link`.

Plan line numbers had drifted (button sites, CSS regions), as the plan said they might; every site was found by content.

## Notes for later plans

- Plan 07: delete the two `[data-theme="dark"]`/system-dark `.ops-object-item-active` rules (Plum ring plus `--shadow-ops-glow`) together with the glow family and the `motion_contract_test.exs` glow test; `.ops-route-mark` dark glow is also still there.
- Plan 06: `ops_refresh_button` is still `:ghost` by default and unstyled by Plan 05 (it is not a border-edged control yet); Plan 06 makes it outline. The info flash icon is untouched (Plan 06 owns icons).
- Plan 08 still owns the `text-base-content/NN` classes; the segmented control's unselected option keeps `text-base-content/75`. `.ops-intent-card:hover`, `.ops-result-row:hover` and `.ops-object-item:hover` keep their Plum alpha border tint (pinned by `surface_depth_token_contract_test.exs`). The saved-search menu item hover and `.ops-command-hint` background keep reading `--ops-surface-2` (their manifest entries move with Plan 07).
- Plan 10: P-07 should measure `border-inline-start` on the elements listed in the shared rule; resting twins have a 2px start edge (transparent, or Control Edge on `.ops-filter-chip`). `--border` is 1.5px, which Chromium renders as 1px on a 1x display, so P-08 should read computed colors, not widths. The `.ops-btn[aria-pressed="true"]` selector is in the shared rule but no template renders it today.
- Disabled `Load` is `disabled` plus `aria-disabled="true"` (not focusable); P-05 should exclude `.ops-text-action:disabled`.
- daisyUI places `.btn`, `.input`, `.select`, `.textarea` and `.modal` in the `utilities` layer, and `.input`, `.select`, `.textarea` set `--input-color` themselves, so a components-layer override never wins. Future control styling belongs in the utilities block near the end of `app.css`.

## Known Stubs

None.

## Threat Flags

None new. T-187-14 (destructive confirms): labels name the consequence, Cancel is present everywhere and is the initial focus in both sync dialogs, the typed-name confirm for saved-search delete is kept, and no server handler changed. T-187-15 (scroll padding leaking to a host page): the rule is `html:has(.ops-shell)` and the token test asserts that scope. T-187-SC: no package was added.

## Self-Check

PASSED

- Files exist: this SUMMARY and the 22 files listed under `key-files` (checked with `[ -f ]`; no file was created by this plan except the SUMMARY).
- Commits are ancestors of HEAD: `63bdfb45`, `639db84d`, `da33defe`, `0babf3f2`, `8311f517`, `6e36ee41`; `git rev-list --count` from the plan base measures 6.
- Acceptance greps all at their expected values: `:danger` 0, `btn-error` 0 in `lib/`, `Replace live index with target` 1 in `operator.spec.ts`, `Delete saved search permanently` 1 in `search_live.ex`, `initial_focus="[data-ops-modal-cancel]"` 1 in `sync_drift_live.ex`, `bg-primary` 0 in `ops_ui.ex`; Help `text-decoration: none` overrides 0, `a.link-primary` 0, Selection Signature line 1, `var(--ops-control-edge)` 14 (at least 5), `class="ops-text-action"` in `failed_sync_live.ex` 1; `scroll-padding-top` rule 1, `scroll-margin-top` 0, `shadow-ops-focus` 0, table focus rule 2, scrim 4 (at least 4), sheet ledger row 0, manifest entry 1.
- `git diff --name-only 8b71e2d2..HEAD` touches no `STATE.md` or `ROADMAP.md`; neither `.planning/config.json` nor `.planning/state.json` was created or staged.
