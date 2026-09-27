---
phase: 166-host-tenant-and-repair-evidence
verified: 2026-09-27T14:12:19Z
status: passed
score: 5/5 must-haves verified
covered_files:

  - .planning/REQUIREMENTS.md
  - .planning/phases/166-host-tenant-and-repair-evidence/166-01-PLAN.md
  - .planning/phases/166-host-tenant-and-repair-evidence/166-01-SUMMARY.md
  - .planning/phases/166-host-tenant-and-repair-evidence/166-02-PLAN.md
  - .planning/phases/166-host-tenant-and-repair-evidence/166-02-SUMMARY.md
  - .planning/phases/166-host-tenant-and-repair-evidence/166-03-PLAN.md
  - .planning/phases/166-host-tenant-and-repair-evidence/166-03-SUMMARY.md
  - examples/phoenix_meilisearch/README.md
  - examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex
  - examples/phoenix_meilisearch/lib/scrypath_demo/blog/post.ex
  - examples/phoenix_meilisearch/priv/repo/migrations/20260927000000_add_host_memberships_and_post_tenants.exs
  - examples/phoenix_meilisearch/test/scrypath_demo/blog_tenant_search_test.exs
  - examples/phoenix_meilisearch/test/smoke/meilisearch_oban_stack_test.exs
  - examples/phoenix_meilisearch/test/smoke/meilisearch_related_inline_stack_test.exs
  - examples/phoenix_meilisearch/test/smoke/meilisearch_related_oban_stack_test.exs
  - examples/phoenix_meilisearch/test/smoke/meilisearch_stack_test.exs
  - examples/phoenix_meilisearch/test/smoke/meilisearch_tenant_stack_test.exs
  - examples/phoenix_meilisearch/test/support/meilisearch_test_index.ex
  - test/scrypath/live_operator_verification_test.exs

covered_digest: "v1:sha256:917ae3c28768ecf4963d358f7661621de8dbb11a783f906bf6be31c77fca3415"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 166: Host Tenant and Repair Evidence Verification Report

**Phase Goal:** A Phoenix host can demonstrate one authorized tenant-search workflow and one bounded repair through visible search without broadening product or CI scope.
**Verified:** 2026-09-27T14:12:19Z
**Status:** passed

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | The named Phoenix host derives tenant scope from persisted membership and rejects missing membership, unowned tenant selection, and caller-controlled scope/runtime input before dispatch. | ✓ VERIFIED | `blog.ex` derives scope through the persisted actor/membership join, validates allowlisted inputs, and hydrates by tenant plus returned IDs. Recorder cases prove rejected input produces no search/facet dispatch; the named live scenario passed. Authentication and trusted-principal creation remain host-owned. |
| 2 | In the selected mixed-tenant scenario, both authorized tenants see their permitted raw IDs, separately scoped hydrated rows, counts, categories, and facet values without the other tenant's marker. | ✓ VERIFIED | `meilisearch_tenant_stack_test.exs` checks A and B symmetrically, including raw IDs, `totalHits`, hydration, categories, facet values, and marker exclusion. The named Postgres/Meilisearch path scenario passed in local and hosted execution. |
| 3 | The same named host scenario succeeds through the path dependency and a fresh local package artifact, while C-09 is reused only for its bounded hard-delete claim after relevant-path review. | ✓ VERIFIED | `166-EVIDENCE.json` binds path, package, and root repair receipts to implementation SHA `50d5c12d36ec560525e245bcb992c40e5927854f`, run `36321613553`, and named jobs/markers. Package provenance is a freshly built locally tagged artifact, not Hex publication. The C-09 comparison accounts for all 16 relevant changed paths and preserves its raw-hit claim limits. |
| 4 | The operator can observe the known mismatch without mutation and restrict manual repair to an explicit Ecto ID selection while controls remain unchanged. | ✓ VERIFIED | `live_operator_verification_test.exs` calibrates request observation, compares full task snapshots around report-only reconcile, applies `where id in selected_ids`, and preserves source-only and already-visible controls. The hosted backend job contains the named repair scenario. |
| 5 | Each returned repair task reaches terminal success on the selected index, then the same Scrypath query returns the selected raw ID and projection; one repeat succeeds and an empty selection submits no task. | ✓ VERIFIED | The integration test asserts both task UIDs, success states and index IDs independently from the raw search result, repeats the fixed selection with a new task, and asserts empty selection makes no requests. `166-EVIDENCE.json` records the hosted task and raw-result observations. |

**Score:** 5/5 phase success criteria verified (0 behavior-unverified).

## Required Artifacts

| Artifact | Expected | Status | Evidence |
|----------|----------|--------|----------|
| `blog.ex`, Post schema, and additive migration | Membership-derived host scope, scoped hydration, projected tenant/category fields, persisted test membership | ✓ EXISTS + SUBSTANTIVE | Source paths and recorder/live tests listed in the plan and validation map. |
| Host recorder and live integration scenarios | Pre-dispatch rejection plus A/B raw, hydration, count, and facet proof | ✓ EXISTS + SUBSTANTIVE | Recorder suite and named `authorized tenant search and facet values` scenario; path and package receipts recorded. |
| Root repair integration scenario | Read-only report, ID-bounded repair, exact task and raw-search controls | ✓ EXISTS + SUBSTANTIVE | Named `bounded manual repair restores the selected raw document` scenario and empty-selection case. |
| `166-EVIDENCE.md` and `.json` | Source-bound host/path/package/repair receipts and bounded C-09 disposition | ✓ EXISTS + SUBSTANTIVE | Schema-checked receipt record with run/job identities, safe scenario output, source comparison, and claim limits. |
| `166-VALIDATION.md` and `166-SECURITY.md` | Task-level validation mapping and resolved ASVS L1 threat register | ✓ EXISTS + SUBSTANTIVE | Six task rows remain backed by pass evidence; all 16 planned threats have a documented disposition and `threats_open: 0`. |

**Artifacts:** 5/5 verified.

## Key Link Verification

| From | To | Via | Status | Evidence |
|------|----|-----|--------|----------|
| Host membership context | Public Scrypath search/facet APIs | Trusted membership scope plus allowlisted inputs | ✓ WIRED | Recorder assertions inspect the composed tenant/status/category filters; live scenario runs the public functions. |
| Host raw search results | Postgres hydration | Tenant and returned-ID predicates | ✓ WIRED | Source query and separate raw/hydrated assertions prove neither layer masks the other. |
| Repair integration test | Public backfill and task waiter | Explicit selected-ID Ecto query and exact returned task references | ✓ WIRED | Test asserts document/batch counts, UIDs, terminal states, expected index, and same-query raw visibility. |
| Evidence JSON | Named scenarios and historical C-09 source | Source/run/job metadata and full relevant-path comparison | ✓ WIRED | Validation and evidence records map every receipt and every changed relevant path. |

**Wiring:** 4/4 connections verified.

## Regression Gate

`ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix test --exclude integration --exclude docs_contract` passed in 22.8 seconds: 591 tests, 0 failures (84 excluded). The result includes Phase 165's tenant and facet contract suites. Phase 166's service-backed acceptance is supported by its recorded exact-source hosted receipts; this run does not claim to rerun the external service scenarios.

## Requirements Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| HOST-01 | ✓ SATISFIED | Persisted membership, trusted host scope, and pre-dispatch rejection tests; bounded synthetic-principal claim. |
| HOST-02 | ✓ SATISFIED | Mixed-tenant raw hits, hydration, counts, categories, and facets for both positive-control tenants. |
| PKG-04 | ✓ SATISFIED | Same named host scenario passed against the repository path and fresh local artifact at the recorded source. |
| REPAIR-01 | ✓ SATISFIED | No-write mismatch observation followed by explicit ID-scoped manual repair with unchanged controls. |
| REPAIR-02 | ✓ SATISFIED | Exact task success/index and same-query raw projection, successful repeat, and empty-query no-op. |
| DELETE-01 | ✓ SATISFIED | Reused only the historical raw-hit hard-delete claim after all 16 relevant changes were semantically dispositioned. |

**Coverage:** 6/6 Phase 166 requirements satisfied.

## Scope Limits Preserved

The 11 unresolved assumption probes and six descriptor-less prohibitions remain explicit for Phase 167. This verification does not claim Scrypath authentication, generic adopter policy, public registry package installation, broad backfill boundaries, exactly-once/concurrent recovery, or deletion behavior beyond the recorded hard-delete workflow. The newly dated six-condition readiness decision remains Phase 167 work.

## Human Verification Required

None. Every Phase 166 software acceptance criterion has automated scenario evidence or an exact-source hosted receipt; no routine post-implementation UAT is required.

## Gaps Summary

**No phase-goal gaps found.** The implemented host workflow and bounded repair evidence meet Phase 166's success criteria. Explicitly unresolved broader probes remain out of scope and are carried forward without being reclassified as passes.

## Verification Metadata

**Verification approach:** Goal-backward against the roadmap success criteria and plan must-haves.
**Automated checks:** Regression suite passed; named service scenarios passed at recorded exact implementation source.
**Human checks required:** 0.
**Verifier:** Codex orchestrator, inline execution.

---
*Verified: 2026-09-27T14:12:19Z*
