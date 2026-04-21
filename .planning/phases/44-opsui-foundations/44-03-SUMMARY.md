---
phase: 44
plan: "03"
status: complete
---

# Plan 44-03 — `/ops` LiveView shell

## Outcome

- **`live_session :ops`** with **`on_mount: [{ScrypathOpsWeb.Live.OnMount, :default}]`** wraps four stub LiveViews under **`scope "/ops", ScrypathOpsWeb`**.
- **`Layouts.app/1`** gained an **`:ops`** shell with **`~p`** primary nav links (no **`href="#"`**), **`flash_group`** with **`id="flash-group"`**, and headings matching **`operator-ia.md`** nav labels.
- **`operator-ia.md`** route column uses **`/ops/...`** paths aligned with **`router.ex`**.

## Key files

- `scrypath_ops/lib/scrypath_ops_web/router.ex`
- `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex`
- `scrypath_ops/lib/scrypath_ops_web/components/layouts/root.html.heex`
- `scrypath_ops/lib/scrypath_ops_web/live/*.ex`
- `scrypath_ops/docs/operator-ia.md`

## Self-Check: PASSED
