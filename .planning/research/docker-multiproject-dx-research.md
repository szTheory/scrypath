# Docker DX: Zero-Conflict Multi-Project Local Stacks (Elixir/Phoenix demos on macOS)

Research date: 2026-06-04. Grounded in the real files under
`/Users/jon/projects/scrypath/examples/scrypath_ecommerce/` and the live `docker ps`
on this machine (parapet_demo, rulestead_demo_jon_main, threadline-postgres,
scrypath_ecommerce). Every recommendation is backed by either a cited source or a fact
observed in this repo.

---

## 1. TL;DR recommendation

**Target architecture: one shared Traefik ingress on a shared external Docker network,
`*.localhost` hostnames, unpublished infra, per-project compose `name:` with an optional
`_<dev>` suffix. Keep the host-port lanes as a fallback for host tooling only.**

Concretely, for this developer running 4–5 Phoenix lib demos at once:

1. **Run ONE Traefik container** (in its own tiny compose project, e.g.
   `~/dev/proxy/compose.yaml`) that publishes `80`/`443` exactly once on the host and
   watches the Docker socket. Source: [Docker — HTTP routing with Traefik](https://docs.docker.com/guides/traefik/).
2. **Create one shared external bridge network** (`docker network create devproxy`). Every
   demo's `web` service joins it and carries `traefik.*` labels; Traefik routes by hostname.
   Source: [hollo.me — Routing to multiple docker-compose setups with Traefik](https://hollo.me/devops/routing-to-multiple-docker-compose-development-setups-with-traefik.html).
3. **Each demo opts in with ~5 labels and one network line — no host ports.** The storefront
   becomes `http://scrypath.localhost`, the admin UI `http://scrypath.localhost/admin/search`,
   Meili `http://meili.scrypath.localhost`. A new lib opts in by copying the label block and
   changing one hostname. This kills the entire `4002/5432/7700` collision class.
4. **`*.localhost` resolves to `127.0.0.1` automatically in Chrome/Edge/Firefox and curl** with
   no `/etc/hosts` and no dnsmasq (RFC 6761). Confirmed live on this machine:
   `dscacheutil -q host -a name foo.localhost` returned `127.0.0.1`/`::1`.
   Sources: [Docker Traefik guide](https://docs.docker.com/guides/traefik/) ("all
   Chromium-based browsers route `*.localhost` requests locally with no additional setup"),
   [Microsoft Learn — .localhost TLD](https://learn.microsoft.com/en-us/aspnet/core/test/localhost-tld?view=aspnetcore-10.0).

**Why this and not the status quo:** the lane convention already in `.env.example`
(`+10` offset per demo) works but is *manual bookkeeping that scales O(projects × services)*
and gives ugly, unmemorable URLs (`:4012`, `:5442`). The proxy gives **stable, memorable,
zero-port URLs**, **automatic opt-in** (Traefik reads labels live with no restart), and
**eliminates infra host collisions entirely** because nothing but Traefik binds a host port.

**Two macOS footguns to bake into the plan up front:**
- **Safari does NOT resolve `*.localhost`.** Use Chrome/Firefox for `*.localhost`, or add a
  dnsmasq/`/etc/resolver` entry for a `*.test` TLD if Safari support is required.
  Source: [Microsoft Learn — .localhost TLD](https://learn.microsoft.com/en-us/aspnet/core/test/localhost-tld?view=aspnetcore-10.0).
- **Keep the loopback host-port lanes for host tooling** (`psql -h 127.0.0.1 -p 5432`, the
  `make dev` *host* Phoenix loop, Playwright pinned at `127.0.0.1:4002`). The proxy is for
  HTTP ingress; it does not replace a published Postgres port when a host tool needs raw TCP.

---

## 2. Options comparison

Scores: ✅ good / ⚠️ partial / ❌ poor.

| Option | Zero-config | Stable URLs | Multi-project safety | Setup cost | macOS friction | Opt-in cost / new lib |
|---|---|---|---|---|---|---|
| **1. Host-port lanes (status quo)** | ⚠️ manual `.env` per project | ⚠️ stable but ugly (`:4012`) | ⚠️ relies on discipline | ✅ none (done) | ✅ low | ⚠️ pick a free block, edit `.env` |
| **2. Shared Traefik + `*.localhost` (recommended)** | ✅ live label discovery | ✅ `scrypath.localhost` | ✅ only proxy binds a port | ⚠️ one-time proxy + net | ⚠️ Safari `*.localhost` gap | ✅ copy label block, 1 hostname |
| **3. Ephemeral host ports (`-P`/`:0`)** | ✅ never collides | ❌ URL changes each `up` | ✅ | ✅ trivial | ✅ | ⚠️ tooling must `compose port`-discover |
| **4. dnsmasq / `*.test` resolver** | ⚠️ one-time install | ✅ `scrypath.test` | n/a (DNS only) | ⚠️ brew + `/etc/resolver` | ⚠️ system config | ✅ wildcard covers all |
| **5. `COMPOSE_PROJECT_NAME` / `-p` namespacing** | ✅ (already via `name:`) | n/a | ✅ net/vol/container isolation | ✅ done | ✅ | ✅ inherit pattern |
| **6. Unpublished infra (reach over net)** | ✅ | n/a | ✅ removes 5432/7700 class | ✅ already done in base stack | ✅ | ✅ free |

The recommended stack is **2 + 5 + 6 together** (Traefik ingress, strict namespacing,
unpublished infra), with **1** retained as the loopback fallback and **3/4** as situational.

---

## 3. Per-option deep dive

### Option 1 — Host-port lanes (status quo)

**What this repo does today.** `compose.yaml` sets `name: scrypath_ecommerce` and publishes
only the app: `127.0.0.1:${WEB_PORT:-4002}:4002`. Infra (`postgres`, `meilisearch`) is
**unpublished** in the base stack; the dev override `compose.dev.yaml` adds loopback infra
lanes `127.0.0.1:${PG_PORT:-5432}:5432` and `127.0.0.1:${MEILI_PORT:-7700}:7700`.
`.env.example` documents the convention: each demo gets a base, offset every port `+10`.

**Pros:** zero infra to stand up; loopback-only binding avoids LAN exposure; works today;
explicit and debuggable.

**Cons / when it breaks down:**
- **Manual allocation is O(projects × services).** With 4–5 demos each owning web+pg+meili
  (+redis), the dev is hand-maintaining a port ledger. The live machine already shows the
  strain: native Postgres on `5432`, `threadline-postgres` bumped to `5433`, and
  `scrypath_ecommerce-postgres` *unpublished* (no host port) — three different strategies
  for one service across three projects.
- **Ugly, unmemorable URLs.** `:4012`, `:5442`, `:7710` are not copy-pasteable from memory.
- **Silent drift.** Nothing enforces the `+10` convention; two demos can pick the same lane.
- The kernel ephemeral range (49153–65535 on Docker 20+) can also collide with a hardcoded
  lane in rare cases. Source: [moby#43054](https://github.com/moby/moby/issues/43054).

**Lesson learned:** lanes are a fine *fallback for raw-TCP host tooling*, but a poor primary
strategy for HTTP ingress once project count grows. Keep them; stop relying on them for URLs.

### Option 2 — Shared Traefik ingress + `*.localhost` (RECOMMENDED)

**How it works.** One Traefik container publishes `80`/`443` once and reads the Docker socket;
each app container declares routing via labels. Traefik watches engine events and adds/removes
routes live — **no restart, no central config edit when a project comes up.**
Source: [Docker — HTTP routing with Traefik](https://docs.docker.com/guides/traefik/).

Minimal proxy service (from the official guide, hardened for local multi-project):

```yaml
# ~/dev/proxy/compose.yaml  (its own project, started once)
name: devproxy
services:
  traefik:
    image: traefik:v3.6
    command:
      - --providers.docker
      - --providers.docker.exposedbydefault=false   # opt-in only
      - --entrypoints.web.address=:80
      - --entrypoints.websecure.address=:443
      - --api.dashboard=true
    ports:
      - "80:80"
      - "443:443"
      - "127.0.0.1:8080:8080"   # Traefik dashboard, loopback only
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks: [devproxy]
networks:
  devproxy:
    external: true        # created once: docker network create devproxy
```

Per-project opt-in (what `scrypath_ecommerce`'s `web` service adds):

```yaml
services:
  web:
    labels:
      - traefik.enable=true
      - traefik.docker.network=devproxy
      - traefik.http.routers.scrypath.rule=Host(`scrypath.localhost`)
      - traefik.http.services.scrypath.loadbalancer.server.port=4002
    networks: [default, devproxy]   # default = project-internal; devproxy = shared ingress
networks:
  devproxy:
    external: true
```

Sources for the external-network + label opt-in pattern:
[hollo.me](https://hollo.me/devops/routing-to-multiple-docker-compose-development-setups-with-traefik.html),
[Traefik Labs forum — external network multi-project](https://community.traefik.io/t/trafik-and-multiple-projects-with-external-network/22642).

**Pros:**
- **Zero host-port management** beyond the proxy itself; backend services need *no* host ports.
- **Stable, memorable URLs** per project (`scrypath.localhost`, `rulestead.localhost`).
- **Automatic discovery** — a new demo appears the moment its labelled container starts.
  Source: [Docker Traefik guide](https://docs.docker.com/guides/traefik/).
- **`*.localhost` needs no `/etc/hosts` / no dnsmasq** in Chrome/Edge/Firefox/curl (RFC 6761).
  Verified live: `foo.localhost` → `127.0.0.1` on this box.

**Cons / footguns:**
- **`traefik.docker.network` is mandatory** when a service is on >1 network (it is here:
  `default` + `devproxy`), or Traefik may pick the wrong IP. Source:
  [bitExpert — Traefik with multiple Docker networks](https://blog.bitexpert.de/blog/traefik_with_multiple_docker_networks).
- **Router names must be globally unique** across all projects (e.g. `routers.scrypath.rule`).
  Reusing `web` across projects collides. Source:
  [Traefik forum — service names in multiple compose projects](https://community.traefik.io/t/service-names-in-multiple-docker-compose-projects-locally/3606).
- **Safari ignores `*.localhost`.** Use Chrome/Firefox, or move to `*.test` + dnsmasq (Option 4)
  if Safari is a hard requirement. Source:
  [Microsoft Learn](https://learn.microsoft.com/en-us/aspnet/core/test/localhost-tld?view=aspnetcore-10.0).
- **Phoenix needs `check_origin` / host config to accept the new Host header.** `dev.exs` here
  reads `PHX_HOST_IP`; the LiveView socket and `check_origin` must allow `scrypath.localhost`
  or LiveView won't connect (a recurring class of bug for proxied Phoenix — see the project's
  own e2e-harness memory about assets/host causing LiveView to not connect).
- **TLS:** browsers warn on self-signed. For trusted local HTTPS use `mkcert "*.localhost"`
  and mount the cert into Traefik. Source:
  [hollo.me](https://hollo.me/devops/routing-to-multiple-docker-compose-development-setups-with-traefik.html).
  For demos, plain HTTP on `:80` is usually fine — skip TLS unless a feature needs secure context.
- **Docker socket mount** gives Traefik root-equiv access to the daemon; acceptable on a dev
  laptop, note it for awareness.

**Lesson learned:** this is the canonical "many local web apps, one machine" answer and the
single highest-leverage change for this developer.

### Option 3 — Ephemeral / dynamic host ports (`-P`, `ports: ["4002"]`, `:0`)

Publish with no fixed host port; discover via `docker compose port web 4002`.
Source: [Docker — docker compose port](https://docs.docker.com/reference/cli/docker/compose/port/),
[markcallen — dynamic ports to prevent conflicts](https://www.markcallen.com/preventing-port-conflicts-in-docker-compose-with-dynamic-ports/).

**Pros:** literally cannot collide; trivial change.
**Cons / footguns:**
- **URL changes on every `up`** — terrible for bookmarks, Playwright (`PLAYWRIGHT_BASE_URL`
  is pinned to `127.0.0.1:4002` here), and copy-paste DX.
- `host:0` binding is **not reliably supported in Compose**; people fall back to `-P` or
  omitting the host port. Source:
  [compose-cli#1314](https://github.com/docker-archive/compose-cli/issues/1314).
- Every tool must shell out to `docker compose port` to find the URL.

**Verdict:** good *only* for throwaway parallel CI runs, not for an interactive demo loop.
Traefik gives the same "no collision" benefit *with* stable URLs.

### Option 4 — dnsmasq / `*.test` resolver on macOS

When `*.localhost` is insufficient (Safari, or you want a non-loopback wildcard, or nested
subdomains in Safari), run dnsmasq and add a macOS resolver:

```
# /usr/local/etc/dnsmasq.conf   (brew install dnsmasq)
address=/test/127.0.0.1
# /etc/resolver/test
nameserver 127.0.0.1
```

Sources: [Simon Willison TIL — wildcard DNS on macOS with dnsmasq](https://til.simonwillison.net/macos/wildcard-dns-dnsmasq),
[dev.to — wildcard domains on macOS with dnsmasq](https://dev.to/timtsoitt/how-to-resolve-local-wildcard-domains-in-macos-h5e).

**Pros:** one wildcard covers every project (`*.test`), works in Safari, nested subdomains.
**Cons / footguns:** system-level config (brew service + `/etc/resolver`); `127.0.0.1` must be
the **topmost** resolver entry or queries leak to upstream DNS and return NXDOMAIN
([dev.to](https://dev.to/timtsoitt/how-to-resolve-local-wildcard-domains-in-macos-h5e)).
**Verdict:** optional Safari/UX upgrade layered *on top of* Traefik. `.test` is the RFC-reserved
TLD for exactly this; prefer it over `.dev` (HSTS-preloaded by Google) or `.local` (mDNS).

### Option 5 — `COMPOSE_PROJECT_NAME` / `-p` namespacing correctness

**Already done well here:** `compose.yaml` sets `name: scrypath_ecommerce`, which prefixes
the default network (`scrypath_ecommerce_default`, confirmed in `docker network ls`),
containers (`scrypath_ecommerce-postgres-1`, confirmed in `docker ps`), and the named volumes
in `compose.dev.yaml`. Precedence: `-p` flag > `COMPOSE_PROJECT_NAME` > top-level `name:` >
directory basename. Source:
[Docker — Compose env vars / COMPOSE_PROJECT_NAME](https://docs.docker.com/compose/how-tos/environment-variables/envvars/).

**The `_jon_main` suffix pattern (from `rulestead_demo_jon_main`)** encodes
`<project>_<developer>_<branch>`. This is the right idea for **multiple checkouts / worktrees /
branches of the same project on one machine** — without it, two checkouts of rulestead share
networks/volumes and clobber each other. Recommendation for scrypath demos: keep the static
`name: scrypath_ecommerce` for the common case, but support an env override so a second
worktree can run as `scrypath_ecommerce_jon_<branch>`:

```yaml
name: ${COMPOSE_PROJECT_NAME:-scrypath_ecommerce}
```

**Footguns:** named **volumes are also project-prefixed** — `make reset` (which does
`down -v`) only wipes *this* project's volumes, good; but two differently-named projects keep
*separate* DB volumes (expected, occasionally surprising). Project names must be lowercase
alnum/dash/underscore. Source:
[Docker — envvars](https://docs.docker.com/compose/how-tos/environment-variables/envvars/).

### Option 6 — Eliminate Postgres/Meilisearch host collisions (unpublished infra)

**Principle, already applied in the base stack:** `web` reaches `postgres`/`meilisearch` by
**service name over the compose network** (`PGHOST: postgres`,
`SCRYPATH_MEILISEARCH_URL: http://meilisearch:7700`), and the base `compose.yaml` publishes
**no** infra host ports. This removes the whole `5432`/`7700` host-collision class — the live
`docker ps` confirms `scrypath_ecommerce-postgres-1` has no host port while two other projects
fight over `5432`/`5433`.
Source: [Baeldung — expose vs ports](https://www.baeldung.com/ops/docker-compose-expose-vs-ports),
[Docker forums — access container only through reverse proxy](https://forums.docker.com/t/access-container-only-through-reverse-proxy/114661).

**When you DO need a published infra port:** host tooling that speaks raw TCP — `psql`/`pgcli`,
a GUI like TablePlus, the Meili dashboard hit directly, or the `make dev` **host** Phoenix loop
which connects to `127.0.0.1:$PG_PORT`. That is exactly why `compose.dev.yaml` publishes
infra on loopback lanes. Keep this as the fallback; just don't publish infra in the proxy world
unless a host tool needs it.

---

## 4. Layer-caching findings (concrete issues in THIS repo)

Build context is the **repo root** (`context: ../..`), so the **root `.dockerignore`**
(`/Users/jon/projects/scrypath/.dockerignore`) is the one that governs `COPY . .`.

### What's already correct
- **mix.exs/mix.lock copied before source** (Dockerfile lines 18–20), then `mix deps.get`
  (lines 26–30), then `COPY . .` (line 32). Textbook layer ordering — a CSS/source change does
  **not** re-run `deps.get`. Source: [Docker — optimize cache usage](https://docs.docker.com/build/cache/optimize/).
- **BuildKit cache mounts** for `/root/.hex` and `/root/.cache/rebar3` (lines 26–27): a
  `mix.lock` change re-resolves but only re-downloads *changed* archives.
  Source: [Docker — optimize cache usage](https://docs.docker.com/build/cache/optimize/).
- **Correctly NOT mounting `/root/.mix`** — the Dockerfile comment explicitly warns this would
  shadow the hex/rebar archives installed by `mix local.hex/local.rebar` (line 10). This is a
  real, subtle footgun and it's handled right.
- **`.git` is in `.dockerignore`** (32M here) — a committed `.git` would otherwise bust the
  `COPY . .` cache on *every commit*. Good. The root ignore also excludes `_build`, `deps`,
  `node_modules`, `test-results`, `playwright-report` — all correct.
- **Dev override uses named volumes** for `deps` and `_build` (six of them), so the host
  bind-mount of source doesn't clobber compiled artifacts and recompiles are incremental.
  Source: [silva96 — Phoenix dev with Docker](https://silva96.github.io/elixir-phoenix-development-using-docker/).

### Issues found
1. **No `.dockerignore` in `examples/scrypath_ecommerce/`.** Today it's harmless *because the
   context is the repo root*. But it is a latent footgun: if anyone ever changes
   `context:` to `examples/scrypath_ecommerce`, there is no ignore file and `COPY . .` would
   suck in `_build`, `deps`, `node_modules`, `test-results`, `.tmp`, busting the cache every
   build. **Fix:** add a local `examples/scrypath_ecommerce/.dockerignore` mirroring the root's
   relevant lines, as defense-in-depth. Source:
   [Docker — optimize cache usage](https://docs.docker.com/build/cache/optimize/).

2. **The entrypoint recompiles/seeds on every boot.** `docker-entrypoint.sh` runs
   `ecto.create`/`ecto.migrate`/`scrypath.demo.seed` and `mix phx.server` each start, and in
   `MIX_ENV=dev` also runs three `mix deps.get` calls. For the **test stack** this means the
   first request compiles the app at boot (no `mix compile` baked into the image). This is a
   deliberate dev/test single-stage tradeoff, but worth flagging: **`mix compile` is not baked**,
   so cold starts pay full compile time. Acceptable for a demo; see #4 below if boot latency
   bites.

3. **`.dockerignore` assets contradiction is intentional but fragile.** The root ignore has:
   ```
   scrypath_ops/priv/static/assets
   !scrypath_ops/priv/static/assets
   !scrypath_ops/priv/static/assets/**
   ```
   i.e. exclude-then-re-include. The net effect is "ship the committed ops assets." It works,
   but the exclude line is dead weight and confusing; the precompiled CSS/JS are committed
   (confirmed: `scrypath_ops/priv/static/assets/{css,js}` exist). **Fix:** drop the bare
   exclude line and keep only the re-include, or document why both exist. Low priority.

4. **No multistage release build.** Single-stage `hexpm/elixir:...-debian` image carries
   build-essential/git/npm/postgresql-client into the runtime. Fine for a dev/test demo. *If*
   you ever want a slim, fast-booting demo image, a two-stage build (builder → `mix release`
   into a slim runtime) drops image size dramatically and bakes a precompiled release so boot
   is instant. Sources:
   [cogini/phoenix_container_example](https://github.com/cogini/phoenix_container_example)
   (<20MB final image via multistage + `mix release`),
   [oneuptime — containerize Phoenix](https://oneuptime.com/blog/post/2026-02-08-how-to-containerize-an-elixir-phoenix-application-with-docker/view).
   **Recommendation: do NOT do this now** — it conflicts with the bind-mount dev loop and the
   test stack's compile-at-boot expectation. Note as a future option only.

5. **Asset watchers (`esbuild`/`tailwind`) run via the Phoenix `watchers` in `dev.exs`**
   (lines 40–42) and the ops Tailwind watcher in `compose.dev.yaml`. Assets are *committed*
   precompiled, so the image doesn't re-download esbuild/tailwind binaries on build — good.
   The known cache pitfall (re-downloading the esbuild/tailwind binary) is avoided because the
   binaries live in `deps`/`_build` named volumes in dev and are baked in test.

---

## 5. Concrete migration plan for scrypath_ecommerce (GSD-phase shaped)

Behavior-parity, light-touch. Demos stay runnable exactly as today; the proxy is **additive**.

**Wave 1 — Shared proxy (one-time, lives outside the repo).**
- `docker network create devproxy` (idempotent; add a guard to the Makefile).
- Add `~/dev/proxy/compose.yaml` (the Traefik service from §3, `exposedbydefault=false`,
  dashboard on `127.0.0.1:8080`). Document `docker compose -f ~/dev/proxy/compose.yaml up -d`.
  (Optionally commit a copy at `examples/_proxy/compose.yaml` so every lib demo shares it.)

**Wave 2 — Opt scrypath_ecommerce in (additive overlay; keep base stack untouched).**
- New file `examples/scrypath_ecommerce/compose.proxy.yaml`:
  ```yaml
  services:
    web:
      labels:
        - traefik.enable=true
        - traefik.docker.network=devproxy
        - traefik.http.routers.scrypath.rule=Host(`scrypath.localhost`)
        - traefik.http.services.scrypath.loadbalancer.server.port=4002
      networks: [default, devproxy]
  networks:
    devproxy:
      external: true
  ```
- This keeps `compose.yaml`'s loopback `WEB_PORT` mapping intact — both the proxy URL and the
  `:4002` lane work. (Drop the host `ports:` only if you want proxy-only.)
- Parameterize the project name for worktrees:
  `name: ${COMPOSE_PROJECT_NAME:-scrypath_ecommerce}` in `compose.yaml`.

**Wave 3 — Phoenix host acceptance.**
- Ensure `dev.exs`/`test.exs` endpoint `check_origin` (and any LiveView socket origin check)
  allows `//scrypath.localhost`. Without this LiveView will refuse the socket behind the proxy
  (matches the project's prior LiveView-won't-connect failure mode). Add
  `scrypath.localhost` to `check_origin` for dev/test only.

**Wave 4 — Makefile ergonomics.**
- `make proxy` → create network (guarded) + `up -d` the proxy.
- `make up` → `docker compose -f compose.yaml -f compose.proxy.yaml up --build`.
- Add a `urls` helper (see §6) called at the end of `up` and `dev` targets.
- `COMPOSE := docker compose -f compose.yaml -f compose.proxy.yaml`.

**Wave 5 — Hygiene fixes from §4.**
- Add `examples/scrypath_ecommerce/.dockerignore` (defense-in-depth).
- Simplify the `scrypath_ops/priv/static/assets` exclude/re-include in root `.dockerignore`.

**Wave 6 — Docs.**
- Update `.env.example` to note: "Lanes are now a fallback for host tooling only; HTTP ingress
  goes through Traefik at `*.localhost`." Add the Safari caveat. Mention the optional
  `*.test` + dnsmasq upgrade.

Optional follow-on (separate phase): replicate the same `compose.proxy.yaml` overlay into
`examples/phoenix_meilisearch/` so all sibling demos share the one Traefik. Each just picks a
unique `Host()` and unique router name.

---

## 6. What it prints after boot

A `urls` Makefile target (echo block; no new deps) appended to `make up` / `make dev`:

```
make[1]: scrypath_ecommerce is up.

  Storefront        http://scrypath.localhost            (proxy)  |  http://127.0.0.1:4002
  Admin / Ops UI    http://scrypath.localhost/admin/search
  Meili dashboard   http://meili.scrypath.localhost      (proxy)  |  http://127.0.0.1:7700
  Postgres          postgres://postgres:postgres@127.0.0.1:5432/scrypath_ecommerce_dev
  Traefik dashboard http://127.0.0.1:8080/dashboard/

  Tip: *.localhost works in Chrome/Firefox/curl with no /etc/hosts. Safari? use the :4002 lane.
  Tip: running another demo? give it its own Host() + a unique router name; no port to pick.
```

Implementation sketch (works with the existing `-include .env` / `export`):

```makefile
.PHONY: urls
urls: ## Print the important URLs for this demo
	@echo ""
	@echo "  Storefront        http://scrypath.localhost            |  http://127.0.0.1:$(WEB_PORT)"
	@echo "  Admin / Ops UI    http://scrypath.localhost/admin/search"
	@echo "  Meili dashboard   http://meili.scrypath.localhost      |  http://127.0.0.1:$(MEILI_PORT)"
	@echo "  Postgres          postgres://postgres:postgres@127.0.0.1:$(PG_PORT)/scrypath_ecommerce_dev"
	@echo "  Traefik dashboard http://127.0.0.1:8080/dashboard/"
	@echo ""
```

Call it at the tail of `dev:` and after `up:` (or via `up: ... ; $(MAKE) urls`).

---

## Sources
- [Docker — HTTP routing with Traefik](https://docs.docker.com/guides/traefik/)
- [Docker — Compose env vars / COMPOSE_PROJECT_NAME](https://docs.docker.com/compose/how-tos/environment-variables/envvars/)
- [Docker — optimize cache usage in builds](https://docs.docker.com/build/cache/optimize/)
- [Docker — docker compose port](https://docs.docker.com/reference/cli/docker/compose/port/)
- [Docker — publishing and exposing ports](https://docs.docker.com/get-started/docker-concepts/running-containers/publishing-ports/)
- [hollo.me — Routing to multiple docker-compose setups with Traefik](https://hollo.me/devops/routing-to-multiple-docker-compose-development-setups-with-traefik.html)
- [Traefik Labs forum — multiple projects with external network](https://community.traefik.io/t/trafik-and-multiple-projects-with-external-network/22642)
- [Traefik Labs forum — service names across compose projects](https://community.traefik.io/t/service-names-in-multiple-docker-compose-projects-locally/3606)
- [bitExpert — Traefik with multiple Docker networks](https://blog.bitexpert.de/blog/traefik_with_multiple_docker_networks)
- [Microsoft Learn — .localhost TLD support (incl. Safari caveat)](https://learn.microsoft.com/en-us/aspnet/core/test/localhost-tld?view=aspnetcore-10.0)
- [Simon Willison TIL — wildcard DNS on macOS with dnsmasq](https://til.simonwillison.net/macos/wildcard-dns-dnsmasq)
- [dev.to — wildcard domains on macOS with dnsmasq](https://dev.to/timtsoitt/how-to-resolve-local-wildcard-domains-in-macos-h5e)
- [Baeldung — expose vs ports in Docker Compose](https://www.baeldung.com/ops/docker-compose-expose-vs-ports)
- [Docker forums — access container only through reverse proxy](https://forums.docker.com/t/access-container-only-through-reverse-proxy/114661)
- [markcallen — preventing port conflicts with dynamic ports](https://www.markcallen.com/preventing-port-conflicts-in-docker-compose-with-dynamic-ports/)
- [moby#43054 — kernel ephemeral port range in Docker 20+](https://github.com/moby/moby/issues/43054)
- [compose-cli#1314 — ephemeral host ports](https://github.com/docker-archive/compose-cli/issues/1314)
- [cogini/phoenix_container_example — multistage Elixir release build](https://github.com/cogini/phoenix_container_example)
- [oneuptime — containerize an Elixir Phoenix app with Docker](https://oneuptime.com/blog/post/2026-02-08-how-to-containerize-an-elixir-phoenix-application-with-docker/view)
- [silva96 — Elixir Phoenix development using Docker (named volumes)](https://silva96.github.io/elixir-phoenix-development-using-docker/)
