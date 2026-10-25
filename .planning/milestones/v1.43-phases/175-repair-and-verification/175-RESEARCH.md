# Phase 175: Repair and Verification - Research

**Researched:** 2026-10-10  
**Domain:** ScrypathOps Phoenix LiveView operator workflow; asynchronous Meilisearch task evidence  
**Confidence:** HIGH for in-repo seams; MEDIUM for external behavior and implementation recommendation

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Evidence and operator decision order

- **D-01:** Keep three evidence questions legible as separate results: (1) what the queue/backend reports, (2) whether the live index matches the declared contract, and (3) whether the expected document is observed in the active index. A clean contract check is not proof that projected documents are present; a queue success is not proof of active-index visibility. Give each result its own observed/unavailable state and relevant next step rather than compressing them into one green/failed verdict.
- **D-02:** Keep the common path ordered around refresh/observation, contract diagnosis, and eligible ordinary recovery. Keep promotion as a visually separate advanced action. This lets operators investigate or verify independently while reducing the chance that an index swap is mistaken for routine repair. Preserve the existing rule that prior failed work blocks promotion until resolved, while still allowing the operator to observe whether newly accepted recovery reached the backend and active index.
- **Tradeoff considered:** A single summary is quicker to scan but hides which evidence is missing or stale; multiple independent cards can become noisy. Keep the evidence distinctions and use the existing section/record primitives with concise labels, not a new nested dashboard.

### Operation identity and outcomes

- **D-03:** Retain the exact operation identity beside its outcome: schema, target/live index as relevant, queue job and attempt for Oban work, and Meilisearch task UID for backend work. Do not substitute the newest historical task or a matching status from another index/schema for the operation just initiated.
- **D-04:** Treat request acceptance as **accepted/enqueued**, not success; preserve a distinct in-progress state; show terminal success only when the matching operation's terminal evidence and the applicable index/document observation support it. Show remote task failure or cancellation as a terminal non-success with its identity. Keep observation timeout, transport failure, malformed/missing task data, and unavailable evidence as **unknown / could not be checked**, never as proof that the remote operation failed.
- **D-05:** Refresh/status-check controls remain observational. After an accepted, timed-out, or unknown operation, checking again must not resubmit the mutation. Retain the exact task/job reference and explain the next safe check. Preserve older failure history instead of clearing it to make the page look healthy.
- **Tradeoff considered:** More explicit lifecycle states use more copy and screen space, but collapsing them makes asynchronous Meilisearch behavior unsafe to interpret. Prefer concise action-adjacent status with exact IDs available/readable; do not hide the distinctions.

### Eligibility, confirmation, and selection

- **D-06:** Offer only actions currently supported and eligible for the selected allowlisted schema. Disabled/unavailable actions retain a concrete reason. UI state is explanatory only: resolve the URL schema against the live allowlist and re-check authorization, eligibility, schema/index identity, and fresh evidence on the server immediately before any mutation.
- **D-07:** Keep ordinary repair on the common task path and index promotion behind the existing advanced disclosure and explicit confirmation. Confirmation continues to name the schema, live index, target index, and alias change. Do not create a second authorization policy or make a frontend confirmation the security boundary.
- **D-08:** Preserve Phase 174's URL-backed schema continuity. When schema/index identity changes, invalidate evidence, pending operation context, or confirmations bound to the former target. An invalid/unavailable explicit target is a visible stop, never an implicit fallback to another schema.
- **Tradeoff considered:** Disabling an ineligible action reduces accidental attempts but can obscure how eligibility works; keep the existing reason visible. Avoid replacing the guard with a generic disabled state or a client-only check.

### Interaction quality and proof

- **D-09:** Use the existing neutral surfaces, OpsUi components/tokens, native controls, LiveView async/navigation patterns, visible focus, and status vocabulary. Pair color with text/icon/state; expose non-focus-moving progress and results programmatically without stealing focus or repeating noisy announcements. Keep long task/index/document IDs readable at narrow widths.
- **D-10:** Verify the decision paths through the rendered controls and mounted flows: eligible and blocked actions, confirmation, accepted/running/succeeded/failed/canceled/unknown outcomes, observation failure, exact task/job mismatch, wrong index/schema/document, refresh without resubmission, and evidence invalidation after target change. Inspect representative degraded states in light/dark and desktop/narrow layouts; use existing executable accessibility, focus/layout, LiveView, and disposable-stack checks. Direct screenshots supplement executable proof and do not replace it.
- **D-11:** No new dependency or component framework. Prefer existing primitives or a small local helper; a modest amount of repeated code is preferable to a dependency or abstraction without a demonstrated repeated need. Keep all changes within approved requirements and current existing lanes.
- **Tradeoff considered:** This verification set emphasizes dangerous boundary conditions rather than exhaustive cosmetic combinations; reuse passing evidence within its recorded source/scenario limits and add cases only when a named acceptance path requires them.

### the agent's Discretion

The UI contract may choose exact headings, labels, concise error/recovery copy, icon treatment, responsive spacing, and which existing OpsUi primitives fit each evidence group. The researcher/planner may choose how to organize the implementation and test tasks. Keep D-01–D-11 and the roadmap success criteria fixed; any new operation/capability or relaxation of an authorization/evidence gate is out of scope.

### Deferred Ideas (OUT OF SCOPE)

None. Any new repair capability, backend/auth product, operator surface, or change to host authorization remains out of scope and requires separate evidence and scope approval. Search and Playbooks remain Phase 176; final shared-pattern and delivery work remains Phase 177.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OPUX-20 | Operators using Sync and drift can distinguish index-contract drift from document freshness and observation from repair or advanced promotion, with a clear next step for ordinary recovery and a separate advanced promotion path. | Keep reconcile, contract, and active-document reads separate; use the schema-preserving failed-work handoff for ordinary recovery and retain promotion in its native advanced disclosure. |
| OPUX-21 | Operators can distinguish accepted, running, terminal success/failure, and unavailable/unknown observations for repair/promotion work while retaining exact task identity; failed observation cannot masquerade as failed or completed remote work. | Reuse the recovery receipt and promotion task UID; close the manual promotion-refresh gap by re-reading that same UID and keep unknown on observer errors. |
| OPUX-22 | Operators can review and perform supported repair/promotion through the existing confirmation, authorization, and eligibility gates; completion remains tied to authoritative task/index/document evidence rather than acceptance, a flash, or historic unrelated work. | Preserve current retry/promotion gates; re-evaluate allowlist, eligibility, target identity and fresh evidence at mutation time; require post-task evidence before completion. |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Keep the Ecto-first Elixir/Phoenix product scope, Meilisearch as the v1 backend, internal adapter seam, existing write-path support, host-owned authorization and operationally truthful async/delete/reindex behavior. No new public API, backend, framework, surface, or dependency. [VERIFIED: root AGENTS.md supplied in task; .planning/phases/175-repair-and-verification/175-CONTEXT.md]
- Keep edits focused; follow CONTRIBUTING.md; treat .planning/ as milestone context; do not broaden shipped claims. The current phase is active and planning. [VERIFIED: .planning/STATE.md:1-24; CONTRIBUTING.md:43-46,198-200]
- ScrypathOps-specific: run mix precommit for code changes; use the existing Req library for HTTP and avoid HTTPoison, Tesla, and httpc; use Layouts.app, existing icon/input helpers, current Tailwind v4 imports and custom CSS (never @apply or inline script); use HEEx and unique IDs; do not create atoms from untrusted input; follow existing LiveView test patterns. [VERIFIED: scrypath_ops/AGENTS.md:5-37,49-103,139-145]
- Test processes should use start_supervised!/1; avoid Process.sleep/1 and Process.alive?/1. Follow Ops component, CSS-token and verification lanes. [VERIFIED: scrypath_ops/AGENTS.md:94-103; CONTRIBUTING.md:30-47,198]

## Summary

Extend ScrypathOpsWeb.SyncDriftLive and the current failed-work handoff. Existing seams include read-only reconcile/contract reads, a bounded RecoveryObservation receipt tied to a specific retry and host context, PromotionEligibility for promotion guards, and a host gate in the failed-work surface. Keep queue/backend, contract and active-document observations independently named and timestamped; link to the existing eligible retry path with schema context intact. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:1-8,56-98,981-1245; scrypath_ops/lib/scrypath_ops/recovery_observation.ex:1-8,118-174; scrypath_ops/lib/scrypath_ops/promotion_eligibility.ex:4-69; scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex:218-266,700-704]

Three evidence gaps need explicit implementation and test tasks. A matching successful promotion task currently sets the display state to completed before checking later reconcile/contract results; failures in those reads do not retract completion. The existing “Refresh checks” re-runs general reconcile, drift and eligibility but does not re-read the retained promotion task UID. The main screen has no general expected-document observation outside the recovery receipt flow. These conflict with the locked evidence contract. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:283-316,150-155,538-557,758-789,1192-1243]

**Primary recommendation:** keep LiveView as orchestration/rendering boundary and mutation decisions in the existing server modules/handlers. Bind each observation to selected schema/index and the exact job-attempt or task UID. Promotion completion requires matching terminal task plus fresh active-index and relevant document evidence. Refresh re-observes the stored task reference and never resubmits the mutation.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Queue/backend, contract, and document observations | API / Backend | Frontend Server (SSR) | Scrypath/Ecto/Meilisearch reads are authoritative; LiveView renders independent results. |
| Retry and promotion authorization/eligibility | API / Backend | Frontend Server (SSR) | Current allowlist, host gate, eligibility evaluator and mutation handlers own decisions; disabled UI is explanatory. |
| Operation status and schema continuity | Frontend Server (SSR) | Browser / Client | LiveView owns async results/patches; URL values are public input resolved against the live allowlist. |
| Shared visual treatment, focus and status announcement | Browser / Client | Frontend Server (SSR) | HEEx semantics and OpsUi components deliver visible and accessible operator feedback. |

## Standard Stack

No package installation is required or permitted. Use the existing Elixir/Phoenix Ops app, LiveView async callbacks, Scrypath Meilisearch operations, optional existing Oban integration, RecoveryObservation, PromotionEligibility, OpsUi and current Playwright lane. The existing Ops dependency declarations are Phoenix ~> 1.8.9, LiveView ~> 1.1.33, Ecto SQL ~> 3.13, Req ~> 0.6.1, and Bandit ~> 1.12.1; do not change them. [VERIFIED: scrypath_ops/mix.exs:41-65]

| Existing dependency/pattern | Declared constraint | Phase purpose |
|---|---|---|
| Phoenix LiveView | ~> 1.1.33 | Server-owned UI, start_async/3, handle_async/3, handle_params/3, push_patch/2. |
| Scrypath Meilisearch adapter/tasks | In-repo path dependency | Read exact task status and index identity; retain returned task UID. |
| Oban | Optional integration in host app | Queue job/attempt evidence, distinct from backend task identity. |
| OpsUi and design tokens | In-repo | Sections, statuses, actions, disclosure, modal and shared light/dark styles. |
| Phoenix.LiveViewTest / Playwright | Existing test suites | Rendered behavior and mounted workflow proof. |

**Package legitimacy:** Not applicable; no external packages are added. A new library conflicts with D-11 and project scope.

## Architecture Patterns

### Recommended flow

~~~text
Selected URL schema ──resolve against current allowlist; advance generation on change
       │
       ▼
Sync and drift LiveView
  Queue/backend read ──► independent status + checked time
  Contract read ───────► declared-vs-live dimensions + checked time
  Document read ───────► expected ID/value in active index + checked time
  Review failed work ──► existing eligible retry + host gate
                                │ accepted receipt
                                ▼
                    retain job + attempt + schema/index + exact task UID
  Refresh ─────────────► observe same receipt/task; no mutation
  Advanced disclosure ► explicit confirmation ► host gate ► swap task UID
                                │
                                ▼
                    poll same UID, then fresh active-index/document evidence

Any stale, mismatched, or unavailable leg ──► unknown; retain identity and safe check
~~~

This is a conceptual flow, not a list of new modules. Keep one LiveView unless a concrete repeated need justifies a small helper. handle_params/3 re-resolves selection and clears context-bound evidence on target change. RecoveryObservation is a bounded, in-memory receipt, not durable history: its state is held in maps and entries are pruned by TTL. After expiry, restart, or unmatched host/runtime, show unknown/unavailable instead of claiming the work failed. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:56-98,355-385; scrypath_ops/lib/scrypath_ops/recovery_observation.ex:10-16,85-114,118-174,446-449]

### Reusable seams and ownership

| Concern | Source | Use |
|---|---|---|
| Schema selection / stale async defense | sync_drift_live.ex:56-98,355-385,705-722 | Preserve URL selection and generation invalidation; never fall back to first schema. |
| Queue and contract reads | sync_drift_live.ex:724-789,1052-1189 | Keep independent loading/error/success; contract match is not freshness. |
| Recovery observation | sync_drift_live.ex:413-557 | Keep bounded observation and unknown-on-error; render exact receipt identity. |
| Receipt identity | recovery_observation.ex:118-174,250-335,371-391 | Preserve operation, schema, index, replacement job, attempt, backend task UID, host/runtime identity. Telemetry only associates task; direct reads verify it. |
| Promotion eligibility | promotion_eligibility.ex:4-69,74-165 | Recompute against current allowlist, generation, schema/index, pending/failed work and contract evidence. |
| Host mutation gate | integrations/sigra/gating.ex:5-47,60-80 | Keep current action-specific sudo/impersonation/audit behavior. |
| Ordinary retry/modal | failed_sync_live.ex:52-75,218-266,640-754 | Link to current retry implementation; do not duplicate it in SyncDriftLive. |
| UI / tokens | components/ops_ui.ex:122-154,173-197,1367-1465; assets/css/DESIGN-TOKENS.md:8-19,44-59,66-94 | Reuse sections/status/actions/modal and theme/spacing/type tokens. |
| Mounted proof | examples/scrypath_ecommerce/e2e/operator.spec.ts:43-60,140-174,199-207,250-263 | Extend existing disposable operator journey. |

### Evidence truth model

- Queue evidence is for the exact Oban replacement job and attempt. A completed queue job without backend/document evidence is not success. The reader validates job ID, attempt, worker, schema, index and backend. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:580-644]
- Backend evidence is for the exact Meilisearch task UID. Validate UID, indexUid and operation type; lookup/transport/shape mismatch is unavailable evidence. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:646-673,538-557]
- Contract evidence compares declared dimensions with a live snapshot; current UI text explicitly says it “does not verify document freshness.” [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:1315-1330]
- Document evidence must independently observe expected upsert/deletion effects in the active index for the selected schema/operation. Current recovery code calls DocumentObservation.check/3; reuse it rather than equating task completion with document visibility. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:538-547]
- Promotion task success is necessary but insufficient. Require current post-swap reconcile/active alias and relevant document evidence for the same selected schema/index. Current code assigns completion before validating later reads. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:283-316,758-789]
- Meilisearch's 202 Accepted body is a summarized asynchronous task in enqueued state with a task UID. A swap is an indexSwap global task with null indexUid. It is acceptance, not completion. [CITED: https://specs.meilisearch.dev/specifications/text/0060-tasks-api.html#summarized-task-object-for-202-accepted] [CITED: https://specs.meilisearch.dev/specifications/text/0191-swap-indexes-api.html#response-definition]
- Timeout, observer exit, transport error, malformed/missing task, task-not-found, or stale generation cannot become remote failure or success. Keep unknown, retain the reference, and offer an observational refresh. Meilisearch task_not_found can mean the task was deleted, so task history is unavailable. [CITED: https://specs.meilisearch.dev/specifications/text/0060-tasks-api.html#task_not_found-error]

### Async observation pattern

Capture the selected schema and generation before async work, include the exact receipt/task ID in the async name/result, and apply it only if the current generation and ID still match. Refresh calls a read/status observer and never calls swap_indexes/2 or retries again. Recovery and promotion already compare generation and receipt/task IDs. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:413-431,244-280,283-319]

~~~elixir
schema = socket.assigns.selected_schema
generation = socket.assigns.context_generation
task_uid = socket.assigns.promotion_task_id

start_async(socket, {:promotion_swap, generation, task_uid}, fn ->
  observe_same_task_and_current_effect(schema, task_uid)
end)
~~~

Structural example only; use existing adapters/private helpers, not a new public API. Existing async work is named with “{:promotion_swap, generation, task_id}”. The observer must preserve unknown on failure and apply fresh index/document evidence before success. LiveView documents process-isolated start_async/3 and advises capturing only needed values rather than copying the socket into the task closure. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:283-289,809-812] [CITED: https://hexdocs.pm/phoenix_live_view/1.1.33/Phoenix.LiveView.html#start_async/4]

### Preserve status vocabulary and announcement

The exact recovery status clauses are:

~~~elixir
defp recovery_status_label(:accepted), do: "Retry accepted"
defp recovery_status_label(:running), do: "Retry running"
defp recovery_status_label(:queue_only_completed),
  do: "Queue job completed; backend evidence pending"
defp recovery_status_label(:verified), do: "Recovery verified"
defp recovery_status_label(:failed), do: "Recovery failed"
defp recovery_status_label(:timed_out), do: "Recovery check timed out"
defp recovery_status_label(_), do: "Recovery unknown"
~~~

Keep these exact local states and meanings while making same-task polling and post-swap evidence clear. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:336-345]

Promotion's existing state clauses include the exact values :accepted, :completed, :timed_out, :unknown, {:failed, ...}, and these task patterns:

~~~elixir
{:ok, %{id: ^task_id, state: :succeeded}} ->
socket |> assign(:promotion_status, :completed)
{:error, {:timeout, _task}} ->
assign(socket, :promotion_status, :timed_out)
{:error, {:task_failed, %OperationTask{id: ^task_id, state: :failed} = task}} ->
assign(socket, :promotion_status, {:failed, {:task_failed, task}})
{:error, {:cancelled, %OperationTask{id: ^task_id, state: :cancelled} = task}} ->
assign(socket, :promotion_status, {:failed, {:cancelled, task}})
{:error, _observation_error} ->
assign(socket, :promotion_status, :unknown)
~~~

These clauses show the current async task mapping; change the completion boundary so the terminal success clause alone does not claim verified promotion. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:292-312]

Meilisearch task statuses are enqueued, processing, succeeded, failed, canceled; local telemetry normalization accepts “cancelled” and “canceled”. [CITED: https://specs.meilisearch.dev/specifications/text/0060-tasks-api.html#status-field-enum] [VERIFIED: scrypath_ops/lib/scrypath_ops/recovery_observation.ex:429-444]

Use visible text and action-adjacent next steps; expose changed async status programmatically without taking focus. WCAG says status messages can be programmatically identified for AT without focus and color cannot be the only information channel. Existing ops_inline_code supports break-all IDs. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html] [VERIFIED: scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex:1435-1440]

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---|---|---|---|
| Retry eligibility/payload | Second retry action in SyncDriftLive | Existing failed-work action, FailedWork.recovery_action/1, Scrypath.retry_sync_work/2 and Gating | Existing surface validates support and applies host authorization. |
| Promotion blockers | Duplicated view-only conditions | PromotionEligibility.evaluate/1 | Central current observation/context, pending/failed work, target and contract checks. |
| Job/task/document correlation | Newest task or status from history list | Existing receipt and exact identity reads | Prevent cross-operation/schema/index success. |
| Async UI state | Custom polling framework, supervisor, generic status framework | Existing LiveView async callbacks and narrow helper | No new process/dependency or speculative abstraction. |
| Status visuals/dialog | New component system or modal | Existing OpsUi sections, statuses, buttons, disclosure and modal | Existing theme, focus and interaction contract. |

**Key insight:** these are correlated asynchronous facts, not one boolean. Keep receipts, terminal task reports, and index/document observations distinct and bound to their operation.

## Common Pitfalls

1. **Treating task acceptance or queue completion as UI completion.** The backend accepts work before processing; queue-only completion is already modeled as “backend evidence pending.” [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:458-483; CITED: https://specs.meilisearch.dev/specifications/text/0060-tasks-api.html]
2. **Reporting promotion complete before post-swap evidence.** Matching succeeded currently sets completed and then reads reconcile/drift; later read errors do not revoke it. Stage a pending/unknown result, then require matching task and fresh index/document evidence. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:283-316,758-789]
3. **Refreshing general state but not the task.** Current refresh re-runs reconcile/drift/eligibility but leaves the retained task status untouched. Query that same UID. Existing test proves no duplicate swap but not same-task lookup. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:150-155; scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs:515-529]
4. **Treating observation error as remote failure.** Timeout, transport, malformed/missing task, expiry, process exit, stale generation, and ID mismatch stay unknown. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:269-280,299-313,322-329,538-557]
5. **Using cross-target evidence.** URL/event values are public; re-resolve allowlist and invalidate context-bound results/confirmation on schema or index change. Reject invalid explicit selection; no implicit fallback. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:56-98,355-385,193-203,705-722]
6. **Trusting stale UI eligibility.** Keep host authorization and fresh promotion prerequisites in the server mutation handler; likewise re-check retry action on the failed-work server path. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:206-229,791-869; scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex:218-266; scrypath_ops/lib/scrypath_ops/integrations/sigra/gating.ex:19-47]
7. **Calling contract compliance document freshness.** Keep the expected-document check separate and show not checked/unavailable where there is no evidence. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:1319-1330]
8. **Hiding old failure when showing new retry.** Render source failure and replacement job/attempt separately; accepted replacement work does not erase historical evidence. [VERIFIED: scrypath_ops/lib/scrypath_ops/recovery_observation.ex:126-150,167-173; scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex:617-668]
9. **Unreadable IDs or color-only status.** Wrap identifiers and reasons, pair colors with text/icons, avoid focus movement and check narrow light/dark layouts. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html; https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html]
10. **Promising durable receipt recovery.** Receipt store is in-memory and TTL-bounded. After expiry/restart/context mismatch, report unavailable/unknown. [VERIFIED: scrypath_ops/lib/scrypath_ops/recovery_observation.ex:10-16,85-114,446-449]

## Security Domain

| ASVS area | Applies | Phase control |
|---|---|---|
| V8 Authorization | Yes | Keep host-owned Sigra authorization, impersonation denial, fresh sudo and audit. Disabled controls are not controls. [VERIFIED: scrypath_ops/lib/scrypath_ops/integrations/sigra/gating.ex:5-47] [CITED: https://cornucopia.owasp.org/taxonomy/asvs-5.0] |
| V2 Validation and Business Logic | Yes | Resolve URL/event schema against live allowlist; bound receipt/generation params; validate schema/index/job/attempt/task IDs server-side. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:56-98,387-401,193-203] [CITED: https://cornucopia.owasp.org/taxonomy/asvs-5.0/02-validation-and-business-logic/02-input-validation] |
| V7 Session Management | Existing host boundary | No new session/auth product; preserve host session and sudo semantics. [CITED: https://cornucopia.owasp.org/taxonomy/asvs-5.0] |
| V11 Cryptography | Narrowly applicable | Continue existing cryptographically random opaque receipt; do not invent client-side signing or auth tokens. [VERIFIED: scrypath_ops/lib/scrypath_ops/recovery_observation.ex:118-123] [CITED: https://cornucopia.owasp.org/taxonomy/asvs-5.0] |

Threat pass: spoofed schema/task IDs, replayed client events, stale authorization or impersonation, accidental duplicate mutation, stale async result after schema change, cross-context receipt reuse, missing task history or observer outage misreported as failure, unescaped long IDs, and success flash detached from audit/evidence. Mitigate with live allowlist resolution, host gate, fresh eligibility/evidence before mutation, generation/identity checks and escaped text. Never treat task UID alone as evidence of target index or document visibility.

## Validation Architecture

Nyquist validation is enabled: the config contains the verbatim value “nyquist_validation”: true. [VERIFIED: .planning/config.json:19-20] CONTRIBUTING’s canonical Ops command is mix verify.ops_ui; the focused LiveView suite covers promotion guards, confirmation replay, schema selection, stale results, receipt evidence, terminal/unknown task results and observational refresh. [VERIFIED: CONTRIBUTING.md:198; scrypath_ops/mix.exs:80-103; scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs:120-189,191-236,238-373,375-529]

| Requirement / proof | Type | Existing target / needed scenario |
|---|---|---|
| OPUX-20: queue/contract/document independent observed/unavailable results | LiveView + rendered | sync_drift_live_test.exs; add distinct expected-document section assertions and prove contract match does not satisfy it. |
| OPUX-20: ordinary retry vs advanced promotion | Mounted + LiveView | Extend operator.spec.ts; existing journey covers failed-work recovery and contract/promotion controls. Assert schema continuity on failed-work handoff and return. |
| OPUX-21: lifecycle states, identity and unknown | Focused LiveView | Existing tests cover accepted UID, exact recovery IDs, matching/wrong task, cancel/failure, observer/transport/malformed/timeout and no resubmit; add same-UID re-observation after timeout/unknown. |
| OPUX-22: mutation-time authorization/eligibility and post-task proof | LiveView + disposable stack | Existing tests cover stale contract, pending queue, replay, impersonation and stale sudo; add post-swap active-index/document mismatch/unavailable cases. |
| Accessibility/responsive contract | Existing a11y + Playwright | Use existing lane and disposable journey; assert visible state text, ID wrapping and light/dark at narrow/desktop widths. |

**Current gaps:** No general active-document section is rendered on Sync and drift; promotion success is task-only before refresh reads; refresh does not query its exact task UID. Add executable regressions for these. Extend existing lanes; do not add a CI service. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:981-1245,283-316,150-155; examples/scrypath_ecommerce/e2e/operator.spec.ts:43-60,250-263]

**Focused command:** cd scrypath_ops && mix test test/scrypath_ops_web/live/sync_drift_live_test.exs  
**Phase gate:** mix verify.ops_ui from repository root. Extend and run the existing mounted E2E lane for disposable mutation proof. Screenshots supplement executable proof.

## Environment Availability

| Dependency | Required by | Available | Version | Fallback |
|---|---|---|---|---|
| Elixir / OTP | Ops suite | Yes | Elixir 1.19.0 / OTP 28 | — |
| Docker / Compose | Disposable mounted proof | Yes | Docker 29.5.2 / Compose 5.1.3 | Focused LiveView tests are available if setup fails; mounted path proof remains relevant. |
| Meilisearch | Real task/swap/document proof | Not probed against any service | — | Repository disposable E2E fixture; never target a non-disposable operator backend. |
| Global Playwright CLI | Browser proof | Not found on PATH | — | Follow repository-managed ecommerce E2E setup. |

No packages were installed and no external service was mutated during research.

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|---|---|---|
| A1 | Existing DocumentObservation.check/3 can support the desired active-index verification input/output for promotion without public API change. | Evidence truth model | Plan must adapt an internal seam or surface a scope question; no public API expansion. |
| A2 | Current disposable Playwright fixtures can expose the promotion alias/document evidence needed by OPUX-22. | Validation Architecture | Fixture-local work or environment limitation may be needed; never replace with production backend access. |

## Open Questions (RESOLVED)

These are conservative planning resolutions under the standing auto-recommendation instruction, derived from locked decisions D-01 and D-05 and the in-repo evidence below; they are not new user confirmations.

1. **Expected-document identity is unavailable without an authoritative source.** When no expected identity exists outside the failed-work receipt or a known disposable fixture, report document freshness as `not checked/unavailable`. Never infer a document ID or claim document success. This keeps document freshness distinct from queue/backend and contract evidence as required by D-01. The existing recovery flow reconstructs expected effects from its failed source item, and its document verification uses that expected identity. [VERIFIED: scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:538-547,675-699]
2. **Receipt expiry/restart stays unknown or unavailable.** The process-local receipt may expire after its ten-minute TTL or disappear on process restart; in either case, retain unknown/could-not-check wording and do not infer remote failure or success. Refresh remains observational and must not resubmit the mutation under D-05. Durable receipt storage is outside this phase's scope. [VERIFIED: scrypath_ops/lib/scrypath_ops/recovery_observation.ex:10-16,85-114,446-449]

## Sources

### Primary in-repo sources

- 175-CONTEXT.md — locked D-01–D-11; copied above.
- 175-UI-SPEC.md — accepted evidence order, copy and interaction contract; recommendations are researcher-synthesized under the recorded standing direction.
- sync_drift_live.ex, recovery_observation.ex, promotion_eligibility.ex, integrations/sigra/gating.ex — observation, correlation, eligibility and authorization.
- failed_sync_live.ex and sync_drift_live_test.exs — existing recovery handoff and behavior coverage.
- scrypath_ops/AGENTS.md, CONTRIBUTING.md, mix.exs, OpsUi, DESIGN-TOKENS.md — project constraints, declared stack, tests and design authority.

### Official external documentation

- [Meilisearch Tasks API](https://specs.meilisearch.dev/specifications/text/0060-tasks-api.html) — UID, acceptance, lifecycle, task lookup and task-not-found.
- [Meilisearch Swap Indexes API](https://specs.meilisearch.dev/specifications/text/0191-swap-indexes-api.html) — asynchronous swap task and global-task index UID.
- [Meilisearch task monitoring guide](https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/monitor_tasks) — polling by returned UID.
- [Phoenix LiveView 1.1.33 API](https://hexdocs.pm/phoenix_live_view/1.1.33/Phoenix.LiveView.html) — async lifecycle, public URL/event params and patch handling.
- [WCAG 2.2 Status Messages](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html) and [Use of Color](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html) — programmatic status announcements and redundant cues.
- [OWASP ASVS 5.0 Input Validation](https://cornucopia.owasp.org/taxonomy/asvs-5.0/02-validation-and-business-logic/02-input-validation) — allowlist and server-side business input checks.

### Local project guidance

- prompts/phoenix-live-view-best-practices-deep-research.md — native LiveView lifecycle/async, don't capture socket in async closures, validate public params, use LiveView test conventions.
- prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md — prefer clear source-of-truth ownership and small functions over speculative process/distributed abstractions.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — read dependency declaration and current in-repo paths.
- Architecture: HIGH — traced LiveView, receipt, eligibility, retry and gate directly.
- Pitfalls: HIGH — tied to concrete existing code gaps and regression tests; current external behavior cited to official docs.
- Validation: HIGH for current tests/commands; MEDIUM for mounted fixture readiness because no disposable stack was started.

**Research date:** 2026-10-10  
**Valid until:** 2026-11-09 for repository patterns; re-check external LiveView/Meilisearch docs after this window.
