# Roadmap: Scrypath

## Milestones

- 🚧 **v1.50 Adopter-ready** — Phases 199–201 (3 phases, about 5 to 6 plans, 16 requirements; opened 2026-11-25; cut line after Phase 201; two Hex releases, each only on the maintainer's explicit yes) — scope: [v1.50-prep/SYNTHESIS.md](research/v1.50-prep/SYNTHESIS.md)
- ✅ **v1.49 Catalog foundation** — Phases 195–197 (3 phases, 13 plans, 20 of 23 requirements; Phase 198 and SCALE-01 to SCALE-03 cut by the maintainer; shipped to `main` via PRs #171, #174, #177 and review PRs #180 to #186 plus the closeout; `tech_debt`; not released to Hex) — [archive](milestones/v1.49-ROADMAP.md)
- ✅ **v1.48 Discovery and onboarding** — Phases 192–193 (2 phases, 6 plans, 13 of 16 requirements; Phase 194 and SITE-07 to SITE-09 cut at the entry-point checkpoint; shipped to `main` 2026-11-21 via PRs #160, #163, #164; `tech_debt`; Hex 0.3.20 carries Phase 192, the Phase 193 regroup waits for the next release) — [archive](milestones/v1.48-ROADMAP.md)
- ✅ **v1.47 Brand completion** — Phases 188.1, 189–191 (4 phases, 8 plans, 18 of 18 requirements; shipped to `main` 2026-11-20 via PRs #149, #152, #153, #154; `tech_debt`; not released to Hex; website deployed) — [archive](milestones/v1.47-ROADMAP.md)
- ✅ **v1.46 Brand foundation and re-skin** — Phases 186–188 (3 phases, 16 plans, 27 of 29 requirements; shipped to `main` 2026-11-19 via PRs #137, #138, #139, #143; `tech_debt`; not released to Hex; Phases 189 and 190 landed in v1.47) — [archive](milestones/v1.46-ROADMAP.md)
- ✅ **v1.45 Foundation and CI** — Phases 182–185 (archived locally 2026-11-01; qualified `tech_debt` closeout; final-source acceptance external; merge/publication separate) — [archive](milestones/v1.45-ROADMAP.md)
- ✅ **v1.44 Sync correctness** — Phases 178–181 (4 phases, 17 plans, 45 tasks; archived locally 2026-10-26; `tech_debt` carried forward; PR #122 merge/publication pending) — [archive](milestones/v1.44-ROADMAP.md)
- ✅ **v1.43 ScrypathOps UI refinement** — Phases 173–177 (5 phases, 21 plans; archived 2026-10-25; first shipped in `scrypath` 0.3.16) — [archive](milestones/v1.43-ROADMAP.md)
- ✅ **v1.42 ScrypathOps operator/admin UI** — Phase 172 (1 phase, 8 plans; archived2026-10-04) — [archive](milestones/v1.42-ROADMAP.md)
- ✅ **v1.41 Readiness Gate Follow-Through** — Phases 168–171 (4 phases, 19 plans; archived 2026-10-02; `tech_debt` accepted; original Phase 170 decision remains NOT READY at its cutoff; later separate readiness assessment is READY) — [archive](milestones/v1.41-ROADMAP.md)
- ✅ **v1.40 Readiness Evidence Closure** — Phases 165–167 (archived locally 2026-09-27; no Hex release; assessment remains NOT READY) — [archive](milestones/v1.40-ROADMAP.md)
- ✅ **v1.39 Pre-Operator UI Quality Readiness Ratchet** — Phases 162–164 (archived locally 2026-09-26) — [archive](milestones/v1.39-ROADMAP.md)
- ✅ **v1.38 Packaged Adopter Proof** — Phases 160–161 (shipped 2026-09-25; `scrypath 0.3.13`) — [archive](milestones/v1.38-ROADMAP.md)
- ✅ **v1.37 Code Quality Ratchet** — Phases 148–159 (shipped 2026-08-26) — [archive](milestones/v1.37-ROADMAP.md)
- ✅ **v1.36 Dependency Security Remediation** — Phases 144–147 (shipped 2026-08-25) — [archive](milestones/v1.36-ROADMAP.md)
- ✅ **v1.35 Brand System & Logo Identity** — Phases 137–143 (shipped 2026-06-24) — [archive](milestones/v1.35-ROADMAP.md)
- ✅ **v1.34 Both-Themes Perfection — Dark Signature + AA Gate** — Phases 128–136 (shipped 2026-06-29) — [archive](milestones/v1.34-ROADMAP.md)

## Current Posture

v1.50 Adopter-ready is the active milestone (opened 2026-11-25): a new adopter can follow the published docs against a secured Meilisearch and get working search, honest status and a way to test it. Scope is the maintainer's adoption on 2026-11-25 of [v1.50-prep/SYNTHESIS.md](research/v1.50-prep/SYNTHESIS.md) (notes A to D); root `lib/` fixes are in scope. Phase 199 (the documented path works) is next, starting with its discuss step. Hex 0.3.21 (2026-11-25, the Meilisearch bearer-token fix) is the latest release. The milestone needs two more releases, each only on the maintainer's explicit yes: one after Phase 199, because the Phase 200 walk must use a published package, and one at the end of Phase 201. The run stops at each release point and at the milestone-end review.

v1.49 Catalog foundation is closed and archived ([audit](milestones/v1.49-MILESTONE-AUDIT.md), `tech_debt`, closed with a recorded override: the phase reports predate the review changes). The adopted order after v1.50 is v1.51 agent diagnosis, v1.52 catalog breadth ([rolling roadmap](reference/ROLLING-ROADMAP.md)).

v1.48 Discovery and onboarding is archived ([audit](milestones/v1.48-MILESTONE-AUDIT.md), `tech_debt`, no unsatisfied requirement; the optional website phase was cut at the entry-point checkpoint, see [research/v1.48-prep/CHECKPOINT.md](research/v1.48-prep/CHECKPOINT.md)).

`deep-quality` is an advisory red. Besides the known cause (cloak and cloak_ecto via optional sigra, until sigra ships without a hard `cloak_ecto` requirement), the flop, db_connection and phoenix advisories listed in the v1.49 audit were patched on 2026-11-25, and the retired sigra 1.20.0 release is reported too. The audit stays fail-closed. The v1.45 archive keeps its documented debt and historical verification overrides.

## Phases

**Phase numbering continues from v1.49 (the first v1.50 phase is 199).** Plan cap is 5 per phase; the milestone stops and re-asks beyond 7 plans. Cut line after Phase 201: nothing further is built in v1.50 without the maintainer asking.

- [ ] **Phase 199: Documented path works** - reproduce first, then make the golden path's filtered and sorted search, `sortable:` settings, the Oban queue read and task history past 1,000 work against a keyed Meilisearch (2 to 3 plans)
- [ ] **Phase 200: Fresh-consumer walk** - a blind walk from the published package and HexDocs only, graded by a separate script, recorded unedited as maintainer-side friction evidence (1 plan; needs release point 1)
- [ ] **Phase 201: Testing guide** - "Testing your app" with no new public API, the walk's documentation fixes, release point 2 and a rerun of failed walk tasks; **cut line** (about 2 plans)

## Phase Details

### Standing rules (every phase)

FLOW-01, FLOW-02, FLOW-03 and FLOW-04 are not deliverables of one phase. They are mapped to Phase 199 for traceability and **stand for every phase** in v1.50 (as in v1.49):

- FLOW-01: no Hex release and no release-PR merge without the maintainer's explicit yes. A `fix:` title is allowed for a real library fix; the release PR it opens stays open until then.
- FLOW-02: no new public API, runtime dependency, highlight or crop support, or paging guard without asking. At most 5 plans per phase; stop and re-ask beyond 7 plans in the milestone.
- FLOW-03: never stage `.planning/config.json`, `.planning/state.json` or `.impeccable/config.json`; name commit paths explicitly; run every required lane's local mirror before a push (including `mix verify.ops_ui` for any `scrypath_ops/` change) and record any skip with its reason. Tests of external contracts run against a Meilisearch configured like production (master key set).
- FLOW-04: the milestone-end review happens after the last executed phase and before the audit, even though this milestone is not expected to change UI.

### Release sequencing (REL-01)

REL-01 is one requirement, mapped to Phase 201, met at two release points. Each point stops the run for the maintainer's explicit yes; neither is pre-authorized.

- **Release point 1 (between Phase 199 and Phase 200).** Phase 199's `fix:` merges open the release PR (expected 0.3.22). The run stops after Phase 199 and asks. On a yes, the release PR is merged, the package publishes, and the release verification passes before Phase 200 starts. The walk needs the fixes as a **published** Hex package with its HexDocs: a git or path dependency does not satisfy the walk protocol. If Phase 199 ends with nothing that ships (every defect failed to reproduce and no guide changed), there is no release point 1 and the walk runs on 0.3.21. If the maintainer declines or defers the release, Phase 200 waits; it does not run against unreleased code.
- **Release point 2 (inside Phase 201, before the rerun).** The testing guide and the walk's documentation fixes ship in HexDocs only through a Hex publish (expected 0.3.23). The run stops and asks; on a yes the package publishes and passes the release verification, and only then are the failed walk tasks rerun against it.

### Phase 199: Documented path works

**Goal**: An adopter who follows the golden path, `getting-started.md` or `phoenix-walkthrough.md` against a keyed Meilisearch gets a working filtered and sorted search, and Scrypath's status, failed-work and reconcile calls tell the truth about the Oban queue and about long task histories.
**Depends on**: Nothing (first phase of v1.50; the bearer-token fix already shipped in 0.3.21)
**Requirements**: PATH-01, PATH-02, PATH-03, PATH-04, PATH-05, PATH-06, FLOW-01, FLOW-02, FLOW-03, FLOW-04 (FLOW-01 to FLOW-04 stand for every phase)
**Success Criteria** (what must be TRUE; each is an executable check, recorded result or recorded decision):
  1. Each defect (golden-path search, `sortable:` and set comparison, unread Oban queue, history past 1,000 tasks) has a test that fails on current code, committed before its fix, and run against a keyed Meilisearch where it touches the server; a defect that does not reproduce is dropped and its passing evidence is recorded in the phase directory.
  2. A live test against a keyed Meilisearch runs the golden-path schema, settings step and filtered, sorted search exactly as `golden-path.md` writes them (the settings step waits for its task) and gets the expected hits; the same pattern in `getting-started.md` and `phoenix-walkthrough.md` is covered by the same test or a guide contract test, and a planted failure (settings step removed, or a filtered or sorted field left out of `fields:`) fails it.
  3. A captured settings payload contains the declared `sortable:` attributes with no explicit `settings:` override, an explicit `settings:` value is kept, and drift and reindex verification report no drift for two sortable attributes and stop words returned in reverse order; the upgrade note states the setting applies at the next settings apply or reindex.
  4. In Oban mode with no custom inspector, a discarded upsert job is returned by `failed_sync_work/2`, and with no running Oban instance the status reports the queue as not observed; an explicit inspector behaves as before.
  5. With 1,200 succeeded tasks and one older failure, status, failed-work and reconcile calls return ok, include the failure and flag the history as partial, and an empty result never comes from a partial read (planted case). The five leads (second managed reindex, second promotion after cutover, retry by id ignoring the source, a settings diff naming a task that does not exist, reindex offered while one is pending) each have a recorded result; a reproduced lead is fixed with a failing-first test if small, otherwise handed to the maintainer in the phase's findings note.
**Plans**: TBD (estimate 2 to 3, cap 5). Ends at release point 1: the run stops for the maintainer's yes before Phase 200.

### Phase 200: Fresh-consumer walk

**Goal**: A blind agent walk from the published package and HexDocs alone, against a production-mode Meilisearch, shows where an adopter still gets stuck, with pass or fail decided by a grader and not by the walker.
**Depends on**: Phase 199 and release point 1 (its fixes published to Hex with the maintainer's explicit yes and the release verification passed; see Release sequencing)
**Requirements**: WALK-01, WALK-02
**Success Criteria** (what must be TRUE; each is an executable check, recorded result or recorded decision):
  1. The walk protocol from [prep note C](research/v1.50-prep/C-adopter-ready.md) section 4 is committed before the first run, with its pins (exact Hex version, toolchain, Meilisearch image by digest in production mode with a master key, a non-master API key for the walker, Postgres, prompt, model, time budget), its fixed task list and its isolation rules (no repository, memory or AGENTS file; HexDocs, hex.pm and official dependency docs only).
  2. A grader separate from the walker checks each task (the walker's tests pass with Meilisearch stopped, a hidden live smoke passes against the keyed server, and a transcript scan finds no forbidden read), and its exit codes are the recorded pass or fail for every task.
  3. Two independent baseline runs are recorded unedited under `.planning/research/v1.50-walk/`: per finding the task, verbatim error, pages read, attempts, severity and bucket, including unfinished tasks and grader failures, with home paths stripped, and the record is labelled maintainer-side friction evidence, not outside-adopter evidence.
  4. The walk's containers, networks and images are task-scoped and gone after the run (`docker system df` checked).
**Plans**: TBD (estimate 1).

### Phase 201: Testing guide

**Goal**: An adopter can test an app that uses Scrypath, inline and with Oban, from one guide with no new public API, the walk's documentation findings are fixed and published, and the failed walk tasks are rerun against that release.
**Depends on**: Phase 200 (its ranked findings feed the documentation fixes)
**Requirements**: TEST-01, TEST-02, TEST-03, REL-01
**Success Criteria** (what must be TRUE; each is an executable check, recorded result or recorded decision):
  1. `guides/testing-your-app.md` exists with no new public API; a root test extracts its code, compiles it and runs inline upsert, delete and search with hydration, and `perform_job` for upsert and delete, with no network, and a planted failure (the stub's task route removed) fails it; the docs build passes with warnings as errors and the guide sits in its HexDocs group.
  2. A contract test pins the worker module names and the job argument keys (`operation`, `schema`, `document_ids`) that the guide asserts on, and they are declared supported in the guide.
  3. The walk's findings are ranked in a recorded list, its documentation fixes are made, and library defects it found that are not small are listed for the maintainer.
  4. Both REL-01 release points are recorded: release point 1 (after Phase 199) and release point 2 (this phase, carrying the guide and the documentation fixes) each happened only after the maintainer's explicit yes, and each published package passed the release verification (`mix verify.release_publish`, `mix verify.release_parity`) plus a keyed live smoke from the Hex package.
  5. The failed walk tasks are rerun against the release point 2 package with the same grader, and the results are recorded beside the baselines; then the milestone-end review (FLOW-04) is offered before the audit.
**Plans**: TBD (estimate about 2, cap 5). **Cut line** after this phase.

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 199. Documented path works | 0/TBD | Not started | - |
| 200. Fresh-consumer walk | 0/TBD | Not started | - |
| 201. Testing guide | 0/TBD | Not started | - |

<details>
<summary>✅ v1.49 Catalog foundation (Phases 195-197) — SHIPPED 2026-11-25</summary>

- [x] Phase 195: Mount and prove (3/3 plans) — PRs #171, #172
- [x] Phase 196: Fixtures and three adopters (5/5 plans) — PRs #174, #175
- [x] Phase 197: Pilot JOB-03, unhealthy verdict to verified retry (5/5 plans) — PR #177
- [~] Phase 198: Scale — cut by the maintainer after Pause 1; the remaining breadth is CATB-01
- [x] Milestone-end storybook review — PRs #180 to #186 and the closeout

Archive: [v1.49-ROADMAP.md](milestones/v1.49-ROADMAP.md), [requirements](milestones/v1.49-REQUIREMENTS.md), [audit](milestones/v1.49-MILESTONE-AUDIT.md).

</details>

<details>
<summary>✅ v1.48 Discovery and onboarding (Phases 192-193) — SHIPPED 2026-11-21</summary>

- [x] Phase 192: Docs truth and README (4/4 plans) — PR #160, Hex 0.3.20
- [x] Phase 193: HexDocs regroup and guards (2/2 plans) — PR #163
- [x] Checkpoint: entry-point signal — PR #164 (cut Phase 194)
- [~] Phase 194: Website content — cut at the checkpoint; SITE-07 to SITE-09 moved to the backlog

Archive: [v1.48-ROADMAP.md](milestones/v1.48-ROADMAP.md), [audit](milestones/v1.48-MILESTONE-AUDIT.md).

</details>

<details>
<summary>✅ v1.47 Brand completion (Phases 188.1, 189-191) — SHIPPED 2026-11-20</summary>

- [x] Phase 188.1: CI path classifier (1/1 plans) — PR #149
- [x] Phase 189: Website re-skin (3/3 plans) — PR #152
- [x] Phase 190: Wording that does not need the catalog (2/2 plans) — PR #153
- [x] Phase 191: Cleanup (2/2 plans) — PR #154

Archive: [v1.47-ROADMAP.md](milestones/v1.47-ROADMAP.md), [audit](milestones/v1.47-MILESTONE-AUDIT.md).

</details>

<details>
<summary>✅ v1.46 Brand foundation and re-skin (Phases 186-188) — SHIPPED 2026-11-19</summary>

See [v1.46-ROADMAP.md](milestones/v1.46-ROADMAP.md).

</details>
