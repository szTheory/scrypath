---
phase: 49-visual-hierarchy-theming-and-phoenix-ergonomics
plan: "01"
status: complete
---

## Summary

- Added `ScrypathOpsWeb.OpsUi` with `ops_page_header/1`, `ops_panel/1`, and optional `ops_scaffold/1` using `Phoenix.Component` (avoids circular import with `html_helpers`).
- Imported `OpsUi` in `ScrypathOpsWeb.html_helpers/0` so all LiveViews receive the components.
- Extended `Layouts.app/1` for `shell: :ops` with assign `ops_main_width` (`:default` → `max-w-3xl`, `:wide` → `max-w-7xl`) via `main_width_classes/1`.

## Self-Check: PASSED

- `cd scrypath_ops && mix compile` succeeds.

## Key files

- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex`
- `scrypath_ops/lib/scrypath_ops_web.ex`
- `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex`
