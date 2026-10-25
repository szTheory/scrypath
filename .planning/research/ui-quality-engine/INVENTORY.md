# UI quality engine: Phase A inventory (2026-10-25)

Read-only measurements at `8ebeb740`. Paths are relative to the repo root; `ops/` = `scrypath_ops/`, `e2e/` = `examples/scrypath_ecommerce/e2e/`.

## 1. Existing machinery, by methodology layer

| Layer | Verdict | Evidence |
| --- | --- | --- |
| Fractal stories | **NEW** | No `phoenix_storybook` in any `mix.lock`; no gallery route. Closest seam: test-only `/ops/phase173/health` (`ops/lib/scrypath_ops_web/dev_router.ex:31`, `Mix.env() == :test`) feeds `PostureLive` from `ops/test/support/phase173_fixture_source.ex` with 15 scenarios (healthy, failed, unavailable, unknown, empty, partial, long, invalid-time, queue-unused, refresh-failure, refresh-disabled, processing, backend-failed, retrying, completed). Only one of 6 LiveViews has a fixture seam. |
| Persona fixtures | **EXTEND** | One domain: an ecommerce catalog (`examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog_fixtures.ex`, 345 lines; Product/Variant/Category). `lib/mix/tasks/scrypath.demo.seed.ex` (478 lines) seeds 3 tenants (showcase, "Ops Incident Lab", sparse). The `/dev/e2e/seed` scenarios are incident, all_green, degraded and empty. `priv/repo/seeds.exs` is 14 lines. No B2B, SaaS or self-hosted twins, and no realism check. |
| Personas/JTBD | **ADOPT-EXISTING** | `ROLE-INT/OPS/OWNER` and `JOB-01..05`, plus the internal-to-user language map (`.planning/reference/OPERATOR-UI-QUALITY.md`). `e2e/ui-review.mjs:12` maps every surface to a role and its jobs. |
| Token source of truth | **EXTEND** | Authority is `ops/assets/css/app.css` (2,792 lines; daisyUI theme blocks plus `@theme`), cataloged in `ops/assets/css/DESIGN-TOKENS.md` (480 lines), with root `DESIGN.md` (71 lines). `brandbook/tokens/tokens.{css,json}` is a **separate palette** (`--sp-*`; canvas `#FAF7F2` against ops `#f3f5f8`). Nothing imports it, and no test references `brandbook/`, so drift between the two goes unguarded. A stale `DESIGN.md` copy also sits in `.claude/worktrees/ui-experience-reconciliation/`. |
| L1 static | **EXTEND** | ExUnit contracts in `ops/test/scrypath_ops_web/`: `design_tokens_contract_test.exs` (every `-ops-` utility and `var(--…)` is defined, every OpsUi export is cataloged, stacking roles), `surface_depth_`, `shell_chrome_`, `motion_contract_` (transform/opacity only, `--duration-ops-*`), `operator_ia_contract_`, and `ops_a11y_contract_` (DOM semantics, no axe). Contrast: `ops/assets/css/contrast-pairs.mjs` (595 lines, muted-alpha manifest), checked by `examples/scrypath_ecommerce/contrast-checker.mjs` (`make contrast`, under 1s). **Missing:** any ban on hex, arbitrary values or `z-` literals in templates. |
| L2 generic sweep | **EXTEND** | 22 Playwright specs, 1 Chromium project (`examples/scrypath_ecommerce/playwright.config.*`). Viewports: 390×844, 768×900 and 1440×900 (once each: 320 and 1000-high). `helpers/theme-grid.ts` covers only mobile and desktop. Themes are light, dark and system-dark (`ui-review.mjs:26`). axe: `helpers/operator-ui.ts:103` runs `scanNonContrastA11y` (WCAG 2.2 AA tags, contrast disabled), but only from `operator.spec.ts` and `admin_shell_chrome.spec.ts`. `admin_contrast_matrix.spec.ts` gates AA contrast, with AAA as advisory. Overflow check: `helpers/operator-ui.ts:13`. Target size is spot-checked only: 44px in `phase173_shell.spec.ts:71`, 24px in `phase173_time.spec.ts:38` and `ui_baseline.spec.ts:137`. CI: `ecommerce-e2e (advisory)` runs on schedule or dispatch only, with `continue-on-error` (`.github/workflows/ci.yml:329`). |
| L3 screenshots | **EXTEND** | `admin_screenshot_matrix.spec.ts` covers states incident/all-green/results/empty/zero-results/empty-workspace × 3 viewports. `admin-light-baseline.json` is an inventory of 30 file names and widths with **no pixel hashes**. `light-pixel-diff.mjs` uses pixelmatch. No committed PNG baselines (`*-snapshots/` is absent). |
| L4 judge | **REPLACE/NEW** | `e2e/ops-ui-visual-judge.mjs` calls the **paid OpenAI API** (`gpt-4.1`, `api.openai.com/v1/responses`, line 191) on 8 sampled PNGs against `ops-ui-visual-rubric.md`. It is skipped without `OPENAI_API_KEY` and opt-in via `OPS_UI_LLM_JUDGE=1` (`Makefile:206`). That conflicts with the "no paid judge" decision in §6. `ui-review.mjs` is not a judge: it is a provenance and capture harness (git tree sha, Docker mount and main-included checks), producing a manifest of 8 surfaces × 3 themes × 3 widths and a pending human review JSON across 8 dimensions. |
| L5 owner log | **ADOPT-EXISTING** | `.planning/UI-FEEDBACK.md` lists 63 `UI-*` items, all resolved. The `.planning/reference/UI-*.md` set holds 10 docs. `.planning/ui-reviews/` is empty. `.impeccable/config.json` has 1 detector ignore. Prior inventories: `.planning/research/v1.42/UI-{SYSTEM,STRUCTURE,AUTOMATION}.md`. |

## 2. UI inventory (`ops/lib/scrypath_ops_web/live/`)

There are **5 primary nav entries** (`nav.ex`) plus Control Room at `/`. "Playbooks" is not its own surface: `/playbooks` is a legacy route into `SearchLive` (`router.ex:46`), and the UI term is "Saved searches". Each LiveView has **one** `~H` render. Only `failed_sync_live` (6) and `search_live` (1) define private function components.

| LiveView | Lines | Render lines | Distinct OpsUi tags used | Comp calls / raw tags* | Service calls† | Events | Storyability (1 = easiest) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| help_live | 221 | 209 | page_header, heading, icon | 18 / 65 | 0 | 0 | 1 (static) |
| control_room_live | 252 | 136 | verdict, intent_card, empty_state, notice, toolbar, refresh_control, time, link_button | 12 / 12 | 3 (one `%Posture{}`) | 1 | 2 |
| posture_live | 694 | 311 | verdict, trail, badge, config_empty, inline_code, time, help_link | 22 / 58 | 11 | 3 | 3 (fixture seam already exists) |
| failed_sync_live | 1,227 | 379 | status, code_block, modal, handoff, disclosure, button, empty_state | 34 / 43 | 14 | 5 | 4 |
| search_live (+ saved_search_form 226) | 2,062 | 720 | 25 kinds incl. field, text_input, sheet, segmented_control, data_card, result_hit | 59 / 48 | 29 | 28 | 5 (form and async state) |
| sync_drift_live | 2,470 | 544 | section, status, table, schema_select, modal, inline_code (×12) | 52 / 60 | 40; 13 async | 10 | 6 (hardest) |

\*Raw tags counts `div/section/p/span/ul/li/table/h*/…`, a lower bound. †Matches `Repo.|Scrypath.|Posture.|*Observation.|SavedSearches.|SearchPlayground.|Oban`.

Data loading runs synchronously in `mount`/`handle_event` (for example `control_room_live.ex:14-24`), and the copy is computed in `defp`s (193 in sync_drift, 111 in search, 93 in failed_sync). There is no view-model boundary. Component library: `ops_ui.ex` (1,951 lines, 51 `ops_*` exports), `result_ui.ex` (2), `core_components.ex` (`flash`), `layouts.ex` (`app`, `flash_group`, `theme_toggle`).

## 3. Raw values that bypass tokens (`ops/lib`, `ops/assets`)

- **Hex:** 0 in `.ex`/`.heex` LiveView/components. 8 in `controllers/page_html/home.html.heex`, the generator-default dev home page. 57 in `app.css`, of which 56 sit inside daisyUI theme token blocks; 1 is a fallback (`app.css:2575`). 0 in JS.
- **rgb/rgba/oklch literals:** 22 in `app.css`. 16 are `--shadow-ops-*` token declarations (`:2401-2417`); 6 are raw backdrop/shadow literals (`:425,:444,:2213,:2217,:2232,:2237`).
- **Arbitrary values `-[`:** 11 in lib. 8 are `min-[wh]-[var(--control-h-*)]` (token-backed). 3 are in `home.html.heex` (`left-[40rem]`, `xl:left-[50rem]`, `text-[2rem]`).
- **`style=`:** 2 (`ops_ui.ex:766` loading bar widths, `search_live.ex:1355` `display: none`).
- **z-index:** 2 utility literals (`core_components.ex:55` `z-50`, plus `home.html.heex`). 2 CSS `z-index: 1` (`app.css:2070,2582`), and 7 that use `var()`.

## 4. Jargon reaching rendered text (samples)

1. `"Reconcile failed: #{inspect(reason)}"` and `"Retry failed: #{inspect(reason)}"` show raw Elixir terms in flashes (`sync_drift_live.ex:192,1184`, `failed_sync_live.ex:352`). **Not OK.**
2. `control_room_live.ex:235`: `"#{inspect(schema)}: schema health could not be checked (#{inspect(reason)})"`. Same problem.
3. `posture_live.ex:486`: renders `{inspect(mod)}`. That is OK as diagnostic identity, since the language map keeps the module name.
4. `"The expected upsert effect was observed in the active index."` (`sync_drift_live.ex:652`). "upsert" is borderline for operators; "document update" is clearer.
5. "Background sync with Oban" (`posture_live.ex:551,680`) against "Oban background sync" (`sync_drift_live.ex:1716`). The map prescribes "Background sync · Oban", so the wording is **inconsistent**.
6. "backend task" in `sync_drift_live.ex:587-664` and "Search backend not configured" (`control_room_live.ex:135`). The map says to use "Meilisearch task" in the v1 UI.
7. `"Schema allowlist is empty — configure schema_allowlist first."` (`search_live.ex:2040`). That is acceptable setup and error language under the map.
8. `"Partial observation"` / `"Last successful observation"` (`control_room_live.ex:145`). The concept is accurate, but "observation" is internal vocabulary.
9. `"Oban #{queue} ##{id}"` (`failed_sync_live.ex:685`). OK; it is an exact queue-job identity.
10. DESIGN.md says "Sync and drift"; the nav and page title say "Sync and index". The docs are out of sync with the UI.

## 5. Stack versions

From `ops/mix.lock`: Phoenix **1.8.12** (demo 1.8.13), LiveView **1.1.33**, phoenix_html 4.3.0, the `tailwind` hex 0.4.1 with binary **v4.1.12** (`ops/config/config.exs:62`), and esbuild 0.10.0. **daisyUI 5.0.35** is vendored (`ops/assets/vendor/daisyui.js`, plus `daisyui-theme.js`) and loaded with `@plugin`; it is the only plugin. The hex.pm entry for `phoenix_storybook` **1.5.0** (2026-09-15) requires `phoenix ~> 1.8.1` and `phoenix_live_view ~> 1.1.21 or ~> 1.2.0`, so it is **compatible**. It brings non-optional deps `mdex ~> 0.12` (a Rust-NIF markdown library), `makeup_eex` and `makeup_html`, plus optional `igniter` and `jason`.

## 6. Locked decisions that constrain this work

- "No paid visual-judge API calls, new AI service, or recurring model gate by default. Never auto-update a pixel baseline merely to clear a failure." (OPERATOR-UI-QUALITY.md, verification §4). PROJECT.md:394: "no paid judge or new required CI lane."
- "Keep the full screenshot/contrast matrix advisory." (OPERATOR-UI-QUALITY.md, verification §3). The required checks are `core`, `package`, `repository-contracts`, `backend` and `ecommerce-mounted` (ROLLING-ROADMAP.md).
- "Prefer copying a small helper over adding a dependency." and "visible UI changes wait for the maintainer's explicit yes." (ROLLING-ROADMAP.md:8-10). DESIGN.md: "Don't … add a dependency for a pattern that the existing LiveView and component seams already cover."
- "Treat roles as task contexts that may overlap, not fictional demographic personas … no adopter interview … is claimed." and "Do not schedule a recurring persona-gardening ceremony." (OPERATOR-UI-QUALITY.md). This bears directly on the request for persona "digital twins".
- "Do not rename public APIs, internal types, or domain concepts merely to make every screen sound nontechnical." "Saved search" is the UI term; "Playbook" is the API name (language map).
- Brand: palette locked since v1.35. The Space Grotesk font is reserved for Sigra (memory notes). Rubric: "Do not request the retired violet background"; "Don't restore the earlier shell wash" (DESIGN.md).
- Verification: completion needs executable tests or exact-SHA evidence, not human UAT (AGENTS.md). The UI review must run in the checkout the preview mounts, after `npm run ui:preflight` (AGENTS.md, UI-WORKTREE-LEARNINGS.md).
