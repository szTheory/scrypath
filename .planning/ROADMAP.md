# Roadmap: Scrypath

## Milestones

- ✅ **v1.28 Realistic Demo App & Admin UI Proof** — Phases 102-105 (shipped 2026-05-31) — see `milestones/v1.28-ROADMAP.md`
- ✅ **v1.29 Contract Repair and Proof Hardening** — Phases 106-108 (shipped 2026-05-31) — see `milestones/v1.29-ROADMAP.md`
- ✅ **v1.30 Release Trust and Evidence Maintenance** — Phases 109-112 (shipped 2026-06-01) — see `milestones/v1.30-ROADMAP.md`
- ✅ **v1.31 Adoption Evidence Demo Hardening** — Phases 113-115 (UAT passed 2026-06-01)
- ✅ **v1.32 Admin UI/UX Design System Cleanup** — Phases 116-118 (shipped 2026-06-01) — see `milestones/v1.32-ROADMAP.md`
- ✅ **v1.33 Admin UI Insane Polish** — Phases 119-127 (shipped 2026-06-03) — see `milestones/v1.33-ROADMAP.md`
- ✅ **v1.34 Both-Themes Perfection — Dark Signature + AA Gate** — Phases 128-136 (shipped 2026-06-29; archived 2026-07-11) — see `milestones/v1.34-ROADMAP.md`
- ✅ **v1.35 Brand System & Logo Identity** — Phases 137-143 (**complete** 2026-06-24, commit `fcb8fc7`; shipped directly, not via GSD plan/execute artifacts — `roadmap.analyze` shows 0% by design, see STATE.md "Completed Milestone")

## Phases — v1.35 Brand System & Logo Identity (COMPLETE — shipped 2026-06-24)

**Milestone v1.35 — Brand System & Logo Identity (phases 137–143).** Pressure-test the existing
`prompts/scrypath-brand-book.md` from a senior brand-designer + design-system + a11y + Elixir-OSS lens,
design a **proper logo system the owner chooses from**, ship a high-fidelity, repo-safe, **self-contained
`brandbook/` HTML package**, then **adopt** the chosen identity across the live product. The existing logos
(`scrypath_ops/priv/static/images/logo.svg`, `website/src/assets/brand-mark.svg`) are AI-generic and sit in a
rectangular `<rect rx>` cage the owner dislikes — they are replaced, not reused. Palette/type are open to
evidence-based refinement but bias-to-keep (they're implemented live in `scrypath_ops` + `website/`); the
`contrast-pairs.mjs` AA gate must stay green. Legend: `[R]` research-heavy · `[S]` screenshot/visual-loop ·
`[G]` selection/verification gate.

### Phase 137: Brand pressure-test & research `[R]`

**Goal:** Audit the current brand book against a full expert-lens decision-point sweep and produce cited research, a pressure-test report, and a decision-log that gates the keep-vs-refine question for palette/type and fixes the logo architecture direction. No product changes.

**Requirements:** BRAND-AUDIT-01

**Success criteria:**

1. `brandbook/notes/pressure-test.md` scores the current brand against the prompt's decision points (brand strategy, distinctiveness, logo system, color, type, layout, components, voice, OSS DX, Phoenix readiness, repo hygiene) with concrete dark-spots/footguns.
2. `brandbook/notes/research.md` cites current references (OSS/Elixir brand systems, integrated-typemark craft, design-token structure, WCAG AA, HexDocs/README conventions, woff2 subsetting).
3. `brandbook/notes/decision-log.md` uses the decision-matrix format with explicit **ship/reject/defer + confidence** for: keep-vs-refine palette, keep-vs-refine type, logo architecture, token expression. Default: keep palette/type, spend creativity on the logo unless a concrete defect is found.

### Phase 138: Logo directions + selection checkpoint `[S] [G]`

**Goal:** Author multiple genuinely distinct, transparent, **un-caged** logo directions as real SVG (each as icon-only mark, primary horizontal lockup, and small 16/24px size), render an honest in-context options gallery, and have the **owner pick** the primary direction.

**Requirements:** LOGO-DIRECTIONS-01

**Success criteria:**

1. 3–5 distinct directions exist as transparent SVGs (no full-bleed `<rect>` background), spanning at least: refined routed monogram, a fully-integrated typemark (motif worked into the wordmark), and a waypoint/wayfinding mark — each unified mark+logotype, mark close to type, no subtitle on the primary.
2. `brandbook/notes/logo-options.html` shows every direction on transparent + light + dark + in-context (favicon, navbar, README header) at real scale, committed for record.
3. The owner selects a primary direction (and optionally an alt) via an explicit checkpoint; `brandbook/notes/logo-options.md` records the rationale and ship/defer/reject per direction.

### Phase 139: Logo finalization & full lockup set `[S]`

**Goal:** From the chosen direction, produce the complete optimized, transparent SVG family plus the usage system.

**Requirements:** LOGO-SYSTEM-01

**Success criteria:**

1. `brandbook/assets/` holds `logo-primary.svg` (no tagline), `-primary-inverse`, `-typemark`, `-mark`, `-mark-mono`, `-stacked`, `-with-tagline` (separate/optional), `favicon.svg` (small-size simplified), `social-card.svg` (1200×630) — all transparent, svgo-optimized, no `<rect>` cage.
2. Clear-space, minimum-size, one-color, and misuse rules are defined (no stretch, no box/cage, no mark/type drift, no low-contrast bg, no shadow, no subtitle on primary).
3. Every mark is legible at 16px (favicon/nav) and at hero scale; transparency verified.

### Phase 140: Design-tokens package + fonts `[—]`

**Goal:** Ship an interoperable token package and self-contained webfonts that mirror the live `scrypath_ops` design system.

**Requirements:** TOKENS-PKG-01

**Success criteria:**

1. `brandbook/tokens/tokens.json` (primitive + semantic, light + dark, state colors, focus-ring), `tokens.css` (CSS custom properties), and `daisyui-theme.example.js` reconcile names with `scrypath_ops/assets/css/DESIGN-TOKENS.md` and the `contrast-pairs.mjs` guard.
2. Subset woff2 for the three OFL families land in `brandbook/assets/fonts/` with `@font-face` + bundled OFL license text; total font weight kept small.
3. Any phase-137 palette/type refinement is expressed once here as the single source.

### Phase 141: The HTML brand book + examples `[S]`

**Goal:** Build the standalone, professional, scoped HTML brand book and copy-ready examples.

**Requirements:** BRANDBOOK-HTML-01

**Success criteria:**

1. `brandbook/index.html` opens from `file://`, is responsive with a light/dark toggle and scoped CSS (no leakage), and covers: strategy/voice, logo system + do/don't, color palette **with contrast notes**, type scale, spacing/radius/shadow/motion tokens, component examples + states in both modes, microcopy good/bad + error pattern, imagery rules, implementation notes, license credits.
2. `brandbook/examples/{components.html, landing-page-section.html, readme-header-example.md}` and `brandbook/README.md` exist and render.
3. `brandbook/notes/accessibility-checks.md` records contrast/focus/state findings.

### Phase 142: Adoption / rollout across product `[S] [G]`

**Goal:** Adopt the chosen identity + any token refinement across the live product surfaces without regressing the contrast gate.

**Requirements:** BRAND-ADOPT-01

**Success criteria:**

1. `scrypath_ops/priv/static/images/logo.svg` + favicon, `website/src/assets/brand-mark.svg` + `og-image.svg`, and the root `README.md` header use the new identity.
2. Any palette/type refinement is applied to `scrypath_ops/assets/vendor/daisyui-theme.js` / `app.css` with the `contrast-pairs.mjs` AA gate **green** in both themes.
3. `scrypath_ops` assets + `website` rebuild and render correctly in light **and** dark; `mix verify.opsui` + design-token/contrast contracts pass.

### Phase 143: Milestone verification & UAT `[S] [G]`

**Goal:** Prove the milestone end-to-end and keep the repo clean.

**Requirements:** BRAND-VERIFY-01

**Success criteria:**

1. The brand book + examples open standalone (fonts offline, light/dark works); every `brandbook/assets/*.svg` is transparent, cage-free, svgo-clean, legible at 16px and hero scale.
2. Repo hygiene: only intended files changed, no unrelated diffs, no binary bloat, total new brand-asset weight within budget (target < ~400KB), fonts subset.
3. A final report ships with artifact manifest, top decisions (ship/reject/defer), cited research, commands run, and a must/should/nice next-commit plan; human UAT passes.

## Archived Milestone Note

v1.34 details are archived at `milestones/v1.34-ROADMAP.md`, `milestones/v1.34-REQUIREMENTS.md`, and `milestones/v1.34-MILESTONE-AUDIT.md`.

The root `.planning/REQUIREMENTS.md` is intentionally preserved because it currently contains v1.35 Brand System & Logo Identity planning state. Do not run generic milestone-close tooling against v1.34 without preserving that file first.
