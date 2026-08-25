---
phase_id: dx-1.1
phase_name: "Shared Traefik proxy + scrypath ingress (core)"
milestone: dx-1
status: spec
created: 2026-06-04
requirements: [DXPROXY-01, DXINGRESS-01, DXORIGIN-01, DXURLS-01]
ambiguity: low   # research-grounded; concrete snippets below
---

# SPEC — Phase dx-1.1: Shared Traefik proxy + scrypath ingress

## What this phase delivers (WHAT, not HOW-in-detail)

A working shared Traefik ingress that lets `scrypath_ecommerce` be reached at
`http://scrypath.localhost/` (storefront) and `http://scrypath.localhost/admin/search`
(ops UI) with **no host port chosen for `web`**, while the legacy `:4002` lane keeps working.
LiveView must connect behind the proxy. `make proxy`/`make up`/`make urls` make it one-command,
self-documenting. Strictly additive — base `compose.yaml` is untouched except the `name:`
parameterization.

## Concrete deliverables

### 1. `examples/_proxy/compose.yaml` (DXPROXY-01) — committed, shared
```yaml
name: devproxy
services:
  traefik:
    image: traefik:v3.6
    command:
      - --providers.docker
      - --providers.docker.exposedbydefault=false   # opt-in only
      - --entrypoints.web.address=:80
      - --api.dashboard=true
    ports:
      - "80:80"
      - "127.0.0.1:8080:8080"   # dashboard, loopback only
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks: [devproxy]
networks:
  devproxy:
    external: true   # created once: docker network create devproxy
```
(No `:443`/TLS — plain HTTP per locked decision. `:443` line omitted vs research sketch.)

### 2. `examples/scrypath_ecommerce/compose.proxy.yaml` (DXINGRESS-01) — additive overlay
```yaml
services:
  web:
    labels:
      - traefik.enable=true
      - traefik.docker.network=devproxy                                  # mandatory: web is on 2 nets
      - traefik.http.routers.scrypath.rule=Host(`scrypath.localhost`)    # router name globally unique
      - traefik.http.services.scrypath.loadbalancer.server.port=4002
    networks: [default, devproxy]
networks:
  devproxy:
    external: true
```
- Base `compose.yaml`: change `name: scrypath_ecommerce` → `name: ${COMPOSE_PROJECT_NAME:-scrypath_ecommerce}` (worktree safety). Keep the `:4002` host mapping (both proxy + lane work).

### 3. Phoenix host acceptance (DXORIGIN-01)
- In `config/dev.exs` (and `config/test.exs` if proxied there), add `scrypath.localhost` to the
  endpoint `check_origin` allow-list (dev/test only), covering the LiveView socket origin check.
  Without this LiveView refuses the socket behind the proxy — the project's known failure mode
  (see memory `phase105-e2e-harness-gap`: assets/host → LiveView won't connect).
- Verify the LiveView websocket actually connects at `scrypath.localhost`, not just that HTML loads.

### 4. Makefile ergonomics (DXURLS-01)
- `make proxy` → `docker network create devproxy 2>/dev/null || true` then
  `docker compose -f ../_proxy/compose.yaml up -d`.
- `COMPOSE := docker compose -f compose.yaml -f compose.proxy.yaml` (so `up` joins the overlay).
- `make urls` → echo block (no new deps): storefront, admin/ops UI, Meili, Postgres DSN, Traefik
  dashboard, both proxy + `:WEB_PORT` lane, Safari caveat, multi-demo tip. Call at the tail of
  `up:` and `dev:`. (Implementation sketch in research §6.)

## Ambiguities / resolutions
- **Drop the `:4002` host port for proxy-only?** → NO. Keep both (Safari + Playwright pinned at
  `127.0.0.1:4002` + raw host tooling). Proxy is additive.
- **Where does `make up` reference the proxy compose?** → relative `../_proxy/compose.yaml`.
- **Router/service name?** → `scrypath` (globally unique across all sibling demos; must not reuse
  `web`).
- **Dashboard exposure?** → loopback `127.0.0.1:8080` only.

## Verification (automatable, no human UAT)
1. `make proxy` → `devproxy` network exists, Traefik container up, `:80` bound once.
2. `make up` → `curl -H 'Host: scrypath.localhost' http://127.0.0.1/admin/search` returns 200
   (or `curl http://scrypath.localhost/admin/search`).
3. LiveView connect proof: Playwright/`waitForLiveConnected` against `http://scrypath.localhost/admin/search`
   succeeds (reuse the existing e2e helper) — guards DXORIGIN-01.
4. `curl http://127.0.0.1:4002/admin/search` still 200 (lane parity).
5. `make urls` prints the route block.
6. Existing contrast/screenshot suites unaffected (they pin `:4002`).

## Footguns to honor (from research §3)
- `traefik.docker.network` is mandatory (web on `default`+`devproxy`) or Traefik picks the wrong IP.
- Router names globally unique across all projects.
- `*.localhost` works in Chrome/Firefox/curl, NOT Safari.
- Docker socket mount = root-equiv daemon access (acceptable on dev laptop; noted).
