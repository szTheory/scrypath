defmodule ScrypathOps.Catalog.Stories.Surfaces.SearchHealth do
  # The whole Search health page inside the operator shell, over `SearchHealth.surface/1`, the one
  # function the LiveView renders. A static render: buttons and links do nothing here (the mounted
  # behavior is the journey test and the 4002 preview).
  #
  # `variations/0` runs when the storybook backend compiles with no application started, so it only
  # calls pure code (`Scrypath.sync_status/2` over each scenario's own options, then
  # `ScrypathOps.Posture.build/3`).
  use PhoenixStorybook.Story, :component

  alias ScrypathOps.Posture

  @mounted "Mounted scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs"

  def function, do: &ScrypathOpsWeb.Components.SearchHealth.surface/1
  def container, do: :iframe
  def job, do: "JOB-03"
  def covers, do: [ScrypathOpsWeb.PostureLive]

  def variations do
    now = ScrypathFixtures.preview_epoch()

    for {id, adopter, description} <- [
          {:shopadelic_failed_journey, "Shopadelic",
           "Shopadelic, on-call, JOB-03: the whole page, degraded, with the failed row and its link to failed sync work."},
          {:wikily_unconfigured, "Wikily",
           "Wikily, no schemas configured: the whole page shows the setup empty state."}
        ] do
      scenario = ScrypathFixtures.Scenarios.get!(id, now)
      summary = posture(scenario, now)

      %Variation{
        id: id,
        description: description,
        note:
          "Adopter: #{adopter} (fictional) · Persona: On-call (ROLE-OPS) · Job: JOB-03 · Proof: #{@mounted}",
        attributes: %{
          mount_path: "/ops",
          flash: %{},
          shell: :ops,
          page_title: "Search health",
          summary: summary,
          rows: Posture.sort_by_urgency(summary.rows),
          sync_mode: Keyword.get(scenario.scrypath_opts, :sync_mode, :inline),
          now: now
        }
      }
    end
  end

  # The same three-way input `Posture.summary/4` hands to `Posture.build/3`, with the scan replaced
  # by direct `Scrypath.sync_status/2` calls (one allowlisted schema per scenario, so no sort).
  defp posture(scenario, now) do
    input =
      cond do
        scenario.allowlist == [] ->
          :unconfigured

        not Keyword.has_key?(scenario.scrypath_opts, :backend) ->
          :missing_backend

        true ->
          for mod <- scenario.allowlist,
              do: {mod, Scrypath.sync_status(mod, scenario.scrypath_opts)}
      end

    Posture.build(input, now, nil)
  end
end
