# Website refresh 02: benchmarks and patterns

Date: 2026-11-20. Scope: how admired library/DB-tooling sites present themselves, and what a one-maintainer Elixir OSS site should copy or avoid.

## Method and confidence (read first)

- Pages were fetched with WebFetch, which converts HTML to text and has a small model answer a prompt. I did NOT render the pages in a browser. Everything about colour, layout, typography and motion is **inferred from markup/asset names or unverified**. Copy quotes and structural facts (nav items, sections, presence of code) are the reliable part.
- Marketing pages change weekly; observations are a 2026-11-20 snapshot. Some counters (Meilisearch "0" stats, Drizzle benchmark "NaN") may be JS-hydration artefacts of the fetch rather than real bugs. I flag them as "as captured".
- Not verified: actual Lighthouse scores of any site; GitHub star counts beyond what the pages themselves print; whether any pattern measurably increases stars (no primary evidence found; treat star advice as hypothesis).
- Prior context file `01-*` did not exist in the directory when I wrote this.

## Site-by-site notes

For each: first screen / proof / nav / trust-honesty / stars / style / what it does wrong.

### 1. Oban Pro (https://oban.pro) - Elixir
- First screen: "Process Billions of Background Jobs Without Losing Sleep." CTA "Upgrade to Oban Pro in Minutes."
- Proof: tabbed Elixir/Python code (`Workflow`, `@job`), adopter logos (PepsiCo, Apple, Supabase, Fly.io), named testimonials, "92% fewer queries" chart.
- Nav: Features, Dashboard, Pricing, Articles, Releases, Docs (dropdown), Sign In.
- Trust: playful tone, pairing-session support, status link in footer. ASCII/monospace diagrams (engineer-friendly).
- Wrong: "Billions"/"Thousands" unsourced; CTA assumes you already use Oban; no baseline for the 92% number; a joke section ("Oban AI ... syke!") muddies the claim.
- Takeaway: code tabs + diagrams in monospace are strong; unsourced scale claims and a CTA for existing users only are weak. Note this is a commercial product page, not the OSS library's own landing.

### 2. Ash Framework (https://ash-hq.org) - Elixir
- First screen: "Model your domain, derive the rest." Sub: "the Elixir backend framework for unparalleled productivity." CTAs "Install Now" and **"Run in Livebook"** (zero-install try).
- Proof: 10-step code/output/mock-UI carousel (below fold), ~16-logo "Trusted in Production" wall, ecosystem grid. No star count shown.
- Nav: Docs, Installer, Ecosystem, Community, Media, Blog, GitHub, Premium Support.
- Wrong: "unparalleled" superlative; best proof is below the fold; install pipes a remote script to a shell (trust friction); some snippets abbreviated and might not run as shown; crowded.
- Takeaway: "Run in Livebook" is a great Elixir-native low-friction CTA. Copy the idea (a runnable notebook), not the superlative.

### 3. Livebook (https://livebook.dev) - Elixir
- First screen: "Automate code & data workflows with interactive notebooks." CTAs "Install Livebook" and **"Star us on GitHub"** (an explicit star ask in the hero).
- Proof: notebook-window mockups (product shown as itself), integration logos, sponsor tiers. No user counts or testimonials.
- Nav: Install, Features, Integrations, Badges, Docs (to HexDocs), What's new.
- Wrong: truncated-looking code in mockups reads as errors; "Not familiar with Elixir?" reassurance arrives near the bottom; generic "supercharges".
- Takeaway: explicit star CTA is normal and unembarrassed in Elixir land; docs delegated to HexDocs is the accepted pattern.

### 4. Phoenix (https://www.phoenixframework.org) - Elixir
- First screen: "Peace of mind from prototype to production." Sub: "Build rich, interactive web applications quickly, with less code and fewer moving parts." Banner: "most loved web framework" linked to the Stack Overflow survey.
- Proof: real LiveView code sample as hero visual, install command `mix archive.install hex phx_new` on screen, company logos, creator testimonial.
- Nav: Docs, Community, Source, Blog (four items).
- Wrong: headline abstract (subhead does the work); no comparison with alternatives; "millions of WebSocket connections" uncited.
- Takeaway: the only superlative that works is the one tied to a linked primary source; four-item nav; code + install command in hero.

### 5. Req / Broadway (https://req.hexdocs.pm/readme.html, https://elixir-broadway.org) - Elixir
- Req README: one-line tagline ("batteries-included HTTP client"), a two-line working example before any explanation, linked feature list, `Mix.install` snippet. Warm informal tone. Does not have a limits section. Fetch showed the snippet pinned an older version than the documented one (stale-version footgun, worth checking directly).
- Broadway site: wordmark + one-sentence description, named adopters linked to independent case-study write-ups (Change.org, V7, Community, Sparkmeter, Veeps), runnable example repo, integration list. No code snippet, benchmark or install on the homepage; "Check our repo" CTA is vague; book CTA mixes commercial into OSS.
- Takeaway: Req shows the "two-line example first" ideal; Broadway shows that third-party-authored case studies are the Elixir-community way to do adopters, but leaving out code is a missed opportunity.

### 6. Meilisearch (https://www.meilisearch.com) - search engine, direct dependency of Scrypath
- First screen: "One platform to build, scale, and unify search and AI retrieval." Live movie search demo beside it ("8 results in 1ms"). Nav includes a GitHub star count (59.9k as captured).
- Proof: typo-tolerance JS snippet, "sub-50ms" claims, CarbonGraph migration case study, SOC 2 / GDPR badges, trust centre + status page.
- Wrong: broad "platform" language; "sub-50ms" repeated with no methodology; snippet uses an undefined `index`; stat counters showed "0" as captured; logos missing as captured.
- Takeaway: live demo above the fold works; broad platform copy is exactly what Scrypath should NOT imitate (Scrypath is a library, not a platform). Do not make claims about Meilisearch itself beyond its docs.

### 7. Typesense (https://typesense.org) - search engine
- First screen: "Lightning Fast, Open Source Search." Sub: "...search engine for mere mortals. Knowledge of rocket science optional." Live recipe search demo; CTAs "Quick Start" and "Typesense Cloud".
- Proof: "25M Docker pulls / 25K stars / 10B searches" (vanity-ish, but specific), large logo row, live showcase demos at scale (32M songs, 28M books), **comparison table vs Algolia/Elasticsearch/Meilisearch** introduced as "no spin, just the raw data ... based on each engine's documentation", with a footnote admitting a gap.
- Wrong: "blazing/absurdly fast" with no numbers on the page; humour before clarity; template-key leaks ("usecase.title" alt text, empty "in ...ms"), typos; pricing buried in footer.
- Takeaway: a comparison page with admitted gaps is the strongest honesty device found. Bugs in a polish-claiming page (typos, untranslated keys) cost credibility, which matters double for a portfolio site.

### 8. Drizzle ORM (https://orm.drizzle.team) - TypeScript DB tooling
- First screen: "ORM for you to settle" (struck-through) / "ship ship ship"; "Get Started" + "Documentation"; star badge "35k+" in nav; release banner for v1.0.0-beta.2. Tagline "Headless TypeScript ORM with a head" only in the footer.
- Proof: dialect row, sponsor logos, dated changelog + a v1.0 progress bar, a **testimonial wall that includes critics** ("Drizzle is terrible. It doesn't even support Mongo."), named team with photos, a Benchmarks page.
- Wrong: unclear hero value; benchmark section showed "0.0ms / xNaN" as captured (possibly JS-only); snake game and whimsy distract; very long docs nav.
- Takeaway: showing criticism and the real team builds trust; the personality only works because the value prop is clear elsewhere. A "headless ORM with a head" line buried in the footer is a cautionary tale: put the plain sentence first.

### 9. Prisma (https://www.prisma.io) - TypeScript DB tooling
- First screen: "Your TypeScript app, from prompt to production." CTAs "Get started free", "See pricing". Proof: "Trusted by 500,000+ developers", "46,500+ GitHub stars", logo wall, named testimonials, trust centre/SLA/DPA/status.
- Wrong: repeated testimonials; "single-digit ms" with no method; self-authored price comparisons with hidden assumptions; "agent-ready" jargon; inconsistent GA/"coming soon" messaging. The fetch also noted the page embeds instructions aimed at AI agents (I ignored them).
- Takeaway: a venture-backed product page; the shape (compliance links, status) is irrelevant to a solo OSS lib. Useful mainly as a counter-example of vague, multi-product positioning.

### 10. Laravel Scout (https://laravel.com/docs/scout) and Searchkick (https://github.com/ankane/searchkick) - the closest functional analogues
- Scout opens with a plain two-sentence definition ("driver-based solution for adding full-text search to your Eloquent models ... keeps your search indexes in sync"), then **a built-in database engine that needs no external service** and the statement "For most applications, this is all you need", then drivers (Algolia, Meilisearch, Typesense, Turbopuffer). A Queueing section says to "strongly consider" a queue driver and states that Meilisearch/Algolia index asynchronously, so the engine may not reflect writes immediately.
- Searchkick README: "Intelligent search made easy", one-line setup sample, one CI badge only, explicit version support ("Elasticsearch 8 and 9 and OpenSearch 2 and 3"), a Gotchas section (up to 1s eventual consistency, 10,000-result cap, do not use for small-dataset autocomplete). Section order goes setup, querying, tuning, ops, advanced. "Battle-tested at Instacart" is self-reported.
- Takeaway: these are what Scrypath's "sync honesty" should look like. Eventual consistency stated in docs, not hidden. Both are docs/README-first; neither has a marketing site.

### 11. htmx (https://htmx.org)
- First screen: "high power tools for HTML", a quick-start code snippet in the hero (`hx-post`/`hx-swap`) and plain-text size claim (~16k min.gz, dependency-free), link to a 67% code-reduction essay.
- Honesty: states "htmx 2.x has dropped IE support", explains 4.0 is not tagged `latest` so users are not upgraded by accident. Stars/sponsors: GitHub star link in header, sponsor tiers.
- Wrong: retro parody ads and merch add clutter; motivation is rhetorical, not balanced; 1.x/2.x/4.0 split confusing for newcomers.
- Takeaway: very low production values, strong voice, essays as the persuasion surface; version/support policy stated openly.

### 12. Tailwind CSS (https://tailwindcss.com)
- First screen: "Rapidly build modern websites without ever leaving your HTML." One CTA "Get started", global search (Cmd+K), version badge in nav (v4.3 as captured).
- Proof: **code beside rendered result for every feature**, sponsor wall, showcase logos (OpenAI, Shopify...), unsourced "<10kB" claim, unlabeled "6.4x / 4.2x / 2.7x" metrics.
- Wrong: sponsor/showcase logo links reportedly have empty alt/text (accessibility failure on a flagship site); never addresses the obvious objection (verbose markup); duplicated nav/footer DOM.
- Takeaway: code/result pairing is the single best proof format for a library page.

### 13. Astro Starlight (https://starlight.astro.build)
- First screen: "Make your docs shine with Starlight"; "Get started" + "View on GitHub"; search, theme selector (Dark/Light/Auto), ~20 languages. Dark, space-themed hero.
- Wrong: claims "fast, accessible" with no audit linked; no code sample or docs preview on the landing page; generic marketing language; logo wall without context.
- Takeaway: the Auto/Light/Dark selector and built-in search are table stakes; Starlight (or plain static HTML) is a viable chassis only for the docs side. Scrypath docs already live on HexDocs.

### 14. Sidekiq (https://sidekiq.org)
- First screen: "Simple, efficient background jobs for Ruby." Sub: "up to 20x faster than the competition!" (no benchmark, no named competitor). CTAs Get Started / Learn more / Buy.
- Proof: named, attributed testimonials with concrete outcomes ("half a billion jobs"), logo wall, OSS vs Pro vs Enterprise comparison table with prices, money-back guarantee, status page.
- Wrong: no code on the homepage; the 20x claim; OSS support listed as "None" with no community channel.
- Takeaway: radical plainness and a transparent what-is-free table; but the hero claim is the weakest line on the page.

## Cross-site tally (from the above)

| Element | Seen working | Seen failing |
|---|---|---|
| Code in/near hero | Phoenix, htmx, Tailwind, Req, Oban Pro | Broadway, Sidekiq, Starlight, Ash (below fold) |
| Live/zero-install try | Typesense demo, Meilisearch demo, Ash "Run in Livebook" | none |
| Install snippet visible | Phoenix, Req, htmx | most others |
| Explicit limits/compat statement | Searchkick, Scout, htmx, Typesense footnote | almost every marketing page |
| Comparison with alternatives | Typesense table, Scout driver list | Phoenix, Starlight, Tailwind none |
| Unsourced perf claims | - | Oban Pro, Meilisearch, Typesense, Prisma, Sidekiq, Tailwind |
| Placeholder/unrendered values | - | Drizzle, Meilisearch (as captured), Typesense |
| Star ask | Livebook (hero CTA), Drizzle/Meilisearch/Prisma (count in nav/proof), htmx (header link) | - |

## Synthesis

### 1. Patterns that consistently work for a library landing page
1. **Above the fold: one plain sentence + real code + install.** Name the category and the audience in the first sentence ("X for Y"), then show the smallest working snippet (Phoenix, Req, htmx, Tailwind). Cute taglines (Drizzle, Typesense) only work when a plain sentence sits next to them, and Drizzle's plain line was in the footer.
2. **Code-first proof.** Pair code with its result (Tailwind), or show real, runnable code (Req's two lines). Snippets must be copy-pasteable and version-pinned; Ash, Meilisearch and Livebook all showed code that looked broken or undefined.
3. **Install snippet with a pinned version, copy button.** `{:scrypath, "~> x.y"}` generated from the real version at build time so it cannot go stale (Req's stale pin is the footgun).
4. **"How it works" as a small diagram in text/monospace or SVG.** Oban Pro's ASCII diagrams, Broadway's pipeline. For Scrypath: schema -> change -> sync mode (inline / Oban / manual) -> Meilisearch -> search, with the eventual-consistency gap drawn, not hidden.
5. **Honest limits section.** Searchkick "Gotchas" and Scout's queueing note are the model: eventual consistency, delete semantics, what is not supported, compatibility matrix (Elixir/OTP/Ecto/Meilisearch versions).
6. **Comparison / when-not-to-use.** Typesense's "raw data, from each engine's documentation, with footnoted gaps" is the strongest single trust device seen. Scout's "for most applications the database engine is all you need" is the gold standard of when-not-to-use. Link the facts to sources.
7. **Social proof without fake numbers.** Use what is checkable: version badge, Hex downloads (live badge), CI badge, last release date, changelog, license, test/coverage links, named adopters only with their permission and a link to their write-up (Broadway's model), and quotes with names. Drizzle's inclusion of a critic is a bonus. Empty is better than invented.
8. **Short nav (4-5 items) that leaves the site fast:** Docs (HexDocs), Guides, Changelog, GitHub, Hex. Phoenix and Broadway do exactly this.
9. **Light/Dark/Auto theme** respecting `prefers-color-scheme` (Starlight, Drizzle).

### 2. Anti-patterns and AI-slop tells
- Generic gradient/orb hero with no code (the "giant hero, no code" problem; Starlight and Sidekiq show no code).
- Feature-card grids of vague nouns ("Orchestration", "Flexibility", "Robust", "Concurrency and Batching") with no concrete outcome. Oban Pro and Broadway both hit this.
- Stock/abstract illustrations; emoji as section icons; "blazing fast / unparalleled / supercharge / absurdly" without numbers (Ash, Typesense, Livebook).
- Vanity counters and logo walls without context ("thousands of organisations", unrendered "0"/"NaN" values). Do not ship placeholders: Drizzle, Meilisearch and Typesense showed broken values/keys in the capture.
- Dark-only designs; contrast failures; logo links with empty alt text (Tailwind's sponsor wall).
- Benchmark claims with no baseline, workload or script (Oban Pro 92%, Sidekiq 20x, Prisma "single-digit ms"). If Scrypath cites a number it must link the reproducible script (the repo has a `bench/` dir to draw on; I did not inspect it).
- Pretending to be a platform (Meilisearch's "unify search and AI retrieval"); a library should say what it does not do.
- Testimonials repeated across sections; a CTA aimed only at existing users; humour that delays the explanation.
- Fabricated or simulated social proof of any kind (the project constraint says no overclaiming).

### 3. What a one-maintainer project can sustain
- **Static site, no CMS, no database.** Every admired Elixir site delegates depth to HexDocs (Livebook "Docs" -> HexDocs; Req README on HexDocs). Keep the site to: landing, quickstart pointer, "how it works", honest limits, compatibility, comparison, changelog link.
- **Generate, do not hand-maintain, anything that rots:** version number, install snippet, compatibility matrix, Hex/CI badges, and the code sample, ideally extracted from a test or example that runs in CI (verify-the-sample; the repo already has an ecommerce example and Docker lanes, which I did not inspect). A sample that is executed cannot drift.
- Content that stays true longer: essays/ADR-style pages (htmx's essays model) beat feature news; one comparison page updated per minor release.
- Sustainable proof cadence: changelog from release-please (already used), a "last verified" date next to the compatibility table.
- GitHub Pages limits (https://docs.github.com/en/pages/getting-started-with-github-pages/github-pages-limits): 1 GB site, ~100 GB/month soft bandwidth, 10 builds/hour soft limit (not applied to custom Actions deploys), and a prohibition on hosting commercial transactions sites. Fine for an OSS lib site. Docs did not say whether custom HTTP headers are supported (in practice Pages does not let you set them; treat as not available, unverified here), so use meta tags and avoid relying on CSP headers.
- Star ask: low-key, explicit ("Star us on GitHub" in Livebook's hero), GitHub link in nav, one star prompt after the quickstart. I found no primary evidence on conversion rates; treat the "what earns stars" mechanics as unverified. What earns stars is a README/landing that answers "what, why me, how fast to try" quickly, plus a runnable example.

### 4. Accessibility, performance, SEO, social cards (static Pages site)
- **Accessibility (WCAG 2.2 AA):** text contrast 4.5:1 (large 3:1), non-text/UI 3:1 (SC 1.4.3, 1.4.11, confirmed from the W3C quickref). Also needed, though body text was truncated in my fetch so verify exact wording: visible focus (2.4.7), minimum target size (2.5.8), skip link (2.4.1). Meaningful `alt` on every logo link (Tailwind failed this), semantic headings, code blocks keyboard-scrollable, respect `prefers-reduced-motion`. Already in repo: a WCAG AA contrast gate for ops UI (per project memory); reuse the same token pair tests for the site.
- **Performance (Core Web Vitals "good" at p75, https://web.dev/articles/vitals):** LCP <= 2.5 s, INP <= 200 ms, CLS <= 0.1. A static page with self-hosted subset woff2 (the repo's brandbook already ships subset woff2), no third-party scripts, explicit image dimensions, and no hero image should clear this trivially. Lighthouse CI can gate this (https://developer.chrome.com/docs/lighthouse/overview mentions Lighthouse CI; thresholds/weights not covered by that page, so unverified).
- **No-JS:** the whole page, including the code sample and install snippet, must read without JS. Copy buttons, theme toggle and any live demo are progressive enhancement only; theme should default to `prefers-color-scheme` via CSS.
- **SEO:** unique `<title>` and meta description, one `<h1>`, canonical URL, `lang`, robots.txt. Google says a sitemap is often unnecessary for a small, well-linked site (<~500 pages) but is harmless and most sites benefit (https://developers.google.com/search/docs/crawling-indexing/sitemaps/overview); a generated sitemap.xml is cheap. Add `SoftwareSourceCode`/`SoftwareApplication` JSON-LD only if cheap (unverified benefit).
- **Social cards:** Open Graph requires `og:title`, `og:type`, `og:image`, `og:url`; add `og:image:alt` whenever an image is set (https://ogp.me). Image dimensions are not specified by ogp.me; GitHub's repo social preview recommends 1280x640 (min 640x320), PNG/JPG/GIF under 1 MB, solid background preferred over transparency (https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/customizing-your-repositorys-social-media-preview). Use one 1200x630-ish card (confirm the ratio against Twitter/X and Slack docs, which I did not fetch) and also upload the same art as the GitHub repo social preview, since the repo link is what most people share. Add `twitter:card=summary_large_image`.
- Current site state: `/Users/jon/projects/scrypath/website` has `src`, `dist`, `scripts`, `package.json`; I did not audit it for these items (my grep for `index.html` at the site root found nothing, since the build output layout differs).

## Recommendations for Scrypath (3-5)

1. **Hero = one plain sentence + one runnable snippet + `mix deps` line, all above the fold, no hero image.** Example shape: "Ecto-native search sync for Phoenix: keep Meilisearch indexes in step with your schemas." Show the schema macro plus one `Scrypath.search/…` call (use the real API from the repo) next to the pinned dependency line. Generate version and snippet from a file that CI executes, so it cannot rot. Secondary CTAs: Docs (HexDocs) and GitHub. Optionally a "Run in Livebook" link (Ash's idea), if feasible without adding scope.
2. **"How sync really works" section as an SVG/text diagram, followed by an "Honest limits" block** (the Searchkick/Scout pattern): inline vs Oban vs manual, eventual consistency, delete semantics, reindex/backfill, supported versions matrix with a "verified on <date>". This section is Scrypath's actual differentiator and matches the project's "operational clarity" constraint.
3. **A "When not to use Scrypath" + comparison page**, Typesense-style: facts linked to each tool's documentation, with a footnote for every place Scrypath loses (e.g. Postgres full-text is enough for many apps, Scout-style drivers do not exist here, Meilisearch-only in v1). Include Elixir alternatives only if verified; I did not research the Elixir search-library landscape in this pass.
4. **Social proof limited to checkable facts**: live Hex version/downloads badge, CI badge, license, changelog, "used by" only with named permission or a linked write-up, and nothing placeholder-shaped. For the portfolio angle, make the engineering visible instead of claimed: a link to the runnable example, the verify/CI pages, ARCHITECTURE and the benchmark script (only if it is reproducible). Ask for stars once, plainly, after the quickstart plus a GitHub link in the nav (Livebook model).
5. **Technical floor as a CI gate, not a promise:** light + dark + auto theme, no-JS complete, self-hosted subset fonts, token contrast tests reused from the ops UI, Lighthouse CI thresholds, OG/Twitter meta + `og:image:alt`, a 1200x630 card and the same image as the GitHub social preview, sitemap.xml and robots.txt, and a link checker. Keep the site to roughly 5 pages and delegate all reference docs to HexDocs.

## Sources (all fetched 2026-11-20)
- https://oban.pro
- https://ash-hq.org
- https://livebook.dev
- https://www.phoenixframework.org
- https://req.hexdocs.pm/readme.html
- https://elixir-broadway.org
- https://www.meilisearch.com
- https://typesense.org
- https://orm.drizzle.team
- https://www.prisma.io
- https://laravel.com/docs/scout
- https://github.com/ankane/searchkick
- https://htmx.org
- https://tailwindcss.com
- https://starlight.astro.build
- https://sidekiq.org
- https://docs.github.com/en/pages/getting-started-with-github-pages/github-pages-limits
- https://ogp.me
- https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/customizing-your-repositorys-social-media-preview
- https://web.dev/articles/vitals
- https://developer.chrome.com/docs/lighthouse/overview
- https://developers.google.com/search/docs/crawling-indexing/sitemaps/overview
- https://www.w3.org/WAI/WCAG22/quickref/
