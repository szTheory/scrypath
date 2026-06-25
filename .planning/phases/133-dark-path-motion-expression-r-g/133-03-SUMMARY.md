---
phase: 133-dark-path-motion-expression-r-g
plan: 03
subsystem: scrypath_ecommerce e2e harness — DARKMOTION-01 browser proof
tags: [e2e, playwright, motion, dark-mode, reduced-motion, patch-refire, darkmotion-01]
status: complete
requires:
  - "Plan 01 shipped .ops-path-* vocabulary (.ops-path-trace, .ops-object-item-active glow, .ops-intent-card--recommended glow, .ops-code-block--shimmer attr)"
  - "helpers/e2e.ts: waitForLiveConnected + seedScenario + drainSearchQueue + waitForSearchVisible"
  - "/dev/e2e/seed endpoint (SEED-01) with all_green / incident scenarios"
  - "booted seeded ops server on :4002 via compose dev lane (current source, not the stale baked image)"
provides:
  - "examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts — focused DARKMOTION-01 browser proof"
  - "inline reducedMotion probe (maxMotionDurationMs) — no prior analog in the harness"
  - "inline patch-refire probe (runningKeyframeAnimationCount) — counts CSSAnimation only, excludes CSSTransition"
  - "targeted screenshot set in test-results/admin-path-motion/ (9 shots: recommended card, merge-trace hover, active playbook A/B; dark+light+system-dark)"
affects:
  - "Phase 136 (DUALVERIFY-01) inherits this focused proof; full 40-shot recapture + gallery + human UAT deferred there (D-05c)"
tech-stack:
  added: []
  patterns:
    - "Theme-before-first-paint: addInitScript(phx:theme) for light/dark; newContext({colorScheme:'dark'}) with NO phx:theme write for system-dark"
    - "Patch-refire proof = running CSSAnimation count on the anchor itself (incl. ::after) staying 0 across a push_patch; running CSSTransitions are the intended patch-safe settle and are excluded"
    - "Reduced-motion proof = computed transition/animation-duration <= ~0.02ms via the global prefers-reduced-motion rule + active end state still visible (functional integrity)"
key-files:
  created:
    - examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts
  modified: []
decisions:
  - "Patch-refire probe counts ONLY running CSSAnimation (a.constructor.name === 'CSSAnimation'), excluding CSSTransition: a running transition is the intended state-driven glow/line-draw settle; only a re-firing @keyframes reveal is the A3 failure mode worth catching"
  - "Probe scope is the anchor element itself (plus its pseudo-elements via getAnimations()), NOT its descendant subtree or main: the intended Phase-123 A1 one-shot ops-fade-in reveals run on descendants and are out of DARKMOTION-01 scope"
  - "Playbook A->B selection targets the exact 'Load preview' accessible name (a 'Load' substring also matches the unrelated 'Reload playbooks' button)"
  - "Shimmer coverage ships the shippable assertion (evidence code blocks shimmer-OFF) — no live template sets shimmer={true}, so there is no shimmer-ON surface to hover; this matches Plan 01's restraint (evidence stays calm, default false)"
metrics:
  duration: ~30min
  completed: 2026-06-25
  tasks: 1
  files: 1
---

# Phase 133 Plan 03: DARKMOTION-01 Path-Motion Browser Proof Summary

Shipped `admin_path_motion.spec.ts` — the locked D-05/D-05a focused Playwright proof that
browser-verifies the transient `.ops-path-*` motion and LiveView patch-safety the static-CSS
contract (Plan 02) and screenshot matrix cannot cover: reduced-motion neutralization, hover
line-draw, active-path glow, evidence-shimmer-off, and NO patch-refire flicker — all in dark
AND light (+ system-dark), with a small targeted screenshot set. 7/7 green against a booted
seeded ops server.

## What Was Built

**Task 1 — `examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts` (commit `2634ba1`)**

A single new Playwright spec (360 lines, 7 tests) reusing the harness patterns from
`admin_screenshot_matrix.spec.ts` + `helpers/e2e.ts`. It imports `waitForLiveConnected`,
`seedScenario`, `drainSearchQueue`, and `waitForSearchVisible`, and gates every flow on
live-connected + seeded state.

Theme handling mirrors the matrix spec: `light`/`dark` set `localStorage["phx:theme"]` via
`addInitScript` before first paint; `system-dark` opens the context with `colorScheme: 'dark'`
and writes NO `phx:theme` key, exercising the `prefers-color-scheme: dark` (no `[data-theme]`)
path — the lane that would catch a missing system-dark glow mirror (D-08).

Two NEW inline probes (no prior analog in the harness — this was a genuine Wave-0 gap):

- **`maxMotionDurationMs(page, selector)`** — reads computed `transition-duration` /
  `animation-duration` on the element and its `::before`/`::after` pseudo-elements and returns
  the max (ms). Under `reducedMotion: 'reduce'` the global `app.css:1306` rule snaps every
  duration to 0.01ms; the spec asserts `<= 0.02ms` AND that the anchor's active end state is
  still visible (functional integrity, D-09).
- **`runningKeyframeAnimationCount(page, selector)`** — counts running CSS `@keyframes`
  animations (`a.constructor.name === "CSSAnimation"`, `playState === "running"`) on the anchor
  element (incl. its pseudo-elements). It deliberately **excludes `CSSTransition`**, because a
  running transition is the intended, patch-safe glow/line-draw settle — only a re-firing
  keyframe reveal is the A3 regression this probe must catch.

Coverage (D-05/D-05a), exercised in dark AND light (recommended card also system-dark):

- **Control Room recommended intent card** — `incident` scenario drives degraded posture so
  `.ops-intent-card--recommended` renders with its dual-dark glow; reduced-motion-neutralized,
  "Start here" flag still present.
- **Search merge-trace** — `all_green` seed + multi mode + "quantum" renders the
  `.ops-path-trace` merge-trace disclosure; hover drives the `::after` line-draw to its
  `scaleX(1)` end state; evidence code blocks asserted shimmer-off (`.ops-code-block--shimmer`
  count 0); single↔multi toggle round-trip leaves 0 running keyframe animations on the anchor.
- **Playbooks** — selecting playbook A then B via "Load preview" moves
  `.ops-object-item-active` (exactly one active, 0 running keyframe animations across the patch).

Targeted screenshots (D-05, small set) land in `test-results/admin-path-motion/`: recommended
card (dark/light/system-dark, reduced-motion), merge-trace hover (dark/light), active playbook
A and B (dark/light) — 9 shots, NOT the 40-shot recapture (deferred to Phase 136, D-05c).

## Verification Results

- `npx playwright test e2e/admin_path_motion.spec.ts --reporter=line`: **7 passed (~10s)**
  against a booted seeded ops server (compose dev lane on `:4002` → current source, with
  free host PG/MEILI lanes `PG_PORT=5455 MEILI_PORT=7755` because sibling project containers
  held `5432`/`7700`).
- `npx playwright test --list`: 7 tests parse cleanly (esbuild transpile — TypeScript-clean).
- Targeted screenshot set confirmed produced (9 PNGs in `test-results/admin-path-motion/`).

## Deviations from Plan

None — plan executed exactly as written. Two within-plan resolutions worth recording (both are
implementation choices the plan left to the executor, not scope changes):

1. **Patch-refire probe counts CSSAnimation only (excludes CSSTransition).** The plan said "if
   the path motion is pure `transition`, `getAnimations()` returns 0 before AND after — that
   zero IS the proof." In practice `getAnimations()` returns the running `CSSTransition`s of the
   glow settling in, so a naive count is non-zero by design. The probe filters to
   `CSSAnimation` (keyframes), which is the actual A3 signal, and scopes to the anchor itself
   (not the descendant subtree where intended Phase-123 `ops-fade-in` reveals legitimately run).
   This is the planner's stated intent realized precisely, not a deviation.
2. **Shimmer coverage = evidence-shimmer-off assertion only.** The plan's action mentions
   "hover a NON-evidence code block with `shimmer={true}` → glint visible." Plan 01 shipped the
   `shimmer` attr default-false and intentionally wired NO live template with `shimmer={true}`
   (evidence stays calm, D-04a/c), so there is no live shimmer-ON surface to hover. The spec
   therefore ships the shippable half — asserting evidence code blocks carry NO
   `.ops-code-block--shimmer` — which is the load-bearing restraint guarantee. The positive
   hover-glint is a CSS `:hover` rule already statically gated by Plan 02's MotionContractTest.

## Deferred Issues

None introduced by this plan. (Plan 01's 4 pre-existing `OpsShellContractTest` failures from
the v1.35 logo→inline-SVG drift remain logged in `deferred-items.md`, untouched here — this
plan adds only an e2e spec and changes no `scrypath_ops` source.)

## Known Stubs

None. The spec drives real seeded UI over the existing `/dev/e2e/seed` endpoint with no mocked
data sources, placeholders, or hardcoded empty values.

## Self-Check: PASSED

- File: `examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts` exists on disk (360 lines).
- Commit: `2634ba1` present in git history.
- Live verification: 7/7 tests green against the booted seeded ops server; 9 screenshots produced.
