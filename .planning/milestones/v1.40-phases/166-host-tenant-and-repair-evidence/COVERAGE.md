# API Coverage — Existing Meilisearch Consumer and Repair Proof

The scope detector returned detected=true. This phase exercises the existing integration; it adds no external API wrapper or public library capability. The matrix inventories the complete existing Scrypath.Meilisearch.Client capability surface, plus fixture/service lifecycle operations and explicitly excluded backend capability families. INTEGRATE means exercise for the selected proof, not introduce a new API.

| capability | decision | reason |
|---|---|---|
| create_index | INTEGRATE | Existing isolated fixture preparation only. |
| update_settings / apply declared settings | INTEGRATE | Tenant/status/category filterability is required by the named host workflow; await the actual task. |
| get_settings | INTEGRATE | Read back the configured subset needed by the host scenario. |
| upsert_documents via public sync/backfill | INTEGRATE | Establish fixtures and submit the explicitly selected repair. |
| delete_documents | INTEGRATE | Induce the known root missing-document fixture; the separate C-09 user claim reuses its historical receipt conditionally. |
| task | INTEGRATE | Poll every returned setup/repair UID and assert terminal success and expected index. |
| tasks | INTEGRATE | Observe the no-action report and complete no-write task snapshots. |
| search | INTEGRATE | Public host and root raw-ID/value/count/facet oracles. |
| facet_search | INTEGRATE | Exact public tenant-plus-keyword-status follow-up in the same path/package scenario. |
| multi_search / native federation | OPT-OUT | No selected cross-schema user job; D-07 prohibits a broader package matrix. Existing Phase 165 contracts retain their own limits. |
| swap_indexes | OPT-OUT | Fixed live-index manual repair does not rebuild or cut over; D-08–D-10 exclude broader reindex proof. |
| delete isolated fixture index | INTEGRATE | Owned cleanup only; not a user deletion or admin-operation guarantee. |
| health / version / service identity | INTEGRATE | Existing service prerequisite and recorded tuple; no new recurring lane. |
| document browse / GET / partial update / filtered delete / clear-all | OPT-OUT | The accepted outcome is through the same public raw search and selected-ID upsert; broad document endpoint coverage is outside the approved workflow. |
| index listing / index metadata updates / index statistics / global statistics | OPT-OUT | No new index administration or monitoring claim; the fixture uses its known index identity. |
| individual settings endpoints / settings reset / settings drift remediation | OPT-OUT | Only the configured subset and existing apply/readback path are required; no settings matrix or new drift engine. |
| task cancellation / task deletion / batch administration | OPT-OUT | Existing task polling suffices; no cancellation, retention or administrative workflow is selected. |
| API-key administration / tenant token construction | OPT-OUT | Host authentication and browser-direct credential architecture are outside D-02/D-03 and the current server-side proof. |
| dumps / snapshots / backend export and restore | OPT-OUT | The selected source-backed document repair is not backup or disaster-recovery evidence. |
| vector / hybrid / semantic / experimental backend capabilities | OPT-OUT | Explicit project scope guard; no public API category or backend/version broadening. |

The existing Postgres and SQLite integrations are reused as Ecto source fixtures. No external auth service, package publication integration, new dependency installation or service is introduced. The existing Phoenix advisory job runs both dependency modes; its scenario must pass at the recorded source but its merge-gate classification stays advisory. C-09 reuse is source-based and does not add a package-delete row or imply one.

All opt-outs follow the approved requirements and D-01–D-11 boundaries. This matrix is a scope record, not execution evidence.
