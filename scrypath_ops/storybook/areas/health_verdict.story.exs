defmodule ScrypathOps.Catalog.Stories.Areas.HealthVerdict do
  # The verdict at the top of Search health, over the same function component the page renders.
  #
  # `variations/0` runs when the storybook backend compiles, with no application started, so it only
  # calls pure code: `Scrypath.sync_status/2` over each scenario's own options, then
  # `ScrypathOps.Posture.build/3`. Never `Posture.summary` or `Posture.scan` here: they need
  # `ScrypathOps.TaskSupervisor` and the compile would fail.
  use PhoenixStorybook.Story, :component

  alias ScrypathOps.Posture

  @mounted "Mounted scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs"

  def function, do: &ScrypathOpsWeb.Components.SearchHealth.health_verdict/1
  def container, do: :iframe
  def job, do: "JOB-03"
  def covers, do: [ScrypathOpsWeb.PostureLive]

  def variations do
    now = ScrypathFixtures.preview_epoch()

    for {id, adopter, proof, description} <- [
          {:shopadelic_failed_journey, "Shopadelic", @mounted,
           "Shopadelic, on-call, JOB-03, degraded: failed sync jobs and tasks"},
          {:shopadelic_settings_aligned, "Shopadelic", "render only",
           "Shopadelic, settings aligned: nothing failed, so the verdict says no sync failures were found."},
          {:wikily_unconfigured, "Wikily", "render only",
           "Wikily, no schemas configured: the verdict area shows the setup empty state."},
          {:wikily_missing_backend, "Wikily", "render only",
           "Wikily, backend missing: the verdict area shows the runtime-not-configured empty state."},
          {:logistify_history_over_limit_f1, "Logistify", "render only",
           "Logistify, task history over the limit: the check could not finish, so the verdict says so."}
        ] do
      scenario = ScrypathFixtures.Scenarios.get!(id, now)

      %Variation{
        id: id,
        description: description,
        note:
          "Adopter: #{adopter} (fictional) · Persona: On-call (ROLE-OPS) · Job: JOB-03 · Proof: #{proof}",
        attributes: %{
          summary: posture(scenario, now),
          sync_mode: Keyword.get(scenario.scrypath_opts, :sync_mode, :inline)
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
