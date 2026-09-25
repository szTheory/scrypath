# Local Demo Docker DX

This runbook is for maintainers running Scrypath's Phoenix demo beside other
Elixir/Phoenix library demos on the same machine.

## Gameplan

- Use `make docker-dev` when you want the hands-off Docker loop.
- Use `make dev` when you want Phoenix on the host and Docker only for services.
- Use `make up` when you want the image-only test stack used by Playwright/CI.
- Run `make doctor` before starting a stack if ports have been noisy.
- Bump `.env` lanes only when a published host port collides.

## The Three Loops

| Goal | Command | What Runs Where |
| ---- | ------- | --------------- |
| Click around or edit UI without local Postgres/Meilisearch | `make docker-dev` | Postgres, Meilisearch, Phoenix, and the ops CSS watcher all run in Docker. |
| Fast local Phoenix loop with host BEAM tooling | `make dev` | Phoenix runs on the host; Meilisearch runs in Docker; Postgres defaults to host. |
| CI-shaped browser proof | `make up` | Image-only `MIX_ENV=test` stack matching Playwright expectations. |

`make docker-dev` is the default human path. It bind-mounts the checkout and
stores generated `deps` / `_build` directories in Docker volumes, so HEEx, CSS,
and LiveView edits do not rebuild dependency layers.

## Ports

The default Docker dev stack publishes only the web UI:

```text
WEB_PORT=4002
```

Postgres and Meilisearch stay private to the Compose network. That removes the
usual `5432` / `7700` collision class when several demos run at once.

Host-tooling flows add `compose.host-ports.yaml` and publish:

```text
PG_PORT=5432
MEILI_PORT=7700
```

Use those only when a host tool needs direct access, such as `psql`, TablePlus,
or a host-run Phoenix server.

## Conflict Checklist

Run:

```sh
cd examples/scrypath_ecommerce
make doctor
```

If a port is busy, copy `.env.example` to `.env` and bump the lane:

```sh
WEB_PORT=4012
PG_PORT=5442
MEILI_PORT=7710
```

For `make docker-dev`, `WEB_PORT` is the only port that normally matters.
`PG_PORT` and `MEILI_PORT` matter only for `make dev`, `make infra`, and
`make infra-pg`.

If two worktrees of this same demo are running at once, also set a distinct
Compose project name:

```sh
COMPOSE_PROJECT_NAME=scrypath_ecommerce_feature_x
```

## Rebuild vs Reset

Use the cheapest fix that matches the problem:

| Symptom | Command |
| ------- | ------- |
| CSS, HEEx, or LiveView edit not visible | Wait for reload, or restart `make docker-dev`. |
| `mix.lock` / `package-lock.json` / Dockerfile changed | `docker compose build web` |
| Database or Meilisearch state is wrong | `make reset`, then start again. |
| Named build/deps volumes feel stale | `make reset`, then `make docker-dev`. |

`make reset` deletes this demo's Compose volumes. It is intentionally heavier
than a restart because it clears generated build/dependency state as well as
demo data.

## URL Cheat Sheet

Run `make urls` any time:

```text
Storefront        http://127.0.0.1:${WEB_PORT}
Control room      http://127.0.0.1:${WEB_PORT}/admin/search
Posture           http://127.0.0.1:${WEB_PORT}/admin/search/posture
Failed sync       http://127.0.0.1:${WEB_PORT}/admin/search/failed-sync
Sync / drift      http://127.0.0.1:${WEB_PORT}/admin/search/sync-drift
Search playground http://127.0.0.1:${WEB_PORT}/admin/search/search
Playbooks         http://127.0.0.1:${WEB_PORT}/admin/search/playbooks
```

## Future Proxy Layer

The current default is explicit loopback ports because it is simple and works
without a global dependency. A queued Docker DX milestone already sketches the
next step: one shared Traefik ingress on `*.localhost` so several demos can use
stable names instead of port lanes.

Reach for that proxy layer when there are enough concurrent HTTP demos that
port lanes become bookkeeping again. Keep direct Postgres/Meilisearch host
ports as explicit debug-only overlays even then.
