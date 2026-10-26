# Roadmap: Scrypath

## Milestones

- 🚧 **v1.44 Sync correctness** — Phases 178–181 (4 phases; in progress since 2026-10-25) — [active section below](#v144--sync-correctness)
- ✅ **v1.43 ScrypathOps UI refinement** — Phases 173–177 (5 phases, 21 plans; archived 2026-10-25; first shipped in `scrypath` 0.3.16) — [archive](milestones/v1.43-ROADMAP.md)
- ✅ **v1.42 ScrypathOps operator/admin UI** — Phase172 (1 phase, 8 plans; archived2026-10-04) — [archive](milestones/v1.42-ROADMAP.md)
- ✅ **v1.41 Readiness Gate Follow-Through** — Phases 168–171 (4 phases, 19 plans; archived 2026-10-02; `tech_debt` accepted; original Phase 170 decision remains NOT READY at its cutoff; later separate readiness assessment is READY) — [archive](milestones/v1.41-ROADMAP.md)
- ✅ **v1.40 Readiness Evidence Closure** — Phases 165–167 (archived locally 2026-09-27; no Hex release; assessment remains NOT READY) — [archive](milestones/v1.40-ROADMAP.md)
- ✅ **v1.39 Pre-Operator UI Quality Readiness Ratchet** — Phases 162–164 (archived locally 2026-09-26) — [archive](milestones/v1.39-ROADMAP.md)
- ✅ **v1.38 Packaged Adopter Proof** — Phases 160–161 (shipped 2026-09-25; `scrypath 0.3.13`) — [archive](milestones/v1.38-ROADMAP.md)
- ✅ **v1.37 Code Quality Ratchet** — Phases 148–159 (shipped 2026-08-26) — [archive](milestones/v1.37-ROADMAP.md)
- ✅ **v1.36 Dependency Security Remediation** — Phases 144–147 (shipped 2026-08-25) — [archive](milestones/v1.36-ROADMAP.md)
- ✅ **v1.35 Brand System & Logo Identity** — Phases 137–143 (shipped 2026-06-24) — [archive](milestones/v1.35-ROADMAP.md)
- ✅ **v1.34 Both-Themes Perfection — Dark Signature + AA Gate** — Phases 128–136 (shipped 2026-06-29) — [archive](milestones/v1.34-ROADMAP.md)

## Current Posture

**v1.44 Sync correctness is active.** Phases 178–181 are planned below; Phase 178 is next and not started. Scope comes from section 2 of the [rolling roadmap](reference/ROLLING-ROADMAP.md) and the 15 requirements in [REQUIREMENTS.md](REQUIREMENTS.md). All changes are library-only (`lib/`, tests and CI); there is no `scrypath_ops` or visible UI work. Each phase is one PR, squash-merged once the lean required checks pass; no new required CI job is added.

v1.43 completed all 20 OPUX requirements (OPUX-09–OPUX-28) across Phases 173–177, with 21/21 plans and five passing phase verifications. The terminal exact-source closeout is recorded in [the v1.43 final receipt](reference/v1.43-final-receipt.json), which closes the last blocking threat, T-177-05. See [the v1.43 audit](milestones/v1.43-MILESTONE-AUDIT.md).

After v1.44 the [rolling roadmap](reference/ROLLING-ROADMAP.md) continues with v1.45 foundation and CI, then the UI quality engine (v1.46–v1.47), then adopter features (v1.48). Each milestone runs the full GSD lifecycle, starting with `/gsd-new-milestone`.

## v1.44 — Sync correctness

**Goal:** Every sync path (inline, Oban, backfill and reindex) builds the same documents through one loader, pages through every row, and reports what it did, so no path silently skips or drops work.

### Phases

- [x] **Phase 178: Loader-routed backfill and full-key paging** - Backfill and reindex build documents through `Scrypath.Loader` and visit every row, including composite keys, proven against real Postgres (completed 2026-10-25)
- [x] **Phase 179: Bounded id lists and related-sync parity** - Loads and backend calls are chunked, and `sync_related` behaves the same under inline and Oban with safe job-arg decoding (completed 2026-10-25)
- [x] **Phase 180: Oban worker telemetry** - Upsert and delete workers emit stable telemetry spans and a missing-record delete event, documented and contract-tested (completed 2026-10-25)
- [x] **Phase 181: Schema hook contract and no-Oban build** - Schema hooks are declared optional callbacks and a no-Oban build stays warnings-clean in CI (completed 2026-10-26)

### Phase Details

### Phase 178: Loader-routed backfill and full-key paging

**Goal**: A backfill or reindex produces exactly the documents inline and Oban sync would produce, for every row of the schema, whatever its primary-key shape.
**Depends on**: Nothing (first phase of v1.44)
**Requirements**: LOAD-01, LOAD-02, LOAD-03, PAGE-01, PAGE-02, TEST-06
**Success Criteria** (what must be TRUE):
  1. A test shows that for a schema declaring `preload:`, the documents a backfill and a reindex build are equal to the documents inline sync builds for the same records.
  2. A test shows that for a schema defining `search_records/2`, every backfill batch is loaded through it and records it omits are absent from the index, while a caller's `:query` scope still decides which rows are visited.
  3. A property test over a composite-primary-key schema with repeated leading-column values across batch boundaries shows every row visited exactly once, and each batch result reports the full composite cursor.
  4. The loader and backfill tests, including the composite-key and `preload:` cases, run against a real Postgres database inside an existing CI lane (not only `FakeRepo`) and pass on the phase PR.

**Plans**: 5/5 plans complete

Plans:
**Wave 1**
- [x] 178-01-PLAN.md — Real-DB harness: shared case template on SQLite + Postgres, postgrex test dep, compose postgres (wave 1)

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 178-02-PLAN.md — `mix verify.postgres` wired into `backend (required)` CI with contract pins (wave 2)
- [x] 178-03-PLAN.md — Full-key composite keyset paging, keyword cursor, `:query` stripping, reindex primaryKey fix (wave 2)

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 178-04-PLAN.md — Backfill/reindex through `Scrypath.Loader`: preload parity, `search_records/2`, removed/omitted (wave 3)

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 178-05-PLAN.md — `Scrypath.backfill/2` result @doc, guides, README, CONTRIBUTING, docs contract test (wave 4)

### Phase 179: Bounded id lists and related-sync parity

**Goal**: Large id sets never produce unbounded loads or backend calls, and related-record sync gives resolvers the same input and the same queue behaviour in every sync mode, failing cleanly on bad job arguments.
**Depends on**: Phase 178 (chunking and the Oban related worker build on the shared loader path)
**Requirements**: PAGE-03, FAN-01, FAN-02, FAN-03
**Success Criteria** (what must be TRUE):
  1. A test shows that 2,500 ids produce three record loads and three backend upsert (and delete) calls of at most about 1000 ids each, and the caller receives one combined result.
  2. A test shows a `sync_related` resolver receives loaded records, not bare ids, under both inline and Oban sync; under Oban the related worker loads current records through the loader before calling the resolver.
  3. A test shows that enqueueing the same related sync twice yields one job, because related enqueue uses the same `unique:` policy as the main enqueue path.
  4. Tests show related, upsert and delete jobs whose args name an unknown schema, fan-out, backend, repo or app finish with a clear, non-retrying error instead of raising from `String.to_existing_atom`.

**Plans**: 7/7 plans complete

Plans:
**Wave 1**
- [x] 179-01-PLAN.md — `Scrypath.Chunks` (1000-id cap), `Result.tasks`, chunked inline/manual sync with halt and per-chunk wait, chunked `Loader.load/3` with owner-only `:preload` tolerance (wave 1)

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 179-02-PLAN.md — Chunked backfill writes, batch `tasks:`, reindex waits on every chunk task, backfill docs (wave 2)
- [x] 179-03-PLAN.md — One Oban job per chunk inside one transaction, shared `unique_opts/0`, `conflict?`, Oban SQLite test harness (wave 2)
- [x] 179-04-PLAN.md — `Scrypath.Oban.JobArgs` decoder, cancelling upsert/delete workers (D-18 repo), chunked worker writes (wave 2)

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 179-05-PLAN.md — Related worker loads trigger structs via the loader, related enqueue chunked/unique/`ensure_loadable!`, FAN-03 matrix, 0.3.17 legacy fixture (wave 3)

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 179-06-PLAN.md — Guides (§(c) "What your resolver receives", chunking/`tasks:`), public docs, PROJECT.md, release note (wave 4)
- [x] 179-07-PLAN.md — Minimal example fixes: ecommerce `Category.search_records/2`, phoenix Oban smoke `repo:` (wave 4, droppable)

### Phase 180: Oban worker telemetry

**Goal**: Operators can observe every Oban upsert and delete job, including deletes for records that no longer exist, through stable, documented telemetry.
**Depends on**: Phase 179 (span metadata reports document counts over the chunked calls and covers the new non-retrying error outcomes)
**Requirements**: OBS-01, OBS-02, OBS-03
**Success Criteria** (what must be TRUE):
  1. A test attaching telemetry handlers sees start, stop and exception events from the Oban upsert and delete workers, each carrying schema, index, backend, document count and attempt.
  2. A test shows that when a job finds ids with no current record and deletes them from the index, an event fires with the count of those ids.
  3. The telemetry guide lists the new events and metadata keys, and its docs contract test fails if a documented event or key drifts from the emitted ones.

**Plans**: 3/3 plans complete

Plans:
**Wave 1**
- [x] 180-01-PLAN.md — Upsert/delete worker spans, `job_stop_metadata/1`, `missing_removed` event, capture helper and scenario support (wave 1)
- [x] 180-02-PLAN.md — `guides/telemetry.md` catalog wired into HexDocs, duplicate tables to pointers, ARCHITECTURE wording, related-worker 4xx cancel shape (wave 1)

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 180-03-PLAN.md — Untagged telemetry drift contract test: name scan, literal-name guard, key contract (wave 2)

### Phase 181: Schema hook contract and no-Oban build

**Goal**: Adopters see and get compiler checks for the schema hooks they can implement, and apps without Oban compile Scrypath with zero warnings.
**Depends on**: Phase 180 (the no-Oban warnings gate runs after the milestone's Oban-touching changes have landed)
**Requirements**: HYG-01, HYG-02
**Success Criteria** (what must be TRUE):
  1. `search_records/2`, `search_document_id/1` and the other duck-typed schema hooks are declared as `@optional_callbacks` on a behaviour that appears in the generated HexDocs, and a test or compile check flags a hook implemented with the wrong arity.
  2. A build without Oban compiles with `--warnings-as-errors`, with no blanket warning suppression, and this check runs inside an existing CI lane on the phase PR.

**Plans**: 2/2 plans complete

Plans:
**Wave 1**
- [x] 181-01-PLAN.md — Isolated, self-proving no-Oban build (fixes the false green), RelatedEnqueue on the shared job builder, check composed into `verify.core` (HYG-02, wave 1)

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 181-02-PLAN.md — Hooks as documented `@optional_callbacks` on `Scrypath.Schema`, injected `@behaviour`, wrong-arity compile warning (HYG-01, wave 2)

### Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 178. Loader-routed backfill and full-key paging | 5/5 | Complete    | 2026-10-25 |
| 179. Bounded id lists and related-sync parity | 7/7 | Complete    | 2026-10-25 |
| 180. Oban worker telemetry | 3/3 | Complete    | 2026-10-25 |
| 181. Schema hook contract and no-Oban build | 2/2 | Complete    | 2026-10-26 |
