# Phase 187: ScrypathOps re-skin - Context

**Gathered:** 2026-11-19
**Status:** Ready for planning
**Mode:** Autonomous discuss. The decision fan-out for this phase was done in the milestone prep ([V1.46-PREP.md](../../research/brand-and-catalog/V1.46-PREP.md) D4, D6, D7, D8, D9, D10, D14, D15, D16: seven research agents through security, product, architecture, devops, design, accessibility and adopter lenses, with adversarial passes and primary sources), then refined by the Phase 186 handoffs. This file records what the planner must follow. Choices that are subjective design calls are made here as recommended defaults and flagged for the one merge-time yes; none is a hard-to-reverse technical question.

<domain>
## Phase Boundary

Operators see ScrypathOps in the plum/orchid identity in light and dark with one consistent sync-status vocabulary, hosts that mount it see no change outside ops, and the maintainer receives it as **one Draft PR** with green gates and a capture inventory, merged only on the maintainer's yes (merge authority; no aesthetic or independent-review claim).

Requirements: SKIN-01..08, STAT-01..03, A11Y-01..04, GATE-03. Changes colors, font families, logo, favicon and status vocabulary. It does **not** reflow type sizes, add the master-detail Search health picture, the progress line, sounds, animation or bulk retry (all deferred; see Deferred Ideas).

</domain>

<decisions>
## Implementation Decisions

### Tokens (D4)
- `scrypath_ops/assets/css/app.css` two daisyUI theme blocks stay the single authoring place. Map base-100 to Panel, base-200 to Page, base-300 to Hairline, base-content to Ink (light) or Pale Ink (dark), primary and accent to Plum or Orchid. Retire `primary-strong` and the copper secondary (daisyUI requires a secondary: set a quiet neutral). The daisyUI required set is 20 variables; re-anchor any lock to that.
- Add hand-authored roles inside the theme block: `--ops-sunken`, `--ops-selected`, `--ops-control-edge`, an opaque `--ops-text-muted` replacing about 52 alpha mixes (ban alpha on text), and `--ops-status-failed|retrying|pending|clear`. Do not alias `--ops-surface-2` (its meaning flips from raised to recessed): introduce `--ops-sunken` and retire `surface-2`. Never use the hairline as a control's only edge. Retire the glow tokens.
- Brand values come from `brand/tokens.json` plus the verified values the prep recorded as living in `brand.json` or prose: Selected Night `#2B2130`, dark Control Edge `#8F7F94`, Night Sunken. Do not generate CSS from the brand file: the Phase 186 token map (`scrypath_ops/assets/css/token-map.json`, 37 rows with `applied` flags) is the parity source. **As each property is recolored, flip its row to `applied: true` and lower the pending ceiling; the Node token test must stay green.** After the recolor the `app.css` allowlist entry needs `max_hits` and the test-owned `HITS_CEILING` lowered together (the test prints the number).
- Rebuild the tracked built CSS (`scrypath_ops/priv/static/assets/…`) so the token-level built-CSS parity check passes; byte freshness is not checked, token level is.
- Contrast (verified in prep, V by running): all 7 text roles pass 4.5:1 on page, panel, sunken and selected backdrops in both themes; thinnest is Retrying on Selected Page light at 4.58:1. Control edge 3.66 to 4.00 and 3.09 to 3.33 on light backdrops, 4.13 to 5.23 dark. Hairline is a divider only (1.1 to 1.47). Plum against ink is about 2.1:1, so inline text links need an underline. The light selected-row fill is only about 1.1:1, so a 2 px Plum inline-start line carries WCAG 1.4.11. Use unrounded thresholds. 2.4.11 needs `scroll-padding-top` of about 5 rem for the 4 rem sticky header. Extend `examples/scrypath_ecommerce/contrast-checker.mjs` (it has the parser and compositing); do not add a second pair document. Phase 186 noted the checker currently stops at the muted-text alpha lockstep guard (D-15 Guard 2) and the `64%, transparent` pin in `UiTokensContractTest`: those two assertions are Phase 187's to rewrite to the new opaque muted token (they are listed as owned by SKIN-01 and A11Y-01).
- Motion: brand-named tokens become the source (instant 80, quick 160, base 240, advance 600). Keep old names (`fast`, `standard`, `slow`, `status`, `instant` at 90) as `var()` aliases for one milestone. Every transition and animation duration is one of the tokens; `advance` only in a named progress-line allowlist (empty in v1.46); no `sting` (1650) in ops CSS. Ban `infinite`: replace `spin` and `ops-pulse` (about app.css lines 896 and 1616) with a word plus `aria-busy`. Reduced motion already has a global rule (about line 2191).

### Fonts and assets (D6)
- Ship Hanken Grotesk and Sometype Mono (already committed byte-identical under `scrypath_ops/priv/static/assets/fonts/` by Phase 186) wired by CSS-relative URLs with a content-hash `?v=` equal to the file's sha256, served by the existing `forward("/assets", AssetPlug)` at any mount prefix (V: `router.ex:27`; `/fonts` exists only in standalone `static_paths` and would 404 mounted). `font-display: swap`; metric-adjusted fallback faces (Hanken over Arial: size-adjust 101.7, ascent 98.3, descent 29.8; mono over Courier New: 96.7, 95.7, 28.5), proven by a layout-shift probe. Preload `ui.woff2` only in the standalone root layout, with `crossorigin`. No base64 inlining. Same-origin fonts need only `font-src 'self'`.
- **Bricolage is not shipped in ops** (the book's operator row omits it; follow the explicit scope row). The ops h1 is Hanken 700 at 28 px.
- Subsets lack U+00A1-00BF including `·` (18 uses), `›` (2) and `⌘` (3, in no font): add a coverage test with a named fallback allowlist. The CSS uses weights 400, 500, 600, 650, 700 and the variable subsets cover 600-800 (display), 400-700 (ui), 400-500 (mono), so snap 650 and 500 appropriately. Hanken digits are already tabular and Sometype Mono has no `zero` feature, so `tabular-nums` and `slashed-zero` are no-ops.
- Contract tests: built CSS `?v=` values equal the files' hashes and no URL is root-absolute; mounted-mode assertions that `/ops/assets/fonts/ui.woff2` and one more nested prefix return 200.
- Logo and favicon: copy the brand lockups (light and dark) and favicon (SVG plus PNG-in-ICO; the current ops `favicon.ico` is a 152-byte stub) from `brand/`. The lockup aspect is 4.71:1: use 136 px or wider with `flex-shrink: 0`; exactly one lockup displayed per theme, `src` matching, width at least 112 and height at least 24 at 320 px. A host that mounts at a prefix must link `<mount>/favicon.svg` (document it).

### Theme default and host contract (D9)
- Ops stays **System-default** for theme; the book's light default applies to the website, README and docs only. ScrypathOps owns styles for its shell and sets nothing outside it; theme comes from `html[data-theme]`, else the OS; ops never forces light; accent override works through the existing daisyUI variables; variable names are stable, values may change.
- Leak mechanics (V in built CSS, no host run): the shipped CSS includes Tailwind preflight (`*, ::after, ::before`), `:where(:root)` daisyUI theme variables and `:root,[data-theme]` base color and background, with theme names "light" and "dark". Do not refactor isolation in this sitting. Guards: a ratchet allowlist of unscoped selectors in compiled CSS; an ecommerce check that a non-ops route loads no ops stylesheet and computes no `--color-primary`; a host-override-wins fixture; a fixture host in light, dark and System with a sentinel host element whose computed style must not change, with CSP `font-src 'self'`; a settled-style check across six combinations (OS scheme times stored preference). A fully scoped `.ops-root` is deferred. Hosts using `class="dark"` get a one-line docs shim in `scrypath_ops/README.md` (also: unchanged stylesheet link and mount prefix, the nine mirrored JS hook names unchanged and re-registered by the ecommerce host, fonts load from the mount prefix and a host CSP may block them, file names frozen).
- The embedded `/admin/search` demo runs on the ecommerce host's `app.js`: any ops JS hook change must be mirrored there (memory note).

### Status component and vocabulary (D7, D10)
- Add one `ops_sync_status(:failed | :retrying | :pending | :clear)` component: word first, then a bar icon (filled = Clear, hollow = Pending, filled from the bottom = Retrying, notched = Failed), `aria-hidden` icons with a `data-shape` attribute, word color from the book's text hexes via the `--ops-status-*` tokens. Use where the repo already shows those states: the Failed sync work row badge (`failed_sync_live.ex` about line 1035) and Search health queue and backend badges and counts (`posture_live.ex` about 345-352, 442-452). Keep the existing six tone kinds as notice and verdict kinds, and keep `data-status-kind` and `data-ops-metric-tone` hooks so tests survive. `ops_badge` stays for non-sync labels as plain neutral text.
- "Not observed", "Not checked" and "Queue not used" are conditions, not statuses: plain muted words, no icon (`posture_live.ex` about 662-676). Show "Clear" only with an observation; never infer health from zero counts (DESIGN.md).
- Notices and verdicts: Panel plus a 2 px left rule; only an error uses the Failed color; Plum is never an info color; `:running` becomes neutral. Green only on the word and icon of Clear. Warning uses the Retrying amber for rule and title only.
- Ranking fix: `posture_row_rank` (about `posture_live.ex:528`) ties queue-failed with queue-retrying and ranks pending as clean; change to Failed, Retrying, Pending, Clear, then name. A row shows its most urgent status. Rows re-sort only on manual refresh.
- Dense facts in place of the progress line: "Queue 2 pending, 1 retrying · Meilisearch 0 · Last succeeded 14:02 UTC" (data per schema exists).
- Two verified copy bugs ship here for a visible increment: the promotion prefix (`sync_drift_live.ex` about line 290) and the `inspect(reason)` leak (`failed_sync_live.ex` about line 352). Other wording renames (e.g. "Control Room" to sentence case, "Searchable" label rule) belong to Phase 190, not here.
- Verified answers (R/V): Retry is per failed item on Failed sync work only, no bulk retry, none on Search health; Pending is the status word for both `queue.pending` and `backend.pending`; Clear does not mean Searchable; `mix scrypath.status` prints Backend (Meilisearch) and Queue lines with Last succeeded as two timestamps.

### Buttons, actions, icons (D7)
- At most one Plum button per visible, non-inert scope (an open modal is its own scope). Keep Control Room "View search health", Search "Run search", Search "Save" in its modal; demote the inline "Rename". Danger buttons (`failed_sync_live.ex` about 1224, `sync_drift_live.ex` about 2463, `search_live.ex` about 1930) become the modal's single Plum button with the consequence in the label; Cancel stays initial focus; no `.btn-error`. Sync and index: no page-level Plum button; the promote confirm is the only main button.
- Row actions (Retry about `failed_sync_live.ex:1100`, Load, Rename, Export, Delete, "View failed sync work") become underlined Ink text on every row (`.ops-text-action` underlines only on hover today, app.css about 2500); minimum target height at least 24 px (today's 40 px is fine); prose links underlined at rest.
- Icons: drop the six nav icons (`layouts.ex` about 253-265) and the verdict icons; keep control glyphs (menu, close, chevron, copy, sun, moon).

### Retired code and type floor (D7, D8)
- Retire `.ops-path-*`, `.ops-copper-*`, glow and copper gradient (app.css about 1979-2035 and 2412-2423; no template uses them), the select chevron hard-coded colors (about 955-962), and `uppercase` at app.css about 786, 1149, 1510, 1750 and `ops_ui.ex` about 401 and 516. The rgba triplets 108,92,231 and 193,122,62 go too. Update the tests and the three advisory e2e specs that pinned them (`admin_path_motion`, `admin_surface_depth`, `phase173_shell`: they hold old RGB constants; use the spec's existing `resolveCssColor` against the token) and `motion_contract_test.exs`.
- h1 at 28 px; raise the 11 px sites to 12 (`app.css` about 202, 1145, 1748, 1931, 1974; `--text-ops-xs` 0.6875rem conflicts with the floor); make `.ops-signal-metrics .ops-time` mono (about 2454). Record the size scale as `keep-platform` in the token map; no body reflow. Every time already names its zone (`ops_ui.ex` about 1850).
- Line numbers above are from the prep (2026-11-18); re-derive on the current tree.

### Assertions that prove each rule without a human (D7)
- h1 `font-family` starts with the heading family at 28 px and is the only element using the display font; `.ops-time` and `[data-ops-copy]` compute to the mono face; minimum computed text size at least 12 px; `text-transform` never `uppercase`; every `ops_sync_status` has non-empty text in {Failed, Retrying, Pending, Clear}, an icon `data-shape` matching it, a word color equal to the token, `aria-hidden` icons; visible non-inert `.btn-primary` at most 1 per page and per open dialog; no `.btn-error`; row actions share one computed tuple; the selected row has a 2 px `border-inline-start` in both themes; focus outline 2 px solid Plum or Orchid and its rect inside the scrollport for the first and last controls of `.ops-table-scroll` (the belief that `overflow-x-auto` ancestors clip it is unverified: test, do not trust the comment at app.css about 157-159); a tab-through leaves the focused element's top at least 64 px below the viewport top; exactly one lockup displayed per theme; no running infinite animation (`getAnimations()`); every transition duration in {80, 160, 240} ms; all book pairs recomputed from custom properties including status words on Selected Page and the control edge; grep gates for `ops-path|copper|glow|gradient|uppercase|infinite`. Put LiveView/DOM-level ones in ops ExUnit tests where possible (cheap) and computed-style ones in Playwright specs under `examples/scrypath_ecommerce/e2e/` (the phase105-e2e job runs all specs; no new CI job).

### Preservation pairs and the Phase 186 structural check
- Phase 186's structural pair comparator is **not font-invariant** and geometry stays exact: the font swap (SKIN-02) and any new dark-surface border will likely reject preservation pairs by design. Decide in planning what that check is expected to prove for 187: keep copy, state, action, identity and geometry-class checks; do not recapture pixel baselines on macOS (CI image only); do not auto-update an unreviewed baseline. A rejecting pair after the re-skin is a reviewed, recorded expectation, not a silent baseline refresh. Record the decision.
- Editing `scripts/ci/ui_state_pairs.cjs` changes the fixture-overlay digest: do it before any "before" capture, or not at all.

### Delivery (D16, GATE-03, AGENTS.md UI work)
- Open the PR as a **Draft** (GitHub blocks merging drafts with no new gate). When every automated gate is green on the exact head SHA (dispatch CI on that head; require `ecommerce-e2e` and `closeout-attestation` green before raising the Draft), post one message with the before and after capture inventory and a plain list of what the gates prove and do not prove. The maintainer's yes is marking it ready or saying "merge". No required-review rule; do not simulate a reviewer identity. Hex 0.3.18 was already released; no Hex release is part of this phase.
- GATE-03: read `.planning/UI-PREVIEW.json` and `.planning/reference/UI-WORKTREE-LEARNINGS.md` first (the preview record is stale: it names worktree `ui/next` at `ebed49b5` and `npm run ui:preflight` failed with `no such object: scrypath_ecommerce-web-1`). Refresh and reconcile `ui/next` to post-merge main, rebuild via `compose.dev.yaml` (the baked image on :4002 is stale; see the memory note on the dev container and Elixir 1.19 gotchas), keep seed-disabled so preview data survives, re-run `npm run ui:preflight` from that checkout's demo directory before editing or restarting the preview. Docker host is shared (other projects' containers): task-scoped names and labels, a free `WEB_PORT` lane when 4002 is taken, clean up per AGENTS.md, never prune other projects' resources. Review artifacts go in `ui-review-artifacts/`. First `verify.repository_contracts` and Buildx builds need escalated permission.
- Follow `examples/scrypath_ecommerce/e2e/UI-REVIEW.md` for storefront/ScrypathOps changes: review the full current screen and journey inventory, inspect rendered screenshots and actual copy, record unreported problems, run `npm run ui:review` from the demo in the checkout actually mounted by the preview. Captures and passing code tests alone are not a design pass; do not claim independent review. Keep the lean CI posture.
- Per-screen risk (prep): all six screens: tokens, fonts, logo, scale, focus, dark (medium; wide snapshot churn). Control Room: verdict icon and tone to the Clear and Failed pattern, one Plum button, drop intent-card icons (low). Search health: hairline rows by CSS, new status component, ranking function, mono times, drop the shadow (medium). Failed sync work: status word and icon, Retry as text action, recolored "Retry queued" notice, Plum destructive confirm (medium). Sync and index: no page-level Plum button, promote confirm only, check ring clipping in `ops_table` (medium). Search and saved searches: demote Rename, row-action style, active saved search selected style (medium). Help: headings and links only (low).

### Claude's Discretion
- Plan slicing and wave order (suggested: tokens and fonts and built CSS first; then the status component, buttons and row actions per screen; then retired-code removal and test rewrites; then host-contract guards; then GATE-03 preview refresh, captures and the Draft PR), file layout, test structure, helper naming. Run cheap consistency checks (contrast checker, token test, ops pure-regex tests) before long suites and look for CI speed wins when CI runs.
- Where this phase could not be one PR without becoming unreviewable, keep one Draft PR but sequence atomic commits so the diff reads screen by screen.

</decisions>

<code_context>
## Existing Code Insights

- Phase 186 left: `brand/` (44 pinned assets), `scrypath_ops/assets/css/token-map.json` and `examples/scrypath_ecommerce/ui-tokens.test.mjs` (token parity with `applied` flags, deny-list with per-file `max_hits`), `test/support/ui_tokens.ex` (resolved-token helper), lifted literals in the three contract tests, the structural pair comparator and its committed crops.
- `scrypath_ops` is not on Hex; `brand` and `brandbook` stay out of the root package `files`. `lib/` must never mention PhoenixStorybook (static boundary tests exist).
- Verification debt that Phase 187 owns (from the Phase 186 recolor projection): token-test applied rows, built CSS parity, `D-15 Guard 2` muted-alpha lockstep and the `64%, transparent` pin, the DTCG mirror remap, `max_hits` and `HITS_CEILING` for `app.css`.
- Local toolchain: `export ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5`. The running :4002 is the baked prod image; live-verify through the dev container (memory: ops-ui-live-verify-dev-container).

</code_context>

<specifics>
## Specific Ideas

- Cheapest checks, in order: `node examples/scrypath_ecommerce/contrast-checker.mjs` (run from `examples/scrypath_ecommerce/`), the Node token test, ops pure-regex tests, the three root `ui_*` tests with `--exclude contrast_child`, then the ops-ui lane, then the contrast_child tests and Docker lanes.
- The new brand has a book-specified status icon set and an operator-UI scope row; the prep sent a list of conflicts and gaps back to the book's author (send-back list). Where the book is silent (danger, info and success fills, overlay surface in dark, section-heading size), invent `local` colors and record them as `local` rows in the token map.
- No human UAT: where something looks subjective, convert it to a computed-style or DOM assertion; what stays subjective is rendered critique, which is nonblocking and explicitly scoped.

</specifics>

<deferred>
## Deferred Ideas

- Master-detail Search health picture (selected row, one sentence, only Plum button, progress line), per-schema retry, bulk retry all, sounds, logo animation: no per-schema progress semantics; revisit in v1.48.
- Type-scale reflow to 16/28/13: six screens reflow with no catalog to show states; v1.48.
- Fully scoped `.ops-root` isolation: a host-reported leak would change this.
- "Control Room" to sentence case and the "Searchable" wording rules: Phase 190.
- Retiring `ui_tokens.ex`, the `ops.*` DTCG mirror and their tests, deleting `brandbook/`, and replacing the demo host favicon: first v1.47 phase cleanup (ROADMAP "Deferred to v1.47"). The `ops.*` DTCG mirror remap is only what the recolor needs to keep them passing.
- Any pixel baseline recapture: CI image only, never macOS; deferred to the catalog work.

</deferred>
