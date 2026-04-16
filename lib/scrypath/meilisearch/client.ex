defmodule Scrypath.Meilisearch.Client do
  @moduledoc false

  alias Scrypath.Config
  alias Scrypath.Document
  alias Scrypath.Meilisearch.Query, as: MeilisearchQuery
  alias Scrypath.Query, as: CommonQuery
  alias Scrypath.Telemetry

  @spec upsert_documents(String.t(), [Document.t()], keyword()) :: {:ok, map()} | {:error, term()}
  def upsert_documents(index_name, documents, config) when is_list(documents) do
    run_request(
      :post,
      "/indexes/#{index_name}/documents",
      [json: Enum.map(documents, &document_payload/1)],
      config,
      index: index_name
    )
  end

  @spec delete_documents(String.t(), [term()], keyword()) :: {:ok, map()} | {:error, term()}
  def delete_documents(index_name, document_ids, config) when is_list(document_ids) do
    run_request(
      :post,
      "/indexes/#{index_name}/documents/delete-batch",
      [json: document_ids],
      config,
      index: index_name
    )
  end

  @spec task(term(), keyword()) :: {:ok, map()} | {:error, term()}
  def task(task_uid, config) do
    run_request(:get, "/tasks/#{task_uid}", [], config, task_uid: task_uid)
  end

  @spec search(String.t(), CommonQuery.t() | map() | String.t(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def search(index_name, query, config) do
    run_request(
      :post,
      "/indexes/#{index_name}/search",
      [json: search_payload(query)],
      config,
      index: index_name
    )
  end

  defp run_request(method, path, req_opts, config, extra_metadata) do
    metadata =
      extra_metadata
      |> Map.new()
      |> Map.merge(%{method: method, path: path})

    Telemetry.span([:scrypath, :meilisearch, :request], metadata, fn ->
      response =
        request(config)
        |> Req.request([method: method, url: path] ++ req_opts)

      {normalize_response(response), response_metadata(response)}
    end)
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

  defp response_metadata({:ok, %Req.Response{status: status}}), do: %{status_code: status}
  defp response_metadata({:error, exception}), do: %{error: inspect(exception)}

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
