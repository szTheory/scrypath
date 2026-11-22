defmodule ScrypathOps.Catalog.Stories.Areas.HealthSchemaRow do
  # One schema's card on Search health, over the same function component the page renders.
  #
  # Every variation is a real row: `Scrypath.sync_status/2` over the scenario's own options, built
  # into a posture by `ScrypathOps.Posture.build/3`, then the one row it holds. `variations/0` runs
  # when the storybook backend compiles with no application started, so it never calls
  # `Posture.summary`, `Posture.scan` or anything that needs `ScrypathOps.TaskSupervisor`.
  #
  # One variation per distinct row state the fixtures reach. `logistify_deep_queue` is not used: its
  # pending count comes through a fake Oban inspector that the real one (capped at 100 rows) could
  # not produce.
  use PhoenixStorybook.Story, :component

  alias ScrypathOps.Posture

  @mounted "Mounted scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs"

  def function, do: &ScrypathOpsWeb.Components.SearchHealth.health_schema_row/1
  def container, do: :iframe
  def job, do: "JOB-03"
  def covers, do: [ScrypathOpsWeb.PostureLive]

  def variations do
    now = ScrypathFixtures.preview_epoch()

    for {id, scenario_id, adopter, description} <- [
          {:shopadelic_failed_journey_failed, :shopadelic_failed_journey, "Shopadelic",
           "Shopadelic, failed sync jobs and tasks: the row says Failed and links to this schema's failed sync work."},
          {:wikily_first_delete_failed_backend_failed, :wikily_first_delete_failed, "Wikily",
           "Wikily, a first delete failed on the backend: the row says Failed and links to its failed sync work."},
          {:shopadelic_settings_aligned_clear, :shopadelic_settings_aligned, "Shopadelic",
           "Shopadelic, settings aligned: both sources were observed and are empty, so the row says Clear."},
          {:logistify_history_over_limit_f1_not_checked, :logistify_history_over_limit_f1,
           "Logistify",
           "Logistify, task history over the limit: the row says Not checked and records no successful observation."}
        ] do
      scenario = ScrypathFixtures.Scenarios.get!(scenario_id, now)
      summary = posture(scenario, now)

      %Variation{
        id: id,
        description: description,
        note:
          "Adopter: #{adopter} (fictional) · Persona: On-call (ROLE-OPS) · Job: JOB-03 · Proof: #{@mounted}",
        attributes: %{
          row: hd(summary.rows),
          summary: summary,
          mount_path: "/ops",
          now: now
        }
      }
    end
  end

  # The same three-way input `Posture.summary/4` hands to `Posture.build/3`, with the scan replaced
  # by direct `Scrypath.sync_status/2` calls (one allowlisted schema per scenario, so no sort).
  defp posture(scenario, now) do
    input =
      for mod <- scenario.allowlist, do: {mod, Scrypath.sync_status(mod, scenario.scrypath_opts)}

    Posture.build(input, now, nil)
  end
end
