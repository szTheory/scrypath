# C-09 research: deletion through to visible search

**Project:** Scrypath · **Candidate milestone:** v1.40 · **Researched:** 2026-09-26  
**Scope:** Readiness condition 3, C-09 only; evidence and claim boundaries, no implementation authorization.  
**Overall research confidence:** MEDIUM. The mandated `classify-confidence --provider websearch --verified` seam returned MEDIUM. Local source and hosted artifact observations below are directly inspected facts; prospective cost and coverage judgments are explicitly estimates or recommendations.

## Recommendation

**Reuse the existing, successful, exact-SHA storefront deletion receipt for a newly dated, bounded C-09 assessment. Do not add another service scenario solely to close this question.** Research located the missing evidence in the final v1.39 full ecommerce E2E run. Its delete scenario checks raw backend hits, not merely hydrated database records, and passed on its first attempt. The archived assessment remains historically correct at its cutoff; this later receipt supports a new assessment.

Recommended claim: **In the source-backed ecommerce Phoenix/Ecto example, a previously searchable product deleted through the explicit host context no longer appears among raw tenant-scoped search hits after the persisted Oban delete work is drained; a sibling product remains visible.** This establishes a representative hard-delete workflow against Postgres 16 and Meilisearch v1.15. It does not establish package-backed deletion, every sync mode, atomic database-and-job enqueue, production polling latency, concurrency ordering, or every host application.

If the owner requires package-specific or explicit row-readback proof, the smallest additional implementation is one focused ExUnit scenario in the existing `phoenix_meilisearch` consumer suite, using `Oban.Testing.with_testing_mode(:manual, ...)` and the existing path/package harness. Do not introduce a new fixture application, public API, browser journey, dependency, or CI matrix. That is a conditional option, not a prerequisite implied by C-09's current wording.

UI and brand design are outside this scope because the uncertainty concerns source deletion, queue/task execution, and the search projection. The existing browser check supplies an additional rendered outcome; changing the interface would not improve the decisive raw-hit oracle. Passing this one claim does not pass the entire readiness gate or authorize ScrypathOps work.

## Decision-changing evidence found

| Receipt field | Observed value |
|---|---|
| Hosted run | [36257182675](https://github.com/szTheory/scrypath/actions/runs/36257182675) |
| Exact source SHA | `dc400b2b57aec0ca6b0ef16c9477d266fd41a433` |
| Job | [108446076619 — ecommerce-e2e (advisory)](https://github.com/szTheory/scrypath/actions/runs/36257182675/job/108446076619), success |
| Job duration | 16:55:23–17:03:55 UTC, 8m32s |
| Artifact | [10910932671 — ecommerce-e2e-evidence](https://github.com/szTheory/scrypath/actions/runs/36257182675/artifacts/10910932671), not expired when inspected |
| GitHub artifact digest | `sha256:7ee2a3ada62293f7c1ded409b426d0b739329fd863bbe6996d1986e5926ee49e` |
| Inspected report | `test-results/phase105-playwright.json` inside that artifact |
| Report SHA-256 | `e53352b3e15a70b861118041024ecf4b60f11eb2627ad0ddcbd76afc143439bf` |
| Scenario | `storefront.spec.ts:125`, `deleted products leave the visible search index` |
| Scenario result | Passed; retry 0; 1,222 ms; zero errors; start 2026-09-26T17:03:45.570Z |
| Suite result | 99 expected passes; 0 skipped; 0 unexpected; 0 flaky; 285,494 ms |
| Freshness inspection | No changes in `lib/`, `examples/`, or `.github/workflows/ci.yml` between receipt SHA and inspected HEAD `6e61380555361b6bb03c07a7f0f7c2a944ef960d` |

These are read-only observations from the GitHub job API, job log, downloaded artifact, and Git diff. No suite was run or service started for this research. The extracted report was inspected rather than treating an overall green run as scenario-level proof. Artifact retention is finite: a milestone evidence record should preserve the minimal sanitized scenario result, IDs, dates, source SHA, and digest, not depend solely on a future download.

### What the existing scenario actually does

1. Seeds the deterministic catalog, obtains the target product ID, and drains prior indexing work.
2. Polls the tenant-scoped search endpoint until the target name is visible.
3. Calls the development/test deletion endpoint, which loads the tenant's product and invokes `Catalog.delete_product/2`.
4. The context executes `Repo.delete`, then explicitly invokes `Scrypath.delete_record`. Scrypath is configured for `:oban`, queue `:scrypath_sync`.
5. Drains the persisted queue and polls the same search endpoint until the target name disappears.
6. Loads the storefront and checks that the sibling product is visible while the target is absent.

The critical endpoint maps **`result.hits`** into names. `Scrypath.SearchResult` takes those hits directly from the backend response. Missing database records cannot alone make this oracle pass. The known small catalog, presence precondition, unchanged query/tenant, and surviving sibling constrain false success through empty setup, wrong search scope, or an entirely removed index.

Limits: the scenario identifies the document by its unique fixture name, not an ID assertion; it does not issue a separate `Repo.get == nil` assertion; queue drain counts are returned/logged but not asserted by this scenario; the deletion controller's `queued_delete_sync: true` value is not proof that enqueue succeeded because the context discards the sync return. None of those auxiliary signals is used as the decisive deletion oracle. The successful raw-hit transition is the strongest receipt. Error-path handling, task UID correlation, and durable enqueue atomicity remain distinct claims.

## Jobs to be done

| Who / when | Job | Inputs | Required output / boundary |
|---|---|---|---|
| Phoenix/Ecto feature owner, hard deletion | Remove an existing row and its search projection | Existing schema, deleted struct or canonical document ID, configured index and sync mode | Source delete succeeds; explicit sync reaches backend; target raw hit is absent |
| Operator, delayed or failed synchronization | Distinguish pending removal from completed removal | Job state, backend task state, stable document identity | Diagnose queued/failed work without representing acceptance as visibility |
| Maintainer, readiness/release review | Decide whether an adopter claim is evidenced | Exact source SHA, scenario result, service tuple, source freshness | Bounded reusable receipt; no human UAT and no inferred broader guarantee |

The representative catalog hard-delete job is sufficient for the proposed claim. Industry permutations add little unless they introduce different deletion semantics, such as soft deletion, authorization, legal retention, or concurrent recreation; those are excluded rather than silently implied.

## Current implementation and proof inventory

| Layer | Inspected source / existing proof | Establishes | Does not establish |
|---|---|---|---|
| Public sync APIs | `lib/scrypath.ex:201`, `lib/scrypath/sync.ex:103`; `test/scrypath/sync_test.exs:341–380,598–626` | `delete_record`, single ID, and batch ID converge; identity can be resolved without projecting a record; empty batches no-op | An Ecto deletion automatically triggers sync; live visibility |
| Queue payload | `lib/scrypath/oban/enqueue.ex`, `payload.ex`; focused enqueue/payload tests | ID-only durable job payload and index routing; no deleted row reload required | Atomicity with a host's DB deletion; queue scheduler progress |
| Worker | `lib/scrypath/oban/delete_worker.ex`; `test/scrypath/oban/worker_test.exs:100,131` | Calls backend by IDs; retryable backend errors propagate; real Meilisearch success goes through `IndexingAck.await` | Exactly-once delivery; racing upsert/delete ordering |
| Client/adapter | `lib/scrypath/meilisearch/operations.ex:38`; `test/scrypath/meilisearch_test.exs:126,216` | Canonical IDs, index, HTTP POST delete-batch request, response/task normalization | Whether real Meilisearch removed the correct document |
| Completion semantics | `sync.ex:163`; `oban/indexing_ack.ex`; `meilisearch/tasks.ex`; task tests | Inline waits; manual accepts; Oban worker waits on real backend task; failed/canceled/malformed/timeout/transport cases have focused coverage | Search results themselves or production completion deadlines |
| Phoenix package example | Existing four integration scenarios; Phase 160 `COVERAGE.md` | Package loading, upsert, hydration, related projection | Deletion explicitly OPT-OUT; default Oban testing is inline and does not prove durable job storage |
| Source-backed ecommerce E2E | Scenario and exact-SHA artifact above | Committed host delete path, persisted queue drain, raw-hit removal, sibling visibility | Package install path, arbitrary host callbacks or policies |

Ecto integration is explicit application orchestration. No library callback on every `Repo.delete` is implied. The ecommerce HTTP server switches off SQL sandbox ownership for the live browser run, uses a real persistent connection pool, and retains Oban manual testing for controlled queue execution. The legacy Phoenix package tests use SQL Sandbox and inline Oban by default; confusing those configurations would overstate what their passing receipts establish.

Local provenance: [baseline C-09](../../milestones/v1.39-phases/162-whole-product-evidence-baseline/162-BASELINE.md), [findings](../../milestones/v1.39-phases/163-findings-and-bounded-follow-up/163-FINDINGS.md), [package coverage](../../milestones/v1.38-phases/160-package-backed-phoenix-proof/COVERAGE.md), [readiness authority](../../reference/PRE-OPERATOR-UI-READINESS.md), [CONTRIBUTING](../../../CONTRIBUTING.md). The five requested `prompts/` references informed the Ecto-native, explicit-sync, measured-cost framing; their earlier proposed APIs and ecosystem assertions are historical research, not current implementation authority.

## Proof options and CI cost

Observed timing anchor: the same hosted run used 1m38s for the path-plus-package `phoenix-example` job, 26s for `backend`, 3m47s for `ecommerce-mounted`, and 8m32s for full `ecommerce-e2e`. These are elapsed job durations, not marginal test timings or guaranteed billed minutes. Startup/cache/concurrency variance applies.

| Option | Strength / what it proves | Weakness / what it misses | Cost and recommendation |
|---|---|---|---|
| Existing focused tests only | Fast ID routing, request shape, no row reload, error/task contracts | Fakes cannot certify real index mutation or final visibility | Zero new CI minutes if simply cited. Necessary supporting proof, insufficient by itself for the requested final outcome |
| Add backend-client fake/contract seam | Deterministically exercises task transitions, bad payloads, failure/retry and custom IDs | Fake search disappearance can encode the implementation assumption; real Postgres/Meilisearch boundaries still absent | Likely seconds in fast suite, no services; much already exists. Add only for a named missing failure boundary |
| Small real-service/package scenario | Real deletion and raw search oracle through packaged consumer; manual Oban can separate enqueue from execution | SQL Sandbox does not establish cross-process commit behavior; no production scheduler/race guarantee | Reuse existing 1m38s job and service block; incremental test likely seconds, unmeasured. Best new-code option if package-specific claim is required |
| Existing mounted adopter/full E2E | Existing committed DB → Oban → real backend → raw search → rendered result chain | More infrastructure, broader suite, source-backed, limited error/ordering coverage | Receipt reuse costs **zero additional CI runs**. Full fresh rerun observed 8m32s vs deletion itself 1.222s. Reuse now; leave scheduled/manual advisory topology intact |
| No additional proof, retain narrower implementation-only claim | Honest documentation of what unit/source inspection establishes | Important workflow remains UNKNOWN if live receipt is ignored | Zero CI minutes, but unnecessarily weak after discovery of the existing receipt. Reserve if receipt later becomes invalid or unreadable and rerun has no decision value |

The recommended choice is **existing E2E receipt reuse plus bounded reassessment**. Do not move the deletion scenario into the required mounted subset or promote the full E2E lane merely because it supplies readiness evidence. Required gates remain core/package/repository/backend/ecommerce-mounted; Phoenix example is advisory and full E2E is scheduled/manual advisory. Milestone acceptance may require inspecting a specific advisory scenario's success without changing merge policy.

## Discriminating oracle and deterministic execution

There are four different facts:

| Observation | Meaning |
|---|---|
| Source row is absent | DB deletion happened; stale search may still return the document |
| Job/task was accepted | Work was scheduled; neither execution nor visibility is established |
| Meilisearch task succeeded | Backend processed that operation; correlation and identity still matter |
| Target absent from raw hits after known presence, sibling still present | The representative user-visible search projection changed as intended |

The existing scenario uses 15-second bounded presence/absence polling, a 30-second scenario timeout, and at most five queue-drain passes. Its CI configuration allows one retry globally, but **this receipt has retry 0 and is not a pass-after-retry**. Error responses cannot count as an empty successful search. Search name absence alone would be weak without the preceding presence assertion and surviving sibling. Hydrated `records == []`, missing DB rows, HTTP 202, or a completed enqueue response must never substitute for raw-hit absence.

For any additional ExUnit proof: seed exactly two known documents in an isolated index, wait for initial indexing, and assert both raw IDs are visible; delete the source target; assert `Repo.get` is nil; preserve the source identity before deletion; enqueue under manual Oban testing; assert the persisted job's IDs and state; execute once with controlled `drain_queue`; require one success and zero failures; query raw hits through `Scrypath.search`; require the target ID absent and the sibling ID present. Assert successful HTTP/search shape throughout. Use one explicit monotonic deadline (suggested 10–15 seconds for visibility), bounded per-request timeouts, and diagnostic last-task/job/search state. Do not wrap the entire scenario in a retry or sleep an arbitrary fixed duration. These durations are proposed test budgets, not product SLAs.

A tiny negative-control stage can make a new scenario especially discriminating: after the DB row is gone but before draining the queued delete, prove the target remains among raw hits. That demonstrates the test would catch hydration masking or a no-op delete. Keep rollback and malformed-job checks in cheap focused tests rather than multiplying service scenarios.

## Failure and boundary disposition

| Boundary | Existing evidence / disposition | Requirement consequence |
|---|---|---|
| Source row gone before worker starts | ID-only worker plus committed source-backed E2E | Central supported case; never reload deleted row |
| Wrong document/index or entire-index deletion | Known initial target and surviving sibling; focused index/ID request tests | Any new scenario should compare raw IDs; preserve unrelated document |
| Backend unavailable, task failed/canceled, timeout | Focused worker/task tests | Keep errors distinct from completed removal; do not inject real outages for C-09 closure |
| Hydration hides a stale document | Existing oracle uses raw hits | Prohibit records-only acceptance |
| App reports enqueue success while enqueue failed | Existing context discards sync return, but final visibility catches failed deletion in this happy path | Do not cite endpoint booleans as queue proof; broader error UX is outside this research claim, not a confirmed new defect |
| Rollback of source deletion and job insertion | Not proved by this scenario; Ecto transaction composition is available | Explicitly exclude atomicity claim; if requested, use same-Repo manual Oban rollback test, never real backend IO inside transaction |
| Duplicate delivery / delete already absent | Not directly established by current receipt | Keep as a possible one-call extension only if idempotent retry claim is required; do not infer from HTTP acceptance |
| Delayed earlier upsert resurrects deleted record | Not covered; upsert jobs store projected documents | Exclude global ordering/exactly-once guarantee; reopen only for concrete race evidence or separately approved requirements |
| Manual / inline paths | Unit semantics present, no cited deletion-specific live receipt | Do not relabel Oban proof as all-mode proof |
| Soft delete, cascade, custom IDs, bulk deletion, tenant policy | Host-specific or separately focused contracts | Limit to explicit hard delete of the demonstrated schema; C-10 owns host authorization |
| Restart, queue contention, production latency | Controlled manual drain does not cover these | No availability or latency promise |

## Requirement-grade acceptance candidates

These are proposed statements for owner-approved requirements; they do not modify the archived gate.

**Recommended evidence-only scope:**

1. **C09-EVID-01:** A new dated C-09 record identifies the exact source-backed deletion scenario, run, job, SHA, service tuple, artifact ID/digest, scenario result, retry count, and before/after oracle, and preserves the sanitized receipt before artifact expiry.
2. **C09-EVID-02:** The record explains why `result.hits` establishes backend visibility independently of DB hydration, and links the known-presence and sibling-survival assertions to inspected source at the receipt SHA.
3. **C09-EVID-03:** The record compares the receipt source to the final assessment source for relevant delete, search, host, configuration, fixture, and workflow changes. Any relevant invalidator requires a targeted fresh automated receipt or a precise UNKNOWN; age alone does not require rerunning.
4. **C09-EVID-04:** The supported claim is limited to this hard-delete Oban workflow. Package deletion, other sync modes, transaction atomicity, race ordering, soft deletes, production scheduling, and arbitrary hosts remain visibly outside the claim. v1.39 history is preserved.
5. **C09-EVID-05:** No new required CI lane or routine human UAT is introduced; any new readiness conclusion evaluates all remaining condition-3 questions independently.

**Conditional package-specific scope, only if the approved claim demands it:**

6. **C09-PKG-01:** Both existing path and packaged Phoenix commands run the same deterministic scenario against real Postgres/Meilisearch, with two initial raw hits, deleted DB-row readback, persisted ID-only Oban job, successful controlled drain, target raw-ID absence, and sibling raw-ID presence.
7. **C09-PKG-02:** The scenario demonstrates that deleting only the DB row leaves the raw target hit until sync executes; any query error, job failure, timeout, or wrong index fails with bounded diagnostics.
8. **C09-PKG-03:** Existing fast tests remain the authority for identity/request/error edges; additional tests cover only uncovered named boundaries. CI records exact-SHA success and measured marginal runtime before considering any topology change.

## Official ecosystem lessons and sources

All external sources accessed **2026-09-26**. Confidence for verified official web findings is **MEDIUM**, per the research seam. Current documentation is used for semantic comparison; it does not expand Scrypath's tested Meilisearch v1.15 support. Versioned Oban v2.21 documentation aligns with the legacy example's 2.21.1 lock; the ecommerce receipt uses Oban 2.23.0, Ecto 3.14.0, and Phoenix 1.8.13. Latest docs may describe later versions.

| Source | Lesson and applicability |
|---|---|
| [Meilisearch batch deletion](https://www.meilisearch.com/docs/reference/api/documents/delete-documents-by-batch) | Array-of-primary-key deletion responds with task acceptance. Do not use HTTP 202 as completion |
| [Meilisearch asynchronous operations](https://www.meilisearch.com/docs/capabilities/indexing/tasks_and_batches/async_operations) | Pending, successful, failed, and canceled tasks differ; observe completion and final search separately |
| [Meilisearch official documents specification](https://specs.meilisearch.dev/specifications/text/0124-documents-api.html#_3-1-8-post-indexes-index-uid-documents-delete-batch) | Batch deletion has task type `documentDeletion`. **Source discrepancy:** the current generated API page sample shows `documentAdditionOrUpdate` and null index; do not copy that sample into a delete contract |
| [Ecto.Multi](https://ecto.hexdocs.pm/Ecto.Multi.html) | Database operations can compose in one transaction; a host can pair deletion and durable enqueue. External search IO is not made rollback-safe by inclusion in a DB transaction |
| [Oban testing](https://oban.hexdocs.pm/testing.html) | Inline testing executes immediately without job persistence; manual mode supports persisted jobs and controlled execution |
| [Oban v2.21 queue draining](https://oban.hexdocs.pm/2.21.0/Oban.html#drain_queue/2) | Deterministic in-process execution of available persisted jobs returns counts; this differs from proving production scheduler behavior |
| [Meilisearch Rails queues](https://github.com/meilisearch/meilisearch-rails#queues--background-jobs) | Background deletion can happen after the ORM record disappears; delete by captured ID. Its synchronous test option waits for tasks. Scrypath already follows the ID-based worker pattern |
| [Laravel Scout queueing](https://laravel.com/docs/12.x/scout#queueing) | Disabling the application queue does not remove Meilisearch's backend asynchrony. Avoid claiming visibility from application-side completion |
| [Searchkick results](https://github.com/ankane/searchkick#results) and [testing](https://github.com/ankane/searchkick#testing) | Database-loaded results and raw engine results differ; isolate indexes and enable live indexing only where relevant. This supports the raw-hit oracle and avoiding broad duplicate service suites |

No popularity ranking or adoption count is asserted; these maintained official integrations are design precedents. Meilisearch Rails/Scout lifecycle conventions are lessons, not instructions to introduce Ecto callbacks or another backend abstraction.

## Research method and remaining uncertainty

The GSD research plan selected `websearch` for three questions; official pages and source were then opened and cross-checked. Context7 tools and the `ctx7` CLI were unavailable. Research digests were cached with the seam's MEDIUM classification. The configured agent-skills mapping was empty. This runtime exposes no literal Read/Write tools, so file reads used the shell and this artifact used the available patch tool; no heredoc file creation was used.

Inspection cannot establish every real application's behavior, and the existing E2E lacks explicit DB readback and task-ID correlation. The report does not turn those limitations into bugs or silently require a broader milestone. The owner/orchestrator must decide whether the bounded representative claim is sufficient for the condition-3 reassessment. If it is, C-09 needs evidence reconciliation, not new product work. No conclusion here resolves C-16, C-10/C-11, condition 6, or the overall readiness outcome.
