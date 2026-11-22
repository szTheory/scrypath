defmodule ScrypathFixtures.Meili do
  @moduledoc """
  Builds raw Meilisearch task maps, as `GET /tasks` returns them. The data is fictional and for
  development and tests only.

  The output is the 12-key string-keyed map Meilisearch v1.15 sends. It is never a
  `Scrypath.Operations.Task` or an operator state: the real Scrypath code normalizes it.

  Task `type` and `status` are closed lists. A foreign value raises `FunctionClauseError` at the
  function head instead of producing a state the library cannot read. Meilisearch spells the
  cancelled status `"canceled"` (one l); Oban spells it `"cancelled"`.
  """

  # The five types Scrypath reads (lib/scrypath/meilisearch/tasks.ex).
  @types ~w(documentAdditionOrUpdate documentDeletion indexCreation settingsUpdate indexSwap)
  @statuses ~w(enqueued processing succeeded failed canceled)
  @keys ~w(uid batchUid indexUid status type canceledBy details error duration enqueuedAt startedAt finishedAt)

  @doc "The 12 keys every task map carries."
  @spec keys() :: [String.t()]
  def keys, do: @keys

  @doc "The closed list of task types."
  @spec types() :: [String.t()]
  def types, do: @types

  @doc "The closed list of task statuses."
  @spec statuses() :: [String.t()]
  def statuses, do: @statuses

  @doc """
  Builds one task map.

  Required: `:type`, `:status`, `:uid`, `:index_uid`, `:now`, `:enqueued_ago` (seconds before
  `now`), and `:canceled_by` (the uid of the cancelation task) when the status is `"canceled"`.
  Optional: `:batch_uid`, `:error`, `:details`, `:documents`, `:primary_key`, `:swap`.

  `details` has the key set the recording shows for the type, counted from `:documents` (default 1):
  `documentAdditionOrUpdate` reports `receivedDocuments` and `indexedDocuments`, `documentDeletion`
  reports `providedIds`, `deletedDocuments` and `originalFilter`, `indexCreation` reports
  `primaryKey` (from `:primary_key`, default `"id"`), `indexSwap` reports `swaps` (from `:swap`, a
  list of the two index names) and `settingsUpdate` echoes the settings it was sent, so it defaults
  to an empty map. Pass `:details` to override all of that. A processed count is `nil` until the
  task has finished, `0` for a failed or canceled task and the received count for a succeeded one.

  `index_uid` is `nil` exactly when the type is `"indexSwap"`: Meilisearch reports swaps with a
  null index and leaves them out of every `indexUids`-filtered list.
  """
  @spec task(map()) :: map()
  def task(%{type: type, status: status, index_uid: index_uid} = attrs)
      when type in @types and status in @statuses and
             ((type == "indexSwap" and is_nil(index_uid)) or
                (type != "indexSwap" and is_binary(index_uid))) and
             (status != "canceled" or is_map_key(attrs, :canceled_by)) do
    now = Map.fetch!(attrs, :now)
    enqueued = Map.fetch!(attrs, :enqueued_ago)
    uid = Map.fetch!(attrs, :uid)
    started? = status != "enqueued"
    finished? = status in ["succeeded", "failed", "canceled"]

    %{
      "uid" => uid,
      "batchUid" => if(started?, do: Map.get(attrs, :batch_uid, uid)),
      "indexUid" => index_uid,
      "status" => status,
      "type" => type,
      "canceledBy" => Map.get(attrs, :canceled_by),
      "details" => Map.get_lazy(attrs, :details, fn -> details(type, status, attrs) end),
      "error" => Map.get(attrs, :error),
      "duration" => if(finished?, do: "PT0.1S"),
      "enqueuedAt" => stamp(now, enqueued),
      "startedAt" => if(started?, do: stamp(now, enqueued - 1)),
      "finishedAt" => if(finished?, do: stamp(now, enqueued - 2))
    }
  end

  defp details("documentAdditionOrUpdate", status, attrs) do
    received = Map.get(attrs, :documents, 1)
    %{"receivedDocuments" => received, "indexedDocuments" => processed(status, received)}
  end

  defp details("documentDeletion", status, attrs) do
    provided = Map.get(attrs, :documents, 1)

    %{
      "providedIds" => provided,
      "deletedDocuments" => processed(status, provided),
      "originalFilter" => nil
    }
  end

  defp details("indexCreation", _status, attrs),
    do: %{"primaryKey" => Map.get(attrs, :primary_key, "id")}

  defp details("indexSwap", _status, attrs),
    do: %{"swaps" => [%{"indexes" => Map.get(attrs, :swap, [])}]}

  defp details("settingsUpdate", _status, _attrs), do: %{}

  # Recorded: null while waiting or running, 0 when nothing was applied, the full count on success.
  defp processed("succeeded", count), do: count
  defp processed(status, _count) when status in ["failed", "canceled"], do: 0
  defp processed(_status, _count), do: nil

  @doc """
  Renders `now` minus `seconds_ago` the way Meilisearch does: nine fractional digits and a `Z`.

  `DateTime.from_iso8601/1` accepts this form, which is what `Scrypath` uses to read it.
  """
  @spec stamp(DateTime.t(), integer()) :: String.t()
  def stamp(%DateTime{} = now, seconds_ago) when is_integer(seconds_ago) do
    now
    |> DateTime.add(-seconds_ago, :second)
    |> Calendar.strftime("%Y-%m-%dT%H:%M:%S")
    |> Kernel.<>(".123456789Z")
  end
end
