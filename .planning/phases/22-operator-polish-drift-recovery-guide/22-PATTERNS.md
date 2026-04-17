# Phase 22 — Pattern Map

**Phase directory:** `.planning/phases/22-operator-polish-drift-recovery-guide/`  
**Generated:** 2026-04-17

---

## Files to create / modify

| File | Role | Closest analog | Excerpt / pattern |
|------|------|----------------|-------------------|
| `lib/scrypath/operator/failed_work.ex` | Extend struct, classification, telemetry | Same file (existing `from_*` pipelines) | Mirror `Map.get(job, :state) \|\| Map.get(job, "state")` for new job fields. |
| `test/scrypath/operator/failed_work_test.exs` | Assertions + telemetry | Same file | Existing fake `meilisearch_tasks` / `oban_jobs` lists. |
| `guides/drift-recovery.md` | New operator runbook | `guides/sync-modes-and-visibility.md` | Symptom → diagnosis → action → verify sections. |
| `mix.exs` | ExDoc extras | `guides/multi-index-search.md` entry | Alphabetical `extras:`; `Operations` group. |
| `test/scrypath/docs_contract_test.exs` | Contract | `guides/multi-index-search.md` test block | `@guide_paths` + `assert_contains_all`. |
| `docs/search-backend-sre.md` | Telemetry table | Existing `[:scrypath, :search]` rows | Same table format, alert posture row. |

---

## PATTERN MAPPING COMPLETE
