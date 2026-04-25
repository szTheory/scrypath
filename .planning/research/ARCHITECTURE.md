# Architecture Research — v1.18 Sigra Integration

**Domain:** Optional auth integration for in-repo Phoenix LiveView operator app
**Researched:** 2026-04-25
**Confidence:** HIGH (all files read from source; Sigra struct fields verified from live code)

---

## 1. Module Placement — Namespace Shape

**Verdict: three independent modules, no umbrella parent in v1.**

The plan proposes `ScrypathOps.Integrations.Sigra.{OperatorContext, OnMount, Gating}`. This is the right shape. Reasons against an umbrella `ScrypathOps.Integrations.Sigra` parent that delegates or re-exports:

- The three modules have zero peer-dependencies on each other at compile time (`OperatorContext` is a struct, `OnMount` builds it, `Gating` reads it from socket assigns — no circular references).
- A parent module would only add surface area with no ergonomic gain — all three are consumed directly by distinct call sites (router `on_mount:`, `handle_event` bodies, and test files).
- The CI namespace fence (grep) is the appropriate boundary enforcement tool, not a Boundary rule or parent module.

**File placement:**

```
scrypath_ops/lib/scrypath_ops/integrations/sigra/
  operator_context.ex   # NEW
  on_mount.ex           # NEW
  gating.ex             # NEW

scrypath_ops/test/scrypath_ops/integrations/sigra/
  operator_context_test.exs   # NEW
  on_mount_test.exs           # NEW
  gating_test.exs             # NEW
```

Tests co-located under `scrypath_ops/test/` mirror the lib structure, consistent with the existing pattern at `scrypath_ops/test/scrypath_ops/playbook/` etc.

**Compile guard shape (every Sigra-referencing file):**

```elixir
if Code.ensure_loaded?(Sigra.Session) do
  defmodule ScrypathOps.Integrations.Sigra.OperatorContext do
    # ...
  end
end
```

`optional: true` in `mix.exs` controls dep-tree resolution. The compile guard controls whether the module body is evaluated. Both are required — they solve different problems.

---

## 2. OnMount Composition — Stacked Hooks Pattern

**Verdict: sibling module wired in router alongside the existing default hook.**

The existing hook is at `scrypath_ops/lib/scrypath_ops_web/live/on_mount.ex:10`:

```elixir
def on_mount(:default, _params, _session, socket) do
  {:cont, assign(socket, :shell, :ops)}
end
```

The router `on_mount:` list at `scrypath_ops/lib/scrypath_ops_web/router.ex:26`:

```elixir
live_session :ops, on_mount: [{ScrypathOpsWeb.Live.OnMount, :default}] do
```

Phoenix LiveView executes `on_mount` hooks in declaration order, each seeing the socket returned by the previous. The host adds the Sigra hook as a second entry in their router:

```elixir
# Host's router.ex (NOT in scrypath_ops/router.ex — host-owned wiring)
live_session :ops,
  on_mount: [
    {ScrypathOpsWeb.Live.OnMount, :default},
    {ScrypathOps.Integrations.Sigra.OnMount, :default}
  ] do
```

**Do not** modify the existing `ScrypathOpsWeb.Live.OnMount` to call Sigra code — that would break the compile-guard isolation. The Sigra `OnMount` module is a sibling, not a replacement or wrapper. The `:default` argument on both uses the same atom but each module pattern-matches its own `on_mount/4` independently.

**Session field propagation**: `Sigra.Plug.FetchSession` (verified at `/Users/jon/projects/sigra/lib/sigra/plug/fetch_session.ex:86`) assigns `conn.assigns[:current_scope]` and stores `%Sigra.Session{}` in `conn.private[:sigra_session]`. Phoenix 1.7+ propagates `conn.assigns` automatically into `socket.assigns` at connect time, so `socket.assigns[:current_scope]` is available in `on_mount/4`. However, `conn.private` is NOT propagated. The `%Sigra.Session{}` fields needed for `OperatorContext` (`sudo_at`, `active_organization_id`, `impersonator_user_id`) live on the session struct.

Pattern followed by Sigra's own `Sigra.LiveView.AdminScope` (at `/Users/jon/projects/sigra/lib/sigra/live_view/admin_scope.ex:16`): reads `socket.assigns[:current_scope]`. The scope struct carries `active_organization` and `impersonating_from`. `sudo_at` requires the host to serialise it into the Plug session via a custom plug before LiveView mounts. The guide must document this requirement explicitly.

**Modified files (existing):**
- `scrypath_ops/lib/scrypath_ops/security.ex:4` — add `"sigra"` to `@allowed_opsui_auth_modes`

---

## 3. Gating Helper — Action Atom Mapping

**Verdict: private `@action_config` module attribute compiled at build time. Not a registry process.**

The `gate_sensitive_action(socket, :swap_live, fn -> ... end)` signature maps action atoms to audit prefixes via a private map in `gating.ex`:

| Action atom | Audit event string | Tier |
|---|---|---|
| `:swap_live` | `"scrypath.ops.swap_live"` | 1 |
| `:delete_documents` | `"scrypath.ops.delete_documents"` | 1 |
| `:reindex` | `"scrypath.ops.reindex"` | 1 |
| `:failed_work_retry` | `"scrypath.ops.failed_work_retry"` | 2 |
| `:playbook_delete` | `"scrypath.ops.playbook_delete"` | 2 |
| `:hot_apply` | `"scrypath.ops.hot_apply"` | 2 |

No GenServer, no ETS, no runtime registration. Adding a new action requires editing `gating.ex` — the CI namespace fence will catch callers that bypass the funnel by calling `Sigra.Audit` directly from LiveView handlers.

**Funnel execution order:**

```
gate_sensitive_action(socket, action, fun)
  1. ctx = socket.assigns[:operator_context]
     if nil -> fun.() directly (Sigra not wired; no-op mode)
  2. if ctx.impersonator_user_id != nil
     -> {:noreply, put_flash(socket, :error, "Cannot perform this action while impersonating.")}
  3. sudo_age = DateTime.diff(utc_now, ctx.sudo_at, :second)
     if sudo_age > sudo_window (default 300, matching Sigra's RequireSudo default)
     -> {:noreply, push_navigate(socket, to: sudo_confirm_path, replace: false)}
  4. Process.put(:scrypath_ops_operator_context, ctx)
  5. result = fun.()
  6. Process.delete(:scrypath_ops_operator_context)
  7. Sigra.Audit.log_safe("scrypath.ops.#{action}", nil, audit_opts)
     # log_safe/3 verified at /Users/jon/projects/sigra/lib/sigra/audit.ex:143
     # no-ops when audit_schema absent — safe for hosts without audit configured
  8. result
```

The sudo confirm path is configured in `:scrypath_ops` application env (e.g., `config :scrypath_ops, :sigra_sudo_confirm_path, "/sudo/confirm"`) or passed explicitly as an option. The host owns the sudo re-auth UI — the integration owns the redirect contract.

---

## 4. Telemetry Attribution — Async Risk Assessment

**Finding: process-dict attribution is SAFE for all current sensitive actions. No async propagation risk today.**

Investigation of every handle_event and async pattern in the four gated LiveViews:

**`posture_live.ex`**: The `"refresh"` event at line 35 calls `load_posture/1` which uses `Task.async_stream/3` at line 72 — but this is READ-ONLY (`Scrypath.sync_status/2`). The swap-live action does not yet exist. When added as a new `handle_event`, it will be a synchronous call. Process-dict attribution is safe.

**`sync_drift_live.ex`**: `handle_event("refresh_reconcile")` at line 63 and `handle_event("load_drift")` at line 85 both call synchronous Scrypath functions. No async spawning. Safe.

**`failed_sync_live.ex`**: `handle_event("refresh")` at line 37 calls `refresh_inspection/1` synchronously. No retry action exists yet (it is a new handler to add). When added, it must be synchronous. Safe.

**`playbook_live.ex`**: `handle_event("confirm_delete")` at line 269 calls `Store.delete_workspace_file/2` synchronously — the only Tier 2 gated action. The `"run"` and `"run_now"` events at lines 189 and 151 use `start_async/3` at line 751, but playbook runs are NOT in the Tier 1/2 sensitive action list — they are not gated.

**Summary table:**

| LiveView | Event | Sync? | Gate target? | Attribution safe? |
|---|---|---|---|---|
| posture_live | "refresh" (Task.async_stream) | Async | No — read-only | N/A |
| posture_live | NEW "swap_live" | Will be sync | Yes | Safe |
| sync_drift_live | "refresh_reconcile" | Sync | No — read-only | N/A |
| sync_drift_live | "load_drift" | Sync | No — read-only | N/A |
| failed_sync_live | NEW "retry" | Will be sync | Yes | Safe |
| playbook_live | "confirm_delete" (line 269) | Sync | Yes | Safe |
| playbook_live | "run" / "run_now" (start_async) | Async | No — not Tier 1/2 | N/A |

**No async attribution risk for v1.18.** The guide must warn that process-dict attribution does not propagate across `Task`, `start_async`, or Oban jobs — relevant for hosts adding custom handlers.

---

## 5. Build Order — Phase Decomposition

**Verdict: 3 phases confirmed. The approved plan's decomposition is correct.**

Phases continue numbering from Phase 70 (last v1.17 phase), so v1.18 starts at Phase 71.

### Phase 71 — Integration modules + dep + allowlist + CI fence

**New files:**
- `scrypath_ops/lib/scrypath_ops/integrations/sigra/operator_context.ex`
- `scrypath_ops/lib/scrypath_ops/integrations/sigra/on_mount.ex`
- `scrypath_ops/lib/scrypath_ops/integrations/sigra/gating.ex`
- `scrypath_ops/test/scrypath_ops/integrations/sigra/operator_context_test.exs`
- `scrypath_ops/test/scrypath_ops/integrations/sigra/on_mount_test.exs`
- `scrypath_ops/test/scrypath_ops/integrations/sigra/gating_test.exs`

**Modified files:**
- `scrypath_ops/mix.exs` — add `{:sigra, "~> 0.2", optional: true}`
- `scrypath_ops/lib/scrypath_ops/security.ex:4` — add `"sigra"` to `@allowed_opsui_auth_modes`
- `.github/workflows/ci.yml` — add namespace-fence grep step in `quality` job

CI fence ships in Phase 71 because it only requires the namespace to exist (not the LiveView wiring). The fence protects the core boundary from day one.

### Phase 72 — Sensitive-action wiring in existing LiveViews

**Modified files:**
- `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex` — wrap `"confirm_delete"` at line 269 in `Gating.gate_sensitive_action/3` under `OPSUI_AUTH_MODE=sigra` guard
- `scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex` — add new `"retry"` handler gated via `Gating`
- `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex` — add new `"swap_live"` handler gated via `Gating`
- `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex` — add new `"swap_live"` handler gated via `Gating`
- LiveView test files — verify gate behaviour when `OPSUI_AUTH_MODE=sigra`

Dependency: Phase 71 must be complete (integration modules compile).

### Phase 73 — Worked example + guide + CI smoke

**New files:**
- `examples/phoenix_sigra_ops/` — complete minimal Phoenix app (see §6)
- `guides/integrations/sigra.md`

**Modified files:**
- `.github/workflows/ci.yml` — add `phoenix-sigra-ops-smoke` job

Dependency: Phase 72 must be complete (LiveView wiring exists for the example to demonstrate).

---

## 6. Worked Example Architecture

**Verdict: `mix phx.new --no-ecto --no-mailer` is wrong. Use SQLite + no-mailer.**

Sigra requires a repo (session schema, optionally audit schema). The example uses SQLite3 to avoid a Postgres service dependency in CI.

Generator: `mix phx.new phoenix_sigra_ops --no-mailer` in `examples/`, then substitute `ecto_sqlite3` for `postgrex`.

**mix.exs deps:**
- `{:scrypath_ops, path: "../.."}` — same relative path pattern as `examples/phoenix_meilisearch/`
- `{:sigra, "~> 0.2"}` — required (not optional) in the example
- `{:ecto_sqlite3, "~> 0.22"}` — SQLite for CI; no Postgres service needed

**Stub Scrypath backend**: The example's `config/config.exs` configures a `StubBackend` module implementing the internal Scrypath backend behaviour with canned `{:ok, _}` return tuples. This lets the example demonstrate the full Sigra auth + audit path without a real Meilisearch instance.

**Minimum surface to exercise end-to-end:**
- One schema module with `use Scrypath.Schema` pointing at the stub backend
- Host router wiring: `Sigra.Plug.FetchSession` in the `:browser` pipeline, both `on_mount` hooks in the live_session
- A stub sudo confirmation LiveView at `/ops/sudo-confirm` (owned by example host, not by `scrypath_ops`)
- One "sensitive action" button exercising the full `gate_sensitive_action/3` → audit path
- Impersonation test scenario using `Sigra.Testing` helpers
- `OPSUI_AUTH_MODE=sigra` set in `config/runtime.exs`

**CI job** (`phoenix-sigra-ops-smoke` in `ci.yml`):
- No Meilisearch service
- No Postgres service (SQLite)
- Runs `mix deps.get && mix test` in `examples/phoenix_sigra_ops/`
- Triggered by same path check as `scrypath-ops` job (changes to `scrypath_ops/` or `examples/`)

---

## 7. CI Integration — Namespace Fence

**Verdict: grep step in existing `quality` job; runs on every push/PR; no separate job.**

The `quality` job at `ci.yml:54` runs unconditionally on every push and PR. A grep step there is lowest friction:

```yaml
- name: Namespace fence - Sigra must not appear outside integration namespace
  run: |
    if grep -rn 'Sigra\.' lib/scrypath/ 2>/dev/null | grep -v '^\s*#'; then
      echo "FAIL: Sigra. found in lib/scrypath/ (core must stay auth-agnostic)"
      exit 1
    fi
    if grep -rn 'Sigra\.' scrypath_ops/lib/ scrypath_ops/test/ 2>/dev/null \
      | grep -v 'scrypath_ops/lib/scrypath_ops/integrations/sigra/' \
      | grep -v 'scrypath_ops/test/scrypath_ops/integrations/sigra/' \
      | grep -v '^\s*#'; then
      echo "FAIL: Sigra. reference outside integrations/sigra/ namespace"
      exit 1
    fi
    echo "Namespace fence OK"
```

Fire on **every push** — not path-gated. The fence protects the core boundary invariant; it must run unconditionally regardless of which files changed. Cost is negligible. Ships in Phase 71.

---

## Component Boundaries

| Component | File | Responsibility | Communicates With |
|---|---|---|---|
| `OperatorContext` | `integrations/sigra/operator_context.ex` | IDs-only struct; single translation point from scope/session | Built by `OnMount`; read by `Gating` |
| `OnMount` | `integrations/sigra/on_mount.ex` | Reads scope from socket assigns; builds `operator_context` assign | Phoenix LV lifecycle; `OperatorContext` |
| `Gating` | `integrations/sigra/gating.ex` | Impersonation check → sudo check → action → audit | `OperatorContext` (socket assign); `Sigra.Audit.log_safe/3`; host sudo path |
| `Security` | `scrypath_ops/security.ex:4` | `OPSUI_AUTH_MODE` allowlist | Boot validation |
| LiveViews (4) | playbook:269, failed_sync (new), posture (new), sync_drift (new) | Call `Gating.gate_sensitive_action/3` for sensitive handlers | `Gating` |
| Telemetry handler | Host-owned snippet in guide | Reads `OperatorContext` from process dict; enriches downstream events | `Process.get(:scrypath_ops_operator_context)`; `Scrypath.Telemetry.common_metadata/3:18` |
| Worked example | `examples/phoenix_sigra_ops/` | CI smoke target; end-to-end demonstration | All integration modules; stub backend |

---

## Data Flow — Sensitive Action

```
Browser event
  → handle_event/3 in LiveView
  → Gating.gate_sensitive_action(socket, :action, fn -> ... end)
      1. Read socket.assigns[:operator_context]  (nil if Sigra not active)
      2. If nil: execute fn.() directly
      3. Check impersonator_user_id != nil -> flash error, halt
      4. Check sudo_at freshness -> push_navigate to sudo confirm path
      5. Process.put(:scrypath_ops_operator_context, ctx)
      6. result = fn.()
      7. Process.delete(:scrypath_ops_operator_context)
      8. Sigra.Audit.log_safe("scrypath.ops.action", nil, audit_opts)
      9. result
  → {:noreply, socket}

[Host telemetry handler - attached at startup]
  :telemetry.attach on [:scrypath, :sync, :stop] etc.
    ctx = Process.get(:scrypath_ops_operator_context)
    emit enriched event with operator_id, org_id when ctx present
```

---

## Anti-Patterns

**Anti-Pattern 1: Calling Sigra modules directly from LiveView handlers**
What: Referencing `Sigra.Audit` or `Sigra.Session` in `playbook_live.ex` directly.
Why: Bypasses the single-funnel audit discipline; CI fence will flag it; compile guard doesn't apply.
Instead: All Sigra calls flow through `ScrypathOps.Integrations.Sigra.{Gating, OnMount, OperatorContext}`.

**Anti-Pattern 2: Wrapping `start_async` in `gate_sensitive_action`**
What: Putting an async playbook runner inside the gating funnel's `fn`.
Why: Process-dict `OperatorContext` is invisible in the spawned task. Attribution silently drops.
Instead: Gate the synchronous decision point (before `start_async`). Log audit at the decision, not in the async work. Document explicitly.

**Anti-Pattern 3: Replacing the existing `ScrypathOpsWeb.Live.OnMount`**
What: Modifying `scrypath_ops/lib/scrypath_ops_web/live/on_mount.ex` to conditionally call Sigra code.
Why: Breaks compile-guard isolation — `scrypath_ops` would fail to compile in hosts without Sigra.
Instead: Add `ScrypathOps.Integrations.Sigra.OnMount` as a second entry in the host's `live_session` `on_mount:` list.

**Anti-Pattern 4: Relying on `optional: true` alone**
What: Adding `{:sigra, "~> 0.2", optional: true}` without compile guards.
Why: `optional: true` only affects dep-tree resolution; references to `Sigra.Session` still fail to compile if the dep is absent.
Instead: Wrap every Sigra-referencing module body in `if Code.ensure_loaded?(Sigra.Session) do ... end`.

---

## Sources

- `scrypath_ops/lib/scrypath_ops_web/live/on_mount.ex:10` — existing hook
- `scrypath_ops/lib/scrypath_ops_web/router.ex:26` — live_session on_mount declaration
- `scrypath_ops/lib/scrypath_ops/security.ex:4` — `@allowed_opsui_auth_modes`
- `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:269,751` — confirm_delete and start_async
- `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex:35,72` — refresh + Task.async_stream
- `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:63,85` — event handlers
- `scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex:37` — refresh handler
- `lib/scrypath/telemetry.ex:18` — common_metadata/3 extra keyword
- `/Users/jon/projects/sigra/lib/sigra/session.ex` — %Sigra.Session{} fields: sudo_at, active_organization_id, impersonator_user_id
- `/Users/jon/projects/sigra/lib/sigra/plug/fetch_session.ex:86` — assigns current_scope and sigra_session
- `/Users/jon/projects/sigra/lib/sigra/plug/require_sudo.ex:44` — @default_sudo_window 300
- `/Users/jon/projects/sigra/lib/sigra/audit.ex:117,143` — log_safe/3; no-ops when audit_schema absent
- `/Users/jon/projects/sigra/lib/sigra/live_view/admin_scope.ex:16` — Sigra's own on_mount pattern
- `~/.claude/plans/so-i-m-considering-rippling-ladybug.md` — approved architectural plan
- `.planning/PROJECT.md` — v1.18 target features and boundary constraints

---
*Architecture research for: v1.18 Sigra integration in scrypath_ops*
*Researched: 2026-04-25*
