# Phase 134: Under-iterated surface polish (dual-theme) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-25
**Phase:** 134-under-iterated-surface-polish-dual-theme-s
**Areas discussed:** Earned-copper scope, Cross-screen fix vs verify-only, Binding verification gate, Hover boost scope

**Method:** All four areas selected. Per the owner's request, each was researched in parallel by a
dedicated advisor agent applying brand / creative-direction / a11y / DX / software-architecture / JTBD /
ecosystem lenses, grounded in `134-UI-SPEC.md`, `129-DARK-AUDIT-BACKLOG.md`, `DESIGN-TOKENS.md`, live
`app.css`, the newer `brandbook/`, and the `prompts/` deep-research set. Owner delegated convergence
("one-shot a perfect coherent set so I don't have to think"); recommendations below were accepted as the
locked set.

---

## Earned-copper scope (success criterion 3)

| Option | Description | Selected |
|--------|-------------|----------|
| Apply both | Copper on Control Room recommended intent-card AND Sync/Drift preflight key-callout | |
| Apply intent-card only | Copper on the one highest-signal "recommended next action" card; hold preflight | ✓ |
| Apply preflight only | Copper on preflight key-callout; leave intent-card generic | |
| Hold both | No copper this phase | |

**User's choice:** Apply to the Control Room recommended intent-card only (`.ops-copper-badge`); hold preflight.
**Notes:** Preflight is a status-chip neighborhood → second copper site would stress the "copper is never a
status tone" law and bust the ~5% budget. The recommended card is the single scan-path "what next" moment →
copper is genuinely earned. AA pre-cleared (12.07:1 dark / 14.86:1 light). Matches the Linear/Vercel/Stripe
scarce-accent-on-the-recommended-affordance pattern; avoids the accent-inflation footgun. → D-01..D-04.

---

## Cross-screen fix vs verify-only (DK-11/13/14/15)

| Option | Description | Selected |
|--------|-------------|----------|
| Tune-in-place on sight | Boost/patch any cross-screen item when a shot looks faint | |
| Strictly verify-only, defer all | No edits; defer every boost to 135/136 | |
| Hybrid — objective trigger | Tune only DK-13, behind a measured threshold; verify-only for the rest | ✓ |

**User's choice:** Hybrid. DK-11/14/15 verify-only (already resolved systemically in current code; any real
gap is systemic → Phase 135). DK-13 is the only in-pass-eligible tune, gated by an objective measured trigger
(dark-390 row-border↔surface-2 contrast < 1.20:1 → boost 12%→18% dark-only; else leave + record).
**Notes:** Reading current `app.css` showed three of four already fixed (verdict-neutral→surface-2; raised-shadow
already cool-black, no warm halo). Blast-radius lens: DK-14/11/15 edit systemic tokens consumed on un-shot
screens → light-pixel-diff + AA risk; DK-13 is a safe leaf. Objective trigger replaces subjective "looks faint"
(0-human-UAT). → D-05..D-09.

---

## Binding verification gate (success criteria 1 & 2)

| Option | Description | Selected |
|--------|-------------|----------|
| Computed-style assertion | Playwright `getComputedStyle` for bg/border/shadow + luminance delta | ✓ (binding gate) |
| Pixel-diff snapshot | Threshold-based visual regression | ✓ (light-only, threshold 0) |
| Token static-check | Assert token values in `mix verify.opsui` | ✓ (cheap tripwire only) |

**User's choice:** New `admin_surface_depth.spec.ts` (computed-style) as the binding gate, modeled on the
existing `admin_path_motion.spec.ts` idiom; light pinned by `light-pixel-diff` at threshold 0; static token
tripwire in `mix verify.opsui`.
**Notes:** Pixel-diff in dark silently passes the exact coplanar bug (tiny delta swallowed by threshold) → must
be computed luminance-delta. Mandatory matrix: Search{results, zero-results} × Sync-Drift{drift} ×
Playbooks{empty, populated}, dark + system-dark, both viewports. CI must build ops assets first (Phase-133
lesson). 40-shot matrix stays human-spot-review only. Gate also asserts copper-applied-where-decided and
hover-on-both-surfaces, so it proves all of Phase 134. → D-10..D-14.

---

## Hover boost scope (DK-17)

| Option | Description | Selected |
|--------|-------------|----------|
| Parity — boost both | `primary 32%→55%` on `.ops-result-row` AND `.ops-object-item` | ✓ |
| Search-rows-only | Split the shared selector; only Search gets 55% | |
| Parity via shared var | Use an existing shared hover-border token | (n/a — none exists) |

**User's choice:** Parity — boost both. They already share one selector, so Search-only would mean *splitting*
it and re-introducing DK-17 faintness on Playbooks.
**Notes:** Matches SPEC Color section verbatim ("result rows AND object items on :hover"). Hover vs active stay
on different axes (hover = border+mid-shadow, no glow; active = border+ring+glow) → rest<hover<active stays
clear. 55% > already-passing 32% → no AA regression on a non-text 3:1 affordance. Ecosystem default (Linear/
Notion/Vercel/GitHub apply one hover treatment across list types). → D-15..D-18.

---

## Claude's Discretion

- Exact luminance-delta floor and DK-13 1.20:1 trigger value (starting points; must stay objective numbers).
- Precise copper-badge content on the recommended intent-card (must be a genuine scan-path key fact).

## Deferred Ideas

- Sync/Drift preflight copper key-callout (held — D-02).
- Systemic DK-14 shadow re-layering / DK-15 notice routing / DK-11 verdict fix → Phase 135 if verify finds a gap.
- Shared `--hover-border-dark` token extraction → future token-hygiene pass (no new tokens this phase).
- Full 40-shot re-capture + AA report + before/after gallery as milestone gate → Phase 136 DUALVERIFY-01.
