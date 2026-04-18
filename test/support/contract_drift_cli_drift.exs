# Invoked via `mix run test/support/contract_drift_cli_drift.exs` (MIX_ENV=test) to assert
# drift path ends with exit code 2 without terminating the ExUnit VM (System.halt/1).

root = File.cwd!()
Code.require_file(Path.join(root, "test/support/searchable_post.ex"))

alias Scrypath.Meilisearch.Settings

defmodule ContractDriftCliDrift.Stub do
  @moduledoc false
  def get_settings(_index, _config) do
    {:ok, Application.fetch_env!(:scrypath, :contract_drift_cli_drift_applied)}
  end
end

base = [
  backend: Scrypath.Meilisearch,
  sync_mode: :manual,
  index_prefix: "tenant",
  meilisearch_url: "http://localhost:7700",
  meilisearch_client: ContractDriftCliDrift.Stub
]

Application.put_env(:scrypath, :defaults, base)

full = Scrypath.Config.resolve!(base)

declared_wire =
  SearchablePost
  |> Settings.resolve(full)
  |> Settings.translate_settings()

# Omit one declared searchable field so the `fields` dimension mismatches.
applied =
  Map.merge(declared_wire, %{
    "searchableAttributes" => ["title"],
    "filterableAttributes" =>
      SearchablePost.__scrypath__(:filterable) |> Enum.map(&Atom.to_string/1),
    "sortableAttributes" => SearchablePost.__scrypath__(:sortable) |> Enum.map(&Atom.to_string/1),
    "faceting" => %{}
  })

Application.put_env(:scrypath, :contract_drift_cli_drift_applied, applied)

Application.put_env(:scrypath, :operator_task_test_opts,
  meilisearch_client: ContractDriftCliDrift.Stub
)

Mix.Tasks.Scrypath.Index.ContractDrift.run(["SearchablePost"])
