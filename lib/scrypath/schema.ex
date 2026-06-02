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

  The macro does not generate runtime APIs such as `search/2` or `reindex/1`.
  """

  alias Scrypath.Options

  defmacro __using__(opts) do
    opts = expand_schema_option_aliases(opts, __CALLER__)
    config = Options.validate_schema_options!(opts)

    quote bind_quoted: [config: Macro.escape(config)] do
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
