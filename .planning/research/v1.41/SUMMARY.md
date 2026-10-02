# Project Research Summary

**Project:** Scrypath — v1.41 Readiness Gate Follow-Through
**Reviewed:** 2026-09-28; repository/advisory observations through 16:47 UTC
**Method:** Three GPT-6 Astra xhigh specialist reviews, primary upstream sources, read-only repository and GitHub inspection, followed by synthesis. No runtime verification or delivery occurred.

## Executive Summary

Keep three phases and the existing product boundaries. Correct the security scope to all four maintained Mix graphs, make selected fixes reach green public `main`, preserve useful first-hour documentation summaries, and define a terminal readiness decision that can finish after final attestation. This review supersedes the initial Phoenix-only/Mint 1.10.1 recommendation in research commit `85924d4`; it does not revise historical readiness outcomes.

Today's upstream advisories affect Mint versions below 1.11.0. Root uses 1.10.1; Phoenix, ecommerce, and standalone Ops use 1.9.3. Three consumer graphs also need HPAX to satisfy Mint 1.11.0's `~> 1.1` requirement. All existing Finch constraints admit the update. Declared compatibility is established; dependency resolution and behavior remain unverified. Updating the Ops dependency graph does not authorize UI changes.

The local/public delta is primarily planning history, alongside small tenant-option and facet-filter runtime corrections and their larger regression/adopter proof. Deliver these corrections coherently; do not push the accumulated branch or require every historical planning commit to become a separate PR. The known public-behavior fixes warrant the normal patch release train once integrated and verified.

## Key Findings

| Decision | Recommendation and evidence | Alternative and tradeoff |
|---|---|---|
| Security scope | Target Mint 1.11.0+ in root, Phoenix, ecommerce, and standalone Ops, including necessary HPAX changes. [Security review](SECURITY-REVIEW.md). | Phoenix-only leaves known High findings; blanket upgrades add unrelated risk. A direct library Mint constraint changes public dependency policy and is not justified here. |
| Effective graph proof | Audit each project and prove the resolved graph used by the Phoenix path/package harness. Reject unexpected Hex-lock drift when staging the package. | Root audit alone misses consumer locks. A green package test checking only the Scrypath Git tag does not prove the intended transport graph. |
| Delivery | Establish a clean public-main PR base before Phase 168. Merge selected security, mounted-readiness, and tenant/facet fixes with exact-source checks and post-merge evidence. [Delivery review](DELIVERY-REVIEW.md). | Prepared PRs remain blocked delivery unless the maintainer explicitly changes the selected scope. Bulk history import hides small product fixes; one PR per historic commit wastes review and CI. |
| PR cohort | Freeze the Phase 169 inventory, disposition it once, and refresh evidence before action. At review: PRs 65 and 68–76. | Newly arriving routine bot PRs stay in maintenance. Material new security/compatibility evidence can reopen the boundary. Empty-inbox completion never terminates. |
| Adopter docs | Keep a short first-result route and acceptance-versus-visibility warning; consolidate detailed semantics and duplicate routes at their canonical owners. [Adoption review](ADOPTION-REVIEW.md). | Links-only removes necessary first-hour context. Repeated full lifecycle/status contracts create drift. |
| Finality | Freeze tracked assessment inputs and cleanup dispositions, complete final attestation and delivery proof, then issue a separately dated terminal decision outside the tested tree. | A new tracked edit after each final run creates another untested SHA. A green attestation is not itself a semantic six-condition assessment. |

### Product and ecosystem fit

Keep Ecto/context ownership, host-owned authentication and tenancy policy, the Meilisearch-first boundary, optional Oban, and explicit acceptance/task/visibility semantics. No new runtime capability, backend, API, UI, brand system, or compatibility matrix is needed. Ecto's linear tutorial and Searchkick's short declaration/index/query introduction support progressive disclosure; they do not justify importing another library's callback model or feature breadth.

### Evidence and cost

Use existing core/package/backend, Phoenix path/package, mounted ecommerce, and Ops checks for their actual graph boundaries. Ops is skipped on manual closeout dispatches, so obtain its PR/main result explicitly. Advisory enforcement status is separate from acceptance: named evidence must pass even when the job is not a required branch-protection check. Inspect resolved versions/lock identity and audit findings, including ignores; do not treat a zero exit or a required-jobs badge as complete security proof. Avoid duplicate full suites, exploit recreation, and new required jobs.

Root `mix.lock` controls this repository's development graph; host applications resolve their own locks. A locally built artifact reporting version 0.3.13 is not the already-published Hex artifact. Keep source, PR merge ref, squash-main, local package, published package, and final tracking identities distinct.

## Implications for Roadmap

### Phase 168 — Dependency Security and Reliable Verification

Deliver the compatible security correction and mounted startup-readiness fix on clean public-main PR bases; record graph-specific audit and effective consumer proof. Add recurring audits of the explicit four-graph inventory in the existing advisory lane, plus cheap omission/drift protection. Audit requires no compilation or services, but clean dependency fetches may add time: measure it and avoid duplicating the root scan. Keep repository inventory/orchestration outside the shipped package surface. Downstream planning chooses whether startup stabilization lands first and the coherent PR grouping. Do not wait for bulk planning-history reconciliation or bot triage.

### Phase 169 — Library Fix Delivery and PR Triage

Deliver the tenant/facet fixes with the coherent regression/host/repair proof they need; reuse the Phase 168 startup-fix receipt within its limits. Inventory and disposition remaining owned local changes; freeze the bot cohort. Selected fixes cannot be silently deferred into a generic disposition row. Reconcile source truth without importing every historical commit.

### Phase 170 — Documentation and Readiness Closeout

Consolidate the confirmed docs issues and adjust only superseded copy assertions. Deliver those edits before final post-merge proof. Complete the warranted Release Please patch and existing publish/consumer/parity verification, or report its exact blocker/explicit maintainer deferral. Reconcile the live readiness authority and make the terminal six-condition decision using the finite baseline and current invalidators. Preserve historic assessments byte-for-byte.

## Upstream decisions and downstream discretion

**Set by this review:** graph scope; actual selected-fix delivery; finite PR/claim inventory; useful first-hour caveats; precise source identities; no new required lane; no UI implementation; one terminal decision after required receipts.

**Owned by downstream GSD planning:** exact PR grouping, supported isolation setup, whether startup stabilization precedes the security slice, repository-only audit orchestration, targeted test/command selection, minimal package-lock proof implementation, documentation wording, and durable external terminal-record storage. Resolve storage and evidence format during Phase 170 planning before implementation; a seven-day Actions artifact alone is insufficient. The record must join six-condition judgments to immutable source/run/digest evidence and be discoverable from the tracked authority. Do not fabricate a semantic PASS from job status. Use an existing publication/evidence surface where feasible; no new service or recurring lane is prescribed.

No phase CONTEXT, PLAN, task graph, UI specification, or implementation has been created by this review. Current requirements and roadmap link this summary so the next GSD command can recover the decisions after context is cleared.

## Change Ledger

| Initial draft | Reviewed recommendation | Reason |
|---|---|---|
| Phoenix-only, Mint 1.10.1+ | Four graphs, Mint 1.11.0+ and necessary HPAX | New official advisories and complete lock inventory. |
| Root is a published dependency graph | Root development graph; host locks remain host-owned | Idiomatic Elixir library dependency resolution. |
| One-time root scan | MINT-03: recurring four-graph audit in the existing advisory lane | Actual missed consumer locks justify cheap prevention; measure fetch/runtime cost. |
| Package-tag check implies graph proof | Actual resolved graph identity/preservation | Existing fake runner can pass after dropping every Hex lock entry. |
| Reviewable PR path can complete delivery | Selected fixes merge; blocked release/merge stays explicit | Maintainer's green-main and release intent. |
| Mutable 137-commit/PR count targets | Dated inventory and selected source manifest | Review measured 140 commits, 125 planning-only; counts keep changing. |
| Delete repeated README semantics wholesale | Preserve summary/caveat; consolidate detailed authority | First-hour UX and operational honesty. |
| Another assessment before final receipt | Provisional tracked inputs plus terminal external decision | Prevent repeated condition-6 UNKNOWN caused by the assessment's own finalization. |
| DOC-01 / GATE-01 / CLOSE-01 | DOC-03 / GATE-05 / CLOSE-04 | Continue existing category numbering before any downstream plans depend on the IDs. |

## Sources

Detailed evidence and alternatives: [SECURITY-REVIEW.md](SECURITY-REVIEW.md), [DELIVERY-REVIEW.md](DELIVERY-REVIEW.md), [ADOPTION-REVIEW.md](ADOPTION-REVIEW.md). These dated reports refer to the initial draft requirement IDs; the ledger above maps their recommendations to the revised draft.

Primary sources: [Mint advisories](https://github.com/elixir-mint/mint/security/advisories), [Mint 1.11.0 release metadata](https://hex.pm/api/packages/mint/releases/1.11.0), [Elixir library guidelines](https://elixir.hexdocs.pm/library-guidelines.html), [Mix dependency update](https://hexdocs.pm/mix/Mix.Tasks.Deps.Update.html), [Hex audit](https://hex.hexdocs.pm/Mix.Tasks.Hex.Audit.html), [Release Please](https://github.com/googleapis/release-please), [Ecto getting started](https://ecto.hexdocs.pm/getting-started.html), [Searchkick](https://github.com/ankane/searchkick#readme).

Project authority: `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/reference/PRE-OPERATOR-UI-READINESS.md`, `CONTRIBUTING.md`, `docs/releasing.md`, and relevant `prompts/` guidance. Current source/policy overrides older generic prompt suggestions. Compatibility, software behavior, merges, publication, and readiness remain unverified by this planning review.
