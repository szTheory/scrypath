---
phase: "185"
slug: "executable-ui-quality-foundations"
status: approved
reviewed_at: "2026-10-31T02:47:50Z"
shadcn_initialized: false
preset: none
created: "2026-10-30"
---

# Phase 185 — UI Design Contract

> Preservation contract for Phase 185's source and contrast foundations. It authorizes no visible redesign and does not claim a rendered review or aesthetic approval.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Manual, existing Phoenix HEEx + Tailwind CSS v4 + vendored daisyUI theme plugins |
| Preset | Not applicable; no shadcn initialization |
| Component library | Local `ScrypathOpsWeb.OpsUi` function components; existing daisyUI classes remain available |
| Icon library | Existing Heroicons integration |
| Font | Existing system sans stack; technical identifiers use the existing monospace stack |

Source of truth: `scrypath_ops/assets/css/app.css`, `scrypath_ops/assets/css/DESIGN-TOKENS.md`, `ScrypathOpsWeb.OpsUi`, root `DESIGN.md`, and the existing ecommerce stylesheet for the host storefront. Phase 185 may add the color-only Tailwind namespace reset to each stylesheet that builds the standalone and mounted UIs, restoring black/white utilities where required. Preserve both theme blocks, semantic daisyUI colors, the host storefront's separate palette, spacing/type namespaces, and all existing component styling. Do not add shadcn, a registry, or a new UI dependency.

## Component Inventory

Enumerated by `rg -c '^  def ops_[A-Za-z0-9_]+\(assigns\) do$' scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` — 50 components — `scrypath_ops@0.1.0` (local Mix app source, not an external UI package) — 2026-10-30.

Cross-check: `rg -n '^  def ops_[A-Za-z0-9_]+\(assigns\) do$' scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex | wc -l` also returns 50; all declarations are in the local `OpsUi` module.

This is a non-exhaustive list of existing components, not an allowlist. The local inventory is based on source exports because the project has no installed component-library package.

| Component | Import path | Notes |
|-----------|-------------|-------|
| `ops_scaffold` | `ScrypathOpsWeb.OpsUi` | Existing shell and shared page rhythm |
| `ops_page_header`, `ops_heading` | `ScrypathOpsWeb.OpsUi` | Existing page, section, and subsection hierarchy |
| `ops_button`, `ops_link_button`, `ops_refresh_button` | `ScrypathOpsWeb.OpsUi` | Existing action semantics, sizing, and feedback |
| `ops_notice`, `ops_status`, `ops_verdict` | `ScrypathOpsWeb.OpsUi` | Existing cause-specific operational status and neutral summaries |
| `ops_empty_state`, `ops_empty_hero`, `ops_loading` | `ScrypathOpsWeb.OpsUi` | Existing no-data, orientation, and in-flight treatments |
| `ops_schema_select`, `ops_segmented_control`, `ops_checkbox_list` | `ScrypathOpsWeb.OpsUi` | Existing native selection/form patterns |
| `ops_result_row`, `ops_object_list`, `ops_object_item`, `ops_signal_table` | `ScrypathOpsWeb.OpsUi` | Existing attributed results, saved searches, and comparisons |
| `ops_disclosure`, `ops_code_block`, `ops_modal`, `ops_sheet` | `ScrypathOpsWeb.OpsUi` | Existing technical detail and protected overlay interactions |
| `ops_help_link` | `ScrypathOpsWeb.OpsUi` | Existing contextual native Help destination |

---

## Spacing Scale

The Tailwind default spacing namespace must remain available in both generated bundles. The existing Ops token steps remain the local authority; this phase must not prune them as part of the color reset.

| Token | Value | Usage |
|-------|-------|-------|
| `--spacing-ops-1` | 4px | Compact gaps and component spacing |
| `--spacing-ops-2` | 8px | Control gaps and compact padding |
| `--spacing-ops-3` | 12px | Existing label-to-control spacing |
| `--spacing-ops-4` | 16px | Existing shell rhythm (`space-y-4`) and body spacing |
| `--spacing-ops-5` | 20px | Existing panel padding at wider widths |
| `--spacing-ops-6` | 24px | Existing section and named page gaps |
| Tailwind defaults | 32px, 48px, 64px remain available | Existing framework scale; do not remove or redefine |

Exceptions: the inherited Ops scale deliberately includes 12px and 20px steps; keep these established `--spacing-ops-*` roles. Preserve existing 40px standard controls and 44px prominent/icon-only targets. Do not add margins to direct shell children or create new spacing tokens for this phase.

---

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body and values | 14px | 400 | 1.5 |
| Labels and actions | 14px | 600 | 1.3 |
| Headings | 16px subsection, 18px section, 24px page title | 600 | 1.3 |
| Display | Not used | Not used | Not used |

Use the existing system sans stack for interface copy and monospace for exact identifiers/evidence. The core contract uses the inherited 400/600 roles above. Keep existing 11px/12px styling only for short timestamps, badges, and optional metadata; it must not carry required action, form, or failure instructions. Existing localized component declarations at other weights remain untouched; Phase 185 adds no typography restyling or weight normalization.

---

## Color

The 60/30/10 labels describe the existing surface hierarchy; they are not a measured area budget and must not trigger palette rebalancing.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | Ops `--ops-bg`: light `#f3f5f8`, dark `#111419` | Existing flat application floor |
| Secondary (30%) | Ops `--ops-surface-1` / `--ops-surface-2`: light `#ffffff` / `#edf1f5`, dark `#191e25` / `#222831` | Existing resting and raised surfaces; preserve neutral separation |
| Accent (10%) | Ops `--color-primary`: light `#5b4ad1`, dark `#aaa0ff` | Existing primary actions, active route/path marks, explicit selected states, and focus indicators only |
| Destructive | Existing `--ops-error-text`: light `#ad2922`, dark `#ffaaa2` | Existing explicit failure/destructive text only; do not apply to broad surfaces |

Accent reserved for: primary action affordances, current route/path emphasis, selected controls whose state is explicit, and the existing visible keyboard-focus indicator. Do not tint every interactive element. Preserve current secondary/status hues and semantic `base-content` foreground pairs in `DESIGN-TOKENS.md` and both daisyUI theme blocks.

The ecommerce storefront is a separate host design. Preserve its existing authored values (including `#f6f7f9` page floor, `#1f2933` body text, white surfaces, forest `#386641` accent, and `#243b53` focus treatment); do not recolor it to match the Ops palette. The host's mounted Ops shell retains the Ops light/dark themes.

Contrast enforcement is static token-pair evidence only: ordinary text stays at unrounded AA 4.5:1, demonstrably large text at 3:1, and meaningful non-text cues/focus indicators against their actual adjacent backgrounds at 3:1. Keep global 2px `:focus-visible` outlines with 2px offset and existing component inset-focus treatments. Both themes, selected/menu surfaces where used, muted-alpha compositing, and live focus declarations/token references remain covered. A passing static pair check is not a claim of complete accessibility or visibility in every rendered state. Preserve the current palette; any genuine contrast conflict remains a failure for maintainer resolution, never an exception or silent recolor.

---

## Copywriting Contract

Phase 185 introduces no product copy or new visible action. Retain the existing route-specific words and state distinctions.

| Element | Copy |
|---------|------|
| Primary CTA | No new CTA. Preserve existing task actions; Control Room entry actions remain “Try a search” and “Check sync and settings.” |
| Empty state heading | Keep each current screen's `ops_empty_state` / `ops_empty_hero` heading; do not replace with a shared generic heading. |
| Empty state body | Keep the current task-specific next step. An empty result/source is not missing configuration, failed observation, healthy completion, or proof of no matches. |
| Error state | Keep cause-specific problem text and the existing safe next step; show Retry only when the server says the work is eligible. Preserve unknown/partial observation language. |
| Destructive confirmation | Saved-search deletion retains its existing explicit protected confirmation and current copy. No new destructive interaction is added. |

---

## Route and Interaction Preservation

| Surface / route | Required behavior |
|-----------------|-------------------|
| Standalone ScrypathOps `GET /` | Return a same-host temporary HTTP redirect (`302`) to `/ops`. Do not render the deleted Phoenix generator home or add a new landing page. The next screen is the existing Control Room. |
| Standalone `/ops/*` | Preserve the existing mounted operator routes, assets, theme preference, authentication-free local development behavior, and task-specific navigation. |
| Host-mounted `/admin/search/*` | Preserve host mount path, host authentication and mount behavior, assets, and all supported operator routes. The Ops root redirect must not escape or rewrite this mount. |
| Ecommerce host `/` | Remain the storefront; never redirect this route to `/ops`. Preserve current storefront copy, search controls, result behavior, theme, and responsive layout. |

Keep the full task inventory distinct: storefront; Control Room; Search health; Failed sync work; Sync and drift; Search; Saved searches; and native Help. Preserve each surface's current evidence order, route-specific recovery language, query/result provenance, and component semantics. This phase removes generator scaffolding and protects the CSS namespace boundary; it does not unify screens or add UI state.

### Existing hierarchy and accessible control names

The Control Room's primary visual anchor remains the existing health verdict (`control-room-verdict`, `ops-verdict--hero`) and its “View search health” action. In setup-missing states, the existing schema/backend setup guidance occupies that place. Preserve the page heading above it and the two secondary intent cards below it; do not promote those cards over the current health observation. Authority: `scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex`.

Icon-only controls retain their existing programmatic names through `aria-label`, `aria-labelledby`, or visually hidden text. Preserve contextual names for refresh, saved-search actions, modal dismissal, and compact navigation; an icon or hover tooltip alone is insufficient. Existing decorative icons remain decoration, with no new media-loading behavior. Preserve current keyboard operation, focus return and protected confirmation semantics. Authority: `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` and current route templates.

---

## UI Considerations

The maintainer accepted the recommended element coverage and preservation backstops after the required propose-then-confirm probe (reply: “follow ur recs”). The compiled `ui-consideration-probe.cjs` was rerun with explicit kind overrides to correct the prose classifier's missed surfaces and its decorative-icon media false positive. The table below records those confirmed kinds. No new behavior or media state is authorized.

| Element ID | Existing surface / element group | Confirmed kinds |
|------------|----------------------------------|-----------------|
| E1 | Ecommerce storefront search and result behavior | form, list-collection, interactive-control, static-content |
| E2 | Control Room health evidence and entry actions | list-collection, nav, interactive-control, static-content |
| E3 | Search health / settings observations and result fields | form, list-collection, interactive-control, static-content |
| E4 | Failed work, settings, search and storefront request states | form, list-collection, interactive-control, static-content |
| E5 | Results, saved searches, sync evidence and storefront records | list-collection, static-content |
| E6 | Navigation, schema lists, record collections and settings comparisons | list-collection, nav, static-content |
| E7 | Exact identifiers, queries, saved names and failure details | static-content |
| E8 | Native Help content and topic navigation | nav, static-content |
| E9 | Shared standard and icon-only controls | interactive-control |
| E10 | Saved-search deletion confirmation and its copy | interactive-control, static-content |

Applicable element/category considerations resolved: **0 covered, 61 backstop, 0 unresolved, 0 unclassified**, grouped into the eight category rows below. These are implementation-time preservation obligations, not completed tests. The planner must wire each backstop to held-out state tests or matched rendered evidence; missing evidence remains insufficient specification/evidence and cannot silently pass. A future passing contract or screenshot capture alone does not prove the rendered experience.

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|
| empty | E1–E6 | 🧪 backstop | Use held-out empty/setup-missing fixtures to verify the Copywriting Contract empty-state rows; empty collections and unfilled fields retain their existing next step without claiming healthy completion. |
| loading | E1–E6, E8–E10 | 🧪 backstop | Exercise in-flight reads, navigation and actions; preserve existing busy/disabled semantics and current content, without adding skeletons, delays or new loading behavior. |
| error | E1–E6, E8–E10 | 🧪 backstop | Exercise failed requests and protected actions; verify the Copywriting Contract error row, textual cause/recovery, eligible-only retry and retained prior observations. |
| populated | E1–E6 | 🧪 backstop | Compare same-source/state ordinary-volume collections before and after changes; preserve attribution, task ordering, layout and existing Control Room visual hierarchy. |
| partial | E1–E6 | 🧪 backstop | Exercise partial, stale, unknown and absent field/row observations; preserve their distinct labels and scope without broad success or failure claims. |
| overflow | E1–E8, E10 | 🧪 backstop | Check matching 1440px, 768px and 390px states; keep existing wrapping or labeled local scrolling without page-wide horizontal overflow, including Help and navigation. |
| zero-one-many | E1–E6 | 🧪 backstop | Exercise zero, one and many entries; preserve selection, singular/plural count language, layout and task-specific empty behavior. |
| long-text | E1–E10 | 🧪 backstop | Exercise long identifiers, labels, queries, saved names, Help and failure details; keep exact content available through existing wrap/scroll/copy affordances and retain accessible control names. |

### Required build and rendered verification

- Build and inspect both actual outputs: standalone ScrypathOps and the ecommerce host with mounted ScrypathOps. Prove the color namespace reset removes default palette utilities while black/white, semantic daisyUI colors, spacing, and typography utilities remain available.
- Capture matched before/after rendering for the existing eight-screen inventory in light, dark, and system-dark at 1440px, 768px, and 390px (72 entry-state observations), plus the existing full-page, hover, focus, and compact-navigation evidence. Include the affected standalone and mounted surfaces and storefront root. Compare the same browser/platform, route, data, theme preference, state, and viewport; inspect actual captures and visible copy.
- Reuse the established route, theme, keyboard, assets, deterministic browser, and state-fixture proofs. Verify standalone `/` redirects to `/ops`, mounted `/admin/search/*` still resolves, operator routes remain reachable, and host `/` still serves the storefront. Do not infer pixel parity from file inventory or viewport checks.
- Keep captures and review records under `ui-review-artifacts/`, outside Playwright cleanup. New review records remain pending until an actual review; passing checks do not create design approval. Do not auto-update a disputed baseline.
- The retained preview named by `.planning/UI-PREVIEW.json` currently has a source/preflight mismatch. Before editing/restarting it or collecting rendered evidence, use its named checkout and complete the documented preflight, bind-mount/URL/branch/current-main reconciliation, and data-preservation checks. A failed preflight remains a stop. This research captured no browser evidence and does not claim visual approval.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | None; shadcn is not initialized | Not applicable |
| Third-party registry | None | Not applicable; no registry block is proposed |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS

**Approval:** approved 2026-10-31 — seven dimensions PASS after checker re-review of the hierarchy, accessible-name and confirmed state-coverage additions. No recommendations remain. This sign-off covers the written contract only; no implementation test, rendered UI approval or risk acceptance is claimed.
