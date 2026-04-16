---
phase: 05-reindexing-and-operational-workflows
verified: 2026-04-16T00:00:00Z
status: human_needed
score: 4/4 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Run an end-to-end rebuild against a real Meilisearch instance"
    expected: "`Scrypath.reindex/2` creates the target index, applies settings, backfills batches, and leaves the live index untouched when `cutover?: false`."
    why_human: "This phase includes external-service behavior. Verification here used focused tests and code traces, not a live Meilisearch server."
  - test: "Read the operator docs as a user"
    expected: "README and ARCHITECTURE clearly distinguish backfill vs reindex, accepted work vs search-visible completion, drift signals, cutover behavior, and recovery steps."
    why_human: "Operational clarity and wording quality are product-surface concerns that cannot be fully proven by grep or unit tests."
---

# Phase 5: Reindexing and Operational Workflows Verification Report

**Phase Goal:** Make rebuilds, cutovers, and recovery workflows safe enough for real systems.
**Verified:** 2026-04-16T00:00:00Z
**Status:** human_needed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A developer can backfill existing records into a fresh or rebuilt index. | ✓ VERIFIED | `Scrypath.backfill/2` delegates to `Scrypath.Backfill.run/2` in `lib/scrypath.ex`; backfill validates options, batches by primary key, and writes through the configured backend in `lib/scrypath/backfill.ex`; focused coverage in `test/scrypath/backfill_test.exs`. |
| 2 | A developer can run a managed reindex workflow instead of composing one manually. | ✓ VERIFIED | `Scrypath.reindex/2` delegates to `Scrypath.Reindex.run/2` in `lib/scrypath.ex`; `lib/scrypath/reindex.ex` performs ordered create -> settings -> backfill -> optional cutover orchestration; order and result contract are covered in `test/scrypath/reindex_test.exs`. |
| 3 | Index settings are applied intentionally as part of operational workflows. | ✓ VERIFIED | Schema settings are declared and reflected through `lib/scrypath/schema.ex`, `lib/scrypath/options.ex`, and `lib/scrypath.ex`; Meilisearch settings resolution and application are implemented in `lib/scrypath/meilisearch/settings.ex`; explicit lifecycle helpers are wired in `lib/scrypath/meilisearch/index_management.ex`, `lib/scrypath/meilisearch.ex`, and `lib/scrypath/meilisearch/client.ex`; tests cover settings application and target-index overrides in `test/scrypath/schema_test.exs`, `test/scrypath/options_test.exs`, and `test/scrypath/meilisearch_test.exs`. |
| 4 | Official docs explain drift detection, rebuild strategy, and recovery expectations. | ✓ VERIFIED | `README.md` documents backfill vs reindex, drift signals, cutover semantics, eventual consistency, and recovery; `ARCHITECTURE.md` documents the fixed workflow order, target-index safety, drift causes, and recovery semantics. |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/scrypath/options.ex` | Phase 5 schema and operational option validation | ✓ VERIFIED | Declares `settings`, `@backfill_options`, `@reindex_options`, and dedicated validators with bulk sync-mode rejection. |
| `lib/scrypath/schema.ex` | Persist schema settings metadata | ✓ VERIFIED | Exposes `__scrypath__(:settings)` from persisted schema config. |
| `lib/scrypath.ex` | Public reflection, backfill, and reindex entrypoints | ✓ VERIFIED | Wires `schema_settings/1`, `backfill/2`, and `reindex/2` to implementation modules. |
| `lib/scrypath/backfill.ex` | Deterministic repo-driven batching | ✓ VERIFIED | Orders by primary key, uses cursor-based `where > last_seen`, projects documents, and delegates writes to backend. |
| `lib/scrypath/reindex.ex` | Managed rebuild orchestration | ✓ VERIFIED | Validates options, computes target index, applies settings before backfill, and conditionally cuts over. |
| `lib/scrypath/meilisearch/client.ex` | Concrete create/settings/swap endpoints | ✓ VERIFIED | Implements `/indexes`, `/indexes/:uid/settings`, and `/swap-indexes` requests. |
| `lib/scrypath/meilisearch/index_management.ex` | Live/target index naming and lifecycle helpers | ✓ VERIFIED | Computes explicit live/target names and delegates create/swap through the client. |
| `lib/scrypath/meilisearch/settings.ex` | Schema settings resolution and application | ✓ VERIFIED | Merges schema-declared settings with runtime overrides and applies them to an explicit index. |
| `README.md` | Operator-facing workflow documentation | ✓ VERIFIED | Contains dedicated Backfill/Reindex, Drift Detection, Cutover/Eventual Consistency, and Recovery sections. |
| `ARCHITECTURE.md` | Internal explanation of workflow order and recovery semantics | ✓ VERIFIED | Documents explicit boundaries, fixed reindex order, and drift/recovery semantics. |
| `test/scrypath/options_test.exs` | Option-contract proof | ✓ VERIFIED | Covers required keys, cutover contract, settings overrides, and `:oban` rejection. |
| `test/scrypath/schema_test.exs` | Settings reflection proof | ✓ VERIFIED | Covers stored settings metadata and compile-time validation failures. |
| `test/scrypath/backfill_test.exs` | Backfill workflow proof | ✓ VERIFIED | Covers explicit API, query override, bounded batching, exact page boundaries, and target index override. |
| `test/scrypath/reindex_test.exs` | Reindex workflow proof | ✓ VERIFIED | Covers ordered operations, `cutover?: false`, and result fields. |
| `test/scrypath/meilisearch_test.exs` | Meilisearch lifecycle proof | ✓ VERIFIED | Covers create index, settings update, swap indexes, and target-index usage. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `lib/scrypath.ex` | `lib/scrypath/backfill.ex` | `Scrypath.backfill/2 -> Scrypath.Backfill.run/2` | ✓ WIRED | Public common-path backfill entrypoint exists and delegates directly. |
| `lib/scrypath/backfill.ex` | backend writes | `backend.upsert_documents/3` | ✓ WIRED | Batch loop projects records then calls backend with explicit `index_name` override. |
| `lib/scrypath/backfill.ex` | repo reads | `repo.all/1` on ordered query | ✓ WIRED | Reads through explicit repo with PK ordering and cursor progression. |
| `lib/scrypath.ex` | `lib/scrypath/reindex.ex` | `Scrypath.reindex/2 -> Scrypath.Reindex.run/2` | ✓ WIRED | Public reindex entrypoint exists and delegates directly. |
| `lib/scrypath/reindex.ex` | `lib/scrypath/meilisearch.ex` | create -> apply settings -> swap | ✓ WIRED | Managed workflow calls explicit Meilisearch lifecycle helpers in order. |
| `lib/scrypath/reindex.ex` | `lib/scrypath/backfill.ex` | `backfill.run/2` against target index | ✓ WIRED | Reindex hands the explicit target index to backfill. |
| `lib/scrypath/meilisearch/settings.ex` | `lib/scrypath/meilisearch/client.ex` | `update_settings/3` | ✓ WIRED | Resolved settings are sent to explicit index-scoped settings endpoint. |
| `lib/scrypath/meilisearch/index_management.ex` | `lib/scrypath/meilisearch/client.ex` | `create_index/3` and `swap_indexes/2` | ✓ WIRED | Index-management helpers delegate to backend-native client endpoints. |
| `README.md` | operator guidance | docs sections | ✓ WIRED | Backfill/reindex, drift, cutover/eventual consistency, and recovery content is present. |
| `ARCHITECTURE.md` | runtime semantics | docs sections | ✓ WIRED | Workflow order and operator semantics match the implementation surface. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `lib/scrypath/meilisearch/settings.ex` | `settings` | `Scrypath.schema_settings/1` merged with runtime `:settings` overrides | Yes | ✓ FLOWING |
| `lib/scrypath/backfill.ex` | `records` / `documents` | explicit `repo.all/1` over ordered Ecto query, projected via `Scrypath.Projection.document/2` | Yes | ✓ FLOWING |
| `lib/scrypath/reindex.ex` | `backfill_result` | `Scrypath.Backfill.run/2` invoked with target index | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Focused Phase 5 automated coverage passes | `mix test test/scrypath/meilisearch_test.exs test/scrypath/reindex_test.exs test/scrypath/backfill_test.exs test/scrypath/options_test.exs test/scrypath/schema_test.exs` | `36 tests, 0 failures` | ✓ PASS |
| Docs include Phase 5 operator vocabulary | `rg -n "backfill|reindex|cutover|drift|recovery|eventual consistency|detect" README.md ARCHITECTURE.md` | Dedicated sections and references found in both docs | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `OPER-01` | `05-03` | Developer can bulk backfill an index from existing Ecto records. | ✓ SATISFIED | `Scrypath.backfill/2` and `Scrypath.Backfill.run/2` are implemented with bounded cursor batching and backend writes; behavior covered in `test/scrypath/backfill_test.exs`. |
| `OPER-02` | `05-04` | Developer can trigger a reindex workflow intentionally rather than reimplementing it ad hoc. | ✓ SATISFIED | `Scrypath.reindex/2` and `Scrypath.Reindex.run/2` implement a single managed workflow with ordered steps and explicit result metadata; covered in `test/scrypath/reindex_test.exs`. |
| `OPER-03` | `05-01`, `05-02`, `05-04` | Developer can apply index settings as part of managed indexing workflows. | ✓ SATISFIED | Schema-declared settings are reflected, validated, merged with runtime overrides, and applied through explicit Meilisearch helpers before backfill in reindex. |
| `OPER-05` | `05-04` | Developer can understand eventual consistency, failure modes, and recovery workflows from the official documentation. | ✓ SATISFIED | `README.md` and `ARCHITECTURE.md` document drift signals, backfill vs rebuild choice, cutover semantics, accepted-vs-visible distinctions, and recovery actions. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| None | - | No TODO/FIXME placeholders, empty implementations, or hardcoded hollow data found in Phase 5 artifacts. | - | No blocking anti-patterns detected. |

### Human Verification Required

### 1. Real Meilisearch Rebuild

**Test:** Run `Scrypath.reindex/2` against a real Meilisearch instance with `cutover?: false`, inspect the target index, then repeat with `cutover?: true`.
**Expected:** The target index is created, schema/runtime settings land on the target index, batches are indexed into that target, and live-index cutover only occurs when explicitly enabled.
**Why human:** External-service behavior was verified through unit tests and code traces, not against a live backend.

### 2. Operator Docs Readability

**Test:** Read the Phase 5 sections in `README.md` and `ARCHITECTURE.md` as if onboarding to recovery workflows.
**Expected:** The docs make it obvious when to backfill vs rebuild, what `cutover?: false` is for, what accepted work does not guarantee, how to detect drift, and how to recover from failed or partial rebuilds.
**Why human:** Documentation quality and operational clarity are user-facing judgment calls.

---

_Verified: 2026-04-16T00:00:00Z_
_Verifier: Claude (gsd-verifier)_
