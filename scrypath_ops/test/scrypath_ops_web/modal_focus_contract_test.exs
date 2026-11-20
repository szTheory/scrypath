defmodule ScrypathOpsWeb.ModalFocusContractTest do
  @moduledoc false
  # COPY-04: a destructive dialog opens with its Cancel button focused. `ops_modal/1` sends that
  # request to the browser as `data-ops-modal-initial-focus`, and its default is the Cancel
  # marker, so a dialog that forgets to set it is safe. This pins the default.
  #
  # The two destructive `ops_modal` dialogs also pin the attribute where they are used:
  # Confirm index promotion in `sync_drift_live_test.exs` and Confirm delete sync work in
  # `failed_sync_live_test.exs`. The hosted `ecommerce-mounted` lane asserts the focus itself in
  # `operator.spec.ts`. The Save search modal and the saved-search delete confirmation are pinned
  # in `search_saved_searches_test.exs`.
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias ScrypathOpsWeb.OpsUi

  @cancel_default "[data-ops-modal-cancel]"

  test "ops_modal asks the browser to focus its Cancel button by default" do
    assert_initial_focus(render_modal(), @cancel_default)
  end

  test "a dialog that overrides the default is seen by the same assertion" do
    override = render_modal(initial_focus: "#name-input")

    assert initial_focus(override) == "#name-input"

    # The planted case: the pin that passes on the default fails on an override.
    assert_raise ExUnit.AssertionError, fn -> assert_initial_focus(override, @cancel_default) end

    # And the override is honoured as written, so the default is the only thing the pin guards.
    assert_initial_focus(override, "#name-input")
  end

  # Helpers ---------------------------------------------------------------------------------

  defp render_modal(attrs \\ []) do
    body = [%{__slot__: :inner_block, inner_block: fn _assigns, _arg -> "Dialog body" end}]

    assigns =
      Map.merge(%{id: "focus-pin-modal", title: "Focus pin", inner_block: body}, Map.new(attrs))

    render_component(&OpsUi.ops_modal/1, assigns)
  end

  defp initial_focus(html) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query("#focus-pin-modal[role=dialog]")
    |> LazyHTML.attribute("data-ops-modal-initial-focus")
    |> case do
      [selector] -> selector
      other -> flunk("expected one dialog with an initial-focus attribute, got #{inspect(other)}")
    end
  end

  defp assert_initial_focus(html, selector) do
    assert initial_focus(html) == selector
  end
end
