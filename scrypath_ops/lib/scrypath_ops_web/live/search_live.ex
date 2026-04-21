defmodule ScrypathOpsWeb.SearchLive do
  use ScrypathOpsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Search & federation")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} shell={@shell}>
      <h1 class="text-2xl font-semibold leading-8 tracking-tight text-balance">Search & federation</h1>
      <p class="mt-4 text-base-content/80">
        Bounded search inspectors and federation-honesty UX ship in phase 46. Read
        <code class="text-sm">guides/multi-index-search.md</code>
        for merge semantics so operators are not misled about a single merged index.
      </p>
    </Layouts.app>
    """
  end
end
