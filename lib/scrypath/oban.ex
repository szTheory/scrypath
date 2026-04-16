defmodule Scrypath.Oban do
  @moduledoc """
  Narrow Oban helpers for composing Scrypath sync jobs into `Ecto.Multi`.
  """

  alias Ecto.Multi
  alias Scrypath.Config
  alias Scrypath.Oban.Enqueue
  alias Scrypath.Projection

  @spec enqueue_upsert(Multi.t(), Multi.name(), module(), [struct() | map()], keyword()) ::
          Multi.t()
  def enqueue_upsert(%Multi{} = multi, name, schema_module, records, opts)
      when is_list(records) do
    config =
      opts
      |> Config.resolve!()
      |> Config.ensure_oban_ready!()

    documents = Enum.map(records, &Projection.document(schema_module, &1))
    changeset = Enqueue.upsert_job_changeset(schema_module, documents, config)

    insert_multi_job(Config.oban_module(config), multi, name, changeset)
  end

  @spec enqueue_delete(Multi.t(), Multi.name(), module(), [term()], keyword()) :: Multi.t()
  def enqueue_delete(%Multi{} = multi, name, schema_module, document_ids, opts)
      when is_list(document_ids) do
    config =
      opts
      |> Config.resolve!()
      |> Config.ensure_oban_ready!()

    changeset = Enqueue.delete_job_changeset(schema_module, document_ids, config)

    insert_multi_job(Config.oban_module(config), multi, name, changeset)
  end

  defp insert_multi_job(oban, multi, name, changeset) do
    cond do
      oban == Oban ->
        Oban.insert(oban, multi, name, changeset)

      function_exported?(oban, :insert, 3) ->
        oban.insert(multi, name, changeset)

      function_exported?(oban, :insert, 4) ->
        oban.insert(multi, name, changeset, [])

      true ->
        Oban.insert(oban, multi, name, changeset)
    end
  end
end
