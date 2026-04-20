---
gsd_state_version: 1.0
milestone: v1.8
milestone_name: — active)
status: "Phase 40 context gathered — ready to plan"
last_updated: "2026-04-20T20:00:00.000Z"
last_activity: 2026-04-20 — `/gsd-discuss-phase 40` captured **40-CONTEXT.md** (tagged `{:all, …}` splice, config allowlist + `global_schemas:` override, error taxonomy, timeout/failure boundaries).
progress:
  total_phases: 23
  completed_phases: 19
  total_plans: 53
  completed_plans: 54
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-20)

**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

**Current focus:** **v1.8 — Multi-index federation** — next **Phase 40** (`:all` expansion, **FED-02**).

## Current Position

Phase: **40** — `:all` expansion (not started)

Plan: —

**Status:** Phase **39** complete (**FED-01**): `federation_weight:` validation, native `search_many` fed_opts, Meilisearch `federationOptions.weight`, `merge_hit_order` / `merge_projection/1`, docs + tests.

**Last activity:** 2026-04-20 — Phase **40** discuss complete; see **`.planning/phases/40-all-expansion/40-CONTEXT.md`**.

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

1. **`/gsd-plan-phase 40`** — plans from **`.planning/phases/40-all-expansion/40-CONTEXT.md`**.

**Resume files:** `.planning/phases/40-all-expansion/40-CONTEXT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`

---
*Last updated: 2026-04-20 — phase 40 discuss complete*

**Prior milestone:** **v1.7** (phases **36–38**) — archived 2026-04-20

**Completed Phase:** 39 (Federation scoring & weights) — 2 plans — 2026-04-20
