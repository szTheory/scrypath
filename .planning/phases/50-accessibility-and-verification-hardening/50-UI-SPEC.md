---
phase: 50
slug: accessibility-and-verification-hardening
status: approved
shadcn_initialized: false
preset: none
created: 2026-04-21
reviewed_at: 2026-04-21
---

# Phase 50 — UI Design Contract

> Visual, semantic, and interaction contract for **OPSUX-06** / **OPSUX-07** on **`scrypath_ops`** (`/ops`). Generated for `/gsd-ui-phase`; stack is **Phoenix LiveView + HEEx**, not React/shadcn.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none (Phoenix / HEEx) |
| Preset | not applicable |
| Component library | Phoenix `CoreComponents` + **daisyUI** (vendored `@plugin` in `scrypath_ops/assets/css/app.css`) |
| Icon library | **Heroicons** (`heroicons` Tailwind plugin, `mix.exs`) |
| Font | System / browser default stack (no custom webfont in ops shell) |

**Source:** `50-RESEARCH.md` § Phoenix LiveView + HEEx; `scrypath_ops/assets/css/app.css` (DaisyUI themes **light** / **dark**).

### Visual hierarchy (focal points)

- **Primary anchor:** the single page **`<h1>`** from **`ops_page_header`**, aligned with **`assigns.page_title`** — this is the first scan target for operators.
- **Secondary anchor:** the first **JTBD / `ops_panel`** block under **`main#ops-main`** (tables, playground fieldsets, or honesty panels per route).

---

## Spacing Scale

Declared values (multiples of **4px**; map to Tailwind spacing utilities already used in `:ops` shell):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px (`p-1`, `gap-1`) | Icon gaps, tight inline padding |
| sm | 8px (`gap-2`, `p-2`) | Compact stacks, menu density |
| md | 16px (`px-4`, `py-4`, `gap-4`) | Default block / form spacing |
| lg | 24px (`gap-6`) | Section breathing room |
| xl | 32px (`gap-8`) | Major stacks |
| 2xl | 48px | Rare section breaks |
| 3xl | 64px | Page-level vertical rhythm (with `py-10` = 40px only where legacy shell already uses it — **do not introduce new non‑4px rhythm tokens**; prefer `py-8` / `py-12` for new layout) |

**Exceptions:** **none** for new markup. (Existing `py-10` in `Layouts.app` shell retained until a dedicated shell refactor; new components use the scale above.)

**Locked semantics spacing (non-visual):** Skip link remains **first focusable** in document order per **50-CONTEXT** **D-02**.

---

## Typography

| Role | Size | Weight | Line height |
|------|------|--------|-------------|
| Body | 16px (`text-base`) | 400 | 1.5 |
| Label / chrome | 14px (`text-sm`) | 400 | 1.45 |
| Heading (section `h2`) | 20px (`text-xl`) | 600 (`font-semibold`) | 1.25 |
| Display (page `h1` via `ops_page_header`) | ~28px (`text-3xl` class family from Phase 49 header primitive) | 600 | 1.2 |

**Source:** Phase **49** scaffold + **50-CONTEXT** **D-01** / **D-03** (single visible `h1`, then `h2` / `h3` ladder).

---

## Color

Semantic roles follow **DaisyUI** tokens in `app.css` (light/dark + system effective theme). Ratios are **perceptual** (ops chrome), not literal pixel %.

| Role | Token | Usage |
|------|-------|-------|
| Dominant (~60%) | `base-100` | Page background, main reading surface |
| Secondary (~30%) | `base-200`, `base-300`, `border-base-300` | Cards, nav bar surface, dividers |
| Accent (~10%) | `primary`, `primary-content` | **Reserved for:** primary form submit (`btn-primary`), **one** high-signal inline link per JTBD block when emphasis is required, **visible `:focus-visible` outline** pairing (same hue family as theme primary) |
| Destructive | `error` / `btn-error` / `text-error` | Rare destructive or **highest-severity** operator alerts only (not routine warnings) |

**Accent reserved for:** primary **Run** actions on bounded playground, **primary** CTA buttons, **active** high-emphasis control state — **not** for every `btn-ghost`, plain nav links, or table body text.

**Source:** `50-CONTEXT` **D-23** (boring semantic HTML over decorative noise); Phase **49** theme work.

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA (playground) | **Run playground search** |
| Empty state heading (failed sync rollups) | **No failed sync work matches this view** |
| Empty state body | **Try another queue or time window. If this is unexpected, run `mix scrypath_ops.check_nav_contract` and confirm Oban is processing jobs — see the operator sync guide linked from Posture.** |
| Error state (search / Meilisearch unreachable) | **Meilisearch is not responding. Confirm the instance URL and API key, then open `guides/meilisearch-operations.md` and retry Run playground search.** |
| Skip link (first focusable) | **Skip to operator content** |
| Destructive confirmation | **Not used in Phase 50** (read-only ops). If a future destructive action ships: **Remove {resource label}: type the resource id to confirm**, with `aria-describedby` pointing to irreversible consequence copy. |

**Source:** `50-CONTEXT` **D-02**, **D-16**; `operator-ia.md` tone; **REQUIREMENTS.md** **OPSUX-06** paths.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn / npm UI registries | none | not applicable |
| DaisyUI + themes | vendored files under `scrypath_ops/assets/vendor/` | **Committed vendor only** — `view passed — no flags — 2026-04-21` (no remote `npx shadcn` blocks in contract) |

---

## Semantics & structure (OPSUX-06) — executor checklist

Locked from **50-CONTEXT**; UI-SPEC does not re-open these.

- **One visible `h1` per `/ops` route** tied to `page_title` / `<.live_title>` (**D-01**).
- **Landmarks:** existing `<header>`, `<nav aria-label="Operator primary">`, `<main id="ops-main">` + skip link (**D-02**).
- **Sections:** 2–4 `<section aria-labelledby="…">` per page for first-class blocks; no landmark soup (**D-04**).
- **Forms:** concern-based `<fieldset>` / `<legend>` on playground; no nested `<form>` (**D-06**–**D-08**).
- **Tables:** real `<table>`, `th scope`, sort buttons with single `aria-sort` authority (**D-12**–**D-13**).
- **Live regions:** one primary polite `role="status"` for aggregate federation/backend chatter; `role="alert"` only for urgent connection loss (**D-10**).
- **Icons:** decorative `aria-hidden="true"`; icon-only buttons get concise `aria-label` (**D-11**).

---

## Verification posture (OPSUX-07)

- **Automated:** extend `operator_ia_contract_test`, `ops_shell_contract_test`, and new **DOM semantics** `LiveViewTest` modules — **no** whole-page HTML snapshot gates (**D-18**, **D-21**).
- **Canonical command:** `mix verify.opsui` from repo root (**D-19**, **50-RESEARCH.md**).
- **Manual:** keyboard + SR spot-check **posture → failed-sync → sync/drift → search** recorded in phase verification doc (**D-22**).

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-04-21
