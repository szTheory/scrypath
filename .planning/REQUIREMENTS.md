# Requirements: Scrypath v1.44 Sync correctness

**Defined:** 2026-10-25
**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.
**Scope source:** section 2 of `reference/ROLLING-ROADMAP.md`. All changes are in `lib/` (plus tests and CI); there are no `scrypath_ops` or visible UI changes.

## v1.44 Requirements

### Loader parity (LOAD)

- [x] **LOAD-01**: A backfill or reindex of a schema that declares `preload:` builds documents identical to the ones inline and Oban sync build for the same records.
- [x] **LOAD-02**: A backfill or reindex of a schema that defines `search_records/2` loads every batch through it, and records it leaves out are not indexed.
- [x] **LOAD-03**: A caller's `:query` scope still selects which rows a backfill visits, while the shared loader builds the documents.

### Paging and batching (PAGE)

- [x] **PAGE-01**: A backfill or reindex over a schema with a composite primary key visits every row exactly once, using a lexicographic keyset on all key columns (maintainer decision 2026-10-25: page on the full key, don't reject composite keys). A property test covers repeated leading-column values across batch boundaries.
- [x] **PAGE-02**: Backfill batch results report the full cursor for composite keys, not just the first column.
- [x] **PAGE-03**: Id lists are chunked to at most about 1000 per record load and per backend upsert or delete call. For example, 2,500 ids make three calls and return one combined result.

### Related sync (FAN)

- [x] **FAN-01**: `sync_related` resolvers get loaded records in every sync mode. Under Oban, the worker loads current records through the loader before it calls the resolver.
- [x] **FAN-02**: Related enqueue uses the same `unique:` policy as the main enqueue path, so duplicate related jobs collapse.
- [x] **FAN-03**: Sync jobs (related, upsert and delete) whose arguments name an unknown schema, fan-out, backend, repo or app end with a clear, non-retrying error instead of crashing on `String.to_existing_atom`.

### Observability (OBS)

- [ ] **OBS-01**: The Oban upsert and delete workers emit telemetry spans (start, stop, exception) with stable metadata: schema, index, backend, document count and attempt.
- [ ] **OBS-02**: When a job finds ids with no current record and deletes them from the index, it emits an event with the count of those ids. This case is no longer silent.
- [ ] **OBS-03**: The telemetry guide and its contract test list the new events and metadata keys.

### Hygiene (HYG)

- [ ] **HYG-01**: The schema hooks (`search_records/2`, `search_document_id/1` and the other duck-typed hooks) are declared as `@optional_callbacks` on a behaviour, so they show up in HexDocs and the compiler checks them.
- [ ] **HYG-02**: A build without Oban compiles with `--warnings-as-errors` and has a CI check, with no blanket warning suppression.

### Testing (TEST)

- [x] **TEST-06**: The loader and backfill, including the composite-key and `preload:` cases, are tested against a real Postgres database in an existing CI lane, not only against `FakeRepo`.

## Open questions for discuss-phase

- Whether the chunk size (PAGE-03) can be configured, and what to call the option.
- What a related resolver receives under Oban (FAN-01) when the trigger records were deleted before the job runs.

## Future Requirements

- Route the seven `case backend do Scrypath.Meilisearch -> ...` spots through the adapter seam (rolling roadmap, Later).

## Out of Scope

| Feature | Reason |
|---------|--------|
| Backend-seam cleanup | Listed under Later in the rolling roadmap; a refactor, not a sync-correctness bug |
| Adopter features (testing kit, `search_indexable?/1`, highlighting, settings guards, mix tasks) | v1.48, after API grilling |
| `scrypath_ops` or visible UI changes | v1.45–v1.47; this milestone is library-only |
| Callback or Repo-hook auto-sync, automatic association walking | Standing scope guard |
| A new required CI job | Lean required gates stay; the new checks run inside existing lanes |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| LOAD-01 | Phase 178 | Complete |
| LOAD-02 | Phase 178 | Complete |
| LOAD-03 | Phase 178 | Complete |
| PAGE-01 | Phase 178 | Complete |
| PAGE-02 | Phase 178 | Complete |
| PAGE-03 | Phase 179 | Complete |
| FAN-01 | Phase 179 | Complete |
| FAN-02 | Phase 179 | Complete |
| FAN-03 | Phase 179 | Complete |
| OBS-01 | Phase 180 | Pending |
| OBS-02 | Phase 180 | Pending |
| OBS-03 | Phase 180 | Pending |
| HYG-01 | Phase 181 | Pending |
| HYG-02 | Phase 181 | Pending |
| TEST-06 | Phase 178 | Complete |

**Coverage:**
- v1.44 requirements: 15 total
- Mapped to phases: 15
- Unmapped: 0

---
*Requirements defined: 2026-10-25*
*Last updated: 2026-10-25 after roadmap creation (Phases 178–181)*
