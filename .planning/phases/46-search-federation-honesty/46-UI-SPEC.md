---
phase: 46
slug: search-federation-honesty
status: approved
shadcn_initialized: false
preset: none
created: 2026-04-21
reviewed_at: 2026-04-21T00:00:00Z
---

# Phase 46 — UI Design Contract

> Visual and interaction contract for **Search & federation honesty** (OPSUI-04, OPSUI-05). Phoenix LiveView under `/ops/search`; semantics must match `guides/multi-index-search.md` and `%Scrypath.MultiSearchResult{}` (no merged-index illusion).

**Primary focal (first paint):** Persistent **environment / non-production** honesty strip at the top of the content column, followed by the **bounded query** controls (single- vs multi-search mode, explicit limits).

**Secondary focal:** Multi-search inspector: **per-schema** panels driven from `results.ordered`, plus an explicit **merge / federation** panel when metadata exists (`merge_projection/1`, weights, partial failures, `:all` expansion footnote).

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none (Phoenix + Tailwind v4 + daisyUI — not shadcn/React) |
| Preset | not applicable |
| Component library | Phoenix `core_components`, daisyUI semantic tokens (`base-*`, `primary`, `warning`, `error`), Heroicons via `@plugin "../vendor/heroicons"` |
| Icon library | Heroicons (outline for nav/decoration; no icon-only primary actions) |
| Font | System / Phoenix defaults (Tailwind `font-sans` stack) |

---

## Spacing Scale

Declared values (multiples of 4 only):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Inline code padding, tight label-to-control gap |
| sm | 8px | Banner padding-y, compact stacks |
| md | 16px | Default vertical rhythm between blocks |
| lg | 24px | Card / inspector section padding |
| xl | 32px | Major section separation (query vs results) |
| 2xl | 48px | Page title to first interactive block |
| 3xl | 64px | Rare — only if a future split-pane layout needs it |

Exceptions: **none** (touch targets follow at least 40px height via padding + line-height, composed from 4px multiples).

---

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|---------------|
| Body | 16px | 400 | 1.5 |
| Label | 14px | 600 | 1.4 |
| Heading | 20px | 600 | 1.25 |
| Display | 28px | 600 | 1.2 |

---

## Color

Semantic mapping uses **light** daisyUI theme tokens from `scrypath_ops/assets/css/app.css` (operator desktop-first). Approximate hex anchors for planners:

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `#fafafa` (`base-100`) | Page background |
| Secondary (30%) | `#f4f4f5` (`base-200`) | Cards, inspector panels, `<details>` diagnostic shells |
| Accent (10%) | `#ea580c` (`primary`) | **Reserved only for:** primary search CTA, **one** active mode toggle (single vs multi), keyboard focus ring emphasis on the primary text field |
| Destructive | `#dc2626` (`error` family) | Hard failures (`{:error, _}` from `search_many/2`), never for partial multi-search success paths |

Accent reserved for: **Run sample searches** button, **active** single/multi mode control, **focused** primary query field outline — **not** per-hit links, not table zebra, not warning banners (those use `warning`).

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA | **Run sample searches** |
| Empty state heading | **No sample results yet** |
| Empty state body | **Submit a bounded query above** to fetch read-only hits from the allowlisted schemas. Increase limits only when you understand Meilisearch cost and cardinality (see `guides/multi-index-search.md`). |
| Error state (hard `{:error, reason}`) | **Search could not run:** plain-language summary of the reason class (for example too many schemas, invalid federation options, missing backend). **Next:** fix the query options or operator config, then use **Run sample searches** again. Link to `guides/multi-index-search.md` for merge and expansion semantics. |
| Partial failure (`:ok` with `failures != []`) | **Some indexes did not return results.** Body: failures are **per schema** and do not cancel the whole response. **Next:** open **failure details** (`<details>`) for `inspect`-style reasons, adjust entries or backend, re-run **Run sample searches**. |
| Non-production / privileged banner | **Non-production search playground** — exploratory queries may be logged by Meilisearch or proxies depending on deployment. **Do not** paste production secrets or PII; keep `page.size` and schema lists bounded. |
| Federation honesty caption | **Merged order is a federation view** — per-schema relevance scores stay local; positions in the merge list are **not** a single-index ranking. |
| `:all` expansion footnote | **`:all` entries expanded** to the configured global schema list **in declaration order** before limits apply; empty registry and missing `otp_app` errors match library `{:invalid_options, {:all_expansion, _}}` vocabulary. |
| Destructive confirmation | *No destructive operator actions in this phase* — **n/a** |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none — Elixir/LiveView UI | not required |
| Third-party shadcn registries | none | not required |

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

## Implementation notes (for planner)

- **Route:** `live "/search", SearchLive` → `/ops/search`.
- **Single-search panel:** optional thin path using `Scrypath.search/3` (or documented equivalent) with the same honesty banner and bounded `page.size`.
- **Multi-search panel:** render from **`results.ordered`** only; duplicate schema handling per guide (`by_schema` last-wins vs ordered iteration).
- **Inspector rows:** show **merge order** (from `merge_projection/1` when present), **federation weights** when set and native federation applied, **partial failure list** mirroring `%{schema: _, reason: _}` maps, **truncation / limit errors** as hard errors not silent clamps.
- **Telemetry:** follow phase 45 precedent — low-cardinality events only; no hot-path per-schema labels (`docs/search-backend-sre.md`).
- **Accessibility:** partial-failure banner `aria-live="polite"`; `<details>` for operator diagnostics (per guide snippet intent).
