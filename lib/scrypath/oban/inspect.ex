defmodule Scrypath.Oban.Inspect do
  @moduledoc false
  @compile {:no_warn_undefined, [Oban.Job]}

  @spec list_jobs(module(), keyword()) :: {:ok, [map()]} | {:error, term()}
  def list_jobs(schema_module, config) do
    case Keyword.get(config, :oban_inspector) do
      inspector when is_atom(inspector) and not is_nil(inspector) ->
        inspector.list_jobs(schema_module, config)

      nil ->
        {:ok, Keyword.get(config, :oban_jobs, [])}
    end
  end
end
