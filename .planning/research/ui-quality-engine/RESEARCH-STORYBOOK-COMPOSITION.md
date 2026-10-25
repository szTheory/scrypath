# Research: storybook host and LiveView composition for ScrypathOps

**Date:** 2026-10-25 · **Scope:** the "fractal storybook" and data-driven LiveViews from [OWNER-INTENT.md](OWNER-INTENT.md) and [METHODOLOGY-PROMPT.txt](METHODOLOGY-PROMPT.txt) §1, §2 and L2. Research only; no code was changed.

**Decision:** use a **hand-rolled, zero-dependency story harness** inside `scrypath_ops`, compiled only in dev and test. Do not add `phoenix_storybook`. The reasons are in §6. This supersedes the parenthetical "(phoenix_storybook, …)" in METHODOLOGY-PROMPT §1. That prompt also sets the rule that every new dependency needs a written justification, and phoenix_storybook does not pass it here.

---

## 0. Facts about this repo that drive the decision

| Fact | Evidence | Consequence |
|---|---|---|
| `scrypath_ops` is **repo-internal and not published**. | `scrypath_ops/mix.exs` has no `package:` or `description:` and uses `{:scrypath, path: ".."}`. Root `README.md:36` says the operator UI "is not part of the Hex package". | The rule "storybook must never be a runtime dep of a published package" holds trivially today. It still matters if ops is published later, so keep story code out of any future `files:` list. |
| Versions: Phoenix 1.8.12 (ops) / 1.8.13 (ecommerce), LiveView 1.1.33, phoenix_html 4.3.0, tailwind hex 0.4.1 with CLI 4.1.12, esbuild 0.10.0. | `scrypath_ops/mix.lock`, `examples/scrypath_ecommerce/mix.lock`, `scrypath_ops/config/config.exs:61` | phoenix_storybook 1.5.0 requires `phoenix ~> 1.8.1` and `phoenix_live_view ~> 1.1.21 or ~> 1.2.0`, so it is **compatible**. |
| Ops CSS is one Tailwind v4 build with vendored daisyUI. Dark mode is keyed on **`<html>`**: `@custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *))`, plus `html:not([data-theme="light"])` inside `prefers-color-scheme` blocks. | `scrypath_ops/assets/css/app.css:127, 949-957, 2202+`; the theme script is in `layouts/root.html.heex:25-57` | Stories are only faithful when they render under the **real root layout**, with the real `<html data-theme>` and the real `app.css`. |
| Hosts never build ops assets; `ScrypathOpsWeb.AssetPlug` serves the precompiled CSS and JS. | `scrypath_ops/lib/scrypath_ops_web/plugs/asset_plug.ex`, `router.ex` `forward("/images", …)` | This is the property that means adopters never need Node. A story system must not add a second CSS pipeline. |
| The e2e lane runs the demo host in **MIX_ENV=test**. | `examples/scrypath_ecommerce/Makefile:173`; phase173 routes are `Mix.env() == :test` | Story routes must exist in `:test`, not only in `:dev`. |
| A dependency is compiled in **`:prod`** inside its parent unless the parent says otherwise, and the dependency's `only:` deps and `elixirc_paths(:test)` do not reach the parent. | Mix `deps` docs, `:env` option (defaults to `:prod`): https://hexdocs.pm/mix/Mix.Tasks.Deps.html | Stories and fixtures in `scrypath_ops/test/support` are invisible to `examples/scrypath_ecommerce`. That is why the repo has **two** `Phase173FixtureSource` modules today. |

### Existing precedents (two of them, both worth learning from)

1. **`/ops/phase173` fixture mode, an anti-pattern to retire.** `dev_router.ex:31-45` and `examples/.../router.ex:30-46` mount `PostureLive` with `live_action: :phase173_fixture`. The production LiveView then branches on it (`posture_live.ex:15-43, 82-96, 148, 166-181, 221, 230`). It loads a fixture source module from `Application.fetch_env!(:scrypath_ops, :phase173_fixture_source)`, and that source is written twice, once in `scrypath_ops/test/support/phase173_fixture_source.ex` and once in `examples/scrypath_ecommerce/test/support/phase173_fixture_source.ex`. The result is fixture branches compiled into `lib/` and a duplicated fixture source. Data-driven extraction removes the need for both.
2. **`ScrypathEcommerceWeb.E2EUIFixtureLive` (`/admin/search/ui-fixtures`), a working proto-story.** It is a dev/test LiveView that renders real `OpsUi` and `ResultUi` components from inline fixture assigns, inside the real `Layouts.app` shell, and Playwright asserts against it. This is the hand-rolled approach at size 1. It already proves that rendering from fixtures inside the real shell works under the e2e lane.

---

## 1. phoenix_storybook, checked against primary sources

Source: Hex API, the 1.5.0 tarball (read locally), and GitHub.

- **Version and cadence.** 1.5.0 was released 2026-09-15. 1.0.0 was 2026-03-03, then 1.1 (May), 1.2 (Jun), 1.3 (Jul) and 1.4.0/1.4.1 (Sep): about 7 releases in 7 months. It has 881 stars and 20 open issues, and the last push was 2026-10-05. It is mostly a single maintainer (cblavier, 877 commits, next human 51), so the **bus factor is about 1**. Health is otherwise good: Phoenix 1.8 and Tailwind v4 have been aligned since 1.2, and LiveView 1.2 is supported since 1.3. https://hex.pm/packages/phoenix_storybook · https://github.com/phenixdigital/phoenix_storybook/blob/main/CHANGELOG.md
- **Security history.** The 1.1.0 changelog lists `CVE-2026-8467` (critical), `CVE-2026-8469` (high) and `CVE-2026-47068`. This is real attack surface if the routes ever get compiled into a deployed host.
- **Dependency weight.** Its direct runtime deps are `makeup_eex ~> 2.0.2`, `makeup_html ~> 0.2.0`, `mdex ~> 0.12`, `phoenix` and `phoenix_live_view`, with `jason` and `igniter` optional. Walking Hex, the tree has **22 packages**. **8 are new** to `scrypath_ops/mix.lock`: `makeup`, `makeup_eex`, `makeup_elixir`, `makeup_html`, `nimble_parsec`, `mdex`, `mdex_native` and `rustler_precompiled`. **`mdex_native` is a Rust NIF**: `rustler_precompiled` downloads a platform-specific binary during compile, which needs network access and adds Docker arm64/musl risk. The package itself is about 10.6k lines of Elixir plus 2 MB of `priv` assets (its own Tailwind build and FontAwesome).
- **Install.** `mix igniter.install phoenix_storybook`, or `{:phoenix_storybook, "~> 1.5.0"}` plus `mix phx.gen.storybook`. The docs do **not** show `only: :dev`, so the default is a prod dependency. Dev/test-only use works: declare `only: [:dev, :test]`, guard the backend module and the `live_storybook` router call with `Mix.env()`, and note that `PhoenixStorybook.enabled?/0` reads `config :phoenix_storybook, :enabled` (default `true`). guides/setup.md: https://github.com/phenixdigital/phoenix_storybook/blob/main/guides/setup.md
- **Mounting.** It needs `storybook_assets()` plus `live_storybook "/storybook", backend_module: …`. These generate `/`, `/*story`, `/iframe/*story` (a bare `ComponentIframeLive` that takes `variation_id`, `theme` and `color_mode` params), `/visual_tests` and `/visual_tests/*story` (`router.ex:55-110` in the tarball).
- **Assets and CSS isolation.** Storybook loads **your `css_path` and `js_path` bundles, not `app.css` or `app.js`**. The guide says to create a separate `storybook.css` that "must mirror any `@plugin`, theme, custom variant or font". That means a second Tailwind profile, a watcher, `assets.build` and `assets.deploy` entries, and a `COPY storybook storybook` line in the Dockerfile. Isolation works through the `psb:` prefix and preflight applied only under `.psb`, your CSS loaded in `@layer app`, and a `sandbox_class` on containers. Iframes are optional and not the default. guides/sandboxing.md
- **Story types.** `:component` (`function/0`), `:live_component` (`component/0`, optional `handle_info/2`), `:page` (static render plus tabs) and `:example` (a child LiveView with `mount`, `render` and `handle_event`, **but no `handle_params`**, optional `container: :iframe`). It also has `%Variation{}`, `%VariationGroup{}`, `attributes/0` and `slots/0`, `template/0` with `<.psb-variation/>`, and the `psb-assign` and `psb-toggle` events for faking state. Unknown events hit a catch-all `handle_event(_, _, s)` that does nothing, and an event log shows them. Stories are `.story.exs` files, lazily compiled through `Code.compile_file` in a GenServer. https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Story.html · guides/components.md
- **Programmatic listing.** The backend module exposes `content_tree/0`, `leaves/0`, `flat_list/0` and `load_story/1`, and `story.variations()` returns ids. A manifest needs a small mix task over those. `/visual_tests?start=a&end=e` renders component stories only, not examples or pages. guides/testing.md
- **Footguns that matter here.**
  1. **Dark-mode fidelity.** `color_mode` toggles a *class on the sandbox div*. Ops dark mode depends on `<html data-theme>` and `html:not(...)` selectors (§0), so inline stories would show the wrong theme unless the CSS is rewritten or every story runs in iframe mode with a custom theme strategy.
  2. **CSS drift.** A mirrored `storybook.css` is exactly the "drift from the real app" risk the owner wants to avoid.
  3. **Host reach.** The demo host would need its *own* phoenix_storybook dependency, backend module, router entries and CSS profile (§0, deps compile in `:prod`).
  4. **`.story.exs` files sit outside `mix compile --warnings-as-errors`**, so attr typos surface at render time, not compile time.
  5. **Example stories cannot use `handle_params`**, so URL-driven states (selected schema, tab, query) cannot be storied at page level.
  6. Issue #900 (2026-09-28): no option to disable the Google Fonts download.

---

## 2. Hand-rolled story harness: shape, size, and what it gives up

**Shape.** Everything below lives in `scrypath_ops` and compiles only in dev and test.

- `ScrypathOps.Stories.Story`, a behaviour (about 30 LOC) with callbacks `id/0`, `level/0` (`:primitive | :group | :area | :section | :page`), `section/0` (a nav or job id), `component/0` (a function reference) and `variations/0`. Each variation is a list of maps: `%{id, situation, assigns, slots?, viewport_hint?}`. `situation` is required; it is METHODOLOGY L2's "every variation has a situation description".
- Story modules are ordinary `.ex` files under, say, `scrypath_ops/stories/`, organised by section and job (`stories/search/results_area.ex`). They go through normal compilation, so `--warnings-as-errors` and attr validation run at compile time. They are added through `elixirc_paths(env) when env in [:dev, :test]`.
- One fixture source, `ScrypathOps.Fixtures.*` (the DB-free "digital twin" personas), shared by stories, tests and seeds. Stories call it; the duplicated `Phase173FixtureSource` modules are deleted.
- `ScrypathOpsWeb.StoryLive` (about 150–250 LOC) has three views:
  - `index`, a tree grouped by section and level;
  - `show`, every variation of one story, stacked, each with its `situation` caption;
  - **`bare`**, `/:story/:variation`, which is one variation in the **real root layout and `Layouts.app` shell**, with no harness chrome. This is the Playwright target.

  Behaviour notes:
  - It is a real LiveView, so a story can call `stream/3` or build `AsyncResult.ok/loading/failed` with no fakes.
  - A catch-all `handle_event/3` appends `{event, params}` to an on-page event log of about 15 LOC, which gives the useful part of storybook's event log.
  - A story may optionally define `handle_event/3` as a reducer over its own fixture assigns, for the few interactive states: a sheet open, or a draft that differs from what was submitted.
  - Theme and width toggles reuse the existing `phx:theme` switch and Playwright viewports. No new mechanism is needed.
- Routes: `scope "/ops/__stories"` in `DevRouter`, under `if Mix.env() in [:dev, :test]`, beside today's phase173 block, which it replaces.
- `mix scrypath_ops.stories.manifest` (about 50 LOC) writes `stories.manifest.json` listing `{story_id, level, section, variation_id, situation, path}`. It is committed, and a test fails if it is stale.
- ExUnit gates, about 80 LOC in total:
  - every variation renders through `rendered_to_string/1` (https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html#rendered_to_string/1) with no warnings or raises;
  - every `situation` is non-empty;
  - every public component in `ScrypathOpsWeb.OpsUi.__components__/0` (52 components, 244 `attr` and 43 `slot` declarations today) has at least one story or an explicit, justified exemption;
  - no two variations render identical HTML, which is METHODOLOGY's "looks identical" pruning rule, done mechanically.

**Estimated size:** 450–650 LOC of harness, tests and mix task, with **zero new deps and zero new asset builds**. Story modules then cost about 15–60 LOC each, the same as with phoenix_storybook.

| You give up (vs phoenix_storybook) | Is that cost real here? |
|---|---|
| Playground, editing attrs live in a form | Low. Reviews run off curated situations, not free-form editing, and the owner wants impossible states pruned, not explored. |
| Auto-generated attr/slot docs tab | Medium. `__components__/0` exposes the same metadata, and a roughly 40-LOC docs table can be added later if needed. |
| Source tab and editor links | Low. |
| Search across stories | Low at this scale (about 100–200 variations). `Cmd-F` on the index is enough. |
| Theme dropdown | None. The real `phx:theme` toggle is *more* faithful (§1, footgun 1). |
| Event log | Kept, in about 15 LOC. |
| Igniter generator, community conventions | Low for a single-repo internal UI. |

---

## 3. Where stories live, and how the e2e lane reaches them

- **Recommended: in `scrypath_ops`, served by its standalone `DevRouter` at `/ops/__stories`.** This is where the components, CSS and fixtures already live, and it needs no host changes. The L2 Playwright sweep runs from the existing `examples/scrypath_ecommerce/e2e` toolchain, so the Playwright and axe setup is reused. It points a dedicated project at the standalone ops server through a second base URL, for example `STORIES_BASE_URL`, with the server started by `MIX_ENV=test mix phx.server` in `scrypath_ops`. That gives one Node toolchain, already maintainer-only, and one story host.
- **Mounted-host fidelity** (the shell inside a host layout, under `/admin/search`) stays covered by the **short list of real composed routes** that L2 already calls for. It does not need a second copy of every story.
- **If stories must also render inside the demo host,** do *not* use `test/support`, which is invisible because of the `:prod` dep env. Instead:
  - put the story modules in a directory guarded by `if Application.compile_env(:scrypath_ops, :stories, false) do … end`;
  - expose a `scrypath_ops_story_routes/1` router macro;
  - have the host set `config :scrypath_ops, stories: true` in its `dev.exs` and `test.exs`, and call the macro under `Mix.env() in [:dev, :test]`.

  Mix tracks `compile_env`, so the dependency recompiles when the flag changes. If ops is ever published, exclude that directory from `package files:` and add a parity test, the way the root package already guards `files:`. This is the same mechanism that would replace both phase173 fixture sources with one.
- **Security:** story routes and fixtures are never compiled into prod. A router test asserts that `/ops/__stories` returns 404 under `MIX_ENV=prod` compilation, or that it is absent from the `Phoenix.Router.routes/1` output in a prod build. Fixtures carry no PII (METHODOLOGY §8).

---

## 4. LiveView composition pattern

**Rule:** the LiveView owns **process concerns**: `mount`, `handle_params`, `handle_event`, `handle_info`, `handle_async`, Repo and `Scrypath.*` calls, and PubSub. Presentational **function components** own **markup**. They take plain data through declared `attr` and `slot` and contain no `Repo`, `Scrypath.` or `socket` access.

Reasons:
- LiveView's own guidance is to default to function components and use live components only "when you need the additional state" (https://phoenix-live-view.hexdocs.pm/welcome.html).
- Declared `attr` and `slot` give compile-time warnings and runtime docs (https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#attr/3).

1. **The extraction unit is the "area"**, not the whole page. Split each `render/1` into 3–6 `<.search_results_area …/>`-style section components in a per-section module, for example `ScrypathOpsWeb.Search.Components`. The LiveView's `render/1` becomes about 30–60 lines of composition. Areas compose existing `OpsUi` primitives, which already carry 244 attr declarations.
2. **View-models: plain maps by default, structs where a state machine exists.** Precedent: `ScrypathOps.Posture` is already a struct that `posture_live.ex:184-187` pattern-matches on (`:unconfigured | :missing_backend | rows`). Use a struct with a closed `state` enum wherever a component branches on more than about 3 `:if` combinations. Sync and index has 62 `:if`s, search 41, failed sync 31. Each struct gets a pure `build/…` function, unit-tested, that turns domain results into the view-model. Fixtures then construct view-models through the same `build` from realistic domain data, which is how "only states the app can render" gets enforced: if `build` cannot produce a state, no story may show it. Do not mock `Scrypath` or `Repo` in stories. Fixtures feed the pure builder (this is the anti-over-mocking rule).
3. **Events.** `phx-click` and `phx-submit` without `phx-target` go to the parent LiveView process, so components stay event-agnostic. Pass event names as attrs only where one component serves two parents. In stories, the harness catch-all logs them (§2). `Phoenix.LiveView.JS` commands (show, hide, toggle, `ops_sheet`, `ops_modal`) work unchanged in stories because they run on the client. Keep `phx-*` names stable, since e2e specs select on them.
4. **Async.** `sync_drift_live.ex` uses `start_async` and `handle_async` (5 sites, with generation guards). Keep those in the LiveView, and turn the result into an `%AsyncResult{}` or a view-model `state` field that the component renders. Stories build `AsyncResult.loading()`, `ok/1` and `failed/2` directly (https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.AsyncResult.html). No stories need real tasks.
5. **Streams.** Not used today. If they are adopted, components should take an enumerable of `{dom_id, item}`, which is what `@streams.x` yields. Stories pass a mapped list, or call `stream/3` inside the harness LiveView.
6. **Unchanged:** URL state stays in `handle_params`. Components never read `@flash`, `@live_action` or `@mount_path` implicitly. Pass `mount_path` explicitly, as `E2EUIFixtureLive` already does.

### Ranked extraction order

Ranked by JTBD weight (from `OPERATOR-UI-QUALITY.md`: JOB-05 search and JOB-03 recover are the baseline tasks, JOB-04 is settings and promotion) against difficulty.

| # | Surface (file) | Render LOC / events / `:if` / data calls | JTBD | Why this position |
|---|---|---|---|---|
| 1 | **Search health**, `posture_live.ex` (694) | 312 / 3 / 20 / 6 | JOB-03 entry | **Pilot.** It already has a view-model (`ScrypathOps.Posture`) and the phase173 seam, so it is the cheapest proof of the pattern. It deletes fixture branches from `lib/` and both duplicated fixture sources. |
| 2 | **Search**, `search_live.ex` (2062) | 723 / 26 / 41 / 2 | JOB-05 (highest traffic) | Highest value. It has few data calls but many events, so extract by area: results first (reusing `ResultUi` and the `E2EUIFixtureLive` fixtures), then targets and query, then saved searches (`search_live/saved_search_form.ex` already exists). The draft-vs-submitted states need a struct. |
| 3 | **Failed sync work**, `failed_sync_live.ex` (1227) | 403 / 5 / 31 / 6 | JOB-03 core | Medium difficulty. Error and boundary states (retry-eligible, ineligible, correlated, unknown visibility) are exactly where stories pay off. |
| 4 | **Sync and index**, `sync_drift_live.ex` (2470) | 554 / 9 / 62 / 29, plus 5 `handle_async` | JOB-04 | Hardest: a real state machine (settings compare → promotion → swap → refresh → observation). Needs a `%SyncIndexView{state: …}` struct and a pure builder first. Do it once the pattern has been proved by rows 1–3. |
| 5 | **Control room**, `control_room_live.ex` (252) | 137 / 1 / 14 / 0 | Navigation hub | Trivial. Do it alongside #1 as a warm-up, or when the IA changes. |
| 6 | **Help**, `help_live.ex` (221) | 210 / 0 / 0 / 0 | Support | Static. One `:page`-level story and no extraction. |

---

## 5. Adversarial pass: should there be a storybook at all?

| Objection | Weight | Mitigation (required, not optional) |
|---|---|---|
| **Maintenance burden.** Every component change edits stories too. | Real | Stories are compiled `.ex` files, so attr changes fail compilation, not review. The story count is capped by the pruning rules: delete a variation that no caller or `build` can produce, or that renders identically to another (enforced by the identical-HTML test). Pruning is a recorded decision. |
| **Drift from the real app.** The story shows a state the app never renders, or styling differs. | High in general, low with this design | Stories render the *same* components through the *same* root layout and `app.css`. There is no mirrored CSS, which removes phoenix_storybook's main drift vector. Fixtures go through the same pure `build/…` the LiveView uses. A short list of real composed routes stays in the e2e lane. |
| **False confidence.** "All stories green" is mistaken for "the UI is good." | Real | Treat L2 as a floor: it catches overflow, contrast, axe and console errors. Design judgement stays in the existing `ui:review` and visual-judge flow (L3). Stories make that review faster but never replace it. Journeys (JOB happy paths) stay as e2e specs. |
| **Refactor risk.** Extracting 2k-line LiveViews could break behaviour. | Medium | Extract one area per PR behind the existing e2e and contract tests, which assert selectors and copy. The pure builders get unit tests before their markup moves. Pilot on posture. |
| **The phase173 and E2EUIFixtureLive precedents already work.** Why generalise? | Fair | They work but don't scale: fixture branches sit in `lib/`, fixture sources are duplicated across two apps, and there is no manifest, coverage check or situation captions. The harness is those precedents, generalised. |
| **YAGNI: just use phoenix_storybook and get the playground for free.** | Fair | Its playground doesn't serve "curated real situations only". The cost is 8 new packages including a native NIF, a second CSS pipeline, a broken dark-mode model for these selectors, a duplicate install in the host, and a bus factor of 1 with a 2026 critical CVE. |

---

## 6. Recommendation

**Build the hand-rolled harness and do not adopt phoenix_storybook.**

Justification, in priority order:
1. **Fidelity.** Ops theming is keyed on `<html data-theme>`, and the stylesheet is a single Tailwind and daisyUI build. phoenix_storybook renders into a sandboxed div with a separately mirrored `storybook.css`, so both dark mode and CSS would drift by design. The harness renders under the real root layout and `app.css`.
2. **Dependency policy.** It adds 8 new packages, including the `mdex_native` Rust NIF fetched at compile time, against about 500 LOC that can be copied in. That clearly fails "copy and paste beats another dep".
3. **Topology.** Dependencies compile in `:prod`, so phoenix_storybook would have to be installed and configured twice, in ops and in the demo host. The harness needs no host change, and it offers an opt-in `compile_env` route macro if host rendering is ever needed.
4. **Correctness gates come cheaper in-house.** Compiled story modules, `__components__/0` coverage, the identical-render pruning test and a committed manifest are about 130 LOC, and they enforce the owner's "only real states" rule better than a playground does.
5. **Precedent.** `E2EUIFixtureLive` already proves the approach in this repo's e2e lane.

**First slice:**
- the harness, the manifest task and the render, coverage and pruning tests;
- the Posture view-model extraction, with health stories at every level;
- deletion of the `:phase173_fixture` branches and of both `Phase173FixtureSource` modules.

Then follow the §4 order: Search, Failed sync work, Sync and index, Control room, Help.

**Revisit trigger:** reconsider phoenix_storybook only if non-maintainers need a free-form playground, or if the story count passes about 500 and search or docs tabs become a real bottleneck.

### Sources
- Hex package and releases: https://hex.pm/packages/phoenix_storybook (API: https://hex.pm/api/packages/phoenix_storybook/releases/1.5.0)
- Repo, CHANGELOG and guides (setup, sandboxing, components, testing): https://github.com/phenixdigital/phoenix_storybook (tarball 1.5.0 read locally: `lib/phoenix_storybook/router.ex`, `stories/story.ex`, `live/story/component_iframe_live.ex`, `live/visual_test_live.ex`, `phoenix_storybook.ex`)
- Story API: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Story.html
- Open issues (e.g. #900 fonts): https://github.com/phenixdigital/phoenix_storybook/issues
- LiveView welcome guide (function vs live components): https://phoenix-live-view.hexdocs.pm/welcome.html
- `Phoenix.Component` attr/slot: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html
- `Phoenix.LiveView.AsyncResult`: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.AsyncResult.html
- `Phoenix.LiveViewTest.rendered_to_string/1`: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html
- Mix deps `:env` option (deps compile in `:prod`): https://hexdocs.pm/mix/Mix.Tasks.Deps.html
- Repo evidence: `scrypath_ops/mix.exs`, `scrypath_ops/mix.lock`, `scrypath_ops/lib/scrypath_ops_web/dev_router.ex`, `.../live/posture_live.ex`, `scrypath_ops/assets/css/app.css`, `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/router.ex`, `.../live/e2e_ui_fixture_live.ex`, `.planning/reference/OPERATOR-UI-QUALITY.md`

*No Dashbit or José Valim posts are cited: none was found that addresses this specific choice. The LiveView guide above is the authoritative position.*
