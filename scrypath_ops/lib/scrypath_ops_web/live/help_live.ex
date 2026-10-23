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
        subtitle="Explanations of search results, synchronization and recovery."
      />
      <nav class="ops-help-topics" aria-label="Help topics">
        <a href="#search">Try search</a>
        <a href="#saved-searches">Save and reuse</a>
        <a href="#sync">Understand sync</a>
        <a href="#settings">Check settings</a>
      </nav>
      <div class="ops-help-content" id="ops-help-content" phx-hook="OpsHelpAnchor">
        <section id="search">
          <.ops_heading>
            <span class="ops-help-heading">
              <.icon name="hero-magnifying-glass" class="size-5" />Try a search
            </span>
          </.ops_heading>
          <p>Select a schema, enter search text and run the query. Leave the text blank to browse.</p>
          <p>
            A schema is the Elixir module that defines your searchable data. Its Meilisearch index holds the search documents.
          </p>
          <section
            id="ranking"
            class="ops-help-subtopic"
            aria-labelledby="ranking-title"
          >
            <h3 id="ranking-title">How ordering works</h3>
            <p>
              Searching multiple schemas sends one query per schema in a single Meilisearch request. Meilisearch combines the hits; the result list keeps that returned order. Raw relevance scores from different indexes are not directly comparable.
            </p>
            <p>
              A schema with no hits on the current page may still have matches further down the combined order. Partial results identify schemas that could not be searched.
            </p>
          </section>
          <section id="limits" class="ops-help-subtopic" aria-labelledby="limits-title">
            <h3 id="limits-title">Results per page</h3>
            <p>
              Use a small page to inspect matches quickly. Previous and Next browse further results without fetching everything at once. In multi-schema search, the page size applies across all selected schemas together.
            </p>
            <p>
              The host sets the maximum per page (50 by default) with <code>:search_playground_max_page_size</code>. It can raise this budget for larger comparisons. This is an operator UI request budget, not a limit on the number of matching documents or your application's search UI.
            </p>
            <p>
              A full page offers Next; the following page can be empty. Meilisearch's own search limits still apply, and changing data can move results between pages.
            </p>
          </section>
          <p>
            Readable fields show the returned document. Open Raw hit payload to inspect or copy its Elixir representation. Database records and search documents can differ.
          </p>
          <.link navigate={"#{@mount_path}/search"} class="ops-text-action">
            Open Search <span aria-hidden="true">→</span>
          </.link>
        </section>
        <section id="saved-searches">
          <.ops_heading>
            <span class="ops-help-heading">
              <.icon name="hero-book-open" class="size-5" />Save and reuse a search
            </span>
          </.ops_heading>
          <p>
            Choose Save search beside Run search to keep the inputs in the form under a name. A saved search contains the query and options, not the results.
          </p>
          <p>
            Pick one from Saved searches in Search to fill the form and run it. After you change the inputs, Save updates it and Save as keeps a copy under a new name. A saved search with options the form can't show runs exactly as saved and lists the inputs it used.
          </p>
          <p>
            Manage saved searches loads, renames and deletes them, and imports or exports them as JSON files to share between environments.
          </p>
          <.link navigate={"#{@mount_path}/search?saved=manage"} class="ops-text-action">
            Manage saved searches <span aria-hidden="true">→</span>
          </.link>
        </section>
        <section id="sync">
          <.ops_heading>
            <span class="ops-help-heading">
              <.icon name="hero-shield-check" class="size-5" />Understand a sync problem
            </span>
          </.ops_heading>
          <p>
            Changes travel from your application to Meilisearch, then Meilisearch applies them to the index. A request being accepted does not mean its documents are searchable yet.
          </p>
          <dl class="ops-help-definitions">
            <div>
              <dt>Background sync with Oban</dt>
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
          <section
            id="recovery"
            class="ops-help-subtopic"
            aria-labelledby="recovery-title"
          >
            <h3 id="recovery-title">Recover from a sync failure</h3>
            <p>
              Failed sync work lists sync work that didn't reach Meilisearch for every schema; filter by schema or cause to narrow it. Retry queues the same records again and sends their current data, so fix invalid data first. Retrying items will run again automatically.
            </p>
            <p>
              After Retry is queued, follow Check sync status to track that operation and its expected document effect. Acceptance alone does not confirm recovery.
            </p>
          </section>
          <.link navigate={"#{@mount_path}/health"} class="ops-text-action">
            Open Search health <span aria-hidden="true">→</span>
          </.link>
        </section>
        <section id="settings">
          <.ops_heading>
            <span class="ops-help-heading">
              <.icon name="hero-arrows-right-left" class="size-5" />Check index settings
            </span>
          </.ops_heading>
          <p>
            Sync and index compares the settings of the live Meilisearch index with what your schema's
            <code>use Scrypath</code>
            declaration says. The comparison loads automatically and makes no changes.
          </p>
          <p>
            Filterable attributes are the fields Meilisearch allows in query filters. An index can enable several. “Not enabled for filtering” means a declared field is absent from that index's live filterable settings; it does not mean the field or index is missing.
          </p>
          <p>
            A schema normally maps to its own index. Multiple tenants can share that index. Enabling a tenant field for filtering does not apply a tenant filter automatically or enforce access control; application queries and authorization must do that.
          </p>
          <p>
            If the declaration is correct, apply it through your application's index setup or reindex workflow, then use Refresh to compare again. Review the deployment procedure in the developer documentation before changing a live index.
          </p>
          <p>
            Settings drift when the code changes but the live index doesn't. For example, adding a field to
            <code>filterable</code>
            has no effect until the settings are applied or the index is rebuilt, so filters on that field fail even though every document synced.
          </p>
          <p>
            Matching settings and successfully completed tasks are useful checks. To confirm an expected document is searchable, run a query for it.
          </p>
          <.link navigate={"#{@mount_path}/sync-and-index"} class="ops-text-action">
            Open Sync and index <span aria-hidden="true">→</span>
          </.link>
        </section>
        <section id="reindexing">
          <.ops_heading>
            <span class="ops-help-heading">
              <.icon name="hero-arrow-path" class="size-5" />Zero-downtime reindexing
            </span>
          </.ops_heading>
          <p>
            A zero-downtime reindex builds a complete copy of the index, called the prepared index, while searches keep using the live one. When the prepared index is ready, promotion asks Meilisearch to swap the two, so searches move to the new index in one step.
          </p>
          <p>
            Sync and index shows promotion only after it finds a prepared index for the selected schema. Promotion stays blocked while sync work is pending or failed, while the reindex is still running, or while the settings differ from the schema. It always asks for confirmation.
          </p>
          <p>
            Reindexing starts from your application, not from this screen. See the developer documentation for the full procedure.
          </p>
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
              <a href="https://github.com/szTheory/scrypath/blob/main/scrypath_ops/docs/team-saved-search-persistence.md">
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
