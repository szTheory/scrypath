# Phase 145: Legacy Phoenix and Ecto/Decimal Remediation - Context

**Gathered:** 2026-08-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 145 remediates the recorded dependency advisories in the independent
`examples/phoenix_meilisearch` Mix graph. It coordinates fixed-compatible
Phoenix, Bandit, Plug, Ecto, Ecto SQL, Postgrex, Decimal, and inherited HTTP
client versions while preserving the example's existing Phoenix endpoint,
Postgres data model, migrations, changesets, and documented Scrypath integration
journey.

This is a maintenance-only dependency batch. It does not add a product feature,
public Scrypath API, application route, socket, database field, search behavior,
new synchronization mode, permanent CI lane, dependency abstraction, or broad
framework modernization. The deliverable is one isolated, explained legacy-graph
implementation commit after Phase 144's shared Req-floor handoff, followed by
causal compatibility proof and truthful fresh-resolution/advisory evidence.

</domain>

<decisions>
## Implementation Decisions

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

### Folded Todos

- **Remediate reproduced dependency security advisories** — fold the todo's
  legacy Phoenix/Ecto/Decimal slice into Phase 145: resolve the recorded
  Phoenix/Bandit/Plug/Postgrex/Decimal and inherited HTTP advisories through the
  coordinated fixed-compatible cohort and pass its causal gates. The todo remains
  open through the ScrypathOps, ecommerce, and all-graph closure work in Phases
  146-147.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and advisory authority

- `.planning/ROADMAP.md` — Phase 145 goal, dependency ordering, isolated-commit
  boundary, and four success criteria.
- `.planning/REQUIREMENTS.md` — SEC-02 and the v1.36 phase traceability contract.
- `.planning/PROJECT.md` — maintenance-only milestone, fixed-compatible policy,
  green-main posture, and public-scope exclusions.
- `.planning/STATE.md` — Phase 144 completion and Phase 145 current position.
- `.planning/phases/144-root-http-client-dependency-remediation/144-CONTEXT.md`
  — shared Req-floor handoff, proof taxonomy, compatibility-fix policy, and the
  graph-local Phase 145 boundary.
- `.planning/todos/pending/2026-08-16-remediate-dependency-security-advisories.md`
  — ordered four-batch intake, recorded target versions, and acceptance gates.
- `.planning/quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-RESEARCH.md`
  — reproduced advisory evidence, exposure analysis, and fixed minima.
- `.planning/quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-ADVISORY-TRIAGE.md`
  — advisory ledger, legacy high-regression-risk classification, and gate table.
- `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-SCOPE-GUARD.md`
  — authority preventing unrelated public/runtime capability expansion.

### Legacy dependency graph and contributor contract

- `examples/phoenix_meilisearch/AGENTS.md` — local Phoenix 1.8, Ecto, test, Mix,
  and `mix precommit` instructions.
- `examples/phoenix_meilisearch/mix.exs` — direct dependency requirements,
  clean-database test alias, setup/reset aliases, and precommit gate.
- `examples/phoenix_meilisearch/mix.lock` — independent deterministic legacy
  resolution and causal diff surface.
- `examples/phoenix_meilisearch/README.md` — canonical local/CI service
  prerequisites, commands, hard-versus-live behavior, and contributor journey.
- `CONTRIBUTING.md` — repository gates, Phoenix example integration contract,
  and required/advisory proof policy.
- `.github/workflows/ci.yml` — Postgres/Meilisearch service topology and exact
  `phoenix-example-integration` command path.

### Database and example behavior

- `examples/phoenix_meilisearch/config/test.exs` — Postgres Sandbox, endpoint
  `server: false`, and inline Oban test configuration.
- `examples/phoenix_meilisearch/test/test_helper.exs` — explicit integration-tag
  opt-in and Sandbox mode.
- `examples/phoenix_meilisearch/test/support/data_case.ex` — generated
  `start_owner!` SQL Sandbox boundary to reuse.
- `examples/phoenix_meilisearch/test/support/conn_case.ex` — generated endpoint
  test boundary and Sandbox integration.
- `examples/phoenix_meilisearch/lib/scrypath_demo/blog/post.ex` — searchable
  schema and existing changeset/cast contract.
- `examples/phoenix_meilisearch/lib/scrypath_demo/blog/author.ex` — related-data
  schema and existing changeset contract.
- `examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex` — Repo/context and
  search-synchronization boundary.
- `examples/phoenix_meilisearch/priv/repo/migrations/20250418120000_create_posts.exs`
  — original Posts migration.
- `examples/phoenix_meilisearch/priv/repo/migrations/20250419000000_add_oban_jobs.exs`
  — Oban migration path.
- `examples/phoenix_meilisearch/priv/repo/migrations/20250420000000_add_authors_and_post_author_fields.exs`
  — Author/Post relationship migration.
- `examples/phoenix_meilisearch/priv/repo/seeds.exs` — current empty seed posture;
  do not invent Phase 145 seed data.

### Endpoint and live proof surfaces

- `examples/phoenix_meilisearch/lib/scrypath_demo_web/endpoint.ex` — Plug.Static,
  RequestId, Telemetry, Parsers, Session, and router pipeline under test.
- `examples/phoenix_meilisearch/lib/scrypath_demo_web/router.ex` — current route
  boundary; no synthetic route may be added for proof.
- `examples/phoenix_meilisearch/test/scrypath_demo_web/controllers/error_json_test.exs`
  — existing error-rendering baseline.
- `examples/phoenix_meilisearch/test/smoke/meilisearch_stack_test.exs` — live
  Postgres/Meilisearch inline reference flow.
- `examples/phoenix_meilisearch/test/smoke/meilisearch_oban_stack_test.exs` —
  live Postgres/Meilisearch inline-Oban reference flow.
- `examples/phoenix_meilisearch/test/smoke/meilisearch_related_inline_stack_test.exs`
  — live related-data inline fan-out proof.
- `examples/phoenix_meilisearch/test/smoke/meilisearch_related_oban_stack_test.exs`
  — live related-data Oban fan-out proof.
- `examples/phoenix_meilisearch/scripts/smoke.sh` — local service orchestration,
  health checks, cleanup, and CI-shaped environment defaults.

### Local expert research

- `prompts/ecto-best-practices-deep-research.md` — schemas/changesets, real-DB
  testing, migrations, SQL Sandbox, and database correctness guidance.
- `prompts/elixir-best-practices-deep-research.md` — idiomatic Elixir, testing,
  error, dependency, and maintainability guidance.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — sane
  dependency bounds, host-resolution behavior, Phoenix-friendly library DX, and
  least-surprise public contracts.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — deterministic
  gates, security auditing, evidence, and lean required-CI guidance.
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md`
  — Phoenix/Bandit/Ecto operational boundaries, security, telemetry, and SRE
  considerations.
- `prompts/phoenix-best-practices-deep-research.md` — generated Phoenix testing
  patterns, contexts, endpoint boundaries, and framework-native correctness.
- `prompts/elixir-search-lib-deep-research.md` — layered unit/database/real-engine
  proof and explicit operational boundaries.
- `prompts/search-lib-use-cases-deep-research.md` — Searchkick/Scout DX lessons,
  explicit operations, and representative Phoenix/Ecto adopter journeys.

### Primary upstream references verified during discussion

- `https://hexdocs.pm/elixir/Version.html` — three-part pessimistic requirement
  semantics used for bounded minor cohorts.
- `https://hex.pm/packages/ecto_sql/dependencies` — Ecto SQL 3.14 dependency on
  Ecto `~> 3.14.0` and Decimal `~> 3.0`.
- `https://hex.pm/packages/ecto/dependencies` — Ecto's ownership of Decimal 3.
- `https://hex.pm/packages/postgrex/dependencies` — Postgrex compatibility with
  Decimal 3.
- `https://ecto-sql.hexdocs.pm/Ecto.Adapters.SQL.Sandbox.html` — current
  `start_owner!`/`stop_owner` testing pattern.
- `https://phoenix.hexdocs.pm/testing.html` and
  `https://phoenix.hexdocs.pm/testing_controllers.html` — generated DataCase,
  ConnCase, fixture, and endpoint-test conventions.
- `https://bandit.hexdocs.pm/Bandit.PhoenixAdapter.html` — Phoenix adapter,
  standard endpoint configuration, and bound-server introspection.
- `https://bandit.hexdocs.pm/Bandit.Telemetry.html` — request span contract.
- `https://plug.hexdocs.pm/Plug.Parsers.html` and
  `https://plug.hexdocs.pm/Plug.Session.html` — endpoint parser and cookie-session
  behavior relevant to the focused request proof.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- The legacy `mix test` alias already creates and migrates the Postgres test DB;
  extend its ExUnit suite rather than inventing a new database harness.
- Generated `DataCase` and `ConnCase` already use the correct Repo, endpoint,
  verified routes, and SQL Sandbox owner lifecycle.
- The existing Post and Author schemas, three migrations, context functions, and
  live smoke fixtures provide representative data without a new domain field.
- `Bandit.PhoenixAdapter.server_info/2` and Bandit's documented telemetry allow a
  small network-bound proof without an external test-server dependency.
- The four existing integration smoke modules and `scripts/smoke.sh` already
  cover the real-service Scrypath journey; reuse them as supplemental evidence.

### Established Patterns

- Root, legacy, ScrypathOps, and ecommerce are independent Mix graphs with
  separate locks; Phase 144 aligned the shared Req floor before graph-local work.
- Required deterministic proof and service-dependent live proof are reported
  separately. Missing external prerequisites never become a pass.
- Phoenix-generated DataCase/ConnCase patterns are the least-surprise testing
  surface. The endpoint has `server: false` in tests, so current ConnCase tests do
  not prove a Bandit listener.
- The example is API-only and currently has no application route, active socket,
  Decimal field, or seed dataset. Dependency proof must not manufacture these.
- The repository prefers lean required gates and compact committed evidence over
  new permanent CI topology or raw generated artifacts.

### Integration Points

- Dependency edits are confined to `examples/phoenix_meilisearch/mix.exs` and
  `examples/phoenix_meilisearch/mix.lock` plus only unavoidable focused tests or
  compatibility fixes.
- Database proof connects through the existing test alias, Repo, migrations,
  DataCase, Post, and Author.
- Endpoint proof connects through ConnCase, `ScrypathDemoWeb.Endpoint`, the
  router/error boundary, and Bandit adapter telemetry.
- Supplemental proof connects through the existing README/runbook,
  `scripts/smoke.sh`, smoke modules, and `phoenix-example-integration` CI job.
- Root regression remains the existing fast ExUnit command; Phase 146 retains
  ScrypathOps/Swoosh work and Phase 147 retains ecommerce/all-graph closure.

</code_context>

<specifics>
## Specific Ideas

- Three typed advisor-researcher passes independently compared manifest,
  database, and endpoint approaches. All converged on bounded dependency cohorts,
  causal Postgres/ConnCase proof, one small real-Bandit boundary check, and a
  separately reported live search lane.
- Apply the successful peer pattern seen in Phoenix generators, Searchkick,
  Laravel Scout, Rails, Django, Bundler, and Composer: declare direct ownership,
  lock exact application resolutions, test representative application behavior,
  and keep real-service proof layered rather than making one giant smoke test the
  only source of confidence.
- Avoid the peer footguns: exact manifest pins that block patch fixes, broad
  modernization batches, direct transitive dependencies, artificial schema
  fields, callback-heavy hidden behavior, service-only test feedback, and claims
  broader than the exercised protocol.
- The intended maintainer flow is: bound -> resolve -> migrate -> cast -> persist
  -> request -> audit -> optionally exercise the live stack.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within the Phase 145 maintenance boundary. Protocol-
specific WebSocket or HTTP/2 tests belong to a future phase only if the example
later mounts sockets or explicitly promises those behaviors.

</deferred>

---

*Phase: 145-legacy-phoenix-and-ecto-decimal-remediation*
*Context gathered: 2026-08-22*
