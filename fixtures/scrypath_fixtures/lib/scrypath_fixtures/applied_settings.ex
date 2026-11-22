defmodule ScrypathFixtures.AppliedSettings do
  @moduledoc """
  The index settings a scenario's Meilisearch reports, keyed by the scenario's
  `:meilisearch_url`. The data is fictional and for development and tests only.

  `Scrypath.index_contract_drift/2` accepts no operator-only option, so a scenario cannot carry
  its applied settings as data. It carries a URL instead (every scenario's is a `.invalid` name
  that never resolves) and `ScrypathFixtures.FakeMeilisearchClient.get_settings/2` looks that URL
  up here. This module is plain data: no process, no application env.

  Every settings map starts from the settings a new index reports in Meilisearch v1.15 (the
  recording `16-settings-default`), so no settings key is typed by hand. An "aligned" state merges
  in what the schema declares, computed with the same Scrypath functions the drift report uses
  (see `aligned/1`). A drifted state changes one key on top of that. A URL not listed here answers
  the recorded 404 for an index that was never created, which the drift report turns into
  `{:error, :index_not_found}`.
  """

  alias Scrypath.Meilisearch.Settings
  alias Scrypath.Schema.Metadata
  alias ScrypathFixtures.Logistify.Shipment
  alias ScrypathFixtures.Recordings
  alias ScrypathFixtures.Shopadelic.Product

  # RFC 2606: the .invalid top-level domain never resolves.
  @logistify "https://logistify.fixtures.invalid"
  @shopadelic_aligned "https://shopadelic.fixtures.invalid"
  @shopadelic_drift "https://shopadelic-drift.fixtures.invalid"

  @urls %{
    logistify: @logistify,
    shopadelic_aligned: @shopadelic_aligned,
    shopadelic_drift: @shopadelic_drift
  }

  @doc "The `meilisearch_url` of a known settings state."
  @spec url(:logistify | :shopadelic_aligned | :shopadelic_drift) :: String.t()
  def url(state), do: Map.fetch!(@urls, state)

  @doc """
  The applied settings for `meilisearch_url`, in the shape `get_settings/2` of the real client
  returns: `{:ok, settings}`, or `{:error, {:http_error, 404, body}}` for an index that does not
  exist. `index` is accepted for the client's signature; every state serves one index.
  """
  @spec fetch(String.t() | nil, String.t()) ::
          {:ok, map()} | {:error, {:http_error, 404, map()}}
  def fetch(meilisearch_url, index)

  def fetch(@logistify, _index), do: {:ok, aligned(Shipment)}
  def fetch(@shopadelic_aligned, _index), do: {:ok, aligned(Product)}

  def fetch(@shopadelic_drift, _index) do
    # Only `status` was ever applied: the schema also declares `storeId`.
    {:ok, Map.merge(aligned(Product), %{"filterableAttributes" => ["status"]})}
  end

  def fetch(_meilisearch_url, _index),
    do: {:error, {:http_error, 404, Recordings.body!("19-settings-unknown-index-404")}}

  # The recorded default, with the settings the schema declares written over it. The drift report
  # compares two declarations with the applied settings: the filterable attributes the settings
  # resolver computes, and the `sortable:` list on the schema. Scrypath's own settings apply sends
  # only the first (finding F4), so an index whose sortable attributes match was set up with them
  # under `settings:` as well, which is what "aligned" means here.
  defp aligned(schema) do
    declared = schema |> Settings.resolve([]) |> Settings.translate_settings()
    sortable = schema |> Metadata.sortable() |> Enum.map(&Atom.to_string/1)

    Recordings.default_settings()
    |> Map.merge(declared)
    |> Map.put("sortableAttributes", sortable)
  end
end
