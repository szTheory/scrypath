# Phase 189: Website re-skin - Research

**Researched:** 2026-11-20
**Domain:** A static, framework-free website (`website/`, node built-ins plus Playwright for the browser check) re-skinned from pinned brand files and deployed to GitHub Pages under a project subpath, with a dependency-free static contract in `core` and `repository-contracts`, a rewritten browser check in the non-required `build-and-check` job, and a deploy-on-merge safety stack.
**Confidence:** HIGH for in-repo facts (read or run on 2026-11-20); MEDIUM for design recommendations marked U; the unverified items are explicit tasks for plan 189-01 below.

Legend: **V** = verified on 2026-11-20 by reading the file or running a command (path and line given). **U** = inferred, from a prep or gap-pass note, or not re-run (`[ASSUMED]`). Facts that came from prep note B or gap-pass G and were re-checked carry V; where a source and the files disagree it is flagged **DRIFT**.

<user_constraints>
## User Constraints (from 189-CONTEXT.md)

All locked decisions are in [189-CONTEXT.md](189-CONTEXT.md) (D-01 to D-52). This research does not re-decide them. In short: derive every color, font, lockup, favicon and the social card from the pinned `brand/` files at build time through a role map in `build.mjs`; light by default with a Light, Dark and System picker keyed `scrypath-theme` that is hidden without JS or working storage; serve and test under `/scrypath/`; copy the WCAG function instead of importing it; extend the deny set and drop the two `p189` allowlist entries in the same commit as the asset swap, except `d08e54`, `0c0f14` and `9aa4b6`; keep `build-and-check` non-required; add deploy concurrency, a post-deploy smoke step and a `workflow_dispatch` rollback; three plans with only 189-03 evidence-only; no human UAT, no `<human-check>`, no `verification: backstop`; no merge yes (non-draft PR, squash on green plus `build-and-check` green on the exact head).

### Claude's Discretion
File and helper naming, which install-time fix wins (by measurement), the forced-colors indicator, the single dark display weight, fallback-face metrics, the fonts-blocked height tolerance, whether to content-hash asset URLs.

### Deferred Ideas (OUT OF SCOPE)
The book's site content spec, upstream defect filing, required `build-and-check`, `apple-touch-icon`, Pages preview, CLS scoring, Phase 191 cleanup.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research support |
|----|-------------|------------------|
| SITE-01 | New identity from pinned files; no color literal except the role map; icons and og meta | Verified assets, hashes, `.ico` and PNG headers, token paths; open contradiction on dark `control-edge` (CONTEXT item 1) |
| SITE-02 | Light default, Light/Dark/System picker, storage key, no-JS and blocked-storage hiding, forced-colors, print, reduced motion; fallback rule | Pitfalls 2, 7, 8, 9, 14; probes recorded by G |
| SITE-03 | Deny-set extension and allowlist shrink in the asset-swap commit | Hit counts per hex, ceilings 7/201 to 5/197, carved-out hexes |
| SITE-04 | `check.mjs` rewrite, static contract and ledger row 9, `--base /scrypath/`, workflow filters, install fix | Existing script facts, wiring-test coupling, install timings |
| SITE-05 | Exact-head evidence command, non-required decision, deploy concurrency, smoke, rollback | `website.yml` facts, branch protection, live headers |
| GATE-02 | Standing guardrails | Lane and snapshot facts, fixture-copy list, focused-test list |
</phase_requirements>

## Summary

The phase is well specified. The risky parts are all about a subpath static site served by GitHub Pages and a themed page that must be right before JavaScript runs: a root-absolute asset URL passes every `/`-rooted test and 404s live; a `hidden` attribute is overridden by an author `display`; `color-mix()` computed values break a naive contrast parser; two dark roles have no token. Prep note B plus the fifteen gap-pass G findings are correct on substance, with the corrections listed under **DRIFT** below. Two facts the requirements text gets wrong are recorded in CONTEXT "Open contradictions" (dark `control-edge` is not in `contrastPairs`; the ledger row placement). Everything else needed to plan was verified in the real files.

The cheapest first moves are all local and offline: `node website/scripts/build.mjs --out <tmp>` plus the static contract (expected red against today's CSS), then `node --test examples/scrypath_ecommerce/ui-tokens.test.mjs`, then the browser check against `serve.mjs --base /scrypath/ --port 0`.

## Verified facts (V)

### Website source
- `website/scripts/build.mjs` is 117 lines, node built-ins only. It reads `@version` from `mix.exs` (lines 13-20), defines four pages (lines 23-56), removes and recreates `dist` (lines 58-59), renders `layout.html` plus `pages/*.html` by `{{TOKEN}}` replacement (lines 61-94), copies `src/assets` to `dist/assets` (line 96), writes `robots.txt` and `sitemap.xml` (lines 98-111). It has no `--out` option and no brand-file reads.
- `website/scripts/serve.mjs` is 48 lines. Default port 4173 (lines 9-10); MIME table has `.css .html .js .json .svg .txt .xml` only (lines 12-20), no `.woff2`, `.png`, `.ico`; `/` maps to `/index.html` (lines 26-30); it serves `dist` at the origin root, no base prefix.
- `website/scripts/check.mjs` is 89 lines and is capture-only: port 4173 fixed (line 9), `chromium.launch()` default (line 42), screenshots with `colorScheme: 'dark'` (line 79), its single assertion is the h1 text (line 83). It writes five PNGs to `website/artifacts/` (gitignored).
- `website/src/layout.html` (67 lines): `theme-color` `#0b0f15` at line 6; `og:image` points at `assets/og-image.svg` at line 13; `rel=icon` points at `assets/brand-mark.svg` at line 18; header brand image and `<small>` tagline at lines 25-31; `header-actions` (star link, version pill) lines 40-48. All asset URLs use `{{BASE_PATH}}` (relative). No inline script and no `style=` in any page or layout (grep count 0).
- `website/src/assets/styles.css`: 641 lines, 11,141 bytes. `color-scheme: dark` at line 2, hex and rgba tokens from line 3, `scroll-behavior: smooth` unconditional at line 32, two `text-transform: uppercase` at lines 239 and 460, h1 `max-width: 11ch` at line 257, `.status-strip code { white-space: nowrap }` at lines 345-348, the only `prefers-reduced-motion` block is `no-preference` and only retimes easing at lines 633-641. System font stacks only; no `@font-face`; no `url(` in CSS.
- Pages: `<pre>` only in `index.html` (1); inline `<code>` in `index.html` (9), `docs.html` (4), `operators.html` (6), none in `evaluate.html`. Non-ASCII in page text: curly quotes (for example `operators.html:37`). `index.html:39` embeds `diagram.svg` as a decorative `<img>`.
- Old-identity values in `website/src` (V by grep, counts are occurrences): `aeb8c8` 8, `f5f1e8` 7, `7d889a` 6, `131b27` 6, `f4f1ea` 3, `e0a06d` 3, `0b0f15` 3, `d08e54` 2, `9f8cff` 2, `8ad9b6` 2, `83d6ee` 2, `0b1018` 2, `090d13` 2, and one each of `f5efe4 f0bc93 eedfff eedfd0 9aa4b6 7b61ff 6c5ce7 111723 0d121a 0c0f14`. Many `rgba(...)` triplets (for example `159,140,255`, `224,160,109`, `193,206,229`).
- `website/package.json:11` `"playwright": "^1.65.1"`; the lockfile resolves 1.65.1; the installed `website/node_modules/playwright` is **1.60.0** (stale locally; run `npm ci`). Dependabot #128 is merged; #132 (upload-artifact bump touching `website.yml` and `ci.yml`) and #129 (ecommerce axe) are open.

### Workflow and deploy
- `.github/workflows/website.yml` (105 lines): `pull_request` with no `paths` (line 4); `push` to `main` with paths `website/**`, `README.md`, `guides/**`, `docs/**`, `mix.exs`, the workflow (lines 5-14); workflow-level concurrency `website-${{ github.workflow }}-${{ github.ref }}` with `cancel-in-progress: true` (lines 19-21); `build-and-check` on `ubuntu-24.04` with `fetch-depth: 0` (line 33), Node 22 with npm cache (35-39), `npm ci`, build, `npx playwright install --with-deps chromium` (lines 49-51), `npm run check`, upload of `website/artifacts` (57-63); no `timeout-minutes`. `deploy` runs `if: github.event_name == 'push'` with `needs: build-and-check` (66-67), rebuilds from source, uses `configure-pages`, `upload-pages-artifact` and `deploy-pages` (96-105). There is **no `environment:` block and no `id:` on the deploy step**, and nothing runs after deploy.
- `test/mix/tasks/workflow_wiring_test.exs`: website pin tests at lines 267-321; the events test at lines 323-340 asserts `"  pull_request:\n"`, the `push` paths prefix, `if: github.event_name == 'push'` (line 330) and `fetch-depth: 0` in both jobs (lines 331-332). Any `workflow_dispatch` or `if` change needs this test amended in the same change. The ledger parsing is at lines 613-690 and 1350-.
- Branch protection on `main` (queried today): contexts `backend (required)`, `core (required)`, `ecommerce-mounted (required)`, `package (required)`, `repository-contracts (required)`, `ops-ui (path-scoped)`; `strict: true`. `build-and-check` is not required.
- Recent `build-and-check` runs on 2026-11-20 (runs 44748268083, 44745564013, 44743876272): whole job 47 to 64 s; "Install Playwright browsers" step 27 to 38 s. This confirms G finding 5; the "8 of 8.5 minutes" figure is a tail, not the norm. **DRIFT:** `.planning/reference/CI-EFFICIENCY.md:41` still says "about 8 of 8.5 minutes".
- Live site (curl 2026-11-20): `https://sztheory.github.io/scrypath/` 200, `cache-control: max-age=600`, `access-control-allow-origin: *`; `https://sztheory.github.io/` 404. Website deploys on push to `main` are succeeding (several green `push` runs on 2026-11-20).
- `.github/workflows/ci.yml:367` (`ops-ui-path` regex) names `brand/` and `brandbook/` but not `website/`.
- The `repository-contracts` lane runs `mix verify.repository_contracts`, which runs the explicit `@focused_tests` list in `dev/mix/tasks/verify.phase99.ex:7-17` (it includes `ui_contrast_contract_test.exs`, `workflow_wiring_test.exs`, `ui_tokens_contract_test.exs`); `core` runs `mix verify.core --exclude integration --exclude docs_contract` (`ci.yml:93`). `test/mix/tasks/verify.phase99_test.exs:32` pins the contrast test name in that list.

### Guards and ledger
- `examples/scrypath_ecommerce/ui-tokens.test.mjs`: `ALLOWLIST_CEILING = 7` (line 68), `HITS_CEILING = 201` (line 72), `ALLOWLIST_TAGS` includes `p189` (line 793), `DENY_HEX` (lines 800-806, 30 values, bare six-digit lowercase, whitespace-separated), `RETIRED_DIR` (line 808), `EXEMPT_PATHS` (line 812, `brand/BRAND.md`, `brand/brand.json`, the allowlist), the over-ceiling message at line 1060, the sum check at line 1069. The scan reads `git ls-files --cached --others --exclude-standard`, so it sees `website/src` but not the ignored `website/dist`.
- `examples/scrypath_ecommerce/retired-identity-allowlist.json`: seven entries; the two `p189` website entries are lines 4 and 5 (`max_hits` 2 each); the sum is 2+2+177+1+15+1+3 = 201 (V).
- `test/mix/tasks/ui_contrast_contract_test.exs:104` `@min_token_test_calls 53`; the wrapper runs `node --test` on the token test and checks the test-name floor and the planted and accept naming.
- `CONTRIBUTING.md:245-260`: ledger has 8 rows (offline brand pin, token parity and deny-list, required `ops-ui`, storybook boundary, structural preservation pair check, re-skin static contract, mounted font delivery, re-skin component contract); `Budget used: 8 of 12.` at line 260; the budget sentence at line 247 names only v1.46.
- `test/scrypath/phase112_contract_test.exs:85-89` asserts `website/src/layout.html` contains `https://hex.pm/packages/scrypath`, `https://hexdocs.pm/scrypath` and `{{REPO_URL}}`; `phase110_contract_test.exs` and `phase112_contract_test.exs` also read the page files.
- `scripts/ci/ecommerce_lifecycle.test.cjs:104-125` copies `contrast-checker.mjs`, `app.css`, `contrast-pairs.mjs`, `brand/tokens.json` and `brand/brand.json` into its fixture; this phase should edit none of them.

### Brand files
- `brand/brand.pin.json`: schema `scrypath.brand-pin.v1`, zip sha256 `3fc6d80f...be88`, 44 assets, owned directories `brand` and `scrypath_ops/priv/static/assets/fonts`; each asset has `path`, `source_member`, `sha256`, `size`, `license`, `role`, `kind`. Site-relevant assets: `display.woff2` 27,072 B, `ui.woff2` 16,128 B, `mono.woff2` 9,876 B, three `OFL-*.txt` (4,400 to 4,403 B), `scrypath-lockup-{light,dark}.svg` (5,773 and 5,830 B), `favicon-{light,dark}.svg` (901 and 896 B), `favicon.ico` 1,573 B, `scrypath-social-card-1280x640.png` 29,652 B.
- `favicon.ico` (V by parsing): 2 images, 16x16 and 32x32, both PNG-encoded. The social card (V): 1280 by 640, bit depth 8, color type 2 (RGB, no alpha). Lockup viewBox `22.5 -689 3950.9 838.9` (aspect 4.71).
- `brand/assets/icon/favicon.svg` (V): paths with `class="g"` and `class="l"`, no `<style>`, no `fill`; it renders black. `favicon-light.svg` uses `#1E1220` and `#7B2D6B`; its bytes equal `favicon-32-light.svg` (same sha256 prefix `832e6098c543`).
- `brand/tokens.json` hex inventory (31): light `page #F8F4F2`, `panel #FFFFFF`, `ink #1E1220`, `plum #7B2D6B`, `hairline #E0D5D1`; dark `night #160E19`, `night-panel #201624`, `pale-ink #F4EDF3`, `orchid #D58BC4`, `night-hairline #3A2A3E`; secondary `muted-ink #5E5360`, `muted-pale #BBAAC0`, `sunken-page #F0E9E6`, `selected-page #EBDFE7`, `control-edge #8A7A8E` (light only); status text colors for both themes; code colors for both themes (`background-dark #110A14`). Typography tokens: display Bricolage 700 56 px/1.05/-0.02em, heading 28/1.2, body Hanken 16/1.55, dense 13, label Hanken 600 12, code Sometype Mono 13. The font note says dark headlines use weight 670 in addition to 600, 700, 800.
- `brand/brand.json` `color.contrastPairs` (nested under `color`, line 269) has 14 pairs with string ids: `body descriptor caption application-copy link focus artwork button selected-row selected-status status-failed status-retrying status-pending status-clear`. Each has `light` and `dark` with `text`, `background`, `contrast`. Published values: body 16.53/16.43, link 8.64/6.92 (on Panel), focus 7.91/7.49 (on Page), button 8.64/7.49 (white on Plum; Night on Orchid). `color.print` and `color.never` exist.
- Dark `selected` `#2B2130` is the dark `background` of `selected-row` and `selected-status`. Dark `control-edge` `#8F7F94` is in **no** `contrastPairs` entry; it is only in the role description (`brand.json:235`, `tokens.json:243`), `scrypath_ops/assets/css/app.css:91` and `token-map.json:178`. No dark `sunken-page` token exists; the dark counterpart for code and table-head backgrounds is `code.background-dark`.
- `scrypath_ops/assets/css/app.css:20-33` shows the font-face pattern to copy: CSS-relative `url("../fonts/x.woff2?v=<sha256>")`, `font-display: swap`, weight ranges set to the real axes, and metric fallback faces (`size-adjust`, `ascent-override`, `descent-override`, `line-gap-override`) naming Arial, Liberation Sans, Arimo and Courier New, Liberation Mono, Cousine. Bricolage is not declared in ops, so its fallback metrics are new work.
- `examples/scrypath_ecommerce/contrast-checker.mjs` (1,454 lines): `relativeLuminance` at line 64, `contrastRatioRaw` at line 75, exports at line 1447 (`contrastRatioRaw`, `evaluatePair`, `passesAA`, `readThemeProperties`). The function to copy is lines 60-80.
- Deny-set candidates (18, none in the 31 brand token hexes, none elsewhere in tracked non-planning files, and none of their rgb triplets elsewhere): `9f8cff 7b61ff e0a06d f0bc93 0b0f15 0b1018 0d121a 111723 131b27 f5f1e8 83d6ee 8ad9b6 aeb8c8 7d889a 090d13 f5efe4 eedfff eedfd0`. Carved out: `d08e54` (6 tracked non-planning hits: 4 in `brandbook/`, 2 website), `0c0f14` (11: 10 and 1), `9aa4b6` (2: 1 and 1).

## DRIFT (source versus real files, flagged)

1. **Prep B's palette list is incomplete.** It omits `f5efe4` (in `styles.css`) from the deny list and never mentions `eedfff` and `eedfd0` (both in `diagram.svg`). All three are in CONTEXT D-36.
2. **REQUIREMENTS SITE-01 and G finding 3: `contrastPairs` placement and coverage.** The pairs are at `color.contrastPairs`, not top level, and they cover dark `selected` but not dark `control-edge` (CONTEXT "Open contradictions" item 1).
3. **G finding 15 "the only page with a code block".** True for `<pre>`; inline `<code>` is on the docs and operators pages as well (CONTEXT item 4; D-30 wording).
4. **CI-EFFICIENCY finding 5 and prep B** say the install is about 8 of 8.5 minutes; measured runs today are 47 to 64 s total (CONTEXT D-33, D-39).
5. **G's `.ico sizes="32x32"`:** the pinned `.ico` holds 16 and 32 px images (D-13).
6. **ROADMAP and prep B "Dependabot #128 first":** already merged; no sequencing needed (D-47).
7. **E finding 1 cites `ui-tokens.test.mjs:1059-1060`;** the message is now at line 1060. Numbers and ceilings (177, 7, 201) still match.
8. **Prep B says "`website.yml` pull_request has no paths";** still true, and SITE-04 now requires `brand/**` in the pull-request filter, which means adding a `paths` filter there (D-34).

## Tasks for plan 189-01 (items prep B left unverified, plus new ones)

Each item is verified or decided inside plan 189-01 and its result recorded in the plan summary; none needs the maintainer.

1. **Install-time fix:** measure cold and warm for (a) `chromium.launch({ channel: 'chrome' })` using the runner's preinstalled Chrome (G reports Chrome 157 on the ubuntu-24.04 image; U: not re-verified, check `google-chrome --version` in a hosted run), (b) browser cache keyed on the lockfile Playwright version, (c) `npx playwright install --only-shell chromium` without `--with-deps`. Keep the winner only if every assertion is unchanged. Add `timeout-minutes: 10`. Record in `CI-EFFICIENCY.md`.
2. **Meta CSP in Safari:** stated limit, not asserted. Record that Chromium is the only browser exercised.
3. **`.ico` contents:** done above (16 and 32 px PNGs). The plan asserts the file is byte-identical to its pin and returns 200; it does not assert how it looks.
4. **Copy the WCAG function** (contrast-checker lines 60-80) and assert it reproduces the published ratios in `brand.json` for every pair the site uses, so the copy cannot drift silently from the brand's numbers.
5. **Dark `control-edge` source** (CONTEXT item 1): implement the proposed default or the caller's amendment, and make the build fail when the printed sentence and the role map disagree.
6. **Roles inventory:** list every role the new CSS uses and confirm each resolves in both themes (dark `sunken` and code backgrounds map to `code.background-dark`; dark `selected` and `control-edge` as above). The build fails on any unresolved role.
7. **Wrapper placement:** confirm `core` runs `test/mix/tasks/website_contract_test.exs` through `mix verify.core`, and add the file to `@focused_tests` in `dev/mix/tasks/verify.phase99.ex:7-17` so it also rides `repository-contracts`; add the matching assertion to `test/mix/tasks/verify.phase99_test.exs` if that test pins list members.
8. **Playwright version:** run `npm ci` in `website/` so local runs match the lockfile (1.65.1) before trusting the local browser check; record the version used.
9. **Chromium computed-color serialization:** confirm locally and in a hosted run which forms (`rgb()`, `color(srgb ...)`) the resolver meets, so the planted translucent case reflects reality.
10. **Pages behavior probes in the smoke step:** the live site serves no `.woff2` yet, so the Pages MIME type for `font/woff2` and the response headers are unverified (U). The deploy smoke step answers it with evidence from the real host; the first post-merge run is that proof (a red smoke means rollback).
11. **`serve.mjs` realism:** `--base /scrypath/` must 404 at `/`; decide whether to mimic Pages' `/docs` 301 to `/docs/` (optional; the live site does it).
12. **Ledger and budget:** add row 9 and `Budget used: 9 of 12.` with no pipe in any cell and an existing enforcing file; run `workflow_wiring_test` (focused) before committing.

## Pitfalls (gap-pass G, numbered as in G, plus verified additions)

1. **Subpath blind spot.** The check serves `dist` at the origin root while production is `/scrypath/`. A root-absolute `/assets/...` passes every root-served test and 404s live. Mitigation: `serve.mjs --base`, every assertion under `/scrypath/`, static contract rejects any root-absolute `href`, `src` or `url()`.
2. **`hidden` is overridden by author `display`.** An element with `hidden` and a rule `display: inline-flex` computes `inline-flex`. Mitigation: `[hidden] { display: none !important }`, a JS-off assertion, and reveal only after a storage write probe.
3. **Two dark roles are not tokens.** See CONTEXT item 1 and the role-map decisions.
4. **`color-mix()` breaks a naive contrast resolver.** Chromium serializes it as `color(srgb ...)`, even when opaque. Mitigation: opaque colors for text and fills, a resolver that parses both forms and composites alpha, a planted translucent surface, and pair-by-id assertions with the real background (link is on Panel).
5. **The 8-minute install is the tail.** Median job 47 to 64 s; fix variance with a timeout and a measured install fix, not the median.
6. **Dark primary button label.** Reusing the ink role gives 2.19:1 on Orchid; the `on-primary` role (Night) gives 7.49:1.
7. **Storage key collision across `sztheory.github.io/*`.** All szTheory project sites share one origin; use `scrypath-theme`, validate the value, listen for `storage`, hide the picker when writes fail, and block storage in tests with a throwing getter.
8. **Forced colors.** Image SVGs keep author colors on a system canvas, so the lockup follows `prefers-color-scheme`; the pressed picker state needs a non-color indicator.
9. **Print.** Browsers drop backgrounds but keep text color; re-emit the light block in `@media print` and show the light lockup.
10. **Faux bold and layout shift.** Sometype Mono covers 400-500 only; `font-synthesis: none`. The h1 uses `max-width: 11ch` (line 257), which is font-dependent; add metric-compatible fallback faces or drop `ch`, and compare hero height with fonts blocked versus loaded.
11. **Favicon wiring.** `media` on `rel=icon` is not documented by MDN; treat the dark icon as an enhancement. Give the `.ico` explicit `sizes` and the SVG `sizes="any"`. A request to a root `/favicon.ico` 404s and would fail the zero-console-error assertion.
12. **Deploy safety.** `cancel-in-progress: true` applies to the whole workflow including `deploy`; nothing runs after `deploy-pages`; a rollback by revert PR costs 5 to 15 minutes. Mitigation: own concurrency group, smoke step, `workflow_dispatch` with `ref`.
13. **`pull_request` has no `paths`.** Because the job is not required, adding paths is safe; "green on the exact head" means the merge ref at run time, so the evidence is the `gh api .../check-runs` command with `head_sha` equal to the PR head.
14. **`theme.js` can carry a color literal that nothing scans.** The no-literal scan covers all of `website/src`; `theme.js` reads `--page` from computed style; it must be a classic synchronous head script and the CSP meta the first meta, or the flash returns.
15. **Nits.** The hex regex false-positives on `&#8217;`, `#123` and fragment links; scan CSS, SVG attributes, `content=` and `style`, not HTML text, and plant an accept case. Use port 0, not 4173. Count fonts after `document.fonts.ready`. Assert no horizontal overflow at 320 px (`.status-strip code` is `nowrap`, line 346, a likely failure), 24 px targets, `reducedMotion` transitions 0 s. Three buttons with `aria-pressed` in a labelled `role=group` is fine and avoids roving-tabindex work. Weekly Dependabot Playwright bumps only move computed-style assertions if checks parse serialized colors, so harden that, not the Dependabot config.

Verified additions from this research:
16. **The wiring test pins the deploy `if` and `fetch-depth`.** Adding `workflow_dispatch` or editing the `if` fails `workflow_wiring_test.exs:330-332` until it is amended in the same change.
17. **`repository-contracts` runs an explicit list.** A new ExUnit wrapper only rides `core` for free; add it to `verify.phase99.ex` `@focused_tests` to reach `repository-contracts`, as SITE-04 requires.
18. **`phase112_contract_test.exs:85-89` constrains `layout.html`.** The rewrite must keep the Hex, HexDocs and `{{REPO_URL}}` links, and the page text those tests read.
19. **The deny scan also checks rgb triplets** derived from every deny hex. Website `rgba(...)` values that are not derived from a deny hex (for example `193,206,229`) are only caught by the static contract's no-literal scan, so that scan is load-bearing.
20. **The extended deny set cannot be staged.** The allowlist is shrink-only, so deny-set extension, allowlist removal, ceiling change and the asset swap are one commit (189-02), as in Phase 187.
21. **The deploy step has no `id` and no `environment`.** Add `id: deployment` (and optionally an `environment`) before using `steps.deployment.outputs.page_url`, or read the base URL from `SCRYPATH_SITE_URL`.
22. **Locally installed Playwright is 1.60.0**, the lockfile is 1.65.1; a green local run on the old version is weaker evidence.

## Validation Architecture

Every success criterion maps to an executable check. "Lane" is where the check runs in hosted CI; "local" means the cheap check the executor runs first.

| Criterion | Executable check | Lane | Local first |
|-----------|------------------|------|-------------|
| SC1 static contract (byte identity, token parity both themes via role map, no literal in `website/src`, closed hex set in `dist`, no root-absolute URLs, no `favicon.svg`, og meta with PNG header, CSP, `font-display`, glyph allowlist, planted failures, `workflow_wiring_test` green) | `website/scripts/site-contract.test.mjs` through `test/mix/tasks/website_contract_test.exs`; ledger row 9 checked by `workflow_wiring_test` | `core` (`mix verify.core`) and `repository-contracts` (`@focused_tests`) | `node --test website/scripts/site-contract.test.mjs`; `mix test test/mix/tasks/workflow_wiring_test.exs` |
| SC2 theme behavior (JS off, empty and blocked storage, Dark/Light/System, persistence, DOMContentLoaded dark, reduced motion, forced colors, print) | Rewritten `website/scripts/check.mjs` at `http://127.0.0.1:<port>/scrypath/` | `build-and-check` (non-required; evidence by exact-head `gh api`) | `node website/scripts/check.mjs` after `npm ci` |
| SC3 identity renders (fonts count, hashes, computed families, one lockup, icons 200, contrast per pair id including `button` states, 320 px overflow, fonts-blocked height, no console error, CSP violation or off-origin request) | Same `check.mjs`; resolver proved by a planted translucent surface and the copied WCAG function asserted against `brand.json` ratios | `build-and-check` | same |
| SC4 deny-set and allowlist (18 hexes added, `p189` entries gone, ceilings 5/197, planted old website hex fails, three carved-out hexes asserted absent, both workflow filters list `brand/**`) | `examples/scrypath_ecommerce/ui-tokens.test.mjs` (existing planted and accept machinery) through `ui_contrast_contract_test.exs`; `grep '"tag": "p189"'` returns nothing; `workflow_wiring_test` and a filter assertion for `brand/**` | `core` and `repository-contracts` | `node --test examples/scrypath_ecommerce/ui-tokens.test.mjs` (about 1 s) |
| SC5 deploy evidence (`build-and-check` green on exact head, deploy concurrency, smoke, rollback documented, non-required decision recorded, one gate run per SHA, no stale receipt, no dirty-tree capture) | `gh api repos/szTheory/scrypath/commits/<head>/check-runs` recorded in the verification file; workflow structure asserted in `workflow_wiring_test`; smoke step of the `deploy` job on the merge commit; `docs/releasing.md` section checked by a grep or contract test | PR checks on the exact head; `deploy` job after merge | `gh run list --workflow website.yml` after the push |
| GATE-02 guardrails | One `mix verify.repository_contracts` per committed SHA (escalated permission first run); lifecycle fixture files untouched | `repository-contracts` | cheap checks before the long suite |

Sampling rule: after each plan commit run the focused local checks above; run `mix verify.repository_contracts` once on the committed 189-02 state; the hosted `build-and-check` run on the final PR head is the exact-head evidence. The ExUnit wrapper's floor on test-call count and its planted and accept naming rule keep the static contract from being silently weakened.

## Don't Hand-Roll

| Problem | Do not build | Use instead |
|---------|--------------|-------------|
| Theme CSS values | A hand-kept hex block plus a parity test | Derive from `brand/tokens.json` through the role map (D-01, D-02) |
| WOFF2 parsing for the glyph check | A font parser | A test-owned list of allowed non-ASCII code points (D-16) |
| Preview deploys | A third-party Pages preview action | The static contract and `check.mjs` are the evidence (D-48) |
| Layout-shift scoring | A CLS tool | A fonts-blocked versus loaded height comparison (D-30) |
| Contrast math across directories | An import of `contrast-checker.mjs` | A copied 12-line function asserted against `brand.json` (D-32) |
| Color parsing | A regex over `rgb()` only | Parse `rgb()` and `color(srgb ...)`, or paint on a canvas (D-05) |

## Assumptions Log

| # | Claim | Status |
|---|-------|--------|
| A1 | Chrome is preinstalled on `ubuntu-24.04` runners (Chrome 157 per the runner-images readme) | U, from G; task 1 measures it |
| A2 | Pages serves `.woff2` with a usable `content-type` | U; the first deploy smoke is the evidence |
| A3 | Meta CSP behaves the same in Safari | U; stated limit |
| A4 | Social platforms crop the 1280 by 640 card acceptably | U; not asserted |
| A5 | Media-conditioned dark `rel=icon` is honored by browsers | U; enhancement only |
| A6 | Subsetting under OFL 1.1 with no Reserved Font Name is permitted with the license text shipped | R, from prep B; legal subtlety not re-checked |
| A7 | The 18 deny hexes plus triplets collide with nothing | V on 2026-11-20 against tracked files and the brand token set; re-run in 189-02 |

## What this does not prove

The checks establish, in Chromium only, that the built site matches the pinned brand bytes and tokens, behaves correctly for the theme states listed, serves every asset under `/scrypath/`, meets the computed contrast of the brand's published pairs, and deploys with a live smoke. They do not prove how the site looks (rendered quality and aesthetics), behavior in Safari or Firefox (including the meta CSP), real screen-reader behavior, social-platform card cropping, how the `.ico` renders, or that any person or independent reviewer approved the result. Screenshots are review artifacts only. Nothing here claims aesthetic or independent-review approval.

## Sources

- In-repo, read 2026-11-20: all paths cited with lines above; `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `AGENTS.md`.
- Prep and gap-pass notes: `.planning/research/v1.47-prep/B-website-reskin.md` (primary), A, C, D; `.planning/research/v1.47-gap-pass/G-website-risk.md`, `E-adversarial-review.md`, `F-autonomy-stalls.md` sections 1 and 3.
- Commands run today: `gh run list` and `gh run view` on `website.yml`; `gh api .../branches/main/protection/required_status_checks`; `curl -I` on the live site; a Python parse of `favicon.ico`, the social-card IHDR and `brand.json`; `git grep` for the old palette and rgb triplets.
- Primary sources cited by the notes and not re-fetched here (U): WCAG 2.2 SC 1.4.1, 1.4.3, 1.4.10, 1.4.11, 2.5.8; MDN `<link>`, `forced-colors`, `font-synthesis`, `color-scheme`, CSP meta limits; GitHub Pages `deploy-pages` concurrency guidance; the GitHub runner-images Ubuntu 24.04 readme.
