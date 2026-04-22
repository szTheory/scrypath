# Phase 60 — Pattern Map

Analogs and excerpts for files Phase 60 will create or extend.

---

## 1. `ScrypathOpsWeb.PlaybookLive` (new)

**Role:** Dedicated `/ops/playbooks` LiveView — list, import, load preview, run, save, delete.

**Closest analog:** `scrypath_ops/lib/scrypath_ops_web/live/search_live.ex` — `Layouts.app` with `shell={:ops}`, honesty banner, `SearchPlayground` dispatch, `format_run_error` style alerts.

**Excerpt (honesty strip pattern):**

```274:290:scrypath_ops/lib/scrypath_ops_web/live/search_live.ex
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} shell={@shell} ops_main_width={:wide}>
      <div class="space-y-6">
        <.ops_page_header title={@page_title} />

        <div
          id="search-honesty-panel"
          class="rounded-md border border-warning/40 bg-warning/10 px-sm py-sm text-sm text-base-content"
        >
          <strong>Non-production search playground</strong>
          — exploratory queries may be logged by Meilisearch or proxies depending on deployment.
```

**PlaybookLive** should use **`60-UI-SPEC.md`** copy: title **Non-production playbook workspace** (not reusing search wording verbatim).

---

## 2. Router + `live_session :ops`

**File:** `scrypath_ops/lib/scrypath_ops_web/router.ex`

**Pattern:** Add `live("/playbooks", PlaybookLive)` beside existing lives inside `live_session :ops, on_mount: ...`.

```23:31:scrypath_ops/lib/scrypath_ops_web/router.ex
  scope "/ops", ScrypathOpsWeb do
    pipe_through(:browser)

    live_session :ops, on_mount: [{ScrypathOpsWeb.Live.OnMount, :default}] do
      live("/posture", PostureLive)
      live("/failed-sync", FailedSyncLive)
      live("/sync-drift", SyncDriftLive)
      live("/search", SearchLive)
    end
  end
```

---

## 3. `ScrypathOpsWeb.Nav.primary/0`

**File:** `scrypath_ops/lib/scrypath_ops_web/nav.ex`

**Pattern:** Ordered list of `%{path: ~p"/ops/...", label: "..."}` — append **Saved playbooks** after search per **D-15**.

```19:26:scrypath_ops/lib/scrypath_ops_web/nav.ex
  def primary do
    [
      %{path: ~p"/ops/posture", label: "Posture / health"},
      %{path: ~p"/ops/failed-sync", label: "Failed sync work"},
      %{path: ~p"/ops/sync-drift", label: "Sync / drift"},
      %{path: ~p"/ops/search", label: "Search & federation"}
    ]
  end
```

---

## 4. Runtime env → `Application.get_env`

**File:** `scrypath_ops/config/runtime.exs`

**Pattern:** `case System.get_env("SCRYPATH_OPS_...")` → `Application.put_env(:scrypath_ops, :key, value)` (see existing `SCRYPATH_OPS_SCHEMAS` block).

---

## 5. LiveView tests + stub adapter

**Files:** `scrypath_ops/test/scrypath_ops_web/live/search_live_test.exs`, `scrypath_ops/test/support/search_playground_stub_adapter.ex`

**Pattern:** `setup` saves/restores `Application.get_env(:scrypath_ops, ...)`; uses **`SearchPlaygroundStubAdapter`** for network-free runs.

---

## PATTERN MAPPING COMPLETE

