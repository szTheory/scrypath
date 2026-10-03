defmodule ScrypathOps.DocumentObservation do
  @moduledoc """
  Checks whether a completed Meilisearch task's expected document effects are visible.

  This module only observes backend state. It never enqueues or retries work.
  """

  @max_expected_count 50
  @max_expected_bytes 65_536
  @observation_timeout 8_000

  @type observation :: %{
          state: :verified | :running | :failed | :unknown,
          reason: atom() | nil,
          checked_at: DateTime.t(),
          evidence: map()
        }

  @doc "Checks expected document effects against the configured Meilisearch server."
  @spec check(map(), map(), keyword()) :: {:ok, observation()}
  def check(receipt, task, runtime_opts) do
    worker = Task.async(fn -> check_now(receipt, task, runtime_opts) end)

    case Task.yield(worker, @observation_timeout) do
      {:ok, result} ->
        result

      nil ->
        Task.shutdown(worker, :brutal_kill)
        result(:unknown, :observation_timeout, %{})
    end
  rescue
    _ -> result(:unknown, :observation_error, %{})
  end

  defp check_now(receipt, task, runtime_opts) do
    base_evidence = %{
      operation: value(receipt, :operation),
      index: value(receipt, :index),
      task_uid: value(receipt, :task_uid)
    }

    with :ok <- valid_receipt(receipt),
         {:ok, expected, encoded_size} <- bounded_expected(receipt),
         {:ok, task_status} <- task_status(task, receipt) do
      evidence =
        Map.merge(base_evidence, %{expected_count: length(expected), expected_bytes: encoded_size})

      case task_status do
        status when status in ["enqueued", "processing"] ->
          result(:running, :task_in_progress, evidence)

        "failed" ->
          result(:failed, :task_failed, evidence)

        "succeeded" ->
          observe_effects(receipt, expected, runtime_opts, evidence)

        _ ->
          result(:unknown, :unknown_task_status, evidence)
      end
    else
      {:error, reason} -> result(:unknown, reason, base_evidence)
    end
  rescue
    _ -> result(:unknown, :observation_error, %{})
  end

  defp observe_effects(receipt, expected, runtime_opts, evidence) do
    with {:ok, base_url} <- configured_base_url(runtime_opts),
         request <- request(runtime_opts, base_url),
         :ok <- observe_operation(request, receipt, expected, runtime_opts) do
      result(:verified, nil, evidence)
    else
      {:error, reason} -> result(state_for_reason(reason), reason, evidence)
    end
  end

  defp observe_operation(request, %{operation: :upsert} = receipt, expected, runtime_opts) do
    field = Keyword.get(runtime_opts, :document_id_field, :id)
    check_upserts(request, receipt.index, expected, field)
  end

  defp observe_operation(request, receipt, expected, _runtime_opts) do
    with :ok <- index_exists(request, receipt.index),
         :ok <- check_deletes(request, receipt.index, expected) do
      :ok
    end
  end

  defp check_upserts(request, index, expected, id_field) do
    Enum.reduce_while(expected, :ok, fn expected_doc, :ok ->
      id = fetch_value(expected_doc, :id)
      data = fetch_value(expected_doc, :data)

      with {:ok, expected_doc} <- projected_document(data, id_field, id),
           {:ok, actual_doc} <- fetch_document(request, index, id),
           true <- expected_values_match?(actual_doc, expected_doc) do
        {:cont, :ok}
      else
        {:error, reason} -> {:halt, {:error, reason}}
        false -> {:halt, {:error, :document_mismatch}}
      end
    end)
  end

  defp check_deletes(request, index, ids) do
    Enum.reduce_while(ids, :ok, fn id, :ok ->
      case get(request, document_path(index, id)) do
        {:ok, %{status: 404, body: %{"code" => code}}}
        when code in ["document_not_found", "not_found"] ->
          {:cont, :ok}

        {:ok, %{status: 200}} ->
          {:halt, {:error, :document_still_present}}

        {:ok, %{status: 404, body: %{"code" => "index_not_found"}}} ->
          {:halt, {:error, :index_not_found}}

        {:ok, _} ->
          {:halt, {:error, :document_observation_http_error}}

        {:error, _} ->
          {:halt, {:error, :document_observation_transport_error}}
      end
    end)
  end

  defp index_exists(request, index) do
    case get(request, index_path(index)) do
      {:ok, %{status: status, body: %{"uid" => ^index}}} when status in 200..299 -> :ok
      {:ok, %{status: 404, body: %{"code" => "index_not_found"}}} -> {:error, :index_not_found}
      {:ok, _} -> {:error, :index_observation_http_error}
      {:error, _} -> {:error, :index_observation_transport_error}
    end
  end

  defp fetch_document(request, index, id) do
    case get(request, document_path(index, id)) do
      {:ok, %{status: status, body: body}} when status in 200..299 and is_map(body) ->
        {:ok, body}

      {:ok, %{status: 404, body: %{"code" => code}}}
      when code in ["document_not_found", "not_found"] ->
        {:error, :document_not_found}

      {:ok, %{status: 404, body: %{"code" => "index_not_found"}}} ->
        {:error, :index_not_found}

      {:ok, _} ->
        {:error, :document_observation_http_error}

      {:error, _} ->
        {:error, :document_observation_transport_error}
    end
  end

  defp projected_document(data, id_field, id) when is_map(data) do
    field = to_string(id_field)

    data
    |> stringify_keys()
    |> Map.put(field, id)
    |> json_round_trip()
  end

  defp projected_document(_, _, _), do: {:error, :invalid_expected_document}

  defp expected_values_match?(actual, expected) when is_map(actual) and is_map(expected) do
    Enum.all?(expected, fn {key, value} -> Map.fetch(actual, key) == {:ok, value} end)
  end

  defp expected_values_match?(_, _), do: false

  defp stringify_keys(map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_nested_keys(value)} end)
  end

  defp stringify_nested_keys(value) when is_map(value), do: stringify_keys(value)

  defp stringify_nested_keys(value) when is_list(value),
    do: Enum.map(value, &stringify_nested_keys/1)

  defp stringify_nested_keys(value), do: value

  defp json_round_trip(value) do
    with {:ok, json} <- Jason.encode(value),
         {:ok, decoded} <- Jason.decode(json) do
      {:ok, decoded}
    else
      _ -> {:error, :invalid_expected_document}
    end
  end

  defp bounded_expected(receipt) do
    expected = value(receipt, :expected)

    cond do
      not is_list(expected) ->
        {:error, :invalid_expected_effects}

      expected == [] ->
        {:error, :empty_expected_effects}

      length(expected) > @max_expected_count ->
        {:error, :expected_effects_out_of_bounds}

      not valid_expected?(value(receipt, :operation), expected) ->
        {:error, :invalid_expected_effects}

      true ->
        encode_bounded_expected(value(receipt, :operation), expected)
    end
  end

  defp encode_bounded_expected(operation, expected) do
    with {:ok, encoded} <- Jason.encode(expected_payload(operation, expected)),
         true <- byte_size(encoded) <= @max_expected_bytes do
      {:ok, expected, byte_size(encoded)}
    else
      false -> {:error, :expected_effects_out_of_bounds}
      _ -> {:error, :invalid_expected_effects}
    end
  end

  defp valid_expected?(:upsert, expected) do
    Enum.all?(expected, fn item ->
      id = fetch_value(item, :id)
      data = fetch_value(item, :data)
      (is_binary(id) or is_integer(id)) and is_map(data)
    end)
  end

  defp valid_expected?(:delete, expected) do
    Enum.all?(expected, &(is_binary(&1) or is_integer(&1)))
  end

  defp valid_expected?(_, _), do: false

  defp expected_payload(:upsert, expected) do
    Enum.map(expected, fn
      %{id: id, data: data} -> %{"id" => id, "data" => data}
      %{"id" => id, "data" => data} -> %{"id" => id, "data" => data}
      other -> other
    end)
  end

  defp expected_payload(:delete, expected), do: expected
  defp expected_payload(_, expected), do: expected

  defp valid_receipt(receipt) when is_map(receipt) do
    operation = value(receipt, :operation)
    index = value(receipt, :index)
    task_uid = value(receipt, :task_uid)

    cond do
      operation not in [:upsert, :delete] -> {:error, :invalid_operation}
      not is_binary(index) or index == "" -> {:error, :invalid_index}
      not is_integer(task_uid) or task_uid < 0 -> {:error, :invalid_task_uid}
      true -> :ok
    end
  end

  defp valid_receipt(_), do: {:error, :invalid_receipt}

  defp task_status(task, receipt) when is_map(task) do
    uid = fetch_value(task, :uid) || fetch_value(task, :task_uid) || fetch_value(task, :taskUid)
    status = fetch_value(task, :status)

    cond do
      not is_nil(uid) and to_string(uid) != to_string(value(receipt, :task_uid)) ->
        {:error, :task_uid_mismatch}

      is_binary(status) or is_atom(status) ->
        {:ok, status |> to_string() |> String.downcase()}

      true ->
        {:error, :invalid_task_payload}
    end
  end

  defp task_status(_, _), do: {:error, :invalid_task_payload}

  defp configured_base_url(opts) do
    case Keyword.get(opts, :meilisearch_url) do
      url when is_binary(url) and url != "" -> {:ok, String.trim_trailing(url, "/")}
      _ -> {:error, :meilisearch_not_configured}
    end
  end

  defp request(runtime_opts, base_url) do
    req_opts = Keyword.get(runtime_opts, :req_options, [])

    safe_opts =
      req_opts
      |> Keyword.drop([:base_url, :url, :method, :auth])
      |> Keyword.update(:headers, [], &drop_auth_headers/1)
      |> Keyword.put(:retry, false)
      |> Keyword.put(:connect_options, connect_options(req_opts))
      |> Keyword.put(:receive_timeout, min(Keyword.get(req_opts, :receive_timeout, 5_000), 5_000))
      |> Keyword.put(:base_url, base_url)

    req = Req.new(safe_opts)

    case Keyword.get(runtime_opts, :meilisearch_api_key) do
      key when is_binary(key) and key != "" -> Req.Request.put_header(req, "x-meili-api-key", key)
      _ -> req
    end
  end

  defp connect_options(req_opts) do
    req_opts
    |> Keyword.get(:connect_options, [])
    |> Keyword.put(
      :timeout,
      min(Keyword.get(Keyword.get(req_opts, :connect_options, []), :timeout, 2_000), 2_000)
    )
  end

  defp drop_auth_headers(headers) do
    Enum.reject(headers, fn
      {name, _value} -> String.downcase(to_string(name)) == "x-meili-api-key"
      _ -> false
    end)
  end

  defp get(request, path) do
    case Req.request(request, method: :get, url: path, decode_body: true, retry: false) do
      {:ok, %Req.Response{status: status, body: body}} -> {:ok, %{status: status, body: body}}
      {:error, error} -> {:error, error}
    end
  end

  defp index_path(index), do: "/indexes/" <> encode_segment(index)
  defp document_path(index, id), do: index_path(index) <> "/documents/" <> encode_segment(id)

  defp encode_segment(value) do
    value
    |> to_string()
    |> URI.encode(&URI.char_unreserved?/1)
  end

  defp state_for_reason(reason)
       when reason in [:document_not_found, :document_mismatch, :document_still_present],
       do: :failed

  defp state_for_reason(_), do: :unknown

  defp result(state, reason, evidence) do
    {:ok,
     %{
       state: state,
       reason: reason,
       checked_at: DateTime.utc_now(),
       evidence: evidence
     }}
  end

  defp value(map, key) when is_map(map), do: fetch_value(map, key)
  defp value(_, _), do: nil

  defp fetch_value(map, key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end
end
