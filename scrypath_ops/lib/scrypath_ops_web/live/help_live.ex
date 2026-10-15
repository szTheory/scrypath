defmodule ScrypathOpsWeb.HelpLive do
  @moduledoc "Task help shipped with the installed operator interface."
  use ScrypathOpsWeb, :live_view

  @impl true
  def mount(_params, _session, socket), do: {:ok, assign(socket, :page_title, "Help")}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app mount_path={@mount_path} flash={@flash} shell={@shell} page_title={@page_title}>
      <.ops_page_header
        title="Help"
        subtitle="Try a query, understand a sync problem, or reuse a search."
      />
      <nav class="ops-help-topics" aria-label="Help topics">
        <a href="#search">Try search</a>
        <a href="#saved-searches">Save and reuse</a>
        <a href="#sync">Understand sync</a>
        <a href="#settings">Check settings</a>
      </nav>
      <div class="ops-help-content">
        <section id="search">
          <.ops_heading>Try a search</.ops_heading>
          <p>Select a schema, enter search text and run the query. Leave the text blank to browse.</p>
          <p>
            A schema is the Elixir module that defines your searchable data. Its Meilisearch index holds the search documents.
          </p>
          <p id="ranking">
            With multiple schemas, results are grouped by source. Combined result order shows how Meilisearch returned the hits across those sources; raw relevance scores from different indexes are not directly comparable.
          </p>
          <p id="limits">
            The result limit controls how many hits to return. In multi-schema mode it applies to the combined response. This screen shows the first set of results; it has no next-page control.
          </p>
          <p>
            Readable fields show the returned document. Open Raw hit payload to inspect or copy its Elixir representation. Database records and search documents can differ.
          </p>
          <.link navigate={"#{@mount_path}/search"} class="ops-text-action">
            Open Search <span aria-hidden="true">→</span>
          </.link>
        </section>
        <section id="saved-searches">
          <.ops_heading>Save and reuse a search</.ops_heading>
          <p>
            After running a query, choose Save search beside the results. This saves the query and options that produced those results.
          </p>
          <p>
            Saved searches are JSON files in a folder on this server. They contain inputs, not result snapshots. Your host application controls the folder and its persistence; the list is not a personal browser bookmark collection.
          </p>
          <p>
            Open Saved searches to preview a file, run it again or manage it. Previewing a file does not run its query.
          </p>
          <.link navigate={"#{@mount_path}/playbooks"} class="ops-text-action">
            Open Saved searches <span aria-hidden="true">→</span>
          </.link>
        </section>
        <section id="sync">
          <.ops_heading>Understand a sync problem</.ops_heading>
          <p>
            Changes travel from your application to Meilisearch, then Meilisearch applies them to the index. A request being accepted does not mean its documents are searchable yet.
          </p>
          <dl class="ops-help-definitions">
            <div>
              <dt>Background sync · Oban</dt>
              <dd>
                Your application queues durable jobs. Pending work can be normal; scheduled retries have encountered a failure, and failed jobs may need your attention.
              </dd>
            </div>
            <div>
              <dt>Inline sync</dt>
              <dd>
                The application sends changes directly and waits for the tracked Meilisearch task to finish.
              </dd>
            </div>
            <div>
              <dt>Manual sync</dt>
              <dd>
                An explicit sync call sends changes and returns when Meilisearch accepts them, without waiting for completion.
              </dd>
            </div>
            <div>
              <dt>Meilisearch document tasks</dt>
              <dd>
                Meilisearch's work to add, update or delete search documents. These tasks have their own IDs and states, separate from Oban jobs.
              </dd>
            </div>
          </dl>
          <p>
            The interface uses the sync mode configured by your host. Application code can override the mode for individual calls; this screen does not discover those overrides.
          </p>
          <p>
            Search health shows failures and pending work by schema. Inspect the error before retrying. A queued retry is a new operation; follow its status to check completion. No failures in the available history does not prove the index is current.
          </p>
          <.link navigate={"#{@mount_path}/health"} class="ops-text-action">
            Open Search health <span aria-hidden="true">→</span>
          </.link>
        </section>
        <section id="settings">
          <.ops_heading>Check index settings</.ops_heading>
          <p>
            Sync and drift compares your schema's declared settings with the live Meilisearch index. The comparison loads automatically and makes no changes.
          </p>
          <p>
            Matching settings and successfully completed tasks are useful checks. To confirm an expected document is searchable, run a query for it.
          </p>
          <.link navigate={"#{@mount_path}/sync-drift"} class="ops-text-action">
            Open Sync and drift <span aria-hidden="true">→</span>
          </.link>
        </section>
        <section id="timestamps">
          <.ops_heading>Read and copy timestamps</.ops_heading>
          <p>
            The Time control switches between UTC and your browser's local time zone. Click a timestamp, or focus it and press Enter, to copy its exact source value. A notification confirms the copy.
          </p>
        </section>
        <section id="developer-docs">
          <.ops_heading>Developer documentation</.ops_heading>
          <p>For application setup, APIs and detailed recovery procedures:</p>
          <ul>
            <li>
              <a href="https://github.com/szTheory/scrypath/blob/main/guides/sync-modes-and-visibility.md">
                Sync modes and visibility
              </a>
            </li>
            <li>
              <a href="https://github.com/szTheory/scrypath/blob/main/guides/drift-recovery.md">
                Failure recovery
              </a>
            </li>
            <li>
              <a href="https://github.com/szTheory/scrypath/blob/main/scrypath_ops/docs/team-playbook-persistence.md">
                Saved-search storage and deployment
              </a>
            </li>
          </ul>
        </section>
      </div>
    </Layouts.app>
    """
  end
end
