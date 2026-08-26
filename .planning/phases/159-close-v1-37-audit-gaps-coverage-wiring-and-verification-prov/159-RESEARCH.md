# Phase 159: Audit Gap Closure — Coverage Wiring and Verification Provenance - Research

**Researched:** 2026-08-26
**Domain:** GitHub Actions evidence wiring and retrospective verification provenance
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Add one `coverage (advisory)` job to the existing `.github/workflows/ci.yml`, guarded to `schedule` and `workflow_dispatch`. Reuse the workflow's existing schedule/manual entry points rather than create another workflow or run coverage on every push and pull request.
- **D-02:** Run the existing capability-named `mix verify.coverage` task unchanged: Mix built-in line coverage over the fast service-free root suite, live integration and docs-contract tests excluded, and warnings fatal.
- **D-03:** Coverage remains explicitly informational and non-blocking. Set the job's advisory posture with `continue-on-error: true`; enforce no suite-wide, per-file, changed-line, branch, or delta threshold, and do not add a badge or PR comment.
- **D-04:** Upload `cover/` with the repository's already pinned artifact action, `if: always()`, `if-no-files-found: warn`, and seven-day retention. Use clear job, step, and artifact names that say the report is informational and bind it to the workflow run/source SHA.
- **D-05:** Add executable structural coverage to `test/mix/tasks/workflow_wiring_test.exs` for the event guard, advisory posture, canonical command, always-upload behavior, artifact path, and bounded retention. Update `CONTRIBUTING.md` with the CI job and manual recovery path.
- **D-06:** Do not add ExCoveralls, Codecov, GitHub Code Quality conversion, Cobertura/LCOV dependencies, historical trend storage, third-party tokens, or an artifact attestation.
- **D-07:** Every retrospective claim uses one of four evidence classes: `historically proven`, `present-state verified`, `supported by prior committed evidence`, or `historically unprovable`.
- **D-08:** Reconstruct historical sequencing only from immutable Git topology and reproducible evidence. For each extraction, inspect the exact parent revision in a detached worktree and count characterization as historically proven only when the relevant observable-contract tests existed before the production change and pass against that parent.
- **D-09:** Commit messages, filenames, current passing tests, or tests added in the same commit as production changes are not proof that characterization preceded the extraction. TEST-01 must fail closed wherever exact sequencing cannot be recovered.
- **D-10:** Fresh commands run by Phase 159 prove present release state only. They must be recorded with date and exact SHA and must never be described as proof of an earlier development action.
- **D-11:** If any part of TEST-01 remains historically unprovable after bounded Git forensics, preserve the original requirement and record a narrow explicit waiver. Do not weaken, rewrite, or mark the requirement passed to manufacture a 31/31 score.
- **D-12:** Prospective refactors retain Phase 148's preferred lightweight proof: passing test-only commits before extraction-only commits, with the CI run URL and affected observable contracts named in reviewable Git/PR history.
- **D-13:** Keep one canonical Phase 159 Markdown requirement-to-evidence matrix for all 31 original requirements, including original phase, implementation source/commit, relevant tests/commands, evidence class, SHA/date/environment or hosted run, limitation, and disposition.
- **D-14:** Restore thin, explicitly retrospective `SUMMARY.md`, `VERIFICATION.md`, and post-input `VALIDATION.md` records for Phases 148–158. They index the canonical matrix and must not impersonate contemporaneous execution artifacts.
- **D-15:** Phase-local records are indexes into the canonical Phase 159 matrix, not parallel sources of truth; keep them uniform and short.
- **D-16:** Preserve Phases 148–158 requirement ownership. Do not invent plans, imply the retrospective files existed during execution, or synthesize passing reports.
- **D-17:** Use Markdown only; do not add JSON unless an existing consumer needs it.
- **D-18:** Record the local deterministic closure bundle's commands, environment versions, exits, date, and exact source SHA.
- **D-19:** Before re-audit, require one hosted GitHub Actions run on the exact closing commit: all established required jobs green and the coverage job successful with its expected artifact. Record its URL, trigger, attempt, workflow/source SHA, conclusions, artifact name/path, digest, and retention.
- **D-20:** Compatibility, hosted deep quality, Phoenix example, ScrypathOps, and full ecommerce E2E remain advisory/path-scoped. Record same-run outcomes when available; do not promote them or make unrelated advisory/external failures blockers.
- **D-21:** Do not publish Hex or reopen release-parity work.
- **D-22:** Re-run the v1.37 audit only after coverage wiring, retrospective evidence, Nyquist validation, local proof, and exact-SHA hosted proof exist. Use an explicit override only for a precisely documented, historically irrecoverable TEST-01 gap.

### the agent's Discretion

- Exact stable matrix column widths, phase-local cross-link wording, detached-worktree directory names, and coverage artifact name may follow existing repository patterns as long as the evidence classes and required provenance fields remain explicit.
- Planning may batch the 148–158 retrospective artifact generation mechanically, but each phase's substantive verification and validation verdict must derive from its own requirements and actual evidence rather than a blanket copied pass.
- Existing daily schedule timing and seven-day artifact retention may be reused without introducing a second cron or new retention policy.

### Deferred Ideas (OUT OF SCOPE)

- Hosted coverage dashboards, PR annotations, historical trend storage, richer branch coverage, mutation testing, and changed-line thresholds.
- Artifact attestations for published Hex/release assets.
</user_constraints>

## Project Constraints (from AGENTS.md)

- Keep the Elixir OSS library Ecto-first and Phoenix-friendly; preserve the internal adapter seam. [VERIFIED: AGENTS.md]
- Preserve explicit inline, Oban-backed, and manual operational flows; do not hide operational reality. [VERIFIED: AGENTS.md]
- Keep edits focused, run the relevant `CONTRIBUTING.md` checks, and update `.planning/PROJECT.md` only when product scope or shipped claims intentionally change. [VERIFIED: AGENTS.md]
- Maintain a green-main, PR-first release train; do not invent work outside an approved item. [VERIFIED: AGENTS.md]

## Summary

Phase 159 has two independent outputs that must converge before re-audit. First, wire the existing zero-threshold, warning-fatal, fast-suite Mix coverage task into the established `ci.yml` scheduled/manual advisory lane and upload its generated `cover/` directory. The existing `ecommerce-e2e` job supplies the in-repository pattern for the event guard, advisory posture, and bounded `always()` artifact upload. [VERIFIED: `.github/workflows/ci.yml`; VERIFIED: `lib/mix/tasks/verify.coverage.ex`; CITED: https://docs.github.com/actions/configuring-and-managing-workflows/persisting-workflow-data-using-artifacts?azure-portal=true]

Second, repair the audit's missing three-source provenance without falsifying history. The canonical new matrix must distinguish immutable chronology evidence from fresh present-state commands and from committed historical receipts. Git commit objects bind a source snapshot to its parents, so a detached worktree at an extraction's parent is the only acceptable local test for whether its contract test both existed and passed before that extraction. A present-day green test cannot prove historical order. [CITED: https://git-scm.com/book/en/v2/Git-Internals-Git-Objects.html; VERIFIED: `.planning/v1.37-MILESTONE-AUDIT.md`; VERIFIED: `159-CONTEXT.md`]

**Primary recommendation:** Plan a small code/documentation wave for TEST-05, then a bounded Git-forensics and retrospective-record wave, followed by fresh exact-SHA local and hosted evidence, per-phase Nyquist validation, and only then the milestone re-audit. [VERIFIED: `159-CONTEXT.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Scheduled/manual coverage execution | CI / GitHub Actions | Mix task | The workflow owns trigger selection and advisory job semantics; Mix owns the actual coverage command. [VERIFIED: `.github/workflows/ci.yml`; VERIFIED: `lib/mix/tasks/verify.coverage.ex`] |
| Coverage report retention | CI artifact storage | — | `upload-artifact` owns retention and run-scoped retrieval, while `cover/` is the Mix-produced input. [CITED: https://docs.github.com/actions/configuring-and-managing-workflows/persisting-workflow-data-using-artifacts?azure-portal=true] |
| Historical characterization determination | Git history | isolated Mix/ExUnit execution | Parent snapshots establish ordering; an isolated test run establishes the observable contract at that snapshot. [CITED: https://git-scm.com/book/en/v2/Git-Internals-Git-Objects.html] |
| Requirement evidence truth | Planning Markdown | GitHub Actions / local commands | One matrix is the source of truth; phase-local records point to it and hosted/local receipts add reproducible facts. [VERIFIED: `159-CONTEXT.md`] |
| Closure decision | Milestone audit | required CI jobs | The re-audit consumes provenance and exact-SHA proof; it must not redefine requirements or job policy. [VERIFIED: `159-CONTEXT.md`; VERIFIED: `.planning/v1.37-MILESTONE-AUDIT.md`] |

## Standard Stack

### Core

| Library / tool | Version | Purpose | Why Standard |
|---|---:|---|---|
| Existing Mix built-in coverage (`mix test --cover`) | Elixir/Mix project toolchain | Generate line-coverage report from the fast root suite | The task already invokes it with warning-fatal and excluded service/docs-contract tests; project configuration sets threshold `0`. [VERIFIED: `lib/mix/tasks/verify.coverage.ex`; VERIFIED: `mix.exs`; CITED: https://mix.hexdocs.pm/Mix.Tasks.Test.html] |
| Existing GitHub Actions upload action | pinned SHA (`043fb…6a0a`) | Persist run-specific `cover/` evidence | Existing CI already uses this exact immutable pin and seven-day retention for advisory E2E evidence. [VERIFIED: `.github/workflows/ci.yml`] |
| Git detached worktrees | Git 2.41.0 available locally | Inspect and execute exact parent snapshots without changing the primary worktree | Commit parent IDs and trees are immutable historical topology; worktrees keep probes isolated from user edits. [VERIFIED: local `git --version`; CITED: https://git-scm.com/book/en/v2/Git-Internals-Git-Objects.html] |
| Markdown planning artifacts | repository convention | Canonical evidence matrix and thin phase indexes | Existing GSD audit and verification artifacts are Markdown; locked decision D-17 rejects a new manifest format. [VERIFIED: `159-CONTEXT.md`; VERIFIED: `.planning/v1.37-MILESTONE-AUDIT.md`] |

### Supporting

| Tool | Purpose | When to Use |
|---|---|---|
| `actionlint` | Workflow syntax/expression verification | After changing `ci.yml`; it is installed locally at 1.7.12. [VERIFIED: local `actionlint -version`] |
| `gh` | Trigger/inspect exact-SHA hosted workflow and artifact metadata | For D-19 after the closing commit is reachable remotely; installed locally at 2.95.0. [VERIFIED: local `gh --version`] |
| Existing ExUnit workflow-wiring suite | Executable YAML structural contract | Extend with a focused `coverage` job test, not a YAML parser or a new test library. [VERIFIED: `test/mix/tasks/workflow_wiring_test.exs`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Built-in Mix coverage artifact | Hosted coverage service / ExCoveralls | Rejected by D-06: adds dependencies, tokens or service policy, and threshold/annotation pressure without a demonstrated decision need. [VERIFIED: `159-CONTEXT.md`] |
| Parent-snapshot proof | Commit-message/file-name inference | Rejected by D-09: same-commit tests and messages do not prove test-before-extraction chronology. [VERIFIED: `159-CONTEXT.md`] |
| Canonical Markdown matrix | New JSON manifest | Rejected by D-17 absent an existing consumer. [VERIFIED: `159-CONTEXT.md`] |

**Installation:** None. This phase adds no package or dependency. [VERIFIED: `159-CONTEXT.md`; VERIFIED: `mix.exs`]

## Architecture Patterns

### System Architecture Diagram

```text
schedule / workflow_dispatch
          |
          v
coverage (advisory) job -- Mix deps/setup --> mix verify.coverage
          |                                          |
          | continue-on-error: true                  v
          +--------------------------------------> cover/
                                                     |
                                     if: always()    v
                                              upload informational artifact (7 days)

Git production/extraction commit --> parent SHA --> detached worktree --> test existed + passed?
                                                           |                    |
                                                           +-- yes --> historically proven
                                                           +-- no/ambiguous --> historically unprovable + narrow waiver

fresh local commands + exact-SHA hosted run + prior committed receipts
                           |
                           v
          canonical Phase 159 requirement-to-evidence matrix
                           |
                           v
 thin 148–158 SUMMARY / VERIFICATION / VALIDATION indexes --> milestone re-audit
```

The diagram separates present-state evidence, committed historical evidence, and reproducible historical sequencing so no record can accidentally claim more than its evidence class permits. [VERIFIED: `159-CONTEXT.md`]

### Recommended Project Structure

```text
.planning/phases/159-close-v1-37-audit-gaps-coverage-wiring-and-verification-prov/
├── 159-EVIDENCE-MATRIX.md      # canonical 31-row source of truth
├── 159-CLOSURE-RECEIPT.md      # local + hosted exact-SHA receipt and re-audit input
└── 159-RESEARCH.md             # planning guidance

.planning/phases/{148..158}-*/
├── {N}-SUMMARY.md              # explicit retrospective index
├── {N}-VERIFICATION.md         # phase-specific current/committed proof
└── {N}-VALIDATION.md           # genuine Nyquist result after inputs exist
```

This is a recommended artifact layout, not a claim that those files exist today. It preserves the canonical-matrix rule and allows existing audit discoverability. [VERIFIED: `159-CONTEXT.md`; VERIFIED: `.planning/v1.37-MILESTONE-AUDIT.md`]

### Pattern 1: Structural workflow contract beside the workflow

**What:** Add one focused `describe` block to `workflow_wiring_test.exs` that extracts the `coverage` job using existing `workflow_job_block/2` and asserts its exact guard, advisory setting, canonical command, artifact action/name/path, `if: always()`, `if-no-files-found: warn`, and seven-day retention. [VERIFIED: `test/mix/tasks/workflow_wiring_test.exs`; VERIFIED: `159-CONTEXT.md`]

**When to use:** Whenever a workflow's semantic topology is a repository contract, particularly where text changes could silently promote a job or break a report path. [VERIFIED: `test/mix/tasks/workflow_wiring_test.exs`]

```elixir
# Source: existing test/mix/tasks/workflow_wiring_test.exs pattern
coverage = workflow_job_block(File.read!(@ci_yml), "coverage")
assert coverage =~ "github.event_name == 'schedule' || github.event_name == 'workflow_dispatch'"
assert coverage =~ "continue-on-error: true"
assert coverage =~ "mix verify.coverage"
assert coverage =~ "if: always()"
assert coverage =~ "path: cover/"
assert coverage =~ "retention-days: 7"
```

### Pattern 2: Fail-closed evidence classification

**What:** Give every matrix row exactly one evidence class, then store the exact reference that earned it. Historical sequence is `historically proven` only after the relevant test is present in the extraction parent and passes there; otherwise use `historically unprovable`, preserve TEST-01, and describe the narrow limitation/waiver. [VERIFIED: `159-CONTEXT.md`]

**When to use:** For all statements about how Phase 148–158 work was performed, as distinct from what current source proves. [VERIFIED: `159-CONTEXT.md`]

```markdown
| Requirement | Evidence class | Immutable reference | Limitation | Disposition |
|---|---|---|---|---|
| TEST-01 | historically unprovable | `<extraction>^` inspected in detached worktree | test landed in mixed commit; order cannot be recovered | narrow waiver; requirement unchanged |
| SAFE-01 | present-state verified | `<closing SHA>`, command/date/environment | proves current behavior, not development chronology | satisfied for current state |
```

### Pattern 3: Receipt-first closure sequencing

1. Implement and structurally test coverage wiring; update contributor recovery guidance. [VERIFIED: `159-CONTEXT.md`]
2. Build the canonical matrix and perform bounded parent-snapshot probes without mutating the main worktree. [VERIFIED: `159-CONTEXT.md`]
3. Write phase-local retrospective indexes and run each phase's real Nyquist assessment after its summary/verification inputs exist. [VERIFIED: `159-CONTEXT.md`; VERIFIED: `.planning/config.json`]
4. Run the prescribed local bundle at the candidate SHA and record environment, date, exit status, and output classification. [VERIFIED: `159-CONTEXT.md`]
5. Obtain a hosted `ci.yml` run for that exact closing SHA; record required-job results plus coverage artifact metadata. [VERIFIED: `159-CONTEXT.md`]
6. Re-run the milestone audit only with those records available; retain only a narrow TEST-01 waiver if forensics cannot establish order. [VERIFIED: `159-CONTEXT.md`]

### Anti-Patterns to Avoid

- **Promoting coverage to a merge gate:** Contradicts D-03 and turns a diagnostic signal into an acceptance metric. [VERIFIED: `159-CONTEXT.md`]
- **Claiming history from fresh tests:** A fresh result proves only the checked-out SHA and date, not the earlier execution order. [VERIFIED: `159-CONTEXT.md`]
- **Copying a blanket phase-pass template:** Phase-local indexes must be mechanically uniform but their verification/validation conclusion must derive from that phase's own requirements and evidence. [VERIFIED: `159-CONTEXT.md`]
- **Using the dirty primary checkout for parent probes:** It risks mixing user-owned planning changes with historical snapshot results; use disposable detached worktrees. [VERIFIED: `159-CONTEXT.md`; VERIFIED: current `git status --short`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Line coverage | Custom tracer, exporter, or coverage threshold policy | Existing `mix verify.coverage` and Mix `:cover` output | The task already encodes the required suite boundary and warning policy; Mix defaults the coverage output to `cover/`. [VERIFIED: `lib/mix/tasks/verify.coverage.ex`; VERIFIED: `mix.exs`; CITED: https://mix.hexdocs.pm/Mix.Tasks.Test.html] |
| Short-lived report storage | Custom archive or cache | Existing pinned `actions/upload-artifact` | Artifacts support per-artifact retention; caches are not evidence records. [VERIFIED: `.github/workflows/ci.yml`; CITED: https://docs.github.com/actions/configuring-and-managing-workflows/persisting-workflow-data-using-artifacts?azure-portal=true] |
| Workflow semantic parser | New YAML/Actions dependency | Existing structural ExUnit test seam plus actionlint | It keeps the phase dependency-free and follows an established contract-test pattern. [VERIFIED: `test/mix/tasks/workflow_wiring_test.exs`; VERIFIED: local `actionlint -version`] |
| Historical attestation | Synthetic timeline or generated “passed” record | Git parent snapshots, detached executions, explicit evidence classes | Git supplies immutable snapshot/parent facts but cannot retroactively attest an unrecorded action. [CITED: https://git-scm.com/book/en/v2/Git-Internals-Git-Objects.html; VERIFIED: `159-CONTEXT.md`] |

## Common Pitfalls

### Pitfall 1: A report upload masks a failing coverage command

**What goes wrong:** `if: always()` uploads an empty/missing report after command failure, then the evidence record treats the artifact presence as a successful coverage run. [VERIFIED: `159-CONTEXT.md`]

**How to avoid:** Keep `mix verify.coverage` as its own preceding step; make upload warnings non-fatal, and record the job/step conclusion separately from artifact metadata. [VERIFIED: `159-CONTEXT.md`; VERIFIED: `.github/workflows/ci.yml`]

### Pitfall 2: Workflow topology drift from a text-only assertion

**What goes wrong:** A broad full-file string match passes even if the guard or upload settings belong to another job. [ASSUMED]

**How to avoid:** Extract `workflow_job_block(ci, "coverage")` and assert required settings inside that block, while testing the artifact step name/path in the same job. [VERIFIED: `test/mix/tasks/workflow_wiring_test.exs`]

### Pitfall 3: Chronology laundering

**What goes wrong:** Mixed production/test commits, current tests, or commit subjects are presented as proof that characterization preceded extraction. [VERIFIED: `159-CONTEXT.md`; VERIFIED: `.planning/v1.37-MILESTONE-AUDIT.md`]

**How to avoid:** Apply the exact-parent detached-worktree test and fail closed to `historically unprovable` when it cannot prove both test existence and a passing parent run. [VERIFIED: `159-CONTEXT.md`]

### Pitfall 4: Re-auditing too early

**What goes wrong:** Re-running the audit before phase-local Summary/Verification/Validation records and exact-SHA hosted evidence exist merely recreates the same 0/31 provenance failure. [VERIFIED: `.planning/v1.37-MILESTONE-AUDIT.md`; VERIFIED: `159-CONTEXT.md`]

**How to avoid:** Make the re-audit the final plan wave with explicit inputs, not an implementation check. [VERIFIED: `159-CONTEXT.md`]

## Code Examples

### Coverage job shape

```yaml
# Source: .github/workflows/ci.yml ecommerce-e2e pattern; locked D-01..D-04
coverage:
  name: coverage (advisory)
  if: github.event_name == 'schedule' || github.event_name == 'workflow_dispatch'
  runs-on: ubuntu-latest
  continue-on-error: true
  steps:
    # Reuse the repository's pinned checkout/setup-beam/cache/deps setup.
    - run: mix verify.coverage
    - name: Upload informational coverage report
      if: always()
      uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a
      with:
        name: informational-coverage-${{ github.sha }}
        path: cover/
        if-no-files-found: warn
        retention-days: 7
```

The name is discretionary, but it must communicate informational intent and bind the evidence to the source/run while preserving the locked semantics. [VERIFIED: `159-CONTEXT.md`; CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/contexts]

### Parent-snapshot probe shape

```bash
# Source: Git commit/tree model and locked D-08 chronology rule
git worktree add --detach "$PROBE_DIR" "$EXTRACTION_SHA^"
git -C "$PROBE_DIR" ls-files --error-unmatch "$CONTRACT_TEST"
git -C "$PROBE_DIR" status --short
(cd "$PROBE_DIR" && mix test "$CONTRACT_TEST" --warnings-as-errors)
git worktree remove "$PROBE_DIR"
```

Record the fully resolved extraction and parent SHAs, test path/selector, command, environment, timestamp, exit, and any inability to run an old snapshot. A missing test or non-reproducible parent can never be upgraded to historical proof. [VERIFIED: `159-CONTEXT.md`; CITED: https://git-scm.com/book/en/v2/Git-Internals-Git-Objects.html]

## State of the Art

| Old approach | Current approach | Impact |
|---|---|---|
| Local-only informational coverage command | Scheduled/manual advisory CI job with a seven-day run artifact | Completes TEST-05's evidence path while keeping it non-blocking. [VERIFIED: `.planning/v1.37-MILESTONE-AUDIT.md`; VERIFIED: `159-CONTEXT.md`] |
| Directly executed phases without GSD proof artifacts | Retrospective Markdown indexes backed by a single truthful matrix | Restores audit discoverability without pretending plans/reports were contemporaneous. [VERIFIED: `.planning/v1.37-MILESTONE-AUDIT.md`; VERIFIED: `159-CONTEXT.md`] |
| Implicit test-before-refactor belief | Parent-SHA reproducibility or explicit historical limitation | Prevents unsupported 31/31 closure claims. [VERIFIED: `159-CONTEXT.md`] |

**Deprecated/outdated:** Treating the `mix verify.coverage` task alone as satisfaction of TEST-05 is invalid because the audit found the scheduled/manual artifact flow unwired. [VERIFIED: `.planning/v1.37-MILESTONE-AUDIT.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | A broad whole-workflow string assertion can accidentally validate settings belonging to another job. | Common Pitfalls | The focused structural test could be weaker than intended; the planner should keep assertions job-scoped. |

## Open Questions

1. **Which TEST-01 extractions can meet the exact-parent standard?**
   - What we know: the committed history includes mixed production/test commits and a runtime-safety commit before the later quality-baseline commit. [VERIFIED: `159-CONTEXT.md`; VERIFIED: `git log`]
   - What's unclear: the extraction-by-extraction parent test inventory and whether old dependency resolution permits each focused test to run. [VERIFIED: `159-CONTEXT.md`]
   - Recommendation: inventory all production/extraction commits first, probe only relevant parents in disposable worktrees, and emit a narrowly scoped waiver for every non-provable row. [VERIFIED: `159-CONTEXT.md`]

2. **What exact SHA will close the phase?**
   - What we know: the hosted proof must target the final closing commit, not an earlier workflow test commit. [VERIFIED: `159-CONTEXT.md`]
   - What's unclear: that SHA does not exist until execution produces it. [VERIFIED: current `git log`]
   - Recommendation: make SHA capture and hosted-run receipt an explicit post-commit task with no substitution by a branch-head or rerun on another revision. [VERIFIED: `159-CONTEXT.md`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---:|---|---|
| Git | parent-SHA forensics/worktrees | ✓ | 2.41.0 | — [VERIFIED: local `git --version`] |
| actionlint | local workflow syntax validation | ✓ | 1.7.12 | Existing repository workflow test if unavailable elsewhere. [VERIFIED: local `actionlint -version`] |
| GitHub CLI | dispatch/inspect exact hosted run | ✓ | 2.95.0 | GitHub web UI/API with identical recorded fields. [VERIFIED: local `gh --version`] |
| Docker | required `ecommerce-mounted` hosted-equivalent/local validation if run locally | ✓ | 29.5.2 | Hosted required CI job is authoritative for D-19. [VERIFIED: local `docker --version`; VERIFIED: `159-CONTEXT.md`] |
| GitHub Actions remote execution | D-19 exact-SHA proof | not locally probeable | — | Must be obtained from the repository host; no local substitute. [VERIFIED: `159-CONTEXT.md`] |

**Missing dependencies with no fallback:** GitHub-hosted exact-SHA execution cannot be completed solely in the local environment. [VERIFIED: `159-CONTEXT.md`]

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit via Mix, with structural repository-contract tests. [VERIFIED: `test/mix/tasks/workflow_wiring_test.exs`] |
| Config file | `mix.exs` (`test_coverage`, preferred environments, test alias). [VERIFIED: `mix.exs`] |
| Quick run command | `mix test test/mix/tasks/workflow_wiring_test.exs --warnings-as-errors` [VERIFIED: `test/mix/tasks/workflow_wiring_test.exs`] |
| Full suite command | `mix verify.core --exclude integration --exclude docs_contract` [VERIFIED: `CONTRIBUTING.md`; VERIFIED: `.planning/v1.37-MILESTONE-AUDIT.md`] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| TEST-05 | Coverage job runs only for schedule/manual, remains advisory, runs canonical command, and always uploads bounded `cover/` artifact | ExUnit structural + actionlint | `mix test test/mix/tasks/workflow_wiring_test.exs --warnings-as-errors && actionlint .github/workflows/ci.yml` | ❌ Wave 0 extension needed [VERIFIED: `159-CONTEXT.md`; VERIFIED: `test/mix/tasks/workflow_wiring_test.exs`] |
| Original 31 requirements | Each matrix row cites truthful present/current/committed/historical proof and phase-local index | Markdown integrity + per-phase Nyquist review | targeted matrix/link checks plus `gsd-validate-phase` results | ❌ Wave 0 artifacts needed [VERIFIED: `159-CONTEXT.md`; VERIFIED: `.planning/v1.37-MILESTONE-AUDIT.md`] |
| TEST-01 | Characterization chronology is proven only with parent-SHA test presence + passing result, otherwise waived explicitly | Git topology + focused test execution | detached parent probe recorded per extraction | ❌ Wave 0 evidence inventory needed [VERIFIED: `159-CONTEXT.md`] |
| Closure | Candidate revision passes deterministic bundle and has same-SHA required hosted jobs/artifact | local integration + hosted CI | D-18 bundle, then hosted `ci.yml` receipt | ❌ execution receipt needed [VERIFIED: `159-CONTEXT.md`] |

### Sampling Rate

- **Per code/documentation task commit:** focused workflow-wiring test plus actionlint when `ci.yml` changes; Markdown link/field review when evidence files change. [VERIFIED: `159-CONTEXT.md`; VERIFIED: `CONTRIBUTING.md`]
- **Per wave merge:** `mix verify.core --exclude integration --exclude docs_contract`, `mix verify.repository_contracts`, and all relevant phase-local validation checks. [VERIFIED: `159-CONTEXT.md`]
- **Phase gate:** D-18 local bundle and one exact-SHA hosted `ci.yml` run with required jobs green and coverage artifact retained. [VERIFIED: `159-CONTEXT.md`]

### Wave 0 Gaps

- [ ] Extend `test/mix/tasks/workflow_wiring_test.exs` with a job-scoped coverage wiring contract. [VERIFIED: `159-CONTEXT.md`]
- [ ] Create canonical Phase 159 Markdown matrix and short Phase 148–158 retrospective indexes. [VERIFIED: `159-CONTEXT.md`]
- [ ] Produce per-phase `VALIDATION.md` only after that phase's retrospective summary and verification are evidence-backed. [VERIFIED: `159-CONTEXT.md`; VERIFIED: `.planning/config.json`]
- [ ] Create reproducible parent-SHA probe inventory and final local/hosted closure receipt. [VERIFIED: `159-CONTEXT.md`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | no | No new authentication surface; do not add tokens/services. [VERIFIED: `159-CONTEXT.md`] |
| V3 Session Management | no | No runtime session surface changes. [VERIFIED: `159-CONTEXT.md`] |
| V4 Access Control | yes | Preserve workflow `permissions: contents: read`; do not broaden privileges for artifacts. [VERIFIED: `.github/workflows/ci.yml`; VERIFIED: `159-CONTEXT.md`] |
| V5 Input Validation | yes | Strict Mix task arguments and structural assertions constrain repository configuration inputs. [VERIFIED: `lib/mix/tasks/verify.coverage.ex`; VERIFIED: `test/mix/tasks/workflow_wiring_test.exs`] |
| V6 Cryptography | no | No cryptographic feature; SHA values identify source/action revisions but are not a new crypto implementation. [VERIFIED: `159-CONTEXT.md`] |

### Known Threat Patterns for GitHub Actions evidence

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Mutable third-party action reference | Tampering | Reuse existing full-SHA action pin and executable pin/syntax checks. [VERIFIED: `.github/workflows/ci.yml`; VERIFIED: `.planning/QUALITY-LEDGER.md`] |
| Artifact presented as successful proof after producer failure | Repudiation / Tampering | Record job/step conclusion separately; `if: always()` guarantees collection, not success. [VERIFIED: `159-CONTEXT.md`] |
| Historical claim unsupported by stored facts | Repudiation | Use explicit evidence classes, exact SHAs, and fail-closed waivers. [VERIFIED: `159-CONTEXT.md`] |
| Workflow privilege creep | Elevation of Privilege | Retain read-only default permissions and avoid tokens/attestation/services. [VERIFIED: `.github/workflows/ci.yml`; VERIFIED: `159-CONTEXT.md`] |

## Sources

### Primary (HIGH confidence)

- Repository sources: `.github/workflows/ci.yml`, `lib/mix/tasks/verify.coverage.ex`, `test/mix/tasks/workflow_wiring_test.exs`, `mix.exs`, and `CONTRIBUTING.md` — existing CI/task/contract patterns. [VERIFIED: codebase]
- `.planning/v1.37-MILESTONE-AUDIT.md` and `159-CONTEXT.md` — audit gap, locked closure boundary, and evidence policy. [VERIFIED: codebase]
- [Git commit objects](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects.html) — tree snapshot and parent topology. [CITED: https://git-scm.com/book/en/v2/Git-Internals-Git-Objects.html]

### Secondary (MEDIUM confidence)

- [GitHub Actions artifacts](https://docs.github.com/actions/configuring-and-managing-workflows/persisting-workflow-data-using-artifacts?azure-portal=true) — artifact retention support. [CITED: https://docs.github.com/actions/configuring-and-managing-workflows/persisting-workflow-data-using-artifacts?azure-portal=true]
- [GitHub Actions contexts](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts) — `github.event_name` job guard pattern. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/contexts]
- [Mix test](https://mix.hexdocs.pm/Mix.Tasks.Test.html) — default coverage tool, `cover` output, and threshold semantics. [CITED: https://mix.hexdocs.pm/Mix.Tasks.Test.html]

### Tertiary (LOW confidence)

- None, except Assumption A1, which is isolated and not a planning decision. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all recommended components already exist in the repository; no external dependency is proposed. [VERIFIED: codebase]
- Architecture: HIGH — locked decisions prescribe the evidence separation and the codebase supplies both CI and verification-report analogues. [VERIFIED: `159-CONTEXT.md`; VERIFIED: codebase]
- Pitfalls: HIGH — the milestone audit documents the two actual failure modes; A1 is separately marked LOW. [VERIFIED: `.planning/v1.37-MILESTONE-AUDIT.md`]

**Research date:** 2026-08-26
**Valid until:** 2026-09-25 (repository patterns are stable; verify GitHub action/docs semantics again if execution is delayed). [ASSUMED]
