---
phase: 62
slug: playground-capture-and-playbook-catalog
status: draft
shadcn_initialized: false
preset: none
created: 2026-04-22
---

# Phase 62 — UI Design Contract

> Visual and interaction contract for **OPSUI** — Search playground capture into **`playbook_format: 1`**, playbook catalog legibility (title/description), and rename/duplicate flows. Stack: **Phoenix LiveView**, **Tailwind CSS v4**, **daisyUI** (vendored themes in `scrypath_ops/assets/css/app.css`), **Heroicons** plugin. Verified against **OPS2-01**–**OPS2-03** and existing **SearchLive** / **PlaybookLive** patterns.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none (no shadcn / no separate component CLI) |
| Preset | not applicable |
| Component library | daisyUI primitives (`btn`, `card`, `input`, `alert`, `modal`, `menu`, `link`, `fieldset` / `legend` patterns as today) |
| Icon library | Heroicons (Tailwind `@plugin` vendor path) |
| Font | System / browser default stack via Tailwind + daisyUI themes (no custom webfont for `/ops`) |

**Implementation seam:** New markup lives under `scrypath_ops/lib/scrypath_ops_web/live/` and shared components under `scrypath_ops_web/components/`, using `Layouts.app` with `shell={@shell}` and existing `ops_main_width` conventions (`:wide` where table- or two-column layouts need room, matching Search + Playbooks).

---

## Spacing Scale

Declared values for **new** Phase 62 markup — **multiples of 4px**. Reuse existing class names already scanned in HEEx where they match this scale.

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Tight inline gaps (`gap-1`), legend padding |
| sm | 8px | Compact stacks (`space-y-sm`, `gap-sm`), small control groups |
| md | 16px | Default vertical rhythm inside cards (`space-y-md`), `p-md` panels |
| lg | 24px | Spacious panels (`p-lg`), section breathing room |
| xl | 32px | Major breaks between page-level blocks (prefer existing `space-y-6` = 24px only when matching parent; use `space-y-6` / `space-y-8` consistently with sibling routes) |
| 2xl | 48px | Page outer padding already from layout (`py-10` on `main`) — do not add extra 48px wrappers without cause |

**Exceptions:** Continue **`space-y-6`** on the outer LiveView wrapper for **Search** and **Playbooks** parity (`24px`). Inner fieldsets keep **`space-y-sm`** as today.

---

## Typography

At most **four** size roles on new surfaces (checker-safe):

| Role | Classes / size | Weight | Line height |
|------|----------------|--------|-------------|
| Page title (`h1`) | `text-2xl font-semibold leading-8 tracking-tight` via `ops_page_header` | semibold | tight (leading-8) |
| Section title (`h2` in card) | `text-lg font-semibold` | semibold | default |
| Body, labels, helpers | `text-sm` (or `text-base` only where an existing route already uses it — do not mix both on the same new panel) with `text-base-content` / opacity variants | normal / semibold for labels | default |
| Monospace / JSON | `font-mono text-xs` | normal | pre-wrap where preview |

**Rule:** Do **not** introduce additional heading utilities beyond this table and existing **`text-heading font-semibold`** usages already on **SearchLive** result headings; new Phase 62 headings use **`text-lg font-semibold`** to match **PlaybookLive** section titles.

---

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | daisyUI `base-100` / `base-content` | Page background, default text |
| Secondary (30%) | `base-200` / `base-300` borders | Panels, list wells, preview `pre` background |
| Accent (10%) | `primary` + `primary-content` | **One** primary action per logical step (e.g. run search, save playbook, confirm rename) |
| Semantic warning | `warning` / `warning/10` border | Honesty / non-production panels (`search-honesty-panel`, `playbook-honesty-panel` pattern) |
| Semantic error | `error` / `alert-error` | Validation failures, blocked saves, run failures |
| Semantic success | `success` / `alert-success` | Successful save, successful validation handoff |
| Destructive | `btn-error`, `btn-outline` for list actions; solid `btn-error` in modal confirm | Delete, and **any new destructive overwrite** (e.g. replace-on-save if explicitly chosen) |

**Accent reserved for:** Primary submit buttons (`btn-primary`), active mode toggle state on Search (`btn-primary` on selected mode), **first** positive action in a focused flow (e.g. **Save search as playbook** when no competing primary on the same row). **Not** for plain navigation links — use `link link-hover` / `link-primary` only where emphasis matches existing Search playbook link.

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA — capture | **Save search as playbook** (opens or focuses preview + metadata step; must be verb + object) |
| Primary CTA — run (unchanged context) | **Run sample searches** (existing Search form) |
| Primary CTA — persist (workspace) | **Save playbook to workspace** (or keep **Save playbook to disk** if copy already shipped — align one string in implementation pass; prefer **Save playbook to workspace** when `SCRYPATH_OPS_PLAYBOOK_DIR` is the mental model in docs) |
| Secondary CTA — preview | **Preview playbook JSON** (when separating preview from save) |
| Empty state — catalog list | Heading: **No playbooks in this folder** — body: keep next step to export from Search, import JSON, or save from playground; link **playbook-schema-v1.md** by title. |
| Empty state — capture (no successful run yet) | **Run a search first** — body: explain that the playbook captures the **last successful** single- or multi-search inputs (honesty caps included), then link to honesty panel. |
| Error — validation (`V1` / codec) | **Playbook JSON failed validation** — body: one-line reason + **Next:** open **`scrypath_ops/docs/playbook-schema-v1.md`** or adjust fields, then retry preview. |
| Error — basename / collision | **That playbook name is already in use** — body: suggest **pick a new `.json` basename** or use **Duplicate playbook** (when present) with suggested name. |
| Error — missing workspace | **Playbook workspace is not configured** — body: set **`SCRYPATH_OPS_PLAYBOOK_DIR`** (or env name in README), reload, then save again. |
| Destructive confirmation — delete | Keep **PlaybookLive** pattern: title **Delete playbook file**, instruction **Type the filename to confirm**, actions **Cancel** / **Confirm delete**. |
| Destructive / lossy — rename or overwrite | If rename can overwrite: modal title **Rename playbook file**, body names old → new, confirm button **Rename playbook**; require typed basename or explicit checkbox **I understand this replaces the target file** only if product chooses overwrite — default spec: **no silent overwrite**; collision = error copy above. |
| Metadata labels | **Playbook title**, **Short description**, **Tags (optional)** — helper text: **Shown in the playbook list; stored in JSON per schema doc.** |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| daisyUI (vendored `vendor/daisyui.js` + theme plugins) | Buttons, inputs, alerts, cards, modals, menus | not required |
| Heroicons (vendored `@plugin`) | `hero-*` only if icons added; text-first Phase 62 OK without new icons | not required |
| shadcn / third-party React | none | n/a |

---

## Interaction & layout contracts (Phase 62–specific)

1. **Capture entry:** On **Search** (`SearchLive`), after at least one successful run in the current session (or “last good” state as implemented), show a secondary panel **Save search as playbook** with fields for **title**, **description**, optional **tags**, and **basename** — default basename slugified from title with collision check. **Honesty panel** remains the first landmark for safety copy; capture panel references it (`aria-describedby` where a field depends on caps).
2. **Preview:** Read-only `pre` (same visual as **PlaybookLive** preview: `max-h-96`, `bg-base-200`, `font-mono text-xs`). Show **Validated playbook preview** marker when `V1` validation passes (reuse `data-testid` pattern from playbooks where useful).
3. **List / detail:** Workspace list rows show **title** (primary line), **description** (muted secondary line, truncated with CSS), basename in mono smaller — legacy files without metadata show documented default **Untitled playbook** (or equivalent) per **OPS2-03**; do not show raw JSON in the list.
4. **Rename / duplicate:** Actions use `btn-ghost` / `btn-sm` row pattern consistent with **Load** / **Delete**. **Duplicate** suggests `copy-of-<stem>-<n>.json` in a field before commit. Destructive paths follow **PlaybookLive** modal + explicit confirm; no single-click delete/rename.

**Focal point:** On Search, primary focal remains **Run sample searches** until results exist; then focal shifts to the capture card **without** demoting honesty panel visibility (warning panel stays above the card stack order as today).

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS

**Approval:** pending

---

## UI checker result (inline — `/gsd-ui-phase` 2026-04-22)

**## UI-SPEC VERIFIED**

| Dimension | Verdict | Notes |
|-----------|---------|-------|
| 1 Copywriting | PASS | CTAs are verb+noun; empty/error copy includes next step + doc anchor. |
| 2 Visuals | PASS | Focal hierarchy and honesty-panel precedence declared. |
| 3 Color | PASS | Accent scoped; destructive/error/warning paths tied to daisyUI roles. |
| 4 Typography | PASS | Four roles max on new surfaces. |
| 5 Spacing | PASS | 4px-multiple table + explicit exceptions. |
| 6 Registry | PASS | daisyUI + vendored Heroicons only; no third-party shadcn blocks. |

**FLAG (non-blocking):** Align **Save playbook to workspace** vs legacy **Save playbook to disk** in one implementation pass to avoid duplicate primary strings in the app.
