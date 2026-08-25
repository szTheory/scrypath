# Phase 144: Root HTTP Client Dependency Remediation - Context

**Gathered:** 2026-08-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 144 establishes the patched Req 0.6 dependency floor that the root library and
its three checked-in path consumers must share, remediates the root Req/Mint/hpax/Plug
advisories, and proves that Scrypath's existing Req-backed Meilisearch contract remains
stable. It is a maintenance-only dependency transition: no product capability, public
API, search behavior, adapter breadth, Phoenix UI, or permanent security infrastructure
is added.

The approved roadmap's literal root-only intermediate state is not resolvable: root,
ScrypathOps, and ecommerce currently declare incompatible direct Req 0.5 constraints
once root moves to Req 0.6, while the legacy example's independent lock becomes stale
through its root path dependency. Planning MUST first reconcile the roadmap/requirement
delivery wording so the shared Req-floor handoff is atomic and later framework/database
remediations remain graph-local.

</domain>

<decisions>
## Implementation Decisions

### 1. Cross-graph Req-floor handoff

- **D-01:** Phase 144 is an atomic shared Req-floor handoff across all four independent
  Mix graphs, not a root-only dependency edit. Update the direct Req requirements in
  root Scrypath, ScrypathOps, and ecommerce together; align the root, legacy example,
  ScrypathOps, and ecommerce locks in the same valid intermediate state. —
  **Reversibility:** costly — undoing it would reopen the recorded Req advisory floor
  and reintroduce mutually incompatible path-consumer requirements.
- **D-02:** Before execution, correct `.planning/ROADMAP.md` Phase 144 success criterion
  4 and `.planning/REQUIREMENTS.md` EVID-02 delivery wording. The truthful boundary is
  one minimal, explained cross-graph Req compatibility handoff followed by graph-local
  commits for the remaining legacy, Ops, and ecommerce advisories.
- **D-03:** Use `~> 0.6.1` for each direct Req requirement. This enforces the fixed 0.6
  floor while allowing later compatible 0.6 patch releases and excluding Req 0.7.
- **D-04:** Change the root test-only Plug requirement from the broad `~> 1.18` range
  to `~> 1.19.5`, keeping the root remediation on the recorded fixed 1.19 line rather
  than allowing a fresh resolution to select Plug 1.20 package-head.
- **D-05:** Refresh only the required Req dependency closure in all four lockfiles.
  Req, Finch, Mint, hpax, and unavoidable solver rows must be explained; root Plug is
  also in scope. Do not add direct Mint/hpax constraints, `override: true`, advisory
  ignores, or unrelated upgrades.
- **D-06:** The legacy example needs no direct Req declaration. Its lock moves only
  because the root path dependency changes. Later phases retain ownership of Phoenix,
  Bandit, Ecto/Decimal, Postgrex, LiveView, Swoosh, and other graph-local remediation.

### 2. Req 0.6 compatibility proof

- **D-07:** Keep Scrypath's public transport contract unchanged: successful decoded
  JSON returns, `{:error, {:http_error, status, body}}`,
  `{:error, {:transport_error, exception}}`, caller `req_options`, API-key header
  behavior, and request telemetry retain their existing meanings.
- **D-08:** Use the existing `Req.Test` seam and add only causal gap coverage. At minimum,
  prove transport-error normalization with retries disabled, caller option/header merge
  with the default API-key header, unique task-filter query encoding, and error telemetry
  without sensitive headers or bodies. Reuse existing success, JSON body, HTTP-error,
  sync, multi-search, facet-search, and success-telemetry tests rather than duplicating
  every wrapper.
- **D-09:** Req 0.6's removed archive decoding, Req 0.6.1's opt-in HTTP decompression,
  and multipart escaping are upstream security changes. Scrypath's normal transport is
  JSON-only. Do not proactively opt into compression, add multipart behavior, or change
  request defaults unless a focused failure proves a real compatibility need.
- **D-10:** The root deterministic gate bundle is binding: fresh dependency fetch,
  compile with warnings as errors, fast tests, `mix verify --exclude integration`,
  `mix verify.phase11`, and `mix verify.phase99`. Run the existing live Meilisearch smoke
  when its service prerequisites are available and report it separately as supplemental
  evidence; do not create a new required lane.
- **D-11:** Phase 144 does not claim Swoosh runtime proof. Root has no Swoosh dependency,
  while `Swoosh.ApiClient.Req` is configured in ScrypathOps production. Phase 146 owns a
  focused service-free Swoosh Req-client contract alongside `mix verify.opsui` and the
  Ops dependency remediation.

### 3. Fresh-resolution and advisory evidence

- **D-12:** Maintain two explicit proof classes. Deterministic proof is the reviewed
  manifest/lock diff, `mix deps.get --check-locked` in every touched graph, clean
  workspace, and required behavior gates. Network-dependent proof is a lockless fresh
  resolution and `mix hex.audit` against the current Hex registry/advisory feed.
- **D-13:** Produce the root fresh-resolution proof from a disposable detached worktree
  at the exact candidate commit SHA. Remove only the disposable root lock, isolate its
  dependency/build directories, run a fresh root `mix deps.get`, and record the selected
  Req, Mint, hpax, and Plug versions plus dependency paths.
- **D-14:** The root fresh probe must select Req `>= 0.6.1` and `< 0.7.0`, Plug
  `>= 1.19.5` and `< 1.20.0`, Mint `>= 1.9.3`, and hpax `>= 1.0.4`. Root
  `mix hex.audit` must exit zero with no advisory suppression. All-four clean advisory
  proof remains Phase 147 closure evidence because the later graphs intentionally retain
  other advisories after the shared Req handoff.
- **D-15:** Record only a compact dated result in Phase 144 SUMMARY/VERIFICATION: commit
  SHA, timestamp, OS and Elixir/OTP/Hex versions, commands and exit statuses, four target
  versions, audit result, and deterministic-vs-network classification. Do not commit raw
  command logs, disposable lockfiles, advisory snapshots, or generated dependency trees.
- **D-16:** Add no permanent Mix task, script, CI lane, dependency policy, or security
  abstraction in this milestone. Existing Mix/Hex commands are the maintainer interface.
- **D-17:** A network/registry/advisory-feed outage is proof unavailable, not a pass.
  A fresh resolution below a fixed minimum, a non-zero root audit, a dirty primary lock,
  an unexplained lock row, or any required gate failure blocks Phase 145.

### 4. Compatibility-fix and scope boundary

- **D-18:** A production source change is allowed only when a Req 0.6 compile/test failure
  demonstrates the need. The fix must be the smallest internal change, preserve existing
  public APIs and request/error/telemetry semantics, and include a focused regression test.
- **D-19:** Stop and re-plan if remediation would change public Scrypath APIs,
  configuration defaults, retry/redirect/timeout/decompression semantics, Swoosh adapter
  behavior, database schemas, or require a new transport abstraction, broad refactor, or
  dependency upgrades beyond the recorded fixed-compatible set.
- **D-20:** This phase optimizes the consumer-facing interface, not provider internals.
  An adopter should run normal `mix deps.get`, receive a patched compatible graph, and
  observe no Scrypath API or behavior change. A maintainer should get clean locks, causal
  diffs, familiar Mix commands, and an unambiguous stop condition after every commit.

### Design and engineering lenses

- **D-21:** The governing quality pillars are security, correctness, compatibility,
  least surprise, reproducibility, maintainability, evidence clarity, bounded CI cost,
  and strict scope discipline. Visual UI, accessibility styling, theme behavior, and
  brand expression are not applicable to this dependency-only phase.
- **D-22:** Use the domain language consistently: dependency graphs/manifests/locks and
  fixed floors are the nouns; resolve/compile/test/audit are the events; align/verify/
  explain/stop are the maintainer verbs. Do not expose Req migration details through the
  public Scrypath API or adopter docs unless an actual consumer action is required.

### the agent's Discretion

- Exact test organization may extend `client_test.exs` or use one focused migration
  contract file, whichever produces the smaller, clearer diff without duplicated setup.
- Exact targeted Mix update commands may vary by graph, but the resulting lock diff must
  remain limited to the required Req closure and each moved row must be explained.
- The live Meilisearch command may use the existing smoke task or existing phase-5 path,
  depending on available local services; it remains separately reported supplemental proof.

### Folded Todos

- **Remediate reproduced dependency security advisories** — fold the todo's root/shared
  Req-client slice into Phase 144: raise the secure Req floor, align its necessary
  cross-graph locks, clear root Req/Mint/hpax/Plug findings, and pass the root gates.
  The remaining legacy, Ops, ecommerce, and all-graph closure portions stay assigned to
  Phases 145-147; the todo remains open until Phase 147.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Approved scope and security evidence

- `.planning/ROADMAP.md` — v1.36 order, guardrails, Phase 144 goal, and the delivery wording that must be reconciled before execution.
- `.planning/REQUIREMENTS.md` — SEC-01, COMPAT-02, EVID-02, maintenance exclusions, and phase traceability.
- `.planning/PROJECT.md` — maintenance-only milestone boundary, green-main posture, adopter contract, and public-scope exclusions.
- `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-SCOPE-GUARD.md` — authority preventing runtime/public API scope expansion.
- `.planning/todos/pending/2026-08-16-remediate-dependency-security-advisories.md` — ordered remediation intake, fixed versions, and gate expectations.
- `.planning/quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-RESEARCH.md` — authoritative reproduced advisory research, exposure analysis, fixed minima, and original batch proposal.
- `.planning/quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-ADVISORY-TRIAGE.md` — dated advisory ledger and unresolved reachability questions.

### Dependency graphs and release policy

- `mix.exs` — root public dependency requirements, test-only Plug dependency, aliases, and Hex package file boundary.
- `mix.lock` — current root Req/Mint/hpax/Plug resolution and deterministic contributor graph.
- `scrypath_ops/mix.exs` — root path dependency, direct Req/Swoosh declarations, and Ops test aliases.
- `scrypath_ops/mix.lock` — independent Ops graph requiring shared Req-floor alignment.
- `examples/phoenix_meilisearch/mix.exs` — legacy root path dependency and graph-local framework boundary.
- `examples/phoenix_meilisearch/mix.lock` — independent legacy lock affected by the root Req floor.
- `examples/scrypath_ecommerce/mix.exs` — root and Ops path dependencies plus direct Req/Swoosh declarations.
- `examples/scrypath_ecommerce/mix.lock` — independent ecommerce graph requiring shared Req-floor alignment.
- `CONTRIBUTING.md` — canonical local gates, required/advisory CI distinction, and path-dependent Ops verification.
- `docs/releasing.md` — green-main release train, deterministic package proof, and release evidence policy.
- `.github/workflows/ci.yml` — required root gates, deep-quality audit, Ops path trigger, and independent graph jobs.

### Runtime and proof seams

- `lib/scrypath/meilisearch/client.ex` — sole root Req construction/dispatch/normalization seam and request telemetry boundary.
- `test/scrypath/meilisearch/client_test.exs` — existing GET/POST JSON and HTTP-error Req.Test coverage.
- `test/scrypath/meilisearch/client_multi_search_test.exs` — existing multi-search wire contract.
- `test/scrypath/sync_test.exs` — existing Req.Test-backed sync/task lifecycle coverage.
- `test/scrypath/telemetry_test.exs` — existing successful Meilisearch request span contract.
- `lib/mix/tasks/verify.ex` — deterministic root maturity gate.
- `lib/mix/tasks/verify.phase11.ex` — release/package/consumer/docs proof.
- `lib/mix/tasks/verify.phase99.ex` — trust-lane compatibility and workflow contract proof.

### Local expert research

- `prompts/elixir-best-practices-deep-research.md` — idiomatic tagged errors, HTTP-client boundaries, ExUnit, and library API stability.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — Hex dependency bounds, host lockfile behavior, optional/test dependencies, and consumer DX.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — deterministic CI, compatibility matrices, security gates, and release engineering.
- `prompts/elixir-search-lib-deep-research.md` — layered transport/contract/live testing and explicit operational boundaries.
- `prompts/search-lib-use-cases-deep-research.md` — Searchkick/Scout ecosystem lessons: simple consumer surface, explicit operations, and no hidden transport magic.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Scrypath.Meilisearch.Client`: one private `run_request/5` seam centralizes Req construction,
  response normalization, headers, option pass-through, and Telemetry spans.
- `Req.Test` fixtures already used across client, sync, facet, multi-search, and telemetry tests:
  extend these rather than introducing Mox/Bypass or a public transport abstraction.
- Existing `verify`, `verify.phase11`, `verify.phase99`, `verify.opsui`, and live Meilisearch
  tasks provide the required layered proof without a new workflow.
- Existing package consumer/release checks and temporary-directory patterns can inform the
  disposable exact-commit fresh-resolution probe.

### Established Patterns

- Root, legacy example, ScrypathOps, and ecommerce are separate Mix projects with separate
  locks; path dependencies still participate in each consumer's single-version resolver.
- Root `mix.exs`/`mix.lock` changes trigger the required ScrypathOps path gate, so dependency
  compatibility across checked-in consumers is part of green-main, not optional evidence.
- Scrypath exposes stable tagged error tuples and backend-specific Telemetry metadata while
  keeping Req an internal implementation detail.
- Tracked locks serve contributor/CI reproducibility and bisectability; the root Hex package
  does not ship `mix.lock`, so adopter safety depends on manifest requirements.
- Required service-free gates and service-dependent evidence are reported separately; an
  unavailable external prerequisite is never recorded as a pass.

### Integration Points

- Dependency edits: `mix.exs`, `scrypath_ops/mix.exs`,
  `examples/scrypath_ecommerce/mix.exs`, and all four `mix.lock` files.
- Behavior proof: `lib/scrypath/meilisearch/client.ex` and focused Req.Test/Telemetry tests.
- Delivery-truth prerequisite: Phase 144 roadmap success criterion 4 and EVID-02 wording.
- Later-phase handoff: Phase 146 Swoosh Req-client proof and Phase 147 all-graph advisory closure.

</code_context>

<specifics>
## Specific Ideas

- Four independent advisor passes examined dependency topology, Req/Swoosh behavior,
  evidence design, ecosystem precedent, and the combined recommendation. All rejected the
  written root-only intermediate state as incompatible with the repository's path graphs.
- Official upstream guidance to verify during research/planning includes the Elixir library
  rule that host projects ignore dependency lockfiles, Req 0.6/0.6.1 release notes,
  `Req.Test.transport_error/2`, `mix deps.get --check-locked`, Hex 2.5 advisory-aware
  `mix hex.audit`, and the `Swoosh.ApiClient.Req` option-forwarding contract.
- Successful search integration libraries keep the adopter-facing API small and make
  operational transitions explicit. Apply that lesson here by changing dependency floors
  and tests without exposing transport internals or inventing new configuration.
- The proof summary should read like an audit record, not a pasted terminal transcript:
  what commit was tested, what resolved, which gates passed, which evidence was live, and
  why every lock row moved.

</specifics>

<deferred>
## Deferred Ideas

- Phase 145 retains legacy Phoenix/Bandit/Ecto/Ecto SQL/Decimal/Postgrex remediation after
  the shared Req floor is aligned.
- Phase 146 retains ScrypathOps Phoenix/LiveView/Bandit/Postgrex/Swoosh remediation and adds
  explicit `Swoosh.ApiClient.Req` runtime contract proof.
- Phase 147 retains ecommerce graph-local remediation and consolidated dated no-advisory
  evidence across all four graphs.
- Broader dependency modernization, package-head upgrades, permanent dependency/security
  automation, and advisory policy tooling remain future requirements outside v1.36.

</deferred>

---

*Phase: 144-root-http-client-dependency-remediation*
*Context gathered: 2026-08-21*
