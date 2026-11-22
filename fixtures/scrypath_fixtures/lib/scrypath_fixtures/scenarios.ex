defmodule ScrypathFixtures.Scenarios do
  @moduledoc """
  The registry of every fixture scenario. The data is fictional and for development and tests
  only.

  A scenario is built for one instant, so the registry holds builders: `{id, fun}` where `fun` takes
  `now` and returns the `ScrypathFixtures.Scenario`. The order is fixed (Logistify, Shopadelic,
  then Wikily; within an adopter, ordinary states before its stress variation), and every other
  consumer (the check task, the round-trip tests, a later preview) reads this one list.

  A new scenario is registered here and nowhere else. A builder whose id differs from the id of the
  scenario it builds is a bug the registry test reports.
  """

  alias ScrypathFixtures.Logistify
  alias ScrypathFixtures.Scenario
  alias ScrypathFixtures.Shopadelic
  alias ScrypathFixtures.Wikily

  @type builder :: {atom(), (DateTime.t() -> Scenario.t())}

  @doc "Every `{id, builder}` pair, in registry order."
  @spec builders() :: [builder()]
  def builders do
    [
      {:logistify_deep_queue, &Logistify.scenario(:deep_queue, now: &1)},
      {:logistify_steady, &Logistify.scenario(:steady, now: &1)},
      {:logistify_history_over_limit_f1, &Logistify.scenario(:history_over_limit, now: &1)},
      {:shopadelic_settings_aligned, &Shopadelic.scenario(:settings_aligned, now: &1)},
      {:shopadelic_settings_drift, &Shopadelic.scenario(:settings_drift, now: &1)},
      {:shopadelic_failed_journey, &Shopadelic.scenario(:failed_journey, now: &1)},
      {:wikily_unconfigured, &Wikily.scenario(:unconfigured, now: &1)},
      {:wikily_missing_backend, &Wikily.scenario(:missing_backend, now: &1)},
      {:wikily_index_not_created, &Wikily.scenario(:index_not_created, now: &1)},
      {:wikily_first_delete_failed, &Wikily.scenario(:first_delete_failed, now: &1)}
    ]
  end

  @doc "Every scenario built at `now`, in registry order."
  @spec all(DateTime.t()) :: [Scenario.t()]
  def all(%DateTime{} = now), do: Enum.map(builders(), fn {_id, build} -> build.(now) end)

  @doc "The id of every registered scenario, in registry order."
  @spec ids() :: [atom()]
  def ids, do: Enum.map(builders(), fn {id, _build} -> id end)

  @doc "One scenario built at `now`. An unregistered id raises `ArgumentError`."
  @spec get!(atom(), DateTime.t()) :: Scenario.t()
  def get!(id, %DateTime{} = now) when is_atom(id) do
    case List.keyfind(builders(), id, 0) do
      {^id, build} ->
        build.(now)

      nil ->
        raise ArgumentError, "no scenario registered as #{inspect(id)}; known: #{inspect(ids())}"
    end
  end
end
