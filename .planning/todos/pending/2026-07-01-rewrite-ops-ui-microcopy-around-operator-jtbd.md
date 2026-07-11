---
created: 2026-07-01T23:04:16Z
title: Rewrite Ops UI microcopy around operator JTBD
area: ui
files:
  - scrypath_ops/lib/scrypath_ops_web/live/search_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex
---

## Problem

Operator-facing copy is drifting into backend/library jargon instead of meeting the user in their job language. Specific examples called out during QA: "Run one allowlisted schema through the bounded Scrypath search path" and "Run bounded read-only probes, inspect federation behavior..." are too verbose and make the user translate implementation terms before acting.

## Solution

Audit the primary scan-path copy across Control Room, Search, Sync/Drift, and Playbooks. Prefer calm, task-oriented operator language. Keep precise terms like schema, federation, and bounded only where they clarify a concrete operational constraint, not as default marketing/helper copy.
