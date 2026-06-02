defmodule ScrypathEcommerceWeb.SearchLive do
  use ScrypathEcommerceWeb, :live_view

  alias Scrypath.SearchResult
  alias ScrypathEcommerce.Catalog
  alias ScrypathEcommerce.Catalog.Product
  alias ScrypathEcommerce.Repo

  import Ecto.Query, only: [preload: 2, where: 3]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    tenant = tenant_from_params(params) || default_tenant()
    text = Map.get(params, "q", "")
    category_id = parse_category_id(Map.get(params, "category_id"))
    tenants = Catalog.list_tenants()
    categories = if tenant, do: Catalog.list_categories(tenant), else: []

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
     |> assign(:tenants, tenants)
     |> assign(:categories, categories)
     |> assign(:category_labels, category_labels(categories))
     |> assign(:product_summaries, product_summaries(results.hits))
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
    %{
      "q" => text,
      "category_id" => to_string(category_id),
      "tenant_id" => tenant_id_param(tenant)
    }
  end

  defp tenant_id_param(%{id: id}), do: to_string(id)
  defp tenant_id_param(_), do: ""

  defp category_labels(categories) do
    Map.new(categories, &{to_string(&1.id), &1.name})
  end

  defp category_label(labels, value) do
    Map.get(labels, to_string(value), "Category #{value}")
  end

  defp product_summaries(hits) do
    ids =
      hits
      |> Enum.map(&hit_value(&1, "id"))
      |> Enum.map(&parse_id/1)
      |> Enum.reject(&is_nil/1)

    Product
    |> where([product], product.id in ^ids)
    |> preload([:category, :variants])
    |> Repo.all(skip_tenant_id: true)
    |> Map.new(fn product ->
      {to_string(product.id),
       %{
         category: product.category && product.category.name,
         price: price_range(product.variants),
         inventory: total_inventory(product.variants),
         variants: length(product.variants)
       }}
    end)
  end

  defp hit_summary(summaries, hit), do: Map.get(summaries, to_string(hit_value(hit, "id")), %{})

  defp hit_value(hit, key) when is_map(hit), do: hit[key] || hit[String.to_atom(key)]
  defp hit_value(_hit, _key), do: nil

  defp parse_id(value) when is_integer(value), do: value

  defp parse_id(value) when is_binary(value) do
    case Integer.parse(value) do
      {id, ""} -> id
      _ -> nil
    end
  end

  defp parse_id(_value), do: nil

  defp price_range([]), do: nil

  defp price_range(variants) do
    prices = Enum.map(variants, & &1.price_cents)
    min = Enum.min(prices)
    max = Enum.max(prices)

    if min == max do
      format_price(min)
    else
      "#{format_price(min)} - #{format_price(max)}"
    end
  end

  defp total_inventory(variants), do: Enum.reduce(variants, 0, &(&1.inventory_count + &2))

  defp format_price(cents) when is_integer(cents) do
    dollars = div(cents, 100)
    cents = cents |> rem(100) |> Integer.to_string() |> String.pad_leading(2, "0")
    "$#{dollars}.#{cents}"
  end

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
