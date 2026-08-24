# Phase 146: ScrypathOps Web/Client Remediation - Context

**Gathered:** 2026-08-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 146 independently remediates the `scrypath_ops` Mix graph across its
Phoenix, LiveView, Bandit, Swoosh, Req, Postgrex, Plug, Mint, hpax, and causal
transitive resolution; proves that the existing operator application and its
production-selected `Swoosh.ApiClient.Req` contract still work; and produces
truthful deterministic and fresh-resolution security evidence.

This is a maintenance-only dependency batch. It adds no product capability,
public Scrypath API, Ops route or screen, mail provider, database schema,
permanent CI/security subsystem, browser lane, or broad framework modernization.
The deliverable is one isolated, explained ScrypathOps remediation commit after
the completed shared Req-floor and legacy-example batches. Ecommerce and
all-four-graph closure evidence remain Phase 147 work.

</domain>

<decisions>
## Implementation Decisions

### 1. Fixed-compatible manifest bounds and dependency ownership

- **D-01:** Express the direct remediation cohort as Phoenix `~> 1.8.9`,
  Phoenix LiveView `~> 1.1.33`, Bandit `~> 1.12.1`, Swoosh `~> 1.26.3`, and
  Postgrex `~> 0.22.4`. Retain the Phase 144 Req requirement `~> 0.6.1`.
  These three-part pessimistic requirements admit reviewed patches in the
  chosen minor line while excluding the next minor line and avoiding package-head
  modernization.
- **D-02:** The Postgrex publication guard currently permits `0.22.4`. On
  2026-08-24, the live Hex registry identifies stable, unretired `0.22.4` as
  Postgrex's latest stable release, and the live EEF CNA record identifies
  versions from `0.19.3` before `0.22.4` as affected by CVE-2026-66838. Planning
  and execution must re-check both authorities; missing or contradictory evidence
  stops the batch rather than selecting a prerelease, invented substitute, or
  vulnerable fallback.
- **D-03:** Keep Plug, Mint, hpax, Finch, Ecto, and Decimal transitive. Do not add
  direct requirements or `override: true` for them. Leave `phoenix_ecto`,
  `ecto_sql`, and unrelated direct requirements unchanged unless the resolver or
  a focused compatibility failure demonstrates a causal need.
- **D-04:** Refresh only the causal solver closure required by the approved
  direct floors and the already-landed Req 0.6 handoff. Every moved lock row must
  be explained; unrelated cleanup and current-package-head churn are out of scope.
- **D-05:** A detached lockless probe at the exact candidate commit must resolve
  Phoenix `>= 1.8.9 and < 1.9.0`, Phoenix LiveView
  `>= 1.1.33 and < 1.2.0`, Bandit `>= 1.12.1 and < 1.13.0`, Swoosh
  `>= 1.26.3 and < 1.27.0`, Postgrex `>= 0.22.4 and < 0.23.0`, Req
  `>= 0.6.1 and < 0.7.0`, Plug `>= 1.19.5 and < 2.0.0`, Mint
  `>= 1.9.3`, and hpax `>= 1.0.4`.

#### Execution-discovery amendment — D-05 Plug range (2026-08-24)

Plan 146-03's first exact-SHA detached, lockless probe selected Plug `1.20.3`.
The former D-05 upper bound of `< 1.20.0` was not enforceable while D-03 keeps
Plug transitive and forbids a direct requirement or override. The Plug portion
of D-05 is therefore corrected only to `>= 1.19.5 and < 2.0.0`; the other eight
fresh-resolution ranges and every other decision remain unchanged. This is a
consistency correction for the solver-owned transitive dependency, not broader
dependency modernization. The reviewed primary lock remains deterministically
at Plug `1.19.5`; fresh proof may select Plug `1.20.3` or another compatible
transitive 1.x release only when it is unretired and the mandatory unsuppressed
`mix hex.audit` exits zero. On 2026-08-24, Hex listed Plug `1.20.3` as current,
unretired, and published 2026-07-09, while Plug's official supported-versions
policy listed v1.20 for bug fixes and v1.19 for security patches only.

### 2. Production-shaped Swoosh/Req compatibility proof

- **D-06:** Add a focused, service-free contract around the real
  `Swoosh.ApiClient.Req` using `Req.Test` or the equivalent supported Req test
  seam. Exercise the production-selected client module directly; do not send to
  a real provider, require credentials/network, or invent a fake production
  adapter.
- **D-07:** Prove the contract Swoosh adapters depend on: client initialization;
  POST URL, body, headers, and Swoosh user-agent forwarding; caller
  `email.private[:client_options]` forwarding; Swoosh-owned precedence for
  `headers`, `body`, and `decode_body: false`; raw response-body preservation;
  `{:ok, status, headers, body}` normalization; and Req transport-error
  propagation.
- **D-08:** Preserve the normal test posture of `Swoosh.Adapters.Test` with
  `config :swoosh, :api_client, false`. Scope temporary application configuration
  narrowly and restore it, or call the real API-client module directly. Do not
  globally make the existing suite behave like production.
- **D-09:** Keep `ScrypathOps.Mailer` and the production selection
  `config :swoosh, api_client: Swoosh.ApiClient.Req` unchanged. This phase proves
  that configuration; it does not choose a deployment-specific mail adapter or
  broaden ScrypathOps' mail contract.

### 3. Web, LiveView, and database compatibility proof

- **D-10:** Treat root `mix verify.opsui` as the binding ScrypathOps application
  gate. It fetches the standalone Ops graph and runs the existing Postgres-backed
  test alias, complete ExUnit suite, and Ops accessibility contract. This existing
  suite owns Phoenix routing, LiveView mount/event/render behavior, application
  boot, Ecto migrations/Repo behavior, operator contracts, and UI invariants.
- **D-11:** Fixed package selection plus an unsuppressed advisory audit proves
  remediation of the recorded upstream vulnerabilities. Do not duplicate upstream
  fragmented-WebSocket, redirect-validation, HTTP parser, or Postgrex exploit
  tests, and do not create a permanent real-browser or protocol lane. Add only
  causal focused coverage if the approved upgrades expose a repository-owned
  behavior gap.
- **D-12:** Do not claim ecommerce mounted-browser proof in Phase 146. Existing
  Ops route/LiveView/component tests are required application proof; Phase 147
  owns mounted ecommerce behavior and all-graph closure evidence.
- **D-13:** A source compatibility fix is allowed only when compile/test failure
  demonstrates the need. Keep it to the smallest ScrypathOps-internal change with
  focused regression coverage and unchanged public Scrypath APIs, Ops routes/UI,
  mail configuration semantics, database schema, and operational behavior.

### 4. Gate order, evidence, commit boundary, and stops

- **D-14:** The binding deterministic order is: inspect and explain the Ops
  manifest/lock diff; run Ops `mix deps.get --check-locked` and compile with
  warnings as errors; run root `mix verify.opsui`; then run the command equivalents
  for the named root `main-ci`, `repo-hygiene`, `release-truth`, and
  `phase99-trust` gates from `CONTRIBUTING.md`.
- **D-15:** After deterministic proof is green, use a disposable detached
  worktree at the exact candidate commit, isolate dependency/build directories,
  remove only the disposable ScrypathOps lock, perform a fresh resolution, record
  the D-05 target versions, and run an unsuppressed ScrypathOps `mix hex.audit`.
  Never delete or rewrite the primary workspace lock for fresh proof.
- **D-16:** A registry, network, or advisory-feed outage is unavailable evidence,
  never a pass. An out-of-range resolution, non-zero audit, loss of the stable
  Postgrex dual-source evidence, dirty primary lock, unexplained lock row, Swoosh
  contract failure, or any required Ops/root gate failure stops Phase 147 handoff.
- **D-17:** Keep evidence compact and auditable: candidate SHA, UTC timestamp,
  environment/tool versions, commands and exit statuses, target package versions,
  audit result, causal lock rows, and deterministic-versus-network classification.
  Do not commit raw logs, disposable locks, advisory snapshots, dependency trees,
  provider credentials, or generated service artifacts.
- **D-18:** Keep the ScrypathOps manifest, lock, focused Swoosh contract, and any
  unavoidable causal compatibility fix in one isolated third remediation commit.
  Do not include ecommerce files or unrelated upgrades.
- **D-19:** Stop and re-plan if remediation would require public Scrypath API or
  configuration changes, a new route/screen/socket, a database migration, UI
  behavior or brand changes, a mail-provider decision, a permanent CI/security
  abstraction, advisory suppression, or dependency modernization beyond the
  recorded fixed-compatible cohort.

### 5. Maintainer experience and quality lenses

- **D-20:** Primary maintainer job: remove the independently resolved Ops graph's
  recorded advisories in one understandable batch and know whether dependency
  resolution, Phoenix/LiveView behavior, Postgres-backed operation, or the
  production-selected Swoosh Req client regressed.
- **D-21:** Contributors keep familiar Mix/Phoenix interfaces: a reviewed lock,
  `mix verify.opsui`, the named root gates, and standard Mix/Hex evidence. Do not
  create a new dependency policy language or testing subsystem.
- **D-22:** The governing quality pillars are security, correctness,
  compatibility, reproducibility, maintainability, operability, resilience,
  evidence clarity, least surprise, contributor/adopter DX, bounded CI cost, and
  strict scope discipline. Visual design, accessibility styling changes, motion,
  microcopy, and brand expression are not applicable because this phase changes
  no UI.

### the agent's Discretion

- Exact focused Swoosh contract filename and whether temporary API-client
  configuration is used are left to research/planning, provided isolation and
  cleanup are deterministic.
- Exact targeted `mix deps.update` command(s) may vary; the approved manifest
  strings, target ranges, causal lock diff, and no-override rule are binding.
- Exact ordering of individual root gate commands may follow `CONTRIBUTING.md`
  where dependencies permit, but every named required gate must pass before the
  phase commit/handoff.

### Folded Todos

- **Remediate reproduced dependency security advisories** — fold the todo's
  ScrypathOps slice into Phase 146: bound and resolve its web, LiveView, mailer,
  HTTP, database, and causal transitive graph; prove the configured Swoosh Req
  path and Ops behavior; and pass deterministic plus fresh-resolution audit
  evidence. The ecommerce and all-four-graph closure portions remain Phase 147,
  so the todo stays open until that phase closes them.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope, ordering, and advisory authority

- `.planning/ROADMAP.md` — Phase 146 goal, dependency order, success criteria,
  stable-only Postgrex rule, and isolated third-commit boundary.
- `.planning/REQUIREMENTS.md` — SEC-03, EVID-03, milestone exclusions, and phase
  traceability.
- `.planning/PROJECT.md` — maintenance-only milestone, fixed-compatible policy,
  green-main posture, and public-scope exclusions.
- `.planning/STATE.md` — completed Phase 145 handoff and current Phase 146 position.
- `.planning/phases/144-root-http-client-dependency-remediation/144-CONTEXT.md`
  — shared Req 0.6 floor, Swoosh handoff, proof taxonomy, and compatibility-fix policy.
- `.planning/phases/145-legacy-phoenix-and-ecto-decimal-remediation/145-CONTEXT.md`
  — immediately preceding graph-local dependency/proof conventions and Phase 146 handoff.
- `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-SCOPE-GUARD.md`
  — authority preventing public/runtime capability expansion.
- `.planning/todos/pending/2026-08-16-remediate-dependency-security-advisories.md`
  — four-batch intake, exact recorded fixed minima, required gates, and stop policy.
- `.planning/quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-RESEARCH.md`
  — reproduced advisory exposure, independent graph inventory, minima, and Ops risk.
- `.planning/quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-ADVISORY-TRIAGE.md`
  — dated package/advisory ledger and unresolved Swoosh/Postgrex reachability questions.

### ScrypathOps dependency and runtime surfaces

- `scrypath_ops/AGENTS.md` — local Phoenix 1.8, Req, Mix, and test conventions.
- `scrypath_ops/mix.exs` — direct requirements, standalone test alias, precommit,
  and current fixed Req floor.
- `scrypath_ops/mix.lock` — independent deterministic Ops resolution and causal
  lock-diff surface.
- `scrypath_ops/config/config.exs` — endpoint/Bandit and default mailer configuration.
- `scrypath_ops/config/prod.exs` — production `Swoosh.ApiClient.Req` selection.
- `scrypath_ops/config/test.exs` — Postgres Sandbox, server-disabled endpoint,
  Swoosh test adapter, and disabled API-client baseline.
- `scrypath_ops/config/runtime.exs` — deployment-time endpoint and mail-adapter guidance.
- `scrypath_ops/lib/scrypath_ops/mailer.ex` — actual Swoosh mailer boundary.
- `scrypath_ops/lib/scrypath_ops/application.ex` — application supervision and
  standalone endpoint/Repo boot boundary.
- `scrypath_ops/lib/scrypath_ops_web/endpoint.ex` — Bandit/Phoenix endpoint under test.
- `scrypath_ops/lib/scrypath_ops_web/router.ex` — current LiveView route surface;
  no route should be added for dependency proof.

### Existing proof and release policy

- `lib/mix/tasks/verify.opsui.ex` — canonical root-to-Ops standalone graph/test gate.
- `CONTRIBUTING.md` — exact required root gates, Ops path-gate contract, and
  hard-versus-advisory evidence policy.
- `.github/workflows/ci.yml` — Postgres service topology and Ops/root job wiring.
- `scrypath_ops/test/scrypath_ops/application_test.exs` — application boot baseline.
- `scrypath_ops/test/scrypath_ops/config_prod_guard_test.exs` — production config guard pattern.
- `scrypath_ops/test/support/data_case.ex` — existing SQL Sandbox ownership boundary.
- `scrypath_ops/test/scrypath_ops_web/router_test.exs` — mounted route baseline.
- `scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs` — representative
  LiveView behavior pattern; the other existing LiveView modules remain part of the full gate.

### Local expert research

- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — sane
  dependency bounds, host resolution, stable contracts, and least-surprise OSS DX.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — deterministic
  CI, Hex audit, compatibility proof, release safety, and bounded required gates.
- `prompts/phoenix-live-view-best-practices-deep-research.md` — LiveView process,
  test, redirect, and application-boundary guidance.
- `prompts/phoenix-best-practices-deep-research.md` — Phoenix-native endpoint,
  config, testing, and release conventions.
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md`
  — Phoenix/Bandit/LiveView/Postgres operational and security boundaries.

### Live upstream authorities verified during discussion

- `https://hex.pm/api/packages/postgrex` — on 2026-08-24, reports stable,
  unretired Postgrex `0.22.4` as the latest stable release.
- `https://cna.erlef.org/cves/CVE-2026-66838.json` — EEF CNA authority identifying
  Postgrex `0.19.3` through versions before `0.22.4` as affected.
- `https://hex.pm/api/packages/swoosh` — package registry evidence that fixed
  Swoosh `1.26.3` is published and unretired; newer minor lines exist but are not
  selected for this bounded remediation.
- `https://hexdocs.pm/swoosh/Swoosh.ApiClient.Req.html` — public Req client
  configuration and option-forwarding contract to verify during planning.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Mix.Tasks.Verify.Opsui`: already reproduces the required standalone Ops flow
  from the root with CI-shaped dependency fetching and the complete test alias.
- ScrypathOps `test`/`verify.opsui` aliases: already create and migrate Postgres,
  run the full ExUnit suite, validate navigation, and run the accessibility contract.
- Existing Application, router, LiveView, Repo/DataCase, security, and production
  config guard tests provide broad regression coverage without new infrastructure.
- `Req.Test`: already available through direct Req and is the narrow service-free
  seam for the missing real `Swoosh.ApiClient.Req` wire/error contract.

### Established Patterns

- Root, legacy example, ScrypathOps, and ecommerce are separate Mix projects with
  separate locks. Phase 144 already aligned ScrypathOps to Req `0.6.3`, Mint
  `1.9.3`, and hpax `1.0.4`; Phase 146 must preserve that fixed HTTP closure while
  moving only the remaining Ops web/mailer/database rows.
- Production selects `Swoosh.ApiClient.Req`; tests deliberately select
  `Swoosh.Adapters.Test` and disable the API client. The missing proof should be
  focused and production-shaped without changing the suite-wide test posture.
- The current Ops lock already resolves Ecto/Ecto SQL `3.14.0`; no Ecto/Decimal
  advisory or direct-ownership change belongs in this batch.
- Required service-free gates and network-dependent fresh/audit evidence are
  reported separately. Unavailable external evidence is never recorded as passing.
- Tracked locks provide contributor/CI reproducibility, while fresh detached
  resolution proves the manifest contract independently of the reviewed lock.

### Integration Points

- Dependency edits: `scrypath_ops/mix.exs` and `scrypath_ops/mix.lock` only.
- Missing causal proof: a focused test of the real `Swoosh.ApiClient.Req` contract.
- Existing application proof: `mix verify.opsui` plus the named root release gates.
- Fresh proof: disposable exact-commit worktree and isolated lockless ScrypathOps resolution.
- Downstream handoff: Phase 147 consumes the green root, legacy, and Ops sources
  for ecommerce remediation and final four-graph evidence.

</code_context>

<specifics>
## Specific Ideas

- Auto mode selected the recommended bounded option for every gray area. The key
  principle is to prove repository-owned behavior at stable seams, while relying
  on fixed version selection and unsuppressed audit—not brittle exploit copies—to
  establish upstream advisory remediation.
- The focused Swoosh contract should read like an adapter compatibility test: what
  request Swoosh handed Req, what Req returned, and what tuple Swoosh exposed.
- The evidence summary should read like an audit record, not terminal output: exact
  candidate, versions, causal diff, gates, audit, evidence class, and stop result.
- Live registry evidence shows Swoosh `1.28.0` exists, but this phase deliberately
  stays on the reviewed `1.26.x` fixed line to preserve causal review scope.

</specifics>

<deferred>
## Deferred Ideas

- Phase 147 retains ecommerce web/client remediation, mounted Ops/browser evidence,
  final all-four-graph audit evidence, ordered-commit closure, and todo completion.
- Any permanent dependency automation, new security CI lane, or broader package
  modernization remains future work requiring separately approved evidence.

</deferred>

---

*Phase: 146-scrypathops-web-client-remediation*
*Context gathered: 2026-08-24*
