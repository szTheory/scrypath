---
phase: 85-real-app-proof-and-drift-gates
verified: 2026-05-23T21:14:00Z
status: passed
score: 5/5 must-haves verified
overrides_applied: 0
deferred: []
---

# Phase 85: Real-App Proof And Drift Gates Verification Report

**Phase Goal:** prove the new composition seam through one canonical guide, two real-app proof flows, and a focused verification gate that catches public-story drift.
**Verified:** 2026-05-23T21:14:00Z
**Status:** passed
**Re-verification:** Yes — verified at milestone close from the checked-out tree with a fresh `mix verify.phase85` run.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Phase 85 has one canonical guide for composition, metadata, and multi-search semantics. | ✓ VERIFIED | `guides/composing-real-app-search.md` owns the v1.22 story in [guides/composing-real-app-search.md](/Users/jon/projects/scrypath/guides/composing-real-app-search.md:1), and docs-contract assertions pin it as the canonical authority in [test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs:156). |
| 2 | Root docs and reading order route readers from request-edge normalization into the canonical composition guide before the proof guides. | ✓ VERIFIED | Root docs and entrypoint guidance are wired in [lib/scrypath.ex](/Users/jon/projects/scrypath/lib/scrypath.ex:7), and docs contracts assert the ordering in [test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs:187). |
| 3 | The single-schema and multi-schema proof guides hang off the canonical story without implying generated UI or a fake merged capability surface. | ✓ VERIFIED | The faceted and multi-index guides explicitly route back to the canonical guide and keep host-owned boundaries visible in [guides/faceted-search-with-phoenix-liveview.md](/Users/jon/projects/scrypath/guides/faceted-search-with-phoenix-liveview.md:5) and [guides/multi-index-search.md](/Users/jon/projects/scrypath/guides/multi-index-search.md:5). |
| 4 | The public docs state the v1.22 non-goals plainly. | ✓ VERIFIED | The canonical guide explicitly lists no public `%Scrypath.Query{}`, no schema-generated runtime verbs, no generated UI widgets, and no tenant/authz or related-data guarantees in [guides/composing-real-app-search.md](/Users/jon/projects/scrypath/guides/composing-real-app-search.md:129), and docs contracts pin those strings in [test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs:161). |
| 5 | The phase has one focused maintainer gate that protects the full public story. | ✓ VERIFIED | `mix verify.phase85` runs composition, metadata, compose-many, docs contracts, and strict docs generation in [lib/mix/tasks/verify.phase85.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.phase85.ex:1), and the docs-contract suite asserts that wiring in [test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs:297). |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `guides/composing-real-app-search.md` | Canonical v1.22 composition and metadata authority | ✓ VERIFIED | Covers why composition exists, metadata reflection, multi-search lowering, and explicit non-goals. |
| `README.md`, `guides/overview.md`, `lib/scrypath.ex` | Short wayfinding into the canonical guide | ✓ VERIFIED | Root/docs entrypoints point readers into the canonical guide instead of competing with it. |
| `guides/faceted-search-with-phoenix-liveview.md` | Single-schema proof guide that stays host-owned and metadata-honest | ✓ VERIFIED | Explicitly cites `schema_capabilities/1`, `reflect_search/2`, and host-owned concerns. |
| `guides/multi-index-search.md` | Multi-schema proof guide that stays entry-scoped and boundary-honest | ✓ VERIFIED | Explicitly cites `compose_many/2`, shared-default semantics, and the tuple/shared-option contract. |
| `lib/mix/tasks/verify.phase85.ex` | Focused public-story drift gate | ✓ VERIFIED | Runs the exact test/docs lane needed for milestone-close proof. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Focused Phase 85 public-story gate | `mix verify.phase85` | `74 tests, 0 failures` plus successful `mix docs --warnings-as-errors` build | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `DOC-01` | `85-01-PLAN.md`, `85-02-PLAN.md`, `85-03-PLAN.md` | Guides and examples show real-app flows that reduce query glue while keeping contexts canonical and Phoenix optional. | ✓ SATISFIED | The canonical composition guide plus the faceted and multi-index proof guides establish the two flagship flows in [guides/composing-real-app-search.md](/Users/jon/projects/scrypath/guides/composing-real-app-search.md:77), [guides/faceted-search-with-phoenix-liveview.md](/Users/jon/projects/scrypath/guides/faceted-search-with-phoenix-liveview.md:17), and [guides/multi-index-search.md](/Users/jon/projects/scrypath/guides/multi-index-search.md:62). |
| `DOC-02` | `85-01-PLAN.md`, `85-02-PLAN.md`, `85-03-PLAN.md` | Docs keep the non-goals explicit: no public `%Scrypath.Query{}`, no schema-generated verbs, no generated UI, and no tenant/authz or related-data guarantees. | ✓ SATISFIED | The canonical non-goals section is explicit in [guides/composing-real-app-search.md](/Users/jon/projects/scrypath/guides/composing-real-app-search.md:129), and docs contracts pin the same boundary in [test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs:161). |
| `VRFY-01` | `85-02-PLAN.md`, `85-03-PLAN.md` | Verification fails on composition drift, metadata drift, multi-search parity drift, and guide-story drift. | ✓ SATISFIED | `mix verify.phase85` is the focused drift gate in [lib/mix/tasks/verify.phase85.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.phase85.ex:1), and the docs-contract suite asserts that exact wiring in [test/scrypath/docs_contract_test.exs](/Users/jon/projects/scrypath/test/scrypath/docs_contract_test.exs:297). |

No orphaned Phase 85 requirements were found in `.planning/REQUIREMENTS.md`.

### Gaps Summary

No Phase 85 closeout gaps remain. The public story is centralized, bounded, and protected by a single focused maintainer gate.

---

_Verified: 2026-05-23T21:14:00Z_  
_Verifier: Codex_
