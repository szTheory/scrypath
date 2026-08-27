# Phase 148: Quality Baseline - Context

**Gathered:** 2026-08-26
**Status:** Retrospective context captured — implementation complete

<domain>
## Phase Boundary

Phase 148 establishes the evidence and executable-behavior baseline that makes the
v1.37 quality ratchet safe. It gives maintainers one ranked quality ledger, requires
observable behavior to be characterized before extraction, turns actionable Elixir
test/compile diagnostics into failures, proves that the root library does not require
optional integrations, and makes coverage available as informational evidence.

The primary users are maintainers preparing a refactor, contributors interpreting a
failure, and adopters whose public and operational behavior must remain stable. The
domain vocabulary is: **finding, evidence, contract, characterization, gate, report,
verification, disposition**. The lifecycle verbs are: **record, reproduce, rank,
characterize, extract, verify, retain, exclude, reopen**.

This phase defines baseline semantics and local commands. It does not perform later
extractions, redesign CI topology or branch protection, impose a coverage target, add
new public runtime capability, or touch ScrypathOps presentation/UX. UI, graphic design,
theme, and brand-system decisions are therefore not applicable; the relevant UX is the
maintainer/contributor command-line experience.

This context was gathered after direct implementation. It records the intended contract
and must not be used to reopen completed work unless an implementation/decision mismatch
or new adopter evidence is found.

</domain>

<decisions>
## Implementation Decisions

### Quality ledger lifecycle
- **D-01:** Keep one committed, milestone-scoped Markdown ledger as the canonical ranked
  view. Update stable rows in place and use Git history for chronology. Do not maintain a
  second spreadsheet, issue-only ledger, or duplicated status document.
- **D-02:** Use the lifecycle `candidate -> evidence-qualified -> planned -> implemented ->
  verified -> fixed | retained | excluded`. A closed row may be reopened only when new
  evidence changes its impact, compatibility assessment, expected benefit, or verification
  confidence.
- **D-03:** Every evidence-qualified row records a stable identifier, concrete evidence or
  reproducer, affected contract/risk, impact and expected benefit, estimated churn, exact
  verification method, disposition, and a PR/commit link when implemented. Rank by risk and
  leverage, not novelty, aesthetics, tool scores, or ease of change.
- **D-04:** Use a linked GitHub issue when a finding needs public discussion, ownership, or
  independent scheduling. Use an ADR only for unusually durable public-API, security, or
  release-policy decisions. Issues and ADRs support the ledger; neither replaces it.
- **D-05:** The ledger is a decision aid and closeout record, not a promise to eliminate all
  findings. `retained` and `excluded` are valid dispositions when churn exceeds compatible
  benefit, measurements reject the hypothesis, or scope authority excludes the work.

### Characterization bar before extraction
- **D-06:** Use a risk-based, black-box-first observable-contract matrix. Characterize what
  a reasonable caller, adapter implementer, telemetry consumer, operator, job system, or
  HTTP peer can observe without reaching into a private module.
- **D-07:** Require characterization before changes that cross a public facade, documented
  return/error shape, behavior callback, inline/manual/Oban lifecycle, `Ecto.Multi`
  composition contract, HTTP/backend boundary, telemetry event, or operator/Mix-task
  contract. Pure private cleanup that crosses none of these boundaries does not need a
  ceremonial characterization record.
- **D-08:** The preferred sequencing proof is a passing test-only commit against the old
  implementation, followed by extraction-only commits. The PR/commit record names the
  refactor boundary, affected observable contracts, tests added or confirmed, focused/live
  verification commands, and intentional non-contracts. A separate test PR is optional;
  reviewable commit ordering is sufficient.
- **D-09:** Characterize public inputs/options, result and error vocabulary, ordering and
  no-op semantics, transaction/rollback effects, enqueue-versus-execute behavior, delete
  identity, retryability, credential exclusion, HTTP method/path/body/auth precedence,
  Meilisearch acceptance-versus-completion, and documented telemetry names/metadata.
- **D-10:** Do not freeze private module names, helper call counts, internal call order,
  intermediate maps, Req structs, handler IDs, or incidental backend payloads. Inspect
  `Ecto.Multi` only through supported APIs such as `Ecto.Multi.to_list/1`, and only when the
  composition itself is an intentional caller-facing contract.
- **D-11:** Layer tests by purpose: examples communicate named user/operator scenarios;
  property tests cover broad invariants such as normalization idempotence, tenant
  preservation, decoder safety, and settings precedence; a small number of real
  Ecto/Oban/Meilisearch paths prove boundaries that doubles cannot. Neither line coverage
  nor end-to-end tests alone satisfy the characterization bar.

### Diagnostic strictness
- **D-12:** Treat all actionable project-owned compile, test-source, and documentation
  warnings as failures wherever their owning gate runs. Because `mix test
  --warnings-as-errors` does not promote compile warnings, the full test-quality command
  explicitly runs `MIX_ENV=test mix do compile --warnings-as-errors + test
  --warnings-as-errors ...`.
- **D-13:** Discovery exceptions must be exact, documented, and executable. Permit only
  intentionally loaded, non-`*_test.exs` files beneath `test/support/`. Never use a blanket
  ignore predicate, and never suppress a misnamed test elsewhere or a `*_test.exs` file
  under support.
- **D-14:** Telemetry tests use module-qualified callbacks, unique handler IDs, `on_exit`
  detachment, and `async: false` where tests share process-global events. Test event names,
  lifecycle, bounded/safe metadata, and credential absence rather than handler mechanics.
- **D-15:** Prove optional-dependency isolation with a child Mix process that runs a forced
  root compile using `--no-optional-deps --warnings-as-errors`. This avoids the false pass
  caused when a custom task is loaded only after Mix has already considered compilation.
  A separate temporary build path is a diagnostic escalation for suspected cache
  contamination, not required routine ceremony.
- **D-16:** Phase 148 defines strictness and locally runnable commands; required versus
  advisory job placement, matrices, duplication removal, and branch-protection policy stay
  with the later CI phases.

### Coverage evidence
- **D-17:** Use Mix's built-in, dependency-free line coverage for the fast, service-free
  root suite. Exclude live integration and optional docs-contract tests whose setup/cost
  would make the report less reproducible. Keep warnings fatal during the coverage run.
- **D-18:** Coverage is scheduled/manual informational evidence. Enforce no suite-wide,
  per-file, changed-line, or delta percentage threshold. A percentage cannot prove branch
  choices, transaction rollback, queue durability, telemetry safety, or backend task
  visibility and must not become a proxy for those contracts.
- **D-19:** Make the console summary and local HTML report easy to inspect. When a scheduled
  CI run owns coverage, its HTML output may be uploaded as a short-lived artifact, but this
  phase does not require hosted reporting or alter workflow topology.
- **D-20:** Use uncovered modules and lines as review prompts. A gap becomes work only when
  it maps to a credible behavior/risk; record that risk in the quality ledger and close it
  with the appropriate example, property, contract, or live test.
- **D-21:** Add ExCoveralls, a hosted service, PR annotations, historical trend storage, or
  richer branch reporting only after a demonstrated maintainer need. Do not add dependencies
  and tokens merely to display a badge or encourage a vanity target.

### Developer experience and coherent quality policy
- **D-22:** Prefer capability-named commands and plain output that states what is running,
  which expensive/service-backed paths are excluded, whether a metric is informational,
  and exactly how a failure can be reproduced locally. Internal implementation details
  should not leak into the contributor interface unless they explain a fundamental
  constraint or remediation.
- **D-23:** Optimize the baseline across correctness, compatibility, security, operability,
  resilience, maintainability, performance, auditability, contributor speed, ecosystem fit,
  and cognitive load. The governing rule is: **observable contracts are protected, actionable
  diagnostics are strict, proxy metrics remain advisory, and evidence must justify churn**.
- **D-24:** Preserve the release-train posture: fast deterministic proof remains easy to run,
  deep/live evidence remains explicit, and no new gate becomes required solely because it is
  available. A gate earns blocking status by controlling a material risk with stable signal.

### the agent's Discretion
- Exact stable ledger-ID syntax and Markdown column widths may follow existing repository
  conventions as long as rows remain linkable and contain the required evidence fields.
- Characterization records may live in a PR description or commit body; do not create another
  permanent planning artifact when the same proof is already reviewable in Git history.
- Coverage artifact retention and scheduling details belong to the CI-owning phase and may be
  tuned for cost, as long as coverage remains available and explicitly non-blocking.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and requirements
- `.planning/ROADMAP.md` — Phase 148 boundary, success criteria, and ownership split with later phases.
- `.planning/REQUIREMENTS.md` — `QUAL-01`, `TEST-01`, `TEST-03`, `TEST-04`, and `TEST-05` acceptance contract.
- `.planning/PROJECT.md` — v1.37 evidence-led quality-ratchet goal, public-behavior preservation, and green-main posture.
- `.planning/STATE.md` — current milestone completion state; Phase 148 must not be mistaken for unfinished implementation.

### Existing baseline and contributor contract
- `.planning/QUALITY-LEDGER.md` — canonical ranked evidence ledger and current dispositions.
- `CONTRIBUTING.md` — contributor-facing verification commands, release train, and required/advisory proof vocabulary.
- `mix.exs` — test discovery exception, zero-threshold built-in coverage configuration, optional dependency, and preferred Mix environments.
- `lib/mix/tasks/verify.ex` — warning-fatal standard root verification behavior.
- `lib/mix/tasks/verify.no_optional_deps.ex` — forced child-process optional-dependency compile proof.
- `lib/mix/tasks/verify.coverage.ex` — informational fast-suite coverage command.
- `lib/mix/tasks/verify/capability.ex` — canonical capability command composition used by later quality/CI phases.
- `.github/workflows/ci.yml` — current required/advisory job topology; consult only to avoid stealing later-phase ownership.
- `test/test_helper.exs` — explicit support-file loading boundary.
- `test/scrypath/telemetry_test.exs` — existing Telemetry contract-test patterns.

### Local ecosystem and architecture research
- `prompts/elixir-best-practices-deep-research.md` — idiomatic API, behavior, testing, process, error, and library-design guidance.
- `prompts/ecto-best-practices-deep-research.md` — Ecto transaction/composition and testing guidance.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — OSS packaging, compatibility, optional dependencies, telemetry, docs, and evolution guidance.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — warning-fatal gates, coverage posture, CI cost, and release-engineering guidance.
- `prompts/elixir-search-lib-deep-research.md` — search-library operational contracts and source-of-truth boundaries.
- `prompts/meileisearch best practices for scrypath deep research.md` — Meilisearch task lifecycle and operational semantics. The existing filename spelling is canonical.

No UI or brand reference is canonical for this phase. The newer `brandbook/` is
authoritative over the older brand prompt when visual work is in scope, but Phase 148
contains no visual or presentation work.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.planning/QUALITY-LEDGER.md`: already provides the canonical milestone-wide ranked view and final diminishing-return boundary.
- `Mix.Tasks.Verify`: already centralizes the fast repository gate and promotes test-source warnings to failures.
- `Mix.Tasks.Verify.NoOptionalDeps`: already forces the exact child compile required to avoid a cached/no-op proof.
- `Mix.Tasks.Verify.Coverage`: already provides the desired built-in, zero-threshold, service-free report.
- `Mix.Tasks.Verify.Capability`: provides the later capability-named command seam without requiring Phase 148 to redesign CI.

### Established Patterns
- Public and operational behavior is protected with focused ExUnit examples, StreamData properties, Req.Test/adapter doubles, and curated live Meilisearch proof.
- Optional integrations remain explicit; the core library must compile without optional Oban support present.
- Telemetry is a public operational contract: event vocabulary and safe bounded metadata matter, while handler mechanics do not.
- Required merge gates stay lean; compatibility, deep analysis, and expensive browser/example paths may remain advisory when their signal/cost profile warrants it.

### Integration Points
- Quality findings enter and close through `.planning/QUALITY-LEDGER.md` and the Git/PR evidence linked from each row.
- Refactor characterization belongs beside the affected tests and in reviewable test-only commit history.
- Contributor entry points live in `CONTRIBUTING.md` and capability-named Mix tasks.
- Workflow scheduling/artifact retention integrates through `.github/workflows/ci.yml` only in the phase that owns CI topology.

</code_context>

<specifics>
## Specific Ideas

### Research-backed comparison conclusions
- A committed milestone ledger beats issue-only tracking for one ranked, offline,
  reviewable source of truth. GitHub issues remain valuable as linked collaboration
  records; ADRs are reserved for durable policy decisions.
- A risk-based observable-contract matrix beats both changed-line coverage and
  white-box call-graph tests. It preserves user value while leaving internal architecture
  free to improve.
- A test-only first commit is the clearest, lowest-bureaucracy proof that characterization
  tests describe the old behavior rather than ratify the refactor.
- Tiered strictness beats both zero-exception purity and blanket suppression. Exact
  `test/support/` filtering keeps contributor output quiet without hiding misnamed tests.
- Built-in Mix coverage is sufficient while Scrypath only needs a local/scheduled gap-finding
  signal. Mature Ruby tooling demonstrates useful aggregation and branch reports, but also
  shows how thresholds and reporting machinery can become policy and dependency overhead.

### External primary references considered
- Elixir Library Guidelines: https://hexdocs.pm/elixir/1.18.4/library-guidelines.html
- Mix test and warning behavior: https://mix.hexdocs.pm/Mix.Tasks.Test.html
- Mix built-in coverage behavior and limitations: https://mix.hexdocs.pm/Mix.Tasks.Test.Coverage.html
- Ecto.Multi supported composition/introspection: https://hexdocs.pm/ecto/Ecto.Multi.html
- Oban testing modes and helpers: https://hexdocs.pm/oban/testing.html
- Telemetry contract and synchronous handlers: https://hexdocs.pm/telemetry/
- StreamData property testing: https://hexdocs.pm/stream_data/ExUnitProperties.html
- Meilisearch task lifecycle: https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/monitor_tasks
- ExCoveralls reporting capabilities: https://github.com/parroty/excoveralls
- GitHub Projects single-source-of-truth guidance: https://docs.github.com/en/issues/planning-and-tracking-with-projects/learning-about-projects/best-practices-for-projects
- Searchkick operational/synchronization precedent: https://github.com/ankane/searchkick
- meilisearch-rails synchronization/deletion precedent: https://github.com/meilisearch/meilisearch-rails

### Maintainer JTBD example
1. A maintainer finds a possible behavior or architecture problem and records evidence,
   affected contract, benefit, churn, and proof in one ledger row.
2. If the evidence qualifies the work, the maintainer maps observable contracts and adds
   a passing test-only commit.
3. The extraction changes internals while focused tests protect caller/operator outcomes.
4. Strict diagnostics catch warning, discovery, telemetry-handler, and optional-dependency
   regressions; live proof is used only where a real boundary matters.
5. Coverage highlights possible blind spots but cannot approve or reject the change.
6. Exact verification evidence closes, retains, excludes, or later reopens the ledger row.

</specifics>

<deferred>
## Deferred Ideas

- Hosted coverage dashboards, PR annotations, historical trend storage, mutation testing,
  and branch-coverage tooling — adopt only if maintainers demonstrate a recurring decision
  they cannot make with the built-in report.
- Automatic CI enforcement of characterization-record structure — consider only after
  repeated extraction PRs show that the lightweight review convention is being missed.
- Required/advisory CI promotion and matrix topology — owned by the later CI phases, not
  Phase 148.
- UI, ScrypathOps visual quality, brand, theme, and graphic-design review — explicitly out
  of scope for the v1.37 non-UI quality milestone.

</deferred>

---

*Phase: 148-quality-baseline*
*Context gathered: 2026-08-26*
