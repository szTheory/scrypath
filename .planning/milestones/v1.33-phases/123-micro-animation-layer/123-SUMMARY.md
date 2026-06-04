---
phase: 123-micro-animation-layer
plan: 123
subsystem: ui
tags: [phoenix, liveview, scrypath_ops, opsui, css, motion, animation]
requires:
  - phase: 120-per-touchpoint-audit
    provides: motion fix-class backlog (A1/A2/A3/A4 = P15/P16/P3+P17/P3)
  - phase: 121-design-system-tokens
    provides: --ease-ops-exit token + completed status-tone set
  - phase: 122-design-system-components
    provides: static row hover/press states + .ops-loading pulse primitive
provides:
  - "A1 exit easing wired to dismissals: flash/banner (core_components show/hide → ease-ops-out/ease-ops-exit), modal (ops_modal phx-remove exit transition), command palette + cheat sheet (.ops-cmdk--closing exit beat, interruptible)"
  - "A1 new exit keyframes ops-modal-out + ops-fade-out (origin-aware mirrors of ops-modal-in/ops-fade-in)"
  - "A2 signature verdict tone-settle: .ops-verdict + .ops-verdict__dot + .ops-metric borders coordinated on one --duration-ops-status + --ease-ops-standard beat (dot color now transitions); pure CSS, no JS/stagger"
  - "A4 row press/hover timing: .ops-result-row/.ops-object-item press transform at --duration-ops-instant (button parity), hover settle at --duration-ops-fast"
  - "A3 (staggered result reveal) deliberately NOT shipped — documented rationale"
affects: [opsui, scrypath_ops, admin-ui]
tech-stack:
  added: []
  patterns: [enter/exit easing asymmetry, origin-aware exit transforms, interruptible JS dismissal, shared-token motion coordination]
key-files:
  created:
    - .planning/milestones/v1.33-phases/123-micro-animation-layer/123-PLAN.md
    - .planning/milestones/v1.33-phases/123-micro-animation-layer/123-SUMMARY.md
    - .planning/milestones/v1.33-phases/123-micro-animation-layer/123-VERIFICATION.md
  modified:
    - scrypath_ops/assets/css/app.css
    - scrypath_ops/assets/css/DESIGN-TOKENS.md
    - scrypath_ops/assets/js/app.js
    - scrypath_ops/lib/scrypath_ops_web/components/core_components.ex
    - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
key-decisions:
  - "A2 coordination is a SHARED TIMING TOKEN, not a JS stagger: verdict surface, verdict dot, and metric borders all transition on --duration-ops-status + --ease-ops-standard, so posture flips read as one beat. The dot gained a transition (it snapped before) because it is the loudest tone signal. No JS hook — a stagger would read as a dashboard toy."
  - "A1 palette/sheet exit is JS-class-driven (.ops-cmdk--closing for ~160ms before [hidden]) rather than a Phoenix.LiveView.JS transition, because the palette is a pure client-side hook with no server event; re-open cancels the pending close (interruptibility)."
  - "A1 modal exit uses phx-remove (Phoenix.LiveView.JS.transition) so LiveView plays the ease-out before removing the :if-gated node; the cancel_event still fires server-side state unchanged."
  - "core_components show/hide raw ease-out/ease-in routed to ease-ops-out/ease-ops-exit (also cleans the raw-step leak); enter ~240ms, exit ~120ms — the emilkowalski enter/exit asymmetry."
  - "A4 press transform runs at --duration-ops-instant (= .ops-btn:active) while hover color/elevation stay at --duration-ops-fast: one press-feel authority across buttons/cards/rows."
  - "A3 SKIPPED: a CSS-only nth-child stagger re-fires on every LiveView DOM patch of the result list (re-runs/re-sorts) → flicker; gating to first-reveal needs a JS hook this item forbids. Reserved brand favors restraint."
emilkowalski-principles-applied:
  - "enter/exit easing asymmetry (ease-out enter, ease-in exit)"
  - "ease-out for enters"
  - "durations < 300ms"
  - "interruptibility (re-open cancels in-flight close)"
  - "origin-aware exit transforms (exit reverses toward the enter origin)"
  - "transform/opacity only"
  - "respect prefers-reduced-motion"
emilkowalski-principles-rejected:
  - "spring/bounce/overshoot — too playful for an incident console"
  - "count-up/ticker value animations"
  - "decorative default stagger (A3)"
requirements-completed: [MOTION-01]
completed: 2026-06-03
---

# Phase 123 Summary: Micro-animation layer (MOTION-01)

Added the restrained micro-animation layer — the motion half of "elevate within reserved".
Every beat is transform/opacity only, < 300ms, no bounce, and neutralized by the single
global `prefers-reduced-motion` rule. No LiveView logic/event/behavior changed; this wires
timing/easing onto existing chrome and existing JS-transition hooks.

## What shipped

### A1 — exit easing on dismissals
The console only enter-animated chrome before; close vanished. Now close eases out with the
crisp `--ease-ops-exit` (ease-in), faster than the enter — so dismissal feels as intentional
as open (emilkowalski enter/exit asymmetry).
- **Flash / connection banner** — `core_components.ex` `show/2` (`ease-ops-out`, enter) and
  `hide/2` (`ease-ops-exit`, exit); also cleans the prior raw `ease-out`/`ease-in` leak.
- **Modal** — `ops_modal` (`ops_ui.ex`) gets a `phx-remove` `Phoenix.LiveView.JS.transition`
  (`ease-ops-exit`, 120ms) so it eases out as LiveView removes the `:if`-gated node.
- **Command palette + cheat sheet** — the `CommandPalette` JS hook adds `.ops-cmdk--closing`
  for ~160ms before `[hidden]`, playing the new `ops-modal-out` (panel) + `ops-fade-out`
  (backdrop) keyframes. Re-opening cancels the pending close (interruptibility).

### A2 — signature verdict tone-settle (the brand moment)
`.ops-verdict` (surface), `.ops-verdict__dot`, and every `.ops-metric` border now transition
on the **same** `--duration-ops-status` + `--ease-ops-standard` pair. A Refresh that flips
posture settles to the new tone as one coherent beat — "the answer just moved" — rather than
six independent flickers. The dot gained a `background-color` transition (it snapped before),
because the dot is the loudest tone signal and a snapping dot would break the single-beat read.
Pure CSS: the coordination is the shared timing token, not a JS stagger (which would read as a
dashboard toy in an incident tool).

### A4 — row press/hover timing polish
`.ops-result-row`/`.ops-object-item` press transform now runs at `--duration-ops-instant`
(matching `.ops-btn:active`), while hover color/elevation settle at `--duration-ops-fast` —
one press-feel authority across buttons, cards, and interactive rows.

### A3 — staggered result reveal: NOT shipped
A CSS-only `nth-child` stagger re-fires on every LiveView DOM patch of the result list
(re-runs, re-sorts), reading as flicker — the dashboard-toy bar the reserved brand rejects.
Gating it to first-reveal only requires a JS hook this item explicitly forbids. Skipped on the
side of restraint and documented in DESIGN-TOKENS.md.

## DESIGN-TOKENS.md sync
Added the enter/exit keyframe table (`ops-modal-in/out`, `ops-fade-in/out`), the A1 asymmetry
rule, the A2 coordination contract, the A4 press/hover authority, and the A3 skip rationale.

## Verification (all green)
1. `mix verify.opsui` — 2 doctests, 129 tests, 0 failures (baseline parity).
2. `cd scrypath_ops && mix test` — same suite, 129/0.
3. `cd examples/scrypath_ecommerce && mix compile --warnings-as-errors` — clean (exit 0).
4. Booted `:4002` (seed run separately, then `phx.server`; ops `assets.build` first;
   Meilisearch via `make infra`; non-sandbox dev DB) and ran `npm run test:e2e:admin-matrix`
   → 3 scenarios / 40 shots, all passed; Control Room (verdict hero) + Search (result rows)
   confirmed unchanged in light and dark — motion is invisible at rest, so no static regression.
5. Reduced-motion (`reducedMotion: "reduce"`): palette open/close, interrupt-reopen, cheat
   sheet open/close, and a Failed-Sync disclosure toggle all functional; `.ops-verdict`
   computed `transition-duration` = `1e-05s` (0.01ms) → additions neutralized by the global rule.
