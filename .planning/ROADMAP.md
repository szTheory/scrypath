# Roadmap: Scrypath

## Milestones

- ✅ **v1.28 Realistic Demo App & Admin UI Proof** — Phases 102-105 (shipped 2026-05-31) — see `milestones/v1.28-ROADMAP.md`
- ✅ **v1.29 Contract Repair and Proof Hardening** — Phases 106-108 (shipped 2026-05-31) — see `milestones/v1.29-ROADMAP.md`
- ✅ **v1.30 Release Trust and Evidence Maintenance** — Phases 109-112 (shipped 2026-06-01) — see `milestones/v1.30-ROADMAP.md`
- ✅ **v1.31 Adoption Evidence Demo Hardening** — Phases 113-115 (UAT passed 2026-06-01)
- ✅ **v1.32 Admin UI/UX Design System Cleanup** — Phases 116-118 (shipped 2026-06-01) — see `milestones/v1.32-ROADMAP.md`
- ✅ **v1.33 Admin UI Insane Polish** — Phases 119-127 (shipped 2026-06-03) — see `milestones/v1.33-ROADMAP.md`
- 🔨 **v1.34 Both-Themes Perfection — Dark Signature + AA Gate** — Phases 128-136 (**active**; Phases 128–133 complete & verified, 6/9; next Phase 134 SCREEN-DARK-01)
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

## Phases — v1.34 Both-Themes Perfection (ACTIVE — 128–133 complete; next Phase 134)

**Milestone v1.34 — Both-Themes Perfection: Dark Signature + AA Gate (phases 128–136).** Next-level UI/UX +
design-system iteration of the `scrypath_ops` admin console, building on v1.33. Dark/light/system theming
already exists and works — this milestone makes **both themes genuinely perfect and brand-expressive** (dark
as signature, light at parity) per `prompts/scrypath-brand-book.md`, adds a formal automated WCAG AA contrast
gate (AAA for body text), and continues polish on v1.33's under-touched surfaces. Legend: `[R]` research-heavy ·
`[S]` screenshot-loop-heavy · `[G]` cross-AI/verification gate.

### Phase 128: Contrast gate harness + dark seed coverage `[S] [G]`

**Goal:** Make WCAG AA/AAA **measurable** and the dark state-space observable before changing any pixels — add `@axe-core/playwright`, an `admin_contrast_matrix.spec.ts` (6 screens × {light, dark, system-dark} × seed scenarios; AA = build-fail, AAA-body = advisory report), `npm run test:e2e:admin-contrast` + `make contrast`, and a fast custom token-pair pre-check. Run it first to learn the real failure set.

**Requirements:** CONTRAST-HARNESS-01

**Success criteria:**

1. `npm run test:e2e:admin-contrast` runs the full screen × {light, dark, system-dark} × scenario matrix and exits non-zero on any AA color-contrast violation.
2. The AAA (7:1) status for body/long-form text is reported without failing the build.
3. A fast Node token-pair contrast checker (`make contrast`) grades every declared `--color-*` pair + documented muted alphas at AA/AAA with no browser.
4. The existing 40-shot screenshot matrix still captures both themes cleanly as the dark-audit substrate.

**Plans:** 3/3 plans complete

Plans:
**Wave 1**

- [x] 128-01-PLAN.md — Install @axe-core/playwright, create contrast-pairs.mjs muted manifest, wire test:e2e:admin-contrast script

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 128-02-PLAN.md — Create contrast-checker.mjs with WCAG math/self-test/D-15 guards, Makefile targets, DESIGN-TOKENS.md update

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 128-03-PLAN.md — Create admin_contrast_matrix.spec.ts axe gate, run full matrix, commit 128-CONTRAST-REPORT.md

**Status:** Pending

### Phase 129: Dark-theme brand-expression audit `[S] [R]`

**Goal:** Enumerate and score every dark surface against the brand book; produce one ranked, fix-class-tagged backlog (`129-DARK-AUDIT-BACKLOG.md`) with a systemic-vs-per-screen split and the `#1B2230` surface-2 ramp gap as finding #1. No code changes.

**Requirements:** DARKAUDIT-01

**Success criteria:**

1. Every dark touchpoint is scored on the brand's dark dimensions (4-step ramp, 65/20/10/5 ratio, quiet-vs-loud glow, ambient-shadow-plus-border, path-line glow restraint, AA pass/fail).
2. Findings are tagged by fix class and split systemic (≥3 screens → token/component fix) vs per-screen.
3. The backlog mirrors v1.33's `120-AUDIT-BACKLOG.md` format and is the single source for phases 130–135.

**Plans:** 1/1 plans complete

Plans:
**Wave 1**

- [x] 129-01-PLAN.md — Score 6-screen × DD1–DD6 dark brand audit; assemble 129-DARK-AUDIT-BACKLOG.md

**Status:** Complete (verified 2026-06-04 — rebuilt assets, static token gate, ops UI suite, Playwright AA matrix for light/dark/system-dark, AAA advisory, and light baseline recapture recorded)

### Phase 130: Dark surface ramp + depth tokens `[G]`

**Goal:** Land the 4-step midnight ramp (introduce `#1B2230` surface-2) and refactor the `.ops-*` fill recipes via theme-scoped elevation tokens so dark steps **up** in elevation while light stays pixel-identical. Highest blast radius → cross-AI gate.

**Requirements:** DARKTOKEN-01

**Success criteria:**

1. Dark renders a true four-step ramp: bg `#0C0F14` → panel `#141923` → raised/muted `#1B2230` → border `#2A3446`.
2. `.ops-muted-panel`, `.ops-data-card`, `.ops-surface-flat`, `.ops-nav-list`, `.ops-disclosure`, `.ops-kbd`, `.ops-result-row`, `.ops-preflight__card--locked` step up (not down) in dark.
3. The light theme is pixel-identical (light matrix + light contrast gate unchanged); `DESIGN-TOKENS.md` records the dark ramp.

**Plans:** 4/4 plans complete

Plans:
**Wave 1**

- [x] 130-01-PLAN.md — Scaffold light-pixel-diff.mjs gate script, add pixelmatch/pngjs devDeps, add verify.opsui alias

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 130-02-PLAN.md — Declare --ops-bg/surface-1/surface-2 tokens in both @plugin blocks

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 130-03-PLAN.md — Recipe routing: 8 token-swaps + .bg-ops-surface-2 helper + D-05 dark overrides + D-10 shadow dual-path + ops_code_block DK-09

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 130-04-PLAN.md — Run D-11 proof bundle, update DESIGN-TOKENS.md elevation-surface subsection

**Status:** Pending

### Phase 131: Glow, dark shadow, and copper accent system `[R] [G]`

**Goal:** Add the brand's dark "ambient-shadow-plus-border" depth, a restrained opt-in violet "quiet glow," and copper's branded 5% accent role — tokenized, both-theme, AA-safe.

**Requirements:** GLOW-01, COPPER-01

**Success criteria:**

1. Dark panels (`.ops-panel`, `.ops-cmdk__panel`, `#flash-group`, `.ops-intent-card`) read as seated depth via a dark ambient shadow + the existing border; light keeps its vertical lift.
2. A low-spread violet glow token applies to the route mark / active-path / key-callout hover only — never text, resting panels, or background floods.
3. A `.ops-*` copper accent family (eyebrow, key-callout badge, key-node emphasis) ships with AA-safe dark-text-on-copper pairings and is used at roughly the brand's 5% ratio.

**Plans:** 4/4 plans complete

Plans:
**Wave 1**

- [x] 131-01-PLAN.md — Declare 3 dark shadow tokens + glow/copper classes; Wave-0 baseline freshness

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 131-02-PLAN.md — Apply panel-dark + violet glow (dark-scoped, compose) + shell wash mobile tune
- [x] 131-03-PLAN.md — Eyebrow copper re-style (ops_ui.ex) + DESIGN-TOKENS.md lockstep sections

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 131-04-PLAN.md — Run D-11 proof bundle + copper AA re-confirm + human verify

**Status:** Complete (verified 2026-06-04 — D-11 bundle green, human-verify APPROVED)

### Phase 132: A11y contrast remediation — both themes (hard gate) `[G]`

**Goal:** Re-tune muted-text alphas so both themes pass AA and body text reaches AAA. **Gate: CONTRAST-HARNESS-01 must be green in both themes before this phase closes.**

**Requirements:** A11Y-TOKEN-01

**Success criteria:**

1. `.ops-text-meta`, `.ops-trail__crumb`, header nav, handoff/palette/preflight hints all clear AA 4.5:1 in both themes (the flagged weak dark header-nav contrast is fixed).
2. Large-text/UI elements clear ≥3:1; body/long-form text reaches AAA (≥7:1).
3. The contrast gate is green for light, dark, and system-dark; `DESIGN-TOKENS.md` records the new alpha floors.

**Plans:** 2/2 plans complete

Plans:
**Wave 1**

- [x] 132-01-PLAN.md — Implement named muted AA floor, scoped primary-strong fill, checker/manifest support, and token docs

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 132-02-PLAN.md — Rebuild assets, run static and browser contrast gates, attach AAA advisory, and refresh light baseline evidence

**Status:** Complete (verified 2026-06-04 — rebuilt assets, static token gate, ops UI suite, Playwright AA matrix for light/dark/system-dark, AAA advisory, and light baseline recapture recorded)

### Phase 133: Dark/path motion expression `[R] [G]`

**Goal:** Add the brand's directional path motion where it serves a JTBD (line-draw/reveal, active-path tracing, node pulse, code-block shimmer-on-hover), tuned for dark and restrained, via the existing motion tokens.

**Requirements:** DARKMOTION-01

**Success criteria:**

1. New motion is transform/opacity only, <300ms, no bounce, and neutralized under `prefers-reduced-motion`.
2. It honors v1.33's A3 precedent — no per-LiveView-patch re-firing reveals on result lists.
3. Motion reads "deliberate/infrastructural" in dark and does not regress light; reduced-motion + functional integrity confirmed via Playwright.

**Plans:** 3/3 plans complete

Plans:
**Wave 1**

- [x] 133-01-PLAN.md — `.ops-path-*` CSS motion vocabulary + `shimmer` attr on `ops_code_block` + anchor wiring + DESIGN-TOKENS.md docs

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 133-02-PLAN.md — static CSS contract test (transform/opacity-only + tokenized <300ms + dual-dark-path) running inside `mix verify.opsui`
- [x] 133-03-PLAN.md — focused Playwright proof: reduced-motion + hover-shimmer + active-path + patch-refire, dark AND light, + targeted screenshots

**Status:** Pending

### Phase 134: Under-iterated surface polish (dual-theme) `[S]`

**Goal:** Bring the surfaces v1.33 under-touched — Search result rows, Sync/Drift depth, Playbooks — to dark-signature + light-parity quality across all seed states.

**Requirements:** SCREEN-DARK-01

**Plans:** 3 plans

Plans:
**Wave 1**

- [ ] 134-01-PLAN.md — Wave 0 harness: new admin_surface_depth.spec.ts computed-style gate + test:e2e:admin-depth script + populated-playbooks seed (R4) + new ExUnit token tripwire (R3)

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 134-02-PLAN.md — Application core: dark hover-border boost to primary 55% (D-15/16), earned copper badge on the recommended intent-card (D-01), conditional DK-13 posture-table tune (D-08), verify-only DK-11/14/15 sweep, filled depth-spec assertions

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 134-03-PLAN.md — Verification gate: light pixel-diff threshold 0 (D-13) + AA gate green in 3 themes + mix verify.opsui + depth spec, plus the two human-only aesthetic spot-reviews (D-13/D-06)

**Success criteria:**

1. Search result rows visibly separate in dark (reseated on the surface-2 raised token + dark ambient-shadow-plus-border; hover keeps `shadow-ops-mid` + violet border).
2. Sync/Drift drift-chips and preflight gain depth; Playbooks empty + populated are polished — both themes, all seed scenarios.
3. Earned copper/glow accents appear where they serve the scan path, not decoratively.

**Status:** Pending

### Phase 135: Shell chrome polish (dual-theme) `[S]`

**Goal:** Make header/nav, command palette, theme toggle, flash, and the `.ops-shell` violet wash brand-expressive and AA-clean in both themes, consistent across all 6 screens.

**Requirements:** SHELL-DARK-01

**Success criteria:**

1. Header nav contrast passes AA in dark; the `.ops-shell` radial violet wash reads as a quiet ambient glow on Night, not a blob.
2. Command palette + flash adopt the dark ambient-shadow-plus-border recipe; theme-toggle states are verified.
3. Chrome is consistent across Control Room, Posture, Failed Sync, Sync/Drift, Search, Playbooks in both themes.

**Status:** Pending

### Phase 136: Milestone verification & UAT `[S] [G]`

**Goal:** Prove both themes are perfect end-to-end against intent — static + contrast + smoke gates green, matrix re-captured, v1.33→v1.34 before/after gallery, milestone audit, human UAT.

**Requirements:** DUALVERIFY-01

**Success criteria:**

1. `mix verify.opsui` + ScrypathOps LiveView suite + ecommerce admin Playwright smoke all green.
2. CONTRAST-HARNESS-01 passes AA in both themes with the AAA-body report attached; reduced-motion neutralization holds.
3. A v1.33→v1.34 before/after gallery (dark-weighted) and a milestone audit against this intent are produced; human UAT passes.

**Status:** Pending

## Progress — v1.35 (active)

| Phase | Requirements | Status |
|-------|--------------|--------|
| 137 Brand pressure-test & research | BRAND-AUDIT-01 | In progress |
| 138 Logo directions + selection checkpoint | LOGO-DIRECTIONS-01 | In progress (awaiting owner pick) |
| 139 Logo finalization & full lockup set | LOGO-SYSTEM-01 | Pending |
| 140 Design-tokens package + fonts | TOKENS-PKG-01 | Pending |
| 141 The HTML brand book + examples | BRANDBOOK-HTML-01 | Pending |
| 142 Adoption / rollout across product | BRAND-ADOPT-01 | Pending |
| 143 Milestone verification & UAT | BRAND-VERIFY-01 | Pending |

## Requirement Coverage — v1.35 (active)

| Requirement | Phase | Status |
|-------------|-------|--------|
| BRAND-AUDIT-01 | Phase 137 | In progress |
| LOGO-DIRECTIONS-01 | Phase 138 | In progress |
| LOGO-SYSTEM-01 | Phase 139 | Pending |
| TOKENS-PKG-01 | Phase 140 | Pending |
| BRANDBOOK-HTML-01 | Phase 141 | Pending |
| BRAND-ADOPT-01 | Phase 142 | Pending |
| BRAND-VERIFY-01 | Phase 143 | Pending |

**Coverage:** 7/7 requirements mapped across 7 phases.

## Progress — v1.34 (active — Phases 128–133 complete)

| Phase | Requirements | Status |
|-------|--------------|--------|
| 128 Contrast gate harness + dark seed coverage | CONTRAST-HARNESS-01 | Complete |
| 129 Dark brand-expression audit | DARKAUDIT-01 | Complete |
| 130 Dark surface ramp + depth tokens | DARKTOKEN-01 | Complete |
| 131 Glow + dark shadow + copper system | GLOW-01, COPPER-01 | Complete |
| 132 A11y contrast remediation (hard gate) | A11Y-TOKEN-01 | Complete |
| 133 Dark/path motion expression | DARKMOTION-01 | Complete |
| 134 Under-iterated surface polish | SCREEN-DARK-01 | Pending |
| 135 Shell chrome polish | SHELL-DARK-01 | Pending |
| 136 Milestone verification & UAT | DUALVERIFY-01 | Pending |

## Requirement Coverage — v1.34 (active)

| Requirement | Phase | Status |
|-------------|-------|--------|
| CONTRAST-HARNESS-01 | Phase 128 | Complete |
| DARKAUDIT-01 | Phase 129 | Complete |
| DARKTOKEN-01 | Phase 130 | Complete |
| GLOW-01 | Phase 131 | Complete |
| COPPER-01 | Phase 131 | Complete |
| A11Y-TOKEN-01 | Phase 132 | Complete |
| DARKMOTION-01 | Phase 133 | Complete |
| SCREEN-DARK-01 | Phase 134 | Pending |
| SHELL-DARK-01 | Phase 135 | Pending |
| DUALVERIFY-01 | Phase 136 | Pending |

**Coverage:** 10/10 requirements mapped across 9 phases.

## Ordering Rationale

128 makes AA measurable + dark observable; 129 ranks the work; 130–133 are the compounding systemic fixes
(ramp → glow/copper → a11y → motion), each carrying a cross-AI/contrast gate because they touch shared tokens —
with 132 the **hard AA gate** that 134–135 inherit; 134–135 are the per-screen/shell dividends with the
explicitly-flagged under-iterated surfaces front-loaded; 136 closes the loop. Gate phases: 130, 131, 132, 133, 136.
The central architectural risk is shared-token edits regressing light — mitigated by theme-scoped elevation tokens
that pin light literally and a re-run of the light matrix + light contrast gate after every systemic change.

## Historical Contract Anchors

- [PHASE97-SCOPE-GUARD] Runtime breadth remains closed; v1.34 is UI polish only. See `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-SCOPE-GUARD.md`.
- [POST-V1.29-DONE-POSTURE] The library scope is effectively complete; this milestone is an explicit owner-initiated polish wedge for the existing operator/admin proof surface, not roadmap re-expansion. See `.planning/threads/scrypath-post-v1.29-done-posture-2026-05-31.md`.

## Source plan

Full design + methodology + brand-expression spec + risk analysis: `~/.claude/plans/v1-33-admin-ui-deep-tower.md` (the owner-approved v1.34 plan).

## Next

**Active: milestone v1.35 Brand System & Logo Identity (phases 137–143).** Phase 137 (BRAND-AUDIT-01)
pressure-test + research and Phase 138 (LOGO-DIRECTIONS-01) logo directions are under way; the milestone
is blocked at the **Phase 138 selection checkpoint** awaiting the owner's choice of primary logo direction.
After the pick: 139 finalize the logo family → 140 tokens+fonts → 141 the HTML brand book → 142 adopt across
product → 143 verify/UAT. Source plan: `~/.claude/plans/brand-book-pressure-test-scalable-alpaca.md`.

**Resumed & advanced: milestone v1.34 (phases 128–136).** v1.35 shipped 2026-06-24; v1.34 resumed and Phases
128–133 are now complete & verified (Phase 133 DARKMOTION-01 verification fully automated, 0 human UAT, 2026-06-25).
**Next: Phase 134 (SCREEN-DARK-01).** No v1.35 brand-token refinement shipped, so the remaining dark-polish phases
(134–135) inherit the existing tokens unchanged.
