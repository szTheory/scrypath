defmodule Scrypath.BackfillContractDocsTest do
  # Core-lane pins for the documented backfill/reindex result contract.
  # Not tagged :docs_contract on purpose, so drift fails the default `mix test`.
  use ExUnit.Case, async: true

  @readme "README.md"
  @sync_modes_guide "guides/sync-modes-and-visibility.md"
  @related_data_guide "guides/related-data-and-reindexing.md"
  @contributing "CONTRIBUTING.md"

  defp backfill_doc do
    {:docs_v1, _anno, _lang, _format, _module_doc, _meta, docs} = Code.fetch_docs(Scrypath)

    Enum.find_value(docs, fn
      {{:function, :backfill, 2}, _anno, _sig, %{"en" => doc}, _meta} -> doc
      _entry -> nil
    end) || flunk("Scrypath.backfill/2 has no @doc")
  end

  defp assert_contains_all(text, label, fragments) do
    for fragment <- fragments do
      assert text =~ fragment, "expected #{label} to contain #{inspect(fragment)}"
    end
  end

  test "Scrypath.backfill/2 @doc describes the result contract" do
    assert_contains_all(backfill_doc(), "Scrypath.backfill/2 @doc", [
      "removed",
      "batches",
      "documents",
      "mode",
      "batch_results",
      "last_primary_key",
      "delete_task",
      "asynchronously",
      "[org_id: 1, id: 7]"
    ])
  end

  test "Scrypath.backfill/2 @doc does not expose internal options" do
    refute backfill_doc() =~ "_scrypath_fresh_target"
    refute backfill_doc() =~ "prepare_records"
  end

  test "README lists the reindex omission count" do
    assert File.read!(@readme) =~ "result.omitted"
  end

  test "sync-modes guide states backfill removal, reindex omission and the scope limit" do
    assert_contains_all(File.read!(@sync_modes_guide), @sync_modes_guide, [
      "omitted",
      "reconcile_sync",
      "delete_task",
      "only ids from the rows it visits",
      "not a whole-index prune"
    ])
  end

  test "related-data guide covers composite keys and :query fan-out" do
    assert_contains_all(File.read!(@related_data_guide), @related_data_guide, [
      "composite",
      "constraint",
      "fan out",
      "omitted",
      "not a whole-index prune"
    ])
  end

  test "CONTRIBUTING documents the real-Postgres loader lane" do
    assert_contains_all(File.read!(@contributing), @contributing, [
      "mix verify.postgres",
      "SCRYPATH_POSTGRES_URL",
      "docker compose up -d postgres",
      "**`backend`**"
    ])
  end
end
