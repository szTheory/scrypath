---
phase: 01-core-contracts-and-api-shape
verified: 2026-04-16T16:49:12Z
status: passed
score: 4/4 must-haves verified
overrides_applied: 0
---

# Phase 1: Core Contracts and API Shape Verification Report

**Phase Goal:** Establish the searchable schema contract, projection runtime, reflection helpers, and internal backend seam that later phases build on.
**Verified:** 2026-04-16T16:49:12Z
**Status:** passed
**Re-verification:** No - backfilled verification artifact from current source and tests

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A developer can declare a searchable Ecto schema with a small, explicit `use Scrypath` configuration. | ✓ VERIFIED | `Scrypath.__using__/1` forwards schema declarations into `Scrypath.Schema`, which validates options once and persists normalized metadata without generating runtime verbs. [`lib/scrypath.ex`](/Users/jon/projects/scrypath/lib/scrypath.ex#L23), [`lib/scrypath/schema.ex`](/Users/jon/projects/scrypath/lib/scrypath/schema.ex#L24), [`test/scrypath/schema_test.exs`](/Users/jon/projects/scrypath/test/scrypath/schema_test.exs#L5) |
| 2 | A developer can define how a source record is projected into a search document. | ✓ VERIFIED | `Scrypath.Projection.document/2` supports both declared field projection and `search_document/1` precedence, and raises when required projected data is missing. [`lib/scrypath/projection.ex`](/Users/jon/projects/scrypath/lib/scrypath/projection.ex#L16), [`test/scrypath/projection_test.exs`](/Users/jon/projects/scrypath/test/scrypath/projection_test.exs#L37) |
| 3 | A developer can inspect declared search metadata for a schema at runtime. | ✓ VERIFIED | Phase 1 stores normalized metadata behind `__scrypath__/1`, and the public reflection helpers expose config, fields, settings, document source, and document id without schema-specific APIs. [`lib/scrypath/schema.ex`](/Users/jon/projects/scrypath/lib/scrypath/schema.ex#L31), [`lib/scrypath.ex`](/Users/jon/projects/scrypath/lib/scrypath.ex#L29), [`test/scrypath/schema_test.exs`](/Users/jon/projects/scrypath/test/scrypath/schema_test.exs#L17) |
| 4 | The internal architecture preserves a path to future backend support without forcing a premature public abstraction. | ✓ VERIFIED | `Scrypath.Backend` defines a narrow internal behavior, while the README and architecture docs keep the seam explicitly internal and Meilisearch-first for v1. [`lib/scrypath/backend.ex`](/Users/jon/projects/scrypath/lib/scrypath/backend.ex#L1), [`test/scrypath/backend_test.exs`](/Users/jon/projects/scrypath/test/scrypath/backend_test.exs#L42), [`README.md`](/Users/jon/projects/scrypath/README.md#L18), [`ARCHITECTURE.md`](/Users/jon/projects/scrypath/ARCHITECTURE.md#L55) |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/scrypath.ex` | Public macro entrypoint and runtime reflection helpers | ✓ VERIFIED | Exposes `use Scrypath` plus schema reflection helpers on the top-level module. [`lib/scrypath.ex`](/Users/jon/projects/scrypath/lib/scrypath.ex#L23) |
| `lib/scrypath/schema.ex` | Metadata-only schema declaration contract | ✓ VERIFIED | Validates declaration options and persists `__scrypath__/1` metadata keys. [`lib/scrypath/schema.ex`](/Users/jon/projects/scrypath/lib/scrypath/schema.ex#L24) |
| `lib/scrypath/projection.ex` | Document projection contract | ✓ VERIFIED | Implements field projection, custom projection precedence, and explicit missing-field failures. [`lib/scrypath/projection.ex`](/Users/jon/projects/scrypath/lib/scrypath/projection.ex#L16) |
| `lib/scrypath/backend.ex` | Internal backend seam | ✓ VERIFIED | Declares the internal callback set later concrete backends implement. [`lib/scrypath/backend.ex`](/Users/jon/projects/scrypath/lib/scrypath/backend.ex#L12) |
| `README.md` | Public product boundary and schema declaration guidance | ✓ VERIFIED | Documents `use Scrypath`, metadata-only runtime shape, and internal backend seam messaging. [`README.md`](/Users/jon/projects/scrypath/README.md#L20), [`README.md`](/Users/jon/projects/scrypath/README.md#L118) |
| `ARCHITECTURE.md` | Architecture guidance for projection flow and backend seam | ✓ VERIFIED | Documents projection precedence and the internal backend behavior boundary. [`ARCHITECTURE.md`](/Users/jon/projects/scrypath/ARCHITECTURE.md#L44), [`ARCHITECTURE.md`](/Users/jon/projects/scrypath/ARCHITECTURE.md#L55) |
| `test/scrypath/schema_test.exs` | Schema declaration and reflection proof | ✓ VERIFIED | Covers normalized metadata, settings reflection, no generated runtime search API, and invalid option rejection. [`test/scrypath/schema_test.exs`](/Users/jon/projects/scrypath/test/scrypath/schema_test.exs#L5) |
| `test/scrypath/projection_test.exs` | Projection contract proof | ✓ VERIFIED | Covers field projection, `search_document/1` precedence, document source reflection, and missing-field failures. [`test/scrypath/projection_test.exs`](/Users/jon/projects/scrypath/test/scrypath/projection_test.exs#L37) |
| `test/scrypath/backend_test.exs` | Internal backend seam proof | ✓ VERIFIED | Covers explicit runtime config precedence and a fake backend satisfying the behavior contract. [`test/scrypath/backend_test.exs`](/Users/jon/projects/scrypath/test/scrypath/backend_test.exs#L22) |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `lib/scrypath.ex` | `lib/scrypath/schema.ex` | `use Scrypath` delegates into the schema macro | ✓ WIRED | The top-level macro forwards declaration options directly into `Scrypath.Schema`. [`lib/scrypath.ex`](/Users/jon/projects/scrypath/lib/scrypath.ex#L23), [`lib/scrypath/schema.ex`](/Users/jon/projects/scrypath/lib/scrypath/schema.ex#L24) |
| `lib/scrypath/schema.ex` | runtime reflection helpers | persisted metadata through `__scrypath__/1` | ✓ WIRED | Reflection clauses expose config, fields, settings, document source, document id, and backend metadata for runtime callers. [`lib/scrypath/schema.ex`](/Users/jon/projects/scrypath/lib/scrypath/schema.ex#L31), [`lib/scrypath.ex`](/Users/jon/projects/scrypath/lib/scrypath.ex#L29) |
| `lib/scrypath.ex` | `lib/scrypath/projection.ex` | document-source reflection | ✓ WIRED | `Scrypath.document_source/1` delegates directly to `Scrypath.Projection.document_source/1`, and tests assert both the direct and top-level paths. [`lib/scrypath.ex`](/Users/jon/projects/scrypath/lib/scrypath.ex#L44), [`lib/scrypath/projection.ex`](/Users/jon/projects/scrypath/lib/scrypath/projection.ex#L25), [`test/scrypath/projection_test.exs`](/Users/jon/projects/scrypath/test/scrypath/projection_test.exs#L67) |
| `lib/scrypath/projection.ex` | projected document behavior | field/default vs custom source projection | ✓ WIRED | Projection returns `%Scrypath.Document{}` from either declared fields or `search_document/1`, preserving explicit source metadata. [`lib/scrypath/projection.ex`](/Users/jon/projects/scrypath/lib/scrypath/projection.ex#L17), [`test/scrypath/projection_test.exs`](/Users/jon/projects/scrypath/test/scrypath/projection_test.exs#L53) |
| `lib/scrypath/backend.ex` | internal adapter boundary | narrow callback behavior | ✓ WIRED | The fake backend exercises the callback set directly, proving the seam exists without making it a public registry surface. [`lib/scrypath/backend.ex`](/Users/jon/projects/scrypath/lib/scrypath/backend.ex#L12), [`test/scrypath/backend_test.exs`](/Users/jon/projects/scrypath/test/scrypath/backend_test.exs#L42) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Phase 1 schema/projection/backend contract tests pass | `mix test test/scrypath/schema_test.exs test/scrypath/projection_test.exs test/scrypath/backend_test.exs` | `12 tests, 0 failures` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `SCMA-01` | `01-01`, `01-03` | Developer can declare a searchable Ecto schema with a small, explicit `use Scrypath` configuration. | ✓ SATISFIED | Metadata-only schema declaration plus docs and schema tests. [`lib/scrypath/schema.ex`](/Users/jon/projects/scrypath/lib/scrypath/schema.ex#L24), [`README.md`](/Users/jon/projects/scrypath/README.md#L20), [`test/scrypath/schema_test.exs`](/Users/jon/projects/scrypath/test/scrypath/schema_test.exs#L5) |
| `SCMA-02` | `01-02`, `01-03` | Developer can define how a source record is projected into a search document. | ✓ SATISFIED | Projection runtime supports declared fields and explicit custom projection hooks. [`lib/scrypath/projection.ex`](/Users/jon/projects/scrypath/lib/scrypath/projection.ex#L16), [`test/scrypath/projection_test.exs`](/Users/jon/projects/scrypath/test/scrypath/projection_test.exs#L37) |
| `SCMA-03` | `01-01`, `01-02`, `01-03` | Developer can inspect declared search metadata for a schema at runtime. | ✓ SATISFIED | Persisted `__scrypath__/1` metadata and top-level reflection helpers are tested directly. [`lib/scrypath/schema.ex`](/Users/jon/projects/scrypath/lib/scrypath/schema.ex#L31), [`lib/scrypath.ex`](/Users/jon/projects/scrypath/lib/scrypath.ex#L29), [`test/scrypath/schema_test.exs`](/Users/jon/projects/scrypath/test/scrypath/schema_test.exs#L17) |
| `BACK-02` | `01-02`, `01-03` | The internal architecture preserves a future backend path without forcing a premature public abstraction. | ✓ SATISFIED | Internal behavior plus docs keep the backend seam explicit and non-public. [`lib/scrypath/backend.ex`](/Users/jon/projects/scrypath/lib/scrypath/backend.ex#L1), [`README.md`](/Users/jon/projects/scrypath/README.md#L18), [`ARCHITECTURE.md`](/Users/jon/projects/scrypath/ARCHITECTURE.md#L55) |

This report backfills Phase 1 evidence from the current codebase and focused tests. It does not assign shipped features to Phase 7.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| None | - | No TODO/FIXME placeholders, empty implementations, or audit-unsafe ownership claims were found in the Phase 1 artifacts referenced here. | - | No blocking anti-patterns detected. |

### Gaps Summary

The prior gap was missing verification evidence, not missing Phase 1 runtime behavior. Current source, tests, and docs already prove the schema declaration contract, projection contract, runtime reflection surface, and internal backend seam; this report restores that evidence chain without reassigning ownership away from the original Phase 1 plans.

---

_Verified: 2026-04-16T16:49:12Z_
_Verifier: Codex (inline execute-phase fallback)_
