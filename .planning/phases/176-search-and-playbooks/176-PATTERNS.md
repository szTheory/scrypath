# Phase 176: Search and Playbooks - Pattern Map

**Mapped:** 2026-10-10  
**Files analyzed:** 8  
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `scrypath_ops/lib/scrypath_ops_web/live/search_live.ex` | controller (LiveView) | request-response, event-driven | Same file | exact |
| `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex` | controller (LiveView) | request-response, event-driven, file-I/O | Same file | exact |
| `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` | component | request-response presentation | Same file | exact |
| `scrypath_ops/assets/js/ops_hooks.js` | utility (LiveView hook) | event-driven | `OpsModal` in same file | exact |
| `scrypath_ops/assets/css/app.css` | component (styles) | request-response presentation | Existing `.ops-disclosure` and modal rules | exact |
| `scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs` | test | request-response, event-driven | Same file | exact |
| `scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` | test | request-response, event-driven, file-I/O | Same file | exact |
| `examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts` | test | event-driven, request-response | Same file | exact |

All named analogs were confirmed in `git ls-files`; no gitignored install/runtime mirror paths are used. Several analogs have current local edits (including Search LiveView tests, OpsUi, CSS, and the browser spec). Treat those contents as the live baseline and preserve unrelated edits.

## Pattern Assignments

### `scrypath_ops/lib/scrypath_ops_web/live/search_live.ex` (controller/LiveView, request-response + event-driven)

**Analog:** `scrypath_ops/lib/scrypath_ops_web/live/search_live.ex`

**Imports and setup** (lines 1-12, 44-68):
```elixir
use ScrypathOpsWeb, :live_view

alias Scrypath.MultiSearchResult
alias ScrypathOps.Playbook.Store
alias ScrypathOps.Playbook.V1
alias ScrypathOps.Schemas
alias ScrypathOps.SearchPlayground

def mount(_params, _session, socket) do
  allowlist = Schemas.allowlist()
  scrypath_opts = Schemas.scrypath_opts()
```

**Core submit / dispatch pattern** (lines 225-263):
```elixir
def handle_event("search", params, socket) do
  send(self(), {:run_search, params})

  socket =
    socket
    |> assign(:result_single, nil)
    |> assign(:result_multi, nil)
    |> assign(:run_error, nil)
    |> assign(:searching, true)

  {:noreply, socket}
end

def handle_info({:run_search, params}, socket) do
  q = params["q"] |> to_string() |> String.trim()
  page_size = parse_page_size_param(params["page_size"], socket.assigns.page_size)
  mode = socket.assigns.mode
  # validate and dispatch via SearchPlayground, then assign the actual response
end
```
For this phase, move mode and criteria into one captured submission before queuing: current code reads `socket.assigns.mode` after enqueue, which is the known race documented in RESEARCH.md. Preserve the loading-frame behavior, native `phx-submit`, validation, response-derived capture eligibility, and per-mode dispatch. Do not copy the current race into new code.

**Render pattern** (lines 759-815):
```heex
<.form for={%{}} as={:search} phx-submit="search" id="ops-search-playground-form">
  <.ops_fieldset legend="Search target" disabled={...}>
    <.ops_segmented_control label="Search mode" event="set_mode" ... />
    <.ops_schema_select id="search_schema" name="schema" label="Index" ... />
  </.ops_fieldset>
</.form>
```
Keep the current native form structure and shared OpsUi fields. The locked reading order puts query and page-size controls before this same form's single submit and result region.

**Response / partial handling** (lines 382-414):
```elixir
{:ok, %MultiSearchResult{failures: failures} = res} ->
  outcome = if failures == [], do: :ok, else: :partial
  emit_run(:multi, outcome, duration_ms)

  socket =
    socket
    |> assign(:result_multi, res)
    |> assign_search_capture_multi(selected, q, opts)
```
Render complete, zero-hit, partial, hard-error, and setup-unavailable states distinctly. Partial failures remain visible outside optional raw-response disclosures; keep raw payloads in the existing `ops_disclosure` pattern.

### `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex` (controller/LiveView, event-driven + file-I/O)

**Analog:** `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex`

**Imports and upload setup** (lines 1-70):
```elixir
use ScrypathOpsWeb, :live_view

alias ScrypathOps.Playbook.Runner
alias ScrypathOps.Playbook.Store
alias ScrypathOps.Playbook.V1

@max_import_bytes 256_000
@playbook_run_async_key :playbook_run
@playbook_run_timeout_ms 60_000

|> allow_upload(:playbook_file,
  accept: ~w(.json), max_entries: 1,
  max_file_size: @max_import_bytes, auto_upload: false
)
```

**Decode, validation, file actions** (lines 75-108, 223-285):
```elixir
if byte_size(bin) > @max_import_bytes do
  {:noreply, put_flash(socket, :error, "Paste exceeds the maximum import size.")}
else
  {:noreply, apply_decoded(socket, bin, :paste)}
end

case V1.encode(socket.assigns.draft_playbook) do
  {:ok, json} ->
    case Store.save_workspace_file(root, basename, json <> "\n") do
      :ok -> {:noreply, socket |> reload_workspace_catalog() |> put_flash(:info, "Saved #{basename}")}
      {:error, _} -> {:noreply, put_flash(socket, :error, "Save failed — check directory permissions.")}
    end
  {:error, _} -> {:noreply, put_flash(socket, :error, "Could not encode playbook for saving.")}
end
```
Keep V1/Runner/Store as the validation, execution, and persistence authorities. Preserve upload and paste limits, save-overwrite policy, basename/path checks, host authorization, and typed exact-name deletion confirmation. A configured workspace only allows an attempted write; show success only after Store returns `:ok`.

**Async run and stale-reply guard** (lines 390-402, 739-783):
```elixir
def handle_async({@playbook_run_async_key, run_id}, {:ok, {:ok, result}}, socket) do
  if active_run?(socket, run_id) do
    {:noreply,
     socket
     |> assign(:run_result, result)
     |> assign(:run_ui, %{phase: :ok, run_id: run_id, started_monotonic: nil})}
  else
    {:noreply, socket}
  end
end

draft = assigns.draft_playbook

socket
|> start_async(run_async_key(run_id), fn ->
  Runner.run_validated(draft, allowlist, scrypath_opts)
end)
```
Retain keyed async handling, timeout/cancel/supersede behavior and run-ID check. Extend the captured run record with source/criteria attribution so later preview/import/save actions do not relabel old evidence.

### `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` (component, request-response presentation)

**Analog:** `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex`

**Native disclosure and modal contracts** (lines 1280-1307, 1376-1422):
```heex
<details id={@id} open={@open} class={["ops-disclosure", @class]} {@rest}>
  <summary class="cursor-pointer text-ops-body font-medium text-base-content">
    {@summary}
  </summary>
  <div class="ops-disclosure-body mt-2 text-ops-body text-base-content/80">
    {render_slot(@inner_block)}
  </div>
</details>
```
```heex
<div id={@id} role="dialog" aria-modal="true" phx-hook="OpsModal"
     data-ops-modal-initial-focus={@initial_focus}
     data-ops-modal-successor={@successor}>
```
Use the existing components for per-row management disclosure and modal affordances. Add/adjust shared component API only if an actual repeated use requires it; retain native `<details>/<summary>` semantics and ordinary buttons.

### `scrypath_ops/assets/js/ops_hooks.js` (utility/LiveView hook, event-driven)

**Analog:** `OpsModal` in `scrypath_ops/assets/js/ops_hooks.js`

**Focus restore and modal behavior** (lines 420-457, 527-545):
```javascript
destroyed() {
  this.restoreBackground()
  if (activeOpsModal === this) activeOpsModal = null
  window.requestAnimationFrame(() => {
    if (!activeOpsModal) this.restoreFocus()
  })
},
restoreFocus() {
  const sameRecord = this.returnTarget?.getAttribute("phx-value-name") === this.returnTargetName
  const target = this.returnTarget && this.returnTarget.isConnected && sameRecord
    ? this.returnTarget
    : this.querySuccessor()
  if (target && typeof target.focus === "function") target.focus({preventScroll: true})
}
```
The current contract handles patch timing and reused row identity but does not establish visibility after its disclosure closes. Preserve Escape, focus containment, background inertness, and initial-focus selection; ensure the return target is visible and belongs to the correct row, with a logical successor fallback.

### `scrypath_ops/assets/css/app.css` (styles, request-response presentation)

**Analog:** Existing `.ops-disclosure` and `.ops-modal` rules in `scrypath_ops/assets/css/app.css`

**Disclosure styling** (lines 1124-1185):
```css
.ops-disclosure {
  border: 1px solid color-mix(in oklch, var(--color-base-content) 10%, transparent);
  border-radius: var(--radius-ops-lg);
  background: color-mix(in oklch, var(--ops-surface-2) 58%, transparent);
  padding: var(--spacing-ops-3);
}

.ops-disclosure summary,
.ops-disclosure-compact summary {
  display: flex;
  align-items: center;
  min-height: var(--control-h-md);
  cursor: pointer;
}
```
Continue using existing tokens, section rhythm and responsive wrapping. Keep action details in document flow; don't add popup/menu geometry or decorative motion. The source CSS currently has uncommitted edits, so layer any phase changes on that current working copy.

### `scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs` (test, request-response + event-driven)

**Analog:** `scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs`

**Setup and LiveView assertions** (lines 1-48, 162-180, 210-262):
```elixir
use ScrypathOpsWeb.ConnCase, async: false
import Phoenix.LiveViewTest

setup do
  Application.put_env(:scrypath_ops, :schema_allowlist, [OpsPostA, OpsPostB])
  Application.put_env(:scrypath_ops, :search_playground_adapter, SearchPlaygroundStubAdapter)
  # restore application config in on_exit
  :ok
end

{:ok, view, _html} = live(conn, ~p"/ops/search")
view
|> element("#ops-search-playground-form")
|> render_submit(%{"q" => "hello", "page_size" => "10", "schema" => inspect(OpsPostA)})
```
Follow the existing stub-adapter setup and rendered DOM assertions. Add a deterministic queued-submit mode/criteria regression plus result/capture provenance after URL/form edits; keep zero-hit, partial and hard-error cases distinct. Do not replace current local test edits.

### `scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` (test, event-driven + file-I/O)

**Analog:** `scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs`

**Fixtures and transition testing** (lines 1-58, 195-319, 519-638):
```elixir
use ScrypathOpsWeb.ConnCase, async: false
import Phoenix.LiveViewTest

{:ok, view, _html} = live(conn, ~p"/ops/playbooks")
json =
  Jason.encode!(%{
    "playbook_format" => 1,
    "mode" => "search",
    "schema" => "ScrypathOps.Test.OpsPostA",
    "q" => "x",
    "opts" => %{}
  })
html =
  view
  |> form("form[phx-submit='import_paste']", %{json: json})
  |> render_submit()
assert html =~ "data-testid=\"playbook-preview-marker\""
```
Use temporary workspaces with cleanup, stub runner/backend setup and LiveView event sequences. Add source/run/save attribution and failed-import retention cases while preserving existing save, file action, timeout and supersede assertions.

### `examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts` (test, event-driven browser flow)

**Analog:** `examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts`

**Browser workflow pattern** (lines 360-380):
```typescript
await gotoSearch(page);
await page.getByRole("button", { name: "Run search" }).click();
await expect(page.getByRole("heading", { name: "Results", exact: true })).toBeVisible();
await page.getByRole("button", { name: "Save as playbook" }).click();
await page.getByRole("button", { name: "Save playbook" }).click();
await gotoPlaybooks(page);
await expect(page.locator(".ops-object-item").first()).toBeVisible();
```
Extend the existing disposable-stack lane with real narrow/desktop ordering and focus/visibility checks across disclosure close and LiveView row patches. Keep mutating fixtures in the disposable workspace; never target the persistent feedback preview.

## Shared Patterns

### Server ownership and truthful outcomes

**Sources:** `search_live.ex` lines 225-290; `playbook_live.ex` lines 223-285, 739-797; `Playbook.Store` lines 54-129.  
Validate and authorize on the server, call existing SearchPlayground/Runner/V1/Store seams, and render the actual response or write result. UI visibility is not authorization; a configured workspace path is not proof of write access. Search capture rejects an occupied filename; Playbook save overwrites by design; rename/duplicate reject collisions.

### Forms, validation, and accessible status

**Sources:** `ops_ui.ex` lines 1280-1307; both LiveViews' form handlers/rendering.  
Use HEEx, imported Phoenix.Component forms and existing OpsUi controls with stable unique IDs and native submit/Enter behavior. Associate validation with its control and keep a concise outcome/error visible. Raw payloads and diagnostics may be disclosed, but required partial/failure information remains visible.

### Async provenance and focus after patches

**Sources:** `playbook_live.ex` lines 390-457, 739-797; `ops_hooks.js` lines 420-457, 527-545.  
Snapshot source and criteria with each run ID; ignore stale completion and retain current timeout/cancel/supersede rules. For modal actions, close the invoking disclosure before opening, then return focus to a visible same-record action or the specified logical successor after the patch.

### Visual system

**Sources:** `ops_ui.ex` lines 1280-1422; `app.css` lines 1124-1185, 2016-2035.  
Use the existing token and shared component system, neutral light/dark surfaces, violet focus, quiet/disabled/busy states, and natural document flow. Keep the Search/Playbook workspace vertically staged and avoid introducing dependencies or public/core API work.

## No Analog Found

None. This phase refines existing Search and Playbook surfaces; all proposed files have a current tracked source analog.

## Metadata

**Analog search scope:** `scrypath_ops/lib/scrypath_ops_web/live/`, `components/`, `assets/js/`, `assets/css/`, `test/scrypath_ops_web/live/`, and `examples/scrypath_ecommerce/e2e/`.  
**Files scanned:** 8 direct analogs; supporting Store, V1, and Runner seams were consulted in RESEARCH.md.  
**Pattern extraction date:** 2026-10-10
