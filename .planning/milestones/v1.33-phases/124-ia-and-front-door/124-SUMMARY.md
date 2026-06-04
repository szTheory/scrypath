---
phase: 124-ia-and-front-door
plan: 124
subsystem: ui
tags: [phoenix, liveview, scrypath_ops, opsui, ia, microcopy, ecommerce-demo]
requires:
  - phase: 120-per-touchpoint-audit
    provides: Ranked, fix-class-tagged backlog (anchors P1/P2/P4/P12/P13/P14/P24/P26)
provides:
  - Task-first nav vocabulary (Recover / Explore) in lockstep across nav.ex, breadcrumb trail, layout class, and operator-ia.md
  - Closed in-page threading loop (Search→Playbooks handoff added; recover chain already threaded)
  - Trimmed Control Room front-door (Jump-to rail → ⌘K hint + quiet orientation link; emoji icons → on-brand monoline Heroicons)
  - Microcopy sweep (sentence-case empty/error states with concrete next actions; CTA verbs matching the new groups)
affects: [opsui, scrypath_ops, examples/scrypath_ecommerce]
tech-stack:
  added: []
  patterns: [task-first IA, recover-first nav order, on-brand iconography, sentence-case microcopy]
key-files:
  created:
    - .planning/milestones/v1.33-phases/124-ia-and-front-door/124-PLAN.md
    - .planning/milestones/v1.33-phases/124-ia-and-front-door/124-SUMMARY.md
    - .planning/milestones/v1.33-phases/124-ia-and-front-door/124-VERIFICATION.md
    - examples/scrypath_ecommerce/e2e/p124_after.spec.ts
  modified:
    - scrypath_ops/lib/scrypath_ops_web/nav.ex
    - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
    - scrypath_ops/lib/scrypath_ops_web/components/layouts.ex
    - scrypath_ops/assets/css/app.css
    - scrypath_ops/docs/operator-ia.md
    - scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/search_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex
    - scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs
requirements-completed: [IA-01, COPY-01]
completed: 2026-06-03
owner_gate: pending
---

# Phase 124 Plan 124: IA + Control Room front-door Summary

**The operator nav now speaks the same task-first language the Control Room teaches — Recover and
Explore — with the front door trimmed to one signature glance, the incident/explore chains threaded
in-page, and the remaining microcopy swept to sentence-case concrete next-actions. No route, handler,
or mount-path changed; the ⌘K palette is intact.**

## Accomplishments

### IA-01 — nav rename to task language (lockstep)
- `nav.ex`: group atoms `:triage`→`:recover` (Posture, Failed Sync, Sync Drift) and
  `:probes`→`:explore` (Search, Playbooks). Paths/labels/titles unchanged.
- Breadcrumb trail (`ops_ui.ex` `trail_for/1`): `"Triage"`→`"Recover"` for the three recover screens;
  Explore was already the label for the probes screens.
- Layout group hook + CSS: `ops-nav-group-probes`→`ops-nav-group-explore` (`layouts.ex` + `app.css`).
- `operator-ia.md`: navigation + journey-loops prose reframed from "roadmap triage order" to
  recover-first task groups (Recover chain → Explore). Nav-contract JSON fence unchanged.

### IA-01 — in-page threading
- Recover chain already threaded via `ops_handoff` (Posture→Failed Sync→Sync Drift→Posture).
- Added Search→Playbooks `ops_handoff` ("Once a probe earns its keep — Save it and open playbooks")
  so the explore loop closes at the page bottom with the same grammar as the recover chain.

### IA-01 — front-door trims (`control_room_live.ex`)
- "Jump to" rail (4 ghost link-buttons duplicating sidebar+palette) → a single quiet footer row:
  "Press ⌘K to jump to any surface." + "New here? See what each surface does →" (links the
  operator-ia map). Does not compete with the intent cards.
- Emoji intent-card icons (🚨 / 🚀 / 🔎) → on-brand monoline Heroicons
  (`hero-wrench-screwdriver` / `hero-arrow-up-tray` / `hero-map`), rendered in the violet primary tint.
  `ops_intent_card` `icon` attr now takes a `hero-*` name; `.ops-intent-card__icon` CSS updated from
  emoji font-size to a flex SVG container.

### COPY-01 — microcopy sweep
- CTA verbs now match the groups: "Start triage"→"Start recovery", "Open sync drift"→"Pre-flight sync
  drift", "Open search"→"Explore search"; intent-card summary "Triage an incident"→"Recover from an incident".
- Sentence-case + concrete-next-action empty/error states: failed_sync "No Schemas Configured"/"Runtime
  Not Configured"/"No Failed Sync Jobs" and search "No Schemas Configured"/"Runtime Not Configured" →
  sentence case, each now naming what to do next (add allowlist / configure runtime / re-check posture).
- Vocab drift fixes: posture "Open in OPSUI"→"Open this check"; playbooks "Reload list"→"Reload
  playbooks"; search badge "last run loaded"/"run a probe"→sentence case; multi-search "Run sample
  searches" → "run bounded search again" (matches the actual button); sync/drift H1 "Sync & Drift" →
  "Sync and drift".

## No-behavior-change contract held
Only labels, copy, icons, one added handoff, and the front-door footer changed. No `handle_event`,
mount, route, or dispatch path was touched. The nav-contract fence is byte-identical, so the gate stays green.
