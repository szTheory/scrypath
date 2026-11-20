# Gap pass G: Phase 189 website risk (what prep note B missed or got wrong)

Written 2026-11-20. Read-only review of the repo; recommendations only. Labels: V = verified in this session by reading a file, running a probe, or querying GitHub/the live site; U = judgment or not verified.
Probes ran in the scratchpad against the installed Playwright (Chromium 148); nothing in the repo was touched.

## Summary table

| # | Sev | Finding |
|---|-----|---------|
| 1 | blocker | The check serves `dist` at `/`, production is `/scrypath/`: subpath bugs pass CI and break live |
| 2 | blocker | `hidden` on the picker is overridden by an author `display` rule; no-JS visitors get a dead control |
| 3 | blocker | Dark `selected` and dark `control-edge` are not structured values in `tokens.json`; "derive, no hex literal" cannot be met as written |
| 4 | blocker | Contrast resolver cannot parse `color-mix()` computed values (Chromium returns `color(srgb ...)`) |
| 5 | should-fix | Premise "8 min browser install" is the tail, not the typical case (median 49 s, 15% of runs over 200 s) |
| 6 | should-fix | Dark primary button label: reusing the ink role gives 2.19:1 |
| 7 | should-fix | `localStorage` key collides across all `sztheory.github.io/*` project sites |
| 8 | should-fix | Forced-colors: the light lockup can land on a black canvas; picker pressed state is color-only |
| 9 | should-fix | Print with dark chosen prints pale text on white paper |
| 10 | should-fix | Faux bold on Sometype Mono (range 400-500) and CLS from font swap on the LCP h1 (`max-width: 11ch`) |
| 11 | should-fix | Favicon link wiring: `media` on `rel=icon` is not specified by MDN; `.ico` without `sizes` can win over SVG |
| 12 | should-fix | Deploy: no post-deploy smoke, `cancel-in-progress` on the deploy path, rollback is 9+ minutes |
| 13 | should-fix | `pull_request` trigger has no `paths`; a non-required job can be path-filtered safely, and a job-level classifier would make a required gate cheap |
| 14 | should-fix | theme.js can carry a hex literal (theme-color) that the "no literal" test does not scan |
| 15 | nit | Static-contract hex regex false positives (`&#8217;`, `#123`), WCAG reflow and target size not asserted, fixed port, font count per page, cache headers |

---

## 1. blocker: the browser check tests a different URL shape than production

Evidence (V): `website/scripts/serve.mjs` serves `dist` at the server root, and `check.mjs` loads `http://127.0.0.1:4173/`. Production is `https://sztheory.github.io/scrypath/` (`website.yml` env `SCRYPATH_SITE_URL`). Today everything is relative (`{{BASE_PATH}}`), which is why it works. A re-skin adds a CSS `url()`, font preloads, favicon links, `theme.js`, an inline SVG and a social card; one root-absolute `/assets/...` passes every planned assertion and 404s live. Live headers (V, curl): `cache-control: max-age=600`, `access-control-allow-origin: *`, `/docs` 301 to `/docs/`, unknown path 404. The planned "font `content-type` is `font/woff2`" assertion tests the project's own `serve.mjs` MIME table, not Pages (U: Pages' woff2 type was not probed because the live site serves no woff2 yet).

Add to SITE-04 / success criterion 3: "`serve.mjs` takes `--base /scrypath/` and serves `dist` only under that prefix (404 at `/`); `check.mjs` runs every page assertion at `http://127.0.0.1:<port>/scrypath/`, and the static contract rejects any `href`, `src` or CSS `url()` that starts with `/` or an origin other than the declared site URL."

## 2. blocker: the picker's `hidden` attribute does not hide it

Evidence (V, probe): an element with `hidden` and an author rule `display:inline-flex` computes `display: inline-flex`. Note B's picker "ships with `hidden`", and every flex or grid container rule in `styles.css` (the header actions are `inline-flex`) is exactly this case. No-JS visitors would see three dead buttons.

Add: "`[hidden] { display: none !important }` is in `styles.css`. The browser check opens every page in a context with `javaScriptEnabled: false` and asserts the picker is not visible and the page is light; with JS on, the picker is visible and focusable." Also reveal it only after a write probe to storage succeeds, or state the opposite explicitly (item 7b below).

## 3. blocker: two dark roles are not data in `tokens.json`

Evidence (V): `brand/tokens.json` holds light `selected-page` and `control-edge` only. The dark values `#2B2130` (selected row) and `#8F7F94` (control edge) appear only inside a description string in `tokens.json` and in `brand.json` contrast pairs; the ops UI hard-codes them in `scrypath_ops/assets/css/app.css` and `token-map.json`. Note B's role map says each role "names a light path and a dark path"; for these two roles there is no dark path. A generator that parses description text is fragile; a hex in website source breaks SITE-01 and the "no hex in source" test.

Control edge matters: hairline is 1.3:1 on Page (V, computed), so every non-filled button, the picker buttons and any bordered control must use control-edge (3.66:1 light, 5.07:1 dark) not hairline. The book's rule is "an input or a button has a Control Edge border".

Change SITE-01 wording from "no hex literal ... remains in website source" to "no hex literal remains in website source except the role map in `build.mjs`, which resolves each role to a `tokens.json` path or, for the two dark roles with no token (`selected`, `control-edge`), to the `brand.json` `contrastPairs` entry whose hex it must equal". Add to criterion 1: "the generator fails the build if a role resolves to nothing". Alternative that keeps the rule absolute: drop dark `selected` entirely (use no selected state on the site) and take dark control-edge from `brand.json`. Report the gap upstream with the favicon bug.

## 4. blocker: the contrast resolver will break on `color-mix()`

Evidence (V, probe, Chromium 148): `color-mix(in srgb, var(--ink) 14%, transparent)` computes to `color(srgb 0.117647 0.0705882 0.12549 / 0.14)`; even an opaque mix serializes as `color(srgb ...)`, only plain hex tokens serialize as `rgb(...)`. Note B recommends `color-mix` for translucent edges, then says to "resolve each element's computed color and nearest opaque background". A parser that only reads `rgb()` returns NaN or throws, and the serialization is a browser-version detail that Dependabot's Playwright bumps change.

Add: "Text and fill surfaces use opaque token colors only; `color-mix` is allowed for borders and shadows. The check normalizes any computed color by painting it on a 1x1 canvas (or by parsing both `rgb()` and `color(srgb)`), and composites alpha over the resolved ancestor background; a test with a planted translucent surface proves the resolver does the math." Also name each pair's real background: the book's link ratios (8.64 light, 6.92 dark) are link on Panel; a link on Page is 7.91 and 7.49. An assertion table that says "link" without a background gives a false red or tolerates the wrong one. State the table as pair id from `brand.json` (`body`, `descriptor`, `caption`, `link`, `focus`, `button`) plus the exact selector and its expected background token.

## 5. should-fix: "the install is 8 of 8.5 minutes" is the tail, not the norm

Evidence (V, `gh run view` over the last 39 `build-and-check` runs): the Playwright install step has a median of 36 s and p50 of about 49 s; the fastest is 21 s; 6 of 39 runs took 377-492 s. The cited run 44422718989 is a Dependabot PR and one of those tail runs. Recent full jobs are 47-64 s. The cost is variance (apt mirror time under `--with-deps`), not a steady 8 minutes.

Also stale (V): note B says Dependabot #128 is open and should merge first; `git log` shows it merged (`b097e5c3`), `website/package.json` is already `^1.65.1`.

Options, ordered by simplicity:
1. Skip the download: ubuntu-24.04 images preinstall Google Chrome (V, runner-images Ubuntu2404-Readme lists Google Chrome 157). Launch with `chromium.launch({ channel: 'chrome' })` in CI, no install step. Cost: Chrome drifts with the image, so assertions must stay computed-style/behavior only (they do).
2. Keep the download but drop `--with-deps` and install only the headless shell (`npx playwright install --only-shell chromium`), avoiding the apt step. U: measure.
3. Cache `~/.cache/ms-playwright` keyed on the lockfile Playwright version.

Change the Phase 189 / CI-EFFICIENCY item 5 wording from "about 8 of 8.5 minutes" to "typically under one minute with an intermittent 6 to 8 minute tail; success criterion: no step in `build-and-check` can take more than N minutes (set `timeout-minutes: 10` on the job) and the install variance is removed, not the median shaved".

## 6. should-fix: dark primary button label

Evidence (V, computed): `brand.json` pair `button` is white on Plum in light (8.64) and Night (`#160E19`) on Orchid in dark (7.49). Pale Ink on Orchid is 2.19:1. The current `.button` uses `color: var(--text)`; a role map that lists `ink` (which flips to Pale Ink in dark) but no `on-primary` role reproduces the 2.19:1 failure in dark only.

Add the role `on-primary` (light white, dark Night) to the role map and criterion 3: "the `button` pair from `brand.json` is asserted for the one `.button-primary` in both themes, in rest, hover and `:focus-visible` states." Also: `outline-offset` of at least 2px on filled buttons; a ring directly on a Plum fill is 1:1.

## 7. should-fix: storage key collides across the whole `sztheory.github.io` origin

Evidence (V): localStorage is per origin, and every szTheory project Pages site is `https://sztheory.github.io/<repo>/`. A bare `theme` key is shared and writable by any of those sites. (The origin root itself 404s today, so there is no user site to conflict, but other project sites would.)

Add to SITE-02: "The stored key is `scrypath-theme`; `theme.js` accepts only `light`, `dark` or `system` and treats anything else (or a throwing storage) as light; it listens for the `storage` event so a second tab follows." Item 7b: when storage is blocked the site is an MPA, so a picked theme lasts one page. Decide and write it down: hide the picker when a write probe fails (recommended, no dead control), and say so in criterion 2 ("with storage blocked the page renders light and the picker is hidden"). The test must block storage deterministically with `addInitScript` defining a throwing `localStorage` getter; Playwright has no storage-blocked switch.

## 8. should-fix: forced-colors and the lockup

Evidence (U, standard behavior; not probed): in forced-colors mode `<img>` SVGs keep their author colors while the page canvas becomes the user's system color. The light lockup is chosen by `data-theme`/default, so a user in a dark high-contrast theme sees `#1E1220` letters on a black canvas. The picker's pressed state is a background change that forced-colors strips.

Add criterion text: "Under `forced-colors: active` the displayed lockup follows `prefers-color-scheme` and the picker's pressed state has a non-color indicator (border width or a check glyph); a Playwright run with `forcedColors: 'active'` asserts exactly one lockup is visible and `aria-pressed=true` button has a different computed border-width or text." Source: MDN `forced-colors` media feature, WCAG 2.2 SC 1.4.1.

## 9. should-fix: print

Evidence (U, standard behavior): browsers drop backgrounds when printing by default but keep text color, so a chosen dark theme prints Pale Ink on white. Cheap, because tokens are generated: emit the light block again inside `@media print { :root, :root[data-theme] { ... } }` and show the light lockup. Test deterministic: `page.emulateMedia({ media: 'print' })` with stored `dark`; assert body color equals the light ink token. The book also says the logo in print is the light or one-color version.

## 10. should-fix: font synthesis and layout shift

Evidence (V, probe): with the pinned Sometype Mono (`font-weight: 400 500`), text requested at weight 700 renders differently from weight 500 (Chromium synthesizes bold); `font-synthesis: none` removes it. Hanken has no italic, so any `<em>` would be faux italic. The current pages use `<strong>` only in Hanken, but a future `<code>` in a heading or `strong` would be faux bold.

CLS (V from CSS, U on size): the h1 is the likely LCP element and carries `max-width: 11ch`; `ch` is font-dependent, so the swap from the system fallback to Bricolage changes the wrap and the hero height. Note B says "no layout shift tooling is added (not measured)". Preloading helps on warm paths only.

Add: "`:root { font-synthesis: none }`; each `@font-face` has a metric-compatible fallback face (`size-adjust`, `ascent-override`) or the h1 does not use `ch`; the check compares the h1 and hero bounding-box height at 390 and 1440 px with fonts aborted (`page.route` abort `.woff2`) versus loaded and requires a difference under N px." Deterministic, no timing. Optionally preload `mono.woff2` too since the home page hero holds a code block, or accept the swap with the fallback-metrics fix. Do not assert a CLS score; that is flaky in CI.

## 11. should-fix: favicon wiring

Evidence: note B specifies two `rel=icon` SVG links, one with `media="(prefers-color-scheme: dark)"`, plus `favicon.ico`. MDN's `<link>` page documents `media` for stylesheets and says nothing about icon support (V, fetched); browser support for media-conditioned icons is U and should be treated as unreliable. The tab icon follows the browser UI theme, not the site's picker, so a Light-default site cannot control it anyway. The ICO-versus-SVG ordering is also known to bite: MDN's example gives the `.ico` explicit `sizes="16x16 32x32 48x48"` and the SVG `sizes="any"` (V, fetched), so the browser can choose.

Add to SITE-01: "Icon links: `rel=icon href=favicon.ico sizes="32x32"`, `rel=icon type=image/svg+xml sizes=any` pointing at one pinned themed SVG, with the dark variant by `media` as an enhancement only; the check asserts every declared icon returns 200, that there is no request to `/favicon.ico` at the origin root (Chromium logs a 404 console error for it, which would fail the zero-console-error assertion), and that `favicon.svg` is referenced nowhere." Optional nit: no 180 px `apple-touch-icon` exists in `brand/assets/icon`, so iOS uses a page screenshot.

Social card (V): `scrypath-social-card-1280x640.png` is a real 1280x640 8-bit RGB (color type 2, no alpha), so the transparent-PNG crawler problem does not apply. Add `og:image` absolute-URL and `og:image:width/height/alt/type` plus `twitter:image:alt`, and in the static contract read the PNG signature and IHDR from `dist` and assert 1280x640 and that the meta URL equals `SITE_URL` + the published path. Social crawlers cache by URL, so a future card change needs a new filename; the dimensions-in-name convention does not give that. Nit.

## 12. should-fix: deploy safety

Evidence (V, `website.yml`): (a) `concurrency: cancel-in-progress: true` applies to the whole workflow including `deploy`; a second push during a deploy cancels it mid-flight (GitHub's Pages starter uses `group: pages`, `cancel-in-progress: false` for the deploy). (b) No step runs after `deploy-pages`; the first time anyone learns of a subpath, MIME or cache problem is a visitor. (c) Rollback in note B is "revert PR, which redeploys", that is a PR, the required lanes, and `build-and-check` (1 to 8 minutes) before the deploy: 5 to 15 minutes for a broken live site.

Add to SITE-05: "The `deploy` job keeps `cancel-in-progress: false` for itself (own concurrency group), and ends with a smoke step against `steps.deployment.outputs.page_url` that asserts 200 for the home page, one font, both lockups, the social card, and that the font response header and the og:image URL resolve under `/scrypath/`. `workflow_dispatch` with a `ref` input (checkout that SHA) is the documented rollback, written in `docs/releasing.md`." The smoke step also answers the open "Pages font MIME" question with evidence from the real host.

## 13. should-fix: SITE-05's required-or-not analysis missed two cheaper options

Evidence (V): `website.yml` `pull_request` has no `paths`, so every PR (docs, planning, ops, Dependabot for other lanes) runs this job; the 39-run sample shows it on nearly every PR. Because the job is not required, adding `paths` to the `pull_request` trigger is safe (no pending-forever required context). Use the same list as the push filter: `website/**`, `brand/**`, `scrypath_ops/priv/static/assets/fonts/**` (the source note B copies fonts from), `examples/scrypath_ecommerce/contrast-checker.mjs` if imported, `mix.exs`, `README.md`, `guides/**`, `docs/**`, workflow file.

If gate 9 is wanted later, the repo already has the pattern that avoids the "every PR pays" objection: a job-level classifier that reports when skipped (`ops-ui (path-scoped)`), which a workflow-level `paths` filter cannot do. Note B's reason for "not required" ("every PR pays 8.5 minutes") weakens with the 1-minute median and with this pattern; the decision can still be "not required" but SITE-05 should record these reasons, not the 8.5 minute figure.

Also (V): `pull_request` checks out the merge ref, so "green on the exact head SHA" means the merge of head and base at run time. SITE-05 evidence should be a command the agent runs, not prose: "`gh api repos/szTheory/scrypath/commits/<head>/check-runs` shows `build-and-check` completed/success and `head_sha` equals the PR head; recorded in the verification file."

## 14. should-fix: theme.js can hold a color literal that nothing scans

Evidence: note B has `theme.js` update `<meta name="theme-color">` in dark. The dark page color then lives in JS as a hex, and static test #3 scans only `styles.css` and `layout.html`.

Add to criterion 1: "the no-literal scan covers every source file under `website/src` (css, html, js, svg), and `theme.js` reads the color from `getComputedStyle(document.documentElement).getPropertyValue('--page')` rather than carrying a literal." Also assert in the static contract that `theme.js` is a classic synchronous `<script src>` inside `<head>` (no `async`, `defer`, `type=module`, which defer execution and reintroduce the flash) and that the CSP meta is the first `<meta>` after charset (a meta CSP only governs content after it). Dynamic flash test that is deterministic: with stored `dark`, read computed body background at `DOMContentLoaded` (via `addInitScript` listener) and require the dark token. Do not use paint timing.

## 15. nits and notes

- Static hex scan: `#[0-9a-f]{3,8}` matches `&#8217;`, `#123` in prose and fragment links like `#face`. Note B says there are no entities today (V). Scan CSS, SVG attributes, `content=` of theme-color and `style` only, not HTML text, and plant an `&#8217;` accept case. Pinned lockups and light/dark favicons use only token hexes (V: `#1E1220 #7B2D6B` and `#D58BC4 #F4EDF3`), so the closed set holds.
- Fixed port 4173 in `check.mjs`: use port 0 and read it from stdout; a busy port currently surfaces as "server exited before ready".
- "Exactly three `.woff2` requests" holds only on the home page (the only page with a code block, V: `code` in `index.html`); the other pages request at most three and only pinned files. State "home: exactly 3; every page: subset of the pinned set", wait on `document.fonts.ready` before counting.
- Responsive/a11y checks the plan omits and that are deterministic: no horizontal overflow at 320 px (`scrollWidth <= clientWidth`; the existing `.status-strip code { white-space: nowrap }` is a likely failure, WCAG 2.2 SC 1.4.10), minimum 24 px target size for picker and nav (SC 2.5.8), and `reducedMotion: 'reduce'` computes `transition-duration: 0s` (current CSS only retimes the easing under `no-preference`, V, and hover uses `translateY`).
- Picker semantics: three buttons with `aria-pressed` in a `role=group` is fine for a mutually exclusive set of three and avoids the roving-tabindex work a `radiogroup` requires (WAI-ARIA APG); keep arrow keys unimplemented and document Tab order: skip link, brand, nav, picker, star, version pill. Label the group ("Color theme"); the check asserts it.
- Cache busting (V: Pages `max-age=600`): worst case is 10 minutes of new HTML with an old `styles.css`/`tokens.css`. Content-hashed filenames in `build.mjs` are about 10 lines and remove it; otherwise accept and write it down. Font filenames are stable; a pin refresh replaces bytes under the same name.
- Dark display weight: `tokens.json` says dark headlines use weight 670; decide (the subset covers 600-800) and assert one value.
- Dependabot (V `dependabot.yml`): `/website` npm is grouped weekly with a limit of 3; `Playwright` is not ignored there (it is for the ecommerce lane, which pins Playwright by hand). A weekly Chromium bump can only move computed-style assertions if the checks parse serialized colors (item 4); that is the thing to harden, not the Dependabot config. No new package is added by this phase.
- `website.yml` uses `fetch-depth: 0` in both jobs; build reads only `mix.exs` and `brand/`; safe to drop (about 5 s, V step timing).
- Gate budget: nothing here adds a required gate.

## Primary sources

- WCAG 2.2: SC 1.4.1 Use of Color, 1.4.3 Contrast (Minimum), 1.4.10 Reflow, 1.4.11 Non-text Contrast, 2.4.7/2.4.11 Focus Visible/Not Obscured, 2.5.8 Target Size (Minimum), https://www.w3.org/TR/WCAG22/
- GitHub runner image contents (Google Chrome on ubuntu-24.04): https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2404-Readme.md
- MDN `<link>` (`media`, `sizes`, icon examples): https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/link
- MDN `forced-colors`, `font-synthesis`, `color-scheme`, CSP `<meta>` limitations (`frame-ancestors`, `report-uri`, `sandbox` unsupported)
- GitHub Pages: `actions/deploy-pages` concurrency guidance and `actions/configure-pages` starter workflow
- Live check, 2026-11-20: `curl -I https://sztheory.github.io/scrypath/` (`cache-control: max-age=600`, `access-control-allow-origin: *`)
- Run history: `gh run list/view` on `website.yml`, 39 runs
