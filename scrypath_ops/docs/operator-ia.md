# Operator information architecture

Canonical contract for the optional **ScrypathOps** Phoenix shell: who uses it, what jobs they bring, and how primary navigation maps to routes and follow-up docs or Mix tasks.

## Personas

- **On-call engineer** — owns incident response when search indexing or sync pipelines misbehave; needs fast triage signals and safe recovery hooks.
- **Library maintainer** — ships Scrypath releases, runs verification tasks, and keeps Hex packaging and docs honest with runtime behavior.
- **Search owner** — accountable for relevance, federation semantics, and operational health across environments without pretending indexes are magically unified.
- **First-run operator** — arrives with the console freshly mounted (an `unconfigured` or `missing_backend` verdict) and asks "why is everything empty / what is this?"; needs orientation and a setup-oriented next step, not a diagnostic one. The Control Room verdict + intent cards are their onboarding (no separate tour); config-empty states carry the guidance to wire schemas/backend, and the first green verdict is their success signal.

## Jobs-to-be-done

Control Room answers “Does search sync need attention?” across every configured schema. Search health answers “Which schemas need attention, and what failed or is still pending?” with a worst-first list and expandable details. Its diagnostic next step is each schema’s recovery link, rather than generic links that default to a different schema. Neither overview has a selected schema or a schema filter. Old overview links carrying `schema` normalize to the all-schema URL. Choose a schema through its recovery link; Failed sync work and Sync and drift have actual schema selectors and scoped content. Those workflows preserve the validated selection between each other; returning to Search health restores the overall view.

1. **When** an alert fires that search or sync looks unhealthy, **I need** one place to see search health and sync signals, **so that** I can decide whether to page deeper or recover — **done when** I can tell “healthy / degraded / broken” with explicit next checks (ships fully in phase 45).
2. **When** sync jobs fail or retry, **I need** a bounded list of failed work with reasons, **so that** I can retry or quarantine safely — **done when** I can open failed-work detail from the same nav priority as health (ships fully in phase 45).
3. **When** someone asks “is the index in sync?”, **I need** read-only drift and visibility plus links to existing Mix tasks and guides, **so that** I never bypass the library’s public APIs — **done when** I can jump to `mix scrypath.*` docs and drift guides without duplicate prose here (shipped phase 45 — see `/ops/sync-drift` and **`phase 45`** in the nav table below).
4. **When** we expose multi-index or federated search, **I need** the UI to state merge and honesty rules up front, **so that** operators do not assume a single merged index — **done when** the shell links to federation docs and phase-46 inspectors (ships fully in phase 46).
5. **When** I need a quick CLI snapshot during an incident, **I need** the same priorities reflected in nav as in terminal workflows, **so that** muscle memory matches between OPSUI and Mix — **done when** primary nav order matches jobs 1–4 above.
6. **When** onboarding a teammate to operator workflows, **I need** a short mapping from job to route and docs, **so that** they self-serve without reading the whole repo — **done when** this table is kept in sync with `router.ex` on every nav change.
7. **When** planning roadmap work, **I need** triage (health + failed sync) ranked above exploratory search, **so that** the product does not imply search debugging is co-equal with outage response — **done when** nav order stays health → failed sync → sync/drift → search.
8. **When** I want to replay a bounded search or multi-index run from disk, **I need** an ops-local JSON playbook library with the same honesty and dispatch rails as the playground, **so that** I can iterate without pasting large payloads into chat — **done when** I can import, preview, and run validated playbooks under an explicit workspace directory (see `/ops/playbooks`); deploy layout and GitOps live in [team-playbook-persistence.md](team-playbook-persistence.md).

### Playbook (saved playbooks)

Version **1** interchange for saved searches is **JSON** and **ops-local** (validated beside the OPSUI code, not as a separate Hex-published schema package). Normative fields, caps, and banned secret keys are documented in [playbook-schema-v1.md](playbook-schema-v1.md).

## Securing `/ops`

Authentication and authorization for **`/ops`** are **host-owned** concerns: **`scrypath_ops`**
ships a Phoenix + LiveView shell and documents boot-time guards (for example
**`OPSUI_AUTH_MODE`** in **`docs/SECURITY.md`**), but it does **not** replace your
organization’s identity layer.

Wire the operator routes the same way you would any internal admin UI: wrap them in a
**`live_session`** with **`on_mount`** hooks that enforce your session or token rules, or
terminate TLS and authenticate at the edge before traffic reaches Phoenix. See Phoenix
**[`live_session/3`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html#live_session/3)**
and **`on_mount`** callbacks in
**[`Phoenix.LiveView`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#module-on_mount)**.

## Navigation

The former `/ops/posture` path redirects to `/ops/health` so saved links continue to work.

The `/ops` root (`/ops/`) is the **Control Room** landing: a glanceable search-health summary plus three intent task-cards that route by the job the operator brought — incident triage (→ `/ops/health`), shipping a change (→ `/ops/sync-drift`), or explore & capture (→ `/ops/search`). It is the start page, not a sixth nav item; the per-schema health view stays on `/ops/health`.

Primary shell navigation under `/ops` is grouped by the job the operator brought, in **recover-first order**: the **Recover** chain comes first (health → failed sync → read-only sync/drift, ordered as the incident walk), then **Explore** (bounded search and federation honesty → saved playbooks). Search is **not** co-equal with recovery work — Explore stays below the Recover chain.

### Journey loops & handoffs

The surfaces thread into two task groups — **Recover** (health → failed sync → sync drift) and **Explore** (search → playbooks) — and three named loops, each a hub-and-spoke trip from the Control Room. Within a group the steps are sequential; the primary shell nav stays free so a power user is never trapped.

- **Incident-response loop** (on-call): Control Room → Search health → the affected schema's next action. Failed work leads to Failed sync work; pending, clear or unavailable observations lead to Sync and drift. Verify recovery against the correlated task and active-index document observation, then return to overall health. A quiet health summary or empty failed-work list alone does not establish that recovery completed.
- **Ship-a-change preflight loop** (search owner / maintainer): Control Room ("shipping a change") → Sync and drift (refresh sync status → check index configuration) → optionally open **Advanced: index promotion** → re-check Search health.
- **Explore → capture loop** (search owner): Control Room ("explore") → Search (probe) → capture → Playbooks (save/run) → back to Search.

Two shared components carry this structure so it stays consistent (principle of least surprise):

- **`ops_trail`** — a contextual breadcrumb (`<group> › <page>`), not a map of the whole product. Siblings live in the primary shell nav; the landing shows no trail.
- **`ops_handoff`** — the "Next step" footer for a scoped workflow. Search health uses each schema’s recovery link instead of a generic footer that could open the wrong schema.

### Sync recovery and index promotion

Sync and drift keeps the ordinary recovery checks usable on their own: refresh sync and queue status, then check index configuration. A prior failed-sync event remains useful incident history and continues to block index promotion until it is resolved; it does not prevent the operator from checking whether newly accepted recovery work reached the backend and active index.

Index promotion is a separate advanced action. Its readiness and server-side guard use the same current, schema-and-index scoped checks. A confirmation names the schema, live index, target index, and alias change. Backend task acceptance is shown as **accepted** with its exact task ID; only that task's terminal success is shown as **Index swap completed**. Timeout or failure keeps the task identity visible and offers check refresh without submitting another swap.

Use **backend task** for Meilisearch work and **queue job** for Oban work. Matching **index configuration** means declared fields and settings match the live index; it does not prove that indexed documents are current. Technical APIs retain their established contract names. Recovery verification is based on the correlated task and active-index document observation described by the incident flow.

### Common-path hierarchy

Search has one Run action. Result limits live in Search options; completed results and saved-check captures identify the executed query and schemas even while the form is edited. Playbooks lead with the catalog and selected preview, identify the exact loaded file or imported input, and keep less frequent file actions under each row's named Actions disclosure. Import and workspace details remain available without competing with a loaded preview. Required errors and next actions stay visible; successful technical comparisons and file history can be disclosed. Apply the shared [operator UX rubric](../../.planning/reference/OPERATOR-UX-RUBRIC.md) when refining these paths.

| Job | Primary persona | Nav label | Route | Scrypath / doc / Mix follow-up |
| --- | --- | --- | --- | --- |
| 1 | On-call engineer | Search health | /ops/health | Phase 45 — health dashboards; until then see [guides/meilisearch-operations.md](../../guides/meilisearch-operations.md) |
| 2 | On-call engineer | Failed sync work | /ops/failed-sync | Phase 45 — failed work UI; today use `mix scrypath.failed` from [guides/operator-mix-tasks.md](../../guides/operator-mix-tasks.md) |
| 3 | Search owner | Sync and drift | /ops/sync-drift | Shipped **phase 45** — read-only reconcile + lazy index contract drift in OPSUI; still use `mix scrypath.status`, [guides/drift-recovery.md](../../guides/drift-recovery.md), [guides/sync-modes-and-visibility.md](../../guides/sync-modes-and-visibility.md) |
| 4 | Search owner | Search | /ops/search | Shipped in phase 46 — bounded single/multi playground with federation-honest inspector; semantics in [guides/multi-index-search.md](../../guides/multi-index-search.md) |
| 4b | Search owner | Playbooks | /ops/playbooks | JSON format and caps in [playbook-schema-v1.md](playbook-schema-v1.md); persistence and workspace authority in [team-playbook-persistence.md](team-playbook-persistence.md); runs use the same `SearchPlayground` dispatch path as `/ops/search` |
<!-- scrypath:nav-contract-begin -->
[{"route":"/ops/health","label":"Search health"},{"route":"/ops/failed-sync","label":"Failed sync work"},{"route":"/ops/sync-drift","label":"Sync and drift"},{"route":"/ops/search","label":"Search"},{"route":"/ops/playbooks","label":"Playbooks"}]
<!-- scrypath:nav-contract-end -->
| 5 | Library maintainer | Sync and drift | /ops/sync-drift | Mix tasks index: [guides/operator-mix-tasks.md](../../guides/operator-mix-tasks.md) |
| 6 | Library maintainer | Search health | /ops/health | Library verification: [CONTRIBUTING.md](../../CONTRIBUTING.md) |
| 7 | On-call engineer | Failed sync work | /ops/failed-sync | SRE-style expectations: [docs/search-backend-sre.md](../../docs/search-backend-sre.md) |
