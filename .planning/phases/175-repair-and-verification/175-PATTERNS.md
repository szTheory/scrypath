# Phase 175: Repair and Verification - Pattern Map

**Mapped:** 2026-10-10
**Files analyzed:** 11 likely touched/added files
**Analogs found:** 11 / 11

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex` | controller / LiveView | request-response, async observation | same file; `failed_sync_live.ex` for receipt handoff | exact |
| `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` | component | transform/render | same file | exact |
| `lib/scrypath/meilisearch/tasks.ex` or client seam (only if needed) | service | request-response | `lib/scrypath/meilisearch/client.ex`, `task_payload.ex` | exact |
| `scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs` | test | request-response / async | same file | exact |
| `scrypath_ops/test/scrypath_ops/promotion_eligibility_test.exs` | test | transform | same file | exact |
| `scrypath_ops/test/scrypath_ops/recovery_observation_test.exs` and `document_observation_test.exs` | test | event-driven / request-response | same files | exact |
| `scrypath_ops/test/support/phase175_fixture_source.ex` (if added) | test fixture | transform / request-response | `phase174_fixture_source.ex` | role-match |
| `scrypath_ops/lib/scrypath_ops_web/dev_router.ex` and fixture LiveView test (if extended) | test route/config | request-response | Phase 174 test-only route and route contract | exact |
| `examples/scrypath_ecommerce/e2e/phase175_repair.spec.ts` (if added) | test | browser request-response | `phase174_recovery.spec.ts` | role-match |
| `examples/scrypath_ecommerce/e2e/helpers/e2e.ts` (if extended) | test utility | file-I/O / request-response | same file's `prepareRecoveryFixture` / `prepareSwapFixture` | exact |
| `examples/scrypath_ecommerce/scripts/verify-phase175.sh` (if added) | utility / runner | process orchestration / file-I/O | `verify-phase174.sh` | role-match |

Fixture/route additions are only warranted if existing Phase 174 fixture hooks cannot safely express required states. Keep test routes test-only and fixture mutation in a uniquely owned disposable stack. Relevant existing patterns are tracked sources; the pinned runtime APIs remain the client/task contracts below.

## Pattern Assignments

### Sync and drift LiveView, task outcome and recovery correlation

**Analogs:** `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex` (tracked)

Selection changes advance `context_generation` in `handle_params/3` (lines 56-98); recovery callbacks publish only when generation, receipt handle and current allowlist selection still match (lines 244-284, 719-727). Promotion callbacks already guard captured generation and exact task id, and map terminal success/failure/cancel plus timeout/read failure to distinct outcomes (lines 295-344). Preserve this identity guard on both result and error callbacks; include current allowlist/runtime identity where the new observer can cross host runtime context.

```elixir
if generation == socket.assigns.context_generation and
     task_id == socket.assigns.promotion_task_id do
  # publish only the result belonging to the still-current selection/task
else
  {:noreply, socket}
end
```

For retry verification, copy the existing receipt pipeline rather than treating job completion/telemetry as success: allowlist + receipt generation/runtime + active index + exact job/attempt are checked before task/document proof (`sync_drift_live.ex:461-510,550-684`). `RecoveryObservation` stores a bounded opaque handle and identity-only telemetry (`recovery_observation.ex:32-49,118-171`); `DocumentObservation` classifies exact task state and requires active-index upsert contents or delete absence (`document_observation.ex:36-89,91-155`). A completed queue job without task/effect evidence remains intermediate.

### Meilisearch task read and state normalization

**Analogs:** `lib/scrypath/meilisearch/client.ex:80-83`, `lib/scrypath/meilisearch/task_payload.ex:4-54`, `lib/scrypath/meilisearch/tasks.ex:99-182` (tracked)

The client seam is `Client.task(uid, config)`, which issues `GET /tasks/#{task_uid}` (client lines 80-83); configured clients are selected as `Keyword.get(config, :meilisearch_client) || Client` in `tasks.ex:208-209`. `TaskPayload.normalize/2` extracts UID from `taskUid`/`uid` and maps `enqueued` (and legacy `queued`) separately from `processing` (lines 7-26,35-54). `Tasks.wait_for_task/2` considers both statuses pollable but they are distinct normalized states (tasks lines 139-182). For the required UI contract, show `accepted/queued` only from the successful swap response; show `running` only after exact-UID GET returns normalized `processing`. A GET returning `enqueued` remains accepted/queued. Busy observation, HTTP acceptance, and elapsed time are not remote running. GET errors, missing UID, malformed response, unexpected UID or stale context remain unknown/unconfirmed. Do not duplicate HTTP/config resolution: use configured `meilisearch_client` plus `Client.task/2` behavior and normalize/validate response against the requested UID.

```elixir
def task(task_uid, config) do
  run_request(:get, "/tasks/#{task_uid}", [], config, task_uid: task_uid)
end
```

### Promotion eligibility, authorization, and confirmation

**Analogs:** `scrypath_ops/lib/scrypath_ops/promotion_eligibility.ex:4-72`; `scrypath_ops/lib/scrypath_ops/integrations/sigra/gating.ex:21-49,111-127`; `sync_drift_live.ex:805-883` (tracked)

Keep eligibility as the existing fail-closed pure evaluator: current same-context reconciliation/configuration, distinct observed indexes, cutover/reindex state, no pending/failed work, and supported allowlisted schema (eligibility lines 4-72). Immediately before calling the existing swap, `swap_live/1` passes through `Gating.gate_sensitive_action/3`, fetches current prerequisites and only then submits (`sync_drift_live.ex:805-835,838-883`). Revalidate schema through canonical `OperatorSelection.resolve/2`; do not rely on hidden/disabled browser controls. Host auth return preserves navigation context and does not replay the mutation (`gating.ex:35-47`). Existing modal pattern uses `ops_modal` and explicit cancel event; show full schema and live/target IDs as current `sync_drift_live.ex:1366-1398` does. Correct effect copy to pairwise index swap, not alias mutation.

### Native disclosure, rendering and patch/focus behavior

**Analogs:** `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex:1378-1409`; `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex:410-417,570-586`; `scrypath_ops/assets/js/ops_hooks.js:36-97` (tracked)

Use `OpsHealthDetails` when a LiveView-patched native `<details>` must retain manual expansion and focus. It ignores server `open` mutations and restores a focused descendant after DOM patch. Current `ops_disclosure` provides native details/summary, but the promotion disclosure is raw `<details open={@promotion_status != nil}>` (`sync_drift_live.ex:1297-1348`), which does not preserve user-owned open/closed state. Keep active/terminal status and task UID outside its collapsible body as the UI-SPEC requires; use the existing hook rather than forcing `open` on every patch.

```heex
<details phx-hook="OpsHealthDetails" phx-mounted={JS.ignore_attributes("open")}
         data-ops-required-open={if required?, do: "true", else: "false"}>
  <summary>...</summary>
  ...
</details>
```

### LiveView proof and pure eligibility/correlation tests

**Analogs:** `scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs:15-77,79-117,498-565`; `promotion_eligibility_test.exs`; `recovery_observation_test.exs`; `document_observation_test.exs` (tracked)

The LiveView test uses a configurable client/Oban inspector and supervised Agent state/call counters (lines 15-77,79-117); use it to assert exact requested task UID and that check events never increment swap count. Existing async callback assertions cover matching UID and terminal/unknown states (lines 498-565); extend with enqueued vs processing, timeout then same-UID read, and stale generation/allowlist. Keep policy matrix coverage in the pure eligibility test and receipt/effect identity cases in the corresponding focused unit tests. Rendered form/click assertions are preferred where confirming UI behavior; tests that directly call handlers alone do not prove rendered interaction.

### Standalone fixture route/support and disposable mounted proof

**Analogs:** `scrypath_ops/lib/scrypath_ops_web/dev_router.ex:31-51`; `scrypath_ops/test/support/phase174_fixture_source.ex:1-68,70-103`; `scrypath_ops/test/scrypath_ops_web/live/phase174_fixture_live_test.exs:15-60`; `examples/scrypath_ecommerce/e2e/phase174_recovery.spec.ts:553-600`; `examples/scrypath_ecommerce/e2e/helpers/e2e.ts:409-417,451-470`; `examples/scrypath_ecommerce/scripts/verify-phase174.sh:5-31,48-79` (tracked)

Standalone Ops fixtures use a test-only LiveView route, explicit allowlist, deterministic fake client, and fixture contract test proving fixture settings do not bleed into production routes. Follow those guards when adding a Phase 175 scenario (route currently `/ops/phase174` at `dev_router.ex:37-50`; do not broaden a production route). Mounted browser tests create unique markers, seed their tenant fixture, exercise real links/forms, then verify outcome/evidence (`phase174_recovery.spec.ts:553-600`). `prepareRecoveryFixture` and `prepareSwapFixture` call the dedicated dev fixture endpoints and return exact IDs/index pairs (`helpers/e2e.ts:409-417,451-470`); use them only on the existing disposable mounted lane. The standalone script validates the phase/scope namespace, derives a unique Compose project from source SHA and PID, records bounded artifacts, and tears down only labeled owned resources (`verify-phase174.sh:20-29,34-68`). Copy ownership guards if a new phase runner is required; don't repurpose retained previews or seed shared resources.

## Shared Patterns

- **Truthful task states:** acceptance is the swap response and returned UID; remote `running` requires GET of that same UID with `processing`; `enqueued` is still queued. Matching terminal task is separate from observed current index/configuration and document effect.
- **Stale result protection:** capture generation + schema + task/receipt identity; require current allowlist and relevant runtime identity before publishing. Follow `sync_drift_live.ex:244-344,461-510,719-727`.
- **Mutation gate:** existing host sensitive-action gate, fresh prerequisites, allowlist validation, `PromotionEligibility`, duplicate/in-flight guard, then one existing `swap_indexes` call. A status recheck must invoke only `Client.task/2` for the retained UID.
- **Fixture ownership:** test-only standalone scenario/source and mounted fixture endpoints are explicit opt-ins. Preserve allowlist boundaries; mounted mutations run only inside uniquely named task-owned Compose resources with cleanup/artifact checks.

## No Analog Found

No new abstraction is needed for task fetching or disclosure behavior. If a Phase 175 standalone scenario/route or mounted browser fixture must be newly named, follow the Phase 174 fixtures above; there is no existing Phase 175-specific implementation.

## Metadata

**Analog search scope:** `scrypath_ops/lib`, `scrypath_ops/test`, `lib/scrypath/meilisearch`, `examples/scrypath_ecommerce/e2e`, `examples/scrypath_ecommerce/scripts`
**Tracked-source verification:** all analog paths listed above were checked with `git ls-files`; no runtime mirrors or dependency paths are referenced.
**Pattern extraction date:** 2026-10-10
