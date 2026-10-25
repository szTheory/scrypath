defmodule Scrypath.Oban do
  @moduledoc """
  Narrow Oban helpers for composing Scrypath sync jobs into `Ecto.Multi`.

  `enqueue_upsert/5` and `enqueue_delete/5` add one job per `Ecto.Multi` step, whatever the
  number of records or ids. Unlike `Scrypath.sync_records/3` under `sync_mode: :oban`, they do
  not split the ids into several jobs; the worker bounds each backend write to at most 1000
  documents or ids.

  These helpers insert the job inside your transaction, so the hazards described in the
  sync modes guide under "Call sync functions after your write commits" apply: the job can
  collapse into an identical pending job that runs before your commit. Prefer calling
  `Scrypath.sync_records/3` or `Scrypath.delete_documents/3` after the commit.
  """
  @compile {:no_warn_undefined, Oban}

  alias Ecto.Multi
  alias Scrypath.Config
  alias Scrypath.Oban.Enqueue
  alias Scrypath.Identity

  @spec enqueue_upsert(Multi.t(), Multi.name(), module(), [struct() | map()], keyword()) ::
          Multi.t()
  def enqueue_upsert(%Multi{} = multi, name, schema_module, records, opts)
      when is_list(records) do
    config =
      opts
      |> Config.resolve!()
      |> Config.ensure_oban_ready!()

    document_ids = Identity.document_ids(schema_module, records)
    changeset = Enqueue.upsert_job_changeset(schema_module, document_ids, config)

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
