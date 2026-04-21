defmodule ScrypathOpsWeb.SyncDriftLive do
  use ScrypathOpsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Sync / drift")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} shell={@shell}>
      <h1 class="text-2xl font-semibold leading-8 tracking-tight text-balance">Sync / drift</h1>
      <p class="mt-4 text-base-content/80">
        Read-only drift views stay thin here on purpose: use
        <code class="text-sm">mix scrypath.status</code>, drift recovery guides, and sync visibility
        docs linked from <code class="text-sm">operator-ia.md</code> so the library surface stays canonical.
      </p>
    </Layouts.app>
    """
  end
end
