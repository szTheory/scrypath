---
phase: 20
slug: faceted-search-liveview-guide
status: approved
shadcn_initialized: false
preset: none
created: 2026-04-17
reviewed_at: "2026-04-17T12:00:00.000Z"
---

# Phase 20 — UI Design Contract

> Visual and interaction contract for **guides/faceted-search-with-phoenix-liveview.md** and any reference HEEx in Phase 20. This library ships documentation-first UI patterns (Phoenix LiveView), not a separate frontend bundle. Generated for `/gsd-ui-phase 20`, verified inline (gsd-ui-checker criteria).

**Sources:** `.planning/ROADMAP.md` (Phase 20 goals + FACET-08), `.planning/REQUIREMENTS.md` (FACET-01..10), `.planning/research/deep/FACETING.md`, `guides/phoenix-liveview.md` (context boundary tone). No Phase 20 `CONTEXT.md` / `RESEARCH.md` yet — defaults follow Scrypath guide style.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none (no `components.json`; Elixir/OSS library) |
| Preset | not applicable |
| Component library | Phoenix LiveView + `Phoenix.Component` (`~H` HEEx) |
| Icon library | Heroicons outline (optional) or minimal inline SVG for chevrons/clear — never a third-party React kit |
| Font | System UI stack only in prose (`font-sans` / browser default); no custom webfont loading in the guide |

**Manual design system declaration (registry dimension):** All interactive examples in the faceted-search guide use Phoenix-first markup and Tailwind-compatible utility classes exactly as spelled in the guide snippets. No parallel design tool is required to ship Phase 20.

---

## Spacing Scale

Declared values (multiples of 4; map to Tailwind `gap-*`, `p-*`, `space-y-*` in snippets):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon-to-label gap, dense chip padding |
| sm | 8px | Checkbox row vertical rhythm, chip gap |
| md | 16px | Card/panel padding, sidebar section inset |
| lg | 24px | Between sidebar column and results column |
| xl | 32px | Page-level vertical rhythm between major blocks |
| 2xl | 48px | Rare — only before footer "Anti-patterns" appendix |
| 3xl | 64px | not used in the worked example (reserved for future full-page mock) |

Exceptions:

- **44px minimum** hit target on mobile-critical controls only (sidebar "Clear all filters", range slider thumb): document as `min-h-11 min-w-11` (2.75rem = 44px). Justification: WCAG 2.5.5 target size; 44 is a multiple of 4.

---

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 16px (1rem) | 400 | 1.5 |
| Label | 14px (0.875rem) | 500 | 1.4 |
| Heading | 20px (1.25rem) | 600 | 1.25 |
| Display (page title only) | 28px (1.75rem) | 600 | 1.2 |

Guide rule: at most these four roles appear in the worked LiveView example; prose paragraphs outside snippets stay ExDoc default (body-equivalent).

---

## Color

Semantic roles for light-mode examples (Tailwind zinc/sky idiom; dark mode optional callout only in appendix, not the primary worked UI):

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `#fafafa` (`bg-zinc-50`) | Page background behind results |
| Secondary (30%) | `#ffffff` with `#e4e4e7` border (`bg-white border border-zinc-200`) | Facet sidebar panel, result cards |
| Accent (10%) | `#0284c7` (`sky-600`) | Primary "Apply filters" / "Search catalog" control fill, active facet chip background, focused filter ring |
| Destructive | `#dc2626` (`red-600`) | "Clear all filters" text/button when presented as destructive; never used for neutral deselect |

Accent reserved for: **(1)** single primary action control per screen state, **(2)** active facet chips and slider track emphasis, **(3)** visible `:focus-visible` ring on sidebar controls. Not reserved for: passive checkboxes, static bucket counts, plain hyperlinks, or body text.

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA | **Search catalog** (submits query + applies current facet state to `Scrypath.search/3`) |
| Empty state heading | **No movies match these filters** |
| Empty state body | **Try removing one filter or shortening your search. Bucket counts update as you change filters.** |
| Error state | **Search could not complete.** Follow with inline reason from `{:error, _}` tuple in monospace, then: **Retry search** or **Remove the filter you added last** (both actionable). |
| Destructive confirmation | **Clear all filters**: modal/flash copy **Reset genre, year, rating, and director?** — confirm **Reset filters**, cancel **Keep filters** |

**Filter chip removal:** each removable chip exposes `aria-label` text **Remove {facet name}: {value}** (e.g. "Remove genre: Horror").

**Unknown facet error (FACET-03):** user-facing dev text in guide: **That attribute is not declared on this schema's `faceting:` list.** (maps to `{:error, {:unknown_facet, attr}}`).

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | not required |
| Third-party UI registries | none | not applicable — Phase 20 does not introduce npm blocks or `shadcn` registries |

---

## LiveView layout & interaction (FACET-08)

These are **locked** for the movies-by-genre-year-rating-director worked example:

1. **Visual hierarchy:** The **query field + primary CTA** is the focal column (upper results rail). The **facet sidebar** is the secondary anchor (left on `lg+`, stacked above on narrow viewports). Result hit list is tertiary flow below the rail.
2. **Sidebar checklist:** Genre and director as checkbox groups; year as multi-select checkboxes or toggle list (same semantics as `facet_filter` OR-within-field).
3. **Chip row:** Active `facet_filter` values render as dismissible chips between the search rail and results; clicking × removes one value and re-runs `Scrypath.search/3`.
4. **Numeric range:** Rating uses `facet_stats`-driven min/max labels and a range control; applying range triggers search with `facet_filter: [rating: [gte: _, lte: _]]` (exact operators per implementation).
5. **Search-within-facet:** Director (or secondary text facet) gets an optional text input that filters visible facet values client-side in the LiveView assign — guide must state this does **not** call Meilisearch facet-value search API (deferred per roadmap backlog); it is assign-filter only for v1.3.

**URL sync:** Deep-linkable query + facet state is **recommended** in the guide (`handle_params`); document `push_patch` vs initial mount clearly.

**Loading:** While `Scrypath.search/3` is in flight, show **Searching…** on the primary CTA (disabled) and `aria-busy="true"` on the results region.

---

## Anti-pattern appendix (guide tone)

The roadmap requires **7+** anti-pattern entries in the shipped guide; the UI-SPEC requires they each include a **one-line visual or interaction consequence** (e.g. double-fetch, misleading counts) so the checker/planner can verify FACET-08 completeness during doc review.

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-04-17 (orchestrated verification against gsd-ui-checker dimensions; no third-party registry surface)
