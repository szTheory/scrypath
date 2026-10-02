---
phase: 169-library-fix-delivery-and-pr-triage
plan: "05"
subsystem: maintenance
tags: [delivery, pull-requests, dependency-triage, release]
requires:
  - phase: 169-04
    provides: merged-fix delivery receipts and exact-main verification
provides:
  - Dated owned-delta inventory with one disposition per observed path
  - Current evidence-based dispositions for frozen PRs 65, 68–76
  - Phase 170 patch-release handoff and current planning pointers
affects: [169, 170, release-train]
actuals:
  tokens: 11149
  tasks: 3
  commits: 1
  plan_head_before: 658464508972c51e3925615c1ed066644f1b82e2
tech-stack:
  added: []
  patterns: [source-fingerprinted ownership ledger, refresh-before-mutation PR accounting]
key-files:
  created: [.planning/phases/169-library-fix-delivery-and-pr-triage/169-05-SUMMARY.md]
  modified: [.planning/STATE.md, .planning/ROADMAP.md, .planning/REQUIREMENTS.md, .planning/PROJECT.md]
key-decisions:
  - "PR #85's normal squash merge proceeded under explicit user authorization after required CI was green; GitHub has no review and none is claimed."
  - "Frozen cohort scope remains exactly #65 and #68–#76; selected no-value closures remain pending because the authorization applied only to PR #85."
  - "No additional archive history, dependency upgrade, or readiness assessment is needed to explain this delivery."
patterns-established:
  - "Disposition every path in a hashed original/refreshed union exactly once, including separately fingerprinted dirty paths."
  - "Keep current observation separate from any external action not authorized or performed."
requirements-completed: [DELIV-02, TRIAGE-01]
coverage:
  - id: D1
    description: "Every path in the original/refreshed public-main and dirty-path union has one source-linked disposition."
    requirement: DELIV-02
    verification:
      - kind: other
        ref: "owned path selector coverage check; raw snapshot SHA-256 8e4a5179d6d57dd5d769e15676fe03f5925928105163dd15cc6d625b8c1bbb4e"
        status: pass
    human_judgment: false
  - id: D2
    description: "Exactly the ten frozen PR identities have current heads, bases, states, checks, value reasons and dispositions."
    requirement: TRIAGE-01
    verification:
      - kind: other
        ref: "gh pr view readback for PRs 65, 68–76 plus ten-cohort structural check"
        status: pass
    human_judgment: false
  - id: D3
    description: "Integrated fixes are handed to the normal Phase 170 patch/release train without claiming publication or a GitHub review."
    requirement: DELIV-02
    verification:
      - kind: other
        ref: "Plan 04 merge receipt; main SHA 933ad30645c41df9f21dd4ddfd2d5b93fbd48620; post-merge run 36644133759"
        status: pass
    human_judgment: false
duration: unmeasured
completed: 2026-09-29
status: complete
---

# Phase 169 Plan 05: Owned Delivery and Frozen PR Triage Summary

**The tenant/facet corrections are integrated on public `main`; the complete 232-path observed delta and all ten frozen dependency PRs now have source-linked dispositions for Phase 170.**

## Performance

- **Duration:** unmeasured (executor start timestamp was not captured)
- **Started:** unmeasured
- **Completed:** 2026-09-29T23:48:14Z
- **Tasks:** 3/3
- **Files modified:** 5 intended planning files; no source/product files

## Accomplishments

- Compared the original Plan 01 snapshot and refreshed local/public trees plus dirty paths; recorded a raw, reproducible 232-path union outside the repository.
- Recorded a disposition for every observed path and a current value-based decision for each frozen PR, while making no PR mutations or comments.
- Linked the Plan 04 delivery receipts, accurately recorded the user's merge authorization and absent GitHub review, and routed the normal patch rationale to Phase 170.

## Plan 04 delivery receipt and authorization

PR [#85](https://github.com/szTheory/scrypath/pull/85) was squash-merged to public `main` at `933ad30645c41df9f21dd4ddfd2d5b93fbd48620`; the merge tree and the verified candidate tree are both `48605fa22efafd8c37ad563ea84949a1fdf05988`. The post-merge CI run [36644133759](https://github.com/szTheory/scrypath/actions/runs/36644133759) passed on that exact merge SHA. Full candidate, merge-ref, and post-merge receipts remain in [169-04-SUMMARY.md](169-04-SUMMARY.md).

The user explicitly authorized a normal merge after required CI checks passed. This was the authorization used. GitHub's PR record still has no review and an empty `reviewDecision`; this summary does not claim a review occurred. No Hex package was published. The PR correction is release input for the existing patch train, not a completed release.

## Owned change dispositions

The dated original observation is 2026-09-29T19:22:18Z (local `aadc06a8833a0132e8c3a0bc7e47c49994ac7e25`, public `2832e91d725d70eff9ba11d08052260ba17e2747`). The refreshed observation is 2026-09-29T23:40:00Z (local `658464508972c51e3925615c1ed066644f1b82e2`, tree `aeeb5d07ae86b86ca863eace8cbd553d6ce77422`; public `933ad30645c41df9f21dd4ddfd2d5b93fbd48620`, tree `48605fa22efafd8c37ad563ea84949a1fdf05988`). The original committed comparison had 209 paths and 21 dirty paths; refreshed committed comparison had 200 paths and 21 dirty paths; union: 232 unique paths. The full blob/fingerprint snapshot is held in external session storage, SHA-256 `8e4a5179d6d57dd5d769e15676fe03f5925928105163dd15cc6d625b8c1bbb4e`. Its `paths` property is the 232 repository-relative path strings consumed by the plan validator; `observations` is keyed by path and retains original/refreshed local/public blob identities plus separately fingerprinted worktree observations. Source identities and capture metadata are at the top level. Regeneration used the preserved external snapshot, `git ls-tree -r HEAD`, `git status --porcelain=v1 --untracked-files=all` with SHA-256 of present bytes, and GitHub REST `GET /repos/szTheory/scrypath/git/trees/933ad30645c41df9f21dd4ddfd2d5b93fbd48620?recursive=1`. A local `git fetch` could not update read-only `.git/FETCH_HEAD`; GitHub REST supplied the public tree instead. Selectors below are disjoint and collectively cover only those 232 observed paths.

| Path selector | Source comparison | Ownership | Disposition | Delivery source/path | Evidence/revisit trigger |
|---|---|---|---|---|---|
| lib/scrypath/search/single.ex; lib/scrypath/search/many.ex; lib/scrypath/search/facet_values.ex; lib/scrypath/meilisearch/client.ex; lib/scrypath/meilisearch/query.ex | Local selected blobs match public main at refreshed SHAs; PR #85 merge tree equals verified candidate tree. | Selected tenant-option and facet-filter runtime correction. | Selected and delivered. | PR [#85](https://github.com/szTheory/scrypath/pull/85); exact candidate, merge, and post-merge receipts in [169-04-SUMMARY.md](169-04-SUMMARY.md). | Main SHA `933ad30645c41df9f21dd4ddfd2d5b93fbd48620`, tree `48605fa22efafd8c37ad563ea84949a1fdf05988`; CI run [36644133759](https://github.com/szTheory/scrypath/actions/runs/36644133759) passed. |
| examples/phoenix_meilisearch/** | Coherent host/repair evidence and example changes are identical at the PR #85 merge tree and verified candidate tree. | Selected adopter/regression proof accompanying the runtime correction. | Selected and delivered. | PR #85, with source-specific evidence and proof limits in [169-04-SUMMARY.md](169-04-SUMMARY.md). | Exact merge SHA/tree and post-merge CI above; package publication is not claimed. |
| test/scrypath/tenant_scope_contract_test.exs; test/scrypath/facet_values_contract_test.exs | Selected regression paths are part of the merged public source identity. | Existing public tenant and facet contracts. | Selected and delivered. | PR #85 and its joined tests/adopter evidence; [169-04-SUMMARY.md](169-04-SUMMARY.md). | Revisit only if an exact-source regression or current supported-call-contract defect appears. |
| .github/workflows/ci.yml; lib/mix/tasks/verify.adopter.ex; lib/mix/tasks/verify/capability.ex; lib/mix/tasks/verify/phoenix_example/lock_graph.ex; lib/mix/tasks/verify/phoenix_example/package.ex; scripts/ci/dependency_audit.ex; scripts/ci/dependency_audit.exs; test/mix/tasks/dependency_audit_test.exs; test/mix/tasks/verify_adopter_test.exs; test/mix/tasks/verify_capability_test.exs; test/mix/tasks/verify_lock_graph_test.exs; test/mix/tasks/verify_phoenix_example_package_test.exs; test/mix/tasks/workflow_wiring_test.exs; test/release/consumer_smoke_test.exs; test/scrypath/phase99_contract_test.exs; test/scrypath/live_operator_verification_test.exs | Phase 168 security/proof paths are present in public main; current local/public blob differences are retained as the refreshed comparison identifies them. | Phase 168 current-main owner; selected security and proof workflow. | Already delivered/equivalent at refreshed main; preserve public source. | Phase 168 summaries and main `933ad30645c41df9f21dd4ddfd2d5b93fbd48620`; do not overwrite from accumulated local branch. | Revisit on current-main regression or newly applicable advisory, not from historical filename/blob difference alone. |
| mix.lock; scrypath_ops/mix.exs; scrypath_ops/mix.lock; examples/scrypath_ecommerce/mix.lock | Refreshed identities show the active four-graph/security delivery separately from local lockfile deltas; no selected Plan 05 upgrade was made. | Maintained dependency graphs and local consumer snapshots. | Preserve current main/security graph; retain local graph state for its own evidence-backed follow-up. | Phase 168 four-graph remediation receipts and existing audit path; no source upgrade in Plan 05. | Revisit only against a current primary advisory or a concrete graph compatibility failure; do not infer value from behind status. |
| .planning/phases/168-dependency-security-and-reliable-verification/** | Historical phase receipts exist locally and in the current evidence context; unchanged. | Phase 168 proof record. | Retain unchanged as historical delivery authority. | Existing Phase 168 standard summaries and exact source links in them. | Reopen only if their source-specific receipt is invalidated by a new public-main change. |
| .planning/phases/169-library-fix-delivery-and-pr-triage/** | Current planning set is local maintainer state; Plan 04 links the integrated source receipts. | Phase 169 execution/planning records. | Retain; add this Plan 05 canonical summary as the sole owner of the two detailed tables. | This summary plus [169-04-SUMMARY.md](169-04-SUMMARY.md); no competing inventory document. | Phase 170 consumes the two distinct records. |
| .planning/research/v1.41/** | Approved current-milestone research remains local and unchanged. | Upstream v1.41 scope and research decisions. | Retain as research input, not duplicate delivery proof. | [v1.41 research entrypoint](../../research/v1.41/SUMMARY.md) and linked decision sources. | Revisit if Phase 170 finds new source/advisory evidence that materially changes approved scope. |
| .planning/milestones/v1.39-MILESTONE-AUDIT.md; .planning/milestones/v1.39-REQUIREMENTS.md; .planning/milestones/v1.39-ROADMAP.md; .planning/milestones/v1.39-phases/** | Older milestone archive differs from refreshed public main; no archived record was required to prove the present merge. | Historical v1.39 milestone. | Retain locally; no archive import. | Existing archive links from PROJECT and prior assessment records. | A specific Phase 170 claim may request a bounded record by exact path; no automatic history transfer. |
| .planning/milestones/v1.40-MILESTONE-AUDIT.md; .planning/milestones/v1.40-REQUIREMENTS.md; .planning/milestones/v1.40-ROADMAP.md; .planning/milestones/v1.40-phases/** | Historical v1.40 records, including dated assessment, remain unchanged; they predate PR #85's delivery. | Historical assessment and closeout. | Retain locally unchanged; no archive import and no reinterpretation of its cutoff. | Historical v1.40 milestone links; current delivery relies on Plan 04 receipts. | Preserve the dated NOT READY result; only a separately authorized, freshly dated assessment can change current readiness. |
| .planning/milestones/v1.38-phases/160-package-backed-phoenix-proof/160-UAT.md | Worktree modification is in the preserved baseline/current dirty set, outside this plan's ownership. | Unrelated maintainer work. | Preserve untouched. | Existing local file. | Owner review when addressing the independent Phase 160 evidence/debug concern. |
| .planning/debug/160-03-summary-commit-claim.md; .planning/debug/resolved/**; examples/scrypath_ecommerce/docker-e2e-entrypoint.sh; test/scrypath/phase147_e2e_contract_test.exs | Dirty/deleted observations were fingerprinted independently; not changed by this task. | Unrelated local maintainer/debug work. | Preserve untouched, including the tracked deletion and untracked resolutions. | Existing worktree bytes / maintainer-owned resolution files. | Resume only under the existing debug/owner workflow. |
| .planning/research/.cache/*.json | Fifteen current untracked cache files were individually included by path and fingerprint in the union. | Generated/untracked local research cache. | Preserve untouched; no cleanup or staging. | Existing local cache files. | Cache owner may remove under its own cleanup decision. |
| .planning/reference/**; .planning/research/ARCHITECTURE.md; .planning/research/FEATURES.md; .planning/research/PITFALLS.md; .planning/research/STACK.md; .planning/research/SUMMARY.md; .planning/research/v1.39-SUMMARY.md; .planning/research/v1.40/** | Planning/reference sources remain local; only retained evidence is relevant to this bounded review. | Durable architecture, historical, and general research reference. | Retain locally; not a prerequisite to import archive history. | Existing references linked from current planning documents. | Revisit only if a specific implementation or release question cites a source claim needing refresh. |
| .planning/MILESTONES.md; .planning/RETROSPECTIVE.md; .planning/WINDOWS.md; .planning/config.json; .planning/state.json | Current maintainer planning inputs remain local; no source change. | GSD/current maintainer tracking. | Retain and update only explicit current state/roadmap/requirement fields separately below. | This summary and GSD state operations. | Reconcile in future planning maintenance when relevant; do not rewrite historical bodies. |
| .planning/PROJECT.md; .planning/REQUIREMENTS.md; .planning/ROADMAP.md; .planning/STATE.md | Current planning text had stale “awaiting review/merge” and pre-delivery status. | Current milestone source of truth. | Update bounded current tracking to reflect verified merge, completed requirements, and Phase 170 handoff. | This summary's source receipts and standard GSD tracking operations. | Phase 170 updates only its next-step/current claims as evidence warrants. |
| prompts/scrypath-milestone-ratchet-roadmap.txt | Local prompt delta is not a shipped library or release artifact. | Maintainer planning prompt. | Retain as local planning material; do not publish or use as historical archive. | Existing prompt remains unchanged. | Revisit only in a separately scoped prompt-maintenance task. |
### Archive necessity

Necessary historical archive set for explaining the current choice: **zero new records**. The source correction and proof are explained by PR #85's exact delivery receipt in Plan 04, this summary's refreshed path comparison, and current public main. Plan 01 preserves baseline/extraction facts; Plan 04 preserves merge/check facts. Existing v1.39/v1.40 archive records remain locally available and unchanged, and none must be bulk-imported to account for the selected fix or finite cohort. This follows D-05–D-08 and does not revise any historical assessment.

## Frozen cohort dispositions

The cohort is exactly PRs 65 and 68–76. The final live metadata/check refresh ran 2026-09-29T23:48:09Z–23:48:14Z; each row records that observation cutoff. All ten were OPEN at observation, with unchanged full head/base SHAs shown. PR state/check evidence is an observation, not a completed mutation. Under the user's explicit authorization scope, no cohort PR was closed, merged, edited, or commented on. For selected close actions, the close remains pending authorization; PRs selected to remain reviewable stay unchanged. Checks are exact run-linked observations, not inferred from behind status. “Required” refers to the named repository required jobs; advisory failures are distinguished.

| PR | Observed at | Head | Base | State | Change/check evidence | Value/rationale | Disposition | Action/result | Revisit trigger |
|---:|---|---|---|---|---|---|---|---|---|
| 65 | 2026-09-29T23:48:09Z | 6b70b673347ec3e31af22f044aecbab6fe6c3a98 | 40c9978c975dbfb42db75511f44ff0369c8d7d88 | OPEN | [#65](https://github.com/szTheory/scrypath/pull/65) changes only cache action pin 5.1.0→6.1.0. Required `core` and `repository-contracts` failed; `actionlint`, `action-pins`, and `dependency-review` passed; deep-quality/compatibility advisory failures. [Run 36420001401](https://github.com/szTheory/scrypath/actions/runs/36420001401). | No concrete cache incident or policy/security gap found; cache v5 already runs Node 24. Proposed v6 update has required failures because contract expectations remain v5. [actions/cache](https://github.com/actions/cache). | close | **Pending:** no close performed; user authorization is limited to PR #85. | Reopen if cache v5 reaches documented lifecycle/security end or a concrete cache/runner incompatibility is observed. |
| 68 | 2026-09-29T23:48:09Z | 949fafb68635b2fee2c0ac5ff4b6cc4a2eb116dd | 40c9978c975dbfb42db75511f44ff0369c8d7d88 | OPEN | [#68](https://github.com/szTheory/scrypath/pull/68) changes dependency-review-action 4.9.0→5.0.0 in workflow-security. Required jobs, actionlint/pins, dependency review and mounted gate passed; deep-quality advisory failed. [Run 36420003472](https://github.com/szTheory/scrypath/actions/runs/36420003472). v5 requires runner ≥2.327.1 and Node24 ([upstream](https://github.com/actions/dependency-review-action)); current observed runner 2.337.0 and v4 dependency-review check passed. Node20 retirement policy is active ([GitHub notice](https://github.blog/changelog/2026-09-23-node-20-is-no-longer-available-in-github-actions/)). | This action implements the dependency-review security gate, so it has bounded security-maintenance value; the observed current v4 check still succeeds on supported runner, with no present failure established. | keep | PR remains OPEN and unchanged; no update/action completed. | Recheck when the dependency-review run fails, runner floor changes, or upstream action supersedes v5. |
| 69 | 2026-09-29T23:48:09Z | b4bd46d244fa3db8e1bb6a35e651bf1250372c1d | 40c9978c975dbfb42db75511f44ff0369c8d7d88 | OPEN | [#69](https://github.com/szTheory/scrypath/pull/69) changes only StreamData 1.3.0→1.4.0 in `mix.lock`. All required jobs passed; deep-quality advisory failed. [Run 36420001337](https://github.com/szTheory/scrypath/actions/runs/36420001337). | Test-only library update; no failing property, supported-runtime incompatibility, or concrete test gap tied to the version was found. Upstream release docs [StreamData](https://stream-data.hexdocs.pm/). | close | **Pending:** no close performed; user authorization is limited to PR #85. | Revisit if a reproducible property-test gap or supported Elixir/test-runtime incompatibility requires 1.4.x. |
| 70 | 2026-09-29T23:48:09Z | a7695881de49fe4e812435d3a148d56b37e633d7 | 40c9978c975dbfb42db75511f44ff0369c8d7d88 | OPEN | [#70](https://github.com/szTheory/scrypath/pull/70) changes setup-node 6.5.0→7.0.0 only in `website.yml`; required jobs, website build, actionlint/pins and dependency review passed; deep-quality advisory failed. [Run 36420001401](https://github.com/szTheory/scrypath/actions/runs/36420001401). Upstream v7 is ESM; website pins Node 22 and does not configure registry token ([upstream releases](https://github.com/actions/setup-node/releases)). | No current workflow behavior defect; action v7's breaking module migration is not shown to solve a project issue. | close | **Pending:** no close performed; user authorization is limited to PR #85. | Revisit if the website workflow hits a concrete setup-node v6 support issue or action behavior changes. |
| 71 | 2026-09-29T23:48:09Z | a46d9db1e8ffae1499c13fff1a8091d7cd22c267 | 40c9978c975dbfb42db75511f44ff0369c8d7d88 | OPEN | [#71](https://github.com/szTheory/scrypath/pull/71) updates checkout 6.1.0→7.0.1 in six workflows. Current workflows use `pull_request` and not `pull_request_target`/`workflow_run`, so upstream hardening for those privileged triggers does not apply. `actionlint`/pins passed; required `core` and `repository-contracts` failed their v6 pin contracts; deep-quality advisory failed. [Run 36420001401](https://github.com/szTheory/scrypath/actions/runs/36420001401); [upstream changelog](https://github.com/actions/checkout/blob/main/CHANGELOG.md). | No project-specific exploit/advisory or applicable privileged-trigger issue established; current update fails required workflow-version contracts. | defer | PR remains OPEN unchanged; no update performed. | Re-evaluate on an applicable checkout advisory, addition of a privileged trigger, or required contract migration with concrete benefit. |
| 72 | 2026-09-29T23:48:09Z | 2bb02e546a0ea685a873bf09e0f104f466d28cfd | 2832e91d725d70eff9ba11d08052260ba17e2747 | OPEN | [#72](https://github.com/szTheory/scrypath/pull/72) updates deploy-pages 5.0.0→5.0.1 in website workflow. All required and advisory checks passed. [Run 36503782162](https://github.com/szTheory/scrypath/actions/runs/36503782162); upstream [v5.0.1 notes](https://github.com/actions/deploy-pages/releases). | Release adds retry backoff/jitter to Pages deployment polling, directly relevant to this repository's deployment path; low-scope operational reliability value. | keep | PR remains OPEN unchanged; no action completed. | Reassess if a later deploy-pages release supersedes it or the Pages workflow exposes a concrete related issue. |
| 73 | 2026-09-29T23:48:09Z | f6feeb157527e4ac1d58cecdd7a58bcb84975968 | 2832e91d725d70eff9ba11d08052260ba17e2747 | OPEN | [#73](https://github.com/szTheory/scrypath/pull/73) changes Req `~> 0.6.1`→`~> 0.7.4` in root manifest/lock. Required ecommerce-mounted failed and consumer/Ops resolution failures occur because `scrypath_ops` and ecommerce still constrain `~> 0.6.1`; deep-quality advisory failed. [Run 36503793068](https://github.com/szTheory/scrypath/actions/runs/36503793068). Req 0.7 includes auth-value redaction improvement and breaking request API changes ([changelog](https://github.com/wojtekmach/req/blob/main/CHANGELOG.md)); Hex advisory history marks versions through 0.6.0 vulnerable, not the current 0.6.3 ([Req versions](https://hex.pm/packages/req/versions)). | Security-relevant diagnostic-redaction improvement merits bounded follow-up, but current manifest split demonstrably breaks maintained consumers. Existing telemetry scrubs API keys (`lib/scrypath/meilisearch/client.ex`, `test/scrypath/telemetry_test.exs`); Req error-inspection redaction still needs focused regression proof. | update | **Pending:** no files changed. Bounded follow-up needs aligned constraints across root/Ops/ecommerce, error-redaction regression, then Req/Meili telemetry and Phoenix/ecommerce consumer proofs plus required CI; action needs separate authorization. | Resume when the consumer constraints and regression test can be included in one reviewable update, or a Req advisory affects 0.6.3. |
| 74 | 2026-09-29T23:48:09Z | ecb00d502c8800c79581e769904c75520c71fcb4 | 2832e91d725d70eff9ba11d08052260ba17e2747 | OPEN | [#74](https://github.com/szTheory/scrypath/pull/74) updates ex_doc 0.40.3→0.40.4 with transitive documentation-tool lock changes. All required and advisory checks passed. [Run 36503782162](https://github.com/szTheory/scrypath/actions/runs/36503782162). | No current docs-render defect, security advisory, or compatibility need tied to the version was found. | close | **Pending:** no close performed; user authorization is limited to PR #85. | Revisit for an applicable ExDoc advisory, docs-build defect, or selected feature requiring the new version. |
| 75 | 2026-09-29T23:48:09Z | b3b5f495cf9f6adb34612b7da31c5a555dee842c | 2832e91d725d70eff9ba11d08052260ba17e2747 | OPEN | [#75](https://github.com/szTheory/scrypath/pull/75) updates Dialyxir 1.4.7→1.4.8 and erlex 0.2.8→0.2.9. All required/advisory checks passed. [Run 36503776164](https://github.com/szTheory/scrypath/actions/runs/36503776164). | No current Dialyzer defect or supported Elixir/OTP diagnostic issue points to this dev-tool update. | close | **Pending:** no close performed; user authorization is limited to PR #85. | Revisit if supported Elixir/OTP surfaces a Dialyzer defect fixed by a later Dialyxir release. |
| 76 | 2026-09-29T23:48:09Z | cc40b53b0009eb404c75258ab44b210fb064d9f4 | 2832e91d725d70eff9ba11d08052260ba17e2747 | OPEN | [#76](https://github.com/szTheory/scrypath/pull/76) updates Oban 2.23.0→2.24.1 in `mix.lock`, expanding the Ecto/SQLite optional dependency subtree. All required and advisory checks passed. [Run 36503784358](https://github.com/szTheory/scrypath/actions/runs/36503784358); [Oban 2.24.1 release](https://hex.pm/packages/oban/2.24.1). | No current Scrypath Oban workflow defect or concrete feature need was found to justify accepting the expanded lock subtree; green checks alone do not establish value. | defer | PR remains OPEN unchanged; no update performed. | Revisit when an existing Oban workflow requires a 2.24.1 fix/feature or a concrete compatibility/security issue appears. |
The Node20 retirement notice postdates the cohort freeze but is current evidence considered for action workflows. For #68, current runner version 2.337.0 exceeds v5's documented minimum and the current v4 dependency-review check passed on the refreshed run; therefore no observed break changes scope. For #71, actionlint and action-pin checks pass while required repository contract failures identify the version-pin expectation, not a failed checkout execution. No PR was modified based on this observation.

## Phase 170 patch rationale and boundary

The merged changes correct existing tenant-option and facet-filter behavior without adding a public capability. Under [the existing release process](../../../docs/releasing.md) and [contributor workflow](../../../CONTRIBUTING.md), the integrated correction is appropriate input for the normal Release Please **patch** train. Phase 170 owns final docs delivery, release evaluation, publication/consumer parity if the train proceeds, and its terminal readiness record. `published_package` for Phase 169 is **none**. PR #83 stays outside this frozen cohort and within Phase 170's release-PR scope; new routine bot PRs remain maintenance work.

## Deviations from Plan

1. **Task 2 external mutations remain pending.** The selected close dispositions and the possible #73 update would require external PR mutations. Parent authorization and the user's explicit authorization cover only PR #85; no PR #65/#68–#76 was closed, merged, edited, or commented on. The selected decisions are recorded with concrete pending actions and revisit triggers. No further authorization was sought because the task is explicitly record-first under the parent scope.
2. **Public tree refresh used GitHub REST.** `git fetch origin main` could not write `.git/FETCH_HEAD` under the read-only Git metadata sandbox. The authoritative GitHub REST tree/ref API supplied exact public SHA/tree/blob evidence; local Git metadata and worktree were not mutated.
3. **Initial GSD commit attempt was blocked by Git metadata permissions.** The scoped GSD operation returned `staging_failed` while creating Git's index lock (`Operation not permitted`) and rolled back. A scoped GSD commit was then approved through local-write escalation and succeeded as `34898f6`, limited to this summary and the four listed planning files. No raw Git staging, branch rewrite, or push was used; unrelated working-tree paths remain untouched.

## Task Commits

1. **Task 3: Finalize canonical tracking and the Phase 170 handoff** — `34898f6` (`docs(169-05): record owned delta and PR triage`), containing the five intended planning files.

## Issues Encountered

The selected Req update (#73) has current dependency-resolution failures in maintained Ops/ecommerce consumer paths and an unresolved implementation-level redaction proof. Its security motivation is retained as a bounded, pending update disposition rather than described as delivered. Other observed check failures are named in their rows. No source code or dependency change was made and no local tests were run.

## Resource cleanup and retention

This executor created no branch, worktree, service, or repository-local evidence file. PR state was not changed. The reproducible snapshot and fetched check logs remain in external session storage for this session; no private content was copied into the repository. All unrelated dirty/untracked paths listed in the starting status were preserved.

## Next Phase Readiness

Phase 169's integrated correction and finite accounting are ready for goal verification. Phase 170 can begin with README/docs reconciliation and the normal patch train; it must reassess release/publication facts at its own cutoff, keep PR #83 in its release scope, and not treat this summary as a readiness assessment. The five-file planning change is committed at `34898f6`; phase-level regression and goal verification remain.

## Bounded validation

- Owned-path selector check: **passed**; the exact Plan 05 Task 1 command reported `owned path coverage complete` against 232 string paths and 17 non-overlapping selectors. Snapshot digest: `8e4a5179d6d57dd5d769e15676fe03f5925928105163dd15cc6d625b8c1bbb4e`.
- Cohort structure plus live `gh pr view` head/base/state refresh: **passed**; the exact Plan 05 Task 2 command reported all ten current head/base/state rows match live GitHub API. Required checks refreshed 2026-09-29T23:48:09Z–23:48:14Z.
- Canonical handoff and completed requirements check: **passed** (`canonical handoff linked`). Exact #85 readback: **passed**; GitHub reports MERGED at `933ad30645c41df9f21dd4ddfd2d5b93fbd48620`, and reviewDecision is empty. `main` points to that SHA/tree `48605fa22efafd8c37ad563ea84949a1fdf05988`; run `36644133759` completed SUCCESS on the same SHA.
- No test suites/builds were run within Plan 05 because it changes planning records only. Phase-level regression passed 66 tests across seven Phase 168 test files; goal verification passed 41/41 with the explicit review-first wording override documented in [169-VERIFICATION.md](169-VERIFICATION.md).

## Self-Check: PASS

All three bounded plan checks pass; the exact #85 merge/readback passes. The scoped GSD commit `34898f6` contains only the five intended planning files. The original unrelated dirty paths remain unchanged, and the Git index is clean.

---
*Phase: 169-library-fix-delivery-and-pr-triage*
*Completed: 2026-09-29*
