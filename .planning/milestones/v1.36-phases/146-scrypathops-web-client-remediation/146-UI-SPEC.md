---
phase: 146
slug: scrypathops-web-client-remediation
status: draft
shadcn_initialized: false
preset: none
created: 2026-08-24
---

# Phase 146 — UI Design Contract

> Preservation-only contract. This dependency-security phase introduces no visual or interaction work; it protects the already-shipped ScrypathOps operator interface while its dependency graph is remediated.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none — shadcn is not applicable to this Phoenix/LiveView project |
| Preset | not applicable |
| Component library | existing Phoenix function components and vendored daisyUI only; do not add, replace, or reconfigure either |
| Icon library | existing Heroicons through the imported Phoenix `<.icon>` component; no icon changes |
| Font | preserve the existing application font stack unchanged |

**Preservation rule:** Do not edit HEEx templates, LiveView render functions, router routes, layouts, `assets/css/app.css`, `assets/js/app.js`, theme storage/selection, icon usage, or component APIs for this phase. The existing `mix verify.opsui` suite is the regression proof for the retained rendered operator experience.

---

## Spacing Scale

Spacing is preservation-only and is not declared or redesigned by this phase. Do not alter spacing tokens or layout dimensions.

**Testable invariant:** the phase diff must contain no changes to spacing tokens, layouts, HEEx templates, CSS, JavaScript, or UI assets. Verify this restriction through phase-diff review and the existing `mix verify.opsui` gate.

---

## Typography

Preserve the existing type scale and weights exactly. This phase declares no typography change and must not introduce new sizes, weights, families, or line-height rules.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | existing `--text-ops-body` | unchanged | existing `--leading-ops-body` |
| Label | existing `--text-ops-sm` | unchanged | unchanged |
| Heading | existing application token | unchanged | unchanged |
| Display | existing application token | unchanged | unchanged |

---

## Color

Preserve both existing quiet operator themes and their semantic tokens; no color or theme work is authorized.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | existing `--color-base-100` / `--color-base-200` per active theme | Existing backgrounds and surfaces only |
| Secondary (30%) | existing `--ops-surface-1` / `--ops-surface-2` per active theme | Existing cards, sidebar, navigation, and raised surfaces only |
| Accent (10%) | existing `--color-primary` per active theme | Existing focused controls, active navigation, and established primary actions only |
| Destructive | existing `--color-error` per active theme | Existing destructive actions only |

Accent reserved for: the pre-existing focused controls, active navigation, and established primary-action states. Do not add accent usage or modify light, dark, or system-theme behavior.

---

## Copywriting Contract

No copy is introduced or changed in this phase. Preserve all existing labels, calls to action, empty-state language, error messages, and destructive confirmations byte-for-byte unless an upgrade demonstrably changes a framework-generated message; such a regression blocks the phase and requires re-planning rather than replacement copy.

| Element | Copy |
|---------|------|
| Primary CTA | Existing copy unchanged; no new CTA |
| Empty state heading | Existing copy unchanged; no new empty state |
| Empty state body | Existing copy unchanged; no new empty state |
| Error state | Existing copy unchanged; no new error state |
| Destructive confirmation | Existing confirmations unchanged; no destructive behavior added |

---

## UI Considerations

The post-verification UI probe resolved 8/8 preservation considerations with explicit evidence. This phase creates or changes no UI element, UI state, route, screen, or user interaction; the diff restriction plus `mix verify.opsui` preserve the established surface.

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|
| empty | preserved operator UI | ✅ covered | The phase diff changes no HEEx, LiveView render, router, layout, CSS, JS, component API, or UI asset, and `mix verify.opsui` passes. |
| loading | preserved operator UI | ✅ covered | No loading UI changes; the UI-file diff restriction and `mix verify.opsui` preserve existing behavior. |
| error | preserved operator UI | ✅ covered | No user-visible error UI or copy changes; the UI-file diff restriction and `mix verify.opsui` preserve existing behavior. |
| populated | preserved operator UI | ✅ covered | No populated view changes; the UI-file diff restriction and `mix verify.opsui` preserve existing behavior. |
| partial | preserved operator UI | ✅ covered | No partial-data UI changes; the UI-file diff restriction and `mix verify.opsui` preserve existing behavior. |
| overflow | preserved operator UI | ✅ covered | No layout or text-container changes; the UI-file diff restriction and `mix verify.opsui` preserve existing overflow behavior. |
| zero-one-many | preserved operator UI | ✅ covered | No collection or count-sensitive copy changes; the UI-file diff restriction and `mix verify.opsui` preserve existing behavior. |
| long-text | preserved operator UI | ✅ covered | No text, label, navigation item, or container changes; the UI-file diff restriction and `mix verify.opsui` preserve existing behavior. |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | not applicable — no React/shadcn integration |
| third-party registries | none | no registry additions or block imports permitted |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS — no copy changes
- [x] Dimension 2 Visuals: PASS — no visual or interaction changes
- [x] Dimension 3 Color: PASS — existing themes and semantic roles preserved
- [x] Dimension 4 Typography: PASS — four existing roles preserved
- [x] Dimension 5 Spacing: PASS — non-numeric no-change invariant
- [x] Dimension 6 Registry Safety: PASS — no registry additions

**Approval:** approved 2026-08-24 — UI checker verified 6/6 dimensions; post-verification probe resolved 8/8 considerations explicitly.

## Source Decisions

- `146-CONTEXT.md` — maintenance-only scope; no product capability, Ops route/screen, UI, layout, styling, copy, interaction, accessibility, motion, theme, or brand change.
- `146-RESEARCH.md` — no template/UI change is planned; existing `mix verify.opsui` owns Ops UI invariants.
- `REQUIREMENTS.md` — Phoenix UI work is explicitly out of scope for v1.36.
