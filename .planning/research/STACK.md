# Technology Stack

**Project:** Scrypath Demo App & Admin UI Proof (v1.28)
**Researched:** 2026-05-30 (Context Date)

## Recommended Stack

### Core Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Phoenix & LiveView | 1.8+ / 1.1+ | Web Demo UI & Admin UI | Idiomatic foundation. The demo app will embed the `scrypath_ops` admin UI directly inside a real Phoenix router. |
| Ecto | 3.13+ | Truth & Data Modeling | Strict boundary for truth. Ensures Ecto schemas stay thin while contexts manage Scrypath synchronization. |

### Database & Search
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| PostgreSQL | 15+ | Primary Datastore | Provides durable truth, check constraints, and referential integrity (idiomatic Ecto). |
| Meilisearch | latest | Search Backend | Core target for Scrypath syncing and integration proof. Ran as a Docker container locally and natively as a service in CI. |

### Infrastructure / Testing
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Playwright (Node Runner) | latest | E2E Browser Testing | `@playwright/test` provides the most robust E2E browser testing, trace viewing, and developer experience. It is vastly superior to Wallaby or Elixir wrappers for complex browser interactions (like JS hooks and full lifecycle testing). |
| ExUnit + LiveViewTest | latest | Component & View Tests | Idiomatic Elixir testing. Handles 95% of UI state machine and component verification without browser overhead. |
| GitHub Actions | latest | CI/CD | Easily spins up Postgres and Meilisearch service containers, starts Phoenix in the background (`mix phx.server`), and runs Playwright tests against it. |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| E2E Testing | Playwright (Node.js `@playwright/test`) | Wallaby | Wallaby relies on aging WebDriver protocols (ChromeDriver). It lacks Playwright's auto-waiting, built-in trace viewer, network interception, and robust cross-browser support out-of-the-box. |
| E2E Testing | Playwright (Node.js `@playwright/test`) | `playwright_elixir` | While running Playwright inside ExUnit sounds appealing for language consistency, it loses the native Playwright Test Runner's powerful UI mode, VSCode integration, and parallel sharding logic. The standard TS/JS Playwright runner against a running Elixir server provides the best DX. |
| CI Search Backend | Meilisearch Service Container | Mocking / Mox | For v1.28's goal of "Realistic Demo App & Admin UI Proof", mocking the backend defeats the purpose. A real Meilisearch instance in CI validates true E2E behavior and operator honesty. |

## E2E Testing Strategy

1. **ExUnit & LiveViewTest (The Core):** Fast, process-isolated testing for all Phoenix contexts and LiveView state machines. This remains the primary testing mechanism.
2. **Playwright E2E (The Proof):** Targeted at 1-2 critical user flows (e.g., searching for a product, filtering by facets, opening the admin UI to check sync status).
   - **Workflow:** In CI, run `MIX_ENV=test mix phx.server` in the background. Playwright tests execute against `http://localhost:4002`. The database and Meilisearch are seeded with standard fixtures before the run.

## Demo App Integration Patterns

- **Contexts:** Implement a realistic `Catalog` context for Products to demonstrate standard Scrypath integration.
- **Admin UI Integration:** Mount `scrypath_ops` LiveViews via `live_session` in the demo app's router, protected by basic auth or a mock admin role, proving seamless adoption.
- **Playwright Targets:** Ensure the demo app uses semantic data attributes (e.g., `data-testid="search-input"`) to make Playwright assertions stable without relying on brittle CSS selectors.

## Sources
- `.planning/milestone-candidates.md` (Noted the deferred "Playwright on 1-2 flows" and "OPSUI + real backend in CI" - this milestone specifically answers those challenges).
- `prompts/phoenix-live-view-best-practices-deep-research.md` (Emphasizes thin LiveViews, explicit context APIs, and LiveViewTest for state machines).
- `prompts/ecto-best-practices-deep-research.md` (Emphasizes PostgreSQL truth and database-level constraints).