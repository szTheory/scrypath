defmodule ScrypathOps.RecoveryView do
  @moduledoc """
  What the two recovery areas of Sync and index show, as one pure value.

  `ScrypathOpsWeb.SyncDriftLive` keeps the observer's results in several assigns: the recovery
  status, the evidence that names the exact queue job, the document observation, the observer's
  error and the check time. `build/1` takes those and returns this struct for the function
  components in `ScrypathOpsWeb.Components.Recovery`. It reads no clock, starts no process and
  imports nothing from Phoenix, so the component catalog builds the same value from plain data.

  ## Closed sets

    * status: `:not_checked | :accepted | :running | :queue_only_completed | :verified | :failed |
      :cancelled | :unavailable`. `:unavailable` is the one honest answer when the outcome could not
      be read: the observer's `:unknown`, and anything the observer does not name. Its label and copy
      say the outcome could not be checked.
    * evidence: `nil` or a map that holds all of `replacement_job`, `attempt`, `task_uid` and
      `index`. A map with fewer keys cannot reach a component, so an unresolved handle can never
      render a half-empty evidence line (defect D3: the template read `replacement_job` from an
      empty map and crashed the page).

  ## Combinations the observer cannot emit are refused

  `build/1` returns `{:error, reason}` for a status that claims an outcome without its evidence:

    * `:verified_without_document_evidence` - `:verified` needs a document observation whose state is
      `:verified`
    * `:observed_status_without_evidence` - a status that names an observed queue job
      (`:accepted`, `:running`, `:queue_only_completed`, `:verified`, `:failed`, `:cancelled`) needs
      full evidence
    * `:evidence_without_status` - evidence cannot exist while the status is `:not_checked`

  `for_page/1` is the total form the LiveView calls: a refused combination becomes the closed
  `:unavailable` state, so the page never shows an outcome its evidence does not back.
  """

  alias ScrypathOps.OperatorSelection
  alias ScrypathOps.RecoveryView.Document

  @statuses [
    :not_checked,
    :accepted,
    :running,
    :queue_only_completed,
    :verified,
    :failed,
    :cancelled,
    :unavailable
  ]
  @observed [:accepted, :running, :queue_only_completed, :verified, :failed, :cancelled]

  @type status ::
          :not_checked
          | :accepted
          | :running
          | :queue_only_completed
          | :verified
          | :failed
          | :cancelled
          | :unavailable

  @type evidence :: %{
          replacement_job: term(),
          attempt: term(),
          task_uid: term(),
          index: String.t()
        }

  @type rejection ::
          :verified_without_document_evidence
          | :observed_status_without_evidence
          | :evidence_without_status

  @typedoc """
  What `build/1` reads, with these keys:

    * `:schema` - the selected schema module, or `nil` when none is selected
    * `:handle` - the receipt handle from the URL, or `nil`
    * `:status` - the observer's status, `nil` while nothing was checked
    * `:evidence` - the observer's evidence map, `nil`, or an incomplete map
    * `:document_observation` - the document observation map, or `nil`
    * `:error` - the observer's reason when a check could not be made, or `nil`
    * `:checked_at` - when the status was last checked, or `nil`
    * `:loading?` - whether a check is running
  """
  @type input :: %{
          required(:schema) => module() | nil,
          required(:handle) => String.t() | nil,
          required(:status) => atom() | nil,
          required(:evidence) => map() | nil,
          required(:document_observation) => map() | nil,
          required(:error) => term(),
          required(:checked_at) => DateTime.t() | nil,
          required(:loading?) => boolean()
        }

  @type t :: %__MODULE__{
          schema: module() | nil,
          schema_name: String.t() | nil,
          handle?: boolean(),
          status: status(),
          label: String.t(),
          kind: :success | :error | :warning | :neutral,
          copy: String.t(),
          evidence: evidence() | nil,
          error: term(),
          checked_at: DateTime.t() | nil,
          loading?: boolean(),
          document: Document.t(),
          visible?: boolean()
        }

  @enforce_keys [:status, :label, :kind, :copy, :document]
  defstruct [
    :schema,
    :schema_name,
    :status,
    :label,
    :kind,
    :copy,
    :evidence,
    :error,
    :checked_at,
    :document,
    handle?: false,
    loading?: false,
    visible?: false
  ]

  @doc "The closed set of statuses a view can hold."
  @spec statuses() :: [status()]
  def statuses, do: @statuses

  @doc """
  Builds the view, or refuses a combination the observer cannot emit (see the moduledoc).
  """
  @spec build(input()) :: {:ok, t()} | {:error, rejection()}
  def build(%{} = input) do
    status = status(Map.get(input, :status))
    evidence = evidence(Map.get(input, :evidence))
    document = Document.build(Map.get(input, :document_observation))

    with :ok <- check(status, evidence, document) do
      {:ok, struct!(__MODULE__, fields(input, status, evidence, document))}
    end
  end

  @doc """
  The total form for the page: `build/1`, with a refused combination shown as the closed
  `:unavailable` state and no evidence. The observer's error and the document observation stay, so
  the page still says what could not be checked.
  """
  @spec for_page(input()) :: t()
  def for_page(%{} = input) do
    case build(input) do
      {:ok, view} ->
        view

      {:error, _rejection} ->
        document = Document.build(Map.get(input, :document_observation))
        struct!(__MODULE__, fields(input, :unavailable, nil, document))
    end
  end

  defp check(:verified, _evidence, %Document{state: state}) when state != :verified,
    do: {:error, :verified_without_document_evidence}

  defp check(status, nil, _document) when status in @observed,
    do: {:error, :observed_status_without_evidence}

  defp check(:not_checked, evidence, _document) when not is_nil(evidence),
    do: {:error, :evidence_without_status}

  defp check(_status, _evidence, _document), do: :ok

  defp fields(input, status, evidence, document) do
    schema = Map.get(input, :schema)
    handle? = Map.get(input, :handle) not in [nil, false]
    error = Map.get(input, :error)

    [
      schema: schema,
      schema_name: OperatorSelection.canonical(schema),
      handle?: handle?,
      status: status,
      label: label(status),
      kind: kind(status),
      copy: copy(status),
      evidence: evidence,
      error: error,
      checked_at: Map.get(input, :checked_at),
      loading?: Map.get(input, :loading?) == true,
      document: document,
      visible?: not is_nil(schema) and (handle? or not is_nil(error) or document.present?)
    ]
  end

  # `nil` is "never checked"; the observer's own `:unknown` and anything it does not name is the one
  # closed answer that the outcome could not be read.
  defp status(nil), do: :not_checked
  defp status(status) when status in @observed, do: status
  defp status(_unknown), do: :unavailable

  # A complete evidence map, or nothing: an empty or partial map is what an unresolved handle
  # leaves behind and must not reach a component. `task_uid` may be `nil` (no backend task yet).
  defp evidence(%{replacement_job: job, attempt: attempt, index: index} = map)
       when not is_nil(job) and not is_nil(attempt) and not is_nil(index),
       do: %{
         replacement_job: job,
         attempt: attempt,
         task_uid: Map.get(map, :task_uid),
         index: index
       }

  defp evidence(_other), do: nil

  defp label(:not_checked), do: "Not checked"
  defp label(:accepted), do: "Retry queued"
  defp label(:running), do: "Retry running"
  defp label(:queue_only_completed), do: "Queue job completed; backend evidence pending"
  defp label(:verified), do: "Recovery verified"
  defp label(:failed), do: "Recovery failed"
  defp label(:cancelled), do: "Recovery canceled"
  defp label(:unavailable), do: "Recovery outcome could not be checked"

  defp kind(:verified), do: :success
  defp kind(:failed), do: :error
  defp kind(:cancelled), do: :error
  defp kind(status) when status in [:accepted, :running, :queue_only_completed], do: :warning
  defp kind(_status), do: :neutral

  defp copy(:accepted),
    do:
      "The queue has this retry; refresh to observe this same job. Refresh never resubmits work."

  defp copy(:running),
    do: "This retry is still running; refresh to observe the same job, attempt, and task."

  defp copy(:queue_only_completed),
    do: "The queue job completed, but backend and document evidence are not confirmed."

  defp copy(:verified),
    do: "The exact retry task and its expected active-index effect were observed."

  defp copy(:failed),
    do: "The exact retry job or backend task failed. Review its result before retrying."

  defp copy(:cancelled),
    do: "The exact retry job or backend task was canceled. Review its result before retrying."

  defp copy(:unavailable),
    do:
      "This operation's outcome could not be checked. Refresh this same operation; do not submit another retry."

  defp copy(:not_checked),
    do:
      "No recovery result has been checked yet. Review failed sync work to start an eligible retry."
end
