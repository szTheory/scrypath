# Phase 145: Legacy Phoenix and Ecto/Decimal Remediation - Research

**Researched:** 2026-08-22
**Domain:** Isolated Mix dependency remediation for a Phoenix/Ecto/Postgres example
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### 1. Manifest bounds and dependency ownership

- **D-01:** Express the direct fixed-compatible cohorts as Phoenix `~> 1.8.9`,
  Bandit `~> 1.12.1`, Ecto SQL `~> 3.14.0`, and Postgrex `~> 0.22.4`. These
  three-part pessimistic requirements admit reviewed patch releases within each
  selected minor line while excluding the next minor line.
- **D-02:** Leave `phoenix_ecto` unchanged unless the resolver or a focused
  compatibility failure proves that its manifest requirement must move. Do not
  widen or modernize unrelated direct dependencies.
- **D-03:** Keep Ecto and Decimal transitive. Ecto SQL 3.14 owns the Ecto 3.14
  cohort and both Ecto/Ecto SQL own Decimal 3; the example must not add direct
  `:ecto` or `:decimal` dependencies, a Decimal override, or `override: true`.
- **D-04:** The reviewed lockfile is the deterministic application resolution.
  Refresh only the causal solver closure required by the four direct cohort
  changes and Phase 144's inherited Req floor. Every moved row must be explained;
  package-head churn and unrelated cleanup are out of scope.
- **D-05:** A detached lockless probe at the exact candidate commit must resolve:
  Phoenix `>= 1.8.9 and < 1.9.0`, Bandit `>= 1.12.1 and < 1.13.0`, Ecto and
  Ecto SQL `>= 3.14.0 and < 3.15.0`, Postgrex `>= 0.22.4 and < 0.23.0`, Decimal
  `>= 3.0.0`, Plug `>= 1.19.5 and < 1.20.0`, Req `>= 0.6.1 and < 0.7.0`,
  Mint `>= 1.9.3`, and hpax `>= 1.0.4`.
- **D-06:** Run an unsuppressed legacy-graph `mix hex.audit` against the fresh
  resolution. A network, registry, or advisory-feed outage means evidence is
  unavailable, never passing.

### 2. Database, migration, fixture, and cast proof

- **D-07:** Add a small Postgres-backed `DataCase` compatibility contract using
  the existing `Post`, `Author`, Repo, migrations, changesets, and SQL Sandbox.
  It must prove representative valid and invalid changesets, required-field
  errors, inserts, queries, the Author/Post relationship, timestamps, and the
  persisted values the example actually uses.
- **D-08:** Test-local Phoenix-style fixture helpers are appropriate when they
  make the causal database tests clearer. Do not create a public fixture API or
  seed data solely for this phase.
- **D-09:** Do not add a Decimal-valued field, migration, schema, seed, or
  artificial runtime assertion. The example has no Decimal domain field. The
  bounded dependency resolution and audit prove Decimal 3; application tests
  prove the example's real Ecto behavior.
- **D-10:** Prove both migration postures: the normal clean-database `mix test`
  alias must create and migrate successfully, and a second
  `mix ecto.migrate --quiet` against the already-migrated database must succeed
  as a no-op.
- **D-11:** Keep the causal database contract independent of Meilisearch and
  Scrypath synchronization. Do not call `Blog.update_author/3` from it because
  that path intentionally crosses into search synchronization. The existing live
  smokes retain ownership of inline/Oban/fan-out behavior.
- **D-12:** Reuse the generated `DataCase` pattern with
  `Ecto.Adapters.SQL.Sandbox.start_owner!/2` and `stop_owner/1`. Preserve correct
  ownership for any supervised or spawned process; do not solve ownership errors
  with sleeps, global shared state, or disabling isolation.

### 3. Phoenix, Plug, and Bandit endpoint proof

- **D-13:** Use a layered endpoint contract. First, add focused `ConnCase`
  requests through the real `ScrypathDemoWeb.Endpoint` and router pipeline for
  representative JSON and malformed-cookie/error behavior. Assert stable
  responses and non-crashing request processing without adding an application
  route.
- **D-14:** Add one async-false, loopback, ephemeral-port real-HTTP contract that
  starts the configured Phoenix/Bandit endpoint, sends a normal HTTP/1 JSON
  request through the endpoint, asserts the stable response, and observes the
  documented `[:bandit, :request, :stop]` telemetry event. Use public
  Phoenix/Bandit adapter interfaces and supervised cleanup.
- **D-15:** Do not claim or add WebSocket, HTTP/2, session round-trip, browser, or
  UI coverage. The example mounts no socket, writes no session state through a
  route, and has no relevant UI. Fixed dependency selection and the advisory
  audit cover the recorded protocol vulnerabilities; protocol-specific behavior
  becomes testable only if the example later promises it.
- **D-16:** The existing Postgres + Meilisearch + inline-Oban/fan-out example lane
  remains supplemental live evidence. Run it when its documented prerequisites
  are available and report it separately. It must not substitute for the causal
  database or endpoint hard checks, and unavailable services must not be reported
  as passing.

### 4. Gate order, evidence, and stop conditions

- **D-17:** The binding deterministic order is: inspect and explain the
  manifest/lock diff; run legacy `mix deps.get --check-locked`; run clean-database
  legacy tests; run the already-migrated no-op check; run the legacy app's
  `mix precommit`; then run root
  `mix test --exclude integration --exclude docs_contract`.
- **D-18:** After the deterministic candidate is green, run the detached fresh
  resolution and unsuppressed audit. Separately run the existing live example
  lane when Postgres and Meilisearch prerequisites are available.
- **D-19:** Keep evidence compact and auditable: record the candidate commit,
  timestamp, environment, commands and exit statuses, resolved target versions,
  audit result, causal lock rows, and hard-versus-supplemental classification.
  Do not commit raw logs, disposable locks, generated dependency trees, service
  artifacts, or advisory snapshots.
- **D-20:** Add no permanent Mix task, dependency-policy layer, CI topology, new
  service, or UI evidence. Existing Mix aliases, the root fast test, the current
  live CI/runbook, and standard Hex tooling are the maintainer interface.
- **D-21:** A source compatibility fix is allowed only when the fixed-compatible
  upgrade demonstrates the need. Keep it to the smallest example-internal change
  with focused regression coverage and unchanged public Scrypath and example
  behavior.
- **D-22:** Stop and re-plan on any out-of-range fresh resolution, advisory audit
  failure, unexplained lock churn, migration/cast/persistence/endpoint regression,
  inability to boot the real listener, root regression, requirement for a direct
  Decimal dependency or override, public Scrypath API change, new route/socket,
  schema migration, endpoint policy redesign, or broader dependency modernization.

### 5. JTBD, domain language, and quality lenses

- **D-23:** Primary maintainer JTBD: "I need to remove the legacy example's
  reproduced advisories in one understandable batch and know immediately whether
  dependency resolution, Ecto persistence, Phoenix request processing, or the
  optional live search path regressed."
- **D-24:** Contributor JTBD: normal Mix/Phoenix workflows should remain the
  interface. A contributor gets a reviewed lock, concise failures at the owning
  boundary, a fast causal loop, and one documented opt-in live path rather than a
  new security/testing subsystem.
- **D-25:** Adopter JTBD: the example continues to demonstrate an ordinary
  Phoenix/Ecto/Postgres application using Scrypath without exposing dependency
  solver mechanics through the public library API or hiding operational search
  requirements.
- **D-26:** Use the domain language consistently. Nouns: manifest, lock,
  dependency cohort, Repo, migration, changeset, fixture, row, association,
  endpoint, request, audit, and live stack. Events: resolve, compile, migrate,
  cast, insert, query, serve, audit, and smoke. Maintainer verbs: bound, align,
  explain, verify, isolate, report, and stop.
- **D-27:** The governing quality pillars are security, correctness,
  compatibility, reproducibility, maintainability, operability, resilience,
  performance, evidence clarity, least surprise, contributor/adopter DX, and
  strict scope discipline. Visual design, accessibility styling, dark/light/system
  themes, motion, microcopy, and brand expression are not applicable because this
  phase changes no user interface.

### the agent's Discretion

- Exact focused test filenames and whether the small fixture helpers live in the
  database contract file or existing test support are left to planning, provided
  they remain private, representative, and easy to diagnose.
- The exact supervised ephemeral-listener harness and HTTP client are left to
  research/planning. It must use existing dependencies or OTP facilities, public
  Phoenix/Bandit APIs, loopback port allocation, and deterministic cleanup.
- The exact JSON path and malformed-cookie shape are flexible because the example
  has no application route; do not add one solely to make the test more attractive.
- Targeted Mix update commands may vary, but the resulting manifest intent,
  bounded fresh resolution, and causal lock diff are binding.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within the Phase 145 maintenance boundary. Protocol-
specific WebSocket or HTTP/2 tests belong to a future phase only if the example
later mounts sockets or explicitly promises those behaviors.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SEC-02 | Maintainers can resolve the legacy Phoenix example's recorded advisories through coordinated Phoenix/Bandit and Ecto/Ecto SQL/Decimal upgrades. | Bounded direct cohorts, transitive Ecto/Decimal ownership, causal lock-diff review, detached resolution/audit, and database/endpoint regression contracts. |
</phase_requirements>

## Summary

[VERIFIED: repository code] This phase changes one independent graph: `examples/phoenix_meilisearch/mix.exs` currently directly bounds Phoenix at `~> 1.8.5`, Ecto SQL at `~> 3.13`, Bandit at `~> 1.5`, and Postgrex broadly, while its lock selects Phoenix 1.8.5, Bandit 1.10.4, Ecto/Ecto SQL 3.13.5, Decimal 2.3.0, Plug 1.19.1, and Postgrex 0.22.0. Phase 144 has already moved this graph's inherited root-path Req closure to Req 0.6.3, Mint 1.9.3, and hpax 1.0.4; do not re-own that handoff.

[CITED: https://hex.pm/packages/ecto_sql/dependencies] Ecto SQL 3.14 declares Ecto `~> 3.14.0` and Decimal `~> 3.0`; [CITED: https://hex.pm/packages/postgrex/dependencies] current Postgrex dependencies allow Decimal 3. Therefore Ecto SQL is the correct direct owner for the Ecto/Decimal remediation, and a direct Decimal dependency or override would fight rather than clarify the resolver.

[VERIFIED: repository code] The existing example already supplies the least-surprise proof surfaces: its test alias creates and migrates the database; `DataCase` uses `Sandbox.start_owner!/2` and cleanup; `ConnCase` routes requests through the actual endpoint; the endpoint uses `Bandit.PhoenixAdapter`; and the existing tagged smoke modules plus `scripts/smoke.sh` own the real Postgres/Meilisearch/Scrypath journey. Add only focused DB and endpoint contracts alongside those surfaces.

**Primary recommendation:** Use the four locked direct bounds, accept only their causal solver closure in `mix.lock`, add private `DataCase` and layered endpoint compatibility tests, then verify in D-17 order before detached fresh-resolution/audit evidence.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Dependency cohort selection and deterministic resolution | Build/dependency management | Hex registry | [VERIFIED: repository code] The example manifest declares the direct owners and its tracked lock records the application resolution. |
| Ecto changeset, insert, query, association, and timestamp compatibility | Database/Storage | API/Backend | [VERIFIED: repository code] `Post`, `Author`, `Repo`, and three migrations own the persisted model. |
| JSON/error and malformed-cookie request compatibility | API/Backend | Frontend server | [VERIFIED: repository code] The Phoenix endpoint owns Plug parsers/session/router; `ConnCase` invokes this pipeline in process. |
| Listener and request-span compatibility | Frontend server | API/Backend | [CITED: https://bandit.hexdocs.pm/Bandit.PhoenixAdapter.html] The configured Phoenix adapter owns the bound Bandit listener; [CITED: https://bandit.hexdocs.pm/Bandit.Telemetry.html] Bandit owns request telemetry. |
| Search synchronization smoke | External service boundary | Database/Storage | [VERIFIED: repository code] Existing tagged integration tests require Postgres and Meilisearch and remain supplemental. |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | `~> 1.8.9` | Example endpoint/router framework | [CITED: https://elixir.hexdocs.pm/Version.html] A three-part pessimistic bound admits 1.8 patch fixes and excludes 1.9. |
| Bandit | `~> 1.12.1` | Configured Phoenix HTTP server | [CITED: https://bandit.hexdocs.pm/Bandit.PhoenixAdapter.html] The example already configures `Bandit.PhoenixAdapter`. |
| Ecto SQL | `~> 3.14.0` | SQL Repo, migrations, Sandbox | [CITED: https://hex.pm/packages/ecto_sql/dependencies] It causally owns Ecto 3.14 and Decimal 3. |
| Postgrex | `~> 0.22.4` | Existing Postgres driver | [CITED: https://hex.pm/packages/postgrex/dependencies] Postgrex accepts Decimal 3, avoiding a separate Decimal constraint. |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Ecto | transitive `>= 3.14.0, < 3.15.0` | schemas, changesets, queries | [CITED: https://hex.pm/packages/ecto_sql/dependencies] Let Ecto SQL resolve it. |
| Decimal | transitive `>= 3.0.0` | Ecto/Postgrex numeric dependency | [CITED: https://hex.pm/packages/ecto/dependencies] Let Ecto and Ecto SQL resolve it; do not add an application field or direct declaration. |
| Plug | transitive `>= 1.19.5, < 1.20.0` | parsers/session/request pipeline | [VERIFIED: repository lock] It is required by Phoenix/Bandit and Req but should remain transitive here. |
| Req/Mint/hpax | inherited fixed floor | Root path dependency HTTP closure | [VERIFIED: repository lock] Phase 144 already selected Req 0.6.3, Mint 1.9.3, hpax 1.0.4 in this lock. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Cohort-aligned Ecto SQL upgrade | Direct Decimal 3 constraint/override | [VERIFIED: phase context D-03] Forbidden: it obscures the actual Ecto SQL ownership and risks an invalid solver graph. |
| Existing `DataCase`/`ConnCase` | New integration framework or permanent Mix task | [VERIFIED: repository code] Unnecessary; generated Phoenix/Ecto test support already has the correct Repo, endpoint, and Sandbox lifecycle. |
| One small real HTTP listener test | WebSocket/HTTP2/browser suite | [VERIFIED: phase context D-15] Out of scope because the example exposes none of those application behaviors. |

**Installation:** No new package is installed. [VERIFIED: repository code] The implementation changes bounds on existing direct dependencies and refreshes their causal lock closure only.

**Version verification:** [VERIFIED: Hex registry via `mix hex.info`] On 2026-08-22, Hex listed Phoenix 1.8.9 (released 2026-07-07), Bandit 1.12.1 (2026-07-24), Ecto SQL 3.14.0 (2026-05-19), and Postgrex 0.22.4 (2026-08-07); the locked bounds intentionally permit only compatible patches rather than package heads.

## Package Legitimacy Audit

[VERIFIED: repository code] Not applicable: Phase 145 adds no external package or package name. It remediates already-declared Hex packages under locked bounds, so the package-legitimacy gate for a newly introduced dependency does not apply.

## Architecture Patterns

### System Architecture Diagram

```text
mix.exs direct bounds
        |
        v
Hex resolver ---> reviewed mix.lock ---> deterministic checks
        |                                      |
        |                                      +--> deps.get --check-locked
        v
Ecto SQL 3.14 ---> Ecto 3.14 + Decimal 3 ---> DataCase -> Repo -> Postgres
                                                        |
                                                        +--> migrations / changesets / associations

HTTP/1 client -> loopback Bandit -> ScrypathDemoWeb.Endpoint -> Plug pipeline -> Router -> JSON error response
                                      |                                  |
                                      +--> Bandit request :stop telemetry +--> ConnCase error/cookie contract

Postgres + Meilisearch + tagged smoke tests ----------------------------------> supplemental live evidence only
```

### Recommended Project Structure

```text
examples/phoenix_meilisearch/
├── mix.exs                              # four direct cohort bounds only
├── mix.lock                             # reviewed causal application resolution
├── test/scrypath_demo/
│   └── ecto_compatibility_test.exs       # private DataCase contract
├── test/scrypath_demo_web/
│   └── endpoint_compatibility_test.exs   # ConnCase + real HTTP contract
└── test/smoke/                           # existing optional live search contracts
```

### Pattern 1: Cohort owner plus causal lock review

**What:** Change only Phoenix, Bandit, Ecto SQL, and Postgrex constraints to the locked three-part bounds; resolve and explain every resulting lock row.

**When to use:** [VERIFIED: phase context D-01 through D-06] Always for this remediation; stop rather than loosening direct/transitive ownership if the resolver cannot meet the required range.

**Example:**

```elixir
# Source: phase context D-01/D-03; current manifest location
{:phoenix, "~> 1.8.9"}
{:ecto_sql, "~> 3.14.0"}
{:postgrex, "~> 0.22.4"}
{:bandit, "~> 1.12.1"}
# No direct :ecto, :decimal, :mint, :hpax, or override: true.
```

### Pattern 2: Generated Sandbox contract, not a second database harness

**What:** Put the DB compatibility test on `use ScrypathDemo.DataCase`; use existing schemas and private helpers to create a valid `Author` and `Post`, then assert required errors, insertion/query, association, timestamps, and persisted title/body/status/author_name.

**When to use:** [VERIFIED: repository code] For the Ecto/Decimal cohort proof, excluding `Blog.update_author/3` because it deliberately invokes search synchronization.

**Example:**

```elixir
# Source: https://ecto-sql.hexdocs.pm/Ecto.Adapters.SQL.Sandbox.html
use ScrypathDemo.DataCase, async: true

test "persists the example's Author/Post shape" do
  author = Repo.insert!(Author.changeset(%Author{}, %{name: "Ada"}))
  changeset = Post.changeset(%Post{}, %{title: "T", body: "B", status: "published", author_id: author.id, author_name: author.name})
  assert {:ok, post} = Repo.insert(changeset)
  assert %{author: %{name: "Ada"}, inserted_at: %DateTime{}} = Repo.get!(Post, post.id) |> Repo.preload(:author)
end
```

### Pattern 3: Layered request proof

**What:** First use `ConnCase` with `get/2` on an existing unmatched `/api/...` path and a malformed session cookie to assert the JSON error response and no crash. Then use one `async: false` loopback HTTP/1 request against a supervised ephemeral Bandit listener using `ScrypathDemoWeb.Endpoint` as the Plug, attach a unique telemetry handler, and assert the request `:stop` event plus the stable response.

**When to use:** [VERIFIED: phase context D-13 through D-15] Only to prove the configured stack's real request boundary; do not introduce a test route, socket, browser, or protocol claim.

**Example:**

```elixir
# Sources: https://phoenix.hexdocs.pm/testing.html and https://bandit.hexdocs.pm/Bandit.Telemetry.html
handler_id = {__MODULE__, make_ref()}
parent = self()

:ok =
  :telemetry.attach(handler_id, [:bandit, :request, :stop], fn _event, measurements, metadata, _config ->
    send(parent, {:bandit_stop, measurements, metadata})
  end, nil)

on_exit(fn -> :telemetry.detach(handler_id) end)

# Start a supervised Bandit child on {127, 0, 0, 1}, port 0, using the existing endpoint Plug.
# Obtain the bound port through the selected public server-info interface, make one HTTP/1 request,
# then assert its JSON 404/error response and the matching stop event before teardown.
```

### Anti-Patterns to Avoid

- **Direct Decimal ownership:** [VERIFIED: phase context D-03] Do not add `:decimal`, `:ecto`, an override, a Decimal field, or an artificial cast assertion.
- **Package-head refresh:** [VERIFIED: phase context D-04] Do not unlock all dependencies or accept unrelated `mix.lock` movement.
- **Search-coupled DB test:** [VERIFIED: phase context D-11] Do not use `Blog.update_author/3`; the causal DB test must not need Meilisearch.
- **Flaky listener or Sandbox management:** [CITED: https://ecto-sql.hexdocs.pm/Ecto.Adapters.SQL.Sandbox.html] Do not use sleeps or leave spawned processes alive; supervise/await them and preserve ownership.
- **Synthetic application surface:** [VERIFIED: phase context D-13 through D-15] Do not create routes, sockets, migrations, schema fields, or permanent testing infrastructure merely to improve coverage appearance.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Dependency range logic | Custom fixed-version policy or override layer | [CITED: https://elixir.hexdocs.pm/Version.html] Three-part `~>` bounds and Mix resolver | Correctly expresses a patch-line floor/ceiling without exact pins. |
| Transactional DB isolation | New checkout/rollback harness | [CITED: https://ecto-sql.hexdocs.pm/Ecto.Adapters.SQL.Sandbox.html] Existing `DataCase.setup_sandbox/1` | It already starts/stops an owner and shares only non-async test connections. |
| Endpoint test framework | Ad hoc `Plug.Test` route harness | [CITED: https://phoenix.hexdocs.pm/testing.html] Existing `ConnCase` and `Phoenix.ConnTest` | Exercises the actual endpoint/router pipeline with the app's endpoint configuration. |
| HTTP server/telemetry shim | Test-only server or event wrapper | [CITED: https://bandit.hexdocs.pm/Bandit.PhoenixAdapter.html] Existing Bandit and Phoenix adapter interfaces | Covers the actual selected server and stable request span. |
| Live search replacement | Fake Meilisearch for database compatibility | [VERIFIED: repository code] Existing tagged smoke modules and `scripts/smoke.sh` | Keeps service-dependent search proof separate from deterministic cohort proof. |

**Key insight:** [VERIFIED: phase context D-23 through D-24] The smallest trustworthy remediation separates resolver, DB, endpoint, and live-search failures by their owning boundary instead of hiding them behind one slow all-services smoke.

## Common Pitfalls

### Pitfall 1: Ecto/Decimal split ownership

**What goes wrong:** [VERIFIED: repository lock] Upgrading Decimal alone conflicts with the current Ecto 3.13 requirement on Decimal 2.

**Why it happens:** [CITED: https://hex.pm/packages/ecto_sql/dependencies] Ecto SQL 3.14 is the cohort that changes Ecto to 3.14 and Decimal to 3.

**How to avoid:** [VERIFIED: phase context D-03] Update only Ecto SQL directly and prove Decimal 3 in the detached resolver; never add `override: true`.

**Warning signs:** [VERIFIED: phase context D-22] The solver asks for a direct Decimal declaration/override or returns an out-of-range Ecto/Decimal version.

### Pitfall 2: Lock drift disguised as security work

**What goes wrong:** [VERIFIED: repository code] A broad `deps.update` can move unrelated legacy dependencies beyond their reviewed application resolution.

**Why it happens:** [VERIFIED: phase context D-04] Four direct cohort edits have a limited causal closure, while package-head upgrades add unrelated solver changes.

**How to avoid:** [VERIFIED: phase context D-17] Review manifest and lock diff before any test; explain every moved row, including Phase 144 inherited Req rows if present.

**Warning signs:** [VERIFIED: phase context D-22] A moved lock row has no path from Phoenix/Bandit/Ecto SQL/Postgrex/Req closure or the fresh resolution reaches a disallowed minor.

### Pitfall 3: Sandbox ownership failure in asynchronous proof

**What goes wrong:** [CITED: https://ecto-sql.hexdocs.pm/Ecto.Adapters.SQL.Sandbox.html] A spawned process queries after the test owner exits or without an allowance, yielding an ownership error.

**Why it happens:** [CITED: https://ecto-sql.hexdocs.pm/Ecto.Adapters.SQL.Sandbox.html] The Sandbox controls connection ownership transactionally; shared mode is non-concurrent and allowances must be explicit.

**How to avoid:** [VERIFIED: repository code] Reuse `DataCase`; keep the DB contract async-safe; make the real listener test `async: false`, supervise its child, and stop/await it before test exit.

**Warning signs:** `DBConnection.OwnershipError`, owner-exited logs, sleeps, global state, or tests that pass only serially without a documented ownership reason. [CITED: https://ecto-sql.hexdocs.pm/Ecto.Adapters.SQL.Sandbox.html]

### Pitfall 4: Treating ConnCase as a real listener

**What goes wrong:** [VERIFIED: repository code] A `ConnCase` request can prove the endpoint pipeline but not that test configuration (`server: false`) starts a Bandit socket.

**Why it happens:** [VERIFIED: repository code] `config/test.exs` explicitly sets `server: false`.

**How to avoid:** [VERIFIED: phase context D-14] Retain the fast in-process request contract and add exactly one isolated loopback, ephemeral-port HTTP/1 contract with request-stop telemetry.

**Warning signs:** [VERIFIED: phase context D-22] No bound listener, a fixed/colliding port, no stop event, or claims of WebSocket/HTTP2 coverage.

### Pitfall 5: Misreporting unavailable external proof

**What goes wrong:** [VERIFIED: environment audit] Local Postgres at 5433 and Meilisearch at 7700 were unavailable during research.

**Why it happens:** [VERIFIED: repository code] The smoke lane needs both services; ordinary `mix test` also requires Postgres for its create/migrate alias.

**How to avoid:** [VERIFIED: phase context D-16/D-18] Mark unavailable live proof unavailable, not passing; run deterministic checks when their prerequisites exist and report hard versus supplemental status separately.

**Warning signs:** [VERIFIED: phase context D-19] Evidence lacks environment/prerequisites, a command exit status, or an explicit unavailable classification.

## Code Examples

Verified patterns from official sources:

### Existing DataCase ownership lifecycle

```elixir
# Source: https://ecto-sql.hexdocs.pm/Ecto.Adapters.SQL.Sandbox.html
pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Repo, shared: not tags[:async])
on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
```

### Existing Phoenix ConnCase shape

```elixir
# Source: https://phoenix.hexdocs.pm/testing.html
@endpoint ScrypathDemoWeb.Endpoint
import Phoenix.ConnTest

setup tags do
  ScrypathDemo.DataCase.setup_sandbox(tags)
  {:ok, conn: Phoenix.ConnTest.build_conn()}
end
```

### Bandit request evidence

```elixir
# Source: https://bandit.hexdocs.pm/Bandit.Telemetry.html
parent = self()
:telemetry.attach(handler_id, [:bandit, :request, :stop], fn _event, measurements, metadata, _ ->
  send(parent, {:bandit_stop, measurements, metadata})
end, nil)
# Assert response first, then assert_receive the stop event with non-negative duration
# and endpoint Plug metadata; detach in on_exit.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Ecto SQL 3.13 with Ecto/Decimal 2 | Ecto SQL 3.14 with Ecto/Decimal 3 | [CITED: https://hex.pm/packages/ecto_sql/dependencies] 3.14.0 published 2026-05-19 | Align the full data cohort through Ecto SQL, not Decimal alone. |
| Bandit 1.10.4 and Phoenix 1.8.5 locked example | Bounded Bandit 1.12.x and Phoenix 1.8.x patch line | [VERIFIED: phase context D-01] fixed-compatible floor | Security remediation stays within compatible minor lines. |

**Deprecated/outdated:**

- [VERIFIED: repository lock] The locked legacy set (Phoenix 1.8.5, Bandit 1.10.4, Ecto/Ecto SQL 3.13.5, Decimal 2.3.0, Plug 1.19.1, Postgrex 0.22.0) is the recorded advisory state and must be replaced only by the bounded cohort.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The implementation can obtain the ephemeral listener's bound port using the final selected public Phoenix/Bandit server-info interface without changing permanent endpoint policy. | Architecture Patterns | The real-HTTP contract would need a smaller harness adjustment; no dependency or public-scope decision changes. |

## Open Questions

1. **Exact ephemeral-listener startup shape after the Bandit patch-line update**
   - What we know: [CITED: https://bandit.hexdocs.pm/Bandit.PhoenixAdapter.html] Bandit supports Phoenix endpoint adapter configuration and exposes bound-server information; [VERIFIED: repository code] the installed Phoenix endpoint supports startup options merged with endpoint config.
   - What's unclear: [VERIFIED: repository code] Test config starts the normal endpoint with `server: false`, so the executor must choose the smallest supervised test-only startup shape that preserves the configured endpoint Plug/adapter contract.
   - Recommendation: Use the Phase Context D-14 acceptance condition as the decision rule; prove a loopback port, normal HTTP/1 JSON response, request-stop event, and deterministic teardown before retaining the harness. Stop and re-plan if this requires endpoint policy redesign or a permanent service.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir/Mix | resolver and all Mix gates | ✓ | Elixir/Mix 1.19.5, OTP 28 | — |
| Docker Compose | optional local live smoke | ✓ | Docker 29.5.2 | GitHub Actions service job |
| PostgreSQL listener at `localhost:5433` | legacy test alias, migration check, DB contract | ✗ | client 14.17; listener absent | Start documented Compose/CI-shaped Postgres 16 service |
| Meilisearch at `127.0.0.1:7700` | supplemental live smoke only | ✗ | — | Start documented Compose/CI-shaped Meilisearch v1.15 service |
| Hex registry/advisory feed | detached resolution and `mix hex.audit` | ✓ during research lookup | registry reachable | None; outage is unavailable evidence |

**Missing dependencies with no fallback:**

- [VERIFIED: repository code] None for planning. Execution must start Postgres before deterministic legacy DB gates; a missing listener is a prerequisite failure, not a passing result.

**Missing dependencies with fallback:**

- [VERIFIED: repository code] The optional live lane can use the documented Compose stack or CI services; do not replace its outcome with a fake service.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | [VERIFIED: repository code] ExUnit with Phoenix `ConnCase` and Ecto SQL Sandbox |
| Config file | [VERIFIED: repository code] `examples/phoenix_meilisearch/config/test.exs` |
| Quick run command | `cd examples/phoenix_meilisearch && mix test test/scrypath_demo/ecto_compatibility_test.exs test/scrypath_demo_web/endpoint_compatibility_test.exs` |
| Full suite command | `cd examples/phoenix_meilisearch && mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SEC-02 | Bounded direct manifest and causal lock select the fixed compatible dependency cohort | resolver/lock inspection + detached integration | `cd examples/phoenix_meilisearch && mix deps.get --check-locked` | ❌ Wave 0 evidence procedure |
| SEC-02 | Ecto changesets, required errors, inserts, queries, association, timestamps, and persisted values remain valid | Postgres-backed integration | `cd examples/phoenix_meilisearch && mix test test/scrypath_demo/ecto_compatibility_test.exs` | ❌ Wave 0 |
| SEC-02 | Existing endpoint/router keeps JSON error processing stable for unmatched API and malformed-cookie requests | endpoint integration | `cd examples/phoenix_meilisearch && mix test test/scrypath_demo_web/endpoint_compatibility_test.exs` | ❌ Wave 0 |
| SEC-02 | Bandit performs one real HTTP/1 request and emits its request stop span | real-listener integration | `cd examples/phoenix_meilisearch && mix test test/scrypath_demo_web/endpoint_compatibility_test.exs` | ❌ Wave 0 |
| SEC-02 | Clean DB migration and already-migrated no-op both work | migration integration | `cd examples/phoenix_meilisearch && mix test && mix ecto.migrate --quiet` | Existing alias / ❌ no-op invocation evidence |
| SEC-02 | Root library remains green with legacy path dependency | root regression | `mix test --exclude integration --exclude docs_contract` | ✅ existing |

### Sampling Rate

- **Per task commit:** Focused legacy test file(s), then `mix deps.get --check-locked`.
- **Per wave merge:** `cd examples/phoenix_meilisearch && mix test && mix ecto.migrate --quiet && mix precommit`, then root fast suite.
- **Phase gate:** D-17 deterministic sequence green before detached fresh resolution and unsuppressed audit; live smoke is classified separately.

### Wave 0 Gaps

- [ ] `examples/phoenix_meilisearch/test/scrypath_demo/ecto_compatibility_test.exs` — private, causal DataCase coverage for SEC-02.
- [ ] `examples/phoenix_meilisearch/test/scrypath_demo_web/endpoint_compatibility_test.exs` — ConnCase plus one async-false loopback real-HTTP/telemetry proof for SEC-02.
- [ ] Compact candidate evidence document or phase summary section — command/status/version/causal-lock-row/audit classification only; no raw logs or disposable artifacts.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | [VERIFIED: repository code] The example exposes no auth route. |
| V3 Session Management | yes, boundary only | [VERIFIED: repository code] Existing signed cookie `Plug.Session`; malformed-cookie request proves non-crashing behavior without asserting a nonexistent session flow. |
| V4 Access Control | no | [VERIFIED: repository code] The router has no application routes or authorization policy. |
| V5 Input Validation | yes | [VERIFIED: repository code] Existing `Plug.Parsers` and Ecto changesets; test invalid required fields and a malformed cookie/error boundary. |
| V6 Cryptography | no new implementation | [VERIFIED: repository code] Existing signed cookie configuration stays unchanged; do not hand-roll or redesign session cryptography. |

### Known Threat Patterns for the Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Vulnerable resolved dependency remains selected | Tampering / Information disclosure / DoS | [VERIFIED: phase context D-05/D-06] Bounded detached fresh resolution and unsuppressed `mix hex.audit`. |
| Parser or malformed cookie crashes endpoint | Denial of service | [VERIFIED: phase context D-13] ConnCase malformed-cookie/error contract plus real HTTP request proof. |
| Cross-process DB access outlives Sandbox owner | Denial of service / correctness | [CITED: https://ecto-sql.hexdocs.pm/Ecto.Adapters.SQL.Sandbox.html] Existing owner lifecycle, explicit allowance/shared-mode discipline, and supervised cleanup. |
| Scope expansion masks remediation risk | Elevation of privilege / maintainability | [VERIFIED: phase context D-20/D-22] Stop on routes, sockets, schema migrations, public API, endpoint-policy redesign, or broad modernization. |

## Execution-Recovery Addendum — 2026-08-22

### Trigger and recommendation

[VERIFIED: execution evidence] The detached, lockless resolution at implementation SHA `e50fbd5694c75ff5f25c2a07046185f35c107dd9` selected Plug `1.20.3`, so it compiled but correctly stopped before the audit and live smoke: the D-05 assertion requires `>= 1.19.5 and < 1.20.0`.

**Primary recommendation:** Add the existing transitive package as one explicit, ordinary direct requirement in `examples/phoenix_meilisearch/mix.exs`:

```elixir
{:plug, "~> 1.19.5"},
```

[VERIFIED: Mix resolution, 2026-08-22] In Mix, this three-part pessimistic requirement resolves the reviewed `1.19.x` line (`>= 1.19.5 and < 1.20.0`); a detached, lockless resolution at the implementation SHA selected Plug `1.19.5`, preserved Phoenix `1.8.12`, Bandit `1.12.5`, Ecto `3.14.2`, Ecto SQL `3.14.0`, Postgrex `0.22.4`, Decimal `3.1.1`, Req `0.6.3`, Mint `1.9.3`, and hpax `1.0.4`, and compiled successfully.

[VERIFIED: Hex registry API, 2026-08-22] Plug `1.19.5` is the patched release for the `1.19` advisories listed by Hex: the affected ranges end before `1.19.5`; the direct-bound fresh graph also returned `No retired or security advisory packages found` from unsuppressed `mix hex.audit`.

### Why this is the smallest safe recovery

| Alternative | Evidence | Decision |
|-------------|----------|----------|
| Add `{:plug, "~> 1.19.5"}` and retain the D-05 ceiling | [VERIFIED: Mix resolution, 2026-08-22] The one-entry manifest change makes the fresh solver select `1.19.5`; the candidate compiles and unsuppressed audit is clean. | **Use.** It makes the already-reviewed 1.19.x cohort reproducible without an override, suppression, source change, or broader modernization. |
| Widen D-05 to permit `>= 1.19.5 and < 1.21.0` | [VERIFIED: Hex registry API, 2026-08-22] Phoenix `1.8.9` declares Plug `~> 1.14` and Bandit `1.12.5` declares Plug `~> 1.18`, both of which admit Plug `1.20.3`; the unbounded fresh graph compiles and audits cleanly. | **Reject.** Plug `1.20.3` is currently security-fixed and declared-compatible, but widening replaces an explicit reviewed minor ceiling with a newly admitted minor line and weakens the phase's causal cohort contract. |
| Pin `== 1.19.5` | [VERIFIED: Hex registry API, 2026-08-22] `1.19.5` is current and audited cleanly. | **Reject.** It unnecessarily denies later patched `1.19.x` releases; `~> 1.19.5` expresses the intended fixed-compatible patch line. |
| Use `override: true`, a lock-only pin, or an audit suppression | [VERIFIED: Mix resolution, 2026-08-22] The normal solver accepts the direct `~> 1.19.5` requirement without conflict. | **Reject.** No conflict exists to justify an override; a lock-only outcome fails the detached-fresh proof; a suppression contradicts D-06. |

### Compatibility and security finding

[VERIFIED: Hex registry API, 2026-08-22] Plug `1.20.3` is technically compatible with the selected Phoenix/Bandit cohort under their published requirements: Phoenix `1.8.9` requires Plug `~> 1.14`, Bandit `1.12.5` requires Plug `~> 1.18`, and both ranges admit `1.20.3`.

[VERIFIED: Hex registry API, 2026-08-22] Plug `1.20.3` is also currently outside Hex's affected `1.20` advisory ranges, which end before `1.20.3`; the detached unbounded graph's unsuppressed `mix hex.audit` returned clean. This does **not** make it the recovery choice: the phase's binding D-05 ceiling intentionally defines the narrower compatibility cohort, and D-22 requires re-planning rather than silently accepting an out-of-range fresh result.

### Decision-contract disposition

| Context decision | Recovery disposition |
|------------------|----------------------|
| D-01 | **Amend narrowly.** Add Plug `~> 1.19.5` as a fifth direct fixed-compatible cohort owner; retain the existing Phoenix, Bandit, Ecto SQL, and Postgrex ranges exactly. |
| D-03 | **Remain locked.** Ecto and Decimal remain transitive; this adds neither, and it uses no Decimal override or `override: true`. |
| D-05 | **Reinterpret ownership; retain the exact range.** Plug `>= 1.19.5 and < 1.20.0` stays binding, but it must now be enforced by the direct `~> 1.19.5` manifest requirement rather than inferred only from the reviewed lock. |
| D-20 | **Remain locked.** The recovery adds no Mix task, policy layer, CI topology, service, or UI evidence. |
| D-21 | **Remain locked and not invoked.** No source compatibility fix is demonstrated or allowed by this recovery. |
| D-22 | **Remain locked; trigger satisfied.** The observed out-of-range fresh result caused this re-plan. After the direct bound, another out-of-range resolution, audit finding, unexplained tracked-lock churn, or deterministic regression remains a stop condition. |
| D-23 through D-27 | **Remain locked.** The direct manifest bound keeps the repair understandable and reproducible, preserves normal Mix workflows and the existing Phoenix/Ecto example, uses the established domain language, and supports the stated security/correctness/compatibility/evidence-quality pillars. |

### Implementation and verification contract for the recovery plan

1. [VERIFIED: Mix resolution, 2026-08-22] Make one graph-local implementation commit that adds only `{:plug, "~> 1.19.5"}` to the example manifest. Do not alter application source, test source, routes, schemas, endpoint policy, CI, or the root graph. The existing lock already selects `1.19.5`; retain it only if `mix deps.get --check-locked` confirms it remains valid, otherwise explain every lock row before committing.
2. [VERIFIED: phase context D-17/D-22] Treat the manifest amendment as a new exact candidate SHA and rerun the deterministic D-17 sequence on that SHA before a fresh network probe; Plan 145-01's completed commit and summary remain historical evidence and are not rewritten.
3. [VERIFIED: Mix resolution, 2026-08-22] In the detached, lockless probe, retain the existing assertion `Version.match?(plug, ">= 1.19.5 and < 1.20.0")`. Run `mix deps.get`, `mix compile --warnings-as-errors`, the ten package assertions, and unsuppressed `mix hex.audit`; require Plug `1.19.5` under today's registry. Record a future registry or advisory outage as unavailable/blocking, never as pass.
4. [VERIFIED: phase context D-19] Preserve the compact evidence format: recovery SHA, UTC time, Elixir/OTP/Mix/Hex versions, selected versions, direct Plug rationale, audit exit, and primary-lock hash/clean-worktree result. The existing Postgres/Meilisearch live lane remains supplemental and is not changed by this dependency-only recovery.

### Exact recovery commands

```bash
# On the recovery candidate, from examples/phoenix_meilisearch
mix deps.get --check-locked
mix test
mix ecto.migrate --quiet
mix precommit

# From the repository root after the legacy deterministic gates
mix test --exclude integration --exclude docs_contract

# In the detached lockless worktree after mix deps.get and mix compile
mix run --no-compile --no-deps-check -e '
lock = Mix.Dep.Lock.read()
version = lock |> Map.fetch!(:plug) |> elem(2)
Version.match?(version, ">= 1.19.5 and < 1.20.0") ||
  raise "plug #{version} violates >= 1.19.5 and < 1.20.0"
'
mix hex.audit
```

[VERIFIED: project constraints] This recovery introduces no new external package: Plug is already a resolved Hex dependency of Phoenix, Bandit, Phoenix Ecto, and WebSock Adapter. Therefore the package-legitimacy gate for a newly introduced package is not applicable; Hex registry metadata and the normal resolver/audit remain the authoritative checks.

## Sources

### Primary (HIGH confidence)

- [VERIFIED: repository code] `examples/phoenix_meilisearch/{mix.exs,mix.lock,config/test.exs,test/support/{data_case,conn_case}.ex}` — current graph, test alias, endpoint/test/Sandbox seams.
- [VERIFIED: repository code] `examples/phoenix_meilisearch/lib/{scrypath_demo/blog*.ex,scrypath_demo_web/{endpoint,router}.ex}` and migrations — real data and request boundaries.
- [VERIFIED: phase context] `145-CONTEXT.md`, Phase 144 artifacts, roadmap, requirements, advisory triage, README, CONTRIBUTING, and CI workflow — locked scope, target ranges, proof taxonomy, and gate order.
- [VERIFIED: Hex registry via `mix hex.info`] Phoenix, Bandit, Ecto SQL, and Postgrex selected fixed-line publication evidence.
- [VERIFIED: Hex registry API, 2026-08-22] `https://hex.pm/api/packages/{plug,phoenix,bandit}/releases/{version}` and `https://hex.pm/api/packages/plug` — published Plug requirements, release metadata, and the current affected-version ranges.
- [VERIFIED: detached Mix resolution, 2026-08-22] Exact-SHA disposable probes of `e50fbd5694c75ff5f25c2a07046185f35c107dd9` — unbounded Plug `1.20.3` and direct-`~> 1.19.5` Plug `1.19.5` both compile and pass unsuppressed `mix hex.audit`; only the latter satisfies D-05.

### Secondary (MEDIUM confidence)

- [CITED: https://elixir.hexdocs.pm/Version.html] — pessimistic requirement semantics.
- [CITED: https://hex.pm/packages/ecto_sql/dependencies] and [CITED: https://hex.pm/packages/ecto/dependencies] — Ecto SQL/Ecto ownership of Ecto 3.14 and Decimal 3.
- [CITED: https://hex.pm/packages/postgrex/dependencies] — Postgrex Decimal 3 compatibility.
- [CITED: https://ecto-sql.hexdocs.pm/Ecto.Adapters.SQL.Sandbox.html] — owner lifecycle, shared mode, allowances, and cleanup hazards.
- [CITED: https://phoenix.hexdocs.pm/testing.html] and [CITED: https://phoenix.hexdocs.pm/testing_controllers.html] — generated ConnCase and focused endpoint-test conventions.
- [CITED: https://bandit.hexdocs.pm/Bandit.PhoenixAdapter.html] and [CITED: https://bandit.hexdocs.pm/Bandit.Telemetry.html] — adapter/listener and telemetry-span contracts.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — locked phase bounds, current registry checks, official dependency metadata, and current manifest/lock agree.
- Architecture: HIGH — codebase supplies the exact schemas, endpoint, generated support, smoke lane, and configured adapter.
- Pitfalls: HIGH — constraints enumerate stop conditions and official Sandbox/Bandit documentation corroborates the operational hazards.

**Research date:** 2026-08-22 (execution-recovery addendum added 2026-08-22)
**Valid until:** 2026-08-29 (fast-moving advisory and package-resolution domain)
