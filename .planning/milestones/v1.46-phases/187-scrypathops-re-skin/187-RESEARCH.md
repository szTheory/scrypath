# Phase 187: ScrypathOps re-skin - Research

**Researched:** 2026-11-19
**Domain:** Phoenix LiveView operator UI re-skin (Tailwind v4 + vendored daisyUI 5.0.35 theme blocks, self-hosted fonts, status vocabulary, host-mount contract), with Node/ExUnit/Playwright contract gates
**Confidence:** HIGH on the per-file map, build pipeline, test inventory and Docker findings (read or run this session); MEDIUM on Playwright cost estimates and the local host-native browser lane (not run)

Legend: **V** = verified this session by reading the file or running the command. **U** = inferred, not confirmed (each U is also in the Assumptions Log). Line numbers are for HEAD `3092b754` (main `8beb3ed0` plus two docs commits) and drift as edits land; re-derive with the greps given.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Tokens (D4)
- `scrypath_ops/assets/css/app.css` two daisyUI theme blocks stay the single authoring place. Map base-100 to Panel, base-200 to Page, base-300 to Hairline, base-content to Ink (light) or Pale Ink (dark), primary and accent to Plum or Orchid. Retire `primary-strong` and the copper secondary (daisyUI requires a secondary: set a quiet neutral). The daisyUI required set is 20 variables; re-anchor any lock to that.
- Add hand-authored roles inside the theme block: `--ops-sunken`, `--ops-selected`, `--ops-control-edge`, an opaque `--ops-text-muted` replacing about 52 alpha mixes (ban alpha on text), and `--ops-status-failed|retrying|pending|clear`. Do not alias `--ops-surface-2` (its meaning flips from raised to recessed): introduce `--ops-sunken` and retire `surface-2`. Never use the hairline as a control's only edge. Retire the glow tokens.
- Brand values come from `brand/tokens.json` plus the verified values the prep recorded as living in `brand.json` or prose: Selected Night `#2B2130`, dark Control Edge `#8F7F94`, Night Sunken. Do not generate CSS from the brand file: the Phase 186 token map (`scrypath_ops/assets/css/token-map.json`, 37 rows with `applied` flags) is the parity source. **As each property is recolored, flip its row to `applied: true` and lower the pending ceiling; the Node token test must stay green.** After the recolor the `app.css` allowlist entry needs `max_hits` and the test-owned `HITS_CEILING` lowered together (the test prints the number).
- Rebuild the tracked built CSS (`scrypath_ops/priv/static/assets/…`) so the token-level built-CSS parity check passes; byte freshness is not checked, token level is.
- Contrast (verified in prep, V by running): all 7 text roles pass 4.5:1 on page, panel, sunken and selected backdrops in both themes; thinnest is Retrying on Selected Page light at 4.58:1. Control edge 3.66 to 4.00 and 3.09 to 3.33 on light backdrops, 4.13 to 5.23 dark. Hairline is a divider only (1.1 to 1.47). Plum against ink is about 2.1:1, so inline text links need an underline. The light selected-row fill is only about 1.1:1, so a 2 px Plum inline-start line carries WCAG 1.4.11. Use unrounded thresholds. 2.4.11 needs `scroll-padding-top` of about 5 rem for the 4 rem sticky header. Extend `examples/scrypath_ecommerce/contrast-checker.mjs` (it has the parser and compositing); do not add a second pair document. Phase 186 noted the checker currently stops at the muted-text alpha lockstep guard (D-15 Guard 2) and the `64%, transparent` pin in `UiTokensContractTest`: those two assertions are Phase 187's to rewrite to the new opaque muted token (they are listed as owned by SKIN-01 and A11Y-01).
- Motion: brand-named tokens become the source (instant 80, quick 160, base 240, advance 600). Keep old names (`fast`, `standard`, `slow`, `status`, `instant` at 90) as `var()` aliases for one milestone. Every transition and animation duration is one of the tokens; `advance` only in a named progress-line allowlist (empty in v1.46); no `sting` (1650) in ops CSS. Ban `infinite`: replace `spin` and `ops-pulse` (about app.css lines 896 and 1616) with a word plus `aria-busy`. Reduced motion already has a global rule (about line 2191).

Fonts and assets (D6)
- Ship Hanken Grotesk and Sometype Mono (already committed byte-identical under `scrypath_ops/priv/static/assets/fonts/` by Phase 186) wired by CSS-relative URLs with a content-hash `?v=` equal to the file's sha256, served by the existing `forward("/assets", AssetPlug)` at any mount prefix (V: `router.ex:27`; `/fonts` exists only in standalone `static_paths` and would 404 mounted). `font-display: swap`; metric-adjusted fallback faces (Hanken over Arial: size-adjust 101.7, ascent 98.3, descent 29.8; mono over Courier New: 96.7, 95.7, 28.5), proven by a layout-shift probe. Preload `ui.woff2` only in the standalone root layout, with `crossorigin`. No base64 inlining. Same-origin fonts need only `font-src 'self'`.
- **Bricolage is not shipped in ops** (the book's operator row omits it; follow the explicit scope row). The ops h1 is Hanken 700 at 28 px.
- Subsets lack U+00A1-00BF including `·` (18 uses), `›` (2) and `⌘` (3, in no font): add a coverage test with a named fallback allowlist. The CSS uses weights 400, 500, 600, 650, 700 and the variable subsets cover 600-800 (display), 400-700 (ui), 400-500 (mono), so snap 650 and 500 appropriately. Hanken digits are already tabular and Sometype Mono has no `zero` feature, so `tabular-nums` and `slashed-zero` are no-ops.
- Contract tests: built CSS `?v=` values equal the files' hashes and no URL is root-absolute; mounted-mode assertions that `/ops/assets/fonts/ui.woff2` and one more nested prefix return 200.
- Logo and favicon: copy the brand lockups (light and dark) and favicon (SVG plus PNG-in-ICO; the current ops `favicon.ico` is a 152-byte stub) from `brand/`. The lockup aspect is 4.71:1: use 136 px or wider with `flex-shrink: 0`; exactly one lockup displayed per theme, `src` matching, width at least 112 and height at least 24 at 320 px. A host that mounts at a prefix must link `<mount>/favicon.svg` (document it).

Theme default and host contract (D9)
- Ops stays **System-default** for theme; the book's light default applies to the website, README and docs only. ScrypathOps owns styles for its shell and sets nothing outside it; theme comes from `html[data-theme]`, else the OS; ops never forces light; accent override works through the existing daisyUI variables; variable names are stable, values may change.
- Leak mechanics (V in built CSS, no host run): the shipped CSS includes Tailwind preflight (`*, ::after, ::before`), `:where(:root)` daisyUI theme variables and `:root,[data-theme]` base color and background, with theme names "light" and "dark". Do not refactor isolation in this sitting. Guards: a ratchet allowlist of unscoped selectors in compiled CSS; an ecommerce check that a non-ops route loads no ops stylesheet and computes no `--color-primary`; a host-override-wins fixture; a fixture host in light, dark and System with a sentinel host element whose computed style must not change, with CSP `font-src 'self'`; a settled-style check across six combinations (OS scheme times stored preference). A fully scoped `.ops-root` is deferred. Hosts using `class="dark"` get a one-line docs shim in `scrypath_ops/README.md` (also: unchanged stylesheet link and mount prefix, the nine mirrored JS hook names unchanged and re-registered by the ecommerce host, fonts load from the mount prefix and a host CSP may block them, file names frozen).
- The embedded `/admin/search` demo runs on the ecommerce host's `app.js`: any ops JS hook change must be mirrored there (memory note).

Status component and vocabulary (D7, D10)
- Add one `ops_sync_status(:failed | :retrying | :pending | :clear)` component: word first, then a bar icon (filled = Clear, hollow = Pending, filled from the bottom = Retrying, notched = Failed), `aria-hidden` icons with a `data-shape` attribute, word color from the book's text hexes via the `--ops-status-*` tokens. Use where the repo already shows those states: the Failed sync work row badge (`failed_sync_live.ex` about line 1035) and Search health queue and backend badges and counts (`posture_live.ex` about 345-352, 442-452). Keep the existing six tone kinds as notice and verdict kinds, and keep `data-status-kind` and `data-ops-metric-tone` hooks so tests survive. `ops_badge` stays for non-sync labels as plain neutral text.
- "Not observed", "Not checked" and "Queue not used" are conditions, not statuses: plain muted words, no icon (`posture_live.ex` about 662-676). Show "Clear" only with an observation; never infer health from zero counts (DESIGN.md).
- Notices and verdicts: Panel plus a 2 px left rule; only an error uses the Failed color; Plum is never an info color; `:running` becomes neutral. Green only on the word and icon of Clear. Warning uses the Retrying amber for rule and title only.
- Ranking fix: `posture_row_rank` (about `posture_live.ex:528`) ties queue-failed with queue-retrying and ranks pending as clean; change to Failed, Retrying, Pending, Clear, then name. A row shows its most urgent status. Rows re-sort only on manual refresh.
- Dense facts in place of the progress line: "Queue 2 pending, 1 retrying · Meilisearch 0 · Last succeeded 14:02 UTC" (data per schema exists).
- Two verified copy bugs ship here for a visible increment: the promotion prefix (`sync_drift_live.ex` about line 290) and the `inspect(reason)` leak (`failed_sync_live.ex` about line 352). Other wording renames (e.g. "Control Room" to sentence case, "Searchable" label rule) belong to Phase 190, not here.
- Verified answers (R/V): Retry is per failed item on Failed sync work only, no bulk retry, none on Search health; Pending is the status word for both `queue.pending` and `backend.pending`; Clear does not mean Searchable; `mix scrypath.status` prints Backend (Meilisearch) and Queue lines with Last succeeded as two timestamps.

Buttons, actions, icons (D7)
- At most one Plum button per visible, non-inert scope (an open modal is its own scope). Keep Control Room "View search health", Search "Run search", Search "Save" in its modal; demote the inline "Rename". Danger buttons (`failed_sync_live.ex` about 1224, `sync_drift_live.ex` about 2463, `search_live.ex` about 1930) become the modal's single Plum button with the consequence in the label; Cancel stays initial focus; no `.btn-error`. Sync and index: no page-level Plum button; the promote confirm is the only main button.
- Row actions (Retry about `failed_sync_live.ex:1100`, Load, Rename, Export, Delete, "View failed sync work") become underlined Ink text on every row (`.ops-text-action` underlines only on hover today, app.css about 2500); minimum target height at least 24 px (today's 40 px is fine); prose links underlined at rest.
- Icons: drop the six nav icons (`layouts.ex` about 253-265) and the verdict icons; keep control glyphs (menu, close, chevron, copy, sun, moon).

Retired code and type floor (D7, D8)
- Retire `.ops-path-*`, `.ops-copper-*`, glow and copper gradient (app.css about 1979-2035 and 2412-2423; no template uses them), the select chevron hard-coded colors (about 955-962), and `uppercase` at app.css about 786, 1149, 1510, 1750 and `ops_ui.ex` about 401 and 516. The rgba triplets 108,92,231 and 193,122,62 go too. Update the tests and the three advisory e2e specs that pinned them (`admin_path_motion`, `admin_surface_depth`, `phase173_shell`: they hold old RGB constants; use the spec's existing `resolveCssColor` against the token) and `motion_contract_test.exs`.
- h1 at 28 px; raise the 11 px sites to 12 (`app.css` about 202, 1145, 1748, 1931, 1974; `--text-ops-xs` 0.6875rem conflicts with the floor); make `.ops-signal-metrics .ops-time` mono (about 2454). Record the size scale as `keep-platform` in the token map; no body reflow. Every time already names its zone (`ops_ui.ex` about 1850).
- Line numbers above are from the prep (2026-11-18); re-derive on the current tree.

Assertions that prove each rule without a human (D7)
- h1 `font-family` starts with the heading family at 28 px and is the only element using the display font; `.ops-time` and `[data-ops-copy]` compute to the mono face; minimum computed text size at least 12 px; `text-transform` never `uppercase`; every `ops_sync_status` has non-empty text in {Failed, Retrying, Pending, Clear}, an icon `data-shape` matching it, a word color equal to the token, `aria-hidden` icons; visible non-inert `.btn-primary` at most 1 per page and per open dialog; no `.btn-error`; row actions share one computed tuple; the selected row has a 2 px `border-inline-start` in both themes; focus outline 2 px solid Plum or Orchid and its rect inside the scrollport for the first and last controls of `.ops-table-scroll` (the belief that `overflow-x-auto` ancestors clip it is unverified: test, do not trust the comment at app.css about 157-159); a tab-through leaves the focused element's top at least 64 px below the viewport top; exactly one lockup displayed per theme; no running infinite animation (`getAnimations()`); every transition duration in {80, 160, 240} ms; all book pairs recomputed from custom properties including status words on Selected Page and the control edge; grep gates for `ops-path|copper|glow|gradient|uppercase|infinite`. Put LiveView/DOM-level ones in ops ExUnit tests where possible (cheap) and computed-style ones in Playwright specs under `examples/scrypath_ecommerce/e2e/` (the phase105-e2e job runs all specs; no new CI job).

Preservation pairs and the Phase 186 structural check
- Phase 186's structural pair comparator is **not font-invariant** and geometry stays exact: the font swap (SKIN-02) and any new dark-surface border will likely reject preservation pairs by design. Decide in planning what that check is expected to prove for 187: keep copy, state, action, identity and geometry-class checks; do not recapture pixel baselines on macOS (CI image only); do not auto-update an unreviewed baseline. A rejecting pair after the re-skin is a reviewed, recorded expectation, not a silent baseline refresh. Record the decision.
- Editing `scripts/ci/ui_state_pairs.cjs` changes the fixture-overlay digest: do it before any "before" capture, or not at all.

Delivery (D16, GATE-03, AGENTS.md UI work)
- Open the PR as a **Draft** (GitHub blocks merging drafts with no new gate). When every automated gate is green on the exact head SHA (dispatch CI on that head; require `ecommerce-e2e` and `closeout-attestation` green before raising the Draft), post one message with the before and after capture inventory and a plain list of what the gates prove and do not prove. The maintainer's yes is marking it ready or saying "merge". No required-review rule; do not simulate a reviewer identity. Hex 0.3.18 was already released; no Hex release is part of this phase.
- GATE-03: read `.planning/UI-PREVIEW.json` and `.planning/reference/UI-WORKTREE-LEARNINGS.md` first (the preview record is stale: it names worktree `ui/next` at `ebed49b5` and `npm run ui:preflight` failed with `no such object: scrypath_ecommerce-web-1`). Refresh and reconcile `ui/next` to post-merge main, rebuild via `compose.dev.yaml` (the baked image on :4002 is stale; see the memory note on the dev container and Elixir 1.19 gotchas), keep seed-disabled so preview data survives, re-run `npm run ui:preflight` from that checkout's demo directory before editing or restarting the preview. Docker host is shared (other projects' containers): task-scoped names and labels, a free `WEB_PORT` lane when 4002 is taken, clean up per AGENTS.md, never prune other projects' resources. Review artifacts go in `ui-review-artifacts/`. First `verify.repository_contracts` and Buildx builds need escalated permission.
- Follow `examples/scrypath_ecommerce/e2e/UI-REVIEW.md` for storefront/ScrypathOps changes: review the full current screen and journey inventory, inspect rendered screenshots and actual copy, record unreported problems, run `npm run ui:review` from the demo in the checkout actually mounted by the preview. Captures and passing code tests alone are not a design pass; do not claim independent review. Keep the lean CI posture.
- Per-screen risk (prep): all six screens: tokens, fonts, logo, scale, focus, dark (medium; wide snapshot churn). Control Room: verdict icon and tone to the Clear and Failed pattern, one Plum button, drop intent-card icons (low). Search health: hairline rows by CSS, new status component, ranking function, mono times, drop the shadow (medium). Failed sync work: status word and icon, Retry as text action, recolored "Retry queued" notice, Plum destructive confirm (medium). Sync and index: no page-level Plum button, promote confirm only, check ring clipping in `ops_table` (medium). Search and saved searches: demote Rename, row-action style, active saved search selected style (medium). Help: headings and links only (low).

### Claude's Discretion

- Plan slicing and wave order (suggested: tokens and fonts and built CSS first; then the status component, buttons and row actions per screen; then retired-code removal and test rewrites; then host-contract guards; then GATE-03 preview refresh, captures and the Draft PR), file layout, test structure, helper naming. Run cheap consistency checks (contrast checker, token test, ops pure-regex tests) before long suites and look for CI speed wins when CI runs.
- Where this phase could not be one PR without becoming unreviewable, keep one Draft PR but sequence atomic commits so the diff reads screen by screen.

### Deferred Ideas (OUT OF SCOPE)

- Master-detail Search health picture (selected row, one sentence, only Plum button, progress line), per-schema retry, bulk retry all, sounds, logo animation: no per-schema progress semantics; revisit in v1.48.
- Type-scale reflow to 16/28/13: six screens reflow with no catalog to show states; v1.48.
- Fully scoped `.ops-root` isolation: a host-reported leak would change this.
- "Control Room" to sentence case and the "Searchable" wording rules: Phase 190.
- Retiring `ui_tokens.ex`, the `ops.*` DTCG mirror and their tests, deleting `brandbook/`, and replacing the demo host favicon: first v1.47 phase cleanup (ROADMAP "Deferred to v1.47"). The `ops.*` DTCG mirror remap is only what the recolor needs to keep them passing.
- Any pixel baseline recapture: CI image only, never macOS; deferred to the catalog work.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SKIN-01 | Brand palette in both theme blocks, new hand-authored roles, no primary-strong/copper/glow, System-default | Section 1.1 (theme blocks), 1.7 (token-map and ceilings), Section 4 Plan 03; token test stale-claim rules (V, `ui-tokens.test.mjs:340-380`) force an atomic recolor commit |
| SKIN-02 | Hanken and Sometype Mono from the mount prefix at any depth, `?v=`, swap, fallbacks, h1 28/700, coverage test | Section 2 (serving), 1.1 (type sites), **Docker finding D-1: images delete `assets/fonts`** |
| SKIN-03 | Brand lockup and favicon replace logo and stub; one lockup per theme at 320 px | 1.3 (layouts/root), 2.4 (asset serving), E-13/P-11 |
| SKIN-04 | One Plum button per scope, no `.btn-error`, confirm labels, row actions, prose links | 1.2-1.4 (button sites), 1.8 pinned-test inventory (operator.spec.ts:280 is in the required lane) |
| SKIN-05 | Retired code gone, infinite animation gone, motion tokens | 1.1 (retire blocks, daisyUI durations measured), 1.5 grep gates |
| SKIN-06 | 11 px to 12, mono times, no reflow | 1.1 (`--text-ops-xs` one-line fix, V) |
| SKIN-07 | Ranking, two copy bugs | 1.4 (posture_live.ex:522-540, failed_sync_live.ex:352, sync_drift_live.ex:290/1256/1579) |
| SKIN-08 | One Draft PR, 24 captures, gates list | Section 5 (preview/captures), Open Questions 1, 8 |
| STAT-01..03 | `ops_sync_status`, conditions, notice/verdict rules | 1.4, fixture finding (two copies), pinned tests in 1.8 |
| A11Y-01 | Contrast, control edge, no alpha on text, selection line | Validation Architecture; contrast-checker Guard 1/2 sites (V) |
| A11Y-02 | Focus ring in scrollport, scroll padding | Validation Architecture (P-09, P-10); `:focus-visible` at app.css:233 (V) |
| A11Y-03 | Reduced motion, no infinite, 12 px floor | 1.1 animation inventory (V), Validation Architecture |
| A11Y-04 | Host contract guards | Section 6 |
| GATE-03 | Preview refreshed, preflight passes, data survives | Section 5: no preview volumes or images exist (V) |
</phase_requirements>

## Summary

The phase is large but mostly mechanical once three coupling facts are respected. First, the Phase 186 token test makes the recolor atomic: an `applied: false` row whose CSS value already equals the brand value fails ("stale pending claim"), an `applied: true` row that differs fails, and the tracked built CSS must carry the same token values as the source blocks (V, `ui-tokens.test.mjs:340-418`). So the theme-block values, the token-map flips, the rebuilt built CSS, the allowlist `max_hits` and `HITS_CEILING`, the contrast-checker guards and the DTCG mirror remap have to land in one commit. Second, the Docker images used by every browser lane delete the committed fonts: the asset-builder stage runs `rm -rf scrypath_ops/priv/static/assets` and the runtime stages copy only the builder's output (V, `examples/scrypath_ecommerce/Dockerfile:32,83-105`). Without a Dockerfile fix the fonts 404 in the mounted lane, the standalone fixture host, CI e2e and the preview, silently, because `font-display: swap` falls back. Third, the evidence machinery has its own pins: both `phase173_fixture_source.ex` copies, `ui-review.mjs` and `helpers/ui-preservation-states.ts` are in the fixture-overlay digest (V, `ecommerce_evidence.cjs:65-91`), the `closeout-attestation` check requires specific spec files and 13 named cases to stay (V, `ecommerce_evidence.cjs:545-580`), and the one required Playwright pin on a changed label is `operator.spec.ts:280` (V).

No preview infrastructure survives: there are no scrypath_ecommerce containers, images or volumes (V), so "preview data survives" is vacuous and the refresh is a cold build. Port 4002 is free (V). The retained worktree `ui/next` is 12 commits behind main with a regenerable built-CSS artifact edit and the maintainer's untracked `my-search.json` (V). No tool captures 1280 px (V); SKIN-08's 24 images need a small new capture script.

**Primary recommendation:** Execute as 7 sequential plans: (01) test-only and evidence prep with before captures, (02) fonts, brand assets and type floor with the Dockerfile fix, (03) one atomic palette-and-guards commit, (04) status component, ranking and copy bugs, (05) buttons, row actions, selection, focus, icons and loading, (06) retired-code, alpha and motion cleanup with the pinned-test rewrites, (07) host contract specs, e2e pin fixes, after captures, preview refresh and the Draft PR. Keep `ui_state_pairs.cjs` untouched, edit overlay files only in Plan 01, and run the cheap checks (0.3 s, 6 s, 4 s, 7 s) before any lane.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Theme roles, motion tokens, type floor | CDN / Static (built CSS from `app.css`) | Browser (computed cascade) | Tokens live in two daisyUI theme blocks; Tailwind emits them; tests read source and built CSS |
| Font and brand-asset delivery | API / Backend (`AssetPlug` when mounted, `Plug.Static` standalone) | CDN / Static (committed files) | `forward("/assets", AssetPlug)` serves any mount prefix; `?v=` = sha256 gives immutable caching (V `asset_plug.ex:56-70`) |
| Status vocabulary and ranking | Frontend Server (LiveView function components, `posture_live.ex`) | Database (`Posture.summary` rows) | Words, shapes and rank are server-rendered; no client state |
| Selection, focus, scroll padding | Browser (CSS) | — | Pure CSS plus the existing `OpsModal` hook for initial focus |
| Host isolation | Browser (cascade of ops CSS in host page) | Frontend Server (host root layout decides which routes load the sheet) | Leak is CSS-level (preflight, `:root,[data-theme]`); guarded, not refactored |
| Preview and captures | Tooling (Docker compose, Playwright) | — | `UI-PREVIEW.json`, `ui-review.mjs`, new capture script |

## Standard Stack

No new dependency. Everything below is already in the repo (AGENTS.md: another copy-paste beats another dependency).

### Core
| Library | Version | Purpose | Provenance |
|---------|---------|---------|------------|
| Tailwind CSS (standalone binary) | 4.1.12 | Builds `app.css` to the tracked built CSS | V `scrypath_ops/config/config.exs:52-60`; binary `scrypath_ops/_build/tailwind-macos-arm64` present |
| daisyUI (vendored) | 5.0.35 | Component classes and theme plugin | V UI-SPEC registry table; `assets/vendor/daisyui.js` header |
| esbuild | 0.25.4 | Builds tracked `priv/static/assets/js/app.js` | V `config.exs:41-49` |
| Phoenix LiveView | 1.1.33 | Components and LiveViewTest | V (stack trace in ops test run) |
| Playwright | 1.60.0 (Chromium installed locally) | Computed-style specs | V `npx playwright --version`; `~/Library/Caches/ms-playwright` has chromium builds |
| Hanken Grotesk `ui.woff2`, Sometype Mono `mono.woff2` | pinned subsets | Interface and mono faces | V sha256 `b9929d24…97a14` and `d8c5ea4c…730ea` equal the UI-SPEC hashes |
| Node | 26.10.0 local; CI version not checked (U) | Token test, contrast checker | V `node --version` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Atomic palette commit | Per-property flips | Rejected: stale-claim and built-CSS parity rules make partial states red (V) |
| New `.spec.ts` capture | Extend `ui-review.mjs` | Rejected: `ui-review.mjs` is in the overlay digest and is allowlisted (2 retired hexes) |

**Installation:** none. **Package Legitimacy Audit:** not required, this phase adds no external package (checked: no `mix.exs`, `package.json` or vendor change is planned). Nothing is tagged SUS or SLOP.

## 1. Per-file change map

### 1.1 `scrypath_ops/assets/css/app.css` (2798 lines, V)

| Area | Current lines (V) | Change | Notes |
|------|-------------------|--------|-------|
| Dark theme block | 28-≈70 | Recolor all adopt/derive/local cells per UI-SPEC Color table; add `--ops-sunken`, `--ops-selected`, `--ops-control-edge`, `--ops-status-{failed,retrying,pending,clear}`; `--ops-text-muted` becomes an opaque hex; keep `--color-primary-strong`, `--ops-surface-2` until Plan 06 (their rows are `retire`) | Property currently `--ops-text-muted: color-mix(... 64%, transparent)` at 68 and 112 |
| Light theme block | ≈72-≈115 | Same | `--color-secondary` copper `#a85d2e` becomes `#f0e9e6` |
| `@theme` tokens | 130-203 | Shadows 157-168 (`--shadow-ops-focus` 166, glow 167-168: retire); motion 191-200; `--text-ops-xs` 202 | See motion row |
| Motion tokens | 192-196 | `--duration-ops-instant:80ms; -quick:160ms; -base:240ms; -advance:600ms`; old names as `var()` aliases (`fast`→instant, `standard`→base, `slow`→base, `status`→quick, `instant`) | Consumers: fast 39, standard 6, slow 5 (+1 in lib), instant 6, status 5 (V counts) |
| 11 px floor | 202 (`--text-ops-xs: 0.6875rem`) | Redefine to `0.75rem` | All five sites read the token: 967, 1145, 1748, 1931, 1974 (V). No literal `11px` exists in CSS or lib (V grep) |
| Uppercase | 786-787, 1148-1149, 1510-1511, 1750-1751 | Remove `text-transform` and the letter-spacing paired with it | Lib sites: `ops_ui.ex:401`, `:516` |
| Infinite animations | 896 (`spin 1s linear infinite`, inside `@media (prefers-reduced-motion: no-preference)`), 1616 (`ops-pulse 1.4s ... infinite`); keyframes `ops-pulse` 2143 | Remove; loading becomes a word plus `aria-busy` | Lib: `motion-safe:animate-spin` at `core_components.ex:97` (inside an `@doc` example), `layouts.ex:395,407`; the built CSS also holds daisyUI `skeleton`/`progress` infinite animations that no ops template uses (U) |
| Retired families | `.ops-glow` 774; `.ops-copper-*` 783-808; `.ops-route-mark` 1772-1776 (+dark glow 2354-2362); `.ops-path-*` 1979-2036; glow tokens 2412-2423; `rgba(108,92,231,…)` 2412,2417; `rgba(193,122,62,…)` 2413,2423 | Delete | Gradients at 1773 and 2001 use `--color-secondary` |
| Select chevron | 945 base, 955 `[data-theme="dark"]`, 960 `@media` twin | One `currentColor` two-layer gradient chevron (LD-11) | |
| Alpha | `color-mix(` total 141; with a primary/secondary/info/success/warning/error operand 57; `color:`-family declarations 52 (V counts) | Remove retired-color mixes and all text alpha; container-border, shadow, scrim and scroll-edge alpha stay (UI-SPEC Alpha policy) | `.ops-table-scroll` gradients 1636-1640 stay (allowlisted) |
| Focus | `:focus-visible` 233-236 (2 px solid primary, offset 2 px) | Keep; add `.ops-table-scroll :focus-visible { outline-offset: -2px }`; remove `--shadow-ops-focus` | Comment at 157-159 claims overflow clips box-shadow, not outlines: P-09 measures it |
| Scroll padding | none today (V: no `scroll-padding` in file); Help `scroll-margin-top` 2493 (6rem) and 2596 (7rem) | `html { scroll-padding-top: calc(var(--ops-header-h) + 1rem) }`; delete the two help rules | `--ops-header-h` 4rem, 7rem at ≤640 px (LD-12) |
| Buttons | `.ops-btn` 843-890 (hover rule 851 uses `:not(.btn-error)`; `[aria-pressed="true"]` 861; loading 890) | Control Edge border, Sunken hover, retire `:not(.btn-error)` | Pinned by `design_tokens_contract_test.exs:182-184` |
| Row actions and links | `.ops-text-action` 2500-2501; Help overrides 2597-2599; `.ops-sync-work .ops-text-action` 2617; `.ops-shell a.link-primary` 2428; `.ops-shell a.link:not(...)` 2796 | Underline at rest, one computed tuple, delete the Help `text-decoration:none` overrides and the 2428 override | |
| Notices and verdicts | `.ops-notice-surface*` 557-625; `.ops-tone-*` 625-652; verdict 693-718; `.ops-badge*` 724-770; `.ops-tone-chip` 809-840; metrics 653-692 | 2 px inline-start rule scheme, no tint, no cue dot | `.ops-notice-surface__cue` margin rule is pinned (`design_tokens_contract_test.exs`, "shared actions" test) |
| Search health rows | `.ops-schema-signal-card*` 1656-1731 (variants 1676-1687), dark twins 2295-2335 | Radius 0, hairline bottom border, no shadow, no variants | |
| Wordmark | 1777-1795; dark swap 2247-2262 | Keep swap rules; size to 136 px | `brand_mark` imgs have `width="120"` (`layouts.ex:290,297`) |
| Mono families | 8 `font-mono\|ui-monospace` matches (≈968, 1110, 1759, 1973) | `var(--font-mono)`; `.ops-signal-metrics .ops-time` 2452-2454 to mono | |
| Fonts | none | Four `@font-face` blocks (UI-SPEC Typography) plus `--font-sans`, `--font-mono` in `@theme`; literal `?v=` hashes | Hashes V-equal to the files |
| daisyUI duration overrides | built CSS, not source | See "Motion measurement" below | |
| Reduced motion | 2191-2199 (`0.01ms !important`, iteration count 1) | Keep | P-12 requires ≤1 ms computed under `reduce` |
| Dual dark rules | 23 `[data-theme="dark"]` mentions and 23 `html:not([data-theme="light"])` mentions (V) | Ratchet only shrinks | N-11 |
| Surface-2 consumers | `--ops-surface-2` 25 sites in app.css, 1 in `ops_ui.ex` | Each site is classified: raised surface to `--color-base-100`, hover or recessed to `--ops-sunken`; this is design work, not a find-and-replace | Meaning flips from raised to recessed (CONTEXT D4) |

**Motion measurement (V, fresh Tailwind build in the scratchpad):** the compiled CSS contains these non-token durations that apply to classes ops uses: `.btn` `transition-duration: 0.2s`; `.modal` (0.3 s, 0.1 s); `.modal-box` (0.3 s, 0.2 s); `.checkbox` (0.2 s) and `.checkbox:before` (0.3 s, 0.1 s); `.card` (`outline 0.2s`, used by the theme toggle); `.radio` checked (`radio 0.2s`); `.toggle`, `.toast`, `.menu`, `.swap`, `.filter` (not referenced in ops templates, U); Tailwind `--default-transition-duration: 150ms` (line 29) and the generated `.duration-100/.duration-200` utilities. A probe with the pinned Tailwind showed `@theme inline { --default-transition-duration: var(--duration-ops-quick); }` rewires `transition-colors` and `transition-opacity`, and `duration-(--duration-ops-quick)` generates a utility (V). Use the P-12 computed scan as the authority for which selectors need overrides; do not trust this list as complete.

### 1.2 `components/ops_ui.ex` (1952 lines, V)

| Site | Lines | Change |
|------|-------|--------|
| `ops_page_header` | 23-35 (h1 classes 28; subtitle `text-base-content/70` 32) | h1: `--text-ops-h1` 1.75rem, new `--leading-ops-title` 1.2, tracking -0.01em; subtitle to muted token |
| `ops_command_hint` | 45-59 (icon 54, `⌘K` 56) | Glyph only ≤360 px; `⌘` is in neither font (named fallback) |
| `ops_button`, `ops_refresh_button`, `ops_refresh_control`, `ops_link_button` | 199-205, 230-248 (icon 244), 271-286, 302-308; `variant` values list incl. `:danger` at 184, 219, 260, 294 | Remove `:danger`; refresh button loses the glyph, two label spans swapped by `[aria-busy="true"]` (hook already sets it, `ops_hooks.js:24-25`, V) |
| `ops_notice`, `ops_status` | 321-335, 351-387 (cue span 368-373; body `text-base-content/80` 377) | 2 px rule scheme; drop cue; `neutral` attr stays |
| `ops_metric`, `ops_metric_grid`, `ops_tone_chip` | 398-417 (uppercase 401, cue icon 406-412), 432-438, 456-463 | No template calls them (UI-SPEC): restyle or leave unreferenced without retired styles |
| `ops_badge`, `badge_class` | 474-480, 1945-1951 | Plain neutral text for non-sync labels |
| `ops_verdict` | 502-547 (label uppercase 516; icon 524-531; body `text-base-content/75` 534); helpers 1927-1943 | New optional `status` attr renders `ops_sync_status`; delete `verdict_icon*`; `data-testid="ops-verdict-icon"` is pinned (see 1.8) |
| `ops_intent_card`, `ops_empty_state`, `ops_empty_hero`, `ops_config_empty`, `ops_loading` | 644, 679, 701 (id contains `hero-heading` at 706, **not an icon**), 815, 757-785 (`text-base-content/65` inside) | Drop icons and flag; loading is a literal word plus `aria-busy`, static bars |
| `ops_segmented_control` | 1110-1138 (`bg-primary text-primary-content shadow-ops-mid` 1129) | Selection Signature |
| `ops_time` | 1276-1313 (clipboard icon 1299, `ops-time__affordance`) | Mono value; affordance opacity .45 to full opacity |
| `ops_code_block`, `ops_help_link`, `ops_inline_code` | 1417-1470 (clipboard 1433, shimmer 1446), 1473-1487 (external glyph 1477), 1489 | Keep glyphs; `.ops-code-block--shimmer` (css 2039-2060) needs a motion audit |
| `ops_modal`, `ops_sheet` | 1512-1584 (JS.transition `duration-100` + `time: 120` at 1532-1533; close icon 1548), 1586-1650 (1604-1605; 1626) | Tokens: `duration-(--duration-ops-quick)` and `time: 160` |
| `button_classes` | 1785-1798 (`variant == :danger && "btn-error"` 1794) | Remove danger |
| Doc catalog | `scrypath_ops/assets/css/DESIGN-TOKENS.md` | **Must list every `def ops_*` in backticks** or `design_tokens_contract_test.exs:138-148` fails: add `ops_sync_status` (and `ops_row_action` if created) |

`text-base-content/NN`: 33 uses: ops_ui.ex 19, control_room_live.ex 2, posture_live.ex 6, search_live.ex 1, sync_drift_live.ex 5 (V).

### 1.3 `layouts.ex`, `core_components.ex`, `root.html.heex`, router, assets

| File | Lines (V) | Change |
|------|-----------|--------|
| `layouts.ex` | nav icons: markup 251-253 and 267-269 (help), `nav_sections` 329-345 (`nav_item_icon/1` 341-345); `brand_mark` 284-303 (`width="120"` 290, 297); reconnect flashes 367-415 (`hero-information-circle` 368, spinners 395, 407); theme toggle `card` 422, icons 435, 448, 461; non-shell landing with a `btn btn-primary` 146 | Remove nav icons and the six names; lockup 136 px (`width="136"`, `flex: none`); flash icon and spinner removal (text stays) |
| `core_components.ex` | flash icons 62-63; x-mark `opacity-40 group-hover:opacity-70` 74; `@doc` example with `animate-spin` 97; JS transitions `time: 240` 144, `duration-200` 146, `time: 120` 157, `duration-200` 159 | Flash loses its leading icon; the close glyph at 40% opacity is a non-text contrast risk (U): use full opacity; fix the doc example or the `animate-spin` grep gate fails |
| `root.html.heex` | `<link rel="icon" href="/favicon.svg">` line 7; CSS/JS links 11-18 with `AssetPlug.asset_version/1`; inline theme script 20-96 | Add ICO link and `<link rel="preload" as="font" type="font/woff2" crossorigin href="/assets/fonts/ui.woff2?v=#{AssetPlug.asset_version("assets/fonts/ui.woff2")}">` in this standalone layout only |
| `router.ex` | forwards 26-29 (`/assets`, `/images`, `/favicon.svg`, `/favicon.ico`) | No change (V: serves any prefix) |
| `endpoint.ex` / `scrypath_ops_web.ex:20` | `Plug.Static only: static_paths` (`assets fonts images favicon.svg favicon.ico robots.txt`) | No change |
| `assets/js/app.js` | 106 `topbar.config({barColors: {0: "#29d"}…})` | Read computed `--color-primary` at `show()`; the tracked `priv/static/assets/js/app.js` (342 KB) must be rebuilt; the ecommerce host `app.js` has no topbar (V grep), nothing to mirror. `#29d` is also one `raw-hex` row in `scripts/ci/ui-literal-baseline.json` (V): run the literal ratchet after |
| `priv/static` | `favicon.ico` 152 B, `favicon.svg` 981 B, `images/{logo,scrypath-wordmark,scrypath-wordmark-inverse}.svg` (V) | Replace with brand bytes (UI-SPEC Brand Assets); keep names; four p187 allowlist entries (3 hits each) drop to 0 |
| `scrypath_ops/README.md` | exists (V tracked) | Host note (D6/D9) |

### 1.4 LiveViews

| File | Lines (V) | Change |
|------|-----------|--------|
| `posture_live.ex` (694) | scenario list 246-262 (add `"all-statuses"`); verdict 278-284 (kind from `Posture.badge_kind`); row badges 344-356; groups with icons 393-398, 442-454; error row icon 489-490 and class string 489; rank 522-540 (`posture_row_rank`: error 0, backend failed 1, queue unobserved 2, queue failed 2, queue retrying 2, clean 3); badge helpers 650-678 | `ops_sync_status` per row (most urgent) or `.ops-condition`; new rank constant (LD-8); verdict kind from worst row (LD-10); dense facts line; `ops_time` mono |
| `failed_sync_live.ex` (1231) | flash `Retry failed: #{inspect(reason)}` 352; `state_label` 682-683; row badge 1035-1037; `data-state` 1031; Retry `ops_button` 1099-1109 (`data-testid="failed-sync-retry"`); receipt `ops_status kind={:info}` 1113-1132; confirm modal 1191-1224 (title 1191, `initial_focus="[data-ops-modal-cancel]"` 1194, danger button 1224) | Component; Retry becomes `<button class="ops-text-action">`; neutral-rule receipt; confirm label `Retry deleting {N} document(s)`; new error sentence |
| `sync_drift_live.ex` (2470) | prefix `"Index promotion blocked: #{promotion_eligibility_copy(...)}"` 290 and `"Promotion is blocked: …"` 1579 (doubled); flash 1256; `promotion_reason/1` 1553-1569; activity icons 1713-1714, 2013, arrows 2020, 2028; promote trigger 2331; modal Cancel 2459-2461, danger 2463 | One "blocked"; text `→`; status for failed and pending signals; confirm `Replace live index with target` |
| `search_live.ex` (2062) | `search_status_badge_label` `"Failed"` 1205; chevron 1350; manage trigger 1395; segmented 1418; Run search 1494-1499; badge 1560-1565; save modal 1753-1786; row actions 1844-1864; Rename submit `:primary` 1898; delete confirm `:danger` 1930; Import glyph 1967 | `Search failed`; Rename outline; confirm `Delete saved search permanently`; row actions text |
| `control_room_live.ex` (252) | verdict 140-184; primary button 165; intent cards 191-200 | status attr, drop card icons |
| `help_live.ex` (221) | `ops-help-heading` icons at 25-26, 67-68, 86-87, 144-145, 176-177 | Headings and links only |
| `test/support/phase173_fixture_source.ex` | **two copies** (V): `scrypath_ops/test/support/` and `examples/scrypath_ecommerce/test/support/` (different schema modules; ecommerce uses `ScrypathEcommerce.Catalog.Product`) | `all-statuses` must be added to both (scenario guard list at lines 86-103 and `allowlist/1`, `tasks_for/1`, `jobs_for/1`) plus the select in `posture_live.ex`; both files are overlay files |

### 1.5 Grep gates (E-12) are cheap but have false positives (V)

`hero-` matches `ops-empty-hero-heading` at `ops_ui.ex:706`; anchor E-10 on `<.icon name=` and `icon="hero-` sites. `animate-spin` also matches the `@doc` example at `core_components.ex:97`. `infinite` appears in comments at app.css 2037. `copper` appears in the comment at 2377 and test files.

### 1.6 Other source and docs touched

`dev_router.ex` (test fixture mount 58-71, no change), `ecommerce router.ex` (phase173 mount `Mix.env() == :test` only, V 28-47), `examples/scrypath_ecommerce/lib/.../layouts.ex` (root layout loads ops CSS only on `/admin/search*`, V 22-53, no change), `scrypath_ops/assets/css/DESIGN-TOKENS.md` (42 retired-value hits, p187), root `DESIGN.md` (7 hits, p187), `scrypath_ops/assets/css/contrast-pairs.mjs` (MUTED_PAIRS, surface lists at 619-620), `examples/scrypath_ecommerce/contrast-checker.mjs` (Guard 1 at 687-706, Guard 2 at 708-790, self-test fixtures at 573 and 595-650).

### 1.7 Token map and ceilings (V)

`token-map.json`: 37 rows; **there are no rows for the new properties**, so adding `--ops-sunken`, `--ops-selected`, `--ops-control-edge`, `--ops-status-*` requires new rows in the same commit (parity both ways). Info/success/warning/error rows are `local` with `target` `#5ca9e6 #4fae74 #d9a441 #d96262 #0c0f14` and must change to the brand status hexes (8 targets, LD-1). `PENDING_CEILING 38`, `HEX_OUTSIDE_CEILING 34`, `ALLOWLIST_CEILING 22`, `HITS_CEILING 485` (V `ui-tokens.test.mjs:60-69`). Allowlist: 12 p187 entries total 154 hits (DESIGN.md 7, DESIGN-TOKENS.md 42, app.css 34, built CSS 51, favicon 3, logo 3, two wordmarks 3+3, ui-review.mjs 2, three specs 2+1+3), p188 3, p189 4, retire-last 324 (brandbook 270).

### 1.8 Existing tests and specs that pin old values (V, file:line)

**scrypath_ops ExUnit (cheap, run in `mix verify.ops_ui`)**

| File:line | Pins | Disposition |
|-----------|------|-------------|
| `design_tokens_contract_test.exs:116,132` | `.ops-modal` `transition: opacity var(--duration-ops-fast)` | Alias keeps the name; re-point to the new alias value |
| `:133` | `--duration-ops-fast: 120ms;` | Rewrite to the alias form |
| `:138-148` | catalog lists every `def ops_*`; `"The existing 11px/12px scale remains reserved"` | Add `ops_sync_status` to DESIGN-TOKENS.md; rewrite the 11 px sentence |
| `:182-184` | `.ops-btn:hover:not(:disabled):not(.btn-primary):not(.btn-error)`, `background: var(--ops-surface-2)` | Rewrite to Sunken |
| `:191-203` | marker comment "Cascade-safe operator text contrast." and `.ops-shell .text-base-content\/60` override | Rewrite (classes go away) |
| `:161` | `.ops-notice-surface__cue` has `margin-top: var(--spacing-ops-1)` | Retire with the cue dot |
| `shell_chrome_token_contract_test.exs:84-87` | `.ops-nav-item-active { background: var(--ops-selection) }` | Keep (`--ops-selection` kept one milestone) |
| `:90,96` | `.ops-nav-item-active` dark `box-shadow … var(--shadow-ops-glow)` (explicit and system dark) | Replace with Selection Signature assertion |
| `:102-119` | wordmark dark swap rules | Keep |
| `:121-141` | overlay shadows `var(--shadow-ops-overlay), var(--shadow-ops-panel-dark)` on `.ops-cmdk__panel`, `.ops-flash` | Keep (shadows survive) |
| `surface_depth_token_contract_test.exs:43-56` | dark `--ops-bg < --ops-surface-1 < --ops-surface-2` | Rewrite: `--ops-sunken < --ops-bg < --ops-surface-1` (Night Sunken `#110a14`, Night `#160e19`, Night Panel `#201624`) |
| `:58-84` | `.ops-data-card` (58) and `.ops-result-row:not(.ops-search-hit)` (72) dark fill `var(--ops-surface-2)` | Re-point to the role you choose |
| `:86-120` | dark hover-border boost "primary 55%" (86), base shared hover "primary 32%" (100) | Rewrite (alpha tints retired) |
| `motion_contract_test.exs:56-145` | `.ops-path-*`/`ops-code-block--shimmer` blocks animate only transform/opacity/box-shadow; durations are tokens; dark glow mirrored | Rewrite around the new token-only rule (E-18); drop glow case |
| `ops_shell_contract_test.exs:131` | exactly 2 `ops-nav-item-active … aria-current="page"` | Keep the class and count |
| `:152-153` | wordmark srcs `/ops/images/scrypath-wordmark(-inverse).svg` | Keep (file names frozen) |
| `:302,310` | flash `hero-information-circle` or 2 `<svg>`; `hero-exclamation-circle` or 2 `<svg>` | Rewrite (flash loses its icon, one svg remains) |
| `posture_live_test.exs:140-158` | `mt-ops-2 flex items-start gap-ops-2 text-ops-body text-error`, `mt-ops-1 size-4 shrink-0`, `text-ops-body text-base-content/75`, "Queue not used" | Rewrite |
| `:160-172` | "Meilisearch tasks failed", "Sync jobs failed", `.ops-badge-error`, `[data-testid='ops-verdict-icon'][data-state='warning']` | Rewrite to status words |
| `:174-184` | healthy row `refute "ops-badge-neutral"/"ops-badge-success"` | Rewrite (Clear shows only with observation) |
| `:395` | fetch failures sort first, ties alphabetical | Semantics change: unverified now ranks after Failed, Retrying, Pending |
| `control_room_live_test.exs:152-204` | verdict copy "No failed sync jobs or Meilisearch tasks were found across 2 schemas." | Copy unchanged; add status assertions |
| `failed_sync_live_test.exs:413,466,560,599,718,727` | `refute "btn-primary"`; "Retry queued"; "Confirm delete sync work" | Keep strings; add status component assertions |
| `sync_drift_live_test.exs:262,301,394,494` | `data-status-kind` success/error/warning; flash `=~ "Index promotion blocked"` | Keep hooks; add exactly-once "blocked" |
| `:328,343` | trigger button `#promote-target-index` text "Promote target index" | Trigger label stays; the modal confirm label changes |
| `search_live_test.exs:393` | `ops-badge-error` on run failure | Rewrite with `Search failed` |
| `search_saved_searches_test.exs:339,408-451` | row actions `Load Rename Export Delete`; `button[aria-label='Delete A']` | Row action buttons stay; confirm label changes |

**Root tests (`MIX_ENV=test mix test … --exclude contrast_child`, 7.4 s wall, V)**: `ui_contrast_contract_test.exs:98` (wrapper), `:122-156`, `:157-230` (clone-based `contrast_child`; "muted alpha drift" mutation at 211-217 owns the `64%` pin), `ui_tokens_contract_test.exs` (mirror cases 146-243, brandbook doc parity 411-436, two retired hexes at 425-426), `ui_tokens_helper_test.exs`, `test/support/ui_tokens.ex`, `ui_literal_contract_test.exs` (ratchet; baseline holds one `raw-hex` row for `app.js`).

**Node**: `ui-tokens.test.mjs` (ceilings and flips), `contrast-checker.mjs` Guard 1 (21 tokens including primary-strong), Guard 2 (muted alpha lockstep), self-test fixtures.

**Playwright**: see Section 3.3 for which run in the required lane.

## 2. Build, tracking, serving

### 2.1 Build commands and cost (V unless noted)
- CSS: `cd scrypath_ops && mix tailwind scrypath_ops` or `./_build/tailwind-macos-arm64 --input=assets/css/app.css --output=priv/static/assets/css/app.css`: **1.4 s wall, offline** (local plugins at `assets/vendor/`). Alias `mix assets.build` = `compile`, `tailwind scrypath_ops`, `esbuild scrypath_ops`; `esbuild-darwin-arm64` is present (U on JS build time, expect seconds).
- Output is unminified. A fresh build with no source edit already differs from the tracked file in about 466 diff lines (the tracked file lacks daisyUI's `.tab` block and has different property ordering), so the first rebuild commit shows a noisy diff. The token test is token-level only (V).
- Tracked artifacts: `priv/static/assets/css/app.css` (200,700 B) and `priv/static/assets/js/app.js` (341,976 B); `.gitignore` re-includes both (V `scrypath_ops/.gitignore`).
- The built CSS is read by the token test (`BUILT_CSS`, `ui-tokens.test.mjs:54`): three theme emissions must equal source token values and carry no extra `color-*`/`ops-*` token.
- Worktrees: the Tailwind binary and `_build` are per checkout (gitignored); a fresh worktree needs `deps/` and `_build/` copied (memory note) or `mix assets.setup` (network). U on a worktree run.

### 2.2 Serving at nested prefixes
- `forward("/assets", ScrypathOpsWeb.AssetPlug, path_prefix: "assets")` (V `router.ex:26-29`); AssetPlug rejects `..`, `.` and empty segments and checks `inside_static_dir?` (V `asset_plug.ex:21-52`); `MIME` maps `.woff2` to `font/woff2` (V `deps/mime/lib/mime.ex:95`); `cache-control: public, max-age=31536000, immutable` only when `?v=` equals the file sha256, else `max-age=0, must-revalidate` (V `:56-70`).
- CSS `url("../fonts/ui.woff2?v=<sha256>")` resolves against `<mount>/assets/css/app.css` to `<mount>/assets/fonts/ui.woff2` at any depth. The hash must be literal in `app.css`; the test recomputes it (E-14, N-10).
- Standalone: `Plug.Static at: "/" only: ~w(assets fonts images favicon.svg favicon.ico robots.txt)` serves the same paths without immutable `?v=` semantics (U on headers).
- Host root layout builds the sheet URL as `/admin/search/assets/css/app.css?v=#{AssetPlug.asset_version("assets/css/app.css")}` (V `examples/.../layouts.ex:46-51`). Because AssetPlug re-reads and re-hashes the file per request, base64 inlining would be costly (CONTEXT).
- Real depths available in tests: `/ops` (standalone test router, ConnTest) and `/admin/search` (ecommerce host). `AssetPlug` itself only sees `path_info` after the forward consumed the prefix, so a synthetic third depth proves nothing new; assert URL resolution with `URI.merge/2` for N prefixes and real 200s at the two real depths.

### 2.3 Mounted-host test requirements (V on what exists, U on placement)
- Ops ExUnit can GET `/ops/assets/fonts/ui.woff2` and `mono.woff2` (200, `font/woff2`, immutable with matching `?v=`), assert the CSS `?v=` equals the hash, and assert preload only in `root.html.heex`.
- `examples/scrypath_ecommerce/test/.../page_controller_test.exs` already tests mounted favicon and CSS-link behavior at `/admin/search` and would take the `/admin/search/assets/fonts/ui.woff2` check cheaply, **but no workflow or verify task runs that file** (V grep: only `e2e_controller_test.exs` is wired, via `verify.phase107`). Put the required assertion where a required lane runs it: a `request.get` in `harness.spec.ts`/`operator.spec.ts` (the `focused` scope run by `ecommerce-mounted (required)`, V `capability.ex:17-23`, `Makefile:157`, `docker-playwright.sh:253-255`).

### D-1 Docker finding (V): images lose the fonts
`examples/scrypath_ecommerce/Dockerfile:32` runs `rm -rf scrypath_ops/priv/static/assets …` in `asset_builder`; `runtime_test` (lines 83-105) and `runtime_prod` (46-70) run `rm -rf scrypath_ops/priv/static` and copy `/app/scrypath_ops/priv/static` from the builder, which holds only `assets/css` and `assets/js` plus the non-asset statics. `.dockerignore` does not exclude the fonts. No script or test pins the `rm` line (V grep). Fix before any Docker lane serves the new CSS: delete only the generated subtrees (`scrypath_ops/priv/static/assets/css`, `…/assets/js`) so the tracked `assets/fonts/` survives, then add a hosted check (P-14 or the `request.get`) that fails on a 404 font. Compose dev (bind mount) is unaffected.

## 3. Test architecture for the 53 assertions

### 3.1 Placement and cost (cheapest first)

| Level | Where | Cost (V) | Needs |
|-------|-------|----------|-------|
| N-02..N-07, N-09 | `contrast-checker.mjs` (+ `contrast-pairs.mjs`) | 0.34 s | Node |
| N-01, N-08, N-10, N-11, N-12, N-13 | `ui-tokens.test.mjs` (42 tests now) | 5.8 s | Node + git |
| E pure-regex (E-10, E-12, E-13, E-14, E-17, E-18) | new `scrypath_ops/test/.../reskin_static_contract_test.exs` plus the four existing CSS tests | 3.8 s test time (24 tests) | local Postgres |
| E LiveView/DOM (E-01..E-09, E-11, E-15, E-16, E-19) | new `ops_sync_status_test.exs`, existing live test files | full ops suite 45.7 s test time, 55 s wall, 329 tests + 2 doctests | local Postgres |
| Root `ui_*` | `MIX_ENV=test mix test test/mix/tasks/ui_{contrast,tokens,literal}_contract_test.exs test/mix/tasks/ui_tokens_helper_test.exs --exclude contrast_child` | 4.7 s test, 7.4 s wall | none |
| `contrast_child` clone tests + literal policy needing fetch | inside `mix verify.repository_contracts` | 179.5 s (Phase 186 receipt) | escalated permission (fetch) |
| P (Playwright) | two new specs under `examples/scrypath_ecommerce/e2e/` | not measured; `ecommerce-e2e` job cap is 30 min, cold `ecommerce-mounted` about 18 min (prep) | Docker, or a host-native standalone ops (U) |

New Node tests are picked up by the existing ExUnit wrapper (`node --test` runs the whole file; wrapper needs 7 named passing lines and `# fail 0`), so no CI step is added (V 186 verification). Ops has no browser in ExUnit; computed-style needs Playwright.

### 3.2 Fixtures and scenarios (V)
- Standalone and mounted `phase173` fixture host: `/ops/phase173/health` and `/admin/search/phase173/health`, `Mix.env() == :test` only (`dev_router.ex:58-71`, ecommerce `router.ex:28-47`). Scenarios (15): healthy, failed, unavailable, unknown, empty, partial, long, invalid-time, queue-unused, refresh-failure, refresh-disabled, processing, backend-failed, retrying, completed.
- `all-statuses` needs five schemas, but the fixture today defines three modules per copy (`Phase173FixtureSchema`, `PartialSchema`, `VeryLong…`) and per-index task/job maps keyed by index uid: add schemas or reuse by scenario in **both** copies.
- E2E seed scenarios `all_green`, `incident`, `empty` via `/dev/e2e/seed` (V use in `ui_iteration3.spec.ts`) for Failed sync rows and Control Room verdicts; `helpers/theme-grid.ts` has `THEME_MODES`, `VIEWPORTS` (390 and 1440; **no 1280**), and `goto*` helpers; `helpers/operator-ui.ts` has a min font-size probe.
- Standalone Docker fixture: `compose.phase173.yaml` (`standalone_ops` on 4003). Host-native equivalent: `cd scrypath_ops; MIX_ENV=test mix ecto.create/migrate; PHX_SERVER=true SCRYPATH_OPS_PORT=<free> mix phx.server` against local Postgres, which is exactly what `phase173-standalone-entrypoint.sh` runs (V). I did not start it (U that Playwright against it works on macOS).

### 3.3 Which Playwright specs gate what (V)
`ecommerce-mounted (required)` runs only `focused` = `harness.spec.ts` and `operator.spec.ts`. The pin that changes is **`operator.spec.ts:280`** (`confirmation.getByRole("button", { name: "Promote target index", exact: true })`; the trigger at 265/322 keeps its label). `operator.spec.ts:138` `failedRow.getByRole("button", { name: "Retry" })` still holds if Retry stays a `<button>`. Everything else runs in `ecommerce-e2e (advisory)` (schedule and dispatch only), which the maintainer requires green on the head SHA: `phase173_shell` (L79 reads `--ops-selection`; L188 `rgb(17, 20, 25)` / `rgb(243, 245, 248)`; L311), `phase173_status_actions` (L48,71-92,102,139,169: "Meilisearch tasks failed", "Sync jobs failed", `.ops-badge-*`, `ops-verdict-icon`), `admin_path_motion` (whole spec is about `.ops-path-*` and glow: delete or rewrite), `admin_surface_depth` (consts L47-49, L270, L296-348 copper, L541-543, L899-915), `admin_shell_chrome` (L416-471; sheet `Delete` exact at 434,438), `ui_baseline` (L120-122 `Delete` exact), `helpers/ui-preservation-states.ts` (L642-698, 817, 1359 `Delete`).
`closeout-attestation` requires the files `ui_followup`, `ui_iteration3`, `phase173_shell` (with mounted and standalone entrypoints) and 13 named cases (7 in `ui_followup`, 6 in `ui_iteration3`) to remain in the inventory (V `ecommerce_evidence.cjs:545-580`): do not rename or delete them. `admin_path_motion` and `admin_surface_depth` are not required suites. Mandatory cases pin kept hooks: `[data-tone=error]`, `[data-tone=retrying]`, `.ops-signal-counts dt svg` equals `dt` count, "No pending or failed tasks." (V `ui_followup.spec.ts:65-76`, `ui_iteration3.spec.ts:137`).

### 3.4 Overlay digest (V)
`PRESERVATION_FIXTURE_FILES` (`ecommerce_evidence.cjs:65-91`) includes both fixture sources, `ui-review.mjs`, `helpers/ui-preservation-states.ts`, `helpers/theme-grid.ts`, `helpers/e2e.ts`, `playwright.config.ts`, `package.json`, `Dockerfile.e2e`, compose files and `scripts/ci/ui_state_pairs.cjs`. CI recomputes the digest from the working tree (`ci.yml:719-720`), so editing them is safe for CI. It only matters for a before/after pair flow where both sides must use the same overlay. Edit them once, in Plan 01, and never again.

## 4. Recommended decomposition

Sequential waves (one plan per wave) because every plan after 01 touches `app.css` or `ops_ui.ex` and `use_worktrees: true` would create merge conflicts. Each plan ends green on its listed gate; commit order inside a plan keeps `HITS_CEILING` and `applied` flags in lockstep.

| Plan | Requirements | Contents | Green gate (cheapest first) |
|------|--------------|----------|----------------------------|
| 01 Evidence prep and baseline | GATE-03 (refresh half), SKIN-08 (before half) | Add `all-statuses` to both fixture copies and the `posture_live.ex` select (test-only, no rendered change); replace the 2 old hexes in `ui-review.mjs:782` and drop its allowlist entry; make `ui-preservation-states.ts` accept both `Delete` and `Delete saved search permanently` (and any other confirm label that changes) so overlay files never change again; write the 1280-capable capture script (`.mjs`, not collected by Playwright); reconcile and refresh `ui/next`; `ui:preflight`; take the before captures from the baseline commit | N, E pure-regex, ops suite, root `ui_*`; no CSS change so no rebuild |
| 02 Fonts, assets, type floor | SKIN-02, SKIN-03, SKIN-06 | Dockerfile fix (D-1); four `@font-face`, `--font-*`, h1 28/700/1.2, `--text-ops-xs`, weight snapping, mono selectors, `data-ops-identity`; brand lockups, favicon SVG and ICO, `root.html.heex` links and preload, `brand_mark` 136 px; README host note; remove 4 asset allowlist entries; rebuild CSS; E-13, E-14, E-15, N-10 (font part) | N (token test unchanged values), E, root `ui_*`, `mix verify.brand`, then Docker `verify-mounted` once |
| 03 Palette and guards (atomic) | SKIN-01, A11Y-01 | Both theme blocks, new properties and rows, opaque muted token, 8 info/success/warning/error targets, `applied` flips, rebuilt CSS, `max_hits` and ceilings, contrast Guards 1/2 and N-03..N-06, N-08, mirror remap (`brandbook/tokens/tokens.json` `ops.*`, `daisyui-theme.example.js`, brandbook hit counts), pinned-test rewrites for the `ui_*` and surface-depth tests, DESIGN-TOKENS.md and DESIGN.md | N first, then root `ui_*` with `--exclude contrast_child`, ops regex, then `verify.repository_contracts` |
| 04 Status vocabulary | STAT-01..03, SKIN-07 | `ops_sync_status`, `.ops-condition`, rank constant, verdict kind rule, notice/verdict scheme, dense facts, the two copy bugs, flash strings; DESIGN-TOKENS entry; E-01..E-06, E-11, E-17, E-19 | E and root `ui_*` |
| 05 Buttons, actions, selection, focus, icons | SKIN-04, A11Y-02, A11Y-03 (part), SKIN-05 (icons, spinners) | Remove `:danger`, confirm labels, `ops_row_action` or class, links, Selection Signature, Control Edge borders, inset ring, scroll padding, nav and verdict icon removal, loading words, `operator.spec.ts:280` and the four `Delete` pins | E, then Docker `verify-mounted` (required lane) |
| 06 Retire and rewrite | SKIN-05, A11Y-01 (N-07, N-12), A11Y-03 | Delete path, copper, glow, route-mark, tint mixes, text alpha, `text-base-content/NN`, `surface-2`, `primary-strong`, glow tokens, `#29d`; motion alias period and daisyUI duration overrides; grep gates; N-12, N-13, E-12, E-18; rewrite `motion_contract`, `shell_chrome`, `design_tokens`, the three advisory specs and `phase173_status_actions`; delete retire rows and their mirror entries; allowlist to the lowest honest count | N, E, root `ui_*`, `verify.repository_contracts` |
| 07 Host contract and delivery | A11Y-04, GATE-03, SKIN-08, P-level | `ops_reskin_contract.spec.ts`, `ops_host_contract.spec.ts`, N-11 ratchet, README notes; full Docker e2e; after captures; refresh preview to the head; dispatch CI on the exact head; Draft PR with the inventory and gates list | Everything, once, on the exact head SHA |

### Ordering constraints
1. **Overlay files only in Plan 01** (fixtures, `ui-review.mjs`, preservation helper, `theme-grid.ts`). `ui_state_pairs.cjs` is never edited.
2. **Dockerfile fix before any Docker lane serves the new CSS** (Plan 02). Verify with a font request, not by eye.
3. **Palette is one commit.** A row's `applied` flag, its CSS value, the rebuilt built CSS, the `max_hits` of `app.css` and the built CSS, and `HITS_CEILING` all change together. The test prints the numbers (`holds N retired values, under its max_hits M`).
4. **Retire rows are deleted with their property** (Plan 06), and the DTCG mirror and the example JS drop the same entries in the same commit (mirror parity is both ways, V `ui_tokens.ex:469-530`).
5. **Motion alias period:** rename tokens in Plan 03 or 06 only together with `design_tokens_contract_test.exs:133`; old names stay as `var()` aliases.
6. **Cheapest-first rule:** after any CSS edit run, in order, rebuild (1.4 s), contrast checker (0.3 s), token test (6 s), ops regex tests (4 s), root `ui_*` (7 s), then the ops suite (55 s), then lanes.
7. **Required-lane label pin:** `operator.spec.ts:280` changes in the same commit as the confirm label (Plan 05).
8. **Literal ratchet:** HEEx edits must not add `[...]` arbitrary utilities or inline styles. The baseline has 6 arbitrary values in `layouts.ex` `theme_toggle`, 2 in `ops_ui.ex`, 2 inline styles, one `z-50`; restructuring `theme_toggle` changes the ratchet context keys. Whether `duration-(--x)` is counted as arbitrary is U: run `ui_literal_contract_test.exs` after the first use.

### Highest cascade risk
(1) Plan 03, because token-map flips, built CSS, three allowlist numbers, two contrast guards, mirror files and four test files must agree. (2) D-1: browser lanes appear healthy while fonts are missing. (3) Required-lane Playwright pin and `closeout-attestation` mandatory cases. (4) The overlay digest, which silently invalidates a before/after pair. (5) HEEx restructure vs the literal ratchet.

## 5. Preview, preflight and captures (read-only inspection, V)

- `.planning/UI-PREVIEW.json` names checkout `/Users/jon/projects/scrypath/.claude/worktrees/ui-experience-reconciliation`, branch `ui/next`, container `scrypath_ecommerce-web-1`, compose project `scrypath_ecommerce`, `seed_on_start: false`, status "running" as of 2026-10-24.
- Worktree state: HEAD `ebed49b5`, an ancestor of main (12 commits behind, includes the Phase 186 merge). Dirty: `scrypath_ops/priv/static/assets/css/app.css` +80 lines (the hunk is the daisyUI `.tab` block, identical in kind to the difference my fresh build showed, so it is a regenerable watcher artifact, U on the full diff) and untracked `examples/scrypath_ecommerce/priv/playbooks/my-search.json` (the maintainer's unimported file: preserve). Main also changed the built CSS (`8beb3ed0`), so a fast-forward needs that file restored first.
- `npm run ui:preflight` from that worktree's demo directory fails now: `error: no such object: scrypath_ecommerce-web-1` (V, ran it; it is read-only). `node_modules` exists in that worktree. `UI_REVIEW_CONTAINER` selects another container.
- Docker (V): no scrypath_ecommerce containers, images or volumes exist. Six stale scrypath networks exist (`scrypath_ecommerce_default`, `scrypath_default`, `scrypath-ui-v142_default`, `scrypath_ecommerce_verify_full_53268690_81314_default`, `scrypath_phase174_d4395f2_review_default`, `scrypath_phx_meili_net`). `docker system df`: 312 images 118.6 GB (62.5 GB reclaimable), build cache 9 GB. Port 4002 has no listener (V lsof). Other projects' containers (threadline, sigra, mailglass, playstead, getfluent, dev_proxy) are running: do not touch.
- **"Preview data survives" is vacuous:** nothing persisted in Docker; the only retained data is `my-search.json` in the worktree.
- Refresh involves: (1) fetch (network; escalated), save or restore the built-CSS artifact, fast-forward `ui/next` to the chosen commit; (2) `docker compose -f compose.yaml -f compose.dev.yaml -f compose.preview.yaml up -d --no-deps --force-recreate web` from the worktree demo dir plus postgres and meilisearch (memory: dev container recompiles source, runs migrate and the entrypoint; `compose.preview.yaml` sets `DEMO_SEED_ON_START: "0"`), on a free `WEB_PORT`; (3) cold image build (no images exist; asset_builder plus deps compile; the memory note's "8 s rebuild" only holds warm, so expect minutes, U); (4) escalated permission for the Docker socket and Buildx; (5) cleanup per AGENTS.md. Note the dev compose runs `mix tailwind scrypath_ops --watch`, which rewrites the tracked built CSS in whichever checkout is mounted: mount the worktree, never the feature checkout, or commit the rebuilt CSS before capturing.
- **Capture gap (V):** `ui-review.mjs` captures 1440, 768 and 390; `ui_preservation.cjs` also 1440, 768, 390; no tool does 1280. The retained preview is dev mode, where the fixture routes do not exist (`Mix.env() == :test` only), so the `all-statuses` state needs a test-mode stack (compose base `web` is `MIX_ENV=test` with `/dev/e2e/seed`). Resolution in Open Question 1.

## 6. Host-contract guards (A11Y-04)

What exists (V): the demo host loads the ops sheet only on `/admin/search*` through `ops_admin_path?` (`examples/.../layouts.ex:22-73`), sets its inline theme script only there, and scopes its own CSS to `body.scrypath-demo` (`assets/css/app.css:13`); the host stylesheet itself also loads on ops routes (line 44). No CSP is set anywhere (V grep: only `put_secure_browser_headers`; Phoenix's default adds no CSP, U). No sentinel element, no host-override fixture, no unscoped-selector baseline exists. `helpers/theme-grid.ts` has the theme modes.

Leak measurement (V, naive parse of a fresh build): 1154 style rules; 606 ops-scoped, 320 daisyUI/Tailwind class rules, 425 element/other, and 28 rules (52 selector parts) targeting `*`, `::…`, `:root`, `:host`, `html`, `body` or `[data-theme]` outside ops (includes preflight, `:root:has(.modal-open …)`, `:root, [data-theme]`, `[data-theme="dark"]`, `html:not([data-theme="light"])`). Use this as the ratchet's starting shape, but define "unscoped" in the test and record the first-run count.

To build:
- N-11 in `ui-tokens.test.mjs`: parse built CSS, count unscoped selectors and dual dark rules, compare to a committed baseline that may only shrink; plant a failing case.
- P-17 spec: (a) on `/` and other non-ops routes the document has no ops stylesheet and `getComputedStyle(documentElement).getPropertyValue("--color-primary")` is empty; (b) sentinel computed style unchanged across the six combinations (`colorScheme` x stored `phx:theme`); (c) host override wins: inject `:root{--color-primary:#123456}` after the ops sheet with `addStyleTag` and read `.btn-primary` background; (d) CSP: `page.route` adds `Content-Security-Policy: font-src 'self'` only (not `default-src`, which would also block the inline theme scripts already in both root layouts), then assert both fonts load via `document.fonts` and no `securitypolicyviolation`. No host code is needed (U that `page.route` header injection works for document responses).
- README (`scrypath_ops/README.md`): host note and the `class="dark"` shim.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.0 / OTP 28 via asdf env vars), `node --test` (Node 26.10.0), Playwright 1.60.0 |
| Config file | `scrypath_ops/mix.exs` (test alias runs `check_nav_contract`, `ecto.create`, `ecto.migrate`); `examples/scrypath_ecommerce/playwright.config.ts` (testDir `./e2e`, 1 worker, 0 retries, chromium) |
| Quick run command | `cd examples/scrypath_ecommerce && node contrast-checker.mjs` (0.3 s) then `node --test examples/scrypath_ecommerce/ui-tokens.test.mjs` from the repo root (6 s) |
| Full suite command | `mix verify.ops_ui`, `mix verify.repository_contracts`, `mix verify.core`, `mix verify.ecommerce_mounted` (required lanes) and `mix verify.ecommerce_e2e` (advisory, dispatch) |

Environment for ExUnit: `export ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5` and a task-scoped `SCRYPATH_OPS_TEST_DATABASE=scrypath_ops_test_187_<task>`, dropped afterwards (V: I ran and dropped `scrypath_ops_test_187_research`).

### Phase Requirements → Test Map (cheapest first within each row)

| Req | Checks | Commands | Cost |
|-----|--------|----------|------|
| SKIN-01 | N-01, N-02, N-06, N-08, N-10; E token reads; P-01, P-18 | contrast checker; token test; `mix test` the four ops CSS tests; Playwright P-01 six combinations | 0.3 s; 6 s; 4 s; spec in e2e lane |
| SKIN-02 | N-10 (font urls, hashes), E-14 (four `@font-face`, no Bricolage, glyph coverage), E-15 (ConnTest `/ops/assets/fonts/*.woff2`, preload only standalone), P-02, P-14, P-19, P-20 | token test; ops ExUnit; Docker spec | 6 s; ~55 s suite; e2e |
| SKIN-03 | E-13 (bytes equal `brand/`, ICO has 16 and 32 entries, root layout links), `mix verify.brand` (0.4 s, V), P-11 | ops ExUnit; Playwright | seconds; e2e |
| SKIN-04 | E-07 (per route and per open modal `.btn-primary` ≤ 1; no `.btn-error`; `ops_button` rejects `:danger`), E-08, E-09, P-04, P-05, P-06, P-07 | ops LiveViewTest; Playwright | ~55 s; e2e |
| SKIN-05 | E-10, E-12 (planted-failure scan), E-18, N-12, P-12, P-15, P-16, P-21 | ops regex; token test; Playwright `getAnimations()` | 4 s; 6 s; e2e |
| SKIN-06 | N-13, P-02 (min font size 12, weights, no uppercase) | token test; Playwright | 6 s; e2e |
| SKIN-07 | E-05 (rank fixture), E-11 (exact strings, flash has no raw term, "blocked" once) | ops LiveViewTest | ~55 s |
| SKIN-08 | E-19 (scenario renders four words and a condition; name equals capture command argument); capture inventory script exits non-zero if a file is missing; gates list in the PR text | ops ExUnit; capture script | seconds; minutes with Docker |
| STAT-01 | E-01, E-02, P-03 | ops ExUnit; Playwright | seconds; e2e |
| STAT-02 | E-03, E-04 (observed-empty, `{:error,_}`, oban-unobserved, inline, zero-from-unobserved) | ops LiveViewTest | seconds |
| STAT-03 | E-06, E-17, P-15, P-18 | ops; Playwright | seconds; e2e |
| A11Y-01 | N-03..N-07, P-07, P-08, P-13, P-16 | contrast checker (56 text pairs, edge, button labels, book pairs), Playwright forced colors | 0.3 s; e2e |
| A11Y-02 | N-09 (`scroll-padding-top` calc over `--ops-header-h`), P-09 (rects inside `.ops-table-scroll` scrollport), P-10 (tab-through ≥ 64 px) | token/contrast test; Playwright | 0.3 s; e2e |
| A11Y-03 | E-16 (`aria-busy`, word, no animation class), P-02, P-12 | ops; Playwright | seconds; e2e |
| A11Y-04 | N-11, P-17, mounted font 200 in `operator.spec.ts` or `harness.spec.ts` | token test; Playwright | 6 s; required lane (~18 min cold) |
| GATE-03 | `npm run ui:preflight` from the worktree demo dir exits 0; preview data check (seed-disabled) | `PLAYWRIGHT_BASE_URL=http://127.0.0.1:<lane> npm run ui:preflight` | seconds after the stack is up |

### Sampling Rate
- **Per task commit:** rebuild CSS (if touched), contrast checker, token test, the four ops regex tests (about 12 s total), plus the touched LiveView test file.
- **Per wave merge:** root `ui_*` with `--exclude contrast_child` (7 s), full ops suite (55 s), `mix verify.ops_ui`.
- **Phase gate:** `verify.repository_contracts` (about 180 s, escalated), `verify.core`, required lanes, then dispatch CI on the exact head with `ecommerce-e2e` and `closeout-attestation` green.

### Wave 0 Gaps
- [ ] `all-statuses` scenario in both fixture copies (Plan 01).
- [ ] 1280-capable capture script (Plan 01).
- [ ] `scrypath_ops/test/.../reskin_static_contract_test.exs` and `ops_sync_status_test.exs` (Plans 02, 04).
- [ ] Two new Playwright specs (Plan 07) and a request-level font check in `operator.spec.ts` (Plan 02).
- [ ] N-11 baseline in `ui-tokens.test.mjs` (Plan 07).
- [ ] Dockerfile fix (Plan 02). Framework install: none.

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input validation | Yes (small) | `ops_sync_status` takes a closed atom set (`attr :status, :atom, values: [...]`); fixture `scenario` param is whitelisted and falls back to `"healthy"` (V `phase173_fixture_source.ex:85-105`) |
| V7 Error handling | Yes | Remove `inspect(reason)` from the retry flash (V `failed_sync_live.ex:352`); existing test that error bodies do not leak (`posture_live_test.exs:412`) stays |
| V12 Files and resources | Yes | `AssetPlug` rejects `..`/`.`/empty segments and `inside_static_dir?` (V); serve only committed, pinned files; fonts and SVGs are sha256-pinned by `mix verify.brand` (V Phase 186) |
| V14 Configuration | Yes | Same-origin fonts need only `font-src 'self'`; no third-party font host; host CSP is the host's call and is documented |
| V10 Malicious code | Yes | No new vendored script; brand SVG active-content scan exists in `verify.brand` (V 186 verification: appended `<script` rejected) |
| V2/V3/V4 | No | No auth, session or access-control change |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Path traversal via asset URL or `?v` | Tampering | Existing segment and prefix checks; `?v` is only compared, never used as a path |
| Retry error leaking internal terms | Information disclosure | Fixed sentence with module name only |
| Test-only fixture route reachable in prod | Elevation | Routes compiled under `Mix.env() == :test` only (V); keep `all-statuses` inside the same guard |
| Host CSP silently blocks fonts | Denial of service (cosmetic) | `font-display: swap` plus metric-matched fallbacks, documented in README, tested with a CSP injection |
| Capture artifacts contain operational data | Information disclosure | Keep in ignored `ui-review-artifacts/`, never upload (UI-REVIEW.md) |
| Strict host `script-src` blocks the inline theme scripts in both root layouts | Availability | Existing residual, out of scope; keep the CSP probe to `font-src` only |

## Open Questions (RESOLVED)

1. **Where do the 24 captures and the all-statuses state come from?** RESOLVED. The preview is dev mode (no fixture routes, V) and no tool captures 1280 (V). Take the before and after sets for Control Room, Search health and Failed sync work from a disposable test-mode stack seeded with `/dev/e2e/seed` (deterministic), built from the baseline commit and the head, using one new `.mjs` capture script (not `*.spec.ts`, so Playwright discovery and the evidence inventory ignore it; not an edit to `ui-review.mjs`). Capture the `all-statuses` Search health state in the same pair (Plan 01 adds the scenario before the before-capture). The refreshed retained preview is for the maintainer's live look and `ui:review` context. Deciding sources: V capture-tool widths, V router mounts, UI-SPEC Delivery Evidence (all-statuses must exist), CONTEXT GATE-03.
2. **Fonts missing in Docker images.** RESOLVED: narrow the Dockerfile `rm -rf` to the generated css and js (Section 2, D-1). Deciding source: V Dockerfile lines 32, 83-105 and Phase 186 pin of `assets/fonts` (owned directory).
3. **Edit `ui-review.mjs` (2 retired hexes in the gallery HTML, line 782)?** RESOLVED: yes, in Plan 01 before any capture, and remove the p187 entry. Deciding sources: V `ecommerce_evidence.cjs:70` (overlay file), CONTEXT preservation note ("before any before capture, or not at all").
4. **What does the Phase 186 pair check prove for 187, and do we run the full pair flow?** RESOLVED (recommendation, record it): do not run the full Docker pair flow in 187. SKIN-08 as written asks for captures and a gates list, not pair verdicts; the flow needs two clean-commit full-matrix captures (expensive, 30 min class) and its geometry check will reject every screen by design (font swap, 136 px lockup, hairline rows). Leave `ui_state_pairs.cjs` untouched, keep its tests green, keep `ui_state_preservation` and `ui_content_preservation` passing in the full lane, and record "geometry-class rejection expected; pair flow not run; no baseline recaptured". If the maintainer wants it later, Plan 01's tolerant helper already supports it. Deciding sources: REQUIREMENTS SKIN-08, 186-VERIFICATION finding 4, CONTEXT "Record the decision".
5. **How to remap the DTCG mirror?** RESOLVED: regenerate the `ops.*` subtree and `daisyui-theme.example.js` once with a throwaway script (not committed) from the new theme blocks, hand-check the diff, keep names and `$extensions` shape, and lower the `brandbook/` `max_hits` with the printed number. Deciding sources: V `ui_tokens.ex:469-530` (set and expression parity), CONTEXT Deferred (mirror stays until v1.47).
6. **Per-property flips or one commit for the palette?** RESOLVED: one commit (Plan 03). Deciding source: V `ui-tokens.test.mjs:340-380` and `395-418`.
7. **Where does the mounted-host font 200 assertion run in a required lane?** RESOLVED: `request.get` in `harness.spec.ts` or `operator.spec.ts` plus ops ExUnit at `/ops`. The ecommerce ExUnit `page_controller_test.exs` is not wired in CI (V). Do not add a lane (gate budget 5 of 12 used, V 186).
8. **Which tool produces the 1280 px width?** RESOLVED: the new capture script sets 1280x900 and 390x844; nothing existing does (V).
9. **How to count `hero-` icons without false positives?** RESOLVED: scan `<.icon name="hero-…">`, `icon="hero-…"` and `name={"hero-…"}` sites, not the bare substring (V `ops_ui.ex:706`).
10. **`--ops-selection` and `--ops-theme-selection` vs `--ops-selected`?** RESOLVED by UI-SPEC: keep all three with identical values for one milestone (V pins at `shell_chrome_token_contract_test.exs:84-87`, `phase173_shell.spec.ts:79`).
11. **Does `duration-(--duration-ops-quick)` and a token-driven Tailwind default work?** RESOLVED: yes with the pinned 4.1.12 (V scratch probe). Whether the literal ratchet counts the parenthesized form is open (A6); test after first use.
12. **Is the preview data at risk?** RESOLVED: nothing to lose in Docker (V); preserve `my-search.json`; still run seed-disabled.
13. **Where do N-11 and P-17 live?** RESOLVED: N-11 in `ui-tokens.test.mjs`; P-17 in `ops_host_contract.spec.ts`. Deciding source: one Node mechanism (186), no new CI job (CONTEXT).
14. **Delete `admin_path_motion.spec.ts`?** RESOLVED: it is not a required suite (V `ecommerce_evidence.cjs:553`); delete or rewrite as the P-12 motion spec, and retire its p187 allowlist entry.

## Common Pitfalls

1. **Stale pending claim.** Changing a CSS value without flipping `applied` fails ("stale pending claim"). Flip in the same commit.
2. **Built CSS drift.** Any theme-block edit needs the 1.4 s rebuild, or the emission check fails. Remember the dev compose watcher rewrites the tracked file in the mounted checkout.
3. **Allowlist lockstep.** A drop in retired-value hits fails until `max_hits` and `HITS_CEILING` are lowered (V `ui-tokens.test.mjs:953-955`); it prints the number.
4. **Overlay digest.** Editing fixture or helper files after the before capture invalidates a pair.
5. **Docker lanes without fonts** (D-1).
6. **Opacity on glyphs.** `core_components.ex:74` close icon at 40% and `.ops-time__affordance` at .45 are non-text UI below 3:1 (U); ban opacity below 1 on control glyphs too.
7. **Selected state loses its line.** `.ops-nav-item-active` count is pinned to 2 (V); keep the class name while changing the treatment.
8. **Hover reads as selected.** UI-SPEC LD-13: hover uses Sunken, selected uses Selected.
9. **Ranking semantics.** Fetch-failure rows no longer sort first (LD-8): the `posture_live_test.exs:395` title and any e2e that assumes it need review.
10. **`⌘`, `·`, `›` render from fallback faces** in both fonts (V per UI-SPEC); do not assert glyph shape, assert the allowlist.
11. **Tailwind default duration** (`150ms`) and daisyUI component durations leak into computed styles; the P-12 scan names the selector.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Contrast math, theme parsing, alpha compositing | A second pair document or parser | Extend `contrast-checker.mjs` / `readThemeProperties` | Already exported and tested (V) |
| Token parity | Generated CSS from `brand/tokens.json` | `token-map.json` + the Node test | CONTEXT locked |
| Font coverage | Glyph tables by hand | fontTools-read cmap results recorded in the test (UI-SPEC lists the missing code points) | Allowlist `·`, `›`, `⌘` |
| Asset cache headers | New plug | Existing `AssetPlug` | `?v=` immutable behavior exists (V) |
| Status icon art | Heroicons or a new icon library | Four inline paths in UI-SPEC (LD-7) | Heroicons are restricted to the LD-6 allowlist |
| Browser theme/CSP fixtures | New host app | `page.route`, `addStyleTag`, existing `theme-grid.ts` | No host code needed |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/OTP | ExUnit, mix tasks | Yes | 1.19.0 / OTP 28 (asdf env vars) | — |
| Node | token test, contrast checker, Playwright | Yes | 26.10.0 (CI version U) | — |
| Postgres | ops ExUnit | Yes | local on 5432 (`pg_isready` accepting) | task-scoped DB name |
| Tailwind and esbuild binaries | rebuild tracked assets | Yes | `_build/tailwind-macos-arm64`, `esbuild-darwin-arm64` | `mix assets.setup` (network) |
| Playwright and Chromium | P specs, captures | Yes | 1.60.0, chromium builds cached | Docker `Dockerfile.e2e` |
| Docker | preview, captures, required lanes | Yes | Desktop; no scrypath images or volumes; 4002 free | — |
| `git fetch` / GitHub | preview refresh, CI dispatch | Not exercised | — | escalated permission (AGENTS.md) |

**Missing with no fallback:** none. **Missing with fallback:** scrypath preview stack (cold build required).

## State of the Art

| Old | Current | Impact |
|-----|---------|--------|
| Blue-grey/violet/copper ops palette with alpha tints | Plum/Orchid opaque roles | Tokens, alpha policy, new rows |
| Icon + tinted badges for sync states | Word first plus bar icon | `ops_sync_status` |
| Hover-only underlined text actions | Underlined at rest | Computed tuple test |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Phoenix `put_secure_browser_headers` sets no CSP by default | 6 | The host-CSP probe assumes `page.route` is the only CSP source |
| A2 | Removing the `#29d` finding from `app.js` may require a matching ledger edit in `ui-literal-baseline.json`; the stale-finding rule was not read | 1.3 | One extra commit if the ratchet fails |
| A3 | daisyUI components not referenced in ops templates (`toggle`, `toast`, `menu`, `swap`, `filter`, `skeleton`, `progress`) never render | 1.1 | More duration or infinite-animation overrides |
| A4 | Playwright works against a host-native standalone ops on macOS | 3.2 | Local spec loop falls back to Docker (slower) |
| A5 | Cold Docker build takes minutes, not seconds | 5 | Schedule risk only |
| A6 | `duration-(--x)` is not an "arbitrary-value" finding in the literal ratchet | 4 | Ratchet baseline edit |
| A7 | `page.route` can add a response header to document requests for the CSP probe | 6 | Need a test-only middleware instead |
| A8 | The built-CSS dirty hunk in `ui/next` is only the `.tab` block | 5 | Maintainer edit lost if not |
| A9 | `opacity-40` on the flash close glyph and `.ops-time__affordance` fail non-text contrast | 1.3 | Minor |
| A10 | Node version on CI equals local | Environment | Token test behavior |

## Sources

### Primary (HIGH confidence): read or run this session
- `187-CONTEXT.md`, `187-UI-SPEC.md`, `186-VERIFICATION.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `V1.46-PREP.md`, `UI-PREVIEW.json`, `UI-REVIEW.md`, `UI-WORKTREE-LEARNINGS.md` (first 60 lines), memory notes (dev container, Docker lanes, toolchain).
- Repo files named inline with line numbers, `Dockerfile`, `compose*.yaml`, `ci.yml`, `ecommerce_evidence.cjs`, `ui-tokens.test.mjs`, `contrast-checker.mjs`, `ui_tokens.ex`.
- Runs: token test 42/42 in 5.8 s; contrast checker PASS in 0.34 s; Tailwind build 1.4 s; ops suite 329 tests, 0 failures, 45.7 s; root `ui_*` 29 tests, 0 failures, 4.7 s; `npm run ui:preflight` failure; Docker, `lsof` and `git` read-only inspection; Tailwind duration probe.

### Secondary (MEDIUM)
- Claims about WCAG and daisyUI requirements are carried from `V1.46-PREP.md` and UI-SPEC (cited there to W3C and daisyUI docs); not re-fetched this session.

### Tertiary (LOW)
- Items in the Assumptions Log.

## Project Constraints (from AGENTS.md and scrypath_ops/AGENTS.md)

- No human UAT: convert subjective checks to computed-style or DOM assertions; captures are context, not approval; no simulated reviewer.
- Cheap consistency checks first; copy-paste over new dependency; no new Hex or npm dependency.
- Docker: task-scoped names and labels, clean up temporary containers, images, networks and owned build cache, check `docker system df`, never prune other projects' resources or volumes.
- `verify.repository_contracts` and Buildx builds need escalated permission on the first invocation; snapshot-based contracts read committed HEAD, so commit a fix before rerunning.
- Worktree continuity: absolute working directories, preserve dirty edits, verify the mounted checkout with `ui:preflight`.
- UI work: read `UI-PREVIEW.json` first, follow `UI-REVIEW.md`, keep evidence in `ui-review-artifacts/`, no pixel baseline recapture on macOS.
- Phoenix guidelines (ops AGENTS.md): `<.icon>` only, unique DOM ids, no inline scripts in templates, `mix precommit`; the existing root layout inline script predates this and is not changed here.
- Keep `.planning/config.json` and `.planning/state.json` edits out of owned commits (STATE note and prep); update `.planning/PROJECT.md` only if shipped claims change.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH. All pinned and present.
- Architecture and change map: HIGH. Read from the tree; line numbers will drift.
- Pitfalls and Docker finding: HIGH. Dockerfile, router, evidence script read.
- Playwright cost and the host-native lane: MEDIUM. Not run.

**Research date:** 2026-11-19
**Valid until:** about 7 days or the first commit that edits `app.css`, whichever is sooner.
