# Continue — Scrypath UI follow-up

The maintainer's second review round is implemented and locally verified on `fix/ui-feedback-baseline` in `/Users/jon/projects/scrypath/.claude/worktrees/ui-experience-reconciliation`. All 24 follow-up entries are preserved and reconciled in `../UI-FEEDBACK.md`; `UI-FOLLOWUP-RESULTS.md` records behavior, tests, rendered evidence and limits. Earlier feedback-only pauses are superseded. Do not restart planning or replay Phases 173–177.

## Current next action

**Delivery complete:** [PR #106](https://github.com/szTheory/scrypath/pull/106) squash merged to `29c287c8e732cddd13e435ccf601e06a39a65837` after all five required exact-head checks and Ops passed. The preview checkout includes current main with no product differences. Local closeout bookkeeping is an unpublished maintainer checkpoint only; it contains no missing UI work. Do not push/replay it as another UI implementation cycle.

No GSD phase or implementation command is needed for this completed pass. The next useful action is reviewing the updated app, especially Search → Save/reuse and Help, then recording genuinely new feedback. The separate unsuppressed dependency advisory task is `../todos/pending/2026-10-15-dependency-audit-followup.md`; it is open, not accepted or resolved by this UI delivery.

## New feedback collection — 2026-10-15

The maintainer is reviewing the delivered UI and asks to batch the next changes coherently. Fifteen open entries in `../UI-FEEDBACK.md` preserve result-limit policy/help, on-blur and app-wide validation, consistent single/multi options, contextual help that preserves the task in a new tab, intentional empty/populated result hierarchy, compact combined results as the recommended primary multi-schema view, raw data/copy scope and placement, Run wording, Save/Run proximity and the multi-query request model. IDs: CONTENT-27/28, UI-38 through UI-47, UX-08/09 and DOC-07. The 11:43–11:48 screenshots add ragged duplicated combined order, overly tall per-hit field grids, Copy outside the code surface, and a group-level raw-response disclosure that misleadingly appears attached to the last hit. No product edits or broad input audit have occurred in this round. Continue capturing feedback and synthesize one batch; do not dispatch isolated cuts or reopen the delivered pass. Keep native/server guards and avoid a generic validation framework or tooltip system without need.

Three findings must survive compaction: (1) admin max 50 is not a universal library/backend limit: core federation defaults to 200, while the separate multi-query page-size guard is 50; reconsider policy and traversal before merely explaining the ceiling; (2) a schema contributing zero hits to a bounded merged response may still have matches, so do not infer “no matches” per schema; (3) federated per-schema raw maps are reconstructed projections, not exact original HTTP responses. Also, Save currently captures submitted inputs; moving it beside Run must not silently save an older query than the nearby edited fields. Current Meilisearch sends one HTTP multi-search request containing one logical query per schema. Any new pagination behavior needs compatibility verification against pinned Meilisearch 1.15. Source references and proposed acceptance are in the ledger; no new number or behavior has been selected.

## Canonical preview and preservation

`../UI-PREVIEW.json` points to the canonical checkout above. Retained preview: `http://127.0.0.1:4002/admin/search`, `scrypath_ecommerce-web-1`, startup seeding disabled. Preserve its incident/index-settings data, databases, search indexes and volumes. Root checkout is a different dirty historical branch: do not reset/stash/copy its product files.

Never stage/delete/reset `examples/scrypath_ecommerce/priv/playbooks/my-search.json`; it is the maintainer's server-saved file and remains untracked, SHA256 `3c8de6b45b9b3bc6f5daff18ce71da1ee817b5270ddc57a8c064f59a1a42c0f7`.

## Evidence and boundaries

Ops: 313 tests + 2 doctests; demo: 38 tests on a separate database partition; review tooling: 7 tests. All 175 browser cases covered through full and repaired focused runs, with transparent run history in the results report. Final reviewed matrix: `examples/scrypath_ecommerce/ui-review-artifacts/2026-10-15T13-22-55-099Z`, 72 views and zero mechanical findings. Populated/raw/draft/save/toast shots are in `ui-review-artifacts/followup-journeys/`. Complete review source binding must stay valid.

The new `indexing_failure` seed was actually exercised only on disposable data: Meilisearch task 691 failed with `invalid_document_id`, and health displayed it. Fixed health snapshots and typed-hit fixtures are labeled examples, not live recovery evidence. Shared configured mode is not per-call override discovery. No pagination, new dependency, public library API, format change or brand refresh.

Verification used only Compose project `scrypath_ui_followup`, ports 4013/4014, and `/private/tmp/scrypath-followup-saved`. Its containers, network and seven named volumes are now removed; local screenshots/logs remain available. Never tear down the retained preview or unrelated stacks. Fresh owned backends keep task-history bounds deterministic; do not weaken a 1000-task guard to force green.
