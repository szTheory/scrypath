# Phase 45 — Technical research

**Question:** What do we need to know to plan posture, failed-sync, and sync/drift LiveViews well?

## Library contracts (planning anchors)

- **`Scrypath.sync_status/2`** delegates to **`Scrypath.Operator.sync_status/2`**; operator-only opts are split in **`Scrypath.Operator`** via `@operator_only_opts` (`:meilisearch_tasks`, `:oban_jobs`, `:oban_inspector`, `:target_index`, `:reason_class_counts`, `:include_index_contract_drift`). Runtime opts go through **`Config.resolve!/1`**.
- **`Scrypath.failed_sync_work/2`** with **`reason_class_counts: true`** returns **`{:ok, %FailedSyncWorkInspection{entries: rows, counts: FailedWork.reason_class_counts(rows)}}`** — single snapshot invariant (CONTEXT D-09).
- **`Scrypath.reconcile_sync/2`** vs **`index_contract_drift/2`**: `@doc` on **`lib/scrypath.ex`** stresses **`include_index_contract_drift: true`** performs extra **`get_settings`** and can fail the whole reconcile; default OPS path must **not** use combined flag for interactive load (CONTEXT D-15).
- **`%Scrypath.Operator.Status{}`**, **`%FailedWork{}`**, **`%Reconcile{}`**, **`IndexContractDrift.Report`** — field names and `queue.observed?` semantics live in respective modules under **`lib/scrypath/operator/`**.

## Phoenix / LiveView patterns

- **Bounded concurrency:** `Task.async_stream(modules, fn mod -> {mod, Scrypath.sync_status(mod, opts)} end, max_concurrency: 3, timeout: 15_000)` (exact numbers are discretion) with overall `receive` deadline or `Task.yield_many` pattern to meet CONTEXT D-07.
- **Tab-visible polling:** `phx-hook` or `PageLifecycle` / `visibilitychange` via small JS hook in `assets/js` — only if implementing auto-refresh; acceptable to ship manual-only first with TODO for hook.
- **Testing:** **`Phoenix.LiveViewTest`** with **`ConnCase`**; pass operator fakes through **`Scrypath`** public APIs using documented operator opts (CONTEXT D-20). Prefer **`Mox`** or inline anonymous MFA stubs if existing tests establish a pattern — grep **`scrypath_ops`** and **`examples/phoenix_meilisearch`** test trees before implementing.

## Config allowlist

- Add **`config :scrypath_ops, :schema_allowlist, [Module, ...]`** (exact key is planner/impl discretion) read at runtime in LiveViews; **document** in **`scrypath_ops/README.md`** and **`config/runtime.exs`** for prod env override. Empty allowlist → honest empty state with link to README (no silent fallback to `Code.all_loaded/0`).

## CLI parity references

- **`guides/operator-mix-tasks.md`** — columns and flags for **`mix scrypath.failed`**, **`mix scrypath.status`**.
- **`mix scrypath.failed`** default sort = newest first (verify in **`lib/mix/tasks`** if planning sort keys).

## Pitfalls

- **Rollup desync:** Never derive `reason_class` totals from paginated `entries` alone; always from `counts` on the inspection struct.
- **High-cardinality Telemetry:** Do not attach schema module name to `:telemetry` events fired on interval tick.
- **Conflated drift:** UI copy must separate reconcile **`drift_signals`** from index contract drift (CONTEXT D-16).

## Validation Architecture

Execution should prove:

1. **Unit-ish / LiveView:** With injected operator backends, each LiveView renders **success**, **empty allowlist**, and **representative error** paths without calling real Meilisearch.
2. **Compile:** `cd scrypath_ops && mix test` (or scoped test files) green in CI when phase 47 wires it; phase 45 plans should add tests under **`scrypath_ops/test/`** and document **`mix test`** as the quick command from the ops app root.
3. **Manual smoke:** Operator opens `/ops/posture` with allowlist pointing at a known example schema in dev — optional checklist in VALIDATION.md.

Nyquist Dimension 8 maps to **automated ExUnit** for new modules plus **grep-verifiable** copy anchors (doc links) in HEEx templates.

## RESEARCH COMPLETE

Planning can proceed with **`45-CONTEXT.md`**, this file, and **`45-UI-SPEC.md`**.
