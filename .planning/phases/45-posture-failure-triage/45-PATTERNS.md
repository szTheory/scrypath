# Phase 45 — Pattern map

Analogues and excerpts for executors (from CONTEXT + repo scan).

## Shell / routing

| New / touched | Analog | Notes |
|---------------|--------|-------|
| `scrypath_ops/lib/scrypath_ops_web/live/*_live.ex` | `posture_live.ex`, `failed_sync_live.ex`, `sync_drift_live.ex` (stubs) | Replace stub `render/1` only; keep `Layouts.app` + `shell={@shell}`. |
| `scrypath_ops/lib/scrypath_ops_web/router.ex` | unchanged routes | No new `/ops` routes in phase 45. |

## Library usage

| Concern | Source of truth |
|---------|-----------------|
| Public operator entrypoints | `lib/scrypath.ex` — `sync_status/2`, `failed_sync_work/2`, `reconcile_sync/2`, `index_contract_drift/2` |
| Operator opt split | `lib/scrypath/operator.ex` — `@operator_only_opts` |
| Status shape | `lib/scrypath/operator/status.ex` — `%Status{schema:, mode:, index:, backend:, queue:}` |
| Failed inspection | `lib/scrypath/operator/failed_sync_work_inspection.ex` |
| Reconcile + optional drift | `lib/scrypath/operator/reconcile.ex` |

## Phoenix reference

| Pattern | Analog |
|---------|--------|
| LiveView + layout | `scrypath_ops/lib/scrypath_ops_web/live/on_mount.ex`, phase 44 LiveViews |
| Example integration | `examples/phoenix_meilisearch/lib/scrypath_demo/blog/post.ex` (`use Scrypath`) — **reference** for allowlist module names in README only |

## PATTERN MAPPING COMPLETE
