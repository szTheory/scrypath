defmodule Scrypath.Schema do
  @moduledoc """
  Metadata-only schema declaration support for `use Scrypath`.

  `Scrypath.Schema` validates declaration options, stores normalized metadata on the
  schema module, and exposes that metadata through `__scrypath__/1`.

  The initial declaration surface supports these `__scrypath__/1` keys:

  - `:config`
  - `:fields`
  - `:filterable`
  - `:faceting`
  - `:sortable`
  - `:settings`
  - `:document_id`
  - `:document_source`
  - `:backend`
  - `:tenant_field`
  - `:fan_outs`
  - `:preload`

  The macro does not generate runtime APIs such as `search/2` or `reindex/1`.

  ## Hooks

  `use Scrypath` makes the schema module implement the `Scrypath.Schema` behaviour.
  Define these callbacks on the schema module to change how Scrypath builds and loads
  documents:

  - `c:search_document/1`: build the document yourself, for computed or nested values
    that `fields:` cannot express.
  - `c:search_document_id/1`: use a document id other than the `document_id:` field.
  - `c:search_records/2`: load records by document id yourself, for custom ids,
    soft deletes or preloads that a plain Ecto query cannot express.

  All three are optional. When a hook is absent, Scrypath projects the declared
  `fields:`, reads the `document_id:` field and loads records with an Ecto query.

  A hook defined at the wrong arity, such as `search_records/1`, triggers a compile
  warning, because Scrypath would otherwise ignore it at runtime.

  If the schema module uses `@impl` for any other behaviour, Elixir expects `@impl`
  on every callback, so mark the hooks with `@impl Scrypath.Schema`.
  """

  alias Scrypath.Options

  @doc """
  Builds the search document for `record`.

  When defined, Scrypath uses the returned map instead of projecting the declared
  `fields:`. The callback must return a map. An `:id` (or `"id"`) key in the map
  overrides the document id. When the schema declares `tenant_field:`, Scrypath
  still adds the tenant value to the document.
  """
  @callback search_document(record :: struct() | map()) :: map()

  @doc """
  Returns the search document id for `record`.

  When defined, Scrypath uses the returned value instead of reading the
  `document_id:` field. If you sync through Oban, also define
  `c:search_records/2`, because the job cannot map a custom id back to a row:
  without it, enqueueing returns `{:error, :search_records_required}`.
  """
  @callback search_document_id(record :: struct() | map()) :: term()

  @doc """
  Loads the current records for `document_ids`.

  Scrypath calls this during Oban sync and backfill with at most 1000 deduplicated
  ids per call and a context map `%{repo: repo}`, where `repo` may be `nil`. The
  callback must return a list. Ids whose records are not returned are treated as
  missing, so their documents are deleted from the index.

  When the callback is absent, Scrypath loads records with an Ecto query on the
  `document_id:` field through the configured repo.
  """
  @callback search_records(
              document_ids :: [term()],
              context :: %{required(:repo) => module() | nil}
            ) :: [struct() | map()]

  @optional_callbacks [search_document: 1, search_document_id: 1, search_records: 2]

  @hooks [search_document: 1, search_document_id: 1, search_records: 2]

  @doc false
  defmacro __before_compile__(env) do
    defs = Module.definitions_in(env.module, :def)

    for {name, arity} <- @hooks,
        arities = defs |> Enum.filter(&(elem(&1, 0) == name)) |> Enum.map(&elem(&1, 1)),
        arities != [] and arity not in arities do
      arities = Enum.sort(arities)
      line = hook_definition_line(env, {name, hd(arities)})

      IO.warn(
        "[scrypath] #{inspect(env.module)} defines " <>
          Enum.map_join(arities, ", ", &"#{name}/#{&1}") <>
          " but Scrypath calls #{name}/#{arity}; the hook is ignored at runtime",
        file: env.file,
        line: line
      )
    end

    :ok
  end

  defp hook_definition_line(env, name_arity) do
    case Module.get_definition(env.module, name_arity) do
      {:v1, _kind, meta, _clauses} -> Keyword.get(meta, :line, env.line)
      _ -> env.line
    end
  end

  defmacro __using__(opts) do
    opts = expand_schema_option_aliases(opts, __CALLER__)
    config = Options.validate_schema_options!(opts)

    quote bind_quoted: [config: Macro.escape(config)] do
      @behaviour Scrypath.Schema
      @before_compile Scrypath.Schema

      Module.register_attribute(__MODULE__, :scrypath_config, persist: true)
      @scrypath_config config

      def __scrypath__(:config), do: @scrypath_config
      def __scrypath__(:fields), do: @scrypath_config.fields
      def __scrypath__(:filterable), do: @scrypath_config.filterable
      def __scrypath__(:faceting), do: @scrypath_config.faceting
      def __scrypath__(:sortable), do: @scrypath_config.sortable
      def __scrypath__(:settings), do: @scrypath_config.settings
      def __scrypath__(:document_id), do: @scrypath_config.document_id
      def __scrypath__(:document_source), do: @scrypath_config.document_source
      def __scrypath__(:backend), do: @scrypath_config.backend
      def __scrypath__(:tenant_field), do: @scrypath_config.tenant_field
      def __scrypath__(:fan_outs), do: @scrypath_config.fan_outs
      def __scrypath__(:preload), do: @scrypath_config.preload

      def __scrypath__(key) do
        raise ArgumentError, "unknown Scrypath metadata key: #{inspect(key)}"
      end
    end
  end

  defp expand_schema_option_aliases(opts, env) when is_list(opts) do
    Enum.map(opts, fn
      {:backend, backend} -> {:backend, expand_module_alias(backend, env)}
      {:fan_outs, fan_outs} -> {:fan_outs, expand_fan_out_aliases(fan_outs, env)}
      option -> option
    end)
  end

  defp expand_schema_option_aliases(opts, _env), do: opts

  defp expand_fan_out_aliases(fan_outs, env) when is_list(fan_outs) do
    Enum.map(fan_outs, fn
      {name, config} when is_list(config) ->
        {name,
         Enum.map(config, fn
           {:target, target} ->
             {:target, expand_module_alias(target, env)}

           {:resolver, {:{}, _meta, [module, function, args]}} ->
             {:resolver, {expand_module_alias(module, env), function, args}}

           {:resolver, {module, function, args}} ->
             {:resolver, {expand_module_alias(module, env), function, args}}

           option ->
             option
         end)}

      entry ->
        entry
    end)
  end

  defp expand_fan_out_aliases(fan_outs, _env), do: fan_outs

  defp expand_module_alias(module, env) do
    Macro.expand(module, env)
  end
end
