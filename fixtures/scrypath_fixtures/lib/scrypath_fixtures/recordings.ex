defmodule ScrypathFixtures.Recordings do
  @moduledoc """
  The Meilisearch v1.15 payloads recorded once from a real server, decoded at compile time. The
  data is fictional and for development and tests only.

  Every `*.json` file under `recordings/meilisearch-v1.15/` is read into this module and declared
  an `@external_resource`, so editing a recording recompiles it. `PROVENANCE.md` there names the
  image, the date and the request behind each file. Adding or removing a file also recompiles the
  module (`__mix_recompile__?/0`).

  Callers compare key sets and value types only, never values: uids and timestamps differ on every
  recording run, so a value comparison would fail for no reason (research Pitfall 11). Use
  `value_type/1` for the types.
  """

  @dir Path.expand("../../recordings/meilisearch-v1.15", __DIR__)
  @pattern Path.join(@dir, "*.json")
  @paths @pattern |> Path.wildcard() |> Enum.sort()
  @paths_digest :erlang.md5(@paths)
  @provenance_path Path.join(@dir, "PROVENANCE.md")

  if @paths == [] do
    raise CompileError,
      file: __ENV__.file,
      description: "no recordings found in #{@dir}; run recordings/record.sh"
  end

  for path <- @paths do
    @external_resource path
  end

  @external_resource @provenance_path

  @bodies Map.new(@paths, fn path ->
            {Path.basename(path, ".json"), path |> File.read!() |> Jason.decode!()}
          end)

  @provenance File.read!(@provenance_path)

  # One recorded full task per Meilisearch status. The file for each is named here once, and the
  # compile fails if a re-record leaves one of them with a different status.
  @task_exemplars %{
    "enqueued" => "13-task-document-addition-enqueued",
    "processing" => "12-task-document-addition-processing",
    "succeeded" => "04-task-document-addition-succeeded",
    "failed" => "05-task-failed-invalid-document-id-space-slash",
    "canceled" => "14-task-document-addition-canceled"
  }

  # The recorded task whose `details` key set stands for each type. `settingsUpdate` echoes the
  # settings that were sent, so its details have no fixed key set and are exempt.
  @details_exemplars %{
    "documentAdditionOrUpdate" => "04-task-document-addition-succeeded",
    "documentDeletion" => "15-task-document-deletion-succeeded",
    "indexCreation" => "03-task-index-creation",
    "indexSwap" => "26-task-index-swap"
  }

  for {status, name} <- @task_exemplars do
    case Map.fetch(@bodies, name) do
      {:ok, %{"status" => ^status}} ->
        :ok

      _other ->
        raise CompileError,
          file: __ENV__.file,
          description: "recording #{name} is not a #{status} task; re-record or rename it here"
    end
  end

  for {type, name} <- @details_exemplars do
    case Map.fetch(@bodies, name) do
      {:ok, %{"type" => ^type, "details" => %{}}} ->
        :ok

      _other ->
        raise CompileError,
          file: __ENV__.file,
          description: "recording #{name} is not a #{type} task with details"
    end
  end

  @doc false
  def __mix_recompile__? do
    :erlang.md5(@pattern |> Path.wildcard() |> Enum.sort()) != @paths_digest
  end

  @doc "Base names (no `.json`) of every recording, sorted."
  @spec files() :: [String.t()]
  def files, do: @bodies |> Map.keys() |> Enum.sort()

  @doc "The decoded body of one recording, by base name. Raises `ArgumentError` for an unknown name."
  @spec body!(String.t()) :: term()
  def body!(name) when is_binary(name) do
    case Map.fetch(@bodies, name) do
      {:ok, body} -> body
      :error -> raise ArgumentError, "no recording named #{inspect(name)}"
    end
  end

  @doc "The text of `PROVENANCE.md`."
  @spec provenance() :: String.t()
  def provenance, do: @provenance

  @doc """
  One recorded full task for a Meilisearch status (`enqueued`, `processing`, `succeeded`, `failed`
  or `canceled`). Raises `ArgumentError` for any other status.
  """
  @spec task_exemplar!(String.t()) :: map()
  def task_exemplar!(status) do
    case Map.fetch(@task_exemplars, status) do
      {:ok, name} -> body!(name)
      :error -> raise ArgumentError, "no recorded task exemplar for status #{inspect(status)}"
    end
  end

  @doc "The statuses `task_exemplar!/1` knows."
  @spec statuses() :: [String.t()]
  def statuses, do: @task_exemplars |> Map.keys() |> Enum.sort()

  @doc """
  The recorded `details` key set (sorted) for a task type, `:any` for `settingsUpdate` (its details
  echo the settings that were sent) and `nil` for a type that was not recorded.
  """
  @spec details_keys(String.t()) :: [String.t()] | :any | nil
  def details_keys("settingsUpdate"), do: :any

  def details_keys(type) when is_binary(type) do
    case Map.fetch(@details_exemplars, type) do
      {:ok, name} -> name |> body!() |> Map.fetch!("details") |> Map.keys() |> Enum.sort()
      :error -> nil
    end
  end

  @doc "The settings a new index reports (20 keys in v1.15)."
  @spec default_settings() :: map()
  def default_settings, do: body!("16-settings-default")

  @doc """
  The JSON type of a decoded value. Anything that is not one of the six JSON kinds, a float for
  example, is `:other`, so a caller can report it instead of crashing.
  """
  @spec value_type(term()) :: :null | :string | :integer | :map | :list | :boolean | :other
  def value_type(nil), do: :null
  def value_type(value) when is_boolean(value), do: :boolean
  def value_type(value) when is_binary(value), do: :string
  def value_type(value) when is_integer(value), do: :integer
  def value_type(value) when is_map(value), do: :map
  def value_type(value) when is_list(value), do: :list
  def value_type(_value), do: :other
end
