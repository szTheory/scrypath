defmodule Scrypath.Schema do
  @moduledoc false

  alias Scrypath.Options

  defmacro __using__(opts) do
    config = Options.validate_schema_options!(opts)

    quote bind_quoted: [config: Macro.escape(config)] do
      Module.register_attribute(__MODULE__, :scrypath_config, persist: true)
      @scrypath_config config

      def __scrypath__(:config), do: @scrypath_config
      def __scrypath__(:fields), do: @scrypath_config.fields
      def __scrypath__(:filterable), do: @scrypath_config.filterable
      def __scrypath__(:sortable), do: @scrypath_config.sortable
      def __scrypath__(:document_id), do: @scrypath_config.document_id
      def __scrypath__(:document_source), do: @scrypath_config.document_source
      def __scrypath__(:backend), do: @scrypath_config.backend

      def __scrypath__(key) do
        raise ArgumentError, "unknown Scrypath metadata key: #{inspect(key)}"
      end
    end
  end
end
