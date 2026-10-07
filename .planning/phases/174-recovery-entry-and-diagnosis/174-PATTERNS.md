# Phase 174: Recovery Entry and Diagnosis - Pattern Map

**Mapped:** 2026-10-06
**Files analyzed:** 12 likely new/modified files
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `scrypath_ops/lib/scrypath_ops/operator_selection.ex` | utility | transform | same file | exact |
| `scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex` | component | request-response | same file | exact |
| `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex` | component | request-response / transform | same file | exact |
| `scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex` | component | request-response / event-driven | same file | exact |
| `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` | component | transform | same file | exact |
| `scrypath_ops/lib/scrypath_ops_web/nav.ex` | utility | transform | same file | exact |
| `scrypath_ops/lib/scrypath_ops_web/live/on_mount.ex` | middleware / provider | request-response | same file | exact |
| `scrypath_ops/lib/scrypath_ops/integrations/sigra/gating.ex` | middleware | request-response | same file | exact |
| `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex` | component | request-response / event-driven | same file | exact |
| `scrypath_ops/test/scrypath_ops/operator_selection_test.exs` and LiveView tests | test | request-response | same test files | exact |
| `examples/scrypath_ecommerce/e2e/operator.spec.ts` | test | request-response / event-driven | same file | exact |
| `examples/scrypath_ecommerce/scripts/verify-phase174.sh` (possible new runner) | utility / test harness | batch | `verify-phase173.sh` | role-match |

The phase is an in-place Ops change. Preserve existing server-side schema resolution, bounded observation/time behavior, host authorization and core recovery contracts. No new package is indicated. The Phase 174 runner is conditional; if added, make a separate script and scope rather than changing Phase 173's completed receipt/scope contract.

## Pattern Assignments

### `scrypath_ops/lib/scrypath_ops/operator_selection.ex` (utility, transform)

**Analog:** same tracked file; it is the canonical implementation to extend only if current call sites require it.

**Canonical resolution and URL construction** (`operator_selection.ex`, lines 11-39):

```elixir
def resolve(params, allowlist) when is_map(params) and is_list(allowlist) do
  case allowlist do
    [] -> :setup
    [first | _] ->
      if Map.has_key?(params, "schema") do
        requested = Map.get(params, "schema")
        case Enum.find(allowlist, &(canonical(&1) == requested)) do
          nil -> :unavailable
          module -> {:ok, module}
        end
      else
        {:ok, first}
      end
  end
end

def path(mount_path, destination, schema)
    when is_binary(mount_path) and is_binary(destination) and is_atom(schema) do
  base = String.trim_trailing(mount_path, "/")
  query = URI.encode_query(%{"schema" => canonical(schema)})
  "#{base}/#{destination}?#{query}"
end
```

Keep absent-param defaulting distinct from explicitly invalid/blank input; only compare canonical strings against currently loaded allowlist modules. Do not create atoms from URL values. Build every recovery handoff through `path/3` or an equally bounded canonical builder.

### `scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex` (component, request-response)

**Analog:** same file.

**Imports/data source and refresh** (`control_room_live.ex`, lines 11-43):

```elixir
use ScrypathOpsWeb, :live_view
alias ScrypathOps.Posture

def mount(_params, _session, socket) do
  socket =
    socket
    |> assign(:schema_allowlist, ScrypathOps.Schemas.allowlist())
    |> assign(:scrypath_opts, ScrypathOps.Schemas.scrypath_opts())
    |> load_summary()
  {:ok, socket}
end

defp load_summary(socket) do
  summary = Posture.summary(socket.assigns.schema_allowlist, socket.assigns.scrypath_opts)
  assign(socket, :posture, summary)
end
```

The current rendered verdict and health link are at lines 69-93. Use the same component vocabulary and posture evidence; revise the hierarchy to one read-only health CTA and a separately named valid recovery target. Keep the overview fleet-wide and avoid duplicating the destination in multiple cards.

### `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex` (component, request-response / transform)

**Analog:** same file.

**LiveView setup and canonical handoff** (`posture_live.ex`, lines 9-48, 68-79):

```elixir
use ScrypathOpsWeb, :live_view
alias ScrypathOps.OperatorSelection

def mount(params, _session, socket) do
  allowlist = ScrypathOps.Schemas.allowlist()
  scrypath_opts = ScrypathOps.Schemas.scrypath_opts()
  socket =
    socket
    |> assign(:schema_allowlist, allowlist)
    |> assign(:scrypath_opts, scrypath_opts)
    |> assign(:posture_rows, [])
  {:ok, load_posture(socket)}
end

def handle_event("swap_live", %{"schema" => mod_str}, socket) do
  case mod_from_allowlist(mod_str, socket.assigns.schema_allowlist) do
    {:ok, mod} ->
      {:noreply, push_navigate(socket,
        to: OperatorSelection.path(socket.assigns.mount_path, "sync-drift", mod))}
    :error -> {:noreply, put_flash(socket, :error, "Select an allowlisted schema.")}
  end
end
```

The current worst-first ordering and record/link rendering are at lines 315-345, 439-447 and 512-525. Keep fleet rows in their established order and preserve complete module/index identity. Row-specific links intentionally select that row's schema; a fleet-level recovery handoff must use the separately resolved target, never infer it from severity or row order.

### `scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex` (component, request-response / event-driven)

**Analog:** same file; for the core row contract, see tracked `lib/scrypath/operator/failed_work.ex` lines 52-99 and recovery action at 144-155.

**Validated selection, invalidation, and existing gates** (`failed_sync_live.ex`, lines 36-89, 109-140, 218-273):

```elixir
def handle_params(params, _uri, socket), do: {:noreply, resolve_selection(socket, params)}

def handle_event("select_schema", %{"schema" => mod_str}, socket) do
  case OperatorSelection.resolve(%{"schema" => mod_str}, ScrypathOps.Schemas.allowlist()) do
    {:ok, mod} ->
      {:noreply, push_patch(socket,
        to: OperatorSelection.path(socket.assigns.mount_path, "failed-sync", mod))}
    _ -> {:noreply, unavailable(socket)}
  end
end

defp maybe_advance_generation(socket, true) do
  Enum.each(Map.values(Map.get(socket.assigns, :recovery_receipts, %{})), fn receipt ->
    if receipt.handle, do: ScrypathOps.RecoveryObservation.invalidate(receipt.handle)
  end)
  socket
  |> update(:context_generation, &(&1 + 1))
  |> assign(:inspection, nil)
  |> assign(:recovery_receipts, %{})
  |> assign(:delete_confirmation, nil)
end

defp request_retry(socket, id) do
  cond do
    not current_selection?(socket) -> unavailable(socket)
    true ->
      case failed_work_row(socket, id) do
        %{operation: :delete, recovery: recovery} when not is_nil(recovery) ->
          assign(socket, :delete_confirmation, to_string(id))
        %{recovery: recovery} when not is_nil(recovery) ->
          Gating.gate_sensitive_action(socket, :failed_work_retry, fn ->
            retry_failed_work(socket, id)
          end)
        _row -> put_flash(socket, :error, "That job does not expose a retry action.")
      end
  end
end
```

Current ID-only row/receipt/modal lookup is at lines 223-238, 380-424; retry acceptance and observation handoff are at lines 247-326, 382-393. Derive an Ops-local identity from canonical selected schema, `row.source`, and full `row.id`; use it consistently for event values, DOM IDs, receipt map keys and delete confirmation. Resolve each event back to a row in the current inspection before using `FailedWork.recovery_action/1` and the existing server gates. Keep original `row.id` intact for display and core API calls. The current HEEx ordering at lines 616-677 already places reason before diagnostics; revise labels/actions to name Backend task vs Queue job and keep acceptance distinct from terminal observation. Preserve the exact delete evidence and existing modal at lines 697-747.

### `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` (component, transform)

**Analog:** same tracked component file.

**Command palette boundary** (`ops_ui.ex`, lines 1481-1502, 1524-1538):

```elixir
attr(:mount_path, :string, required: true)

def ops_command_palette(assigns) do
  items =
    [%{path: assigns.mount_path, label: "Control Room", hint: "Home · trust verdict"}
     | Enum.map(ScrypathOpsWeb.Nav.primary(assigns.mount_path), fn item ->
         %{path: item.path, label: item.label,
           hint: "#{nav_group_label(item.group)} · #{item.title}"}
       end)]
  assigns = assign(assigns, :items, items)
  ~H"""
  <div id="ops-command-palette" phx-hook="CommandPalette" phx-update="ignore">
    ...
    <.link :for={item <- @items} navigate={item.path} data-cmdk-item>
      {item.label}
    </.link>
  </div>
  """
end
```

The ignored subtree will not receive ordinary server patches. Carry selected target into shell/navigation inputs and use the existing `CommandPalette` hook lifecycle in `scrypath_ops/assets/js/ops_hooks.js` (tracked) for a narrow contextual destination update. Preserve open/close, filtering, keyboard and focus behavior; actual updated `href` after selection is the relevant browser contract.

### `scrypath_ops/lib/scrypath_ops_web/nav.ex` and `live/on_mount.ex` (utility / provider)

**Analogs:** same files.

`Nav.primary/1` (`nav.ex`, lines 14-46) defines ordered shell destinations using `mount_path`; add canonical schema context at the caller/builder seam without changing route ownership or dropping a query on only one destination. `OnMount.on_mount/4` (`on_mount.ex`, lines 18-35) assigns the ops shell and derives the mount path through a `:handle_params` hook. Follow that hook pattern for shared URL context only where page-local resolution is not available; keep the URL as the source of truth and avoid a second sticky selection store.

### `scrypath_ops/lib/scrypath_ops/integrations/sigra/gating.ex` (middleware, request-response)

**Analog:** same tracked file.

**Host authorization boundary and safe return construction** (`gating.ex`, lines 19-46, 72-80):

```elixir
def gate_sensitive_action(socket, action, fun)
    when action in @actions and is_function(fun, 0) do
  case Map.get(socket.assigns, :operator_context) do
    nil -> fun.()
    %{impersonator_user_id: id} when not is_nil(id) ->
      Phoenix.LiveView.put_flash(socket, :error, "Impersonation must be cleared before this action.")
    %{sudo_at: sudo_at} = operator_context ->
      if stale_sudo?(sudo_at) do
        confirm_path = confirm_path()
        return_to = return_to(socket)
        Phoenix.LiveView.push_navigate(socket,
          to: confirm_path <> "?" <> URI.encode_query(return_to: return_to))
      else
        audit_action(action, operator_context, socket)
        fun.()
      end
  end
end

defp return_to(%{assigns: assigns, host_uri: %URI{path: path}}),
  do: Map.get(assigns, :return_to) || path || "/"
```

Thread only already validated canonical schema context through the existing local-path boundary; after return, resolve against the current allowlist again. Keep host auth, audit and stale-sudo behavior intact; do not forward arbitrary params or replay the interrupted action.

### `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex` (component, request-response / event-driven)

**Analog:** same tracked file.

Use the existing recovery handoff and observer seam (`sync_drift_live.ex`, lines 53-96, 560-590). Preserve handle/generation checks and accepted/running/terminal/unknown distinctions when schema context is carried into the route. This phase changes ingress/return context only; Phase 175 owns recovery presentation.

### Tests: OperatorSelection, LiveViews, and rendered browser

**Analogs:** tracked `scrypath_ops/test/scrypath_ops/operator_selection_test.exs`, `scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs`, existing ControlRoom/Posture/SyncDrift LiveView tests, and `examples/scrypath_ecommerce/e2e/operator.spec.ts`.

Follow ExUnit + LiveViewTest conventions for absent/allowed/invalid selection, equal IDs across sources, current-inspection lookup, receipt collision, generation invalidation, exact delete confirmation, and auth return. Extend `operator.spec.ts`'s rendered journey: it already chooses non-first Variant, navigates via rendered controls, checks Back/reload and invalid schema, and distinguishes accepted retry from later verification (`operator.spec.ts`, lines 43-169). Add the newly changed Control Room, fleet navigation/palette and return seams; do not claim those are covered by the current journey until exercised.

### `examples/scrypath_ecommerce/scripts/verify-phase174.sh` (possible test harness, batch)

**Analog:** tracked `examples/scrypath_ecommerce/scripts/verify-phase173.sh`.

**Fixture isolation, source identity, cleanup** (`verify-phase173.sh`, lines 3-18, 21-33, 48-65, 67-110):

```bash
set -Eeuo pipefail
scope="${1:-}"
case "$scope" in shell|status|time|copy) ;; *) exit 64 ;; esac
docker compose version >/dev/null 2>&1 || exit 69
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
example_dir="$(cd "$script_dir/.." && pwd)"
repo_root="$(cd "$example_dir/../.." && pwd)"
source_sha="$(git -C "$repo_root" rev-parse HEAD)"
project="scrypath_phase173_${safe_sha:0:10}_${scope}_$$"
trap cleanup EXIT
```

If a dedicated runner is justified by the dual mounted/standalone rendered browser journey, copy isolated Compose naming, source-SHA evidence, artifact collection and guaranteed cleanup. Give it Phase 174's own scope/routes. Do not widen or rewrite the Phase 173 runner/receipt.

## Shared Patterns

### Schema context and navigation

**Sources:** `operator_selection.ex` lines 4-39; `failed_sync_live.ex` lines 79-117; `posture_live.ex` lines 68-79; `nav.ex` lines 14-46; `ops_ui.ex` lines 1483-1538.

Resolve query values against the current allowlist, distinguish absence from invalid explicit values, and encode canonical module identity into mounted URLs. Fleet display remains fleet-wide; explicit row actions deliberately change target. Shell/palette links must carry the validated context and palette DOM updates must cross the ignored-subtree boundary.

### Recovery safety and evidence

**Sources:** `failed_sync_live.ex` lines 218-326, 382-424; `lib/scrypath/operator/failed_work.ex` lines 83-99, 144-155; `gating.ex` lines 19-80; `sync_drift_live.ex` lines 53-96.

Client event data identifies a candidate, never authorization. Re-find it in current schema inspection, preserve source and complete ID, then use the existing recovery action and host gates. An accepted queue receipt remains separate from later observation; selection changes invalidate inspection-bound receipts and confirmations.

### Inherited timing and visual components

**Sources:** `ops_ui.ex` and `posture_live.ex` existing component usage; `scrypath_ops/assets/css/app.css` and `scrypath_ops/assets/js/ops_hooks.js` (tracked).

Reuse Phase 173's time rendering, tokens, controls, disclosures and hook lifecycle. Avoid introducing alternate time semantics, redundant labels, or a new UI dependency.

## No Analog Found

None. The new runner is optional and has a close tracked Phase 173 harness analog.

## Metadata

**Analog search scope:** `scrypath_ops/lib`, `scrypath_ops/test`, `lib/scrypath/operator`, `examples/scrypath_ecommerce/e2e`, `examples/scrypath_ecommerce/scripts`.
**Files scanned:** 12 primary analogs and corresponding shared core/test/hook references.
**Pattern extraction date:** 2026-10-06
