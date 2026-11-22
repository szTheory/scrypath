# Requirements: Scrypath v1.49 Catalog foundation

**Defined:** 2026-11-21
**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

Scope source: the maintainer's adoption on 2026-11-21 of [catalog-prep/SYNTHESIS.md](research/catalog-prep/SYNTHESIS.md) (seven prep notes A to G and an adversarial pass H; where a note disagrees, SYNTHESIS and H win), on top of the recorded 2026-10-25 decision (ADR 0001, UI engine D1) and the 2026-11-21 feedback session ([FEEDBACK-SESSION-2026-11-21.md](research/storybook-catalog/FEEDBACK-SESSION-2026-11-21.md)). The original input is kept at [catalog-prep/MILESTONE-CONTEXT-v1.49.md](research/catalog-prep/MILESTONE-CONTEXT-v1.49.md). Phases 195 to 198, about 15 plans, stop and re-ask at 20, at most 5 plans per phase. The two pre-work PRs (#169, #170) are merged and are not part of this milestone. Research for this milestone was done upstream; no separate research step ran.

Every criterion below is an executable check, a recorded number or a recorded decision, stated as such. Nothing here claims that the catalog "looks good", that a design is approved, or that anyone reviewed it; those stay explicitly unproven until the maintainer's look (Phase 185 correction in AGENTS.md).

## v1 Requirements

### Mount and prove (Phase 195)

- [x] **MOUNT-01**: `phoenix_storybook ~> 1.5` is a dev/test-only dependency of `scrypath_ops` (`only: [:dev, :test]`). The existing storybook row in `dependency_boundary_contract_test.exs` flips from vacuous to real: it asserts the dependency is present with that `only` list, and a planted loosening (the dependency in prod, or removed) fails it. `PhoenixStorybook` and `MDEx` are in the absent-module list for every mounted and direct-prod scratch consumer and in the `forbidden_dep` and `forbidden_modules` lists of `verify-dependency-boundaries.sh` (prod image); `package_metadata_test.exs` refutes `fixtures` and `storybook` in the Hex tarball.
- [x] **MOUNT-02**: The storybook route exists only in dev and test, bound to loopback. The route macro's environment guard sits outside the `quote`; a test proves the production route table (`DevRouter.__routes__()` or the prod scratch consumer probe) has no `/storybook` path, with a planted case that fails if the guard is removed. No storybook route is ever mounted in the ecommerce host's production image.
- [x] **MOUNT-03**: The storybook renders with ScrypathOps's real styling and hooks: `css_path` points at the built `/assets/css/app.css`, a small `storybook.js` sets the theme attribute the app uses and registers the same LiveView hooks as `app.js`, and five primitives have stories. A render-all test loads every story variation through the real iframe route (not a helper that bypasses it) and fails on empty output or `data-phx-error`; a planted failing story proves it can fail. Variations that carry adopter brand colors keep them outside the roots the UI literal ratchet scans.
- [x] **MOUNT-04**: A measured go/no-go is recorded in `GO-NO-GO.md` and ADR 0001 is amended with the numbers: cold and warm `ops-ui` timings from a hosted run (`gh run view <id> --json jobs`), the Rust NIF fetch time, lock growth, and whether a phoenix_storybook advisory is open. Continue is pre-authorized unless an ADR 0001 trigger trips (advisory open over 14 days; cold `ops-ui` more than 3 minutes over baseline; isolation work over a day; the Docker asset-builder stage more than 60 seconds over; NIF failure twice). If a trigger trips, the run stops and asks the maintainer; the milestone does not continue on its own.

### Fixtures and three adopters (Phase 196)

- [x] **FIX-01**: A `fixtures/scrypath_fixtures` Mix project (ADR 0002) holds pure builders that take `now` and emit raw Meilisearch task maps and Oban job maps, so the real `Operator.Status`, `FailedWork` and `Posture` code does the normalizing and only reachable states can be written. The first slice is a tracer bullet: the Logistify builder through the fake client to a rendered posture, before any other builder exists. A recorded exit rule folds the project into `scrypath_ops/` if no second consumer appears by Phase 197.
- [x] **FIX-02**: Real Meilisearch task payload shapes are recorded once from a task-scoped Docker run (and the container removed afterward). Every failure string in the fixtures comes from a closed table with a `source:` field pointing at a real Meilisearch error code or a Scrypath path; hostile text (markup, very long values, non-Latin text) is stored as escapes. Failures the library cannot produce (per-tenant drift, "11 minutes of lag", per-document size limits, out-of-order replay overwrite on the Oban path) are not fabricated.
- [x] **FIX-03**: Three Scrypath-owned fictional adopters exist, each with named states: **Shopadelic** (the journey and settings drift), **Logistify** (a deep queue with nothing failed), **Wikily** (an empty install). Realistic ordinary data comes first; stress cases are separate named variations. Nothing is copied from the six sibling brand repos.
- [x] **FIX-04**: A DB-free `check_fixtures` task runs first in the `test` alias of its consumers, with a planted failing case; two renders of a builder with different `now` differ only in time-derived text (no wall-clock reads). `package_metadata_test` (or its sibling) asserts `fixtures/` never ships in the Hex tarball, which ADR 0002 claims but nothing currently asserts. The CI path classifier and `package_contents_test` decisions for the new top-level `fixtures/` are made and recorded. The host's `phase173` fixtures and their `?scenario=` branches stay, with a deletion trigger recorded.

### Pilot: JOB-03, unhealthy verdict to verified retry (Phase 197)

- [x] **PILOT-01**: The mounted journey is written first and passes on current code (`Phoenix.LiveViewTest`, reusing the existing stubs and insert counter): Search health row to Failed sync prefilled with the same index and run (asserted in elements and URL params, not a screenshot), then retry (changed field text and exactly one insert), then the return link back with the same context. Denial paths are covered through the schema allowlist (`That schema is unavailable.`, insert counter 0) and through stale sudo, each with a positive control (the same action with the allowed viewer gives counter 1) and an absence check for protected fixture values. The stale-sudo test at `failed_sync_live_test.exs:540` is repaired so it actually renders the row.
- [x] **PILOT-02**: The stale-sudo `return_to` defect (D1: a stale-sudo operator returns to `/` in production instead of the page they left, because only `search_live.ex:122` assigns `:return_to`) is fixed in `scrypath_ops` with its own test. No root `lib/` change.
- [x] **PILOT-03**: Under the PILOT-01 safety net, the Search health and Failed sync surfaces are extracted into pure view-models with closed enums (`Posture.summary/4` split into scan and build) and function components shared by the LiveView and the story. A throwaway rendered-HTML parity capture before and after shows no unintended change, and the PILOT-01 journey stays green unmodified. Slice order: Search health first (cheapest), then Failed sync and recovery.
- [x] **PILOT-04**: Stories live in the glossary tiers `primitives/ patterns/ areas/ surfaces/ jobs/`, with the adopter as a variation dimension, JOB ids in file paths (the sidebar search reads only path and name), and both themes shown. Scrypath chrome keeps the Scrypath brand; adopter theming appears in one Hosting story only. Story descriptions claim no more than the linked test proves.
- [x] **PILOT-05**: One test file (`catalog_contract_test.exs`) carries render-all, route and component coverage (no hard-coded counts; a literal `@no_story` map with reasons, stale entries failing), no-two-identical-variations, copy lint over rendered variations (the existing `CopyRules` forbidden lists), and DOM hygiene (unique ids, existing `aria-*` targets, accessible names, one `main` landmark per screen-tier story). Each check has one planted failing input. It runs inside the existing `ops-ui` job as required-gate ledger row 11 of 12, with a deletion trigger and expected churn recorded in `CONTRIBUTING.md`; no new required CI context is created.
- [ ] **PILOT-06**: A stable seeded storybook runs on 127.0.0.1:4003 with its own `storybook` block in `.planning/UI-PREVIEW.json`, a landing page that shows `main@sha`, and an extension of `npm run ui:preflight` that checks it; the 4002 preview stays the mounted-behavior surface, and AGENTS.md "UI work" matches.
- [x] **PILOT-07**: Pause 1 happens: the run stops after Phase 197, the maintainer looks at the storybook, and their feedback is recorded verbatim in a dated note under `.planning/research/` as rows of storybook path, variation id, theme and viewport (or "unknown"). The feedback sizes Phase 198 (cut, shrink or run).

### Scale (Phase 198, cut by default; sized after Pause 1)

- [ ] **SCALE-01**: Stories exist for the remaining small screens (Control room, help, and the failed-sync remainder), each covered by the PILOT-05 checks without a new gate. Search and Sync-and-index only if the Pause 1 feedback asks.
- [ ] **SCALE-02**: A Clinicly story set shows only denials the product really has (schema allowlist, stale sudo; ScrypathOps has no read-denial), and a Chatly set shows a reindex swap and CJK text. If real denials cannot support a never-index headline, the default is to proceed with real denials.
- [ ] **SCALE-03**: A local browser check (at most 10 fixed iframe URLs, 375 and 1280 wide, light, dark and system-dark) fails on serious or critical axe findings, page-level horizontal overflow, and a theme probe that proves the sandbox applies the theme; an ExUnit test asserts every listed URL resolves to a story. It runs locally first and is advisory if it ever runs hosted; it is not a required gate.

### Standing rules (every phase)

- [x] **FLOW-01**: No Hex release and no release PR in this milestone. Every PR title is `docs`, `chore`, `test` or `ci`, never `feat` or `fix`: release-please has one root package and no `exclude-paths`, so a `feat:` or `fix:` that touches `scrypath_ops/` opens a release PR. The PILOT-02 fix therefore ships under a `chore(ops-ui):` or `test(ops-ui):` title, and the PR body says plainly that it fixes a defect. A change that cannot honestly carry one of those titles is raised with the maintainer before merge.
- [x] **FLOW-02**: Each phase stays within its plan cap (5), and the milestone stops and re-asks at 20 plans. Ask-first items stay ask-first: an ADR 0001 trigger tripping or a no-go; a new required CI context or branch-protection change; changing root `lib/` behavior (including findings F1 and F2); copying from the six sibling brand repos; a runtime dependency beyond the storybook subtree.
- [x] **FLOW-03**: `.planning/config.json`, `.planning/state.json` and `.impeccable/config.json` are never staged; every commit names its paths explicitly. Every phase's local mirror of each required lane runs before a push (pre-push confidence), and a skipped one has a recorded reason.
- [x] **FLOW-04**: Findings F1 (`Tasks.list_sync_tasks` truncates history at 1,000 tasks though Meilisearch keeps about 1M), F2 (the ops UI prints Meilisearch error messages unbounded), D2 (retry receipts are per-process) and the test-hygiene items in SYNTHESIS are recorded and handed to the maintainer, not fixed, unless the maintainer says so.
- [ ] **FLOW-05**: The milestone-end review happens after the last executed phase and before the audit: the storybook is refreshed to current `main`, the maintainer is told what UI changed and where to look, and the run waits (AGENTS.md "Milestone-end review"). The feedback note is folded into the v1.50 input.

## v2 Requirements

Deferred, tracked but not in this roadmap.

- **ADOPT-01**: v1.50 Adopter-ready (Phases 199 to 201): a "Testing your app" guide with no new API, a fresh-consumer walk, then highlight/crop or a paging guard only after an API-grilling session. First release 0.3.21 with the maintainer's yes.
- **CATB-01**: v1.51 Catalog breadth: remaining screens, a second mounted journey, the storybook as the review surface; only if Phase 198 is cut or the review says widen.
- **CATB-02**: Hosted advisory `catalog-browser` job (path-filtered, 10-minute timeout), promoted to required only after 14 clean nights and a maintainer branch-protection change.
- **ANNC-01**: v1.52 Announce-ready: website content with product images from stories, a maintainer-run announcement.
- **OPSH-01**: ScrypathOps on Hex is a decision (ADR and package dry run first), not planned.

## Out of Scope

| Feature | Reason |
|---------|--------|
| A Hex release or release PR | Nothing releasable exists; the first release ships with v1.50 and needs the maintainer's yes |
| Coverage manifest or state grid | Refused until the same missing-state class appears twice (E section 5) |
| Hash-bound receipts, screenshot ledgers, per-state pixel baselines | A review dispute or shipped visual regressions the checks missed would be the trigger (E section 5) |
| An LLM critic as a gate | Never a gate; an on-demand rubric skill is already the UI-engine decision |
| Parallel gallery, per-story axe sweep | Only a gate shown to be vacuous by a real miss would justify it |
| A required browser CI job | Needs 14 clean nights and a branch-protection change |
| Seven adopters at once, Clinicly never-index headline | ScrypathOps has no read-denial; three Scrypath-owned adopters first |
| A viewer or role model in ScrypathOps | None exists in source; a catalog must not invent one |
| Fixing F1, F2, D2 | Root `lib/` change (ask-first) or not a catalog concern; handed to the maintainer |
| Copying from the six sibling brand repos | Reuse grant is not needed for Scrypath-owned adopters |
| Human UAT as a completion gate | Every criterion is an executable check or a recorded decision |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| MOUNT-01 | Phase 195 | Complete |
| MOUNT-02 | Phase 195 | Complete |
| MOUNT-03 | Phase 195 | Complete |
| MOUNT-04 | Phase 195 | Complete |
| FIX-01 | Phase 196 | Complete |
| FIX-02 | Phase 196 | Complete |
| FIX-03 | Phase 196 | Complete |
| FIX-04 | Phase 196 | Complete |
| PILOT-01 | Phase 197 | Complete |
| PILOT-02 | Phase 197 | Complete |
| PILOT-03 | Phase 197 | Complete |
| PILOT-04 | Phase 197 | Complete |
| PILOT-05 | Phase 197 | Complete |
| PILOT-06 | Phase 197 | Pending |
| PILOT-07 | Phase 197 | Complete |
| SCALE-01 | Phase 198 | Pending |
| SCALE-02 | Phase 198 | Pending |
| SCALE-03 | Phase 198 | Pending |
| FLOW-01 | Phase 195 (standing, every phase) | Complete |
| FLOW-02 | Phase 195 (standing, every phase) | Complete |
| FLOW-03 | Phase 195 (standing, every phase) | Complete |
| FLOW-04 | Phase 195 (standing, every phase) | Complete |
| FLOW-05 | Phase 198 (also runs after Phase 197 if 198 is cut) | Pending |

**Coverage:**
- v1 requirements: 23 total
- Mapped to phases: 23 (Phase 195: 8 including standing FLOW-01 to FLOW-04; 196: 4; 197: 7; 198: 4 including FLOW-05)
- Unmapped: 0 ✓

---
*Requirements defined: 2026-11-21*
*Last updated: 2026-11-21 after roadmap creation (traceability mapped)*
