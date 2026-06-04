# Roadmap: Scrypath

## Milestones

- ✅ **v1.28 Realistic Demo App & Admin UI Proof** — Phases 102-105 (shipped 2026-05-31) — see `milestones/v1.28-ROADMAP.md`
- ✅ **v1.29 Contract Repair and Proof Hardening** — Phases 106-108 (shipped 2026-05-31) — see `milestones/v1.29-ROADMAP.md`
- ✅ **v1.30 Release Trust and Evidence Maintenance** — Phases 109-112 (shipped 2026-06-01) — see `milestones/v1.30-ROADMAP.md`
- ✅ **v1.31 Adoption Evidence Demo Hardening** — Phases 113-115 (UAT passed 2026-06-01)
- ✅ **v1.32 Admin UI/UX Design System Cleanup** — Phases 116-118 (shipped 2026-06-01) — see `milestones/v1.32-ROADMAP.md`
- ✅ **v1.33 Admin UI Insane Polish** — Phases 119-127 (shipped 2026-06-03) — see `milestones/v1.33-ROADMAP.md`
- 🔨 **v1.34 Both-Themes Perfection — Dark Signature + AA Gate** — Phases 128-136 (active, defined 2026-06-04)

## Phases

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

**Plans:** 1/3 plans executed

Plans:
**Wave 1**

- [x] 128-01-PLAN.md — Install @axe-core/playwright, create contrast-pairs.mjs muted manifest, wire test:e2e:admin-contrast script

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 128-02-PLAN.md — Create contrast-checker.mjs with WCAG math/self-test/D-15 guards, Makefile targets, DESIGN-TOKENS.md update

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 128-03-PLAN.md — Create admin_contrast_matrix.spec.ts axe gate, run full matrix, commit 128-CONTRAST-REPORT.md

**Status:** Pending

### Phase 129: Dark-theme brand-expression audit `[S] [R]`

**Goal:** Enumerate and score every dark surface against the brand book; produce one ranked, fix-class-tagged backlog (`129-DARK-AUDIT-BACKLOG.md`) with a systemic-vs-per-screen split and the `#1B2230` surface-2 ramp gap as finding #1. No code changes.

**Requirements:** DARKAUDIT-01

**Success criteria:**

1. Every dark touchpoint is scored on the brand's dark dimensions (4-step ramp, 65/20/10/5 ratio, quiet-vs-loud glow, ambient-shadow-plus-border, path-line glow restraint, AA pass/fail).
2. Findings are tagged by fix class and split systemic (≥3 screens → token/component fix) vs per-screen.
3. The backlog mirrors v1.33's `120-AUDIT-BACKLOG.md` format and is the single source for phases 130–135.

**Status:** Pending

### Phase 130: Dark surface ramp + depth tokens `[G]`

**Goal:** Land the 4-step midnight ramp (introduce `#1B2230` surface-2) and refactor the `.ops-*` fill recipes via theme-scoped elevation tokens so dark steps **up** in elevation while light stays pixel-identical. Highest blast radius → cross-AI gate.

**Requirements:** DARKTOKEN-01

**Success criteria:**

1. Dark renders a true four-step ramp: bg `#0C0F14` → panel `#141923` → raised/muted `#1B2230` → border `#2A3446`.
2. `.ops-muted-panel`, `.ops-data-card`, `.ops-surface-flat`, `.ops-nav-list`, `.ops-disclosure`, `.ops-kbd`, `.ops-result-row`, `.ops-preflight__card--locked` step up (not down) in dark.
3. The light theme is pixel-identical (light matrix + light contrast gate unchanged); `DESIGN-TOKENS.md` records the dark ramp.

**Status:** Pending

### Phase 131: Glow, dark shadow, and copper accent system `[R] [G]`

**Goal:** Add the brand's dark "ambient-shadow-plus-border" depth, a restrained opt-in violet "quiet glow," and copper's branded 5% accent role — tokenized, both-theme, AA-safe.

**Requirements:** GLOW-01, COPPER-01

**Success criteria:**

1. Dark panels (`.ops-panel`, `.ops-cmdk__panel`, `#flash-group`, `.ops-intent-card`) read as seated depth via a dark ambient shadow + the existing border; light keeps its vertical lift.
2. A low-spread violet glow token applies to the route mark / active-path / key-callout hover only — never text, resting panels, or background floods.
3. A `.ops-*` copper accent family (eyebrow, key-callout badge, key-node emphasis) ships with AA-safe dark-text-on-copper pairings and is used at roughly the brand's 5% ratio.

**Status:** Pending

### Phase 132: A11y contrast remediation — both themes (hard gate) `[G]`

**Goal:** Re-tune muted-text alphas so both themes pass AA and body text reaches AAA. **Gate: CONTRAST-HARNESS-01 must be green in both themes before this phase closes.**

**Requirements:** A11Y-TOKEN-01

**Success criteria:**

1. `.ops-text-meta`, `.ops-trail__crumb`, header nav, handoff/palette/preflight hints all clear AA 4.5:1 in both themes (the flagged weak dark header-nav contrast is fixed).
2. Large-text/UI elements clear ≥3:1; body/long-form text reaches AAA (≥7:1).
3. The contrast gate is green for light, dark, and system-dark; `DESIGN-TOKENS.md` records the new alpha floors.

**Status:** Pending

### Phase 133: Dark/path motion expression `[R] [G]`

**Goal:** Add the brand's directional path motion where it serves a JTBD (line-draw/reveal, active-path tracing, node pulse, code-block shimmer-on-hover), tuned for dark and restrained, via the existing motion tokens.

**Requirements:** DARKMOTION-01

**Success criteria:**

1. New motion is transform/opacity only, <300ms, no bounce, and neutralized under `prefers-reduced-motion`.
2. It honors v1.33's A3 precedent — no per-LiveView-patch re-firing reveals on result lists.
3. Motion reads "deliberate/infrastructural" in dark and does not regress light; reduced-motion + functional integrity confirmed via Playwright.

**Status:** Pending

### Phase 134: Under-iterated surface polish (dual-theme) `[S]`

**Goal:** Bring the surfaces v1.33 under-touched — Search result rows, Sync/Drift depth, Playbooks — to dark-signature + light-parity quality across all seed states.

**Requirements:** SCREEN-DARK-01

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

## Progress

| Phase | Requirements | Status |
|-------|--------------|--------|
| 128 Contrast gate harness + dark seed coverage | CONTRAST-HARNESS-01 | Pending |
| 129 Dark brand-expression audit | DARKAUDIT-01 | Pending |
| 130 Dark surface ramp + depth tokens | DARKTOKEN-01 | Pending |
| 131 Glow + dark shadow + copper system | GLOW-01, COPPER-01 | Pending |
| 132 A11y contrast remediation (hard gate) | A11Y-TOKEN-01 | Pending |
| 133 Dark/path motion expression | DARKMOTION-01 | Pending |
| 134 Under-iterated surface polish | SCREEN-DARK-01 | Pending |
| 135 Shell chrome polish | SHELL-DARK-01 | Pending |
| 136 Milestone verification & UAT | DUALVERIFY-01 | Pending |

## Requirement Coverage

| Requirement | Phase | Status |
|-------------|-------|--------|
| CONTRAST-HARNESS-01 | Phase 128 | Pending |
| DARKAUDIT-01 | Phase 129 | Pending |
| DARKTOKEN-01 | Phase 130 | Pending |
| GLOW-01 | Phase 131 | Pending |
| COPPER-01 | Phase 131 | Pending |
| A11Y-TOKEN-01 | Phase 132 | Pending |
| DARKMOTION-01 | Phase 133 | Pending |
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

Milestone v1.34 defined (phases 128–136). Start with **Phase 128 (CONTRAST-HARNESS-01)** — add `@axe-core/playwright`, the contrast matrix spec, and the token-pair checker — running it first to learn the real AA failure set before any pixels change. `/clear` then `/gsd:discuss-phase 128` (or `/gsd:plan-phase 128` to plan directly).
