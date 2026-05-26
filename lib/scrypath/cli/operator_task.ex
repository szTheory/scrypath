defmodule Scrypath.CLI.OperatorTask do
  @moduledoc false

  alias Scrypath.Operator.FailedWork
  alias Scrypath.Operator.ReasonClassCounts
  alias Scrypath.Operator.Reconcile
  alias Scrypath.Operator.RecoveryAction
  alias Scrypath.Operator.State
  alias Scrypath.Operator.Status

  @runtime_keys [
    :backend,
    :sync_mode,
    :index_prefix,
    :meilisearch_url,
    :meilisearch_api_key,
    :oban,
    :oban_queue,
    :oban_max_attempts,
    :repo,
    :otp_app
  ]

  @common_switches [
    backend: :string,
    sync_mode: :string,
    index_prefix: :string,
    meilisearch_url: :string,
    meilisearch_api_key: :string,
    oban: :string,
    oban_queue: :string,
    oban_max_attempts: :integer,
    repo: :string,
    otp_app: :string
  ]

  def parse!(args, extra_switches \\ []) do
    {opts, argv, invalid} = OptionParser.parse(args, strict: @common_switches ++ extra_switches)

    case invalid do
      [] -> {opts, argv}
      _ -> Mix.raise("invalid options: #{Enum.map_join(invalid, ", ", &format_invalid_opt/1)}")
    end
  end

  def schema_from_argv!([schema_name]), do: resolve_module!(schema_name)

  def schema_from_argv!(_argv) do
    Mix.raise("expected one schema module argument, for example `SearchablePost`")
  end

  def runtime_opts(opts) do
    opts
    |> Keyword.take(@runtime_keys)
    |> Enum.map(fn
      {:backend, value} -> {:backend, normalize_backend!(value)}
      {:sync_mode, value} -> {:sync_mode, normalize_sync_mode!(value)}
      {:oban, value} -> {:oban, resolve_module!(value)}
      {:repo, value} -> {:repo, resolve_module!(value)}
      {:otp_app, value} -> {:otp_app, normalize_otp_app!(value)}
      {:oban_queue, value} -> {:oban_queue, normalize_existing_atom!(value, :oban_queue)}
      pair -> pair
    end)
  end

  def target_index_opt(opts) do
    case Keyword.get(opts, :target_index) do
      nil -> []
      value -> [target_index: value]
    end
  end

  def test_operator_opts do
    if Mix.env() == :test do
      Application.get_env(:scrypath, :operator_task_test_opts, [])
    else
      []
    end
  end

  def id!(opts) do
    case Keyword.get(opts, :id) do
      nil -> Mix.raise("`--id` is required for this command")
      value -> value
    end
  end

  def action!(opts) do
    case Keyword.get(opts, :action) do
      "retry" -> :retry
      "backfill" -> :backfill
      "reindex" -> :reindex
      nil -> Mix.raise("`--action` must be one of retry, backfill, or reindex")
      other -> Mix.raise("unsupported action #{inspect(other)}")
    end
  end

  def find_failed_work!(failed_work, id) do
    case Enum.find(failed_work, &(to_string(&1.id) == to_string(id))) do
      nil -> Mix.raise("no failed work found for id #{id}")
      work -> work
    end
  end

  def retry_action_from_report!(%Reconcile{} = report, id) do
    report.failed_work
    |> find_failed_work!(id)
    |> FailedWork.recovery_action()
    |> case do
      %RecoveryAction{} = action -> action
      nil -> Mix.raise("failed work #{id} does not expose a retry action")
    end
  end

  def repair_action_from_report!(%Reconcile{} = report, kind)
      when kind in [:backfill, :reindex] do
    case Enum.find(report.actions, &(&1.kind == kind)) do
      %RecoveryAction{} = action -> action
      nil -> Mix.raise("no #{kind} action is available for this report")
    end
  end

  def render_status(%Status{} = status) do
    [
      "Schema: #{inspect(status.schema)}",
      "Mode: #{status.mode}",
      "Index: #{status.index}",
      "Backend pending: #{length(status.backend.pending)}",
      "Backend failed: #{length(status.backend.failed)}",
      "Backend last succeeded: #{format_state(status.backend.last_succeeded)}",
      "Queue observed: #{yes_no(status.queue.observed?)}",
      "Queue pending: #{length(status.queue.pending)}",
      "Queue retrying: #{length(status.queue.retrying)}",
      "Queue failed: #{length(status.queue.failed)}",
      "Queue last succeeded: #{format_state(status.queue.last_succeeded)}"
    ]
    |> Enum.join("\n")
  end

  def render_failed_work(schema, failed_work, opts \\ []) do
    include_summary? = Keyword.get(opts, :include_class_summary, true)

    header = [
      "Schema: #{inspect(schema)}",
      "Failed work: #{length(failed_work)}"
    ]

    rollup =
      if include_summary? and failed_work != [] do
        format_reason_class_counts_lines(FailedWork.reason_class_counts(failed_work))
      else
        []
      end

    details =
      Enum.map(failed_work, fn work ->
        "- id=#{work.id} source=#{work.source} state=#{work.state} operation=#{work.operation} retryable=#{yes_no(work.retryable?)} reason_class=#{format_reason_class(work.reason_class)} reason=#{work.reason || "n/a"}"
      end)

    Enum.join(header ++ rollup ++ details, "\n")
  end

  @doc false
  def failed_work_cli_json(schema, failed_work) when is_list(failed_work) do
    failed_work
    |> failed_work_public_map(schema)
    |> Jason.encode!()
  end

  defp failed_work_public_map(failed_work, schema) do
    counts = FailedWork.reason_class_counts(failed_work)

    %{
      "schema" => inspect(schema),
      "entries" => Enum.map(failed_work, &failed_work_entry_public/1),
      "counts" => %{
        "version" => counts.version,
        "total" => counts.total,
        "by_class" => reason_class_counts_to_string_map(counts)
      }
    }
  end

  defp failed_work_entry_public(work) do
    %{
      "id" => work.id,
      "reason_class" => format_reason_class(work.reason_class),
      "source" => work.source |> to_string(),
      "state" => work.state |> to_string(),
      "operation" => work.operation |> to_string(),
      "retryable" => work.retryable?
    }
  end

  defp reason_class_counts_to_string_map(%ReasonClassCounts{by_class: bc}) do
    Map.new(
      [:transport, :validation, :backend_rejected, :queue_exhausted, :unknown],
      fn k -> {Atom.to_string(k), Map.fetch!(bc, k)} end
    )
  end

  defp format_reason_class_counts_lines(%ReasonClassCounts{} = counts) do
    line =
      [:transport, :validation, :backend_rejected, :queue_exhausted, :unknown]
      |> Enum.map_join(", ", fn k -> "#{k}=#{Map.fetch!(counts.by_class, k)}" end)

    ["Failed work by class:", "  #{line}"]
  end

  defp format_reason_class(nil), do: "unknown"
  defp format_reason_class(atom) when is_atom(atom), do: Atom.to_string(atom)

  def render_retry_result(id, result) do
    [
      "Retried failed work #{id}",
      "Status: #{Map.get(result, :status, "unknown")}",
      "Mode: #{Map.get(result, :mode, "unknown")}",
      "Reference: #{format_reference(result)}"
    ]
    |> Enum.join("\n")
  end

  def render_reconcile_report(%Reconcile{} = report) do
    retry_ids =
      report.failed_work
      |> Enum.filter(&match?(%RecoveryAction{}, FailedWork.recovery_action(&1)))
      |> Enum.map(&to_string(&1.id))

    actions =
      [
        if(retry_ids == [], do: nil, else: "retry(ids=#{Enum.join(retry_ids, ",")})"),
        if(Enum.any?(report.actions, &(&1.kind == :backfill)), do: "backfill", else: nil),
        if(Enum.any?(report.actions, &(&1.kind == :reindex)), do: "reindex", else: nil)
      ]
      |> Enum.reject(&is_nil/1)

    rollup = format_reason_class_counts_lines(report.failed_work_counts)

    ([
       "Schema: #{inspect(report.schema)}",
       "Mode: #{report.mode}",
       "Index: #{report.index}",
       "Drift signals: #{format_list(report.drift_signals)}",
       "Failed work count: #{length(report.failed_work)}"
     ] ++
       rollup ++
       [
         "Recommended actions: #{format_list(actions)}",
         "Reindex live index: #{report.reindex.live_index}",
         "Reindex target index: #{report.reindex.target_index}",
         "Reindex task state: #{report.reindex.task_state}",
         "Reindex cutover: #{report.reindex.cutover}"
       ])
    |> Enum.join("\n")
  end

  def render_action_result(action, result) do
    [
      "Applied action: #{action}",
      "Status: #{Map.get(result, :status, "unknown")}",
      "Mode: #{Map.get(result, :mode, "unknown")}",
      "Reference: #{format_reference(result)}"
    ]
    |> Enum.join("\n")
  end

  @spec error!(String.t(), term()) :: no_return()
  def error!(task_name, reason) do
    Mix.raise("#{task_name} failed: #{format_reason(reason)}")
  end

  defp resolve_module!(name) do
    module =
      name
      |> String.split(".")
      |> Enum.reject(&(&1 == "Elixir"))
      |> Module.concat()

    if Code.ensure_loaded?(module) do
      module
    else
      Mix.raise("module #{name} is not available")
    end
  end

  defp normalize_otp_app!(value) do
    String.to_existing_atom(value)
  rescue
    ArgumentError -> Mix.raise("otp_app must be an existing atom name, got #{inspect(value)}")
  end

  defp normalize_backend!("meilisearch"), do: Scrypath.Meilisearch
  defp normalize_backend!(value), do: resolve_module!(value)

  defp normalize_sync_mode!("inline"), do: :inline
  defp normalize_sync_mode!("manual"), do: :manual
  defp normalize_sync_mode!("oban"), do: :oban
  defp normalize_sync_mode!(value), do: Mix.raise("unsupported sync mode #{inspect(value)}")

  defp normalize_existing_atom!(value, key) do
    String.to_existing_atom(value)
  rescue
    ArgumentError ->
      Mix.raise("#{key} must reference an existing atom, got #{inspect(value)}")
  end

  defp format_invalid_opt({name, value}), do: "#{name}=#{value}"

  defp format_state(nil), do: "none"

  defp format_state(%State{} = state) do
    suffix =
      case state.at do
        %DateTime{} = at -> " at #{DateTime.to_iso8601(at)}"
        _ -> ""
      end

    "#{state.source}:#{state.id} (#{state.state})#{suffix}"
  end

  defp format_reference(result) do
    metadata =
      case result do
        %{metadata: metadata} -> metadata
        _ -> %{}
      end

    case Map.get(metadata, :index) do
      nil -> "n/a"
      index -> index
    end
  end

  defp format_reason(:index_not_found), do: "index not found"

  defp format_reason(reason) when is_atom(reason), do: Atom.to_string(reason)
  defp format_reason(reason) when is_binary(reason), do: reason
  defp format_reason(reason), do: inspect(reason)

  defp format_list([]), do: "none"
  defp format_list(values), do: Enum.join(values, ", ")

  defp yes_no(true), do: "yes"
  defp yes_no(false), do: "no"
end
