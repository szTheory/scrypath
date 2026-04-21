# Phase 50: Accessibility and verification hardening - Context

**Gathered:** 2026-04-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **OPSUX-06** and **OPSUX-07** for **v1.11** on **`scrypath_ops`**: assistive-technology semantics (**heading** order, **`main` / nav / header** landmarks, **labels** and related ARIA) on **operator-critical paths** — posture, failed sync, sync/drift triage **tables**, and **search / federation playground** controls — plus **automated verification** so shell and IA contracts **do not regress** and new a11y structure is **CI-guarded**.

**In scope (requirements):**

- **OPSUX-06:** Logical heading order; **`main`** and landmark usage where appropriate; **labels** (or equivalent accessible names) for interactive controls on triage and playground paths.
- **OPSUX-07:** Extend CI for new contracts and critical LiveView flows — **no decrease** in operator wiring discipline after Phase **48–49** polish.

**Out of scope:** Full WCAG 2.x conformance audit or certified compliance; default **Playwright/Cypress** matrix in PR CI; **Meilisearch-in-CI** for ops (per **REQUIREMENTS.md** out-of-scope table unless explicitly promoted); **write-side** recovery verbs (unchanged v1.10 boundary).

Roadmap success criteria: (1) spot **keyboard + screen-reader** pass on **posture → failed-sync → sync/drift → search**; (2) CI / documented **`verify.opsui`** path green with **new cases**.

</domain>

<decisions>
## Implementation Decisions

### Heading + landmark model (OPSUX-06) — coheres with Phase 49 scaffold

- **D-01 (Single document `h1` per route):** Exactly **one visible `<h1>`** per **`/ops`** route, emitted from the shared **page header** primitive (Phase **49** `ops_page_header` / equivalent) with text **aligned** to **`assigns.page_title`** and **`<.live_title>`** — same string discipline as **49-CONTEXT** **D-03** / **D-15**. **Reject** a layout-owned product `h1` (“ScrypathOps”) with the real page title demoted to **`h2`** — it fights Phoenix’s **`page_title` mental model** and hurts heading navigation for SR users.
- **D-02 (Landmarks):** Keep **`<header>`**, **`<nav aria-label="Operator primary">`**, and **`<main>`** in **`Layouts.app` (`shell: :ops`)** as today. Add **`id="ops-main"`** on **`main`** and a **skip link** (“Skip to operator content”) targeting **`#ops-main`** as the first focusable affordance in document order (keyboard / SR efficiency — pattern from mature ops consoles).
- **D-03 (Secondary headings):** Under the page **`h1`**, use **`h2`** for each first-class **`ops_panel`** / JTBD block; **`h3`** for nested sub-blocks only when hierarchy is real — **no** `h1` → `h4` jumps from component library defaults (DaisyUI card examples are a common footgun; override levels in ops templates).
- **D-04 (Named regions, selective):** Wrap **2–4** first-class blocks per page (e.g. “Next checks”, “Federation honesty”, “Results”) in **`<section aria-labelledby="…">`** referencing a stable **`id`** on the visible **`h2`**. **Do not** wrap every bordered **`div`**; avoid **landmark soup** and unnecessary **`role="region"`** when **`section` + heading** suffices (prefer native HTML semantics).
- **D-05 (Optional `main` naming):** If beneficial for SR rotor clarity, set **`aria-labelledby`** on **`<main>`** to the page **`h1` `id`** — **one** naming relationship, no duplicate hidden titles.

### Playground + federation form semantics (OPSUX-06)

- **D-06 (Default grouping — `fieldset` / `legend`):** Use **one bounded `<.form>`** for the playground “run” surface where a single submit model applies; split into **concern-based chapters** with **`<fieldset>` + `<legend>`** (e.g. **Query**, **Federation / merge**, **Limits / safety**, **Actions**). This matches HTML’s intended model (**WAI H71**), stays **maintainable** (template structure mirrors operator mental model), and is **least surprise** for Phoenix contributors using **`<.input field={@form[:…]}>`** label/`for` wiring.
- **D-07 (Radio / checkbox clusters):** Any **mutually exclusive** or **named group** of radios/checkboxes answering **one question** **must** use **`fieldset` / `legend`** even if the rest of the page uses headings only.
- **D-08 (Dense non-form inspector rows):** Where a block is **mostly** read-only metadata with a few inputs, **inside the same outer form** prefer **`section` + `h2` + `aria-labelledby`** for that subsection — **never** nest **`<form>`** inside **`<form>`** (illegal HTML). If a genuine second submit lifecycle appears later, split at layout boundaries into sibling forms (deferred unless product demands it).
- **D-09 (Honesty / warnings + `aria-describedby`):** Give honesty panels **stable `id`s**; reference them from **`aria-describedby`** only on **controls the copy constrains** — not every toggle. Avoid attaching **huge** diagnostic blobs to **`aria-describedby`** (SR verbosity / cognitive load).
- **D-10 (Dynamic federation status):** Use **one primary `role="status"`** (polite) region for **aggregate** federation / backend posture changes; reserve **`role="alert"`** for rare **urgent** connection-loss style messages. Do **not** attach **`aria-live`** to large containers that re-render on every **`phx-update`** tick.
- **D-11 (Icon-only vs visible labels):** Prefer **visible text** for operator actions; use **`aria-label`** only for **true icon-only** controls. **Decorative** icons: **`aria-hidden="true"`**. Never duplicate conflicting **visible text + `aria-label`** on the same node.

### Dense triage tables + actions (OPSUX-06)

- **D-12 (Real tables):** Use **semantic `<table>`**, **`<thead>` / `<tbody>`**, **`th scope="col"`** (and **`scope="row"`** for row-header tables if used). **Do not** fake tables with **`div` grids** for primary triage data — loses table navigation in AT unless rebuilt with full grid roles (not worth it here).
- **D-13 (Sortable columns):** Implement sort as a **`<button type="button">` inside `<th>`** with **`aria-sort="none" | "ascending" | "descending"`** on **one** authoritative element (button **or** `th`, not conflicting duplicates). Pair visible sort text with **`aria-hidden`** arrows.
- **D-14 (Expandable row details):** Prefer a **sibling `<tr>`** detail row with **`aria-expanded` / `aria-controls`** on the toggle; toggle **`hidden`** in sync with **`aria-expanded`**. Manage **focus** on open/close when needed (small **`phx-hook`** only where LiveView replaces nodes).
- **D-15 (Row action toolbars):** Wrap icon actions in **`role="group"`** with **`aria-label`** naming the **row subject** (e.g. “Actions for job {id}”). Each button: **task-specific** **`aria-label`** (“Copy Oban job id”, not “Menu”).
- **D-16 (Copy-to-clipboard):** Keep **`<code>` / text** separate from the **copy** button; **`aria-describedby`** may reference the value **`id`**. Confirm success with **polite** feedback (**inline** or **single shared** polite region) — not **`assertive`** for routine copy.
- **D-17 (LiveView table stability):** Prefer **`phx-update="stream"`** (or append patterns) with keys from **natural ids** (task uid, Oban id, drift key) — never ordinal row index. Restore focus after patches only when user action would otherwise land on a replaced node.

### Verification + CI (OPSUX-07)

- **D-18 (Layered guarantees — extend, don’t replace):** Continue **Phase 48** **`operator_ia_contract_test`** + **`mix scrypath_ops.check_nav_contract`** and **Phase 49** **`ops_shell_contract_test`** for **IA / shell / structural** wiring. **Add** a dedicated **`LiveViewTest`** module (or clearly named test files) for **OPSUX-06** “**DOM semantics contracts**” on the **four** critical routes: landmarks, **single `h1`**, stable **`id`s** used in **`aria-labelledby`**, and **label** association for inputs (assert via **`has_element?`/Floki** — deterministic server HTML, not screenshots).
- **D-19 (`mix verify.opsui`):** Introduce or document **`mix verify.opsui`** as the **canonical** command (alias in **`scrypath_ops/mix.exs`** or root **`mix.exs`**) that runs the **ops** test suite (or the **contract + a11y** subset if split by tag). Align **CI** job(s) and **`docs/releasing.md`** / ops README so “green” matches **operator guarantees**.
- **D-20 (Defer browser E2E):** **No** default **Wallaby / Playwright** gate on every PR. If a concrete gap appears (e.g. focus trap), add an **optional** tagged suite on **`main`** or nightly — OSS **flakiness + driver churn** cost outweighs default benefit for this repo.
- **D-21 (No whole-page HTML snapshots):** Do **not** use large golden HTML snapshots as CI gates. If ever needed, **one tiny** fragment with explicit maintainer review only.
- **D-22 (Manual SR pass artifact):** Record the **posture → failed-sync → sync/drift → search** spot-check outcome in **`50-VERIFICATION.md`** (or phase verification doc the planner chooses) — complements automated contracts; does not replace **D-18**.

### Cross-cutting engineering principles (locked)

- **D-23 (Boring over clever):** Prefer **native HTML** primitives (**`main`**, **`nav`**, **`section`**, **`fieldset`**, **`label`**, **`th scope`**) over **ARIA**-heavy **`div`** reconstructions — aligns with **Elixir / Phoenix** culture of **explicit, readable templates**.
- **D-24 (DX for contributors):** Centralize repeated patterns in **`CoreComponents`** / **`OpsUi`** helpers so a11y fixes are **one place** (`skip_link`, `ops_section`, table header button, polite status region). Tests assert **stable hooks** (`id`, `data-testid` only when necessary) — not full copy equality.

### Claude's Discretion

- Exact **`id` prefix** scheme for sections and skip-link styling (visible on keyboard focus only vs always-on text).
- Whether **`aria-labelledby` on `main`** ships in the first PR vs a follow-up slice inside Phase **50**.
- **`phx-hook`** minimal JS for focus restore — only on views proven to lose focus after patch.
- Exact **`mix verify.opsui`** task shape (full `mix test` vs `@tag` subset) as long as **D-19**’s “one canonical command” holds.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — **OPSUX-06**, **OPSUX-07**; out-of-scope table; traceability rows for Phase **50**.
- `.planning/ROADMAP.md` — Phase **50** success criteria under **v1.11**.
- `.planning/PROJECT.md` — Milestone goals for **ScrypathOps** polish.

### Prior phase boundaries (do not re-litigate)

- `.planning/phases/49-visual-hierarchy-theming-and-phoenix-ergonomics/49-CONTEXT.md` — Phase **49** vs **50** boundary (**D-15**); scaffold, theme, Phoenix ergonomics locks.
- `.planning/phases/48-ia-and-jtbd-alignment/48-CONTEXT.md` — **`Nav.primary/0`**, **`operator_ia_contract_test`**, doc sync — Phase **48** ownership.

### Operator IA and implementation anchors

- `scrypath_ops/docs/operator-ia.md` — JTBD ordering and copy intent (reference for labels / triage language).
- `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex` — **`:ops`** shell, **`nav`**, **`main`**, flash placement.
- `scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex` — **`live_title`**, theme bootstrap.
- `scrypath_ops/lib/scrypath_ops_web/components/core_components.ex` — Form / UI primitives to extend.
- `scrypath_ops/lib/scrypath_ops_web/router.ex` — **`live_session :ops`**.

### Tests and contracts (extend here)

- `scrypath_ops/test/scrypath_ops_web/operator_ia_contract_test.exs` — IA / router / doc spine (**Phase 48**).
- `scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs` — Shell / LiveView structural contracts (**Phase 49**).
- `scrypath_ops/test/scrypath_ops_web/live/*_live_test.exs` — Per-route **`LiveViewTest`** patterns.

### External guidance (techniques, not law)

- [W3C WAI — H71: Providing a description for groups of form controls using `fieldset` and `legend`](https://www.w3.org/WAI/WCAG22/Techniques/html/H71.html)
- [W3C WAI — ARIA1: Using `aria-describedby`](https://www.w3.org/WAI/WCAG22/Techniques/aria/ARIA1.html)
- [Phoenix LiveView — Live layouts](https://hexdocs.pm/phoenix_live_view/live-layouts.html)
- [Phoenix.Component — `live_title/1`](https://hexdocs.pm/phoenix/Phoenix.Component.html#live_title/1)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`ScrypathOpsWeb.Nav.primary/0`** — Nav data; chrome labels stay aligned with IA tests.
- **`Layouts.app/1` (`shell: :ops`)** — **`nav`**, **`main`**, **`flash_group`** with **`aria-live="polite"`** — extend with **skip link** + **`id="ops-main"`**.
- **`PostureLive`** — **`aria-label="Next checks"`** on a region — evolve with **D-04** section / heading **`id`** wiring.
- **`SearchLive`** — Multiple **`h2`** sections and **`aria-live`** — normalize **heading levels** and live-region **verbosity** per **D-03**, **D-10**.
- **`CoreComponents`** — **`aria-label`** on flash close — pattern for **icon-only** naming (**D-11**).

### Established patterns

- **Read-only ops** — honesty, links, bounded playground; no new write verbs.
- **Contract tests over pixel tests** — Phase **48–49** precedent; Phase **50** adds **semantic** assertions in the same spirit.

### Integration points

- **`ops_page_header`** (or equivalent from Phase **49**) — single **`h1`** + stable **`id`** for **`aria-labelledby`** chains.
- **Playground forms** — **`SearchLive`** (and federation inspector markup) ↔ **`Phoenix.Component` form helpers**.

</code_context>

<specifics>
## Specific Ideas

- **Research synthesis (2026-04-21):** Parallel research covered **(1)** heading/landmark models vs Phoenix **`page_title`**, **(2)** `fieldset` vs `role="group"` tradeoffs for dense operator forms, **(3)** Sidekiq/GitHub/Sentry-style **literal triage tables** + **`aria-live`** discipline, **(4)** OSS CI layering (**LiveViewTest** + contract tests vs browser snapshots). User asked for a **single coherent** “do not make me think” stance — captured as **D-01**–**D-24**.
- **Ecosystem takeaway:** Successful **ops UIs** (Sidekiq, Sentry, Grafana-class tools) win on **boring structure** — stable columns, verb actions, minimal SR noise — not marketing chrome.
- **Anti-patterns to avoid:** Landmark soup; **`aria-label`** duplicating visible text; **`assertive`** live regions for routine updates; nested forms; whole-page HTML snapshots in CI.

</specifics>

<deferred>
## Deferred Ideas

- **Wallaby / Playwright** as optional **`main`** or nightly job — only when **`LiveViewTest`** cannot cover a proven interaction gap (**D-20**).
- **Strict CSP + nonce** for inline theme script — already noted as roadmap in **49-CONTEXT** **D-10**; not Phase **50** unless escalated.
- **WCAG formal audit / VPAT** — product/compliance phase beyond v1.11 ops polish.

**Reviewed todos (not folded):** None (`todo.match-phase` returned empty).

</deferred>

---

*Phase: 50-accessibility-and-verification-hardening*
*Context gathered: 2026-04-21*
