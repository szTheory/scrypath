# Website refresh 01: goals, audience, scope

Status: research note for the maintainer, 2026-11-20. Recommendations only; no phase plan, nothing started. Read-only on source; no build was run.

Labels: V = verified by reading a file or querying GitHub this session; J = judgment.

Inputs read: `README.md`, `mix.exs` (docs/package), `guides/overview.md`, `guides/golden-path.md`, `guides/jtbd-and-user-flows.md`, `website/src/{layout.html,pages/*.html,assets/*}`, `website/scripts/{build,check}.mjs`, `brand/BRAND.md`, `brand/brand.json`, `PRODUCT.md`, `DESIGN.md`, `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md` (SITE-01..05), `.planning/research/v1.47-prep/B-website-reskin.md`, `prompts/elixir-search-lib-deep-research.md`, the website-related contract tests, and the stale screenshot `website/artifacts/home-desktop.png` (dated Jun 1, shows v0.3.8, so it is not the current build).

## 0. Summary

- Phase 189 (already planned) fixes the identity only: tokens, fonts, lockups, light default, picker, guards. It deliberately leaves headline, CTA, command picture, version badge and all copy alone (REQUIREMENTS.md "Out of Scope", row "Website content changes beyond identity"). A refresh that is only a re-skin will still read as "a dark landing page with a link farm". The missing half is a content and information-architecture decision. That is what this note scopes.
- The site today has no job it can finish. It has four pages that each hand the visitor to a GitHub `blob/main` markdown file. Nothing on it shows Scrypath working (no Mix output, no Search health screen, no sync-status vocabulary), and it has no logo.
- One honesty defect needs fixing regardless of the refresh: the site tells adopters to run `mix verify.adopter`, a task that is not in the Hex package (section 4).
- The GitHub repo has 0 stars (V: `gh api repos/szTheory/scrypath`). Any star strategy has to work with no social proof and must not fake any (PRODUCT.md: "Do not invent customer, adoption, or performance claims").

## 1. What the current site says and does

Stack (V): no framework, no JS, `build.mjs` replaces `{{TOKEN}}`s in `layout.html` plus four page fragments. Dark-only, system-font stacks, violet/copper palette from the retired identity (`styles.css`: `#9f8cff`, `#e0a06d`, `#0b0f15`). Four pages: home, docs, operators, evaluate. Nav: "Home / Docs / Operations / Evaluate", then a Star button and a `v{{VERSION}}` pill.

### Whole-site problems (apply to every page)

1. **No logo.** Header is a generic mark plus `<strong>Scrypath</strong><small>Ecto-native search indexing</small>` (`layout.html`). The brand book says the logo is the lockup and the tagline is never inside it. Rendering is old-identity, not the plum/orchid book (covered by Phase 189).
2. **Nothing shows the product.** The brand book's imagery rule is "show the path an update takes": Mix task output, a Search health row, the five steps saved, queued, sent, indexed, searchable (`BRAND.md` "Imagery: the path"; "Applications: the website": "Show the command"). The site shows a decorative wave diagram (`diagram.svg`, text unreadably small in the screenshot, badge "Verified locally") and an unhighlighted code block. No terminal output anywhere. ScrypathOps, the thing most likely to make a visitor say "this is a real project", appears only as one passing mention each on `docs` and `operators`, with no image.
3. **"Docs" is a link farm out of the site.** `docs.html` is a list of `{{REPO_URL}}/blob/main/guides/...` links. HexDocs (rendered, versioned, searchable, already branded in v1.46) is linked only from the footer. A visitor who clicks "Docs" lands on raw GitHub markdown, not on the docs product.
4. **Copy fights the brand voice.** Quotes from the source against `BRAND.md` "Voice":
   - `index.html`: "Three personas, one boundary." (internal planning vocabulary as a headline); "left as application folklore"; "stale, wedged, or drifting" (brand term list: say "out-of-date index"; "drift" is allowed in guides); "Choose `:inline`, `:manual`, or `:oban` with eyes open".
   - `evaluate.html`: "a giant callback maze", "Magic callback runtime" (names the thing it disclaims, which is fine in the negation, but the tone is combative); `build.mjs` meta description promises "comparing Scrypath to other search approaches" and the page contains no comparison.
   - `operators.html`: "Recovery, verification, and drift should be boring." (cute, and "verification" points at the repo-only task); "Accepted work is not the same thing as visible search." appears as an `<h2>` and again as the first line of body (duplicated verbatim, `operators.html` lines 11-13); `hydration` appears in "Observe" (brand: "record loading" in screens; allowed in guides, but this is a marketing surface).
   - Brand words "queued", "searchable" (the key terms table) are not used. The site says "accepted work" and "search visibility". `Scrypath.sync_record/3` returns `:accepted`; the brand book says to write "queued" in prose.
5. **Redundant pages.** Home has a four-card "What ships today", a personas band, and a four-row "Where to go next" list that repeats the nav. `operators` "Sync modes" tiles repeat `index.html`'s "Sync modes" tile, which links to it. `evaluate` "Scope and reopen" ("reopen triggers") is maintainer process (scope-guard authority) leaking onto a public evaluation page; a prospective adopter does not need the reopen policy before deciding to try a library. It also appears in `docs.html` ("Scope and reopen policy" in the First-hour section) and `operators.html` callout.
6. **Version and install facts are hand-maintained in markup.** `index.html` hard-codes "Elixir 1.17+, OTP 26-28" and `build.mjs` hard-codes `{:scrypath, "~> 0.3"}`. Both also live in `README.md`, `guides/golden-path.md` and `AGENTS.md`. The version pill reads `mix.exs` (V), so it is correct, but the brand book says the website has no version badge because it can go stale.
7. **Visual defects in the screenshot (stale, so treat as indicative):** the status-strip cells clip their content ("{:scrypath, "~> 0.3"}" and "Elixir 1.17+, OTP 26-2" cut off); the hero panel's diagram text is unreadable; all section headings are the same weight and the same three-box rhythm, so nothing is the focal point after the hero; cards are used for everything (brand: "No cards or charts" applies to the Search health application, but the same restraint applies to marketing).
8. **Social card is an SVG** (`og-image.svg`), which most crawlers do not render, so shared links show no image (covered by Phase 189 via the pinned PNG).
9. **Zero-stars call to action is a button, not a reason.** "Star" sits in the header; the page gives no reason, no evidence of activity (releases, CI, changelog), no roadmap, no "what's next".
10. **No SEO or discoverability surface**: no page on "how Scrypath compares to Searchkick/Scout-style libraries" (the research prompt names Searchkick, Laravel Scout, meilisearch-rails as the benchmark and finds no dominant Elixir equivalent as of 2026-04; `prompts/elixir-search-lib-deep-research.md` lines 5-15), no mention of "Meilisearch Elixir" / "Ecto full-text search" in a page a person could land on.

### Page by page

| Page | What it says | What it does | Weakness |
|---|---|---|---|
| Home `index.html` | Hero: tagline h1 (matches brand tagline), a lede that starts with the old "Scrypath, the Ecto-native search indexing library, helps ..." claim sentence (needed by the README contract test), 3 buttons (Read the docs, See operator support, View on GitHub), 3-cell status strip, schema+search+sync code block, four cards, personas band, link list, install callout. | Routes to docs / operators / GitHub. | Three equal-weight buttons (brand: one Plum button, "Read the golden path"); install snippet clipped; code block mixes `use Scrypath` + a context function + `sync_record` out of order and shows no output or result shape; no proof of operation. |
| Docs `docs.html` | "Find the guide for your next step." | Link list to GitHub blobs, three tiles, example apps. | Duplicates `guides/overview.md` (which is already a map with a recommended reading order and ships in HexDocs). Sends people off-site to raw markdown. Tenant-safety section is a full section for one feature of ~25 guides. |
| Operators `operators.html` | "Recovery, verification, and drift should be boring." | Sync-mode tiles, a 4-step first-response list, SRE tiles, callout. | Names `mix verify.adopter` as first response (repo-only task). Contains no real output, no screenshot of ScrypathOps. Duplicates `docs/operator-support.md`, `guides/operator-mix-tasks.md`, `guides/drift-recovery.md`, `guides/sync-modes-and-visibility.md`. |
| Evaluate `evaluate.html` | "Should I use Scrypath?" | Fit / not-a-fit / tradeoffs / scope-and-reopen / decision rule. | Strongest honest content on the site, but it never says what Scrypath is compared to (Searchkick-style libraries; Postgres FTS; hand-rolled Oban job + Meilisearch client; hosted search), and no table. "Magic callback runtime" vs README "When It Does Not" is duplicated text. |

## 2. Goals, audience, one job per page

### Primary goal (proposed)

**A Phoenix/Ecto developer who lands from Hex, GitHub, a post or a search can say in 30 seconds what Scrypath is and is not, see it working, and reach the first real step (golden path) in one click.**

Everything else follows from that. Stars, trust and portfolio value are outcomes of a site that is clear, honest, specific and well made, not separate features.

### Ranked secondary goals

1. **Build trust through exactness.** Show real output and name the guarantees honestly (queued vs searchable; `:accepted`). Trust for a 0-star project comes from: a visible release cadence (CHANGELOG, Hex version), CI badge/green main, a runnable example, a stated scope policy, a stated support matrix. None of that requires testimonials, which do not exist.
2. **Route to the right depth without duplicating it.** The site is the front door, HexDocs is the manual, GitHub is the code and the issues.
3. **Earn stars honestly.** One star ask, placed after the visitor has seen the product (footer / end of page / evaluate page), with a reason ("follow releases"). No fake counters. J: a live star count badge would read 0; do not embed it until it is not embarrassing; link to the repo instead.
4. **Portfolio piece.** The site is the maintainer's design-and-engineering showpiece. What helps: a polished, fast, accessible, correctly themed static site; product drawings in the brand's own system (progress line, slanted bar, status words); both themes verified; a short "how this site is built and checked" line linking to the contract tests is a credibility signal for engineers. What does not help: effects, gradients, stock illustration (brand imagery "never" list).
5. **Contributor funnel.** A small "Contribute / report an integration issue / roadmap" path (CONTRIBUTING.md, outside-adopter intake). Lowest priority; keep it as a footer column.

### Audience segments and what each needs

| Segment | Arrives wanting | Needs from the site | Does not need |
|---|---|---|---|
| A. Phoenix/Ecto dev evaluating search (primary) | "Is this the Ecto way to add Meilisearch search, and is it real?" | Headline, a 6-line schema declaration, the output of a real status command, honest fit/not-fit, Meilisearch-first statement, license, current version, link to the golden path | Operations depth, reopen policy |
| B. Adopter in the first hour | Install, config, first `Scrypath.search/3` | One click into the golden path (HexDocs), the sync-mode decision in three lines, known gotchas ("common mistakes") | A second copy of the golden path on the site |
| C. Operator / SRE (co-primary per PROJECT.md) | "What do I run when search is stale; will this tell me?" | The four Mix tasks with sample output, a drawing of Search health (labelled sample data per the brand rule), links to drift-recovery and operator guides, who owns Meilisearch (host team, today) | Library onboarding |
| D. Contributor / star-giver | "Is this alive and credible enough to follow?" | Release history, CI status, roadmap posture ("Meilisearch-first; scope reopens only on evidence"), CONTRIBUTING, intake | Marketing copy |
| E. Portfolio viewer (hiring manager, peer, conference organizer) | "Does this person ship polished, rigorous work?" | Visual craft, accessibility, speed, a clear story, evidence of rigor (verification, contrast checks, pinned brand) | Product detail beyond one screen |

Note on the existing "three personas" band: it names App developer / Operator / Evaluator. PRODUCT.md says personas live in `OPERATOR-UI-QUALITY.md` and "do not duplicate persona or glossary tables here". The site should route by question ("I'm evaluating", "I'm installing", "search is wrong"), not display a persona table.

### One job per page (proposed)

| Page | One job | Primary action |
|---|---|---|
| Home | Say what Scrypath is, show it working, send the visitor to the next step. | "Read the golden path" (the brand's single Plum button; the brand book already specifies it) |
| Evaluate (or "Is it for you?") | Let a skeptical dev decide fit in two minutes, including a plain comparison with the alternatives. | Go to golden path, or leave with confidence |
| Operate | Show that keeping search healthy is a first-class job: the four Mix tasks, sample output, ScrypathOps, who owns what. | Open the operator guide on HexDocs |
| Docs | Not a page of its own if possible: a nav item that goes to HexDocs. If a landing is kept, it is a 6-link map, not a mirror of `guides/overview.md`. | HexDocs |
| (Optional) Roadmap / releases | Show that the project is alive and what it will not do. | Star / Watch releases |

J: collapse to three authored pages (Home, Evaluate, Operate) plus nav links out to HexDocs and GitHub. Fewer pages means fewer duplicated claims to keep true.

## 3. Scope: website vs HexDocs vs README vs ScrypathOps docs

### Single-source-of-truth rule

**Each claim has one owner. Every other surface either links to the owner or quotes the owner's canonical sentence, never restates it in its own words.**

Owners already declared in the repo:

| Claim | Owner (V) | Other surfaces may |
|---|---|---|
| Support floor, supported Elixir/OTP tuples, install snippet, readiness | `guides/support-and-compatibility.md` ("single current support and readiness authority", asserted by `phase110_contract_test.exs`) | link; the website currently states "Elixir 1.17+, OTP 26-28" and `~> 0.3` itself |
| Sync-mode return contract and "queued is not searchable" | `guides/sync-modes-and-visibility.md` | state the one-sentence summary and link |
| Scope, non-goals, reopen triggers | `guides/scope-and-reopen-policy.md` | the README and website say only "Meilisearch-first v1; scope reopens on evidence" and link |
| Brand names, voice, key terms | `brand/BRAND.md` + `brand.json`, pinned by `mix verify.brand` | follow, do not paraphrase |
| Version | `mix.exs` `@version` | `build.mjs` already reads it |
| Operator UI behavior and vocabulary | `DESIGN.md`, `PRODUCT.md`, `.planning/reference/OPERATOR-UI-QUALITY.md`, `scrypath_ops/README.md` | show a drawing; do not describe screens in prose that can drift |

### Scope table

| Content | Website | HexDocs (ExDoc from `mix.exs` extras) | README | ScrypathOps docs (`scrypath_ops/README.md`, in-app Help, `docs/operator-support.md`) |
|---|---|---|---|---|
| What Scrypath is, tagline, positioning, fit / not fit | Own it (home + evaluate) in brand voice | README is the first HexDocs page | Short form; link to site | no |
| Install snippet | Show it (copy of canonical) with link to support guide | Own (golden path, support guide) | Own (short) | no |
| First-hour tutorial | Link only, never copy | Own (`golden-path.md`, `getting-started.md`) | Link | no |
| Sync modes | One sentence + a five-step drawing (saved, queued, sent, indexed, searchable) | Own | One paragraph (exists) | Link |
| Backfill, reindex, drift | One paragraph + the four Mix tasks as output | Own (`drift-recovery.md`, `operator-mix-tasks.md`) | Own short sections (exist; consider trimming) | Link |
| Phoenix/LiveView/faceted/multi-index guides | Link to HexDocs group "Phoenix" | Own | Link | no |
| Meilisearch operations, SRE | One line + link | Own (`meilisearch-operations.md`, `docs/search-backend-sre.md`) | Link | no |
| ScrypathOps (what it is) | Show (a brand-conformant drawing, labelled sample data; real screenshots only if a captured, current one exists) and link | Not in Hex package; mention only | Link (exists) | Own (setup, mounting, screens) |
| Support matrix, scope policy, intake | Link only (contract tests already require this; see below) | Own | Link | Link |
| Release notes | Link to CHANGELOG and releases | CHANGELOG in HexDocs | Link | no |
| Contributing, CI, release flow | Footer link | Own (`CONTRIBUTING.md`, `docs/releasing.md`) | Link | no |
| API reference | Never | Own (ExDoc) | no | no |
| Brand usage, logo, voice | Follow; do not host a brand page unless the maintainer wants one | no | Header only | no |

Website pages stay "route-map summaries" (the existing contract wording in `phase112_contract_test.exs`).

### Interaction with the existing doc contract tests (V)

Tests read the website source files directly:

- `test/scrypath/phase112_contract_test.exs` reads `layout.html` and all four `pages/*.html`. It asserts: `docs.html` contains `{{REPO_URL}}/blob/main/README.md`, the two example READMEs, and `{{REPO_URL}}/blob/main/guides/`; `layout.html` contains the Hex URL, the HexDocs URL and `{{REPO_URL}}`; **`evaluate.html`** contains two exact sentences ("If you want hidden hooks that imply search is always current, the library is deliberately" and "v1 targets Meilisearch first and keeps the adapter seam internal."); misleading-claim regexes (`always current`, `immediately searchable`, `ai search`, `vector search`, `public multi-backend support`, etc.) fail on all surfaces including the website; no website page may contain runbook tokens (`docker compose up -d`, `mix deps.get`, `SCRYPATH_MEILISEARCH_URL`, `mix test`).
- `test/scrypath/phase110_contract_test.exs` asserts `docs.html` and `operators.html` contain `guides/support-and-compatibility.md` and `guides/outside-adopter-intake.md`, and that website pages do not contain the support-tuple literals `1.17.3`, `26.2.5`, `1.19.0`, `28.1`.
- `test/mix/tasks/workflow_wiring_test.exs` pins the website workflow (Node 22, `fetch-depth: 0`, Pages permissions, action SHAs). A workflow edit must keep those or update the test in the same change.
- `test/release/package_metadata_test.exs` asserts `website` is not in the Hex package files.
- `ui-tokens.test.mjs` retired-value deny-list covers `website/src` (via `git ls-files`); SITE-03 extends it.

What this means for a refresh:
1. The refresh is not free to rename, merge or delete `docs.html`, `operators.html`, `evaluate.html`, or to remove the specific sentences above. Collapsing to three pages means editing these tests in the same commit. That is a small, mechanical edit, but it must be planned. It should be a deliberate move of the assertions to the new owners (for example, the "Meilisearch-first" and "always current" sentences move with `evaluate.html`), not deletion of the assertions.
2. The tests are string-presence tests on source files, so a refresh that moves to generated or data-driven copy (for example reading canonical sentences from a shared file) would stop them from seeing the text. Either keep the literals in the page fragments or update the tests to read the built `dist/` output.
3. The runbook-token rule is compatible with "show the command": `mix scrypath.status MyApp.Blog.Post` is fine; `mix deps.get`, `mix test`, `docker compose up -d` are not. The install snippet shows `{:scrypath, "~> 0.3"}` only, which the tests allow. Do not show a Docker quickstart on the site.
4. The `{{REPO_URL}}/blob/main/...` literal assertions bind the docs page to GitHub blob links. If the maintainer chooses "Docs goes to HexDocs", the assertions for `guides/` and README route need to be re-pointed at `https://hexdocs.pm/scrypath/...`. HexDocs URLs are also version-sensitive (`@release_docs_url` in `mix.exs` is versioned); `https://hexdocs.pm/scrypath/<page>.html` (unversioned) follows latest.
5. Phase 189 (SITE-01..05) is identity-only and is already sized at 3 plans; its tests (`site-contract.test.mjs`, rewritten `check.mjs`) assert the old four-page layout. A content refresh after 189 should not re-open the identity work: build it on 189's tokens, picker, fonts and checks. If the refresh starts first, 189's browser check headings will need retargeting. Recommended order: 189 (identity) merges, then a separate content/IA milestone or phase uses its pipeline.
6. A cheap tripwire that does not exist today and would make the single-source rule enforceable: a test that fails if the website source contains an install snippet, version string or support tuple that differs from the canonical owner (build the page from `{{CANONICAL_INSTALL}}`/`{{VERSION}}` tokens only; remove the hard-coded "Elixir 1.17+, OTP 26-28" or generate it from `mix.exs` `elixir:` plus the support guide). This is one small Node check; no new dependency.

## 4. Honesty constraints the copy must respect

From `AGENTS.md`, `PRODUCT.md`, `.planning/PROJECT.md`, `brand/BRAND.md`:

1. **Meilisearch-first.** Public v1 backend is Meilisearch. The adapter seam is internal, not a promised abstraction. Never say "backend-agnostic", "multi-backend", "supports Typesense/Elasticsearch/OpenSearch". Phase 112 test enforces `public multi-backend support`. `evaluate.html` may name this as a non-goal (allowed phrases are whitelisted).
2. **Eventual consistency is explicit.** Say "queued", then "searchable". `Scrypath.sync_record/3` returns `:accepted` for queued work. Never "synced", "real-time", "instant", "always current", "immediately searchable". The brand "Do not say" list: magic, effortless, "it just stays in sync", real-time (unless measured), federated, hydration, playbook, "AI-powered".
3. **Scrypath is a library, not a service.** No "Scrypath Cloud", "platform", "Scrypath.io".
4. **Phoenix is optional**; Ecto is the integration surface. Do not say "Phoenix library".
5. **No invented proof.** No customers, testimonials, adoption numbers, benchmarks, performance claims, "production-proven". PRODUCT.md "Evidence on Hand": in-repo examples and automated verification exist; they are "not independent adopter evidence". The repo has 0 stars; no star count display.
6. **Operators: host owns infrastructure today.** Do not imply Scrypath backs up, restores, scales or provisions Meilisearch. Future automation is a north star, not a claim.
7. **`mix verify.*` is not for adopters.** Since Phase 183 the repo-only `verify.*` tasks (including `mix verify.adopter`) live in `dev/mix/tasks`, compile only under `MIX_ENV=test`, and are not in the Hex package (README "Choose a route"; `.planning/PROJECT.md` "Canonical Adopter Contract"; 0.3.17 still contains them). The website currently says "Verify locally: `mix verify.adopter`" (home status strip, home install callout, operators step 2) and "Run `mix verify.adopter` for a quick verification check". For a visitor who installed from Hex that command does not exist. Replace with the public tasks `mix scrypath.status`, `mix scrypath.failed`, `mix scrypath.retry`, `mix scrypath.reconcile`. This is a truth fix, independent of the refresh; it could ship as a one-line PR first.
8. **ScrypathOps is optional and not in the Hex package.** Say "optional operator UI in the repository", not "ships with Scrypath". Say the maintainer expects most production adopters will want it only if framed as direction, not measured demand.
9. **Brand imagery rules:** product pictures are drawings with sample data and must be captioned as sample data; no screenshots of a UI claimed as real unless captured; show a time zone with every time; one status color at most per diagram; no crystal balls, magnifiers, clouds, neural nodes, rockets.
10. **No version badge on the website** per the brand book, but the current site has one and Phase 189 keeps it. Decide explicitly (open question 3).
11. **No subjective-quality claims on the site about its own review.** AGENTS.md Phase 185 correction: do not infer independent or maintainer aesthetic approval; the portfolio framing can say how the site is checked, not that it was judged good.
12. **Name rules:** "Scrypath" in sentences, `scrypath` for logo/package/commands, `Scrypath` for the module, "ScrypathOps" for the operator UI. Never start a sentence with lowercase `scrypath`, never "scry/path".
13. **Brand tone dial:** guides and README liveliness 1 of 4, talks and social 2. The website is public-facing "Scrypath's own pages" for developers deciding whether to adopt; J: liveliness 1, plain, specific, no jokes ("boring", "folklore").

## 5. Rough shape of the refresh (J, for the next decision, not a plan)

- Home: lockup header; headline = tagline; one-sentence descriptor from the approved one-liner in `BRAND.md` ("Full-text search for Elixir apps, declared on your Ecto schemas, with a way to see when the search index is out of date."); one Plum button "Read the golden path"; a Mix-command-and-output picture (`mix scrypath.status MyApp.Blog.Post`) and a schema declaration with brand code colors; the five-step path drawing (saved, queued, sent, indexed, searchable) with caption "sample data"; three claims (declared on the schema, sync you can see, when a record is searchable) taken from the brand's key messages; the four sync words as a small row; one fit / not-fit teaser linking Evaluate; footer with HexDocs, GitHub, Hex, CHANGELOG, license, star ask.
- Evaluate: keep the honest content; add a plain comparison (hand-rolled Oban + client; Postgres FTS; Searchkick/Scout-style libraries in other ecosystems; hosted search) with only claims that can be sourced; drop reopen-policy to one link.
- Operate: four Mix tasks with sample output, a Search health row drawing, ScrypathOps one-paragraph description with "optional, in the repository", who owns Meilisearch today.
- Nav: Docs (to HexDocs), Evaluate, Operate, GitHub. No separate docs map.

## 6. Open questions only the maintainer can answer

1. **Scope of the refresh.** Is this (a) 189 as planned plus a follow-on content/IA phase (recommended: it keeps 189 at 3 plans and the identity guards intact), (b) one combined phase that does identity and content together (fewer merges, bigger and riskier PR; 189's plans, tests and the CI-ledger row would be rewritten), or (c) content only on the current styles (not recommended: it throws away work 189 would redo)? This changes cost and sequencing.
2. **Does "Docs" leave the site?** Point nav "Docs" at HexDocs and delete `docs.html` (simpler, no duplicated map; requires editing `phase110`/`phase112` assertions and accepting that visitors leave the branded site), or keep a short local docs landing that links into HexDocs?
3. **Version badge.** The brand book says no version badge on the website (it can go stale); 189 explicitly keeps the pill. Keep, or follow the book? (A version pill is a trust cue for a young library and the build reads `mix.exs`, so it cannot go stale on this site; J: keep and note the book deviation.)
4. **Product pictures.** Will the maintainer accept brand-conformant drawings with sample data (matching the book's own approach; no new capture infrastructure), or does the site need real captured ScrypathOps screenshots (needs a captured current UI state and a refresh process that can go stale; the UI is still being reworked in v1.48 and v1.49)?
5. **Third-party comparison content.** Evaluate comparison with named alternatives (Searchkick, Laravel Scout, meilisearch-rails, Postgres FTS, hand-rolled) is the main trust and SEO win, but names other projects and needs sourcing and upkeep. Include, or keep Evaluate to Scrypath's own boundaries?
6. **Portfolio framing.** Should the site carry a visible "how this site is built and verified" note and maintainer byline, or stay product-only? This is a positioning call (the brand book is silent).
7. **Star ask placement and any social-proof element.** Single end-of-page ask only, or also a header Star button (today's header has one)? With 0 stars, should the site omit any star counter until it is not embarrassing (J: yes)?
8. **Budget.** Any page or analytics addition (a custom domain, analytics, search on the site) costs money or a dependency; house preference is none. Confirm: static GitHub Pages, no analytics, no new dependencies.
