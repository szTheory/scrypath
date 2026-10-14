# Continue — Scrypath UI baseline

## Current state

All three baseline batches are implemented and verified on `fix/ui-task-baseline` in `/Users/jon/projects/scrypath/.claude/worktrees/ui-experience-reconciliation`. Delivery is [PR #105](https://github.com/szTheory/scrypath/pull/105); read its current merge/check state before doing anything. The maintainer authorized marking ready and squash merging after required CI is green. Finish that delivery if still open; if merged, there is no remaining baseline implementation or phase replay to do.

Evidence: [UI-BASELINE-RESULTS.md](UI-BASELINE-RESULTS.md), the reconciled `../UI-FEEDBACK.md`, and final local reviewed capture `examples/scrypath_ecommerce/ui-review-artifacts/2026-10-14T22-45-57-728Z`. Full 168-case browser inventory: 167 passed initially; one test-only paint-timing assertion corrected and its full status suite rechecked 6/6; Ops: 309 tests + 2 doctests; demo: 12 tests; review tooling: 7 tests. The review checker validates current source/artifact binding and completeness, not taste or an independent reviewer identity. Required hosted checks must cover the final delivered commit. Unchanged dependency-audit advisories remain separate and disclosed.

## Preview and next work

`../UI-PREVIEW.json` is the canonical pointer. The retained preview is `http://127.0.0.1:4002/admin/search`, container `scrypath_ecommerce-web-1`; startup seeding is disabled. It retains incident data, so some warnings/search unavailability are expected. Preserve its database, indexes and volumes. The root checkout is a different dirty historical branch; do not reset/stash/copy it or transport old product files.

The three tasks are trying search, understanding/recovering a problem, and saving/reusing inputs. The implementation includes unreported clipboard, stationary-pointer selection, long-name and compact-layout defects, not just the maintainer's examples. New feedback should extend the same ledger and maintained `OPERATOR-UI-QUALITY.md`; no new persona workshop, brand refresh or numbered phase is needed. Do not replay Phases 173–177 or route from historical STATE frontmatter. No speculative new work is authorized by a completed baseline.

All stateful checks used only the owned `scrypath_ui_baseline` Compose project (ports 4013/4014 and separate saved-file volume); remove only that disposable stack if it still exists. Never tear down the retained `scrypath_ecommerce` preview or unrelated containers. Repeated full tests require a fresh owned search backend: the 1000-task history bound correctly blocks promotion after accumulated test runs; never raise the limit or weaken a guard to force green.
