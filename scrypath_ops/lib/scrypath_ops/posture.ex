defmodule ScrypathOps.Posture do
  @moduledoc """
  Pure fleet-posture summary over `Scrypath.sync_status/2` for allowlisted schemas.

  Shared by `ScrypathOpsWeb.PostureLive` (the deep per-schema signals table) and
  `ScrypathOpsWeb.ControlRoomLive` (the glanceable posture strip) so the headline,
  counts, and next-checks are computed in exactly one place and never diverge.

  Uses a bounded `Task.async_stream/3` per call. Manual refresh is the only driver.
  """

  alias __MODULE__

  @meilisearch_ops_guide "https://github.com/szTheory/scrypath/blob/main/guides/meilisearch-operations.md"
  @readme "https://github.com/szTheory/scrypath/blob/main/scrypath_ops/README.md"

  @typedoc "Coarse posture state. `:unconfigured` = empty allowlist, `:missing_backend` = no `:backend` opt."
  @type state :: :unconfigured | :missing_backend | :degraded | :ok

  @type row :: {module(), {:ok, map()} | {:error, term()}}

  @type t :: %__MODULE__{
          state: state(),
          rows: [row()],
          error_count: non_neg_integer(),
          schema_count: non_neg_integer(),
          backend_failed_count: non_neg_integer(),
          queue_failed_count: non_neg_integer(),
          queue_observed_count: non_neg_integer(),
          last_success_refs: map(),
          refreshed_at: DateTime.t() | nil,
          headline: String.t(),
          evidence: String.t()
        }

  defstruct state: :ok,
            rows: [],
            error_count: 0,
            schema_count: 0,
            backend_failed_count: 0,
            queue_failed_count: 0,
            queue_observed_count: 0,
            last_success_refs: %{},
            refreshed_at: nil,
            headline: "—",
            evidence: ""

  @doc """
  Builds a posture summary by scanning the allowlist with the given Scrypath opts.

  Performs one `Scrypath.sync_status/2` per schema. Returns a `%ScrypathOps.Posture{}`
  with a coarse `:state`, fleet counts, and a human headline/evidence pair.
  """
  @spec summary([module()], keyword()) :: t()
  def summary(allowlist, opts) do
    summary(allowlist, opts, ScrypathOps.Clock.utc_now(), nil)
  end

  @doc false
  @spec summary([module()], keyword(), DateTime.t()) :: t()
  def summary(allowlist, opts, %DateTime{} = snapshot_at) do
    summary(allowlist, opts, snapshot_at, nil)
  end

  @doc false
  @spec summary([module()], keyword(), DateTime.t(), t() | nil) :: t()
  def summary(allowlist, opts, %DateTime{} = snapshot_at, previous_summary) do
    cond do
      allowlist == [] ->
        classify(%Posture{state: :unconfigured, refreshed_at: snapshot_at})

      not Keyword.has_key?(opts, :backend) ->
        classify(%Posture{state: :missing_backend, refreshed_at: snapshot_at})

      true ->
        rows = scan(allowlist, opts)

        previous_refs =
          if match?(%Posture{}, previous_summary),
            do: previous_summary.last_success_refs,
            else: %{}

        err = Enum.count(rows, fn {_m, r} -> match?({:error, _}, r) end)
        backend_failed = backend_failed_count(rows)
        queue_failed = queue_failed_count(rows)

        # Honest "can I trust search right now?" verdict: fetch errors degrade it, and
        # so does sync work that already failed and won't self-heal (terminal backend
        # rejections + discarded queue jobs) — that means the live index may be missing
        # documents. Retrying/pending work is in-flight, so it stays neutral (no crying
        # wolf over work that may yet succeed).
        stuck_failed = backend_failed + queue_failed

        classify(%Posture{
          state: if(err > 0 or stuck_failed > 0, do: :degraded, else: :ok),
          rows: rows,
          error_count: err,
          schema_count: length(rows),
          backend_failed_count: backend_failed,
          queue_failed_count: queue_failed,
          queue_observed_count: queue_observed_count(rows),
          last_success_refs: refresh_success_refs(rows, previous_refs, snapshot_at),
          refreshed_at: snapshot_at
        })
    end
  end

  @doc "Ordered operator next-checks for a summary, given the mount path. Caller decides how many to show."
  @spec next_checks(t() | state(), String.t()) :: [map()]
  def next_checks(%Posture{state: state}, mount_path), do: next_checks(state, mount_path)

  def next_checks(:unconfigured, _mount_path) do
    [
      %{
        text:
          "Add schemas to the OPSUI allowlist in :scrypath_ops config or SCRYPATH_OPS_SCHEMAS.",
        href: @readme
      }
    ]
  end

  def next_checks(:missing_backend, _mount_path) do
    [
      %{
        text: "Wire :backend and related :scrypath_ops options so sync_status can run.",
        href: @readme
      }
    ]
  end

  def next_checks(:degraded, mount_path) do
    [
      %{
        text: "Open failed sync work to triage fetch and queue errors first.",
        navigate: "#{mount_path}/failed-sync"
      },
      %{
        text: "Check sync progress and index settings before changing indexes.",
        navigate: "#{mount_path}/sync-and-index"
      },
      %{
        text: "Walk Meilisearch operations expectations for the search backend.",
        href: @meilisearch_ops_guide
      }
    ]
    |> maybe_append_mix_status()
  end

  def next_checks(:ok, mount_path) do
    [
      %{
        text: "Scan failed sync work periodically, even when search health is green.",
        navigate: "#{mount_path}/failed-sync"
      },
      %{
        text: "Check sync progress and index settings when changing sync modes.",
        navigate: "#{mount_path}/sync-and-index"
      },
      %{
        text: "Use search playground only after triage surfaces are quiet.",
        navigate: "#{mount_path}/search"
      }
    ]
    |> maybe_append_mix_status()
  end

  @doc "Badge kind for a posture state (matches the operator status palette)."
  @spec badge_kind(state()) :: atom()
  def badge_kind(:degraded), do: :warning
  def badge_kind(:missing_backend), do: :error
  def badge_kind(:unconfigured), do: :warning
  def badge_kind(:ok), do: :success

  @doc "Metric tone: zero stays neutral; nonzero health failures receive a local warning cue."
  @spec metric_tone(integer()) :: :neutral | :warning
  def metric_tone(0), do: :neutral
  def metric_tone(_), do: :warning

  # ── row status, ranking and verdict (Phase 187, LD-8 and LD-10) ─────────────
  #
  # One place decides what a Search health row says about itself, how rows rank, and what the
  # verdicts above them say, so the Control room and Search health can never disagree.

  @typedoc """
  The most urgent thing a row can say: a sync status, a condition word for a row nobody could
  observe, or `:clear` for a row that was observed and has nothing to report.
  """
  @type row_status :: :failed | :retrying | :pending | {:condition, String.t()} | :clear

  # Rank of a row class, most urgent first. `:unverified` (a row that was not checked, or whose
  # queue was not observed) sorts above `:clear` because an unknown row is not a healthy one.
  @rank_order [:failed, :retrying, :pending, :unverified, :clear]
  @ranks @rank_order |> Enum.with_index() |> Map.new()

  @doc """
  Most urgent status of a Search health row, from the `Scrypath.sync_status/2` result.

  Order: failed, retrying, pending, unverified (a `{:error, _}` row is `Not checked`; a queue
  that sync mode says should be observed but was not is `Not observed`), then clear. `:clear`
  needs an observation: the row read cleanly, its backend lists are empty, and the queue is
  either observed-empty or not used by the sync mode. A zero count from an unobserved source
  never produces `:clear`.
  """
  @spec row_status({:ok, map()} | {:error, term()}) :: row_status()
  def row_status({:error, _reason}), do: {:condition, "Not checked"}

  def row_status({:ok, status}) do
    cond do
      status.backend.failed != [] or status.queue.failed != [] -> :failed
      status.queue.retrying != [] -> :retrying
      status.backend.pending != [] or status.queue.pending != [] -> :pending
      not status.queue.observed? and not queue_unused?(status) -> {:condition, "Not observed"}
      true -> :clear
    end
  end

  @doc """
  True when the queue was not observed because the sync mode does not use one (`:inline` or
  `:manual`), as opposed to a queue that should have been observed.
  """
  @spec queue_unused?(map()) :: boolean()
  def queue_unused?(%{queue: %{observed?: true}}), do: false
  def queue_unused?(%{mode: mode}), do: mode in [:inline, :manual, "inline", "manual"]

  @doc "Rows ordered most urgent first (failed, retrying, pending, unverified, clear), then by module name."
  @spec sort_by_urgency([row()]) :: [row()]
  def sort_by_urgency(rows) when is_list(rows) do
    Enum.sort_by(rows, fn {mod, result} -> {row_rank(result), inspect(mod)} end)
  end

  @doc "Rank of one row result in `sort_by_urgency/1` (0 is most urgent)."
  @spec row_rank({:ok, map()} | {:error, term()}) :: non_neg_integer()
  def row_rank(result), do: Map.fetch!(@ranks, result |> row_status() |> row_class())

  @doc """
  The status word a verdict shows: the worst status across rows, or `nil` when no status can
  be claimed. `:clear` only when every row is clear, so a verdict never reads healthy while any
  row is unverified; with no rows there is nothing to say.
  """
  @spec worst_status([row()]) :: :failed | :retrying | :pending | :clear | nil
  def worst_status(rows) when is_list(rows) do
    classes = row_classes(rows)

    cond do
      :failed in classes -> :failed
      :retrying in classes -> :retrying
      :pending in classes -> :pending
      :unverified in classes -> nil
      classes == [] -> nil
      true -> :clear
    end
  end

  @doc """
  The `kind` of a verdict over these rows (LD-10): any failed row is `:error`, retrying or
  unverified rows are `:warning`, everything else is `:neutral`. It follows the worst row
  status, never the coarse posture state, so a warning rule never sits beside a `Failed` word.
  """
  @spec verdict_kind([row()]) :: :error | :warning | :neutral
  def verdict_kind(rows) when is_list(rows) do
    classes = row_classes(rows)

    cond do
      :failed in classes -> :error
      :retrying in classes or :unverified in classes -> :warning
      true -> :neutral
    end
  end

  defp row_classes(rows) do
    Enum.map(rows, fn {_mod, result} -> result |> row_status() |> row_class() end)
  end

  defp row_class({:condition, _word}), do: :unverified
  defp row_class(status), do: status

  # ── internals ──────────────────────────────────────────────────────────────

  defp scan(allowlist, opts) do
    outcomes =
      Task.Supervisor.async_stream_nolink(
        ScrypathOps.TaskSupervisor,
        allowlist,
        &Scrypath.sync_status(&1, opts),
        max_concurrency: 3,
        timeout: 15_000,
        on_timeout: :kill_task
      )

    allowlist
    |> Enum.zip(outcomes)
    |> Enum.map(fn
      {mod, {:ok, result}} -> {mod, result}
      {mod, {:exit, reason}} -> {mod, {:error, {:async_stream, reason}}}
    end)
    |> sort_rows()
  end

  defp sort_rows(rows) do
    Enum.sort_by(rows, fn
      {_m, {:error, _}} -> 0
      _ -> 1
    end)
  end

  defp backend_failed_count(rows) do
    Enum.reduce(rows, 0, fn
      {_mod, {:ok, status}}, acc -> acc + length(status.backend.failed)
      _row, acc -> acc
    end)
  end

  defp queue_failed_count(rows) do
    Enum.reduce(rows, 0, fn
      {_mod, {:ok, status}}, acc -> acc + length(status.queue.failed)
      _row, acc -> acc
    end)
  end

  defp queue_observed_count(rows) do
    Enum.count(rows, fn
      {_mod, {:ok, status}} -> status.queue.observed?
      _row -> false
    end)
  end

  defp refresh_success_refs(rows, previous_refs, snapshot_at) do
    Enum.reduce(rows, previous_refs, fn
      {schema, {:ok, status}}, refs ->
        queue_ref =
          if status.queue.observed? do
            success_ref(status.queue.last_succeeded, snapshot_at)
          else
            %{state: nil, checked_at: snapshot_at, unused?: true}
          end

        Map.put(refs, schema, %{
          backend: success_ref(status.backend.last_succeeded, snapshot_at),
          queue: queue_ref
        })

      # A fetch error has no new source timestamp. Keep the last successful source-local
      # references intact so the caller can label them retained instead of re-dating them.
      {_schema, {:error, _reason}}, refs ->
        refs
    end)
  end

  defp success_ref(state, snapshot_at) do
    %{state: state, checked_at: snapshot_at}
  end

  defp classify(%Posture{state: :unconfigured} = summary) do
    %{
      summary
      | headline: "Not configured",
        evidence:
          "No schemas are configured for search health. Add them to the :scrypath_ops allowlist or set SCRYPATH_OPS_SCHEMAS (see the README)."
    }
  end

  defp classify(%Posture{state: :missing_backend} = summary) do
    %{
      summary
      | headline: "Broken",
        evidence:
          "The :scrypath_ops configuration is missing :backend, so sync status cannot be checked."
    }
  end

  defp classify(%Posture{state: :degraded} = summary) do
    %{
      summary
      | headline: failure_headline(summary),
        evidence: degraded_evidence(summary)
    }
  end

  defp classify(%Posture{state: :ok} = summary) do
    %{
      summary
      | headline: "No sync failures found",
        evidence:
          "No failed jobs or Meilisearch tasks were found. This does not confirm document visibility."
    }
  end

  defp failure_headline(%Posture{error_count: errors}) when errors > 0,
    do: "Search health could not be fully checked"

  defp failure_headline(%Posture{queue_failed_count: jobs, backend_failed_count: 0}),
    do: "#{jobs} sync #{if jobs == 1, do: "job failed", else: "jobs failed"}"

  defp failure_headline(%Posture{queue_failed_count: 0, backend_failed_count: tasks}),
    do: "#{tasks} Meilisearch #{if tasks == 1, do: "task failed", else: "tasks failed"}"

  defp failure_headline(_), do: "Sync jobs and Meilisearch tasks failed"

  defp degraded_evidence(summary) do
    cond do
      summary.error_count > 0 ->
        "#{summary.error_count} schema #{if summary.error_count == 1, do: "check is", else: "checks are"} unavailable. Any displayed successful observations are partial."

      summary.backend_failed_count > 0 and summary.queue_failed_count > 0 ->
        "#{summary.queue_failed_count} sync jobs and #{summary.backend_failed_count} Meilisearch tasks failed. Review failed sync work; search documents may be out of date."

      summary.backend_failed_count > 0 ->
        "Review the failed Meilisearch tasks. Some search documents may be missing or out of date."

      true ->
        "Review failed sync work before retrying. Some search documents may be missing or out of date."
    end
  end

  defp operator_mix_guide_path do
    Path.expand("../../guides/operator-mix-tasks.md", __DIR__)
  end

  defp maybe_append_mix_status(checks) do
    path = operator_mix_guide_path()

    if File.exists?(path) and String.contains?(File.read!(path), "mix scrypath.status") do
      checks ++
        [
          %{
            text: "Snapshot a schema from the CLI when you need raw sync_status output.",
            mix: "mix scrypath.status"
          }
        ]
    else
      checks
    end
  end
end
