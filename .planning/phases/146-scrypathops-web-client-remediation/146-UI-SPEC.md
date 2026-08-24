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

Applicable state considerations resolved: none applicable — this phase creates or changes no UI element, UI state, route, screen, or user interaction. Existing state behavior remains under the established `mix verify.opsui` regression gate; it is not a new implementation surface.

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|
| empty | none | ✅ covered | No new or changed UI collection, form, or media surface. Existing empty states remain unchanged. |
| loading | none | ✅ covered | No new or changed loading UI. Existing LiveView loading behavior remains unchanged. |
| error | none | ✅ covered | No new or changed user-visible failure UI. Existing error states remain unchanged. |
| populated | none | ✅ covered | No new or changed populated collection or media surface. |
| partial | none | ✅ covered | No new or changed form or collection data state. |
| overflow | none | ✅ covered | No layout or text-container change is authorized. |
| zero-one-many | none | ✅ covered | No new or changed collection. |
| long-text | none | ✅ covered | No changed static content, control label, or navigation item. |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | not applicable — no React/shadcn integration |
| third-party registries | none | no registry additions or block imports permitted |

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS — preservation-only review pending
- [ ] Dimension 2 Visuals: PASS — preservation-only review pending
- [ ] Dimension 3 Color: PASS — preservation-only review pending
- [ ] Dimension 4 Typography: PASS — preservation-only review pending
- [ ] Dimension 5 Spacing: PASS — preservation-only review pending
- [ ] Dimension 6 Registry Safety: PASS — preservation-only review pending

**Approval:** pending

## Source Decisions

- `146-CONTEXT.md` — maintenance-only scope; no product capability, Ops route/screen, UI, layout, styling, copy, interaction, accessibility, motion, theme, or brand change.
- `146-RESEARCH.md` — no template/UI change is planned; existing `mix verify.opsui` owns Ops UI invariants.
- `REQUIREMENTS.md` — Phoenix UI work is explicitly out of scope for v1.36.
