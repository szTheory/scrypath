---
created: 2026-07-01T23:04:16Z
completed: 2026-07-10T23:59:22Z
title: Normalize Playbooks row action styling
area: ui
files:
  - scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex
  - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
  - scrypath_ops/assets/css/app.css
---

## Problem

Duplicate and Rename actions on Playbooks rows do not read like intentional controls. They look visually odd compared with the rest of the design system, making the row action hierarchy harder to scan.

## Solution

Clean up Playbooks row actions so Load/Run are primary operational actions, Duplicate/Rename read as secondary maintenance actions, and Delete remains clearly separated as destructive. Prefer existing `ops_button`/`ops_action_group` patterns unless a small reusable row-action variant is needed.

## Completion Evidence

- Playbooks row actions now group operational actions separately from secondary Duplicate/Rename maintenance controls.
- Delete remains isolated in an error-toned destructive action group.
- `134-UAT.md` records focused Playbooks LiveView and browser depth evidence as passed, including active-row glow, preview card depth, secondary action grouping, and destructive action separation.
