defmodule Mix.Tasks.Scrypath.Failed do
  use Mix.Task

  alias Scrypath.CLI.OperatorTask
  alias Scrypath.Operator.FailedSyncWorkInspection

  @shortdoc "Lists failed or retrying sync work for one Scrypath schema"

  @moduledoc """
  Lists Scrypath-owned failed-work entries for one searchable schema.

  ## Read next

  - [guides/golden-path.md](guides/golden-path.md) — first-hour checklist from dependencies through search.
  - [guides/sync-modes-and-visibility.md](guides/sync-modes-and-visibility.md) — authority on sync modes, eventual consistency, and operator lifecycle language.

  ## Flags

  - **`--json`** — print a single JSON document to stdout (no `Mix` shell lines).
  - **`--no-class-summary`** — hide the per-class rollup header on the default human path.
  """

  @extra_switches [json: :boolean, no_class_summary: :boolean]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, argv} = OperatorTask.parse!(args, @extra_switches)
    schema = OperatorTask.schema_from_argv!(argv)

    json? = Keyword.get(opts, :json, false)
    no_class_summary? = Keyword.get(opts, :no_class_summary, false)

    runtime_opts =
      opts
      |> Keyword.drop([:json, :no_class_summary])
      |> OperatorTask.runtime_opts()

    full_opts =
      runtime_opts ++ OperatorTask.task_history_opt(opts) ++ OperatorTask.test_operator_opts()

    if json? do
      case Scrypath.failed_sync_work(schema, full_opts ++ [reason_class_counts: true]) do
        {:ok, %FailedSyncWorkInspection{entries: rows}} ->
          IO.puts(OperatorTask.failed_work_cli_json(schema, rows))

        {:ok, _} ->
          OperatorTask.error!(
            "scrypath.failed",
            :unexpected_shape_for_json_path
          )

        {:error, reason} ->
          OperatorTask.error!("scrypath.failed", reason)
      end
    else
      case Scrypath.failed_sync_work(schema, full_opts) do
        {:ok, failed_work} ->
          Mix.shell().info(
            OperatorTask.render_failed_work(schema, failed_work,
              include_class_summary: not no_class_summary?
            )
          )

        {:error, reason} ->
          OperatorTask.error!("scrypath.failed", reason)
      end
    end
  end
end
