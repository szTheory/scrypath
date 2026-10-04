---
phase: 172-consistent-operator-ui-and-verified-recovery
reviewed: 2026-10-04T04:11:33Z
depth: standard
source_sha: 1b2287ed598ef6e9025e95f2db1b727e70eeb17f
base_sha: 3c83a58c9bc5af70a204957431ff66fd9db035de
files_reviewed: 39
files_reviewed_list:
  - lib/scrypath/meilisearch/tasks.ex
  - lib/scrypath/operator/index_contract_drift.ex
  - lib/scrypath/operator/reconcile.ex
  - scrypath_ops/lib/scrypath_ops/document_observation.ex
  - scrypath_ops/lib/scrypath_ops/operator_selection.ex
  - scrypath_ops/lib/scrypath_ops/promotion_eligibility.ex
  - scrypath_ops/lib/scrypath_ops/recovery_observation.ex
  - scrypath_ops/lib/scrypath_ops_web/components/layouts.ex
  - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
  - scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/search_live.ex
  - scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
  - scrypath_ops/lib/scrypath_ops_web/plugs/asset_plug.ex
  - scrypath_ops/assets/js/app.js
  - scrypath_ops/assets/js/ops_hooks.js
  - scrypath_ops/assets/css/app.css
  - scrypath_ops/assets/css/DESIGN-TOKENS.md
  - examples/scrypath_ecommerce/lib/scrypath_ecommerce/e2e_recovery.ex
  - examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/live/e2e_ui_fixture_live.ex
  - examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/router.ex
  - examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts
  - examples/scrypath_ecommerce/e2e/helpers/operator-ui.ts
  - examples/scrypath_ecommerce/e2e/helpers/theme-grid.ts
  - examples/scrypath_ecommerce/e2e/admin_screenshots.spec.ts
  - examples/scrypath_ecommerce/e2e/admin_screenshot_matrix.spec.ts
  - examples/scrypath_ecommerce/e2e/operator.spec.ts
  - scrypath_ops/test/scrypath_ops/document_observation_test.exs
  - scrypath_ops/test/scrypath_ops/promotion_eligibility_test.exs
  - scrypath_ops/test/scrypath_ops/recovery_observation_test.exs
  - scrypath_ops/test/scrypath_ops_web/asset_plug_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs
  - scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs
  - test/scrypath/meilisearch/tasks_test.exs
  - test/scrypath/operator/index_contract_drift_test.exs
  - test/scrypath/operator/reconcile_test.exs
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
resolved_findings:
  high: 2
  medium: 3
  total: 5
status: clean
---

# Phase 172: Independent Code Review

## Narrative Findings (AI reviewer)

**Disposition:** No unresolved concrete findings in the inspected scope at source commit `1b2287ed598ef6e9025e95f2db1b727e70eeb17f`. The review found two HIGH backend defects and three MEDIUM UI defects during implementation; all five fixes were independently inspected. The frontmatter counts describe open findings, not historical findings.

This is a bounded source review, not a human approval or a phase acceptance attestation. The parent reported a 66-file phase inventory; this review does not claim equivalent depth across that inventory. It consolidates the prior independent backend review and focused UI follow-up.

## Scope and method

- Baseline: `3c83a58c9bc5af70a204957431ff66fd9db035de`; final product source: `1b2287ed598ef6e9025e95f2db1b727e70eeb17f`.
- Read root and Ops AGENTS instructions, CONTRIBUTING, Phase 172 plans 04/05/08, Plan 06 summary, UI-SPEC, and relevant local Meilisearch reference material.
- Reviewed the listed files by source or focused diff, with deeper call-chain tracing for recovery identity, target readiness, promotion outcomes, modal focus, and modal validation. Related task normalization, status/failed-work retrieval, worker, and adapter code was consulted to establish caller guarantees.
- Whole-branch diff inventory informed scope. The example recovery fixture was inspected for its changed identity and gating paths; this is not an exhaustive independent audit of every fixture operation.
- Reviewed Plan 08 threat concerns around false verified/eligible states, forged or stale action context, fixture isolation, focus containment, and misleading outcome copy. No structural-analysis output was supplied.
- No source edits, tests, service operations, commits, cleanup, or browser sessions were performed by this reviewer. Only review artifacts were written.

## Resolved findings

### CR-01 — HIGH / BLOCKER: Canceled target ingestion accepted as completed

**Anchors:** `lib/scrypath/operator/reconcile.ex:174`; `scrypath_ops/lib/scrypath_ops/promotion_eligibility.ex:117`.

**Original defect:** The prior summary treated any nonempty target history without pending or failed tasks as completed. A successful index creation followed by canceled document ingestion therefore passed promotion readiness despite incomplete preparation. The new eligibility guard made this preexisting summary behavior consequential for mutation authorization.

**Resolution:** Reconcile now returns `:unknown` for canceled/unknown work and `:completed` only when every task succeeded. The eligibility whitelist rejects unknown. Pending and failed histories retain their denial paths. The report type includes unknown, and inspected consumers handle it conservatively. Raw unrecognized task statuses fail during normalization.

**Evidence:** Inspected source and added reconcile/promotion regressions. No new regression found in empty-history, success, pending, failed, or canceled paths.

### CR-02 — HIGH / BLOCKER: Target document deletion omitted from promotion preflight

**Anchors:** `lib/scrypath/meilisearch/tasks.ex:19`; `scrypath_ops/lib/scrypath_ops/promotion_eligibility.ex:46`.

**Original defect:** Target readiness queried creation, settings, swap, and ingestion tasks but excluded `documentDeletion`. Live-index status could not cover pending or failed target deletions. A target with prior successful history could thus appear ready while deletion work remained active or failed.

**Resolution:** Target task queries now include `documentDeletion`. The same reconcile summary and eligibility gate reject pending, failed, and canceled target deletions. Regression clients honor actual requested index/type filters, covering the omission through the producer rather than only synthetic eligibility maps.

**Evidence:** Inspected changed query and focused tests. Adding deletion can reach the existing task-history cap sooner; that returns an explicit error and blocks readiness.

### WR-01 — MEDIUM / WARNING: Successful rename lost keyboard focus

**Anchors:** `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:1266`; `scrypath_ops/assets/js/ops_hooks.js:490`.

**Original defect:** Successful rename replaces the filename-keyed row and removes its trigger. With no successor configured, the modal could not restore focus to a connected element.

**Resolution:** Rename declares `successor="#playbook-catalog-heading"`; that stable heading exists with `tabindex=-1` at `playbook_live.ex:938`. Existing hook fallback now restores focus after the original trigger disappears. Filename-based DOM IDs use URL-safe encoding.

**Evidence:** Inspected component/hook path and the browser regression at `examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts:488`, which asserts the old row disappears, the renamed row exists, and the catalog heading receives focus.

### WR-02 — MEDIUM / WARNING: Observation failures falsely described as swap failure

**Anchors:** `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:278`; `sync_drift_live.ex:929`.

**Original defect:** Transport/invalid-payload errors and observer exits were mapped to failed swap outcomes. These results establish that observation failed, not that the accepted remote task failed.

**Resolution:** Only terminal `OperationTask` failures with the exact expected ID and failed/cancelled state become `{:failed, ...}`. Timeout remains timed out. Unexpected successful payloads, other errors, and observer exits become unknown while retaining the accepted task identity. Unknown/timeout copy states that the outcome is unconfirmed and directs a refresh.

**Evidence:** Inspected `Tasks.wait_for_task` return shapes, final callback mapping, UI copy, and focused regression at `scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs:375`. Wrong identities and unconfirmed observations cannot be reported as completed or failed.

### WR-03 — MEDIUM / WARNING: Modal validation feedback was outside the accessible dialog

**Anchors:** `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:494`, `:535`, `:1349`; `scrypath_ops/assets/js/ops_hooks.js:499`.

**Original defect:** Rename, duplicate, and delete validation only wrote global flash messages. The active dialog makes surrounding content inert, so an invalid filename or confirmation left the user inside the modal without accessible error feedback.

**Resolution:** Local `:file_action_error` is reset on each dialog open and used for validation/file-operation failures. Each dialog passes it to both `ops_field` and `ops_text_input`. The shared components render an in-dialog alert and associate the error through `aria-describedby` and `aria-invalid` (`ops_ui.ex:793`, `:818`). Rename/duplicate preserve the submitted text for correction.

**Evidence:** Inspected all three submission paths and dialog templates. The browser regression submits `invalid/name.json`, asserts the alert has no inert ancestor and focus remains inside, corrects the name, and confirms successful focus restoration. LiveView regressions cover local error rendering.

## Other inspected concerns

- No additional concrete false-verified recovery path found. The production caller validates the current endpoint/Oban instance/repo/prefix/node, exact job ID/attempt/schema/index/worker, backend task UID/index/type, and the expected document fields or deletion absence before verified success. The collector alone does not declare verified success.
- No additional concrete wildcard/facet normalization defect found. Implicit searchable wildcard is accepted; explicit restrictions and searchable ranking order remain compared. Facet membership derives from filterables, with feature differences retained as settings drift.
- Modal source includes focus containment, Escape cancellation, inert restoration, successor fallback, and closure of competing shell overlays. No further concrete regression found in the inspected paths.
- The example UI-fixture route is compiled only in dev/test and its LiveView does not call backend mutation services. Existing example-only probe capabilities were not treated as production routes.
- Asset path containment uses a relative-path boundary; content hashes govern immutable caching. No concrete path traversal or caching regression found in the changed path.
- Operator schema resolution uses an allowlist without input-to-atom conversion. Posture action links navigate to the guarded Sync/Drift workflow.
- No dependency lockfile changes were found in the compared root, Ops, or example lockfiles. This does not substitute for the parent supply-chain workflow.

## Remaining limits

1. **Target evidence is bounded:** successful target index creation alone can qualify as observed/completed. The gate does not prove target population completeness, target settings parity, or present target existence. The inspected contract read covers the live index. Do not describe eligibility as proof that target contents are complete.
2. **Partial contract maps:** `promotion_eligibility.ex:159` accepts a nonempty dimensions map when all provided entries match. The canonical producer emits all five dimensions, so no current production false-eligible path was demonstrated. A stricter required-key check would be defense in depth.
3. **Collector versus caller:** `DocumentObservation` alone accepts less identity evidence than its current production caller; the caller checks identity first. This review's no-false-verified conclusion depends on that caller contract.
4. **Execution evidence:** no fresh tests, assistive-technology sessions, browser rendering, screenshots, live backend reproduction, or hosted exact-SHA checks were run by this reviewer. Source-level resolution is independently assessed; executable outcomes below have separate provenance.
5. **Final acceptance:** Plan 08 exact-source evidence, hosted checks, UI acceptance, cleanup ownership, and closeout remain the parent's work. This report does not confer a human reviewer identity or attest those gates. Subsequent changes to tests or product source are outside this recorded snapshot.

## Evidence provenance

- Prior executor logs were read: target RED 19 tests / 2 failures; GREEN 19 / 0; Ops eligibility 17 / 0. The Ops log contained the previously noted Sync typing warning.
- Parent-reported later evidence, not rerun by this reviewer: dialog RED 21 / 2 to GREEN 21 / 0; corrected invalid-path-to-valid-rename browser regression 1 / 1; promotion RED 17 / 1 to GREEN 17 / 0; root `verify.ops_ui` 233 + 2 / 0.
- Parent reported the full advisory run on `1b2287e` finished with 95 passes and 9 failures, with no retries, then began correcting old test expectations in screenshot/surface-depth tests. Those failures are not silently treated as passing evidence here; their final disposition belongs in the parent's acceptance record.
- Historical detailed backend reproduction and follow-up are preserved in `/private/tmp/phase172-independent-core-review.md`; this tracked report contains the substantive findings and limits so that it stands alone.

_Reviewed by the independent Codex review agent, 2026-10-04T04:11:33Z. Standard-depth bounded source review; no human approval claimed._
