# ScrypathOps operator guide

ScrypathOps is an optional Phoenix and LiveView interface for inspecting search indexing and sync operations. It complements the library's `Scrypath.*` APIs and Mix tasks; it does not replace them or provide host-application authentication.

## Personas

- **On-call engineers** need to see current search health, inspect failed work, and choose a safe recovery action.
- **Search owners** need to understand index contract and document visibility, then run bounded searches without implying that separate indexes form one merged index.
- **Library maintainers** need reproducible status, verification commands, and documentation that matches the code.
- **First-run operators** need to distinguish missing setup from an empty catalog or a failed observation, with a clear next step.

## Jobs-to-be-done

The shared path is **observe → diagnose → recover or explore → verify**. An accepted job or a clean settings contract does not prove that documents are visible in the active index. Preserve that distinction when reading status and recovery results.

## Navigation

The default mount prefix is `/ops`; host applications may mount the interface at another path. Routes below show the default prefix. The Control Room at `/ops/` is the landing page and is not a primary navigation item. The retired `/ops/posture` route redirects to `/ops/health` for saved links.

| Group | Destination | Route | Use and next reference |
| --- | --- | --- | --- |
| Home | Control Room | `/ops/` | Read the current summary, then follow the task-specific health, verification, or search handoff. |
| Recover | Search health | `/ops/health` | Inspect per-schema backend and queue observations. See [Meilisearch operations](../../guides/meilisearch-operations.md). |
| Recover | Failed sync work | `/ops/failed-sync` | Inspect retained failure evidence before retrying or quarantining work. See [operator Mix tasks](../../guides/operator-mix-tasks.md). |
| Recover | Sync and drift | `/ops/sync-drift` | Reconcile accepted work, inspect index-contract drift, then verify active-index visibility. See [drift recovery](../../guides/drift-recovery.md) and [sync modes and visibility](../../guides/sync-modes-and-visibility.md). |
| Explore | Search | `/ops/search` | Run an allowlisted query and inspect results by their submitted target. See [multi-index search](../../guides/multi-index-search.md). |
| Explore | Playbooks | `/ops/playbooks` | Preview, run, save, and import bounded search playbooks. See the [playbook format](playbook-schema-v1.md) and [team persistence](team-playbook-persistence.md). |

The primary navigation contract below is machine-checked against `ScrypathOpsWeb.Nav.primary/0`. Its JSON is kept inside an HTML comment so it stays available to verification without appearing in the rendered guide.

<!-- scrypath:nav-contract-begin -->
<!--
[{"route":"/ops/health","label":"Search health"},{"route":"/ops/failed-sync","label":"Failed sync work"},{"route":"/ops/sync-drift","label":"Sync and drift"},{"route":"/ops/search","label":"Search"},{"route":"/ops/playbooks","label":"Playbooks"}]
-->
<!-- scrypath:nav-contract-end -->

## Handoffs

- **Incident response:** Control Room → Search health → Failed sync work → Sync and drift → Control Room. Confirm the correlated task and document observation before treating recovery as complete.
- **Change preflight:** Control Room → Sync and drift → inspect the declared contract and current document evidence → Search health. Index promotion is an advanced, confirmed action.
- **Search exploration:** Control Room → Search → capture the submitted targets and criteria → Playbooks to save or replay the bounded check.

The contextual trail identifies the current task group and page; sibling routes remain available in primary navigation. Each page's next-step handoff should direct operators to the next safe action without implying that an unobserved state is healthy.

## Security boundary

Authentication and authorization for the mounted operator routes belong to the host application. ScrypathOps provides the Phoenix and LiveView interface and documents its boot-time guard in [Security](SECURITY.md); it does not replace the host's identity layer.

Place the routes inside a `live_session` whose `on_mount` hooks enforce the host's session or token policy, or authenticate and terminate TLS at a trusted edge before requests reach Phoenix. See Phoenix [`live_session/3`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html#live_session/3) and [`on_mount`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#module-on_mount).

The optional `scrypath_ops` application is maintained in this repository and is not part of the published `scrypath` Hex package. This guide therefore links to its rendered repository documentation; the core library API and adoption guides are published separately through HexDocs.
