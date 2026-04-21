# Phase 50: Accessibility and verification hardening — Research

**Role:** gsd-phase-researcher  
**Gathered:** 2026-04-21  
**Audience:** Phase planner / orchestrator implementing **OPSUX-06** and **OPSUX-07** on **`scrypath_ops`**

---

## Executive summary for planners

Phase **50** is deliberately **bounded**: ship **operator-grade HTML semantics** and **lightweight, CI-stable contracts**—not a WCAG certification program or a default browser E2E matrix (**REQUIREMENTS.md** out-of-scope table; **50-CONTEXT** **D-20**).

**What planners must internalize:**

1. **Decisions are already locked** in **50-CONTEXT.md** (**D-01**–**D-24**): one visible **`h1`** per route tied to **`page_title` / `<.live_title>`**; **`header` / `nav` / `main`** in the **`:ops`** shell with **`id="ops-main"`** and a **skip link**; **native tables** and **sortable column buttons** with **`aria-sort`**; **fieldset/legend** for grouped controls; **one polite `role="status"`** (or equivalent) for aggregate federation/posture chatter—not **`aria-live`** on large LiveView containers.

2. **Verification strategy is layered extension**, not replacement (**D-18**): keep **Phase 48** **`operator_ia_contract_test`** + **`mix scrypath_ops.check_nav_contract`** (already in **`scrypath_ops/mix.exs`** `test` alias) and **Phase 49** **`ops_shell_contract_test`**. Add **new LiveViewTest-based “DOM semantics” modules** that assert **structure** (landmarks, heading count/level, **`for`/`id`** label wiring, stable **`id`s** referenced by **`aria-labelledby`**) using **`Phoenix.LiveViewTest`** (`render/1`, **`has_element?/2`**) and, where tree queries help, **Floki** on **`render(lv)`** strings.

3. **`mix verify.opsui` is already implemented** at the **repo root** (`lib/mix/tasks/verify.opsui.ex`): it **`cd scrypath_ops && mix deps.get && mix test`**, matching **CONTRIBUTING.md** and the **`scrypath-ops`** CI job. **D-19** work is therefore **documentation + optional task shape refinement** (e.g. a **tagged quick subset** for local iteration while CI stays **full**), not inventing the task from scratch.

4. **Manual screen-reader spot-check** remains a **first-class artifact** (**D-22**): **posture → failed-sync → sync/drift → search** recorded in phase verification docs; automation guards **regression of wiring**, not subjective “readability” of every string.

5. **Prioritize boring HTML** over ARIA reconstruction (**D-23**): **`main`**, **`nav`**, **`section` + heading**, **`fieldset`/`legend`**, **`th scope`**, **`label`**. Centralize repeated patterns in **`CoreComponents`** / small **`OpsUi`** helpers (**D-24**) so fixes are one place and tests target **stable hooks** (`id`, minimal **`data-testid`**).

---

## Phoenix LiveView + HEEx patterns

### Landmarks and document structure

- **Live layouts** attach a layout to a LiveView without duplicating mount logic. The **`:ops`** shell should continue to own **top-level landmarks** (**`<header>`**, **`<nav aria-label="…">`**, **`<main>`**) per **D-02**. Official reference: [Phoenix LiveView — Live layouts](https://hexdocs.pm/phoenix_live_view/live-layouts.html).

- **Skip link:** First **focusable** control in tab order should be a link (often visually hidden until **`:focus`**) pointing to **`#ops-main`** (**D-02**). Technique background: [W3C WAI — G1: Adding a link at the top of each page…](https://www.w3.org/WAI/WCAG22/Techniques/general/G1.html) (pattern reference; project locks specifics in **D-02**).

- **Landmark soup:** Too many **`role="region"`** / unnamed **`section`** elements pollutes screen-reader “rotors”. Prefer **2–4** meaningful **`<section aria-labelledby="stable-heading-id">`** blocks (**D-04**); do not wrap every card.

- **Optional `main` naming:** **`aria-labelledby`** on **`<main>`** pointing at the page **`h1`** is allowed when it improves rotor clarity (**D-05**); avoid duplicate invisible titles.

### Heading order and page title

- **Single visible `h1`** per **`/ops`** route, aligned with **`assigns.page_title`** and **`<.live_title>`** (**D-01**, **D-03**). Phoenix docs: [Phoenix.Component — `live_title/1`](https://hexdocs.pm/phoenix/Phoenix.Component.html#live_title/1).

- **Secondary structure:** **`h2`** per first-class **`ops_panel` / JTBD** block; **`h3`** only for real nested hierarchy—fix component-library defaults that jump **`h1` → `h4`** (**D-03**).

### Forms: `fieldset`, `legend`, labels

- Group related inputs with **`<fieldset>` + `<legend>`** when they answer one operational question or share one submit model (**D-06**, **D-07**). W3C technique: [H71: fieldset and legend](https://www.w3.org/WAI/WCAG22/Techniques/html/H71.html).

- Phoenix **`<.form>`**, **`<.input field={@form[:field]}>`** preserve **`for`/`id`** wiring—planners should specify **where** fieldsets break without introducing **nested `<form>`** (**D-08**; nested forms are invalid HTML).

- **`aria-describedby`** for honesty / constraint copy: attach only to **controls the text constrains**; keep referenced nodes **stable `id`s**; avoid huge blobs (**D-09**). Reference: [ARIA1: `aria-describedby`](https://www.w3.org/WAI/WCAG22/Techniques/aria/ARIA1.html).

### `aria-live` and dynamic status

- **One primary polite status region** (`role="status"` / `aria-live="polite"`) for **aggregate** federation/backend posture changes (**D-10**). Reserve **`role="alert"`** / **`assertive`** for rare urgent connection loss (**D-10**).

- **Do not** put **`aria-live`** on large subtrees that re-render frequently (LiveView diffing will **spam** assistive tech). Prefer **small, dedicated** regions updated only when operator-meaningful text changes.

- Flash groups often already use **`aria-live="polite"`**—ensure **only one** “global” polite channel does not fight a second unbounded region (**coordinate with D-10**).

### Sortable tables

- Use **real `<table>`** with **`<thead>` / `<tbody>`**, **`th scope="col"`** (**D-12**).

- Sort controls: **`<button type="button">`** inside **`<th>`**; expose sort state with **`aria-sort="none" | "ascending" | "descending"`** on **one** authoritative element (**D-13**). MDN reference: [`aria-sort`](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Attributes/aria-sort).

- **Expandable rows:** sibling **`<tr>`** detail pattern with **`aria-expanded`** / **`aria-controls`** (**D-14**); manage focus only when proven necessary (**D-17**, optional **`phx-hook`**).

- **Row actions:** **`role="group"`** + **`aria-label`** naming the row subject; per-button **task-specific** names (**D-15**).

- **Copy buttons:** keep value in **`<code>`** or text with its own **`id`**; **`aria-describedby`** optional; success feedback **polite**, not assertive (**D-16**).

### Icons and control naming

- **Visible text** beats **`aria-label`** for operator actions (**D-11**). Icon-only: **`aria-label`**; decorative icons: **`aria-hidden="true"`**. Never **`aria-label`** that **paraphrases** visible label text in conflicting ways.

---

## Testing: `Phoenix.LiveViewTest`, Floki, tags, `mix verify.opsui`

### What Elixir / Phoenix OSS typically does

- **Default gate:** **ExUnit** + **`Phoenix.ConnCase`** / **`Phoenix.LiveViewTest`**—no browser for most LiveView apps. API: [Phoenix.LiveViewTest](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html) (`live/2`, `live_isolated/3`, `render/1`, **`has_element?/2`**, `element/2`, `view/1`).

- **Structure assertions:** Many teams parse **`render(lv)`** with **Floki** for queries that CSS selectors express awkwardly (e.g. “exactly one `h1` in `main`”). **`scrypath_ops`** already depends on **`lazy_html`** in **test**; Floki remains the **ecosystem default** for HTML parsing in tests—choose one strategy per repo and stick to it.

- **Contract tests** (strings, router, nav module, doc parity)—already exemplified by **`operator_ia_contract_test.exs`**—are **cheap CI** and match **OPSUI-10** discipline.

- **Browser E2E (Wallaby, Playwright):** usually **optional**, nightly, or **`main`-only** in OSS Elixir due to **flakiness and driver cost**—aligns with **D-20**.

### Tag strategy (recommended for planners)

Introduce explicit ExUnit tags, for example:

| Tag | Purpose |
|-----|---------|
| `:opsui_ia` | Router / nav / doc contracts (existing files; optional re-tag) |
| `:opsui_shell` | Layout / shell structural contracts |
| `:opsui_a11y` | New DOM semantics contracts (**OPSUX-06**) |

**CI / canonical verify:** keep **`mix verify.opsui`** running the **full** **`scrypath_ops`** suite so guarantees do not drift.

**Local quick loop:** `cd scrypath_ops && mix test --only opsui_a11y` (after tagging)—**not** a substitute for full verify before push.

### `mix verify.opsui` layering (current repo facts)

- **Root:** `mix verify.opsui` → `scrypath_ops` + `mix deps.get` + **`mix test`** (see `lib/mix/tasks/verify.opsui.ex`).

- **`scrypath_ops` `test` alias** already runs **`scrypath_ops.check_nav_contract`**, **`ecto.create`**, **`ecto.migrate`**, then **`test`** (`scrypath_ops/mix.exs`). Planners adding tags must ensure **`mix test --only …`** still runs prerequisites if needed (ExUnit does not invoke Mix aliases for filtered runs—**document** or add a small **`mix verify.opsui.quick`** task if friction appears).

---

## Pitfalls

| Pitfall | Why it hurts | Mitigation (context lock) |
|--------|--------------|-----------------------------|
| **Nested forms** | Invalid HTML; unpredictable browser/LiveView behavior | One outer **`<.form>`**; subsections via **`section`/`h2`**; split sibling forms only when lifecycles truly differ (**D-08**) |
| **Landmark soup** | Screen-reader navigation noise | **2–4** named **`section`**s max; avoid redundant **`role="region"`** (**D-04**) |
| **Duplicate / conflicting `aria-label`** | SR reads wrong or redundant name | **`aria-label`** only for icon-only; no duplicate of visible text (**D-11**) |
| **Large `aria-live` regions** | Chatter on every patch | Dedicated small status node; **no live** on big **`phx-update`** containers (**D-10**) |
| **`aria-describedby` on everything** | Cognitive overload | Only controls constrained by that copy (**D-09**) |
| **Ordinal DOM keys in streams** | Focus loss / wrong row updates | Natural ids in streams (**D-17**) |
| **Whole-page HTML snapshots** | Brittle CI, merge pain | Forbidden as default gate (**D-21**) |
| **Conflicting `aria-sort` targets** | AT exposes wrong sort state | **One** authoritative element (**D-13**) |

---

## Validation Architecture

This subsection is for the orchestrator to derive **VALIDATION.md**: commands, scopes, and tagging.

### Canonical full verify (matches CI / contributor docs)

- **From repo root:** `mix verify.opsui`  
  - Equivalent to **`cd scrypath_ops && mix deps.get && mix test`** in CI style (non-interactive).

### Core automated paths under `scrypath_ops/test/`

| Area | Paths (extend, do not remove) |
|------|-------------------------------|
| IA / nav contracts | `scrypath_ops/test/scrypath_ops_web/operator_ia_contract_test.exs` |
| Shell / LiveView structural contracts | `scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs` |
| Per-route LiveView tests | `scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs`, `failed_sync_live_test.exs`, `sync_drift_live_test.exs`, `search_live_test.exs` |
| Auth / boot / schema / config guards | `scrypath_ops/test/scrypath_ops/opsui_auth_boot_contract_test.exs`, `schemas_test.exs`, `config_prod_guard_test.exs`, `search_playground_test.exs` |
| Controllers / errors | `scrypath_ops/test/scrypath_ops_web/controllers/*.exs` |

**Phase 50 addition (planned):** one or more modules such as **`scrypath_ops_web/ops_a11y_contract_test.exs`** (name at planner discretion) asserting **OPSUX-06** DOM contracts across the **four** critical **`/ops`** routes (**D-18**).

### Suggested ExUnit tags

- **`:opsui_a11y`** — all new **accessibility DOM contract** tests (**OPSUX-06**).
- Optionally **`:opsui_contract`** — umbrella tag including IA + shell + a11y for documentation clarity.

### Quick vs full

| Mode | Command | Intent |
|------|---------|--------|
| **Full** | `mix verify.opsui` (root) | Same breadth as **scrypath-ops** CI; required before merge |
| **Focused app tests** | `cd scrypath_ops && mix test test/scrypath_ops_web/live/posture_live_test.exs` (etc.) | Fast feedback on one surface |
| **Future quick a11y slice** | `cd scrypath_ops && mix test --only opsui_a11y` | After tags land; local iteration only |

### Manual verification artifact

- **Spot-check:** keyboard + screen reader on **posture → failed-sync → sync/drift → search**; record outcome in **`50-VERIFICATION.md`** (or chosen phase verification doc) per **D-22**.

### Library / tool references for test implementation

- [Phoenix.LiveViewTest](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html)
- [Phoenix Test.ConnCase](https://hexdocs.pm/phoenix/Phoenix.Test.ConnCase.html) (if using `ConnCase` for LiveView routes)

---

## RESEARCH COMPLETE
