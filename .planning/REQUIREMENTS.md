# Requirements: Scrypath v1.35 Brand System & Logo Identity

**Defined:** 2026-06-22
**Status:** Active
**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

> **Resumed milestone:** v1.34 Both-Themes Perfection (phases 128–136) has advanced through Phase 134 with 7/9 phases complete. Its remaining requirements are preserved in the **Appendix** at the bottom of this file for Phase 135 and Phase 136.

## Milestone Intent

An owner-initiated brand/identity wedge: take `prompts/scrypath-brand-book.md` — a strategically thorough but
artifact-thin "deep-research" brand doc — and turn it into a **genuinely high-fidelity, implementation-ready,
repo-safe brand package**, with a **proper logo system the owner chooses from** at its center.

The two concrete gaps this milestone closes:

1. **The logos are AI-generic and caged.** Both `scrypath_ops/priv/static/images/logo.svg` and
   `website/src/assets/brand-mark.svg` are a "path-S" mark inside a `<rect rx="12">` dark box — exactly the
   rectangular-background cage the owner dislikes. There is no proper lockup, no integrated typemark, no usage
   system, no favicon/social family. These are **replaced, not reused**.

2. **There is no real, self-contained brand book** — the existing `.md` is a strategy doc, not a usable
   design-system package an engineer can build UI / landing pages / docs from.

The milestone pressure-tests the brand from a senior brand-designer + design-system + a11y + Elixir-OSS lens,
designs and lets the owner **choose** a logo direction, ships a self-contained `brandbook/` HTML package
(logos, tokens, subset-woff2 fonts, component examples, usage rules, a11y notes), then **adopts** the chosen
identity across the live product surfaces.

### Locked decisions

- **Sequencing:** new milestone **v1.35** beginning at **phase 137**; v1.34 (133–136) paused, resumes after.
- **Adoption:** build the `brandbook/` package **and** rewire the chosen logo/tokens into ops UI, website, favicon, OG image, README (not artifacts-only).
- **Palette/type:** open to **evidence-based refinement** (not locked), but **bias-to-keep** — the violet+copper palette + Space Grotesk / Inter / IBM Plex Mono stack is already implemented live in `scrypath_ops` (Tailwind v4 + daisyUI) and `website/`; any change must keep the `contrast-pairs.mjs` AA gate green and is justified in the decision-log.
- **Fonts:** check in **subset woff2** (the three families are SIL OFL → embed+subset is license-clean; include OFL files) so the HTML book is self-contained offline.
- **Logo non-negotiables:** transparent / **no rectangular `<rect>` cage**; unified mark+logotype sharing geometry/weight; mark sits close to the type; **primary lockup has no subtitle** (a tagline lockup is a separate optional file); **≥1 fully-integrated typemark** with the route/node motif worked into the letterforms; **show options, owner picks**.
- **Repo hygiene:** everything self-contained under `/brandbook/`; SVG/HTML/CSS/JSON/MD first; svgo every SVG; subset fonts; prefer the live HTML over raster screenshots; no build system added for the book; total new brand-asset weight kept small (target < ~400KB).
- **Scope guard holds:** Phase 97–99 runtime breadth ban is unaffected — this is brand/UI work, not library runtime scope.

## Requirements

### Pressure-test & research

- [ ] **BRAND-AUDIT-01**: The current brand book is audited against a full expert-lens decision-point sweep, producing `brandbook/notes/pressure-test.md` (scored dark-spots/footguns across brand strategy, distinctiveness, logo system, color, type, layout, components, voice, OSS DX, Phoenix readiness, repo hygiene), `brandbook/notes/research.md` (cited current references), and `brandbook/notes/decision-log.md` (decision-matrix with explicit ship/reject/defer + confidence for keep-vs-refine palette, keep-vs-refine type, logo architecture, token expression). Default recommendation: keep palette/type, spend creativity on the logo unless a concrete defect is found.

### Logo system

- [ ] **LOGO-DIRECTIONS-01**: 3–5 genuinely distinct, transparent, un-caged logo directions exist as real SVG (each as icon-only mark, primary horizontal lockup, and small 16/24px size), spanning at least a refined routed monogram, a fully-integrated typemark, and a waypoint/wayfinding mark; `brandbook/notes/logo-options.html` shows them on transparent + light + dark + in-context (favicon, navbar, README header) at real scale; the **owner selects** a primary direction (and optional alt) at an explicit checkpoint, recorded in `brandbook/notes/logo-options.md`.
- [ ] **LOGO-SYSTEM-01**: From the chosen direction, `brandbook/assets/` holds the full optimized transparent family — `logo-primary.svg` (no tagline), `-primary-inverse`, `-typemark`, `-mark`, `-mark-mono`, `-stacked`, `-with-tagline` (separate/optional), `favicon.svg`, `social-card.svg` (1200×630) — with clear-space, minimum-size, one-color, and misuse rules; every mark is legible at 16px and hero scale; no `<rect>` cage; transparency verified.

### Design system package

- [ ] **TOKENS-PKG-01**: `brandbook/tokens/{tokens.json, tokens.css, daisyui-theme.example.js}` express primitive + semantic tokens (light + dark, state colors, focus-ring) reconciled with `scrypath_ops/assets/css/DESIGN-TOKENS.md` and the `contrast-pairs.mjs` guard; subset woff2 for the three OFL families land in `brandbook/assets/fonts/` with `@font-face` + OFL license text; any phase-137 refinement is expressed once here as the single source.
- [ ] **BRANDBOOK-HTML-01**: `brandbook/index.html` is a standalone, responsive, scoped (no-leak) HTML brand book with a light/dark toggle that opens from `file://` and covers strategy/voice, logo system + do/don't, color palette with contrast notes, type scale, spacing/radius/shadow/motion tokens, component examples + states in both modes, microcopy good/bad + error pattern, imagery rules, implementation notes, and license credits; with `brandbook/examples/{components.html, landing-page-section.html, readme-header-example.md}`, `brandbook/README.md`, and `brandbook/notes/accessibility-checks.md`.

### Adoption & verification

- [ ] **BRAND-ADOPT-01**: The chosen identity + any token refinement is adopted across the live product — `scrypath_ops` logo + favicon, `website/src/assets/brand-mark.svg` + `og-image.svg`, and the root `README.md` header — with the `contrast-pairs.mjs` AA gate **green** in both themes, `scrypath_ops` assets + `website` rebuilding and rendering correctly in light and dark, and `mix verify.opsui` + design-token/contrast contracts passing.
- [ ] **BRAND-VERIFY-01**: The milestone is proven end-to-end — the brand book + examples open standalone (fonts offline, light/dark works), every `brandbook/assets/*.svg` is transparent/cage-free/svgo-clean and legible at 16px + hero scale, repo hygiene holds (no unrelated diffs, no binary bloat, weight within budget, fonts subset), and a final report ships with artifact manifest, top decisions, cited research, commands run, and a must/should/nice next-commit plan; human UAT passes.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Renaming the project / changing the `scrypath` Hex package name | The library is published as `scrypath`; this milestone styles the existing name. Naming-collision nuance is handled by always pairing "Scrypath" with a descriptor, not by a rename. |
| New Scrypath runtime APIs or search capabilities | Phase 97–99 scope guard still applies; v1.35 is brand/UI work, not runtime breadth. |
| A user-customizable / per-org theme editor | Theming stays the two brand-defined themes + system. |
| Wholesale palette/type replacement "to look different" | Refinement is allowed only where the pressure-test finds a concrete defect; gratuitous change causes thrash in the already-built ops UI. Bias-to-keep. |
| Checking in heavy raster artifacts (large PNG screenshots, font superfamilies) | Repo-size hygiene: the live HTML renders palettes/components; fonts are subset; raster is last-resort only. |
| Adding a build system / bundler for the brand book | The book is plain standalone HTML/CSS/SVG; no toolchain dependency. |
| Promoting brand assets to a required CI merge gate | Out of scope; the brand book is a reference + adopted assets, not a new gate. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| BRAND-AUDIT-01 | Phase 137 | In progress |
| LOGO-DIRECTIONS-01 | Phase 138 | In progress (awaiting owner pick) |
| LOGO-SYSTEM-01 | Phase 139 | Pending |
| TOKENS-PKG-01 | Phase 140 | Pending |
| BRANDBOOK-HTML-01 | Phase 141 | Pending |
| BRAND-ADOPT-01 | Phase 142 | Pending |
| BRAND-VERIFY-01 | Phase 143 | Pending |

---

## Appendix — Completed v1.34 Requirements

> Preserved from the v1.34 milestone (defined 2026-06-04). v1.34 completed on 2026-06-29 after Phase 136 passed DUALVERIFY-01 with approved Human UAT.

**Milestone intent:** Make the `scrypath_ops` admin UI's existing dark/light/system theming genuinely perfect and brand-expressive in both modes (dark signature, light at parity), backed by a formal automated WCAG AA contrast gate (AAA for body text), with continued design-system/IA polish on v1.33's under-touched surfaces. Locked: comprehensive both-themes scope; system-follows-OS default; AA hard gate / AAA-body advisory; keep Tailwind v4 + daisyUI + `.ops-*`.

| Requirement | Phase | Status |
|-------------|-------|--------|
| CONTRAST-HARNESS-01 | Phase 128 | Complete |
| DARKAUDIT-01 | Phase 129 | Complete |
| DARKTOKEN-01 | Phase 130 | Complete |
| GLOW-01 | Phase 131 | Complete |
| COPPER-01 | Phase 131 | Complete |
| A11Y-TOKEN-01 | Phase 132 | Complete |
| DARKMOTION-01 | Phase 133 | Complete |
| SCREEN-DARK-01 | Phase 134 | Complete |
| SHELL-DARK-01 | Phase 135 | Complete |
| DUALVERIFY-01 | Phase 136 | Complete |

- **DARKMOTION-01** (Phase 133, complete): restrained path-expression motion (line draw/reveal, node pulse, active-path tracing on the route mark/diagrams, code-block shimmer on hover) via existing `--duration-ops-*`/`--ease-ops-*` tokens, transform/opacity only, reduced-motion-safe, tuned for dark without breaking light; honors v1.33's A3 no-re-fire precedent.
- **SCREEN-DARK-01** (Phase 134, complete): under-iterated surfaces (Search result rows, Sync/Drift drift-chips/preflight depth, Playbooks empty/populated) reach dark-signature + light-parity quality across all seed states.
- **SHELL-DARK-01** (Phase 135, complete): shell chrome (header/nav, command palette, theme toggle, flash, `.ops-shell` radial violet wash) brand-expressive and AA-clean in both themes; weak header-nav dark contrast fixed; palette/flash adopt the dark ambient-shadow-plus-border recipe.
- **DUALVERIFY-01** (Phase 136, complete): end-to-end proof — `mix verify.opsui` + ScrypathOps LiveView suite + mounted ecommerce admin Playwright smoke green; CONTRAST-HARNESS-01 AA in both themes with AAA-body report; 40-shot matrix re-captured with a v1.33→v1.34 before/after gallery; milestone audit + human UAT.
