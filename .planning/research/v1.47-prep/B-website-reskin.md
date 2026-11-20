# Decision B: website re-skin (SITE-01)

Status: PREP NOTE for owner review, written 2026-11-19. Recommendations and research only; no phase plan, nothing started. Read-only on source.

Labels: V verified by reading a file or querying GitHub in this session; R read in a file; U unverified or judgment. Primary sources (WCAG 2.2, MDN, the OFL text, GitHub Pages docs) are cited from background knowledge and were not re-fetched this session, so treat them as U.

## Recommendation (one option)

Re-skin the website as one PR in three plans, deriving everything from the pinned `brand/` files at build time instead of copying values into the site:

1. `website/scripts/build.mjs` generates the theme CSS variables from `brand/tokens.json` and copies the pinned fonts, lockups, favicons and social card into `dist/assets/`. No hex literal appears in website source. The pin (`mix verify.brand`) already guards the source bytes, so the site needs no second pin file.
2. A dependency-free Node contract test (`website/scripts/site-contract.test.mjs`) covers everything that needs no browser. It runs through the same ExUnit wrapper pattern as `ui-tokens.test.mjs`, so it rides `core` and `repository-contracts`. A Playwright rewrite of `check.mjs` covers computed style, font requests, theme behavior and contrast, and stays in the existing `build-and-check` job.
3. Light is the default; dark is reached through a small three-state picker (Light, Dark, System) backed by a roughly 1 KB external script.
4. Bricolage ships (about 27 KB).
5. `build-and-check` is NOT made a required status check. The existing `deploy needs build-and-check` dependency plus exact-head evidence recorded before a manual merge is the safety. The browser install step should be fixed for speed first.

Confidence: 0.75 on derive-at-build, static plus browser split, and shipping Bricolage. 0.6 on the dark picker. 0.55 on leaving the website job non-required.

What would change it:
- If the maintainer wants auto-merge on green for the site, make `build-and-check` required (gate 9 of 12) after the install-time fix.
- If the maintainer wants light-only, drop the picker, `theme.js` and the dark token block (one task fewer; tests shrink).
- If the Playwright install cannot be made fast, accept about 8.5 minutes on a non-required job.

## Verified facts

### Current website
- Stack: no framework and no runtime JS. `website/scripts/build.mjs` (117 lines, node built-ins only) renders `src/layout.html` plus `src/pages/*.html` into `dist/` by `{{TOKEN}}` replacement. `serve.mjs` is a 48-line static server whose MIME table has no `.woff2`, `.png` or `.ico`. The only devDependency is `playwright` (`^1.53.1`; 1.60.0 installed). (V)
- `scripts/check.mjs` is a screenshot capture, not a check. Its only assertion is that the h1 text matches, and it captures with `colorScheme: 'dark'`. (V)
- `src/assets/styles.css` is 11 KB, dark-only (`color-scheme: dark`), system-font stacks, and holds many literal colors: `#9f8cff #7b61ff #e0a06d #f0bc93 #83d6ee #8ad9b6 #0b0f15 #0b1018 #0d121a #111723 #131b27 #f5f1e8 #aeb8c8 #7d889a #090d13 #f5efe4`, plus rgba grid and gradient decoration (`body::before`, three gradients) and two `text-transform: uppercase` sites. (V)
- Other old-identity files: `brand-mark.svg` (`#6c5ce7 #d08e54 #f4f1ea`), `og-image.svg` (SVG, which most social crawlers do not render; `#0c0f14 #9aa4b6 #d08e54 #f4f1ea`), `diagram.svg` (old hexes, system-font text, used once on the home page as a decorative `<img>`), and `<meta name="theme-color" content="#0b0f15">`. (V)
- No inline script, no inline style attribute, no external origin in the source. All colors and fonts are therefore swappable without touching page markup. (V)
- `scroll-behavior: smooth` is set unconditionally, and only a transition-timing rule sits inside `prefers-reduced-motion: no-preference`. It is a reduced-motion gap to fix in this phase. (V)
- Website text is ASCII plus two curly quotes; no HTML entities. (V)

### Deploy and CI
- The workflow is `.github/workflows/website.yml`, not `ci.yml`. Triggers: `pull_request` (no path filter) and `push` to `main` with paths `website/**`, `README.md`, `guides/**`, `docs/**`, `mix.exs` and the workflow file. `deploy` runs only on push and `needs: build-and-check`, and rebuilds from source. (V)
- Branch protection on `main` requires 6 contexts: backend, core, ecommerce-mounted, package, repository-contracts and `ops-ui (path-scoped)`. `build-and-check` is not among them. `strict` is true. There are no rulesets. (V)
- The `github-pages` environment allows deployments from `main` only (branch policy), so a PR cannot deploy a preview and there is no Pages preview. (V)
- Latest `build-and-check` run: the `npx playwright install --with-deps chromium` step took about 8 min of the 8m30s job; the `npm run check` step took about 5 s. (V, run 44422718989)
- Open Dependabot PR #128: playwright 1.60.0 to 1.65.1, touches only `website/package.json` and `website/package-lock.json`, mergeable, its own `build-and-check` passed. #129 is a separate lane (the ecommerce example's axe package). (V)
- The Phase 186 deny-list is already wired. `ui-tokens.test.mjs` scans `git ls-files` (tracked plus untracked and not ignored), so it covers `website/src` but not the ignored `website/dist`. The allowlist has 7 entries (ceiling 7); two are `p189` website entries (`brand-mark.svg`, `og-image.svg`, `max_hits` 2 each). The tag the roadmap calls "website-tagged" is `p189`. (V)
- The deny list does not contain the website's own old palette: none of `9f8cff 7b61ff e0a06d f0bc93 0b0f15 0b1018 0d121a 111723 131b27 f5f1e8 83d6ee 8ad9b6 aeb8c8 7d889a 090d13 d08e54 0c0f14 9aa4b6` is on it, so today the deny-list would NOT notice the website CSS keeping the old identity. SITE-01's "reports no retired identity value in website assets" therefore needs the deny set extended in the same change. (V by comparing the two lists)
- `examples/scrypath_ecommerce/contrast-checker.mjs` exports `contrastRatioRaw`, `evaluatePair`, `passesAA` and `readThemeProperties` and only runs `main()` when invoked directly. `brand/brand.json` publishes 14 contrast pairs with per-theme ratios (for example body 16.53 light and 16.43 dark, link 8.64 and 6.92, focus 7.91 and 7.49). (V)
- CONTRIBUTING's ledger says 8 of 12 gates used. `workflow_wiring_test` enforces the table. The Node token test is run through an ExUnit wrapper (`test/mix/tasks/ui_contrast_contract_test.exs:103`), not a workflow step. (V)

### Brand assets
- The pin already copies, byte-verified: `brand/assets/logo/scrypath-lockup-{light,dark}.svg` (5.8 KB each, wordmark drawn as vector shapes, so the logo needs no font), `brand/assets/icon/favicon-{light,dark}.svg`, `favicon.ico` (1,573 B), the social card PNG (1280 by 640, 29.6 KB), and in `scrypath_ops/priv/static/assets/fonts/`: `display.woff2` 27,072 B (Bricolage, wght 600-800, 174 glyphs), `ui.woff2` 16,128 B (Hanken, wght 400-700, 172 glyphs), `mono.woff2` 9,876 B (Sometype Mono, wght 400-500, 174 glyphs), and the three OFL text files (about 4.4 KB each). Total font payload is about 53 KB. (V)
- All three subsets contain U+201C, U+201D, U+2019, U+2014 and U+2192, and lack U+00B7 (the middle dot). The website needs none of the missing ones. (V via fontTools)
- BUG in the pinned book assets: `brand/assets/icon/favicon.svg` has no `<style>` and no `fill` attribute, so its two paths render in the default black. The book claims the favicon follows the device scheme, but only the separate `favicon-light.svg` and `favicon-dark.svg` carry real fills (`#1E1220` plus `#7B2D6B`; `#F4EDF3` plus `#D58BC4`). The site must not use `favicon.svg`. Phase 187/188 already worked around this on the ops and docs side. Report it to the book's author with the ExDoc CSS bug. (V)
- The OFL copyright lines declare no Reserved Font Name for any of the three families (V: first lines of each text file). Subsetting is modification, which the OFL permits when no RFN is declared; the license text must travel with the font files. (R, U on legal subtlety)
- The book's website application spec: headline is the tagline (`brand.json` tagline equals the current h1, "Search indexing that feels native to Ecto."), one Plum button "Read the golden path", a Mix command picture instead of a generic illustration, and no version badge. "Light by default. Dark when chosen, or when System follows a dark device." The theme picker offers Light, Dark and System and remembers the choice; "Docs and website follow the same rule." The book's type scale: display 56 px/1.05/-0.02em, heading 28/1.2, body 16/1.55, dense 13, label 12; type tokens use Bricolage 700. (V)

## 1. What to change in website/

| Area | Change | Why |
|------|--------|-----|
| Tokens | `build.mjs` reads `../brand/tokens.json` and emits `assets/tokens.css`: light variables on `:root`, dark on `:root[data-theme="dark"]`, and the same dark set inside `@media (prefers-color-scheme: dark) { :root[data-theme="system"] {...} }`. A hand-kept role map in `build.mjs` (page, panel, ink, muted, link, edge, sunken, selected, code-bg, code-text, status colors, focus) names a light path and a dark path per role. | Derive beats copy: the site has no hex, nothing can drift, and a pin refresh flows through. Cost is about 30 lines of Node, less than a parity test plus a hand-maintained block. |
| `styles.css` | Rewrite to variables only: no hex, no rgb/rgba/hsl, no named colors except `transparent` and `currentColor`. Translucent edges use `color-mix(in srgb, var(--ink) N%, transparent)`. Delete the grid overlay and the three gradients (the book allows no gradient). Replace both `uppercase` rules. Move to the book scale (h1 56 px at wide widths, clamped down on mobile; headings Bricolage 700; body Hanken 16; code Sometype Mono 13). `scroll-behavior: smooth` goes inside `prefers-reduced-motion: no-preference`. Focus ring uses the Plum or Orchid focus token, at least 2 px. | A flat tokenized sheet makes the "no literal colors" rule enforceable by a 10-line test. |
| Fonts | `@font-face` x3 with `font-display: swap` and CSS-relative `url(fonts/...)` (the sheet lives in `assets/`, so it works under the `/scrypath/` Pages subpath). Weight ranges set to the subset's real axes (600-800, 400-700, 400-500). Preload only `ui.woff2` and `display.woff2`, with `crossorigin` (a same-origin font preload without it is fetched twice). Copy the three OFL files into `dist/assets/fonts/` and link them from the footer. | Same-origin keeps CSP simple; OFL text must travel with the files. |
| Logo | Replace the mark plus text with the light lockup and the dark lockup (two `<img>`, one shown per theme by CSS, `alt="Scrypath"` on the link or image, width at least 136 px so the 4.71:1 lockup stays at least 29 px tall, `flex-shrink: 0`). Drop the `<small>` tagline in the header. | Matches the Phase 187 rule ("exactly one lockup displayed per theme"). |
| Favicon | `<link rel="icon" type="image/svg+xml" href="assets/favicon-light.svg">`, a second with `media="(prefers-color-scheme: dark)"` for `favicon-dark.svg`, and `favicon.ico` as fallback. Do not use the pinned `favicon.svg`. Keep one `theme-color` (light page color); `theme.js` updates it in dark. | Verified bug above. |
| Social card | Use the pinned PNG for `og:image` and `twitter:image` with width, height and alt meta; delete `og-image.svg`. | SVG OG images are not rendered by most crawlers; the book ships the right PNG. Free product improvement. |
| Diagram | Replace `diagram.svg` with an inline SVG (`{{INLINE:diagram}}` expanded by `build.mjs`) that uses `var(--...)` classes and inherits the site fonts, so it themes with the page. If that proves fiddly, replace it with an HTML and CSS flow of five boxes. | An `<img>` SVG cannot read page variables; the old file would trip the extended deny-list. |
| Theme | `assets/theme.js` (about 1 KB, external, blocking in `<head>`, no inline script) reads `localStorage` in try/catch, sets `data-theme` before first paint, wires a three-button `role="group"` picker (aria-pressed) and updates `theme-color`. The picker markup ships with `hidden` and the script reveals it, so no-JS visitors see no dead control. Absent or unreadable storage means light. | Light default plus dark access without a flash. |
| CSP | `<meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src 'self'; style-src 'self'; font-src 'self'; script-src 'self'; base-uri 'none'; form-action 'none'">`. GitHub Pages cannot set headers, so a meta tag is the only option (`frame-ancestors` does not work in meta). | Free, and the source already has no inline script or style. |
| `serve.mjs` | Add `.woff2` (`font/woff2`), `.png`, `.ico` MIME types. | Required for the font checks. |
| `layout.html` | New head (icons, preload, CSP, social meta), lockups, picker. Footer links to the OFL texts. | |
| Out of scope | The book's site content spec (single Plum button, command picture, no version badge, tagline as headline). The tagline already equals the h1. Log the rest as a Phase 190 wording follow-up or v1.48. The version pill stays. | SITE-01 is identity, not layout or copy; layout changes would also change the h1 and CTA assertions. |

Footgun list: a font preload without `crossorigin`; `font-display: swap` hiding a 404 (the Phase 187 Dockerfile lesson, so the browser check must assert the font responses); relative `url()` in CSS resolves against the stylesheet, not the page; `color-scheme: light` must follow the theme or native controls and scrollbars stay light in dark; `localStorage` throwing in private windows; the picker's `aria-pressed` state must match `data-theme`.

## 2. Exact automated verification

### A. Static contract (no browser, no npm install): `website/scripts/site-contract.test.mjs`

Run through an ExUnit wrapper (new `test/mix/tasks/website_contract_test.exs`, copying the `ui_contrast_contract_test.exs` pattern) so it rides `core` and `repository-contracts`. `build.mjs` gets an `--out <dir>` option (and `SCRYPATH_SITE_OUT`) so the test builds into a temp directory and never touches `dist/`.

1. Every pinned asset the site serves (3 fonts, 3 OFL, 2 lockups, 2 favicons plus `.ico`, social card) is byte-identical to its `brand.pin.json` sha256.
2. Generated `tokens.css` values equal `brand/tokens.json` hexes for each role, both themes. The `[data-theme="dark"]` block and the `system` media block hold the same dark values.
3. Source `styles.css` and `layout.html` contain no color literal (hex, rgb, rgba, hsl, color(), named colors other than `transparent` and `currentColor`).
4. Every hex in the built `dist` (CSS, HTML, SVG) belongs to the brand token set. This is a closed set, stronger than a deny-list, and it covers `dist`, which the git-based deny-list cannot see.
5. Default state: `:root` is the light token block and no `data-theme` is hard-coded into the HTML. Dark exists only under `data-theme="dark"` and the `system` media block.
6. `font-display: swap` on all three faces; every `url()` is relative; no `http(s)://` in CSS; no inline `<script>` or `style=`; the CSP meta is present and has no `unsafe-inline` or `*`.
7. Non-ASCII characters in built HTML are a subset of the test-owned list {U+201C, U+201D, U+2019, U+2014, U+2192} (verified present in all three font subsets); this avoids a woff2 parser.
8. Planted failures through the same functions (the 186 pattern): a hex outside the token set, an rgba, a missing OFL file, a changed font byte, a `font-display: block`, an inline script. Each must fail.

Cost: about a second of Node, no new gate if the existing token-test row is widened to name this file; counted conservatively it is gate 9 of 12 (see below).

### B. Deny-list (existing, git-tracked scan)

In `ui-tokens.test.mjs` and `retired-identity-allowlist.json` (a two-file edit, as the ceilings require):
- Extend `DENY_HEX` with the website's old palette listed under Verified facts. None collide with brand token hexes (V by comparison).
- Remove the two `p189` entries; `ALLOWLIST_CEILING` goes from 7 to 5 and `HITS_CEILING` drops by 4.
- Land this in the same commit as the asset swap, because the extended deny set fails on the old CSS and SVGs. The allowlist is shrink-only, so no temporary entry can bridge the gap. That is the same atomic palette-and-guards commit pattern Phase 187 used.
- Roadmap check: "every website-tagged allowlist entry is removed" is a grep for `"tag": "p189"` returning zero, plus the existing stale-entry rule that fails when an entry covers no retired value.

### C. Browser check (rewrite `check.mjs`, same `build-and-check` job, Playwright)

For each of the four pages, serve `dist` and assert:
1. Light default: with an empty `localStorage` and `colorScheme: 'dark'` emulated, `getComputedStyle(body).backgroundColor` equals the light page token and `html` has no dark `data-theme`. Then click Dark: background equals the dark page token, `aria-pressed` is correct and a reload persists it. Click System: it follows the emulated scheme in both directions. With storage blocked, the page still renders light.
2. Fonts: record every response. Exactly three `.woff2` requests across the home page, all 200, `content-type` `font/woff2`, same origin, and their sha256 equals the pinned files. `document.fonts` shows the three families `status === 'loaded'`. The h1 computes to Bricolage, body to Hanken, `code` to Sometype Mono (first family in the computed stack). Zero requests to any other origin.
3. Logo and favicon: exactly one lockup is visible per theme, `naturalWidth > 0`, rendered width at least 136 px, `src` is the pinned file. Both favicon links and the `.ico` return 200; `favicon.svg` is not referenced.
4. Contrast: iterate a selector table (body text on page, muted text, link, primary button, nav, code block, footer) in light and dark; resolve each element's computed color and nearest opaque background; import `contrastRatioRaw` from `examples/scrypath_ecommerce/contrast-checker.mjs` and require at least 4.5 (3 for the focus ring). Also assert that the body pair rounds to the book's published ratio (16.53 light, 16.43 dark) and the link pair to 8.64 and 6.92 from `brand/brand.json`, so a token or role mistake is caught, not just a low ratio.
5. Accessibility basics: with `reducedMotion: 'reduce'`, computed `transition-duration` is 0 and `scroll-behavior` is `auto`. Tab to the first link: outline at least 2 px with at least 3:1 against its background. The skip link exists and is the first focusable element. Minimum computed font size is at least 12 px and no `text-transform: uppercase` anywhere.
6. Security: zero `securitypolicyviolation` events and zero console errors on every page in both themes; every request origin is 127.0.0.1.
7. Screenshots stay as an artifact (light and dark, desktop and 390 px) and are explicitly not a gate. Rendered critique is scoped, non-blocking and not claimed as independent approval.

Zero human UAT: nothing here needs a person to look at anything. The picture's subjective quality is outside the gate by design, per AGENTS.md.

### Gate budget

- Static contract: counted as gate 9 of 12 (conservative), enforced by the new ExUnit wrapper, runs in `core` and `repository-contracts`. Deletion trigger: delete if the website leaves this repository or stops building from the pinned brand. Churn per UI PR: none unless a brand asset or token role changes; an allowed non-ASCII or role-map edit otherwise. Update the CONTRIBUTING table and keep `workflow_wiring_test` green.
- Browser check: stays in the existing non-required `build-and-check`; counts as no gate.
- Budget after the phase: 9 of 12.

## 3. Pre-merge safety for a deploy-on-merge site

- No preview exists: the Pages environment is `main`-only (V). Adding a third-party preview action would add supply-chain surface (house rule against a new dependency). Use artifacts instead: have the existing job also upload `website/dist` (the `upload-artifact` pin is already in the file) beside the screenshots, so a reviewer can download and serve it with `node scripts/serve.mjs`. Cost: seconds.
- The safety stack is: static contract in required `core` and `repository-contracts` (fast and blocking); `build-and-check` on the exact PR head with `strict: true` so the head is current with main; then, after the squash merge, `deploy needs build-and-check` on the merge commit. If the post-merge browser check fails, deploy is skipped and the old site stays live. Rollback is a revert PR, which redeploys.
- Do not make `build-and-check` required in this phase. It runs on every PR (no path filter on `pull_request`) and costs about 8.5 minutes, nearly all of it the browser install; as a required gate it would add that to every PR, including Dependabot. Evidence for the criterion instead: before the manual merge (visible UI merges already wait for the maintainer's yes) record the `build-and-check` conclusion for the exact head SHA (`gh api repos/.../commits/<sha>/check-runs`) in the phase verification file.
- Risk to name: auto-merge on green waits only for required checks, so a red non-required website job would not block it. The mitigation is the manual merge above. If the maintainer prefers enforcement, make it required after the speed fix (gate 10).
- Add to the push path filter in `website.yml`: `brand/**`, `scrypath_ops/priv/static/assets/fonts/**` and `examples/scrypath_ecommerce/contrast-checker.mjs`, so a pin refresh redeploys the site. Today a font or token refresh would never redeploy it (V: the filter lists only `website/**`, README, guides, docs, mix.exs and the workflow).
- Optional: `workflow_dispatch` on `website.yml` for a manual redeploy; `deploy`'s `if` would need to allow it.

### CI speed (measured, to apply in the same change)

- The browser install is about 8 minutes of 8m30s (V). Candidates, in order of least change: (a) cache `~/.cache/ms-playwright` keyed on the Playwright version from `package-lock.json` and install system packages only on a cache miss; (b) try dropping `--with-deps` on ubuntu-24.04, which often suffices for headless Chromium (U, measure first); (c) run the job in a digest-pinned Playwright container, which couples the image tag to the npm version. Measure (a) and (b) in plan 01 and keep whichever wins without weakening the check.
- `fetch-depth: 0` is unneeded in both jobs; the build reads only `mix.exs` and `brand/`.
- `deploy` repeats `npm ci` and the build even though only `dist` is needed; leave it (it is cheap, and a rebuild from the merge commit is the safer shape).
- Record the measured numbers in `.planning/` and update the CONTRIBUTING table.

## 4. Does Bricolage have to ship?

Yes, ship it. Reasons: the requirement text names it; the book's type tokens set display and heading in Bricolage 700; the website's headline is the first place the identity shows. The ops decision (Hanken and Sometype Mono only, Bricolage for website and docs) was already recorded in the v1.46 prep, with the ops h1 in Hanken, so the website is exactly where Bricolage belongs. The logo is outlined vectors and needs no font, so Bricolage affects only h1 and h2. Cost: 27,072 B (about 51 percent of the 53 KB total), and the file is already committed and pinned under the ops static directory (V), so no new bytes in the repository. Licensing: OFL 1.1, no Reserved Font Name declared; serve the three OFL texts (about 13 KB) next to the fonts and link them from the footer. The subsets are Latin (about 174 glyphs) with only the wght axis (600-800), so display optical-size and width axes from the book are not used on the site. That is acceptable: the logo carries the opsz 96 and width 90 drawing. Do not claim the web headline matches the book's specimen at all sizes. Missing glyphs: U+00B7 is absent in all three subsets, so the test-owned character list is the guard.

## 5. Phase size, order and risks

Size: 3 plans, one PR, about the size of Phase 186 (3 plans), far below Phase 187 (11).

- 189-01 (guards and pipeline): merge or rebase Dependabot #128 first (separate, green, only lockfile changes), then add `build.mjs` derive-and-copy, `--out`, `serve.mjs` MIME types, the static contract and its planted failures, the Playwright rewrite written to the new expectations, and the CI speed experiment. Cheap check first: run `node scripts/build.mjs --out <tmp>` and the static test, which should fail red on the old CSS.
- 189-02 (the atomic re-skin commit): `layout.html`, `styles.css`, `theme.js`, inline diagram, lockups, favicons, social card, OFL links, deletion of `brand-mark.svg`, `og-image.svg`, old `diagram.svg`, the `DENY_HEX` extension plus allowlist and ceiling edit, `website.yml` path filter and artifact upload. Run the static contract, the browser check locally, the token test and the repository-contracts lane once on the final commit.
- 189-03 (closeout): ledger row and CONTRIBUTING, playbook update (derive-at-build, favicon bug, deny-list gap for per-surface palettes), report the favicon bug to the book's author, record the Phase 190 follow-ups (book's website spec items), exact-head evidence, Draft PR with downloadable `dist`.

Risks:
- Dependabot #128 changes the Playwright minor version. There are no pixel baselines, so it only matters if an API used by the rewrite changed; merge it first so the new check is written against the final version. If CI reds on it, the cause is isolated.
- The cross-directory import of `contrast-checker.mjs` couples the website job to the ecommerce lane; moving that file fails loudly. Alternative: copy the 12-line WCAG function (house rule favors copy over dependency). I recommend the import for single math and the push-filter entry above.
- Atomicity: the extended deny set cannot be staged; plan 02 is one big commit. Same trade-off as Phase 187.
- Dark mode is new surface: the site has never had a light theme, and dark text pairs need the checks above (both published dark ratios are in the book, so mismatches show up).
- `meta` CSP regression risk if someone later adds an inline script; the static test catches it.
- The pinned book itself has bugs (favicon). Treat other pinned assets as unproven until a rendering probe confirms them.

## Lenses (strongest point from each)

- Security: no third-party origin at all (same-origin fonts, no CDN, no analytics) plus a meta CSP that the source can already satisfy; nothing to pin or hash beyond the existing brand pin. Supply chain adds zero packages.
- Product: the identity has to be visibly the book's; the social card PNG and a real lockup do more for first-impression than any CSS detail, and the og:image fix repairs a broken-in-practice link preview.
- Architecture: derive from the pinned `tokens.json` at build time so the pin is the single source of truth; the site stays a no-framework static build.
- DevOps and CI: the browser install is 94 percent of the job time; fix that before anything else, widen the push path filter so a pin refresh redeploys, and do not make a slow job required.
- Design and UX: follow the book's scale and the flat, no-gradient rule; remove the grid overlay and gradients; a picker with System honors devices that prefer dark without making dark the default.
- Accessibility: assert contrast on real computed colors against the book's published ratios, fix unconditional smooth scrolling, enforce a 2 px focus ring and the 12 px floor, give the picker `aria-pressed` and reveal it only when it can work.
- OSS maintainer and adopter: the adopter sees a brand-consistent site with a real link preview; the maintainer gets one place to change a color (the pin), and `dist` as a downloadable review artifact without a hosted preview.
- Rendering and web-framework: a static site served from a subpath needs CSS-relative font URLs, a preload with `crossorigin`, `font-display: swap`, and `color-scheme` that tracks the theme; no layout shift tooling is added (not measured, U).

## Adversarial pass

1. "Derive-at-build is over-engineered; hand-write 26 hex lines and a parity test." The parity test is as large as the generator, the hand block can still drift between light, dark and system copies, and the generator removes all hex from source, which makes the "no literal colors" rule trivially enforceable. Holds.
2. "A picker plus script is scope creep; ship light-only." Fair. SITE-01 only demands light as default, and every extra control is more surface to test. But the current site is dark-only, so dropping dark entirely removes a theme visitors have today, and the book calls dark a complete second theme. Judgment (U): keep, with the cheap fallback of dropping it if plan 02 runs long.
3. "Not making the job required defeats a pre-merge gate." It is true the pre-merge enforcement is by process, not by branch protection. The static contract (which does enforce) covers identity, assets and tokens; the browser job covers rendering and fonts, and deploy is blocked post-merge on it. The residual gap is a rendering failure that only the browser sees, which would leave `main` red with the old site live rather than a broken site live. Acceptable, but if the owner wants auto-merge for this phase, flip it.
4. "Meta CSP could break something in production only." The browser check runs under the same CSP and fails on any violation; GitHub Pages adds no scripts. Residual risk is browser-specific meta handling (U).
5. "Static test in `core` makes every PR slower." It builds to a temp directory in about a second and has no npm install; the risk is `core` going red for a website-only reason, which is the point.
6. "The book's own assets are buggy (favicon, ExDoc CSS); more could be." Yes. The favicon was caught by reading; the browser checks for lockups, fonts and contrast will catch rendering problems in the others. Unproven: the favicon.ico appearance (not probed) and whether the PNG social card meets platform cropping.
7. "Deny-list scan misses dist." It does, because it reads `git ls-files`; the static contract's closed-hex-set check on built output covers it.
8. Did not verify: the browser-install speedups, the CSP in Safari, the .ico contents, and that `contrast-checker.mjs` import works from `website/` (the export is verified, the call path is not run).
