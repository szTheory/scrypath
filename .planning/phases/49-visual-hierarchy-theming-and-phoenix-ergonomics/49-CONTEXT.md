# Phase 49: Visual hierarchy, theming, and Phoenix ergonomics - Context

**Gathered:** 2026-04-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **OPSUX-03**, **OPSUX-04**, and **OPSUX-05** for **v1.11** on all **`/ops`** LiveViews: **scan-friendly hierarchy** (title → primary → secondary), **system / light / dark** theming that is readable on first load and persists sensibly, and **Phoenix-idiomatic** shell behavior (layouts, flash, titles, navigation primitives) **without** duplicating Phase **48** IA contracts or preempting Phase **50** accessibility / CI semantics.

**In scope (requirements):**

- **OPSUX-03:** **`/ops/posture`**, **`/ops/failed-sync`**, **`/ops/sync-drift`**, **`/ops/search`** share a **consistent page structure** and visual vocabulary so operators can scan lists, rollups, and warnings in **light and dark**.
- **OPSUX-04:** **System, light, dark** end-to-end (first paint, persistence, OS preference when system), readable contrast, borders, and focus treatment on **`/ops`**.
- **OPSUX-05:** UI patterns follow **conventional Phoenix LiveView** expectations; fix **stray default shell**, duplicate titles, unclear errors, and navigation/layout inconsistencies called out in audit — **not** WCAG-deep work reserved for Phase **50**.

**Out of scope:** New write-side recovery semantics; **landmark / heading-order / aria** hardening beyond incidental fixes (**Phase 50**); new **IA** assertions duplicating **`operator_ia_contract_test`** / **`mix scrypath_ops.check_nav_contract`** (**Phase 48** owns nav list, labels, order).

</domain>

<decisions>
## Implementation Decisions

### Shared `/ops` page scaffold (OPSUX-03)

- **D-01 (Hybrid scaffold):** Keep **`Layouts.app` (`shell: :ops`)** responsible for **global chrome only** (logo link, **`Nav.primary/0`**, **`theme_toggle`**, outer padding, **`flash_group`**). Introduce a **small set of function components** (e.g. in **`CoreComponents`** or a dedicated **`OpsUi`** module) implementing **`ops_scaffold`** / **`ops_page_header`** / **`ops_panel`** so each LiveView composes **title → primary panel → optional secondary detail** **inside** `inner_block` — not a mega-template (avoid assign explosion across heterogeneous screens) and not mandatory layout-only slots for every page on day one.
- **D-02 (Width policy):** Treat **`max-w-3xl`** on **`:ops`** `main` as the **default reading width**, not a hard law for all data. For **wide tables / playground / inspector**, use **layout variant or wrapper**: e.g. **`overflow-x-auto`** + **`min-w-0`** on flex parents, optional **`sticky`** `<thead>`, and/or a documented **`max-w-7xl` / full-bleed** variant for routes that are **table-first** (Sidekiq-style honesty over decorative cards).
- **D-03 (Titles):** Each **`/ops`** LiveView sets **`assign(:page_title, …)`** aligned with visible page intent; **`live_title`** in **`root.html.heex`** remains the tab source — avoid duplicate **`<h1>`** stacks and drift between tab and page (**OPSUX-03** + **OPSUX-05**).

### Theme + first paint (OPSUX-04)

- **D-04 (Single theme contract):** Preserve **three modes** — **`system`**, **`light`**, **`dark`** — matching current **`root.html.heex`** script: **`system`** = **no** `data-theme` on `<html>` and **no** `phx:theme` in **`localStorage`**; explicit themes set **`data-theme`** and persist **`phx:theme`**. **Do not** introduce a second storage key or parallel `class="dark"` signal.
- **D-05 (First paint):** Keep the **small synchronous inline script in `<head>`** before CSS so theme applies before paint; do **not** move initial resolution to deferred **`app.js`**.
- **D-06 (Cross-tab):** Keep **`window` `storage`** listener on **`phx:theme`** for multi-tab sync.
- **D-07 (DaisyUI + Tailwind `dark:` coherence):** **`@custom-variant dark`** in **`app.css`** currently matches **only** `[data-theme=dark]`, while **system** dark relies on daisyUI **`prefersdark`** on `:root`. **Pick one documented strategy:** either **extend** `@custom-variant dark` to include **`(prefers-color-scheme: dark)`** when `data-theme` is absent, **or** reserve Tailwind **`dark:`** for regions that are explicitly **`data-theme=dark`** only and use **daisyUI semantic tokens** (`base-*`, components) everywhere operator chrome must track **system** dark. **Do not** leave the mismatch undocumented — it is a footgun for contributors.
- **D-08 (Theme toggle UI):** **`theme_toggle`** knob positioning today keys off **`[[data-theme=light]_&]`** / **`dark`** only — **incorrect visual state in `system` mode** when attribute is absent. Fix by reflecting **effective** appearance (e.g. **`matchMedia('(prefers-color-scheme: dark)')`** + small client hook or server-visible resolved state — choose minimal approach consistent with **D-07**).
- **D-09 (Styling surfaces):** Prefer **daisyUI semantic utilities** for chrome, flash, panels, and tables so theme tokens stay consistent; custom focus rings should use **theme variables** (`primary`, `base-content`), not hard-coded neutrals.
- **D-10 (CSP roadmap):** Document that strict **CSP** later may require **nonce** (or tiny non-deferred first-party script) for the inline theme bootstrap — optional for this milestone unless OPS adopts CSP imminently.

### Dense operator data — tables, banners, federation honesty (OPSUX-03)

- **D-11 (Thin semantic wrappers):** Add **namespaced wrappers** (e.g. **`ops_data_table`**, **`ops_posture_banner`**, **`ops_metric_strip`**, **`ops_disclosure`**) implemented **with daisyUI + Tailwind inside** — not re-styling from scratch per LiveView. Wrappers carry **severity → daisyUI variant** mapping: **degraded → `alert-warning`**, **failed / unsafe → `alert-error`**, **informational → `alert-info`**, **healthy assurance →** subtle **`alert-success`** only when it adds real signal; **do not** use success green for neutral “zero results.”
- **D-12 (`card` vs flat panels):** Use **`card`** for **self-contained task surfaces** (e.g. playground with inputs + actions + help). Use **flat bordered sections** (`border border-base-300 rounded-lg bg-base-100` or equivalent) for **dense repeating** structures (table chrome, honesty text, KPI strips) — avoid **card + shadow** on every block.
- **D-13 (Density):** Default table body to **`text-sm` / `leading-snug` / `tabular-nums`** for counts and timestamps; keep **primary column** and **page title** at higher emphasis. Truncate long IDs with **tooltip or copy** affordance.
- **D-14 (Federation / partial failure):** “Honesty” panels are **structured disclosure**: short headline, compact facts (what failed, merge order, ceilings), **one** primary egress — prefer **`alert` + list** over nested **`card`** unless the panel also hosts controls.

### Phoenix ergonomics vs Phase 50 boundary (OPSUX-05)

- **D-15 (One-line boundary):** **Phase 49** makes **`/ops`** behave like **one coherent Phoenix LiveView app** (correct **`shell`**, flash update path, **`live_title` / `page_title`**, **`~p` / `<.link navigate>`**, **`push_patch` vs `push_navigate`** discipline, no marketing shell leak). **Phase 50** adds **assistive-technology semantics** (heading order audit, landmark redundancy, **`aria-*`**, form **`label`/`fieldset`** for playground controls, extended CI) — **OPSUX-06**, **OPSUX-07**.
- **D-16 (`live_title` product suffix):** Replace or narrow the stock **“· Phoenix Framework”** **`live_title`** suffix for **`/ops`** so tabs read as **operator product**, not generator default (**OPSUX-05** polish).
- **D-17 (Flash rule):** **Single `flash_group`** per document pass, rendered from **`Layouts.app`** so LiveView **`put_flash`** updates correctly — **no duplicate** static **`flash_group`** on **`/ops`** paths; document and grep-guard if needed.
- **D-18 (Navigation primitives):** Internal **`/ops`** links use **`<.link navigate={~p"…"}>`** (or **`patch`** where appropriate); avoid raw **`href`** for internal routes; avoid deprecated **`live_redirect` / `live_patch`** in new or touched code — use **`push_navigate` / `push_patch`** per current Phoenix guidance.
- **D-19 (Cohesion with Phase 48):** **Do not** assert **`Nav.primary/0` order, labels, or route set** in Phase **49** tests — that remains **`operator_ia_contract_test`** / **`mix scrypath_ops.check_nav_contract`**. Phase **49** tests target **structural wiring**: e.g. **`:ops`** shell present, **`page_title`** assigned, **`Layouts.app`** receives **`@shell`**, optional **scaffold region** hooks — not IA content duplication.

### Claude's Discretion

- Exact **component module name** (`OpsUi` vs extra functions on **`CoreComponents`**) and **attr API** shape for scaffold wrappers.
- Precise **max-width breakpoints** per route and whether **search** uses **full-bleed table** vs **wider max-width** — within **D-02** policy.
- Whether **`matchMedia`** lives in **small head script** vs **minimal `hooks.js`** hook — within **D-07** / **D-08** coherence.
- **`live_title` suffix** exact string for marketing **`/`** vs **`/ops`**.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — **OPSUX-03**, **OPSUX-04**, **OPSUX-05**; out-of-scope table; traceability rows for Phase **49**.
- `.planning/ROADMAP.md` — Phase **49** success criteria under **v1.11**.
- `.planning/PROJECT.md` — Current milestone goals for **ScrypathOps** polish.

### Prior phase context (do not re-litigate IA here)

- `.planning/phases/48-ia-and-jtbd-alignment/48-CONTEXT.md` — **Nav** as Elixir SOT, **contract test** boundaries, deferred shell/theme/flash assertions to Phase **49**.

### Operator IA (reference only for copy alignment — tests are Phase 48)

- `scrypath_ops/docs/operator-ia.md` — Personas, JTBD, nav labels intent.

### Implementation anchors

- `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex` — **`:ops`** vs default shell, **`flash_group`**, **`theme_toggle`**.
- `scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex` — **`live_title`**, inline theme bootstrap, **`@inner_content`**.
- `scrypath_ops/assets/css/app.css` — daisyUI theme plugins, **`@custom-variant dark`**.
- `scrypath_ops/lib/scrypath_ops_web/components/core_components.ex` — Existing flash / UI primitives to extend or mirror.
- `scrypath_ops/lib/scrypath_ops_web/router.ex` — **`live_session :ops`** grouping.

### External patterns (for planner research notes)

- [Phoenix LiveView — Live layouts](https://hexdocs.pm/phoenix_live_view/live-layouts.html) — root vs app layout, **`live_session`**, **`on_mount`**.
- [daisyUI documentation](https://daisyui.com/) — **`data-theme`**, theme controller patterns.
- [DockYard — LiveView rendering pitfalls](https://dockyard.com/blog/2022/08/18/liveview-rendering-pitfalls-and-how-to-avoid-them) — navigation and re-render discipline.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`ScrypathOpsWeb.Nav.primary/0`** — Curated **`/ops`** nav data; chrome must keep rendering from this module only (**Phase 48**).
- **`Layouts.app/1`** (`shell: :ops`) — Navbar, **`Nav`**, **`theme_toggle`**, **`main`** with **`max-w-3xl`**, **`flash_group`** after **`main`** — integration point for width variants and flash placement audit (**D-02**, **D-17**).
- **`root.html.heex`** — Synchronous theme script, **`phx:theme`** / **`data-theme`** contract (**D-04**–**D-06**, **D-08**).
- **`app.css`** — daisyUI **light** / **dark** plugins; **`dark`** Tailwind variant tied to **`data-theme=dark`** only (**D-07**).
- **`CoreComponents.flash_group` / `flash`** — daisyUI-aligned toast patterns; extend severity vocabulary consistently (**D-11**).

### Established patterns

- **Read-only ops shell** — No new write-side recovery verbs; honesty and links only (**v1.10** / **v1.11** boundary).
- **Verified routes** — **`~p"/ops/…"`** for internal navigation.

### Integration points

- **`on_mount`** assigns **`shell`** for **`/ops`** LiveViews ↔ **`Layouts.app`** wrapper in each **`*.html.heex`** root template.
- **Theme toggle** uses **`JS.dispatch("phx:set-theme")`** targeting **`window`** — keep event name and storage key stable (**D-04**).

</code_context>

<specifics>
## Specific Ideas

- **Prior art synthesis (research):** Sidekiq-style **table-first honesty** + PagerDuty-like **severity vocabulary** + AWS Health-style **degraded vs broken** disclosure + Datadog-like **facets as secondary column** on wide layouts — inform density and banner copy, not feature scope.
- **Anti-patterns to avoid:** ActiveAdmin-style **mega-template DSL**, duplicate theme signals (**`class="dark"`** + **`data-theme`**), **card-on-card** elevation noise, **Tailwind `dark:`** utilities that silently fail under **system** dark given current **`@custom-variant`** (**D-07**).
- User requested **all four** gray areas in discuss-phase; decisions above integrate parallel subagent research into **one coherent** implementation stance.

</specifics>

<deferred>
## Deferred Ideas

- **Phase 50 — OPSUX-06 / OPSUX-07:** Full **heading order** pass, **`main` / `nav` landmark** audit beyond “tag exists”, **`aria-*`** for icon-only and playground controls, **`fieldset`/`legend`**, extended **LiveViewTest** / CI for a11y contracts.
- **SSR / cookie-mirrored theme** for zero-JS first paint or strict **CSP** — only if OPS hardening demands it (**D-10**).
- **Visual / screenshot regression CI** — explicitly out of **v1.11** requirements table unless Phase **50** proves insufficient.

**Reviewed todos (not folded):** None.

</deferred>

---

*Phase: 49-visual-hierarchy-theming-and-phoenix-ergonomics*
*Context gathered: 2026-04-21*
