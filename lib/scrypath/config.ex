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

  @spec fetch_meilisearch_url!(keyword()) :: String.t()
  def fetch_meilisearch_url!(config) do
    Keyword.fetch!(config, :meilisearch_url)
  end

  @spec meilisearch_api_key(keyword()) :: String.t() | nil
  def meilisearch_api_key(config) do
    Keyword.get(config, :meilisearch_api_key)
  end

  @spec inline_poll_interval(keyword()) :: pos_integer()
  def inline_poll_interval(config) do
    Keyword.fetch!(config, :inline_poll_interval)
  end

  @spec inline_timeout(keyword()) :: pos_integer()
  def inline_timeout(config) do
    Keyword.fetch!(config, :inline_timeout)
  end
end
