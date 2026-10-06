defmodule ScrypathEcommerceWeb.Phase173FixtureSource do
  @moduledoc false

  @observed_at ~U[2026-10-06 17:18:42.318Z]
  @task_time "2026-10-04T13:02:05.123456-04:00"
  @schemas [ScrypathEcommerce.Catalog.Product, ScrypathEcommerce.Catalog.Variant]

  def scenario(name)
      when name in ["default", "failed", "unknown", "empty", "partial", "long-value"] do
    allowlist =
      if name == "empty", do: [], else: if(name == "partial", do: [hd(@schemas)], else: @schemas)

    tasks =
      if name in ["empty", "partial"] do
        []
      else
        Enum.map(allowlist, fn schema -> task(schema, name) end)
      end

    jobs =
      if name in ["empty", "partial"] do
        []
      else
        Enum.map(allowlist, fn schema -> job(schema, name) end)
      end

    %{
      allowlist: allowlist,
      observed_at: @observed_at,
      opts: [
        backend: Scrypath.Meilisearch,
        sync_mode: :oban,
        oban_queue: :scrypath_sync,
        index_prefix: "ecommerce_",
        meilisearch_url: "http://fixture.invalid",
        meilisearch_client: __MODULE__,
        meilisearch_tasks: tasks,
        oban_jobs: jobs
      ]
    }
  end

  def scenario(_invalid), do: scenario("default")

  def tasks(filters, opts) do
    index_uids = Keyword.get(filters, :index_uids, [])

    results =
      Enum.filter(Keyword.get(opts, :meilisearch_tasks, []), &(&1["indexUid"] in index_uids))

    {:ok, %{results: results, next: nil}}
  end

  defp task(schema, scenario) do
    status =
      if scenario == "failed",
        do: "failed",
        else: if(scenario == "unknown", do: "mystery", else: "succeeded")

    title =
      if scenario == "long-value",
        do: String.duplicate("Long ecommerce title for phase 173 ", 16),
        else: nil

    %{
      "uid" => 173_200 + Enum.find_index(@schemas, &(&1 == schema)),
      "status" => status,
      "type" => "documentAdditionOrUpdate",
      "indexUid" => Scrypath.Meilisearch.index_name(schema, index_prefix: "ecommerce_"),
      "finishedAt" => @task_time,
      "details" => %{"title" => title}
    }
  end

  defp job(schema, scenario) do
    %{
      id: 173_300 + Enum.find_index(@schemas, &(&1 == schema)),
      state: if(scenario == "failed", do: "discarded", else: "completed"),
      worker:
        if(scenario == "long-value",
          do: String.duplicate("ScrypathEcommerce.LongWorker", 8),
          else: "Scrypath.SyncWorker"
        ),
      queue: "scrypath_sync",
      completed_at: "2026-10-04T13:02:05.123456-04:00"
    }
  end
end
