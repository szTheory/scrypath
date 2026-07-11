# Requirements: Scrypath

**Status:** No active feature or repair requirements
**Last reconciled:** 2026-07-11
**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## Active

No active feature, repair, or brand requirements.

The default lane is idle maintenance-and-evidence mode: release/support truth, proof stability, public claim drift, and outside-adopter evidence only when concrete signal appears. Do not open a new milestone just because additional polish is imaginable.

## Recently Validated

### v1.35 Brand System & Logo Identity

**Shipped:** 2026-06-24
**Archived:** 2026-07-11
**Completion mode:** Direct completion in commit `fcb8fc7`; phases 138-143 intentionally have no GSD phase directories or PLAN/SUMMARY artifacts.

- [x] **BRAND-AUDIT-01:** Brand pressure-test, cited research, and decision-log completed under `brandbook/notes/`.
- [x] **LOGO-DIRECTIONS-01:** Owner selection recorded; final direction is the copper `/` `scry/path` identity. Routed-S concepts are rejected historical exploration.
- [x] **LOGO-SYSTEM-01:** Transparent, cage-free SVG family shipped under `brandbook/assets/`.
- [x] **TOKENS-PKG-01:** Portable token package and subset woff2 fonts shipped under `brandbook/tokens/` and `brandbook/assets/fonts/`.
- [x] **BRANDBOOK-HTML-01:** Self-contained brand book, examples, README, and accessibility notes shipped under `brandbook/`.
- [x] **BRAND-ADOPT-01:** New identity adopted across root README, ScrypathOps logo/favicon/layout, website brand mark, and OG image.
- [x] **BRAND-VERIFY-01:** Direct evidence archived through commit `fcb8fc7`, brandbook notes, logo proof sheet, accessibility checks, package-size discipline, and planning audit.

Archive files:

- `milestones/v1.35-ROADMAP.md`
- `milestones/v1.35-REQUIREMENTS.md`
- `milestones/v1.35-MILESTONE-AUDIT.md`

### v1.34 Both-Themes Perfection - Dark Signature + AA Gate

**Shipped:** 2026-06-29
**Archived:** 2026-07-11

- [x] **CONTRAST-HARNESS-01**, **DARKAUDIT-01**, **DARKTOKEN-01**, **GLOW-01**, **COPPER-01**, **A11Y-TOKEN-01**, **DARKMOTION-01**, **SCREEN-DARK-01**, **SHELL-DARK-01**, **DUALVERIFY-01** - both-themes perfection wedge closed with dark signature, light parity, AA hard gate, browser proof, screenshot matrix recapture, before/after gallery, milestone audit, and approved Human UAT.

Archive files:

- `milestones/v1.34-ROADMAP.md`
- `milestones/v1.34-REQUIREMENTS.md`
- `milestones/v1.34-MILESTONE-AUDIT.md`

## Traceability

| Requirement | Milestone | Phase | Final Status | Evidence |
|-------------|-----------|-------|--------------|----------|
| BRAND-AUDIT-01 | v1.35 | 137 | Complete | `brandbook/notes/pressure-test.md`, `research.md`, `decision-log.md` |
| LOGO-DIRECTIONS-01 | v1.35 | 138 | Complete | `brandbook/notes/logo-options.md` |
| LOGO-SYSTEM-01 | v1.35 | 139 | Complete | `brandbook/assets/*.svg`, `brandbook/notes/logo-final-c.html` |
| TOKENS-PKG-01 | v1.35 | 140 | Complete | `brandbook/tokens/*`, `brandbook/assets/fonts/*` |
| BRANDBOOK-HTML-01 | v1.35 | 141 | Complete | `brandbook/index.html`, `brandbook/examples/*`, `brandbook/README.md` |
| BRAND-ADOPT-01 | v1.35 | 142 | Complete | README, ScrypathOps logo/favicon/layout, website brand-mark/OG |
| BRAND-VERIFY-01 | v1.35 | 143 | Complete | `fcb8fc7`, accessibility notes, logo proof sheet, archive audit |
| CONTRAST-HARNESS-01 | v1.34 | 128 | Complete | `milestones/v1.34-REQUIREMENTS.md` |
| DARKAUDIT-01 | v1.34 | 129 | Complete | `milestones/v1.34-REQUIREMENTS.md` |
| DARKTOKEN-01 | v1.34 | 130 | Complete | `milestones/v1.34-REQUIREMENTS.md` |
| GLOW-01 | v1.34 | 131 | Complete | `milestones/v1.34-REQUIREMENTS.md` |
| COPPER-01 | v1.34 | 131 | Complete | `milestones/v1.34-REQUIREMENTS.md` |
| A11Y-TOKEN-01 | v1.34 | 132 | Complete | `milestones/v1.34-REQUIREMENTS.md` |
| DARKMOTION-01 | v1.34 | 133 | Complete | `milestones/v1.34-REQUIREMENTS.md` |
| SCREEN-DARK-01 | v1.34 | 134 | Complete | `milestones/v1.34-REQUIREMENTS.md` |
| SHELL-DARK-01 | v1.34 | 135 | Complete | `milestones/v1.34-REQUIREMENTS.md` |
| DUALVERIFY-01 | v1.34 | 136 | Complete | `milestones/v1.34-REQUIREMENTS.md` |

## Open Follow-ups

- Pending nonblocking TODO: `.planning/todos/pending/2026-07-01-rewrite-ops-ui-microcopy-around-operator-jtbd.md`.

This is not an active milestone requirement.

## Out of Scope

- Postgres-native full-text search as a first-class v1 product surface.
- Public multi-backend support before real adoption pressure proves the common contract deserves to widen.
- Advanced relevance features such as vector search, hybrid retrieval, personalization, analytics, or autocomplete/suggestions before the operational core and public release story settle.
- Public `%Scrypath.Query{}` or other internal normalization structs as semver-stable contract.
- Schema-generated runtime search verbs, controller/LiveView macros, or any helper that turns Scrypath into a framework facade.
- Reusable UI widgets, search-page scaffolds, or broader composition/preset systems.

## Archive Policy

Root requirements describe current posture and recently validated requirements only. Detailed milestone requirements live under `milestones/v*-REQUIREMENTS.md`.
