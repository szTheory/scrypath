# UI quality engine: recommendations (2026-10-25)

Synthesis of [OWNER-INTENT](OWNER-INTENT.md) and four research passes: [INVENTORY](INVENTORY.md), [storybook and composition](RESEARCH-STORYBOOK-COMPOSITION.md), [profiles, fixtures and copy](RESEARCH-PERSONAS-FIXTURES-COPY.md), and [automation and CI](RESEARCH-AUTOMATION-CI.md). Each research file has its own sources and adversarial pass; this file records the decisions. Every claim below was measured at `8ebeb740` unless marked as an estimate.

**Goal:** machines check UI quality continuously, so the maintainer's review time goes on taste.

## Decisions

### D1. Adopt phoenix_storybook in `scrypath_ops`, dev/test only, with our own thin gates on top

*Maintainer decision, 2026-10-25. It reverses the research pass's hand-rolled recommendation; see [the storybook research](RESEARCH-STORYBOOK-COMPOSITION.md) for the original argument.*

- **Install:** `{:phoenix_storybook, "~> 1.5", only: [:dev, :test]}` in `scrypath_ops` only. The storybook is served from the ops dev router, so the demo host doesn't need a second install.
  - `scrypath_ops` isn't a Hex package (`mix.exs:268`), so adopters never see these dependencies.
  - They are `makeup_eex`, `makeup_html` and `mdex`, a precompiled Rust NIF. They're accepted because the browsable tree, docs, playground and search are the review surface the maintainer wants. That's a dependency we truly need, not a convenience.
- **Theme fidelity:**
  - Use `themes_strategies: [data_attribute: "theme"]` with light and dark themes. Ops dark CSS is keyed on `[data-theme="dark"] …` descendant selectors and `@custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *))`. That works on any ancestor, and so do daisyUI themes, so the sandbox container drives the real theme.
  - The one exception is System mode, which is keyed on `html:not([data-theme="light"])` with `prefers-color-scheme`. Page and section stories therefore use `container: :iframe`, which is also needed for real viewport widths. The browser sweep pins the colour scheme for explicit-theme runs.
- **One stylesheet source:** `css_path` serves a `storybook.css` that only `@import`s `app.css` and adds `@source` for the story files. `js_path` registers the same hooks as `app.js`, which the host-hook registration lesson in memory requires.
- **Our own gates:**
  - an ExUnit test renders every story variation;
  - every variation has a situation description (persona + `JOB-*`);
  - every exported `OpsUi` component has a story;
  - no two variations render identically (automatic pruning);
  - a committed manifest of iframe URLs, with a staleness check, feeds the L2 sweep.
- **Tree:** fractal, named with the UI's own nouns: primitives → groups → areas → sections → pages per job.
- **Supply-chain care:** pin the version in `mix.lock`. Dependabot and the existing `deep-quality` dependency audit cover it. Its 2026 CVEs are fixed in 1.5.0, and it only ever runs on a developer machine or in CI.
- **Fallback:** if a fidelity gap that the iframe can't solve shows up, fall back to the hand-rolled harness in the research doc. `E2EUIFixtureLive` is the precedent.

### D2. Composable LiveViews: area components over pure view-models

- The LiveView keeps the process concerns: `mount`, params, events, async work, Repo and `Scrypath.*` calls.
- Presentational function components ("areas", 3–6 per section) take plain data through declared `attr`.
- Wherever a screen branches on a state machine, a view-model struct with a closed `state` enum is built by one pure function.
- Stories get their states by passing fixture domain data through **the same builder**. A state the builder can't produce can't be storied, which enforces "only real states" mechanically.
- No Repo or `Scrypath` mocks in stories.

**Extraction order** (by job weight against difficulty):
1. Search health (pilot: it already has a view-model and a fixture seam)
2. Control room (warm-up, alongside the pilot)
3. Search (highest traffic)
4. Failed sync work
5. Sync and index (hardest: 62 `:if`s and 5 async loads, so it needs a state-machine struct)
6. Help (a single static story)

**Pixel parity:** an extraction must not change rendered pixels. Screenshots before and after, at fixed states, prove it. That keeps extraction work out of the "visible UI change" approval gate.

### D3. Personas on both sides, plus one shared fixture project

*Maintainer decision, 2026-10-25: real personas are wanted. This supersedes the 2026-10-14 "don't invent personas" line in `OPERATOR-UI-QUALITY.md`.*

- **Operator personas:** the people who open the UI, for example the paged on-call engineer, the solo self-hoster, the platform/SRE owner and the support-triggered checker. Each one maps onto the existing `ROLE-*`/`JOB-*` ids, which stay as the stable references. The persona set is settled in the v1.46 discuss phase.
- **Adopter personas** (digital twins of the products whose data is indexed) are the five below.

The five profiles are:
- **Wikily:** a brand-new, empty install with inline sync.
- **Chatly:** a multi-tenant chat product with Oban sync, retries, failed deletes and emoji.
- **Langalern:** language learning with Japanese, Chinese, Korean and right-to-left text, settings drift and index promotion.
- **Budgetly:** self-hosted personal finance with manual sync and Meilisearch task failures.
- **Shoply:** the existing e-commerce demo, scaled to a power-user, 41M-document, 6-schema install.

Each profile owns at least one state no other profile covers. A profile that owns no live story at a pruning pass is deleted.

**The fixture project:**
- **Location:** a new `fixtures/scrypath_fixtures` Mix project. It is a path dependency, `only: [:dev, :test]`, and depends on nothing but `scrypath`.
- **Consumers:** stories, ExUnit and demo seeds all read it.
- **Format:** it emits real external shapes (Meilisearch tasks, Oban jobs) into the real normalisation code.
- **Invariant tests (12):** closed enums, legal transitions, timestamp ordering, tenant ids, and realistic id formats.
- **Content rules:** no lorem ipsum, no PII, and no Faker. Deterministic data is copied in rather than generated by a dependency.
- **What it replaces:** the two drifting `Phase173FixtureSource` copies (73 lines differ) and the `:phase173_fixture` branches in the production `PostureLive`.
- **Packaging:** `mix verify.package` gains a must-not-contain check for `fixtures/`.

### D4. One design language, checked statically (L1)

- **Colours:** reset Tailwind's default colour namespace (`--color-*: initial`, re-declaring `--color-black`/`--color-white` for daisyUI). Today no template uses a default-palette colour. Spacing and text defaults are *not* reset, because that would churn about 250 classes; L2's computed-style check covers them instead.
- **Static ban:** ban hex values, arbitrary values, inline `style=` and `z-` literals outside the token files, with a ratchet baseline that may only shrink. Today it would hold about 23 template rows plus 3 CSS rows.
- **Generator leftover:** delete the generator-default `home.html.heex`. That alone clears 12 of the 23 template rows.
- **Contrast:** promote the existing sub-second `contrast-checker.mjs` from the nightly advisory lane into the required `repository-contracts` job, and add focus-ring pairs.
- **Tokens:** make `brandbook/tokens/tokens.json` real DTCG with an `ops` light/dark group that mirrors `app.css`, plus an ExUnit drift test. This fixes the brandbook's false "mirrored" claim.
- **Copy:** one `copy_rules.json` (a denylist, verb-first buttons, sentence case, no "Oops" or "!", errors say what happened and what to do) drives an ExUnit render lint over every fixture state and the text that `ui-review.mjs` already captures. The baseline starts with today's 7 findings, including a raw "Something went wrong!" error, raw `inspect` output in flashes and Control Room, and one empty state worded four ways.
- **Glossary:** rows are appended to the existing language map in `OPERATOR-UI-QUALITY.md`, never a second glossary, and only for demonstrated leaks.

### D5. A generic browser sweep over the manifest (L2)

- **Matrix:** one Playwright spec runs the manifest × widths {320, 375, 768, 1280, 1440} × {light, dark}, plus reduced motion.
- **Assertions:**
  - no console errors;
  - no page-level horizontal overflow;
  - axe with WCAG 2.2 AA tags, where new "incomplete" results fail;
  - 24px targets, via axe `target-size`;
  - no clipped text at 200% font size;
  - font size, font family and z-index come from the built token set. Radius, shadow and duration are advisory until their baseline is empty.
  - focus stays visible at 3:1 on a tab walk;
  - the navigation's ARIA snapshot is identical on every page;
  - the copy lint passes on rendered text and accessible names.
- **Runtime:**
  - Stories are DB-free, so the sweep needs no Docker on PRs.
  - A PR runs one default variation per story, plus the full matrix for changed or shared code, in 4 shards within about 5 minutes (estimate; re-budget after 20 stories).
  - The full matrix runs nightly.
  - The job starts advisory and becomes required after 14 clean nights.
- **Helpers:** reuse the ones in `e2e/helpers/`.
- **Mounted coverage:** a short list of mounted-host routes stays in the nightly run, and `ecommerce-mounted` stays on PRs. This catches story/app divergence, such as host CSS and the `app.js` hooks the host must register.

### D6. Screenshots, an agent-run judge, and a decisions log (L3–L5)

- **L3:**
  - About 30 element screenshots, taken in the pinned Playwright container, with one Linux baseline.
  - Stability: fonts loaded, animations off, fixed pixel density, timestamps masked.
  - Runs nightly first, then gets promoted.
  - Retires `light-pixel-diff.mjs` and the hashless `admin-light-baseline.json`.
  - A changed baseline needs a recorded maintainer acceptance. It is never auto-updated to clear a failure.
- **L4:**
  - **Delete the paid OpenAI path in `ops-ui-visual-judge.mjs`.** It breaks a locked rule (quoted under Conflicts), and its mock mode writes an assumed pass.
  - Replace it with a bounded, agent-run rubric skill built on `impeccable`, used on demand and never as a CI gate. It gives binary verdicts with evidence and compares a PR head against main pairwise, in both orders, keeping only verdicts that agree.
  - It never reports what L1–L3 already check.
  - It is calibrated on owner-labelled examples: the 63 resolved items in `UI-FEEDBACK.md` and past owner-directed fix commits. Rubric items that keep failing calibration are demoted.
- **L5:**
  - `ui-decisions.jsonl` records each decision as a fingerprint, a verdict and a reason. A rejection suppresses future reports.
  - A test fails when the same kind of decision has been made twice without being promoted into an L1/L2 rule or a calibration example.
  - It folds in the existing `.impeccable` detector ignore.

### D7. The review rubric, by owner

| # | Rubric item | Primary owner | Machine floor |
|---|---|---|---|
| 1 | Light and dark both good, not tacky | maintainer | contrast matrix, colours from tokens, system-dark invariants |
| 2 | Typography intentional | judge | type scale and family from tokens; no px-locked text |
| 3 | Hierarchy elegant | judge | heading order, one `h1` |
| 4 | Nothing redundant | judge | repeated text-block and duplicate-control detector (advisory) |
| 5 | Each job's happy path great, power users served | maintainer | journey e2e proves function only |
| 6 | Microcopy consistent and in voice | machine (rules), judge (voice) | `copy_rules.json` lint |
| 7 | Profiles and jobs curated | maintainer | manifest lint: each variation cites a profile and a `JOB-*` |
| 8 | Coherent journey, natural navigation | judge | navigation snapshot identity; mounted journey |
| 9 | Mobile first at 320, comfortable targets | machine | overflow, targets and 200% zoom at 320 and 375 |
| 10 | Least surprise, one pattern per job | judge | census of raw button and table markup outside the primitives (advisory) |

Machine checks set floors; they never certify taste. Taste items go to the maintainer as triaged findings plus key screenshots, never as an open-ended UAT round.

## Grilling decisions (maintainer, 2026-10-25)

All of these were settled in a `/grill-with-docs` session. The terms are in the root [`GLOSSARY.md`](../../../GLOSSARY.md); the hard-to-reverse choices are [ADR 0001](../../../docs/adr/0001-phoenix-storybook-for-scrypath-ops.md) (phoenix_storybook) and [ADR 0002](../../../docs/adr/0002-shared-fixtures-mix-project.md) (the shared fixtures project).

**Order:** v1.44 sync → v1.45 foundation and CI (plus the engine's prerequisites) → v1.46 engine and pilot → v1.47 surfaces and polish → v1.48 adopter features.

**Language:**
- One root `GLOSSARY.md` is the canonical domain language. The copy lint is built from it.
- **Operator persona** and **adopter twin** are the only persona terms. A bare "persona" must say which kind it means.
- Docs use the rendered surface names: Control room, Search health, Failed sync work, Sync and index, Search (with Saved searches), Help.
- The story levels are **Primitive → Pattern → Area → Surface → Job**.

**Operator personas:** four role handles, each mapped to the `ROLE-*` ids:

| Handle | Role | Device |
|---|---|---|
| Solo Dev | `ROLE-INT` | laptop |
| On-call | `ROLE-OPS` | phone, paged |
| Platform SRE | `ROLE-OPS` + `ROLE-OWNER` | desktop, keyboard-first |
| Search Owner | `ROLE-OWNER` | desktop |

A fifth persona is added only if it brings a distinct device, skill or trigger that the stories need.

**Adopter twins:** obvious domain names; trademark collisions don't matter for demos.
- **Wikily:** a brand-new, empty wiki install with inline sync.
- **Chatly:** multi-tenant team chat with Oban retries, failed deletes and emoji.
- **Langalern:** language learning with Japanese, Chinese, Korean and right-to-left text, settings drift and promotion.
- **Budgetly:** self-hosted personal finance with manual sync, Meilisearch task failures and privacy-sensitive data.
- **Shoply:** the e-commerce demo at power-user scale. This is a fixture label only; the `scrypath_ecommerce` app keeps its name.

Each twin names its one or two paired operator personas. Every story variation cites a twin, a persona and a `JOB-*`, for example "Chatly · On-call · JOB-03 · retry burst". A twin that owns no live state is deleted at the per-milestone pruning pass.

**Scope:**
- **Locale:** the ScrypathOps interface stays English and left-to-right. Only adopter data is multi-script, rendered with `dir="auto"`.
- **Realism:** only what changes the rendered UI or breaks layout. That's about 80 hand-written lines per twin, and volumes are labels, not generated rows.

**Mechanics:**
- **Fixtures:** in `fixtures/scrypath_fixtures`, per ADR 0002. Personas and twins are defined once in code, and a generated `PERSONAS.md` index is drift-checked against it.
- **Serving:** the storybook runs from the standalone `scrypath_ops` dev server at `/storybook`, with its own Compose service and port lane next to the retained preview.
- **Gates:** the story ExUnit gates block merges from the first story PR. The Playwright sweep stays advisory until 14 clean nights.
- **Approvals:** extraction work stays pixel-identical. Copy and design fixes are batched for one maintainer yes per milestone, shown as before/after storybook links.

## Conflicts with recorded owner decisions

1. **Personas.** `OPERATOR-UI-QUALITY.md:9` says: *"Treat roles as task contexts that may overlap, not fictional demographic personas."* Line 19 adds: *"Do not invent new personas or duplicate the job table."* **Superseded by the maintainer on 2026-10-25:** personas are wanted on both sides (D3). That file now carries a dated note.
   - **Resolution:** the two don't actually collide. Operator humans stay `ROLE-*`/`JOB-*`, and on-call, solo self-hoster and SRE become situations within those roles, not new ids. The adopter side becomes fixture data profiles, which is what the indexed data is about. Update line 19 with a dated note pointing here.
2. **Paid judge.** `OPERATOR-UI-QUALITY.md:99` says: *"No paid visual-judge API calls, new AI service, or recurring model gate by default."* `ops-ui-visual-judge.mjs:191` calls `api.openai.com`.
   - **Resolution:** delete that path (D6).
3. **Storybook vs. dependency rule.** The owner's standing rule is "copy-paste over a dep", but it allows a dependency when one is truly needed. **The maintainer decided on 2026-10-25** that phoenix_storybook qualifies (D1). Its dependencies are dev/test only, in a package that isn't published.
4. **Approved rolling roadmap.** v1.45 plans to run the standalone `phase173_*` specs. D3 retires the `phase173` fixture mode.
   - **Resolution:** keep v1.45's cheap fix, one compose `-f` flag, so the nightly lane goes green; L2 depends on that. The UI-engine milestone then ports those specs onto stories and deletes the mode.

## Antipatterns to refuse

- Prop-permutation stories. Cover equivalence classes instead.
- Stories of states the builder can't produce.
- Mocking Repo or `Scrypath` in stories.
- A second inventory (gallery page, component catalogue) living alongside the stories.
- Personas kept for flavour. An adopter persona that owns no live story state gets deleted at the pruning pass.
- Lorem ipsum, real PII, Faker.
- Resetting Tailwind spacing or text defaults wholesale.
- Counting a passing retry as green.
- Auto-updating a pixel baseline.
- A paid judge, a judge as a CI gate, or an agent approving its own findings in the decisions log.
- 1–10 design scores.
- Claiming a visual or UX pass that no tool or human actually performed.

## Build order

1. **Prerequisites** (fit inside the approved v1.45): nightly lane green; the L1 ratchet and colour reset; contrast promoted to required; `home.html.heex` deleted; the OpenAI judge path deleted; the token DTCG group plus drift test. None of this changes visible UI.
2. **Engine and pilot** (new milestone A):
   - the fixtures project with its invariants;
   - phoenix_storybook (dev/test) with the data-attribute theme strategy, iframe page stories, and our gates and manifest;
   - primitive and group stories for `OpsUi`;
   - the Search health pilot extraction plus Control room;
   - the L2 sweep (advisory), the copy lint baseline and the decisions log;
   - porting the `phase173_*` specs onto stories, then deleting the `phase173` fixture mode.
3. **Surfaces and polish** (new milestone B):
   - extract Search, then Failed sync work, then Sync and index, with area, section and page stories for each;
   - L3 baselines and the L4 judge skill with calibration;
   - one rubric review per section.

   The resulting copy and design fixes are batched for the maintainer's yes, because they are visible.
4. **Each milestone closes** with a pruning pass, plus stories-per-component as a sprawl signal.
