defmodule Scrypath.Meilisearch.Client do
  @moduledoc false

  alias Scrypath.Config
  alias Scrypath.Meilisearch.Query, as: MeilisearchQuery
  alias Scrypath.Document
  alias Scrypath.Query, as: CommonQuery

  @spec upsert_documents(String.t(), [Document.t()], keyword()) :: {:ok, map()} | {:error, term()}
  def upsert_documents(index_name, documents, config) when is_list(documents) do
    request(config)
    |> Req.post(
      url: "/indexes/#{index_name}/documents",
      json: Enum.map(documents, &document_payload/1)
    )
    |> normalize_response()
  end

  @spec delete_documents(String.t(), [term()], keyword()) :: {:ok, map()} | {:error, term()}
  def delete_documents(index_name, document_ids, config) when is_list(document_ids) do
    request(config)
    |> Req.post(url: "/indexes/#{index_name}/documents/delete-batch", json: document_ids)
    |> normalize_response()
  end

  @spec task(term(), keyword()) :: {:ok, map()} | {:error, term()}
  def task(task_uid, config) do
    request(config)
    |> Req.get(url: "/tasks/#{task_uid}")
    |> normalize_response()
  end

  @spec search(String.t(), CommonQuery.t() | map() | String.t(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def search(index_name, query, config) do
    request(config)
    |> Req.post(url: "/indexes/#{index_name}/search", json: search_payload(query))
    |> normalize_response()
  end

  defp request(config) do
    options =
      config
      |> Keyword.get(:req_options, [])
      |> Keyword.put_new(:base_url, base_url!(config))
      |> Keyword.update(:headers, default_headers(config), &(default_headers(config) ++ &1))

    Req.new(options)
  end

  defp normalize_response({:ok, %Req.Response{status: status, body: body}})
       when status >= 200 and status < 300 and is_map(body) do
    {:ok, body}
  end

  defp normalize_response({:ok, %Req.Response{status: status, body: body}}) do
    {:error, {:http_error, status, body}}
  end

  defp normalize_response({:error, exception}) do
    {:error, {:transport_error, exception}}
  end

  defp document_payload(%Document{id: id, data: data}) when is_map(data) do
    Map.put(data, :id, id)
  end

  defp search_payload(%CommonQuery{} = query), do: MeilisearchQuery.to_payload(query)
  defp search_payload(query) when is_binary(query), do: %{q: query}
  defp search_payload(query) when is_map(query), do: query

  defp default_headers(config) do
    case Config.meilisearch_api_key(config) do
      nil -> []
      api_key -> [{"x-meili-api-key", api_key}]
    end
  end

  defp base_url!(config) do
    case Config.fetch_meilisearch_url!(config) do
      url when is_binary(url) and url != "" -> url
      _ -> raise ArgumentError, "meilisearch_url is required"
    end
  end
end
