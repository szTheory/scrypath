---
slug: search-module-archive-code-drift
title: Reconcile v1.20 search-module archive with current code
status: open
priority: high
created: 2026-05-08
updated: 2026-05-27
---

# Todo: Reconcile v1.20 search-module archive with current code

## Why

The v1.20 archive claims a thin `Scrypath.SearchModule` layer shipped, but the checked-out code does not currently expose that module or its guide. That leaves planning truth ahead of code truth.

The post-v1.26 done-ness assessment keeps this as the main planning-truth cleanup before calling Scrypath effectively done. It is not currently a product gap for adopters because public docs route through `Scrypath.QueryParams`, `Scrypath.Phoenix`, `Scrypath.Composition`, and context-owned `Scrypath.search/3`.

## What to do

- Confirm whether the missing search-module work exists in salvage history or was lost during the main reconciliation.
- If it exists and still fits the current boundary, recover it cleanly and re-verify the public docs/contracts.
- If it does not exist, or if the current QueryParams/Composition surface supersedes it, correct the archive and milestone language so future planning does not assume the layer is already present.

## Progress

- 2026-05-27: Rolling planning docs (`PROJECT.md`, `MILESTONES.md`, `MILESTONE-ARC.md`) now consistently mark `v1.20` SearchModule statements as archive history rather than branch-tip shipped surface. Remaining work is the final code-or-archive reconciliation decision.

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
