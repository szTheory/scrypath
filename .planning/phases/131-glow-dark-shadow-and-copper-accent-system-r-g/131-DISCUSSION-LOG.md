# Phase 131: Glow, dark shadow, and copper accent system - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-04
**Phase:** 131-glow-dark-shadow-and-copper-accent-system-r-g
**Areas discussed:** Application surface / scope boundary, Recommended-card shadow composition, Copper glow token — ship or defer

**Mode:** advisor (USER-PROFILE.md present), `minimal_decisive` calibration (technical owner,
`vendor_philosophy: opinionated`). Per the Phase 128/129/130 precedent, decisions were grounded in
the codebase + the locked `131-UI-SPEC.md` Implementation Checklist rather than external research
(a CSS/token phase has no external research surface). All three areas locked to recommendation in one pass.

**Context:** `131-UI-SPEC.md` (a `/gsd:ui-phase` design contract) already locks token values, AA
pairings, allowed-site tables, and the 10-step checklist. Discussion only resolved the three HOW
ambiguities the contract left open.

---

## Application surface / scope boundary

| Option | Description | Selected |
|--------|-------------|----------|
| System + eyebrow now, defer badges | Ship tokens + classes + all zero-markup CSS applications + the shared eyebrow re-style (1 slot → 6 screens); defer per-screen copper badges (Search/Playbook/intent-card icon) to Phase 134. Keeps the `[G]` gate's blast radius clean. | ✓ |
| Apply every listed site now | Wire up all copper application sites in 131 too — per-screen `.heex` edits land in the gate phase. | |
| Vocabulary only, no application | Ship only tokens + classes + CSS-only glow/panel applications; skip even the eyebrow swap; all copper markup application deferred to 134. | |

**User's choice:** System + eyebrow now, defer badges
**Notes:** The UI-SPEC's own 10-step Implementation Checklist lists only the CSS/dark-scoped
applications + declaring the copper classes — it does not list per-screen badge edits. The eyebrow is
the lone justified in-situ application because `ops_page_header` (`ops_ui.ex:23`) is a single shared
slot and the change is a re-style, not new markup. Per-screen badges → Phase 134 (SCREEN-DARK-01),
matching the milestone's "131 = systemic vocabulary, 134 = per-screen dividends" ordering.

---

## Recommended-card shadow composition

| Option | Description | Selected |
|--------|-------------|----------|
| All three layers, token refs | Dark-scoped override stacking inset ring (top) + panel-dark seat + glow aura (behind), via token references so it stays tunable. | ✓ |
| Glow + inset only (drop panel-dark) | Recommended card gets the violet inset ring + glow but not the panel-dark ambient shadow. | |

**User's choice:** All three layers, token refs
**Notes:** The recommended card is an `.ops-intent-card`, so it should share the family's panel-dark
seated depth rather than float differently. Order: inset ring on top, panel-dark seat, glow as the
outermost soft halo. Light value (`app.css:866-870`) left byte-unchanged; the 3-layer stack is
dark-scoped only.

---

## Copper glow token — ship or defer

| Option | Description | Selected |
|--------|-------------|----------|
| Declare now, no consumer | Declare `--shadow-ops-glow-copper` in both D-10 dark paths + `@theme: none` light per checklist step 4; no class consumes it yet. | ✓ |
| Defer entirely to 133/134 | Don't declare the token in 131 at all; add it when the consuming hover rule is built later. | |

**User's choice:** Declare now, no consumer
**Notes:** One line per path, zero visual/light impact with no consumer (zero `[G]`-gate risk), and it
lets 133/134 hover work use it without reopening the `app.css` token block. The consuming hover rule
is deferred to 133/134.

---

## Claude's Discretion

- Exact authoring site/ordering of the dark-scoped override blocks (must follow the D-10 dual-path
  precedent + Phase-130 shadow blocks).
- Whether the four panel-dark target overrides live in one shared dark-scoped block or per-selector
  blocks — provided light stays pixel-identical.
- Precise `DESIGN-TOKENS.md` section wording (two new sections per UI-SPEC Lockstep Obligations).
- The `mix verify.opsui` vs `mix test`/`mix opsui.test_a11y` naming reconciliation (flagged D-13 in 130).

## Deferred Ideas

- Per-screen copper-badge/node application (Search federation, Playbook file-type, intent-card icon node) → Phase 134.
- Copper-glow consuming hover rule → Phase 133/134.
- Muted-text / header-nav AA re-tuning (contrast Cluster 3) → Phase 132.
- Full 40-shot re-capture + before/after gallery → Phase 136.
