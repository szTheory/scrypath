defmodule ScrypathOps.RecoveryObservationTest do
  use ExUnit.Case, async: false

  alias ScrypathOps.RecoveryObservation

  setup do
    {:ok, server} =
      start_supervised({RecoveryObservation, name: nil, attach: false, ttl_ms: 60_000})

    %{server: server}
  end

  test "joins task wait evidence to the exact emitting retry process", %{server: server} do
    host = %{schema: "ScrypathOps.Test.Post", host: "ops.example", org: "org-1"}
    receipt = receipt(41, 2, "http://search-a:7700", :upsert)
    {:ok, handle} = RecoveryObservation.register(server, host, receipt)

    worker(server, job_metadata(41, 2, "http://search-a:7700", :upsert), fn ->
      task_wait(server, 701, :succeeded)
    end)

    observed = RecoveryObservation.observe(server, host, handle)
    assert observed.task_uid == 701
    assert observed.telemetry_status == :succeeded
    assert observed.state == :accepted
  end

  test "retains fast task completion before the LiveView registers the accepted receipt", %{
    server: server
  } do
    host = %{schema: "Scrypath.Test.Post", host: "ops.example", org: "org-1"}

    worker(server, job_metadata(42, 1, "http://search-a:7700", :upsert), fn ->
      task_wait(server, 702, :succeeded)
    end)

    {:ok, handle} =
      RecoveryObservation.register(
        server,
        host,
        receipt(42, 1, "http://search-a:7700", :upsert)
      )

    assert RecoveryObservation.observe(server, host, handle).task_uid == 702
  end

  test "does not join across attempts, Oban instances, or backend endpoints", %{server: server} do
    host = %{schema: "Scrypath.Test.Post", host: "ops.example", org: "org-1"}

    worker(server, job_metadata(43, 2, "http://search-a:7700", :upsert, Oban.SearchA), fn ->
      task_wait(server, 703, :succeeded)
    end)

    for {attempt, endpoint, instance} <- [
          {1, "http://search-a:7700", Oban.SearchA},
          {2, "http://search-b:7700", Oban.SearchA},
          {2, "http://search-a:7700", Oban.SearchB}
        ] do
      {:ok, handle} =
        RecoveryObservation.register(
          server,
          host,
          receipt(43, attempt, endpoint, :upsert, instance)
        )

      assert RecoveryObservation.observe(server, host, handle).state == :accepted
      assert RecoveryObservation.observe(server, host, handle).task_uid == nil
    end
  end

  test "new attempts supersede old success and terminate evidence is identity scoped", %{
    server: server
  } do
    host = %{schema: "Scrypath.Test.Post", host: "ops.example", org: "org-1"}
    start = job_metadata(44, 1, "http://search-a:7700", :upsert)
    worker(server, start, fn -> task_wait(server, 704, :succeeded) end)

    {:ok, old_handle} =
      RecoveryObservation.register(server, host, receipt(44, 1, "http://search-a:7700", :upsert))

    assert RecoveryObservation.observe(server, host, old_handle).task_uid == 704

    worker(server, job_metadata(44, 2, "http://search-a:7700", :upsert), fn ->
      RecoveryObservation.handle_event(
        [:oban, :job, :stop],
        %{},
        %{job: job(44, 2, "http://search-a:7700", :upsert, Oban.SearchA)},
        %{server: server}
      )
    end)

    assert RecoveryObservation.observe(server, host, old_handle).task_uid == nil
  end

  test "a newer retry receipt for the same source failure supersedes its prior handle", %{
    server: server
  } do
    host = %{schema: "Scrypath.Test.Post", host: "ops.example", org: "org-1"}
    source = %{id: 950, operation: :upsert}
    first = Map.put(receipt(54, 1, "http://search:7700", :upsert), :source_failure, source)
    second = Map.put(receipt(55, 1, "http://search:7700", :upsert), :source_failure, source)

    {:ok, first_handle} = RecoveryObservation.register(server, host, first)
    {:ok, _second_handle} = RecoveryObservation.register(server, host, second)

    assert RecoveryObservation.lookup(server, host, first_handle) == :unknown
  end

  test "wrong handle host and allowlist context cannot read a receipt", %{server: server} do
    host = %{schema: "Scrypath.Test.Post", host: "ops.example", org: "org-1"}

    {:ok, handle} =
      RecoveryObservation.register(server, host, receipt(45, 1, "http://search:7700", :upsert))

    assert RecoveryObservation.lookup(server, %{host | host: "other.example"}, handle) == :unknown

    assert RecoveryObservation.lookup(server, %{host | schema: "Scrypath.Test.Other"}, handle) ==
             :unknown
  end

  test "invalidation, collector restart, and expiry turn prior observations unknown", %{
    server: server
  } do
    host = %{schema: "Scrypath.Test.Post", host: "ops.example", org: "org-1"}

    {:ok, handle} =
      RecoveryObservation.register(server, host, receipt(46, 1, "http://search:7700", :upsert))

    assert RecoveryObservation.lookup(server, host, handle) != :unknown
    :ok = RecoveryObservation.invalidate(server, handle)
    assert RecoveryObservation.lookup(server, host, handle) == :unknown

    {:ok, second_handle} =
      RecoveryObservation.register(
        server,
        host,
        receipt(48, 1, "http://search:7700", :upsert)
      )

    {:ok, restarted} =
      start_supervised(
        {RecoveryObservation, name: nil, attach: false, ttl_ms: 1_000},
        id: :restarted_observation
      )

    assert RecoveryObservation.lookup(restarted, host, second_handle) == :unknown

    :sys.replace_state(server, fn state ->
      update_in(state.observations[second_handle].inserted_at, &(&1 - 61_000))
    end)

    assert RecoveryObservation.lookup(server, host, second_handle) == :unknown
  end

  test "receipt status says accepted until authoritative task and document checks happen", %{
    server: server
  } do
    host = %{schema: "Scrypath.Test.Post", host: "ops.example", org: "org-1"}

    {:ok, handle} =
      RecoveryObservation.register(server, host, receipt(47, 1, "http://search:7700", :upsert))

    assert RecoveryObservation.observe(server, host, handle).state == :accepted
    assert RecoveryObservation.observe(server, host, handle).verified == false
  end

  test "cached receipt drops payloads and credentials", %{server: server} do
    host = %{schema: "Scrypath.Test.Post", host: "ops.example", org: "org-1"}

    input =
      receipt(49, 1, "http://user:secret@search:7700", :upsert)
      |> Map.put(:payload, %{"private" => "raw document"})
      |> Map.put(:accepted_result, %{job_id: 849, args: %{"secret" => "token"}})

    {:ok, handle} = RecoveryObservation.register(server, host, input)
    stored = RecoveryObservation.lookup(server, host, handle)

    refute Map.has_key?(stored, :payload)
    assert stored.accepted_result == %{job_id: 849}
    assert stored.endpoint.host == "search"
    refute inspect(:sys.get_state(server)) =~ "raw document"
    refute inspect(:sys.get_state(server)) =~ "secret"
  end

  defp worker(server, metadata, callback) do
    parent = self()

    {pid, ref} =
      spawn_monitor(fn ->
        RecoveryObservation.handle_event(
          [:oban, :job, :start],
          %{},
          metadata,
          %{server: server}
        )

        callback.()
        send(parent, :worker_done)
      end)

    assert_receive :worker_done
    assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
    _ = :sys.get_state(server)
  end

  defp task_wait(server, uid, status) do
    RecoveryObservation.handle_event(
      [:scrypath, :meilisearch, :task_wait, :start],
      %{},
      %{task_uid: uid},
      %{server: server}
    )

    RecoveryObservation.handle_event(
      [:scrypath, :meilisearch, :task_wait, :stop],
      %{},
      %{task_uid: uid, final_status: status},
      %{server: server}
    )
  end

  defp receipt(id, attempt, endpoint, operation, instance \\ Oban.Search) do
    %{
      id: id,
      attempt: attempt,
      operation: operation,
      schema: "Elixir.Scrypath.Test.Post",
      index: "posts",
      endpoint: endpoint,
      instance: instance,
      repo: ScrypathOps.Repo,
      prefix: "public",
      source_failure: %{id: 900 + id, task_uid: 200 + id},
      accepted_result: %{job_id: 800 + id}
    }
  end

  defp job_metadata(id, attempt, endpoint, operation, instance \\ Oban.Search) do
    %{
      id: id,
      attempt: attempt,
      worker: worker_name(operation),
      args: %{
        "schema" => "Elixir.Scrypath.Test.Post",
        "backend" => "Elixir.Scrypath.Meilisearch",
        "index" => "posts",
        "operation" => Atom.to_string(operation),
        "meilisearch_url" => endpoint
      },
      conf: %{name: instance, repo: ScrypathOps.Repo},
      prefix: "public"
    }
    |> then(&Map.put(&1, :job, job(id, attempt, endpoint, operation, instance)))
  end

  defp job(id, attempt, endpoint, operation, instance) do
    %{
      id: id,
      attempt: attempt,
      worker: worker_name(operation),
      args: %{
        "schema" => "Elixir.Scrypath.Test.Post",
        "backend" => "Elixir.Scrypath.Meilisearch",
        "index" => "posts",
        "operation" => Atom.to_string(operation),
        "meilisearch_url" => endpoint
      },
      conf: %{name: instance, repo: ScrypathOps.Repo},
      prefix: "public"
    }
  end

  defp worker_name(:upsert), do: "Elixir.Scrypath.Oban.UpsertWorker"
  defp worker_name(:delete), do: "Elixir.Scrypath.Oban.DeleteWorker"
end
