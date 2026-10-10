defmodule ScrypathEcommerce.E2ERecovery do
  @moduledoc false

  import Ecto.Query

  alias Oban.Job
  alias Scrypath.Meilisearch.Client
  alias Scrypath.Meilisearch.Tasks
  alias ScrypathEcommerce.Catalog.Product
  alias ScrypathEcommerce.Catalog.Tenant
  alias ScrypathEcommerce.Catalog.Variant
  alias ScrypathEcommerce.Repo
  alias ScrypathOps.RecoveryObservation

  @variant_schema "Elixir.ScrypathEcommerce.Catalog.Variant"
  @product_schema "Elixir.ScrypathEcommerce.Catalog.Product"
  @backend "Elixir.Scrypath.Meilisearch"

  @doc "Creates one retained failed Variant job whose unique projected document is absent from the active index."
  def prepare(tenant_id, marker) when is_integer(tenant_id) and is_binary(marker) do
    marker = safe_marker!(marker)
    tenant = Repo.get!(Tenant, tenant_id, skip_tenant_id: true)

    product =
      Product
      |> where([product], product.tenant_id == ^tenant_id)
      |> order_by([product], asc: product.id)
      |> limit(1)
      |> Repo.one!(skip_tenant_id: true)

    variant =
      %Variant{tenant_id: tenant.id}
      |> Variant.changeset(%{
        product_id: product.id,
        sku: "SCRY-RECOVERY-#{marker}",
        price_cents: 1000,
        options: %{"e2e_recovery" => marker}
      })
      |> Repo.insert!(skip_tenant_id: true)
      |> Repo.preload(:product, skip_tenant_id: true)

    config = Scrypath.Config.resolve!(sync_mode: :manual)
    index = Scrypath.Meilisearch.index_name(Variant, config)
    document = Scrypath.Projection.document(Variant, variant)
    expected = document_payload(document)

    :absent = ensure_document_absent!(index, document.id, config)
    task_baseline = max_task_uid!(config)

    args = %{
      "operation" => "upsert",
      "schema" => @variant_schema,
      "backend" => @backend,
      "index" => index,
      "scenario_key" => "phase172_recovery_#{marker}",
      "task_baseline" => task_baseline,
      "document_count" => 1,
      "document_ids" => [document.id],
      "documents" => [
        %{
          "id" => document.id,
          "source" => to_string(document.source),
          "data" => stringify_keys(document.data)
        }
      ]
    }

    original =
      %Job{}
      |> Ecto.Changeset.cast(
        %{
          worker: "Scrypath.Oban.UpsertWorker",
          queue: "scrypath_sync",
          args: args,
          state: "discarded",
          attempt: 1,
          max_attempts: 1,
          errors: [
            %{
              "attempt" => 1,
              "at" => DateTime.to_iso8601(DateTime.utc_now()),
              "error" => "** (Req.TransportError) deterministic Phase172 replayable failure"
            }
          ],
          attempted_at: DateTime.utc_now(),
          scheduled_at: DateTime.utc_now()
        },
        [
          :worker,
          :queue,
          :args,
          :state,
          :attempt,
          :max_attempts,
          :errors,
          :attempted_at,
          :scheduled_at
        ]
      )
      |> Repo.insert!()

    %{
      marker: marker,
      schema: @variant_schema,
      index: index,
      original_job_id: original.id,
      original_attempt: original.attempt,
      document_id: document.id,
      expected_sku: Map.fetch!(expected, "sku"),
      expected: expected,
      task_baseline: task_baseline
    }
  end

  @doc "Prepares one discarded, source-qualified delete retry for the mounted browser fixture."
  def prepare_delete(tenant_id, marker) when is_integer(tenant_id) and is_binary(marker) do
    marker = safe_marker!(marker)
    _tenant = Repo.get!(Tenant, tenant_id, skip_tenant_id: true)

    product =
      Product
      |> where([product], product.tenant_id == ^tenant_id)
      |> order_by([product], asc: product.id)
      |> limit(1)
      |> Repo.one!(skip_tenant_id: true)

    config = Scrypath.Config.resolve!(sync_mode: :manual)
    index = Scrypath.Meilisearch.index_name(Product, config)

    case read_document(index, product.id, config) do
      {:ok, _document} ->
        :ok

      other ->
        raise ArgumentError,
              "delete recovery fixture requires an active source document: #{inspect(other)}"
    end

    scenario_key = "phase175_delete_recovery_#{marker}"
    now = DateTime.utc_now()

    args = %{
      "operation" => "delete",
      "schema" => @product_schema,
      "backend" => @backend,
      "index" => index,
      "scenario_key" => scenario_key,
      "document_count" => 1,
      "document_ids" => [product.id]
    }

    original =
      %Job{}
      |> Ecto.Changeset.cast(
        %{
          worker: "Scrypath.Oban.DeleteWorker",
          queue: "scrypath_sync",
          args: args,
          state: "discarded",
          attempt: 1,
          max_attempts: 1,
          errors: [
            %{
              "attempt" => 1,
              "at" => DateTime.to_iso8601(now),
              "error" => "** (Req.TransportError) deterministic Phase 175 delete retry fixture"
            }
          ],
          attempted_at: now,
          scheduled_at: now
        },
        [
          :worker,
          :queue,
          :args,
          :state,
          :attempt,
          :max_attempts,
          :errors,
          :attempted_at,
          :scheduled_at
        ]
      )
      |> Repo.insert!()

    %{
      marker: marker,
      schema: @product_schema,
      index: index,
      original_job_id: original.id,
      original_attempt: original.attempt,
      document_id: product.id,
      expected_name: product.name
    }
  end

  @doc "Verifies a delete retry's exact completed Oban job/task and active-index absence."
  def probe_delete(
        marker,
        original_job_id,
        accepted_job_id,
        handle,
        host,
        generation,
        expected_task_uid,
        index,
        expected_document_id
      )
      when is_binary(marker) and is_integer(original_job_id) and is_integer(accepted_job_id) and
             is_binary(handle) and is_binary(host) and is_integer(generation) and
             is_integer(expected_task_uid) and is_binary(index) and
             is_integer(expected_document_id) do
    marker = safe_marker!(marker)
    config = Scrypath.Config.resolve!(sync_mode: :manual)
    expected_index = Scrypath.Meilisearch.index_name(Product, config)
    true = index == expected_index

    original = Repo.get!(Job, original_job_id, skip_tenant_id: true)
    assert_fixture!(original.state == "discarded", :original_job_state, original.state)

    assert_fixture!(
      get_arg(original.args, "scenario_key") == "phase175_delete_recovery_#{marker}",
      :original_scenario_key,
      get_arg(original.args, "scenario_key")
    )

    assert_fixture!(accepted_job_id != original_job_id, :accepted_job_id, accepted_job_id)
    job = Repo.get!(Job, accepted_job_id, skip_tenant_id: true)
    args = job.args
    assert_fixture!(job.worker == "Scrypath.Oban.DeleteWorker", :worker, job.worker)
    assert_fixture!(job.queue == "scrypath_sync", :queue, job.queue)
    assert_fixture!(job.state == "completed", :job_state, job.state)

    assert_fixture!(
      get_arg(args, "operation") == "delete",
      :operation,
      get_arg(args, "operation")
    )

    assert_fixture!(get_arg(args, "schema") == @product_schema, :schema, get_arg(args, "schema"))
    assert_fixture!(get_arg(args, "index") == expected_index, :index, get_arg(args, "index"))

    assert_fixture!(
      get_arg(args, "document_ids") == [expected_document_id],
      :document_ids,
      get_arg(args, "document_ids")
    )

    assert_fixture!(
      get_arg(original.args, "document_ids") == [expected_document_id],
      :original_document_ids,
      get_arg(original.args, "document_ids")
    )

    context = %{
      host: host,
      org: nil,
      schema: "ScrypathEcommerce.Catalog.Product",
      generation: generation
    }

    receipt = RecoveryObservation.observe(context, handle)
    assert_fixture!(is_map(receipt), :receipt, receipt)

    assert_fixture!(
      receipt.source_failure.id == original_job_id,
      :source_id,
      receipt.source_failure.id
    )

    assert_fixture!(
      receipt.replacement_job == accepted_job_id,
      :replacement_job,
      receipt.replacement_job
    )

    assert_fixture!(receipt.attempt == job.attempt, :attempt, receipt.attempt)
    assert_fixture!(receipt.schema == @product_schema, :receipt_schema, receipt.schema)
    assert_fixture!(receipt.index == expected_index, :receipt_index, receipt.index)
    assert_fixture!(receipt.task_uid == expected_task_uid, :receipt_task_uid, receipt.task_uid)

    task_uid = receipt.task_uid
    {:ok, task} = Client.task(task_uid, config)
    assert_fixture!(task_uid == task_uid_of(task), :task_uid, task_uid_of(task))
    assert_fixture!(task_status(task) == "succeeded", :task_status, task_status(task))
    assert_fixture!(task_index(task) == expected_index, :task_index, task_index(task))
    assert_fixture!(task_type(task) == "documentDeletion", :task_type, task_type(task))
    :absent = ensure_document_absent!(expected_index, expected_document_id, config)

    %{
      marker: marker,
      accepted_job_id: job.id,
      accepted_attempt: job.attempt,
      task_uid: task_uid,
      task_status: task_status(task),
      task_type: task_type(task),
      task_index: task_index(task),
      document_id: expected_document_id,
      active_document_absent: true
    }
  end

  @doc "Joins a rendered retry receipt to its exact accepted job, worker task, terminal Meili task, and active document."
  def probe_recovery(
        marker,
        accepted_job_id,
        handle,
        host,
        generation,
        expected_task_uid,
        expected_document_id
      )
      when is_binary(marker) and is_integer(accepted_job_id) and is_binary(handle) and
             is_binary(host) and is_integer(generation) do
    marker = safe_marker!(marker)
    source = recovery_source!(marker)
    config = Scrypath.Config.resolve!(sync_mode: :manual)
    index = Scrypath.Meilisearch.index_name(Variant, config)

    job = Repo.get!(Job, accepted_job_id, skip_tenant_id: true)
    true = accepted_job_id != source.id
    true = job.worker == "Scrypath.Oban.UpsertWorker"
    true = job.queue == "scrypath_sync"
    true = job.state == "completed"
    true = get_arg(job.args, "schema") == @variant_schema
    true = get_arg(job.args, "backend") == @backend
    true = get_arg(job.args, "index") == index
    [accepted_document] = get_arg(job.args, "documents")

    context = %{
      host: host,
      org: nil,
      schema: "ScrypathEcommerce.Catalog.Variant",
      generation: generation
    }

    receipt = RecoveryObservation.observe(context, handle)
    true = is_map(receipt)
    true = receipt.replacement_job == accepted_job_id
    true = receipt.attempt == job.attempt
    true = receipt.schema == @variant_schema
    true = receipt.index == index
    true = receipt.source_failure.id == source.id

    task_uid = receipt.task_uid
    true = is_integer(task_uid) and task_uid > source.task_baseline
    true = task_uid == expected_task_uid
    {:ok, task} = Client.task(task_uid, config)
    true = task_uid == task_uid_of(task)
    true = task_status(task) == "succeeded"
    true = task_index(task) == index
    true = task_type(task) == "documentAdditionOrUpdate"

    expected = recovery_expected!(source)
    true = accepted_document == expected
    [expected_id] = get_arg(job.args, "document_ids")
    true = expected["id"] == expected_id
    true = expected_id == expected_document_id
    {:ok, document} = read_document(index, expected_id, config)
    true = expected_values_match?(document, expected["data"])
    true = Map.get(document, "sku") == "SCRY-RECOVERY-#{marker}"

    true =
      is_binary(Map.get(document, "options")) and String.contains?(document["options"], marker)

    %{
      marker: marker,
      schema: @variant_schema,
      index: index,
      original_job_id: source.id,
      original_attempt: source.attempt,
      accepted_job_id: job.id,
      accepted_attempt: job.attempt,
      task_uid: task_uid,
      task_status: task_status(task),
      task_type: task_type(task),
      task_index: task_index(task),
      document_id: expected["id"],
      expected_sku: expected["data"]["sku"],
      active_document: true
    }
  end

  @doc "Prepares unique target-only Product content and returns the current index pair and task baseline."
  def prepare_swap(tenant_id, marker) when is_integer(tenant_id) and is_binary(marker) do
    marker = safe_marker!(marker)
    tenant = Repo.get!(Tenant, tenant_id, skip_tenant_id: true)

    category =
      ScrypathEcommerce.Catalog.Category
      |> where([category], category.tenant_id == ^tenant_id)
      |> order_by([category], asc: category.id)
      |> limit(1)
      |> Repo.one!(skip_tenant_id: true)

    product =
      %Product{tenant_id: tenant.id}
      |> Product.changeset(%{
        name: "SCRY-SWAP-#{marker}",
        description: "phase172 swap marker #{marker}",
        category_id: category.id
      })
      |> Repo.insert!(skip_tenant_id: true)
      |> Repo.preload(:category, skip_tenant_id: true)

    config = Scrypath.Config.resolve!(sync_mode: :manual)
    backend = Scrypath.Config.fetch_backend!(config)
    live_index = Scrypath.Meilisearch.index_name(Product, config)
    target_index = Scrypath.Meilisearch.IndexManagement.target_index_name(Product, config)
    target_config = Keyword.put(config, :index_name, target_index)
    ensure_index_settings!(backend, Product, live_index, config)
    ensure_index_settings!(backend, Product, target_index, config)
    document = Scrypath.Projection.document(Product, product)
    expected = document_payload(document)

    :absent = ensure_document_absent!(live_index, document.id, config)

    case backend.upsert_documents(Product, [document], target_config) do
      {:ok, %{task: task}} ->
        case Tasks.wait_for_task(task, config) do
          {:ok, _} ->
            :ok

          {:error, reason} ->
            raise ArgumentError, "prepare swap marker failed: #{inspect(reason)}"
        end

      {:error, reason} ->
        raise ArgumentError, "prepare swap marker failed: #{inspect(reason)}"
    end

    :present = ensure_expected_document!(target_index, document.id, expected, config)
    seed_swap_pair!(live_index, target_index, config)
    seed_swap_pair!(target_index, live_index, config)
    :absent = ensure_document_absent!(live_index, document.id, config)
    :present = ensure_expected_document!(target_index, document.id, expected, config)
    task_baseline = max_swap_task_uid!(config)

    %{
      marker: marker,
      schema: @product_schema,
      live_index: live_index,
      target_index: target_index,
      document_id: document.id,
      expected_name: expected["name"],
      task_baseline: task_baseline
    }
  end

  @doc "Accepts only the returned swap task, its exact index pair, and this run's active-index document."
  def probe_swap(marker, task_uid, live_index, target_index, task_baseline, expected_document_id)
      when is_binary(marker) and is_integer(task_uid) and is_binary(live_index) and
             is_binary(target_index) and is_integer(task_baseline) and
             is_integer(expected_document_id) do
    marker = safe_marker!(marker)
    config = Scrypath.Config.resolve!(sync_mode: :manual)
    true = live_index == Scrypath.Meilisearch.index_name(Product, config)
    true = target_index == Scrypath.Meilisearch.IndexManagement.target_index_name(Product, config)

    source =
      Product
      |> where([product], product.name == ^"SCRY-SWAP-#{marker}")
      |> Repo.one!(skip_tenant_id: true)

    true = source.id == expected_document_id
    true = task_uid > task_baseline
    {:ok, task} = Client.task(task_uid, config)
    true = task_uid == task_uid_of(task)
    true = task_type(task) == "indexSwap"
    true = task_status(task) == "succeeded"
    true = swap_pair?(task, live_index, target_index)

    {:ok, document} = read_document(live_index, source.id, config)
    true = Map.get(document, "name") == "SCRY-SWAP-#{marker}"
    true = Map.get(document, "description") == "phase172 swap marker #{marker}"

    %{
      marker: marker,
      task_uid: task_uid,
      task_status: task_status(task),
      task_type: task_type(task),
      live_index: live_index,
      target_index: target_index,
      swapped_pair: [live_index, target_index],
      document_id: source.id,
      expected_name: source.name,
      active_document: true
    }
  end

  defp recovery_source!(marker) do
    job =
      Job
      |> where([job], job.queue == "scrypath_sync")
      |> where(
        [job],
        fragment("?->>'scenario_key' = ?", job.args, ^"phase172_recovery_#{marker}")
      )
      |> Repo.one!(skip_tenant_id: true)

    args = job.args
    [document] = get_arg(args, "documents")

    %{
      id: job.id,
      attempt: job.attempt,
      args: args,
      task_baseline: get_arg(args, "task_baseline"),
      document: document
    }
  end

  defp recovery_expected!(source) do
    source.document
  end

  defp max_task_uid!(config) do
    {:ok, result} = Client.tasks([limit: 100], config)
    results = Map.get(result, "results") || Map.get(result, :results) || []

    Enum.map(results, &(Map.get(&1, "uid") || Map.get(&1, :uid)))
    |> Enum.filter(&is_integer/1)
    |> Enum.max(fn -> -1 end)
  end

  defp ensure_index_settings!(backend, schema, index, config) do
    case backend.apply_settings(schema, index, config) do
      {:ok, %{task: task}} when is_map(task) ->
        case Tasks.wait_for_task(task, config) do
          {:ok, _task} ->
            :ok

          {:error, reason} ->
            raise ArgumentError, "prepare swap settings failed: #{inspect(reason)}"
        end

      {:ok, result} ->
        raise ArgumentError, "prepare swap settings returned no task: #{inspect(result)}"

      {:error, reason} ->
        raise ArgumentError, "prepare swap settings failed: #{inspect(reason)}"
    end
  end

  defp seed_swap_pair!(source, target, config) do
    case Client.swap_indexes({source, target}, config) do
      {:ok, %{taskUid: uid}} -> wait_seed_swap!(uid, config)
      {:ok, %{"taskUid" => uid}} -> wait_seed_swap!(uid, config)
      {:error, reason} -> raise ArgumentError, "prepare swap task failed: #{inspect(reason)}"
      other -> raise ArgumentError, "prepare swap task returned no task UID: #{inspect(other)}"
    end
  end

  defp wait_seed_swap!(uid, config) when is_integer(uid) do
    case Tasks.wait_for_task(%{uid: uid, status: "enqueued", type: "indexSwap"}, config) do
      {:ok, _task} -> :ok
      {:error, reason} -> raise ArgumentError, "prepare swap task failed: #{inspect(reason)}"
    end
  end

  defp wait_seed_swap!(uid, _config),
    do: raise(ArgumentError, "invalid prepare swap task UID: #{inspect(uid)}")

  defp max_swap_task_uid!(config) do
    {:ok, result} = Client.tasks([types: ["indexSwap"], limit: 100], config)
    results = Map.get(result, "results") || Map.get(result, :results) || []

    Enum.map(results, &(Map.get(&1, "uid") || Map.get(&1, :uid)))
    |> Enum.filter(&is_integer/1)
    |> Enum.max(fn -> -1 end)
  end

  defp ensure_document_absent!(index, id, config) do
    case read_document(index, id, config) do
      {:error, :not_found} ->
        :absent

      {:ok, _document} ->
        raise ArgumentError, "expected document #{id} to be absent from #{index} before action"

      {:error, reason} ->
        raise ArgumentError, "could not establish baseline document state: #{inspect(reason)}"
    end
  end

  defp ensure_expected_document!(index, id, expected, config) do
    case read_document(index, id, config) do
      {:ok, actual} ->
        if expected_values_match?(actual, expected),
          do: :present,
          else: raise(ArgumentError, "target document mismatch")

      {:error, reason} ->
        raise ArgumentError, "target document missing: #{inspect(reason)}"
    end
  end

  defp read_document(index, id, config) do
    url = Scrypath.Config.fetch_meilisearch_url!(config)

    path =
      "/indexes/#{URI.encode(index, &URI.char_unreserved?/1)}/documents/#{URI.encode(to_string(id), &URI.char_unreserved?/1)}"

    request =
      config
      |> Keyword.get(:req_options, [])
      |> Keyword.delete(:base_url)
      |> Keyword.put(:base_url, url)
      |> Req.new()

    request =
      case Scrypath.Config.meilisearch_api_key(config) do
        nil -> request
        key -> Req.Request.put_header(request, "x-meili-api-key", key)
      end

    case Req.get(request, url: path) do
      {:ok, %Req.Response{status: status, body: body}} when status in 200..299 and is_map(body) ->
        {:ok, body}

      {:ok, %Req.Response{status: 404, body: %{"code" => code}}}
      when code in ["not_found", "document_not_found"] ->
        {:error, :not_found}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, {:transport, reason}}
    end
  end

  defp document_payload(document) do
    document.data
    |> stringify_keys()
    |> Map.put("id", document.id)
  end

  defp stringify_keys(map),
    do: Map.new(map, fn {key, value} -> {to_string(key), stringify_nested(value)} end)

  defp stringify_nested(map) when is_map(map), do: stringify_keys(map)
  defp stringify_nested(list) when is_list(list), do: Enum.map(list, &stringify_nested/1)
  defp stringify_nested(value), do: value

  defp expected_values_match?(actual, expected),
    do: Enum.all?(expected, fn {key, value} -> Map.get(actual, key) == value end)

  defp task_uid_of(task),
    do: Map.get(task, "uid") || Map.get(task, :uid) || Map.get(task, "taskUid")

  defp task_status(task), do: Map.get(task, "status") || Map.get(task, :status)
  defp task_index(task), do: Map.get(task, "indexUid") || Map.get(task, :indexUid)
  defp task_type(task), do: Map.get(task, "type") || Map.get(task, :type)

  defp swap_pair?(task, live, target) do
    details = Map.get(task, "details") || Map.get(task, :details) || %{}
    swaps = Map.get(details, "swaps") || Map.get(details, :swaps) || []

    Enum.any?(swaps, fn swap ->
      indexes = Map.get(swap, "indexes") || Map.get(swap, :indexes)
      indexes == [live, target]
    end)
  end

  defp get_arg(map, key) when is_map(map) do
    Map.get(map, key) ||
      Enum.find_value(map, fn {candidate, value} -> if to_string(candidate) == key, do: value end)
  end

  defp get_arg(_, _), do: nil

  defp safe_marker!(marker) do
    if byte_size(marker) in 1..80 and Regex.match?(~r/\A[a-zA-Z0-9_-]+\z/, marker),
      do: marker,
      else: raise(ArgumentError, "invalid E2E fixture marker")
  end

  defp assert_fixture!(true, _label, _actual), do: :ok

  defp assert_fixture!(false, label, actual),
    do: raise(ArgumentError, "#{label} mismatch: #{inspect(actual)}")
end
