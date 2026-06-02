defmodule ScrypathEcommerce.Repo do
  use Ecto.Repo,
    otp_app: :scrypath_ecommerce,
    adapter: Ecto.Adapters.Postgres

  require Ecto.Query

  @impl true
  def prepare_query(_operation, query, opts) do
    cond do
      opts[:skip_tenant_id] || opts[:schema_migration] ->
        {query, opts}

      tenant_id = opts[:tenant_id] ->
        {Ecto.Query.where(query, tenant_id: ^tenant_id), opts}

      is_oban_query?(query) ->
        {query, opts}

      true ->
        raise ArgumentError, "expected :tenant_id or :skip_tenant_id to be set in Repo options"
    end
  end

  defp is_oban_query?(%{from: %{source: {source, _}}}) when is_binary(source) do
    String.starts_with?(source, "oban_")
  end

  defp is_oban_query?(_), do: false
end
