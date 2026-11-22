defmodule ScrypathOps.RecoveryView.Document do
  @moduledoc """
  The document freshness half of `ScrypathOps.RecoveryView`: whether the documents a retry was
  expected to write or delete were seen in the active index.

  Built from the observer's document observation (a map, or `nil` when none was made). Every key a
  component reads is present on the struct, so a thin observation (the observer reports only a
  state and a reason when it could not check) cannot crash the page by missing a key.
  """

  @type state :: :not_checked | :verified | :running | :failed | :cancelled | :unknown | nil

  @type t :: %__MODULE__{
          present?: boolean(),
          state: state(),
          title: String.t(),
          kind: :success | :error | :warning | :info,
          copy: String.t(),
          checked_at: DateTime.t() | nil,
          operation: atom() | nil,
          index: String.t() | nil,
          expected_ids: [term()] | nil
        }

  @enforce_keys [:present?, :title, :kind, :copy]
  defstruct [
    :present?,
    :state,
    :title,
    :kind,
    :copy,
    :checked_at,
    :operation,
    :index,
    :expected_ids
  ]

  @doc "The document view for an observation map, or for `nil` (nothing was checked)."
  @spec build(map() | nil) :: t()
  def build(nil) do
    %__MODULE__{
      present?: false,
      state: nil,
      title: title(nil),
      kind: kind(nil),
      copy: copy(nil)
    }
  end

  def build(%{} = observation) do
    %__MODULE__{
      present?: true,
      state: Map.get(observation, :state),
      title: title(observation),
      kind: kind(observation),
      copy: copy(observation),
      checked_at: Map.get(observation, :checked_at),
      operation: Map.get(observation, :operation),
      index: Map.get(observation, :index),
      expected_ids: expected_ids(Map.get(observation, :expected_ids))
    }
  end

  defp expected_ids(ids) when is_list(ids), do: ids
  defp expected_ids(_other), do: nil

  defp title(nil), do: "Not checked"
  defp title(%{state: :not_checked}), do: "Not checked"
  defp title(%{state: :verified}), do: "Expected documents observed"
  defp title(%{state: :running}), do: "Document task is still running"
  defp title(%{state: :failed}), do: "Document task failed"
  defp title(%{state: :cancelled}), do: "Document task was canceled"
  defp title(_observation), do: "Could not check document freshness"

  defp kind(%{state: :verified}), do: :success
  defp kind(%{state: :failed}), do: :error
  defp kind(%{state: :cancelled}), do: :error
  defp kind(%{state: :running}), do: :warning
  defp kind(_observation), do: :info

  defp copy(nil), do: "Expected-document evidence has not been checked for this recovery."

  defp copy(%{state: :not_checked, reason: reason}),
    do:
      "Expected-document evidence is unavailable (#{inspect(reason)}); check the selected recovery receipt."

  defp copy(%{state: :verified, operation: :upsert}),
    do: "The expected upsert effect was observed in the active index."

  defp copy(%{state: :verified, operation: :delete}),
    do: "The expected delete effect was observed in the active index."

  defp copy(%{state: :running}),
    do: "The exact backend task is still running; refresh recovery status to check again."

  defp copy(%{state: :failed}),
    do: "The exact backend task failed; inspect its task result before retrying."

  defp copy(%{state: :cancelled}),
    do: "The exact backend task was canceled; inspect its task result before retrying."

  defp copy(%{reason: reason}),
    do:
      "Document freshness could not be checked (#{inspect(reason)}); refresh recovery status to check again."

  defp copy(_observation),
    do: "Document freshness has not been confirmed; refresh recovery status to check again."
end
