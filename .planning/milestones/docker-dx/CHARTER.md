---
milestone_id: dx-1
milestone_name: "Dev Environment — Zero-Conflict Docker DX"
status: queued
created: 2026-06-04
blocks_active_milestone: false
activate_after: v1.34 (or switch anytime — this milestone is independent of dark-mode work)
source_research: .planning/research/docker-multiproject-dx-research.md
non_product: true   # dev tooling, NOT part of the v1.x product/version sequence
---

# Milestone Charter: Dev Environment — Zero-Conflict Docker DX (`dx-1`)

> **Status: QUEUED.** This is a standalone, non-product (dev-tooling) milestone. It does NOT
> displace the active v1.34 dark-mode milestone — `.planning/{PROJECT,REQUIREMENTS,ROADMAP,STATE}.md`
> remain v1.34's. Activate this when you want to work it (see **Activation** below). Spec'd and
> discussed; **stopped before build** per owner request (2026-06-04).

## Why (problem statement)

The owner runs 4–5 Elixir/Phoenix OSS library demos on one macOS machine simultaneously
(observed live: `parapet_demo`, `rulestead_demo_jon_main`, `threadline`, `scrypath_ecommerce`),
each with its own admin UI + Postgres/Meilisearch/Redis. Host-port conflicts on
`4002/5432/7700` are a recurring pain — proven live during Phase 128 execution, when port 4002
was grabbed by another lib's host server mid-run and the contrast-gate stack had to be re-homed
onto a free lane (`4012`). The current host-port "lane" convention (`.env`: `WEB_PORT`/`PG_PORT`/
`MEILI_PORT`, `+10` per demo) works but is **manual bookkeeping that scales O(projects × services)**
and yields ugly, unmemorable URLs (`:4012`, `:5442`). Goal: make multi-demo local Docker
**seamless, hands-off, collision-free, with stable memorable URLs** — great DX.

## Goal

Replace host-port URLs with a **shared Traefik reverse-proxy ingress** on a shared external
Docker network, routing by `*.localhost` hostname, with **unpublished infra** and strict
per-project compose namespacing. Each demo opts in with ~5 labels + one network line and gets a
stable URL (`http://scrypath.localhost/admin/search`). Only Traefik binds a host port — the
entire `4002/5432/7700` collision class disappears. Keep the loopback host-port lanes as a
fallback for raw-TCP host tooling (`psql`, the host `make dev` loop, Playwright pinned at `:4002`).
Strictly **additive and behavior-parity**: every demo stays runnable exactly as today.

## Locked decisions (from discuss pass, 2026-06-04)

1. **Scope** = shared proxy + opt scrypath_ecommerce **and** `examples/phoenix_meilisearch` in,
   + a documented copy-paste opt-in convention so the *other* repos (rulestead/parapet/threadline,
   separate git repos this milestone can't edit) adopt it themselves later.
2. **Hostnames** = `*.localhost` (zero-config; resolves to 127.0.0.1 in Chrome/Firefox/curl with
   no `/etc/hosts`/dnsmasq, RFC 6761). **Safari does NOT resolve `*.localhost`** — documented
   caveat; the `:4002` lane stays as the Safari fallback; `*.test`+dnsmasq noted as an optional
   future upgrade, not built.
3. **TLS** = plain HTTP on `:80`. No mkcert/HTTPS (no demo feature needs a secure context).
4. **Proxy home** = committed `examples/_proxy/compose.yaml` (version-controlled, shared,
   referenceable by sibling demos) — NOT `~/dev/proxy/`.

## Requirements

| ID | Requirement |
|----|-------------|
| DXPROXY-01 | A shared Traefik v3 ingress (`examples/_proxy/compose.yaml`, project `name: devproxy`, `exposedbydefault=false`, dashboard on loopback `127.0.0.1:8080`) binds `:80`/`:443` once and routes by Docker labels over an external `devproxy` network. Idempotent network creation. |
| DXINGRESS-01 | `scrypath_ecommerce` opts in via an additive `compose.proxy.yaml` overlay (Traefik labels incl. mandatory `traefik.docker.network=devproxy`, globally-unique router name, `web` joined to `[default, devproxy]`); the base `compose.yaml` `:4002` lane stays intact; `name: ${COMPOSE_PROJECT_NAME:-scrypath_ecommerce}` for worktree safety. |
| DXORIGIN-01 | Phoenix `check_origin` (dev/test endpoint config + LiveView socket) accepts `//scrypath.localhost` so LiveView connects behind the proxy (guards against the project's known LiveView-won't-connect-behind-proxy failure mode). |
| DXURLS-01 | A `make urls` helper prints the important URLs/routes (storefront, admin/ops UI, Meili, Postgres DSN, Traefik dashboard) after `make up`/`make dev`, with the Safari caveat + multi-demo tip. `make proxy` target stands up the shared proxy. |
| DXHYGIENE-01 | Add `examples/scrypath_ecommerce/.dockerignore` (defense-in-depth for `COPY . .` if `context:` ever changes) and simplify the redundant `scrypath_ops/priv/static/assets` exclude/re-include in the root `.dockerignore`. |
| DXCONVENTION-01 | `examples/phoenix_meilisearch` opted in with its own `Host()`+router name; `.env.example` updated ("lanes = host-tooling fallback; HTTP ingress via Traefik `*.localhost`" + Safari caveat + optional `*.test` upgrade); a short opt-in convention doc the sibling repos can copy. |

## Success criteria (milestone-level)

1. `make proxy && make up` (scrypath) → `http://scrypath.localhost/` (storefront) and
   `http://scrypath.localhost/admin/search` (ops UI) both serve, **LiveView connects** (socket
   established, no `check_origin` rejection), with **no host-port chosen** for `web`.
2. The legacy `http://127.0.0.1:4002` lane still works concurrently (parity / Safari / Playwright).
3. `phoenix_meilisearch` reachable at its own `*.localhost` host through the **same** Traefik,
   with a unique router name (no collision) — proving the shared-ingress convention.
4. `make urls` prints the route summary after boot; running two demos at once needs **zero**
   host-port decisions.
5. Strictly additive: `make dev`, `make up` (`:4002`), `psql -h 127.0.0.1 -p 5432`, and the
   existing Playwright/contrast/screenshot suites all behave exactly as before.

## Proposed phase roadmap

> Derived from the research's 6 waves, grouped into 2 light-touch phases. Re-confirm/repartition
> at `/gsd:new-milestone` or `/gsd:plan-phase` time.

- **Phase dx-1.1 — Shared proxy + scrypath ingress (core).** DXPROXY-01, DXINGRESS-01,
  DXORIGIN-01, DXURLS-01. (Research waves 1–4.) The load-bearing phase: stand up
  `examples/_proxy/`, the `devproxy` network, scrypath's `compose.proxy.yaml` overlay, the
  `check_origin` allowance, and the `make proxy`/`urls` ergonomics. See `dx-1.1-SPEC.md`.
- **Phase dx-1.2 — Hygiene + convention rollout.** DXHYGIENE-01, DXCONVENTION-01. (Research
  waves 5–6.) `.dockerignore` defense-in-depth, root-ignore asset cleanup, opt
  `phoenix_meilisearch` in, `.env.example` + opt-in convention docs for the sibling repos.

## Out of scope (explicitly deferred — noted, not built)

- `*.test` + dnsmasq Safari support (optional upgrade; `*.localhost` chosen).
- Local HTTPS via mkcert (plain HTTP chosen).
- Multistage `mix release` image (conflicts with the bind-mount dev loop + compile-at-boot test
  stack; future-only per research §4.4).
- Actual per-repo edits to rulestead/parapet/threadline (separate git repos) — this milestone
  ships the **convention + docs**; those repos adopt it on their own.

## Activation

This milestone is queued and self-contained. To make it active when ready:

```
/gsd:new-milestone   # then point it at this charter: .planning/milestones/docker-dx/CHARTER.md
```
or, to run it in parallel without disturbing v1.34, `/gsd:workstreams` (create a `docker-dx`
stream). Either way, the spec + decisions here feed straight into `/gsd:plan-phase` for dx-1.1.

**Do not** let milestone-activation tooling overwrite v1.34's active STATE.md/ROADMAP.md while
v1.34 is mid-flight (phases 129–136 pending) — see memory `state-planned-phase-clobbers-milestone`.
