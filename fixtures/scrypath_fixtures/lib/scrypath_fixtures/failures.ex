defmodule ScrypathFixtures.Failures do
  @moduledoc """
  The closed table of failure text a fixture may show. The data is fictional and for development
  and tests only.

  Every failure string in any scenario comes from here, never from a builder's own text. An entry
  has:

    * `:id` and `:surface`: `:meilisearch_task` (the `error` object of a failed task) or
      `:oban_error` (one entry of an Oban job's `errors`);
    * `:template` (Meilisearch) or `:reason` (Oban): the exact text, with `%{name}` placeholders
      for the parts the server or Oban fills in;
    * `:code`, `:type`, `:link` for a Meilisearch error, `:task_types` for the task types the
      server produces it for, and `:bindings` for the placeholders it takes;
    * `:source`: where the text comes from. A base name in `ScrypathFixtures.Recordings.files/0`
      (a recorded Meilisearch body) or a path from the repository root that exists. `Check` fails
      when neither resolves.

  The text is copied from the recordings in `recordings/meilisearch-v1.15/` and from Oban 2.24's
  `Oban.PerformError` (`"<worker> failed with <inspected return value>"`). A returned error has an
  empty stacktrace, so the stored text is that one banner line and nothing is left out.

  `cannot_produce/0` lists what must never appear because the library cannot produce it. `Check`
  rejects a table entry on that list.
  """

  alias Scrypath.Meilisearch.TaskPayload
  alias Scrypath.Operations

  @errors_url "https://docs.meilisearch.com/errors#"

  @entries [
    %{
      id: :invalid_document_id,
      surface: :meilisearch_task,
      code: "invalid_document_id",
      type: "invalid_request",
      link: @errors_url <> "invalid_document_id",
      template:
        "Document identifier `%{id}` is invalid. A document identifier can be of type integer or string, " <>
          "only composed of alphanumeric characters (a-z A-Z 0-9), hyphens (-) and underscores (_), " <>
          "and can not be more than 511 bytes.",
      task_types: ["documentAdditionOrUpdate"],
      bindings: [:id],
      reaches:
        "a failed backend row, reason class :validation; the id is echoed as the customer sent it",
      source: "05-task-failed-invalid-document-id-space-slash"
    },
    %{
      id: :missing_document_id,
      surface: :meilisearch_task,
      code: "missing_document_id",
      type: "invalid_request",
      link: @errors_url <> "missing_document_id",
      template: "Document doesn't have a `id` attribute: `%{document}`.",
      task_types: ["documentAdditionOrUpdate"],
      bindings: [:document],
      reaches:
        "a failed backend row, reason class :validation; the whole document is echoed (finding F2)",
      source: "09-task-failed-missing-document-id-markup"
    },
    %{
      id: :index_not_found_task,
      surface: :meilisearch_task,
      code: "index_not_found",
      type: "invalid_request",
      link: @errors_url <> "index_not_found",
      template: "Index `%{uid}` not found.",
      task_types: ["documentDeletion"],
      bindings: [:uid],
      reaches: "a failed delete row; a delete on an index that does not exist is a failed task",
      source: "10-task-failed-document-deletion-index-not-found"
    },
    %{
      id: :primary_key_no_candidate,
      surface: :meilisearch_task,
      code: "index_primary_key_no_candidate_found",
      type: "invalid_request",
      link: @errors_url <> "index_primary_key_no_candidate_found",
      template:
        "The primary key inference failed as the engine did not find any field ending with `id` in its name. " <>
          "Please specify the primary key manually using the `primaryKey` query parameter.",
      task_types: ["documentAdditionOrUpdate"],
      bindings: [],
      reaches: "a failed backend row, reason class :validation",
      source: "11-task-failed-primary-key-no-candidate"
    },
    %{
      id: :oban_transport,
      surface: :oban_error,
      reason:
        {:exact, "{:error, {:transport_error, %Req.TransportError{reason: :econnrefused}}}"},
      bindings: [:attempt, :at, :worker],
      reaches: "a retryable job, then a discarded one; reason class :transport",
      source: "lib/scrypath/meilisearch/client.ex"
    },
    %{
      id: :oban_task_failed,
      surface: :oban_error,
      reason: {:prefix, "{:error, {:task_failed, %Scrypath.Operations.Task{"},
      bindings: [:attempt, :at, :worker, :task],
      reaches:
        "a discarded job; the text embeds the whole failed task and is longer than 500 characters, " <>
          "so the real Translation truncates it",
      source: "lib/scrypath/meilisearch/tasks.ex"
    },
    %{
      id: :oban_cancel_invalid_job,
      surface: :oban_error,
      reason: {:prefix, "{:cancel, {:invalid_job, {:unknown_schema, "},
      bindings: [:attempt, :at, :worker, :schema],
      reaches: "a cancelled job: the worker refused arguments it could not decode",
      source: "lib/scrypath/oban/upsert_worker.ex"
    }
  ]

  # What must never appear in a fixture, and why. Each name is a Meilisearch error code or a
  # descriptive id; a table entry whose id or code is listed here is a `:forbidden_failure`.
  @cannot_produce [
    %{
      id: "payload_too_large",
      reason:
        "Meilisearch refuses an oversized request with an HTTP error, never as a failed task."
    },
    %{
      id: "database_size_limit_reached",
      reason:
        "A system-type error: Scrypath's failure classifier has no system arm, so it would read as unknown. Not recorded."
    },
    %{
      id: "no_space_left_on_device",
      reason: "A system-type error: classified as unknown, not as a designed state. Not recorded."
    },
    %{
      id: "per_tenant_drift",
      reason:
        "Scrypath compares one index's applied settings with its schema; there is no tenant dimension."
    },
    %{
      id: "minutes_of_lag",
      reason:
        "Scrypath reports counts and ages, never a lag duration between the database and the index."
    },
    %{
      id: "per_document_size_limit",
      reason: "Meilisearch has no per-document size limit, only a limit on the request payload."
    },
    %{
      id: "out_of_order_overwrite",
      reason:
        "An Oban job loads the record as it is now, so a retried or delayed job never sends an older copy."
    },
    %{
      id: "price_as_string",
      reason:
        "Meilisearch stores any JSON value in a field that is not filterable; it never rejects a type."
    }
  ]

  @placeholder ~r/%\{(\w+)\}/

  @doc "Every entry of the closed table."
  @spec all() :: [map()]
  def all, do: @entries

  @doc "What must never appear in a fixture: `%{id: String.t(), reason: String.t()}`."
  @spec cannot_produce() :: [%{id: String.t(), reason: String.t()}]
  def cannot_produce, do: @cannot_produce

  @doc "One entry by id. An id outside the table raises `FunctionClauseError`."
  @spec entry!(atom()) :: map()
  for entry <- @entries do
    def entry!(unquote(entry.id)), do: unquote(Macro.escape(entry))
  end

  @doc """
  The `error` object of a failed Meilisearch task, rendered from a table entry.

  `bindings` must hold exactly the entry's `:bindings`: `:id` (the document id, a string or an
  integer), `:document` (the document as an ordered list of `{key, value}` pairs, the order
  Meilisearch echoes it in) or `:uid` (an index uid). An Oban entry raises `FunctionClauseError`.
  """
  @spec meili_error(atom(), keyword()) :: %{String.t() => String.t()}
  def meili_error(id, bindings) when is_atom(id) and is_list(bindings),
    do: render_meili(entry!(id), bindings)

  defp render_meili(%{surface: :meilisearch_task} = entry, bindings) do
    ensure_bindings!(entry, bindings)

    message =
      Regex.replace(@placeholder, entry.template, fn _match, name ->
        encode_binding(
          String.to_existing_atom(name),
          Keyword.fetch!(bindings, String.to_existing_atom(name))
        )
      end)

    %{"message" => message, "code" => entry.code, "type" => entry.type, "link" => entry.link}
  end

  # An id is shown the way the server shows it: as a JSON value.
  defp encode_binding(:id, id) when is_binary(id) or is_integer(id), do: Jason.encode!(id)

  defp encode_binding(:document, [{_key, _value} | _rest] = pairs),
    do: pairs |> Jason.OrderedObject.new() |> Jason.encode!()

  defp encode_binding(:uid, uid) when is_binary(uid), do: uid

  @doc """
  One entry of an Oban job's `errors`: `%{"attempt", "at", "error"}`, as Oban stores it.

  Options: `:attempt` (a positive integer) and `:at` (a `DateTime`, written as ISO 8601) for every
  entry; `:worker` (`:upsert`, `:delete` or `:related`, default `:upsert`); `:task` (the raw failed
  Meilisearch task map) for `:oban_task_failed`; `:schema` (the schema module or its string) for
  `:oban_cancel_invalid_job`. A Meilisearch entry raises `FunctionClauseError`.
  """
  @spec oban_error(atom(), keyword()) :: %{String.t() => term()}
  def oban_error(id, opts) when is_atom(id) and is_list(opts), do: render_oban(entry!(id), opts)

  defp render_oban(%{surface: :oban_error} = entry, opts) do
    ensure_bindings!(entry, Keyword.delete(opts, :worker), [:worker])

    attempt = Keyword.fetch!(opts, :attempt)
    at = Keyword.fetch!(opts, :at)

    unless is_integer(attempt) and attempt >= 1 and is_struct(at, DateTime) do
      raise ArgumentError,
            ":attempt must be a positive integer and :at a DateTime, got #{inspect({attempt, at})}"
    end

    worker = opts |> Keyword.get(:worker, :upsert) |> worker_name()

    %{
      "attempt" => attempt,
      "at" => DateTime.to_iso8601(at),
      "error" =>
        "** (Oban.PerformError) " <> worker <> " failed with " <> oban_reason(entry.id, opts)
    }
  end

  defp oban_reason(:oban_transport, _opts),
    do: "{:error, {:transport_error, %Req.TransportError{reason: :econnrefused}}}"

  # The same value Scrypath's `IndexingAck` returns for a failed task, inspected by Oban with its
  # default options, so the text has the real struct's shape and line breaks.
  defp oban_reason(:oban_task_failed, opts),
    do: {:error, {:task_failed, opts |> Keyword.fetch!(:task) |> failed_task()}} |> inspect()

  defp oban_reason(:oban_cancel_invalid_job, opts),
    do:
      {:cancel,
       {:invalid_job, {:unknown_schema, opts |> Keyword.fetch!(:schema) |> schema_name()}}}
      |> inspect()

  defp failed_task(%{"status" => "failed"} = raw) do
    {:ok, normalized} = TaskPayload.normalize(raw, :poll)
    Operations.task_from_backend(normalized, source: :meilisearch)
  end

  defp schema_name(schema) when is_atom(schema), do: Atom.to_string(schema)
  defp schema_name(schema) when is_binary(schema), do: schema

  defp worker_name(role) when is_atom(role),
    do: Map.fetch!(ScrypathFixtures.ObanJob.workers(), role)

  @doc """
  Whether `error` (the `error` map of a task of type `task_type`) is exactly what some Meilisearch
  entry renders: same code, type and link, a message that fits the template, and a task type the
  server produces that error for.
  """
  @spec meili_error?(term(), term()) :: boolean()
  def meili_error?(error, task_type) when is_map(error) do
    Enum.any?(@entries, fn
      %{surface: :meilisearch_task} = entry ->
        error["code"] == entry.code and error["type"] == entry.type and
          error["link"] == entry.link and task_type in entry.task_types and
          template_match?(entry.template, error["message"])

      _other ->
        false
    end)
  end

  def meili_error?(_error, _task_type), do: false

  @doc """
  Whether `entry` (one element of an Oban job's `errors`) is what some Oban entry renders: the
  three keys, a positive integer attempt, a parseable time, and text that is the
  `Oban.PerformError` banner for a known worker and a known reason.
  """
  @spec oban_error?(term()) :: boolean()
  def oban_error?(%{"attempt" => attempt, "at" => at, "error" => text} = entry)
      when map_size(entry) == 3 and is_integer(attempt) and attempt >= 1 and is_binary(at) and
             is_binary(text) do
    match?({:ok, _datetime, _offset}, DateTime.from_iso8601(at)) and
      case Regex.run(~r/\A\*\* \(Oban\.PerformError\) (\S+) failed with (.+)\z/s, text) do
        [_all, worker, reason] ->
          worker in Map.values(ScrypathFixtures.ObanJob.workers()) and
            Enum.any?(@entries, &oban_reason_match?(&1, reason))

        nil ->
          false
      end
  end

  def oban_error?(_entry), do: false

  defp oban_reason_match?(%{surface: :oban_error, reason: {:exact, text}}, reason),
    do: reason == text

  defp oban_reason_match?(%{surface: :oban_error, reason: {:prefix, prefix}}, reason),
    do: String.starts_with?(reason, prefix)

  defp oban_reason_match?(_entry, _reason), do: false

  # `%{name}` stands for any non-empty text; everything else must match exactly.
  defp template_match?(template, message) when is_binary(message) do
    pattern =
      @placeholder
      |> Regex.split(template)
      |> Enum.map_join("(.+)", &Regex.escape/1)

    Regex.match?(Regex.compile!("\\A" <> pattern <> "\\z", "s"), message)
  end

  defp template_match?(_template, _message), do: false

  defp ensure_bindings!(entry, given, extra_allowed \\ []) do
    given_keys = given |> Keyword.keys() |> Enum.sort()
    expected = Enum.sort(entry.bindings -- extra_allowed)

    if given_keys != expected do
      raise ArgumentError,
            "#{inspect(entry.id)} takes bindings #{inspect(expected)}, got #{inspect(given_keys)}"
    end
  end
end
