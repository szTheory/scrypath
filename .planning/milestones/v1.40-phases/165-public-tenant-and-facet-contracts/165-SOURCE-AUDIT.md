# Phase 165 — Source Coverage and Planning Audit

**Status:** Planned, not executed. **Source checkout observed:** `e8c579e6c0229456da0ca9185e25c424ab4ba320`.
No public contract has been classified as passing or defective by planning.

## Multi-source coverage

| Source | ID | Feature / constraint | Plan / task | Status | Notes |
|---|---|---|---|---|---|
| GOAL | Phase 165 | Existing public tenant and facet contracts with compatible corrections only after reproduction | 165-01, 165-02 | COVERED | Independent recorder and public HTTP proof |
| REQ | API-01 | Tenant plus ordinary filter through single, shared multi-search, facet; collision/undeclared rejection before dispatch | 165-01-01/02 | COVERED | Equal-valued collision and valid-then-invalid preflight included |
| REQ | API-02 | Public facet defaults and nonempty keyword filters produce endpoint-valid requests | 165-02-01/02 | COVERED | Real adapter and encoded Req.Test body; current error behavior |
| RESEARCH | Architecture | Schema validation owns composition, orchestration owns runtime separation, client/renderer owns backend grammar | Both plans | COVERED | Conditional source ownership stays in these existing tiers |
| RESEARCH | C10-R1 | Source hypothesis requires each public runtime boundary to execute | 165-01-01/02 | COVERED | Shared multi-search is explicit; success also closes a hypothesis |
| RESEARCH | C11-R1 | Defaults and keyword inputs require independent public-entry classification | 165-02-01/02 | COVERED | Neither depends on tenant input or the tenant test fixture |
| RESEARCH | Parser | Pinned Meilisearch 1.15 ignores unknown search parameters | 165-02-01 | COVERED | No deny-unknown-fields oracle or predeclared defaults defect |
| RESEARCH | Compatibility | Preserve path-specific ArgumentError, multi validation wrapper, HTTP/transport tuple and bang reason | 165-01-02, 165-02-02 | COVERED | Explicit zero-dispatch/request-count assertions |
| RESEARCH | Rendering | Reuse existing grammar/literal encoding and retain rendered-client compatibility | 165-02-02 | COVERED | One escaping example only if reuse seam changes; existing range tests |
| RESEARCH | Fixtures | Real schema metadata, local recorder hooks, existing Req.Test, synthetic data, no framework install | Both tracers | COVERED | Process-local fixtures; no global support extension |
| RESEARCH | Verification | Independent focused commands, historical scoped gates, consolidated core, conditional existing backend policy | Both verification blocks | COVERED | New files run explicitly; core already includes fast suite |
| RESEARCH | Evidence | Exact source identity, baseline output, corrected output, timing and precise limits | Both output sections | COVERED | Local proof stays distinct from hosted closeout |
| RESEARCH | Handoff | Facet service/package implication depends on actual supported failure | 165-02-02 | COVERED | Only the reproduced scenario is handed to Phase 166 |
| CONTEXT | D-01 | Fixed approved API scope; preserve public contract | Both plans | COVERED | No broad facet/settings/backend matrix |
| CONTEXT | D-02 | Supplied-scope composition; declaration/collision checks; host ownership | 165-01-01/02, 165-02-02 | COVERED | One joined tenant/filter HTTP regression; no auth product |
| CONTEXT | D-03 | Public facet boundary is mandatory | 165-02-01/02 | COVERED | Lower-client tests supplement, never replace |
| CONTEXT | D-04 | Hypotheses distinct from reproduction/pass/insufficient evidence | All tasks | COVERED | No manufactured RED when baseline passes |
| CONTEXT | D-05 | Smallest deterministic boundary proof; independent commands; conditional service evidence | Both plans | COVERED | Recorder and Req.Test only |
| CONTEXT | D-06 | Reproduced compatible fix and regression; preserve errors; bounded verification | All tasks | COVERED | Conditional source edits; no new lane/UAT/release |
| CONTEXT | D-07 | Reuse approved research; reopen only concrete compatibility question | Both plans | COVERED | No new survey |

Excluded by source authority: host identity/membership/database policy, repair/delete/service jobs owned by Phase 166, readiness/closeout reconciliation owned by Phase 167, operator UI, auth framework, new public backend/API categories, broad matrices and forced publication. These are not unplanned Phase 165 requirements.

## Dependency graph and file ownership

| Task | Needs | Creates / proves | Checkpoint |
|---|---|---|---|
| 165-01-01 | Existing public facade, metadata, recorder pattern | One passing single-search tenant tracer and baseline classification | No |
| 165-01-02 | 165-01-01 local fixture and passing tracer | Other public paths, shared options, complete preflight and rejection proof | No |
| 165-02-01 | Plan 01 complete to serialize phase execution | Independent public default facet HTTP tracer | No |
| 165-02-02 | 165-02-01 HTTP fixture; Plan 01 tenant facet behavior | Independent keyword/error proof plus one joined tenant/status HTTP assertion | No |

Wave 1: `165-01`. Wave 2: `165-02`. Each plan has two tasks; no task reserves more than three modified files. The only producer/consumer dependency between the proof units is the joined public tenant/status HTTP assertion. The two primary contract files can still execute independently; they share no test fixtures or global mutable state. Production file reservations are conditional.

## Discovery, grounding, calibration

- Level 0 applies: existing ExUnit recorder/Req.Test/schema patterns are documented in 165-PATTERNS; no new library or architecture is selected. Current 165-RESEARCH already resolves the narrow pinned-parser question. No repeated ecosystem research is necessary.
- `git ls-files` confirms the existing source/analog paths referenced in the plans are tracked. The two explicitly new test paths live in the existing `test/scrypath/` tree. No installed runtime mirror is an edit target.
- The installed OpenGSD runtime identifies as `@opengsd/gsd-core 1.14.0`. Init/state loaded the active Phase 165, API-01/API-02 and no prior proven verify commands.
- Command paths are rooted in this repository's Mix project; contributor tasks are named in CONTRIBUTING. Research demonstrated the command-local Elixir 1.19.5/OTP 28 overrides. No test timing or passing implementation result is asserted.
- `estimate-calibration`: factor 1, sample_count 0, confidence low. Raw/calibrated estimates are 22,000 for Plan 01 and 26,000 for Plan 02; two tasks each.
- No project skills directory or planning graph exists. Configured agent_skills is empty. The supplied agent-skills payload contains the planner role rather than additional skill entries.
- History retained: Phase 164's completed assessment stays historically NOT READY and its structural checker proves only record shape. The quality ledger preserves lean contributor gates, internal orchestration separation, and existing renderer/transport ownership. Historical prompts inform explicit Elixir/Ecto boundaries; their older backend recommendation is superseded.
- Consequential choices are reversible: local tests and internal corrections preserve existing syntax and error contracts. No migration, new public contract, external-service lock-in, or one-way decision is planned.

## Spec-less edge probe

The six detector items are accounted for below. A resolution is an authored assertion, not an executed pass.

| Requirement | Category | Planning disposition | Verification / explicit flagged assumption |
|---|---|---|---|
| API-01 | adjacency | resolved / explicit | Existing same-key collision rejects even when the tenant value equals tenant_scope; Plan 01 truth and task 02 negative cases. |
| API-01 | empty | resolved / explicit for ordinary filters | Omitted/empty filter preserves the supplied scope; one status predicate composes. Plan 01 truth and task 02. Null tenant identity is separately flagged below. |
| API-01 | ordering | unresolved | **EA-01:** API-01 promises conjunction and rejection, not filter-list ordering or new result tie ordering. Compare predicate meaning; preserve existing ordering behavior without making a new stability claim. |
| API-02 | boundary | dismissed | The numeric cue is the pinned 1.15 service version, not a min/max input contract. No threshold, range boundary or new numeric limit is introduced. Named defaults/nonempty filter boundaries are explicitly covered. |
| API-02 | precision | dismissed | No arithmetic, rounding or overflow behavior is added by this phase. Existing literal rendering remains the authority; service-side numeric precision is not claimed by Req.Test. |
| API-02 | concurrency | unresolved | **EA-02:** The selected oracle proves synchronous request construction and bounded no-fallback error behavior; interruption/parallel backend execution semantics remain unclaimed and outside D-01/D-05/D-06. |

**EA-03 — Null/absent tenant policy remains unresolved as a host concern:** source declares tenant_scope as optional `:any`; this phase must not invent a requirement to reject nil, require a tenant for every search, or authenticate its identity. The empty-filter assertion does not settle null-tenant semantics. Carry this precise limit into the execution summary. No new policy test or human checkpoint is implied.

The unresolved items are explicit claim limits, not permission to weaken composition, request-shape or error acceptance. No unrelated property suite is introduced.

## Spec-less prohibition probe — recall then precision

Stage 1 asked of each requirement: what could this silently become that the author would not want?

| Requirement | Raw recall candidates |
|---|---|
| API-01 | Authorization certification from a recorder; host identity policy moved into Scrypath; synthetic input presented as membership proof; broad backend claim; dropped filter; mutated input; wrong schema dispatch; accidental ranking promise; generic injection; real tenant data in fixtures |
| API-02 | Req.Test presented as live acceptance; manufactured rejection of ignored defaults; automatic service/package/release expansion; new common API semantics; malformed JSON; wrong route; changed error tuples; fallback request; duplicated renderer; generic injection |

Stage 2 precision:

- Routine correctness items (filter retention, mutation, schema/route/JSON correctness, ordering, error shapes, fallback counts and duplicate rendering) belong to ordinary acceptance/edge checks, not new prohibitions.
- Generic injection and sensitive-data handling are canon: refer to the scoped threat models and `$gsd-secure-phase`; no duplicate prohibition or JavaScript security tool is minted for this Elixir phase.
- Fixed scope already excludes moving host policy into the library and new API/backend breadth. Preserve those decisions without new implementation work.
- Two bespoke transparency prohibitions remain: supplied-scope proof must not become an authorization claim; request-construction proof must not become live/general compatibility or an unconditional escalation claim.

These two retained items are projected into their respective plan `must_haves.prohibitions` with status unresolved, verification null, and no `check_*` descriptors. They are explicit evidence-review flags. The planner did not fabricate a wired test, convert them to automatic approval, or add routine human UAT. Their resolution needs the actual execution evidence and semantic claim review.

## Capability contributions

- API coverage detector returned detected true on final scope for generic API-surface wording. COVERAGE.md records a reasoned no-new-integration declaration: this phase verifies/corrects existing contracts, with no new endpoint/service capability and no fabricated Meilisearch matrix.
- Assumption-delta detector returned detected false; no identity-model checkpoint.
- Schema-push detection found no matching ORM patterns; no database push.
- Security enforcement: ASVS level 1, high threshold. Plan 01 owns tenant composition/rejection; Plan 02 owns request/filter/error boundaries.
- UI detector is false; no UI design contract. Context drift found no stale inputs.

## Artifact validation

Both plan files passed OpenGSD frontmatter.validate with schema plan and verify.plan-structure: valid true, two tasks each, no missing fields, errors, or warnings. These are planning-structure results only. No library source was changed, no implementation tests were run, and no documentation commit was made by the planner.
