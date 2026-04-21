---
phase: 49
slug: visual-hierarchy-theming-and-phoenix-ergonomics
status: approved
shadcn_initialized: false
preset: not applicable
created: 2026-04-21
reviewed_at: 2026-04-21
---

# Phase 49 — UI Design Contract

> Visual and interaction contract for **ScrypathOps** `/ops` LiveViews (**OPSUX-03**, **OPSUX-04**, **OPSUX-05**). Generated for `/gsd-ui-phase`; stack is **Phoenix LiveView + Tailwind CSS v4 + daisyUI** (not React/shadcn).

---

## Design System

| Property | Value |
|----------|-------|
| Tool | **none** (no shadcn; Elixir/HEEx stack) |
| Preset | **not applicable** |
| Component library | **Phoenix `CoreComponents`** + **daisyUI** utilities (`btn`, `alert`, `card`, `menu`, `navbar`, `table`, etc.) |
| Icon library | **Heroicons** (`hero-*` via `@plugin "../vendor/heroicons"` in `app.css`) |
| Font | **System / Tailwind default** sans stack (no custom webfont in v1.11 ops shell) |

---

## Spacing Scale

Declared values (multiples of **4** px). Use Tailwind spacing scale mapped to these semantics:

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon gaps, tight inline padding |
| sm | 8px | Compact stacks, `gap-2` |
| md | 16px | Default vertical rhythm between blocks (`space-y-4`), panel padding |
| lg | 24px | Section separation (`mt-6`, `mt-8`) |
| xl | 32px | Major section breaks |
| 2xl | 48px | Rare page-level breathing room |
| 3xl | 64px | Full-bleed layouts only when justified |

**Exceptions:** **none** for this phase (prefer `min-h-10` / daisyUI `btn` sizing over ad hoc pixel values). **Source:** `49-CONTEXT.md` D-02, D-12, D-13.

---

## Typography

| Role | Size | Weight | Line height |
|------|------|--------|---------------|
| Body | **16px** (`text-base`) | **400** | **1.5** |
| Label / table body | **14px** (`text-sm`) | **400** | **1.45** (snug tables: `leading-snug` + `tabular-nums` for counts/timestamps per D-13) |
| Heading (section `h2`, nav density) | **18px** (`text-lg`) | **600** | **1.25** |
| Display (page `h1`) | **24px** (`text-2xl`) | **600** | **1.2** (`leading-8`, `tracking-tight` where already used) |

**Weights allowed:** **400** (normal) and **600** (semibold) only. **Source:** existing `posture_live` title classes; D-13 emphasis rules.

---

## Color

Semantic contract uses **daisyUI theme tokens** (not raw hex in templates). Light/dark values come from `scrypath_ops/assets/css/app.css` theme plugins.

| Role | Token / class role | Usage (60 / 30 / 10) |
|------|-------------------|----------------------|
| Dominant (**~60%**) | `bg-base-100`, `text-base-content` | Page canvas, main reading surface |
| Secondary (**~30%**) | `bg-base-200` / `bg-base-200/40`, `border-base-300`, navbar chrome | Panels, borders, subtle strips, **flat** dense regions (D-12) |
| Accent (**~10%**) | `primary`, `btn-primary`, `link-primary` (sparingly) | **Primary refresh/run actions**, **one** active mode toggle state, **focus-visible** rings tied to theme variables |
| Destructive | `error`, `alert-error`, `text-error` | **Failed / unsafe** posture and honesty paths only (D-11) |

**Accent reserved for:**

- Primary **verb+noun** actions (`btn-primary`): e.g. refresh posture, run searches, refresh reconcile.
- **Single** “you are here” affordance in a control group when required (e.g. active search mode toggle).
- **Focus rings** using `primary` / `base-content` mix — **not** hard-coded neutral grays (D-09).

**Not** accent: every `btn-ghost`, every link, neutral toggles, table row chrome, informational banners (use `alert-info` / `alert-warning` per severity).

**60/30/10:** Explicitly **yes** — majority base-100/Content, secondary structural chrome, accent only for above list.

**Source:** `49-CONTEXT.md` D-07–D-09, D-11–D-12.

---

## Visual hierarchy and layout

**Primary focal point (each `/ops` screen):** The **page `<h1>`** (display typography) plus the **first primary panel** (rollup, table, or playground **card** per D-12). Secondary detail flows **below** or **beside** within the scaffold; do not duplicate a second full-width `<h1>`.

**Scaffold:** Implement **`ops_page_header`**, **`ops_panel`**, and optional **`ops_scaffold`** wrappers (exact module name: implementer discretion per CONTEXT) so every targeted LiveView follows **title → primary → optional secondary** inside `Layouts.app` `inner_block` only (D-01).

**Width:** Default **`max-w-3xl`** on `:ops` `main` inner wrapper. **Wide / table-first** routes (search playground, wide tables): **`max-w-7xl` or full width** inner variant with `min-w-0`, `overflow-x-auto`, optional sticky `<thead>` (D-02).

**Severity → daisyUI:** degraded → `alert-warning`; failed/unsafe → `alert-error`; informational → `alert-info`; healthy assurance → subtle `alert-success` **only** when it adds signal — never success styling for neutral empty tables (D-11).

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| **Primary actions (pattern)** | **`{Verb} {object}`** — never bare **Refresh** / **Submit** / **OK**. Per surface: **Refresh posture** (posture LiveView); **Refresh failed sync jobs** (failed-sync list); **Refresh reconcile** (sync drift reconcile block — already matches); **Load / refresh contract drift** (drift block); **Run sample searches** (search playground submit). |
| **Empty state — posture / health** | **Heading:** “No blocking issues detected.” **Body:** “Keep monitoring drift and failed sync. Use the nav links when you need detail.” (Adjust to match live assign copy but keep **actionable next step**.) |
| **Empty state — failed sync** | **Heading:** “No failed sync jobs right now.” **Body:** “When jobs fail, they appear here with timestamps. Check **Posture / health** for rollups or run your usual Oban dashboards if something still looks wrong.” |
| **Empty state — sync drift tables** | **Heading:** “No drift rows loaded.” **Body:** “Pick a schema (or tap **Load / refresh contract drift**) to compare declared settings vs the live index.” |
| **Empty state — search results** | **Heading:** “No hits for this query.” **Body:** “Widen filters or try another sample; see the honesty panel for merge ceilings and backend limits.” |
| **Error state (generic pattern)** | **Problem in first sentence** + **Next step:** “**{What failed}:** {reason}. Next: {operator action} — then retry **{matching primary CTA}**.” Link to `guides/multi-index-search.md` or ops docs when federation/query errors apply (align with existing search error panel). |
| **Destructive confirmation** | **None** for this phase (read-only ops shell). Toggles like “compact view” are **non-destructive** — no modal. |

---

## Theming and Phoenix ergonomics (interaction contract)

- **Theme modes:** **`system`**, **`light`**, **`dark`** only. **`phx:theme`** + `data-theme` contract unchanged; no second storage key (D-04).
- **First paint:** Inline **synchronous** script in `<head>` before CSS — **do not** defer initial theme to `app.js` (D-05).
- **Cross-tab:** `storage` listener on `phx:theme` preserved (D-06).
- **Tailwind `dark:` vs system dark:** Document chosen strategy in implementation (single coherent approach per D-07 — extend `@custom-variant dark` **or** restrict `dark:` and rely on daisyUI tokens for system-dark chrome).
- **Theme toggle:** Must reflect **effective** appearance in **system** mode (D-08) — implementer picks minimal `matchMedia` / hook approach.
- **Flash:** Exactly **one** `<.flash_group>` per document from **`Layouts.app`** on `/ops` paths (D-17).
- **Navigation:** Internal `/ops` links — **`<.link navigate={~p"…"}>`** or **`push_patch`** where appropriate; no stray marketing shell on ops routes (D-15, D-18).
- **`live_title`:** Replace stock **“· Phoenix Framework”** suffix on **`/ops`** with product-appropriate suffix; marketing `/` may differ (D-16, discretion).

---

## Registry Safety

| Registry | Blocks / packages | Safety Gate |
|----------|-------------------|-------------|
| **shadcn official** | — | **not applicable** (no shadcn) |
| **Third-party shadcn registries** | **none** | — |
| **Vendored assets** | `vendor/daisyui`, `vendor/daisyui-theme`, `vendor/heroicons` committed in-repo | **PASS — vendored source in repo; no remote block fetch** — reviewed 2026-04-21 |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-04-21

---

## Verification notes (orchestrator)

**Dimension 1:** All CTAs use **verb + object**; empty/error patterns include **next steps**; no generic Submit/OK/Cancel as primary.

**Dimension 2:** Focal hierarchy and scaffold rules declared; table/wide variant documented.

**Dimension 3:** Accent list is **restricted**; 60/30/10 explicit; destructive tied to **error** semantic.

**Dimension 4:** Four sizes (14, 16, 18, 24), two weights (400, 600), line heights set.

**Dimension 5:** All scale values multiples of 4; standard set only.

**Dimension 6:** No third-party shadcn registry; vendored plugins documented with PASS evidence.
