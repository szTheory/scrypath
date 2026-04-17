defmodule Scrypath.Config do
  @moduledoc """
  Internal runtime configuration helpers for Scrypath.

  The functions here normalize and expose runtime settings for the common path
  and the backend-specific orchestration code.
  """

  alias Scrypath.Options

  @doc "Resolve runtime options by merging explicit opts over application defaults."
  @spec resolve!(keyword()) :: keyword()
  def resolve!(opts) when is_list(opts) do
    Application.get_env(:scrypath, :defaults, [])
    |> Keyword.merge(per_repo_config(opts))
    |> Keyword.merge(opts)
    |> Options.validate_runtime_options!()
  end

  @spec per_repo_config(keyword()) :: keyword()
  defp per_repo_config(opts) do
    otp_app = Keyword.get(opts, :otp_app) || repo_otp_app(opts)

    with repo when is_atom(repo) <- Keyword.get(opts, :repo),
         otp_app when is_atom(otp_app) and not is_nil(otp_app) <- otp_app,
         repo_env when is_list(repo_env) <- Application.get_env(otp_app, repo, []),
         scrypath_config when is_list(scrypath_config) <- Keyword.get(repo_env, :scrypath, []) do
      scrypath_config
    else
      _ -> []
    end
  end

  defp repo_otp_app(opts) do
    case Keyword.get(opts, :repo) do
      repo when is_atom(repo) -> Application.get_application(repo)
      _ -> nil
    end
  end

  @spec ensure_oban_ready!(keyword()) :: keyword()
  def ensure_oban_ready!(config) do
    if Keyword.fetch!(config, :sync_mode) == :oban do
      maybe_ensure_oban_dependency!(config)
      ensure_oban_config!(config)
    end

    config
  end

  @spec oban_dependency_available?() :: boolean()
  def oban_dependency_available? do
    Code.ensure_loaded?(Oban) and Code.ensure_loaded?(Oban.Job)
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

  @spec oban_module(keyword()) :: module() | nil
  def oban_module(config) do
    Keyword.fetch!(config, :oban)
  end

  @spec oban_queue(keyword()) :: atom() | nil
  def oban_queue(config) do
    Keyword.fetch!(config, :oban_queue)
  end

  @spec oban_max_attempts(keyword()) :: pos_integer()
  def oban_max_attempts(config) do
    Keyword.fetch!(config, :oban_max_attempts)
  end

  defp maybe_ensure_oban_dependency!(config) do
    if oban_module(config) == Oban and not oban_dependency_available?() do
      raise ArgumentError,
            "Oban dependency is required for sync_mode :oban. Add {:oban, \"~> 2.21\", optional: true} to your deps."
    end
  end

  defp ensure_oban_config!(config) do
    validate_oban_queue!(config)
    validate_oban_module!(config)
    validate_oban_max_attempts!(config)
  end

  defp validate_oban_queue!(config) do
    case oban_queue(config) do
      queue when is_atom(queue) and not is_nil(queue) -> :ok
      _ -> raise ArgumentError, "oban_queue is required when sync_mode is :oban"
    end
  end

  defp validate_oban_module!(config) do
    case oban_module(config) do
      module when is_atom(module) and not is_nil(module) ->
        if Code.ensure_loaded?(module) do
          :ok
        else
          raise ArgumentError,
                "configured Oban instance #{inspect(module)} is not available for sync_mode :oban"
        end

      _ ->
        raise ArgumentError, "oban must be a module when sync_mode is :oban"
    end
  end

  defp validate_oban_max_attempts!(config) do
    case oban_max_attempts(config) do
      attempts when is_integer(attempts) and attempts > 0 ->
        :ok

      _ ->
        raise ArgumentError,
              "oban_max_attempts must be a positive integer when sync_mode is :oban"
    end
  end
end
