---
slug: search-module-archive-code-drift
title: Reconcile v1.20 search-module archive with current code
status: open
priority: high
created: 2026-05-08
updated: 2026-05-08
---

# Todo: Reconcile v1.20 search-module archive with current code

## Why

The v1.20 archive claims a thin `Scrypath.SearchModule` layer shipped, but the checked-out code does not currently expose that module or its guide. That leaves planning truth ahead of code truth.

## What to do

- Confirm whether the missing search-module work exists in salvage history or was lost during the main reconciliation.
- If it exists, recover it cleanly and re-verify the public docs/contracts.
- If it does not exist, correct the archive and milestone language so future planning does not assume the layer is already present.

## References

- `.planning/milestones/v1.20-ROADMAP.md`
- `.planning/milestones/v1.20-REQUIREMENTS.md`
- `.planning/MILESTONE-ARC.md`
- `.planning/milestone-candidates.md`
- `lib/scrypath.ex`
- `guides/overview.md`
- `README.md`

## Done when

- Archive, roadmap, and code all agree on whether `Scrypath.SearchModule` exists.
- Future milestone planning can treat the search-module layer as either grounded or explicitly deferred.
