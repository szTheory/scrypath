# Phase 195: Mount and prove - Research

**Researched:** 2026-11-21
**Domain:** phoenix_storybook 1.5.0 mounted in the unpublished `scrypath_ops` Phoenix app (dev/test only), dependency and route boundary proofs, hosted CI cost measurement
**Confidence:** HIGH for wiring, boundaries and local timings (all exercised in a scratch copy this session); MEDIUM for hosted-CI cost (predicted from local numbers and 14 baseline runs, to be measured by the spike PR)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Recorded maintainer decisions (adopted 2026-11-21, SYNTHESIS.md and ADR 0001; not re-opened here)
- phoenix_storybook `~> 1.5` is a dev/test-only dependency of `scrypath_ops` (`only: [:dev, :test]`), not a hand-rolled harness — **Reversibility:** costly — ADR 0001 records the 2026-10-25 maintainer decision and its fallback; undoing it touches mix.lock, boundary tests and the Docker asset-builder stage
- Spike first (195), fixtures second (196): the spike's risks are external (Rust NIF via mdex, cold `ops-ui`, story-type limits) and fixtures pay off on a no-go
- The catalog runs inside the existing `ops-ui` job; no new required CI context and no branch-protection change (ask-first if one becomes necessary)
- Pre-authorized to continue after the go/no-go unless an ADR 0001 trigger trips: advisory open over 14 days; cold `ops-ui` more than 3 minutes over baseline; isolation work over a day; Docker `asset_builder` stage more than 60 s over; NIF failure twice. If a trigger trips the run stops and asks the maintainer
- PR titles are `docs`, `chore`, `test` or `ci`, never `feat` or `fix` (release-please has one root package); no Hex release; no root `lib/` change
- Never stage `.planning/config.json`, `.planning/state.json` or `.impeccable/config.json`; commit with explicit paths

#### Mount shape (verified against 1.5.0 source in H-adversarial-pass)
- `css_path` points at the built `/assets/css/app.css` (tracked at `scrypath_ops/priv/static/assets/css/app.css`); there is no separate `storybook.css`
- `themes_strategies: [data_attribute: "theme"]` puts the attribute on `<body>`, so a small `storybook.js` sets the `html` theme attribute and registers the same LiveView hooks as `app.js`
- Only `:component` and `:example` stories render in `container: :iframe`; `:page` stories cannot be iframed, so none are used
- The route macro's environment guard sits outside the `quote`; the route is loopback-bound and dev/test-only; the playground cannot be disabled, which is why loopback-only matters
- Render-all goes through the real iframe route, not a `render_component` helper (variation slots are HEEx strings; a helper could pass vacuously). Fails on empty output or `data-phx-error`; a planted failing story proves it can fail
- Five primitive stories; variations that carry adopter brand colors stay outside the roots the UI literal ratchet scans

#### Boundary tests (flip vacuous to real)
- The existing storybook row in `test/mix/tasks/dependency_boundary_contract_test.exs` asserts presence plus the `only` list, with a planted loosening that fails it; `PhoenixStorybook` and `MDEx` join the absent-module list for mounted and direct-prod scratch consumers and the `forbidden_dep` and `forbidden_modules` lists of `verify-dependency-boundaries.sh`; `package_metadata_test.exs` refutes `fixtures` and `storybook` in the tarball; a production route-table test (`DevRouter.__routes__()` or the prod scratch probe) has no `/storybook` path, with a planted case for the removed guard

#### Go/no-go
- `GO-NO-GO.md` records cold and warm `ops-ui` timings from a hosted run (`gh run view <id> --json jobs`), Rust NIF fetch time, lock growth and advisory status; each ADR 0001 trigger is evaluated explicitly; ADR 0001 is amended with the numbers. Baseline is the last green `ops-ui` run on main (about 368 s per the prep note)

#### Decided autonomously
- [Plan split] Q: "How many plans?" → Selected: "Two (plan 1 dependency, lock, boundary rows, route macro, production-absence tests, hosted timing; plan 2 css_path, storybook.js, five primitives, render-all, GO-NO-GO and ADR amendment)" — plan boundaries are planning metadata and cheap to re-cut
- [Story file layout] Q: "Where do the five primitive stories live?" → Selected: "A `storybook/primitives/` tree under `scrypath_ops` per the recorded glossary tiers" — files can be moved before Phase 197 builds on them
- [Which primitives] Q: "Which five primitives?" → Selected: "Chosen from existing ops function components by the planner (buttons, status badge, panel, empty state, form field class)" — story content is cheap to swap
- [Timing method] Q: "How are timings measured?" → Selected: "A throwaway branch PR run on hosted CI, cold (cache miss) then warm" — measurement method, no persisted contract

### Claude's Discretion
- Exact module names, story variation ids, the render-all test's iframe-route plumbing, and where `GO-NO-GO.md` lives (phase directory preferred)
- Whether the Docker `asset_builder` timing is measured locally or hosted, provided the recorded number says which

### Deferred Ideas (OUT OF SCOPE)
- Fixtures project and adopters (Phase 196); pilot job, view-model extraction, catalog contract test, 4003 seeded preview (Phase 197)
- Findings F1, F2, D1 (fixed in 197), D2: see SYNTHESIS; F1 and F2 need a root `lib/` change and stay ask-first
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MOUNT-01 | `phoenix_storybook ~> 1.5` dev/test-only; boundary row flips vacuous to real; `PhoenixStorybook`/`MDEx` absent from mounted + direct-prod scratch consumers and prod-image script lists; `package_metadata_test.exs` refutes `fixtures`/`storybook` | Findings 1, 6, 7 below; "Boundary changes" table; exact current rows quoted; env-aware script edit (the script also runs the `test` image) |
| MOUNT-02 | Route only in dev/test, loopback-bound; guard outside the `quote`; prod route table has no `/storybook`; planted case fails if guard removed | Finding 2 (compile_env expansion footgun), Finding 3 (do not mount a planted route in `DevRouter`), route macro example, static AST test with outside-quote walker, prod probe verified in scratch |
| MOUNT-03 | Real styling and hooks (`css_path` at `/assets/css/app.css`, `storybook.js`, five primitives); render-all via real iframe route, fails on empty output or `data-phx-error`; planted failing story | Findings 4, 5, 8; verified iframe path shape; verified harness with planted tree and negative control; five stories that render |
| MOUNT-04 | `GO-NO-GO.md` with cold/warm hosted timings, NIF fetch time, lock growth, advisory status; ADR 0001 amended; each trigger evaluated | "GO-NO-GO measurement protocol": 14-run baseline (noise is large), local numbers, advisory facts, Docker proxy |
| FLOW-01 | No Hex release/PR; titles `docs/chore/test/ci` | Constraint only; throwaway timing PR must also carry such a title and never merge |
| FLOW-02 | 5-plan phase cap, 20-plan milestone cap; ask-first items | Two plans fit; trigger-trip handling in protocol |
| FLOW-03 | Never stage the three config files; local mirror of each required lane before a push | Validation Architecture lane-mirror table |
| FLOW-04 | Findings F1, F2, D2, test hygiene recorded, not fixed | Not researched here (SYNTHESIS owns them); two new findings added in this file for the maintainer (Findings 2 and 9) |
</phase_requirements>

## Project Constraints (from AGENTS.md)

Directives that bind this phase (root `AGENTS.md` and `scrypath_ops/AGENTS.md`; there is no `CLAUDE.md`):

- Pre-push confidence: before pushing, run the local mirror of each required lane on the exact commit and say which part could not run; a skipped run needs a recorded reason (AGENTS.md "CI and CD efficiency").
- CI efficiency: measure with `gh run view <id> --json jobs`, never weaken what a check proves, record findings in `.planning/reference/CI-EFFICIENCY.md`.
- Docker: task-scoped names or labels, remove images, containers and owned build cache when done, check `docker system df`, never prune another project's resources.
- Never stage `.planning/config.json`, `.planning/state.json`, `.impeccable/config.json`; commit with explicit paths and check `git diff --cached --name-only`.
- PR titles `docs|chore|test|ci`; squash-merge a green PR yourself; the throwaway timing PR is never merged.
- Another copy-paste is better than another dependency; smaller flatter dependency trees (the storybook subtree is the recorded exception, ADR 0001).
- Zero human UAT: every success criterion needs an executable check; subjective rendered critique stays non-blocking and unclaimed.
- `scrypath_ops/AGENTS.md`: run `mix precommit` (`compile --warnings-as-errors`, `deps.unlock --unused`, `format`, `test`) when done; use `start_supervised!/1` in tests; prefer `element/2`/`has_element?` over raw-HTML assertions; never nest several modules in one file (the existing `dev_router.ex` already holds two; put new modules in their own files).
- Recorded owner decisions outrank prep notes: ADR 0001 (phoenix_storybook, not a hand harness) is not re-opened.

## Summary

The mount works as the prep notes predicted. In a scratch copy of `scrypath_ops` (tracked source of HEAD plus the dependency, a backend module, a route macro, a `storybook.js` and five primitive stories), `live(conn, "/storybook/iframe/primitives/ops_button?variation_id=default&theme=light")` renders the real production component inside the real iframe route with `css_path` resolving to `/assets/css/app.css?hash=...`, and 16 variations of 5 primitives pass a composite render-all harness. Production graphs are clean: a direct `prod` compile has no `PhoenixStorybook`, `MDEx`, catalog backend or `/storybook` route; a mounted consumer in `test` or `prod` has none of the storybook-only packages (`phoenix_storybook`, `mdex`, `mdex_native`, `makeup_eex`, `makeup_html`) in its lock; the host and root locks are unchanged and pass `deps.get --check-locked`.

The prep notes did not settle several things that change the plan. Four are traps that would have produced a green-but-wrong or red-for-the-wrong-reason result: (1) `Macro.expand` on `Application.compile_env(...)` returns a call AST, never the value, so copying the existing `dashboard_routes` guard pattern yields a route that is always off (or, as written today, a flag that is never consulted); (2) a "planted" second storybook mount inside `DevRouter` breaks the production compile, so the planted tree needs its own test-only endpoint and router; (3) `data-phx-error` is not emitted by the server in LiveView 1.1.34, and `psb-sandbox` is always on `<body>`, so "non-empty" must be asserted inside `[data-phx-main]` and a missing `storybook.js` is only a log warning; (4) `verify-dependency-boundaries.sh` runs the same forbidden-dependency loop over the `test` image too, where `phoenix_storybook` legitimately exists in `/app/scrypath_ops`, so the new names can be forbidden for the host in both images but for `/app/scrypath_ops` only in `prod`.

Hosted cost: `verify.ops_ui` already isolates the ops build and deps into scratch directories, so cache state cannot hide or reveal the storybook cost and cold versus warm will differ only by the root-graph caches. The measured baseline noise is large (14 successful main pushes: 360 to 579 s, median 409.5 s), so a baseline of 368 s plus 180 s (548 s) would already be exceeded by 2 of the 14 baseline runs; record both the 368 s figure and the median and route an in-between result to the maintainer. Local cold dependency compile of the whole ops graph grew from 20.1 s to 25.4 s (+5.3 s wall) and the NIF fetch was 0.66 s, so a trigger trip looks unlikely.

**Primary recommendation:** Plan 1 lands the dependency, lock, `elixirc_paths`, the flag-reading route macro in its own file, the flipped boundary rows, the prod-absence probes and the env-aware script edit, then a throwaway `ci(...)` PR produces cold and warm `ops-ui` numbers; Plan 2 adds `storybook.js` (tracked, separate esbuild profile, `assets.build` untouched), five stories, the pure-helper render-all with a test-only planted endpoint, `GO-NO-GO.md` and the ADR 0001 amendment.

## What the prep notes do not settle (read first)

Each item was exercised this session unless tagged otherwise.

1. **Guard flag must be read with `Application.get_env` at expansion, not `Macro.expand(Application.compile_env(...))`.** `Macro.expand` of the `compile_env` call returns a remote-call AST `{{:., [], [{:__aliases__, ..., [:Application]}, :compile_env]}, [], [...]}`, never `true`/`nil` [VERIFIED: ran an expansion probe in scratch]. The existing macro quoted below therefore never consults `dev_routes`; its `and dev_routes?` is truthy for any AST tuple. Today this is unobservable because `phoenix_live_dashboard` is `only: :dev` and absent in test, but copying the pattern for storybook made my first route macro compile to `:ok` everywhere (all `/storybook` requests were 404 in test) [VERIFIED]. Existing code, `scrypath_ops/lib/scrypath_ops_web/dev_router.ex:4-7`:
   ```elixir
   defmacro dashboard_routes(dev_routes_ast) do
     dev_routes? = Macro.expand(dev_routes_ast, __CALLER__)

     if Code.ensure_loaded?(Phoenix.LiveDashboard.Router) and dev_routes? do
   ```
   Hand this latent defect to the maintainer as a finding (it is in `scrypath_ops/lib`, not root `lib/`, so a fix is not ask-first, but it is outside this phase's scope; record it, optionally fix with its own test). The static guard test in `dependency_boundary_contract_test.exs:475-518` only checks that the `if` mentions `compile_env`, so it cannot see this.
2. **A planted mount inside `DevRouter` breaks the prod build.** `if Mix.env() == :test do import PhoenixStorybook.Router ... end` fails to compile in `prod` ("cannot compile module ScrypathOpsWeb.DevRouter ... expanding macro: Kernel.if/2") because `import` is resolved lexically even in a dead branch [VERIFIED: failed prod compile]. Do not touch the production router for the planted tree. Use a test-only endpoint plus router in `test/support` (see Code Examples); the same ConnTest/LiveViewTest machinery works with `@endpoint ScrypathOps.Catalog.PlantedEndpoint` [VERIFIED: passing run].
3. **`data-phx-error` is never produced by server-side LiveView 1.1.34 or phoenix_storybook 1.5.0.** Greps of `phoenix_live_view/lib` and the storybook `lib` found no emission; the only `phx-error` string is the JS client class `PHX_ERROR_CLASS = "phx-error"` in `priv/static/phoenix_live_view.esm.js:39` [VERIFIED: grep]. The requirement text inherits it from prep note E (judgment). Keep the substring check (cheap, requirement wording) but the real failure signals are: a crashing story makes `live/2` exit with the story's exception; an unknown `variation_id` exits with a `FunctionClauseError` in `ComponentIframeLive.variation_extra_attributes/2`; an empty variation renders `{:ok, view, html}` with an empty sandbox `<div>`; a missing `storybook.js` or `app.css` only logs a warning and drops `?hash=` [VERIFIED for all four].
4. **"Non-empty" must be measured inside `[data-phx-main]`.** `<body class="psb-sandbox ops-storybook" data-theme="dark">` is always present, so `html =~ "psb-sandbox"` passes vacuously for an empty story and for a request with no `variation_id` (which renders only the chrome, 1,794 bytes) [VERIFIED]. The empty planted story renders `<div style="display: flex; ..." class="" data-theme="light"></div>` and is caught by "sandbox has no child element and no text" [VERIFIED].
5. **A missing `priv/static/assets/js/storybook.js` is a silent pass.** `asset_hash/3` logs `Can't resolve js_path: .../storybook.js not found (storybook assets are built by mix assets.build)` and renders `<script ... src="/assets/js/storybook.js">` without `?hash=` [VERIFIED]. The render-all must therefore assert `?hash=<md5>` on both the `@import ... layer(app)` and the `storybook.js` script tag. Negative control: moving the bundle away turned the real render-all red with "js_path did not resolve (no ?hash=)" [VERIFIED].
6. **`verify-dependency-boundaries.sh` loops `for environment in test prod` (line 486) and runs `mix deps` in both `/app/scrypath_ops` and the host for each.** In the `test` image `/app/scrypath_ops` legitimately lists `phoenix_storybook`, `mdex`, `mdex_native` (`mix deps` per env: test LISTED, prod absent, dev LISTED) [VERIFIED]. Adding the names to the shared `forbidden_dep` list at lines 658-662 would fail the `test` target. Make the new names forbidden when `$environment == prod` or `$project_dir` is the host (host graph excludes them in both envs, verified via the mounted-consumer lock). The runtime module probe (lines 691-693) runs only in the host project, so `PhoenixStorybook` and `MDEx` can join `forbidden_modules` unconditionally.
7. **Mix `only:` of a path dependency's own dependencies is not applied to consumers, and `Mix.env()` inside the dependency is `:prod`.** A mounted consumer in `test` and in `prod` has a lock with none of `phoenix_storybook`, `mdex`, `mdex_native`, `makeup_eex`, `makeup_html`, `lazy_html`, `esbuild`; compiling the `test` consumer built 50 `scrypath_ops` files with the catalog backend, `test/support` modules and phase173 routes all absent [VERIFIED]. So adding `catalog/lib` to `elixirc_paths(:dev)` and `(:test)` is safe for hosts.
8. **ops-ui is always cold for the ops graph.** `verify.ops_ui` sets `MIX_BUILD_PATH`, `MIX_DEPS_PATH`, `MIX_HOME`, `MIX_ARCHIVES`, `HEX_HOME` to a scratch dir for every ops command (`dev/mix/tasks/verify.ops_ui.ex:83-92`), so the BEAM cache keys in `scripts/ci/beam_cache.cjs` only help the root graph. The "cold versus warm" the context asks for is real but small; report both and say why.
9. **Baseline noise.** ops-ui job seconds on 14 successful main pushes (2026-11-21): 360, 368, 368, 374, 378, 399, 409, 410, 419, 429, 449, 484, 553, 579 (median 409.5, mean 427) [VERIFIED: `gh run view <id> --json jobs`]. The locked wording "baseline about 368 s" is the low end of this range.
10. **`package_metadata_test.exs` and `ops_dependency_boundary_test.exs` live in `test/release/`, not `test/mix/tasks/`.** The refutes go after line 134 of `test/release/package_metadata_test.exs`; the scratch-consumer probes are in `test/release/ops_dependency_boundary_test.exs` [VERIFIED].
11. **The package-legitimacy seam does not support Hex** (`Usage: gsd-tools package-legitimacy check --ecosystem <npm|pypi|crates>`). Registry facts below come from the hex.pm API instead; `mdex_native` is young (first release 2026-06-05) with 121k downloads/week.
12. **Default NIF cache is already shared.** `rustler_precompiled` resolves its cache from `RUSTLER_PRECOMPILED_GLOBAL_CACHE_PATH` or else `:filename.basedir(:user_cache, "rustler_precompiled/...")` (`rustler_precompiled.ex:875-886`), which does not depend on `MIX_HOME`/`HEX_HOME`; one download per job, the other compile contexts hit it. No cache env var is needed [VERIFIED: source read; hosted behavior ASSUMED].

## Architectural Responsibility Map

This is a Mix/Phoenix library-adjacent app, not a browser/SSR/API stack, so tiers are the layers that own each capability.

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Dependency present only in dev/test | Mix manifest (`scrypath_ops/mix.exs` + lock) | Root contract tests | `only: [:dev, :test]` is what keeps the subtree out of every consumer graph (verified) |
| Route exists only in dev/test | Router compile-time macro (guard outside the quote) | Prod scratch probes | Absence is decided at router compile; proven by route-table probes in direct and mounted prod |
| Story rendering with real CSS and hooks | Endpoint `Plug.Static` + phoenix_storybook iframe LiveView | `storybook.js` bundle (tracked artifact) | `css_path`/`js_path` are URL paths served by the existing `static_paths` entry `assets` |
| Backend module and story files | `scrypath_ops/catalog/lib` (compiled dev/test only) and `scrypath_ops/storybook/` | Docker context | Kept out of `lib/` so prod and mounted builds never compile them; outside the UI literal ratchet roots |
| Prod-image absence | Docker verify script (`verify-dependency-boundaries.sh`) | Root static contract test with mutations | Image lists run only in `ecommerce-mounted`; a text-level static check gives a cheap local mirror |
| Cost measurement | Hosted CI (`gh run view --json jobs`) | Local scratch builds | Hosted is the number of record; local numbers are the control |

## Standard Stack

### Core
| Library | Version (resolved) | Purpose | Why Standard |
|---------|---------|---------|--------------|
| phoenix_storybook | 1.5.0 (2026-09-15, latest) | Storybook UI, iframe route, playground, search | Recorded maintainer decision, ADR 0001 [VERIFIED: hex.pm API; tarball read] |
| mdex | 0.14.7 | Markdown for storybook docs | Required by phoenix_storybook (`{:mdex, "~> 0.12"}`) [VERIFIED: tarball mix.exs; resolved in scratch] |
| mdex_native | 0.3.2 | Precompiled Rust NIF for mdex | Transitive; NIF downloaded by rustler_precompiled |
| rustler_precompiled | 0.10.1 | NIF download and checksum | Transitive |
| makeup_eex / makeup_html | 2.0.2 / 0.2.0 | Source highlighting in Source tab | Required by phoenix_storybook |
| makeup / makeup_elixir / nimble_parsec | 1.2.3 / 1.0.1 / 1.4.2 | Highlighter core | Transitive |

Lock growth: `scrypath_ops/mix.lock` 56 to 65 lines (+9 packages), no existing entry changed; root and host locks unchanged and `mix deps.get --check-locked` passes in root, host `test` and host `prod` [VERIFIED: ran in scratch].

### Supporting (already in the graph, no change)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| lazy_html | `>= 0.1.0`, `only: :test` (mix.exs:59) | HTML assertions in the render-all helper | `LazyHTML.from_document/1`, `query/2`, `text/1` [VERIFIED: used in spike] |
| esbuild | `~> 0.10`, `only: :dev` (mix.exs:61) | Builds `storybook.js` via a second profile | Dev-only; output is committed (see Pattern 4) |

### Alternatives Considered
None. The hand harness is the recorded ADR 0001 fallback only if a trigger trips (not re-opened here).

**Installation:**
```elixir
# scrypath_ops/mix.exs deps (insert before the heroicons line, mix.exs:63-64)
{:phoenix_storybook, "~> 1.5", only: [:dev, :test]},
```
then `cd scrypath_ops && mix deps.get`. Resolution: 1.4 s warm hex index, +9 packages.

**Version verification:** `curl https://hex.pm/api/packages/phoenix_storybook` lists 1.5.0 (2026-09-15) as newest, 1.4.1 (2026-09-07) before it [VERIFIED]. `mix hex.audit` on the new lock reports exactly the baseline findings (retired `sigra 1.20.0`; advisories `cloak 1.1.4` HIGH and `cloak_ecto 1.3.0` MEDIUM), and nothing for the nine new packages [VERIFIED: ran on baseline and new lock].

## Package Legitimacy Audit

The seam supports only npm, pypi, crates, so no seam verdicts exist. Registry facts from the hex.pm API [VERIFIED: hex.pm API this session]:

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| phoenix_storybook | hex | 3.7 y | 1.9M total, 31.6k/wk | github.com/phenixdigital/phoenix_storybook | seam n/a | Approved: ADR 0001 recorded decision |
| mdex | hex | 3.2 y | 2.3M total, 130k/wk | hexdocs.pm/mdex | seam n/a | Approved: transitive of the above |
| mdex_native | hex | 0.5 y (first release 2026-06-05) | 1.48M total, 121k/wk | github.com/leandrocp/mdex_native | seam n/a | Approved with note: young, same author as mdex; NIF downloaded from the GitHub release and checksum-verified by rustler_precompiled; covered by the NIF-failure trigger |
| rustler_precompiled | hex | 4.8 y | 10.1M total, 197k/wk | github.com/philss/rustler_precompiled | seam n/a | Approved |
| makeup_eex | hex | 4.7 y | 2.3M, 32.7k/wk | github.com/elixir-makeup/makeup_eex | seam n/a | Approved |
| makeup_html | hex | 5.4 y | 2.4M, 33.7k/wk | github.com/elixir-makeup/makeup_html | seam n/a | Approved |
| makeup, makeup_elixir, nimble_parsec | hex | 8.7 to 9.3 y | 95M to 112M | elixir-makeup, dashbitco | seam n/a | Approved |

**Packages removed due to [SLOP] verdict:** none (seam not run for hex).
**Packages flagged as suspicious [SUS]:** none. No `checkpoint:human-verify` is required: the package set is the maintainer's recorded decision and every name was read from the phoenix_storybook 1.5.0 `mix.exs` in the Hex tarball. Hex packages have no install-time scripts; the only network action is the NIF download at compile time.

## Architecture Patterns

### System Architecture Diagram

```
 mix.exs deps: {:phoenix_storybook, "~> 1.5", only: [:dev, :test]}
        │  (consumers: only: is not applied to a path dep's children → absent)
        ▼
 ┌──────── scrypath_ops (dev / test compile) ────────────────────────────┐
 │ elixirc_paths(:dev|:test) += "catalog/lib"                              │
 │   catalog/lib/.../storybook.ex  use PhoenixStorybook, content_path,   │
 │        css_path "/assets/css/app.css", js_path "/assets/js/storybook.js"│
 │   storybook/primitives/*.story.exs ── (eager compile in test)          │
 │                                                                         │
 │ lib/scrypath_ops_web/optional_catalog_routes.ex                         │
 │   if flag == true and Code.ensure_loaded?(PhoenixStorybook.Router)      │  ← guard OUTSIDE quote
 │      do quote: storybook_assets() + live_storybook "/storybook"          │
 │      else quote(do: :ok)                                                │
 │ DevRouter ──► route table (/storybook/iframe/*story, /visual_tests, …)  │
 └─────────────────────────────────────────────────────────────────────────┘
   request: GET /storybook/iframe/<story path>?variation_id=<id>&theme=<t>
        │ Endpoint Plug.Static serves /assets/css/app.css, /assets/js/storybook.js
        ▼
   ComponentIframeLive (real route) ─► ComponentRenderer evals generated HEEx
        ▼                                 against production components
   html: <head> @import app.css?hash=… layer(app); storybook.js?hash=…
         <body data-theme> <div data-phx-main> <div sandbox> component </div>

 TESTS
  render-all (scrypath_ops, real endpoint) ─► live/2 per variation ─► pure `problems/1`
  planted tree (test/support endpoint + router + backend) ─► same helpers must FAIL
  prod proof: root `ops_dependency_boundary_test` builds scratch consumers
     mounted test/prod + direct dev/test/prod ─► probe: modules, apps, DevRouter routes
  prod-image proof: verify-dependency-boundaries.sh (ecommerce-mounted, Docker)
```

### Recommended Project Structure (changes only)
```
scrypath_ops/
├── mix.exs                                   # dep, elixirc_paths, (optional) assets.storybook alias
├── mix.lock                                  # +9 packages
├── config/config.exs                         # second esbuild profile scrypath_ops_storybook
├── config/dev.exs, config/test.exs           # catalog_routes flag (test: off when PHX_SERVER=true)
├── assets/js/storybook.js                    # hooks + html data-theme (source)
├── priv/static/assets/js/storybook.js        # built, tracked like app.js (not in prod image)
├── catalog/lib/scrypath_ops/catalog/storybook.ex   # backend module (dev/test only)
├── storybook/primitives/*.story.exs          # five stories (outside UI literal roots)
├── lib/scrypath_ops_web/optional_catalog_routes.ex # guard macro (own file)
├── lib/scrypath_ops_web/dev_router.ex        # +require, +1 call
└── test/
    ├── support/catalog_render_all.ex         # pure helpers (targets/1, url/4, problems/1)
    ├── support/planted_storybook.ex (+ planted endpoint/router, split per module)
    ├── support/storybook_planted/failing/*.story.exs
    └── scrypath_ops_web/{storybook_render_all_test,storybook_planted_test,catalog_routes_test}.exs
test/mix/tasks/dependency_boundary_contract_test.exs   # root: rows flipped, guard AST test, script text check
test/release/{package_metadata_test,ops_dependency_boundary_test}.exs
examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh
```

### Current shape the plan edits (verbatim, with file:line)

| What | Where | Current text |
|------|-------|--------------|
| elixirc_paths | `scrypath_ops/mix.exs:42-43` | `defp elixirc_paths(:test), do: ["lib", "test/support"]` / `defp elixirc_paths(_), do: ["lib"]` |
| Dev/test-only deps pattern | `mix.exs:59,61` | `{:lazy_html, ">= 0.1.0", only: :test},` / `{:esbuild, "~> 0.10", only: :dev, runtime: Mix.env() == :dev},` |
| Aliases (pinned by a test, do not change) | `mix.exs:96`; asserted at `dependency_boundary_contract_test.exs:324-328` | `"assets.build": ["compile", "tailwind scrypath_ops", "esbuild scrypath_ops"],` |
| Static paths | `scrypath_ops/lib/scrypath_ops_web.ex:20` | `def static_paths, do: ~w(assets fonts images favicon.svg favicon.ico robots.txt)` |
| Test endpoint bind | `config/test.exs:23,27-28` | `ip: if(System.get_env("PHX_SERVER") == "true", do: {0, 0, 0, 0}, else: {127, 0, 0, 1}),` / `check_origin: System.get_env("PHX_SERVER") != "true",` / `server: System.get_env("PHX_SERVER") == "true"` |
| Dev bind and flags | `config/dev.exs:23,72` | `http: [ip: {127, 0, 0, 1}],` / `config :scrypath_ops, dev_routes: true` |
| Vacuous storybook row | `dependency_boundary_contract_test.exs:693-702` | `defp storybook_dependency_violation(manifest_path) do` / `if :phoenix_storybook in direct_dependency_names!(manifest_path) do` … (returns nil when absent) |
| Row label (stale) | `dependency_boundary_contract_test.exs:618` | `describe "storybook boundary (v1.47 catalog)" do` |
| Absent-module list | `test/release/ops_dependency_boundary_test.exs:7-18` | `@diagnostic_apps [:phoenix_live_dashboard, :telemetry_metrics, :telemetry_poller]`, `@asset_apps [:esbuild, :tailwind]`, `@absent_modules [ Module.concat(["Sigra", "Audit"]), … Module.concat(["ScrypathOpsWeb", "Telemetry"]) ]` |
| Tarball refutes | `test/release/package_metadata_test.exs:127-134` | `refute "scrypath_ops" in package_files` … `refute "dev" in package_files` |
| Prod-image lists | `verify-dependency-boundaries.sh:486,658,691` | `for environment in test prod; do` / `for forbidden_dep in esbuild tailwind phoenix_live_dashboard telemetry_metrics telemetry_poller; do` / `forbidden_modules = [Esbuild, Tailwind, Phoenix.LiveDashboard, Phoenix.LiveDashboard.RequestLogger, Telemetry.Metrics, :telemetry_poller]` |
| ops-ui job | `.github/workflows/ci.yml:442-476` | `ops-ui:` `name: ops-ui (path-scoped)` … `- run: mix deps.get` `- run: mix verify.ops_ui`; env `{PGPORT: "5433", MIX_ENV: test, MIX_TARGET: host, BEAM_CACHE_PROFILE: ops-test}` |
| ops isolation | `dev/mix/tasks/verify.ops_ui.ex:83-92` | `{"MIX_BUILD_PATH", Path.join(scratch, "build")},` … `{"HEX_HOME", Path.join(scratch, "hex")}` |

### Pattern 1: Route macro with the guard outside the quote
**What:** A macro that evaluates `enabled?(Application.get_env(...), Code.ensure_loaded?(PhoenixStorybook.Router))` at expansion and returns `quote(do: :ok)` otherwise. The flag and availability predicate is a public `@doc false` function so a unit test can run its truth table.
**When to use:** Always for the `/storybook` mount; call it once at the bottom of `DevRouter`.
**Verified shape:** see Code Examples. Result in scratch: prod `routes=14 storybook_routes=0`; test `routes=24 storybook_routes=8`; dev `routes=27 storybook_routes=8` (8 storybook routes: three asset routes, two `visual_tests`, one `iframe`, `/` and `/*story`) [VERIFIED].

### Pattern 2: Backend module in `catalog/lib`, not `lib/`
`use PhoenixStorybook` fails to compile where the dependency is absent, so the backend module must sit in a path that only dev/test compile. `Mix.env()` inside a path dependency is `:prod`, so consumers compile only `lib` [VERIFIED]. In `:test` the backend compiles in eager mode (every story compiles at `mix compile`; a syntax error in a story fails the build); in `:dev` it is lazy (`phoenix_storybook.ex:202-213`) [VERIFIED: read]. `mix compile --force --warnings-as-errors` is clean with five stories [VERIFIED].

### Pattern 3: Render-all as pure helpers plus a `live/2` loop in the test module
`live/2` expands to `get/2` and needs the test module's `@endpoint` and `import Phoenix.ConnTest`. Keep `targets/1`, `url/4` and `problems/1` pure in `test/support`; keep the `live/2` loop in two test modules (real endpoint, planted endpoint) so one helper set is checked against both a passing and a failing tree. `:component` stories iterate `story.variations()` ids (variation-group ids are valid `variation_id` values: `component_iframe_live.ex:193-196` finds by `to_string(&1.id)`); `:example` stories take no `variation_id` (`render_example/1` has no `variation_id` gate), so branch on `story.storybook_type()` and reject `:page` (not iframeable, `story_live.ex:428-438` per H).

### Pattern 4: `storybook.js` as a separate esbuild profile and a tracked artifact
A second profile `scrypath_ops_storybook` (entry `js/storybook.js`, no Phoenix/LiveView bundled because storybook prepends its own) builds a 37,943-byte file in 16 ms (app.js is 350,261 bytes) [VERIFIED]. Do **not** add it to `assets.build`: that alias is asserted verbatim (`dependency_boundary_contract_test.exs:324-328`) and is what the Docker `asset_builder` runs (`Dockerfile:40-42`), so leaving it alone keeps the Docker stage's commands unchanged. `esbuild` is `only: :dev`, so the test env cannot rebuild it; commit the built file like `app.js`. `git check-ignore -v scrypath_ops/priv/static/assets/js/storybook.js` exits 1 (not ignored: `scrypath_ops/.gitignore` re-includes `/priv/static/assets/`) [VERIFIED]. The prod images never carry it: the asset_builder stage deletes `scrypath_ops/priv/static/assets/js` (`Dockerfile:36-38`) and the runtime stages replace `priv/static` from the builder (`Dockerfile:72-74,108-110`) [VERIFIED: read]. Freshness check without a rebuild: a test that the bundle contains `window.storybook`, every hook name and `data-theme`, plus the render-all `?hash=` assertion.

### Pattern 5: Boundary rows
- **Flip the ops row** (`dependency_boundary_contract_test.exs:693-702`): violation when `:phoenix_storybook` is absent, when the requirement is not `"~> 1.5"` (`direct_dependency_requirement!/2` exists), or when `only` is not exactly `[:dev, :test]`. The "absent" planted manifest at lines 679-685 must flip from `== nil` to a violation; add planted cases for a wrong requirement. Rename the label at line 618.
- **Guard AST test** (root, same file, house style of lines 475-518): require an `if` whose condition contains `Code.ensure_loaded?(PhoenixStorybook.Router)` and the flag read, whose clause body contains `live_storybook`, and which is **not inside a `quote`**. The existing helper `conditional_has_calls_and_body?/3` (`:1060`) walks the whole AST including quotes, so a mutation that moves the `if` into the `quote` would still pass; add a small `has_node_outside_quote?/2` (prune `{:quote, _, _}` subtrees, about 10 lines). Planted mutations on the source string: delete the guard (`if ... do quote ... end` replaced by the bare quote) and move it inside the quote; both must fail the predicate.
- **Runtime guard proof** (`scrypath_ops/test/.../catalog_routes_test.exs`): truth table of `OptionalCatalogRoutes.enabled?/2`; compile a throwaway router via `Code.compile_string` with the flag off (`Application.put_env`, `async: false`) and assert no `/storybook` route, with the flag on assert the 8 routes (positive control); compile the same source with the guard stripped and assert the route appears (this is the planted "guard removed" case) [ASSUMED: `Code.compile_string` approach not run; every ingredient is verified separately].
- **Prod probes** (`ops_dependency_boundary_test.exs`): add `PhoenixStorybook`, `MDEx`, `ScrypathOps.Catalog.Storybook` (via `Module.concat` to avoid compile-time references from the root) to `@absent_modules` (feeds the mounted probe's `@forbidden_modules`) and `:phoenix_storybook, :mdex, :mdex_native` to a new `@storybook_apps` list checked against the mounted lock; in the direct probe expect them present in dev/test and absent in prod (`:code.which/1` and `.app` requirement, same shape as `@diagnostic_apps`); in both probes assert `ScrypathOpsWeb.DevRouter.__routes__()` has no `/storybook` path in mounted and direct prod and has it in direct dev/test. Do not add the storybook apps to `@diagnostic_apps`/`@asset_apps`: those lists assert absence in test.
- **Tarball:** add `refute "fixtures" in package_files` and `refute "storybook" in package_files` after `package_metadata_test.exs:134`. `PackageContract.allowed_top_level/0` is derived from the file list, so no second change is needed (`package_contents_test.exs:157-166`).
- **Script:** env-aware edit (Finding 6) plus a root text-level static check with a mutation (remove a name, expect failure), so the local mirror catches a typo before the 14 to 19 minute Docker lane. The `mix deps` line format `* phoenix_storybook 1.5.0 (Hex package) (mix)` matches the script's `grep -Eq "^[*] $forbidden_dep[[:space:]]"` [VERIFIED].

### Anti-Patterns to Avoid
- **`Macro.expand(Application.compile_env(...))` for a boolean:** returns an AST (Finding 1).
- **A test-only route inside `DevRouter`:** breaks prod (Finding 2). Likewise `import PhoenixStorybook.Router` anywhere outside the guarded quote.
- **`render_component` helper or `html =~ "psb-sandbox"`:** passes vacuously (Findings 3, 4).
- **Adding `phoenix_storybook` to the shared `forbidden_dep` list:** fails the `test` image (Finding 6).
- **Changing `assets.build`/`assets.deploy`:** pinned by a test and run by the Docker builder.
- **Putting the backend or stories under `lib/`:** compiled into prod and mounted consumers.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Storybook UI, search, iframe routes | A hand-rolled story LiveView | phoenix_storybook 1.5.0 | Recorded decision (ADR 0001); fallback only on a trigger |
| NIF download and checksum | Custom fetch or vendored `.so` | rustler_precompiled via mdex_native | Already integrity-checked; shared user cache |
| HTML emptiness assertions | Regex over raw HTML for structure | `LazyHTML.query/2` (already a test dep) | Spike-verified; also matches `scrypath_ops/AGENTS.md` guidance |
| Guard predicates over source | String matching | AST walk with the existing helpers plus an outside-quote walker | The helper pattern exists at `dependency_boundary_contract_test.exs:1060` |
| Cache provocation for ops-ui | New workflow inputs | `gh run rerun <run> --job <job id>` for the warm run | Re-runs one job; no workflow edit, no new context |

**Key insight:** every check in this phase must be able to fail. The two silent-pass hazards found (always-present `psb-sandbox`, warning-only missing assets) and the two vacuous guards (compile_env expansion, outside-quote) are exactly the cases where a green test would claim more than it proves.

## Runtime State Inventory

Not a rename/refactor/migration phase: omitted. Note only that the spike database `scrypath_ops_research_spike*` created during research was dropped.

## Common Pitfalls

### Pitfall 1: A green render-all with a broken storybook
**What goes wrong:** `live/2` succeeds, `psb-sandbox` is present, but the story is empty or `storybook.js` is missing. **Why:** see Findings 3 to 5. **Avoid:** `problems/1` asserts a non-empty sandbox inside `[data-phx-main]`, `?hash=` on css and js, and the (cheap, required) `data-phx-error` substring; the planted tree proves each branch can fail. **Warning signs:** a log warning "Can't resolve js_path" during `mix test`.

### Pitfall 2: Planted failure that is not a real failure
**What goes wrong:** the first planted idea (`slots: ["<.no_such_component />"]` on a component that ignores its slot) rendered fine (`<p>fine</p>`) [VERIFIED]. **Avoid:** plant what the harness actually detects: a render that raises (`live/2` exits), an empty render, and, optionally, an unknown `variation_id` (exits with `FunctionClauseError`).

### Pitfall 3: `live/2` crashes are exits, not raises
A crashing story ends the LiveView process; the test sees `catch :exit`, and the server logs a GenServer termination with the story's exception [VERIFIED]. Expect noisy logs from the planted test; capture with `ExUnit.CaptureLog` or accept it (`logger level: :warning` in test shows errors).

### Pitfall 4: Dead-branch `import` and `Mix.env()` checks
`Mix.env() == :test` does not stop `import` of an absent module from failing at expansion (Finding 2). Use a macro whose guard sits outside its quote.

### Pitfall 5: Lock drift across the three projects
`scrypath_ops` and the host depend on each other by path; CI-EFFICIENCY item 8 records a past `ecommerce-mounted` failure from a stale sibling lock. Here the host and root locks stay valid (verified), but run `mix deps.get --check-locked` in root, `scrypath_ops/` and `examples/scrypath_ecommerce/` after the lock change (`scripts/ci/pre_push.sh` does it).

### Pitfall 6: Namespace fence and literal ratchet on new files
New files under `scrypath_ops/test/support` are read by the namespace fence (CI-EFFICIENCY item 9): run `mix test test/mix/tasks/verify_namespace_fence_test.exs`. `scrypath_ops/assets/js/storybook.js` sits under a literal-ratchet root (`scripts/ci/ui_literal_policy.cjs:10-15`) so it must contain no hex colors or inline styles; `catalog/lib` and `storybook/` are outside the roots, which is where adopter brand colors may live in Phase 196+.

### Pitfall 7: The `test` Docker image would serve `/storybook`
`config/test.exs:23` binds `{0, 0, 0, 0}` and starts a server when `PHX_SERVER=true`, which the `runtime_test` image sets. With the flag on in `test.exs`, that image (CI-only, published on host loopback by the verify script) exposes the storybook (a hard-wired HEEx playground). Prefer `config :scrypath_ops, catalog_routes: System.get_env("PHX_SERVER") != "true"` in `test.exs` (same idiom as line 27), so the flag is off exactly when the test env is served on all interfaces [ASSUMED: expression not run; Dockerfile sets `ENV MIX_ENV=test PHX_SERVER=true` at `Dockerfile:90-91`, read this session]. A cheap root test can `Config.Reader.read!/2` the config files and assert "non-loopback http ip implies catalog flag off".

## Code Examples

All pieces below were run in the scratch copy (`.../scratchpad/ops-src/scrypath_ops`) unless tagged otherwise. Story values come from the verbatim component definitions: `ops_button` has `variant` values `[:default, :primary, :secondary, :ghost]` and `size` values `[:xs, :sm, :md]` (`ops_ui.ex:180-187`), `ops_sync_status` has `attr(:status, :atom, required: true, values: [:failed, :retrying, :pending, :clear])` (`ops_ui.ex:509`), `ops_badge` kinds `[:neutral, :info, :success, :warning, :error, :partial, :running]` (`ops_ui.ex:476-486` region), `ops_empty_state` has `attr(:title, :string, required: true)`, `slot(:actions)`, `slot(:inner_block, required: true)` (`ops_ui.ex:718-721`), `ops_panel` has `attr(:class, :any, default: nil)` and an inner_block slot (`ops_ui.ex:97-99`). The storybook `Variation` struct is `defstruct [:id, :description, :note, :let, slots: [], attributes: %{}, template: :unset]` (`variation.ex:48`, 1.5.0 tarball).

### Route macro (own file, guard outside the quote)
```elixir
defmodule ScrypathOpsWeb.OptionalCatalogRoutes do
  @moduledoc false
  # Flag read with Application.get_env at expansion: Macro.expand on a compile_env AST yields a call AST.
  defmacro catalog_routes do
    if enabled?(
         Application.get_env(:scrypath_ops, :catalog_routes, false),
         Code.ensure_loaded?(PhoenixStorybook.Router)
       ) do
      quote do
        import PhoenixStorybook.Router
        scope "/" do
          storybook_assets()
        end
        scope "/" do
          live_storybook("/storybook", backend_module: ScrypathOps.Catalog.Storybook)
        end
      end
    else
      quote(do: :ok)
    end
  end

  @doc false
  def enabled?(flag, storybook_loaded?), do: flag == true and storybook_loaded? == true
end
# DevRouter: `require ScrypathOpsWeb.OptionalCatalogRoutes` and, last in the module,
# `ScrypathOpsWeb.OptionalCatalogRoutes.catalog_routes()`
```
`live_storybook` may only be used in a scope with path `/` (`router.ex:52`), and defines its own `:storybook_browser` pipeline; do not `pipe_through :browser` around it (that pipeline sets the ops root layout).

### Backend module (`catalog/lib/scrypath_ops/catalog/storybook.ex`)
```elixir
defmodule ScrypathOps.Catalog.Storybook do
  use PhoenixStorybook,
    otp_app: :scrypath_ops,
    content_path: Path.expand("../../../../storybook", __DIR__),
    css_path: "/assets/css/app.css",
    js_path: "/assets/js/storybook.js",
    sandbox_class: "ops-storybook",
    themes: [light: [name: "Light"], dark: [name: "Dark"], system: [name: "System"]],
    themes_strategies: [data_attribute: "theme"]
end
```
`css_path` and `js_path` are URL paths and also the file under `priv/static` (`asset_helpers.ex:17-40`); `PhoenixStorybook.enabled?/0` reads `Application.get_env(:phoenix_storybook, :enabled, true)` so it defaults to on (`phoenix_storybook.ex:254-256`): the env guard has to be ours. `config :scrypath_ops, catalog_routes: true` goes in `dev.exs` and `test.exs`.

### Story (`storybook/primitives/ops_button.story.exs`; four siblings: `ops_badge`, `ops_panel`, `ops_empty_state`, `ops_sync_status`)
```elixir
defmodule ScrypathOps.Catalog.Stories.Primitives.OpsButton do
  use PhoenixStorybook.Story, :component

  def function, do: &ScrypathOpsWeb.OpsUi.ops_button/1
  def container, do: :iframe

  def variations do
    [
      %Variation{id: :default, slots: ["Retry"]},
      %Variation{id: :primary, attributes: %{variant: :primary}, slots: ["Retry failed work"]},
      %Variation{id: :ghost, attributes: %{variant: :ghost, size: :xs}, slots: ["Dismiss"]}
    ]
  end
end
```
Sibling shapes that rendered: `ops_sync_status` via `for status <- [:failed, :retrying, :pending, :clear], do: %Variation{id: status, attributes: %{status: status}}`; `ops_empty_state` with `attributes: %{title: "Nothing to show"}, slots: ["No rows yet.", "<:actions><.link href=\"#\">Open help</.link></:actions>"]`; `ops_panel` with `slots: ["<p>Panel body copy</p>"]`. Total 16 variations over the five primitives rendered. Note `size: :xs` on a button trips an existing source invariant (a `size: :xs` caller check in `ui-tokens.test.mjs`, ledger row 2): drop the `:xs` variation or keep stories outside that scan; confirm which roots that check reads [ASSUMED: the ledger text says "no `size: :xs` caller" but the scanned roots were not read this session].

### Pure helpers (`test/support/catalog_render_all.ex`) and the real loop
```elixir
defmodule ScrypathOps.Catalog.RenderAll do
  @moduledoc false
  def targets(backend) do
    for entry <- backend.leaves(),
        {:ok, story} = backend.load_story(String.trim_leading(entry.path, "/")),
        target <- story_targets(entry.path, story),
        do: target
  end

  defp story_targets(path, story) do
    case story.storybook_type() do
      :component -> for v <- story.variations(), do: {path, to_string(v.id)}
      :example -> [{path, nil}]
      other -> [{path, {:unsupported, other}}]
    end
  end

  def url(mount, path, variation_id, theme) do
    query = if variation_id, do: "?variation_id=#{variation_id}&theme=#{theme}", else: "?theme=#{theme}"
    "#{mount}/iframe#{path}#{query}"
  end

  def problems(html) do
    doc = LazyHTML.from_document(html)
    sandbox = LazyHTML.query(doc, "[data-phx-main] > *")
    inner = LazyHTML.query(doc, "[data-phx-main] > * > *")

    [
      {LazyHTML.to_html(sandbox) |> String.trim() == "", "no LiveView sandbox container"},
      {LazyHTML.to_html(inner) |> String.trim() == "" and LazyHTML.text(sandbox) |> String.trim() == "", "empty output"},
      {html =~ "data-phx-error", "data-phx-error present"},
      {not Regex.match?(~r|@import "[^"]+\?hash=[0-9a-f]{32}" layer\(app\)|, html), "css_path did not resolve (no ?hash=)"},
      {not Regex.match?(~r|<script[^>]+src="/assets/js/storybook\.js\?hash=[0-9a-f]{32}"|, html), "js_path did not resolve (no ?hash=)"}
    ]
    |> Enum.filter(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end
end
```
(Use `~r|...|`: a `{32}` inside `~r{...}` ends the sigil early [VERIFIED: compile error].) Real loop in `storybook_render_all_test.exs` (`use ScrypathOpsWeb.ConnCase, async: true`, `import Phoenix.LiveViewTest`): for each `{path, variation_id}` and each of `["light", "dark"]`, `{:ok, view, html} = live(conn, RenderAll.url("/storybook", path, variation_id, theme))`, `_ = render(view)`, collect `RenderAll.problems(html)` and `catch kind, reason` into a failures list, then `assert failures == []`. Ran in 0.1 s for 32 requests. The `:example` branch and `has_element?` variants were not exercised (no example story in this phase).

### Planted tree (test-only endpoint, router, backend, three stories; one module per file)
```elixir
# test/support: ScrypathOps.Catalog.PlantedStorybook  (use PhoenixStorybook, otp_app: :scrypath_ops,
#   content_path: Path.expand("storybook_planted", __DIR__), css_path: "/assets/css/app.css",
#   js_path: "/assets/js/storybook.js", themes_strategies: [data_attribute: "theme"])
# ScrypathOps.Catalog.PlantedRouter: use Phoenix.Router, helpers: false; import PhoenixStorybook.Router;
#   scope "/" do storybook_assets() end; scope "/" do live_storybook("/storybook", backend_module: ScrypathOps.Catalog.PlantedStorybook) end
# ScrypathOps.Catalog.PlantedEndpoint: use Phoenix.Endpoint, otp_app: :scrypath_ops; own @session_options;
#   socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]);
#   plug(Plug.Static, at: "/", from: :scrypath_ops, only: ~w(assets)); plug(Plug.Session, @session_options);
#   plug(ScrypathOps.Catalog.PlantedRouter)
# config/test.exs: config :scrypath_ops, ScrypathOps.Catalog.PlantedEndpoint,
#   secret_key_base: String.duplicate("p", 64), live_view: [signing_salt: "plantedlv"], server: false
```
Planted stories: `boom` (component raising `"planted render failure"`) and `empty` (component returning `~H""`). Test module: `use ExUnit.Case, async: false`, `import Phoenix.ConnTest`, `import Phoenix.LiveViewTest`, `@endpoint ScrypathOps.Catalog.PlantedEndpoint`, `setup do start_supervised!(@endpoint); {:ok, conn: build_conn()} end`, then run the same loop; observed: `{"/failing/boom", "boom"} => {:crashed, :exit}`, `{"/failing/empty", "empty"} => {:rendered, ["empty output"]}`; also unit-test `problems/1` with `"<html><body></body></html>"` and a `data-phx-error` fragment. The planted backend needs no `catalog_routes` flag: only the test router mounts it, and `DevRouter` never references it.

### `storybook.js` (source, `scrypath_ops/assets/js/storybook.js`)
```javascript
import {CommandPalette, OpsNavDrawer, OpsModal, OpsRefreshButton, OpsToast, OpsTimestampCopy} from "./ops_hooks"
import {OpsSearchDraft, OpsHelpAnchor, OpsFieldValidation} from "./ops_search"

;(function () {
  const theme = new URLSearchParams(window.location.search).get("theme")
  if (theme === "light" || theme === "dark") document.documentElement.setAttribute("data-theme", theme)
  window.storybook = {
    Hooks: {CommandPalette, OpsNavDrawer, OpsModal, OpsRefreshButton, OpsToast, OpsTimestampCopy, OpsSearchDraft, OpsHelpAnchor, OpsFieldValidation}
  }
})()
```
The hook list equals the `app.js` list minus `...colocatedHooks`; `grep -rn ColocatedHook scrypath_ops/lib` found nothing, so no colocated hooks are lost [VERIFIED]. `ops_hooks.js` exports `CommandPalette, OpsNavDrawer, OpsModal, OpsRefreshButton, OpsToast, OpsTimestampCopy` (`ops_hooks.js:754`), `ops_search.js` exports `OpsSearchDraft` and `OpsHelpAnchor` and re-exports `OpsFieldValidation`; none imports `phoenix`. Extend the existing parity test (`ops_shell_contract_test.exs:285-290` shape) to a third regex over `storybook.js`. The iframe document gets `data-theme` on `<body>` and on the inner sandbox `<div>` from the library; `<html>` gets none, hence the script (System-mode rules key on `html:not([data-theme="light"])`, per H).
esbuild profile (config.exs): `scrypath_ops_storybook: [args: ~w(js/storybook.js --bundle --target=es2022 --outdir=../priv/static/assets/js), cd: Path.expand("../assets", __DIR__)]`; build with `mix esbuild scrypath_ops_storybook` in dev (first `esbuild.install` took 33.8 s because it also compiled the dev graph).

### Env-aware script edit (design; grep format verified, bash edit not run)
```bash
forbidden_deps="esbuild tailwind phoenix_live_dashboard telemetry_metrics telemetry_poller"
if [[ "$environment" == "prod" || "$project_dir" == "/app/examples/scrypath_ecommerce" ]]; then
  forbidden_deps="$forbidden_deps phoenix_storybook mdex mdex_native"
fi
for forbidden_dep in $forbidden_deps; do
```
and `forbidden_modules = [..., :telemetry_poller, PhoenixStorybook, MDEx]` at line 691. Optional stronger proof (planner's call): `curl` `/storybook` on the standalone Ops container and the host in both images and require 404.

## GO-NO-GO measurement protocol

**Baseline.** Record both: the locked "about 368 s" (minimum-ish; runs 44930917171, 44922150467 at 368) and the 14-run median 409.5 s (mean 427, max 579). Two of the 14 (553, 579) exceed 368+180=548, so the trigger cannot be read against 368 alone; against the median it is about 590 s. Take a fresh same-day control: `gh run rerun <recent main run> --job <ops-ui job id>` re-runs only that job (flag exists in `gh run rerun --help`; not exercised) and gives a paired sample. If the PR's cold number lands between 548 and 590 s, that is a judgment case: stop and ask the maintainer rather than continuing silently.
**Cold vs warm.** `verify.ops_ui` isolates ops build/deps/hex (Finding 8), so both runs pay the full storybook compile; "cold" = first run after the lock change (root-graph cache key `beam-v1-resolved-<digest>-<locks_digest>-` misses, `scripts/ci/beam_cache.cjs:111-118` region), "warm" = rerun of the same job on the same SHA. Report the difference honestly even if it is a few seconds. Do not use the `phase182_cache_mode` dispatch inputs: they apply to the root `core` and Docker jobs, not `ops-ui`.
**Procedure.** (1) Plan 1's commits on a branch, open a draft PR titled `ci(ops-ui): measure storybook dependency cost` (never merged; FLOW-01). (2) `gh run view <run> --json jobs` for `ops-ui (path-scoped)`: total and the `Run mix verify.ops_ui` step. (3) `gh run rerun --job` for warm. (4) The hosted log keeps per-line timestamps; the NIF fetch is the delta between the `Downloading NIF from` and `NIF cached at` debug lines printed by `mix` in the captured step output [ASSUMED: lines are not suppressed by `MIX_QUIET`/`CI` in the suite compile; locally they printed]. Local reference: 0.66 s, 1,328,480-byte `.tar.gz` for `aarch64-apple-darwin` nif-2.15 [VERIFIED]. (5) NIF failures: count failed fetches across all hosted runs including the two cold ones.
**Docker `asset_builder`.** Hosted per-build marker lines share one timestamp (flushed together), so they give no stage time. Use the `ecommerce-mounted` step `Bake and load checked mounted images` as an upper-bound proxy: 253, 259, 351 s on the last three main runs [VERIFIED]; it contains asset_builder on its critical path and also compiles storybook in `runtime_test`, so a PR delta under 60 s proves the +60 s trigger is not tripped; a larger delta means measure locally: task-scoped `docker build --no-cache --target asset_builder -t scrypath-195-<before|after>` on main HEAD versus the branch, then `docker rmi` and check `docker system df` (AGENTS.md). Record which was used. Local native numbers for orientation: cold compile of the whole ops graph (test env, Apple silicon) 20.1 s without and 25.4 s with the dependency (+5.3 s wall, +8.6 s CPU) [VERIFIED]; expect roughly 2 to 3 times that on a hosted runner (judgment).
**Lock growth.** 56 to 65 lines, +9 packages, no existing package changed; host and root locks unchanged [VERIFIED].
**Advisories** (trigger 1: none open over 14 days on resolved versions) [VERIFIED: `gh api` and `mix hex.audit` today]: phoenix_storybook has 3 global advisories published 2026-05-20, all patched in 1.1.0 (GHSA-55hg-8qxv-qj4p critical, unauthenticated RCE via HEEx template injection in the playground; GHSA-833p-95jq-929q high, atom-table DoS; GHSA-mrhx-6pw9-q5fh low, PubSub topic injection); resolved 1.5.0 is clear. mdex repo advisories GHSA-4383-7xfp-gpph and GHSA-923r-7vf4-5vw8 (patched 0.13.2); mdex_native-repo advisories published 2026-06-29 (GHSA-j93q, cmvp, v664, 3w4f); GHSA-3w4f's entries are package `mdex` `>= 0.3.0` patched `>= 0.12.3` and package `mdex_native` `>= 0.1.0 and < 0.2.3` patched `0.2.3`, so resolved mdex 0.14.7 and mdex_native 0.3.2 are clear (a first jq pass showing only one entry made it look unbounded). The global DB returns 0 for the other eight packages. `mix hex.audit`: no new findings versus baseline (baseline already red for `sigra 1.20.0` retired and `cloak`/`cloak_ecto`, which is why `deep-quality (advisory)` is red on every main run, 187 to 262 s).
**Isolation work.** Record engineer hours spent on fidelity and wiring; this research found none above a few minutes of fix-up.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `storybook.css` mirroring app.css | `css_path` at the production built CSS | 1.5.0 serves any `priv/static` path (`asset_helpers.ex`) | No second Tailwind profile; hash follows mtime |
| Igniter/`phx.gen.storybook` installer | Hand-written ~5 files | Prep C D7 | No `igniter` dependency |
| `render_component` render-all | Real iframe route via `live/2` | H row 10 | Slots (HEEx strings) render for real |

**Deprecated/outdated:** the shape in ADR 0001's original text (`storybook.css`, all screens in iframes) is already corrected by its 2026-11-21 amendments.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Hosted `ops-ui` cost delta is within +180 s (extrapolated from +5.3 s local wall per graph build, three storybook-bearing builds per run, 2 to 3x slower runner) | Summary, protocol | A trigger trips; protocol says stop and ask |
| A2 | Hosted log lines expose the NIF fetch timestamps | Protocol | Use local 0.66 s plus a log search; record "not observed on hosted" |
| A3 | `gh run rerun --job` gives a clean warm sample | Protocol | Fall back to a second empty-commit push |
| A4 | The `Bake and load` delta is a conservative proxy for the asset_builder stage | Protocol | Measure locally with Docker |
| A5 | `Code.compile_string` planted-router test works as sketched | Pattern 5 | Use the static AST test plus the prod probe only |
| A6 | `config :scrypath_ops, catalog_routes: System.get_env("PHX_SERVER") != "true"` is read correctly at compile in the Docker `runtime_test` stage | Pitfall 7 | Test image keeps `/storybook` (loopback-published, CI-only); verify with the optional curl check |
| A7 | `size: :xs` caller invariant may flag a story variation | Code Examples | Drop that variation |
| A8 | phoenix_storybook 1.5.0 handles hostile story path segments (not audited; loopback and dev/test only) | Security | Residual risk accepted by ADR 0001's loopback control |
| A9 | NIF for `x86_64-unknown-linux-gnu` downloads on ubuntu-24.04 and in the hexpm debian-bookworm image (prep C read the checksum file, not re-read here) | Protocol | NIF-failure trigger |
| A10 | `scrypath_ops/priv/static/assets/js/storybook.js` as a tracked artifact is acceptable drift-wise | Pattern 4 | Add a freshness check or generate in a dev alias only |

## Open Questions

1. **Baseline definition for the +180 s trigger.** Locked text says last green main run (about 368 s); data say median 409.5 s with spread 360 to 579 s. Recommendation: record both, evaluate against both, and treat a result between them as an ask-first judgment.
2. **Test env flag expression and the `runtime_test` image.** Recommend `catalog_routes` off when `PHX_SERVER == "true"` (Pitfall 7), plus an optional 404 curl in the verify script. Planner decides whether the Docker-side proof is worth one more edit to a Docker-only lane.
3. **`.dockerignore` for `scrypath_ops/storybook` and `scrypath_ops/catalog`.** `COPY . .` puts story and backend sources into prod images (uncompiled, unloaded). Excluding them is cheap defense in depth; but `runtime_test`/`asset_builder` would then compile a router that names a missing backend module. Recommendation: leave the sources in (they are inert in prod) unless the maintainer wants image contents asserted.
4. **Root `.formatter.exs` inputs** (`scrypath_ops/{config,lib,test}/**` and `scrypath_ops/mix.exs`) do not cover `catalog/` or `storybook/`. Add `scrypath_ops/{catalog,storybook}/**/*.{ex,exs}` so `core`'s `mix format --check-formatted` covers them.
5. **Render-all file and the ledger.** CONTEXT says this phase adds no gate row and row 11 is Phase 197's. Name the 195 file so 197 can fold it into its single contract file (`storybook_render_all_test.exs`); it still runs in the required `ops-ui`.
6. **Latent `dashboard_routes` guard defect** (Finding 1): fix now with its own test or record only? Recommendation: record in the findings note; fix only if the maintainer asks.
7. **Playwright fidelity probe** (computed-style parity, three themes by two color schemes) is listed by H as a 195-2 exit item. `examples/scrypath_ecommerce/node_modules/.bin/playwright` and cached chromium exist, so a throwaway local probe is feasible; it is not a CI gate and is not part of the success criteria. Planner decides whether to run it in this phase or leave it to 197.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/OTP (asdf) | all `mix` | yes (needs `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5`) | 1.19.0 / OTP 28.5 (CI: 1.19.0 / 28.1) | none needed |
| hex.pm, npm registry, github.com | deps.get, esbuild.install, NIF fetch | yes | NIF `aarch64-apple-darwin` fetched in 0.66 s | none needed |
| Postgres | `mix test` (alias runs `ecto.create`), `verify.ops_ui` | yes, accepting on `/tmp:5432`; `localhost` with postgres/postgres worked | n/a | `PGHOST`/`PGPORT` overrides |
| Docker Desktop | local `asset_builder` measurement, `ecommerce-mounted` mirror | yes, engine 29.5.2, 8 CPUs, 15.6 GiB; `docker system df` shows 29 GB build cache (not mine) | | hosted proxy |
| `gh` (authenticated as szTheory) | timing, advisories | yes | | none |
| Playwright + chromium | optional fidelity probe | yes (`node_modules/.bin/playwright`, `~/Library/Caches/ms-playwright` chromium-1200/1212) | | skip, record reason |
| `act` | workflow wiring only | not checked (AGENTS says `/opt/homebrew/bin/act`); no workflow edits in this phase | | n/a |

No missing dependency blocks execution.

## Validation Architecture

`workflow.nyquist_validation` is true in `.planning/config.json`.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19) with `Phoenix.LiveViewTest` and `LazyHTML` in `scrypath_ops`; ExUnit at root |
| Config files | `scrypath_ops/test/test_helper.exs`; root `test/test_helper.exs` |
| Quick run (ops) | `cd scrypath_ops && mix test test/scrypath_ops_web/storybook_render_all_test.exs test/scrypath_ops_web/storybook_planted_test.exs test/scrypath_ops_web/catalog_routes_test.exs` (needs Postgres; about 5 s plus compile) |
| Quick run (root) | `mix test test/mix/tasks/dependency_boundary_contract_test.exs test/release/package_metadata_test.exs` (seconds) |
| Full suite | `mix verify.ops_ui` (repo root; Postgres reachable) |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MOUNT-01 | Dep present, `~> 1.5`, `only: [:dev, :test]`; planted loosening/absence/wrong requirement fails | root unit | `mix test test/mix/tasks/dependency_boundary_contract_test.exs` | edit existing row (lines 618-703) |
| MOUNT-01 | `PhoenixStorybook`, `MDEx`, apps absent from mounted test/prod and direct prod; present in dev/test | integration (cold scratch builds) | `mix test test/release/ops_dependency_boundary_test.exs --include integration --warnings-as-errors` (part of `mix verify.ops_ui`) | edit existing |
| MOUNT-01 | Script forbids the names for prod and host, not for the `test` ops graph; mutation fails | root unit (text + `--static-contract-only` mutation set) | same root file | add test + mutation |
| MOUNT-01 | Tarball refutes `fixtures`, `storybook` | root unit | `mix test test/release/package_metadata_test.exs` or `mix verify.package` | edit after line 134 |
| MOUNT-02 | Guard outside quote (AST) with planted removal/move-inside mutations | root unit | root contract test | new test + `has_node_outside_quote?/2` |
| MOUNT-02 | Flag/availability truth table; flag-off router has no `/storybook`; flag-on has 8; guard-stripped source exposes it | ops unit (`async: false`) | `cd scrypath_ops && mix test test/scrypath_ops_web/catalog_routes_test.exs` | Wave 0 |
| MOUNT-02 | Prod route table has no `/storybook` (direct and mounted prod) | integration probe | `mix verify.ops_ui` | extend probes |
| MOUNT-02 | Loopback: dev `127.0.0.1`; any non-loopback bind implies flag off | root unit via `Config.Reader.read!/2` [ASSUMED approach] | root contract test | Wave 0 |
| MOUNT-03 | Every variation of five primitives renders via real iframe route; fails on empty/`data-phx-error`/missing assets/crash | ops integration-style unit | `cd scrypath_ops && mix test test/scrypath_ops_web/storybook_render_all_test.exs` | Wave 0 |
| MOUNT-03 | Planted failing tree is detected by the same helpers | ops unit | `... storybook_planted_test.exs` | Wave 0 |
| MOUNT-03 | `storybook.js` registers the same hooks as `app.js`; bundle contains them and `data-theme` | ops unit | `cd scrypath_ops && mix test test/scrypath_ops_web/ops_shell_contract_test.exs` (extend regex) | edit existing |
| MOUNT-04 | `GO-NO-GO.md` has cold/warm hosted numbers, NIF time, lock growth, advisory status, one verdict line per trigger; ADR 0001 amended | manual doc check, not CI | `grep -c` for required headings; `git diff --stat .planning/adr/0001-*.md` | create |
| FLOW-01/03 | Titles; no staged config files | pre-commit check | `git diff --cached --name-only \| grep -E '^(\.planning/(config\|state)\.json\|\.impeccable/config\.json)$'` must print nothing | n/a |

No human UAT item remains. The only non-automatable parts are hosted-run numbers, which are recorded evidence, not a pass/fail gate; the optional computed-style probe is local and non-gating.

### Sampling Rate
- **Per task commit:** `mix format --check-formatted` (root), the focused test file(s) above.
- **Per wave merge:** root `mix test test/mix/tasks/dependency_boundary_contract_test.exs test/release/package_metadata_test.exs test/mix/tasks/verify_namespace_fence_test.exs` plus the three ops test files plus `mix precommit` in `scrypath_ops`.
- **Phase gate:** local mirror of every required lane on the committed head (below), then hosted CI green on the exact PR head.

### Local mirror of each required CI lane (run on the committed head before any push)
| Lane | Mirror | Cost | Note |
|------|--------|------|------|
| `core` | `scripts/ci/pre_push.sh` (format, warnings-as-errors compile, Credo, workflow wiring) then `mix test test/mix/tasks/dependency_boundary_contract_test.exs test/release/package_metadata_test.exs`; full `mix verify.core --exclude integration --exclude docs_contract` about 6 min | min to 6 min | Several contracts clone `HEAD`: commit first |
| `package` | `mix verify.package` | not measured locally (hosted 110 s) | |
| `repository-contracts` | `mix verify.repository_contracts` (about 6 min) and `node scripts/ci/ui_literal_policy.cjs` (new `storybook.js` is under a scanned root) | | needs `origin` reachable |
| `ops-ui (path-scoped)` | `mix verify.ops_ui` from the root | 6 to 8 min estimated (hosted 360 to 579 s; not measured locally) | cannot show hosted cache state or the Linux NIF target |
| `ecommerce-mounted` | `mix verify.ecommerce_mounted` (hosted bake 253 to 351 s plus proof 517 to 750 s; local not measured, Apple silicon builds arm64) | 15 to 20 min | If skipped locally, record "Docker lane not run locally: first full proof of the script edit is hosted; text-level static check and `bash -n` ran instead" and treat it as a known risk |
| `backend` | not affected (no root `lib/`) | | record "not affected" |
| After the lock change | `mix deps.get --check-locked` in root, `scrypath_ops/`, `examples/scrypath_ecommerce/` | seconds | CI-EFFICIENCY item 8 |
| New files in `scrypath_ops/test` | `mix test test/mix/tasks/verify_namespace_fence_test.exs` | 1 s | CI-EFFICIENCY item 9 |

### Wave 0 Gaps
- [ ] `scrypath_ops/test/scrypath_ops_web/storybook_render_all_test.exs`, `storybook_planted_test.exs`, `catalog_routes_test.exs`
- [ ] `scrypath_ops/test/support/` helpers, planted backend, endpoint, router (one module per file), `storybook_planted/failing/{boom,empty}.story.exs`; `config/test.exs` planted endpoint config
- [ ] `scrypath_ops/lib/scrypath_ops_web/optional_catalog_routes.ex`, `catalog/lib/.../storybook.ex`, five `storybook/primitives/*.story.exs`, `assets/js/storybook.js` and its built, committed bundle
- [ ] Root: `has_node_outside_quote?/2` helper and the new/edited cases in `dependency_boundary_contract_test.exs`
- [ ] Framework install: none (ExUnit, LiveViewTest, LazyHTML already present)

## Security Domain

`security_enforcement` is not set to false in config, so this section applies.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V1 Architecture / V14 Configuration | yes | `only: [:dev, :test]`, guard outside the quote, prod-graph absence tests, loopback-only bind, flag off when the test env is served on all interfaces |
| V2/V3 Authentication, Session | no (storybook has none by design) | The route is loopback and dev/test-only; no auth is added |
| V4 Access Control | yes | Network reachability is the control: loopback bind (dev.exs:23) and no route in prod (tested) |
| V5 Input Validation | partial | `variation_id`, `theme` and the story path are URL inputs handled by the library; hostile-path handling not audited (A8) |
| V6 Cryptography | no | none |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Server-side HEEx evaluation in the playground (hard-wired, cannot be disabled: tabs at `story_live.ex:293-301` per H; critical RCE GHSA-55hg-8qxv-qj4p fixed in 1.1.0) | Elevation of privilege | Dev/test only, loopback only, no prod graph, `~> 1.5` floor admits no vulnerable version; planted-guard and prod-absence tests |
| Storybook reachable on a published port in a CI image | Information disclosure | Flag off when `PHX_SERVER=true` in test; optional 404 check in the verify script |
| Supply chain via a precompiled NIF | Tampering | rustler_precompiled checksum verification; NIF-failure trigger; no `RUSTLER_PRECOMPILED_FORCE_BUILD_ALL` needed |
| Dependency drift from a Dependabot bump | Tampering | The pin row asserts `~> 1.5` and `only`; render-all fails on a breaking minor |

## Sources

### Primary (HIGH)
- phoenix_storybook 1.5.0 Hex tarball (`repo.hex.pm/tarballs/phoenix_storybook-1.5.0.tar`, read in an isolated scratch dir): `lib/phoenix_storybook/router.ex` (live_storybook, storybook_assets, session wiring), `lib/phoenix_storybook.ex` (`enabled?`, compilation mode, config keys), `live/story/component_iframe_live.ex`, `templates/layout/root_iframe.html.heex`, `helpers/asset_helpers.ex`, `views/layout_view.ex`, `helpers/theme_helpers.ex`, `stories/variation.ex`, `guides/{setup,sandboxing,testing}.md`, `mix.exs` deps.
- `rustler_precompiled` 0.10.1 source (`lib/rustler_precompiled.ex:875-886`) from the scratch deps.
- Repo files read this session with file:line citations above; scratch experiments under `/private/tmp/claude-501/-Users-jon-projects-scrypath/afd5559e-efb4-4bb2-8341-eb9df5900f61/scratchpad` (not part of the repo).
- hex.pm API (versions, downloads, first release); GitHub Advisory Database and repo advisories via `gh api`; `gh run view --json jobs` for hosted timings (runs 44943834998, 44943130548, 44939887715, 44930917171 and 10 more).
- Prep notes C, E, H, SYNTHESIS, ADR 0001 (treated as established where H marks CONFIRMED).

### Secondary (MEDIUM)
- `.planning/reference/CI-EFFICIENCY.md` local-first checklist and lane-mirror table (maintainer-recorded).

### Tertiary (LOW)
- Hosted extrapolations (A1 to A4), unrun sketches (A5, A6), hostile-path behavior (A8).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH, resolved and compiled in scratch; hex.pm and `hex.audit` checked.
- Architecture: HIGH for mount, route, backend, render-all, planted tree and prod absence (each ran); MEDIUM for the guard-stripped planted-router test and Docker script edit (sketched).
- Pitfalls: HIGH, each pitfall reproduced as a failure or a vacuous pass.
- Hosted cost: MEDIUM until the spike PR runs.

**Research date:** 2026-11-21
**Valid until:** 2026-12-05 (phoenix_storybook and its NIF subtree move fast; re-run `hex.pm` version and `gh api` advisory checks if planning slips past this)
