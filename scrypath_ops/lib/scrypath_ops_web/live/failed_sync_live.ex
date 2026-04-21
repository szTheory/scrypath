defmodule ScrypathOpsWeb.FailedSyncLive do
  use ScrypathOpsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Failed sync work")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} shell={@shell}>
      <h1 class="text-2xl font-semibold leading-8 tracking-tight text-balance">Failed sync work</h1>
      <p class="mt-4 text-base-content/80">
        Interactive failed-work triage ships in phase 45. Today, run
        <code class="text-sm">mix scrypath.failed</code>
        as documented in the operator Mix guide.
      </p>
    </Layouts.app>
    """
  end
end
