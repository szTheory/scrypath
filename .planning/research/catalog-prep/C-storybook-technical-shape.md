# Prep C: storybook technical shape and the spike

Date 2026-11-21. Research only; nothing in the repo was changed except this note. Tags: V = read or ran it, J = judgment, U = unverified. phoenix_storybook 1.5.0 source was read from the Hex tarball (`repo.hex.pm/tarballs/phoenix_storybook-1.5.0.tar`, paths below are inside it). A scratch project (Phoenix 1.8.17, LiveView 1.1.34 plus `{:phoenix_storybook, "~> 1.5"}`, Elixir 1.19.0, OTP 28.5, arm64 Mac) was compiled in the session scratchpad for timings.

## Corrections to earlier notes (each has file:line)

1. **`:page` stories cannot be iframed** (V). `story_live.ex:428-438` renders a page inline in the chrome's DOM from `render(%{__changed__: %{}, tab:, theme:})` as static HTML. Only `:component` and `:example` take `container: :iframe` (`story_live.ex:440-455`, `component_iframe_live.ex:96-176`). ADR 0001 and C2 say screens go in iframes; that means `:component` or `:example`, not `:page`.
2. **`storybook.css` is unnecessary** (V). `css_path` is both the URL path and the file under `priv/static` (`asset_helpers.ex:19-33`), imported as `@import "<path>?hash=<md5>" layer(app)` (`root.html.heex:69`, `root_iframe.html.heex:58`). Point it at `/assets/css/app.css`, which the standalone endpoint already serves (`static_paths` has `assets`, `scrypath_ops_web.ex:20`). The hash follows mtime, so there is no mirror to go stale and no second Tailwind profile.
3. **`data_attribute: "theme"` puts the attribute on `<body>`, not `<html>`** (V: `root_iframe.html.heex:75`; `theme_helpers.ex:7-31`). ADR 0001 says descendant selectors work from any ancestor. True for `[data-theme="dark"] .x`, false for the System-mode rules `html:not([data-theme="light"]) .ops-header` (`app.css:1989` and about 25 siblings). On a dark-OS machine an explicit Light story renders a mixed theme: daisy variables light, header/sidebar/panel dark. Fix is a few lines in the story JS (below).
4. **Fonts:** the app declares Hanken Grotesk (`ui.woff2`) and Sometype Mono; Bricolage (`display.woff2`) is on disk but never declared (V: `app.css:14-26`). Fonts resolve as `../fonts/` against the imported CSS URL, so `/assets/fonts/` is served by the endpoint's `Plug.Static`.
5. **C30 "no advisories for mdex packages" is incomplete** (V, `gh api`). Repo-level advisories exist, published 2026-06-29: mdex GHSA-4383-7xfp-gpph and GHSA-923r-7vf4-5vw8 (patched 0.13.2); mdex_native GHSA-j93q/cmvp/v664/3w4f (patched 0.2.3). The global advisory DB returns none for mdex_native. The lock resolves mdex 0.14.7 and mdex_native 0.3.2, so all clear. GHSA-3w4f lists mdex `>= 0.3.0` with no upper bound (U: could false-positive a scanner).
6. `handle_params` on `:example` is still impossible on 1.5.0 (V: `story.ex:99`), and it is a LiveView child-view limit, not a storybook bug. Threadline is right; upgrading never fixes it.

## Decisions

### D1. Mount: standalone catalog lane on its own port (confidence 0.8)
- Stories live in `scrypath_ops`, served by its own dev endpoint; **not** host-mounted. Rejected: adding the dependency to the demo host. Reasons: the host would need its own backend, router entries and CSS pairing, `css_path` cannot map to the host's `/admin/search/assets/...` URL (hash lookup is by file under host `priv/static`, V `asset_helpers.ex:19`), and the host's Docker `runtime_test` build is the CI critical path (`ecommerce-mounted` 824 to 1,147 s, V CI-EFFICIENCY 18, 21).
- Placement: `catalog/lib/` (backend module, wrappers) and `catalog/stories/**/*.story.exs`, in `elixirc_paths` for `:dev` and `:test` only. Dependencies compile in `:prod` (ADR 0002), so consumers never see them (`mix.exs:42-43` today).
- Route: extend the existing `OptionalDevRoutes` pattern (`dev_router.ex:4-21`, guard outside the `quote`, V C28) with a `catalog_routes` macro: `Code.ensure_loaded?(PhoenixStorybook.Router)` and `Application.compile_env(:scrypath_ops, :catalog)` (true only in dev.exs and test.exs). Emits `storybook_assets()` plus `live_storybook "/storybook", backend_module: ScrypathOps.Catalog.Storybook` at scope `/` (the macro forbids other scopes, `router.ex:52`). Leave `scrypath_ops_routes/2` untouched.
- Serving: a `catalog` Compose service (`compose.catalog.yaml`, layered over dev) on `127.0.0.1:${CATALOG_PORT:-4003}`; inside the container it must bind 0.0.0.0 (same as `PHX_HOST_IP`), so loopback is enforced by the publish line, and a static test parses the compose file for `127.0.0.1:`. A remote-IP plug would break Docker (gateway address). Separate `_build` volume to avoid contending with the `web` watcher; shared deps volume (U).
- Needs a database or a Repo-less mode: `dev.exs` hardcodes `hostname: "localhost"` (V `dev.exs:5-9`; test.exs honors `PGHOST`). Cheapest: make dev.exs read `PGHOST` like test.exs and give the lane the compose Postgres (U).
- Preview workflow: the catalog does not ride 4002. Add `catalog_url` and `catalog_container` to `UI-PREVIEW.json` and make `ui:preflight` check the container, the `127.0.0.1` publish and source match. Catalog data is code (fixtures), so "preserve seeded data" is automatic. Once the first screen story ships, this URL is the review surface (AGENTS.md).
- Hardening: in the catalog lane set `check_origin` to the two loopback origins (existing dev config is `check_origin: false`, V `dev.exs:24`).

### D2. CSS, themes, JS fidelity (0.7)
- `css_path: "/assets/css/app.css"`, `theme_path`: none (keep the chrome native, accrue lesson). Story code uses only classes production already emits (no new `@source`); if a wrapper needs one, add `@source` to app.css rather than a second sheet.
- `themes: [light, dark, system]`, `themes_strategies: [data_attribute: "theme"]`. A new `assets/js/storybook.js` (second esbuild profile in `config.exs`, gitignored output, built by `assets.build` and the dev watcher) does two things: sets `<html data-theme>` from the iframe URL's `theme` param (light or dark; nothing for system), and sets `window.storybook = {Hooks: {...}}` with the same hook list as the two `app.js` files, so the existing `ops_shell_contract_test.exs:285-290` import regex pattern extends to a third file (J, no refactor of `app.js`). `color_mode: true` is cut (its dark class does not match `[data-theme=dark]`).
- Frame choice: iframe for everything with layout; primitives may stay inline only if the leak check passes. For width and axe checks load `/storybook/iframe/<story>?variation_id=&theme=` or `/storybook/visual_tests/<story>` directly (chrome-free, V router and `visual_tests` source), not the nested iframe. 375 and 1280 are then plain viewport sizes.
- Executable fidelity checks: (a) ExUnit: iframe HTML contains the css and js imports and `data-theme` on body (cheap, runs in `ops-ui`); (b) throwaway local Playwright, not CI: computed `background-color`, `color`, `font-family`, `border-color` of `.ops-header`, `.ops-panel`, `.ops-sidebar` equal between `/ops/health` and the iframe story across 3 themes times 2 OS color schemes; plus a chrome-leak check (sidebar computed styles with and without `css_path`). Probability the leak check fails 0.3 (app.css preflight lands in `app` layer, chrome utilities in a later layer); fallback is all stories in iframes with the chrome unchanged, or the hand harness.

### D3. Story types by tier (0.75)
| Tier | Type | Why |
|---|---|---|
| Primitive, Pattern | `:component`, iframe | variations with `note:` for scenario, actor, job (C36); plain assigns |
| Area, Screen | `:component` wrapping an extracted `*_page/1` in `catalog/lib`, iframe, variation per state | real renderer, view-model from the scenario module, props small (a scenario key, not a struct; large attrs bloat the Source tab and the playground, V `component_renderer.ex:183-217`) |
| Interaction states | `:example` (child LiveView), iframe, one module per state | `mount`, `handle_event`, `assign_async`, streams all work; no `handle_params`; session carries only `theme` (V `component_iframe_live.ex:142`) |
| Flow | not a story | LiveViewTest on the mounted host (C7, C23); a story may only link to it |
| `:page`, `:live_component` | docs-only, else cut | no iframe; ops has no live components (grep 0) |

Component stories render by evaluating generated HEEx with `assigns = %{psb_variation_attrs: attrs}` (V), so there is no socket: async results become `AsyncResult.loading/ok/failed` values, streams become `{dom_id, row}` lists. The one production change this implies (Phase 197): `failed_sync_live` row rendering must accept any enumerable of `{id, row}` (works for streams and lists, J). LiveViews that call `Posture.summary` in mount (control room, V `control_room_live.ex:20-50`) render from a `%Posture{}` struct directly; no Repo is touched.

### D4. The spike (Phase 196), measurements and go/no-go
Already measured here (V, scratch, M-series): `deps.get` 1.4 s; cold `deps.compile` of the whole graph 11.8 s wall; NIF fetch 0.66 s (1.33 MB, `aarch64-apple-darwin`, nif-2.15, `deps.compile` log); storybook-subtree rebuild with a warm NIF cache 7.6 s; `mix hex.audit` clean; resolved mdex 0.14.7, mdex_native 0.3.2, rustler_precompiled 0.10.1, makeup_html 0.2.0. Checksum file for 0.3.2 lists `x86_64-unknown-linux-gnu` and `aarch64-unknown-linux-gnu` (the Docker image on Apple silicon). Hosted baseline for `ops-ui`: lock-changing PR run 508 s total (verify step 469 s); push to main 449 s (397 s) (V, runs 44860899193 and 44862186749). So a cold penalty is already about 70 s; the +3 min trigger means about 650 s cold.

Spike measures and thresholds (all recorded in a dated note, ADR 0001 gets the numbers):
| Check | Go if | Method |
|---|---|---|
| Advisory | none open over 14 days on resolved versions of the 9 packages | `gh api repos/<r>/security-advisories` plus the global query, record dates |
| Cold `ops-ui` | at most baseline cold plus 180 s | first hosted run after the lock change, then a second push for warm; `gh run view --json jobs` step times; warm should be at most plus 60 s (J, the common case) |
| **New: Docker `asset_builder` stage** | at most plus 60 s | `mix assets.build` compiles ops in dev, so the dependency lands on the `ecommerce-mounted` critical path (V `Dockerfile:42`); task-scoped `docker build --target asset_builder` before and after, clean up per AGENTS.md; if over, gate the dep behind an env var the Docker stage sets |
| NIF fetch | 0 failures over the hosted runs, including 2 cold | the boundary test builds fresh graphs per case; set one shared `RUSTLER_PRECOMPILED_GLOBAL_CACHE_PATH` under its scratch root so it downloads once (J); do not add retries until a failure occurs |
| Isolation work | at most 1 working day | the time-box for D2 |
| Prod absence | direct prod and mounted consumers lack `PhoenixStorybook`, `MDEx` and the catalog modules, and `DevRouter` has no `/storybook` route; dev has them | extend `@absent_modules` and probes in `test/release/ops_dependency_boundary_test.exs` (it already builds throwaway consumers per env); `mix hex.build --unpack` is the wrong artifact (ops is unpublished, the root allowlist already has a test, V `dependency_boundary_contract_test.exs:618-700`) |
| Render-all | every story and variation renders through the real router via `live/2` on `/storybook/iframe/...` with no error, no two variations identical | one ExUnit file in `ops-ui`; compile with the default eager mode so a bad story fails `mix compile` (U) |
| Parity | D2 checks pass | local |

**Switch to the hand harness (E2EUIFixtureLive is 86 lines, V; earlier estimate 450 to 650 lines) when any one holds:** two ADR triggers trip; the fidelity fix exceeds one day; the Docker stage cannot be bounded by the env gate; a LiveView or Phoenix bump is blocked by storybook for 14 days; the NIF download fails twice in a required lane after caching. Add the Docker-stage trigger to ADR 0001 (it is a CI-critical-path cost, not a scope change).

### D5. Security (0.8)
The 1.5.0 range is clear (all six advisories patched at 1.1.0, 0.13.2 and 0.2.3, V). Residual: every story render evaluates generated HEEx server-side, and the playground tab is hard-wired (`story_live.ex:293-301`; no config key hides it, V grep of all `config(:` keys), so "disable the playground" is not available. Controls: dev and test only, no prod graph (tested), published on host loopback only (tested), `check_origin` pinned, `:example` stories show no playground tab (J, a reason to prefer them for screen-level interaction). No bind to 0.0.0.0 on the host namespace. CSP: the router passes nonces if configured; the existing dev router sets none, so skip. Keep the default dev router's `put_secure_browser_headers` away from the storybook pipeline only if frame headers ever block iframes (same-origin works today).

### D6. Version pin and Dependabot (0.7)
`{:phoenix_storybook, "~> 1.5", only: [:dev, :test]}`; the lock pins exactly. Leave it in the existing `ops-mix-minor-patch` group: the render-all test makes a breaking bump (it uses LiveView internals `TagEngine.compile`, C2) red in the PR instead of a silent break. Reject an exact pin (mailglass reported tight pins hurt). Update the ledger test label "v1.47 catalog" (V `dependency_boundary_contract_test.exs:618`).

### D7. Cut from the thin start
Playground use and `theme_path`; `color_mode`; `:page` screens; `:live_component`; docs-heavy `doc/0` (keep one line; mdex stays regardless); Igniter installer (hand-write about 5 files); Font Awesome kit; any `storybook.css`; a second manifest. Keep built-in search and the events log (free).

## Adversarial pass
- "css_path = app.css leaks into the chrome": cheapest test is the sidebar computed-style diff above; fallback listed.
- "System mode is wrong after the JS fix": test the 3 themes times 2 `colorScheme` emulations locally.
- "Eager story compile slows `ops-ui`": time `mix compile` delta in the spike; fall back to `compilation_mode: :lazy` plus render-all forcing compile.
- "Hook list drifts a third time": extend the existing contract regex; it fails on mismatch.
- "A separate `_build` volume costs a cold minute per lane": acceptable; measure.
- Early warnings: stories needing `@source` additions, a story needing more than 30 lines of wrapper, `handle_params` wanted for a screen story (then it is a mounted test, not a story).

## Plan implications
Phase 196 is 2 plans: (1) dependency, `catalog/`, route macro, prod-absence and render-all tests, one primitive story and one control-room screen story; (2) JS and theme fidelity, Compose lane, `UI-PREVIEW.json` entry, measurements and the go/no-go note. Cheap order inside: static boundary tests, then `mix compile`, then `verify.ops_ui`. New ledger rows: at most 1 (render-all and route contract; everything else extends existing files). Fixtures (195) must give wrappers a `now`-taking builder and plain structs so 196 needs no Repo.

**For other agents:** the owner of fixtures should expect structs and small scenario keys, not giant attrs; the owner of review process should know the review URL is a separate port, not 4002; the owner of CI should add the `asset_builder` delta and a shared NIF cache path to its watch list.
