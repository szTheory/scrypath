---
phase: 60
slug: playbook-liveview-and-ia
status: approved
shadcn_initialized: false
preset: none
created: 2026-04-22
reviewed_at: "2026-04-22T00:00:00Z"
---

# Phase 60 — UI Design Contract

> Visual and interaction contract for **Playbook LiveView and IA** (**OPS-PB-02**, **OPS-PB-04**). Stack is **Phoenix LiveView** in `scrypath_ops` (not React); extends existing `/ops` shell used by `SearchLive`, `PostureLive`, etc.

**Sources:** `.planning/REQUIREMENTS.md` (**OPS-PB-02**, **OPS-PB-04**); `.planning/STATE.md`; `scrypath_ops/lib/scrypath_ops_web/live/search_live.ex` (honesty panel + bounded-run patterns); `scrypath_ops/lib/scrypath_ops_web/components/core_components.ex`; `scrypath_ops/assets/css/app.css` (daisyUI themes); `.planning/phases/59-playbook-schema-and-persistence-mvp/59-CONTEXT.md` (file-backed persistence, no secrets in JSON).

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none (no shadcn — Elixir / Phoenix) |
| Preset | not applicable |
| Component library | **daisyUI** (`btn`, `card`, `alert`, `input`, `select`, `menu`, `navbar`, etc.) + **`ScrypathOpsWeb.CoreComponents`** (`Layouts.app`, `flash`, `button`, `input`, `icon`, shared patterns) |
| Icon library | **Heroicons** via vendored Tailwind plugin (`assets/vendor/heroicons`; `CoreComponents.icon/1`) |
| Font | System UI stack from Phoenix / Tailwind defaults (no custom webfont for this phase) |

**Stack note:** Tailwind CSS v4 with `@import "tailwindcss"` and **vendored** `@plugin` files for daisyUI + themes under `scrypath_ops/assets/` — treat as **repo-pinned**, not ad-hoc CDN widgets.

---

## Spacing Scale

Declared values (multiples of 4px; use Tailwind spacing where possible):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Tight inline gaps, `gap-xs` / `p-1` class family |
| sm | 8px | Compact stacks (`space-y-2`, `gap-2`, `px-sm` / `py-sm` when matching 8px) |
| md | 16px | Default field groups (`space-y-4`, `gap-4`) |
| lg | 24px | Card interior padding (`p-6` on wide surfaces) |
| xl | 32px | Section breaks between major blocks |
| 2xl | 48px | Rare page-level breathing room |
| 3xl | 64px | Not used by default on `/ops` (narrow shell) |

**Exceptions:** `min-h-10` (40px) on primary **submit**-style controls to match `SearchLive` — 40 is a multiple of 4. Prefer **`max-w-*`** + `min-w-0` on flex children to avoid overflow in playbook JSON previews.

---

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|---------------|
| Body | 16px (`text-base`) | 400 | 1.5 |
| Label / legend | 14px (`text-sm`) + `font-semibold` where needed | 600 | 1.45 |
| Heading (page / card) | 20px (`text-lg` or `text-heading` if defined in app CSS) | 600 | 1.25 |
| Meta / code hints | 12px (`text-xs`) | 400 | 1.4 |

**Hierarchy:** Page title via shared `ops_page_header` pattern; section **`<legend>`** text uses **label** row; monospace snippets use `font-mono text-xs` for playbook paths and schema names (same as search playground).

---

## Color

Map to **daisyUI semantic tokens** (light/dark via `data-theme` / system — see `app.css` D-07 comment). Do **not** introduce raw hex in HEEx for surfaces.

| Role | Token / class | Usage |
|------|---------------|--------|
| Dominant (~60%) | `base-100`, `base-content` | Page background, default text |
| Secondary (~30%) | `base-200`, `base-300`, `card` + `border-base-300` | Cards, fieldsets, dividers |
| Accent (~10%) | `primary`, `text-primary`, `btn-primary` | **Reserved for:** (1) primary action buttons (**Save playbook to disk**, **Run saved playbook**, **Import playbook JSON**), (2) **active** mode toggle state (match `SearchLive` single/multi pattern), (3) **current** primary nav item affordance if distinct from hover-only links |
| Warning (honesty / federation) | `warning` / `border-warning/40` / `bg-warning/10` | **Non-production** and bounded-run disclaimers — **reuse** `SearchLive` honesty panel styling |
| Destructive | `error` / `alert-error` / `btn-error` (if used) | Validation failures, disk/export errors, and **Delete playbook file** only |

**Accent reserved for:** primary CTAs, active mode chips, optional nav-active emphasis — **not** every `link` (use `link link-hover` with default content color for doc links).

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary run CTA | **Run saved playbook** (executes validated playbook through the same bounded path as the playground) |
| Secondary save CTA | **Save playbook to disk** (after in-memory edit or compose flow) |
| Import CTA | **Import playbook JSON** (file upload or paste surface — planner picks; label stays verb + noun) |
| Honesty panel title | **Non-production playbook workspace** — body must state: exploratory runs may be logged; **do not** paste secrets or PII; cite bounded `page.size` / schema caps (mirror tone of existing search panel). |
| Empty state heading | **No playbooks in this folder** |
| Empty state body | **Export a playbook from Search** (or **Import playbook JSON**) **to add a `.json` file here.** Link to `scrypath_ops/docs/playbook-schema-v1.md` when shown in UI. |
| Load error (invalid JSON) | **This file is not valid playbook JSON.** Next: fix the file or pick another, then use **Import playbook JSON** again. |
| Validation error (`Playbook.V1`) | **Playbook failed validation:** show machine-readable reason; next step: **Edit JSON** (if inline) or fix offline, then **Import playbook JSON** / **Reload list**. |
| Run error (dispatch) | **Playbook run failed:** reuse `SearchLive`-style pattern — problem line + **Next:** adjust entries or operator config, then **Run saved playbook** again; link multi-index guide when mode is `search_many`. |
| Destructive confirmation | **Delete playbook file:** confirm modal or typed slug: **This permanently deletes `{filename}` from the playbook directory. This cannot be undone.** |

---

## Visual hierarchy (focal contract)

1. **First:** Non-production honesty panel (full width, warning surface) — operator must see posture before acting.  
2. **Second:** Primary workspace — **either** playbook list (table or card list) **or** editor/run split as planned; list **Name**, **Mode** (`search` / `search_many`), **Updated**, **Actions** column.  
3. **Third:** Secondary actions (import, refresh list) in a subdued row (`text-sm`, `btn-ghost` / outline).  

Icon-only buttons (if any): require **`aria-label`** matching visible action text.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn / React registries | — | **not applicable** — this phase is Phoenix HEEx only |
| daisyUI + Heroicons (vendored under `assets/vendor/`) | Project-shipped plugins | **Repo-pinned** — bump only via explicit dependency / vendor file update and normal code review (no `npx shadcn view` gate) |

No third-party **shadcn** blocks or remote component registries for Phase 60.

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-04-22

---

## OPS-PB-04 (IA alignment)

- New or updated **`ScrypathOpsWeb.Nav.primary/0`** label must match **`scrypath_ops/docs/operator-ia.md`** JTBD wording (e.g. **Saved playbooks** or agreed subsection title) so **`mix scrypath_ops.check_nav_contract`** stays green.  
- Router path under **`/ops/...`** must appear in IA doc the same way as existing ops routes.
