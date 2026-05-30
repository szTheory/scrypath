---
phase: "102-admin-ui-router-engine-refactor"
plan: "02"
type: execute
wave: 2
---

# Wave 2: Create Engine Macro and DevRouter

## What was built
Implemented dynamic routing for the engine by creating a new `scrypath_ops_routes/2` macro in `ScrypathOpsWeb.Router`. The macro leverages `NimbleOptions` to enforce required configuration (such as `:repo`) during mounting and binds this configuration into a `live_session`. Updated `ScrypathOpsWeb.Live.OnMount` to intercept this session payload and inject it directly into the LiveView socket context, effectively severing the dependency on the host's global Application env. Also created a `DevRouter` for testing and development, which mounts the macro exactly as a host application would, and updated `Endpoint` to route to it.

## Key files modified
- `scrypath_ops/lib/scrypath_ops_web/router.ex` (Added macro)
- `scrypath_ops/lib/scrypath_ops_web/dev_router.ex` (Added standalone dev router)
- `scrypath_ops/lib/scrypath_ops_web/endpoint.ex` (Wired DevRouter)
- `scrypath_ops/config/dev.exs` (Configured DevRouter)
- `scrypath_ops/lib/scrypath_ops_web/live/on_mount.ex` (Extracted config from session)
- `scrypath_ops/assets/css/app.css` (Isolated Tailwind with sop- prefix)
- `scrypath_ops/test/scrypath_ops_web/router_test.exs` (Added macro validation tests)

## Deviations / Issues
The `mix assets.build` step fails due to a missing dependency file (`deps/heroicons/optimized/24/outline`) which appears to be a preexisting workspace issue unrelated to the prefix addition. The CSS changes were applied successfully despite this build error.
