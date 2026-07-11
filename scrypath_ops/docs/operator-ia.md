# Operator information architecture

Canonical contract for the optional **ScrypathOps** Phoenix shell: who uses it, what jobs they bring, and how primary navigation maps to routes and follow-up docs or Mix tasks.

## Personas

- **On-call engineer** — owns incident response when search indexing or sync pipelines misbehave; needs fast triage signals and safe recovery hooks.
- **Library maintainer** — ships Scrypath releases, runs verification tasks, and keeps Hex packaging and docs honest with runtime behavior.
- **Search owner** — accountable for relevance, federation semantics, and operational posture across environments without pretending indexes are magically unified.
- **First-run operator** — arrives with the console freshly mounted (an `unconfigured` or `missing_backend` verdict) and asks "why is everything empty / what is this?"; needs orientation and a setup-oriented next step, not a diagnostic one. The Control Room verdict + intent cards are their onboarding (no separate tour); config-empty states carry the guidance to wire schemas/backend, and the first green verdict is their success signal.

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

The `/ops` root (`/ops/`) is the **Control Room** landing: a glanceable fleet-posture strip plus three intent task-cards that route by the job the operator brought — incident triage (→ `/ops/posture`), shipping a change (→ `/ops/sync-drift`), or explore & capture (→ `/ops/search`). It is the start page, not a sixth nav item; the deep per-schema posture table stays on `/ops/posture`.

Primary shell navigation under `/ops` is grouped by the job the operator brought, in **recover-first order**: the **Recover** chain comes first (posture → failed sync → read-only sync/drift, ordered as the incident walk), then **Explore** (bounded search and federation honesty → saved playbooks). Search is **not** co-equal with recovery work — Explore stays below the Recover chain.

### Journey loops & handoffs

The surfaces thread into two task groups — **Recover** (posture → failed sync → sync drift) and **Explore** (search → playbooks) — and three named loops, each a hub-and-spoke trip from the Control Room. Within a group the steps are sequential; the primary shell nav stays free so a power user is never trapped.

- **Incident-response loop** (on-call): Control Room verdict (degraded) → Posture (which schemas?) → Failed Sync (why? retry) → Sync Drift (did it stick?) → Control Room (verdict green). The loop closes on the verdict flipping green — that round-trip is the success signal.
- **Ship-a-change preflight loop** (search owner / maintainer): Control Room ("shipping a change") → Sync Drift preflight (reconcile → contract drift → mismatches → gated promote) → re-check Posture.
- **Explore → capture loop** (search owner): Control Room ("explore") → Search (probe) → capture → Playbooks (save/run) → back to Search.

Two shared components carry this structure so it stays consistent (principle of least surprise):

- **`ops_trail`** — a contextual breadcrumb (`Control Room › <group> › <page>`), not a map of the whole product. Siblings live in the primary shell nav; the landing shows no trail.
- **`ops_handoff`** — the unified "Next step" page footer. One eyebrow + imperative grammar on every triage/explore surface so the bottom of each page reliably tells the operator where to go next, and the loops visibly close.

| Job | Primary persona | Nav label | Route | Scrypath / doc / Mix follow-up |
| --- | --- | --- | --- | --- |
| 1 | On-call engineer | Posture | /ops/posture | Phase 45 — posture dashboards; until then see [guides/meilisearch-operations.md](../../guides/meilisearch-operations.md) |
| 2 | On-call engineer | Failed Sync | /ops/failed-sync | Phase 45 — failed work UI; today use `mix scrypath.failed` from [guides/operator-mix-tasks.md](../../guides/operator-mix-tasks.md) |
| 3 | Search owner | Sync Drift | /ops/sync-drift | Shipped **phase 45** — read-only reconcile + lazy index contract drift in OPSUI; still use `mix scrypath.status`, [guides/drift-recovery.md](../../guides/drift-recovery.md), [guides/sync-modes-and-visibility.md](../../guides/sync-modes-and-visibility.md) |
| 4 | Search owner | Search | /ops/search | Shipped in phase 46 — bounded single/multi playground with federation-honest inspector; semantics in [guides/multi-index-search.md](../../guides/multi-index-search.md) |
| 4b | Search owner | Playbooks | /ops/playbooks | JSON format and caps in [playbook-schema-v1.md](playbook-schema-v1.md); persistence and workspace authority in [team-playbook-persistence.md](team-playbook-persistence.md); runs use the same `SearchPlayground` dispatch path as `/ops/search` |
<!-- scrypath:nav-contract-begin -->
[{"route":"/ops/posture","label":"Posture"},{"route":"/ops/failed-sync","label":"Failed Sync"},{"route":"/ops/sync-drift","label":"Sync Drift"},{"route":"/ops/search","label":"Search"},{"route":"/ops/playbooks","label":"Playbooks"}]
<!-- scrypath:nav-contract-end -->
| 5 | Library maintainer | Sync Drift | /ops/sync-drift | Mix tasks index: [guides/operator-mix-tasks.md](../../guides/operator-mix-tasks.md) |
| 6 | Library maintainer | Posture | /ops/posture | Library verification: [CONTRIBUTING.md](../../CONTRIBUTING.md) |
| 7 | On-call engineer | Failed Sync | /ops/failed-sync | SRE-style expectations: [docs/search-backend-sre.md](../../docs/search-backend-sre.md) |
