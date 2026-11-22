defmodule ScrypathFixtures.Check do
  @moduledoc """
  The no-database consistency check for every fixture scenario. The data is fictional and for
  development and tests only.

  `run/1` returns `{:ok, %{scenarios: n}}` or `{:error, problems}`. A problem is a
  `{scenario_id, tag_tuple}` pair. Callers can pass `:scenarios` and `:now`, so a test can plant a
  broken scenario without a special mode.

  The check never reads the operator UI and never touches a database. It round-trips each scenario
  through the real Scrypath code: every task map must pass
  `Scrypath.Meilisearch.TaskPayload.normalize/2`, and `Scrypath.sync_status/2` and
  `Scrypath.failed_sync_work/2` must answer as the scenario's `:expect` says.

  Anything that reaches `Scrypath.Config.resolve!/1` or `Scrypath.index_contract_drift/2` is given
  `ScrypathFixtures.Scenario.runtime_opts/1`; `sync_status/2` and `failed_sync_work/2` take the
  full options because they split the operator keys off themselves.
  """

  alias Scrypath.Meilisearch.TaskPayload
  alias ScrypathFixtures.Scenario

  @type problem :: {atom(), tuple()}

  @doc "The scenarios `run/1` checks by default."
  @spec scenarios(DateTime.t()) :: [Scenario.t()]
  def scenarios(%DateTime{} = now) do
    [ScrypathFixtures.Logistify.scenario(:deep_queue, now: now)]
  end

  @doc """
  Checks scenarios and returns `{:ok, %{scenarios: n}}` or `{:error, [problem]}`.

  Options: `:now` (default `ScrypathFixtures.preview_epoch/0`) and `:scenarios` (default
  `scenarios/1` at `now`).
  """
  @spec run(keyword()) :: {:ok, %{scenarios: non_neg_integer()}} | {:error, [problem()]}
  def run(opts \\ []) do
    now = Keyword.get(opts, :now, ScrypathFixtures.preview_epoch())
    scenarios = Keyword.get_lazy(opts, :scenarios, fn -> scenarios(now) end)

    case Enum.flat_map(scenarios, &check_scenario/1) do
      [] -> {:ok, %{scenarios: length(scenarios)}}
      problems -> {:error, problems}
    end
  end

  defp check_scenario(%Scenario{} = scenario) do
    tasks = list_opt(scenario, :meilisearch_tasks)

    tag(Enum.flat_map(tasks, &wire_guard/1), scenario) ++ round_trip_problems(scenario)
  end

  defp list_opt(%Scenario{scrypath_opts: opts}, key) do
    case Keyword.get(opts, key, []) do
      list when is_list(list) -> list
      _other -> []
    end
  end

  # -- wire guard ------------------------------------------------------------------------------

  defp wire_guard(task) do
    case TaskPayload.normalize(task, :poll) do
      {:ok, _normalized} -> []
      {:error, _reason} -> [{:wire_guard, task["uid"]}]
    end
  end

  # -- round trip through the real Scrypath code -----------------------------------------------

  defp round_trip_problems(%Scenario{allowlist: allowlist, expect: expect} = scenario) do
    for schema <- allowlist,
        {call, fun} <- [
          sync_status: &Scrypath.sync_status/2,
          failed_sync_work: &Scrypath.failed_sync_work/2
        ],
        expected = Map.get(expect, call),
        expected != nil,
        got = outcome(fun.(schema, scenario.scrypath_opts)),
        not matches?(expected, got) do
      {scenario.id, {:unexpected_outcome, call, got}}
    end
  end

  defp outcome({:ok, _value}), do: :ok
  defp outcome({:error, reason}), do: {:error, reason}

  defp matches?(:ok, :ok), do: true
  defp matches?({:error, tag}, {:error, tag}), do: true

  defp matches?({:error, tag}, {:error, reason}) when is_tuple(reason),
    do: elem(reason, 0) == tag

  defp matches?(_expected, _got), do: false

  defp tag(problems, %Scenario{id: id}), do: Enum.map(problems, &{id, &1})
end
