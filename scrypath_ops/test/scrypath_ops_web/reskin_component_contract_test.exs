defmodule ScrypathOpsWeb.ReskinComponentContractTest do
  @moduledoc false
  # Phase 187 component contract for the ScrypathOps re-skin: the phase's one new required
  # component and LiveView contract file, in the `ops-ui (path-scoped)` lane (see CONTRIBUTING
  # "Required-gate budget"). Plans 05 and 06 add their describes to this file; they do not add
  # another required file.
  #
  # What each describe proves, in plain terms:
  #   - E-01 `ops_sync_status`: each status renders its word first and then one decorative 16px
  #     bar icon with its own shape, so the status reads without color, and an unknown status is
  #     rejected when the component is compiled.
  #   - E-03 `ops_condition`: "Not observed", "Not checked", "Queue not used" and "Unavailable"
  #     are plain muted words with no icon, no status and no color of their own, so something
  #     nobody looked at can never read as healthy or as failed.
  use ScrypathOpsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias ScrypathOpsWeb.OpsUi

  @app_css Path.expand("../../assets/css/app.css", __DIR__)
  @condition_words ["Not observed", "Not checked", "Queue not used", "Unavailable"]

  @status_words %{
    failed: "Failed",
    retrying: "Retrying",
    pending: "Pending",
    clear: "Clear"
  }

  @status_shapes %{
    failed: "notched",
    retrying: "bottom-filled",
    pending: "hollow",
    clear: "filled"
  }

  # The tree of one rendered status: {tag, attrs, children}, whitespace between tags dropped.
  defp status_tree(status) do
    [tree] =
      (&OpsUi.ops_sync_status/1)
      |> render_component(%{status: status})
      |> LazyHTML.from_fragment()
      |> LazyHTML.to_tree(skip_whitespace_nodes: true)

    tree
  end

  describe "E-01 ops_sync_status" do
    for status <- [:failed, :retrying, :pending, :clear] do
      test "#{status} renders its word first and then one decorative bar icon" do
        status = unquote(status)
        {"span", attrs, [word, icon]} = status_tree(status)

        assert List.keyfind(attrs, "data-sync-status", 0) == {"data-sync-status", "#{status}"}
        assert {"span", word_attrs, [word_text]} = word
        assert List.keyfind(word_attrs, "class", 0) == {"class", "ops-sync-status__word"}
        assert word_text == @status_words[status]

        assert {"svg", icon_attrs, [{"path", _path_attrs, []}]} = icon
        icon_attrs = Map.new(icon_attrs)

        assert icon_attrs["class"] == "ops-sync-status__icon"
        assert icon_attrs["data-shape"] == @status_shapes[status]
        assert icon_attrs["aria-hidden"] == "true"
        assert icon_attrs["focusable"] == "false"
        assert icon_attrs["height"] == "16"
        assert icon_attrs["viewBox"] == "0 0 8.63 16"
        assert icon_attrs["fill"] == "currentColor"
        refute Map.has_key?(icon_attrs, "role")
        refute Map.has_key?(icon_attrs, "aria-label")
        refute Map.has_key?(icon_attrs, "aria-labelledby")
      end
    end

    test "exactly one status element and one icon per render" do
      for status <- Map.keys(@status_words) do
        doc =
          (&OpsUi.ops_sync_status/1)
          |> render_component(%{status: status})
          |> LazyHTML.from_fragment()

        assert doc |> LazyHTML.query("[data-sync-status]") |> Enum.count() == 1
        assert doc |> LazyHTML.query("svg") |> Enum.count() == 1
        assert doc |> LazyHTML.query("[data-sync-status=#{status}]") |> Enum.count() == 1
      end
    end

    test "the four shapes are drawn with four distinct paths" do
      paths =
        for status <- Map.keys(@status_words) do
          {"span", _attrs, [_word, {"svg", _icon_attrs, [{"path", path_attrs, []}]}]} =
            status_tree(status)

          {"d", d} = List.keyfind(path_attrs, "d", 0)
          d
        end

      assert length(paths) == 4
      assert paths |> Enum.uniq() |> length() == 4
    end

    test "an unknown status is rejected at compile time by the attr's closed value list" do
      status_attr =
        OpsUi.__components__()
        |> Map.fetch!(:ops_sync_status)
        |> Map.fetch!(:attrs)
        |> Enum.find(&(&1.name == :status))

      assert status_attr.required
      assert status_attr.type == :atom
      assert Keyword.fetch!(status_attr.opts, :values) == [:failed, :retrying, :pending, :clear]
    end
  end

  describe "E-03 ops_condition" do
    for word <- ["Not observed", "Not checked", "Queue not used", "Unavailable"] do
      test "#{word} is a plain word with no icon and no status" do
        word = unquote(word)
        html = render_component(&OpsUi.ops_condition/1, %{word: word})
        doc = LazyHTML.from_fragment(html)

        assert [condition] = doc |> LazyHTML.query(".ops-condition") |> Enum.to_list()
        assert String.trim(LazyHTML.text(condition)) == word

        assert doc |> LazyHTML.query("svg") |> Enum.count() == 0
        refute html =~ "hero-"
        refute html =~ "data-sync-status"
        refute html =~ "data-shape"
      end
    end

    test "the condition set is closed" do
      word_attr =
        OpsUi.__components__()
        |> Map.fetch!(:ops_condition)
        |> Map.fetch!(:attrs)
        |> Enum.find(&(&1.name == :word))

      assert word_attr.required
      assert Keyword.fetch!(word_attr.opts, :values) == @condition_words
      refute "Unknown" in @condition_words
    end

    test "the stylesheet paints a condition as muted body text with no status color" do
      [_, body] = Regex.run(~r/\n  \.ops-condition \{([^}]*)\}/, File.read!(@app_css))

      assert body =~ "color: var(--ops-text-muted)"
      assert body =~ "font-weight: 400"
      refute body =~ "--ops-status-"
    end
  end
end
