---
phase: 166-host-tenant-and-repair-evidence
verified: 2026-09-27T23:53:07Z
status: passed
score: 5/5 roadmap success criteria verified
covered_files:
  - .planning/REQUIREMENTS.md
  - .planning/phases/166-host-tenant-and-repair-evidence/166-01-PLAN.md
  - .planning/phases/166-host-tenant-and-repair-evidence/166-01-SUMMARY.md
  - .planning/phases/166-host-tenant-and-repair-evidence/166-02-PLAN.md
  - .planning/phases/166-host-tenant-and-repair-evidence/166-02-SUMMARY.md
  - .planning/phases/166-host-tenant-and-repair-evidence/166-03-PLAN.md
  - .planning/phases/166-host-tenant-and-repair-evidence/166-03-SUMMARY.md
  - .planning/phases/166-host-tenant-and-repair-evidence/166-EVIDENCE.json
  - .planning/phases/166-host-tenant-and-repair-evidence/166-EVIDENCE.md
  - .planning/phases/166-host-tenant-and-repair-evidence/166-REVIEW.md
  - examples/phoenix_meilisearch/README.md
  - examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex
  - examples/phoenix_meilisearch/lib/scrypath_demo/blog/post.ex
  - examples/phoenix_meilisearch/priv/repo/migrations/20260927000000_add_host_memberships_and_post_tenants.exs
  - examples/phoenix_meilisearch/test/scrypath_demo/blog_tenant_search_test.exs
  - examples/phoenix_meilisearch/test/smoke/meilisearch_tenant_stack_test.exs
  - examples/phoenix_meilisearch/test/smoke/meilisearch_oban_stack_test.exs
  - examples/phoenix_meilisearch/test/smoke/meilisearch_related_inline_stack_test.exs
  - examples/phoenix_meilisearch/test/smoke/meilisearch_related_oban_stack_test.exs
  - examples/phoenix_meilisearch/test/smoke/meilisearch_stack_test.exs
  - examples/phoenix_meilisearch/test/support/meilisearch_test_index.ex
  - test/scrypath/live_operator_verification_test.exs
covered_digest: "v1:sha256:9af7ff511b087f039c4bd6939063a3c8df4adf9a970026266dab179e52fe19c2"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 166: Host Tenant and Repair Evidence Verification Report

**Phase Goal:** A Phoenix host can demonstrate one authorized tenant-search workflow and one bounded repair through visible search without broadening product or CI scope.
**Verified:** 2026-09-27T23:53:07Z
**Status:** passed
**Re-verification:** No — initial-mode refresh; the prior report had no `gaps:` section.

## Goal Achievement

### Observable Truths

| # | Roadmap truth | Status | Evidence |
|---|---|---|---|
| 1 | The named host derives scope from trusted actor membership and rejects missing membership, forged selection, and caller-controlled overrides before search. | ✓ VERIFIED | Current `Blog` context performs a persisted actor/membership join, validates allowlisted params, constructs tenant/filter options, and dispatches only afterward. Current recorder test exercises an authorized positive control and invalid principal, unowned tenant, string/atom override, and malformed-input rejection with no dispatch. Local run: 5 tests, 0 failures. The synthetic principal represents upstream authentication; no Scrypath authentication claim is made. |
| 2 | The mixed-tenant workflow exposes only permitted IDs and metadata, with the second tenant as a positive control and no foreign marker in raw hits, hydration, counts, or facets. | ✓ VERIFIED | The live scenario independently asserts raw hits, total hits, host records, categories, facet values, and foreign/draft-marker absence for A and B. Exact hosted path receipt at source `50d5c12d36ec560525e245bcb992c40e5927854f`, run `36321613553`, Phoenix job `108626420623`, records 16 tests/0 failures and the named marker. Current local Meilisearch was unavailable, so this hosted receipt—not a local rerun—is the service evidence. |
| 3 | The named flow passes through repository path and fresh package artifact; C-09 reuse is limited to a source-reviewed bounded claim or recorded unknown. | ✓ VERIFIED | Run `36321613553`, job `108626420623`, contains successful path and package executions at `50d5c12d36ec560525e245bcb992c40e5927854f`; package provenance is a freshly built local artifact resolved through a temporary tagged Git dependency, not Hex/public registry installation. The historical delete receipt remains tied to `dc400b2b57aec0ca6b0ef16c9477d266fd41a433`; its comparison source is `50d5c12d36ec560525e245bcb992c40e5927854f`. The 16-path ledger bounds reuse to the ecommerce hard-delete raw-hit claim. No receipt is reassigned to the later source. |
| 4 | The operator observes a known mismatch without mutation and bounds manual backfill with an explicit Ecto ID predicate, preserving controls. | ✓ VERIFIED | Current repair test uses `where id in ^selected_ids`, observes reconcile requests and task snapshots, and checks source-only/already-visible controls. Exact-source hosted backend receipt in run `36321613553`, job `108626420717`, records 3 reads/0 mutations and the selected ID. |
| 5 | The exact returned task succeeds on the expected index and the same search shows the repaired projection while controls remain correct. | ✓ VERIFIED | The live test correlates returned task UIDs to succeeded state and index, then checks the same raw query; it also tests one fixed-scope repeat and empty-selection no-op. Hosted receipt records task UIDs 31/32 succeeded on `scrypath-op-5154_queryable_post`, target ID `166000040`, and 4 tests/0 failures at source `50d5c12d36ec560525e245bcb992c40e5927854f`. |

**Score:** 5/5 roadmap truths verified (0 behavior-unverified).

### Required Artifacts and Wiring

| Artifact/link | Status | Evidence |
|---|---|---|
| Persisted actors/memberships and additive tenant/category migration | ✓ VERIFIED | Migration defines non-null membership foreign key, tenant ID, unique actor/tenant index, and nullable post tenant/category columns; DataCase recorder tests insert and query the persisted rows. |
| Host tenant search and facet context | ✓ VERIFIED | Public `Scrypath.search/3` and `search_facet_values/4` receive freshly assembled membership-derived options. Host hydration queries by tenant AND returned IDs and retains the original raw response. |
| Mixed-tenant live scenario | ✓ VERIFIED | Test creates declared filter/facet settings, awaits setup and write tasks, queries B as a positive control, then asserts A/B raw, hydrated, count, ordinary-facet, and facet-value results. Success marker is emitted after assertions. |
| Bounded repair scenario | ✓ VERIFIED | Public backfill consumes an explicit Ecto selection; each actual returned task is awaited and checked before the same public search is used as visibility oracle. Existing backend runner names this test module. |
| Exact-source evidence record | ✓ VERIFIED | `166-EVIDENCE.json` ties every host/package/repair run and job to source `50d5c12d36ec560525e245bcb992c40e5927854f`, includes safe named output, and preserves runtime, service, and package provenance. |

### Current-source identity check

The receipts are not current-HEAD receipts. `50d5c12` is their measured implementation source; the final-source SHA is `03d8e63de5f0c60e5bd46d29ba375b1770b6b7cc`; current HEAD is `106e158b18f70eefd3a0b99a2620615a5e0670fb`. The relevant source-path diff from `50d5c12` to `03d8e63` contains no implementation changes (the added Phase 166 review report is documentation); `03d8e63..HEAD` adds no relevant source change. Thus the receipts remain applicable to the same implementation, while their source identity remains `50d5c12`. This report does not claim the hosted service scenarios ran at `03d8e63` or `106e158`.

### Focused Local Checks

| Behavior | Command/result | Status |
|---|---|---|
| Persisted-membership policy, rejection-before-dispatch, raw/hydration separation | `cd examples/phoenix_meilisearch && ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix test test/scrypath_demo/blog_tenant_search_test.exs --trace` — 5 tests, 0 failures | ✓ PASS |
| Public tenant-scope and facet filter contracts | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix test test/scrypath/tenant_scope_contract_test.exs test/scrypath/facet_values_contract_test.exs` — 17 tests, 0 failures | ✓ PASS |
| Local service-backed rerun | Existing service ports 55433 (Postgres 16) and 7700 (Meilisearch 1.15) were closed; no service was started. Hosted exact-source receipts above remain the service evidence. | ? NOT RUN |

### Requirements Coverage

| Requirement | Status | Evidence and claim boundary |
|---|---|---|
| HOST-01 | ✓ SATISFIED | Persisted membership-derived scope and pre-dispatch rejection in the named Phoenix host only; authentication remains upstream. |
| HOST-02 | ✓ SATISFIED | Selected deterministic mixed-tenant corpus with independently asserted raw/hydrated/count/facet surfaces and positive control. |
| PKG-04 | ✓ SATISFIED | Same named scenario passed against repository path and a fresh local package artifact at `50d5c12`; not public registry installation. |
| REPAIR-01 | ✓ SATISFIED | Known mismatch is a fixture precondition; report path is read-only and selected-ID predicate bounds the one repair workflow. |
| REPAIR-02 | ✓ SATISFIED | Exact tasks, terminal state, expected index, visible raw projection, bounded repeat, and empty-selection no-op are recorded. |
| DELETE-01 | ✓ SATISFIED | Historical receipt reused only at its own SHA after the documented 16-path semantic comparison; claim remains limited to the specified ecommerce hard-delete workflow. |

No additional Phase 166 requirements are mapped in `.planning/REQUIREMENTS.md`.

### Anti-patterns and Probes

No unreferenced `TBD`, `FIXME`, or `XXX` debt marker, placeholder, or empty implementation was found in the reviewed implementation/test files. Phase 166 declares no standalone `probe-*.sh`; no probe claim is substituted for the named integration receipts.

### Preserved Claim Limits

The plans' 11 assumption probes and six descriptor-less prohibitions remain unresolved and are carried into Phase 167 as explicit limits; this report does not convert them into broad guarantees. In particular, the evidence does not establish general adopter authorization, public package publication, general repair boundaries, exactly-once/concurrent recovery, broad deletion semantics, or all service/version combinations. The clean `166-REVIEW.md` contains no findings. No post-implementation UAT is required by the project workflow, and no UAT artifact was created.

### Gaps Summary

No Phase 166 roadmap success criterion or mapped requirement is contradicted by the current implementation or source-bound evidence. The local live-service rerun was unavailable; the exact-source hosted receipts and unchanged relevant implementation paths provide the bounded service evidence. Broader unresolved probes/prohibitions remain carry-forward limits, not claims of universal behavior.

---

_Verified: 2026-09-27T23:53:07Z_  
_Verifier: gsd-verifier_
