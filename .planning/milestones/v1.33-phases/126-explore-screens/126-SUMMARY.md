---
phase: 126-explore-screens
plan: 126
subsystem: ui
tags: [phoenix, liveview, scrypath_ops, opsui, explore, search, playbooks, loading, ecommerce-demo]
requires:
  - phase: 120-per-touchpoint-audit
    provides: Ranked backlog (S2, P28, P29 mapped to 126)
  - phase: 122-design-system-components
    provides: ops_loading primitive, ops_action_group tone={:danger}, ops_empty_state
provides:
  - Search shows an ops_loading skeleton during a bounded run (deferred via :run_search, event model unchanged)
  - Single-index result rows lead with the hit's human field instead of "Hit 1 / Hit 2"
  - Zero-results is an ops_empty_state naming the concrete next action
  - Playbooks destructive Delete separated into its own ops_action_group tone={:danger}
affects: [scrypath_ops, examples/scrypath_ecommerce]
tech-stack:
  added: []
  patterns: [deferred-read loading state, human-field-first result titles, destructive-action separation]
key-files:
  created:
    - .planning/milestones/v1.33-phases/126-explore-screens/126-PLAN.md
    - .planning/milestones/v1.33-phases/126-explore-screens/126-SUMMARY.md
    - .planning/milestones/v1.33-phases/126-explore-screens/126-VERIFICATION.md
  modified:
    - scrypath_ops/lib/scrypath_ops_web/live/search_live.ex
    - scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex
    - scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs
requirements-completed: [EXPLORE-01]
completed: 2026-06-03
commit: 4f0d6f4
---

# Phase 126 Plan 126: Explore screens polish Summary

**Search now has the loading state it was missing, leads results with the human field instead of a generic
ordinal, and names a concrete next action when nothing matches; Playbooks separates its destructive Delete
from the neutral row actions. The single/multi modes, capture flow, and workspace-vs-examples clarity carry
over from prior phases. No dispatch path, route, or mount changed.**

## Accomplishments

### S2 — Search loading state (EXPLORE-01)
- `handle_event("search", …)` now sets `:searching`, clears prior results, and `send(self(), {:run_search,
  params})`; the bounded read runs in `handle_info({:run_search, …})`. The results panel renders an
  `ops_loading` skeleton while `@searching`; the Run button gains `phx-disable-with="Running…"`; the
  result-status badge gains a `:running` "Running…" state via `search_status_badge_{kind,label}/1`.
- `base_socket` clears `:searching` on every terminal branch (ok / partial / error / config).

### P29 — meaningful result titles
- `hit_title/2` leads with the hit's human field (name → title → sku → id), falling back to "Hit N" only
  when no human field is present. The subtitle still carries the id + name detail. Confirmed on the
  all_green results shot ("Quantum CyberPhone X" etc., no more "Hit 1/2").

### Zero-results next action
- The empty single-index result is now an `ops_empty_state` ("No hits for this query") whose body names the
  next action: widen/simplify the query, raise the page size, or pick another schema, then run again — with
  the multi-index-search guide link retained.

### P28 — Playbooks destructive-action separation
- Delete moved into its own `ops_action_group tone={:danger}` (red-bordered), separated from the advanced
  Duplicate/Rename group, so the destructive action no longer sits among neutrals.

## Parity / clarity verified (no change needed)
- Single vs multi (federation) mode: both render through the same form + status idioms; the federation
  honesty panel, per-schema panels, and merge trace are intact.
- Read-only(`:examples`)-vs-workspace clarity: the `ops_workspace_mode_indicator` + examples banner +
  empty-workspace `ops_empty_state` already serve this; left as-is.

## No-contract-break
The only behavior change is deferring the search read to surface the loading state (the loading finding
requires it). External event names, the search dispatch, capture/save flow, routes, and mounts are untouched.

## Deferred
- P26/P27 microcopy ("last run loaded" / non-production notice parity) were largely handled in 124's COPY-01
  sweep; the badge copy is now state-aware ("Run a probe" / "Running…" / "Last run loaded"). Nothing outstanding.
