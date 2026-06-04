---
phase: 121-design-system-tokens
plan: 121
subsystem: ui
tags: [tailwind-v4, design-tokens, scrypath_ops, opsui, css]
requires:
  - phase: 120-per-touchpoint-audit
    provides: ranked fix-class-tagged backlog (11 systemic token/component findings)
provides:
  - "`--ease-ops-exit` dismissal easing token (defined; wired in Phase 123)"
  - "Complete status-tone set: metric_tone_class/1 maps info/partial/running (was nil); .ops-metric-{info,partial,running} classes; widened ops_metric + ops_intent_card kind enums"
  - "Raw Tailwind-step leaks routed to -ops- tokens across skip-link, theme toggle, empty-state, upload-box, checkbox, data-card, modal close, object-item CSS"
  - "ops-preflight sm: 2-col tablet intermediate (4-col only at lg)"
affects: [opsui, scrypath_ops, admin-ui, design-tokens]
tech-stack:
  added: []
  patterns: [Tailwind v4 @theme tokens, .ops-* component layer, single :focus-visible outline law]
key-files:
  created:
    - .planning/milestones/v1.33-phases/121-design-system-tokens/121-PLAN.md
    - .planning/milestones/v1.33-phases/121-design-system-tokens/121-SUMMARY.md
    - .planning/milestones/v1.33-phases/121-design-system-tokens/121-VERIFICATION.md
  modified:
    - scrypath_ops/assets/css/app.css
    - scrypath_ops/assets/css/DESIGN-TOKENS.md
    - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
    - scrypath_ops/lib/scrypath_ops_web/components/layouts.ex
key-decisions:
  - "Define --ease-ops-exit now but do not wire it onto any close animation (that is the Phase 123 motion gate)."
  - ":partial settles like :warning (shared tone family); :running accents the brand primary so an in-flight count reads as 'working', not a problem."
  - "Drop the skip-link ring-2 (the single :focus-visible outline is the shell's only focus ring) and the theme-toggle brightness-200 magic (base-100 on base-300 already has contrast)."
  - "mt-0.5 (0.125rem) rounds up to the smallest spacing token mt-ops-1 (0.25rem); .ops-object-item 0.875rem padding maps to --spacing-ops-3 (0.75rem) — accepted token rounding, no perceptible regression."
patterns-established:
  - "Every tone consumed anywhere (surface / badge / metric) has a backing class — no 'supported on badges but nil on metrics' gaps."
  - "Responsive grids that jump from 1-col straight to a dense N-col get an sm: intermediate step."
requirements-completed: [TOKEN-01]
completed: 2026-06-03
---

# Phase 121 Summary: Design-system tightening — tokens (TOKEN-01)

**The token system is tightened — a crisp exit-easing token defined, the status-tone set completed so `info`/`partial`/`running` are first-class everywhere a tone is consumed, the audited raw Tailwind-step leaks routed to `-ops-` tokens, and the preflight tablet jump given an `sm:` step — with `DESIGN-TOKENS.md` in lockstep.**

## Accomplishments

- **`--ease-ops-exit`** (`cubic-bezier(0.4, 0, 1, 1)`, ease-in) added to `app.css` `@theme` and documented in `DESIGN-TOKENS.md`. Defined only; wiring onto modal/palette/flash close is Phase 123.
- **Status-tone set completed.** `metric_tone_class/1` now maps `:info`/`:partial`/`:running` (previously `nil`), backed by new `.ops-metric-{info,partial,running}` border-accent classes (`:partial`→warning hue, `:running`→primary). `ops_metric` and `ops_intent_card` `kind` enums widened from `[:neutral,:success,:warning,:error]` (and the info-only intent variant) to the full `[:neutral,:info,:success,:warning,:error,:partial,:running]` set, matching `tone_class/1`/`badge_class/1`.
- **Raw-step leaks → tokens:**
  - skip-link (`layouts.ex`): `rounded-md`/`px-3`/`py-2`/`top-2`/`left-2`/`z-50`/`shadow-lg`/`ring-2` → `rounded-ops-control`/`px-ops-3`/`py-ops-2`/`top-ops-2`/`left-ops-2`/`z-ops-skip-link`/`shadow-ops-overlay`, `ring-2` dropped.
  - theme toggle (`layouts.ex`): `p-2`→`p-ops-2`, `border-1`→`border`, removed `brightness-200`.
  - `ops_empty_state` `p-5`/`mt-2` → `p-ops-5`/`mt-ops-2`; `ops_upload_box` `p-3`/`mt-1`/`mt-3` → ops tokens; `ops_checkbox_list` `p-3`→`p-ops-3` + checkbox `rounded`→`rounded-ops-sm`; `ops_data_card` `p-4`/`mt-0.5` → `p-ops-4`/`mt-ops-1`; `ops_modal` close `right-3 top-3` → `right-ops-3 top-ops-3`; `.ops-object-item` CSS `padding: 0.875rem` → `var(--spacing-ops-3)`.
- **`ops-preflight`**: added a `@media (min-width: 640px)` 2-col rule; the `repeat(4,…)` now starts at `1024px` (`lg`) instead of `768px`, so the wizard isn't a cramped 4-up on tablets.
- **Shadow ladder verified** (`shadow-ops-mid` used on segmented-selected; intent-card hover uses `shadow-ops-raised`) — confirmed correct, no change (matches the backlog's CONFIRMED-already-correct hypothesis).
- **`DESIGN-TOKENS.md` in lockstep:** added the `--ease-ops-exit` motion row and a note that the full tone set is backed everywhere (including the metric border-accent modifiers).

## Task Commits

1. **feat(phase121): complete status-tone set, add exit easing token, fix raw-step leaks (TOKEN-01)** — `15d77e4`

## Deviations from Plan

None. All listed token fix-class items landed; the shadow-ladder check needed no change.

## Verification

`mix verify.opsui` 129/0, ScrypathOps suite 129/0, ecommerce compile `--warnings-as-errors` clean, 40-shot matrix re-captured green with no regressions (see `121-VERIFICATION.md`, shared with Phase 122 since both shipped in one pass).

## Self-Check: PASSED

- `--ease-ops-exit` present in `app.css` `@theme` and `DESIGN-TOKENS.md`.
- `metric_tone_class/1` maps info/partial/running; `.ops-metric-{info,partial,running}` in compiled CSS.
- Raw-step leaks routed; new `-ops-` utilities emit into `priv/static/assets/css/app.css`.
- Commit `15d77e4` in git history on `gsd/v1.33-admin-ui-insane-polish`.
