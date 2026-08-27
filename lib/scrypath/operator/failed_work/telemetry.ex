defmodule Scrypath.Operator.FailedWork.Telemetry do
  @moduledoc false

  @spec emit(map()) :: :ok
  def emit(row) when is_map(row) do
    :telemetry.execute(
      [:scrypath, :operator, :failed_work, :observed],
      %{count: 1},
      %{
        reason_class: row.reason_class,
        schema: row.schema,
        mode: row.mode,
        operation: row.operation,
        retryable?: row.retryable?
      }
    )
  end
end
