defmodule ScrypathEcommerceWeb.SearchLive do
  use ScrypathEcommerceWeb, :live_view

  alias Scrypath.SearchResult
  alias ScrypathEcommerce.Catalog
  alias ScrypathEcommerce.Catalog.Product

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    tenant = tenant_from_params(params) || default_tenant()
    text = Map.get(params, "q", "")
    category_id = parse_category_id(Map.get(params, "category_id"))

    results =
      if tenant do
        Product
        |> Scrypath.search(text, search_opts(tenant.id, category_id))
        |> case do
          {:ok, results} -> results
          {:error, _reason} -> empty_results()
        end
      else
        empty_results()
      end

    {:noreply,
     socket
     |> assign(:tenant, tenant)
     |> assign(:results, results)
     |> assign(:category_id, category_id)
     |> assign(:form, to_form(search_form_params(text, category_id, tenant), as: :search))}
  end

  @impl true
  def handle_event("search", %{"search" => params}, socket) do
    query_params =
      params
      |> Map.take(["q", "category_id", "tenant_id"])
      |> Enum.reject(fn {_key, value} -> value in [nil, ""] end)
      |> Map.new()

    {:noreply, push_patch(socket, to: ~p"/?#{query_params}")}
  end

  defp tenant_from_params(%{"tenant_id" => tenant_id}) do
    with {id, ""} <- Integer.parse(tenant_id) do
      Catalog.get_tenant!(id)
    else
      _ -> nil
    end
  rescue
    Ecto.NoResultsError -> nil
  end

  defp tenant_from_params(_params), do: nil

  defp default_tenant do
    Catalog.list_tenants()
    |> Enum.max_by(& &1.id, fn -> nil end)
  end

  defp search_opts(tenant_id, nil) do
    [filter: [tenant_id: tenant_id], facets: [:category_id]]
  end

  defp search_opts(tenant_id, category_id) do
    [filter: [tenant_id: tenant_id, category_id: category_id], facets: [:category_id]]
  end

  defp parse_category_id(nil), do: nil
  defp parse_category_id(""), do: nil

  defp parse_category_id(value) when is_binary(value) do
    case Integer.parse(value) do
      {id, ""} -> id
      _ -> nil
    end
  end

  defp search_form_params(text, nil, tenant) do
    %{"q" => text, "category_id" => "", "tenant_id" => tenant_id_param(tenant)}
  end

  defp search_form_params(text, category_id, tenant) do
    %{"q" => text, "category_id" => to_string(category_id), "tenant_id" => tenant_id_param(tenant)}
  end

  defp tenant_id_param(%{id: id}), do: to_string(id)
  defp tenant_id_param(_), do: ""

  defp empty_results do
    %SearchResult{
      query: nil,
      hits: [],
      records: [],
      raw: %{},
      missing_ids: [],
      page: %{},
      facets: %Scrypath.SearchResult.Facets{}
    }
  end
end
