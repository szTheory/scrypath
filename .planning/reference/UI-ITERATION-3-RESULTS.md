# Scrypath UI iteration 3

All three implementation batches and their verification are complete. This report supersedes the iteration-3 handoff's unimplemented status, not the historical PR #106 receipts. The mounted checkout remains `/Users/jon/projects/scrypath/.claude/worktrees/ui-experience-reconciliation`, on `fix/ui-iteration-3`.

## Delivered behavior and feedback disposition

| Batch | Feedback | Result |
| --- | --- | --- |
| Search | CONTENT-27, DOC-07 | Results per page is a request budget, default 50, adjustable by the host. Previous/Next use supported single-search page numbers or combined federation offsets. The core per-query multi-search cap stays 50. Help explains one HTTP request with one logical query per selected schema, bounded traversal and changing index contents. |
| Forms | UI-38, UX-08 | Shared native constraints now show associated inline errors on blur/submit, retain inputs, correct touched errors, focus invalid controls and retain server errors until edits. The inventory covers result size, search target guards, optional metadata's existing byte limits, filenames, pasted JSON, file uploads and protected confirmations. Upload/domain/filesystem checks and operational eligibility remain server-owned. Optional fields remain optional. |
| Targets | UI-39 | Radio and checkbox modes share short/full schema names, selected treatment, row anatomy and native semantics. The maximum-schema hint appears only when it can constrain the configured choices. |
| Outcomes | UI-41, UX-09, UI-44 | One purposeful successful-empty state; one count heading for results shown; separate partial/failed/loading states. No source-zero-match conclusion is drawn from absence in a bounded merged page. |
| Results | UI-45, UI-46 | One primary backend-ordered multi-schema list replaces the duplicated trace and tall source lists. Quiet rank, source and configured ID accompany adjacent title/summary heuristics. Small scalar previews follow declared field order, with complete typed fields and full raw data available. No association fetches or client sorting. |
| Inspection | UI-42, UI-47 | Optional response data belongs to the run, with explicit reconstructed-projection scope for federation. Complete returned data is copyable using actual-outcome toasts. Copy sits inside the code surface with reserved text clearance and selectable source. |
| Saving | CONTENT-28, UI-43 | Save sits beside Run and is disabled when controls differ from the submitted result. Guidance says Run search to update these results. Saved JSON still contains submitted inputs, including the viewed page, in a server file; no-overwrite rules remain. |
| Health | CONTENT-29, UI-48 | Same source-section anatomy, consistent pending/retry/failure icons, neutral ordinary activity, local error emphasis and naturally aligned last-success rows. Brief task/job descriptions distinguish Meilisearch document application from delivery by application jobs. Uses Background sync with Oban. |
| Recovery | CONTENT-31, UI-51 | Failed sync uses the same neutral verdict grammar as home/health. Its introduction names schema scope. Terminal failures and scheduled retries remain separate; zero-state noise does not return. |
| Settings | UI-52, UI-53, CONTENT-32 | Header Refresh owns routine sync/settings checking. Compact identity and activity replace stretched facts and raw atom wording. The comparison lists differences, explains filter capabilities, says Not enabled for filtering instead of Missing, and names a read-only-safe application setup/reindex follow-up. Comparison columns stay readable with contained horizontal scrolling on small screens. |
| Help | UI-40, UI-49, UI-50, CONTENT-30 | Shared restrained contextual links open a new tab with a visible/accessibility cue. Ranking/limits/recovery have meaningful fragment headings and hydration-safe native scrolling. Help has a purpose-specific introduction and matching task icons; destination labels/arrows form coherent actions. Failed-sync recovery help stays in-app and appears when work needs review. |

All 25 ledger IDs are covered. The maintained role/job model, original feedback and twelve original screenshots remain intact. Implementation does not claim maintainer acceptance or independent adopter research.

## Whole-inventory critique

A distinct in-thread critic pass inspected all eight surfaces against JOB-01/02/03/04/05 and the existing design authority; no independent reviewer identity is claimed. The starting 72-view capture is `ui-review-artifacts/2026-10-15T17-12-26-479Z`. It established the incumbent visual truth before implementation. Intermediate captures with changed-source flags are superseded evidence, not accepted baselines.

Preserve: the branded neutral shell, flat task navigation, concise home problem/action hierarchy, source-qualified operational evidence, protected recovery/promotion, app-owned storage and authorization, and the storefront's honest unavailable state when intentional filter drift blocks its query. No preview reseed or brand refresh was used to make screenshots green.

Unreported defects addressed alongside maintainer examples: permissive numeric parsing could substitute a different query limit; disabled Save needed to reflect actual browser drafts; live patches could erase touched errors; server collision messages needed to survive focus changes; an empty error wrapper duplicated the field error; comparison prose collapsed into a narrow column; blur errors could move a button between pointerdown and click. The final pointer fix defers that blur presentation during a button press, validates on submit and respects later user intent.

State proofs distinguish empty from unavailable/partial, accepted retry from completion, settings agreement from document visibility, configured mode from per-call behavior, and displayed results from all matches. They retain exact raw payloads, arbitrary/custom IDs, duplicate titles, false/zero/null/nested data, stationary copy notifications, native keyboard controls and modal focus.

## Verification

- Canonical `mix verify.ops_ui`: **317 tests + 2 doctests, zero failures** after the final shared CSS fix. `/tmp/scrypath-ui3-ops-clearance.log`.
- Ops `mix precommit`: **317 tests + 2 doctests, zero failures**, including format/compile checks. `/tmp/scrypath-ui3-precommit-317.log`. The subsequent shared CSS fix also passed the canonical contract suite above.
- Demo `mix test`, isolated `_ui3` database partition: **38 tests, zero failures**. `/tmp/scrypath-ui3-final-demo.log`.
- Full affected browser suite: **98/98 passed** in one run, no retries. `/tmp/scrypath-ui3-final-98.log`. After the last shared CSS repair, the affected Search/copy/Help journeys and contrast matrix were repeated: **16/16 passed**, including a computed clearance check for Copy above the first source line. `/tmp/scrypath-ui3-final-shared.log`.
- Contrast matrix: incident, all-green and empty, light/dark/system-dark, desktop/mobile; **zero AA contrast failures**. Optional AAA body advisories remain 40/30/12, respectively. Full reports: `ui-review-artifacts/iteration3-contrast-final/`. No thresholds or palettes were loosened.
- Review tooling: **7/7 passed**. `/tmp/scrypath-ui3-tooling-tests.log`.
- Single-schema page traversal, exact code copying, mobile in-surface Copy and in-page Help additionally have a direct browser receipt in `ui-review-artifacts/iteration3-journeys/extra-journeys.json`.

The earlier failed/interrupted runs exposed obsolete assertions, the test-folder mismatch and the pointerdown/blur button-shift regression. They remain separate logs; their failures are not counted as successful final proofs. The final runs above use the owned shared test folder and repaired controls.

Final rendered review: `ui-review-artifacts/2026-10-15T17-53-27-914Z`, **72/72 views, zero mechanical findings**, with all nine theme/width views per surface inspected in contact sheets and representative full-page/interaction images. `review.json` records a distinct in-thread critique and truthful state/journey coverage. Its completeness/source checker passes; it does not certify taste or maintainer approval. Product-source SHA256: `4231936e61f1d5a555aa5ddd314a93f605b25fa7247b1ebca5a3156175662299`. Chromium `148.0.7778.96`, macOS; no claim of physical-device or other-engine certification.

## Preview and boundaries

Retained preview: `http://127.0.0.1:4002/admin/search`, container `scrypath_ecommerce-web-1`, canonical source mount, startup seed disabled. Database/index/incident/settings records were preserved. Maintainer `priv/playbooks/my-search.json` stays untracked and has SHA256 `3c8de6b45b9b3bc6f5daff18ce71da1ee817b5270ddc57a8c064f59a1a42c0f7`.

Mutation tests use project `scrypath_ui3` at 4013/4014, a separate Postgres/Meilisearch pair and `/tmp/scrypath-ui3-playbooks`. The initial broad harness was stopped when its default fixture-folder mismatch was found; fixture storage was corrected before final runs. No retained file was overwritten or deleted. Owned backend history was recreated between broad runs rather than relaxing the 1000-task observation guard.

Pagination does not promise a stable snapshot across changing data. Titles/descriptions remain heuristics, with original full fields/raw values available. Federated source data remains reconstructed, not an exact original HTTP packet. Host infrastructure, authorization and end-user search controls remain app-owned. The separate dependency advisory remains outside this UI pass.
