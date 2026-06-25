---
phase: 133-dark-path-motion-expression-r-g
plan: 02
subsystem: scrypath_ops admin UI — motion-discipline static contract
tags: [test, exunit, css-contract, motion, dark-mode, darkmotion-01, static-assert]
status: complete
requires:
  - "Plan 01 .ops-path-*/.ops-code-block--shimmer CSS vocabulary in app.css"
  - "design_tokens_contract_test.exs (the structural analog this mirrors)"
  - "existing --duration-ops-* tokens (the tokenization the contract enforces)"
provides:
  - "ScrypathOpsWeb.MotionContractTest — static CSS contract over the path-motion vocabulary"
  - "build-fails-on-regression for transform/opacity-only + tokenized <300ms + dual-dark-path"
affects:
  - "Phase 134 (SCREEN-DARK-01) / 135 (SHELL-DARK-01): any reuse of .ops-path-* now gated by this contract"
  - "Plan 03 browser proof complements this static layer (reduced-motion, patch-refire, screenshots)"
tech-stack:
  added: []
  patterns:
    - "Static CSS contract as an ExUnit test (File.read! + Regex.scan over app.css) — mirrors design_tokens_contract_test.exs; no verify.opsui.ex change, picked up by mix test automatically"
    - "Block-isolation regex: scan only rules whose selector mentions ops-path/ops-code-block--shimmer, never the whole stylesheet"
    - "Dual-dark-path symmetry asserted via set-difference of [data-theme=dark] vs system-dark selectors that set var(--shadow-ops-glow)"
key-files:
  created:
    - scrypath_ops/test/scrypath_ops_web/motion_contract_test.exs
  modified: []
decisions:
  - "`inset` deliberately NOT in the forbidden-property list — the line-draw ::after uses `inset: auto 0 0 0` + border-bottom/border-image as STATIC positioning precisely to avoid banned width/height/top/left longhand; banning inset would false-flag that intentional choice (runtime motion stays scaleX+opacity)"
  - "Dual-dark-path symmetry scoped to the .ops-object-item-active active-path glow (the only dark-only path glow Plan 01 shipped); the recommended-intent-card glow predates Phase 133 with its own dual coverage, so it is not in scope of this assertion"
  - "Non-empty guard on the active-path dark glow set so a regression that removed BOTH dark branches cannot pass vacuously"
metrics:
  duration: ~2min
  completed: 2026-06-25
  tasks: 1
  files: 1
---

# Phase 133 Plan 02: Motion-Discipline Static CSS Contract Summary

Landed the locked D-05 static-CSS assert as `ScrypathOpsWeb.MotionContractTest` — a pure
file-read + regex ExUnit test that reads `assets/css/app.css`, isolates the `.ops-path-*` /
`.ops-code-block--shimmer` path-motion blocks, and fails the build on any motion-discipline
violation. It binds DARKMOTION-01's "transform/opacity-only + tokenized <300ms + dual-dark-path"
properties to an automated check that runs every commit via `mix verify.opsui` (no
`verify.opsui.ex` change — ExUnit discovers it automatically).

## What Was Built

**Task 1 — `motion_contract_test.exs` (commit `2b4490c`)**

`ScrypathOpsWeb.MotionContractTest` mirrors `design_tokens_contract_test.exs`'s exact shape
(`use ExUnit.Case, async: true`; `@app_css` path-expanded to `../../assets/css/app.css`; a
`css/0` helper doing `File.read!`; `Regex.scan` over the source). A `path_motion_blocks/0` helper
extracts every `{selector, body}` rule whose selector text mentions `ops-path` or
`ops-code-block--shimmer`, so the contract asserts ONLY over the new vocabulary, never the whole
stylesheet. Three assertions:

1. **Transform/opacity-only** — fails if any path-motion block *declares* a banned animatable
   layout/paint property (`width`/`height`/`top`/`left`/`margin`/`filter`/`background-position`/
   `stroke-dashoffset`/`stroke-dasharray`). Allowed animated set is `{transform, opacity,
   box-shadow}`. A token-boundary regex (`(?<![a-z-])prop\s*:`) means `border-bottom`/
   `border-image`/`transform-origin: left center` are not false-flagged.
2. **Tokenized duration <300ms** — collects every `transition:`/`animation:` value in a path-motion
   block; asserts each references a `--duration-ops-*` token (all ≤240ms by definition, so
   token-use proves <300ms) AND contains no raw `\d+ms`/`\d+s` literal.
3. **Dual-dark-path** — collects the `.ops-object-item-active` selectors that set
   `var(--shadow-ops-glow)` under the explicit-dark (`[data-theme="dark"]`) and system-dark
   (`@media (prefers-color-scheme: dark) html:not([data-theme="light"])`) contexts, and asserts
   set-difference symmetry in both directions, plus a non-empty guard so a both-branches-removed
   regression cannot pass vacuously.

## Verification Results

- `mix test test/scrypath_ops_web/motion_contract_test.exs`: **3 tests, 0 failures** (~0.5s, async, no DB).
- **Negative proof (acceptance criterion)** — each assertion proven RED against an injected
  violation, then app.css restored byte-clean:
  - injecting `filter: blur(1px)` into `.ops-path-node` → transform/opacity test RED.
  - replacing a `var(--duration-ops-fast)` with `200ms` in a path-motion transition → token test RED.
  - deleting the system-dark mirror of `.ops-object-item-active` glow → dual-dark-path test RED.
- `mix verify.opsui`: the new `MotionContractTest` (3 tests) runs and passes inside the gate with
  **no change to `verify.opsui.ex`** — confirmed it is picked up by `mix test` automatically.
- `git status` after restore: `assets/css/app.css` clean (no diff); the test file is the only change.

## Deviations from Plan

None — plan executed exactly as written. One within-plan judgement worth recording: `inset` is
**not** in the forbidden-property list even though the plan's prose lists layout properties to ban.
Plan 01 deliberately authored the line-draw `::after` with `inset: auto 0 0 0` + `border-bottom` +
`border-image` as STATIC positioning precisely to satisfy the literal `width`/`height`/`top`/`left`
ban while keeping runtime motion to `scaleX` + `opacity`. Banning `inset` would false-flag that
intentional, plan-blessed choice (documented in Plan 01's decisions). The contract therefore bans
the specific longhand the plan/D-05 names and treats `inset` as the sanctioned static alternative.

## Deferred Issues

**4 pre-existing `OpsShellContractTest` failures (logo.svg → inline-SVG drift)** — unchanged from
Plan 01, NOT caused by this plan. `mix verify.opsui` reports `2 doctests, 132 tests, 4 failures`;
the 4 are `OpsShellContractTest` markers for `/ops/search`, `/ops/failed-sync`, `/ops/posture`,
`/ops/sync-drift`, all from the v1.35 brand-adoption inline-SVG header swap (commit `fcb8fc7`) that
did not update the shell-contract test. This plan adds only a test file and touches no
header/logo/layouts. Already logged in `deferred-items.md` (per the executor Scope Boundary). The
new `MotionContractTest` is green.

## Known Stubs

None. The file is a deterministic file-read + regex contract — no hardcoded data, no placeholders,
no unwired sources.

## Self-Check: PASSED

- File: `scrypath_ops/test/scrypath_ops_web/motion_contract_test.exs` exists on disk.
- Commit: `2b4490c` present in git history.
