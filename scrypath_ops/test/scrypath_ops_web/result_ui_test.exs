defmodule ScrypathOpsWeb.ResultUiTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  alias ScrypathOpsWeb.{OpsUi, ResultUi}

  test "arbitrary returned fields retain false, zero, null, nested values and descriptive text" do
    hit = %{
      "uuid" => "record-42",
      "description" => "Useful text to judge this match.",
      "active" => false,
      "quantity" => 0,
      "optional" => nil,
      "tags" => ["one", "two"],
      "details" => %{"note" => "<script>untrusted</script>"}
    }

    document =
      render_component(&ResultUi.result_hit/1, hit: hit, position: 2) |> LazyHTML.from_fragment()

    assert document |> LazyHTML.query("h3") |> LazyHTML.text() == "Result 2"
    assert LazyHTML.text(document) =~ hit["description"]
    assert LazyHTML.text(document) =~ "false"
    assert LazyHTML.text(document) =~ "null"
    assert LazyHTML.text(document) =~ "record-42"
    assert document |> LazyHTML.query("script") |> Enum.empty?()

    assert document |> LazyHTML.query("button[aria-label='Copy hit payload']") |> Enum.count() ==
             1
  end

  test "raw copy preserves every item beyond inspect defaults and no template indentation" do
    hit = %{"title" => "Long data", "items" => Enum.to_list(1..80)}

    document =
      render_component(&ResultUi.result_hit/1, hit: hit, position: 1) |> LazyHTML.from_fragment()

    raw = document |> LazyHTML.query("pre") |> LazyHTML.text()
    assert String.starts_with?(raw, "%{")
    assert raw =~ "80"
    refute raw =~ "..."

    [{"data-ops-copy-text", copied}] =
      document
      |> LazyHTML.query("button[data-ops-copy-text]")
      |> LazyHTML.attribute("data-ops-copy-text")
      |> Enum.map(&{"data-ops-copy-text", &1})

    assert copied == raw
  end

  test "code blocks preserve intentional source whitespace without adding caller indentation" do
    source = "{\n  \"value\": \"  keep these spaces  \"\n}"
    document = render_component(&OpsUi.ops_code_block/1, text: source) |> LazyHTML.from_fragment()
    assert document |> LazyHTML.query("pre") |> LazyHTML.text() == source
  end
end
