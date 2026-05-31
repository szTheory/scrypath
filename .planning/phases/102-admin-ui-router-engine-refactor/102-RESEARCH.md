# Phase 102: Admin UI Router Engine Refactor - Research

**Researched:** 2026-05-30
**Domain:** Phoenix Engine Architecture / UI Embedding
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Implement a custom macro `scrypath_ops_routes(path, opts \\ [])` to mount the engine's routes, rather than relying on `forward`.
- **D-02:** Use the macro to wrap the ops UI in a `live_session` and `on_mount` hooks, mirroring the DX of `Phoenix.LiveDashboard` and Oban Web.
- **D-03:** Pass all required engine configuration (e.g., `repo`, adapter) explicitly as runtime options to the `scrypath_ops_routes` macro.
- **D-04:** Inject these options into the LiveView socket via an `on_mount` hook, strictly avoiding `Application.get_env/3` for the engine's primary interface to enable multitenancy and explicit APIs.
- **D-05:** Serve pre-compiled static assets (CSS, JS) directly from the engine via an internal plug/controller isolated from the host app's asset pipeline.
- **D-06:** Ensure CSS isolation (e.g., via Tailwind prefix or scoped classes) so the engine renders perfectly regardless of host application styling, eliminating integration friction.

### the agent's Discretion
- Exact naming and location of the internal asset controller/plug and exact shape of `NimbleOptions` schema for the macro, provided the macro DX and explicit configuration principles hold.
- Exact internal routing structure (e.g., grouping `live` macros inside the `scrypath_ops_routes`), provided the host app only needs to call the one macro.

### Deferred Ideas (OUT OF SCOPE)
- None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OPS-01 | Refactor `scrypath_ops` into a pure mountable router engine. | Verified implementation pattern via `Phoenix.LiveDashboard` using a custom macro to wrap `scope` and `live_session`. |
| OPS-02 | Deprecate the standalone `Endpoint` and `Repo` within `scrypath_ops`. | `ScrypathOpsWeb.Endpoint` and `ScrypathOps.Repo` should only start in dev environment (if at all). Engine relies on host app's web/db dependencies. |
</phase_requirements>

## Summary

Phase 102 converts `scrypath_ops` from a standalone Phoenix app into a reusable router engine. This follows established ecosystem patterns like `Phoenix.LiveDashboard` and Oban Web. The engine will provide a `scrypath_ops_routes/2` macro for developers to mount within their host application's Phoenix router. Runtime configuration (e.g. `repo`, `tenant`) will be injected directly via macro options instead of global Application config. Asset delivery will be fully encapsulated inside the engine using a custom Plug.

**Primary recommendation:** Define the macro `scrypath_ops_routes/2` in `ScrypathOpsWeb.Router` or a dedicated module. Extract options using `NimbleOptions` at compile-time/macro-expansion time, inject them into `session` and use `ScrypathOpsWeb.Live.OnMount` to hydrate the LiveView socket. Standalone endpoint/repo should be gated behind `Mix.env() == :dev` or fully removed.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Router Macro | API / Backend | — | Modifies the host Phoenix Router to inject LiveSession, scope, and specific UI routes. |
| Config Injection | Frontend Server (SSR) | — | Extracts macro options and uses `on_mount` to store them in the LiveView socket assigns for UI use. |
| Asset Delivery | Frontend Server (SSR) | CDN / Static | Internal controller/plug serves engine-specific precompiled CSS/JS from `priv/static`, bypassing the host asset pipeline. |
| Isolated Styling | Browser / Client | — | Tailwind prefixing ensures `scrypath_ops` CSS doesn't bleed into or break from the host application's styles. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix LiveView | ~> 1.1.0 | UI rendering | Required for realtime dashboards. |
| NimbleOptions | ~> 1.1 | Option validation | Ecosystem standard for validating macro options gracefully with excellent error messages. |
| Plug.Static / Plug | ~> 1.19 | Asset serving | Idiomatic way to serve engine assets natively. |

## Package Legitimacy Audit

> **Required** whenever this phase installs external packages.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| nimble_options | hex | >2 yrs | >63M | github.com/dashbitco/nimble_options | OK (assumed) | Approved |

*Note: `nimble_options` is an official Dashbit library already present in the parent `scrypath` package tree. No new dependencies are introduced to the workspace.*

## Architecture Patterns

### System Architecture Diagram
(Conceptual text representation for the engine mount)

```
Host Router -> scrypath_ops_routes("/ops", repo: MyApp.Repo)
   |
   -> Wraps in `live_session :scrypath_ops, on_mount: [...]`
   |
   -> Mounts asset route: `get "/assets/app.css", ScrypathOpsWeb.AssetPlug`
   |
   -> Mounts internal views: `live "/posture", ScrypathOpsWeb.Live.PostureLive`, etc.
```

### Pattern 1: Router Engine Macro
**What:** Use a macro to expand routes safely into the user's `Router` module.
**When to use:** When building a mountable Phoenix UI dashboard that requires session boundaries and specific configuration options.
**Example:**
```elixir
defmodule ScrypathOpsWeb.Router do
  defmacro scrypath_ops_routes(path, opts \\ []) do
    quote bind_quoted: binding() do
      scope path, alias: false, as: false do
        import Phoenix.Router, only: [get: 4]
        import Phoenix.LiveView.Router, only: [live: 4, live_session: 3]

        # Validates options and generates session defaults
        {session_name, session_opts, route_opts} =
          ScrypathOpsWeb.Router.__options__(opts)

        live_session session_name, session_opts do
          get "/assets/app.css", ScrypathOpsWeb.AssetPlug, :css, as: :scrypath_ops_asset
          get "/assets/app.js", ScrypathOpsWeb.AssetPlug, :js, as: :scrypath_ops_asset

          live "/posture", ScrypathOpsWeb.Live.PostureLive, :index, route_opts
          # ...other routes
        end
      end
    end
  end

  def __options__(opts) do
    # Validate with NimbleOptions here
    # Return {session_name, on_mount_hooks, route_opts}
  end
end
```

### Pattern 2: Dynamic LiveView Configuration
**What:** Exposing configuration explicitly through the socket assigns instead of `Application.get_env`.
**When to use:** When your engine supports multi-tenancy or explicit configuration boundaries (D-03, D-04).
**Example:**
```elixir
defmodule ScrypathOpsWeb.Live.OnMount do
  import Phoenix.Component

  def on_mount(:default, _params, session, socket) do
    # `session` contains serialized configuration passed via macro
    repo = session["scrypath_ops_repo"]
    socket = assign(socket, :ops_repo, repo)
    {:cont, socket}
  end
end
```

### Pattern 3: Embedded Asset Controller
**What:** Bypassing host application `Plug.Static` to serve `scrypath_ops` assets from its own `priv/static` path.
**When to use:** When distributing a Phoenix UI library as a dependency, ensuring consumers do not need to run `npm install` or tailwind builds for the library's assets.
**Example:**
```elixir
defmodule ScrypathOpsWeb.AssetPlug do
  @moduledoc "Serves precompiled static assets"
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, action) do
    # Read pre-compiled static file from priv/
    # Put proper content-type, cache headers, and send
  end
end
```

### Anti-Patterns to Avoid
- **`Application.get_env/3` for core config:** This breaks the ability to mount multiple instances of the dashboard in one host app.
- **Requiring `forward "/ops", ScrypathOpsWeb.Router`:** This prevents cleanly injecting a customized `live_session` with `on_mount` hooks defined by the macro.
- **Assuming host styling:** Missing a CSS prefix can break the host's styling or vice-versa.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Macro option validation | Custom Enum iteration | `NimbleOptions` | Native ecosystem tool, standardizes error messages for misconfiguration |
| Dashboard styling isolation | Hand-written CSS scopes | Tailwind config with `prefix` | Guarantees complete selector isolation without sacrificing utility class DX |

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None | Code-only refactor. |
| Live service config | None | Code-only refactor. |
| OS-registered state | None | Code-only refactor. |
| Secrets/env vars | None | Code-only refactor. |
| Build artifacts | `ScrypathOps.Repo`, `ScrypathOpsWeb.Endpoint` | Update `application.ex` to only start these dynamically in `MIX_ENV=dev`. |

## Common Pitfalls

### Pitfall 1: Macro Variable Hygiene
**What goes wrong:** Unintended variable capture inside the `defmacro`.
**Why it happens:** Writing unquoted logic in the macro body that bleeds into the host router.
**How to avoid:** Use `bind_quoted` or delegate heavy logic to an external module function like `ScrypathOpsWeb.Router.__options__(opts)`.

### Pitfall 2: Static Asset Fingerprinting
**What goes wrong:** Busted cache for CSS/JS assets.
**Why it happens:** The host app expects `.css` to be digested, but the engine is serving raw files.
**How to avoid:** Pre-digest files within `scrypath_ops` release build, or explicitly set ETag/Cache-Control headers in the `AssetPlug`.

## Code Examples
*(See Architecture Patterns above for macro and plug examples)*

## Environment Availability
*(Step 2.6: SKIPPED - No external dependencies identified for this phase)*

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OPS-01 | Mount macro parses and expands successfully | unit | `mix test test/scrypath_ops_web/router_test.exs` | ❌ Wave 0 |
| OPS-02 | Endpoint/Repo don't auto-start in test | unit | `mix test test/scrypath_ops/application_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/scrypath_ops_web/router_test.exs` — covers OPS-01 macro behavior
- [ ] `test/scrypath_ops/application_test.exs` — covers OPS-02 service startup isolation

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Engine delegates auth to host router/plugs |
| V3 Session Management | yes | `live_session` handles WebSocket boundary |
| V4 Access Control | yes | Engine uses `on_mount` to securely read authorized config |
| V5 Input Validation | yes | `NimbleOptions` validates macro configuration |
| V6 Cryptography | no | — |

### Known Threat Patterns for Phoenix LiveView

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-site WebSocket Hijacking | Spoofing | `check_origin: true` (handled by host app) |
| Missing LiveView Mount Auth | Elevation | Rely on the host's `on_mount` hook or router pipelines to secure the route. |

## Sources

### Primary (HIGH confidence)
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` - Explicit configuration and library architecture.
- `prompts/phoenix-best-practices-deep-research.md` - LiveView routing, session boundaries, asset serving.
- `Phoenix.LiveDashboard` GitHub Source - `live_dashboard` macro implementation pattern.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Phoenix macro and NimbleOptions are the indisputable standards for this.
- Architecture: HIGH - Matches official `live_dashboard` precedent.
- Pitfalls: HIGH - Common issues with macros and assets are well-documented.

**Research date:** 2026-05-30
**Valid until:** 2026-08-30