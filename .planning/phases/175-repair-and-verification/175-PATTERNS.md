# Phase 175: Repair and Verification - Pattern Map

**Mapped:** 2026-10-11  
**Files analyzed:** 7 likely touched files / contracts  
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex` | LiveView controller/component | request-response + async observation | same file, `sync_drift_live.ex` | exact |
| `scrypath_ops/lib/scrypath_ops/recovery_observation.ex` | service/store | event-driven + bounded in-memory receipt lookup | same file, `recovery_observation.ex` | exact |
| `scrypath_ops/lib/scrypath_ops/promotion_eligibility.ex` | service/utility | transform | same file, `promotion_eligibility.ex` | exact |
| `scrypath_ops/lib/scrypath_ops/document_observation.ex` | service | request-response observation | same file, `document_observation.ex` | exact |
| `scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs` | test | request-response + async state transitions | same file, `sync_drift_live_test.exs` | exact |
| `examples/scrypath_ecommerce/e2e/operator.spec.ts` | test | rendered/mounted operator flow | same file, `operator.spec.ts` | exact |
| `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` and `scrypath_ops/assets/css/app.css` | component/config | rendered UI | `ops_ui.ex` and existing tokens | exact shared UI system |

The implementation and test paths above are git-tracked (`git ls-files -- <path>` returned each path). `app.css` and `DESIGN-TOKENS.md` are existing token sources; only touch styling if the rendered states demonstrate a concrete gap. D-01–D-11 remain locked; no new public API or dependency is implied.

## Pattern Assignments

### `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex` (LiveView, request-response + async)

**Analog:** same file; imports and mount assigns at lines 1-48; selection and generation invalidation at lines 56-98 and 355-385; mutation gates at lines 193-229; async result correlation at lines 244-329; recovery observer at lines 413-557; rendering at lines 981 onward.

**Imports and state pattern** (lines 1-18, 20-48):
```elixir
use ScrypathOpsWeb, :live_view

alias ScrypathOps.Integrations.Sigra.Gating
alias ScrypathOps.OperatorSelection
alias ScrypathOps.PromotionEligibility
alias ScrypathOps.RecoveryObservation
alias Scrypath.Meilisearch.Tasks
alias Scrypath.Operations.Task, as: OperationTask
```
Mount initializes independent result/error/generation/loading assigns for reconcile, drift, recovery, promotion, and confirmation. Extend those local assigns instead of collapsing queue, contract, document, and task evidence into one verdict.

**Selection / stale-result pattern** (lines 56-98, 355-385, 705-722):
```elixir
resolution = OperatorSelection.resolve(params, allowlist)
selected = case resolution do
  {:ok, module} -> module
  _ -> nil
end
changed? = selected != socket.assigns.selected_schema or error != socket.assigns.selection_error
socket = socket |> assign(:selected_schema, selected) |> maybe_advance_generation(changed?)
```
Generation changes clear all context-bound results, handles, task IDs, and confirmation. Async callbacks compare both generation and exact receipt/task identity before assigning results. Preserve visible unavailable selection behavior and never substitute another allowlisted schema.

**Read-only refresh and async pattern** (lines 150-155, 413-431, 538-557):
```elixir
handle_event("refresh_recovery_status", _params, socket) do
  case Map.get(socket.assigns, :recovery_handle) do
    handle when is_binary(handle) ->
      if current_selection?(socket), do: {:noreply, start_recovery_observation(socket, handle)},
        else: {:noreply, unavailable(socket)}
    _ -> {:noreply, socket |> assign(:recovery_status, :unknown) |> assign(:recovery_evidence, nil)}
  end
end
```
`start_recovery_observation/2` captures schema, generation, runtime and host context; async result includes `{generation, handle, result}`. Retain the same bounded receipt/task identity on refresh and make unknown/error/exit outcomes unavailable evidence. Refresh handlers must call observers and fresh reads only, never retry/swap mutation functions.

**Mutation / eligibility pattern** (lines 193-229, 791-869):
```elixir
if not socket.assigns.promotion_loading and
     socket.assigns.promotion_eligibility == :eligible and current_selection?(socket) do
  {:noreply, assign(socket, :confirm_swap?, true)}
else
  {:noreply, put_flash(socket, :error, "Index promotion blocked: ...")}
end
```
The actual confirmed mutation re-resolves current selection, recalculates eligibility and fresh evidence, then applies `Gating.gate_sensitive_action/3`. Keep recovery on the existing failed-work action path. The browser confirmation and disabled state are explanatory UI, not authorization.

**UI rendering pattern** (lines 981-1060, 1315-1345):
```heex
<.ops_section
  title="Retry observation"
  subtitle="This read checks the accepted queue job, its exact Meilisearch task, and the active index documents."
  meta={if @recovery_checked_at, do: "checked #{format_dt(@recovery_checked_at)}"}
>
  <:actions><.ops_button phx-click="refresh_recovery_status" disabled={@recovery_loading || !@selected_schema}>
    Refresh recovery status
  </.ops_button></:actions>
  <.ops_status kind={recovery_status_kind(@recovery_status)} title={recovery_status_label(@recovery_status)}>
    A refresh observes this retry and never submits work.
  </.ops_status>
</.ops_section>
```
Use distinct sections/status text per evidence question. Existing contract copy explicitly says it does not verify document freshness (lines 1315-1345). Keep promotion inside the existing advanced disclosure and retain the schema/live/target/alias confirmation wording.

### `scrypath_ops/lib/scrypath_ops/recovery_observation.ex` (service/store, event-driven)

**Analog:** same file; registration and receipt sanitization at lines 117-179, identity at 371-391, task status normalization and TTL pruning at 429-449.

```elixir
handle = :crypto.strong_rand_bytes(24) |> Base.url_encode64(padding: false)
identity = receipt_identity(receipt)
sanitized = receipt
  |> Map.take([:replacement_job, :attempt, :operation, :schema, :index, :task_uid, :generation, ...])
  |> Map.put(:handle, handle)
  |> Map.put(:context, context_digest(host_context))
  |> Map.put(:state, :accepted)
  |> Map.put(:verified, false)
```
Preserve host/context scoping, schema/index/job/attempt/task identity, bounded TTL and explicit unknown after unavailable/expired state. Telemetry associates task identity; authoritative job/task/document reads decide outcome. Do not make this in-memory receipt durable or promote telemetry into proof.

### `scrypath_ops/lib/scrypath_ops/promotion_eligibility.ex` (service, transform)

**Analog:** same file; `evaluate/1` decision order at lines 4-72 and context matching/pending/failed checks at lines 74-165.

```elixir
cond do
  not allowed_schema?(context) -> {:blocked, :schema_not_allowed}
  Map.get(context, :reconcile_error) -> {:blocked, :reconcile_failed}
  Map.get(context, :drift_error) -> {:blocked, :contract_failed}
  not current_generation?(context, :reconcile) -> {:blocked, :reconcile_not_current}
  not same_context?(context) -> {:blocked, :context_mismatch}
  failed_work?(context) -> {:blocked, :failed_work}
  contract_mismatch?(context) -> {:blocked, :contract_mismatch}
  true -> :eligible
end
```
Keep eligibility centralized and return concrete blocker atoms for UI explanation. The LiveView must recompute it at mutation time from current allowlist, generation, schema/index, queue/task state, and fresh contract evidence.

### `scrypath_ops/lib/scrypath_ops/document_observation.ex` (service, request-response observation)

**Analog:** same file; observer timeout/error semantics at lines 19-34, matching task before document read at lines 36-76, and upsert/delete effects at lines 79-155.

```elixir
case task_status do
  status when status in ["enqueued", "processing"] -> result(:running, :task_in_progress, evidence)
  "failed" -> result(:failed, :task_failed, evidence)
  "succeeded" -> observe_effects(receipt, expected, runtime_opts, evidence)
  _ -> result(:unknown, :unknown_task_status, evidence)
end
```
Reuse `check/3` for expected document effects with exact receipt index/task identity. Keep unknown on timeout, transport, malformed task, or missing expected effects. For a general schema probe without authoritative expected values, render not checked/unavailable; do not invent expected document identity.

### `scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs` (test, LiveView async)

**Analog:** same test module; configurable Agent-backed backend/Oban fakes at lines 15-75 and setup/cleanup at 77-118; rendered control at 120-158; mutation guards at 160-236; stale result and receipt checks at 269-373; task outcome matrix and no-resubmit test at 375-529; host authorization at 541-576.

```elixir
{:noreply, stale} = SyncDriftLive.handle_async(
  {:recovery_observation, 7, "opaque-handle"},
  {:ok, {7, "opaque-handle", :verified}},
  refreshing
)
assert stale.assigns.recovery_status == :unknown
assert stale.assigns.recovery_loading
```
Use a single controllable fixture/fake and restore application env in `on_exit`. Test exact same-task UID and target identity; wrong schema/index/document, timeout/transport/malformed/exit, and stale generation stay unknown. Assert observational refresh leaves swap/retry call counts unchanged. Add rendered assertions with `live/3`, `has_element?/3`, `form/3`, and `render_click/1` for evidence labels, action reasons, confirmation content, and selection continuity.

### `examples/scrypath_ecommerce/e2e/operator.spec.ts` (mounted test, browser/backend fixture I/O)

**Analog:** same file; disposable recovery journey at lines 43-60, 140-207; promotion journey at lines 234-280.

```typescript
const fixture = await prepareSwapFixture(request, { tenantId: seed.tenant_id!, marker: runMarker });
await page.goto("/admin/search");
await waitForLiveConnected(page);
await page.getByRole("button", { name: "Check index contract" }).click();
const advanced = page.locator("details").filter({ has: page.locator("summary", { hasText: "Advanced: index promotion" }) });
await advanced.getByRole("button", { name: "Promote target index" }).click();
await expect(page.getByRole("heading", { name: "Confirm index promotion" })).toBeVisible();
```
Reuse disposable fixtures and record task/index/document evidence. Check the task UID displayed in the UI equals the observed backend task, and verify active-index/document proof against the fixture. Preserve the established checks for accessible names, geometry, light/dark screenshots, and browser history schema continuity. Screenshots supplement executable assertions.

### `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` and `scrypath_ops/assets/css/app.css` (shared UI components/tokens)

**Analog:** `ops_section/1` lines 122-154; `ops_button/1` and refresh controls lines 173-239; disclosure lines 1359-1387; inline code lines 1431-1440; modal lines 1443 onward. Token authority: `scrypath_ops/assets/css/DESIGN-TOKENS.md` lines 8-19, 27-42, 66-94.

```heex
<section aria-labelledby={@heading_id} class={["space-y-3", @class]}>
  <.ops_toolbar class="items-start gap-3">...</.ops_toolbar>
  {render_slot(@inner_block)}
</section>
```
Prefer these existing section, status, button, disclosure and modal primitives with native controls. Use semantic status text and breakable `ops_inline_code` for long identifiers; token rules use `ops-*` classes/utilities and semantic theme colors. Add no new component system. `scrypath_ops/lib/scrypath_ops/integrations/sigra/gating.ex` is the tracked authorization seam (lines 19-47): it blocks impersonation, checks current sudo and audits the named action before invoking the mutation.

## Shared Patterns

### Async identity and stale-result protection
Capture only schema/runtime/host context plus current generation and receipt/task ID; include identity in the async name and result. Apply only when current generation and exact ID match. Unknown, timeout, exit, mismatch and malformed evidence must remain unknown and retain the reference for re-observation.

### Independent evidence and lifecycle states
Keep queue job/attempt, backend task UID, live/target index, contract snapshot and expected document evidence separate. Accepted/enqueued and running do not mean success. A matching succeeded task still requires fresh active-index/document evidence. Unavailable evidence is not remote failure.

### Authorization and eligibility
URL/event params and disabled buttons are untrusted. Resolve schema against the live allowlist and re-check eligibility, identity, fresh evidence, host-owned authorization and audit immediately before mutation. Preserve concrete blocked reasons, one-use confirmation and old failure evidence.

### Native operator UI
Use `OpsUi` section/status/button/disclosure/modal primitives, native controls, semantic text/icon/state, visible focus and existing spacing/theme tokens. Keep IDs readable when narrow; use text announcements without moving focus.

### Test fixture pattern
The LiveView suite isolates application configuration, exposes observable fake call counts through a named Agent, and restores prior settings in `on_exit`. Mounted tests use disposable seeded fixtures with unique markers; never target a non-disposable operator backend.

## No Analog Found

No missing role/data-flow analog. One bounded evidence gap remains: a general expected document identity when no recovery receipt exists. `DocumentObservation` is the checker analog, but only call it when an authoritative expected effect is available; otherwise show the existing unavailable/not-checked state.

## Metadata

**Analog search scope:** Sync and drift LiveView, recovery/promotion/document services, Sigra gating, focused LiveView tests, OpsUi, and mounted operator flow.  
**Files scanned:** 9 tracked implementation/test/UI sources plus the design token catalog.  
**Pattern extraction date:** 2026-10-11
