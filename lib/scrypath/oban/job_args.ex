defmodule Scrypath.Oban.JobArgs do
  @moduledoc false

  # Decodes the JSON args of Scrypath's Oban jobs. Job args are stored input that anyone
  # with database or Oban Web access can edit, so this module never creates an atom from
  # them and never calls a module named in them unless it is loaded and exports the
  # callbacks its role needs. Every failure is a tagged `{:error, tag}` the workers turn
  # into `{:cancel, {:invalid_job, tag}}`.
  #
  # Pure on purpose: no Oban references, so it compiles without the optional dependency.

  alias Scrypath.Config
  alias Scrypath.Oban.JobConfig
  alias Scrypath.Schema.Metadata

  @type tag ::
          {:unknown_schema, String.t()}
          | {:unknown_fan_out, String.t()}
          | {:unknown_backend, String.t()}
          | {:unknown_repo, String.t()}
          | {:unknown_otp_app, String.t()}
          | {:invalid_arg, String.t()}
          | {:invalid_config, String.t()}

  @doc false
  @spec decode_upsert(map()) :: {:ok, map()} | {:error, tag()}
  def decode_upsert(args) when is_map(args) do
    with {:ok, schema} <- fetch_schema(args),
         {:ok, backend} <- fetch_module(args, "backend", :unknown_backend, &full_backend?/1),
         {:ok, index} <- fetch_index(args),
         {:ok, document_ids} <- fetch_document_ids(args),
         {:ok, repo_opts} <- fetch_repo(args) do
      {:ok,
       %{
         schema: schema,
         backend: backend,
         index: index,
         document_ids: document_ids,
         opts: JobConfig.merge_job_runtime_opts(repo_opts, args)
       }}
    end
  end

  def decode_upsert(_args), do: {:error, {:invalid_arg, "args"}}

  @doc false
  @spec decode_delete(map()) :: {:ok, map()} | {:error, tag()}
  def decode_delete(args) when is_map(args) do
    # A delete job never loads records, so a "repo" key is ignored here.
    with {:ok, schema} <- fetch_schema(args),
         {:ok, backend} <- fetch_module(args, "backend", :unknown_backend, &delete_backend?/1),
         {:ok, index} <- fetch_index(args),
         {:ok, document_ids} <- fetch_document_ids(args),
         :ok <- check_document_count(args, document_ids) do
      {:ok,
       %{
         schema: schema,
         backend: backend,
         index: index,
         document_ids: document_ids,
         opts: JobConfig.merge_job_runtime_opts([], args)
       }}
    end
  end

  def decode_delete(_args), do: {:error, {:invalid_arg, "args"}}

  @doc false
  @spec decode_related(map()) :: {:ok, map()} | {:error, tag()}
  def decode_related(args) when is_map(args) do
    with {:ok, schema} <- fetch_schema(args),
         {:ok, fan_out, fan_out_config} <- fetch_fan_out(schema, args),
         {:ok, document_ids} <- fetch_document_ids(args),
         {:ok, opts_map} <- fetch_opts(args),
         {:ok, opts} <- decode_related_opts(opts_map) do
      {:ok,
       %{
         schema: schema,
         fan_out: fan_out,
         fan_out_config: fan_out_config,
         document_ids: document_ids,
         opts: opts
       }}
    end
  end

  def decode_related(_args), do: {:error, {:invalid_arg, "args"}}

  @doc false
  @spec resolve_config(keyword()) :: {:ok, keyword()} | {:error, tag()}
  def resolve_config(opts) when is_list(opts) do
    {:ok, Config.resolve!(opts)}
  rescue
    error in ArgumentError -> {:error, {:invalid_config, Exception.message(error)}}
  end

  defp fetch_schema(args), do: fetch_module(args, "schema", :unknown_schema, &schema?/1)

  defp fetch_module(args, key, tag, validator) do
    case Map.get(args, key) do
      name when is_binary(name) and name != "" -> resolve_existing_module(name, tag, validator)
      _ -> {:error, {:invalid_arg, key}}
    end
  end

  defp fetch_index(%{"index" => index}) when is_binary(index) and byte_size(index) > 0,
    do: {:ok, index}

  defp fetch_index(_args), do: {:error, {:invalid_arg, "index"}}

  # Ids round-trip through JSON as integers or strings. Anything else would make the
  # loader's query raise (and Oban retry) instead of cancelling, so reject it here.
  defp fetch_document_ids(%{"document_ids" => ids}) when is_list(ids) do
    if Enum.all?(ids, &(is_integer(&1) or is_binary(&1))),
      do: {:ok, ids},
      else: {:error, {:invalid_arg, "document_ids"}}
  end

  defp fetch_document_ids(_args), do: {:error, {:invalid_arg, "document_ids"}}

  defp check_document_count(%{"document_count" => count}, ids)
       when is_integer(count) and count == length(ids),
       do: :ok

  defp check_document_count(_args, _ids), do: {:error, {:invalid_arg, "document_count"}}

  # A named repo that does not resolve is cancelled rather than dropped: loading through
  # a default repo would silently read the wrong data. No repo at all is the path jobs
  # enqueued before 0.3.16 take.
  defp fetch_repo(args) do
    case Map.get(args, "repo") do
      name when is_binary(name) and name != "" ->
        with {:ok, repo} <- resolve_existing_module(name, :unknown_repo, &repo?/1) do
          {:ok, [repo: repo]}
        end

      nil ->
        {:ok, []}

      "" ->
        {:ok, []}

      _other ->
        {:error, {:invalid_arg, "repo"}}
    end
  end

  defp fetch_fan_out(schema, args) do
    case Map.get(args, "fan_out") do
      name when is_binary(name) and name != "" ->
        with {:ok, key} <- existing_atom(name),
             {:ok, config} <- configured_fan_out(schema, key) do
          {:ok, key, config}
        else
          _ -> {:error, {:unknown_fan_out, name}}
        end

      _ ->
        {:error, {:invalid_arg, "fan_out"}}
    end
  end

  defp configured_fan_out(schema, key) do
    Keyword.fetch(Metadata.fan_outs(schema), key)
  rescue
    _error in [UndefinedFunctionError, FunctionClauseError, ArgumentError] -> :error
  end

  defp fetch_opts(%{"opts" => opts}) when is_map(opts), do: {:ok, opts}
  defp fetch_opts(_args), do: {:error, {:invalid_arg, "opts"}}

  # Reads a fixed allowlist of string keys and never walks the map, so no key becomes an
  # atom and a key added by a newer Scrypath during a rolling deploy is ignored rather
  # than stranding the job. nil and "" mean the option is absent.
  @related_opts [
    {"index_prefix", :index_prefix, :string},
    {"meilisearch_url", :meilisearch_url, :string},
    {"backend", :backend, :backend},
    {"otp_app", :otp_app, :otp_app},
    {"repo", :repo, :repo}
  ]

  defp decode_related_opts(opts_map) do
    Enum.reduce_while(@related_opts, {:ok, []}, fn {key, opt, kind}, {:ok, acc} ->
      case decode_opt(kind, key, Map.get(opts_map, key)) do
        :absent -> {:cont, {:ok, acc}}
        {:ok, value} -> {:cont, {:ok, [{opt, value} | acc]}}
        {:error, _tag} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, opts} -> {:ok, Enum.reverse(opts)}
      error -> error
    end
  end

  defp decode_opt(_kind, _key, value) when value in [nil, ""], do: :absent
  defp decode_opt(_kind, key, value) when not is_binary(value), do: {:error, {:invalid_arg, key}}
  defp decode_opt(:string, _key, value), do: {:ok, value}

  defp decode_opt(:backend, _key, name),
    do: resolve_existing_module(name, :unknown_backend, &full_backend?/1)

  defp decode_opt(:repo, _key, name), do: resolve_existing_module(name, :unknown_repo, &repo?/1)

  defp decode_opt(:otp_app, _key, name) do
    with {:ok, app} <- existing_atom(name),
         spec when spec != nil <- Application.spec(app) do
      {:ok, app}
    else
      _ -> {:error, {:unknown_otp_app, name}}
    end
  end

  defp existing_atom(name) do
    {:ok, String.to_existing_atom(name)}
  rescue
    ArgumentError -> :error
  end

  defp schema?(module), do: function_exported?(module, :__scrypath__, 1)

  defp repo?(module), do: function_exported?(module, :__adapter__, 0)

  defp full_backend?(module) do
    function_exported?(module, :upsert_documents, 3) and delete_backend?(module)
  end

  defp delete_backend?(module) do
    function_exported?(module, :delete_documents, 3) and
      function_exported?(module, :index_name, 2)
  end

  # Only the exact `to_string(module)` form ("Elixir.MyApp.Post") resolves, so a name has
  # one spelling and an Erlang module name never reaches a role check.
  defp resolve_existing_module(name, tag, validator) do
    with {:ok, module} <- safe_module(name),
         true <- Atom.to_string(module) == name,
         true <- Code.ensure_loaded?(module),
         true <- validator.(module) do
      {:ok, module}
    else
      _ -> {:error, {tag, name}}
    end
  end

  # Resolves the full module atom, which exists once the module is loaded. Splitting the
  # name and resolving each alias segment does not work in a release: a loaded BEAM adds
  # only `:"Elixir.MyApp.Post"` to the atom table, never the bare `:MyApp` or `:Post`.
  defp safe_module("Elixir." <> _ = name) do
    {:ok, String.to_existing_atom(name)}
  rescue
    ArgumentError -> :error
  end

  defp safe_module(_name), do: :error
end
