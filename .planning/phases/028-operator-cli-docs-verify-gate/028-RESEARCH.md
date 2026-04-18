# Phase 28 — Technical research

**Question:** What do we need to know to plan Mix CLI, docs, and `mix verify.phase28` well?

## Findings

### Mix task shape (OPS15-02)

- **Module:** `Mix.Tasks.Scrypath.Index.ContractDrift` → invocation **`mix scrypath.index.contract_drift`** (nested task namespace under `lib/mix/tasks/scrypath/index/contract_drift.ex`).
- **Pattern source:** `lib/mix/tasks/scrypath.settings.diff.ex` — `Mix.Task.run("app.start")`, `OperatorTask.parse!(args, [json: :boolean])`, `OperatorTask.schema_from_argv!(argv)`, `Config.resolve!(OperatorTask.runtime_opts(opts) ++ OperatorTask.test_operator_opts())`, drift path ends with `System.halt(2)`, parity prints and returns normally (exit 0).
- **API delegate:** `Scrypath.index_contract_drift/2` → `Operator.index_contract_drift/2` → `IndexContractDrift.build/2`; returns `{:ok, %Report{}} | {:error, term()}`.
- **Drift detection:** `%Report{dimensions: %{...}}` — each value is `%Dimension{match: boolean(), details: ...}`. Contract is “OK” only when **all** five keys (`:fields`, `:filterable_attributes`, `:sortable_attributes`, `:faceting`, `:settings`) have `match: true`. Any `match: false` → exit **2** (same bucket as `settings.diff` drift).
- **JSON:** `Jason.encode!/1` on `%Report{}` (encoder already implemented). `--json` must still use **same exit codes** as human mode (028-CONTEXT D-05).
- **Human output (028-CONTEXT D-07–D-09):** One-line header (schema + index UID); print **only** dimensions with `match: false` (compact lines referencing dimension name + truncated details); explicit **parity** line when all match (never empty success); short footer pointing to `--json` and cross-refs to `settings.diff` / reconcile / reindex **without** new verbs.

### Verify gate (OPS15-04)

- **Template:** `lib/mix/tasks/verify.phase26.ex` — `Mix.Tasks.Verify.Phase26`, `@shortdoc`, `@focused_tests` list, `Mix.Task.run("test", paths ++ ["--warnings-as-errors"])`, then `Mix.Task.run("docs", ["--warnings-as-errors"])`, `ensure_no_args!/1`.
- **Registration:** `mix.exs` `def cli` → `preferred_envs` needs **`"verify.phase28": :test`** and **`"scrypath.index.contract_drift": :test`** (mirror `scrypath.settings.diff`).
- **Focused tests (minimum):** `test/scrypath/operator/index_contract_drift_test.exs`, extended **`test/scrypath/mix_tasks/operator_tasks_test.exs`** (or dedicated test module) for the new Mix task, `test/scrypath/docs_contract_test.exs` — keep gate **auth-free** (no `HEX_API_KEY` in verify task source).

### Docs (OPS15-03)

- **`guides/drift-recovery.md`:** Add a subsection (or extend “Settings drift”) distinguishing **Meilisearch settings keys** (`mix scrypath.settings.diff`, `Scrypath.reindex/2`, `hot_apply`) vs **full index contract** (fields, filterable, sortable, faceting + settings families) via **`mix scrypath.index.contract_drift`** / `Scrypath.index_contract_drift/2`; cross-link `docs/operator-support.md`.
- **`docs/operator-support.md`:** Insert **contract drift** into the first-response ordering; refresh the **mix verify.*** table: add **`mix verify.phase28`** as the v1.5 operator/doc slice for index-contract CLI + docs contract; avoid implying phase14 is the only doc gate for this concern (028-CONTEXT D-12).
- **`guides/operator-mix-tasks.md`:** Document the new task alongside other `scrypath.*` commands if the guide lists them exhaustively.

### Pitfalls

- **Do not** use `Mix.raise` for drift (exit 1); use **`System.halt(2)`** after emitting drift output, matching `settings.diff`.
- **`OperatorTask.error!`** wraps `Mix.raise` → exit **1** for `:index_not_found`, bad args, network errors — correct for “could not complete comparison”.
- **Tests:** Reuse `Application.put_env(:scrypath, :operator_task_test_opts, ...)` + stub client patterns from `operator_tasks_test.exs` and `index_contract_drift_test.exs` rather than live Meilisearch.

## Validation Architecture

Nyquist / execution sampling for this phase:

- **Framework:** ExUnit (`mix test`), no extra install.
- **Quick loop:** `mix format --check-formatted && mix compile --warnings-as-errors` after each Mix/library edit.
- **Plan-level:** After each plan: run the verification `<automated>` block from that plan’s last task.
- **Gate:** `mix verify.phase28` (auth-free) is the milestone contract check before UAT / merge handoff.
- **Dimension 8:** Every plan task lists grep-able acceptance criteria; contract drift CLI behavior is covered by focused tests referenced in `028-VALIDATION.md`.

## RESEARCH COMPLETE
