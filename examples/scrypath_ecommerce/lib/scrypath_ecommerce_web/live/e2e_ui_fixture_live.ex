defmodule ScrypathEcommerceWeb.E2EUIFixtureLive do
  @moduledoc false
  # Dev/test-only rendered component boundaries; no backend operations or global config changes.
  use ScrypathOpsWeb, :live_view
  import ScrypathOpsWeb.ResultUi

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
     assign(socket,
       hit_fixture: %{
         "name" => "Travel scanner",
         "description" =>
           "A compact scanner with a readable description, useful for judging a search match.",
         "id" => "custom-key-42",
         "available" => false,
         "inventory_count" => 0,
         "note" => nil,
         "options" => %{"colors" => ["Slate", "Copper"], "portable" => true},
         "price_cents" => 1299
       },
       schemas: @schemas,
       selected: hd(@schemas),
       page_title: "Component boundaries"
     )}
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
        <.ops_field id="long-filename" label="Saved search filename">
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
      <section id="typed-result-fixture" aria-label="Example returned hit" class="mt-6">
        <.ops_heading>Example returned hit</.ops_heading>
        <.result_hit hit={@hit_fixture} position={1} />
      </section>
    </Layouts.app>
    """
  end
end
