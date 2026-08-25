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

  @type row :: {module() | :posture_stream, {:ok, map()} | {:error, term()}}

  @type t :: %__MODULE__{
          state: state(),
          rows: [row()],
          error_count: non_neg_integer(),
          schema_count: non_neg_integer(),
          backend_failed_count: non_neg_integer(),
          queue_failed_count: non_neg_integer(),
          queue_observed_count: non_neg_integer(),
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
    cond do
      allowlist == [] ->
        classify(%Posture{state: :unconfigured, refreshed_at: DateTime.utc_now()})

      not Keyword.has_key?(opts, :backend) ->
        classify(%Posture{state: :missing_backend, refreshed_at: DateTime.utc_now()})

      true ->
        rows = scan(allowlist, opts)
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
          refreshed_at: DateTime.utc_now()
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
        text: "Review read-only sync and drift signals before changing indexes.",
        navigate: "#{mount_path}/sync-drift"
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
        text: "Scan failed sync work periodically even when posture is green.",
        navigate: "#{mount_path}/failed-sync"
      },
      %{
        text: "Confirm drift and queue visibility when changing sync modes.",
        navigate: "#{mount_path}/sync-drift"
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

  @doc "Metric tone: a zero count is reassuring (`:success`), any nonzero is a `:warning`."
  @spec metric_tone(integer()) :: :success | :warning
  def metric_tone(0), do: :success
  def metric_tone(_), do: :warning

  # ── internals ──────────────────────────────────────────────────────────────

  defp scan(allowlist, opts) do
    allowlist
    |> Task.async_stream(
      fn mod -> {mod, Scrypath.sync_status(mod, opts)} end,
      max_concurrency: 3,
      timeout: 15_000,
      on_timeout: :kill_task
    )
    |> Enum.map(fn
      {:ok, {mod, res}} -> {mod, res}
      {:exit, reason} -> {:posture_stream, {:error, {:async_stream, reason}}}
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

  defp classify(%Posture{state: :unconfigured} = summary) do
    %{
      summary
      | headline: "Not configured",
        evidence:
          "No schemas are allowlisted for posture — configure schema_allowlist or SCRYPATH_OPS_SCHEMAS (see scrypath_ops README)."
    }
  end

  defp classify(%Posture{state: :missing_backend} = summary) do
    %{
      summary
      | headline: "Broken",
        evidence:
          "Scrypath runtime is missing :backend under :scrypath_ops — posture cannot query sync status."
    }
  end

  defp classify(%Posture{state: :degraded} = summary) do
    %{
      summary
      | headline: "Degraded",
        evidence: degraded_evidence(summary)
    }
  end

  defp classify(%Posture{state: :ok} = summary) do
    %{
      summary
      | headline: "No fetch errors observed",
        evidence:
          "This check found no schema fetch errors. Keep failed work and drift checks in the loop before treating the fleet as ready for promotion."
    }
  end

  # Name the real cause so "Degraded" never reads as a vague alarm. Fetch errors and
  # stuck failed sync work are distinct signals; report whichever (or both) fired.
  defp degraded_evidence(%Posture{
         error_count: err,
         backend_failed_count: backend_failed,
         queue_failed_count: queue_failed
       }) do
    stuck = backend_failed + queue_failed

    parts =
      [
        err > 0 && "#{err} schema(s) report fetch errors on this check",
        stuck > 0 &&
          "#{stuck} sync job(s) failed to apply and will not self-heal (the live index may be missing documents)"
      ]
      |> Enum.filter(& &1)

    Enum.join(parts, "; ") <>
      " — treat as incident triage, not green. Work the failed-sync queue first."
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
