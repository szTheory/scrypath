# UI quality engine: automation and CI layers (L1–L5)

**Date:** 2026-10-25 · **Branch inspected:** `docs/ui-quality-engine-plan` at `8ebeb740` · **Evidence class:** static inspection, grep counts, and `gh run` job timings. No new test, browser or CI run was performed. Runtime figures for the not-yet-built storybook sweep are estimates and are labelled that way.

**Inputs read:** `AGENTS.md`, `CONTRIBUTING.md`, `.github/workflows/ci.yml`, `OWNER-INTENT.md`, `METHODOLOGY-PROMPT.txt` §5 and the rubric, `.planning/research/v1.42/UI-AUTOMATION.md` (the prior automation study, which this file extends and does not repeat), `.planning/reference/OPERATOR-UI-QUALITY.md`, `examples/scrypath_ecommerce/e2e/{UI-REVIEW.md,ops-ui-visual-judge.mjs,ops-ui-visual-rubric.md,ui-review.mjs,helpers/*}`, `examples/scrypath_ecommerce/{contrast-checker.mjs,docker-playwright.sh,Makefile,playwright.config.ts,package.json}`, `scrypath_ops/assets/{css/app.css,css/contrast-pairs.mjs,css/DESIGN-TOKENS.md,vendor/daisyui.js}`, `brandbook/tokens/*`, `.impeccable/config.json`, and the installed `impeccable` skill.

## 0. Ground truth that shapes everything below

| Fact | Evidence | Consequence |
|---|---|---|
| Tailwind **4.1.12** with vendored **daisyUI 5.0.35** (`themes: false`) plus `daisyui-theme` plugin blocks that hold the literal light/dark hex values | `scrypath_ops/config/config.exs:62`, `assets/vendor/daisyui.js` (`version = "5.0.35"`), `assets/css/app.css:13-110` | Theme colors live in `@plugin` blocks, not in `@theme`. daisyUI registers `bg-base-100` etc. through JS `theme.extend.colors` (`daisyui.js:164`), not the `--color-*` CSS namespace. |
| Static contrast gate **already exists**: `contrast-checker.mjs` (999 lines, zero npm deps) parses both theme blocks from `app.css`, composites muted alpha pairs from `contrast-pairs.mjs`, and has a lockstep guard so every muted `color-mix` must be registered | `examples/scrypath_ecommerce/contrast-checker.mjs:23-25` (node builtins only), `make contrast` | **ADOPT.** But it runs only in the nightly advisory `full` scope (`docker-playwright.sh:57`), not in any required lane. |
| Browser contrast matrix (axe `color-contrast` only) and a non-contrast axe helper exist | `e2e/admin_contrast_matrix.spec.ts`, `e2e/helpers/operator-ui.ts:103` (`scanNonContrastA11y`, tags wcag2a/2aa/21a/21aa/22aa, records `incomplete` but asserts only `violations`) | **EXTEND.** |
| No pixel baselines are committed; `toHaveScreenshot`, `toMatchAriaSnapshot` are not used anywhere | grep over `e2e/` | L3 is **NEW**; the screenshot matrix and `admin-light-baseline-check.mjs` are evidence and inventory, not regression gates. |
| Brandbook tokens are **not** DTCG-conformant and **have drifted** from the shipped theme | `brandbook/tokens/tokens.json` uses bare strings (no `$value`/`$type`), claims to be "mirrored from the live scrypath_ops daisyUI theme", yet light `surface #FFFDF8` vs live `--color-base-100: #ffffff`, dark `bg #0C0F14` vs live `--color-base-200: #111419` | The token single source of truth is **NEW work**, and the first drift test would fail today. The live ops theme moved to a cool-neutral floor on purpose (`ops-ui-visual-rubric.md`: "Light mode uses the current cool neutral floor… Do not request… copper/cream halos"). |
| Required-lane critical path is `ecommerce-mounted` ≈ **4 m 16 s**; the other required jobs take ≈ 25–55 s; `ops-ui` (path-scoped) ≈ 2 m | `gh run view` on main run of 2026-10-25 | PR UI checks must fit **≤ 5 min wall** to avoid lengthening the train. |
| The nightly `ecommerce-e2e` takes ≈ 12.6 min and **failed** on the last scheduled run (2026-10-25 06:55 UTC) | `gh run view` (schedule) | Fix nightly red before adding lanes. Otherwise advisory noise trains everyone to ignore it. |
| Public repo, so standard-runner minutes are free | `gh repo view` → `PUBLIC` | The cost that matters is **wall time and flake rate**, not billed minutes. |
| Existing judge calls the **paid OpenAI Responses API** (`gpt-4.1`, `OPENAI_API_KEY`), off by default; `--mock` writes an assumed pass | `ops-ui-visual-judge.mjs:12,160-200,138-155` | L4 must be **replaced** (see §4). |
| Owner rule: the glossary is "a decision aid, not a blind find/replace glossary"; precise technical terms stay when the user must act on them | `.planning/reference/OPERATOR-UI-QUALITY.md:47,63` | The L2 text lint must be a narrow **denylist of decided terms**, not a vocabulary whitelist. |
| Owner rule: "don't mask whole status cards or data regions to make diffs green"; "Do not freeze today's disputed palette as an approved golden" | `e2e/UI-REVIEW.md` §Bounded repair | L3 stability must come from fixed fixtures and clock, not masking. Baselines are seeded only after a section passes review. |

## 1. L1 static checks (blocking, run in `repository-contracts`)

### 1a. Tailwind namespace reset: partial, colors only

Tailwind v4 drops a default namespace with `--color-*: initial` inside `@theme` (https://tailwindcss.com/docs/theme#overriding-the-default-theme). Feasibility per namespace:

| Namespace | Current default-utility use in `lib/scrypath_ops_web` | daisyUI dependency | Verdict |
|---|---|---|---|
| `--color-*` | **0** default-palette utilities (`bg-red-500`, `text-white`, …) | daisyUI colors come from JS `theme.extend.colors`, which still applies after the reset. One daisyUI rule references `var(--color-black)` (`daisyui.js`, `color-mix(in oklab, var(--color-black) 30%, transparent)`) | **DO IT.** Add `--color-*: initial;` and re-declare `--color-black: #000; --color-white: #fff;`. Verify by diffing the built `priv/static/assets/css/app.css` before and after (expect only the dropped palette vars) and by running `contrast-checker` plus the contrast matrix once. |
| `--spacing` (single multiplier) | ≈ 140 (`gap-*` 46, `mt-*` 32, `space-y-*` 25, `px/py` 26, …) | daisyUI component CSS uses its own `--size-*` with fallbacks | **NOT NOW.** Ratchet instead (1c). |
| `--text-*`, `--leading-*`, `--font-weight-*`, `--tracking-*` | ≈ 110 (`text-*` 52, `font-*` 41, `leading-*` 13, `tracking-*` 3) | n/a | **NOT NOW.** The L2 computed-style check catches off-scale results at render time. `text-sm` = 0.875rem = `--text-ops-body`, so many uses already resolve to token values. |
| `--radius-*`, `--shadow-*` | `rounded-*` 4 | daisyUI uses `--radius-selector/field/box` (separate) | Feasible after 4 fixes. Leave for one later ratchet step. |
| z-index | n/a: v4 has no default z namespace; `z-50` is a bare-value utility, so no reset can remove it | — | Ban by grep (1b). `--z-index-ops-*` already drives the `z-ops-*` names (`app.css:175-182`, `design_tokens_contract_test.exs:121`). |

### 1b. Source bans with a ratchet baseline (current counts)

| Rule | Scope | Count today | Where |
|---|---|---|---|
| Arbitrary values `-[…]` | `lib/scrypath_ops_web/**/*.{ex,heex}` | **11** | 8× `min-h/min-w-[var(--control-h-*)]` (`layouts.ex:427,440,453`, `ops_ui.ex:974,1175`); `left-[40rem]`, `xl:left-[50rem]`, `text-[2rem]` in `controllers/page_html/home.html.heex` |
| Arbitrary var shorthand `-(--…)` | same | 0 | — |
| Inline `style=` | same | **2** | `ops_ui.ex:766` (`loading_bar_width`), `search_live.ex:1355` (`display: none`) |
| Raw hex/rgb in templates | same | **8** | all in `home.html.heex` (the Phoenix generator landing page, dev router only: `dev_router.ex:22`) |
| `z-<n>` / `z-[…]` | same | **2** | `core_components.ex` `z-50`, `home.html.heex` `z-0` |
| Raw hex/rgb in **non-custom-property** CSS declarations | `assets/css/app.css` | **3** | `app.css:2213,2232` (`rgba(0,0,0,.46)` shadows), `:2661` (`#000` fallback) |
| Literal `z-index: <n>` in CSS | `app.css` | **2** | `:2070`, `:2582` (`z-index: 1`) |
| Literal durations not via `var(--duration-ops-*)` | `app.css` | ≈ 4 | grep `transition|animation … \d+m?s` |
| Literal `font-size` / `border-radius` in CSS | `app.css` | 2 / 5 | — |

Recommendations:
- One ExUnit contract test in `scrypath_ops/test/scrypath_ops_web/` beside `design_tokens_contract_test.exs`, plus `ui-l1-baseline.json`, a `{rule, file} → count` map. It fails when a count rises, or when a count falls without the file being lowered (this locks in gains). Elixir rather than Node keeps it inside `mix verify.ops_ui` and the existing contract style.
- Allowed exceptions are structural, not ad hoc. `style=` may set only custom properties (`style={"--bar-w: #{w}%"}`). `var(--control-h-*)` arbitrary values become named utilities. Hex is allowed only in declarations whose property name starts with `--` (the token blocks).
- **Delete `home.html.heex` and its PageController route** (the generator leftover). That removes 12 of the 23 template violations, leaving a baseline of about 11 that a single PR can clear.

### 1c. Static contrast matrix: ADOPT, then promote

- **ADOPT** `contrast-checker.mjs` + `contrast-pairs.mjs` as-is. It covers both themes, 4.5:1 text / 3:1 large and UI, and sRGB alpha compositing that matches axe (WCAG 1.4.3 https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html, 1.4.11 https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html).
- **Promote** it to the required `repository-contracts` job as one step: `node examples/scrypath_ecommerce/contrast-checker.mjs`. `ubuntu-latest` ships Node, the checker has no npm deps, and it takes under 1 s. Adopters still need no Node.
- **EXTEND** with focus-ring pairs: `--color-primary` outline against each of `base-100/200/300` and `--ops-surface-*` at 3:1, in both themes. Today's global `:focus-visible` outline is at `app.css:227`.

### 1d. Token single source of truth and drift test: NEW, with a decision

- **Decision (recommended):** for Ops values, the source of truth is a real DTCG file: `brandbook/tokens/tokens.json` rewritten to the DTCG format with `$value`/`$type`, groups, and `{alias}` references (https://www.designtokens.org/tr/drafts/format/). Add an **`ops` group with `light` and `dark` sets mirroring today's `app.css`**, because those values passed the contrast gates. Brand primitives (paper, canvas, copper) stay a separate group, so the brand palette itself doesn't change.
- **Check, don't generate.** The `@plugin "daisyui-theme" { … }` blocks need literal values and cannot import JSON. A generator would add a build step that adopters' copy-paste themes do not have. An ExUnit drift test parses both theme blocks and `@theme` from `app.css` and compares them with `tokens.json`. The checker's theme parser (`contrast-checker.mjs:116`) is the reference logic to port.
- Fix the false "mirrored from the live theme" note in the same PR. This is **owner-visible** in the brandbook. It records the shipped state and does not change identity, so it can be decided without a strategic fork. Do say so in the PR.

## 2. L2 generic sweep (one spec over the story manifest)

### 2a. Assertions (exact)

The suite runs on the bare storybook iframe route per variation, plus a short `composed_routes` list that **replaces** `theme-grid.ts` `SCENARIO_CAPTURES`, so there is no third route catalogue (per the v1.42 study).

| # | Assertion | Implementation | Primary source |
|---|---|---|---|
| A1 | No console `error` or `pageerror` | `page.on("console")`, `page.on("pageerror")`. Allowlist only by decisions-log entry | — |
| A2 | No page-level horizontal overflow | `documentElement.scrollWidth ≤ clientWidth + 1` and the same for `body`, at **every** width. Element-level overflow is allowed inside an element that is a labelled scroll region (`role=region` + name, `overflow-x:auto`); data tables and code are the WCAG-recognised 2-D exception | 1.4.10 https://www.w3.org/WAI/WCAG22/Understanding/reflow.html |
| A3 | axe `wcag2a, wcag2aa, wcag21a, wcag21aa, wcag22aa`, **including** `color-contrast`; `violations` = fail; `incomplete` = finding fingerprinted into the ratchet baseline (new ones fail) | `AxeBuilder.withTags(...)` (https://github.com/dequelabs/axe-core/blob/develop/doc/API.md#options-parameter). Note the existing helper omits `wcag21a` from the prompt's list but already includes it; keep it | axe docs; https://playwright.dev/docs/accessibility-testing |
| A4 | Targets ≥ 24×24 CSS px **or** the 24px-circle spacing exception; inline-in-text links exempt | **Use axe's `target-size` rule first** (tag `wcag22aa`; it implements the spacing and inline exceptions). Write a custom check only if axe misses a measured case. A naive "every control ≥ 24px" check false-fails dense tables | 2.5.8 https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html |
| A5 | No clipped text at 200% root font size | Set `html{font-size:200%}`, then (a) flag any text element whose computed font-size did **not** double, which means px-locked text; (b) flag any element with a text node where `scrollWidth>clientWidth+1` or `scrollHeight>clientHeight+1` and `overflow∈{hidden,clip}`, `text-overflow:ellipsis` or `line-clamp`. Approved truncation needs a `data-truncate` attribute plus a decisions-log id **and** a full-text exposure (title, tooltip or disclosure) | 1.4.4 https://www.w3.org/WAI/WCAG22/Understanding/resize-text.html |
| A6 | Computed values ∈ token set | The token set is resolved **at runtime** from the built CSS: a probe element sets each `var(--text-ops-*)`, `--radius-ops-*`, `--radius-{selector,field,box}`, `--shadow-ops-*`, `--z-index-ops-*` and `--duration-ops-*` and reads them back, once per theme. Checked: `font-size`, `line-height`, `font-family` (3 roles), `border-*-radius` (also allow `0`, `inherit`, ≥ 9999px pill), `box-shadow` (allow `none`, a token, or a comma-join of tokens such as focus + elevation), `z-index` (positioned elements only, `auto` allowed), `transition-duration` / `animation-duration` (`0s` allowed). **Blocking:** font-size, font-family, z-index. **Advisory and baselined first:** radius, shadow, duration (see §7) | — |
| A7 | Focus: a tab-walk (cap 30 stops) changes something visible on each stop; the indicator meets 3:1 against its adjacent background; it is **not entirely obscured**; and the order is sensible | Per stop: diff computed `outline-*` / `box-shadow` focused vs blurred (it must change); contrast of `outline-color` against the nearest opaque ancestor background ≥ 3:1; `elementFromPoint` at the centre and corners must hit the element (catches the sticky header); no `tabindex>0`. **Visual-order monotonicity is advisory** | 2.4.7 https://www.w3.org/WAI/WCAG22/Understanding/focus-visible.html, 2.4.11 https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum.html, 1.4.11. **Correction to the prompt:** the 3:1 indicator requirement comes from 1.4.11 (and AAA 2.4.13 https://www.w3.org/WAI/WCAG22/Understanding/focus-appearance.html), not 2.4.11 |
| A8 | Navigation ARIA snapshot identical on every **page-level** story and composed route | `locator("nav[aria-label=…]").ariaSnapshot()`, normalised by stripping `[current]` / `[selected]` / `[expanded]`, because the active item legitimately differs. Compare within a width class (drawer below `lg`, sidebar above). Store one golden per class with `toMatchAriaSnapshot` | https://playwright.dev/docs/aria-snapshots |
| A9 | Rendered text and accessible-name lint | Collect `innerText` of `main` plus `aria-label`, `title`, `placeholder`, `alt`. Rules: (a) **denylist** of internal terms that the decisions log has explicitly rejected (starts empty; owner rule §0); (b) no `Oops` and no `!` inside `[role=alert]` or error-tone regions; (c) buttons start with a verb from a maintained list, with a decisions-log escape; (d) sentence case for headings and buttons, with an acronym and proper-noun allowlist (Meilisearch, Oban, Ecto, ID, URL) | rubric item 6 |
| A10 | Reduced motion | One extra pass per **motion-flagged** variation with `reducedMotion:"reduce"`: every computed `animation-duration`/`transition-duration` ≤ 0.01s or the element is static. The existing `@media (prefers-reduced-motion: reduce)` block is at `app.css:2185` | https://playwright.dev/docs/emulation#reduced-motion |

Every finding row carries `{story_id|route, variation, width, theme, motion, rule, selector-by-role, fingerprint}`. That keeps each finding reproducible as URL + viewport + theme + motion setting.

### 2b. Widths

Use **{320, 390, 768, 1280, 1440}** rather than 375. 320 is the WCAG reflow floor and covers anything 375 would catch. 390 keeps continuity with `theme-grid.ts` `VIEWPORTS.mobile` and `ui-review.mjs`, so old and new evidence stay comparable.

### 2c. Cost model (estimate, not measured)

Measure on the first 20 stories and replace these numbers.

- Load **once per theme** and resize in place (`setViewportSize`). Width-independent checks run at a subset of widths: axe at 320 and 1280; tab-walk and A6 at 1280 (plus 390 for tab-walk when a drawer exists); zoom at 1280. A2, A4 and A5-overflow run at all 5 widths.
- That is roughly 0.4 s load + 5×0.1 s geometry + 2×0.4 s axe + 0.6 s tab-walk + 0.3 s zoom + 0.2 s styles and text, about **2.7 s per variation-theme**, so about **5.4 s per variation**.
- The storybook is DB-free and stateless, so unlike the existing serial suite (`workers: 1`, which exists because of shared DB and Meilisearch), it can run `fullyParallel` with **3 workers** on a 4-vCPU public runner.

| Variations | Worker-time | 1 runner × 3 workers | 4 shards (`--shard=i/4`, https://playwright.dev/docs/test-sharding) |
|---|---|---|---|
| 150 | ≈ 13.5 min | ≈ 4.5 min | ≈ 1.2 min + boot |
| 300 | ≈ 27 min | ≈ 9 min | ≈ 2.3 min + boot |
| 400 | ≈ 36 min | ≈ 12 min | ≈ 3 min + boot |

Boot (setup-beam with deps/_build cache + compile + tailwind + cached Chromium) is about 1.5 min. **No Docker, Postgres or Meilisearch is needed**, which is the main saving over `ecommerce-mounted`.

### 2d. PR-blocking versus nightly

- **New required job `ops-ui-sweep`**, budget **≤ 5 min wall**. It is path-scoped like `ops-ui-path` but also triggers on `examples/scrypath_ecommerce/e2e/**` and the manifest.
  - **Tier S (always):** the default variation of every story × {light, dark} × {320, 1280}, A1–A9. About 100 stories gives ≈ 2 min on one runner.
  - **Tier C (changed):** the full 5-width matrix for variations whose manifest `sources` intersect the diff.
  - **Shared-surface escalation:** when `app.css`, `tokens.json`, `core_components.ex`, `ops_ui.ex`, `layouts.ex` or a manifest-declared shared component changed, run the full matrix as **4 shards**, each ≤ 4 min wall.
  - The job should not join the formal required set until it has a two-week flake-free record (§7).
- **Nightly (`ecommerce-e2e` schedule or a sibling job):** the full matrix, plus composed routes against the real mounted host (Docker, as today), plus the L3 compare. Upload the findings JSON as an artifact.
- Keep `ecommerce-mounted` unchanged. It proves the mounted, real-backend seam, which stories cannot.

### 2e. Helpers to reuse (`examples/scrypath_ecommerce/e2e/helpers/`)

| Helper | Reuse |
|---|---|
| `operator-ui.ts` `assertOperatorGeometry` | Port its overflow logic for A2, generalised from `#ops-main` to the story root. Keep the essential-control reachability and overlap check for page stories |
| `operator-ui.ts` `assertReadableControl` | A6 font floor and A4 fallback |
| `operator-ui.ts` `assertDialogCycle` | Dialog and palette stories. A7 generalises it into a bounded walk |
| `operator-ui.ts` `scanNonContrastA11y` | Extend for A3: add `color-contrast`, return results, and fingerprint `incomplete` |
| `theme-grid.ts` `THEME_MODES`, `themeSlug`, `assertSystemDarkInvariants` | Theme axis. Keep **system-dark** in the composed-routes list only, because it exercises a distinct cascade (`app.css:120-128`) |
| `e2e.ts` `waitForLiveConnected` | Parametrise the selector. The storybook iframe has its own LiveView socket, and `[data-phx-main]` / `window.liveSocket` may differ there |
| `ui-review.mjs` (capture recipe: `fonts.ready`, `reducedMotion`, `animations:"disabled"`, source fingerprint) | L3 and L4 capture, sourced from the manifest instead of its fixed 8 screens |
| `contrast-checker.mjs` theme parser | Token-set and drift parsing reference |

## 3. L3 screenshots

- **What exists:** no compared baselines. `admin_screenshot_matrix.spec.ts` captures 40 shots as evidence. `admin-light-baseline-check.mjs` checks file names and widths only. `light-pixel-diff.mjs` is a historical zero-diff Phase 130 tool. `admin_shell_wash.spec.ts` samples pixels as an invariant.
  - **Retire** `light-pixel-diff.mjs` and `admin-light-baseline-check.mjs` plus `admin-light-baseline.json` once L3 lands; the latter's name invites misreading (UI-REVIEW.md already warns about this).
  - **Fold** the 10 seeded states of `admin_screenshot_matrix` into stories.
  - **Keep** `admin_shell_wash` as a computed-pixel invariant.
  - **Keep** `ui-review.mjs` as the agent and owner evidence capture, fed by the manifest.
- **Set:** one key state per section × {390, 1440} × {light, dark}, plus one worst case per section. About 6 sections gives roughly 30 shots, under 1 min.
- **Stability recipe:**
  - Render only inside the pinned image `mcr.microsoft.com/playwright:v${PLAYWRIGHT_VERSION}-noble`, which `Dockerfile.e2e:3` already uses (https://playwright.dev/docs/docker). That makes **one platform baseline (linux-chromium)**: `snapshotPathTemplate: "{testDir}/__screenshots__/{projectName}-{platform}/{arg}{ext}"`. Refuse `--update-snapshots` outside the container through an env guard, so macOS baselines never get committed.
  - Use `deviceScaleFactor: 1`, a fixed viewport and `reducedMotion: "reduce"`, and `toHaveScreenshot({ animations: "disabled", caret: "hide", scale: "css" })` (https://playwright.dev/docs/test-snapshots).
  - `await document.fonts.ready`, then assert `document.fonts.check("14px Inter")` and the display and mono faces, which are self-hosted woff2 with no network.
  - Pin time with `page.clock.install({ time: FIXED })` (https://playwright.dev/docs/clock) and use fixture timestamps. Per UI-REVIEW.md, no masking of data regions; `mask` only for genuinely random output, and DB-free stories should have none.
  - Inject `stylePath` CSS hiding the topbar progress bar and the LiveView loading classes.
  - Screenshot the story root element, not `fullPage`.
  - Tolerance: `maxDiffPixelRatio: 0.001`, with the default `threshold` of 0.2.
- **Accepting diffs without UAT:** a diff fails the job and uploads expected, actual and diff images. The agent regenerates the baselines in the container and commits them **with a decisions-log entry** (`verdict: accepted-baseline`, reason, PR). GitHub's PNG diff view in the PR is the evidence. The owner's existing "visible UI waits for yes" merge decision (rolling roadmap) is the only human touchpoint, so no separate UAT step is added. Seed baselines only **after** that section's rubric review, to respect "don't freeze a disputed palette".
- **Placement:** nightly advisory first. Promote into `ops-ui-sweep` after **14 consecutive nightly runs with 0 spurious diffs**.

## 4. L4 LLM judge (advisory, never gating)

**Today:** `ops-ui-visual-judge.mjs` sends 8 hard-coded screenshots plus the rubric to `https://api.openai.com/v1/responses` (model `gpt-4.1`). It is enabled only with `OPS_UI_LLM_JUDGE=1` and `OPENAI_API_KEY`, and it returns schema JSON (`status` pass/needs_review, findings with severity, claim_verdicts). `--mock` writes `status:"mock"` with an assumed pass. It is wired into `docker-playwright.sh` `full` scope, `make verify-shell-wash`, and `test/mix/tasks/workflow_wiring_test.exs:413`.

**Recommendation:**
1. **Retire the paid path.** Delete the `fetch` and OpenAI code, the `OPS_UI_LLM_JUDGE*` branches in `docker-playwright.sh` and the Makefile, and update `workflow_wiring_test.exs`. Keep `JUDGE_SCHEMA` and `ops-ui-visual-rubric.md` as the seed of the new judge (reuse, don't build a second one).
2. **New agent-run project skill** at `.agents/skills/ops-ui-judge/SKILL.md` (AGENTS.md "Project Skills" location; copy-paste, no dependency). Invoked on demand in a session with **one bounded pass**: no critic loop, no retries, and a fixed input set.
   - **Inputs:** L3 or ui-review captures at 390 and 1440 in light and dark, the nav ARIA snapshot, rendered text, `DESIGN.md`, `OPERATOR-UI-QUALITY.md` (roles, jobs, language), the variation's persona + JTBD, the L1–L3 findings JSON, and the decisions log.
   - **It must not report** anything an L1–L3 rule id owns. It checks its output against the L2 rule list and drops overlaps.
3. **Verdicts:** `pass | fail | n/a` per rubric item, each with evidence (a capture id plus what is visible) and owner tier (`token|primitive|pattern|section|page|copy`). No 0–4 or 1–10 scores.
4. **PR mode (pairwise):** capture head and the merge-base (`git worktree` at `origin/main`) with the same manifest subset. Ask per item "A better / B better / tie" twice, with **A=head, B=main and then swapped**. Keep only order-consistent verdicts and report "inconsistent" as no-signal. This is the standard position-bias mitigation; see Zheng et al. 2023, *Judging LLM-as-a-Judge* (https://arxiv.org/abs/2306.05685). **Milestone mode:** one pointwise full audit.
5. **Pinning:** the findings file records the session model id, a `prompt_version` (SHA-256 of SKILL.md plus the rubric), and the source fingerprint. The model can't be pinned the way a CI dependency can, so it is recorded instead and calibration is re-run when it changes.
6. **Calibration set:**
   - **Positives:** labelled positives come from `.planning/UI-FEEDBACK.md` (269 lines of owner feedback) and owner-directed fix commits (`#91`, `#102`, `#105`, `#106`, `#109`; `git log --grep=feedback`).
   - **Captures:** reconstruct parent and fix captures once with `ui:review` in a disposable stack (the storybook didn't exist at those SHAs).
   - **Negatives:** the `.impeccable/config.json` `ignoreValues` entries and decisions-log rejections.
   - **Metrics:** per-item precision and FPR. **Demote an item to owner-only** when precision < 0.7 or FPR > 0.2 over ≥ 10 labelled examples. `.planning/ui-reviews/` exists but is empty.
7. **Impeccable as basis:** use `impeccable` `critique`'s Assessment A lenses (design specificity, hierarchy, cognitive load) as the rubric vocabulary, **but replace its Nielsen 0–4 scoring with binary verdicts**. Use `impeccable detect --json` (deterministic and local) as an *input*, not a CI gate: it lives in the user's skill install, not the repo, so CI can't rely on it.

## 5. L5 decisions log

- **File:** `examples/scrypath_ecommerce/e2e/ui-decisions.jsonl`. It sits next to its consumers (L2 suppression, L3 acceptance, judge calibration); `.planning/` keeps only summaries. **Fold** `.impeccable/config.json` `ignoreValues` into it, since that file is already a decisions log with reason and createdAt.
- **Row:** `{id, fingerprint, layer, rule, scope (story|route|glob), verdict (accept|reject|wontfix|accepted-baseline|rule), reason, reason_tag, decided_by (owner|agent+owner-quote), date, source (PR/commit), promoted_to (test path + rule id | null), revisit_by?}`.
- **Fingerprint:** `sha256(layer|rule|story_or_route|role-name selector path|width_class(narrow<768≤wide)|theme)`. Width classes, not exact widths, so one decision covers 320 and 390.
- **"Decided twice becomes a rule":** an L1 ExUnit check fails when **two or more** rows share `rule` + `reason_tag` with `verdict ∈ {reject, accept}` and `promoted_to: null`. The message names the rows and tells the agent to promote them to an L1 or L2 rule or a calibration example. Example: the sibling-repo "label long enough to truncate is a naming smell" becomes an A5 rule plus a deleted story state.
- A `reject` suppresses future reports with the same fingerprint. An `agent` decision without an owner quote cannot suppress, so an agent can't simulate the reviewer (AGENTS.md).

## 6. Rubric tags

Primary owner of each verdict is listed first. Machine checks set floors; they never certify taste.

| # | Item | Tag | Machine part |
|---|---|---|---|
| 1 | Light and dark both good, not tacky | **owner** · LLM · machine | Contrast matrix, colors ∈ tokens (by the namespace reset), system-dark invariants |
| 2 | Typography intentional | **LLM** · owner · machine | A6 font-size, line-height, family ∈ scale; A5 px-locked text |
| 3 | Hierarchy elegant | **LLM** · owner | axe heading-order, one h1 (`ops_a11y_contract_test.exs`) |
| 4 | Nothing redundant | **LLM** · machine (advisory) | The same ≥ 24-char text block appearing twice in `main`; two controls with the same accessible name and different targets |
| 5 | JTBD happy path great, power users served | **owner** · LLM | Journey e2e (`operator.spec.ts`) proves function only |
| 6 | Microcopy consistent, in voice | **machine** (mechanical rules A9) · LLM (voice, consistency) | Denylist, verb-first, sentence case, no Oops/! |
| 7 | Personas and JTBD curated | **owner** · machine | A manifest lint requires every variation to cite `ROLE-*`/`JOB-*` ids from `OPERATOR-UI-QUALITY.md` |
| 8 | Coherent journey, natural navigation | **LLM** · owner · machine | A8 nav snapshot identity; the composed journey in `ecommerce-mounted` |
| 9 | Mobile-first at 320, comfortable targets | **machine** | A2, A4, A5, A7 at 320 and 390 |
| 10 | Least surprise, one pattern per job | **LLM** · machine (advisory) | A component census flags raw `<button class="btn …">` and table markup outside the `ops_ui.ex`/`core_components.ex` primitives |

## 7. Adversarial pass

| Risk | Why it bites here | Mitigation (decided) |
|---|---|---|
| **Flakiness** in geometry after resize | LiveView patches, transitions and the topbar can move layout mid-measure | Use reduced motion plus an injected `*{transition:none!important;animation:none!important}` for geometry passes. Wait for the socket (parametrised `waitForLiveConnected`) and for `fonts.ready`. Run retries: 0 and count a retry pass as flaky, per CONTRIBUTING. The flake budget is 0 over 14 nights before the job becomes required |
| **CI wall time** | 400 variations × 10 combos | Load once per theme, put checks on subsets of widths, tier S/C plus 4-way sharding, DB-free host, no Docker on PR. Measure after 20 stories and re-budget |
| **axe `incomplete` noise** | `color-contrast` returns incomplete for gradients, pseudo-elements and overlap. The shell has had wash and glow effects | Incomplete findings are fingerprinted into the baseline. Only *new* ones fail. Each existing one needs a decisions-log reason within a milestone |
| **Over-asserting design (A6)** | Legit cases: UA `<code>`/`<kbd>` sizes, daisyUI internal radius vars, focus + elevation multi-shadows, `rounded-full`, reduced-motion `0.01ms`, inherited values, SVG | The token set is resolved from built CSS (not hand-listed). Composites are allowed. Only font-size, family and z-index are blocking at first; radius, shadow and duration stay advisory until their baseline is empty. Exempt `svg *` and `[data-third-party]`. Any new exemption needs a decisions-log row |
| **Target-size false positives** | Dense tables, inline links, the keycap hint | Use axe `target-size` (implements the spacing and inline exceptions) before any custom check |
| **Glossary lint fights owner policy** | Owner: "not a blind find/replace glossary" | Denylist only; starts empty and grows from decisions |
| **Ratchet fatigue** | Baselines that never shrink become wallpaper | Mostly small baselines today (≈ 11 template rows after deleting `home.html.heex`, plus 3 CSS rows). Clear them in the first PR. A baseline row requires a decision id. A per-milestone "baseline must shrink or justify" step goes into the closeout attestation |
| **Static ban on default utilities would churn ~250 classes** | spacing, text and font defaults are used widely | Don't ban them; A6 judges the rendered value. Reset only the colors |
| **Story/app divergence** | Stories pass while the mounted app breaks (host CSS, app.js hooks: see memory on host-app hook registration) | Keep the composed-routes list on the mounted host nightly and `ecommerce-mounted` on PRs |
| **Nightly already red** | Last scheduled `ecommerce-e2e` failed | Gate step 0: restore green, or explicitly quarantine with an issue, before adding L2 or L3 |
| **Judge sycophancy / position bias** | Agents tend to confirm the hypothesis they are handed | Pairwise both orders, binary verdicts, calibration demotion, no L1–L3 overlap, never gating, and no agent self-approval in the decisions log |
| **Token drift test fails on day one** | The brandbook has already diverged | Land the DTCG `ops` group mirroring the live values and fix the README claim in the same PR as the test |

## 8. One-shot recommendations (ordered)

1. Fix or quarantine the red nightly `ecommerce-e2e`.
2. **L1 PR (no storybook needed):** add `--color-*: initial` with `--color-black`/`--color-white` re-declared, after a built-CSS diff; delete `home.html.heex` and its dev route; clear the remaining arbitrary-value, `style=`, `z-50` and CSS-literal rows. Add an ExUnit ban test with `ui-l1-baseline.json`, and run `node contrast-checker.mjs` in `repository-contracts` with focus-ring pairs added.
3. **Token SSoT:** a DTCG `tokens.json` with an `ops` light/dark group equal to `app.css`, plus an ExUnit drift test and the corrected brandbook note.
4. **L2 `ops-ui-sweep`** once the manifest exists: assertions A1–A10, tiers S/C, 3 workers, sharding, a ≤ 5 min wall budget, and the full matrix nightly. Composed routes replace `SCENARIO_CAPTURES`.
5. **L5** `ui-decisions.jsonl` with the "decided twice" check, folding in the `.impeccable` ignores.
6. **L3:** about 30 element screenshots in the pinned container with one linux baseline, nightly first and promoted after 14 clean nights. Retire `light-pixel-diff.mjs` and `admin-light-baseline-check.mjs`.
7. **L4:** delete the OpenAI judge path and add the `.agents/skills/ops-ui-judge` bounded pairwise skill, calibrated from `UI-FEEDBACK.md` and fix commits.

**Owner input genuinely needed:** none strategic. Two things should be confirmed in the PR description, not ahead of time: (a) the brandbook token file gets an `ops` group and its "mirrored" claim is corrected; (b) the paid OpenAI judge is removed rather than kept as an option.
