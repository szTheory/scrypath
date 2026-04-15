defmodule Scrypath.Config do
  @moduledoc false

  alias Scrypath.Options

  @spec resolve!(keyword()) :: keyword()
  def resolve!(opts) when is_list(opts) do
    Application.get_env(:scrypath, :defaults, [])
    |> Keyword.merge(opts)
    |> Options.validate_runtime_options!()
  end

  @spec fetch_backend!(keyword()) :: module()
  def fetch_backend!(config) do
    Keyword.fetch!(config, :backend)
  end
end
