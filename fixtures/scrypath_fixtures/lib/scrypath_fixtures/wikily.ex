defmodule ScrypathFixtures.Wikily do
  @moduledoc """
  Wikily scenarios. Wikily is a fictional team-wiki product; the data is for development and tests
  only.

  Fictional adopter: Scrypath-owned data, no records copied from any other project.

  Wikily is an empty install, the four stages a new operator passes through before search health
  has anything to show. All four are ordinary states, and each is one the real code produces:

    * `:unconfigured` has an empty schema allowlist. The posture reads "Not configured".
    * `:missing_backend` allowlists a schema but sets no `:backend`. The posture reads "Broken".
      `Scrypath.sync_status/2` itself raises `ArgumentError` ("required :backend option not
      found") without a backend; only the posture's own guard keeps the operator UI from calling
      it, so this scenario states no per-schema expectation.
    * `:index_not_created` has a backend and a schema but no index yet. Meilisearch answers a task
      list for an index that does not exist with an empty page, not an error, so the sync status is
      clear, and `Scrypath.index_contract_drift/2` returns `{:error, :index_not_found}` because
      reading the settings of that index is a 404.
    * `:first_delete_failed` is the first thing that goes wrong there: a document delete queued
      before the index existed becomes a failed `documentDeletion` task with `index_not_found`.

  Wikily uses `sync_mode: :inline`, the low-complexity mode, so there is no queue to observe. Its
  `meilisearch_url` has no entry in `ScrypathFixtures.AppliedSettings`, which is what makes the
  index "never created".
  """

  alias ScrypathFixtures.FakeMeilisearchClient
  alias ScrypathFixtures.Meili
  alias ScrypathFixtures.Scenario
  alias ScrypathFixtures.Wikily.Page

  @index_prefix "wikily"

  # RFC 2606: the .invalid top-level domain never resolves. No AppliedSettings entry owns this
  # url, so reading the index settings answers the recorded 404.
  @url "https://wikily.fixtures.invalid"

  @states [:unconfigured, :missing_backend, :index_not_created, :first_delete_failed]

  @doc "The state names `scenario/2` builds."
  @spec states() :: [:unconfigured | :missing_backend | :index_not_created | :first_delete_failed]
  def states, do: @states

  @doc "Builds one named Wikily scenario at `now`."
  @spec scenario(
          :unconfigured | :missing_backend | :index_not_created | :first_delete_failed,
          keyword()
        ) :: Scenario.t()
  def scenario(state, now: %DateTime{} = now) when state in @states do
    index = Scrypath.Meilisearch.index_name(Page, index_prefix: @index_prefix)
    {id, label, allowlist, opts, expect} = describe(state, now, index)

    %Scenario{
      id: id,
      adopter: :wikily,
      label: label,
      kind: :ordinary,
      now: now,
      allowlist: allowlist,
      scrypath_opts: opts,
      expect: expect
    }
  end

  defp base_opts do
    [
      backend: Scrypath.Meilisearch,
      sync_mode: :inline,
      index_prefix: @index_prefix,
      meilisearch_url: @url,
      meilisearch_client: FakeMeilisearchClient
    ]
  end

  defp describe(:unconfigured, _now, _index) do
    {:wikily_unconfigured, "Wikily pages, not configured (fictional)", [],
     base_opts() ++ [meilisearch_tasks: []],
     %{posture: %{state: :unconfigured, headline: "Not configured"}}}
  end

  defp describe(:missing_backend, _now, _index) do
    {:wikily_missing_backend, "Wikily pages, backend missing (fictional)", [Page],
     Keyword.delete(base_opts(), :backend) ++ [meilisearch_tasks: []],
     %{posture: %{state: :missing_backend, headline: "Broken"}}}
  end

  defp describe(:index_not_created, _now, _index) do
    {:wikily_index_not_created, "Wikily pages, index not created (fictional)", [Page],
     base_opts() ++ [meilisearch_tasks: []],
     %{
       sync_status: :ok,
       failed_sync_work: :ok,
       index_contract_drift: {:error, :index_not_found},
       posture: %{state: :ok, headline: "No sync failures found"}
     }}
  end

  defp describe(:first_delete_failed, now, index) do
    delete =
      Meili.task(%{
        type: "documentDeletion",
        status: "failed",
        uid: 1,
        index_uid: index,
        now: now,
        enqueued_ago: 1_800,
        failure: {:index_not_found_task, uid: index}
      })

    {:wikily_first_delete_failed, "Wikily pages, first delete failed (fictional)", [Page],
     base_opts() ++ [meilisearch_tasks: [delete]],
     %{
       sync_status: :ok,
       failed_sync_work: :ok,
       index_contract_drift: {:error, :index_not_found},
       posture: %{state: :degraded, headline: "1 Meilisearch task failed"}
     }}
  end
end
