# Phase 111: Advisory Proof Stability Decision - Research

**Researched:** 2026-05-31
**Domain:** CI governance and evidence-based promotion policy for `phase105-e2e`
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Keep `phase105-e2e` advisory for Phase 111. Do not promote it to a required merge gate now.
- **D-02:** The reason for staying advisory is evidentiary, not philosophical: recent remote CI history reviewed through `gh` did not show enough `phase105-e2e` job outcomes to prove stable run behavior, likely because the workflow job exists locally ahead of `origin/main`.
- **D-03:** Lock the posture as "harden advisory with evidence collection plus prepare a future promotion path." This preserves the repo's lean required-gate contract while making promotion possible later if the lane earns it.
- **D-04:** Do not remove or replace `phase105-e2e`. It protects true browser/live-services behavior that service-free tests and narrower integration lanes cannot fully prove.
- **D-05:** Use a dual-window evidence model when evaluating future promotion:
  - `main` and scheduled workflow runs are the canonical stability source.
  - PR runs are the merge-risk source.
- **D-06:** Evidence must be tied to workflow run, commit SHA, event, job name, conclusion, runtime, retry/flaky signal, and failure classification. Local runs can inform debugging but are not sufficient promotion evidence by themselves.
- **D-07:** If the workflow file or job identity changes, planners must treat pre-change and post-change evidence separately unless the change is explicitly proven equivalent.
- **D-08:** Future required-check promotion requires all existing promotion criteria to be satisfied together: stable job name, sustained low flake rate, bounded runtime, actionable artifacts, owner response expectations, and explicit trigger rules.
- **D-09:** Treat Playwright retries as flake detection, not as a way to hide instability. A pass-after-retry should count as a flaky signal for promotion evaluation.
- **D-10:** Prefer a graduated promotion path: advisory evidence collection -> short "shadow required" period with documented owner response and rollback criteria -> required branch-protection promotion only after evidence passes.
- **D-11:** Do not use scoped/path-based required promotion for Phase 111. It creates trigger ambiguity and can miss cross-cutting regressions. If considered later, it needs dedicated trigger-policy proof.
- **D-12:** Define "actionable artifacts" as enough evidence to classify the failure without an immediate rerun.
- **D-13:** The advisory lane should capture a layered triage bundle on failure:
  - Playwright HTML report, traces, screenshots/videos where available, and `test-results`.
  - Phoenix app log for the example server.
  - Meilisearch `/health` and filtered task state relevant to the run.
  - Readiness/data setup snapshot sufficient to distinguish fixture, queue-drain, search-visibility, and operator-state failures.
- **D-14:** Avoid full diagnostic dumps by default. Artifact collection should be structured and bounded so it improves maintainer triage without creating noisy, sensitive, or expensive uploads.
- **D-15:** Routine required gates remain lean: `main-ci`, `repo-hygiene`, `release-truth`, and `phase99-trust`.
- **D-16:** `phase105-e2e` can remain on PR, push, schedule, and manual triggers as advisory evidence, but Phase 111 must not add branch-protection requirements.
- **D-17:** Documentation and tests should make the advisory/required split explicit so contributors are not surprised by what blocks merge.

### the agent's Discretion
- Planner may choose the exact evidence artifact implementation, such as a small shell script, workflow summary step, generated JSON/Markdown evidence record, or focused ExUnit/docs contract assertions.
- Planner may choose exact numeric thresholds if they are explicit, conservative, and easy to audit. Suggested shape: minimum run count or time window, flake classification that treats retry-pass as flaky, p95 runtime envelope within the 20-minute timeout, and owner-response expectation before promotion.
- Planner may add route/documentation checks that ensure `CONTRIBUTING.md`, `.github/workflows/ci.yml`, and any support/readiness surfaces agree on the advisory posture.

### Deferred Ideas (OUT OF SCOPE)
- Promoting `phase105-e2e` to a required branch-protection check is deferred until the documented evidence thresholds are met.
- Scoped/path-based required promotion is deferred because trigger ambiguity and skipped-required-check behavior need their own proof.
- Full diagnostic artifact dumps are deferred unless repeated advisory failures prove the layered triage bundle is insufficient.
- Replacing `phase105-e2e` with a different proof lane is deferred; current evidence supports hardening rather than removal.
- New runtime APIs, product-surface changes, public backend broadening, autocomplete/suggestions, vector/hybrid, and broader website truth alignment remain outside Phase 111.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| STAB-01 | Evidence-based advisory/required decision using outcomes, flake/runtime, artifacts, owner response | Evidence model, scorecard fields, artifact/actionability criteria, and trigger/owner checks below |
| STAB-02 | Required gates remain lean unless promotion is justified | Current required-gate inventory and explicit non-promotion posture with graduated path |
</phase_requirements>

## Summary

`phase105-e2e` should remain advisory in Phase 111 and be hardened as an evidence lane, not promoted as a required gate yet. [VERIFIED: `.planning/phases/111-advisory-proof-stability-decision/111-CONTEXT.md`] [VERIFIED: `CONTRIBUTING.md`]  
Current remote CI evidence shows recent `ci.yml` runs without a `phase105-e2e` job in job listings, so there is not enough contiguous run history to justify required-gate promotion. [VERIFIED: `gh run list --workflow ci.yml --limit 25 --json ...`] [VERIFIED: `gh run view <run_id> --json jobs`]

The planning target should be: codify collection of promotion-grade evidence (run metadata, retry-derived flake signal, runtime envelope, artifact actionability, owner response), and enforce docs/workflow truth alignment with deterministic tests. [VERIFIED: `.planning/REQUIREMENTS.md`] [VERIFIED: `.github/workflows/ci.yml`] [VERIFIED: `test/scrypath/phase108_contract_test.exs`]

**Primary recommendation:** Plan Phase 111 as a policy-and-proof hardening slice that keeps branch protection unchanged while producing auditable promotion readiness evidence for a future decision window.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| CI lane execution (`phase105-e2e`) | Frontend Server (SSR) | API / Backend | Workflow orchestrates Phoenix app + browser flow; app and backend services are dependencies, not policy owners. [VERIFIED: `.github/workflows/ci.yml`] |
| Advisory vs required gate policy | API / Backend | Frontend Server (SSR) | Branch/gate policy is repository automation governance, not browser logic. [VERIFIED: `CONTRIBUTING.md`] |
| Promotion evidence ledger | API / Backend | Database / Storage | Evidence artifacts and metadata are generated/retained by workflow and artifacts store. [VERIFIED: `.github/workflows/ci.yml`] |
| Failure artifact triage | Frontend Server (SSR) | API / Backend | Browser + app logs + search health are captured at workflow runtime and interpreted by maintainers. [VERIFIED: `.github/workflows/ci.yml`] |
| Required-gate lean posture enforcement | API / Backend | — | Contract tests and docs define which jobs block merges. [VERIFIED: `test/mix/tasks/workflow_wiring_test.exs`] [VERIFIED: `CONTRIBUTING.md`] |

## Project Constraints (from AGENTS.md)

- Keep `main` green with lean required gates; do not introduce speculative heavy blockers. [VERIFIED: `AGENTS.md`]
- Follow `CONTRIBUTING.md` verification and CI/release gates for any changes. [VERIFIED: `AGENTS.md`]
- Preserve maintenance-and-evidence posture and avoid broadening product scope in this phase. [VERIFIED: `AGENTS.md`] [VERIFIED: `.planning/REQUIREMENTS.md`]
- Consult local `prompts/` material when decisions touch CI/CD and OSS release practices. [VERIFIED: `AGENTS.md`]

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| GitHub Actions workflow (`ci.yml`) | repo-defined | Canonical CI source of truth for gates and advisory lanes | Branch-protection and run evidence are controlled here. [VERIFIED: `.github/workflows/ci.yml`] |
| GitHub CLI (`gh`) | 2.93.0 | Query recent workflow/job evidence for STAB decisions | Directly inspects remote run history. [VERIFIED: `gh --version`; `gh run list`; `gh run view`] |
| ExUnit contract tests | repo-defined | Enforce docs/workflow posture alignment | Existing pattern for gate-policy truth checks. [VERIFIED: `test/mix/tasks/workflow_wiring_test.exs`; `test/scrypath/phase108_contract_test.exs`] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Playwright config | repo-defined | Retry/worker/reporter behavior used for flake signal | Needed when interpreting retry-as-flake and artifact usefulness. [VERIFIED: `examples/scrypath_ecommerce/playwright.config.ts`] |
| `actions/upload-artifact` | v7 | Persist triage bundle on failure | Needed to make advisory failures actionable without rerun. [VERIFIED: `.github/workflows/ci.yml`] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Advisory hardening now | Immediate required promotion | Violates current evidence posture; insufficient recent job history. [VERIFIED: `111-CONTEXT.md`; `gh run view ... jobs`] |
| Deterministic contract tests | Manual periodic review only | Less repeatable; greater drift risk between docs and workflow. [VERIFIED: `test/mix/tasks/workflow_wiring_test.exs`] |

## Architecture Patterns

### System Architecture Diagram
```text
GitHub event (push/PR/schedule/manual)
  -> ci.yml workflow
    -> required gates (main-ci/repo-hygiene/release-truth/phase99-trust)
    -> advisory phase105-e2e lane
      -> start services (Postgres, Meilisearch) + Phoenix
      -> run Playwright suite
      -> on failure upload artifacts (report/results/logs)
        -> maintainer triage + response expectation
          -> evidence ledger for future promotion decision
```

### Recommended Project Structure
```text
.github/workflows/ci.yml                    # Canonical gate + advisory lane wiring
CONTRIBUTING.md                             # Contributor-visible gate posture + criteria
test/mix/tasks/workflow_wiring_test.exs     # Required gate wiring truth tests
test/scrypath/phase111_contract_test.exs    # New focused phase111 posture/evidence contract tests
scripts/ci/phase105_evidence.(sh|exs)       # Optional evidence extraction helper
```

### Pattern 1: Dual-Window Evidence Scoring
**What:** Separate canonical stability (`main` + schedule) from merge-risk signal (PR). [VERIFIED: `111-CONTEXT.md`]  
**When to use:** Required-check promotion decisions.  
**Example:**
```text
for each phase105-e2e run:
  collect {run_id, sha, event, job_name, conclusion, duration, retry_signal, artifact_presence}
aggregate by window:
  canonical = main+schedule
  merge_risk = pull_request
promotion only if both windows satisfy thresholds
```

### Anti-Patterns to Avoid
- **Promoting from sparse or mixed-identity data:** Require stable job identity and sufficient run window before promotion calls. [VERIFIED: `111-CONTEXT.md`]
- **Treating retry-pass as clean pass:** Retry-pass must remain flaky signal. [VERIFIED: `111-CONTEXT.md`] [VERIFIED: `examples/scrypath_ecommerce/playwright.config.ts`]
- **Changing required gates in this phase:** Conflicts with STAB-02 lean posture. [VERIFIED: `.planning/REQUIREMENTS.md`] [VERIFIED: `CONTRIBUTING.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| CI run history source | Custom scraper DB/service | `gh run list` + `gh run view` | Native API-backed evidence with less maintenance. [VERIFIED: `gh run list`; `gh run view`] |
| Gate-policy enforcement | Human-memory checklist | ExUnit contract tests against docs/workflow text | Deterministic and reviewable in CI. [VERIFIED: `test/mix/tasks/workflow_wiring_test.exs`] |
| Flake detection primitive | Ad hoc heuristics detached from runner | Existing Playwright retry semantics + explicit classification | Reuses current behavior and avoids hidden logic drift. [VERIFIED: `examples/scrypath_ecommerce/playwright.config.ts`] |

## Common Pitfalls

### Pitfall 1: Workflow-Level Status Mistaken for Job-Level Stability
**What goes wrong:** Success/failure of `ci.yml` is used as proxy for `phase105-e2e` readiness.  
**Why it happens:** Workflow has many jobs; job-level evidence may be absent. [VERIFIED: `gh run view <run_id> --json jobs`]  
**How to avoid:** Require explicit per-job records for `phase105-e2e`.  
**Warning signs:** `ci.yml` passes, but no `phase105-e2e` job appears in run jobs.

### Pitfall 2: Advisory Lane with Non-Actionable Artifacts
**What goes wrong:** Failures require rerun before classification.  
**Why it happens:** Missing or noisy artifact bundle.  
**How to avoid:** Enforce bounded triage bundle (report/results/Phoenix log + minimal readiness/search state). [VERIFIED: `111-CONTEXT.md`] [VERIFIED: `.github/workflows/ci.yml`]  
**Warning signs:** Repeated “cannot classify” owner comments.

## Code Examples

### Existing advisory lane characteristics
```yaml
phase105-e2e:
  timeout-minutes: 20
  services: [postgres, meilisearch]
  steps:
    - wait for postgres/meilisearch/app readiness
    - run npm run test:e2e
    - upload artifacts on failure
```
Source: [CITED: `.github/workflows/ci.yml`]

### Existing retry semantics used for flake signal
```ts
retries: process.env.CI ? 1 : 0,
workers: process.env.CI ? 1 : undefined,
trace: "on-first-retry"
```
Source: [CITED: `examples/scrypath_ecommerce/playwright.config.ts`]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Broad “make E2E required” aspiration | Evidence-gated advisory hardening first | Prior phases through 2026-05-31 | Preserves lean merge blockers and reduces false blockage risk. [VERIFIED: `.planning/STATE.md`] [VERIFIED: `111-CONTEXT.md`] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A new `phase111_contract_test.exs` is the best place for STAB-specific guardrails | Architecture Patterns | Medium: planner may choose existing test file instead |

## Open Questions

1. **What numeric threshold defines “sustained low flake” for promotion readiness?**
   - What we know: Thresholds are intentionally left to planner discretion. [VERIFIED: `111-CONTEXT.md`]
   - What's unclear: Required minimum run count/window.
   - Recommendation: Choose explicit minimums in plan and lock them in phase output.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `gh` | Remote CI evidence collection | ✓ | 2.93.0 | Manual GitHub UI run inspection |
| `jq` | Evidence parsing | ✓ | 1.7.1 | Shell text parsing (lower quality) |
| `node` | Optional evidence scripts | ✓ | v22.14.0 | Elixir/shell script |
| `mix` | Contract tests | ✓ | OTP 28 / Elixir runtime present | — |

**Missing dependencies with no fallback:**
- None.

**Missing dependencies with fallback:**
- None.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (project standard) |
| Config file | `mix.exs` / `test/test_helper.exs` |
| Quick run command | `mix test test/mix/tasks/workflow_wiring_test.exs -x` |
| Full suite command | `mix test --exclude integration --exclude docs_contract --include requires_clean_workspace` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| STAB-01 | Evidence-based advisory decision criteria remain explicit and auditable | contract | `mix test test/scrypath/phase111_contract_test.exs -x` | ❌ Wave 0 |
| STAB-02 | Required gates stay lean and advisory split remains documented | contract | `mix test test/mix/tasks/workflow_wiring_test.exs -x` | ✅ |

### Sampling Rate
- **Per task commit:** `mix test test/mix/tasks/workflow_wiring_test.exs -x`
- **Per wave merge:** `mix test --exclude integration --exclude docs_contract --include requires_clean_workspace`
- **Phase gate:** Full suite green before `$gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/scrypath/phase111_contract_test.exs` — codify STAB-specific advisory/promotion rules and artifact expectations

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | N/A (no auth-surface change) |
| V3 Session Management | no | N/A |
| V4 Access Control | yes | Keep branch protection unchanged; no new required gate escalation in this phase |
| V5 Input Validation | yes | Contract tests for workflow/docs truth reduce policy drift |
| V6 Cryptography | no | N/A |

### Known Threat Patterns for CI-gate governance

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| False promotion from sparse evidence | Tampering | Require explicit minimum evidence window and stable job identity |
| Hidden flake masked by retries | Repudiation | Classify retry-pass as flaky signal |
| Contributor confusion about blockers | DoS | Keep required/advisory contract explicit in docs + tests |

## Sources

### Primary (HIGH confidence)
- [CITED: `.planning/phases/111-advisory-proof-stability-decision/111-CONTEXT.md`] - locked decisions, discretion, deferred scope
- [CITED: `.planning/REQUIREMENTS.md`] - STAB-01/STAB-02 requirement text
- [CITED: `.planning/STATE.md`] - current phase posture/history
- [CITED: `.github/workflows/ci.yml`] - actual job topology, `phase105-e2e` wiring, artifact behavior
- [CITED: `CONTRIBUTING.md`] - required-gate posture and promotion criteria
- [CITED: `examples/scrypath_ecommerce/playwright.config.ts`] - retry/worker/trace/reporter policy
- [CITED: `test/mix/tasks/workflow_wiring_test.exs`] - existing required-gate wiring contracts
- [CITED: `test/scrypath/phase108_contract_test.exs`] - explicit advisory posture contract precedent
- [VERIFIED: `gh run list --workflow ci.yml --limit 25 --json ...`] - recent remote run inventory
- [VERIFIED: `gh run view <run_id> --json jobs`] - job-level absence/presence evidence for `phase105-e2e`

### Secondary (MEDIUM confidence)
- [CITED: `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md`] - lean required-gate guidance for OSS release trains

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Derived from repository CI/docs/tests plus direct remote run inspection
- Architecture: HIGH - Responsibilities map directly to existing workflow and gate contracts
- Pitfalls: HIGH - Based on observed job-level evidence gaps and existing advisory design

**Research date:** 2026-05-31
**Valid until:** 2026-06-30
