defmodule Scrypath.Meilisearch.Naming do
  @moduledoc false

  @spec index_name(module(), keyword()) :: String.t()
  def index_name(schema_module, config) do
    prefix =
      Keyword.get(config, :index_prefix) ||
        Scrypath.Schema.Metadata.config(schema_module).index_prefix ||
        "scrypath"

    schema_name = schema_module |> Module.split() |> List.last() |> Macro.underscore()

    "#{prefix}_#{schema_name}"
  end
end
