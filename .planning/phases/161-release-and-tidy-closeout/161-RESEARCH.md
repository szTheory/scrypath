<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Dependency Security and Exact-SHA Proof
- **D-01:** Include remediation of the Mint advisories found in Phase 160's `deep-quality` run in Phase 161. Upgrade the dependency graph to Mint 1.10.1 or later, confirm the reported advisories are cleared, and rerun required checks on the resulting exact commit SHA.
- **D-02:** Keep the security fix scoped to dependency remediation and its evidence; do not broaden the library's runtime or public API scope.

### Release Endpoint
- **D-03:** Target an actually published release when merge and publisher authorization, secrets, and services are available. Follow the documented Release Please path and require its Hex, HexDocs, and tag/source parity evidence before describing the milestone as shipped.
- **D-04:** If an external release prerequisite blocks publication, complete all checks that can run, label the result `release-ready`, and record the specific blocker and exact resume action. Never report an unpublished release as shipped.

### the agent's Discretion
- Select the smallest compatible Mint dependency update and determine the appropriate lockfile/graph changes from repository constraints.
- Choose the verification and documentation-contract checks that provide machine-verifiable coverage of the phase requirements.
- Clean up only resources demonstrably owned by this milestone; preserve and report unrelated or pre-existing working-tree changes.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within the Phase 161 scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOC-01 | Adopter-facing and maintainer documentation accurately states what package-backed proof exercises, how to run it, its service prerequisites, and what synthetic evidence does and does not establish. | Current package-proof implementation, canonical adopter runbook, docs contract test, and source guidance are identified below. [VERIFIED: .planning/REQUIREMENTS.md:17] |
| HYGIENE-01 | Milestone changes remain idiomatic and self-documenting; affected canonical docs and examples match executable behavior, and final review finds no stale planning narration, temporary scaffolding, or task-owned generated debris. | Docs contract and `mix verify.package` cover package/doc agreements; closeout inventory and ownership checks are specified below. [VERIFIED: .planning/REQUIREMENTS.md:18] |
| REL-01 | Before the milestone is reported shipped, milestone PRs are reviewed and triaged, required checks pass on the exact final commit, `main` is verified green after merge, and the documented Release Please/Hex/HexDocs path confirms the released package, changelog, docs, tag, and source agree through post-publish verification. | CI closeout helper, required job list, release workflow, and publish/parity verification commands are already present. [VERIFIED: .planning/REQUIREMENTS.md:22] |
| CLOSE-01 | Milestone-owned branches, worktrees, service stacks, generated artifacts, and working-tree changes are cleaned up; unrelated or pre-existing user changes are preserved and reported. If a release dependency blocks publication, all available checks finish and the milestone is reported as release-ready with the specific blocker and resume action, never as shipped. | Scope-safe inventory and exact release-ready fallback are defined by phase context; current unrelated dirt is recorded below. [VERIFIED: .planning/REQUIREMENTS.md:23] |
</phase_requirements>

# Phase 161: Release and Tidy Closeout - Research

**Researched:** 2026-09-24  
**Domain:** Elixir dependency remediation, package-backed adopter documentation, exact-SHA CI, Hex release operations, and milestone closeout  
**Confidence:** HIGH for repository workflow and advisories; MEDIUM for external publication prerequisites until release execution

## Summary

Phase 161 closes the v1.38 milestone by updating one transitive dependency graph, documenting the package proof truthfully, and producing exact-final-SHA release evidence. The Phase 160 summary reports the required checks and package-backed Phoenix proof passed on `7931271abe53e83261d85a22077176f75898eb81`, while advisory `mix hex.audit` reported three Mint 1.9.3 findings. [VERIFIED: .planning/phases/160-package-backed-phoenix-proof/160-03-SUMMARY.md:62-107]

The Mint findings resolve to published Mint 1.10.1: OSV lists 1.10.1 as the fixed version for EEF-CVE-2026-82672, and versions 1.10.0+ for EEF-CVE-2026-82729 and EEF-CVE-2026-82728; the Hex package page listed 1.10.1 as current when checked. [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-82672] [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-82729] [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-82728] [CITED: https://hex.pm/packages/mint]

**Primary recommendation:** Keep the patch dependency-only: resolve Mint to at least `1.10.1` in the existing lock graph, rerun `mix verify.deep_quality`, then candidate and final closeout on their exact SHAs. Extend the existing docs contract and align canonical adopter/maintainer copy to the executable package flow. Complete publication only through the existing Release Please workflow; if a merge, publisher key, or service is unavailable, finish attainable checks and record a concrete `release-ready` resume action. [VERIFIED: .planning/phases/161-release-and-tidy-closeout/161-CONTEXT.md:16-27] [VERIFIED: mix.lock:19,26] [CITED: https://hex.pm/docs/publish]

Verbatim sources for the selected values: D-01 says DATA_5c87b0ad_START Upgrade the dependency graph to Mint 1.10.1 or later, confirm the reported advisories are cleared, and rerun required checks on the resulting exact commit SHA. DATA_5c87b0ad_END; D-04 says DATA_dab011fc_START label the result `release-ready` DATA_dab011fc_END [VERIFIED: .planning/phases/161-release-and-tidy-closeout/161-CONTEXT.md:17,22]. The current lock entry is DATA_30c78d4e_START "mint": {:hex, :mint, "1.9.3" DATA_30c78d4e_END [VERIFIED: mix.lock:26].

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Dependency remediation and audit | Build / CI | Mix dependency graph | Mint is currently locked transitively through Finch; `mix verify.deep_quality` owns no-optional-dependency, namespace, Hex audit, and Dialyzer checks. [VERIFIED: mix.lock:19,26] [VERIFIED: CONTRIBUTING.md:37] |
| Package-proof documentation truth | Maintainer and adopter docs | Contract tests | The Phoenix example README is the detailed prerequisite/runbook source; docs contract tests already bind CI command order, env prerequisites, and path dependency. [VERIFIED: examples/phoenix_meilisearch/README.md:5-7,39-48] [VERIFIED: test/scrypath/docs_contract_test.exs:702-728] |
| Candidate and final acceptance evidence | GitHub Actions | Local closeout coordinator | `scripts/ci_monitor.cjs` pins a full SHA, selects a new dispatch run at that SHA, and checks the five required jobs plus closeout artifacts. [VERIFIED: scripts/ci_monitor.cjs:10-16,119-209] |
| Version and tag generation | GitHub Actions / Release Please | `mix.exs`, manifest, changelog | Release Please owns version bump, changelog PR, and tag; Hex publication checks out that tag. [VERIFIED: docs/releasing.md:3-5,98-123] |
| Package and docs publication | Hex / HexDocs | Release workflow | `mix hex.publish --yes` publishes package and generated docs; post-publish tasks verify package visibility, consumer compilation, versioned docs reachability, and tarball-to-tag parity. [VERIFIED: docs/releasing.md:57-65] [CITED: https://hex.pm/docs/publish] |
| Milestone cleanup | Git/worktree and service owners | Closeout record | Cleanup must be based on branch/worktree/temp/service ownership; unrelated changes found at research start must survive and be reported. [VERIFIED: .planning/phases/161-release-and-tidy-closeout/161-CONTEXT.md:24-27] |

## Project Constraints (from AGENTS.md)

- Follow `CONTRIBUTING.md` for verification tasks, CI, and release gates; keep changes focused and run the checks it names. Update `.planning/PROJECT.md` only if intentionally changing product scope or shipped claims. [VERIFIED: AGENTS.md:90-94]
- Keep `main` green on lean required gates, prefer PR-first work, and base completion on executable tests or exact-SHA hosted evidence. Do not simulate review or approvals. [VERIFIED: AGENTS.md:96-103]
- Release policy is squash-merge/PR-title driven. Keep release mechanics centralized in `docs/releasing.md`; use auth-free `mix verify.package` as the normal gate and reserve credential-bearing publish commands for authorized release runs. [VERIFIED: CONTRIBUTING.md:20-24] [VERIFIED: docs/releasing.md:21-55]
- Preserve unrelated or pre-existing working-tree changes during closeout. The worktree and current branch must be inventoried before deleting anything. [VERIFIED: .planning/phases/161-release-and-tidy-closeout/161-CONTEXT.md:24-27]
- Project skills discovery found no `.codex/skills/` or `.agents/skills/` project skill; config has an empty `agent_skills` map and AGENTS.md says “No project skills found.” [VERIFIED: .planning/config.json:47] [VERIFIED: AGENTS.md:81-85]

## Standard Stack

### Core

| Tool / package | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Elixir / OTP in CI | `1.19.0` / `28.1` | Run required and release jobs | CI and the release workflow explicitly use these versions. Verbatim CI tuple: DATA_44c25ee1_START {elixir-version: "1.19.0", otp-version: "28.1"} DATA_44c25ee1_END [VERIFIED: .github/workflows/ci.yml:24-27] [VERIFIED: .github/workflows/release-please.yml:55-58] |
| Mint | `>= 1.10.1` for this graph | Clear the three Mint findings | Hex currently publishes 1.10.1; OSV shows it covers the three named fixes. `mint` is transitive via Finch, whose locked requirement is `~> 1.8`; preserve dependency ownership unless solver evidence requires another compatible graph adjustment. [VERIFIED: mix.lock:19,26] [CITED: https://hex.pm/packages/mint] [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-82672] [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-82729] [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-82728] |
| Release Please Action | `v5.0.0` pinned SHA | Reviewable version/changelog/tag flow | Existing workflow consumes manifest config and only runs the Hex publisher when Release Please reports a created release. Verbatim action ref: DATA_6aa770ad_START uses: googleapis/release-please-action@45996ed1f6d02564a971a2fa1b5860e934307cf7 # v5.0.0 DATA_6aa770ad_END [VERIFIED: .github/workflows/release-please.yml:33-39] [CITED: https://github.com/googleapis/release-please-action] |
| GitHub Actions + `erlef/setup-beam` | Existing pinned actions; Beam `1.19.0` / OTP `28.1` | Exact-SHA CI and publishing | Reuse the existing workflow rather than create parallel release automation. [VERIFIED: .github/workflows/ci.yml:1-70] [VERIFIED: .github/workflows/release-please.yml:55-59] |
| Hex / HexDocs / ExDoc | Existing root Mix release configuration | Publish package and generated docs | Hex documents automatic docs publication with package publication and recommends checking `mix docs` before release. [VERIFIED: mix.exs:107-122] [CITED: https://hex.pm/docs/publish] |

### Supporting

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `mix verify.package` | Auth-free package, consumer, docs, and release contract gate | Before a Release Please PR merge and as package-truth validation. [VERIFIED: docs/releasing.md:21-29] |
| `mix verify.deep_quality` | No-optional-deps compile, namespace fence, `mix hex.audit`, Dialyzer | After Mint graph remediation; distinguish its advisory CI status from the required merge gates. Source literal: DATA_68b6bdf0_START `mix verify.deep_quality` — No-optional-deps, namespace, Hex audit, and Dialyzer checks DATA_68b6bdf0_END [VERIFIED: CONTRIBUTING.md:37] [VERIFIED: .github/workflows/ci.yml:134-150] |
| `node scripts/ci_monitor.cjs closeout` | Candidate/final exact-SHA hosted closeout | After pushing the candidate and again after all final tracking/evidence commits. [VERIFIED: CONTRIBUTING.md:67-83] [VERIFIED: scripts/ci_monitor.cjs:140-209] |
| `mix verify.release_publish X.Y.Z` | Polls Hex, compiles a clean consumer, checks versioned HexDocs reachability | Automatically after actual publication; also available for independent recheck. Source literal: DATA_daf747f5_START `mix verify.release_publish X.Y.Z` DATA_daf747f5_END [VERIFIED: docs/releasing.md:57-65] |
| `mix verify.release_parity X.Y.Z` | Compares the published tarball to the corresponding tag | Immediately after `verify.release_publish` and through the scheduled monitor. Source literal: DATA_f0197ad2_START `mix verify.release_parity X.Y.Z` DATA_f0197ad2_END [VERIFIED: docs/releasing.md:65,227-250] |
| `mix test test/scrypath/docs_contract_test.exs` | Focused docs/CI contract suite | Run when changing adopter or maintainer command/prerequisite/claims; this suite is optional and not part of default CI. Source literal: DATA_14538c24_START `mix test test/scrypath/docs_contract_test.exs` DATA_14538c24_END [VERIFIED: CONTRIBUTING.md:7] [VERIFIED: test/scrypath/docs_contract_test.exs:702-728,793-815] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Directly declaring Mint to force an override | Resolve the existing Finch-owned transitive Mint edge in the lock graph | A new direct dependency duplicates ownership and is unnecessary if Finch's existing `~> 1.8` range admits the fixed 1.x release. Only add a direct constraint if solver output proves it necessary and project policy permits it. [VERIFIED: mix.lock:19,26] [ASSUMED] |
| Manual release/tag/publish | Release Please, then the existing publish job | Manual tags bypass the reviewed changelog/version flow and weaken tag/source parity evidence. [VERIFIED: docs/releasing.md:98-123,146-155] |
| Treating passing PR CI or Phase 160 candidate SHA as final closeout | Run the closeout helper against the final full SHA | Any edits after evidence invalidate exact-SHA authority; the final attestation must follow all closeout artifact commits. [VERIFIED: CONTRIBUTING.md:67-83] |

**Installation:** No new package installation is required. Mint is already a transitive Hex dependency; change only the dependency graph/lockfile needed to resolve the approved floor. Source literals: DATA_34ce060b_START `{:mint, "~> 1.8", [hex: :mint, repo: "hexpm", optional: false]}` DATA_34ce060b_END and DATA_9627ac5a_START `"mint": {:hex, :mint, "1.9.3"` DATA_9627ac5a_END [VERIFIED: mix.lock:19,26].

## Package Legitimacy Audit

Not applicable: this phase is scoped to remediating the existing transitive dependency; no new package is recommended. Do not add a Mint direct dependency merely for the audit unless the solver demonstrates that the existing graph cannot satisfy the floor. [VERIFIED: .planning/phases/161-release-and-tidy-closeout/161-CONTEXT.md:16-18] [ASSUMED]

## Architecture Patterns

### System Architecture Diagram

```mermaid
flowchart LR
  PR[Reviewed milestone PRs] --> CI[CI at candidate SHA]
  CI -->|required jobs pass| Closeout[Exact-SHA closeout attestation]
  Closeout --> Final[Commit final tracking and verification evidence]
  Final --> Exact[CI closeout at final SHA]
  Exact --> Main[Merge; verify main is green]
  Main --> RP[Release Please PR: version and changelog]
  RP --> Tag[Release Please tag]
  Tag --> Pub[Hex publish workflow from tag]
  Pub --> H[Hex package and generated HexDocs]
  H --> Post[verify.release_publish]
  Post --> Parity[verify.release_parity: tarball vs tag]
  Parity -->|pass| Shipped[May report shipped]
  Pub -->|required external prerequisite missing| Ready[release-ready with blocker + resume action]
```

Diagram nodes mirror existing phases and Release Please workflow contracts. [VERIFIED: .planning/phases/161-release-and-tidy-closeout/161-CONTEXT.md:6-27] [VERIFIED: docs/releasing.md:98-123] [VERIFIED: .github/workflows/release-please.yml:41-94]

### Recommended Project Structure

No new source tree is needed. Expected touch points are current canonical documentation, its existing test contract, `mix.lock` if dependency resolution changes it, and Phase 161 planning/evidence artifacts. Avoid adding a new publish workflow or duplicate adopters' runbook. [VERIFIED: .planning/phases/161-release-and-tidy-closeout/161-CONTEXT.md:42-76] [VERIFIED: docs/releasing.md:1-5]

### Pattern 1: Remediate transitive security fixes with a scoped graph diff

**What:** Update the resolved graph so Mint is at or above the locked `1.10.1` floor, then run the advisory audit and project checks. Do not broaden runtime code/API scope. [VERIFIED: .planning/phases/161-release-and-tidy-closeout/161-CONTEXT.md:16-18] [CITED: https://hex.pm/packages/mint]

**When to use:** Mint remains transitive through Finch and dependency metadata accepts the fixed release. [VERIFIED: mix.lock:19,26]

**Example:**

```sh
mix deps.update mint
mix verify.deep_quality
```

`mix deps.update mint` is an **[ASSUMED]** implementation suggestion and has not been run; inspect the resolved graph before adopting it. The verified audit command literal is `DATA_8383161a_START mix verify.deep_quality DATA_8383161a_END` [VERIFIED: CONTRIBUTING.md:37], and the locked Finch edge is `DATA_f516b3cf_START {:mint, "~> 1.8", [hex: :mint, repo: "hexpm", optional: false]} DATA_f516b3cf_END` [VERIFIED: mix.lock:19].

### Pattern 2: Make package-backed proof claims match the tested boundary

**What:** Treat the package mode as a real-service integration proof of the local built artifact and staged clean consumer. Describe its tested inline, Oban, and related-data scenarios and required Postgres/Meilisearch services; say explicitly what synthetic/contract evidence establishes versus what it cannot establish. The Phase 160 evidence records ten passing tests and four scenarios against hosted services on the exact candidate SHA. [VERIFIED: .planning/phases/160-package-backed-phoenix-proof/160-03-SUMMARY.md:62-81] [VERIFIED: examples/phoenix_meilisearch/README.md:1-7,39-48]

**When to use:** Changes touch package-proof scope claims, prerequisites, synthetic evidence wording, or maintainer commands.

**Example:**

```sh
mix verify.phoenix_example
mix verify.phoenix_example --package
```

The first is the existing path-backed flow; the second stages an isolated example and verifies the current checkout's built package artifact. Both require `SCRYPATH_EXAMPLE_INTEGRATION`, `PGPORT`, `SCRYPATH_MEILISEARCH_URL`, and reachable Postgres/Meilisearch. Verbatim values: DATA_b214bbfe_START `mix verify.phoenix_example` and `mix verify.phoenix_example --package` DATA_b214bbfe_END; DATA_d368fba8_START `SCRYPATH_EXAMPLE_INTEGRATION=1`, `PGPORT`, and `SCRYPATH_MEILISEARCH_URL` DATA_d368fba8_END [VERIFIED: examples/phoenix_meilisearch/README.md:7,39-48].

### Pattern 3: Bind acceptance to exact final SHA

**What:** Record the candidate SHA/run evidence, finish and commit all tracking/verification files, then rerun the machine closeout on that exact final SHA. Do not change tracked files after the final successful closeout. [VERIFIED: CONTRIBUTING.md:67-83]

**Example:**

```sh
node scripts/ci_monitor.cjs closeout --push \
  --branch "$(git branch --show-current)" \
  --sha "$(git rev-parse HEAD)"
```

The helper validates a full SHA, requires origin to match it, selects a newly dispatched run at that SHA, checks each required job conclusion, and validates digest-bearing SHA-bound coverage and closeout artifacts. Verbatim helper invocation: DATA_2a22cb56_START node scripts/ci_monitor.cjs closeout --push
  --branch "$(git branch --show-current)"
  --sha "$(git rev-parse HEAD)" DATA_2a22cb56_END [VERIFIED: CONTRIBUTING.md:71-74] [VERIFIED: scripts/ci_monitor.cjs:119-209]

### Pattern 4: Publish via the generated Release Please tag

**What:** Release Please owns version/changelog/tag; publish workflow checks out the generated tag, runs the auth-free release contract, dry-run, publish, live publish verification, and parity check in order. Exact workflow values: DATA_e7207f30_START `release_created` DATA_e7207f30_END, DATA_aa431498_START `tag_name` DATA_aa431498_END, DATA_b296f239_START `mix hex.publish --yes` DATA_b296f239_END [VERIFIED: docs/releasing.md:5,111-112] [VERIFIED: .github/workflows/release-please.yml:18-53,75-94]

**When to use:** Release PR is reviewed and ready to merge and publisher authorization is available. [VERIFIED: docs/releasing.md:49-73,98-123]

**Example:** The exact helper outputs documented by Release Please are `release_created`, `tag_name`, `version`, and `sha`; the existing Scrypath workflow gates publication on `release_created` and checks out `tag_name`. [CITED: https://github.com/googleapis/release-please-action] [VERIFIED: .github/workflows/release-please.yml:18-53]

### Anti-Patterns to Avoid

- **Manually bumping or tagging around Release Please:** conflicts with the canonical changelog/version/tag stream. Fix source or rerun Release Please if the version, manifest, and changelog disagree. [VERIFIED: docs/releasing.md:98-112,134-155]
- **Calling an unpublished release “shipped”:** Hex, HexDocs, and parity checks have not happened until publication succeeds; use `release-ready` with blocker and exact resume action instead. [VERIFIED: .planning/phases/161-release-and-tidy-closeout/161-CONTEXT.md:20-22]
- **Leaking `HEX_API_KEY` into ordinary CI or local logs:** keep it scoped to publish jobs; the repository explicitly keeps credential-bearing dry-run out of always-on CI. [VERIFIED: docs/releasing.md:49-73]
- **Using success from a previous SHA as evidence for final source:** rerun candidate/final exact-SHA attestation after each set of changes. [VERIFIED: CONTRIBUTING.md:67-83]
- **Deleting by broad path/name match:** inspect ownership of branches, worktrees, compose services, and generated files individually; preserve initial unowned status entries. [VERIFIED: .planning/phases/161-release-and-tidy-closeout/161-CONTEXT.md:24-27]
- **Duplicating proof contracts in docs:** preserve the example README as the detailed local service/env runbook and make other docs point to it. [VERIFIED: examples/phoenix_meilisearch/README.md:5-7] [VERIFIED: CONTRIBUTING.md:98-100]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Conventional version/changelog/tag management | Manual version bumps and tag creation | Release Please's existing manifest-mode flow | The project's canonical flow ties the release PR, manifest, changelog, tag, and publish workflow. [VERIFIED: docs/releasing.md:98-112] |
| Final-SHA evidence collection | A manual checklist that only reads PR checks | `scripts/ci_monitor.cjs closeout` | It requires an exact full SHA, newly dispatched matching CI run, specific job conclusions, and digest-bearing SHA-bound artifacts. [VERIFIED: scripts/ci_monitor.cjs:119-209] |
| HexDocs reachability and package-source consistency | Hand-maintained publish checklist only | `mix verify.release_publish` and `mix verify.release_parity` | These are the repository's implemented post-publish probes and are called in the release workflow. [VERIFIED: docs/releasing.md:57-65] |
| Proof documentation drift checks | Broad grep alone | Extend `test/scrypath/docs_contract_test.exs` | Existing job-scoped contract asserts order, service setup, environment names, and normal path dependency. [VERIFIED: test/scrypath/docs_contract_test.exs:702-728] |
| Mint advisories | Custom audit script or runtime patch | `mix verify.deep_quality` / `mix hex.audit` after graph update | Existing deep-quality capability already runs Hex audit and advisory CI lane reports it. [VERIFIED: CONTRIBUTING.md:37] [VERIFIED: .github/workflows/ci.yml:134-150] |

**Key insight:** “Green” is not one signal in this milestone: required merge-gate status, advisory deep-quality status, exact-SHA closeout authority, and post-publish artifact parity are distinct evidence layers. Record each independently and only use shipped status after all release-specific checks pass. [VERIFIED: CONTRIBUTING.md:76-83,146-157] [VERIFIED: docs/releasing.md:111-123]

## Runtime State Inventory

This is a closeout phase, not a rename/migration phase; the five-category rename inventory does not apply. For CLOSE-01, still inventory milestone-owned branches/worktrees, running example services, generated artifacts, and changes before cleanup. The package-proof task's temporary workspace is created under the OS temp directory using the unique prefix `scrypath-phoenix-package-` and its code has ownership-checked removal; do not broaden cleanup beyond that owner. [VERIFIED: lib/mix/tasks/verify/phoenix_example/package.ex:204-237]

At research start, one worktree was listed for the current working directory and the current local branch was `gsd/v1.37-code-quality-ratchet`; this branch is not demonstrably a v1.38-owned cleanup target. Preserve these pre-existing status entries unless their owners explicitly establish otherwise: DATA_43ea128c_START  M .planning/phases/134-under-iterated-surface-polish-dual-theme-s/134-UAT.md DATA_43ea128c_END; DATA_0c4a3f90_START  M .planning/phases/136-milestone-verification-uat-s-g/136-UAT.md DATA_0c4a3f90_END; DATA_778a512d_START ?? .planning/research/.cache/ DATA_778a512d_END; DATA_7b329189_START ?? .planning/state.json DATA_7b329189_END. [VERIFIED: `git status --short`, `git worktree list --porcelain`, `git branch --show-current`, captured 2026-09-24]

## Common Pitfalls

### Pitfall 1: Mint's partial fix floor

**What goes wrong:** Updating only to 1.10.0 clears two of the three cited records but leaves EEF-CVE-2026-82672 unresolved. [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-82672] [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-82729] [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-82728]

**How to avoid:** Honor the context floor 1.10.1 or later, then require `mix hex.audit` to report no Mint advisories and inspect the resulting lock entry. [VERIFIED: .planning/phases/161-release-and-tidy-closeout/161-CONTEXT.md:16-18] [VERIFIED: mix.lock:26]

**Warning signs:** The lock still resolves Mint 1.9.3 or exactly 1.10.0, or `mix verify.deep_quality` still reports one of the listed EEF IDs. [VERIFIED: mix.lock:26] [VERIFIED: .planning/phases/160-package-backed-phoenix-proof/160-03-SUMMARY.md:95]

### Pitfall 2: Treating advisory failure as a required-gate failure—or dismissing it

**What goes wrong:** Phase 160 required jobs passed while the optional deep-quality lane reported the audit finding. An advisory classification does not make a known high-severity dependency advisory irrelevant. [VERIFIED: .planning/phases/160-package-backed-phoenix-proof/160-03-SUMMARY.md:95-106]

**How to avoid:** Remediate and rerun deep-quality; report that result separately from the five required jobs. Reuse exact-SHA CI for each candidate and final evidence. [VERIFIED: .github/workflows/ci.yml:18-70,134-150]

### Pitfall 3: Confusing evidence types in adopter docs

**What goes wrong:** A contract test or synthetic package fixture may prove command wiring/claims, but cannot stand in for the package-backed live-service run; conversely, live service proof does not establish production reliability or every adopter configuration. **[ASSUMED]** The plan should encode the specific proof boundary established by the requirement and Phase 160 evidence rather than make broader claims.

**How to avoid:** Keep real-service and synthetic/contract evidence explicitly distinguished. Preserve exact scope, service prerequisites, command, exercised modes, and evidence limitations in the canonical example README and maintainer docs, with contract assertions for wording/commands. [VERIFIED: .planning/REQUIREMENTS.md:17] [VERIFIED: examples/phoenix_meilisearch/README.md:7,39-48] [VERIFIED: test/scrypath/docs_contract_test.exs:702-728]

### Pitfall 4: Final tracking edits invalidate closeout

**What goes wrong:** A successful attestation applies only to its selected SHA; later edits leave final source without matching evidence. [VERIFIED: CONTRIBUTING.md:67-83]

**How to avoid:** Split closeout into candidate validation, final evidence commit, and final exact-SHA validation. No tracked edits afterward. [VERIFIED: CONTRIBUTING.md:76-83]

### Pitfall 5: Premature or wrong-ref release

**What goes wrong:** Publishing from a branch or manually made tag can make Hex package, docs, changelog, and Git source diverge. [VERIFIED: docs/releasing.md:98-123,146-155]

**How to avoid:** Merge the reviewed Release Please PR, publish from its generated `tag_name`, wait for `verify.release_publish` and `verify.release_parity`, and only then state shipped. [VERIFIED: .github/workflows/release-please.yml:41-94] [VERIFIED: docs/releasing.md:111-123]

## Code Examples

### Validate the current package/doc contract and re-run the docs seam

```sh
mix verify.package
mix test test/scrypath/docs_contract_test.exs
mix docs --warnings-as-errors
```

`mix verify.package` is the auth-free release gate; the docs contract suite is optional and excluded from default CI, so run it directly for Phase 161 contract changes. The docs build is a documented CI requirement for docs changes. Verbatim gate literals: DATA_744fe614_START `mix verify.package` DATA_744fe614_END; DATA_ba24d65e_START `mix docs --warnings-as-errors` DATA_ba24d65e_END [VERIFIED: docs/releasing.md:21-29] [VERIFIED: CONTRIBUTING.md:7,110-114].

### Attest the final SHA and inspect release evidence

```sh
node scripts/ci_monitor.cjs closeout --push \
  --branch "$(git branch --show-current)" \
  --sha "$(git rev-parse HEAD)"
```

After merge, verify `main` remains green. Before a release PR merge compare the version in `mix.exs`, `.release-please-manifest.json`, and top `CHANGELOG.md` entry. Verbatim source commands: DATA_096fe18e_START `grep -n '@version\|@source_ref' mix.exs` DATA_096fe18e_END, DATA_8cf29c25_START `cat .release-please-manifest.json` DATA_8cf29c25_END, and DATA_854e5a11_START `sed -n '1,80p' CHANGELOG.md` DATA_854e5a11_END [VERIFIED: docs/releasing.md:98-121].

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manually inspect package publish and docs later | Release workflow immediately runs `verify.release_publish`, then `verify.release_parity` | Repository release workflow currently includes both checks; date not independently established | Failure is caught in the publish sequence, including versioned docs reachability and tag/tarball parity. [VERIFIED: docs/releasing.md:57-65,111-123] |
| Accept PR checks without final SHA artifacts | Two-stage candidate/final closeout with digest-bearing SHA-bound artifacts | Added during project milestone history; exact date not needed for this phase | Ensures the final committed tracking state is itself the validated state. [VERIFIED: CONTRIBUTING.md:67-83] |
| Pin Mint at 1.9.3 | Resolve Mint 1.10.1 or later | 1.10.1 is current on Hex; EEF-CVE-2026-82672 was published Sep 19, 2026, while the two Sep 4 advisories list fixes in 1.10.0 | Satisfies all three named advisory fix floors. [CITED: https://hex.pm/packages/mint] [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-82672] [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-82729] [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-82728] |

**Deprecated/outdated:** No deprecated package/release workflow was identified. Do not follow repository historical names if a capability-named command exists; in this phase use the current names documented in `CONTRIBUTING.md`. [VERIFIED: CONTRIBUTING.md:26-41]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Contract/synthetic fixtures prove their encoded command and wording invariants but do not prove live service behavior; live service proof does not prove all production or adopter deployment behavior. | Common Pitfalls | Overclaiming package support or narrowing trust claims beyond actual evidence. |

## Open Questions

1. **Will the Release Please PR merge and will publish authorization/services be available during execution?**
   - What we know: the user selected publication as the target when merge, secret, and services are available; a configured Hex publisher key is required for CI publish. [VERIFIED: .planning/phases/161-release-and-tidy-closeout/161-CONTEXT.md:20-22] [VERIFIED: docs/releasing.md:67-73]
   - What's unclear: release PR status and whether the publishing secret and external services are usable at execution time. Secret contents must not be inspected or logged.
   - Recommendation: do all repo and exact-SHA checks first; if a blocker persists, document the specific blocker, finish other checks, and record one precise resume action with `release-ready`. [VERIFIED: .planning/phases/161-release-and-tidy-closeout/161-CONTEXT.md:20-22]

2. **Does the Mint graph update remain lockfile-only?**
   - What we know: Mint enters the current root lock via Finch, which accepts `~> 1.8`; Mint 1.10.1 is published. [VERIFIED: mix.lock:19,26] [CITED: https://hex.pm/packages/mint]
   - What's unclear: resolver result and resulting lockfile closure after update.
   - Recommendation: try the minimal Mint update, inspect the diff and `mix deps.tree mint`, and alter project dependency constraints only if the resolver demonstrates necessity. [VERIFIED: mix.lock:19,26]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| GitHub CLI `gh` | Read hosted evidence, dispatch exact-SHA closeout | ✓ | `2.101.0`; authenticated session observed | GitHub web UI for read-only inspection; closeout helper itself requires `gh` and auth. |
| Git | SHA/worktree/branch inventory | ✓ | present; repository checkout | — |
| Mix / Elixir | Local audit/docs/contract checks | ⚠ | `mix` shim exists, but current shell reports no version selected; configured `1.19.0-otp-28` toolchain is listed | Use CI's `setup-beam` jobs or select an installed project toolchain before local checks. |
| GitHub Actions | Required exact-SHA evidence and release automation | ✓ | repository workflows exist | No equivalent substitute for hosted attestation/release execution. |
| Hex publisher credential | Actual package publication | Unknown | Not inspected | If unavailable, finish all available checks and use `release-ready` with exact resume action. |
| Hex and HexDocs network services | Post-publish verification | Not probed | — | If unavailable, retry/record service blocker and leave release `release-ready`; do not claim shipped. |

The only worktree found at research time was the current worktree. Local output also showed unrelated pre-existing modifications/untracked files; preserve them as listed in Runtime State Inventory. [VERIFIED: `git worktree list --porcelain` and `git status --short`, 2026-09-24]

**Missing dependencies with no fallback:** None for planning. Actual publication depends on external authorization and service availability.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (root Mix test suite; file declares `use ExUnit.Case`) [VERIFIED: test/scrypath/docs_contract_test.exs:1-2] |
| Config file | `mix.exs` (Mix project) |
| Quick run command | `mix test test/scrypath/docs_contract_test.exs` |
| Full suite command | `mix verify.core --exclude integration --exclude docs_contract`; hosted closeout helper runs CI gate set on exact SHA. [VERIFIED: .github/workflows/ci.yml:18-70] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DOC-01 | Docs state tested proof scope, command, service prerequisites, and synthetic evidence boundary | Contract | `mix test test/scrypath/docs_contract_test.exs` | Yes; extend assertions for any new claim [VERIFIED: test/scrypath/docs_contract_test.exs:702-728] |
| HYGIENE-01 | Docs and package contract remain valid; no generated debris | Contract + package | `mix test test/scrypath/docs_contract_test.exs`; `mix verify.package`; exact-SHA closeout | Existing docs/package gates; final debris check is inventory-based [VERIFIED: docs/releasing.md:21-29] [VERIFIED: scripts/ci_monitor.cjs:193-209] |
| REL-01 | Advisory remediation, required exact-SHA jobs, green `main`, Hex publish, docs, and source/tag parity | Security audit + hosted CI + release workflow | `mix verify.deep_quality`; `node scripts/ci_monitor.cjs closeout ...`; workflow's `mix verify.release_publish X.Y.Z` then `mix verify.release_parity X.Y.Z` | Existing workflow/helper [VERIFIED: .github/workflows/ci.yml:134-150] [VERIFIED: .github/workflows/release-please.yml:75-94] |
| CLOSE-01 | Owned branches/worktrees/services/artifacts cleaned; unrelated entries preserved/reported | Manual inventory + machine evidence | `git status --short`; `git worktree list --porcelain`; inspect only milestone services/artifacts; final status record | No single cleanup contract test exists; report exact resource evidence |

### Sampling Rate

- **Per docs task:** `mix test test/scrypath/docs_contract_test.exs` plus `mix docs --warnings-as-errors` when published docs change.
- **After dependency task:** `mix verify.deep_quality` and focused package/doc contract verification.
- **Per candidate/final closeout:** `node scripts/ci_monitor.cjs closeout --push --branch "$(git branch --show-current)" --sha "$(git rev-parse HEAD)"`; repeat after final evidence commits.
- **Release gate:** Release Please publish path must pass `mix verify.release_publish X.Y.Z` and `mix verify.release_parity X.Y.Z` before shipped disposition.

### Wave 0 Gaps

- Extend existing docs assertions for the synthetic evidence limits required by DOC-01; no new test harness is needed. [VERIFIED: .planning/REQUIREMENTS.md:17] [VERIFIED: test/scrypath/docs_contract_test.exs:702-728]

## Security Domain

This phase modifies a dependency lock graph and release/docs/CI evidence. It does not introduce a web authentication or session feature. OWASP identifies ASVS 5.0.0 as its latest stable version; select only controls applicable to publisher credential scoping, workflow permissions, validation, and output redaction. [CITED: https://owasp.org/projects/asvs]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No application login surface is changed. |
| V3 Session Management | No | No user/web session surface is changed. |
| V4 Access Control | Yes, CI permissions | Keep token/workflow permissions minimal; release actions use explicitly scoped `contents`, PR, and publish permissions. [VERIFIED: .github/workflows/release-please.yml:9-12,41-48] |
| V5 Input Validation | Yes, release inputs/docs contract | Validate manually dispatched recovery tag/version and preserve existing strict test assertions. [VERIFIED: .github/workflows/publish-hex.yml:3-13] [VERIFIED: test/scrypath/docs_contract_test.exs:702-728] |
| V6 Cryptography / secret management | Yes, credentials handling | Do not inspect/log secret contents; scope `HEX_API_KEY` to publish jobs only. [VERIFIED: docs/releasing.md:67-73] |
| V7 Error handling and logging | Yes | Keep endpoint/token redaction in proof diagnostics. [VERIFIED: lib/mix/tasks/verify/phoenix_example/package.ex:185-202] |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Compromised/stale transitive HTTP client | Tampering / Denial of service | Resolve fixed Mint release; run `mix hex.audit` through deep-quality on exact source. [CITED: OSV Mint advisories] [VERIFIED: .github/workflows/ci.yml:134-150] |
| Publisher token exposed to ordinary jobs | Elevation of privilege | Keep Hex key in publisher-scoped job only; never put it in always-on CI or diagnostics. [VERIFIED: docs/releasing.md:67-73] |
| Version/tag/package mismatch | Tampering | Publish from the Release Please tag; run live publish and parity verification. [VERIFIED: docs/releasing.md:111-123] |
| CI evidence from an earlier SHA presented as final | Repudiation | Use exact full SHA and SHA-bound artifacts; rerun after evidence edits. [VERIFIED: scripts/ci_monitor.cjs:119-209] |

## Sources

### Primary (HIGH confidence, in-repo source-of-truth read this session)

- `.planning/phases/161-release-and-tidy-closeout/161-CONTEXT.md` — locked decisions, acceptance scope, canonical references, and code touchpoints.
- `.planning/REQUIREMENTS.md` — exact DOC-01, HYGIENE-01, REL-01, and CLOSE-01 contracts.
- `.planning/phases/160-package-backed-phoenix-proof/160-VERIFICATION.md` and `160-03-SUMMARY.md` — previous exact-SHA proof and unresolved Mint advisory record.
- `mix.exs`, `mix.lock` — root Mix dependency constraints and resolved transitive Mint version.
- `docs/releasing.md`, `CONTRIBUTING.md`, `examples/phoenix_meilisearch/README.md` — canonical package, release, CI, and adopter instructions.
- `.github/workflows/ci.yml`, `release-please.yml`, `publish-hex.yml`, `verify-published-release.yml` — real workflow job/service/publish definitions.
- `scripts/ci_monitor.cjs`, `test/scrypath/docs_contract_test.exs`, `lib/mix/tasks/verify/phoenix_example/package.ex` — exact-SHA helper, docs contract coverage, temp ownership and output redaction.
- `AGENTS.md`, `.planning/PROJECT.md`, `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md`, `prompts/elixir-opensource-libs-best-practices-deep-research.md` — project directives and release/adopter reference material.

### Secondary (MEDIUM confidence; authoritative external documentation)

- [Mint 1.10.1 Hex package](https://hex.pm/packages/mint) — currently published Mint version.
- [EEF-CVE-2026-82672](https://osv.dev/vulnerability/EEF-CVE-2026-82672), [EEF-CVE-2026-82729](https://osv.dev/vulnerability/EEF-CVE-2026-82729), [EEF-CVE-2026-82728](https://osv.dev/vulnerability/EEF-CVE-2026-82728) — advisory descriptions and fixed-version ranges.
- [Hex publishing documentation](https://hex.pm/docs/publish) — `mix hex.publish`, automatic docs publishing, `HEX_API_KEY`, and CI usage.
- [Release Please Action](https://github.com/googleapis/release-please-action) and [manifest releaser documentation](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md) — manifest, outputs, release PR and GitHub release behavior.
- [GitHub status checks](https://docs.github.com/en/pull-requests/reference/status-checks) — required checks and merge constraints.
- [OWASP ASVS](https://owasp.org/projects/asvs) — current standard status and security control context.

### Tertiary (LOW confidence)

- None used for recommendations.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — repository manifests/workflows read directly; Mint advisory ranges cross-checked against OSV and Hex.
- Architecture: HIGH — repository's current workflow and task implementation inspected.
- Pitfalls: HIGH — derived from Phase 160 exact-SHA evidence, release runbook, and relevant implementation/tests.

**Research date:** 2026-09-24  
**Valid until:** 2026-10-24 for repository workflow; recheck Mint registry and advisory data immediately before dependency remediation or publishing.
