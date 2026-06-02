# Domain Pitfalls: Realistic Demo App & E2E Testing

**Domain:** Open-Source Elixir Library E2E Testing & Demo Application
**Researched:** 2026-05-30
**Overall confidence:** HIGH

## Critical Pitfalls

Mistakes that cause dependency issues, CI failures, and developer frustration.

### Pitfall 1: Dependency Bloat in the Root `mix.exs`
**What goes wrong:** Adding `phoenix`, `phoenix_live_view`, `playwright`, or `ecto_sql` to the root `mix.exs` of the core library (even if scoped with `only: [:test, :dev]`).
**Why it happens:** Attempting to build and test the realistic demo app or `scrypath_ops` directly from the main library's root directory.
**Consequences:** End-users resolving Hex dependencies encounter massive trees and version conflicts. Library development slows to a crawl due to compiling Phoenix and asset pipelines just to run unit tests.
**Prevention:** **Total isolation.** Place the realistic demo app inside `examples/scrypath_ecommerce/`. Give it its own `mix.exs` and `mix.lock`. Have it depend on the main library via a path dependency (`{:scrypath, path: "../../"}`). CI will simply run `cd examples/scrypath_ecommerce && mix test` to execute E2E tests, preserving the core library's lean dependency tree.

### Pitfall 2: Ecto Sandbox State Mismatch
**What goes wrong:** Playwright tests click a button, but the UI throws a 404 or shows an empty list, even though the test's `setup` block just inserted the required data.
**Why it happens:** The Playwright browser runs as a separate OS process making HTTP requests. It does not share the same database transaction checkout as the ExUnit test process, meaning it cannot see uncommitted data inserted via `Ecto.Adapters.SQL.Sandbox`.
**Consequences:** Extremely flaky tests, false negatives, or abandoning the sandbox entirely (which breaks test isolation).
**Prevention:** You MUST use `Ecto.Adapters.SQL.Sandbox` in shared mode for browser tests. The standard idiomatic approach is to implement a Phoenix Plug in the demo app's `Endpoint` (active only in `MIX_ENV=test`) that reads a specific user-agent or metadata token from the Playwright request headers, and checks out the shared connection. (Libraries like `phoenix_test_playwright` handle this automatically via cookies/metadata).

### Pitfall 3: Port Clashes in Concurrent CI Runs
**What goes wrong:** Random `EADDRINUSE` errors during CI, or tests failing locally when developers have another Phoenix server running.
**Why it happens:** Hardcoding the Phoenix endpoint to `port: 4000` or `port: 4002` in the test configuration, or having multiple test suites clash over port `7700` for Meilisearch.
**Consequences:** Unreliable CI pipelines and poor developer ergonomics.
**Prevention:** 
- **Phoenix:** Configure the test endpoint with `server: true, http: [port: 0]`. The OS will assign an ephemeral port. Pass this port dynamically to the Playwright test setup.
- **Meilisearch:** Use a single Meilisearch container per workflow job. Clear indices in ExUnit `setup` blocks (via Scrypath test helpers) rather than attempting to isolate at the port/container level.

### Pitfall 4: Meilisearch CI Boot Timeouts
**What goes wrong:** E2E tests fail immediately with a `connection refused` error targeting Meilisearch on port `7700`.
**Why it happens:** The GitHub Actions `services` block starts the container, but Meilisearch takes a few seconds to accept HTTP connections. Tests start before the service is fully booted.
**Consequences:** False-positive CI failures that require manual re-runs.
**Prevention:** Always configure an explicit healthcheck in the GitHub Action `services` definition.
```yaml
services:
  meilisearch:
    image: getmeili/meilisearch:v1.1
    ports:
      - 7700:7700
    options: >-
      --health-cmd "curl --fail http://localhost:7700/health || exit 1"
      --health-interval 5s
      --health-timeout 5s
      --health-retries 5
```

### Pitfall 5: Pre-Compilation Asset Races
**What goes wrong:** Playwright browser tests load the page, but CSS is missing or JS hooks (like LiveView) fail to connect or execute.
**Why it happens:** Running `mix test` directly does not guarantee that `esbuild` or `tailwind` have finished compiling the `scrypath_ops` or demo app assets.
**Prevention:** Define an explicit Mix alias in the demo app's `mix.exs`:
`"test.e2e": ["assets.build", "ecto.create", "ecto.migrate", "test --only e2e"]`
Run this alias in CI. This guarantees assets are compiled before the Playwright browser is launched.

## Perfect One-Shot Recommendation

To successfully implement v1.28 (Realistic Demo App & Admin UI Proof):

1. **Keep the Core Clean:** Do not modify the root `mix.exs`.
2. **Create the Demo App:** Initialize a completely separate Phoenix project at `examples/scrypath_ecommerce/`.
3. **Configure Path Dependencies:** In the demo app's `mix.exs`, add `{:scrypath, path: "../../"}` and `{:scrypath_ops, path: "../../scrypath_ops"}`.
4. **Playwright Integration:** Use standard Playwright (or a thin wrapper like `phoenix_test_playwright`). Ensure the Ecto Sandbox is configured to accept connection metadata via headers/cookies so Playwright and ExUnit share the same transaction.
5. **Dynamic Ports:** Set `http: [port: 0]` for the demo app's test environment.
6. **CI Workflow:** Add an isolated GitHub Actions workflow specifically for the demo app that starts a Meilisearch service (with healthchecks), compiles assets, and runs the E2E tests inside the `examples/scrypath_ecommerce/` directory.

## Sources
- Official Elixir Library Guidelines (Isolation of test/demo dependencies)
- Playwright/Phoenix Ecto Sandbox Best Practices (Shared connection mode)
- GitHub Actions Service Healthcheck Documentation