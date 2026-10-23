# ScrypathOps operator guide

ScrypathOps is an optional Phoenix and LiveView interface for inspecting search indexing and sync operations. It complements the library's `Scrypath.*` APIs and Mix tasks; it does not replace them or provide host-application authentication.

## Start with your task

- **Try search:** select a schema, enter a query and inspect the returned records. Search shows which query and schemas produced the results, even if you edit the controls afterward.
- **Investigate a sync problem:** open Search health, select the affected schema in Failed sync work and review the error. Retry only supported operations. A queued retry is not a completed update; follow its status to check Meilisearch and document visibility.
- **Reuse a query:** choose Save search beside Run search, then pick it from the Saved searches menu in Search to fill the form and run it again. A saved search contains queries and options, not results or pass/fail expectations. It can include multiple schemas. Manage saved searches (in Search) loads, renames, deletes, imports and exports them.
- **Check an index change:** Sync and index answers three questions for one schema: is sync keeping up, does the live Meilisearch index match your schema's settings, and is a reindex waiting to be promoted. It compares settings automatically and never changes them. Promotion controls appear only once a prepared index exists, and keep their explicit checks and confirmation.

## Navigation

The default mount is `/ops`; host apps can choose another prefix. The demo uses `/admin/search`. Help lives at the bottom of the sidebar and explains the installed UI. This repository guide provides developer and integration context. Navigation is a flat list; Search is the primary exploration path, with health and recovery available alongside it. The landing page remains Control Room. Old `/ops/posture` links redirect to Search health, old `/ops/sync-drift` links redirect to Sync and index (keeping `?schema=`), and old `/ops/playbooks` links open Manage saved searches in Search (`/ops/search?saved=manage`).

| Destination | Default route | Purpose |
| --- | --- | --- |
| Control Room | `/ops/` | Search entry point and current sync summary. |
| Search | `/ops/search` | Query configured schemas and inspect attributed results. |
| Search health | `/ops/health` | Inspect Meilisearch tasks and background sync by schema. |
| Failed sync work | `/ops/failed-sync` | Review failures and scheduled retries; retry eligible operations. |
| Sync and index | `/ops/sync-and-index` | Check sync progress, compare live index settings with the schema, follow a correlated retry and promote a prepared reindex. |
| Help | `/ops/help` | Task-focused help within the installed interface. |

## Reading operational evidence

**Oban jobs** run background synchronization in your application. **Meilisearch tasks** apply changes in the search service. They have separate IDs and states. Pending jobs are not necessarily stuck; a count alone does not establish a backlog. An empty failed-work list does not prove the index is current.

A successful observation reports what was checked. Unavailable, partial or retained evidence stays labeled. Settings agreement and operation completion do not, by themselves, prove expected documents are searchable.

Timestamps display UTC by default. The Time control switches to your browser's local zone and remembers your choice. Click a timestamp, or focus it and press Enter, to copy its original source value; copy failures expose that exact value for manual copying.

Saved searches are stored in the host Repo (run `ScrypathOps.Migration` once) and are imported and exported as **v1 saved-search JSON** from Manage saved searches. A saved search the form can show (one query and a page size) fills the form and runs like any search. One with more options (different queries per schema, filters, sort or facets) runs exactly as saved and lists the inputs it used. See the [file format](saved-search-schema-v1.md) and [storage setup](team-saved-search-persistence.md).

## Further help

- [Sync modes and visibility](../../guides/sync-modes-and-visibility.md)
- [Failure recovery](../../guides/drift-recovery.md)
- [Meilisearch operations](../../guides/meilisearch-operations.md)
- [Operator Mix tasks](../../guides/operator-mix-tasks.md)
- [Multi-index search](../../guides/multi-index-search.md)

The hidden navigation contract is checked against `ScrypathOpsWeb.Nav.primary/0`.

<!-- scrypath:nav-contract-begin -->
<!--
[{"route":"/ops/search","label":"Search"},{"route":"/ops/health","label":"Search health"},{"route":"/ops/failed-sync","label":"Failed sync work"},{"route":"/ops/sync-and-index","label":"Sync and index"},{"route":"/ops/help","label":"Help"}]
-->
<!-- scrypath:nav-contract-end -->

## Security boundary

Authentication and authorization for the mounted operator routes belong to the host application. ScrypathOps provides the Phoenix and LiveView interface and documents its boot-time guard in [Security](SECURITY.md); it does not replace the host's identity layer.

Place the routes inside a `live_session` whose `on_mount` hooks enforce the host's session or token policy, or authenticate and terminate TLS at a trusted edge before requests reach Phoenix. See Phoenix [`live_session/3`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html#live_session/3) and [`on_mount`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#module-on_mount).

The optional `scrypath_ops` application is maintained in this repository and is not part of the published `scrypath` Hex package. This guide therefore links to its rendered repository documentation; the core library API and adoption guides are published separately through HexDocs.
