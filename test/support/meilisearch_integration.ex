defmodule Scrypath.TestSupport.MeilisearchIntegration do
  @moduledoc false

  alias Ecto.Adapters.SQL
  alias Scrypath.Meilisearch.Client
  alias Scrypath.Meilisearch.Tasks
  alias Scrypath.TestSupport.IntegrationRepo

  @timeout 10_000

  def meilisearch_url! do
    System.get_env("SCRYPATH_MEILISEARCH_URL") || "http://127.0.0.1:7700"
  end

  def repo_database_path do
    Path.join(System.tmp_dir!(), "scrypath-integration-#{System.unique_integer([:positive])}.db")
  end

  def setup_repo! do
    database = repo_database_path()

    start_supervised_repo!(database)
    create_tables!()

    database
  end

  def reset_repo! do
    SQL.query!(IntegrationRepo, "DELETE FROM posts", [])
    SQL.query!(IntegrationRepo, "DELETE FROM external_posts", [])
  end

  def cleanup_repo!(database) do
    case Process.whereis(IntegrationRepo) do
      pid when is_pid(pid) ->
        if Process.alive?(pid), do: GenServer.stop(pid)

      _ ->
        :ok
    end

    File.rm(database)
  end

  def insert_posts!(rows) do
    IntegrationRepo.insert_all("posts", rows)
  end

  def insert_external_posts!(rows) do
    IntegrationRepo.insert_all("external_posts", rows)
  end

  def index_prefix(prefix \\ "scrypath-it") do
    "#{prefix}-#{System.unique_integer([:positive])}"
  end

  def delete_indexes(indexes) when is_list(indexes) do
    Enum.each(indexes, &delete_index/1)
  end

  def delete_index(nil), do: :ok

  def delete_index(index_name) do
    request(:delete, "/indexes/#{index_name}")
    :ok
  end

  def index_exists?(index_name) do
    case request(:get, "/indexes/#{index_name}") do
      {:ok, %{status: 200}} -> true
      _ -> false
    end
  end

  def fetch_settings!(index_name) do
    case request(:get, "/indexes/#{index_name}/settings") do
      {:ok, %{status: 200, body: body}} -> body
      other -> raise "failed to fetch settings for #{index_name}: #{inspect(other)}"
    end
  end

  def create_index!(index_name, primary_key) do
    config = client_config()

    {:ok, response} = Client.create_index(index_name, primary_key, config)
    wait_for_task!(response["taskUid"], config)
  end

  def upsert_documents!(index_name, documents) when is_list(documents) do
    config = client_config()
    {:ok, response} = Client.upsert_documents(index_name, documents, config)
    wait_for_task!(response["taskUid"], config)
  end

  def wait_for_search_count!(schema_module, index_name, expected_count, opts \\ []) do
    config = Keyword.merge(client_config(), opts)
    deadline = System.monotonic_time(:millisecond) + @timeout

    wait_until!(
      fn ->
        case Scrypath.Meilisearch.search(
               schema_module,
               %{"q" => "", "limit" => 20},
               Keyword.put(config, :index_name, index_name)
             ) do
          {:ok, %{"hits" => hits}} -> length(hits) == expected_count
          {:error, _reason} -> false
        end
      end,
      deadline,
      "expected #{expected_count} searchable documents in #{index_name}"
    )
  end

  def wait_until!(fun, deadline, failure_message) when is_function(fun, 0) do
    case fun.() do
      false ->
        wait_until_retry!(fun, deadline, failure_message)

      nil ->
        wait_until_retry!(fun, deadline, failure_message)

      true ->
        :ok

      other ->
        other
    end
  end

  defp wait_until_retry!(fun, deadline, failure_message) do
    if System.monotonic_time(:millisecond) >= deadline do
      raise failure_message
    else
      Process.sleep(100)
      wait_until!(fun, deadline, failure_message)
    end
  end

  defp start_supervised_repo!(database) do
    unless Process.whereis(IntegrationRepo) do
      {:ok, _pid} =
        IntegrationRepo.start_link(
          database: database,
          pool_size: 1,
          journal_mode: :wal,
          busy_timeout: 5_000
        )
    end
  end

  defp create_tables! do
    SQL.query!(
      IntegrationRepo,
      """
      CREATE TABLE IF NOT EXISTS posts (
        id INTEGER PRIMARY KEY,
        title TEXT,
        body TEXT,
        status TEXT,
        inserted_at TEXT,
        author_id INTEGER
      )
      """,
      []
    )

    SQL.query!(
      IntegrationRepo,
      """
      CREATE TABLE IF NOT EXISTS external_posts (
        external_id TEXT PRIMARY KEY,
        title TEXT
      )
      """,
      []
    )
  end

  defp client_config do
    [
      meilisearch_url: meilisearch_url!(),
      inline_poll_interval: 100,
      inline_timeout: @timeout
    ]
  end

  defp wait_for_task!(task_uid, config) do
    {:ok, _task} = Tasks.wait_for_task(%{uid: task_uid, status: "enqueued"}, config)
  end

  defp request(method, path) do
    req =
      Req.new(
        base_url: meilisearch_url!(),
        headers: [{"content-type", "application/json"}]
      )

    case Req.request(req, method: method, url: path) do
      {:ok, %Req.Response{status: status, body: body}} -> {:ok, %{status: status, body: body}}
      {:error, reason} -> {:error, reason}
    end
  end
end
