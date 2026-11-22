defmodule ScrypathOps.Catalog.Stories.Welcome do
  # The first page of the storybook (`/storybook` opens on the first story, and story entries sort
  # before folders). It says where the catalog comes from and what the screens are, in the words a
  # reviewer needs before looking at a story. A page story renders in the storybook's own frame, not in
  # an iframe, so it uses plain markup and the product's text classes only.
  #
  # `mix scrypath_ops.catalog.serve` stores the build facts before it starts the endpoint; this page
  # reads them at render time. Without them (a test, or an endpoint started another way) every git
  # value reads "unknown", never a guess. The `data-catalog-*` attributes are the stable markers a
  # script reads from the dead render (`npm run ui:preflight` and the serve task's port check).
  #
  # The page claims no design is approved. Keep it that way: approval is the maintainer's to give.
  use PhoenixStorybook.Story, :page

  @build_info_key {ScrypathOps.Catalog, :build_info}

  @layout """
  #catalog-start-here { font-family: var(--font-sans); max-width: 48rem; padding: 1.5rem; display: grid; gap: 2rem; }
  #catalog-start-here section { display: grid; gap: 0.75rem; }
  #catalog-start-here h1, #catalog-start-here h2, #catalog-start-here p, #catalog-start-here ul, #catalog-start-here ol, #catalog-start-here dl { margin: 0; }
  #catalog-start-here ul, #catalog-start-here ol { display: grid; gap: 0.5rem; padding-left: 1.25rem; }
  #catalog-start-here ul { list-style: disc; }
  #catalog-start-here ol { list-style: decimal; }
  #catalog-start-here dd { overflow-wrap: anywhere; }
  """

  def doc, do: "Where this storybook comes from and what the screens are."

  def render(assigns) do
    assigns = Phoenix.Component.assign(assigns, info: info(), layout: @layout)

    ~H"""
    <style phx-no-curly-interpolation>
      <%= @layout %>
    </style>
    <div id="catalog-start-here">
      <p class="text-ops-body">
        This storybook shows the screens a ScrypathOps operator uses, drawn by the same components as the real app. Look at one story at a time, in light and dark.
      </p>

      <section aria-labelledby="catalog-source">
        <h2 id="catalog-source" class="text-ops-h2">Where this storybook comes from</h2>
        <p class="text-ops-body">
          Compare these with the code you expect to be looking at. If they differ, this storybook is out of date.
        </p>
        <dl class="ops-facts">
          <div>
            <dt>Main</dt>
            <dd data-catalog-main-sha={@info.main_sha}>main@{@info.main_sha}</dd>
          </div>
          <div>
            <dt>Served code</dt>
            <dd data-catalog-head-sha={@info.head_sha}>{@info.head_sha}</dd>
          </div>
          <div>
            <dt>Uncommitted changes</dt>
            <dd data-catalog-dirty={@info.dirty}>{dirty_label(@info.dirty)}</dd>
          </div>
          <div>
            <dt>Checkout</dt>
            <dd data-catalog-checkout={@info.checkout}>{@info.checkout}</dd>
          </div>
          <div>
            <dt>Time in every story</dt>
            <dd data-catalog-epoch={@info.epoch}>{@info.epoch}</dd>
          </div>
        </dl>
      </section>

      <section aria-labelledby="catalog-what">
        <h2 id="catalog-what" class="text-ops-h2">What you are looking at</h2>
        <ul class="text-ops-body">
          <li>Each story is drawn by the same component the real ScrypathOps screen uses.</li>
          <li>
            The data is made up, for three fictional adopters: Logistify, Shopadelic and Wikily.
          </li>
          <li>
            Screens are static renders. Buttons and links do nothing here, and the links that point into the app go nowhere.
          </li>
          <li>Time is frozen at 2026-11-20 14:00 UTC, so a story reads the same every time.</li>
        </ul>
      </section>

      <section aria-labelledby="catalog-tiers">
        <h2 id="catalog-tiers" class="text-ops-h2">How the stories are grouped</h2>
        <ol class="text-ops-body">
          <li><strong>Primitives</strong>: a single component.</li>
          <li><strong>Patterns</strong>: a small group of components that work together.</li>
          <li><strong>Areas</strong>: one region of a screen.</li>
          <li><strong>Surfaces</strong>: a whole screen.</li>
          <li>
            <strong>Jobs</strong>: one screen state in one persona's situation, named by a JOB id.
          </li>
        </ol>
      </section>

      <section aria-labelledby="catalog-persona">
        <h2 id="catalog-persona" class="text-ops-h2">Who the screens are for</h2>
        <p class="text-ops-body">
          One persona so far: the paged on-call engineer (ROLE-OPS), working JOB-03. Search looks unhealthy or sync work has failed. They need to find the affected work and take a safe recovery step.
        </p>
      </section>

      <section aria-labelledby="catalog-behavior">
        <h2 id="catalog-behavior" class="text-ops-h2">Where behavior lives</h2>
        <p class="text-ops-body">
          Stories show how a screen looks in one state. How it behaves is in the running ScrypathOps preview and in the journey test that walks Search health, Failed sync, Retry and the status check.
        </p>
      </section>

      <section aria-labelledby="catalog-frame">
        <h2 id="catalog-frame" class="text-ops-h2">The frame around the stories</h2>
        <p class="text-ops-body">
          The sidebar, the toolbar and the theme control belong to the upstream storybook library, not to ScrypathOps. Judge the story inside the frame.
        </p>
      </section>

      <section aria-labelledby="catalog-status">
        <h2 id="catalog-status" class="text-ops-h2">Review status</h2>
        <p class="text-ops-body">
          Nothing here is an approved design. These are the current screens, shown so they can be reviewed.
        </p>
      </section>
    </div>
    """
  end

  defp info do
    stored = :persistent_term.get(@build_info_key, %{})

    Map.merge(
      %{
        main_sha: "unknown",
        head_sha: "unknown",
        dirty: "unknown",
        checkout: "unknown",
        epoch: DateTime.to_iso8601(ScrypathFixtures.preview_epoch())
      },
      stored
    )
  end

  defp dirty_label("true"), do: "Yes"
  defp dirty_label("false"), do: "No"
  defp dirty_label(_unknown), do: "Unknown"
end
