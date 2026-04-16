# Phase 10: Launch Verification and Release Confidence - Research

**Researched:** 2026-04-16 [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md]
**Domain:** Elixir OSS release verification, maintainer release confidence, and milestone evidence bookkeeping [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: docs/releasing.md] [VERIFIED: .github/workflows/ci.yml] [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: mix.exs]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Verification entrypoint
- **D-01:** Phase 10 should introduce one thin canonical maintainer entrypoint for auth-free release-confidence checks, following the existing `mix verify.phase*` pattern rather than relying on prose-only command lists.
- **D-02:** The Phase 10 verification entrypoint should mirror the non-publishing release gate that maintainers can run locally; it should not own tagging, release creation, or Hex publishing.
- **D-03:** CI and `release-please` remain the source of truth for automated release execution. The local Phase 10 command exists to reduce maintainer friction and keep the release-confidence contract obvious.

### Release proof depth
- **D-04:** `SHIP-01` should be satisfied with a hybrid proof model: the auth-free CI/package gate must pass, and a maintainer must also run `HEX_API_KEY=... mix hex.publish --dry-run --yes` on the same release candidate commit.
- **D-05:** A synthetic tagged-release rehearsal is out of scope for Phase 10. For a Hex library, it adds ceremony and divergence risk without enough additional truth.
- **D-06:** The first real tagged release is the production confirmation path; pre-launch proof should focus on the real CI/package gate, the documented publish workflow, and one credentialed dry-run.

### Evidence packaging
- **D-07:** Launch-readiness evidence should use a hybrid packaging model.
- **D-08:** `10-VERIFICATION.md` should be the concrete proof surface for Phase 10, recording what was run, what passed, what remained manual/live, and which artifacts support the launch-readiness claim.
- **D-09:** `docs/releasing.md` should remain the stable maintainer runbook. It may link to current verification artifacts, but it should not become the milestone evidence ledger.
- **D-10:** A v1.1 milestone audit or launch-readiness summary should be the canonical maintainer-facing index that points to the hardening evidence from Phases 8 through 10 and states what remains intentionally deferred.

### Milestone-close bookkeeping
- **D-11:** Phase 10 should use a hybrid closeout shape: keep canonical status ownership in `.planning/STATE.md`, `.planning/ROADMAP.md`, and `.planning/REQUIREMENTS.md`, but add one explicit audit-style milestone closeout artifact that records what was hardened, what was verified, and what remains intentionally deferred.
- **D-12:** The closeout artifact should be evidence-oriented and link-heavy rather than narrative-heavy. It should point to exact verification artifacts and phase outputs instead of restating implementation detail already captured in summaries.
- **D-13:** The closeout artifact must preserve original requirement and phase ownership. Phase 10 may verify and summarize prior hardening work, but it must not make earlier phases look like they shipped in Phase 10.
- **D-14:** Deferred items must stay visible and explicitly categorized as intentional carry-forward or advisory follow-up, not buried in prose. Launch-readiness bookkeeping should answer "what is still open and why is it acceptable now?" in one place.
- **D-15:** Public-facing release surfaces should stay lightweight. The stronger bookkeeping belongs in planning and maintainer artifacts, while public release notes and package metadata stay focused on the user-visible release story.

### Claude's Discretion
- Exact naming and file layout for the Phase 10 verification command, as long as it stays visibly parallel to `mix verify.phase5` and `mix verify.phase8`.
- Exact scope of the auth-free verification command, provided it mirrors the real non-publishing release gate and does not absorb credentialed publish behavior.
- Exact filename and formatting of the Phase 10 closeout artifact, as long as it is easy to find from milestone-level planning files.
- Whether the milestone closeout artifact is named as an audit, verification report, or launch-readiness summary, provided it clearly distinguishes verified scope, deferred items, and evidence links.

### Deferred Ideas (OUT OF SCOPE)
- Full staging-style release rehearsals or throwaway tagged-release drills before launch.
- Broader process redesign outside Phase 10, such as changing the whole planning system or archival model across all milestones.
- Trusted publishing redesign or cross-ecosystem credential model changes beyond the current Hex/GitHub Actions setup.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SHIP-01 | Maintainer can verify the release path from CI/package checks through GitHub Actions Hex publishing with canonical source and package metadata. [VERIFIED: .planning/REQUIREMENTS.md] | Reuse the existing CI quality/package gate, Release Please publish workflow, package metadata contract test, and release runbook behind one thin `mix verify.phase10` mirror plus one manual `mix hex.publish --dry-run --yes` proof step. [VERIFIED: .github/workflows/ci.yml] [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: test/release/package_metadata_test.exs] [VERIFIED: docs/releasing.md] |
| SHIP-02 | Maintainer can point to current verification artifacts for the hardening work and the remaining launch-readiness surface without milestone bookkeeping gaps. [VERIFIED: .planning/REQUIREMENTS.md] | Add a phase proof artifact at `.planning/phases/10-launch-verification-and-release-confidence/10-VERIFICATION.md` and a milestone index at `.planning/v1.1-MILESTONE-AUDIT.md`, then update the active milestone bookkeeping files to point to them while preserving Phase 08 and Phase 09 ownership. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] [VERIFIED: .planning/v1.0-MILESTONE-AUDIT.md] [VERIFIED: .planning/STATE.md] |
</phase_requirements>

## Summary

Phase 10 should stay extremely small. The repo already has the substantive release-confidence machinery: a CI quality job that builds docs, runs the package metadata contract, and unpacks the Hex tarball; a Release Please workflow that gates Hex publish on `release_created == true`; a maintainer runbook that separates auth-free checks from credentialed publish validation; and prior phase-specific verification tasks that establish the local `mix verify.phase*` pattern. [VERIFIED: .github/workflows/ci.yml] [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: docs/releasing.md] [VERIFIED: lib/mix/tasks/verify.phase5.ex] [VERIFIED: lib/mix/tasks/verify.phase8.ex]

The smallest credible Phase 10 slice is therefore not a simulated release system. It is a thin local mirror of the non-publishing release gate, a concrete phase verification report that records one real dry-run credential check on the candidate commit, and one explicit milestone audit that indexes the hardened evidence from Phases 08 through 10 without reassigning ownership. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] [VERIFIED: .planning/v1.0-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-03-SUMMARY.md] [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-03-SUMMARY.md]

Current local baseline is already healthy for the auth-free portion: `mix test test/release/package_metadata_test.exs test/scrypath/docs_contract_test.exs`, `mix docs --warnings-as-errors`, `mix hex.build --unpack`, `mix verify.phase8 --skip-integration`, and `mix verify.phase5 --skip-integration` all passed in this session, while `HEX_API_KEY` is absent locally and therefore the credentialed dry-run remains intentionally manual evidence. [VERIFIED: local command mix test test/release/package_metadata_test.exs test/scrypath/docs_contract_test.exs] [VERIFIED: local command mix docs --warnings-as-errors] [VERIFIED: local command mix hex.build --unpack] [VERIFIED: local command mix verify.phase8 --skip-integration] [VERIFIED: local command mix verify.phase5 --skip-integration] [VERIFIED: local command if [ -n "$HEX_API_KEY" ]; then echo present; else echo absent; fi]

**Primary recommendation:** Implement Phase 10 as two execution slices and one bookkeeping slice: `mix verify.phase10`, `10-VERIFICATION.md`, and `.planning/v1.1-MILESTONE-AUDIT.md`, then update the active milestone status files to point at those artifacts. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] [VERIFIED: .planning/v1.0-MILESTONE-AUDIT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Auth-free release gate mirror | Local maintainer CLI [VERIFIED: lib/mix/tasks/verify.phase5.ex] [VERIFIED: lib/mix/tasks/verify.phase8.ex] | GitHub Actions quality job [VERIFIED: .github/workflows/ci.yml] | The command exists to mirror the existing non-publishing gate locally and reduce maintainer friction; CI remains the automated source of truth. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] |
| Credentialed publish proof | Local maintainer CLI [VERIFIED: docs/releasing.md] | Hex service [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] | The publish dry-run requires `HEX_API_KEY` and must stay out of the always-on CI gate. [VERIFIED: docs/releasing.md] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |
| Automated tag-and-publish execution | GitHub Actions release workflow [VERIFIED: .github/workflows/release-please.yml] | Release Please metadata/config [VERIFIED: release-please-config.json] [VERIFIED: .release-please-manifest.json] | Tagged release creation and Hex publishing are already owned by Release Please plus the gated publish job, not by a local Mix task. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] [VERIFIED: .github/workflows/release-please.yml] |
| Phase proof artifact | Planning artifacts [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] | Release runbook [VERIFIED: docs/releasing.md] | `10-VERIFICATION.md` should record what ran and what remained manual without turning the runbook into an evidence ledger. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] |
| Milestone launch-readiness index | Planning artifacts [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] | Phase 08/09 evidence [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-VALIDATION.md] [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-VALIDATION.md] | The milestone audit should aggregate links, preserve original ownership, and make deferred items explicit in one place. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ExUnit and Mix test tasks | Repo standard `Mix 1.19.5` / `Elixir 1.19.5` locally, library floor `~> 1.17` in project config [VERIFIED: local command mix --version] [VERIFIED: local command elixir --version] [VERIFIED: mix.exs] | Run focused release-confidence checks and existing phase verification tasks. [VERIFIED: lib/mix/tasks/verify.phase5.ex] [VERIFIED: lib/mix/tasks/verify.phase8.ex] | Existing phase verification commands already use Mix as the canonical local maintainer entrypoint. [VERIFIED: lib/mix/tasks/verify.phase5.ex] [VERIFIED: lib/mix/tasks/verify.phase8.ex] |
| ExDoc | Repo dependency `~> 0.37` [VERIFIED: mix.exs] | Build docs with warnings as errors as part of the auth-free release gate. [VERIFIED: .github/workflows/ci.yml] | The CI quality gate and release runbook both already require `mix docs --warnings-as-errors`. [VERIFIED: .github/workflows/ci.yml] [VERIFIED: docs/releasing.md] |
| Hex build/publish tasks | Hex docs viewed at `v2.2.1` in current official docs [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] | Build tarball locally, inspect included files, and perform credentialed publish dry-run. [VERIFIED: docs/releasing.md] [VERIFIED: .github/workflows/ci.yml] | Hex officially documents `--dry-run` as local checks without publishing and `--yes` as noninteractive publish. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |
| GitHub Actions + Release Please | Repo pins `actions/checkout@v4`, `erlef/setup-beam@v1`, and `googleapis/release-please-action@v4` [VERIFIED: .github/workflows/ci.yml] [VERIFIED: .github/workflows/release-please.yml] | Automate CI, release PRs, tagged releases, and gated Hex publishing. [VERIFIED: .github/workflows/ci.yml] [VERIFIED: .github/workflows/release-please.yml] | The existing workflows already embody the desired release path; Phase 10 should mirror them, not replace them. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `test/release/package_metadata_test.exs` | Repo-local test module [VERIFIED: test/release/package_metadata_test.exs] | Lock homepage/source/source_ref/package links and maintainer docs metadata. [VERIFIED: test/release/package_metadata_test.exs] | Always in `mix verify.phase10`; it is the package trust-signal contract. [VERIFIED: .github/workflows/ci.yml] |
| `test/scrypath/docs_contract_test.exs` | Repo-local test module [VERIFIED: test/scrypath/docs_contract_test.exs] | Keep release docs wording and auth-free gate contract aligned with CI and the runbook. [VERIFIED: test/scrypath/docs_contract_test.exs] | Include in `mix verify.phase10` because the release gate depends on the wording staying true. [VERIFIED: test/scrypath/docs_contract_test.exs] |
| `mix verify.phase5` and `mix verify.phase8` | Repo-local Mix tasks [VERIFIED: lib/mix/tasks/verify.phase5.ex] [VERIFIED: lib/mix/tasks/verify.phase8.ex] | Provide precedent for fast-first, optional-integration verification commands with `preferred_envs`. [VERIFIED: lib/mix/tasks/verify.phase5.ex] [VERIFIED: mix.exs] | Use as the exact pattern template for Phase 10. [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-03-SUMMARY.md] |
| `docs/releasing.md` | Repo-local runbook [VERIFIED: docs/releasing.md] | Stable maintainer instructions for local gate, dry-run publish, and manual review. [VERIFIED: docs/releasing.md] | Update only to point at the new Phase 10 command and proof artifacts; do not turn it into an evidence log. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Thin local mirror of CI gate [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] | Full synthetic release rehearsal [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] | The context explicitly rules the rehearsal out because it adds ceremony and divergence without enough extra truth for a Hex library. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] |
| Milestone audit index [VERIFIED: .planning/v1.0-MILESTONE-AUDIT.md] | Narrative launch blog-style summary | The audit pattern already exists locally and better preserves requirement ownership plus deferred-item visibility. [VERIFIED: .planning/v1.0-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] |
| Auth-free CI gate plus manual dry-run [VERIFIED: docs/releasing.md] | Put `HEX_API_KEY` into the always-on gate | The repo already rejects that boundary and keeps credentialed publish validation maintainer-only. [VERIFIED: docs/releasing.md] [VERIFIED: test/scrypath/docs_contract_test.exs] |

**Installation:**
```bash
# No new runtime dependencies are recommended for Phase 10.
# Reuse the existing Mix, ExDoc, Hex, and GitHub Actions stack already present in the repo.
```

## Architecture Patterns

### System Architecture Diagram
```text
Maintainer branch / candidate commit
  |
  v
mix verify.phase10
  |
  +--> focused release-contract tests
  |       - package metadata contract
  |       - docs contract release wording
  |
  +--> mix docs --warnings-as-errors
  |
  +--> mix hex.build --unpack
  |       |
  |       v
  |    package contents inspection
  |
  +--> optional delegations or spot checks
          - mix verify.phase8 --skip-integration
          - mix verify.phase5 --skip-integration
  |
  v
10-VERIFICATION.md
  |
  +--> records auth-free gate results
  +--> links manual HEX_API_KEY dry-run result
  +--> links Phase 08 and Phase 09 evidence
  |
  v
.planning/v1.1-MILESTONE-AUDIT.md
  |
  +--> states hardened scope
  +--> preserves original phase ownership
  +--> lists deferred follow-up
  |
  v
STATE.md / ROADMAP.md / REQUIREMENTS.md updates

In parallel on main:
push -> CI quality job -> Release Please workflow -> release_created? -> tagged checkout -> mix hex.publish --yes
```

### Recommended Project Structure
```text
.planning/
├── phases/10-launch-verification-and-release-confidence/
│   ├── 10-RESEARCH.md        # This research artifact
│   ├── 10-VALIDATION.md      # Nyquist validation contract for execution
│   └── 10-VERIFICATION.md    # Phase 10 proof ledger
├── v1.1-MILESTONE-AUDIT.md   # Launch-readiness index for Phases 08-10
├── ROADMAP.md                # Phase 10 completion status and milestone summary
├── REQUIREMENTS.md           # SHIP-01 / SHIP-02 completion traceability
└── STATE.md                  # Current milestone position and artifact pointers

lib/mix/tasks/
└── verify.phase10.ex         # Thin auth-free release gate mirror

docs/
└── releasing.md              # Stable runbook with links to current proof artifacts
```

### Pattern 1: Thin Phase Verification Task
**What:** Add a `Mix.Tasks.Verify.Phase10` task that mirrors the current auth-free release gate and stays visibly parallel to Phase 5 and Phase 8. [VERIFIED: lib/mix/tasks/verify.phase5.ex] [VERIFIED: lib/mix/tasks/verify.phase8.ex]
**When to use:** Use for maintainer preflight on a release candidate commit and as the canonical command referenced from `docs/releasing.md` and `10-VERIFICATION.md`. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] [VERIFIED: docs/releasing.md]
**Example:**
```elixir
# Source: lib/mix/tasks/verify.phase5.ex and lib/mix/tasks/verify.phase8.ex
defmodule Mix.Tasks.Verify.Phase10 do
  use Mix.Task

  @shortdoc "Runs the automated Phase 10 release-confidence gate"

  @impl true
  def run(_args) do
    Mix.Task.run("app.start")

    run_test!(
      [
        "test/release/package_metadata_test.exs",
        "test/scrypath/docs_contract_test.exs"
      ],
      "Phase 10 release-confidence tests"
    )

    Mix.shell().info("==> Building docs with warnings as errors")
    Mix.Task.reenable("docs")
    Mix.Task.run("docs", ["--warnings-as-errors"])

    Mix.shell().info("==> Building and unpacking Hex package")
    Mix.Task.reenable("hex.build")
    Mix.Task.run("hex.build", ["--unpack"])
  end

  defp run_test!(args, label) do
    Mix.shell().info("==> Running #{label}")
    Mix.Task.reenable("test")
    Mix.Task.run("test", args)
  end
end
```

### Pattern 2: Evidence-by-Link, Not Evidence-by-Restatement
**What:** Keep Phase 10 artifacts short and index-like: Phase 10 should link to Phase 08 and Phase 09 validation and summary artifacts instead of restating those phases as newly delivered work. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-VALIDATION.md] [VERIFIED: .planning/phases/09-public-docs-and-example-safety/09-VALIDATION.md]
**When to use:** Use in `10-VERIFICATION.md`, `.planning/v1.1-MILESTONE-AUDIT.md`, and completion updates to `STATE.md`, `ROADMAP.md`, and `REQUIREMENTS.md`. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md]
**Example:**
```markdown
## Hardening Evidence Index

- Phase 08 reliability hardening: `08-VALIDATION.md`, `08-03-SUMMARY.md`
- Phase 09 docs safety hardening: `09-VALIDATION.md`, `09-03-SUMMARY.md`
- Phase 10 release confidence: `10-VERIFICATION.md`

## Deferred / Carry-Forward

- Live Meilisearch verification still depends on reachable `SCRYPATH_MEILISEARCH_URL`
- Credentialed publish proof requires a maintainer-owned `HEX_API_KEY`
```

### Pattern 3: Runbook Stays Stable, Proof Stays Current
**What:** Keep `docs/releasing.md` as the stable operational guide and put per-run evidence into `10-VERIFICATION.md`. [VERIFIED: docs/releasing.md] [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md]
**When to use:** Any time current results would otherwise be pasted into the runbook. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md]
**Example:**
````markdown
## Automated Release Gate

Run:

```bash
mix verify.phase10
```

Current release-candidate evidence:
- See `.planning/phases/10-launch-verification-and-release-confidence/10-VERIFICATION.md`
````

### Anti-Patterns to Avoid
- **Local release simulator:** The context explicitly rejects synthetic tagged-release rehearsals for Phase 10. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md]
- **Credential leakage into CI:** Do not move `HEX_API_KEY` into the always-on auth-free gate. [VERIFIED: docs/releasing.md] [VERIFIED: test/scrypath/docs_contract_test.exs]
- **Ownership drift in milestone closeout:** Do not let the v1.1 audit imply that Phase 08 or Phase 09 work shipped in Phase 10. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] [VERIFIED: .planning/v1.0-MILESTONE-AUDIT.md]
- **Duplicated evidence prose:** Repeating prior phase details in multiple artifacts increases the chance of stale bookkeeping. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Release orchestration | Custom tagging and changelog automation | Existing Release Please manifest workflow [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: release-please-config.json] | Release Please already owns release PRs, tags, and gated publish flow in this repo. [VERIFIED: .github/workflows/release-please.yml] |
| Package inspection logic | Custom tarball parser or ad hoc shell sprawl | Existing `mix hex.build --unpack` plus package metadata tests [VERIFIED: docs/releasing.md] [VERIFIED: test/release/package_metadata_test.exs] | The current CI gate already uses this path, and Hex documents `--dry-run` / local checks separately from publish. [VERIFIED: .github/workflows/ci.yml] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |
| New verification framework | Bespoke release runner outside Mix | `mix verify.phase*` task pattern [VERIFIED: lib/mix/tasks/verify.phase5.ex] [VERIFIED: lib/mix/tasks/verify.phase8.ex] | The repo already standardizes phase verification through Mix tasks plus `preferred_envs`. [VERIFIED: mix.exs] |
| Milestone status model | New archival or bookkeeping system | Existing audit plus status-file updates [VERIFIED: .planning/v1.0-MILESTONE-AUDIT.md] [VERIFIED: .planning/STATE.md] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] | The current planning system already treats stale bookkeeping as a real launch blocker. [VERIFIED: .planning/STATE.md] [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] |

**Key insight:** Phase 10 should connect existing verified seams into one obvious maintainer story rather than adding new runtime behavior. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] [VERIFIED: .github/workflows/ci.yml] [VERIFIED: docs/releasing.md]

## Common Pitfalls

### Pitfall 1: CI and local gate drift
**What goes wrong:** `mix verify.phase10` checks a different set of things than the CI quality job, so local green does not mean release-candidate green. [VERIFIED: .github/workflows/ci.yml] [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md]
**Why it happens:** It is tempting to add convenience checks or omit package checks when building a new task. [VERIFIED: lib/mix/tasks/verify.phase5.ex] [VERIFIED: lib/mix/tasks/verify.phase8.ex]
**How to avoid:** Mirror the current auth-free release gate exactly: package metadata contract test, docs contract test, docs build, and Hex package build/unpack. [VERIFIED: .github/workflows/ci.yml] [VERIFIED: docs/releasing.md]
**Warning signs:** The runbook lists commands that `mix verify.phase10` does not run, or CI contains release-gate commands absent from the local task. [VERIFIED: docs/releasing.md] [VERIFIED: .github/workflows/ci.yml]

### Pitfall 2: Evidence artifact turns into a second runbook
**What goes wrong:** `10-VERIFICATION.md` accumulates instructions instead of results, and `docs/releasing.md` becomes stale or redundant. [VERIFIED: docs/releasing.md] [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md]
**Why it happens:** Execution notes and stable instructions are easy to mix together during milestone closeout. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md]
**How to avoid:** Keep the runbook imperative and timeless; keep `10-VERIFICATION.md` timestamped and evidence-oriented. [VERIFIED: docs/releasing.md] [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md]
**Warning signs:** Release docs start mentioning one-off command outputs, dates, or specific candidate commits. [VERIFIED: docs/releasing.md]

### Pitfall 3: Milestone audit steals ownership from earlier phases
**What goes wrong:** The v1.1 audit reads like Phase 10 delivered reliability and docs hardening, which breaks requirement traceability. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] [VERIFIED: .planning/v1.0-MILESTONE-AUDIT.md]
**Why it happens:** Aggregation work naturally summarizes earlier accomplishments, and narrative wording blurs who shipped what. [VERIFIED: .planning/v1.0-MILESTONE-AUDIT.md]
**How to avoid:** Phrase the audit as an index of evidence and status, with direct links to Phase 08 and 09 artifacts and explicit ownership tables. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md]
**Warning signs:** Requirement tables or issue lists in the audit attribute `HARD-*` or `DOCS-*` completion to Phase 10 instead of referencing Phase 08 or 09. [VERIFIED: .planning/REQUIREMENTS.md]

### Pitfall 4: Credential boundary gets blurred
**What goes wrong:** Maintainers cannot tell which checks are safe for CI and which need publisher credentials. [VERIFIED: docs/releasing.md] [VERIFIED: test/scrypath/docs_contract_test.exs]
**Why it happens:** `mix hex.build`, `mix hex.publish --dry-run`, and `mix hex.publish --yes` are adjacent commands and easy to conflate. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]
**How to avoid:** Keep `mix verify.phase10` strictly auth-free and record the dry-run as a separate manual verification step in `10-VERIFICATION.md`. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] [VERIFIED: docs/releasing.md]
**Warning signs:** CI docs start referencing `HEX_API_KEY` for routine checks, or the phase command starts requiring credentials. [VERIFIED: docs/releasing.md]

## Code Examples

Verified patterns from official and repo sources, plus one explicitly marked recommended wrapper:

### Recommended Local Release Gate Wrapper
```bash
# Recommended Phase 10 wrapper around the existing auth-free gate [ASSUMED]
mix verify.phase10
```

### Credentialed Publish Dry-Run
```bash
# Source: docs/releasing.md and Hex docs
HEX_API_KEY=... mix hex.publish --dry-run --yes
```

### Gated Publish Workflow Shape
```yaml
# Source: .github/workflows/release-please.yml
publish-hex:
  needs: release-please
  if: ${{ needs.release-please.outputs.release_created == 'true' }}
  env:
    HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
  steps:
    - uses: actions/checkout@v4
      with:
        ref: ${{ needs.release-please.outputs.tag_name }}
    - uses: erlef/setup-beam@v1
      with:
        elixir-version: "1.19.0"
        otp-version: "28.0"
    - run: mix deps.get
    - run: mix hex.publish --yes
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Human command checklist only for release gate [VERIFIED: docs/releasing.md] | Canonical phase-scoped Mix verification tasks for milestone-specific concerns [VERIFIED: lib/mix/tasks/verify.phase5.ex] [VERIFIED: lib/mix/tasks/verify.phase8.ex] | Phase 5 and Phase 8 established the pattern in this repo. [VERIFIED: lib/mix/tasks/verify.phase5.ex] [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-03-SUMMARY.md] | Phase 10 should continue the same shape instead of inventing another release-control style. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] |
| Release docs as the only maintainer memory [VERIFIED: docs/releasing.md] | Stable runbook plus timestamped proof artifacts and milestone audit index [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] [VERIFIED: .planning/v1.0-MILESTONE-AUDIT.md] | v1.0 audit repair made missing evidence and stale bookkeeping material. [VERIFIED: .planning/v1.0-MILESTONE-AUDIT.md] | Phase 10 should keep evidence discoverable months later without bloating the runbook. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] |
| Single-source faith in `GITHUB_TOKEN` workflow chaining [CITED: https://github.com/marketplace/actions/release-please-action] | Explicit understanding that Release Please outputs gate publish, while downstream workflow triggering may require a PAT in other setups [CITED: https://github.com/marketplace/actions/release-please-action] | Current Release Please docs warn that resources created with `GITHUB_TOKEN` do not trigger future workflows. [CITED: https://github.com/marketplace/actions/release-please-action] | This repo’s current single-workflow gated publish pattern avoids needing a second workflow trigger for Hex publish. [VERIFIED: .github/workflows/release-please.yml] |

**Deprecated/outdated:**
- Synthetic pre-release rehearsals for this phase: explicitly out of scope in the locked phase context. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md]
- Letting milestone evidence exist only in summaries or commit history: v1.0 audit precedent shows that stale or missing bookkeeping is treated as a real blocker. [VERIFIED: .planning/v1.0-MILESTONE-AUDIT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `rg -n "Phase 08|Phase 09|Phase 10|Deferred" .planning/v1.1-MILESTONE-AUDIT.md` will be the simplest useful smoke command for the new milestone index artifact. [ASSUMED] | Validation Architecture | Low - planner can replace it with a different artifact-check command without changing implementation scope. |
| A2 | `mix verify.phase10` is the best final command name for the new local release-confidence wrapper. [ASSUMED] | Code Examples | Low - the planner can rename the task while keeping the same thin scope and artifact model. |

## Open Questions

1. **Should `mix verify.phase10` include `mix verify.phase5 --skip-integration` and `mix verify.phase8 --skip-integration`, or should it stay limited to package/docs release checks plus optional references?**
   - What we know: Phase 10 should stay thin, and the auth-free release gate today is package/docs oriented rather than a full regression suite. [VERIFIED: .github/workflows/ci.yml] [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md]
   - What's unclear: The context calls for current evidence for the hardened surface, but it does not explicitly require Phase 10 to nest earlier phase commands. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md]
   - Recommendation: Keep `mix verify.phase10` limited to release-confidence checks and record Phase 08/09 evidence by link; only add nested phase commands if the planner needs one-command convenience and can keep runtimes low. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] [VERIFIED: local command mix verify.phase8 --skip-integration] [VERIFIED: local command mix verify.phase5 --skip-integration]

2. **Should the milestone closeout artifact be named `.planning/v1.1-MILESTONE-AUDIT.md` or a launch-readiness summary?**
   - What we know: The repo already has `.planning/v1.0-MILESTONE-AUDIT.md`, and the context permits audit, verification report, or launch-readiness summary naming. [VERIFIED: .planning/v1.0-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md]
   - What's unclear: Naming is discretionary, but discoverability from milestone-level files matters. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md]
   - Recommendation: Reuse `.planning/v1.1-MILESTONE-AUDIT.md` to match local precedent and make archive transition obvious. [VERIFIED: .planning/v1.0-MILESTONE-AUDIT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix verification tasks and docs build [VERIFIED: mix.exs] | ✓ [VERIFIED: local command elixir --version] | `1.19.5` locally [VERIFIED: local command elixir --version] | — |
| Mix | Test/docs/package commands [VERIFIED: docs/releasing.md] | ✓ [VERIFIED: local command mix --version] | `1.19.5` locally [VERIFIED: local command mix --version] | — |
| Git | Release Please / source metadata workflows [VERIFIED: .github/workflows/release-please.yml] | ✓ [VERIFIED: local command git --version] | `2.41.0` locally [VERIFIED: local command git --version] | — |
| Docker | Optional local Meilisearch follow-up verification only [VERIFIED: .planning/STATE.md] | ✓ [VERIFIED: local command docker --version] | `29.3.1` locally [VERIFIED: local command docker --version] | Use existing reachable Meilisearch endpoint instead of local Docker. [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-03-SUMMARY.md] |
| curl | Meilisearch readiness checks in CI/local integration flows [VERIFIED: .github/workflows/ci.yml] | ✓ [VERIFIED: local command curl --version | head -1] | `8.7.1` locally [VERIFIED: local command curl --version | head -1] | — |
| `HEX_API_KEY` | Manual publish dry-run proof [VERIFIED: docs/releasing.md] | ✗ in this session [VERIFIED: local command if [ -n "$HEX_API_KEY" ]; then echo present; else echo absent; fi] | — | No auth-free fallback; record as manual maintainer evidence. [VERIFIED: docs/releasing.md] |

**Missing dependencies with no fallback:**
- `HEX_API_KEY` for the credentialed `mix hex.publish --dry-run --yes` proof step. [VERIFIED: docs/releasing.md] [VERIFIED: local command if [ -n "$HEX_API_KEY" ]; then echo present; else echo absent; fi]

**Missing dependencies with fallback:**
- None for the auth-free Phase 10 gate; all required local tools for the non-publishing checks are present in this session. [VERIFIED: local command mix test test/release/package_metadata_test.exs test/scrypath/docs_contract_test.exs] [VERIFIED: local command mix docs --warnings-as-errors] [VERIFIED: local command mix hex.build --unpack]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit under `test/test_helper.exs`. [VERIFIED: test/test_helper.exs] |
| Config file | `test/test_helper.exs`. [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/release/package_metadata_test.exs test/scrypath/docs_contract_test.exs -x` [VERIFIED: test/release/package_metadata_test.exs] [VERIFIED: test/scrypath/docs_contract_test.exs] |
| Full suite command | `mix test` [VERIFIED: test/test_helper.exs] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SHIP-01 | Package metadata, docs metadata, and release docs wording stay aligned with the publish flow. [VERIFIED: test/release/package_metadata_test.exs] [VERIFIED: test/scrypath/docs_contract_test.exs] | unit/contract | `mix test test/release/package_metadata_test.exs test/scrypath/docs_contract_test.exs -x` [VERIFIED: local command mix test test/release/package_metadata_test.exs test/scrypath/docs_contract_test.exs] | ✅ [VERIFIED: test/release/package_metadata_test.exs] [VERIFIED: test/scrypath/docs_contract_test.exs] |
| SHIP-01 | Docs still build cleanly and tarball still unpacks with expected package surface. [VERIFIED: docs/releasing.md] [VERIFIED: .github/workflows/ci.yml] | command | `mix docs --warnings-as-errors && mix hex.build --unpack` [VERIFIED: local command mix docs --warnings-as-errors] [VERIFIED: local command mix hex.build --unpack] | ✅ command path [VERIFIED: docs/releasing.md] |
| SHIP-01 | Credentialed publish path is proven without a real release. [VERIFIED: docs/releasing.md] | manual-only | `HEX_API_KEY=... mix hex.publish --dry-run --yes` [VERIFIED: docs/releasing.md] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] | ❌ manual evidence in `10-VERIFICATION.md` [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] |
| SHIP-02 | Maintainer can find current hardening evidence and deferred items from one milestone index. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] | artifact review | `rg -n "Phase 08|Phase 09|Phase 10|Deferred" .planning/v1.1-MILESTONE-AUDIT.md` [ASSUMED] | ❌ Wave 0 [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] |

### Sampling Rate
- **Per task commit:** `mix test test/release/package_metadata_test.exs test/scrypath/docs_contract_test.exs -x` [VERIFIED: test/release/package_metadata_test.exs] [VERIFIED: test/scrypath/docs_contract_test.exs]
- **Per wave merge:** `mix verify.phase10` once added. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md]
- **Phase gate:** `mix verify.phase10` plus one recorded `HEX_API_KEY=... mix hex.publish --dry-run --yes` on the candidate commit. [VERIFIED: docs/releasing.md] [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md]

### Wave 0 Gaps
- [ ] `lib/mix/tasks/verify.phase10.ex` — canonical auth-free release-confidence command. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md]
- [ ] `mix.exs` — register `"verify.phase10": :test` under `preferred_envs` so nested Mix tasks run in test env. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/08-reliability-and-contract-hardening/08-03-SUMMARY.md]
- [ ] `.planning/phases/10-launch-verification-and-release-confidence/10-VALIDATION.md` — Nyquist validation contract for SHIP-01 and SHIP-02. [VERIFIED: .planning/config.json]
- [ ] `.planning/phases/10-launch-verification-and-release-confidence/10-VERIFICATION.md` — current proof ledger including dry-run evidence. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md]
- [ ] `.planning/v1.1-MILESTONE-AUDIT.md` — milestone index for Phases 08 through 10 and deferred carry-forward items. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] [VERIFIED: .planning/v1.0-MILESTONE-AUDIT.md]

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [VERIFIED: docs/releasing.md] | Keep `HEX_API_KEY` confined to manual dry-run or the gated publish job only. [VERIFIED: docs/releasing.md] [VERIFIED: .github/workflows/release-please.yml] |
| V3 Session Management | no [VERIFIED: phase scope in .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] | — |
| V4 Access Control | yes [VERIFIED: .github/workflows/release-please.yml] [CITED: https://github.com/marketplace/actions/release-please-action] | Minimal GitHub Actions permissions and publish-job-only secret scope. [VERIFIED: .github/workflows/release-please.yml] [CITED: https://github.com/marketplace/actions/release-please-action] |
| V5 Input Validation | yes [VERIFIED: test/release/package_metadata_test.exs] [VERIFIED: test/scrypath/docs_contract_test.exs] | Contract tests on package metadata and release-doc wording. [VERIFIED: test/release/package_metadata_test.exs] [VERIFIED: test/scrypath/docs_contract_test.exs] |
| V6 Cryptography | no direct phase logic [VERIFIED: phase scope in .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] | Use Hex/GitHub credential systems as provided; do not hand-roll secret handling. [VERIFIED: docs/releasing.md] |

### Known Threat Patterns for This Stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Accidental secret exposure in routine CI | Information Disclosure | Keep `HEX_API_KEY` out of the always-on CI gate and only in the gated publish job or a maintainer shell. [VERIFIED: docs/releasing.md] [VERIFIED: .github/workflows/release-please.yml] |
| Publishing from the wrong ref or unreviewed version | Tampering | Checkout the released tag in the publish job and record the candidate commit/tag in `10-VERIFICATION.md`. [VERIFIED: .github/workflows/release-please.yml] [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] |
| Stale or misleading release evidence | Repudiation | Keep timestamped phase verification and milestone audit artifacts linked from status files. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] [VERIFIED: .planning/v1.0-MILESTONE-AUDIT.md] |

## Sources

### Primary (HIGH confidence)
- `docs/releasing.md` - Maintainer runbook, auth-free gate, dry-run boundary, and manual review checklist. [VERIFIED: docs/releasing.md]
- `.github/workflows/ci.yml` - Current auth-free quality/package gate shape. [VERIFIED: .github/workflows/ci.yml]
- `.github/workflows/release-please.yml` - Current automated tag-and-publish workflow. [VERIFIED: .github/workflows/release-please.yml]
- `mix.exs` - Preferred envs, package metadata, docs extras, and version floor. [VERIFIED: mix.exs]
- `test/release/package_metadata_test.exs` - Package trust-signal contract. [VERIFIED: test/release/package_metadata_test.exs]
- `test/scrypath/docs_contract_test.exs` - Release-doc and CI wording contract. [VERIFIED: test/scrypath/docs_contract_test.exs]
- `lib/mix/tasks/verify.phase5.ex` and `lib/mix/tasks/verify.phase8.ex` - Canonical local verification task pattern. [VERIFIED: lib/mix/tasks/verify.phase5.ex] [VERIFIED: lib/mix/tasks/verify.phase8.ex]
- `.planning/v1.0-MILESTONE-AUDIT.md` - Local milestone audit precedent and ownership-preservation pattern. [VERIFIED: .planning/v1.0-MILESTONE-AUDIT.md]
- `.planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md` - Locked Phase 10 scope and artifact decisions. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md]

### Secondary (MEDIUM confidence)
- Release Please action docs - outputs, manifest-mode guidance, and workflow-trigger caveat with `GITHUB_TOKEN`. [CITED: https://github.com/marketplace/actions/release-please-action]
- Hex publish docs - `--yes`, `--dry-run`, and docs publishing behavior. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]
- `erlef/setup-beam` docs - strict version-file behavior and exact-version examples. [CITED: https://github.com/erlef/setup-beam]

### Tertiary (LOW confidence)
- None. All material recommendations were verified locally, against repo sources, or against official docs. [VERIFIED: docs/releasing.md] [VERIFIED: .github/workflows/ci.yml] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - the phase reuses already-checked-in workflows, Mix tasks, and docs, with official docs only needed to confirm Release Please and Hex behavior boundaries. [VERIFIED: .github/workflows/ci.yml] [VERIFIED: .github/workflows/release-please.yml] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]
- Architecture: HIGH - the desired slice boundaries and artifact model are locked in the Phase 10 context and strongly reinforced by repo precedent. [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md] [VERIFIED: .planning/v1.0-MILESTONE-AUDIT.md]
- Pitfalls: HIGH - the major risks are visible directly in the current runbook, workflows, and prior milestone audit history. [VERIFIED: docs/releasing.md] [VERIFIED: .planning/v1.0-MILESTONE-AUDIT.md]

**Research date:** 2026-04-16 [VERIFIED: .planning/phases/10-launch-verification-and-release-confidence/10-CONTEXT.md]
**Valid until:** 2026-05-16 for repo-local planning guidance, sooner if the release workflows or Hex/Release Please docs change. [VERIFIED: .github/workflows/ci.yml] [VERIFIED: .github/workflows/release-please.yml] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]

## RESEARCH COMPLETE
