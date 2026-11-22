defmodule ScrypathFixtures.FakeMeilisearchClient do
  @moduledoc """
  A stand-in for Scrypath's Meilisearch client that serves a scenario's task maps. The data is
  fictional and for development and tests only.

  Scrypath calls `tasks/2` through the `:meilisearch_client` option. The task list comes from the
  `:meilisearch_tasks` option: a list of raw task maps, or an `{:error, reason}` tuple that is
  passed straight back.

  It answers like the server does: filtered by `:index_uids` and `:types`, newest first by uid,
  cut to `:limit`, with `from` and `next` set. A task with a `nil` `indexUid` (an `indexSwap`)
  never matches an `:index_uids` filter, exactly as the recorded v1.15 server leaves swaps out of
  filtered lists.
  """

  @doc "Returns one page of tasks in the shape of `GET /tasks`."
  @spec tasks(keyword(), keyword()) :: {:ok, map()} | {:error, term()}
  def tasks(filters, config) do
    case Keyword.get(config, :meilisearch_tasks, []) do
      {:error, _reason} = error ->
        error

      tasks when is_list(tasks) ->
        uids = Keyword.get(filters, :index_uids)
        types = Keyword.get(filters, :types)
        limit = Keyword.get(filters, :limit, 20)
        from = Keyword.get(filters, :from)

        matching =
          tasks
          |> Enum.filter(&(is_nil(uids) or &1["indexUid"] in uids))
          |> Enum.filter(&(is_nil(types) or &1["type"] in types))
          |> Enum.sort_by(& &1["uid"], :desc)

        window = if from, do: Enum.filter(matching, &(&1["uid"] <= from)), else: matching
        {page, rest} = Enum.split(window, limit)

        {:ok,
         %{
           "results" => page,
           "total" => length(matching),
           "limit" => limit,
           "from" => uid_of(List.first(page)),
           "next" => uid_of(List.first(rest))
         }}
    end
  end

  @doc """
  Returns the applied index settings for the scenario's `:meilisearch_url`, as the real client's
  `get_settings/2` does: `{:ok, settings}`, or `{:error, {:http_error, 404, body}}` for an index
  that was never created. The answer comes from `ScrypathFixtures.AppliedSettings`, so it is data,
  not state.
  """
  @spec get_settings(String.t(), keyword()) ::
          {:ok, map()} | {:error, {:http_error, 404, map()}}
  def get_settings(index, config) when is_binary(index) and is_list(config) do
    ScrypathFixtures.AppliedSettings.fetch(Keyword.get(config, :meilisearch_url), index)
  end

  defp uid_of(nil), do: nil
  defp uid_of(task), do: task["uid"]
end
