# Current site inventory (website/)

Read-only inventory, 2026-11-20. No builds, installs or edits were run. Word counts are approximate: element text with tags stripped, so they include template tokens such as `{{REPO_URL}}` and exclude the shared header and footer in `layout.html`.

## 1. Pages

Source: `website/src/pages/*.html`. Each page is injected into `website/src/layout.html` by `website/scripts/build.mjs`. Titles and meta descriptions are set in `build.mjs`, not in the pages.

| Source | Output | Title (build.mjs) | h1 | h2 sections (in order) | Words |
|---|---|---|---|---|---|
| `index.html` | `/` | Scrypath - Search indexing that feels native to Ecto | Search indexing that feels native to Ecto. | Hero (lead paragraph, CTA row, install and baseline blocks, code sample "How it fits"); "One library, four clear jobs." (4 h3 cards: Schema declaration, Sync modes, Recovery and drift, Tenant-safe access); "Three personas, one boundary." (3 cards: App developer, Operator / SRE, Evaluator); "Choose the path that matches your question." (4 links: Docs map, Operator support, Evaluate fit, Example app); "Install, then verify locally." (callout) | ~448 |
| `docs.html` | `/docs/` | Scrypath docs map - guides for Phoenix and Ecto search | Find the guide for your next step. | Page hero; "Start with one schema and one context." (h3: Quick path, Mental model, Meilisearch concepts; anchor `#first-hour`); "Choose by job, not by file name."; "Keep tenant filters impossible to forget." (h3: Multitenancy, Why it matters; anchor `#tenant-safety`); "Run the Phoenix paths before you depend on them." (h3: Phoenix + Meilisearch example, E-commerce/admin showcase, Support posture; anchor `#example`) | ~422 |
| `evaluate.html` | `/evaluate/` | Should I use Scrypath? - evaluation and fit | Should I use Scrypath? | Page hero; "Choose it when the app owns search state." (h3: Why it fits, What it gives you); "Choose something else when the product boundary is different." (h3: Hosted search platform, Magic callback runtime, Public multi-backend facade); "The benefit is clarity, not breadth." (h3: What it avoids, What you still own); "Feature-lane work stays evidence-gated." (h3: Reopen triggers, Canonical policy); closing callout "If you want the app to own search, Scrypath is the right layer." | ~359 |
| `operators.html` | `/operators/` | Scrypath operator support - recovery, verification, and drift | Recovery, verification, and drift should be boring. | Page hero; "Accepted work is not the same thing as visible search." (3 unlabeled h3 blocks; anchor `#sync-modes`); "What to run when someone says “search is wrong.”" (h3: Start here, When you need more, Run Meilisearch; anchor `#recovery`); "The library speaks in telemetry and recovery commands." (h3: Observe, Recover, Escalate); "Start with status, then choose the repair." (callout) | ~334 |

The 404 page, a privacy page and a changelog page do not exist. `sitemap.xml` lists four URLs (root, `docs/`, `operators/`, `evaluate/`).

### Navigation

- Skip link to `#content`.
- Header brand link (`brand-mark.svg` plus "Scrypath" and the tagline "Ecto-native search indexing") to `index.html`.
- Primary nav (`aria-label="Primary"`): Home, Docs, Operations, Evaluate. The nav label "Operations" points to `operators/`, whose title says "operator support".
- Header actions: "Star" button to the GitHub repo; version pill `v{{VERSION}}` to hex.pm/packages/scrypath.
- Footer: one sentence ("Scrypath is Apache-2.0 open source for Phoenix and Ecto teams."), then links to Hex package, HexDocs and GitHub.
- No mobile menu or JS. The nav is plain links.

### Calls to action

- Index hero, primary: "Read the docs" to `docs/`.
- Index hero, secondary: "See operator support" to `operators/`.
- Index hero, ghost: "View on GitHub" to `https://github.com/szTheory/scrypath`.
- Index hero also has a code-sample panel and a "Install from Hex" block showing `{:scrypath, "~> 0.3"}`. The baseline "Elixir 1.17+, OTP 26-28" and "mix verify.adopter" are shown as text.
- Index "Where to go next" cards are links to the four destination pages.
- Header "Star" button and version pill.
- No pricing, sign-up or newsletter forms.

### Outbound links

- `https://github.com/szTheory/scrypath` (header star, index ghost button, footer; hardcoded in `index.html`, `{{REPO_URL}}` elsewhere).
- `https://hex.pm/packages/scrypath` (version pill, footer).
- `https://hexdocs.pm/scrypath` (footer).
- `{{REPO_URL}}/blob/main/...` links from `docs.html` (14 links): `README.md`, `examples/phoenix_meilisearch/README.md`, `examples/scrypath_ecommerce/README.md`, and guides `composing-real-app-search`, `golden-path`, `jtbd-and-user-flows`, `meilisearch-concepts`, `meilisearch-operations`, `multitenancy` (x2), `outside-adopter-intake`, `related-data-and-reindexing`, `request-edge-search`, `scope-and-reopen-policy`, `support-and-compatibility` (x2).
- `evaluate.html`: `guides/meilisearch-concepts.md` and `guides/scope-and-reopen-policy.md`.
- `operators.html`: `guides/meilisearch-operations.md`, `guides/outside-adopter-intake.md` (x2), `guides/scope-and-reopen-policy.md`, `guides/support-and-compatibility.md`.
- No external scripts, analytics, fonts or embeds.

## 2. Assets (`website/src/assets/`)

| File | Bytes | What it is |
|---|---|---|
| `styles.css` | 11,141 | Only stylesheet. 641 lines. Dark-only (`color-scheme: dark`). See section 2a. |
| `brand-mark.svg` | 1,047 | Favicon and header mark. Single path, fill `#6c5ce7` (violet), no background rect. Referenced in `layout.html` as favicon (`<link rel="icon">`) and the header image. |
| `og-image.svg` | 8,875 | Social card as SVG (1200x630; fills `#0c0f14`, `#f4f1ea`, `#d08e54`, `#9aa4b6`). Referenced as `og:image`. SVG is not supported by most social crawlers, so the card does not preview on them. |
| `diagram.svg` | 3,645 | Data-flow diagram (1200x620, "Record to index"). Used once, as `<img class="diagram" alt="" aria-hidden="true">` on `index.html`. |

Images: no raster images in `src/`. Artifacts in `website/artifacts/` (gitignored) hold five screenshots from the last `check` run: `home-desktop.png`, `home-mobile.png`, `docs-desktop.png`, `operators-desktop.png`, `evaluate-desktop.png`.

### 2a. CSS

- One hand-written file, no preprocessor, no framework, no build step for CSS. `build.mjs` copies `src/assets/` to `dist/assets/` unchanged.
- Design tokens are custom properties on `:root`: `--bg #0b0f15`, `--bg-soft #111723`, `--surface`, `--surface-alt`, `--surface-strong #131b27`, `--border`, `--border-strong`, `--text #f5f1e8`, `--muted #aeb8c8`, `--faint #7d889a`, `--violet #9f8cff`, `--violet-strong #7b61ff`, `--copper #e0a06d`, `--copper-soft #f0bc93`, `--cyan #83d6ee`, `--green #8ad9b6`, plus radius, shadow, content width (1160px) and gap.
- The palette is the pre-brand-book palette (violet and copper). It is not sourced from `brand/tokens.json`.
- Fonts: system stacks only (`ui-sans-serif, system-ui, -apple-system, …`; monospace stack for code). No `@font-face`, no web fonts, no `@import`.
- Media queries: `max-width: 1100px`, `max-width: 820px`, and `prefers-reduced-motion: no-preference` (smooth scroll and transitions).
- A fixed decorative `body::before` overlay (repeating vertical gradient lines).
- Hex colors appear throughout the file. Nothing checks them.

### 2b. JavaScript

None. No `<script>` tags in any page or in `layout.html`. The theme is dark-only, so there is no toggle and no theme script.

### 2c. Fonts and images summary

- Fonts: none loaded. The page uses OS system fonts.
- Images: one SVG `<img>` on the home page, two SVGs in the head/header, and one SVG `og:image`. No PNG or WebP in the site source.

## 3. Build, serve, check and deploy

### Files

- `website/package.json`: `"type": "module"`. Scripts: `build` (`node scripts/build.mjs`), `serve` (`node scripts/serve.mjs`), `check` (`node scripts/check.mjs`). Only dev dependency: `playwright ^1.65.1`. No runtime dependencies.
- `website/.gitignore`: `dist/`, `artifacts/`, `node_modules/`.
- `website/package-lock.json`: present.

### `scripts/build.mjs` (node built-ins only)

- Reads `mix.exs` and takes `@version` for the version pill and sitemap.
- Env vars: `SCRYPATH_SITE_URL` (default `https://sztheory.github.io/scrypath/`) and `SCRYPATH_REPO_URL` (default `https://github.com/szTheory/scrypath`).
- Hardcoded page list (4 entries) with `input`, `output`, `title`, `description` and `routePath`. Pages with a route path are written as `<dir>/index.html`.
- Base path: no prefix. Links use relative `BASE_PATH` tokens: `./` for the root page, `../` for subpages. Output therefore works from any sub-path.
- Token replacement is plain `{{TOKEN}}` string replacement. Tokens used: `BASE_PATH`, `BUILD_DATE`, `CANONICAL_INSTALL` (`{:scrypath, "~> 0.3"}`), `DESCRIPTION`, `GITHUB_URL`, `PAGE_PATH`, `PAGE_TITLE`, `REPO_URL`, `SITE_URL`, `VERSION`, `CONTENT`.
- Deletes `dist/`, writes four HTML files, copies `src/assets`, and writes `robots.txt` (allow all, sitemap URL) and `sitemap.xml` (four URLs, priority 1.0/0.8/0.7/0.7, monthly).
- No HTML validation, no link check, no minification, no hashing of asset names.
- Note: `src/robots.txt` and `src/sitemap.xml` are present in `src/`. `sitemap.xml` `<loc>` values use `{{SITE_URL}}`, so `SCRYPATH_SITE_URL` controls them.

### `scripts/serve.mjs`

- Static server on `127.0.0.1`, default port 4173, `--port` flag. Node `http` only.
- Maps `/` to `index.html` and trailing-slash paths to `index.html` within them.
- MIME table covers css, html, js, json, svg, txt and xml. No `.woff2`, `.png` or `.ico` entries (falls back to `application/octet-stream`).
- Serves at the server root. It does not emulate the `/scrypath/` Pages prefix.
- Path-traversal guard via `path.normalize` and `startsWith(distDir)`.

### `scripts/check.mjs` (the only browser check)

- Removes and recreates `artifacts/`. Starts `serve.mjs --port 4173`, waits for the URL in stdout, launches Chromium through Playwright.
- Captures five full-page screenshots with `colorScheme: 'dark'`: home at 1440 wide and 390 wide mobile, `/docs/` and `/operators/` and `/evaluate/` at 1440 wide. Viewport heights are fixed (1800, 1900, 1500, 1600, 1500).
- Each capture waits for the first `h1` and asserts that its text equals a hardcoded heading string. Those strings are: "Search indexing that feels native to Ecto.", "Find the guide for your next step.", "Recovery, verification, and drift should be boring.", "Should I use Scrypath?".
- Assertions: h1 text only. There are no assertions for layout, overflow, links, contrast, fonts, console errors, or the `<title>` and meta tags.
- Note: the check runs against the `dist/` built by `npm run build`. It does not confirm that the build is current, but CI always builds first.

### `.github/workflows/website.yml`

- Name: `Website`. Permissions: `contents: read` at the top level.
- Triggers:
  - `pull_request`: no paths filter, so the job runs on every PR.
  - `push` to `main` with paths `website/**`, `README.md`, `guides/**`, `docs/**`, `mix.exs`, `.github/workflows/website.yml`.
- Concurrency: group `website-<workflow>-<ref>`, cancel in progress.
- Job `build-and-check` (ubuntu-24.04, all actions pinned to commit SHAs): checkout with `fetch-depth: 0`; setup-node 22 with npm cache keyed on `website/package-lock.json`; `npm ci`; `npm run build`; `npx playwright install --with-deps chromium`; `npm run check`; upload `website/artifacts` as `scrypath-website-screenshots` with `if: always()`.
- Job `deploy`: `if: github.event_name == 'push'`, `needs: build-and-check`, permissions `pages: write` and `id-token: write`. Runs build again, then `actions/configure-pages`, `actions/upload-pages-artifact` (path `website/dist`), `actions/deploy-pages`.
- Env in both jobs: `SCRYPATH_SITE_URL: https://sztheory.github.io/scrypath/` and `SCRYPATH_REPO_URL: https://github.com/szTheory/scrypath`.
- No preview deploys for PRs. The Pages environment is `main` only.
- Deploy rebuilds from source; it does not reuse the artifact from `build-and-check`.

### Hosting

- GitHub Pages at `https://sztheory.github.io/scrypath/` (per the env vars). Output is `website/dist`.

### Checks summary

- `npm run check` (screenshots and h1 text only, CI job `build-and-check`).
- Repo ExUnit contract tests that read the site (section 4).
- No link checker, HTML validator, accessibility scan, Lighthouse, visual regression or contrast check.

## 4. Coupling to the rest of the repo

### References to the site or its URLs (outside `website/`)

- `README.md:12`: "Public website: [sztheory.github.io/scrypath](https://sztheory.github.io/scrypath/)".
- `CONTRIBUTING.md:217`: ledger row "Public website/docs truth alignment" runs `mix verify.phase112` and names `README`, `website/`, `guides/scope-and-reopen-policy.md`, and public truth-copy updates as triggers.
- `docs/jtbd-gap-map.md:41`: "Public website launch surface".
- `mix.exs`: `@source_url "https://github.com/szTheory/scrypath"` for `homepage_url` and `source_url`. HexDocs extras and groups list the guides. `mix.exs` does not reference the Pages site. `mix.exs` has the alias `"verify.phase112": :test` (line 78).
- `.github/workflows/website.yml`: the site's own workflow.
- `.dockerignore:13-14`: excludes `website/node_modules`, `website/.next`, `website/out`.
- `examples/scrypath_ecommerce/retired-identity-allowlist.json:4-5`: allowlists `website/src/assets/brand-mark.svg` and `website/src/assets/og-image.svg` for a retired-identity scan (tag `p189`, max 2 hits each).
- `scripts/ci/ui_literal_policy.cjs:952`: matches the `sztheory/scrypath` repo name (GITHUB_REPOSITORY check). Not a site reference.
- `dev/mix/tasks/brand/update.ex:27`: `@source_url` points at `https://sztheory.github.io/scrypath-brand/scrypath-brand.zip` (brand pin download). Separate from the website.
- `brand/brand.pin.json:4`: same brand zip URL.
- `brand/BRAND.md` and `brand/brand.json` name "website" as a surface (see section 6).
- `docs/` and `guides/`: the site links into `guides/*.md` by blob URL on `main`. Those guides are not in the site source, so renaming or moving a guide breaks site links. No automated check covers this.
- Not found: `guides/` or `CONTRIBUTING.md` links to the Pages URL. `README.md` is the only file that links the Pages URL.

### Repo tests that read website content (ExUnit)

All are under `test/`.

- `test/scrypath/phase112_contract_test.exs`: reads `website/src/layout.html` and `website/src/pages/{index,docs,evaluate,operators}.html`, plus several guides and docs. Asserts:
  - Website route-map tokens: `{{REPO_URL}}/blob/main/README.md`, `examples/phoenix_meilisearch/README.md`, `examples/scrypath_ecommerce/README.md`, a `{{REPO_URL}}/blob/main/guides/` link in `docs.html`, and the Hex and HexDocs URLs and `{{REPO_URL}}` in the layout.
  - Absence of misleading-claim phrases on every surface (for example "AI-powered", "AI search", "vector search", "hybrid search", "automatic callbacks", "always current", "immediately searchable", "public multi-backend support"). The evaluate page must keep two explicit negation sentences.
  - Absence of runbook tokens on the website pages: `docker compose up -d`, `mix deps.get`, `SCRYPATH_MEILISEARCH_URL`, `mix test`.
  - The canonical claim line and reopen-trigger phrases in the surface set (I did not confirm which list that assertion iterates).
- `test/scrypath/phase110_contract_test.exs`: reads `website/src/pages/docs.html` and `operators.html`. Asserts that they link `guides/support-and-compatibility.md` and `guides/outside-adopter-intake.md` (operators page), and that they do not contain the compatibility tuple literals listed in the test (the Elixir/OTP pairs as backtick strings).
- `test/mix/tasks/workflow_wiring_test.exs`: reads `.github/workflows/website.yml`. Asserts Node 22, `cache-dependency-path: website/package-lock.json`, the `pull_request` and `push` triggers, the push paths list, `contents: read` top-level permissions, Pages permissions, action SHA pins with version comments, and the `upload-artifact` pin. Changing the workflow's action pins, triggers, or the push path list will fail this test.
- `test/mix/tasks/verify.phase112_test.exs`: checks the phase112 task source strings (task description text).
- `test/release/package_metadata_test.exs`: checks that `website` is not in the Hex package files, and that README header images are commit-pinned raw URLs (not `github.io`).
- `test/mix/tasks/brand_pin_contract_test.exs`: mentions `website` in brand pin context.

### Which tests fail if page text changes

- Changing `index.html`, `docs.html`, `evaluate.html`, `operators.html` or `layout.html` text is caught only when the change touches one of the phrases above:
  - Removing or renaming any `{{REPO_URL}}/blob/main/...` or Hex/HexDocs link named above fails phase112.
  - Adding a banned phrase (section above) or a runbook token (`docker compose up -d`, `mix deps.get`, `SCRYPATH_MEILISEARCH_URL`, `mix test`) to any website page fails phase112.
  - Changing the Elixir/OTP tuple literals on `docs.html` or `operators.html`, or removing the support-guide and intake-guide links from `operators.html`, fails phase110.
  - Free-form copy changes, including all headings, hero text, card copy, and the evaluate page's sentences other than the two pinned negations, do not fail any test.
- The `npm run check` h1 strings in `scripts/check.mjs` must match the h1 text exactly, or the website CI job fails. A new headline requires editing `check.mjs` as well.
- Changing the page title or description strings in `build.mjs` fails nothing.

## 5. Impeccable skill (`~/.claude/skills/impeccable`)

- `SKILL.md`: version 4.10.0, Apache 2.0. Frontmatter description: "Use to design, redesign, critique, audit, polish or animate a frontend: websites, landing pages, dashboards, app UI, components, native iOS/Android screens, or a design system (DESIGN.md)."
- `reference/`: 48 entries. Markdown playbooks for each command: `adapt(.native)`, `android`, `animate`, `audit(.native)`, `bolder`, `clarify`, `colorize`, `component-review`, `craft`, `craft-floor`, `critique` and `critique-rubric`, `degraded/` (asset-producer, documenter, finish-reviewer, manual-edit-applier, motion-reviewer), `delight`, `distill`, `doctor`, `document`, `extract`, `foundations`, `generate`, `harden`, `hooks`, `init`, `ios`, `layout`, `live` and `live-setup`, `mode-operate`, `mode-persuade`, `mode-read`, `new-work` (with `-world` and `-comp` parts), `onboard`, `operate`, `optimize`, `overdrive`, `polish`, `quieter`, `region-map`, `routing`, `shape`, `typeset`, `visualize`.
- `scripts/`: `impeccable` (launcher, shell) and `impeccable.cmd` (Windows), `VERSION`, `command-metadata.json`, `engine-checksums.txt`, `data/` (font-index.json and font-index-failures.json), and browser helpers (`live-browser.js` 567 KB, `live-browser-dom.js`, `live-browser-ignores.js`, `live-browser-session.js`, `modern-screenshot.umd.js`). The skill says the launcher is a self-contained binary that ships with the skill or is downloaded once on first run. I did not run it.
- Modes (from SKILL.md): Persuade (landing pages, marketing; the visitor decides and acts), Operate (app UI, dashboards, admin), Read (docs, articles, guides, help, changelogs), Experience (portfolios and galleries). SKILL.md states that a docs index is Read, not Persuade, and that a tool's landing page is Persuade.
- Commands (from SKILL.md table): craft (deprecated), shape, init (alias teach), document, extract, critique, audit, polish, bolder, quieter, distill, harden, onboard, animate, colorize, typeset, layout, delight, overdrive, clarify, adapt, optimize, live, generate. Pin/unpin, hooks, doctor and foundations are subcommands.
- Setup: run `scripts/impeccable context` once per session. It loads PRODUCT.md and DESIGN.md, the surface brief, and native guidance. Its output and directives are followed.
- Rules that affect a redesign (from SKILL.md): a redesign "replaces" the look, and refinement "preserves" it; for a redesign, the old look is evidence and anti-reference; factual copy is not replaced without asking.

### Root PRODUCT.md and DESIGN.md

- `PRODUCT.md` exists at the repo root (6,732 bytes, modified 2026-11-19). Sections: Product, Platform, Users, Audience and jobs, Product Purpose, Positioning, Operating Context, Capabilities and Constraints, Brand Commitments, Evidence on Hand, Product Principles. It covers the library and its audiences, not a visual system. It is referenced by `test/release/package_metadata_test.exs` (the retired-brand-name check).
- `DESIGN.md` exists at the repo root (10,736 bytes, modified 2026-11-19). Its title is "Design System: Scrypath Operator UI", with sections Overview, Colors, Typography, Layout, Elevation & Depth, Shapes, Components, Do's and Don'ts, and Follow-up interaction contracts. It covers the ScrypathOps operator UI, not the public website. It does not describe `website/`.
- Not checked: whether an Impeccable sidecar file exists next to DESIGN.md. I only listed the two root files.

## 6. Brand book assets (`brand/`)

- `brand/BRAND.md` (71.8 KB, the brand book; it names the pages it covers, and "Applications: the website" is the site section).
- `brand/brand.json` (74 KB), `brand/tokens.json` (18.8 KB, design tokens; not inspected in detail), `brand/brand.pin.json` (17.7 KB; SHA-256 pins for brand files, source URL `https://sztheory.github.io/scrypath-brand/scrypath-brand.zip`).
- `brand/assets/README.md`: "which file to use" guide, version 1.0, November 14, 2026.
- `brand/assets/logo/`: `scrypath-lockup-{light,dark,one-color-ink,one-color-pale-ink}.svg` (about 5.8 KB each), `scrypath-symbol-{light,dark,one-color-ink,one-color-pale-ink}.svg` (about 1.1 KB each). The README also lists `-2048.png` lockups, which are not in the directory listing I ran.
- `brand/assets/icon/`: `favicon.svg`, `favicon.ico`, `favicon-{light,dark}.svg`, `favicon-{16,32}-{light,dark,mono}.svg`, `favicon-{16,32,48}` PNG variants (`-light`, `-dark`, `-mono` as available), `favicon-16/32-mono` PNGs.
- `brand/assets/avatar/`: `scrypath-avatar-{light,dark}.svg` (512 px square). The README also lists 512 PNGs.
- `brand/assets/readme/`: `scrypath-header-{light,dark}.svg` and `header-snippet.html`.
- `brand/assets/social/scrypath-social-card-1280x640.png` (29.6 KB, PNG). This is the brand social card. The website uses its own SVG `og-image.svg` instead.
- `brand/assets/docs/scrypath-exdoc.css`: ExDoc styling.
- Fonts: not in `brand/`. The three self-hosted WOFF2 faces and their OFL licences are in `scrypath_ops/priv/static/assets/fonts/`: `display.woff2` (Bricolage Grotesque), `ui.woff2` (Hanken Grotesk), `mono.woff2` (Sometype Mono), with `OFL-*.txt` files. The website uses none of them.

### Website section of BRAND.md (quoted)

From `brand/BRAND.md`, "Applications: the website":

> The website's first screen. A drawing of the proposed layout with sample data, not a screenshot of the product.
>
> ### Headline and button
>
> The headline is the tagline. The one Plum button, "Read the golden path", opens the README's first guide.
>
> ### Show the command
>
> The picture shows a Mix command and the output it prints, instead of a generic illustration.
>
> ### No version badge here
>
> The version belongs in the README and on Hex, where the version is published with the package, so the page has no badge that can go out of date.

Related lines in `BRAND.md`:
- Line 123: "Where: README, Hex page, HexDocs, website, social card" (under "Scrypath's own pages use the full brand").
- Line 794: "Docs and website follow the same rule, and the favicon follows the device's light or dark setting." (under "light, dark and system").
- Line 1094: "The tagline comes from the website's headline."

Differences to note, factual only:
- The brief's button label "Read the golden path" differs from the built site's "Read the docs". The site's hero currently has no sample command output; its code panel shows a `use Scrypath` schema and a `sync_record` call.
- The brief says the favicon follows device light or dark, but the built site is dark-only and `layout.html` links one favicon (`brand-mark.svg`, violet fill). It also sets `theme-color` to `#0b0f15`.

## Files referenced

- `website/src/pages/{index,docs,evaluate,operators}.html`
- `website/src/layout.html`, `website/src/assets/{styles.css,brand-mark.svg,og-image.svg,diagram.svg}`, `website/src/{robots.txt,sitemap.xml}`
- `website/scripts/{build,serve,check}.mjs`, `website/package.json`, `website/.gitignore`
- `.github/workflows/website.yml`
- `test/scrypath/phase112_contract_test.exs`, `test/scrypath/phase110_contract_test.exs`, `test/mix/tasks/workflow_wiring_test.exs`, `test/mix/tasks/verify.phase112_test.exs`, `test/release/package_metadata_test.exs`
- `README.md`, `CONTRIBUTING.md`, `mix.exs`, `PRODUCT.md`, `DESIGN.md`
- `brand/BRAND.md`, `brand/brand.json`, `brand/brand.pin.json`, `brand/tokens.json`, `brand/assets/`
- `~/.claude/skills/impeccable/SKILL.md`, `~/.claude/skills/impeccable/reference/`, `~/.claude/skills/impeccable/scripts/`
