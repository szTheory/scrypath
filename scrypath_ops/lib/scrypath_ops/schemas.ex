defmodule ScrypathOps.Schemas do
  @moduledoc """
  Explicit schema allowlist and shared operator/runtime defaults for OPSUI.

  The allowlist is read only from application configuration — never from
  enumerating loaded modules or OTP applications at runtime.
  """

  @allowlist_key :schema_allowlist

  @scrypath_opt_keys ~w(
    backend meilisearch_url index_prefix sync_mode oban oban_queue
    meilisearch_api_key meilisearch_client oban_inspector meilisearch_tasks oban_jobs
  )a

  @operator_only_opts ~w(
    meilisearch_tasks oban_jobs oban_inspector target_index reason_class_counts include_index_contract_drift
  )a

  @doc """
  Returns the configured list of schema modules for OPSUI.

  Reads `Application.get_env(:scrypath_ops, :schema_allowlist, [])`.
  """
  @spec allowlist() :: [module()]
  def allowlist do
    Application.get_env(:scrypath_ops, @allowlist_key, [])
  end

  @doc """
  Default keyword options merged into `Scrypath.*` calls from `:scrypath_ops` config.

  Includes operator/runtime families aligned with the operator Mix guide
  (`meilisearch_url`, `index_prefix`, `sync_mode`, `oban`, `oban_queue`).
  Values may be `nil`; callers may merge LiveView-specific overrides.
  """
  @spec default_operator_opts() :: keyword()
  def default_operator_opts do
    [
      meilisearch_url: Application.get_env(:scrypath_ops, :meilisearch_url),
      index_prefix: Application.get_env(:scrypath_ops, :index_prefix),
      sync_mode: Application.get_env(:scrypath_ops, :sync_mode),
      oban: Application.get_env(:scrypath_ops, :oban),
      oban_queue: Application.get_env(:scrypath_ops, :oban_queue)
    ]
  end

  @doc """
  Builds the full keyword passed to `Scrypath.sync_status/2`, `failed_sync_work/2`, etc.

  Merges `default_operator_opts/0` with other configured keys (including `:backend`
  and injected test doubles like `:meilisearch_tasks`). Keys with `nil` values are
  dropped so `Keyword.merge/2` from callers can supply defaults.
  """
  @spec scrypath_opts() :: keyword()
  def scrypath_opts do
    Enum.flat_map(@scrypath_opt_keys, fn k ->
      case Application.get_env(:scrypath_ops, k) do
        nil -> []
        v -> [{k, v}]
      end
    end)
  end

  @doc """
  Parses a comma-separated list of dotted Elixir module names into module atoms.

  Used by `config/runtime.exs` when `SCRYPATH_OPS_SCHEMAS` is set. Intended for
  host operators only — validates shape, not that modules are loaded.
  """
  @spec modules_from_csv(String.t()) :: [module()]
  def modules_from_csv(csv) when is_binary(csv) do
    csv
    |> String.split(",", trim: true)
    |> Enum.map(&module_from_dotted_string/1)
  end

  @doc """
  Drops operator-only keys that must not be passed to `Config.resolve!/1`-only APIs
  such as `Scrypath.index_contract_drift/2`.
  """
  @spec runtime_opts(keyword()) :: keyword()
  def runtime_opts(opts) when is_list(opts) do
    Keyword.drop(opts, @operator_only_opts)
  end

  defp module_from_dotted_string(segment) do
    segment
    |> String.trim()
    |> String.split(".")
    |> Enum.map(&String.to_atom/1)
    |> Module.concat()
  end
end
