defmodule ScrypathOpsWeb.OpsUi do
  @moduledoc """
  Shared function components for `/ops` surfaces: page chrome, panels, and optional scaffold.
  """
  use Phoenix.Component

  use Gettext, backend: ScrypathOpsWeb.Gettext

  @doc """
  Primary page title (`<h1>`) and optional subtitle for operator LiveViews.

  The visible title exposes `id={title_id}` (default `"ops-page-title"`) so the `:ops`
  shell can reference it from `main` via `aria-labelledby`. Each `/ops` route should
  render a single page-level `h1` — do not duplicate this id elsewhere.
  """
  attr(:title, :string, required: true)
  attr(:subtitle, :string, default: nil)
  attr(:title_id, :string, default: "ops-page-title")

  def ops_page_header(assigns) do
    ~H"""
    <div class="space-y-1">
      <h1 id={@title_id} class="text-2xl font-semibold leading-8 tracking-tight">{@title}</h1>
      <p :if={@subtitle} class="text-sm text-base-content/70">{@subtitle}</p>
    </div>
    """
  end

  @doc """
  Flat bordered panel for primary JTBD blocks (D-12).
  """
  slot(:inner_block, required: true)

  def ops_panel(assigns) do
    ~H"""
    <div class="border border-base-300 rounded-lg bg-base-100 p-4">
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Composes `ops_page_header/1` and `ops_panel/1` when a LiveView prefers a single wrapper.
  """
  attr(:title, :string, required: true)
  attr(:subtitle, :string, default: nil)
  attr(:title_id, :string, default: "ops-page-title")
  slot(:inner_block, required: true)

  def ops_scaffold(assigns) do
    ~H"""
    <div class="space-y-4">
      <.ops_page_header title={@title} subtitle={@subtitle} title_id={@title_id} />
      <.ops_panel>
        {render_slot(@inner_block)}
      </.ops_panel>
    </div>
    """
  end
end
