---
phase: 123-micro-animation-layer
plan: 123
subsystem: ui
requirement: MOTION-01
gate: true
---

# Phase 123 Plan: Micro-animation layer (MOTION-01)

## Goal

Add the restrained micro-animation layer that completes the "elevate within reserved"
brand decision: motion exists only in service of a job-to-be-done, never decoration.
Wire the foundations Phases 121 (the `--ease-ops-exit` token) and 122 (the static row
hover/press states, the `.ops-loading` pulse) teed up. No LiveView logic/event/behavior
changes — CSS + the existing JS-transition hooks only.

## Hard constraints (house style, enforced)

- transform/opacity only
- < 300ms
- no bounce / spring overshoot
- reduced-motion-safe via the single global rule (`app.css` `@media (prefers-reduced-motion: reduce)`)

## Research (emilkowalski — applied vs rejected)

Read https://emilkowal.ski/ui/great-animations.

**Applied:**
- **Enter/exit easing asymmetry** — enters ease *out* (decelerate), exits ease *in*
  (accelerate). A1 uses `--ease-ops-out` (~240ms enter) vs `--ease-ops-exit` (~120ms exit).
- **ease-out for enters** — keep the existing `--ease-ops-out`/`--ease-ops-standard` enters.
- **Duration < 300ms** — all beats fit the existing token ladder (90/120/180/200/240ms).
- **Interruptibility** — the palette re-open cancels an in-flight close (clear the timer +
  closing class) so a dismissal can be reversed mid-flight without a flicker.
- **Origin-aware transforms** — the modal/palette exit settles back toward the same
  `translateY(4px) scale(0.98)` the enter came from (a reverse, not a new direction).
- **transform/opacity only** — no layout-animating properties touched.
- **Respect prefers-reduced-motion** — verified neutralized by the global rule.

**Rejected (too playful for an ops console):**
- **Spring / bounce / overshoot** — the article allows springs for organic motion; rejected
  here. An incident tool must not overshoot; cubic-bezier ease only.
- **Count-up / ticker value animations** — already banned in DESIGN-TOKENS; not added.
- **Decorative staggered reveal as a default** — see A3 below.

## Work items

- **A1 — exit easing on dismissals.**
  - `core_components.ex` `show/2`/`hide/2`: route the raw `ease-out`/`ease-in` to
    `ease-ops-out`/`ease-ops-exit` (enter ~240ms, exit ~120ms). Drives flash/banner show/hide.
  - `ops_modal` (`ops_ui.ex`): add `phx-remove` JS transition (`ease-ops-exit`, 120ms) so the
    modal eases out when LiveView removes it on cancel/confirm. Behavior unchanged.
  - Command palette JS (`app.js`): `close()`/`closeSheet()` add a `.ops-cmdk--closing` class
    for one tick (~160ms) before `[hidden]`, playing the new `ops-modal-out`/`ops-fade-out`
    keyframes. Re-open cancels the pending close (interruptibility).
  - CSS: add `ops-modal-out` + `ops-fade-out` exit keyframes; `.ops-cmdk--closing` selectors.

- **A2 — signature verdict tone-settle (the brand moment).** Coordinate `.ops-verdict`,
  `.ops-verdict__dot`, and every `.ops-metric` border onto the SAME `--duration-ops-status`
  + `--ease-ops-standard`, so a Refresh that flips posture reads as one coherent beat. Add the
  dot's `background-color` to the transition (it snapped before). Pure CSS — no JS, no stagger.

- **A4 — row press/hover timing polish.** `.ops-result-row`/`.ops-object-item`: press transform
  at `--duration-ops-instant` (matching `.ops-btn:active`), hover settle at `--duration-ops-fast`
  — one press-feel authority across buttons, cards, and rows.

- **A3 — staggered result reveal.** Evaluate against the "no dashboard toy" bar; ship only if
  clearly under it. (Outcome recorded in SUMMARY/VERIFICATION.)

- **DESIGN-TOKENS.md** — document the new keyframes + the A1/A2/A4 rules in lockstep.

## Verification gate

1. `mix verify.opsui` green (129/0 baseline).
2. `cd scrypath_ops && mix test` green.
3. `cd examples/scrypath_ecommerce && mix compile --warnings-as-errors` clean.
4. Boot + re-screenshot the 40-shot matrix → confirm no static regression in both themes.
5. Reduced-motion: confirm additions are neutralized and nothing functional breaks
   (palette open/close, disclosure toggle, modal open/close).
