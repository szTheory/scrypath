defmodule Mix.Tasks.Scrypath.Index.ContractDrift do
  @moduledoc """
  Compares a schema's **declared** index contract (fields, filterables, sortables,
  faceting, and declared Meilisearch settings families) against the **live** index
  via a single read-only Meilisearch `get_settings` call.

  ## Usage

      mix scrypath.index.contract_drift MyApp.Blog.Post
      mix scrypath.index.contract_drift MyApp.Blog.Post --json
      mix scrypath.index.contract_drift MyApp.Blog.Post --repo MyApp.Repo --index-prefix tenant

  ## Exit codes

    * `0` — comparison completed and every report dimension matches (`match: true`)
    * `2` — comparison completed with one or more dimensions `match: false`
    * `1` — could not complete (bad args, missing index, network, internal error)

  Exit semantics match `mix scrypath.settings.diff`: drift uses exit `2`; runtime
  failures use exit `1` via `Mix.raise/2`. The same rules apply with or without `--json`.

  ## Shell pipelines

  Use `set +e` before piping so a contract-drift exit of `2` does not abort the shell
  script; branch on `$?` afterward to distinguish parity (`0`) from drift (`2`).

  ## API

  The programmatic entry point is **`Scrypath.index_contract_drift/2`**, which returns
  `{:ok, %Scrypath.Operator.IndexContractDrift.Report{}}` or `{:error, reason}`.
  """

  @shortdoc "Read-only index contract drift report (delegates to Scrypath.index_contract_drift/2)"

  use Mix.Task

  alias Scrypath.CLI.OperatorTask
  alias Scrypath.Operator.IndexContractDrift.Report
  alias Scrypath.Operator.IndexContractDrift.Report.Dimension

  @dim_order ~w(fields filterable_attributes sortable_attributes faceting settings)a

  @extra_switches [json: :boolean]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, argv} = OperatorTask.parse!(args, @extra_switches)
    schema = OperatorTask.schema_from_argv!(argv)

    config =
      Scrypath.Config.resolve!(
        OperatorTask.runtime_opts(opts) ++ OperatorTask.test_operator_opts()
      )

    index = Scrypath.Meilisearch.index_name(schema, config)

    case Scrypath.index_contract_drift(schema, config) do
      {:ok, %Report{} = report} ->
        if report_dimensions_all_match?(report) do
          emit_parity!(schema, index, report, opts)
        else
          emit_drift_and_halt!(schema, report, opts)
        end

      {:error, reason} ->
        OperatorTask.error!("scrypath.index.contract_drift", reason)
    end
  end

  defp report_dimensions_all_match?(%Report{dimensions: dims}) do
    Enum.all?(@dim_order, fn key -> Map.fetch!(dims, key).match end)
  end

  defp emit_parity!(schema, index, report, opts) do
    if opts[:json] do
      Mix.shell().info(Jason.encode!(report))
    else
      Mix.shell().info("Index contract OK for #{inspect(schema)} (index=#{index})")
    end
  end

  defp emit_drift_and_halt!(schema, %Report{index: index} = report, opts) do
    if opts[:json] do
      Mix.shell().info(Jason.encode!(report))
      System.halt(2)
    else
      header = "INDEX CONTRACT DRIFT for #{inspect(schema)} (index=#{index})\n"
      body = format_mismatch_lines(report)
      footer = drift_footer()

      Mix.shell().info(header <> body <> "\n" <> footer <> "\n")
      System.halt(2)
    end
  end

  defp drift_footer do
    [
      "Re-run with --json for the full machine-readable report.",
      "For declared-vs-applied Meilisearch settings keys only, see mix scrypath.settings.diff.",
      "For operational sync posture and managed reindex flows, see Scrypath.reconcile_sync/2 and Scrypath.reindex/2."
    ]
    |> Enum.join("\n")
  end

  defp format_mismatch_lines(%Report{dimensions: dims}) do
    @dim_order
    |> Enum.flat_map(fn key ->
      case Map.fetch!(dims, key) do
        %Dimension{match: true} ->
          []

        %Dimension{match: false, details: details} ->
          ["  ! #{key}: #{summarize_details(details)}\n"]
      end
    end)
    |> IO.iodata_to_binary()
  end

  defp summarize_details([]), do: "mismatch (see --json)"

  defp summarize_details([%{key: k} | _]) when is_binary(k) or is_atom(k) do
    "settings detail key=#{inspect(k)}"
  end

  defp summarize_details([%{} = first | _]) do
    "mismatch #{inspect(Map.keys(first))}"
  end

  defp summarize_details(details) when is_list(details) do
    details |> Enum.take(3) |> Enum.map_join(", ", &inspect/1)
  end
end
