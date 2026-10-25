defmodule Scrypath.BackfillContractDocsTest do
  # Core-lane pins for the documented backfill/reindex result contract.
  # Not tagged :docs_contract on purpose, so drift fails the default `mix test`.
  use ExUnit.Case, async: true

  @readme "README.md"

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
end
