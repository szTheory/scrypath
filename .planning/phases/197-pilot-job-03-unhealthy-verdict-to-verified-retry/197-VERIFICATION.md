---
phase: 197-pilot-job-03-unhealthy-verdict-to-verified-retry
verified: 2026-11-22T17:37:00Z
status: human_needed
score: 8/9 must-haves verified
covered_files:
  - ".planning/phases/197-pilot-job-03-unhealthy-verdict-to-verified-retry/197-01-PLAN.md"
  - ".planning/phases/197-pilot-job-03-unhealthy-verdict-to-verified-retry/197-01-SUMMARY.md"
  - ".planning/phases/197-pilot-job-03-unhealthy-verdict-to-verified-retry/197-02-PLAN.md"
  - ".planning/phases/197-pilot-job-03-unhealthy-verdict-to-verified-retry/197-02-SUMMARY.md"
  - ".planning/phases/197-pilot-job-03-unhealthy-verdict-to-verified-retry/197-03-PLAN.md"
  - ".planning/phases/197-pilot-job-03-unhealthy-verdict-to-verified-retry/197-03-SUMMARY.md"
  - ".planning/phases/197-pilot-job-03-unhealthy-verdict-to-verified-retry/197-04-PLAN.md"
  - ".planning/phases/197-pilot-job-03-unhealthy-verdict-to-verified-retry/197-04-SUMMARY.md"
  - ".planning/phases/197-pilot-job-03-unhealthy-verdict-to-verified-retry/197-05-PLAN.md"
  - ".planning/phases/197-pilot-job-03-unhealthy-verdict-to-verified-retry/197-05-SUMMARY.md"
  - "AGENTS.md"
  - "CONTRIBUTING.md"
  - "GLOSSARY.md"
  - "examples/scrypath_ecommerce/e2e/UI-REVIEW.md"
  - "examples/scrypath_ecommerce/e2e/catalog-fidelity-probe.mjs"
  - "examples/scrypath_ecommerce/e2e/ui-review.mjs"
  - "examples/scrypath_ecommerce/e2e/ui-review.selftest.mjs"
  - "examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh"
  - "fixtures/scrypath_fixtures/lib/scrypath_fixtures/shopadelic/product.ex"
  - "scrypath_ops/assets/js/storybook.js"
  - "scrypath_ops/catalog/lib/mix/tasks/scrypath_ops.catalog.serve.ex"
  - "scrypath_ops/catalog/lib/scrypath_ops/catalog/endpoint.ex"
  - "scrypath_ops/catalog/lib/scrypath_ops/catalog/router.ex"
  - "scrypath_ops/config/dev.exs"
  - "scrypath_ops/lib/scrypath_ops/failed_sync_view.ex"
  - "scrypath_ops/lib/scrypath_ops/failed_sync_view/row.ex"
  - "scrypath_ops/lib/scrypath_ops/posture.ex"
  - "scrypath_ops/lib/scrypath_ops/recovery_view.ex"
  - "scrypath_ops/lib/scrypath_ops/recovery_view/document.ex"
  - "scrypath_ops/lib/scrypath_ops_web/components/failed_sync.ex"
  - "scrypath_ops/lib/scrypath_ops_web/components/recovery.ex"
  - "scrypath_ops/lib/scrypath_ops_web/components/search_health.ex"
  - "scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex"
  - "scrypath_ops/lib/scrypath_ops_web/live/on_mount.ex"
  - "scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex"
  - "scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex"
  - "scrypath_ops/priv/static/assets/js/storybook.js"
  - "scrypath_ops/storybook/_start.index.exs"
  - "scrypath_ops/storybook/areas/_areas.index.exs"
  - "scrypath_ops/storybook/areas/document_freshness.story.exs"
  - "scrypath_ops/storybook/areas/failed_row.story.exs"
  - "scrypath_ops/storybook/areas/failed_summary.story.exs"
  - "scrypath_ops/storybook/areas/health_schema_row.story.exs"
  - "scrypath_ops/storybook/areas/health_verdict.story.exs"
  - "scrypath_ops/storybook/areas/recovery_status.story.exs"
  - "scrypath_ops/storybook/jobs/_jobs.index.exs"
  - "scrypath_ops/storybook/jobs/job_03_on_call_recovers_failed_sync.story.exs"
  - "scrypath_ops/storybook/patterns/_patterns.index.exs"
  - "scrypath_ops/storybook/patterns/delete_confirmation.story.exs"
  - "scrypath_ops/storybook/patterns/failed_filters.story.exs"
  - "scrypath_ops/storybook/patterns/retry_receipt.story.exs"
  - "scrypath_ops/storybook/primitives/_primitives.index.exs"
  - "scrypath_ops/storybook/surfaces/_surfaces.index.exs"
  - "scrypath_ops/storybook/surfaces/failed_sync.story.exs"
  - "scrypath_ops/storybook/surfaces/search_health.story.exs"
  - "scrypath_ops/storybook/welcome.story.exs"
  - "scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs"
  - "scrypath_ops/test/scrypath_ops_web/design_tokens_contract_test.exs"
  - "scrypath_ops/test/scrypath_ops_web/live/catalog_journey_test.exs"
  - "scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs"
  - "scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs"
  - "scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs"
  - "scrypath_ops/test/scrypath_ops_web/operator_ia_contract_test.exs"
  - "scrypath_ops/test/support/catalog_checks.ex"
  - "scrypath_ops/test/support/catalog_render_all.ex"
  - "scrypath_ops/test/support/copy_rules.json"
  - "scrypath_ops/test/support/copy_surfaces.ex"
  - "scrypath_ops/test/support/html_canon.ex"
  - "test/mix/tasks/dependency_boundary_contract_test.exs"
  - "test/release/ops_dependency_boundary_test.exs"
  - "test/release/shipped_docs_contract_test.exs"
  - "test/support/release/shipped_docs.ex"
covered_digest: "v4:sha256:e90947a9ad7aab48a7d968dd2002584d9bf11a589031bacdd51958528f1753da"
behavior_unverified: 0
overrides_applied: 0
coincidental_reliance_items:
  - truth: "The seeded storybook is stable across restarts (identical canonical iframe documents), the recorded proof for PILOT-06"
    reason: incidental-ordering
    harden: "fixtures/scrypath_fixtures/lib/scrypath_fixtures/failures.ex:247 builds the Oban error text with inspect/1 over a struct that holds the atom-keyed map %{task_uid: 908, index_uid: \"shopadelic_product\"}. A runtime-built small map prints its keys in atom-table order, which depends on module load order, and nothing enforces that order. Observed: two boots of the same code with different request order printed the two keys in opposite order; every other byte (data, frozen time, ids, counts) was identical. Build the text from ordered data (a literal, or a sorted rendering) or have the canonical form ignore it, then the restart proof is a guarantee and not a coincidence."
human_verification:
  - test: "Pause 1 look (PILOT-07). Open the storybook landing page (currently http://127.0.0.1:4013/storybook/welcome) and the nine linked screens in .planning/research/storybook-catalog/PAUSE-1-PHASE-197.md; paste feedback verbatim into the empty table there (storybook path, variation id, theme, viewport or 'unknown', kind, triage)."
    expected: "The feedback table has rows, or the maintainer replies 'ok'; the feedback sizes Phase 198 as cut, shrink or run (recommendation in the note: cut)."
    why_human: "Whether the screens look and read right is subjective and the feedback is the maintainer's own words. The phase artifacts define this stop (ROADMAP 'Gate (Pause 1)'); no automated check can produce it, and nothing here claims the design is approved."
  - test: "Port decision (PILOT-06 and ROADMAP criterion 5 name 127.0.0.1:4003; the storybook serves on 4013 because another project's beam.smp (pid 22117, cwd /Users/jon/projects/fablebook/hosts/operator) holds 4003)."
    expected: "Either the holder is freed and the storybook moves back to 4003 using the four steps in the storybook.deviation.move_back field of .planning/UI-PREVIEW.json, or the recorded decision is changed to 4013 (edit ROADMAP criterion 5 and PILOT-06)."
    why_human: "Stopping another project's process is outside this repository's authority; only the maintainer can free the port or change the recorded decision. This verification treats the deviation as a recorded decision, not a gap."
  - test: "Fixtures fold decision (the ADR 0002 exit rule, deliberately left to Pause 1 by 197-CONTEXT). Read the evidence and recommendation in the 'Fixtures fold' section of the Pause 1 note."
    expected: "The maintainer chooses keep (recommended; revisit when the four phase173 host specs are ported or at v1.51) or fold into scrypath_ops."
    why_human: "A recorded owner decision point that the context reserved for the maintainer; folding moves a top-level project and touches boundary tests, Docker stages and the classifier."
---

# Phase 197: Pilot JOB-03, unhealthy verdict to verified retry Verification Report

**Phase Goal:** One job (Search health row, to Failed sync prefilled, to retry, to return) is covered by a mounted journey test, extracted into components shared with the story, shown in a stable seeded storybook, and held by one catalog contract test; then the run pauses for the maintainer's look.
**Verified:** 2026-11-22T17:37:00Z
**Status:** human_needed
**Re-verification:** No, initial verification
**Checked at:** `origin/main` 6c22f463 (code PR #177 squash 33aac70f, docs PR #178 squash 6c22f463). The checkout is on `gsd/phase-197-closeout` at that commit.

## Summary in plain language

Everything that a machine can prove about this phase is proven, and most of it I re-ran myself instead of reading the summaries. The only open items are the ones the phase was designed to hand to the maintainer: the Pause 1 look and feedback (PILOT-07), the 4003 versus 4013 port decision (PILOT-06) and the fixtures fold decision. They are not manual UAT for correctness; they are the stop the roadmap defines. One advisory finding: the "stable across restarts" proof is true but not guaranteed (details under the coincidental-reliance item).

## Goal Achievement

### Observable Truths

| # | Truth (roadmap contract first) | Status | Evidence |
|---|---|---|---|
| 1 | SC1 / PILOT-01: the mounted journey was written first and passes on current code (Search health row to Failed sync prefilled, retry with one insert, return with the same context); both denials have a positive control and an absence check; the stale-sudo test at `failed_sync_live_test.exs:540` now renders the row | ✓ VERIFIED | Commit order on the PR branch: `0dceb523` (journey) precedes the first extraction commit `5eec3656`. I archived the pre-extraction commit `d913b8b6` (no `Posture.build`, no components) and ran `catalog_journey_test.exs` there: 4 tests, 0 failures; the same file at HEAD: 4 tests, 0 failures; `git diff d913b8b6 33aac70f` on the file is empty (unmodified through extraction). The test asserts the row, the link `/ops/failed-sync?schema=...` with decoded params, five rows with retry buttons for 101-104 and none for task 43, exactly one insert (`Agent` counter 0 to 1), the receipt text, the handoff query, the Sync and index evidence line, the return links, and `SPD-2041`/`SPD-2042` absent after the allowlist denial (control: present before). Stale-sudo test at `failed_sync_live_test.exs:550` mounts the view, asserts `has_element?` for the row, clicks it, asserts redirect and counter 0, then the control click gives counter 1 |
| 2 | SC2 / PILOT-02: stale-sudo `return_to` defect D1 fixed in `scrypath_ops` with its own test, no root `lib/` change | ✓ VERIFIED | `on_mount.ex` assigns `:return_to` from the request path and query (no host; `//`, backslash and control characters give nil). Test `failed_sync_live_test.exs:575` plus three `return_to_path/1` cases. Mutation check: with the pre-fix `on_mount.ex` restored in a scratch copy the D1 test fails with `right: %{"return_to" => "/"}`, the exact defect. `git diff --name-only 84afaba0 6c22f463` has no root `lib/`, `.github/`, `mix.exs` or lock file |
| 3 | SC3 / PILOT-03: pure view-models and shared components (Search health, then Failed sync and recovery); parity shows no unintended change; journey green unmodified | ✓ VERIFIED | `Posture.scan/2` (the only I/O) and pure `build/3`; `FailedSyncView.build/4` with closed enums; `RecoveryView` with `:unavailable`; LiveViews render `<SearchHealth.surface>`, `<FailedSync.surface>`, `<Recovery.recovery_status>`. Seam tests per area compare canonical trees with planted differences. **My own parity run**: captured 54 pages (11 scenarios x 2 pages, 16 `phase173` pages, 16 copy surfaces) on `d913b8b6` and on HEAD with the committed capture script, compared as canonical trees: 0 differences over 54 common captures; 5 captures exist only on HEAD (the five new copy surfaces for the new states, as the summary says). Control: a planted `Retry` to `Retrry` in one HEAD capture was reported as exactly that page |
| 3a | CONTEXT D3: Sync and index no longer crashes on an unresolvable recovery handle; closed "status unavailable" state with its own test | ✓ VERIFIED | `sync_drift_live_test.exs` "an unresolved recovery handle renders a closed unavailable state" (green at HEAD). Mutation check: that one test extracted into the pre-fix tree fails with `KeyError :replacement_job` at `sync_drift_live.ex:2182`, the recorded defect. `RecoveryView` makes evidence `nil` or a full map, so the half-empty shape cannot be built |
| 4 | SC4 / PILOT-05: `catalog_contract_test.exs` carries render-all, route and component coverage (no hard-coded counts, literal `@no_story` with reasons, stale keys fail), no-identical-variations, copy lint and DOM hygiene, each with a planted failure; runs in the existing `ops-ui` job as ledger row 11 of 12; no new required context | ✓ VERIFIED | Ran it: 36 tests, 0 failures (with the journey, 40 tests, 0 failures, seed 0). No numeric count literals in the file. Mutation check in a scratch copy: removing the `HelpLive` `@no_story` entry fails the coverage test with `[uncovered: ScrypathOpsWeb.HelpLive]`. `CONTRIBUTING.md` has the row and `Budget used: 11 of 12.`; root `workflow_wiring_test.exs` passes (176 root contract tests, 0 failures). `verify.ops_ui` runs plain `mix test` in `scrypath_ops`, so the file rides the existing lane; no `.github/` change; `ops-ui (path-scoped)` is green on PR head `95d716ae` |
| 5 | SC5 (tiers) / PILOT-04: stories in `primitives/ patterns/ areas/ surfaces/ jobs/`, JOB ids in paths, adopter as a variation dimension, both themes shown, descriptions claim no more than their linked test proves | ✓ VERIFIED | `find scrypath_ops/storybook`: five tier folders with indexes; `jobs/job_03_on_call_recovers_failed_sync.story.exs`; 40 non-primitive variations (areas 30, jobs 2, patterns 4, surfaces 4), inside the "about 40" cap; variation ids are scenario ids (Shopadelic, Wikily, Logistify). Render-all runs every variation in light and dark. Provenance lint ties each note's `Mounted` test file and scenario id to a real test and caps descriptions at 140 characters (planted failures pass). The Job story captions say only what the journey asserts. No Hosting story exists by recorded decision (CONTEXT: deferred), so "adopter theming only in one Hosting story" holds vacuously. Glossary and playbook C1 use the new tier names |
| 6 | SC5 (server) / PILOT-06: seeded storybook, `storybook` block in `UI-PREVIEW.json`, landing page with `main@sha`, `ui:preflight` checks it, AGENTS.md matches | ✓ VERIFIED (recorded deviation: port 4013, ratification is a Pause 1 item) | Running on 127.0.0.1:4013 (beam.smp pid 80496); `welcome` markers read `main 6c22f4639fc2`, `head 6c22f4639fc2`, dirty true, the retained checkout, epoch `2026-11-20T14:00:00Z`. I ran `npm run --silent ui:preflight` from the retained checkout: `ok: true`, preview ok, storybook ok with `local_main` = `remote_main` = `6c22f4639fc2`. `npm run ui:review:selftest` 35 of 35; `scripts/ci/ui_preservation.test.cjs` 53 of 53. Deep links answer 200 (page and iframe). Font fix proven live: the fidelity probe in font mode reports the same Hanken Grotesk stack on `html` and `body`, light and dark, for three stories. Server is DB-free, loopback-only (config and boundary tests), refuses a held port without signalling it (`port_verdict/3` tests; `lsof` shows 4003 held by the other project's pid 22117). AGENTS.md "UI work" is present tense and documents the port-collision rule. Port 4003 is held, so the 4003 path itself has not been run |
| 7 | PILOT-07: Pause 1 happens; feedback recorded verbatim; feedback sizes Phase 198 | ? UNCERTAIN (human) | The pause note exists, with the packet, nine deep links, the empty feedback table (header appears exactly once), fixtures fold evidence, findings and the Phase 198 sizing; no `198-*` directory exists and no audit, complete or cleanup step ran. The feedback itself cannot exist yet: it is the maintainer's. See Human Verification |
| 8 | FLOW-01 to FLOW-04 (standing rules) | ✓ VERIFIED | FLOW-01: PR #177 is `test(ops-ui)`, #178 `docs(phase-197)`, zero `feat`/`fix` commit subjects, 0 open PRs, Release Please run succeeded on both merges and opened nothing. FLOW-02: 5 plans in this phase, 13 plans across Phases 195 to 197 (cap 20); no root `lib/`, dependency, lock or workflow change. FLOW-03: protected files appear in neither PR diff (they remain modified and unstaged in the working tree); every local mirror lane and the one skipped set (docs PR, with a recorded reason) are in 197-05-SUMMARY; hosted required checks read through `gh api` on both exact heads are green or correctly skipped. FLOW-04: F1, F2, F3, F4, D2 and the rest are in the Pause 1 note and not fixed; D1 and D3 fixed. FLOW-05 is mapped to Phase 198 and is not claimed by this phase |

**Score:** 8/9 truths verified (0 present but behavior-unverified; 1 awaiting the maintainer)

### Required Artifacts

`verify.artifacts` for all five plans: 5/5, 4/4, 3/3, 4/4, 4/4 passed (exist, substantive). Wiring and data flow below.

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `scrypath_ops/test/scrypath_ops_web/live/catalog_journey_test.exs` | JOB-03 journey, denials, verified end | ✓ VERIFIED | 547 lines, 4 tests, ran green at HEAD and at the pre-extraction commit |
| `scrypath_ops/lib/scrypath_ops_web/live/on_mount.ex` | `return_to` assign | ✓ VERIFIED | Wired in both `router.ex` and `dev_router.ex` live sessions; `Gating.return_to/1` reads it |
| `scrypath_ops/lib/scrypath_ops/posture.ex` | `scan/2`, pure `build/3` | ✓ VERIFIED | `summary/4` composes them; round-trip and seam tests green |
| `scrypath_ops/lib/scrypath_ops/failed_sync_view.ex` (+ `row.ex`) | closed enums | ✓ VERIFIED | `@causes`, `page_state`, `summary_kind`, `sync_status` types |
| `scrypath_ops/lib/scrypath_ops/recovery_view.ex` (+ `document.ex`) | closed status including `:unavailable` | ✓ VERIFIED | Unknown shapes map to `:unavailable` |
| `scrypath_ops/lib/scrypath_ops_web/components/{search_health,failed_sync,recovery}.ex` | shared components | ✓ VERIFIED | Called by the LiveViews and by the stories |
| `scrypath_ops/storybook/**` | 17 stories, 5 tier indexes, `welcome` | ✓ VERIFIED | 58 render targets (57 variations + the page) |
| `scrypath_ops/catalog/lib/**`, `config/dev.exs` | loopback, DB-free server | ✓ VERIFIED | Endpoint absent from prod and mounted builds (boundary tests) |
| `examples/scrypath_ecommerce/e2e/ui-review.mjs`, `catalog-fidelity-probe.mjs` | preflight, probe | ✓ VERIFIED | Preflight run live; probe run live |
| `CONTRIBUTING.md` row 11 | ledger | ✓ VERIFIED | Wiring test green |
| `.planning/research/storybook-catalog/PAUSE-1-PHASE-197.md` | pause packet | ✓ VERIFIED | Feedback table empty by design |
| `.planning/reference/CI-EFFICIENCY.md` finding 30 | hosted cost | ✓ VERIFIED | Present; numbers re-read by the executor with `gh api` |

### Key Link Verification

`verify.key-links` for all five plans: 3/3 each, all verified. I also traced the two that matter most by hand: `posture_live.ex` renders `SearchHealth.surface` and `failed_sync_live.ex` renders `FailedSync.surface` (the story and the page call the same function), and `sync_drift_live.ex` renders `Recovery.recovery_status` from `RecoveryView.for_page/1`.

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| Surface stories | `summary`, `view` | `Scrypath.sync_status/2` and `Scrypath.failed_sync_work/2` over the fixtures' fake client, then `Posture.build/3` / `FailedSyncView.build/4` | yes: real normalizers over raw task and job maps | ✓ FLOWING |
| Job story | receipt | literal receipt shaped as the LiveView stores it, retry job 991 | yes, matches the journey's asserted values | ✓ FLOWING |
| Welcome page | build info | `:persistent_term` written by the serve task from git | yes (live markers match `origin/main`) | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Journey and catalog contract | `mix test test/scrypath_ops_web/live/catalog_journey_test.exs test/scrypath_ops_web/catalog_contract_test.exs --seed 0` (scrypath_ops, test env) | 40 tests, 0 failures | ✓ PASS |
| Journey on the pre-extraction commit | same journey file against `git archive d913b8b6` in the scratchpad | 4 tests, 0 failures | ✓ PASS |
| Changed live and contract tests | failed_sync, posture, sync_drift, operator_ia, design_tokens, copy_rules, catalog_routes | 207 tests, 0 failures | ✓ PASS |
| Whole `scrypath_ops` suite on HEAD | `mix test` in an archive of 6c22f463 | 2 doctests, 804 tests, 0 failures (31 "invalid" only because the archive is not a git repository and `CopyRulesContractTest` runs `git rev-parse`; the same file passes in the real checkout) | ✓ PASS |
| Root contract tests | workflow_wiring, dependency_boundary, ops_dependency_boundary, shipped_docs | 176 tests, 0 failures | ✓ PASS |
| D1 red on old code | D1 test against pre-fix `on_mount.ex` | fails with `"return_to" => "/"` | ✓ PASS |
| D3 red on old code | D3 test against pre-fix `sync_drift_live.ex` | fails with `KeyError :replacement_job` | ✓ PASS |
| Rendered-HTML parity | capture script on `d913b8b6` and HEAD, canonical compare | 0 differences over 54 common captures; planted change detected | ✓ PASS |
| Preflight and probe | `npm run --silent ui:preflight` (retained checkout); `catalog-fidelity-probe.mjs --font` x3 | ok true; same font family, light and dark | ✓ PASS |
| Node selftests | `ui:review:selftest`, `ui_preservation.test.cjs` | 35 of 35, 53 of 53 | ✓ PASS |

### Probe Execution

SKIPPED: no `scripts/*/tests/probe-*.sh` is declared by any plan or summary. The fidelity probe (a local, non-gating `.mjs`) was run above in font mode.

### Requirements Coverage

| Requirement | Source plan | Description | Status | Evidence |
|---|---|---|---|---|
| PILOT-01 | 01 | Journey first, green on current code, denials with controls, repaired stale-sudo test | ✓ SATISFIED | Truth 1 |
| PILOT-02 | 01 | D1 fix with own test, no root `lib/` | ✓ SATISFIED | Truth 2 |
| PILOT-03 | 02, 03, 04 | View-models, shared components, parity, journey unmodified | ✓ SATISFIED | Truths 3, 3a |
| PILOT-04 | 02, 03, 04, 05 | Tiers, JOB ids, adopter dimension, both themes, claim-limited descriptions | ✓ SATISFIED | Truth 5 |
| PILOT-05 | 03, 04 | One contract test, ledger row 11 of 12 | ✓ SATISFIED | Truth 4 |
| PILOT-06 | 01, 05 | Seeded storybook on 4003, block, landing page, preflight, AGENTS.md | ✓ SATISFIED on everything except the literal port: served on 4013 under a recorded deviation | Truth 6; REQUIREMENTS.md still lists it Pending, which is accurate until the maintainer decides |
| PILOT-07 | 05 | Pause 1, feedback verbatim, sizes Phase 198 | ? NEEDS HUMAN | The pause packet is delivered; the feedback is the maintainer's |
| FLOW-01 to FLOW-04 | 05 (standing) | Release hygiene, caps, protected files, findings handed off | ✓ SATISFIED | Truth 8 |
| FLOW-05 | none (mapped to Phase 198, also runs after 197 if 198 is cut) | Milestone-end review | Not this phase's | Pending by design |

No orphaned requirements: every ID that REQUIREMENTS.md maps to Phase 197 appears in a plan's `requirements`.

### Test Quality Audit

| Test file | Linked req | Active | Skipped | Circular | Assertion level | Verdict |
|---|---|---|---|---|---|---|
| `catalog_journey_test.exs` | PILOT-01 | 4 | 0 | no (literals, not generated from the code under test) | Behavioral (multi-step, counter, redirect, absence) | OK |
| `failed_sync_live_test.exs` (D1, stale sudo, seams) | PILOT-01/02/03 | all | 0 | no | Value and behavioral; planted differences | OK |
| `sync_drift_live_test.exs` (D3, seams) | PILOT-03 | all | 0 | no | Behavioral; red on old code proven | OK |
| `catalog_contract_test.exs` | PILOT-04/05/06 | 36 | 0 | no | Value, with one planted failure per check | OK |
| parity capture (throwaway) | PILOT-03 | n/a | n/a | no: expected side is the pre-extraction commit, an independent oracle | Canonical-tree equality | VALID provenance |

Disabled tests on requirements: 0. Circular patterns: 0. Insufficient assertions: 0. One caveat on strength: the seam tests prove the story and the page call the same function (consistency); equivalence to the old behavior is proven by the parity run, not by the seams. Both exist.

### Anti-Patterns Found

None. No `TBD`, `FIXME`, `XXX`, `TODO`, `HACK` or `PLACEHOLDER` in any non-planning file changed by the phase, and none in the Pause 1 note or the summaries. No stubs: the story data flows from the real normalizers.

### Decision Coverage

Decision coverage: skipped (the handler reports "no trackable decisions" for this CONTEXT's format). Checked by hand instead: journey first (yes), tiers and ledger row (yes), D3 and font fixes in the plans CONTEXT assigned (yes), findings not fixed (no root `lib/` change), no Hex release (yes), at most 5 plans (yes), about 40 variations (40), no state grids, baselines, LLM critic, parallel gallery or second journey (none exist), fixtures fold left to the maintainer with evidence (yes).

### Hosted CI evidence (read with `gh`, not from the summaries)

- PR #177 head `95d716ae`: `backend`, `core`, `ecommerce-mounted`, `package`, `repository-contracts` and `ops-ui (path-scoped)` all `success`; advisory `deep-quality` failed (the known advisory, not required); branch protection's required list is exactly those six contexts.
- PR #178 head `805a4674`: `backend`, `core`, `package`, `repository-contracts` success; `ops-ui` and `ecommerce-mounted` skipped and reported (path-scoped).
- Main: CI success on `33aac70f` and on `6c22f463`; Release Please success on both; no open PR.
- Out of scope, for the record: the earlier main run on `84afaba0` (Phase 196 closeout) had a red `core` from a hosted `git fetch` timeout in `UiLiteralContractTest`; main has been green since.

### Human Verification Required

#### 1. Pause 1 look and feedback (PILOT-07)

**Test:** Open http://127.0.0.1:4013/storybook/welcome and the nine links in `.planning/research/storybook-catalog/PAUSE-1-PHASE-197.md`; paste feedback verbatim into its empty table, or reply `ok`.
**Expected:** Rows (or `ok`) that size Phase 198 as cut, shrink or run (the note recommends cut).
**Why human:** Subjective, and the feedback is the maintainer's own words. This is the stop the roadmap defines, not a correctness check; no design is claimed approved.

#### 2. Port decision (PILOT-06)

**Test:** Decide between freeing 4003 (move back with the four steps in `UI-PREVIEW.json` `storybook.deviation.move_back`) and recording 4013 as the decision (edit ROADMAP criterion 5 and PILOT-06).
**Expected:** One of the two is done; `ui:preflight` stays green on whichever port the block names.
**Why human:** Only the maintainer can stop the other project's process or change the recorded decision.

#### 3. Fixtures fold (ADR 0002 exit rule)

**Test:** Read the evidence table in the Pause 1 note (one consumer, hosted cost within a few seconds of its same-day control in both phases, 14 files touched by a fold, 6 unused functions).
**Expected:** Keep (recommended) or fold.
**Why human:** A recorded owner decision point that CONTEXT reserved for the maintainer.

### Gaps Summary

No gaps. Every automatable truth holds on the code at `origin/main` 6c22f463, and the two defect fixes, the extraction parity and the journey-first ordering were each confirmed by an independent run or mutation, not by the summaries. The status is `human_needed` only because PILOT-07 cannot be satisfied by an agent and PILOT-06's literal port is a maintainer decision.

Other things the orchestrator should know (none blocks):

- **Advisory, incidental ordering (see `coincidental_reliance_items`):** the restart-stability proof is conditional. Cause: `failures.ex:247` uses `inspect/1` on an atom-keyed map; the key order can flip between boots. Effect: two spots of text in the Failed row error (the visible error block and its copy attribute) can print `task_uid` and `index_uid` in either order across restarts. No data, time or count differs. Hand-off, not fixed (Phase 196 code, outside this phase's brief).
- **Bookkeeping that phase completion will do, not me:** ROADMAP still shows 197-05 unchecked and "4/5 plans"; REQUIREMENTS.md still shows PILOT-06 and PILOT-07 Pending; STATE.md stops at 197-04. `197-VALIDATION.md` was never updated after execution (`status: draft`, all rows pending, sign-off unchecked, `nyquist_compliant: false`), though every row it lists now has an executable check.
- **Wording:** ROADMAP criterion 2 says "under a chore or test PR title that says plainly it fixes a defect". The PR title is `test(ops-ui): cover JOB-03 end to end ...`; the body (and the squash commit body) say plainly that it fixes D1 and D3, and the branch commit subjects said "fixes defect D1/D3". Treated as satisfied in substance (FLOW-01 requires the body).
- **Loopback endpoint note (info):** the catalog endpoint sets `check_origin: false` and a fixed dev `secret_key_base`; it is dev/test only, loopback only, serves fictional fixtures, and the boundary tests keep it out of prod builds. No action suggested.
- **Verification hygiene:** my scratch trees and captures are under the session scratchpad only; the one scratch catalog I started on port 4023 is stopped; port 4013 and the retained preview were not touched. I wrote two files into scratchpad directories named `parity/base` and `parity/head` before switching to fresh `verify-parity/` directories (throwaway evidence).

---

_Verified: 2026-11-22T17:37:00Z_
_Verifier: Claude (gsd-verifier)_
