# Operator information architecture

Canonical contract for the optional **ScrypathOps** Phoenix shell: who uses it, what jobs they bring, and how primary navigation maps to routes and follow-up docs or Mix tasks.

## Personas

- **On-call engineer** — owns incident response when search indexing or sync pipelines misbehave; needs fast triage signals and safe recovery hooks.
- **Library maintainer** — ships Scrypath releases, runs verification tasks, and keeps Hex packaging and docs honest with runtime behavior.
- **Search owner** — accountable for relevance, federation semantics, and operational posture across environments without pretending indexes are magically unified.

## Jobs-to-be-done

1. **When** an alert fires that search or sync looks unhealthy, **I need** a single place to see posture and health signals, **so that** I can decide whether to page deeper or recover — **done when** I can tell “healthy / degraded / broken” with explicit next checks (ships fully in phase 45).
2. **When** sync jobs fail or retry, **I need** a bounded list of failed work with reasons, **so that** I can retry or quarantine safely — **done when** I can open failed-work detail from the same nav priority as posture (ships fully in phase 45).
3. **When** someone asks “is the index in sync?”, **I need** read-only drift and visibility plus links to existing Mix tasks and guides, **so that** I never bypass the library’s public APIs — **done when** I can jump to `mix scrypath.*` docs and drift guides without duplicate prose here (shipped phase 45 — see `/ops/sync-drift` and **`phase 45`** in the nav table below).
4. **When** we expose multi-index or federated search, **I need** the UI to state merge and honesty rules up front, **so that** operators do not assume a single merged index — **done when** the shell links to federation docs and phase-46 inspectors (ships fully in phase 46).
5. **When** I need a quick CLI snapshot during an incident, **I need** the same priorities reflected in nav as in terminal workflows, **so that** muscle memory matches between OPSUI and Mix — **done when** primary nav order matches jobs 1–4 above.
6. **When** onboarding a teammate to operator workflows, **I need** a short mapping from job to route and docs, **so that** they self-serve without reading the whole repo — **done when** this table is kept in sync with `router.ex` on every nav change.
7. **When** planning roadmap work, **I need** triage (posture + failed sync) ranked above exploratory search, **so that** the product does not imply search debugging is co-equal with outage response — **done when** nav order stays posture → failed sync → sync/drift → search.
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

Primary chrome under `/ops` follows **roadmap triage order**: posture first, failed sync second, read-only sync/drift (with doc and Mix links) third, bounded search and federation honesty last (search **not** co-equal with triage).

| Job | Primary persona | Top nav label | Route | Scrypath / doc / Mix follow-up |
| --- | --- | --- | --- | --- |
| 1 | On-call engineer | Posture / health | /ops/posture | Phase 45 — posture dashboards; until then see [guides/meilisearch-operations.md](../../guides/meilisearch-operations.md) |
| 2 | On-call engineer | Failed sync work | /ops/failed-sync | Phase 45 — failed work UI; today use `mix scrypath.failed` from [guides/operator-mix-tasks.md](../../guides/operator-mix-tasks.md) |
| 3 | Search owner | Sync / drift | /ops/sync-drift | Shipped **phase 45** — read-only reconcile + lazy index contract drift in OPSUI; still use `mix scrypath.status`, [guides/drift-recovery.md](../../guides/drift-recovery.md), [guides/sync-modes-and-visibility.md](../../guides/sync-modes-and-visibility.md) |
| 4 | Search owner | Search & federation | /ops/search | Shipped in phase 46 — bounded single/multi playground with federation-honest inspector; semantics in [guides/multi-index-search.md](../../guides/multi-index-search.md) |
| 4b | Search owner | Saved playbooks | /ops/playbooks | JSON format and caps in [playbook-schema-v1.md](playbook-schema-v1.md); persistence and workspace authority in [team-playbook-persistence.md](team-playbook-persistence.md); runs use the same `SearchPlayground` dispatch path as `/ops/search` |
<!-- scrypath:nav-contract-begin -->
[{"route":"/ops/posture","label":"Posture / health"},{"route":"/ops/failed-sync","label":"Failed sync work"},{"route":"/ops/sync-drift","label":"Sync / drift"},{"route":"/ops/search","label":"Search & federation"},{"route":"/ops/playbooks","label":"Saved playbooks"}]
<!-- scrypath:nav-contract-end -->
| 5 | Library maintainer | Sync / drift | /ops/sync-drift | Mix tasks index: [guides/operator-mix-tasks.md](../../guides/operator-mix-tasks.md) |
| 6 | Library maintainer | Posture / health | /ops/posture | Library verification: [CONTRIBUTING.md](../../CONTRIBUTING.md) |
| 7 | On-call engineer | Failed sync work | /ops/failed-sync | SRE-style expectations: [docs/search-backend-sre.md](../../docs/search-backend-sre.md) |
