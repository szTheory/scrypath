defmodule ScrypathEcommerceWeb.E2EUIFixtureLive do
  @moduledoc false
  # Dev/test-only rendered component boundaries; no backend operations or global config changes.
  use ScrypathOpsWeb, :live_view

  @schemas [
    ScrypathEcommerce.Catalog.Product,
    ScrypathEcommerce.Catalog.Variant,
    ScrypathEcommerce.Catalog.Inventory.Warehouse.StockKeepingUnitWithAnIntentionallyLongName,
    ScrypathEcommerce.Catalog.ArchivedProduct,
    ScrypathEcommerce.Catalog.SupplierProduct
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket, schemas: @schemas, selected: hd(@schemas), page_title: "Component boundaries")}
  end

  @impl true
  def handle_event("select_schema", %{"schema" => name}, socket) do
    selected =
      Enum.find(@schemas, &(String.replace_prefix(Atom.to_string(&1), "Elixir.", "") == name))

    {:noreply, assign(socket, :selected, selected || socket.assigns.selected)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} mount_path="/admin/search" shell={:ops} page_title={@page_title}>
      <.ops_page_header
        title={@page_title}
        subtitle="Rendered shared controls for automated acceptance."
      />
      <.ops_panel>
        <.form for={%{}} id="many-schema-form" phx-change="select_schema">
          <.ops_schema_select id="many-schema" label="Schema" schemas={@schemas} selected={@selected} />
        </.form>
        <p id="selected-schema" class="mt-3 text-ops-body break-all">{inspect(@selected)}</p>
        <.ops_field id="long-filename" label="Playbook filename">
          <.ops_text_input
            id="long-filename"
            name="filename"
            value="inventory-recovery-for-international-warehouses-with-an-intentionally-long-filename.json"
          />
        </.ops_field>
        <.ops_status kind={:partial} title="Queue state unavailable">
          Backend tasks remain visible. Refresh queue status before retrying sync work.
        </.ops_status>
        <.ops_disclosure id="long-diagnostics" summary="Diagnostics">
          <.ops_code_block>{String.duplicate("long_backend_identifier_", 30)}</.ops_code_block>
        </.ops_disclosure>
      </.ops_panel>
    </Layouts.app>
    """
  end
end
