# Phase 86: Support Truth And Proof Surface Reconciliation - Research

**Researched:** 2026-05-24  
**Domain:** Maintainer/adopter support truth, adopter-proof command wiring, and branch-tip vs archive planning reconciliation.  
**Confidence:** HIGH. Based on the checked-out docs, task code, tests, CI workflow, planning files, and one bounded salvage-history check.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Canonical support surface
- **D-01:** Restore one dedicated support/readiness guide as the single canonical authority instead of keeping truth split across `README.md`, `CONTRIBUTING.md`, and the example README.
- **D-02:** Keep that guide narrow and contract-shaped. It should define: defended Phoenix + Meilisearch path, supported runtime/version anchors, supported sync-mode posture, canonical proof command family, repo-clone vs Hex-package boundary, and the distinction between in-repo proof and reviewed outside-adopter evidence.
- **D-03:** Do not let the restored guide duplicate the sync semantics owned by `guides/sync-modes-and-visibility.md` or the live env/runbook details owned by `examples/phoenix_meilisearch/README.md`.
- **D-04:** Keep `README.md` as the adopter front door and quick-path map, `CONTRIBUTING.md` as the maintainer workflow surface, and the example README as the authoritative live proof runbook. Those files should point to the canonical support/readiness guide rather than each becoming partial authorities.

### `mix verify.adopter` contract
- **D-05:** Phase 86 should do more than replace the stale fast target. It should tighten the fast-vs-live contract across task help, task implementation, focused tests, and bounded maintainer docs.
- **D-06:** The fast mode must stay narrow, honest, and service-free. It should target existing files only and should not be widened into the full docs-contract suite.
- **D-07:** The live mode remains the explicit Phoenix example proof path under `examples/phoenix_meilisearch`, with loud prerequisite checks and CI-parity wording.
- **D-08:** `mix help verify.adopter` is treated as a maintainer-facing contract surface and must stay aligned with the actual fast/live execution paths.
- **D-09:** `CONTRIBUTING.md` should explicitly name `mix verify.adopter` as the maintainer-facing adopter-proof command family and map fast mode, live mode, and the `phoenix-example-integration` CI job clearly.

### SearchModule drift handling
- **D-10:** Treat the `v1.20` `Scrypath.SearchModule` mismatch as a history-reconciliation problem, not just a wording fix.
- **D-11:** Do one bounded salvage/history check first, then correct active claims immediately. The purpose is classification, not feature recovery.
- **D-12:** The checked-out branch-tip truth must be made explicit: `main` does not currently expose `Scrypath.SearchModule`, its guide, or its tests.
- **D-13:** If milestone archives or audits clearly point to previously existing implementation artifacts, preserve that distinction in wording: historically claimed/recoverable is not the same as currently available on `main`.
- **D-14:** Do not let Phase 86 widen into relanding or resurrecting `SearchModule`. Any recovery decision is deferred to a separate future product/maintenance call.

### Regression guard scope
- **D-15:** Prefer minimal bounded guards over a broad planning/docs truth net. Phase 86 should protect the concrete support-truth seams that drifted, not freeze large amounts of prose.
- **D-16:** Add guards that directly prove:
  - advertised `verify.adopter` fast-path files exist
  - `mix help verify.adopter` matches the real fast/live contract
  - active maintainer/adopter docs point to one current canonical support/readiness surface
  - active planning surfaces do not restate removed `support-and-compatibility` or `SearchModule` surfaces as current checked-out truth
- **D-17:** Do not treat active planning prose as a release-grade fully snapshotted contract surface. The goal is trust repair with low recurrence risk, not building a second product in tests.

### Workflow preference for this phase
- **D-18:** Research should lead. For planning and execution inside Phase 86, prefer repo-local truth, `prompts/` research, and bounded ecosystem comparison before asking the user follow-up questions.
- **D-19:** Only escalate back to the user on genuinely high-impact branch decisions or when live repo evidence cannot resolve the ambiguity safely.

### Claude's Discretion
- Exact filename for the restored support/readiness guide.
- Whether the focused fast-path contract becomes a new dedicated test file or a narrow reuse of an existing test seam, as long as it stays small and truthful.
- Exact wording used to separate branch-tip truth from historical/archive truth for `SearchModule`.
- Exact placement of maintainer pointers in `README.md` vs `CONTRIBUTING.md`, provided the authority split above is preserved.

### Deferred Ideas (OUT OF SCOPE)
- Relanding or resurrecting `Scrypath.SearchModule` as code on `main`.
- Building a broad planning-wide or docs-wide frozen truth harness beyond the few seams that actually drifted.
- Any new product capability, search feature, or adopter wedge; those remain Phase 87+ concerns.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TRUTH-01 | Maintainers can point adopters to one current canonical readiness/support surface whose files exist in the checkout and whose claims match the current public tree. | Restore one narrow guide, preferably `guides/support-and-compatibility.md`, and route `README.md`, `CONTRIBUTING.md`, `examples/phoenix_meilisearch/README.md`, and `mix help verify.adopter` toward it instead of letting those files each own partial support truth. [VERIFIED: `.planning/REQUIREMENTS.md`] [VERIFIED: `.planning/phases/86-support-truth-and-proof-surface-reconciliation/86-CONTEXT.md`] [VERIFIED: `README.md`] [VERIFIED: `CONTRIBUTING.md`] [VERIFIED: `examples/phoenix_meilisearch/README.md`] |
| TRUTH-02 | `mix verify.adopter` fast/live proof paths target existing files and current proof surfaces; stale references to missing test files or removed guides do not remain in maintainer workflow surfaces. | Keep the existing task seam, replace the missing fast-target contract with a small real test file, and align task help, task internals, maintainer docs, and CI-parity wording around the actual fast/live paths. [VERIFIED: `.planning/REQUIREMENTS.md`] [VERIFIED: `lib/mix/tasks/verify.adopter.ex`] [VERIFIED: `test/mix/tasks/verify_adopter_test.exs`] [VERIFIED: `.github/workflows/ci.yml`] |
| TRUTH-03 | Planning truth explicitly distinguishes defended in-repo proof from reviewed outside-adopter evidence, and current planning/docs no longer rely on the missing `Scrypath.SearchModule` or `guides/support-and-compatibility.md` surfaces as settled shipped fact. | Classify `SearchModule` as salvage-backed historical work but absent from branch tip, then update active planning truth and any touched archive wording to preserve that distinction without relanding code. [VERIFIED: `.planning/REQUIREMENTS.md`] [VERIFIED: `.planning/STATE.md`] [VERIFIED: `.planning/MILESTONES.md`] [VERIFIED: `.planning/milestones/v1.20-ROADMAP.md`] [VERIFIED: `.planning/milestones/v1.20-MILESTONE-AUDIT.md`] [VERIFIED: local git history for `lib/scrypath/search_module.ex`] |
</phase_requirements>

## Summary

Phase 86 is a truth-repair phase, not a feature phase. The checked-out tree currently has no `guides/support-and-compatibility.md`, no `test/scrypath/readiness_contract_test.exs`, and no `Scrypath.SearchModule` code, guide, or tests, yet active maintainer surfaces still assume pieces of that older support/readiness story exist. `README.md` remains an adopter front door, `CONTRIBUTING.md` remains the maintainer workflow surface, and `examples/phoenix_meilisearch/README.md` remains the live runbook, but there is no single current support/readiness authority tying them together. [VERIFIED: `.planning/ROADMAP.md`] [VERIFIED: `.planning/REQUIREMENTS.md`] [VERIFIED: `.planning/phases/86-support-truth-and-proof-surface-reconciliation/86-CONTEXT.md`] [VERIFIED: `README.md`] [VERIFIED: `CONTRIBUTING.md`] [VERIFIED: `examples/phoenix_meilisearch/README.md`] [VERIFIED: local file existence checks]

`mix verify.adopter` is the clearest executable drift seam. Its help text and `@fast_tests` still cite `test/scrypath/readiness_contract_test.exs`, but that file does not exist. Running `mix verify.adopter` today still passes because the remaining task test file exists and `mix test` does not turn the missing path into a meaningful guard, so the task looks healthy while silently failing to prove the support/readiness surface it claims to cover. The existing `test/mix/tasks/verify_adopter_test.exs` only covers flags, prerequisite errors, and a progress marker; it does not prove that the advertised fast-path files or canonical doc links are real. [VERIFIED: `lib/mix/tasks/verify.adopter.ex`] [VERIFIED: `test/mix/tasks/verify_adopter_test.exs`] [VERIFIED: local file existence checks] [VERIFIED: local command `mix verify.adopter`] [VERIFIED: local command `mix test test/mix/tasks/verify_adopter_test.exs`]

The repo also already tells us how to classify the `SearchModule` mismatch. Active planning surfaces such as `.planning/MILESTONES.md` and the `v1.20` archive still describe `Scrypath.SearchModule` as shipped current truth, while branch tip code and docs-contract assertions say the layer is absent. A bounded history check found the missing support guide and all `SearchModule` artifacts inside salvage snapshot commit `ff52363` (`chore: preserve local dirty state before main reconciliation`), which means the mismatch is not pure planning fiction, but it is also not current branch-tip reality. The correct Phase 86 posture is therefore: branch tip absent, salvage/history present, recovery deferred. [VERIFIED: `.planning/MILESTONES.md`] [VERIFIED: `.planning/milestones/v1.20-ROADMAP.md`] [VERIFIED: `.planning/milestones/v1.20-MILESTONE-AUDIT.md`] [VERIFIED: `test/scrypath/docs_contract_test.exs`] [VERIFIED: local git history for `guides/support-and-compatibility.md`] [VERIFIED: local git history for `lib/scrypath/search_module.ex`] [VERIFIED: local git show of salvage snapshot files]

The strongest plan is three slices only: restore one canonical support/readiness guide on the historical path to minimize churn, repair the existing `verify.adopter` command family with a new narrow readiness-contract test, and reconcile active planning truth plus any touched archive wording so current files stop treating salvage-era support or `SearchModule` surfaces as present-day fact. Keep the guards small and seam-specific; do not reuse the broad `docs_contract_test.exs` suite as the fast adopter gate. [VERIFIED: `.planning/phases/86-support-truth-and-proof-surface-reconciliation/86-CONTEXT.md`] [VERIFIED: `docs/jtbd-gap-map.md`] [VERIFIED: `test/scrypath/docs_contract_test.exs`] [VERIFIED: local command `mix test test/scrypath/docs_contract_test.exs`]

**Primary recommendation:** plan Phase 86 in three slices:
1. Restore `guides/support-and-compatibility.md` as the single canonical support/readiness authority and rewire active maintainer/adopter docs to it.
2. Repair `mix verify.adopter` fast/live truth on the existing task seam with one new narrow readiness-contract test plus stronger task-help assertions.
3. Reconcile `SearchModule` and removed-guide planning truth with explicit branch-tip-vs-salvage wording and a few bounded recurrence guards. [VERIFIED: `.planning/ROADMAP.md`] [VERIFIED: `.planning/phases/86-support-truth-and-proof-surface-reconciliation/86-CONTEXT.md`] [VERIFIED: local git history] [VERIFIED: `lib/mix/tasks/verify.adopter.ex`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Canonical support/readiness authority | `guides/support-and-compatibility.md` (restored) | `guides/overview.md` | The missing guide is the one surface intended to own support truth; overview should only route to it. [VERIFIED: `.planning/phases/86-support-truth-and-proof-surface-reconciliation/86-CONTEXT.md`] [VERIFIED: local git history for `guides/support-and-compatibility.md`] [VERIFIED: `guides/overview.md`] |
| Adopter front door | `README.md` | Canonical guide | README should stay short and route support/readiness claims instead of becoming the support matrix itself. [VERIFIED: `.planning/phases/86-support-truth-and-proof-surface-reconciliation/86-CONTEXT.md`] [VERIFIED: `README.md`] |
| Maintainer workflow and CI mapping | `CONTRIBUTING.md` | `mix help verify.adopter`, `.github/workflows/ci.yml` | Maintainers need one current command-family explanation with fast/live/CI mapping in one place. [VERIFIED: `.planning/phases/86-support-truth-and-proof-surface-reconciliation/86-CONTEXT.md`] [VERIFIED: `CONTRIBUTING.md`] [VERIFIED: `lib/mix/tasks/verify.adopter.ex`] [VERIFIED: `.github/workflows/ci.yml`] |
| Live proof runbook | `examples/phoenix_meilisearch/README.md` | `mix verify.adopter --live` | The example README already owns env tables and the exact `cd examples/phoenix_meilisearch && mix deps.get && mix test` path. [VERIFIED: `examples/phoenix_meilisearch/README.md`] [VERIFIED: `lib/mix/tasks/verify.adopter.ex`] |
| Branch-tip vs archive truth | `.planning/STATE.md` and `.planning/MILESTONES.md` | `.planning/milestones/v1.20-ROADMAP.md`, `.planning/milestones/v1.20-MILESTONE-AUDIT.md` | Active planning files must stop overstating current code, while historical files can preserve “claimed/recoverable” nuance. [VERIFIED: `.planning/STATE.md`] [VERIFIED: `.planning/MILESTONES.md`] [VERIFIED: `.planning/milestones/v1.20-ROADMAP.md`] [VERIFIED: `.planning/milestones/v1.20-MILESTONE-AUDIT.md`] |
| Fast recurrence guard | New `test/scrypath/readiness_contract_test.exs` | `test/mix/tasks/verify_adopter_test.exs` | The task test seam is already focused; it needs one small companion file for file/link/planning truth assertions rather than the whole docs-contract suite. [VERIFIED: `lib/mix/tasks/verify.adopter.ex`] [VERIFIED: `test/mix/tasks/verify_adopter_test.exs`] [VERIFIED: `test/scrypath/docs_contract_test.exs`] |

## Standard Stack

### Core

| Library / Module | Purpose | Why Standard |
|------------------|---------|--------------|
| `guides/support-and-compatibility.md` | Canonical support/readiness authority | This exact path already existed historically and is the name active planning still expects, so restoring it minimizes churn and avoids inventing a second authority name. [VERIFIED: local git history for `guides/support-and-compatibility.md`] [VERIFIED: `.planning/STATE.md`] [VERIFIED: `.planning/ROADMAP.md`] |
| `lib/mix/tasks/verify.adopter.ex` | Maintainer-facing fast/live proof command family | The phase context explicitly says repair this seam rather than replace it. [VERIFIED: `.planning/phases/86-support-truth-and-proof-surface-reconciliation/86-CONTEXT.md`] [VERIFIED: `lib/mix/tasks/verify.adopter.ex`] |
| `test/mix/tasks/verify_adopter_test.exs` | Task-argument/help/prerequisite regression seam | It already owns the Mix-task-specific contract and should remain the task-level test surface. [VERIFIED: `test/mix/tasks/verify_adopter_test.exs`] |
| `examples/phoenix_meilisearch/README.md` | Canonical live proof/runbook surface | It already owns env vars, CI job parity, and the exact example command sequence. [VERIFIED: `examples/phoenix_meilisearch/README.md`] |

### Supporting

| Library / Module | Purpose | When to Use |
|------------------|---------|-------------|
| New `test/scrypath/readiness_contract_test.exs` | Narrow fast-path proof for guide existence, active doc routing, task-help alignment, and active planning truth | Use as the service-free support/readiness guard that `mix verify.adopter` should actually run. [VERIFIED: `lib/mix/tasks/verify.adopter.ex`] [VERIFIED: local file absence check for `test/scrypath/readiness_contract_test.exs`] |
| `test/scrypath/docs_contract_test.exs` | Broader public-story and branch-tip drift assertions | Keep for wider docs truth, but do not make it the default adopter fast gate. It is already broad and currently red on an unrelated JTBD-date assertion. [VERIFIED: `test/scrypath/docs_contract_test.exs`] [VERIFIED: local command `mix test test/scrypath/docs_contract_test.exs`] |
| `.planning/STATE.md` | Active branch-tip drift ledger | Use for current-truth annotations and milestone-open concerns. [VERIFIED: `.planning/STATE.md`] |
| `.planning/MILESTONES.md` | Rolling shipped-history surface still visible to maintainers | Update current wording here because it is an active planning file, not a sealed archive. [VERIFIED: `.planning/MILESTONES.md`] |
| `.planning/milestones/v1.20-{ROADMAP,MILESTONE-AUDIT}.md` | Historical `SearchModule` claim surfaces | Touch only to preserve history-vs-branch-tip nuance, not to re-land code. [VERIFIED: `.planning/milestones/v1.20-ROADMAP.md`] [VERIFIED: `.planning/milestones/v1.20-MILESTONE-AUDIT.md`] |

## Architecture Patterns

### Pattern 1: One canonical support/readiness guide, three narrow consumers

Restore the historical guide path `guides/support-and-compatibility.md` and let it own:

- defended Phoenix + Meilisearch path
- current runtime/version anchors
- supported sync-mode posture
- canonical proof command family
- repo-clone vs Hex-package boundary
- in-repo proof vs outside-adopter evidence distinction

Then keep `README.md`, `CONTRIBUTING.md`, and the example README short and role-specific. `README.md` should point to the guide for support truth, `CONTRIBUTING.md` should point to it for maintainer workflow context, and the example README should keep live env/runbook detail without re-owning the support contract. [VERIFIED: `.planning/phases/86-support-truth-and-proof-surface-reconciliation/86-CONTEXT.md`] [VERIFIED: `README.md`] [VERIFIED: `CONTRIBUTING.md`] [VERIFIED: `examples/phoenix_meilisearch/README.md`] [VERIFIED: local git show of historical `guides/support-and-compatibility.md`]

### Pattern 2: `mix verify.adopter` stays a thin orchestrator with one real fast contract

Keep the current command family:

- `mix verify.adopter` -> fast, service-free, narrow
- `mix verify.adopter --live` -> loud prerequisite checks, then shell into `examples/phoenix_meilisearch`

Do not widen fast mode into `docs_contract_test.exs`, and do not move Docker or CI readiness logic into the Mix task. Instead, make fast mode run the existing task test plus one new readiness-contract test that proves the exact files, help text, links, and planning phrases this phase repairs. [VERIFIED: `.planning/phases/86-support-truth-and-proof-surface-reconciliation/86-CONTEXT.md`] [VERIFIED: `lib/mix/tasks/verify.adopter.ex`] [VERIFIED: `test/mix/tasks/verify_adopter_test.exs`] [VERIFIED: `.github/workflows/ci.yml`]

### Pattern 3: SearchModule truth uses a three-way classification

Use explicit wording categories:

- **current branch-tip truth:** `main` does not contain `Scrypath.SearchModule`, `guides/search-modules.md`, or `test/scrypath/search_module_test.exs`
- **salvage/history truth:** those artifacts do exist in salvage snapshot commit `ff52363`
- **planning consequence:** active files must not describe them as currently shipped, but historical files may say they were claimed or preserved in salvage history

That lets Phase 86 repair credibility without making a hidden product decision about whether to recover the layer later. [VERIFIED: `.planning/phases/86-support-truth-and-proof-surface-reconciliation/86-CONTEXT.md`] [VERIFIED: `.planning/STATE.md`] [VERIFIED: local file existence checks] [VERIFIED: local git history and git show for `lib/scrypath/search_module.ex`, `guides/search-modules.md`, `test/scrypath/search_module_test.exs`]

### Pattern 4: Bounded regression guards should target seams, not prose volume

The right guard set is small:

- file-existence and help-text truth on `verify.adopter`
- one canonical guide link target across active docs
- one active-planning truth check that current files do not treat removed guide or `SearchModule` surfaces as present-day code

Do not build a generalized “freeze all support prose” harness. The repo already prefers seam tests over narrative snapshots, and this phase context explicitly locks that posture. [VERIFIED: `.planning/phases/86-support-truth-and-proof-surface-reconciliation/86-CONTEXT.md`] [VERIFIED: `test/scrypath/docs_contract_test.exs`] [VERIFIED: `test/mix/tasks/verify_adopter_test.exs`]

## Recommended Plan Slices

### Slice 1: Restore the canonical support/readiness authority

- Recreate `guides/support-and-compatibility.md` on its historical path.
- Base the content on current branch-tip facts only: defended Phoenix + Meilisearch path, supported sync postures, proof command family, clone-vs-Hex boundary, and “in-repo proof is not outside-adopter evidence.”
- Rewire `README.md`, `CONTRIBUTING.md`, `guides/overview.md`, and `mix help verify.adopter` to point at it.
- Leave sync semantics on `guides/sync-modes-and-visibility.md` and live env tables on `examples/phoenix_meilisearch/README.md`. [VERIFIED: `.planning/phases/86-support-truth-and-proof-surface-reconciliation/86-CONTEXT.md`] [VERIFIED: `README.md`] [VERIFIED: `CONTRIBUTING.md`] [VERIFIED: `guides/overview.md`] [VERIFIED: `examples/phoenix_meilisearch/README.md`] [VERIFIED: local git show of historical `guides/support-and-compatibility.md`]

### Slice 2: Repair `verify.adopter` fast/live contract truth

- Keep `lib/mix/tasks/verify.adopter.ex` as the existing seam.
- Replace the stale fast target with a real small file, preferably `test/scrypath/readiness_contract_test.exs`.
- Keep `test/mix/tasks/verify_adopter_test.exs` for task-level behavior and add assertions that `mix help verify.adopter` matches the actual fast/live wording and file targets.
- Update `CONTRIBUTING.md` so `mix verify.adopter` is again the explicit maintainer-facing adopter-proof family, with clear mapping to `mix verify.adopter --live` and `phoenix-example-integration`. [VERIFIED: `.planning/phases/86-support-truth-and-proof-surface-reconciliation/86-CONTEXT.md`] [VERIFIED: `lib/mix/tasks/verify.adopter.ex`] [VERIFIED: `test/mix/tasks/verify_adopter_test.exs`] [VERIFIED: `CONTRIBUTING.md`] [VERIFIED: `.github/workflows/ci.yml`]

### Slice 3: Reconcile active planning truth and add bounded recurrence guards

- Update active planning files first: `.planning/STATE.md`, `.planning/MILESTONES.md`, and any current milestone surfaces that still present removed guide or `SearchModule` artifacts as current truth.
- If touching `v1.20` archive files, preserve the distinction between “historically claimed / salvage-backed” and “present on branch tip.”
- Add only a few assertions for active-file truth; do not freeze whole archive prose blocks.
- If Phase 86 edits `docs/jtbd-gap-map.md` or `test/scrypath/docs_contract_test.exs`, repair the currently failing stale-date expectation as part of that same narrow truth pass rather than making `docs_contract_test.exs` the new fast gate. [VERIFIED: `.planning/STATE.md`] [VERIFIED: `.planning/MILESTONES.md`] [VERIFIED: `.planning/milestones/v1.20-ROADMAP.md`] [VERIFIED: `.planning/milestones/v1.20-MILESTONE-AUDIT.md`] [VERIFIED: `docs/jtbd-gap-map.md`] [VERIFIED: `test/scrypath/docs_contract_test.exs`] [VERIFIED: local command `mix test test/scrypath/docs_contract_test.exs`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Canonical support truth | Another partial README/CONTRIBUTING prose split | One restored guide plus short links | The repo already uses one-guide-per-concern routing, and the current drift came from losing that authority. [VERIFIED: `guides/overview.md`] [VERIFIED: `.planning/phases/86-support-truth-and-proof-surface-reconciliation/86-CONTEXT.md`] |
| Fast adopter proof | A giant default docs-contract suite | One small `readiness_contract_test.exs` plus task tests | Fast mode must stay narrow and truthful; the full docs-contract suite is too broad and currently red on unrelated drift. [VERIFIED: `.planning/phases/86-support-truth-and-proof-surface-reconciliation/86-CONTEXT.md`] [VERIFIED: `test/scrypath/docs_contract_test.exs`] [VERIFIED: local command `mix test test/scrypath/docs_contract_test.exs`] |
| SearchModule reconciliation | A code reland hidden inside wording cleanup | Branch-tip-vs-salvage classification and planning text repair | The phase explicitly defers relanding; the job here is truth repair. [VERIFIED: `.planning/phases/86-support-truth-and-proof-surface-reconciliation/86-CONTEXT.md`] [VERIFIED: local git history] |
| Planning truth guard | A global frozen-planning harness | A few assertions against active files only | The context explicitly rejects broad prose locking. [VERIFIED: `.planning/phases/86-support-truth-and-proof-surface-reconciliation/86-CONTEXT.md`] |

## Common Pitfalls

### Pitfall 1: Treating `docs/operator-support.md` as the missing readiness authority

`docs/operator-support.md` is real, but it is a maintainer/operator first-response guide with older verify-task language, not the adopter-facing support/readiness contract that Phase 68 and Phase 86 describe. Repointing new support truth there would keep the authority split muddled instead of repairing it. [VERIFIED: `docs/operator-support.md`] [VERIFIED: `.planning/STATE.md`] [VERIFIED: `.planning/phases/86-support-truth-and-proof-surface-reconciliation/86-CONTEXT.md`]

### Pitfall 2: Assuming `mix verify.adopter` is healthy because it exits green

The current task exits green even though one advertised fast-path file is missing. That makes raw pass/fail output misleading for this phase unless the task’s claimed file targets are also asserted directly. [VERIFIED: `lib/mix/tasks/verify.adopter.ex`] [VERIFIED: local file absence check for `test/scrypath/readiness_contract_test.exs`] [VERIFIED: local command `mix verify.adopter`]

### Pitfall 3: Over-correcting archive drift into historical erasure

The salvage snapshot proves the missing support guide and `SearchModule` artifacts existed somewhere in repo history. Saying “this never existed” would be as inaccurate as saying “this ships on current main.” Use branch-tip-vs-salvage wording instead. [VERIFIED: local git history for `guides/support-and-compatibility.md`] [VERIFIED: local git history for `lib/scrypath/search_module.ex`]

### Pitfall 4: Letting fast mode absorb the whole docs-contract suite

Phase 86’s fast gate should protect support/readiness truth, not every public-doc contract in the repo. If fast mode starts running the full `docs_contract_test.exs` suite, maintainers lose the narrow “is adopter proof still coherent?” signal this command family was meant to provide. [VERIFIED: `.planning/phases/86-support-truth-and-proof-surface-reconciliation/86-CONTEXT.md`] [VERIFIED: `test/scrypath/docs_contract_test.exs`]

## Validation Architecture

### Test Framework

- `ExUnit` via focused `mix test` commands
- semantic task verification via `mix verify.adopter`
- example live proof via `mix verify.adopter --live`
- CI parity via `.github/workflows/ci.yml` and `phoenix-example-integration` [VERIFIED: `.planning/config.json`] [VERIFIED: `lib/mix/tasks/verify.adopter.ex`] [VERIFIED: `.github/workflows/ci.yml`]

### Phase Requirements -> Test Map

| Requirement | Validation Strategy |
|-------------|---------------------|
| TRUTH-01 | New `test/scrypath/readiness_contract_test.exs` should assert the canonical support/readiness guide exists and that active maintainer/adopter docs route to it instead of owning competing support truth. [VERIFIED: `.planning/REQUIREMENTS.md`] [VERIFIED: `.planning/phases/86-support-truth-and-proof-surface-reconciliation/86-CONTEXT.md`] |
| TRUTH-02 | `test/mix/tasks/verify_adopter_test.exs` should assert help/flag behavior and loud live prereq failures; `mix verify.adopter` should run only real fast-path files; `mix verify.adopter --live` remains the live example proof when env/services are present. [VERIFIED: `.planning/REQUIREMENTS.md`] [VERIFIED: `test/mix/tasks/verify_adopter_test.exs`] [VERIFIED: `lib/mix/tasks/verify.adopter.ex`] |
| TRUTH-03 | Narrow assertions should prove active planning/docs distinguish branch-tip proof from outside-adopter evidence and stop presenting removed support-guide or `SearchModule` surfaces as current checked-out fact. [VERIFIED: `.planning/REQUIREMENTS.md`] [VERIFIED: `.planning/STATE.md`] [VERIFIED: `.planning/MILESTONES.md`] [VERIFIED: `docs/jtbd-gap-map.md`] |

### Recommended Commands

- Fast contract slice: `mix test test/scrypath/readiness_contract_test.exs test/mix/tasks/verify_adopter_test.exs` [VERIFIED: `lib/mix/tasks/verify.adopter.ex`] [VERIFIED: `test/mix/tasks/verify_adopter_test.exs`]
- Maintainer fast entrypoint: `mix verify.adopter` [VERIFIED: `lib/mix/tasks/verify.adopter.ex`] [VERIFIED: `.github/workflows/ci.yml`]
- Live proof: `SCRYPATH_EXAMPLE_INTEGRATION=1 PGPORT=5433 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix verify.adopter --live` [VERIFIED: `lib/mix/tasks/verify.adopter.ex`] [VERIFIED: `examples/phoenix_meilisearch/README.md`]

### Wave 0 Gaps

- Add `test/scrypath/readiness_contract_test.exs`; the task already points at it, but the file does not exist. [VERIFIED: `lib/mix/tasks/verify.adopter.ex`] [VERIFIED: local file absence check]
- Reconcile the currently failing stale-date assertion in `test/scrypath/docs_contract_test.exs` if Phase 86 touches the JTBD-gap-map seam. [VERIFIED: local command `mix test test/scrypath/docs_contract_test.exs`] [VERIFIED: `docs/jtbd-gap-map.md`]

## Security Domain

### Applicable Concerns

- Overstated support/readiness claims are a trust and operator-risk problem because they cause maintainers or adopters to rely on commands, files, or code paths that do not exist on the current tree. [VERIFIED: `.planning/REQUIREMENTS.md`] [VERIFIED: `.planning/STATE.md`]
- Confusing branch-tip truth with archive or salvage truth creates repudiation risk in milestone planning and outside-adopter review. [VERIFIED: `.planning/MILESTONES.md`] [VERIFIED: `.planning/milestones/v1.20-ROADMAP.md`] [VERIFIED: local git history]

### Mitigation Direction

- Keep one authority per concern.
- Keep `verify.adopter` executable-truth-first.
- Keep branch-tip-vs-salvage wording explicit in active planning surfaces.
- Avoid broad prose freezing that maintainers will stop trusting or running. [VERIFIED: `.planning/phases/86-support-truth-and-proof-surface-reconciliation/86-CONTEXT.md`] [VERIFIED: `docs/jtbd-gap-map.md`]

## Sources

### Primary

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/phases/86-support-truth-and-proof-surface-reconciliation/86-CONTEXT.md`
- `README.md`
- `CONTRIBUTING.md`
- `examples/phoenix_meilisearch/README.md`
- `guides/overview.md`
- `guides/jtbd-and-user-flows.md`
- `guides/sync-modes-and-visibility.md`
- `docs/jtbd-gap-map.md`
- `docs/operator-support.md`
- `lib/mix/tasks/verify.adopter.ex`
- `test/mix/tasks/verify_adopter_test.exs`
- `test/scrypath/docs_contract_test.exs`
- `.planning/MILESTONES.md`
- `.planning/milestones/v1.20-ROADMAP.md`
- `.planning/milestones/v1.20-MILESTONE-AUDIT.md`
- `.planning/todos/search-module-archive-code-drift.md`
- `.github/workflows/ci.yml`
- local commands: file-existence checks, `mix test test/mix/tasks/verify_adopter_test.exs`, `mix verify.adopter`, `mix test test/scrypath/docs_contract_test.exs`
- local git history / salvage check for `guides/support-and-compatibility.md`, `lib/scrypath/search_module.ex`, `lib/scrypath/search_module/param_error.ex`, `guides/search-modules.md`, and `test/scrypath/search_module_test.exs`

## RESEARCH COMPLETE
