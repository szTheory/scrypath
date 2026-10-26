# Phase 180: Oban worker telemetry - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-25
**Phase:** 180-oban-worker-telemetry
**Areas discussed:** Event naming and span placement, Metadata contract and outcomes, Missing-record removal signal, Docs catalog and drift contract

The maintainer asked for every area to be considered: fan out research agents per decision point and synthesize one coherent set of recommendations to follow. Four `gsd-advisor-researcher` agents ran in parallel at full-maturity calibration; the orchestrator resolved conflicts between them.

---

## Event naming and span placement

| Option | Description | Selected |
|--------|-------------|----------|
| New `[:scrypath, :oban, :upsert / :delete]` spans | Integration-named prefix like `[:scrypath, :meilisearch, :request]`; span after decode + config | ✓ |
| Reuse `[:scrypath, :sync, *]` with a source tag | Double-counts: those spans already fire at enqueue in `:oban` mode | |
| Oban `[:oban, :job, *]` only | No index/backend, private args format, can't meet OBS-02 | |
| Hybrid (new spans + documented Oban join + point event) | Concrete form of the first option | ✓ (as guide content) |

**Choice:** New spans, after decode/config; decode cancels documented via Oban's events. Related worker out of scope.

## Metadata contract and outcomes

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse sync spans with `sync_mode: :oban` | Conflates enqueue with execute | |
| New spans, sync-span key names + `attempt`/`max_attempts`, flat atom `outcome`/`error_kind`/`cancel_reason` | Shared handler shape, reporter-safe tags | ✓ |
| Same but Oban `state` vocabulary | Same labels, different event mapping — confusing | |
| No spans, filter Oban events | Fails OBS-01 | |

**Conflicts resolved by orchestrator:** the naming researcher put `job_id`/`queue` in the metadata and the metadata researcher left them out → left out (Oban carries them; `job_id` is high-cardinality). `status: :cancelled` vs `outcome` → `outcome` (`status` already means something on the sync spans). The metadata researcher's proposed `[:scrypath, :oban, :invalid_job]` event → deferred (Oban's cancelled stop + `failed_work` cover it; keeps the contract smaller). D-19 related-worker reason alignment → included as `{:cancel, {:http_error, status}}`; the 4xx-retry inconsistency it raised → deferred.

## Missing-record removal signal

| Option | Description | Selected |
|--------|-------------|----------|
| Point event only | Measurement count, fires after a successful delete | |
| `missing_count` on span stop only | Awkward for metrics; arguably not "an event" | |
| Both (event = removed, metadata = found) | Matches existing `missing_count` spans; metrics and traces both useful | ✓ |
| Plus a Logger line | Noise on normal soft-delete path | |

**Conflict resolved:** `missing_deleted` vs `missing_removed` → `missing_removed` (repo vocabulary: Loader "removed from the index", backfill `removed:`).

## Docs catalog and drift contract

| Option | Description | Selected |
|--------|-------------|----------|
| String presence only (today) | Already drifting: 4 emitted events missing from the SRE table | |
| Public `Scrypath.Telemetry` moduledoc | Ecosystem convention, but exposes internal helpers | |
| Private catalog module | A third copy unless docs are generated | |
| Generate docs from code | Too much machinery for 17 events | |
| `guides/telemetry.md` canonical; test parses table, static-scans `lib/` names both ways, captures keys for new worker events | One human-edited source, deterministic, no deps | ✓ |

**Choice:** The guide is the single source; every event is catalogued by name; strict key checks cover the 3 new events; the SRE and per-query docs become pointers.

## Claude's Discretion

Stop-metadata factoring, `error_kind/1` visibility, test helper placement, wording of rows for existing events.

## Deferred Ideas

4xx retry semantics in the upsert/delete workers; `[:scrypath, :oban, :related]` span; key-level contract for existing events; backfill `missing_removed` analogue; `[:scrypath, :oban, :invalid_job]` event; public `Scrypath.Telemetry` moduledoc.
