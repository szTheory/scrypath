---
phase: 133-dark-path-motion-expression-r-g
plan: 01
subsystem: scrypath_ops admin UI — motion/design-system
tags: [css, motion, design-system, dark-mode, heex-component, darkmotion-01]
status: complete
requires:
  - existing --duration-ops-*/--ease-ops- motion tokens (Phase 123)
  - --shadow-ops-glow / --shadow-ops-glow-copper dark tokens (Phase 130/131)
  - .ops-copper-node declared-but-unused vocabulary (Phase 122, first consumer here)
  - .ops-object-item-active / .ops-intent-card--recommended server-state classes
provides:
  - ".ops-path-trace path line-draw (transition-driven pseudo-element)"
  - ".ops-path-node / .ops-path-node--copper active-path node glow"
  - ".ops-code-block--shimmer opt-in hover glint"
  - "attr(:shimmer, :boolean, default: false) on ops_code_block/1"
  - "active Playbook item dual-dark-path glow on .ops-object-item-active"
  - "DESIGN-TOKENS.md Phase 133 path-motion section"
affects:
  - Phase 134 (SCREEN-DARK-01) and 135 (SHELL-DARK-01) reuse the .ops-path-* vocabulary
  - Plan 02 adds the static-CSS contract that gates this vocabulary in verify.opsui
  - Plan 03 adds the browser proof (reduced-motion, patch-refire, dark+light screenshots)
tech-stack:
  added: []
  patterns:
    - "Line-draw as transition on a pseudo-element state toggle (NOT @keyframes-on-mount) — A3 patch-safety precedent"
    - "Dual-dark-path: compose glow onto existing ring in BOTH [data-theme=dark] and prefers-color-scheme:dark html:not([data-theme=light])"
    - "Opt-in component API via a single boolean attr (shimmer), default false — the only new API"
key-files:
  created:
    - .planning/phases/133-dark-path-motion-expression-r-g/deferred-items.md
  modified:
    - scrypath_ops/assets/css/app.css
    - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
    - scrypath_ops/lib/scrypath_ops_web/live/search_live.ex
    - scrypath_ops/assets/css/DESIGN-TOKENS.md
decisions:
  - "Line-draw underline uses inset shorthand + border-bottom + border-image (no width/height/top/left longhand) to satisfy the literal banned-property grep while staying transform/opacity-only at runtime"
  - "Active Playbook item glow hand-authored in both dark paths composing onto its existing inset ring (Precedent D); recommended intent card already gets --shadow-ops-glow in its Phase 130 dark composition so no new rule needed there"
  - "Merge-trace .ops-path-trace applied to BOTH merge-trace ops_disclosure variants (projection + federation-position); evidence code blocks left shimmer-off"
metrics:
  duration: ~12min
  completed: 2026-06-25
  tasks: 3
  files: 4
---

# Phase 133 Plan 01: .ops-path-* Path-Motion Vocabulary Summary

Shipped the DARKMOTION-01 `.ops-path-*` motion vocabulary — a small, named, opt-in
path-expression system (line-draw + active-path node glow + opt-in code-block glint) applied only
to stable JTBD anchors, plus exactly one new component API (`shimmer` on `ops_code_block/1`), all
CSS-first with no new keyframes, no new JS hooks, and no new tokens.

## What Was Built

**Task 1 — `.ops-path-*` CSS vocabulary (`app.css`, commit `8e52595`)**
- `.ops-path-trace` + `::after`: a state-driven line-draw underline copying the
  `.ops-disclosure summary::before` precedent — rests `scaleX(0)`/`opacity:0`, draws to full width
  on `:hover`, `.ops-path-trace--active`, or `[aria-current="page"]` via a `transition` (never an
  `@keyframes` on mount, never an `nth-child` stagger). Authored with `inset` shorthand +
  `border-bottom` + `border-image` so no banned layout longhand (`width`/`height`/`top`/`left`)
  appears in the rule.
- `.ops-path-node` / `.ops-path-node--copper`: active-path node glow via `--shadow-ops-glow` /
  `--shadow-ops-glow-copper` (Precedent B / first consumer of the declared `.ops-copper-node`
  vocabulary). Free dual-dark coverage through the token (`none` in light, faint glow in dark).
- `.ops-code-block--shimmer`: opt-in hover glint — an opacity-only `::after` ring inside
  `@media (hover: hover)`. Default code blocks (no modifier) stay inert.
- Active Playbook item: `.ops-object-item-active` composes the violet glow onto its existing inset
  ring, **hand-authored in both** `[data-theme="dark"]` and
  `@media (prefers-color-scheme: dark) html:not([data-theme="light"])` (Precedent D / D-10).

**Task 2 — `shimmer` attr + anchor wiring (`ops_ui.ex`, `search_live.ex`, commit `57efe4b`)**
- `attr(:shimmer, :boolean, default: false)` on `ops_code_block/1`, immediately after
  `attr(:variant, ...)`; conditional `@shimmer && "ops-code-block--shimmer"` appended before
  `@class`. Default `false` keeps evidence calm (D-04a/c).
- Both merge-trace `ops_disclosure` variants gain a stable `class="ops-path-trace"` so the
  line-draw fires on hover only — never list-entry (D-06).
- Playbook active item (`playbook_live.ex:929` `active={...}`) and Control Room recommended card
  (`control_room_live.ex:95` `recommended={...}`) confirmed unchanged — wired purely via Task 1 CSS,
  no new state attrs.
- Evidence code blocks (search/merge payloads, Failed Sync) left shimmer-off.

**Task 3 — DESIGN-TOKENS.md documentation (commit `ea766f3`)**
- New Phase 133 path-motion section in the A1/A2/A3/A4 cadence: a class/token table, the allowed
  anchor surface, the A3 "deliberately NOT shipped" restraint boundaries (no result-list stagger,
  no shimmer on evidence, glow not on text/panels/backgrounds), and an extended Animate /
  Never-animate table (adds `stroke-dashoffset`, `background-position`, `filter` to Never).

## Verification Results

- `mix compile --warnings-as-errors` in `scrypath_ops`: **clean**.
- Grep acceptance (Task 1): `ops-path` present (8 occurrences); every `transition` references a
  `--duration-ops-*` + `--ease-ops-*` token (no raw `ms`/`cubic-bezier`); no banned property
  declaration (`width`/`height`/`top`/`left`/`margin`/`filter`/`background-position`/`stroke-dashoffset`)
  in any `.ops-path-*` rule; line-draw is a `transition`, not `animation:`; active-path glow appears
  in both dark selectors.
- Grep acceptance (Task 2): `attr(:shimmer, :boolean, default: false)` matches;
  `ops-code-block--shimmer` wired before `@class`; no `shimmer` in `search_live.ex` or
  `failed_sync_live.ex`; `ops-path-trace` present twice in `search_live.ex`; playbook/control-room
  renders unchanged.
- Grep acceptance (Task 3): `ops-path`, `shimmer`, `stroke-dashoffset` all present; every new
  class/token name documented.
- `mix verify.opsui`: 125/129 pass. The **4 failures are pre-existing and out of scope** — see
  Deferred Issues.

## Deviations from Plan

None — plan executed exactly as written. The line-draw authoring choice (`inset` + `border-bottom`
+ `border-image` instead of a sized `width`/`height` box) is a within-plan implementation detail
chosen to satisfy the literal banned-property acceptance grep; the runtime behavior (scaleX +
opacity line-draw) is exactly as specified.

## Deferred Issues

**4 pre-existing `OpsShellContractTest` failures (logo.svg → inline-SVG drift)** — NOT caused by
this plan. The v1.35 brand-adoption commit `fcb8fc7` replaced the header `<img src="/ops/images/logo.svg">`
with an inline `<svg>` brand mark in `layouts.ex`, but did not update the shell-contract test,
which still asserts the old `src`. Phase 133's 4 changed files do not touch the header/logo/layouts.
Logged to `deferred-items.md` for a v1.35 brand-test follow-up. (Per the executor Scope Boundary,
only issues directly caused by the current task's changes are auto-fixed.)

## Known Stubs

None. No hardcoded empty values, placeholders, or unwired data sources introduced. The
`.ops-path-node`/`--copper` classes are vocabulary intentionally available for Phase 134/135 reuse
(documented as such in DESIGN-TOKENS.md), consistent with the plan's design-system-dividend intent.

## Self-Check: PASSED

- Files: all 4 modified files + `deferred-items.md` exist on disk.
- Commits: `8e52595`, `57efe4b`, `ea766f3` all present in git history.
