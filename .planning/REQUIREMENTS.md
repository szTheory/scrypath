# Requirements: Scrypath v1.50 Adopter-ready

**Defined:** 2026-11-25
**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

Scope source: the maintainer's adoption on 2026-11-25 of [v1.50-prep/SYNTHESIS.md](research/v1.50-prep/SYNTHESIS.md) (notes A to D). The authentication fix it found is already released as 0.3.21 and is not a requirement here. Every criterion is an executable check, a recorded result or a recorded decision.

## v1 Requirements

### Documented path works (Phase 199)

- [ ] **PATH-01**: Each defect below is first reproduced by a failing test against current code; one that does not reproduce is dropped, with the evidence recorded.
- [ ] **PATH-02**: The golden path's filtered and sorted search, and the same pattern in `getting-started.md` and `phoenix-walkthrough.md`, works as written against a real keyed Meilisearch: filtered and sorted attributes are in the projected fields and the guide has a settings step that waits for the task.
- [ ] **PATH-03**: Declared `sortable:` attributes reach Meilisearch, and drift and reindex verification compare sortable attributes and stop words as sets. The upgrade note says the setting applies at the next settings apply or reindex, and explicit `settings:` values are kept.
- [ ] **PATH-04**: In Oban sync mode without a custom inspector, status and failed-work calls read the host's Oban jobs, or report the queue as not observed; they never report an empty observed queue without reading it. A discarded job is returned by `failed_sync_work/2` in a test with no inspector.
- [ ] **PATH-05**: Status, failed-work and reconcile calls succeed on an index with more than 1,000 tasks and say when the history they show is partial; an empty result never comes from a partial read.
- [ ] **PATH-06**: The leads from prep notes B and D are each checked and recorded: a second managed reindex, a second promotion after cutover, retry by id ignoring the source, a settings diff naming a task that does not exist, and reindex offered while one is pending. A reproduced one is fixed if small, otherwise handed to the maintainer.

### Fresh-consumer walk (Phase 200)

- [ ] **WALK-01**: A blind walk follows the protocol in [prep note C](research/v1.50-prep/C-adopter-ready.md): the published package and HexDocs only, a keyed production-mode server, fixed tasks, and a grader separate from the walker whose exit codes decide pass or fail.
- [ ] **WALK-02**: Every finding is recorded unedited with task, error, pages read, severity and bucket, including unfinished tasks, and labelled maintainer-side friction evidence, not outside-adopter evidence.

### Testing guide (Phase 201, cut line after it)

- [ ] **TEST-01**: `guides/testing-your-app.md` shows inline and Oban testing with no new public API; a test extracts its code, compiles and runs it with no network, and a planted failure fails it.
- [ ] **TEST-02**: The worker names and job argument keys the guide asserts on are declared supported and pinned by a contract test.
- [ ] **TEST-03**: The walk's findings are ranked, its documentation fixes made, and its failed tasks rerun against the published release; library defects it found that are not small are listed for the maintainer.
- [ ] **REL-01**: The milestone's library fixes are released to Hex with the maintainer's explicit yes, and the published package passes the release verification.

### Standing rules (every phase)

- [ ] **FLOW-01**: No Hex release and no release-PR merge without the maintainer's explicit yes. A `fix:` title is allowed for a real library fix; the release PR it opens stays open until then.
- [ ] **FLOW-02**: No new public API, runtime dependency, highlight or crop support, or paging guard without asking. At most 5 plans per phase; stop and re-ask beyond 7 plans in the milestone.
- [ ] **FLOW-03**: `.planning/config.json`, `.planning/state.json` and `.impeccable/config.json` are never staged; commits name paths explicitly; every required lane's local mirror, including `mix verify.ops_ui` for `scrypath_ops/` changes, runs before a push, and a skip is recorded. Tests of external contracts run against a server configured like production (keyed).
- [ ] **FLOW-04**: The milestone-end review happens after the last executed phase and before the audit, as in AGENTS.md "Milestone-end review", even if the milestone changes no UI.

## v2 Requirements

- **AGENT-01**: v1.51 Agent diagnosis: one read-only, versioned diagnosis report (a Mix task plus a release-callable function), see [prep note D](research/v1.50-prep/D-agent-cli.md) and SEED-005.
- **CATB-01**: v1.52 Catalog breadth: remaining screens, a second mounted journey, the storybook as the review surface.
- **ANNC-01**: v1.53 Announce-ready: website content with product images from stories, a maintainer-run announcement.
- **SWAP-01**: Make index swaps observable (finding F3); needs design.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Highlight, crop and paging guard | Not built without a grilling session; document the `settings:` passthrough for pagination |
| A public `Scrypath.Testing` module | The guide covers it without new API; revisit with an ADR if the recipe cannot stay short |
| Agent CLI and any agent-driven write | v1.51, read-only first |
| ScrypathOps chores (error text bounds, receipt wording, `return_to`, catalog origin check) | Small `chore(ops-ui)` PRs outside the phases; they do not gate the milestone |
| `sigra` downgrade | Does not remove the cloak advisories |
| Human UAT as a completion gate | Every criterion is an executable check or a recorded decision |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PATH-01 | Phase 199 | Pending |
| PATH-02 | Phase 199 | Pending |
| PATH-03 | Phase 199 | Pending |
| PATH-04 | Phase 199 | Pending |
| PATH-05 | Phase 199 | Pending |
| PATH-06 | Phase 199 | Pending |
| WALK-01 | Phase 200 | Pending |
| WALK-02 | Phase 200 | Pending |
| TEST-01 | Phase 201 | Pending |
| TEST-02 | Phase 201 | Pending |
| TEST-03 | Phase 201 | Pending |
| REL-01 | Phase 201 (met at two release points: after Phase 199, before the walk; and in Phase 201, before the rerun) | Pending |
| FLOW-01 | Phase 199 (standing, every phase) | Pending |
| FLOW-02 | Phase 199 (standing, every phase) | Pending |
| FLOW-03 | Phase 199 (standing, every phase) | Pending |
| FLOW-04 | Phase 199 (standing; performed after Phase 201, before the audit) | Pending |

**Coverage:** 16 of 16 v1 requirements mapped to exactly one phase; no orphans, no duplicates.

---
*Requirements defined: 2026-11-25*
*Last updated: 2026-11-25 after the v1.50 roadmap was created*
