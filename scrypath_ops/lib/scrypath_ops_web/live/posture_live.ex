defmodule ScrypathOpsWeb.PostureLive do
  use ScrypathOpsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Posture / health")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} shell={@shell}>
      <h1 class="text-2xl font-semibold leading-8 tracking-tight text-balance">Posture / health</h1>
      <p class="mt-4 text-base-content/80">
        Full posture dashboards and health signals are planned for phase 45. Until then, use
        <code class="text-sm">mix scrypath.status</code>
        and the operations guides linked from
        <code class="text-sm">operator-ia.md</code>.
      </p>
    </Layouts.app>
    """
  end
end
