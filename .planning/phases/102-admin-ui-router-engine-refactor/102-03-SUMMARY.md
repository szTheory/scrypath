---
phase: "102-admin-ui-router-engine-refactor"
plan: "03"
type: execute
wave: 3
---

# Wave 3: Remove Static Verified Routes and Fix Navigation

## What was built
Removed static verified routes (`~p`) tied to a specific router. Refactored internal navigation within the engine to rely completely on the dynamically injected `:mount_path` (or `@mount_path` in templates) provided by the `scrypath_ops_routes` macro.

## Key files modified
- `scrypath_ops/lib/scrypath_ops_web.ex` (Removed `verified_routes()` import)
- `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex` (Updated `app` function component to require `mount_path`)
- `scrypath_ops/lib/scrypath_ops_web/live/search_live.ex` (Replaced `~p` with string interpolation)
- `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex` (Replaced `~p` with string interpolation)
- `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex` (Replaced `~p` with string interpolation and fixed `jtbd_state/3` arity)
- `scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex` (Passed `mount_path` to Layouts.app)
- `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex` (Passed `mount_path` to Layouts.app)
- `scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs` (Updated test socket with `mount_path`)
- `scrypath_ops/test/scrypath_ops_web/router_test.exs` (Fixed AST match for macro expansion)

## Deviations
Since `<Layouts.app>` is invoked directly as a component rather than relying on Phoenix LiveView's `layout: {Layouts, :app}`, it was necessary to explicitly pass `mount_path={@mount_path}` in every LiveView template rendering the layout. This ensures the root and app templates always have the correct dynamic path regardless of test or dev environments.
