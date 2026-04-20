---
gsd_state_version: 1.0
milestone: v1.8
milestone_name: — active)
status: milestone_complete
last_updated: "2026-04-20T15:54:24.997Z"
last_activity: 2026-04-20
progress:
  total_phases: 1
  completed_phases: 1
  total_plans: 2
  completed_plans: 0
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-20)

**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

**Current focus:** Phase --phase — 41

## Current Position

Phase: 41

Plan: Not started

**Status:** Milestone complete

**Last activity:** 2026-04-20

## Accumulated Context

### Decisions

(See `.planning/PROJECT.md` Key Decisions.)

**v1.8 intent:** Ship **FED-01** (federation scoring/weighting), **FED-02** (`:all` or equivalent expansion + rails), **FED-03** (docs/contracts). **OPSUI-01** (operator LiveView) is an explicit **follow-up** after federation primitives exist.

**Phase 39 (locked in CONTEXT):** Per-entry **`federation_weight:`**; omit weight on wire when unset; **`{:invalid_options, {:federation_weight, _}}`** / **`{:federation_merge_requires_native_search_many, _}}`**; optional merge-order trace **`{schema, id}`** + projection helper; no silent merge on sequential fallback when weights are set.

**Phase 40 (locked in CONTEXT):** Tagged **`{:all, text, keyword?}`** entry in **`search_many`** list expands (splices) to allowlisted modules; default list from **application config**, **`global_schemas:`** replaces for one call; **`{:invalid_options, {:all_expansion, :empty_registry}}`** vs **`:empty_schema_list`**; **`{:too_many_schemas, count, max}`** after expansion; resolution errors before HTTP; validation stays **fail-fast** **`{:validation_failed, …}`** like today.

### Blockers / Concerns

- **None.**

### Deferred Items

Canonical ledger references (AUDT-01 / milestone-close hygiene): **`18-VERIFICATION.md`**, **`v1.4-MILESTONE-AUDIT.md`**, **`260416-eoj-SUMMARY.md`**, **`260416-if2-SUMMARY.md`** — see **`.planning/PROJECT.md`** and archived **`STATE.md`** discussions; no new triage rows for v1.8 open.

## Next Command

1. **`/gsd-discuss-phase 41`** — align docs/contracts scope before planning (**FED-03**).
2. **`/gsd-plan-phase 41`** — after discuss (or skip if CONTEXT already sufficient).

**Resume files:** `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md`

---
*Last updated: 2026-04-20 — phase 40 execution complete*

**Prior milestone:** **v1.7** (phases **36–38**) — archived 2026-04-20

**Completed Phase:** 40 (`:all` expansion) — 2 plans — 2026-04-20

**Next phase:** 41 (Federation docs & contracts) — not started

**Planned Phase:** 41 (Federation docs & contracts) — 2 plans — 2026-04-20T15:50:13.642Z
