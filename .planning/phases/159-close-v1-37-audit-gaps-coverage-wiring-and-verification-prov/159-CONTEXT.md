# Phase 159: Audit Gap Closure — Coverage Wiring and Verification Provenance - Context

**Gathered:** 2026-08-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 159 closes the two concrete gaps found by the v1.37 milestone audit. First,
it connects the existing informational `mix verify.coverage` capability to the
repository's scheduled/manual GitHub Actions evidence path and retains a short-lived
report. Second, it reconstructs truthful verification provenance for directly
executed Phases 148–158, clearly separating facts proven by Git history, fresh
present-state verification, earlier committed evidence, and history that can no
longer be proven.

The primary users are maintainers deciding whether v1.37 can close, contributors
reproducing a verification result, and auditors tracing a requirement to source,
tests, commands, and an exact workflow run. The domain nouns are **requirement,
claim, source revision, verification run, artifact, evidence class, limitation,
waiver, and disposition**. The lifecycle verbs are **reconstruct, reproduce,
classify, verify, retain, link, waive, audit, and close**.

This is a maintainer-evidence and CI-integration phase. It does not change Scrypath's
public API or runtime behavior, broaden search capability, redesign the established
required/advisory CI topology, introduce coverage thresholds or hosted reporting,
publish a Hex release, or perform ScrypathOps UI/UX/brand work. Visual design,
accessibility, theme, and brandbook decisions are not applicable.

</domain>

<decisions>
## Implementation Decisions

### Coverage evidence lane
- **D-01:** Add one `coverage (advisory)` job to the existing
  `.github/workflows/ci.yml`, guarded to `schedule` and `workflow_dispatch`. Reuse
  the workflow's existing schedule/manual entry points rather than create another
  workflow or run coverage on every push and pull request.
- **D-02:** Run the existing capability-named `mix verify.coverage` task unchanged:
  Mix built-in line coverage over the fast service-free root suite, live integration
  and docs-contract tests excluded, and warnings fatal.
- **D-03:** Coverage remains explicitly informational and non-blocking. Set the job's
  advisory posture with `continue-on-error: true`; enforce no suite-wide, per-file,
  changed-line, branch, or delta threshold, and do not add a badge or PR comment.
- **D-04:** Upload `cover/` with the repository's already pinned artifact action,
  `if: always()`, `if-no-files-found: warn`, and seven-day retention. Use clear job,
  step, and artifact names that say the report is informational and bind it to the
  workflow run/source SHA.
- **D-05:** Add executable structural coverage to
  `test/mix/tasks/workflow_wiring_test.exs` for the event guard, advisory posture,
  canonical command, always-upload behavior, artifact path, and bounded retention.
  Update `CONTRIBUTING.md` with the CI job and manual recovery path.
- **D-06:** Do not add ExCoveralls, Codecov, GitHub Code Quality conversion,
  Cobertura/LCOV dependencies, historical trend storage, third-party tokens, or an
  artifact attestation. Those solve needs not demonstrated by this phase and would
  conflict with the dependency-free, least-privilege, no-vanity-metric posture.

### Characterization chronology
- **D-07:** Every retrospective claim uses one of four evidence classes:
  `historically proven`, `present-state verified`, `supported by prior committed
  evidence`, or `historically unprovable`. Reports must not blur these classes.
- **D-08:** Reconstruct historical sequencing only from immutable Git topology and
  reproducible evidence. For each extraction, inspect the exact parent revision in a
  detached worktree and count characterization as historically proven only when the
  relevant observable-contract tests existed before the production change and pass
  against that parent.
- **D-09:** Commit messages, filenames, current passing tests, or tests added in the
  same commit as production changes are not proof that characterization preceded the
  extraction. The v1.37 history already contains mixed production/test commits and a
  runtime-safety commit before the later quality-baseline commit, so TEST-01 must fail
  closed wherever exact sequencing cannot be recovered.
- **D-10:** Fresh commands run by Phase 159 prove present release state only. They
  must be recorded with date and exact SHA and must never be described as proof of an
  earlier development action.
- **D-11:** If any part of TEST-01 remains historically unprovable after bounded Git
  forensics, preserve the original requirement and record a narrow explicit waiver.
  Do not weaken, rewrite, or mark the requirement passed to manufacture a 31/31 score.
- **D-12:** Prospective refactors retain Phase 148's preferred lightweight proof:
  passing test-only commits before extraction-only commits, with the CI run URL and
  affected observable contracts named in reviewable Git/PR history. Do not introduce
  a separate permanent characterization bureaucracy in Phase 159.

### Verification provenance artifact shape
- **D-13:** Keep one canonical Phase 159 Markdown requirement-to-evidence matrix for
  all 31 original requirements. Each row records original owning phase,
  implementation commit/source locations, relevant tests and commands, evidence
  class, exact SHA/date/environment or hosted run, limitation, and final disposition.
- **D-14:** Restore phase-local GSD discoverability for Phases 148–158 with thin,
  explicitly retrospective `SUMMARY.md`, `VERIFICATION.md`, and `VALIDATION.md`
  artifacts. `SUMMARY.md` must say it is not a contemporaneous plan-execution record;
  `VERIFICATION.md` records genuine fresh/current proof; `VALIDATION.md` is produced
  only after the summary and verification inputs exist and performs a real Nyquist
  assessment.
- **D-15:** Phase-local records are indexes into the canonical Phase 159 matrix, not
  parallel sources of truth. Keep them mechanically uniform and short; do not copy
  full command transcripts, evidence narratives, or matrix rows into every phase.
- **D-16:** Preserve the original Phase 148–158 requirement ownership. Do not reassign
  all requirements to Phase 159, invent missing plans, imply that retrospective files
  were written during execution, or synthesize passing reports.
- **D-17:** Use Markdown because existing GSD audit and maintainer workflows consume
  it. Do not add a JSON manifest or another artifact format unless planning identifies
  a concrete existing consumer.

### Closure evidence bar
- **D-18:** The local deterministic closure bundle includes
  `mix verify.core --exclude integration --exclude docs_contract`,
  `mix verify.no_optional_deps`, `mix verify.repository_contracts`,
  `mix verify.package`, `mix verify.deep_quality`, `mix verify.coverage`,
  `mix xref graph --format cycles`, the focused workflow-wiring tests, and applicable
  workflow syntax/pin/security proof. Record commands, environment versions, exits,
  date, and exact source SHA.
- **D-19:** Before rerunning the milestone audit, require one hosted GitHub Actions
  run against the exact closing commit. All established required jobs (`core`,
  `package`, `repository-contracts`, `backend`, and `ecommerce-mounted`) must be green,
  and the new coverage step must succeed and retain the expected report artifact.
  Record workflow URL, trigger, run attempt, workflow/source SHA, job conclusions,
  artifact name/path, digest, and retention.
- **D-20:** Compatibility, hosted deep quality, Phoenix example, ScrypathOps, and full
  ecommerce E2E remain advisory or path-scoped exactly as currently documented.
  Record their same-run outcomes when available, but do not promote them or turn an
  unrelated advisory/external failure into a Phase 159 blocker.
- **D-21:** Do not perform an actual Hex publish or reopen release-parity work for this
  closure. `mix verify.package` and the existing required release-contract proof are
  sufficient unless Phase 159 unexpectedly changes those surfaces.
- **D-22:** Rerun the v1.37 milestone audit only after coverage wiring, retrospective
  evidence, Nyquist validation, local proof, and exact-SHA hosted proof exist. Close
  every repairable gap; use an explicit override only for a precisely documented,
  historically irrecoverable TEST-01 chronology gap.

### the agent's Discretion
- Exact stable matrix column widths, phase-local cross-link wording, detached-worktree
  directory names, and coverage artifact name may follow existing repository patterns
  as long as the evidence classes and required provenance fields remain explicit.
- Planning may batch the 148–158 retrospective artifact generation mechanically, but
  each phase's substantive verification and validation verdict must derive from its
  own requirements and actual evidence rather than a blanket copied pass.
- Existing daily schedule timing and seven-day artifact retention may be reused without
  introducing a second cron or new retention policy.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope, audit findings, and requirement truth
- `.planning/v1.37-MILESTONE-AUDIT.md` — authoritative gap report, three-source audit failure, broken TEST-05 flow, and provenance closure warning.
- `.planning/ROADMAP.md` — original Phase 148–158 ownership and Phase 159 boundary.
- `.planning/REQUIREMENTS.md` — the 31 original requirements and traceability, especially TEST-01 and TEST-05.
- `.planning/PROJECT.md` — evidence-led quality-ratchet goal, public-behavior preservation, and green-main release-train posture.
- `.planning/STATE.md` — milestone state and Phase 159 roadmap evolution.
- `.planning/QUALITY-LEDGER.md` — canonical v1.37 implementation evidence and diminishing-return dispositions.
- `.planning/phases/148-quality-baseline/148-CONTEXT.md` — locked characterization, diagnostic, coverage, evidence, and gate-policy decisions carried into Phase 159.

### Existing coverage and CI integration seams
- `lib/mix/tasks/verify.coverage.ex` — existing dependency-free informational fast-suite coverage capability.
- `.github/workflows/ci.yml` — established schedule/manual triggers, required/advisory topology, immutable action pins, and seven-day artifact pattern.
- `test/mix/tasks/workflow_wiring_test.exs` — established executable workflow-contract seam to extend for coverage wiring.
- `CONTRIBUTING.md` — contributor-facing capability commands and required/advisory CI contract.
- `mix.exs` — coverage configuration, preferred environments, dependencies, and root library contract.
- `lib/mix/tasks/verify/capability.ex` — capability-named verification composition used across CI.

### Provenance and closeout patterns
- `.planning/phases/136-milestone-verification-uat-s-g/136-ARTIFACT-MANIFEST.json` — prior exact-SHA/path/checksum/generated-artifact provenance pattern; use as a field reference, not a mandate for JSON.
- `.planning/phases/136-milestone-verification-uat-s-g/136-DUALVERIFY-REPORT.md` — prior canonical closeout-report organization and evidence classification.
- `.planning/phases/136-milestone-verification-uat-s-g/136-VERIFICATION.md` — prior goal-backward verification reporting pattern.
- `.planning/milestones/v1.36-phases/145-legacy-phoenix-and-ecto-decimal-remediation/145-VERIFICATION.md` — compact exact-commit deterministic/supplemental evidence classification.
- `.planning/milestones/v1.36-phases/146-scrypathops-web-client-remediation/146-VERIFICATION.md` — verification provenance across optional-app and root boundaries.
- `.planning/milestones/v1.36-phases/147-ecommerce-mounted-ops-remediation-and-closure-evidence/147-03-SUMMARY.md` — strong exact-SHA closure summary and bounded evidence receipt.
- `.planning/milestones/v1.36-phases/147-ecommerce-mounted-ops-remediation-and-closure-evidence/147-VERIFICATION.md` — mounted-source, required/advisory, service, and cleanup verification pattern.

### Local ecosystem research requested by the owner
- `prompts/elixir-best-practices-deep-research.md` — idiomatic ExUnit, warning, documentation, explicitness, and library-maintainability guidance.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — OSS library testing, compatibility, packaging, observability, and contributor-DX guidance.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — coverage-as-signal, lean required matrices, artifact-vs-cache, least-privilege, and release-engineering guidance.

No UI, graphic-design, or brand reference is canonical for this phase. The current
brandbook remains authoritative when visual work is in scope, but Phase 159 contains
no visual surface.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mix.Tasks.Verify.Coverage`: already produces the locked fast-suite HTML/console report with no threshold or new dependency.
- `.github/workflows/ci.yml`: already owns daily schedule/manual dispatch, advisory job guards, SHA-pinned setup/cache/upload actions, and seven-day evidence retention.
- `Mix.Tasks.Verify.WorkflowWiringTest`: already treats workflow topology and release ordering as executable repository contracts.
- `.planning/QUALITY-LEDGER.md`: already provides the implementation/verification starting evidence for the 31-requirement matrix.
- Phase 136 and v1.36 evidence artifacts: already demonstrate compact exact-SHA provenance, deterministic-versus-supplemental classification, artifact hashes, and truthful unavailable-lane handling.

### Established Patterns
- Capability-named Mix commands are the contributor and CI interface; phase-number tasks remain historical focused wrappers.
- Required merge gates stay lean and risk-owning; compatibility, deep analysis, optional apps, and expensive browser/example lanes remain advisory or path-scoped.
- Workflow actions are full-SHA pinned and default permissions are read-only; routine evidence must not expand permissions or introduce secrets.
- Public/operational behavior is protected by focused examples, properties, contract tests, and live proof at real boundaries; line coverage is only a gap-finding prompt.
- Strong evidence records exact commits, commands/exits, environment, run URLs, classifications, and bounded artifacts instead of raw logs or unsupported pass claims.

### Integration Points
- Add the coverage consumer beside the existing scheduled/manual `ecommerce-e2e` pattern in `.github/workflows/ci.yml`.
- Extend `test/mix/tasks/workflow_wiring_test.exs` and the `CONTRIBUTING.md` CI table so implementation, executable contract, and contributor vocabulary remain aligned.
- Use Git commit parents and detached worktrees as the historical reconstruction boundary; do not mutate the primary worktree or infer from messages.
- Feed retrospective phase-local indexes and fresh validation results into the canonical Phase 159 evidence matrix, then rerun the milestone audit.

</code_context>

<specifics>
## Specific Ideas

### Maintainer and auditor JTBD
1. A scheduled run produces a clearly named informational coverage report without
   blocking a merge or implying that 66.84% is an acceptance target.
2. A maintainer can manually rerun the same job when schedules are delayed, dropped,
   or inactive and download the report for seven days.
3. An auditor starts from one matrix row, follows the original requirement and phase,
   reaches implementation/test commits, sees the exact evidence class, and can inspect
   the current command or hosted run without reconciling duplicate ledgers.
4. When history cannot establish that characterization preceded extraction, the report
   says so plainly and links the narrow waiver; present green tests are not substituted
   for missing historical proof.
5. A future contributor gets the least-surprising prospective path: commit the passing
   behavior lock first, then perform the extraction, and let exact-SHA CI make the order
   durable.

### Research-backed ecosystem lessons
- Mature Elixir projects prioritize clear `mix test`/compile commands, warning-fatal
  proof, representative supported-version matrices, and real service boundaries over a
  coverage percentage as the main quality contract.
- GitHub workflow artifacts are the appropriate short-lived home for HTML coverage;
  caches are for reusable build inputs, and attestations are most valuable for
  distributable build artifacts rather than transient maintainer reports.
- Hosted coverage services and popular Ruby/JS coverage stacks add trends and PR
  annotations, but also introduce report merging, token/service, notification, and
  Goodhart-style threshold pressure. Scrypath should add them only after evidence of a
  recurring decision the built-in report cannot support.
- Git and SLSA/in-toto provenance can bind a claim to stored source and an actual run;
  neither can attest retroactively to an action that was never recorded.

### External primary references considered
- Mix test and coverage: https://mix.hexdocs.pm/Mix.Tasks.Test.html and https://mix.hexdocs.pm/Mix.Tasks.Test.Coverage.html
- GitHub Actions artifacts: https://docs.github.com/en/actions/tutorials/store-and-share-data
- GitHub schedule/manual event behavior: https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows
- Git commit snapshots and parents: https://git-scm.com/book/en/v2/Git-Internals-Git-Objects.html
- SLSA provenance model: https://slsa.dev/spec/v1.2/provenance
- NIST SSDF evidence/provenance retention: https://csrc.nist.gov/projects/ssdf
- Ecto, Phoenix, and Oban primary CI workflows were reviewed as successful ecosystem examples of direct commands, supported-version matrices, and relevant integration proof.

</specifics>

<deferred>
## Deferred Ideas

- Hosted coverage dashboards, PR annotations, historical trend storage, richer branch
  coverage, mutation testing, and changed-line thresholds — revisit only after a
  recurring maintainer decision cannot be made with built-in Mix coverage.
- Artifact attestations for published Hex/release assets — valuable supply-chain work,
  but not a solution for short-lived HTML coverage or missing historical test ordering.
- Automated enforcement of test-only-before-extraction commit structure — adopt only if
  future refactors repeatedly miss the lightweight review convention.
- UI, ScrypathOps presentation, accessibility, theme, graphic design, and brand work —
  explicitly outside this non-UI audit-closure phase.

</deferred>

---

*Phase: 159-audit-gap-closure-coverage-wiring-and-verification-provenance*
*Context gathered: 2026-08-26*
