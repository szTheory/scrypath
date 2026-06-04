---
phase: 122-design-system-components
plan: 122
subsystem: ui
tags: [phoenix, liveview, scrypath_ops, opsui, components, css]
requires:
  - phase: 120-per-touchpoint-audit
    provides: ranked fix-class-tagged backlog (component findings B1/B2/B5/S1/P2/P3)
  - phase: 121-design-system-tokens
    provides: completed tone set + exit-easing token + raw-step-leak baseline
provides:
  - "Shared `.ops-notice-surface` (+ `--raised`) so ops_notice/ops_status tinted-surface internals can't drift; both public APIs unchanged"
  - "ops_code_block routed to rounded-ops-md + p-ops-* tokens"
  - "New restrained ops_loading skeleton/pulse primitive (:bars / :inline, opacity-only, reduced-motion-safe)"
  - "Hover/press parity for ops_result_row + ops_object_item (border + shadow-ops-mid hover, subtle :active scale)"
  - "Sentence-cased shared empty-state copy in ops_config_empty"
  - "Pure-CSS horizontal scroll-shadow affordance (.ops-table-scroll) for dense ops_table"
affects: [opsui, scrypath_ops, admin-ui]
tech-stack:
  added: []
  patterns: [project-owned LiveView function components, shared .ops-* surface classes, opacity-only loading pulse, CSS scroll-shadow]
key-files:
  created:
    - .planning/milestones/v1.33-phases/122-design-system-components/122-PLAN.md
    - .planning/milestones/v1.33-phases/122-design-system-components/122-SUMMARY.md
    - .planning/milestones/v1.33-phases/122-design-system-components/122-VERIFICATION.md
  modified:
    - scrypath_ops/assets/css/app.css
    - scrypath_ops/assets/css/DESIGN-TOKENS.md
    - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
    - scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs
key-decisions:
  - "Consolidate via a shared CSS class (.ops-notice-surface) rather than a shared HEEx partial, so ops_notice (untitled) and ops_status (titled + actions + resting elevation) keep their distinct DOM/semantics and identical public attrs."
  - "ops_loading is opacity-only and uses the global reduced-motion rule for safety; the pulse is one of only two sanctioned loops (with the reconnect spinner)."
  - "Hover/press parity is static state styling here (the :hover/:active rules); the motion-timing polish stays Phase 123."
  - "Only the SHARED empty-state strings (ops_config_empty) are sentence-cased; the per-screen Title-Case strings in search_live/failed_sync_live are left for the Phase 124 COPY-01 sweep."
  - "ops_table scroll affordance is pure CSS (edge gradients + background-attachment:local cover gradients) — no JS, no layout shift, works in both themes."
patterns-established:
  - "Near-duplicate tinted surfaces share one .ops-* base class; variants are modifiers, not copies."
  - "Interactive-feeling rows reuse the button/card hover+press vocabulary."
requirements-completed: [COMP-01]
completed: 2026-06-03
---

# Phase 122 Summary: Design-system tightening — components (COMP-01)

**The drifting `.ops-*` component families are consolidated, the component-level state gaps are filled (shared loading primitive, hover/press parity, code-block radius, table scroll affordance), and shared-component copy is sentence-cased — presentation/semantics only, both public APIs unchanged.**

## Accomplishments

- **`ops_notice` / `ops_status` consolidated.** Extracted `.ops-notice-surface` (1px tone border, `--radius-ops-control`, `--spacing-ops-3 --spacing-ops-4` padding, body text) + a `--raised` modifier for `ops_status`'s resting elevation. Both components now compose `ops-notice-surface [+ --raised]` + `tone_class/1` instead of repeating the raw `rounded-ops-control border px-4 py-3 …` string. Public attrs (`kind`, `title`, `role`, `actions`, …) and rendered structure unchanged.
- **`ops_code_block`** raw `rounded-md`→`rounded-ops-md`, `p-3`/`p-2`→`p-ops-3`/`p-ops-2` (surfaces were already daisyUI semantic tokens; `max-h-*` left as legit content caps).
- **`ops_loading` primitive added.** `:bars` renders opacity-pulsing skeleton lines (last line tapers via `loading_bar_width/2`); `:inline` is a compact pulsing "working…" label. Opacity-only `ops-pulse` keyframe, neutralized by the global reduced-motion rule. `role="status"` + `aria-label`. Available now; screen wiring is 125/126.
- **Hover/press parity.** `.ops-result-row` + `.ops-object-item` gain a transition + `:hover` (primary-tinted border + `shadow-ops-mid`) + subtle `:active` scale — the same vocabulary `.ops-btn:active` / `.ops-intent-card:hover` already use. `.ops-result-row` padding also moved to `var(--spacing-ops-3)` (matching the `.ops-object-item` token routing from 121).
- **Sentence-case shared empty states.** `ops_config_empty`: "No Schemas Configured"→"No schemas configured", "Runtime Not Configured"→"Runtime not configured". Updated the Control Room test assertion to match. Per-screen Title-Case strings deferred to Phase 124.
- **`ops_table` scroll affordance.** Added `.ops-table-scroll` (pure-CSS edge scroll-shadows via `background-attachment: local` cover gradients) to the `ops_table` wrapper so the dense Posture/signal tables show "more this way" without JS.
- **`DESIGN-TOKENS.md` in lockstep:** added motion-table rows for row hover/press and the loading pulse.

## Task Commits

1. **feat(phase122): consolidate notice/status, ops_code_block tokens, ops_loading primitive, hover/press parity (COMP-01)** — `d90fa04`

## Deviations from Plan

- One test assertion (`control_room_live_test.exs`) updated to the sentence-case shared string — required by the `ops_config_empty` copy fix, not a behavior change. No other deviations.

## Verification

`mix verify.opsui` 129/0, ScrypathOps suite 129/0, ecommerce compile `--warnings-as-errors` clean, 40-shot matrix re-captured green; no regressions (see `122-VERIFICATION.md`).

## Self-Check: PASSED

- `.ops-notice-surface`, `.ops-loading*`, `.ops-table-scroll`, `rounded-ops-md`, `ops-pulse` keyframe all in compiled CSS.
- `ops_loading/1` compiles and is exported from `OpsUi`.
- ops_config_empty strings sentence-cased; Control Room test passes.
- Commit `d90fa04` in git history on `gsd/v1.33-admin-ui-insane-polish`.
