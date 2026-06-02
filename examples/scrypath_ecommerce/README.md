# Scrypath E-commerce Demo

This Phoenix app is the click-around Scrypath showcase: a realistic multi-tenant
catalog, live Meilisearch, Postgres, browser E2E coverage, and the optional
operator UI mounted inside the host app.

**Start here:** run `docker compose up --build`, open `http://localhost:4002`,
search for `quantum`, then visit `/admin/search/posture`. You will see the
same Scrypath ideas from the guides in one place: tenant-scoped search,
category facets, related-data propagation, failed sync triage, and
zero-downtime swap posture.

**Iterating on UI:** after the first image build, use
`docker compose -f compose.yaml -f compose.dev.yaml up` for a bind-mounted dev
container. Source changes under the repository checkout are visible to Phoenix
without rebuilding dependency layers.

The demo host layout loads the ScrypathOps stylesheet only for `/admin/search/*`,
and its app JavaScript handles the operator theme and diagnostics-copy events.
That keeps mounted admin UI iteration fast without bundling a second LiveSocket.

This is a demo and proof surface, not a production starter kit. It shows how
the pieces fit together in a believable Phoenix app while keeping the canonical
API and operational semantics in the main guides.

## What this demonstrates

- A storefront-style LiveView that calls Scrypath through a Phoenix context
  boundary instead of treating search as controller glue.
- Tenant-scoped product search where user filters and facets do not replace
  the tenant guard.
- Category facets with realistic names, inventory, variants, and price ranges
  so the UI feels closer to a working SaaS/catalog screen than a toy fixture.
- Related-data propagation: category changes can update indexed product
  documents, which is the shape real apps need when associated records appear
  in search results.
- The optional Scrypath operator UI mounted by the host app under
  `/admin/search/*`, including posture, failed sync work, and the search
  playground.
- Browser E2E coverage that exercises the storefront and operator surfaces
  against real Postgres and real Meilisearch.

It does not prove production readiness for your app, replace the canonical
guides, or promote the advisory `phase105-e2e` lane into a required merge gate.
It is a high-signal shift-left proof before outside-adopter evidence exists.

## Quickstart (Makefile)

A `Makefile` wraps the common flows. Run `make help` to list targets.

```sh
make dev          # primary loop: host dev server + dockerized Meilisearch + ops-CSS watcher
make up           # full containerized test stack (what Playwright/CI use)
make screenshots  # capture admin-UI screenshots against the running dev server
make reset        # stop and delete volumes (clean DB + Meilisearch)
```

`make dev` runs the app in `MIX_ENV=dev` so **seeded data is visible in the browser**
(the `MIX_ENV=test` stack uses an Ecto sandbox pool that hides data from a plain browser —
that path is for the automated Playwright suite, not click-through). It expects a Postgres
reachable at `PGHOST` (default `localhost`); if you don't run Postgres natively, use
`make infra-pg` and `make dev PGHOST=127.0.0.1`.

### Running several demos at once (host-port lanes)

Host ports are parameterized via `.env` (see `.env.example`). To run this demo beside
other library demos without collisions, copy `.env.example` to `.env` and bump the lane:

```sh
WEB_PORT=4012 PG_PORT=5442 MEILI_PORT=7710   # example: a second demo's lane
```

The Compose project is namespaced (`name: scrypath_ecommerce`), so its network, volumes,
and containers never clash with sibling stacks. Infra ports are only published by the dev
override; the base stack keeps Postgres/Meilisearch inside the Compose network.

## Run it with Docker Compose

Prerequisites:

- Docker with Compose v2
- Port `4002` (or your `WEB_PORT` lane) available on your machine

From this directory:

```sh
docker compose up --build
```

The first boot compiles the Phoenix apps, prepares Meilisearch index settings,
seeds the demo catalog, and starts the server. A successful boot prints:

```sh
Scrypath e-commerce demo seeded.
Open the storefront at / and OPSUI at /admin/search/posture.
```

Then open:

| Route | What to look for |
| ----- | ---------------- |
| http://localhost:4002 | Tenant-scoped storefront search with category facets and realistic product cards. |
| http://localhost:4002/admin/search/posture | Operator posture for schema/index visibility and swap readiness. |
| http://localhost:4002/admin/search/failed-sync | Failed sync triage without exposing raw backend payloads. |
| http://localhost:4002/admin/search/search | Bounded search playground for operator inspection. |

Reset the demo:

```sh
docker compose down -v
```

The reset removes the Postgres and Meilisearch volumes for this demo stack.

For faster UI iteration after the first build:

```sh
docker compose -f compose.yaml -f compose.dev.yaml up
```

Use the same reset command when you want to clear data. If dependency manifests
change, rebuild once with `docker compose build web`.

## Guided click-through

1. Start on the storefront and search for `quantum`, `audio`, or `nebula`.
   Switch tenants to see how tenant scope changes the visible catalog.
2. Use the category facets. The facet labels are human catalog names, while
   Scrypath still sends precise filter values to Meilisearch.
3. Open the operator posture page. This is the maintainer view of search
   posture: schemas, queue/backend signals, and prepared index workflow.
4. Open failed sync work. The page is intentionally operational: enough context
   to triage, without making raw backend payloads the primary interface.
5. Open the search playground when you want to inspect a bounded operator search
   path rather than the consumer storefront.

## Seed story

The demo seeds three tenants so different search states are visible without
manual setup:

- **Nova Outfitters** is the main showcase tenant with smartphones, laptops,
  audio, cameras, and accessories. It is useful for faceting, metadata density,
  and visual inspection.
- **Ops Incident Lab** carries deterministic E2E fixtures. It keeps browser
  tests stable while still exercising the same app path.
- **Quiet Branch Supply** is intentionally sparse. It makes empty and
  low-volume states easier to inspect.

The seeds favor realistic shape over exhaustive commerce modeling. Products
have categories, variants, prices, and inventory because those are the fields
that stress common search UI decisions: filtering, summary metadata, and
operator confidence.

## How this maps to Scrypath

- For the first-hour API path, read the
  [golden path](../../guides/golden-path.md).
- For tenant-safe search and fixed scopes, read
  [multitenancy](../../guides/multitenancy.md) and
  [composing real-app search](../../guides/composing-real-app-search.md).
- For browser params and thin LiveView/controller boundaries, read
  [request-edge search](../../guides/request-edge-search.md).
- For associated data, fan-out, backfill, and reindex decisions, read
  [related data and reindexing](../../guides/related-data-and-reindexing.md).
- For sync mode honesty, failed work, and operator wording, read
  [sync modes and visibility](../../guides/sync-modes-and-visibility.md).

This README stays focused on running and understanding the demo. The guides are
the source of truth for public API semantics.

## Local development

If you already have Postgres and Meilisearch running locally:

```sh
mix deps.get
mix e2e.prepare
mix scrypath.demo.seed
MIX_ENV=test PHX_SERVER=true mix phx.server
```

Use the same URLs listed above after Phoenix starts.

## Verification

The browser E2E lane remains:

```sh
npm ci
npm run test:e2e
```

For visual debugging while the demo is running:

```sh
npm run test:e2e:headed
```

For an isolated in-container ExUnit run against the Compose services:

```sh
docker compose exec -e PHX_SERVER=false -e MIX_TEST_PARTITION=verify web sh -lc \
  'mix ecto.create --quiet && mix ecto.migrate --quiet && mix test'
```

The repository's `phase105-e2e` workflow is advisory today. It exists to keep
the full browser/operator proof visible while maintainers watch runtime and
flake behavior. See the root contributing guide for the CI lane details and
promotion criteria.
