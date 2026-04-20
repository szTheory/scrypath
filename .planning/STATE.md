---
gsd_state_version: 1.0
milestone: v1.8
milestone_name: Multi-index federation
status: milestone_complete
last_updated: "2026-04-20T16:05:00.000Z"
last_activity: "2026-04-20 — Phase **41** executed; v1.8 federation docs and FED-03 complete."
progress:
  total_phases: 3
  completed_phases: 3
  total_plans: 6
  completed_plans: 6
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-20)

**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

**Current focus:** **v1.8 — Multi-index federation** — **complete** (phases **39–41**). Next optional track: **OPSUI-01**.

## Current Position

Phase: **41** — Federation docs & contracts (**complete**)

Plan: **41-02** (final) — summaries and verification recorded

**Status:** Milestone **v1.8** complete in-repo (**FED-01**..**FED-03**).

**Last activity:** 2026-04-20 — Phase **41** executed; `mix verify.phase41`, guides, and requirements traceability updated.

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

1. **`/gsd-progress`** — confirm roadmap and requirements after v1.8 closeout.
2. **`/gsd-new-milestone`** or **`/gsd-discuss-phase`** — when starting **OPSUI-01** or the next version line.

**Resume files:** `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md`

---
*Last updated: 2026-04-20 — phase 41 execution complete*

**Prior milestone:** **v1.7** (phases **36–38**) — archived 2026-04-20

**Completed Phase:** 41 (Federation docs & contracts) — 2 plans — 2026-04-20

**Milestone:** **v1.8** — phases **39–41** — complete in-repo 2026-04-20
