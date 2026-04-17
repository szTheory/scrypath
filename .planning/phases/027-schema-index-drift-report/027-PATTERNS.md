# Phase 27 — Pattern map

Analogs for executor `read_first` chains.

| New / touched role | Closest existing analog | Excerpt / pattern |
|--------------------|-------------------------|-------------------|
| Operator `{:ok, struct} \| {:error, _}` + opts split | `lib/scrypath/operator.ex` — `failed_sync_work/2`, `reconcile_sync/2` | `Keyword.split(opts, @operator_only_opts)` then `Config.resolve!` |
| Versioned operator JSON struct | `lib/scrypath/operator/reason_class_counts.ex` | `@enforce_keys`, `Jason.Encoder`, `Jason.OrderedObject` |
| Additive optional field on `%Reconcile{}` | `lib/scrypath/operator/reconcile.ex` | `failed_work_counts` outside `@enforce_keys` list but in defstruct |
| Settings declared-vs-applied | `lib/scrypath/meilisearch/settings.ex` — `verify_applied/3`, `compute_drift/2` | Single `get_settings` then `compute_drift(declared_wire, applied_wire)` |
| Public `Scrypath.*` delegate | `lib/scrypath.ex` — `failed_sync_work`, `reconcile_sync` | One-line delegate to `Operator` |
| Mix settings drift (reference only) | `lib/mix/tasks/scrypath.settings.diff.ex` | Phase 28 CLI; Phase 27 reuses same `Settings` primitives |
