defmodule ScrypathOps.Catalog.Stories.Screens.FailedSync do
  # The whole Failed sync page inside the operator shell, over `FailedSync.screen/1`, the one function
  # the LiveView renders. A static render: buttons and links do nothing here (the mounted behavior is
  # the journey test and the 4002 preview).
  #
  # `variations/0` runs when the storybook backend compiles with no application started, so it only
  # calls pure code (`Scrypath.failed_sync_work/2` over each scenario's own options, then
  # `ScrypathOps.FailedSyncView.build/4`). The second variation is a setup state (no backend): Wikily's
  # failed delete renders the same row component as Shopadelic's, so it would add no new page.
  use PhoenixStorybook.Story, :component

  alias Scrypath.Operator.FailedSyncWorkInspection
  alias ScrypathOps.FailedSyncView

  @seam "Mounted scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs"

  def function, do: &ScrypathOpsWeb.Components.FailedSync.screen/1
  def container, do: ScrypathOps.Catalog.Frames.full_width()
  def job, do: "JOB-03"
  def covers, do: [ScrypathOpsWeb.FailedSyncLive]

  def variations do
    now = ScrypathFixtures.preview_epoch()

    for {id, adopter, description} <- [
          {:shopadelic_failed_journey, "Shopadelic",
           "Shopadelic, on-call, JOB-03: the whole page with four failed jobs, one retrying and one failed Meilisearch task."},
          {:wikily_missing_backend, "Wikily",
           "Wikily, backend missing: the whole page shows the runtime-not-configured state and no rows."}
        ] do
      scenario = ScrypathFixtures.Scenarios.get!(id, now)

      %Variation{
        id: id,
        description: description,
        note:
          "Adopter: #{adopter} (fictional) · Persona: On-call (ROLE-OPS) · Job: JOB-03 · Proof: #{@seam}",
        attributes: %{
          view: view(scenario, now),
          mount_path: "/ops",
          flash: %{},
          shell: :ops,
          page_title: "Failed sync work",
          last_refresh_at: now
        }
      }
    end
  end

  # The same loads `ScrypathOpsWeb.FailedSyncLive` keeps: one result per allowlisted schema, or
  # `:missing_backend` when the scenario has no backend.
  defp view(scenario, now) do
    opts = Keyword.put(scenario.scrypath_opts, :reason_class_counts, true)

    loads =
      if Keyword.has_key?(opts, :backend) do
        for mod <- scenario.allowlist do
          case Scrypath.failed_sync_work(mod, opts) do
            {:ok, %FailedSyncWorkInspection{entries: entries}} -> {mod, {:ok, entries}}
            {:error, reason} -> {mod, {:error, reason}}
          end
        end
      else
        :missing_backend
      end

    scope = %{
      error: nil,
      allowlist: scenario.allowlist,
      schema_filter: [],
      cause_filter: [],
      delete_confirmation: nil
    }

    FailedSyncView.build(loads, scope, %{}, now)
  end
end
