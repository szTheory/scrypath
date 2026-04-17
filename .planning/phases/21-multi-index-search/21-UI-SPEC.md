---
phase: 21
slug: multi-index-search
status: approved
shadcn_initialized: false
preset: none
created: 2026-04-17
reviewed_at: "2026-04-17T18:00:00.000Z"
---

# Phase 21 — UI Design Contract

> Visual and interaction contract for **guides/multi-index-search.md** and reference HEEx in Phase 21. Scrypath ships documentation-first LiveView patterns (Elixir OSS library), not a separate frontend bundle. Sources: `.planning/ROADMAP.md` (Phase 21 + MULTI-11), `.planning/REQUIREMENTS.md` (MULTI-01..13), `.planning/phases/21-multi-index-search/21-CONTEXT.md` (D-01, D-06). Aligns with Phase 20 tokens where the faceted-search guide is cross-linked.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none (no `components.json`; Elixir/OSS library) |
| Preset | not applicable |
| Component library | Phoenix LiveView + `Phoenix.Component` (`~H` HEEx) |
| Icon library | Heroicons outline (optional) or minimal inline SVG — no third-party React kit |
| Font | System UI stack in prose (`font-sans` / browser default); no custom webfont in the guide |

**Manual design system declaration (registry dimension):** All interactive examples use Phoenix-first markup and Tailwind-compatible utilities exactly as written in the guide. No npm/shadcn registry surface for Phase 21.

---

## Spacing Scale

Declared values (multiples of 4; map to Tailwind `gap-*`, `p-*`, `space-y-*`):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon-to-label gap, dense inline controls |
| sm | 8px | Within-panel control stack, chip gap |
| md | 16px | Per-schema panel padding |
| lg | 24px | Gap between dashboard columns / stacked sections |
| xl | 32px | Vertical rhythm between major dashboard bands |
| 2xl | 48px | Before appendix / cross-links block |
| 3xl | 64px | not used in primary worked example |

Exceptions:

- **44px minimum** touch target for section-level **Retry** and **Dismiss banner** where mobile matters: `min-h-11 min-w-11` (WCAG 2.5.5); 44 is a multiple of 4.

---

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|---------------|
| Body | 16px (1rem) | 400 | 1.5 |
| Label | 14px (0.875rem) | 400 | 1.4 |
| Heading | 20px (1.25rem) | 600 | 1.25 |
| Display | 28px (1.75rem) | 600 | 1.2 |

**Weights used in examples: 400 and 600 only** — labels rely on size/color, not a third weight. At most these four roles appear in the worked 4-schema dashboard; prose outside snippets stays ExDoc default.

---

## Color

Semantic roles for light-mode examples (Tailwind zinc/sky idiom; dark mode optional note in appendix only):

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `#fafafa` (`bg-zinc-50`) | Page background behind the multi-section layout |
| Secondary (30%) | `#ffffff` + `#e4e4e7` border (`bg-white border border-zinc-200`) | Each schema’s panel, hit cards, facet blocks |
| Accent (10%) | `#0284c7` (`sky-600`) | Single primary **Run federated search** control, active per-section focus ring, linked “open details” affordance |
| Destructive | `#dc2626` (`red-600`) | **Clear this section’s search** when presented as resetting user-entered query text (confirm copy required) |
| Warning surface | `#fef3c7` (`amber-100`) + `#92400e` text (`amber-900`) | Non-blocking partial-failure banner (transport / hydration) — not `role="alert"` unless the whole dashboard is blocked |

**60/30/10** split is explicit in the table above.

**Accent reserved for:** (1) one primary federated-submit control per documented screen state, (2) `:focus-visible` rings on section search fields, (3) schema-panel section title emphasis when a single panel is “active” in the narrative step. **Not** for: passive bucket counts, every secondary button, body links, or neutral banner dismiss.

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA | **Run federated search** (submits all section queries via `Scrypath.search_many/2` with the tuple list built from assigns) |
| Per-section secondary | **Search this section** (optional when the guide shows independent `push_patch` per panel) |
| Empty state heading (per schema) | **No matches in {Section title}** (e.g. Posts, Users — human-readable module label from guide fixture) |
| Empty state body | **Try a shorter query or clear filters for this section. Other sections keep their own results.** |
| Partial failure banner (user) | **Some sections could not load.** Then schema-labeled line from `user_message(schema, reason)` — never raw `inspect/1` in default HEEx. |
| Partial failure details | `<details>` summary: **Why sections failed** — bucket text (transport / hydration / validation family) per guide table; optional dev assign in appendix only |
| Retry (transport-shaped) | **Retry failed sections** |
| Hydration timeout | **Showing results for other sections. One section timed out while loading records.** |
| Hard error (`{:error, _}` from `search_many/2`) | **Search could not run.** Monospace snippet of tagged error for dev guide, then **Fix filters or try again** |
| Destructive confirmation | **Clear this section’s search**: **Remove the query text for {section}?** — confirm **Clear search**, cancel **Keep query** |

**Accessibility:** Partial-failure region uses **`aria-live="polite"`** (per CONTEXT D-06). Use **`role="alert"`** only when the guide documents a full blocking error state with no partial results.

**Chip / dismiss:** Removable facet chips keep **Remove {facet}: {value}** `aria-label` pattern from Phase 20 where facets appear inside a section.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | not required |
| Third-party UI registries | none | not applicable — Phase 21 is HEEx-in-guide only |

---

## LiveView layout & interaction (MULTI-11)

**Locked** for the worked **4-schema federated dashboard** example:

1. **Visual hierarchy:** **Declaration order** — each schema is a **distinct panel** (card) in the same vertical or responsive grid; never imply a single merged hit list. Primary **Run federated search** sits in a **global rail** above the panel stack (or spans first column on wide layouts).
2. **Per-schema facets:** Each panel that demonstrates `facets:` shows facet UI **inside that panel only** — facet distribution matches solo `search/3` (MULTI-08); guide text states **`mergeFacets` is never sent**.
3. **Duplicate schema panels:** If the narrative shows the same schema twice, the HEEx **must** iterate `for {schema, result} <- results.ordered` — callout box: **`by_schema` is last-wins; two panels require `ordered`**.
4. **URL sync:** **`handle_params/3`** owns query + per-section facet state; **`mount/3`** static; **namespaced URL keys** (e.g. `post_q`, `user_q`) per CONTEXT D-01 — document encoding; **`push_patch`** for same LiveView.
5. **“Same `q` everywhere” recipe:** Clearly labeled **secondary** subsection — one assign threaded into each tuple’s `text`; callout: **ranking scores are not comparable across schemas**.
6. **Loading:** While `search_many/2` is in flight, disable the primary CTA with **Searching…** and set **`aria-busy="true"`** on the multi-panel results container.
7. **Partial failure demos:** Full walkthroughs for (a) **`reason: :hydration_timeout`** with other panels intact + facets, (b) **transport-shaped** `reason` with banner + retry; (c) **validation** reasons as a **compact table** mapping reason family → UX copy (not a third full story).

**Telemetry:** Guide cross-links operator/sre guidance to `[:scrypath, :search_many, *]` events (MULTI-13); in-page `federation` assign may be `nil` while telemetry still fires (CONTEXT D-04).

---

## Anti-pattern appendix (guide tone)

Each entry includes **one-line consequence** for doc review (MULTI-11 + planner verification):

1. **Rendering from `by_schema` when duplicates exist** — second panel silently wrong or empty.
2. **One URL param overloaded per schema** — deep links corrupt unrelated sections’ meaning.
3. **Implying cross-schema relevance or merged facets** — violates product boundary; adopters mis-tune UX.
4. **`role="alert"` for partial hydration failure** — screen reader overload; use `polite` unless no results at all.
5. **Raw `inspect(reason)` in production HEEx** — leaks internals; use `user_message/2` + operator logging pattern.
6. **Silent truncation on rail exceed** — violates MULTI-10; must surface explicit error tuple messaging in UI.
7. **Skipping `ordered` in failure UI** — failures list order must align with tuple slots when matching banners to panels.

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-04-17 (orchestrator verification against gsd-ui-checker six dimensions; no third-party registry)
