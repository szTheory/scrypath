# Phase 166 — Source Coverage, Dependency and Probe Audit

Planning-only audit; no implementation or service tests were run during planning.

## Discovery and decisions

Level 0: the current research and inspected code establish every required runtime seam. Existing Ecto queries/migrations, SQL Sandbox, Scrypath public APIs, Meilisearch task/settings helpers, telemetry, integration wrappers and package staging suffice. No new dependency or framework choice is planned. The three local Elixir/Ecto/Phoenix briefs were consulted for explicit context ownership, query composition, database constraints, stable tuples and real Repo testing; historical auth-product recommendations do not widen this phase.

The persisted actor/membership fixture uses two small tables and schema-free Ecto lookup/insertion. It has no membership metadata or account lifecycle needing another schema/API. This is within D-01's schema-name/query discretion and keeps a complete host tracer to four files. Post projection explicitly includes status; a filterable declaration alone does not place that value in a field-based document.

The assumption-delta detector returned detected=true for "second" and "choose". The plan records no change to library identity: actor-to-tenant membership is the host scope source; a second tenant is a positive control; the operator selects IDs through the existing query option. No accepted architecture debt is introduced.

Schema-gate patterns for Payload, Prisma, Drizzle, Supabase and TypeORM do not match this Elixir phase. Ecto migrations still execute through the consumer's existing test alias before live proof.

Reversibility: all changes are example/test/evidence local. No published API, retained adopter database, package version or external service choice is changed; the already-approved additive example migration does not require another decision checkpoint.

Estimate calibration returned factor=1, applied=false, sample_count=0, confidence=low. Raw plan estimates are 35,000 / 23,000 / 19,000 tokens and are not time commitments.

## Dependency and resource graph

| Task | Needs | Creates / additional outcome | Checkpoint |
|---|---|---|---|
| 166-01-01 | Existing consumer and Phase 165 contracts | Real persisted member → live search → scoped host hydration tracer | none |
| 166-01-02 | Host tracer | Rejection observation, mixed-tenant metadata and facet vocabulary, bounded runbook | none |
| 166-02-01 | Existing independent root live Repo/backend | Known mismatch → no-write report → selected repair → exact task/raw result | none |
| 166-02-02 | Repair tracer | Once-repeated selected scope, empty-scope no-op and safe receipt marker | none |
| 166-03-01 | Both implementation plans committed | Same-source path/package/root service receipts | none |
| 166-03-02 | Actual receipts plus historical C-09 | Complete freshness disposition, accurate validation and Phase 167 handoff | none |

Wave 1: 166-01 and 166-02. No file overlap. Separate Postgres/SQLite repositories and phx_tenant/scrypath-op index namespaces; orchestration owns shared-service lifecycle. Wave 2: 166-03 depends on both. Its evidence files have one owner. Keep root integration modules isolated as the existing wrapper requires.

Premortem:
1. A service flag excludes the new scenario: each verify fails for zero/excluded/skipped execution; success markers are required.
2. Hydration or a generic successful task hides the failed user outcome: assert raw metadata separately and poll only returned task IDs before the same raw query.
3. Planning/evidence edits move HEAD after a receipt: record the measured source, repeat relevant-path comparison and final external closeout; do not invent an exact-final receipt.

## Multi-source coverage

| Source | ID | Feature / constraint | Plan / task | Status |
|---|---|---|---|---|
| GOAL | 166 | Authorized host tenant search and bounded repair through visible search within existing scope | 01–03 | COVERED |
| REQ | HOST-01 | Trusted actor, persisted membership, forged selection/override rejection before dispatch | 01-01, 01-02, 03-01 | COVERED |
| REQ | HOST-02 | A/B controls, exact raw/hydrated IDs, counts and facets | 01-02, 03-01 | COVERED |
| REQ | PKG-04 | Same named consumer workflow in path and fresh artifact modes | 01-02, 03-01 | COVERED |
| REQ | REPAIR-01 | Known mismatch, no-write report, explicit selected-ID predicate and controls | 02-01, 02-02, 03-01 | COVERED |
| REQ | REPAIR-02 | Exact returned task/index success and same-query raw ID/projection | 02-01, 02-02, 03-01 | COVERED |
| REQ | DELETE-01 | Relevant-path freshness, conditional reuse/fresh proof/UNKNOWN | 03-02 | COVERED |
| CONTEXT | D-01 | Existing Phoenix consumer and persisted actor/membership | 01-01, 03-01 | COVERED |
| CONTEXT | D-02 | Synthetic authenticated principal; host membership and rejection | 01-01, 01-02 | COVERED |
| CONTEXT | D-03 | Host context policy and fresh allowlisted options | 01-01, 01-02 | COVERED |
| CONTEXT | D-04 | Tenant-and-returned-ID hydration; separate raw/metadata proof | 01-01, 01-02 | COVERED |
| CONTEXT | D-05 | A published/draft, B distinct positive marker; stable corpus limits | 01-02, 03-01 | COVERED |
| CONTEXT | D-06 | Public common-keyword facet scenario against live service and package | 01-02, 03-01 | COVERED |
| CONTEXT | D-07 | Existing advisory job/services, exact source, artifact ≠ public release | 03-01, all scope/verification blocks | COVERED |
| CONTEXT | D-08 | Independent root Ecto/SQLite repair fixture and controls | 02-01 | COVERED |
| CONTEXT | D-09 | Known mismatch precondition and non-mutating report observation | 02-01 | COVERED |
| CONTEXT | D-10 | Explicit where IDs, exact tasks/index, same-query projection, bounded repeat | 02-01, 02-02 | COVERED |
| CONTEXT | D-11 | Final-source C-09 freshness and honest conditional disposition | 03-02 | COVERED |
| RESEARCH | R-01 | Architectural responsibility map: host policy/hydration, library composition, backend task execution | 01/02 interfaces and actions | COVERED |
| RESEARCH | R-02 | Existing dependencies/locks and pinned service/runtime posture; no new install | All plans | COVERED |
| RESEARCH | R-03 | Preserve legacy Post fixtures while projecting tenant/status/string facet | 01-01 | COVERED |
| RESEARCH | R-04 | Settings-task success and required settings-subset readback | 01-01 | COVERED |
| RESEARCH | R-05 | Dispatch-positive recorder and zero-dispatch rejections | 01-02 | COVERED |
| RESEARCH | R-06 | Public facet keyword filter; decoded/raw expected values/counts | 01-02, 03-01 | COVERED |
| RESEARCH | R-07 | Do not use record filtering as raw/metadata privacy proof | 01-02 | COVERED |
| RESEARCH | R-08 | Backfill strips query limit; retained predicate is the scope | 02-01 | COVERED |
| RESEARCH | R-09 | Counts alone cannot prove no write; observe actual report requests/tasks | 02-01 | COVERED |
| RESEARCH | R-10 | Distinguish accepted task, terminal task success and query visibility | 02-01, 03-01 | COVERED |
| RESEARCH | R-11 | Bounded repetition and empty-scope/failure contracts without broad recovery claim | 02-02 | COVERED |
| RESEARCH | R-12 | Unique index prefixes, Sandbox and isolated root module lifecycle; bounded polling/cleanup | 01/02 tasks, coupling declarations | COVERED |
| RESEARCH | R-13 | Existing package stages lib/priv/test and runs the same suite | 03-01 | COVERED |
| RESEARCH | R-14 | Exact source/run/job/attempt/mode/service/task receipt; skipped execution is insufficient | 03-01 | COVERED |
| RESEARCH | R-15 | Current local service tuple/auth is unknown until verified; existing hosted fallback | 01-01, 03-01 | COVERED |
| RESEARCH | R-16 | C-09 inspected-HEAD inference must be repeated at final assessment source | 03-02 | COVERED |
| RESEARCH | R-17 | Sanitized synthetic diagnostics and measured rather than invented runtime | All actions, 03 evidence | COVERED |
| RESEARCH | R-18 | ASVS L1 threat mapping; no authentication or certification claims | Every threat_model and scope block | COVERED |

Excluded by source authority: authentication/session implementation, HTTP/Plug/UI/browser host claims, stale-index tenant-move guarantees, Oban retry/full reindex/concurrency guarantees, wider facet/settings/federation/version matrices, new required lanes, release/publication, and Phase 167's separate six-condition assessment. These are exclusions, not missing Phase 166 scope.

## SPEC-less edge probe preservation

The upstream deterministic probe reported applicable=11, resolved=0, unresolved=11; byVerification explicit=0/backstop=0. No row is resolved or dismissed here.

| ID | Requirement | Category | Status | Verification | Resolution | Reason | Plan |
|---|---|---|---|---|---|---|---|
| EA-166-01 | HOST-01 | unclassified | unresolved | null | null | null | 01 |
| EA-166-02 | HOST-02 | unclassified | unresolved | null | null | null | 01 |
| EA-166-03 | PKG-04 | unclassified | unresolved | null | null | null | 03 |
| EA-166-04 | REPAIR-01 | boundary | unresolved | null | null | null | 02 |
| EA-166-05 | REPAIR-01 | adjacency | unresolved | null | null | null | 02 |
| EA-166-06 | REPAIR-01 | empty | unresolved | null | null | null | 02 |
| EA-166-07 | REPAIR-01 | ordering | unresolved | null | null | null | 02 |
| EA-166-08 | REPAIR-01 | precision | unresolved | null | null | null | 02 |
| EA-166-09 | REPAIR-02 | unclassified | unresolved | null | null | null | 02 |
| EA-166-10 | DELETE-01 | idempotency | unresolved | null | null | null | 03 |
| EA-166-11 | DELETE-01 | concurrency | unresolved | null | null | null | 03 |

Each plan carries its assigned probes and concrete bounded assumption. Planning tests is not author resolution of a spec edge.

## SPEC-less prohibition recall → precision

Per requirement, ask: "What could this feature silently become that the author would NOT want, but the spec does not forbid?" The requirements have no SPEC prohibition section; the approved context still constrains every candidate.

| Requirement | Raw recall candidates | Precision outcome |
|---|---|---|
| HOST-01 | Auth product; session assurance; arbitrary-host certification; caller-trusted tenant; bypassed membership; missing/null crash; duplicate membership; malformed key; injection; secret logging | KEEP bespoke overclaim P-166-HOST-01. Routine shape/duplicate/error cases go to tests/edge probe. Canon auth/input-injection/secrets goes to security review. |
| HOST-02 | Hydration hides raw leaks; count leaks; facet leaks; all-tenant promise; stale-index promise; empty fake proof; unstable sort; wrong counts; duplicate hits; unbounded query | KEEP bespoke masking P-166-HOST-02. Routine counts/order/empty issues go to tests/edge probe; general access-control/data exposure is canon. Stable-fixture limits are explicit. |
| PKG-04 | Implied Hex publication; implied public install; new mandatory lane; unapproved matrix; hidden dependency substitution; artifact build mistaken for run; skipped scenario pass; missing file; wrong version; secret output | KEEP provenance/scope inflation P-166-PKG-04. Routine artifact/execution checks are ordinary verification; secrets/dependency trust is canon. |
| REPAIR-01 | Reconcile invents row diagnosis; automatic broad repair; hidden write during inspect; limit masquerades as bound; no-op called recovery; empty crash; duplicate IDs; row-order bug; wrong repo; injection | KEEP operator intent/report overclaim P-166-REPAIR-01. Scope/no-write are explicit tests; ordinary errors remain engineering; injection is canon. |
| REPAIR-02 | Acceptance called visibility; unrelated successful task; hydration masks absence; exactly-once promise; concurrent-ordering promise; all-recovery promise; timeout pass; malformed task; missing control; null projection | KEEP asynchronous/broad guarantee inflation P-166-REPAIR-02. UID/value/control/error mechanics remain tests/edge probes. |
| DELETE-01 | Historical readiness rewritten; stale receipt silently reused; age alone triggers broad rerun; source/package conflation; all-mode guarantee; concurrency guarantee; corrupt digest; missing artifact; typo SHA; missing field | KEEP evidence-history/freshness P-166-DELETE-01. Corrupt/missing/typo/schema checks are routine; bounded claim limits remain explicit. |

All six kept items appear under must_haves.prohibitions with status unresolved, verification/resolution/reason null. They are descriptor-less **flagged-unverified prohibitions**, not fabricated test or judgment closures. No check_kind/check_target/check_rule/violation fixture is emitted.

Canon referral: generic access control, injection, credential exposure and supply-chain tampering are covered by the phase's STRIDE controls and $gsd-secure-phase; no duplicate canon prohibition is minted. Elixir projects use their existing input/contract checks rather than introducing an unrelated ESLint toolchain.

## Artifacts this phase produces

Implementation: one additive example migration, Blog/Post updates, one host rejection file, one host live scenario, one existing root operator test expansion, example README entry.

Execution evidence: 166-EVIDENCE.md, 166-EVIDENCE.json, accurate 166-VALIDATION.md and three plan summaries.

Planning: three PLAN.md files, this source/probe audit, and COVERAGE.md. The orchestrator owns the scoped roadmap plan-list update and final planning commit.

## Tool and source limitations

The active runtime exposes exec_command/apply_patch, not literal Read/Write/Edit tools; canonical files are created with apply_patch, never heredocs. The queried agent-skills payload repeats the planner role and contains no injected skill; project agent_skills is empty and neither project skill directory exists. No codebase map or graph is present. The fresh research/pattern/validation artifacts await the orchestrator's authorized planning commit; all implementation source references are tracked, and new implementation/evidence paths are explicitly intended creations.

