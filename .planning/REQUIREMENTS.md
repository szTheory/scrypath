# Requirements: Scrypath v1.34 Both-Themes Perfection — Dark Signature + AA Gate

**Defined:** 2026-06-04
**Status:** Active
**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## Milestone Intent

A deliberate, owner-initiated UI/UX + design-system iteration of the `scrypath_ops` admin/ops console — the **next-level pass** building directly on v1.33's task-first IA, completed token set, and restrained-motion layer. The pivotal framing: **dark/light/system theming already exists and works** (Tailwind v4 + daisyUI two themes, a 3-way System/Light/Dark toggle, a no-flash init script, `localStorage` `phx:theme` persistence, `prefers-color-scheme` following, multi-tab sync, and a 40-shot screenshot matrix that already captures both themes). This milestone is therefore **not** "build dark mode."

It is: **make both themes genuinely perfect and brand-expressive** — dark as the *signature* look, light at parity — per `prompts/scrypath-brand-book.md` (a "dark-mode-forward" brand: midnight neutrals, violet primary, copper accent, quiet glows, route/path diagrams), **backed by a formal automated WCAG AA contrast gate** (AAA for body text), with continued per-screen and design-system polish on the surfaces v1.33 under-touched.

This is **not** runtime product breadth. This milestone consciously overrides the documented idle/maintenance posture (`.planning/PROJECT.md`) as an explicit strategic polish wedge, decided by the owner. Evidence is screenshot-backed (v1.33→v1.34 before/after across light/dark/system-dark × mobile/desktop × seed states) plus an automated contrast report.

### The mechanical root cause this milestone fixes (verified in `app.css`)
The brand book's dark surface ramp has **four** steps — Night `#0C0F14` (bg) → Ink `#141923` (surface) → **surface-2 `#1B2230`** → Slate `#2A3446` (border). The dark daisyUI theme drops `#1B2230` entirely, and its `base-200` (Night) is *darker* than `base-100` (Ink). The `.ops-*` fill recipes build "raised/muted" surfaces by mixing toward `base-200` — tuned for the *light* ramp — so in dark, raised surfaces go **darker and flatter** instead of stepping *up* in elevation. This is the architectural heart of "dark feels like a generic dashboard, not Scrypath." The fix is theme-scoped elevation tokens that leave light pixel-identical while giving dark a true Ink→surface-2 lift.

### Locked design decisions
- **Scope — comprehensive both-themes perfection + broad iteration.** Dark is the headline; light reaches parity; continue design-system/IA/JTBD polish on v1.33's under-touched surfaces. Not just plumbing (already done).
- **Default theme — keep system-follows-OS.** Do not force dark on first visit. Dark becomes the most-polished "signature" look, not a forced default. (Honors the brand's dark-forward identity through *craft*, not by overriding the user's OS preference.)
- **A11y — WCAG AA enforced as a hard automated gate in both themes**; body/long-form text targets AAA (advisory report, not build-fail).
- **CSS architecture — keep Tailwind v4 + daisyUI + `.ops-*`.** No BEM switch, no `--sp-*` rename. Double down on existing momentum.
- **Motion — restrained, in service of JTBD.** Honor v1.33's A3 precedent (no per-LiveView-patch re-firing reveals); transform/opacity only, <300ms, reduced-motion-safe, "deliberate not playful."

## Requirements

### Audit harness and evidence

- [ ] **CONTRAST-HARNESS-01**: An automated WCAG contrast gate (`@axe-core/playwright`, cloned from the existing `admin_screenshot_matrix.spec.ts` harness) walks every admin screen across light + dark + **system-dark** × seed scenarios, **fails the build on any AA violation** (4.5:1 text / 3:1 large-text & UI), and reports AAA (7:1) status for body/long-form text as advisory. Re-runnable locally (`npm run test:e2e:admin-contrast` / `make contrast`, plus a fast custom token-pair pre-check) and usable as a phase gate.
- [ ] **DARKAUDIT-01**: Every dark surface is scored against the brand-book dark rules (4-step midnight ramp adherence, 65/20/10/5 neutral/structure/violet/copper ratio, "quiet glow not loud," "faint ambient shadow plus border," restrained path-line glow, AA pass/fail from the contrast harness), producing one ranked, fix-class-tagged backlog (`129-DARK-AUDIT-BACKLOG.md`) with a systemic-vs-per-screen split. The `#1B2230` surface-2 ramp gap is finding #1. Mirrors v1.33's 47-finding audit format.

### Design-system tightening (systemic)

- [ ] **DARKTOKEN-01**: The dark theme gains a true 4-step surface ramp (introduce the missing `#1B2230` surface-2 elevation), and the `.ops-*` fill recipes resolve correctly in **both** themes via theme-scoped elevation tokens (no more "muted = darker/flatter" in dark) — with light staying pixel-identical and `DESIGN-TOKENS.md` kept in lockstep.
- [ ] **GLOW-01**: A dark-specific "faint ambient shadow **plus** border" panel recipe gives dark surfaces seated depth, and a tokenized, opt-in, low-spread violet "quiet glow" is available for route/path/diagram lines and key hover states only — never text or background floods. The allowed `linear-gradient(135deg,#5B4AD1,#6C5CE7,#C17A3E)` is reserved for hero highlight lines / diagram emphasis.
- [ ] **COPPER-01**: Copper (secondary) is promoted to its branded 5% role — a `.ops-*` copper accent vocabulary (eyebrow labels, key-callout badges, key-node diagram/route emphasis) usable in both themes, with AA-safe **dark-text-on-copper** pairings. Copper is a brand accent, never a status tone.
- [ ] **A11Y-TOKEN-01**: Muted-text alphas (`.ops-text-meta`, `.ops-trail__crumb`, header nav `/60`, handoff/palette/preflight hints) are re-tuned to clear AA 4.5:1 in both themes; body/long-form text targets AAA — all enforced by CONTRAST-HARNESS-01.

### Motion

- [ ] **DARKMOTION-01**: The restrained motion vocabulary gains the brand book's path-expression patterns where they serve a JTBD (line draw/reveal, node pulse, active-path tracing on the route mark / diagrams, code-block shimmer on hover), expressed through the existing `--duration-ops-*`/`--ease-ops-*` tokens, transform/opacity only, reduced-motion-safe, "deliberate not playful," tuned to read best in dark without breaking light. Honors v1.33's A3 no-re-fire precedent.

### Per-screen and shell (under-iterated surfaces first)

- [ ] **SCREEN-DARK-01**: The under-iterated surfaces — Search result rows (flagged as lacking separation in dark), Sync/Drift drift-chips/preflight depth, and Playbooks empty/populated — reach dark-signature + light-parity quality (separation, depth, copper/glow accents where earned, full seed-state coverage).
- [ ] **SHELL-DARK-01**: The shell chrome (header/nav, command palette, theme toggle, flash, `.ops-shell` radial violet wash) is brand-expressive and AA-clean in both themes — the flagged weak header-nav dark contrast is fixed, the `.ops-shell` wash is tuned for dark "quiet glow," and palette/flash adopt the dark ambient-shadow-plus-border recipe.

### Verification

- [ ] **DUALVERIFY-01**: The milestone is proven end-to-end — `mix verify.opsui`, the ScrypathOps LiveView suite, and the mounted ecommerce admin Playwright smoke stay green; CONTRAST-HARNESS-01 passes AA in **both** themes (with the AAA-body report attached); the 40-shot matrix is re-captured with a v1.33→v1.34 before/after gallery (dark-weighted); a milestone audit against this intent is produced; and human UAT passes.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Building dark mode from scratch | It already exists and works (two daisyUI themes, 3-way toggle, no-flash init, localStorage persistence, system-following). This milestone *perfects* it, not builds it. |
| Forcing dark as the first-visit default | Locked decision: default stays system-follows-OS. Dark is the signature look, not an OS-override. |
| New Scrypath runtime APIs or search capabilities (autocomplete, vector, hybrid, multi-backend) | Phase 97–99 scope guard still applies; v1.34 is UI polish, not runtime breadth. |
| New admin screens or productizing OPSUI into a commercial admin surface | This re-styles the existing 6 screens; it does not add product surfaces. The admin UI remains a mounted, host-owned operator proof. |
| Switching CSS architecture (BEM) or renaming tokens to `--sp-*` | Tailwind v4 + daisyUI + `.ops-*` has momentum; double down, do not switch. |
| A user-customizable / per-org theme editor | Out of this polish pass; theming stays the two brand-defined themes + system. |
| Promoting `phase105-e2e` or visual-regression to a required CI gate | The new contrast gate is a phase gate this milestone; promoting browser/visual proof to a required *merge* gate still needs an explicit policy change. |

## Traceability

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
