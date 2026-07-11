---
created: 2026-07-01T23:04:16Z
completed: 2026-07-10T23:59:22Z
title: Restructure Search playground workflow
area: ui
files:
  - scrypath_ops/lib/scrypath_ops_web/live/search_live.ex
  - examples/scrypath_ecommerce/e2e/helpers/theme-grid.ts
  - examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts
---

## Problem

Search QA surfaced several workflow friction points: the header has a redundant Playbooks link even though primary nav already covers it; the form/results split feels surprising; schema selection is separated from the single/multi mode decision; and the save-playbook form is visible before it is useful.

## Solution

Make Search flow in the order operators expect: choose search target, enter query, run search, inspect results, then save a useful run. Group mode and schema/index controls together, remove redundant cross-linking, and make save-to-playbook progressive after a successful run through a compact action that reveals the full form.

## Completion Evidence

- Search now uses a top-to-bottom workflow with grouped target controls, query/limit controls, results, and progressive save-to-playbook controls after a successful run.
- The high-attention initial state uses `ops_empty_hero/1`; compact empty/error states remain on `ops_empty_state/1`.
- `134-UAT.md` records Search/Playbooks follow-up browser and LiveView evidence as passed, and the phase summary now has zero pending UAT items.
