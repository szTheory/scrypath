# Deferred Items

## Plan 135-02

- `mix precommit` rewrote formatter-only changes in unrelated ScrypathOps files outside this
  plan's scope: `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex`,
  `scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex`,
  `scrypath_ops/lib/scrypath_ops_web/live/search_live.ex`, and
  `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex`. The check passed, then those
  unrelated working-tree deltas were discarded by explicit path to keep Plan 135-02 scoped.
