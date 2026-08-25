# Scrypath E-commerce Demo

This Phoenix app is the click-around Scrypath showcase: a realistic multi-tenant
catalog, live Meilisearch, Postgres, browser E2E coverage, and the optional
operator UI mounted inside the host app.

**Start here:** run `make docker-dev`, open the URL block it prints, search for
`quantum`, then visit `/admin/search/posture`. You will see the same Scrypath
ideas from the guides in one place: tenant-scoped search, category facets,
related-data propagation, failed sync triage, and zero-downtime swap posture.

**Iterating on UI:** `make docker-dev` runs the app in Docker with the repository
bind-mounted and named `deps` / `_build` volumes. HEEx, CSS, and LiveView edits
reload without rebuilding dependency layers. If you already keep Elixir/OTP
installed locally, `make dev` keeps Phoenix on the host and uses Docker only for
Meilisearch by default.

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
make docker-dev  # Docker-only dev loop: Postgres + Meilisearch + Phoenix + ops CSS watcher
make urls        # print storefront, operator routes, and current port lane
make doctor      # check Docker Compose and common host-port conflicts
make dev         # host Phoenix loop + Dockerized Meilisearch
make up          # containerized test stack, matching the Playwright/CI shape
make verify-mounted # zero-touch required mounted integration/browser proof
make verify-e2e    # zero-touch full advisory browser/visual proof
make reset       # stop containers and delete this demo's volumes
```

`make verify-mounted` is the shortest trustworthy proof for the mounted host:
it builds the exact checkout, prepares Postgres and Meilisearch, builds both
asset bundles, runs the focused Playwright routing/operator specs, saves
diagnostics under `test-results/docker-focused/`, and tears everything down.
It requires only Docker Compose and publishes no host ports. `make verify-e2e`
uses the same isolated lifecycle for the complete advisory browser and
deterministic visual lane, with output under `test-results/docker-full/`.

Both commands use unique Compose project names, so parallel worktrees and
already-running services do not collide. Set `KEEP_E2E_STACK=1` only when you
want a failed verifier stack left running for investigation.

Use `make docker-dev` for the hands-off browser loop. It runs `MIX_ENV=dev`, so
**seeded data is visible in the browser**. The default Docker dev stack publishes
only the web UI on `WEB_PORT`; Postgres and Meilisearch stay inside the Compose
network so they do not collide with other projects on `5432` or `7700`.

Use `make dev` when you want Phoenix running directly on your machine. It expects
Postgres at `PGHOST` (default `localhost`) and starts Meilisearch in Docker on
`MEILI_PORT`. If you do not run Postgres natively, start it with Docker too:

```sh
make infra-pg
make dev PGHOST=127.0.0.1
```

Use `make up` for the image-only `MIX_ENV=test` stack that Playwright and CI use.
That path is for automated proof, not the nicest click-through loop.

### Running several demos at once (host-port lanes)

Host ports are parameterized via `.env` (see `.env.example`). To run this demo
beside other library demos, copy `.env.example` to `.env` and bump the lane:

```sh
WEB_PORT=4012 PG_PORT=5442 MEILI_PORT=7710   # example: a second demo's lane
```

For `make docker-dev`, only `WEB_PORT` is published. `PG_PORT` and `MEILI_PORT`
matter only for host-tooling flows such as `make dev`, `make infra`, and
`make infra-pg`.

The Compose project is namespaced (`COMPOSE_PROJECT_NAME`, default
`scrypath_ecommerce`), so its network, volumes, and containers do not clash with
sibling stacks. Use a different `COMPOSE_PROJECT_NAME` when running two worktrees
of this same demo at once.

## Run it with Docker Compose

Prerequisites:

- Docker with Compose v2
- Port `4002` (or your `WEB_PORT` lane) available on your machine

From this directory:

```sh
make docker-dev
```

The first boot compiles the Phoenix apps, prepares Meilisearch index settings,
seeds the demo catalog, and starts the server. A successful boot prints the full
route list:

```sh
Scrypath e-commerce demo is ready.
  Storefront        http://127.0.0.1:4002
  Control room      http://127.0.0.1:4002/admin/search
  Posture           http://127.0.0.1:4002/admin/search/posture
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
make reset
```

The reset clears this demo's containers, generated build/dependency volumes, and
demo data.

The raw Compose equivalent for Docker dev is:

```sh
docker compose -f compose.yaml -f compose.dev.yaml up
```

Add `-f compose.host-ports.yaml` only when host tools need direct Postgres or
Meilisearch access. If dependency manifests change, rebuild once with
`docker compose build web`. For the longer maintainer runbook, see
[`docs/local-demo-docker-dx.md`](docs/local-demo-docker-dx.md).

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

The canonical no-UAT local/CI proof is:

```sh
make verify-mounted
```

For the broader advisory lane:

```sh
make verify-e2e
```

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
