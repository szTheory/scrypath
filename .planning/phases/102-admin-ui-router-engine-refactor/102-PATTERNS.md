# Phase 102: Admin UI Router Engine Refactor - Pattern Map

**Mapped:** 2026-05-30
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `scrypath_ops/lib/scrypath_ops_web/router.ex` | router/macro | request-response | `scrypath_ops/lib/scrypath_ops_web/router.ex` (self) | exact |
| `scrypath_ops/lib/scrypath_ops_web/controllers/asset_controller.ex` | controller | file-I/O | `scrypath_ops/lib/scrypath_ops_web/controllers/page_controller.ex` | role-match |
| `scrypath_ops/lib/scrypath_ops_web/live/on_mount.ex` | middleware | request-response | `scrypath_ops/lib/scrypath_ops_web/live/on_mount.ex` (self) | exact |
| `scrypath_ops/lib/scrypath_ops/application.ex` | config | config | `scrypath_ops/lib/scrypath_ops/application.ex` (self) | exact |

## Pattern Assignments

### `scrypath_ops/lib/scrypath_ops_web/router.ex` (router/macro, request-response)

**Analog:** `scrypath_ops/lib/scrypath_ops_web/router.ex` (existing router layout to convert) and `scrypath_ops/lib/scrypath_ops_web.ex` (for macro pattern)

**Macro pattern** (from `scrypath_ops/lib/scrypath_ops_web.ex` lines 89-91):
```elixir
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
```

**Core Router pattern** (from `scrypath_ops/lib/scrypath_ops_web/router.ex` lines 22-30):
```elixir
  scope "/ops", ScrypathOpsWeb do
    pipe_through(:browser)

    live_session :ops, on_mount: [{ScrypathOpsWeb.Live.OnMount, :default}] do
      live("/posture", PostureLive)
      live("/failed-sync", FailedSyncLive)
      live("/sync-drift", SyncDriftLive)
      live("/search", SearchLive)
      live("/playbooks", PlaybookLive)
    end
  end
```
*Planner note: Refactor this `scope` and `live_session` into a `defmacro scrypath_ops_routes(path, opts \\ [])`. The `live_session` will inject the `opts` into the session so `on_mount` can read them.*

---

### `scrypath_ops/lib/scrypath_ops_web/controllers/asset_controller.ex` (controller, file-I/O)

**Analog:** `scrypath_ops/lib/scrypath_ops_web/controllers/page_controller.ex`

**Controller Definition pattern** (from `scrypath_ops/lib/scrypath_ops_web/controllers/page_controller.ex` lines 1-7):
```elixir
defmodule ScrypathOpsWeb.PageController do
  use ScrypathOpsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
```
*Planner note: The AssetController should use `Plug.Conn.send_download` or `Plug.Conn.put_resp_content_type` with `File.read!` on `priv/static/...` files instead of rendering a view. Ensure caching headers are set appropriately.*

---

### `scrypath_ops/lib/scrypath_ops_web/live/on_mount.ex` (middleware, request-response)

**Analog:** `scrypath_ops/lib/scrypath_ops_web/live/on_mount.ex` (self)

**on_mount pattern** (from `scrypath_ops/lib/scrypath_ops_web/live/on_mount.ex` lines 7-9):
```elixir
  def on_mount(:default, _params, _session, socket) do
    {:cont, assign(socket, :shell, :ops)}
  end
```
*Planner note: Update the `on_mount` hook to extract configuration `opts` from the `_session` (which will be populated by the `live_session` macro) and assign them to the socket for use in LiveViews.*

---

### `scrypath_ops/lib/scrypath_ops/application.ex` (config, config)

**Analog:** `scrypath_ops/lib/scrypath_ops/application.ex` (self)

**Application children pattern** (from `scrypath_ops/lib/scrypath_ops/application.ex` lines 19-25):
```elixir
    children = [
      ScrypathOpsWeb.Telemetry,
      ScrypathOps.Repo,
      {DNSCluster, query: Application.get_env(:scrypath_ops, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ScrypathOps.PubSub},
      ScrypathOpsWeb.Endpoint
    ]
```
*Planner note: The application must be modified so that `ScrypathOps.Repo` and `ScrypathOpsWeb.Endpoint` are only started if the app is running standalone (e.g. `Application.get_env(:scrypath_ops, :standalone)`), avoiding port binding conflicts when mounted as an engine in a host app.*

---

## Shared Patterns

### Configuration Injection
**Apply to:** `router.ex` (macro) and `on_mount.ex`
**Pattern:** Do NOT use `Application.get_env/3` for the engine configuration. Accept options via the `scrypath_ops_routes(path, opts \\ [])` macro, validate them with `NimbleOptions`, and pass them to the LiveView socket through `live_session` session data.

## No Analog Found

Files with no close match in the codebase:

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| Asset Controller implementation details | controller | file-I/O | There is no existing code that serves embedded static assets from `priv` dynamically. |

## Metadata

**Analog search scope:** `scrypath_ops/`
**Files scanned:** 42
**Pattern extraction date:** 2026-05-30
