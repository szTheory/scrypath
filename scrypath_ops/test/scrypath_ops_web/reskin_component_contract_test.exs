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
  use ScrypathOpsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias ScrypathOpsWeb.OpsUi

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
end
