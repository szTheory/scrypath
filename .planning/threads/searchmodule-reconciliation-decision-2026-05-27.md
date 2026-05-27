---
slug: searchmodule-reconciliation-decision-2026-05-27
title: SearchModule reconciliation decision
status: resolved
created: 2026-05-27
updated: 2026-05-27
---

# SearchModule reconciliation decision (2026-05-27)

## Question

Should Scrypath recover the historical `Scrypath.SearchModule` layer from salvage/history, or archive-correct planning language to match current branch-tip code truth?

## Evidence checked

- No `salvage/` directory exists in the current checkout.
- No salvage branches matched `*salvage*` in local/remote refs.
- Branch-tip tree has no `search_module` implementation files.
- Git history searches in this repo found `Scrypath.SearchModule` references in planning files, but no module-definition/source artifacts.

## Decision

**Archive-correction path selected.**

`Scrypath.SearchModule` is not treated as current shipped surface. Historical `v1.20` claims remain as milestone archive narrative only.

## Rationale

- Recoverability evidence is insufficient (no code artifacts to restore in this repo snapshot).
- Current public product story is coherent on `Scrypath.QueryParams`, optional `Scrypath.Phoenix`, `Scrypath.Composition`, and context-owned `Scrypath.search/3`.
- Keeping planning truth aligned to branch-tip code reduces future milestone-selection drift.

## Follow-through completed

- Drift todo marked resolved: `.planning/todos/search-module-archive-code-drift.md`
- Rolling planning files updated to reflect archive-corrected status:
  - `.planning/PROJECT.md`
  - `.planning/STATE.md`
  - `.planning/MILESTONES.md`
  - `.planning/MILESTONE-ARC.md`
- `v1.20` archive trio updated with explicit historical-classification wording:
  - `.planning/milestones/v1.20-ROADMAP.md`
  - `.planning/milestones/v1.20-REQUIREMENTS.md`
  - `.planning/milestones/v1.20-MILESTONE-AUDIT.md`
