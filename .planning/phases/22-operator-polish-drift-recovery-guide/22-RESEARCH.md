# Phase 22 — Technical Research

**Phase:** 22 — Operator Polish + Drift Recovery Guide  
**Researched:** 2026-04-17  
**Question:** What do we need to know to plan implementation well?

---

## Summary

Extend `Scrypath.Operator.FailedWork` with four defaulted fields (`attempt`, `max_attempts`, `reason_class`, `last_attempt_at`), implement a **normalize → classify** pipeline with a five-atom `reason_class` enum, emit `:telemetry.execute` on `[:scrypath, :operator, :failed_work, :observed]` from the two canonical constructors (`from_backend_task/3`, `from_queue_job/3`), and ship `guides/drift-recovery.md` as six SRE-style scenarios using only existing `Scrypath.*` and `mix scrypath.*` verbs. No `@enforce_keys` changes, no new public recovery verbs, no new Mix tasks.

Canonical prior art: `.planning/research/deep/OPERATOR_POLISH.md` and `22-CONTEXT.md` (locked decisions D-01–D-16).

---

## Codebase anchors

| Area | File | Notes |
|------|------|-------|
| Struct + constructors | `lib/scrypath/operator/failed_work.ex` | `from_backend_task/3`, `from_queue_job/3` are the only production constructors for listed failures. |
| Telemetry style | `lib/scrypath/reindex.ex`, `lib/scrypath/search.ex` | `:telemetry.execute(name, measurements, metadata)` with `%{count: n}` for simple counters. |
| Consumer tests | `test/scrypath/operator/failed_work_test.exs` | Extend with classifier + telemetry attach + `attempt`/`max_attempts` expectations. |
| ExDoc | `mix.exs` | `extras:` + `groups_for_extras` → **Operations** group alongside sync/operator guides. |
| Docs contract | `test/scrypath/docs_contract_test.exs` | Add `guides/drift-recovery.md` to `@guide_paths`; add substring assertions for runbook shape. |
| SRE telemetry table | `docs/search-backend-sre.md` | Add row for `[:scrypath, :operator, :failed_work, :observed]` (alert posture: low-frequency observation, not paging by default). |

---

## `reason_class` classification (implementation sketch)

**Enum:** `:transport | :validation | :backend_rejected | :queue_exhausted | :unknown`

**Backend (Meilisearch task `error` map):**

- Normalize to a map with at least `:error_type`, `:error_code` (strings from `"type"` / `"code"`), optional HTTP-ish hints if ever present on raw payload.
- Map `invalid_request` → `:validation`; `internal` → `:backend_rejected`; `auth` → `:transport` (per CONTEXT / OPERATOR_POLISH).
- Missing or malformed `error` → `:unknown`.

**Queue (Oban job map):**

- If `reason_class` from structured worker error is clearly validation (e.g. `ArgumentError` / cast patterns in `errors` list) → `:validation` before exhaustion rollup.
- If state is discarded/cancelled and `attempt >= max_attempts` or last error is transport-like → `:queue_exhausted` vs `:transport` per OPERATOR_POLISH precedence: **specific validation/backend signals beat `:queue_exhausted`**.
- Default unknown when signals ambiguous.

**`attempt` / `max_attempts`:** Read from Oban job fields with atom **and** string keys (`:attempt`, `"attempt"`). For backend-origin rows and any non-`:oban` mode listing, set **`attempt: nil`, `max_attempts: nil`** (OPS-07).

**`last_attempt_at`:** Set equal to `failed_at` for both paths (OPS-08); keep populating `failed_at` unchanged.

---

## Telemetry (OPS-10 + CONTEXT D-01–D-05)

- **Event:** `[:scrypath, :operator, :failed_work, :observed]`
- **Measurements:** `%{count: 1}` unless already inside a measured span (use standalone execute here).
- **Metadata (required):** `reason_class`, `schema`, `mode` (REQ minimum).
- **Metadata (optional v1.3):** `operation` (`:upsert | :delete | :unknown`), `retryable?` (boolean) — CONTEXT D-02.
- **Emit site:** End of `from_backend_task/3` and `from_queue_job/3` only (one event per row materialized for `FailedWork.list/3`); avoids double emission on hand-built structs in tests.

Document in `@moduledoc` and HexDocs-facing note: `schema` and module atoms are **unsafe as Prometheus labels** without rollup (D-05).

---

## Testing strategy

1. **Table-driven unit tests** on `classify_normalized/1`-style private API via **`defmodule` test wrapper** or direct assertion through public `list/3` with fake task/job maps (preferred: keep classifier private; assert on `%FailedWork{reason_class: ...}` from `list/3`).
2. **Small fixture set** for Meilisearch raw task shapes (invalid_request / internal / auth) and Oban discarded vs retryable.
3. **Telemetry:** `:telemetry.attach_many/4` test handler (same pattern as `test/scrypath/search_many_test.exs`) asserting one event per constructed row in `failed_sync_work/2` coverage.
4. **No live Meilisearch** required on default test path (aligns with CONTEXT discretion).

---

## Risk notes

- **Precedence bugs** between `:queue_exhausted` and error-specific classes — mitigate with ordered decision table in code + tests per row.
- **String vs atom keys** on Oban job maps — follow existing `Map.get(job, :state) || Map.get(job, "state")` pattern throughout new field reads.

---

## Validation Architecture

**Nyquist / verification role:** Phase 22 changes operator observability (`FailedWork`, telemetry) and operator documentation. Feedback sampling should prove: (1) backward compatibility of struct literals, (2) classifier determinism, (3) telemetry contract, (4) guide + ExDoc wiring.

**Dimension coverage:**

| Dimension | How phase addresses |
|-----------|----------------------|
| D1 Requirements | Each OPS-05..10 mapped to plans 22-01 / 22-02 with REQ IDs in frontmatter. |
| D2 Backward compat | Tests keep existing `%FailedWork{...}` patterns; no new `@enforce_keys`. |
| D3 Observability | Telemetry test proves event name + required metadata keys. |
| D4 Documentation | Docs contract + ExDoc extras + SRE doc row. |
| D8 Executable validation | `mix test test/scrypath/operator/failed_work_test.exs` and `docs_contract_test.exs` cited in VALIDATION.md task map. |

**Quick feedback command:** `mix test test/scrypath/operator/failed_work_test.exs test/scrypath/docs_contract_test.exs`  
**Full suite:** `mix test --exclude integration`

---

## RESEARCH COMPLETE

Ready for `22-VALIDATION.md`, pattern map, and PLAN.md files.
