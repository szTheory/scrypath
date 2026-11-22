---
phase: 196-fixtures-and-three-adopters
verified: 2026-11-22T05:55:00Z
status: passed
score: 19/19 must-haves verified
covered_files:
  - ".dockerignore"
  - ".formatter.exs"
  - ".planning/phases/196-fixtures-and-three-adopters/196-01-PLAN.md"
  - ".planning/phases/196-fixtures-and-three-adopters/196-01-SUMMARY.md"
  - ".planning/phases/196-fixtures-and-three-adopters/196-02-PLAN.md"
  - ".planning/phases/196-fixtures-and-three-adopters/196-02-SUMMARY.md"
  - ".planning/phases/196-fixtures-and-three-adopters/196-03-PLAN.md"
  - ".planning/phases/196-fixtures-and-three-adopters/196-03-SUMMARY.md"
  - ".planning/phases/196-fixtures-and-three-adopters/196-04-PLAN.md"
  - ".planning/phases/196-fixtures-and-three-adopters/196-04-SUMMARY.md"
  - ".planning/phases/196-fixtures-and-three-adopters/196-05-PLAN.md"
  - ".planning/phases/196-fixtures-and-three-adopters/196-05-SUMMARY.md"
  - "dev/mix/tasks/verify.namespace_fence.ex"
  - "examples/scrypath_ecommerce/Dockerfile"
  - "examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh"
  - "fixtures/scrypath_fixtures/.formatter.exs"
  - "fixtures/scrypath_fixtures/.gitignore"
  - "fixtures/scrypath_fixtures/README.md"
  - "fixtures/scrypath_fixtures/lib/mix/tasks/scrypath_fixtures.check_fixtures.ex"
  - "fixtures/scrypath_fixtures/lib/scrypath_fixtures.ex"
  - "fixtures/scrypath_fixtures/lib/scrypath_fixtures/applied_settings.ex"
  - "fixtures/scrypath_fixtures/lib/scrypath_fixtures/bulk.ex"
  - "fixtures/scrypath_fixtures/lib/scrypath_fixtures/check.ex"
  - "fixtures/scrypath_fixtures/lib/scrypath_fixtures/failures.ex"
  - "fixtures/scrypath_fixtures/lib/scrypath_fixtures/fake_meilisearch_client.ex"
  - "fixtures/scrypath_fixtures/lib/scrypath_fixtures/fake_oban_inspector.ex"
  - "fixtures/scrypath_fixtures/lib/scrypath_fixtures/hostile.ex"
  - "fixtures/scrypath_fixtures/lib/scrypath_fixtures/logistify.ex"
  - "fixtures/scrypath_fixtures/lib/scrypath_fixtures/logistify/shipment.ex"
  - "fixtures/scrypath_fixtures/lib/scrypath_fixtures/meili.ex"
  - "fixtures/scrypath_fixtures/lib/scrypath_fixtures/oban_job.ex"
  - "fixtures/scrypath_fixtures/lib/scrypath_fixtures/recordings.ex"
  - "fixtures/scrypath_fixtures/lib/scrypath_fixtures/scenario.ex"
  - "fixtures/scrypath_fixtures/lib/scrypath_fixtures/scenarios.ex"
  - "fixtures/scrypath_fixtures/lib/scrypath_fixtures/shopadelic.ex"
  - "fixtures/scrypath_fixtures/lib/scrypath_fixtures/shopadelic/product.ex"
  - "fixtures/scrypath_fixtures/lib/scrypath_fixtures/wikily.ex"
  - "fixtures/scrypath_fixtures/lib/scrypath_fixtures/wikily/page.ex"
  - "fixtures/scrypath_fixtures/mix.exs"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/01-version.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/02-enqueue-index-creation.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/03-task-index-creation.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/04-task-document-addition-succeeded.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/05-task-failed-invalid-document-id-space-slash.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/06-task-failed-invalid-document-id-512-bytes.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/07-task-document-addition-511-bytes-succeeded.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/08-task-failed-invalid-document-id-hostile.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/09-task-failed-missing-document-id-markup.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/10-task-failed-document-deletion-index-not-found.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/11-task-failed-primary-key-no-candidate.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/12-task-document-addition-processing.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/13-task-document-addition-enqueued.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/14-task-document-addition-canceled.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/15-task-document-deletion-succeeded.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/16-settings-default.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/17-task-settings-update.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/18-settings-filterable-status.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/19-settings-unknown-index-404.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/20-tasks-limit-invalid-400.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/21-search-filter-not-filterable-400.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/22-list-page1-limit3.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/23-list-page2-from-next.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/24-list-limit1000.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/25-list-unknown-index-empty.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/26-task-index-swap.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/27-list-swap-live.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/28-list-swap-partner.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/29-list-swap-unfiltered.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/30-list-after-swap-live-documents.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/31-list-after-swap-partner-documents.json"
  - "fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/PROVENANCE.md"
  - "fixtures/scrypath_fixtures/recordings/record.sh"
  - "scripts/ci/compat_path_classifier.test.cjs"
  - "scrypath_ops/mix.exs"
  - "scrypath_ops/test/scrypath_ops/fixtures_check_task_test.exs"
  - "scrypath_ops/test/scrypath_ops/fixtures_check_test.exs"
  - "scrypath_ops/test/scrypath_ops/fixtures_provenance_test.exs"
  - "scrypath_ops/test/scrypath_ops/fixtures_recordings_test.exs"
  - "scrypath_ops/test/scrypath_ops/fixtures_round_trip_test.exs"
  - "scrypath_ops/test/scrypath_ops_web/live/fixtures_determinism_test.exs"
  - "scrypath_ops/test/scrypath_ops_web/live/fixtures_hostile_render_test.exs"
  - "scrypath_ops/test/scrypath_ops_web/live/fixtures_tracer_test.exs"
  - "scrypath_ops/test/support/fixture_env.ex"
  - "test/mix/tasks/dependency_boundary_contract_test.exs"
  - "test/mix/tasks/fixtures_project_contract_test.exs"
  - "test/mix/tasks/verify_namespace_fence_test.exs"
  - "test/release/ops_dependency_boundary_test.exs"
  - "test/release/package_metadata_test.exs"
  - "test/support/release/shipped_docs.ex"
covered_digest: "v4:sha256:c7be17b0853186a149fde059c4351bae3bbdbc8ad0c3e3727c2df4731ef0262d"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 19/19
  reason: "Code-review fixes landed on gsd/phase-196-review-fixes (five commits after d69fbb82); criteria 2, 3 and 4 re-checked against the new code"
  gaps_closed: []
  gaps_remaining: []
  regressions: []
---

# Phase 196: Fixtures and three adopters - Verification Report

**Phase Goal:** Realistic, reachable-state-only fixture data exists for three Scrypath-owned fictional adopters, built so the real `Operator.Status`, `FailedWork` and `Posture` code does the normalizing.
**Verified:** 2026-11-22T05:55:00Z
**Status:** passed
**Re-verification:** Yes, after the code-review fixes (the first pass had no gaps; this pass re-checks criteria 2, 3 and 4 on the new code)
**Checkout:** branch `gsd/phase-196-review-fixes` at `053b718c`, five commits after `d69fbb82` (= origin/main, which holds PR #174 `7a18da12` and PR #175 `d69fbb82`). Pre-phase baseline `6fff5f00`. The five review-fix commits are local: the branch is not pushed and has no pull request or hosted run yet.

## What this verification established, in plain words

The phase goal is met, and still met after the code-review fixes. I read the real files rather than the summaries, ran the focused tests myself, and broke nineteen things on purpose across both passes (thirteen, then six more against the review-fix code; each restored byte-identical afterwards) to confirm the guards fail for their own cause. No human UAT item remains, and nothing is left for the maintainer to look at in this phase.

Three statements the caller asked to have on the record:

1. **Hosted timings are recorded evidence, not a gate.** `.planning/reference/CI-EFFICIENCY.md` finding 29 records the cold, warm and same-day-control `ops-ui` samples (warm minus control about -3 s in the job and +1 s in the step, against an advisory 60 s threshold that is not an ADR trigger). Nothing in this verdict depends on those numbers.
2. **Findings F3 and F4 are handed to the maintainer and not fixed.** `git diff 6fff5f00..HEAD -- lib/` is empty. I re-checked both claims against root source: `Scrypath.Meilisearch.Tasks` always passes `index_uids: [index_uid]` (`lib/scrypath/meilisearch/tasks.ex:41`), and `Scrypath.Meilisearch.Settings` merges the declared `filterable:` list and never `sortable:` (`lib/scrypath/meilisearch/settings.ex:33-53`). Both are accurately described in `196-FINDINGS.md`. F1, F2, D2 and the `dashboard_routes` guard defect are untouched and still open as recorded in Phase 195.
3. **The `ecommerce-mounted` Docker lane did not complete locally (four attempts), but passed hosted on the exact head.** Confirmed: run 44983386664, head `9a164bc3c3998529033e603d81b3153ede387757` (PR #174's head; the later review-fix commits have no hosted run yet), `ecommerce-mounted (required)` success in 16m3s, with every other required lane (`core`, `repository-contracts`, `package`, `backend`, `ops-ui`) green. The advisory `deep-quality` lane is red (the known optional sigra to cloak advisory) and does not gate.

## Re-verification after the code-review fixes

Five commits on `gsd/phase-196-review-fixes` followed the merged phase: `ff68e4c0` (`record.sh` safety), `bdb27063` (purity token list and format code points), `3d553d1d` (task uid invariants, Shopadelic timeline, no-`indexUid` fallback), `ee3dc87c` (Oban job shape and coherence invariants), `053b718c` (path-guard plants). They touch eight files: `check.ex`, `shopadelic.ex`, the fixtures README, `PROVENANCE.md`, `record.sh` and three test files. I re-checked roadmap criteria 2, 3 and 4 against that code and read `196-REVIEW-DISPOSITION.md`. **Result: nothing regressed, no gap opened, status stays `passed`.**

Plainly: the five commits are local. There is no pull request and no hosted run for them, so the hosted evidence in this report (run 44983386664, head `9a164bc3`) covers the merged phase and not these fixes. The evidence for the fixes is the local runs below.

| Re-check | How | Result |
|----------|-----|--------|
| Criterion 4: `check_fixtures` still DB-free and first in the alias | `MIX_ENV=test PGPORT=1 mix scrypath_fixtures.check_fixtures`, and `fixtures_check_task_test.exs` (child `mix`, nothing listening) | Exit 0, `Fixtures OK: 11 scenario(s)`. The test alias output still prints `Fixtures OK` before `Nav contract OK`. `scrypath_ops/mix.exs` is unchanged since the phase (still the same 3-line diff against `6fff5f00`). |
| Criterion 4: every invariant still has a cause-pinned plant | `Check.invariants/0` now returns 31 tags (was 26); `fixtures_check_test.exs` "every invariant has at least one plant" passes. Mutation R6 (a 32nd tag with no plant) fails that test. | Held. The five new invariants (`task_uid_unique`, `task_uid_order`, `job_shape`, `job_state_coherence` with six named rules, `job_time_order`) each have plants. |
| Criterion 4: relative time and purity | Determinism test (3 tests) passes. Purity list widened from 8 to 33 tokens (`Check.impure_tokens/0`); raw-format code points widened to 167 (`Check.format_codepoints/0`). Mutation R1 (`Process.sleep`, a token that was not forbidden before) fails with `{:source, {:impure_source, ..., "Process.sleep"}}`. Mutation R2 (a raw U+061C, a code point that was not forbidden before) fails with `{:raw_format_char, ..., 1564}`. Mutation R5 (stamp pinned to a calendar date) still fails with `time_not_relative`. | Held, and stricter. No wall-clock, random or other impure token appears in `lib/` (the check itself passes on the real tree). |
| Criterion 4: tarball and boundary | `package_metadata_test`, `fixtures_project_contract_test`, `dependency_boundary_contract_test`: 80 tests, 0 failures. `git diff 6fff5f00..HEAD` is empty for root `lib/`, every `mix.lock`, `.github/`, the phase173 files and `posture_live.ex`. | Held. |
| Criterion 3: scenarios named, ordinary and stress separate | The registry still holds 11 scenarios. The only scenario code change is Shopadelic's history spacing (`43_200 - n * 900`, deletes at `6_500 - n * 10`), so uids are in enqueue order. Mutation R3 (the old spacing restored) now fails with `{:task_uid_order, 43}` for `shopadelic_failed_journey` and `shopadelic_hostile_ids`: the new invariant catches exactly the defect the fix removed. The round-trip tests (including the F1 truncation shape and the Shopadelic drift report) still pass; stress variations are still the same two. Mutation R4 (an executing job with attempt 0) fails with `{:job_state_coherence, 193, :attempt_required}`. | Held. |
| Criterion 2: recordings pure ASCII and committed files unchanged | `grep -P '[^\x00-\x7F]'` over `fixtures/` finds nothing. `git diff --stat d69fbb82..HEAD` over the 31 recording JSON files is empty; only `PROVENANCE.md` (one description line) and `record.sh` changed. | Held. |
| Criterion 2: `record.sh` safety | `bash -n` passes. I ran it three ways without Docker: against an arbitrary directory holding a `.json` file, against `.` from inside the recordings directory, and against a non-`meilisearch-v*` sibling directory. Each refused with exit 2 before any Docker call, the planted `keep.json` survived, and no `scrypath-p196-recording` container exists. I did not run a real re-record (it needs a 60,000-document Docker load and is not needed to verify the guards). | Held; WR-09 is fixed as the disposition says. |
| Criterion 2: failure table and hostile escapes | Unchanged table; `fixtures_recordings_test.exs` and `fixtures_provenance_test.exs` pass (the provenance test grew from the new code points and tokens). | Held. |
| Format and fence | `mix format --check-formatted` (root and ops), `mix verify.namespace_fence` | Clean. |

**Dispositions read.** `196-REVIEW-DISPOSITION.md` records 0 critical and 9 warning and 5 info findings: WR-01 to WR-06 and WR-09 fixed (verified above), WR-07 and WR-08 handed off, IN-02 accepted, IN-01 and IN-03 to IN-05 handed off. I treat WR-07, WR-08 and the info items as recorded handoffs, not fixes, as instructed.

The one that deserves a plain sentence is **WR-07**: the prod image of the ecommerce host still contains the `fixtures/scrypath_fixtures` source tree (inert files; the verify script proves the project is not compiled, not in the dependency list and its module is not loadable in prod). WR-08 is a related unnecessary `COPY` of the fixtures manifest in the prod stage, pinned by a contract test. Both are handed to the maintainer with a trigger to act (the prod image is ever published, or a fixtures file starts to hold anything sensitive), to be changed together under one Docker-lane run. This does not fail the phase: the roadmap contract is that `fixtures/` never ships in the Hex tarball (verified and mutation-tested), and the project is not part of the production dependency graph or runtime. But the README sentence "never ships in the Hex package or in a release" reads a little wider than the evidence for the prod image, so a reader should take it as "not compiled into, not loadable from"; that is stated here rather than hidden.

## Goal Achievement

### Observable Truths

| # | Truth (source) | Status | Evidence |
|---|----------------|--------|----------|
| 1 | Logistify tracer passes first: builder takes `now`, emits raw task and job maps, a test drives them through the fake client to a rendered `/ops/health` with a deep queue and nothing failed (SC1) | VERIFIED | PR #174's first code commit `bb2754a7` contains only the project, the Logistify builder, the fake client, FixtureEnv and the tracer test (no Shopadelic or Wikily file). `fixtures_tracer_test.exs` renders `/ops/health` and asserts `.ops-verdict[data-verdict-kind='neutral'] [data-sync-status='pending']`, no `[data-sync-status='failed']`, and the "No sync failures found" headline. Passes in my run (160 tests, 0 failures across the eight fixtures files after the review fixes; 148 at the first pass). |
| 2 | Exit rule and "second consumer" definition recorded in `fixtures/scrypath_fixtures/README.md` (SC1) | VERIFIED | README "Exit rule": fold into `scrypath_ops/catalog/` if no second consumer by Phase 197; a second consumer is "a Mix project other than `scrypath_ops` that lists `scrypath_fixtures` in its deps"; evaluated at the start of Phase 197 planning. Pinned by `test/mix/tasks/fixtures_project_contract_test.exs` (README rows with planted failures). |
| 3 | Real Meilisearch payloads recorded once from a task-scoped Docker run, with PROVENANCE.md, container removed (SC2) | VERIFIED | 31 raw JSON bodies under `recordings/meilisearch-v1.15/` plus `PROVENANCE.md` (image tag and id, repo digest, `GET /version` body `pkgVersion":"1.15.2"` matching `01-version.json`, date, the `record.sh` script, per-file request table). Bodies are real server output (`batchUid`, `duration":"PT0.000461666S"`, `indexUid":null` on the swap). All files pure ASCII (hostile text is escaped). `docker ps -a` shows no `scrypath-p196-recording` container and no `label=scrypath.task=p196-recording` container, volume or network. The pinned image `getmeili/meilisearch:v1.15` is still local because the demo stack's running Meilisearch container uses it (see Findings below). |
| 4 | Every fixture failure string comes from a closed table whose entries each carry a resolving `source:` (SC2) | VERIFIED | `Failures` has seven entries, each with `source:` (four recording basenames, three repo paths). I confirmed the three repo-path sources are real (`client.ex:191` `{:transport_error, ...}`, `tasks.ex:146` `{:task_failed, ...}`, `upsert_worker.ex:32` `{:cancel, {:invalid_job, tag}}` with `:unknown_schema` from `job_args.ex:97`). Builders reject inline error text at the function head. Mutation M11 (source repointed to a made-up recording) fails `check_fixtures` with `{:failures, {:failure_source_missing, :invalid_document_id}}`; M12 (template text drifted from the recorded message) fails `fixtures_recordings_test`. |
| 5 | Hostile text stored as escapes, lint fails on a raw format character (SC2) | VERIFIED | `Hostile` holds twelve strings, every non-ASCII character a `\u{...}` escape (the raw-format lint now forbids 167 code points, widened from the first pass); `grep -P '[^\x00-\x7F]'` over `lib/`, `README.md` and `record.sh` returns nothing. Hostile text is used only in `shopadelic.ex` (15 uses), only in the `hostile_ids` stress variation, and only where the system can carry it (invalid ids inside the echoing `invalid_document_id` failures, the 511-byte id and 200-char token only as job `document_ids`, markup only inside an echoed document). Mutation M2 (a raw U+200B typed into `logistify.ex`) fails the check with `{:source, {:raw_format_char, "lib/scrypath_fixtures/logistify.ex", 8203}}`. The render test shows markup as text and no script element. |
| 6 | No failure the library cannot produce (cross-checked against prep note B section D4) (SC2) | VERIFIED | `Failures.cannot_produce/0` lists the eight D4 exclusions (payload_too_large, system storage errors, per-tenant drift, minutes of lag, per-document size limit, out-of-order overwrite, price as string) with reasons; the check rejects a table entry on that list (`forbidden_failure`, plant tested). Grep over scenario code finds none of those strings outside the exclusion list. The "drift in one store" and "N minutes of lag" stories from the sibling handoff were reworded as whole-index `filterableAttributes` drift and queue depth only. |
| 7 | Shopadelic named states: settings drift, aligned, failed journey (SC3) | VERIFIED | `settings_aligned`, `settings_drift`, `failed_journey` (plus stress `hostile_ids`). `fixtures_round_trip_test.exs` asserts the real `Scrypath.index_contract_drift/2` reports `match: true` in all five dimensions for aligned and `only_declared: "storeId"` for drift, and that the failed journey yields the five failed-work rows through the real `failed_sync_work/2`. |
| 8 | Logistify named states: deep queue, steady, and a separately labelled F1 stress variation (SC3) | VERIFIED | `deep_queue` (647 tasks, 195 jobs, nothing failed), `steady`, and `history_over_limit` with kind `:stress` and label "Logistify shipments, stress: task history over 1,000 reproduces finding F1 (fictional)". The round-trip test asserts the real shape `{:error, {:task_history_truncated, %{index_uid: "logistify_shipment", limit: 1000, observed: 1000, next: _}}}` field by field and the posture "Search health could not be fully checked". |
| 9 | Wikily named states: unconfigured, missing backend, index not created, first delete failed (SC3) | VERIFIED | Four ordinary states; posture headlines "Not configured", "Broken", clear with drift `{:error, :index_not_found}`, and "1 Meilisearch task failed", each asserted through the real `Posture.summary/4` round trip. |
| 10 | Ordinary data separate from stress variations; nothing copied from the six sibling brand repos (SC3) | VERIFIED | `Scenario.kind` is `:ordinary` or `:stress`; the check rejects a stress scenario whose label lacks "stress" (`stress_unmarked`) and any scenario without "(fictional)" (`unlabelled`); registry orders each adopter's ordinary states before its stress variation. Sibling cross-check by me: none of the 336 code-quoted tokens in the sibling handoff (`abracabrand/.planning/spikes/025-scrypath-brand-book/HANDOFF-DEMO-ADOPTERS-FOR-SCRYPATH.md`) appears in the fixtures other than the adopter names and the `LGX-0417-DE` sentinel in the denylist and its planted test; `AH 2026/7B`, `LGX-0417-DE`, "Maison", "Lavande", "Keller", "Berlin" and the canon carrier names are absent from fixture data; `fablebook` contains none of the fixture ids or carrier names. Mutation M3 (sentinel in a label) fails with `denylisted_word`; M5 (a compliance word) fails likewise. |
| 11 | `check_fixtures` is DB-free, first in the `test` alias, with a planted failing case for every invariant (SC4) | VERIFIED | `MIX_ENV=test PGPORT=1 mix scrypath_fixtures.check_fixtures` prints `Fixtures OK: 11 scenario(s)` with no database. `scrypath_ops/mix.exs` test alias begins with `"scrypath_fixtures.check_fixtures"`, then `scrypath_ops.check_nav_contract`, then `ecto.create`; `fixtures_check_task_test.exs` proves the order through a real child `mix` with nothing listening. `Check.invariants/0` lists 31 tags after the review fixes (26 at the first pass, plus `task_uid_unique`, `task_uid_order`, `job_shape`, `job_state_coherence`, `job_time_order`); `fixtures_check_test.exs` asserts the planted-tag set equals the invariant set. Mutation M7 (a 27th tag with no plant) fails that test; M8 (alias order swapped) fails the root contract test. |
| 12 | Two renders with different `now` differ only in time-derived text (SC4) | VERIFIED | `fixtures_determinism_test.exs` (3 tests): after normalizing per-render ids, the deep-queue `/ops/health` render three days apart is identical except absolute times, relative ages are equal, and a plant that pins task times differs in relative-age text and nothing else. The data-level `time_not_relative` invariant covers all 11 builders; mutation M6 (stamp pinned to a calendar date) fails the check with 38 `time_not_relative` problems naming the paths. No wall-clock read exists in `lib/` (M1: an injected `DateTime.utc_now` fails `{:source, {:impure_source, ...}}`; the lint now lists 33 tokens, see the re-verification section). |
| 13 | `package_metadata_test` asserts `fixtures/` never ships in the Hex tarball (SC4) | VERIFIED | New non-vacuous tests: the tree exists, and no `files:` entry reaches it; the reaching-entry helper is itself tested with six planted entries and near misses. Mutation M10 (`fixtures` added to `files:`) fails 3 tests in `package_metadata_test.exs`. Root dependency-boundary row requires the path dependency to be `only: [:dev, :test]` with path `../fixtures/scrypath_fixtures`; mutation M9 (drop `only:`) fails it. |
| 14 | CI path classifier and `package_contents_test` decisions recorded (SC4) | VERIFIED | README "Boundary decisions" records each. `scripts/ci/compat_path_classifier.test.cjs` lists `fixtures` as irrelevant with its reason; `ci.yml` already had `fixtures/` in `ops-ui-path` and is unchanged (`git diff --stat -- .github` empty); `test/release/package_contents_test.exs` is unchanged because `allowed_top_level` derives from `files:`. The Dockerfile (three early `COPY` lines), `.dockerignore` (keeps sources, ignores `_build` and `deps`), and the Docker verify script (forbids `scrypath_fixtures` in the prod image and host, forbids the `ScrypathFixtures` module in the runtime probe) were each edited and are statically pinned. |
| 15 | Host `phase173` fixtures and `?scenario=` branches remain, with a recorded deletion trigger (SC4) | VERIFIED | `git diff 6fff5f00..HEAD --` on all ten `phase173` paths and on `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex` is empty; `:phase173_fixture` branches still present (`posture_live.ex:16`). README "Phase 173 deletion trigger" names the four host specs, which I confirmed all use `scenario=` (`ops_reskin_contract`, `ui_baseline`, `ui_followup`, `ui_iteration3`), and the receipt-update obligation (`PRESERVATION_FIXTURE_FILES` in `scripts/ci/ecommerce_evidence.cjs` lists the host copy). |
| 16 | Builders are pure and closed; one `scrypath_ops/mix.exs` edit; lock files unchanged; FixtureEnv restores (Plan 01) | VERIFIED | Purity grep over `fixtures/scrypath_fixtures/lib` (excluding the check's own token list) finds no `utc_now`, `utc_today`, `:rand.`, `System.`, `:os.` or `Repo.`; the one `~U[...]` literal is `preview_epoch/0`. Closed enums raise `FunctionClauseError` (tested). `scrypath_ops/mix.exs` diff is exactly three lines (dep, `preferred_envs`, alias) and only the squash commit touches it. `git diff 6fff5f00..HEAD --stat -- '*mix.lock'` is empty. Mutation M13 (FixtureEnv stops deleting absent keys on restore) fails the restore test. |
| 17 | Bulk generator is deterministic with a golden digest; denylist and provenance lints (Plan 03/05) | VERIFIED | `Bulk` is a `:erlang.phash2` pick, capped at 5,000, no Faker or StreamData; the check compares a SHA-256 of the fixed sample with `@golden_digest` (`bulk_digest`); every adopter module carries the "Fictional adopter: Scrypath-owned data, no records copied" line (`provenance_missing`). All plants pass in `fixtures_provenance_test.exs` and `fixtures_check_test.exs`. |
| 18 | FLOW-01 to FLOW-04: no root `lib/` change, PR titles chore or test or docs, no protected file, no release PR, findings handed over, plan cap (standing) | VERIFIED | See "Standing rules" below. |
| 19 | Required checks green on the exact head and the CI cost recorded (Plan 05) | VERIFIED | PR #174 run 44983386664 on head `9a164bc3` all required lanes green; PR #175 green; `CI-EFFICIENCY.md` finding 29 holds cold, warm, control, delta and the main cold sample. Recorded evidence, not a gate. |

**Score:** 19/19 truths verified (0 present but behavior-unverified, 0 overrides).

Behavior-dependent truths (state transitions, cleanup, ordering) were each tied to a passing test and, where cheap, a mutation: FixtureEnv restore (M13), alias-first ordering (child-mix test, M8), relative time (determinism test, M6), the F1 truncation shape (round-trip test). None was accepted on symbol presence alone.

### Deferred Items

None. Phase 197 and 198 do not have to pick up any gap from this phase. F3 and F4 are findings for the maintainer, not gaps.

### Advisory (New Scope, Unevidenced)

Not applicable: this is an initial verification, not a re-verification. None.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `fixtures/scrypath_fixtures/mix.exs` | ADR 0002 project, deps exactly `[{:scrypath, path: "../.."}]`, no lock, no test dir | VERIFIED | Read; shape pinned by `fixtures_project_contract_test.exs`. |
| `fixtures/scrypath_fixtures/lib/scrypath_fixtures/{logistify,shopadelic,wikily}.ex` | Three adopters | VERIFIED | 253, 425 and 120 lines of real builders, each with the provenance line. |
| `.../meili.ex`, `oban_job.ex`, `scenario.ex`, `scenarios.ex` | Closed raw-shape builders, registry | VERIFIED | Registry of 11 ids; closed enums tested. |
| `.../fake_meilisearch_client.ex`, `fake_oban_inspector.ex`, `applied_settings.ex` | Fake client honouring limit, order, `next`; per-URL applied settings | VERIFIED | Conformance-tested against the recorded pages (`fixtures_recordings_test.exs`). |
| `.../failures.ex` | Closed table with `source:` | VERIFIED | Seven entries plus `cannot_produce/0`. |
| `.../recordings.ex`, `recordings/meilisearch-v1.15/*` | Compile-time loader and 31 raw bodies with PROVENANCE.md | VERIFIED | Every file listed in PROVENANCE.md (tested). |
| `.../check.ex`, `lib/mix/tasks/scrypath_fixtures.check_fixtures.ex` | DB-free check, 26 invariants | VERIFIED | 753 lines; task is a thin shell. |
| `.../hostile.ex`, `bulk.ex` | Escapes only; golden digest | VERIFIED | Read in full. |
| `fixtures/scrypath_fixtures/README.md` | Exit rule, deletion trigger, boundary decisions | VERIFIED | Read in full. |
| `scrypath_ops/test/support/fixture_env.ex` | Put and restore | VERIFIED | Read; mutation-tested. |
| Eight `fixtures_*_test.exs` files in `scrypath_ops/test` | Tracer, check plants, round trip, recordings, determinism, hostile render, provenance, check task | VERIFIED | 160 tests, 0 failures, run by me on `053b718c`. |
| Root `fixtures_project_contract_test.exs`, `dependency_boundary_contract_test.exs`, `package_metadata_test.exs` | Boundary pins with plants | VERIFIED | 80 tests, 0 failures (the first two) plus the package file run during mutations, run by me. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `scrypath_ops/mix.exs` | `fixtures/scrypath_fixtures/mix.exs` | `{:scrypath_fixtures, path: "../fixtures/scrypath_fixtures", only: [:dev, :test]}` | WIRED | Present at `mix.exs` line 53; M9 shows the boundary row catches loosening. |
| `scrypath_ops/mix.exs` | check task | first element of the `test` alias and a `preferred_envs` entry | WIRED | Proven by child mix test; M8. |
| `FixtureEnv` | `ScrypathOps.Schemas.scrypath_opts/0` | twelve forwarded keys plus `:schema_allowlist`, `:test_clock_file` | WIRED | Round trip and tracer tests read through `Schemas`. |
| `Check` | `Scrypath.Meilisearch.TaskPayload.normalize/2`, `Scrypath.sync_status/2`, `failed_sync_work/2`, `index_contract_drift/2` | wire guard and round-trip invariants | WIRED | `check.ex` lines 560-566 and 723-739. |
| `Check` | `Failures`, `Recordings`, `Scenarios`, `Bulk` | failure-closure, shape, registry and digest invariants | WIRED | Each has a mutation or plant that fails for its own tag. |
| `Meili` builders | `Failures` | a failed task's error is rendered from a table entry | WIRED | Function head rejects inline error maps (tested). |
| Test for posture | `ScrypathOps.Posture.summary/4` with nil previous summary | the call `PostureLive` makes on first render | WIRED | `fixtures_round_trip_test.exs`, one test per registered id. |
| `test/release/ops_dependency_boundary_test.exs` | `fixtures/` | archive list includes `fixtures` so direct dev and test builds resolve the path dependency | WIRED | Plan 02 ran the integration case green on `9dce3914`; hosted `repository-contracts` green on the final head. I did not re-run this 3 minute Docker-free build probe locally. |

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|----------|---------------|--------|--------------------|--------|
| `/ops/health` render | posture summary and sync status | scenario task and job maps, through `FakeMeilisearchClient`/`FakeObanInspector`, then the real `Scrypath.sync_status/2`, `failed_sync_work/2` and `Posture.summary/4` | Yes. Fixture data is the only input; the normalized `State`/`FailedWork` values are produced by library code, never constructed by a builder (checked: builders emit only string-keyed task maps and `ObanJob` maps). | FLOWING |
| Failed sync page for `hostile_ids` | failed rows | echoed task errors and job errors | Yes: 13 failed rows rendered, markup as literal text. | FLOWING |

### Behavioral Spot-Checks and Mutations I ran

Commands run from `/Users/jon/projects/scrypath/scrypath_ops` with `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5`. Every mutation was applied to a copy-backed file and restored byte-identical (`git status` afterwards shows only the three pre-existing modified config files, and the fingerprint digest is unchanged).

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Check passes DB-free | `MIX_ENV=test PGPORT=1 mix scrypath_fixtures.check_fixtures` | `Fixtures OK: 11 scenario(s)` | PASS |
| Eight fixtures test files | `mix test` over the eight `fixtures_*_test.exs` paths (through the real `test` alias, so the check ran first) | 160 tests, 0 failures on the review-fixes head (148 on the first pass). Local Postgres printed `too_many_connections` noise from other projects on this machine; no test failed. | PASS |
| Root contract tests | `mix test test/mix/tasks/fixtures_project_contract_test.exs test/release/package_metadata_test.exs test/mix/tasks/dependency_boundary_contract_test.exs` | 80 tests, 0 failures | PASS |
| Alias order | `mix test test/scrypath_ops/fixtures_check_task_test.exs` output | `Fixtures OK` printed before `Nav contract OK` | PASS |
| Format and namespace fence | `mix format --check-formatted` (root and ops), `mix verify.namespace_fence` | clean, "Namespace fence passed" | PASS |
| M1 wall-clock call in a builder | inject `DateTime.utc_now()` into `logistify.ex` | check fails `{:source, {:impure_source, ..., "DateTime.utc_now"}}` | PASS (guard fails for its cause) |
| M2 raw ZWSP in a fixture source | type U+200B into a comment | `{:source, {:raw_format_char, ..., 8203}}` | PASS |
| M3 sibling sentinel in a label | `LGX-0417-DE` in a label | `{:denylisted_word, {:label, ...}, "LGX-0417-DE"}` | PASS |
| M4 label without "(fictional)" | drop the marker | `{:unlabelled, :logistify_steady}` | PASS |
| M5 compliance words in a label | "GDPR compliant" | two `denylisted_word` problems | PASS |
| M6 stamp pinned to a date | `Meili.stamp/2` ignores `now` | exit 1, 38 `time_not_relative` problems with paths | PASS |
| M7 invariant with no plant | add `:zz_unplanted` to `@invariants` | `fixtures_check_test` "every invariant has at least one plant" fails | PASS |
| M8 alias order swapped | check after nav contract | root contract test fails | PASS |
| M9 path dependency loses `only:` | remove option | boundary contract test fails | PASS |
| M10 `fixtures` added to Hex `files:` | edit the `~w(...)` list | 3 `package_metadata_test` failures | PASS |
| M11 failure `source:` unresolved | point at a made-up recording | `{:failures, {:failure_source_missing, :invalid_document_id}}`, exit 1 | PASS |
| M12 failure template drifts from recorded message | reword the 511-byte clause | `fixtures_recordings_test` fails | PASS |
| M13 FixtureEnv stops deleting absent keys | edit restore | tracer test "restores every key it touched" fails | PASS |

### Probe Execution

Not applicable. The phase declares no `probe-*.sh` scripts; its executable evidence is the ExUnit suite, the Mix check task and the root contract tests above. Step 7c skipped for that reason.

### Requirements Coverage

| Requirement | Source plan(s) | Description | Status | Evidence |
|-------------|----------------|-------------|--------|----------|
| FIX-01 | 196-01, 196-02, 196-04 | `fixtures/scrypath_fixtures` project of pure builders emitting raw task and job maps; tracer first; recorded exit rule | SATISFIED | Truths 1, 2, 16; ADR 0002 shape pinned; tracer commit first. |
| FIX-02 | 196-03, 196-05 | Recorded payloads, closed failure table with `source:`, hostile text as escapes, no impossible failures | SATISFIED | Truths 3 to 6. |
| FIX-03 | 196-04, 196-05 | Three adopters with named states; ordinary before stress; nothing copied from siblings | SATISFIED | Truths 7 to 10. |
| FIX-04 | 196-01 to 196-05 | DB-free `check_fixtures` first in alias with plants; relative-time renders; tarball refute; classifier and package decisions; phase173 stays with trigger | SATISFIED | Truths 11 to 15. |
| FLOW-01 | 196-01, 196-02, 196-05 | No release or release PR; titles docs, chore, test or ci | SATISFIED | PR #174 `test(ops-ui): add the scrypath_fixtures project with three fictional adopters`; PR #175 `docs(phase-196): record the fixtures CI cost`; `gh pr list --state open` is empty; newest tag and release are `scrypath-v0.3.20` (2026-11-21, before this phase). |
| FLOW-02 | 196-01, 196-04, 196-05 | At most 5 plans; ask-first items stay ask-first | SATISFIED | Exactly five plans; no root `lib/` change; no new required CI context (`.github/` diff empty); no runtime dependency (fixtures depend only on `scrypath`; `mix.lock` files unchanged); nothing copied from sibling repos. |
| FLOW-03 | 196-01, 196-02, 196-03, 196-05 | Protected files never staged; paths named; local mirror before push with recorded skips | SATISFIED | `git log 6fff5f00..HEAD -- .planning/config.json .planning/state.json .impeccable/config.json` is empty and neither PR's file list contains them. `196-05-SUMMARY.md` records each lane's local result or skip reason; the `ecommerce-mounted` skip (four attempts, Docker VM contention, Hex timeout) is recorded and the lane passed hosted on the exact head. |
| FLOW-04 | 196-02, 196-03, 196-04, 196-05 | F1, F2, D2 and hygiene items handed over, not fixed | SATISFIED | `196-FINDINGS.md` adds F3 and F4, points at the still-open F1, F2, D2 and `dashboard_routes` items; root `lib/` untouched. |

No orphaned requirements: REQUIREMENTS.md maps only FIX-01 to FIX-04 to Phase 196 (FLOW-05 belongs to Phase 198), and every ID appears in at least one plan's `requirements:` frontmatter.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (all phase-modified files) | n/a | `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, `PLACEHOLDER` | none found | None. |
| Phase-modified source | n/a | stubs, empty implementations, hardcoded-empty data | none found | Empty lists in `wikily.ex` (`allowlist: []`, `meilisearch_tasks: []`) are the designed "not configured" and "index not created" states, asserted by name. |

### Observations (not gaps, nothing blocks)

1. **The leftover local Docker image seen at the first pass is gone.** `scrypath_dependency_boundary_20261122t034740z-1018-2653712826:runtime-test` (2.32 GB, labelled with the PR #174 head) no longer exists, and no `scrypath-p196-recording` container or label match exists either. Nothing to clean up.
2. **The sibling-canon guard is a sample, not a full scan (INFO).** The check's denylist holds one sibling sentinel (`LGX-0417-DE`) plus the compliance words; `AH 2026/7B` and other canon values are not machine-checked. "Nothing copied" is therefore supported by the provenance lines, the sentinel check, and my own cross-check of the handoff tokens against the fixtures (clean), rather than by an exhaustive automated comparison. This matches the plan's design (prep note D7), so it is recorded, not a defect.
3. **The pinned Meilisearch image stays local (INFO).** CONTEXT said the recording image would be removed afterwards; it cannot be, because `getmeili/meilisearch:v1.15` is the demo stack's own pinned image and `scrypath_ecommerce-meilisearch-1` is running from it. The roadmap criterion (container removed) holds.
4. **Render-level determinism covers one scenario and one page (INFO).** The two-clock render test is the Logistify deep queue on `/ops/health`; the data-level `time_not_relative` invariant covers all 11 builders at the wire level (M6). Phase 197's stories add more rendered pages and should extend the render-level check where a story shows time.
5. **A coherence nit in `failed_journey` (INFO).** The discarded delete job embeds `index_not_found` tasks for `shopadelic_product`, an index whose creation and settings appear in the same scenario's history. That is reachable (an index deleted and recreated around the delete) and it is the one deletion-failure entry in the recorded table, but the check does not model index existence across records. It does not violate the realism rules.
6. **Review-fix commits are unpushed.** The five commits on `gsd/phase-196-review-fixes` need a pull request (title `test(ops-ui)` or `chore(ops-ui)`, never `feat` or `fix`) and a green hosted run on their exact head before they count as landed. Their local mirror here covered the focused fixtures tests, the three root contract tests, format and the namespace fence; I did not run the full `core`, `repository-contracts` or Docker lanes.
7. **WR-07 and WR-08 are open handoffs** (prod image source copy and the matching manifest `COPY`), described above.
8. **Bookkeeping to update after this verdict.** `.planning/ROADMAP.md` still shows the Phase 196 summary line unchecked and the progress row "5/5, In Progress, -". The orchestrator's phase-complete step owns that update.

### Human Verification Required

None. The AGENTS.md rule is zero human UAT: every success criterion is an executable check or a recorded decision, and each was run or read above. The plan-level `<human-check>` scan found no deferred human items. Subjective review of how the fixtures read on screen belongs to Phase 197's catalog work, not to this phase's goal.

### Gaps Summary

No gaps. All four roadmap success criteria and every plan-level truth are backed by files that exist, are substantive and are wired, and by tests I ran. The guards the phase relies on (purity lint, raw-format lint, denylist, failure closure, source resolution, plant-per-invariant, alias order, boundary row, tarball refute, FixtureEnv restore, relative time) each failed for their own cause when I broke them.

---

_Verified: 2026-11-22T05:10:00Z_
_Verifier: Claude (gsd-verifier)_
