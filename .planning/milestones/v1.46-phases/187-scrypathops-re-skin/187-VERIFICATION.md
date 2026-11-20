---
phase: 187-scrypathops-re-skin
verified: 2026-11-19T23:12:40Z
status: passed
score: 5/5 must-haves verified (success criterion 5 minus two orchestrator-owned items, listed below as pending-orchestrator)
covered_files:
  - .planning/phases/187-scrypathops-re-skin/187-01-PLAN.md
  - .planning/phases/187-scrypathops-re-skin/187-01-SUMMARY.md
  - .planning/phases/187-scrypathops-re-skin/187-02-PLAN.md
  - .planning/phases/187-scrypathops-re-skin/187-02-SUMMARY.md
  - .planning/phases/187-scrypathops-re-skin/187-03-PLAN.md
  - .planning/phases/187-scrypathops-re-skin/187-03-SUMMARY.md
  - .planning/phases/187-scrypathops-re-skin/187-04-PLAN.md
  - .planning/phases/187-scrypathops-re-skin/187-04-SUMMARY.md
  - .planning/phases/187-scrypathops-re-skin/187-05-PLAN.md
  - .planning/phases/187-scrypathops-re-skin/187-05-SUMMARY.md
  - .planning/phases/187-scrypathops-re-skin/187-06-PLAN.md
  - .planning/phases/187-scrypathops-re-skin/187-06-SUMMARY.md
  - .planning/phases/187-scrypathops-re-skin/187-07-PLAN.md
  - .planning/phases/187-scrypathops-re-skin/187-07-SUMMARY.md
  - .planning/phases/187-scrypathops-re-skin/187-08-PLAN.md
  - .planning/phases/187-scrypathops-re-skin/187-08-SUMMARY.md
  - .planning/phases/187-scrypathops-re-skin/187-09-PLAN.md
  - .planning/phases/187-scrypathops-re-skin/187-09-SUMMARY.md
  - .planning/phases/187-scrypathops-re-skin/187-10-PLAN.md
  - .planning/phases/187-scrypathops-re-skin/187-10-SUMMARY.md
  - .planning/phases/187-scrypathops-re-skin/187-11-PLAN.md
  - .planning/phases/187-scrypathops-re-skin/187-11-SUMMARY.md
  - CONTRIBUTING.md
  - DESIGN.md
  - brandbook/tokens/daisyui-theme.example.js
  - brandbook/tokens/tokens.json
  - examples/scrypath_ecommerce/Dockerfile
  - examples/scrypath_ecommerce/contrast-checker.mjs
  - examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts
  - examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts
  - examples/scrypath_ecommerce/e2e/admin_shell_wash.spec.ts
  - examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts
  - examples/scrypath_ecommerce/e2e/harness.spec.ts
  - examples/scrypath_ecommerce/e2e/helpers/ui-preservation-states.ts
  - examples/scrypath_ecommerce/e2e/operator.spec.ts
  - examples/scrypath_ecommerce/e2e/ops_host_contract.spec.ts
  - examples/scrypath_ecommerce/e2e/ops_reskin_contract.spec.ts
  - examples/scrypath_ecommerce/e2e/phase173_shell.spec.ts
  - examples/scrypath_ecommerce/e2e/phase173_status_actions.spec.ts
  - examples/scrypath_ecommerce/e2e/settings_layout.spec.ts
  - examples/scrypath_ecommerce/e2e/ui-review.mjs
  - examples/scrypath_ecommerce/e2e/ui_baseline.spec.ts
  - examples/scrypath_ecommerce/e2e/ui_followup.spec.ts
  - examples/scrypath_ecommerce/retired-identity-allowlist.json
  - examples/scrypath_ecommerce/scripts/reskin-capture.mjs
  - examples/scrypath_ecommerce/scripts/reskin-capture.selftest.mjs
  - examples/scrypath_ecommerce/test/support/phase173_fixture_source.ex
  - examples/scrypath_ecommerce/ui-tokens.test.mjs
  - scripts/ci/ui-literal-baseline.json
  - scripts/ci/ui_state_pairs.test.cjs
  - scrypath_ops/README.md
  - scrypath_ops/assets/css/DESIGN-TOKENS.md
  - scrypath_ops/assets/css/app.css
  - scrypath_ops/assets/css/contrast-pairs.mjs
  - scrypath_ops/assets/css/token-map.json
  - scrypath_ops/assets/js/app.js
  - scrypath_ops/assets/js/ops_hooks.js
  - scrypath_ops/lib/scrypath_ops/posture.ex
  - scrypath_ops/lib/scrypath_ops_web/components/core_components.ex
  - scrypath_ops/lib/scrypath_ops_web/components/layouts.ex
  - scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex
  - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
  - scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/help_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/search_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
  - scrypath_ops/priv/static/assets/css/app.css
  - scrypath_ops/priv/static/assets/js/app.js
  - scrypath_ops/priv/static/favicon.ico
  - scrypath_ops/priv/static/favicon.svg
  - scrypath_ops/priv/static/images/logo.svg
  - scrypath_ops/priv/static/images/scrypath-wordmark-inverse.svg
  - scrypath_ops/priv/static/images/scrypath-wordmark.svg
  - scrypath_ops/test/scrypath_ops_web/design_tokens_contract_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/help_live_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/search_saved_searches_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs
  - scrypath_ops/test/scrypath_ops_web/motion_contract_test.exs
  - scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs
  - scrypath_ops/test/scrypath_ops_web/reskin_component_contract_test.exs
  - scrypath_ops/test/scrypath_ops_web/reskin_static_contract_test.exs
  - scrypath_ops/test/scrypath_ops_web/shell_chrome_token_contract_test.exs
  - scrypath_ops/test/scrypath_ops_web/surface_depth_token_contract_test.exs
  - scrypath_ops/test/support/phase173_fixture_source.ex
  - test/mix/tasks/ui_contrast_contract_test.exs
  - test/mix/tasks/ui_tokens_contract_test.exs
covered_digest: "v4:sha256:f4efb4a68e7c79cf2b4aa289a816b87b3a11a061c9cc24fb638e21e0fb7be406"
behavior_unverified: 0
overrides_applied: 0
pending_orchestrator:
  - "SKIN-08: one Draft PR, hosted run on the exact head SHA (every required check plus ecommerce-e2e and closeout-attestation), the one summary comment"
  - "GATE-03, second half: move the retained preview to the final head, preflight before and after, npm run ui:review inventory, UI-PREVIEW.json update"
warnings:
  - "The 12 px text floor has no static gate (mutation survived); only the browser spec P-02 in the advisory ecommerce-e2e lane proves it"
  - "Every computed-style and host-contract browser spec (P-01..P-21) runs only in the advisory ecommerce-e2e lane, not in a required check; local runs are green but were not re-run by this verification"
  - "The long gates (repository-contracts, package, ecommerce-mounted, ecommerce-e2e) last ran on 9217f326; code commits after it touched loading markup, palette close timing, the JS bundle and the capture script"
  - "No browser test asserts that Cancel is the focused element when a destructive dialog opens; the roadmap criterion is stated as DOM checks and those pass"
  - "The 12 after captures are from 9217f326, not the final code commit cf744109; the built stylesheet is unchanged since"
---

# Phase 187: ScrypathOps re-skin Verification Report

**Phase Goal:** Operators see ScrypathOps in the plum/orchid identity in light and dark with one consistent sync-status vocabulary, hosts that mount it see no change outside ops, and the maintainer receives it as one Draft PR with green gates and capture inventory, merged only on the maintainer's yes.
**Verified:** 2026-11-19T23:12:40Z
**Status:** passed (for everything that can be verified before the orchestrator opens the Draft PR; two items are pending-orchestrator and are not gaps)
**Re-verification:** No, initial verification
**Code under test:** branch `feat/v1.46-187-ops-reskin`, last code commit `cf7441092d18cedb2fca26475906725fbeb67b94` (confirmed: `git diff --name-only cf744109 HEAD` lists only two `.planning/` files). Working tree at start: only `.planning/` changes.

No tracked source file was modified by this verification. Mutation checks ran on a scratch copy outside the repository; two task-scoped test databases were dropped afterwards.

## Result in plain language

I found no failed must-have and no blocker. The re-skin is in the code, the static and server-rendered checks all pass when I run them, and every mutation I planted that maps to a requirement was caught by a gate (two survived for secondary reasons, listed under warnings). What I could not do, by instruction, is re-run the Docker and browser lanes; their results come from the executors' receipts and I say below exactly which claims rest only on that. Hosted CI has not run, the Draft PR does not exist yet, and nothing here proves the result looks good.

## Goal Achievement

### Roadmap success criteria (the contract)

| # | Success criterion | Status | Evidence I produced (not the SUMMARYs) |
|---|---|---|---|
| 1 | Brand roles in light, dark and System; no `primary-strong`, copper or glow; fonts 200 from the mount prefix at two depths with `?v=`; h1 Hanken 700 at 28 px; floor 12 px; no `uppercase`; one lockup per theme at 320 px; brand favicon; no retired path, copper, glow or infinite code; every duration a brand token | VERIFIED (static and server-rendered parts by me; computed-style parts rest on browser receipts) | Theme blocks read directly: 20 daisyUI variables each, light Page `#f8f4f2` / Panel `#fff` / Hairline `#e0d5d1` / Ink `#1e1220` / Plum `#7b2d6b`, dark Night `#160e19` / `#201624` / `#3a2a3e` / `#f4edf3` / Orchid `#d58bc4`, plus sunken, selected, control-edge, four `--ops-status-*` and opaque `--ops-text-muted`. `token-map.json`: 42 rows, 0 not applied, 0 retire rows, no `primary-strong`/`surface-2`/`glow` string. `app.css` and built CSS: 0 hits for `primary-strong`, `copper`, `ops-path`, `shimmer`, `uppercase`, `animate-spin`, `animate-pulse`; 0 `infinite` in source (see warning on 3 dormant daisyUI loops in the built file). `@font-face` URLs relative with `?v=` equal to the sha256 of `ui.woff2` (`b9929d24...`) and `mono.woff2` (`d8c5ea4c...`) as I recomputed; Bricolage appears only as the unshipped `display.woff2`. `AssetPlug` serves immutable only on matching `?v=`. Dockerfile no longer removes the fonts (`rm -rf` limited to `assets/css` and `assets/js`; the old line removed all of `priv/static/assets`). Lockups, symbol, `favicon.svg` and `favicon.ico` are byte-identical to `brand/` sources (`cmp`); the ICO has 16 and 32 px entries and is 1573 bytes against the old 152-byte stub. Only two literal durations remain in `app.css`, both in the reduced-motion block; every other duration reads a `--duration-ops-*` token; `lib/` has no `duration-100/200`, `time: 120` or `animate-spin`. Browser proof (P-01, P-02, P-11, P-14, P-12): retained local partition receipt `ui-review-artifacts/phase187/partition/partition-final.json` shows 235 expected, 0 unexpected, 0 flaky, `ops_reskin_contract.spec.ts` 30 of 30 and `admin_path_motion.spec.ts` 19 of 19; the 300 of 300 canonical-lane run on `9217f326` is SUMMARY-backed only. |
| 2 | `ops_sync_status` renders every sync status with the four words and shapes; muted condition words with no icon; `Clear` only with an observation; notices are Panel plus 2 px rule; ranking Failed, Retrying, Pending, Clear, then name; the two copy bugs fixed | VERIFIED | One component renders the four words (`ops_ui.ex:512`); `grep` finds the words `Failed`/`Retrying`/`Pending`/`Clear` as status text nowhere else in `lib/`. Icon is `aria-hidden`, four distinct paths. `ops_condition` has a closed set of four words and no svg. `Posture.row_status/1` returns `:clear` only when backend lists are empty and the queue is observed-empty or unused by sync mode, else `Not observed`/`Not checked`; `@rank_order` is `[:failed, :retrying, :pending, :unverified, :clear]` then module name, applied once per load in `posture_live.ex:193`. Notice surface CSS: Panel fill, 1 px hairline, 2 px inline-start rule, `box-shadow: none`. Copy bugs: retry flash is a fixed sentence and the raw `inspect(reason)` now goes to `Logger.warning` only; the promotion flash says "blocked" once. I ran `cd scrypath_ops && mix test`: 2 doctests, 513 tests, 0 failures. Mutations caught: rank order swapped (E-05 failed 2), a status word renamed (5 failed), `aria-hidden` removed from the icon (5 failed), raw `inspect` restored into the flash (1 failed), double "blocked" restored into the flash (2 failed). A capture I opened (`after/search-health-dark-390.png`) shows Failed, Retrying, Pending, Not checked, Clear in that order, each status word with its glyph (a fact check of the all-statuses fixture, not a design review). |
| 3 | At most one Plum button per page and per open dialog, no `.btn-error`; destructive confirms name the consequence with Cancel focused; row actions share one style with at least 24 px; prose links underlined | VERIFIED at the DOM level the criterion names (see warnings for runtime focus) | `button_classes` has no danger or error variant. Labels in code: `Retry deleting N document(s)`, `Replace live index with target`, `Delete saved search permanently`. Both sync modals pass `initial_focus="[data-ops-modal-cancel]"` and the ops tests assert that attribute plus an outline Cancel. `.ops-text-action` is one rule: Ink, 600, underline, `min-height` 40 px. Mutations caught: every default button also `btn-primary` (14 failures), `btn-error` added to default buttons (14 failures), explicit Cancel focus attribute replaced on both dialogs (3 failures). One mutation survived: changing the `ops_modal` default `initial_focus` (it is not used by the destructive dialogs, which set it explicitly). |
| 4 | Contrast checker passes all text roles at 4.5:1 and control edge at 3:1 on four backdrops in both themes, no alpha on text, 2 px inline-start rule on selected rows; focus ring 2 px Plum or Orchid inside `.ops-table-scroll`; 64 px scroll clearance; no infinite animation; reduced motion honored | VERIFIED (static parts by me; tab-through and `getAnimations()` rest on browser receipts) | `node contrast-checker.mjs` from `examples/scrypath_ecommerce/`: `Contrast check: PASS`, 0 AA failures, 56 text pairs, 22 non-text pairs, 28 published pairs, Failed/Retrying hue gap 30.0 dark and 29.2 light, thinnest pair 4.58. I recomputed independently with my own WCAG function over the committed hexes: lowest text pair 4.584 (light Retrying on Selected), lowest control edge 3.09. Selection Signature: one shared unlayered rule gives `border-inline-start: 2px solid var(--color-primary)` to every selected element (`app.css:2640`) with a transparent 2 px reserved at rest. `.ops-table-scroll :focus-visible` is `outline: 2px solid var(--color-primary); outline-offset: -2px`. `html` has `scroll-padding-top: calc(var(--ops-header-h) + 1rem)`. `@media (prefers-reduced-motion: reduce)` caps durations at 0.01 ms and iterations at 1. Mutations caught: an alpha `color-mix` text color (checker exit 1, AA failures 1), muted text turned to low contrast (checker exit 2 plus token test), theme hex drift (checker exit 1), an infinite animation (3 ops tests failed). |
| 5 | Host sentinel unchanged off ops routes in light, dark, System; host accent override wins; `font-src 'self'` loads fonts; unscoped-selector ratchet passes; preview refreshed with preflight and data intact; one Draft PR with green gates at the exact head, before and after captures, and a plain what-the-gates-prove list | VERIFIED for everything that exists today; the PR half is pending-orchestrator | Host contract spec `ops_host_contract.spec.ts` has P-17a to P-17d (including the System dark plain-`:root` case added in review) with a planted `font-src 'none'` case; its green run (4 of 4 on a stack, 4 of 4 in the browser container, and in the 300 of 300 lane) is SUMMARY-backed. N-11 ratchets: token test 59 pass; I planted `html{margin:0}` into both stylesheets and "live unscoped selectors stay at the ceiling" failed (ceilings 54 selector parts and 12 dual dark rules, exact in both directions). GATE-03 first half: `.planning/UI-PREVIEW.json` records the refresh to main `8beb3ed0` and passing preflight; I confirmed `main` and `origin/main` are `8beb3ed0`, the preview worktree is on `ui/next` at `8beb3ed0`, the container `scrypath_ecommerce-web-1` is up and healthy and mounts that worktree, and the maintainer's `my-search.json` still hashes to `3c8de6b4...`. Captures: `reskin-capture.mjs --check` prints `capture inventory: 12/12` for before and after; all 24 PNG sha256 values match `187-CAPTURE-INVENTORY.md`; manifests say clean true and `git_status` empty for the after set; the directory is git-ignored. The inventory has the required "What the gates do not prove" section and makes no aesthetic or independent-review claim. Draft PR, exact-head hosted gates and the preview move: pending-orchestrator. |

**Score:** 5 of 5 success criteria verified, with the SC5 items above marked pending-orchestrator, none counted as gaps.

### Plan-level must-haves not already covered above

| Truth | Status | Evidence |
|---|---|---|
| Token map fully applied, `PENDING_CEILING` 0, retire rows deleted (Plan 03, 07) | VERIFIED | `token-map.json` 42 rows, 0 applied false, 0 retire. Token test passes; planted `--color-primary-strong` and `--shadow-ops-glow` each fail it. |
| Gate ledger: 8 of 12 (Plan 02, 04) | VERIFIED | CONTRIBUTING table has 8 rows and the line `Budget used: 8 of 12.`; `workflow_wiring_test.exs` (which parses and bounds it, with planted-defect cases) passes in the run of 191 tests with the boundary and brand pin tests. |
| Fonts and committed pin intact | VERIFIED | `brand_pin_contract_test.exs` passes. |
| Loading is a word plus `aria-busy`, no animation (Plan 06) | VERIFIED (DOM) | E-16 tests pass after the review fix that moved `aria-busy` off the `role="status"` word onto the skeleton or replaced content. No real screen-reader run exists. |
| Tracked JS bundle matches source | VERIFIED | `scripts/ci/ui_bundle_contract.test.cjs`: 12 pass. |
| No debt markers in the phase diff | VERIFIED | `git diff 08827d7f..cf744109` (non-`.planning`): no added `TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER` and no stub patterns. |

### Required artifacts

| Artifact | Status | Details |
|---|---|---|
| `scrypath_ops/assets/css/app.css` and built `priv/static/assets/css/app.css` | VERIFIED | Substantive and wired; token test proves built equals source theme blocks. |
| `scrypath_ops/assets/css/token-map.json`, `contrast-pairs.mjs`, `examples/scrypath_ecommerce/contrast-checker.mjs` | VERIFIED | Checker reads pairs from the stylesheet; mutation-checked both ways. |
| `ops_ui.ex` (`ops_sync_status`, `ops_condition`, `ops_loading`, modals), `posture.ex` | VERIFIED | Called from five LiveViews (`ops_sync_status` 10 call sites in three of them). |
| Font files, lockups, favicon | VERIFIED | Byte-equal to `brand/`, hashes match the `?v=` values. |
| `reskin_static_contract_test.exs`, `reskin_component_contract_test.exs` | VERIFIED | Run and mutation-checked. |
| `ops_reskin_contract.spec.ts`, `ops_host_contract.spec.ts`, `reskin-capture.mjs` | VERIFIED (exist, substantive, wired) | Specs are 2143 and 314 lines with planted-failure cases; capture self-test 25 of 25 pass. Browser runs not repeated by me. |
| `187-CAPTURE-INVENTORY.md` | VERIFIED | 24 hashes match files on disk. |

### Key links

| From | To | Via | Status |
|---|---|---|---|
| `app.css` `@font-face` | `priv/static/assets/fonts/{ui,mono}.woff2` | relative URL plus `?v=` equal to sha256, served by `AssetPlug` | WIRED |
| Dockerfile asset stage | committed fonts | `rm -rf` limited to generated css and js trees | WIRED (Docker lane not run by me) |
| `posture.ex` ranking | `PostureLive` rows and verdicts | `sort_by_urgency` and `worst_status` | WIRED |
| `ops_sync_status` | Failed sync work and Search health | 10 call sites | WIRED |
| Token map | built CSS | token test emissions check | WIRED |
| Root layout | `favicon.svg`/`favicon.ico`, font preload | standalone only; host layout has none | WIRED |
| Contrast checker | contrast contract test | `ui_contrast_contract_test.exs` | WIRED (29 root `ui_*` tests pass with `--exclude contrast_child`) |

### Data-flow trace (Level 4)

| Artifact | Data | Source | Real data | Status |
|---|---|---|---|---|
| Search health rows and verdict | row status, rank, worst status | `Scrypath.sync_status/2` result through `Posture.row_status/1` | Yes; `Not checked` for `{:error, _}`, `Not observed` for an unobserved queue; never `Clear` from a zero count | FLOWING |
| Failed sync work rows | state, `ops_sync_status` word | row state from the failed-work loader; `failed` or `retrying` only | Yes | FLOWING |
| Fonts | `?v=` | recomputed sha256 of the file | Yes | FLOWING |

### Behavioral spot-checks (what I ran)

| Check | Command | Result |
|---|---|---|
| Contrast gate | `node contrast-checker.mjs` (from `examples/scrypath_ecommerce/`) | PASS, 0 AA failures |
| Token test | `node --test --test-reporter=tap examples/scrypath_ecommerce/ui-tokens.test.mjs` | 59 pass, 0 fail |
| Preservation pair test | `node --test ... scripts/ci/ui_state_pairs.test.cjs` | 39 pass, 0 fail |
| Capture self-test | `node --test ... reskin-capture.selftest.mjs` | 25 pass, 0 fail |
| Bundle contract | `node --test ... scripts/ci/ui_bundle_contract.test.cjs` | 12 pass, 0 fail |
| Ops suite | `cd scrypath_ops && mix test` (database `scrypath_ops_test_187_verify`, dropped) | 2 doctests, 513 tests, 0 failures |
| Root contract tests | `mix test test/mix/tasks/ui_*_test.exs --exclude contrast_child` | 29 tests, 0 failures |
| Ledger, boundary, brand pin | `mix test test/mix/tasks/workflow_wiring_test.exs test/mix/tasks/dependency_boundary_contract_test.exs test/mix/tasks/brand_pin_contract_test.exs` | 191 tests, 0 failures |
| Capture inventory | `reskin-capture.mjs --check` on before and after | 12/12 each; 24 of 24 hashes match |

### Mutation spot checks (scratch copy outside the repo)

Each row planted one defect into a copy of commit `cf744109` (source and built CSS together where relevant) and ran the contrast checker, the token test and the full ops suite.

| Planted defect | Caught by | Result |
|---|---|---|
| `text-transform: uppercase` on a rule | ops E-12 (1 test) | caught |
| `.btn-error` on default buttons | ops E-07 and live tests (14) | caught |
| a second `.btn-primary` on every default button | ops E-07 and live tests (14) | caught |
| infinite animation in CSS | motion contract and static contract (3) | caught |
| alpha text color (`color-mix ... transparent`) | contrast checker only (exit 1) | caught |
| muted text turned low-contrast | contrast checker (exit 2) and token test (3) | caught |
| retired hex in a new tracked file; in `app.css` | token test deny-list (1; 2 for the CSS case) | caught |
| `--color-primary-strong` reintroduced | contrast checker, token test (3), ops E-12 | caught |
| `--shadow-ops-glow` reintroduced; `.ops-copper-eyebrow` | token test and ops (2 each) | caught |
| theme hex drifted; source changed without rebuilding CSS | contrast checker and token test (3 and 4) | caught |
| font `?v=` hash wrong | token test and ops E-14 | caught |
| `html{margin:0}` appended (unscoped growth) | token test ratchet | caught |
| ranking order swapped | ops E-05 (2) | caught |
| sync-status word renamed; icon `aria-hidden` removed | ops E-01 and live tests (5 each) | caught |
| raw `inspect(reason)` back in the retry flash | ops (1) | caught |
| double "blocked" back in the promotion flash | ops (2) | caught |
| destructive dialogs' Cancel focus attribute changed | ops E-08 (3) | caught |
| `--text-ops-xs` set to 0.6875rem (11 px) | nothing static | SURVIVED |
| promotion notice body reverted to "Promotion is blocked: ..." | nothing | SURVIVED |
| `ops_modal` default `initial_focus` changed | nothing | SURVIVED (not used by destructive dialogs) |

My first attempt at the unscoped-growth case used a plain class selector and passed; N-11 defines "unscoped" as element, universal, pseudo-element, root and `[data-theme]` subjects, so that was a bad mutation, not a gate hole. Two earlier runs were contaminated by a staged file in my scratch copy; I fixed the runner and re-ran everything from that point.

### Requirements coverage

All 16 requirement IDs appear in plan frontmatter; none is orphaned.

| Requirement | Status | Evidence |
|---|---|---|
| SKIN-01 | SATISFIED | Theme blocks, token map, no retired tokens, mutation-checked |
| SKIN-02 | SATISFIED | Fonts relative with hash `?v=`, Dockerfile, AssetPlug, h1 rule; request and computed parts also in browser specs (receipt-backed) |
| SKIN-03 | SATISFIED | Byte-equal lockups and favicon, ICO 16 and 32 px |
| SKIN-04 | SATISFIED | See SC3; runtime Cancel focus not browser-asserted (warning) |
| SKIN-05 | SATISFIED | Retired families gone, tokens for every duration, no looping source |
| SKIN-06 | SATISFIED, thinly guarded | No sub-12 px source found by my independent scan; no static gate (warning) |
| SKIN-07 | SATISFIED | Ranking and both copy fixes test-pinned and mutation-checked |
| SKIN-08 | PENDING-ORCHESTRATOR | Capture inventory and fixture done and verified; the Draft PR and exact-head hosted gates are the orchestrator's |
| STAT-01, STAT-02, STAT-03 | SATISFIED | See SC2 |
| A11Y-01 | SATISFIED | Checker plus my independent recomputation |
| A11Y-02 | SATISFIED | CSS present; tab-through is receipt-backed |
| A11Y-03 | SATISFIED | Reduced-motion rule, no loops in source; runtime `getAnimations()` is receipt-backed |
| A11Y-04 | SATISFIED | Host spec (receipt-backed), ratchets (run and mutation-checked) |
| GATE-03 | PARTIAL, PENDING-ORCHESTRATOR | Refresh to main with preflight evidence verified; move to final head, second preflight and `ui:review` inventory pending |

### Anti-patterns found

None blocking. No debt markers, no stub patterns, no `raw/1` or runtime atom creation in the changed files (the independent code review reached the same conclusion). A runtime `start_async` warning appears in the ops test output; it comes from `sync_drift_live.ex` code dated 2026-10-12, before this phase.

## Not proven, and what rests only on someone else's run

Rests only on SUMMARY or executor receipts (I did not re-run Docker or browser lanes, as instructed):
- The canonical `mix verify.ecommerce_e2e` run (300 of 300, preservation 61 of 61) and `mix verify.ecommerce_mounted`, `verify.repository_contracts` (157 tests), `verify.package` (110) and `verify.core` (1158) on `9217f326`. The only retained primary artifact I could open is the Plan 10 Playwright partition report (235 expected, 0 unexpected).
- The review-fix round re-ran `verify.ops_ui`, `verify.core` and a browser subset on `cf744109` (SUMMARY-backed). It did not re-run `repository_contracts`, `package`, `ecommerce_mounted` or the full lane, and three `standalone` tests in `phase173_status_actions.spec.ts` did not run at all there (no second stack).
- The Dockerfile font fix: no static test guards it. Its only protection is the font request check in `harness.spec.ts`, which runs in the required `ecommerce-mounted` lane against a built image.

Not proven by anything:
- Hosted CI has not run; nothing is pushed.
- The live GitHub Pages check was not run.
- Rendered quality. The captures are review context. No aesthetic or independent-review claim is made or supported.
- No real screen-reader run. The accessibility work is proved as DOM structure and computed style only.
- Behavior in hosts other than the e-commerce fixture, and a host that links the ops stylesheet on every page (it would still receive the 54 unscoped selector parts, which the ratchet only stops from growing).

## Findings, classified

### Blockers

None.

### Warnings (non-blocking, with a concrete next step)

1. **The 12 px text floor has no static gate.** I set `--text-ops-xs` to 0.6875rem in the source and built CSS; contrast checker, token test and all 513 ops tests still passed. Only `ops_reskin_contract.spec.ts` P-02 (browser, advisory lane) would catch it. My independent scan of `app.css` and the built CSS found no sub-12 px font size today (daisyUI's 11 px `.btn-xs` is unused and overridden by `text-ops-body`). Suggested fix: one ExUnit or Node assertion that `--text-ops-xs` and `--text-ops-sm` resolve to at least 0.75rem.
2. **All browser computed-style proofs live in the advisory `ecommerce-e2e` lane.** The required `ecommerce-mounted` lane runs only `harness.spec.ts` and `operator.spec.ts` (`docker-playwright.sh`). After merge nothing required re-runs P-01 to P-21 or the host contract. That matches the gate budget decision, but the maintainer should know the 12 px floor, the runtime animation checks and the host contract are advisory-lane evidence. For this PR the dispatch on the exact head is the closing check (orchestrator step).
3. **Long gates last ran on `9217f326`, five code commits before the head.** Those commits changed `ops_ui.ex` and `sync_drift_live.ex` (loading markup), `ops_hooks.js` and the bundle (palette close timer), the capture script and tests. The built stylesheet is unchanged since `9217f326`. The 187-CAPTURE-INVENTORY.md sentence calling `9217f326` "the last commit with an executable or rendered change" is no longer true of the branch (it was true when written). The hosted run on the exact head covers this.
4. **No browser test asserts Cancel is focused when a destructive dialog opens.** E-08 asserts the `data-ops-modal-initial-focus="[data-ops-modal-cancel]"` attribute and an outline Cancel; the `OpsModal` hook that reads it was not changed in this phase; `operator.spec.ts` tests the Tab trap, not initial focus. The roadmap states this criterion as a DOM check, so I count it verified, but a one-line Playwright assertion that `document.activeElement` is the Cancel button after opening the promotion dialog would close it. This is automatable, not a human item. The saved-search "Delete saved search permanently" confirm is an inline typed-name form inside the Manage dialog, not its own modal, so Cancel-initial-focus does not apply to it (UI-SPEC scopes the rule to the two sync modals).
5. **The 12 after captures are from `9217f326`, not `cf744109`.** Plan 11 said "from the final code SHA". The built CSS is identical and the later changes are in loading and palette-close states the captures do not show, so they remain valid review context. Re-capturing after the preview moves would also record the served-stylesheet hash the new capture script adds.
6. **The built stylesheet carries three dormant `infinite` declarations** (daisyUI `.progress:indeterminate` twice and `.skeleton`), emitted because words like "skeleton" appear in source comments. No template uses those classes (scanned by a static test, with a planted case) and no ops-authored source loops. A literal `grep infinite` on the built CSS finds them, so the roadmap wording "no infinite-animation code in ops" is true for ops-authored code only.
7. **Open review items (all Info in the code review, untouched by instruction):** IN-01 Sync and index words a retry-only queue "Pending" while Search health says "Retrying" (specified in UI-SPEC and pinned by a test, but a second word for one condition); IN-02 Control Room can show `Clear` beside a retained observation after a failed refresh; IN-03 to IN-05 dead code, phantom attributes and no-op dark twins; IN-07 the command palette input still suppresses its focus outline (pre-existing); IN-08 `.ops-flash__close` has no CSS rule and "Replace live index with target" may overstate the loss.
8. **Thin contrast margin.** The thinnest text pair is 4.58 against a 4.5 floor (light Retrying on Selected). It passes exactly; any hex nudge will fail the checker, which is the intended behavior.
9. **Two secondary copy and default values are not pinned by any test** (the promotion notice body wording and the `ops_modal` default focus selector). The mutation survived; the flash and the destructive dialogs, which the requirements name, are pinned.

### Pending-orchestrator (not gaps)

- **SKIN-08:** open one Draft PR from `feat/v1.46-187-ops-reskin`, dispatch `ci.yml` on the exact head SHA, wait for every required check plus `ecommerce-e2e` and `closeout-attestation`, post the one comment (inventory link, preservation decision, "What the gates do not prove"). The PR stays Draft until the maintainer's yes.
- **GATE-03, second half:** run `npm run ui:preflight` from the preview checkout, move `ui/next` to the PR head, restart seed-disabled (`compose.preview.yaml`), run preflight again, run `npm run ui:review`, update `.planning/UI-PREVIEW.json`. Note for the record: the first refresh started the dev preview with normal seeding because no prior volumes existed, so "preview data survives" held trivially (and `my-search.json` is unchanged); every later restart must use the seed-disabled file.
- Bookkeeping: REQUIREMENTS.md traceability rows, ROADMAP plan checkboxes and STATE.

## Human verification required

None. Everything in this phase is automatable and the project rule is zero human verification. Warnings 1 and 4 each have a one-assertion automated fix; neither needs a person.

## Gaps summary

No gaps. The phase goal as far as it can be established before the orchestrator's steps (identity, one status vocabulary, host containment, evidence, inventory) is met in the code and in the checks I ran. The remaining work is the orchestrator's: the Draft PR, the exact-head hosted run and the preview move.

---

_Verified: 2026-11-19T23:12:40Z_
_Verifier: Claude (gsd-verifier)_
