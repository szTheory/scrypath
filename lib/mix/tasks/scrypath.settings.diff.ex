defmodule Mix.Tasks.Scrypath.Settings.Diff do
  @moduledoc """
  Diffs declared-vs-applied Meilisearch settings for one Scrypath schema.

  ## Usage

      mix scrypath.settings.diff MyApp.Blog.Post
      mix scrypath.settings.diff MyApp.Blog.Post --json
      mix scrypath.settings.diff MyApp.Blog.Post --repo MyApp.Repo --index-prefix tenant

  ## Exit codes

    * `0` — no drift (declared settings match applied)
    * `2` — drift detected (one or more declared keys diverge or are missing)
    * `1` — runtime error (index not found, network failure, bad schema arg)

  TUNE-07.
  """

  @shortdoc "Diffs declared-vs-applied Meilisearch settings for one Scrypath schema"

  use Mix.Task

  alias Scrypath.CLI.OperatorTask
  alias Scrypath.Meilisearch.Client
  alias Scrypath.Meilisearch.Settings

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

    case Settings.verify_applied(schema, index, config) do
      :ok ->
        emit_parity(schema, index, opts)

      {:error, {:settings_drift, drift}} ->
        declared = Settings.resolve(schema, config) |> Settings.translate_settings()

        case Client.get_settings(index, config) do
          {:ok, applied} ->
            emit_drift_and_halt!(schema, index, declared, applied, drift, opts)

          {:error, reason} ->
            OperatorTask.error!("scrypath.settings.diff", reason)
        end

      {:error, :index_not_found} ->
        OperatorTask.error!("scrypath.settings.diff", :index_not_found)

      {:error, reason} ->
        OperatorTask.error!("scrypath.settings.diff", reason)
    end
  end

  @doc false
  def compute(declared_wire, applied_wire) when is_map(declared_wire) and is_map(applied_wire) do
    case Settings.compute_drift(declared_wire, applied_wire) do
      [] -> :parity
      drift -> {:drift, drift}
    end
  end

  @doc false
  def render_json(schema, index, status, declared, applied, drift, error \\ nil) do
    drift_json =
      case drift do
        [] ->
          "[]"

        _ ->
          drift
          |> Enum.map(fn {k, d, a} ->
            Jason.encode!(%{"key" => to_string(k), "declared" => d, "applied" => a})
          end)
          |> then(&("[\n  " <> Enum.join(&1, ",\n  ") <> "\n]"))
      end

    parts = [
      ~s("schema": #{Jason.encode!(inspect(schema))}),
      ~s("index": #{Jason.encode!(index)}),
      ~s("status": #{Jason.encode!(Atom.to_string(status))}),
      ~s("declared": #{Jason.encode!(stringify_keys(declared))}),
      ~s("applied": #{Jason.encode!(stringify_keys(applied))}),
      ~s("drift": #{drift_json})
    ]

    parts =
      if is_nil(error) do
        parts
      else
        parts ++ [~s("error": #{Jason.encode!(to_string(error))})]
      end

    "{\n  " <> Enum.join(parts, ",\n  ") <> "\n}"
  end

  @doc false
  def render_table(schema, index, _declared, _applied, []) do
    "No drift detected for #{inspect(schema)} (index=#{index})\n"
  end

  def render_table(schema, index, _declared, _applied, drift) when is_list(drift) do
    header = "DRIFT for #{inspect(schema)} (index=#{index})\n\n"

    rows =
      Enum.map(drift, fn {k, declared_value, applied_value} ->
        "  ! #{k}\n    declared: #{inspect(declared_value)}\n    applied:  #{inspect(applied_value)}\n"
      end)

    header <>
      Enum.join(rows, "\n") <>
      "\nSet settings: %{...} on the schema OR run `mix scrypath.reindex #{inspect(schema)}` to re-apply.\n"
  end

  defp emit_parity(schema, index, opts) do
    output =
      if opts[:json] do
        render_json(schema, index, :parity, %{}, %{}, [])
      else
        render_table(schema, index, %{}, %{}, [])
      end

    Mix.shell().info(output)
  end

  @spec emit_drift_and_halt!(module(), String.t(), map(), map(), list(), keyword()) :: no_return()
  defp emit_drift_and_halt!(schema, index, declared, applied, drift, opts) do
    output =
      if opts[:json] do
        render_json(schema, index, :drift, declared, applied, drift)
      else
        render_table(schema, index, declared, applied, drift)
      end

    Mix.shell().info(output)
    System.halt(2)
  end

  defp stringify_keys(map) when is_map(map) do
    Enum.into(map, %{}, fn {k, v} -> {to_string(k), v} end)
  end
end
