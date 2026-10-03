# Phase 172 — Source and probe coverage

Planning coverage only; execution evidence is pending. This phase preserves the approved UI-SPEC. D-01–D-10 below are ordinal aliases for the ten unnumbered locked bullets in 172-CONTEXT; they add no decisions. D-11 names the extra shortcut feedback recorded in UI-SPEC (also explicitly named in Plan01).

## Source audit

| Source | ID | Outcome/constraint | Plans | Status |
| --- | --- | --- | --- | --- |
| GOAL | Phase172 | Six consistent surfaces, schema-preserving recovery, visible state equals backend state | 01–08 | COVERED |
| GOAL | SC1 | Readable shared roles, triage hierarchy, truthful empty/error/partial states and actual catalog | 01,02,03,05,07 | COVERED |
| GOAL | SC2 | Named semantic forms and full dialog focus lifecycle | 02,07 | COVERED |
| GOAL | SC3 | Allowed schema continuity and explicit invalid-target refusal | 03,04,06 | COVERED |
| GOAL | SC4 | New work→exact terminal task→expected active document; separate current promotion | 04,05,06 | COVERED |
| GOAL | SC5 | Existing automated lanes, reviewed PR, traceability, cleanup and final-source proof | 06,07,08 | COVERED |
| REQ | OPUX-01 | Shared roles and responsive component catalog | 01,02,07 | COVERED |
| REQ | OPUX-02 | Semantic controls/modal keyboard behavior | 02,07 | COVERED |
| REQ | OPUX-03 | Coherent nouns, action hierarchy, concise copy | 01,02,03,05,07 | COVERED |
| REQ | OPUX-04 | Schema and context identity | 03,04,06 | COVERED |
| REQ | OPUX-05 | Truthful recovery states and server promotion predicate | 04,05,06 | COVERED |
| REQ | OPUX-06 | Actual mounted discriminating recovery | 04,06 | COVERED |
| REQ | OPUX-07 | Focused regression/theme/layout proof | 01,05,06,07,08 | COVERED |
| REQ | OPUX-08 | Reviewed delivery/traceability/release/cleanup | 08 | COVERED |
| CONTEXT | D-01 | Optional preview and autonomous approved work | 06,08 | COVERED |
| CONTEXT | D-02 | Existing shell/palette/fonts/six surfaces/components | 01,02,07 | COVERED |
| CONTEXT | D-03 | State/object/action hierarchy and coherent nouns | 01,02,03,05 | COVERED |
| CONTEXT | D-04 | Named tokens and actual component authority | 01,07 | COVERED |
| CONTEXT | D-05 | Narrow/long/keyboard/loading/empty/error/partial/stale behavior | 02,03,04,07 | COVERED |
| CONTEXT | D-06 | Schema-preserving incident route and separate guarded promotion | 03,04,05,06 | COVERED |
| CONTEXT | D-07 | Correlated recovery with retained history | 04,06 | COVERED |
| CONTEXT | D-08 | Existing automated lanes/direct images; no routine UAT | 01,06,07,08 | COVERED |
| CONTEXT | D-09 | Phase170 frozen history; completion before final attestation | 08 | COVERED |
| CONTEXT | D-10 | Reviewed PR-first/release decision/task-owned cleanup | 08 | COVERED |
| CONTEXT | D-11 | One discoverable shortcut hint | 01,02,03,07 | COVERED |
| RESEARCH | R1 | OpsUi/LiveView/URL/service patterns, authorization/audit preserved | 01–05 | COVERED |
| RESEARCH | R2 | Replacement job identity; no worker task-ID assumption | 04 | COVERED |
| RESEARCH | R3 | Valid replay fixture, runtime index and retained history | 06 | COVERED |
| RESEARCH | R4 | Exact swap task and current prerequisites | 05,06 | COVERED |
| RESEARCH | R5 | Generation isolation, explicit invalid schema | 03,04,05 | COVERED |
| RESEARCH | R6 | Concrete non-vacuous commands, existing lanes, bounded browser grid | 01–08 | COVERED |
| RESEARCH | R7 | Direct images, real contrast/axe limits and diagnosable artifacts | 06,07,08 | COVERED |
| RESEARCH | R8 | Disposable reset/seed ownership distinct from preview4012 | 06,07,08 | COVERED |
| RESEARCH | R9 | Candidate/final closeout ordering with writable completion records | 08 | COVERED |

Deferred scope remains excluded: new public core APIs, frameworks/themes, host authorization product, new backend abstraction, broader matrices/new required job, paid judge, unrelated incidental repairs and Phase170 replay. No required item is missing.

## Discovery and correlation decision

Existing PATTERNS/research provide Level0 evidence for shared UI/navigation. One Level1 check confirmed the only unresolved seam: locked Oban2.23 emits job:start before perform in the same process; existing Scrypath task_wait:start emits task_uid. The private bounded Ops observer joins those synchronous events, then re-reads task/document truth. See [Oban2.23 executor](https://raw.githubusercontent.com/oban-bg/oban/v2.23.0/lib/oban/queue/executor.ex). No worker return-value change or public core API is needed.

Expected replay values are re-read from the authorized original failure payload and compared with the registered digest; do not retain raw payloads or credentials in the recent telemetry cache. Local telemetry capture can be unavailable for remote workers or after eviction/restart; these cases show unknown and cannot satisfy verified. The mounted same-node scenario proves the fully observed supported path.

Graph query reports disabled; no graph evidence is claimed. No project skills or codebase map exist. Agent skill map is empty. Relevant historical134/171 summaries inform theme-grid reuse and completion-before-attestation; they are not current runtime acceptance. Calibration returned factor0.5, samples9, confidence high; all estimates apply that factor.

## Needs / creates / dependency graph

| Plan/task | Needs | Creates/refines | Checkpoint |
| --- | --- | --- | --- |
| 01-1 | Existing shell/OpsUi/Control Room | Rendered readable-control and single-hint tracer | none |
| 01-2 | 01-1 role consumers |48component catalog/token/contrast assertions | none |
| 02-1 |01 shared controls | Semantic fields and Search behavior | none |
| 02-2 |02-1 fields/existing shell JS | Shared modal lifecycle/Playbooks/focus cases | none |
| 03-1 |01 shell | Strict selection and rendered handoffs | none |
| 03-2 |03-1 target identity | Compact triage/Posture cases | none |
| 04-1 |02 modal and03 context | Accepted-retry receipt and exact telemetry join | none |
| 04-2 |04-1 receipt | Authoritative task/document observation and UI states | none |
| 05-1 |04 observation/context | Shared current promotion predicate | none |
| 05-2 |05-1 predicate | Exact swap progress and ordinary check hierarchy | none |
| 06-1 |02–05 completed surfaces | Deterministic real recovery fixture/journey | none |
| 06-2 |06-1 exact IDs | Swap negative controls/first-failure diagnostics | none |
| 07-1 |01/02/05 shared role consumers | Final layer/motion/contrast contracts | none |
| 07-2 |06 oracle,07-1 final styles | Measured representative browser boundaries/images | none |
| 08-1 |01–07 runtime results | Internal/security/visual/requirements review | none |
| 08-2 |08-1 reviewed source | PR delivery/release decision/candidate evidence | none |
| 08-3 |08-2 passed candidate | Final completion commit then exact-source attestation | none |

Waves:1={01};2={02,03};3={04};4={05};5={06};6={07};7={08}. Wave2 file ownership is disjoint. Same-file work and service-global seeded browser work are sequential. One leading tracer covers the first user-visible shared UI slice; expansion tasks add real behavior and proof.

## UI consideration lift —50pairs,8explicit truths

Plan07 must_haves.truths contains all eight consolidated truths, with every applicable element listed. E1=shell/handoffs; E2=Posture/fleet; E3=FailedSync; E4=Sync/recovery/promotion; E5=Search; E6=Playbooks; E7=dialogs.

| Category | Elements | Pair count | Implemented/proved by |
| --- | --- | --- | --- |
| empty | E2,E3,E4,E5,E6,E7 |6|02/03/04 LiveView empty/setup cases;07 browser |
| loading | E1,E2,E3,E4,E5,E6,E7 |7|02/03/04/05 pending/duplicate/generation cases;07 |
| error | E1,E2,E3,E4,E5,E6,E7 |7|02/03/04/05 failed-read/mutation/input cases;06/07 |
| populated | E2,E3,E4,E5,E6 |5|02/03/05 visible state/object/action cases;06/07 |
| partial | E2,E3,E4,E5,E6,E7 |6|02/03/04 partial/correlation/queue cases;07 |
| overflow | E1,E2,E3,E4,E5,E6,E7 |7|07 assertOperatorGeometry at320/390 and bounded technical regions |
| zero-one-many | E2,E3,E4,E5,E6 |5|02/03 radio/select/count cases;07 six-reason≤160px |
| long-text | E1,E2,E3,E4,E5,E6,E7 |7|02/03 exact identity;07 readable long labels/filename/error geometry |

## Edge fallback disposition

The provided edge report had7 classified candidates and5 unclassified rows. No item is dismissed. Seven defensible predicates are lifted as explicit must-have truths; the five classifier gaps remain flagged assumptions, not silently resolved.

| Requirement/category | Disposition | Predicate / named evidence |
| --- | --- | --- |
| OPUX-01 empty | resolved explicit | Plan03/07 empty allowlist/setup distinct from healthy zero |
| OPUX-01 encoding | resolved explicit | Plan02/03/07 exact UTF-8 identity and wrapping |
| OPUX-02 empty | resolved explicit | Plan02 zero/one/four/five schema and empty file/import cases |
| OPUX-02 encoding | resolved explicit | Plan02 long UTF-8 label/filename value retained |
| OPUX-02 concurrency | resolved explicit | Plan02/07 one overlay owner/patch teardown/full focus cycle |
| OPUX-05 empty | resolved explicit | Plan04 empty/malformed/missing correlation→unknown, no verified |
| OPUX-05 encoding | resolved explicit | Plan04 exact encoded index/document identity |
| OPUX-03 unclassified | unresolved; flagged assumption A-03 | Manual classification assumes task hierarchy/copy/state boundaries; operator_ia_contract_test and six LiveView suites cover requirement |
| OPUX-04 unclassified | unresolved; flagged assumption A-04 | Manual classification assumes invalid/removed/non-first/back/refresh/context isolation; operator_selection_test and mounted journey |
| OPUX-06 unclassified | unresolved; flagged assumption A-06 | Manual classification assumes stale-task/wrong-document/replayability; operator.spec exact recovery and negative controls |
| OPUX-07 unclassified | unresolved; flagged assumption A-07 | Manual classification assumes layout/focus/theme/diagnostic proof; Plan07 named browser scenarios plus actual lane receipts |
| OPUX-08 unclassified | unresolved; flagged assumption A-08 | Manual classification assumes SHA/review/release/cleanup identity; canonical candidate/final closeout and requirement-evidence audit |

## Prohibition fallback

Precision pass retains two values constraints in Plan08 must_haves.prohibitions: preserve truthful failure history, and preserve historical evidence/reviewer identity. They were serialized with installed probe-core.projectProhibitions, without any check_* descriptor. Their fallback disposition remains flagged-unverified; runtime tests/reviews substantiate requirement claims but do not masquerade as wired prohibition enforcement. Ordinary atom/path/auth hygiene is covered by STRIDE and existing engineering checks, not minted as extra prohibitions.

## Scope probes

No new AI feature, ORM schema/migration or external-integration product is introduced. Private read-only Meilisearch document observation serves the already-approved existing backend flow. COVERAGE.md records the existing-integration declaration; no speculative full API-capability expansion is planned. Primary noun remains the selected allowed schema plus exact operation context; assumption-delta decision is no-change, because the existing product already supports multiple schemas and modes.

