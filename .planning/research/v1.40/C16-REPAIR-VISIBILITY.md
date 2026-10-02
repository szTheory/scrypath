# C-16: bounded repair through visible search

**Project:** Scrypath — candidate v1.40 evidence/readiness milestone  
**Researched:** 2026-09-26  
**Source checkout:** `6e61380555361b6bb03c07a7f0f7c2a944ef960d`  
**Mode:** comparison and feasibility; research only  
**Confidence:** MEDIUM, conservatively following `classify-confidence --provider websearch --verified`; direct source observations are distinguished from recommended acceptance criteria. No new test or service run was performed.

## Recommendation

Add one deterministic, real-Meilisearch recovery scenario to the existing root `test/scrypath/live_operator_verification_test.exs`, using its existing Ecto/SQLite integration repository. Exercise **known missing document → read-only reconcile → explicitly ID-scoped manual backfill → exact returned task success → the original search returns the repaired ID and projection**. Reuse the existing `backend (required)` job, service, and curated suite inclusion. Pair this with existing fast task/error/recovery contracts. No new lane, matrix, runtime API, dependency, operator UI, or browser harness is needed.

This is the least costly credible proof of the assigned representative C-16 outcome. It does **not** establish that every retry, queue, or reindex recovery works. If requirements instead promise **replay of a selected failed Oban job**, choose the existing Phoenix/Postgres service consumer and its package variant; that stronger claim has a different boundary and cost. Do not describe a backfill receipt as an Oban retry receipt.

The owner-approved evidence/readiness milestone supplies the new decision relevance. No production incident, external adopter failure, or runtime defect is inferred. The [v1.39 findings](../../milestones/v1.39-phases/163-findings-and-bounded-follow-up/163-FINDINGS.md) and dated [NOT READY assessment](../../reference/PRE-OPERATOR-UI-READINESS.md) remain historical facts. A later C-16 receipt supports a newly dated assessment of condition 3; it cannot independently pass the whole six-condition gate.

## Operator and feature-owner job

The operator knows that a particular source record should be searchable, observes its absence, verifies which live index is in use, chooses the smallest repair that fits the known problem, and repeats the affected query. The feature owner needs confidence that repairing that record does not silently rebuild unrelated records or report success at an earlier asynchronous boundary.

For this scenario, the source row remains valid and the index contract is unchanged. Backfill is the documented choice for an incomplete but trustworthy index. Replay is appropriate when the original failed payload is still correct; reindex belongs to a changed or untrusted index contract. These choices follow the existing [drift recovery guide](../../../guides/drift-recovery.md), rather than adding a new recovery product. The local research briefs supply useful principles—explicit projection, Ecto transactions, asynchronous indexing, operational evidence—but their older Typesense-first and expanded-feature suggestions are superseded by current project scope.

## What existing evidence actually covers

| Surface | Observed source behavior | Evidence boundary |
|---|---|---|
| [C-16 baseline](../../milestones/v1.39-phases/162-whole-product-evidence-baseline/162-BASELINE.md) and [findings](../../milestones/v1.39-phases/163-findings-and-bounded-follow-up/163-FINDINGS.md) | Isolated retry/reconcile/backfill contracts exist; no recorded selected-repair-to-visible-result receipt | Evidence gap, not defect; an adjacent successful write or swap cannot fill it |
| [Operator API](../../../lib/scrypath/operator.ex), [Reconcile](../../../lib/scrypath/operator/reconcile.ex) | Without an action, reconcile gathers status, failed work, target history, and recommendations; with an explicit `RecoveryAction`, it applies the action | This is not a full source-row versus index comparison. A missing record can coexist with a clean task report; selection must be grounded in the known DB/search mismatch |
| [RecoveryAction](../../../lib/scrypath/operator/recovery_action.ex) | Backfill/reindex dispatch to existing paths; Oban retry decodes and enqueues stored documents/IDs; manual/inline retry requires explicit records or IDs | Scrypath retry does not call `Oban.retry_job` on the original job. It creates replay work; old failed records need not disappear |
| [Backfill](../../../lib/scrypath/backfill.ex) | Fetches Ecto rows in primary-key batches, projects them, upserts them, returns per-batch task information | `batch_size` limits each batch, not total scope. `base_query` removes `limit` and `order_by`; use a `where` ID predicate to bound the repair. It performs upserts, not stale-document deletion |
| [Backfill contracts](../../../test/scrypath/backfill_test.exs) | Explicit query scope, batch edges, target index and result shape are covered using a recording backend/repository | Good orchestration proof; not a live visible repair |
| [Live backend tests](../../../test/scrypath/live_meilisearch_verification_test.exs) | Custom-ID backfill reaches live search and verifies `ext-1`/`ext-2`; inline writes and target-only reindex also run | Useful existing live building blocks. There is no selected prior drift, report/decision boundary, or unrepaired control in the backfill case |
| [Live operator tests](../../../test/scrypath/live_operator_verification_test.exs) | Observe completed task status and report target-index visibility without creating a live index | Best location for the missing vertical scenario; currently stops before selected repair and final search |
| [Mounted operator browser test](../../../examples/scrypath_ecommerce/e2e/operator.spec.ts) | Retry click is conditional; post-click oracle accepts remaining failed work and generic page text | It can pass without a retry or repaired search result. Do not reuse it as C-16 acceptance |
| [Browser failure fixture](../../../examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/controllers/e2e_controller.ex) | `inject_failed_sync` constructs a job with `Elixir.NotARealBackend`, ID `-1`, then drains it | Useful synthetic diagnosis fixture, not a transient failure with a correct source-backed projection. Turning it into successful recovery needs a different fixture |
| [Existing retry affordance](../../../scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex) | Resolves a row, invokes its recovery action, and flashes `Retried` on an OK return | This observes accepted replay. It is not an independent search oracle; no UI redesign is needed to prove the library flow |
| [Reindex](../../../lib/scrypath/reindex.ex) and existing mounted swap test | Reindex sequences target creation, settings verification, backfill task waits, optional swap and swap wait; C-17 already has a bounded successful swap/search receipt | Do not duplicate C-17 or broaden C-16 into rollback, concurrent writes, or arbitrary full rebuild recovery |

## Completion boundaries that acceptance must preserve

The [sync guide](../../../guides/sync-modes-and-visibility.md) distinguishes DB commit, durable enqueue, backend acceptance, terminal backend success, and visible search. The recommended manual-backfill scenario keeps those stages observable without a real queue.

| Stage | Required observation | Insufficient substitute |
|---|---|---|
| Selection | Explicit schema/index and selected ID set; source exists; original query demonstrably misses the target after controlled drift | Selecting the first failure row or searching any matching document |
| Command accepted | `Scrypath.backfill/2` returns success for exactly the selected record count, with its returned task UID | Treating the return map as completed indexing |
| Repair submission finished | The bounded backfill has submitted its expected batches; all task references are accounted for | A total document count without identifying which tasks or IDs it represents |
| Backend terminal success | Every returned repair task reaches `:succeeded` for the expected live index; failure/cancellation/timeout are not success | Latest arbitrary succeeded task, no pending tasks, or any terminal state |
| Repair complete and visible | Repeat the same application search and verify exact target ID and expected projected value; check out-of-scope controls | DB lookup, hydration alone, raw document GET alone, generic hit count, flash text, or queue drain success |

There is no extra runtime “repair complete” state to implement. In the evidence record, completion means all selected repair tasks succeeded; successful visible recovery additionally requires the search oracle. For an Oban alternative, separately observe the new job ID and its completed state. [UpsertWorker](../../../lib/scrypath/oban/upsert_worker.ex) and [IndexingAck](../../../lib/scrypath/oban/indexing_ack.ex) already await a Meilisearch task when returned; do not incorrectly assume those workers always finish at backend acceptance. A worker's success still does not identify the user's final query result.

## Proof strategy comparison

| Strategy | What it proves well | Tradeoffs and limitations | Recurring Actions cost | Recommendation |
|---|---|---|---|---|
| Report-first isolated contracts | No mutation during reporting, explicit action dispatch, missing inputs, rejection paths | Cannot establish Meilisearch task execution or real search visibility | Existing fast suite; negligible marginal service cost | Reuse; add only a missing discriminating assertion |
| Deterministic fake backend | Pending→success/failure/timeout states; bounded payloads; negative oracle behavior | A fake search returning its own written data proves the fake's model. It cannot close a claim about real backend visibility | Low runtime; potentially substantial emulator maintenance | Use narrowly for error states, not as the C-16 live receipt |
| Narrow real-service root scenario | Ecto selection, projection, real HTTP/tasks, final Scrypath search; exact IDs and controls | SQLite source, checkout dependency; no Phoenix/package/Postgres/Oban retry claim | Existing v1.15 service and compiled root graph; only scenario duration added | **Preferred for bounded backfill C-16** |
| Narrow Phoenix/package scenario | Host context, Postgres/Oban plus real Meilisearch; packaged API if run in package mode | Extra staging/compilation; current lane runs both path and package scenarios; more setup and correlation for retry jobs | Existing advisory job/service block, but scenario executes twice | Prefer only when requirement explicitly depends on package or real queue seam |
| Mounted browser E2E | Actual operator selects row/clicks repair and consumer sees recovery | Needs recoverable fixture and exact ID oracle; browser, JS, LiveView, app and queue contribute failure modes | Existing mounted stack available; higher runtime, artifacts and diagnosis cost | Use only for an actual click-to-visible UI claim; current C-16 can be API/operator-runbook proof |
| No new proof; explicit limitation | Accurate distinction between contracts and end-to-end outcome | Does not establish the requested known-repair-visible outcome | Zero added runtime | Valid fallback if proof is declined; retain UNKNOWN for this claim rather than infer a pass |

## Requirement-grade recommended acceptance

These are candidate requirements, not executed results. Use one deterministic scenario and the existing contracts, with no routine human UAT.

1. **C16-PRE — discriminating known drift.** In an isolated run index, persist records A, B and C. First establish A and C in search through normal indexing, waiting for their setup tasks. Introduce a controlled missing-document state for A while keeping its source row. Keep B source-only and outside the repair scope; keep C already searchable. Wait for fixture mutation tasks, then assert A and B absent and C present through the same search path that will be used after repair. Describe this as synthetic missing-index drift, never a production incident or induced transient outage.
2. **C16-SELECT — report before mutation.** Call `Scrypath.reconcile_sync/2` without `action` against the same schema/index. Require a successful report identifying the expected index, and verify A is still absent. Reuse the fast read-only contract to prove no write dispatch. The known source/search mismatch identifies A; do not claim reconcile itself found missing row A or must recommend backfill when task history contains no failure.
3. **C16-BOUND — explicit repair scope.** Select `[A.id]` and invoke existing `Scrypath.backfill/2` in `:manual` mode with an Ecto query containing `where id in ^selected_ids`, same backend/index prefix, and small batch size. Assert one document/one batch and capture its exact task UID. A query limit is not accepted as the bound. No setup helper may insert A after this command.
4. **C16-TASK — terminal success is mandatory.** Await that task with the existing task helper and explicit deadline. Assert success, expected index, and valid UID; include each batch task if the fixture ever grows. Record acceptance and terminal observations separately. Do not require observing `processing` on a fast service, and do not assert immediate post-enqueue absence—both would be timing races.
5. **C16-VISIBLE — repaired result and controls.** Repeat the affected query through `Scrypath.search/3` and assert raw hit ID A plus expected indexed field value. If the test uses hydration, additionally assert A's hydrated record, never as a substitute for raw-hit evidence. Assert B remains absent and C retains its ID/value. This rejects no-op repair, wrong-index writes, broad backfill, wrong-document substitution and DB-only success. Use exact IDs; do not rely on spelling/typo tolerance alone.
6. **C16-REPEAT — safe bounded repetition.** Repeat the same bounded repair once, await its new task, and require the same unique ID set and values. This proves repeatability for a fixed projection/ID, not arbitrary event ordering or a last-write-wins guarantee under concurrent updates.
7. **C16-FAIL — fail closed.** Reuse task tests for backend failure, cancellation, malformed response, transport error and deadline expiry; none may be classified as successful repair. A search exception, missing expected ID, wrong indexed value or missing control must fail the live scenario. Add a tiny oracle-level test only if acceptance is factored into a reusable helper; avoid a general proof framework.
8. **C16-RECEIPT — exact execution provenance.** Capture named scenario, exact SHA/run/job, pass/fail/skipped status, service image (and resolved version/digest where available), Elixir/OTP and lock identity, selected IDs/index/task identifiers, and command. A skipped integration test or `--skip-integration` run is not a live receipt. The closeout record must point to the exact passing candidate/final evidence under the existing CONTRIBUTING protocol.
9. **C16-ISOLATION — bounded resources.** Reuse unique index prefixes, the serialized integration repository pattern, monotonic deadlines, and teardown. Keep diagnostics to task UID/index/status/error and relevant hit IDs/fields; no credentials or environment dump. Do not widen the test matrix. Missing services are prerequisite failure, not a successful skip.

For a report-selected action claim stronger than this recommendation, use `reconcile_sync(action: chosen_action)` only after a fixture produces that action and independently validates its schema/index/scope. That is additional evidence scope; do not fabricate an action merely to make the report appear to discover row-level drift.

## Failure and boundary cases: where to spend proof

| Case | Cheapest appropriate evidence | Decision and limitation |
|---|---|---|
| Report cannot fetch task history/settings | Existing reconcile/settings error contracts | Read failure must remain an error; do not infer clean posture |
| Selected source set is empty or record vanished | Small Ecto/backfill contract | Zero submitted documents cannot satisfy recovery of A; deletion recovery belongs to C-09, not broad backfill |
| Wrong index/backend or non-retryable failed row | Existing [failed-work tests](../../../test/scrypath/operator/failed_work_test.exs) | Assert the existing rejection paths for failed work/replay. Do not claim every manually constructed action has a universal authorization fence |
| Transient network failure, task failed/canceled/timeout | Existing [task tests](../../../test/scrypath/meilisearch/tasks_test.exs) and [worker tests](../../../test/scrypath/oban/worker_test.exs) | Deterministic injection is cheaper and more reliable than stopping service containers mid-test |
| Partial multibatch success | Existing batch/task contracts, explicit limitation for the one-record live receipt | Backfill is not all-or-nothing across submitted tasks; failure can leave earlier batches applied. No new generalized rollback work |
| Replay of old projected data after source changed | Source-reviewed [RecoveryAction](../../../lib/scrypath/operator/recovery_action.ex) and [worker](../../../lib/scrypath/oban/upsert_worker.ex) | Stored payload replay is not a reload of current DB state. A current-state backfill may be the correct operator choice. Concurrent ordering is explicitly outside this fixed-source scenario |
| Original failed job/task remains after successful repair | Source contracts and task retention semantics | Do not require failed-work history to be empty as the recovery oracle; correlate the new task/result |
| Task succeeded but target is missing from search | Real scenario's final query | Check exact index, filter/query and projection; only the final oracle closes the user job |
| Setup indexed A or hydrated DB data masks the missing repair | Negative precondition and raw-hit/value assertions | Fail a no-op repair; C staying present proves the service/index is readable |
| Broad repair touches B or wrong tenant | B sentinel in root scenario; host tenant proof remains separately scoped | This tests bounded record selection, not host authorization or every tenant topology |
| Repeat delivery | Repeat the same bounded upsert once | Stable-ID repeatability only; no exactly-once promise |
| Swap or rollback | Reuse C-17's named happy-path receipt | No additional swap browser or rollback matrix without a named unmet requirement |

## Official ecosystem evidence and application

All external sources below were accessed **2026-09-26**. Living documentation generally does not state a publication date; source versions are shown where available. Meilisearch current documentation is not a supported-version upgrade: the actual proof stays on the repository's **v1.15** target. Root locks currently resolve Ecto **3.14.0** and Oban **2.23.0**, so their versioned pages are included. Confidence is **MEDIUM** per the verified-web research classifier, not an invented HIGH tier.

| Source | Verified finding | Application to C-16 |
|---|---|---|
| [Meilisearch tasks](https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/async_operations) | Async requests return a task reference; `succeeded`, `failed`, and `canceled` are all terminal; finished tasks remain in history | Require the exact repair task to succeed, then query. Old failure history can remain after repair |
| [Meilisearch swap API](https://www.meilisearch.com/docs/reference/api/indexes/swap-indexes) and [swap specification](https://specs.meilisearch.dev/specifications/text/0191-swap-indexes-api.html) | Swaps are atomic in pairs across the request; task history/index data move, while enqueued tasks are not rewritten | A swap receipt needs correlation and active-index search. Do not add swap to a one-record repair just because it exists |
| [Oban 2.23 worker contract](https://oban.hexdocs.pm/2.23.0/Oban.Worker.html) | Worker return values control completion/retry/cancellation, and failed jobs use retry scheduling | Queue lifecycle alone is not search visibility. Existing Scrypath acknowledgement behavior must be accounted for |
| [Oban 2.23 uniqueness](https://oban.hexdocs.pm/2.23.0/unique_jobs.html) | Uniqueness applies at insertion, not execution concurrency; a successful insert can indicate a conflict | Do not claim dedupe makes replay exactly once or imposes ordering. Stable-ID repeated outcome is the bounded acceptance |
| [Oban insertion, retry and drain APIs](https://oban.hexdocs.pm/Oban.html) | Multi insertion supports transactional enqueue; `retry_job` schedules a job; drain executes available jobs and returns aggregate outcomes | A queue alternative must assert the selected job, not just aggregate drain success. Scrypath replay creates new enqueue work instead of directly using native retry |
| [Ecto 3.14 Multi](https://ecto.hexdocs.pm/3.14.0/Ecto.Multi.html) | Named operations compose into a database transaction with explicit failure results | Transactional source mutation plus enqueue is distinct from external HTTP indexing. Recommended recovery starts from committed source rows and avoids holding a DB transaction while polling |
| [Searchkick official README](https://github.com/ankane/searchkick#testing) | Search tests isolate index names for parallel workers, enable indexing only where needed, refresh explicitly, and assert returned records | Borrow selective integration tests and final-query oracles. Do not copy Elasticsearch refresh semantics into Meilisearch or expand Scrypath runtime breadth |
| [Meilisearch Rails official README](https://github.com/meilisearch/meilisearch-rails#testing) | Test synchronous mode waits for tasks; asynchronous deletion cannot reload an already deleted ORM record | Waiting is an explicit test boundary. Recovery fixtures must represent valid source/operation semantics; never repair a deleted source by an unexamined upsert |
| [Hibernate Search 8.1.3 reference](https://docs.hibernate.org/search/8.1/reference/en-US/html_single/#indexing-plan-synchronization) | Its synchronization strategies distinguish applied changes, durability and search visibility; stricter visibility can reduce throughput | Use separate evidence stages and a narrow integration scenario; do not make all production sync blocking just to simplify tests |

These are established official integration projects used as design precedents. Their examples support testing patterns; they do not establish Scrypath production reliability or justify adopting their full feature sets.

## GitHub Actions economics and implementation boundary

The [current workflow](../../../.github/workflows/ci.yml) already runs `backend (required)` on Ubuntu with Meilisearch v1.15 and Elixir 1.19.0/OTP 28.1. [The curated backend runner](../../../lib/mix/tasks/verify.meilisearch_smoke.ex) already includes the proposed operator test file, avoiding new task wiring. [IntegrationRepo](../../../test/support/integration_repo.ex) is SQLite; [its helper](../../../test/support/meilisearch_integration.ex) provides unique prefixes, task waits, 10-second monotonic search polling and cleanup. Preserve its per-suite repository isolation rather than introducing parallel modules sharing that name.

The Phoenix advisory job has Postgres 16 and Meilisearch v1.15, runs path then package proof, and remains available for a specifically packaged or real-Oban acceptance claim. The mounted required job already starts the more expensive Docker/browser app stack. Existing investment lowers the marginal cost of adding a browser test, but browser machinery still adds maintenance and failure diagnosis that the API-level C-16 claim does not need.

Measure scenario wall time and existing-job delta during implementation; no new timing measurement exists in this research. The root choice adds fixture writes, one report, bounded repair/repeat tasks, and queries to a service already running. The package choice adds the scenario in both dependency modes; the browser choice adds application/queue/UI coordination and artifacts. Record added duration and flake results before widening recurrence. Do not invent a minute saving or duplicate the same live scenario in all three lanes.

[GitHub's current billing documentation](https://docs.github.com/en/billing/concepts/product-billing/github-actions) says standard hosted runners are free for public repositories; larger runners remain charged, and artifact/cache storage has separate limits. Thus public-repository dollar cost can be zero while runner time, queue pressure, artifact volume and maintainer attention remain real costs. This recommendation needs no larger runner or added matrix. Keep routine diagnostics small; the existing exact-SHA closeout remains the provenance authority.

## Claim wording and fallback

After an exact passing receipt, use a bounded claim such as: **On the recorded checkout SHA, Ecto/SQLite and Meilisearch v1.15 completed a report-first, explicitly ID-scoped manual backfill of a synthetic missing document; the exact repair task succeeded and the same Scrypath search returned the target ID/value again while control records retained their expected state.**

Do not claim a real incident, generic operator usability, browser repair, PostgreSQL isolation, packaged Oban retry, ordering under concurrent source changes, exhaustive failure recovery, universal latency or rollback from this receipt. Those limits are precise; they do not negate the representative recovered-search outcome.

If no new scenario is justified, retain: **Retry, reconcile and backfill have isolated contracts and adjacent live indexing/swap proof; selected known drift through a completed repair to matching visible search remains unproven.** Keep the relevant condition-3 assessment UNKNOWN unless the gate owner explicitly narrows the important-workflow claim with documented reasoning. A report parser or a zero-finding ledger cannot turn this into PASS.

## Research method and remaining decisions

Mandatory planning and local prompt references were consulted along with the code/tests/workflow linked above. The research-plan seam selected Context7 for library questions and websearch for cross-ecosystem patterns. Context7 MCP and `ctx7` were unavailable, so official sites were searched/opened using the browser research tool. The confidence seam returned MEDIUM for verified websearch; digests were cached through `research-store`. No package was installed, runtime/test source edited, service started, test run, hosted run dispatched or commit created. This runtime has no dedicated Read/Write tools; shell reads and `apply_patch` were used for the research artifact.

The only material requirements decision is whether C-16 means **one representative bounded repair** or **specifically retrying a failed Oban job through the mounted interface/package**. The assigned outcome supports the first; recommend it. Requirement authors should name the chosen mode and evidence boundary explicitly. If implementation uncovers an actual runtime defect, record it and return to scope review rather than quietly expanding this evidence milestone.
