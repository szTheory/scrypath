# Phase 197: Pilot JOB-03, unhealthy verdict to verified retry - Context

**Gathered:** 2026-11-22
**Status:** Ready for planning

<domain>
## Phase Boundary

One job end to end: Search health row, to Failed sync prefilled, to retry, to return, for the paged on-call engineer (ROLE-OPS, JOB-03) on Shopadelic data. Order is binding: the mounted `Phoenix.LiveViewTest` journey is written first and is green on current code; the stale-sudo `return_to` defect (D1) is fixed with its own test; the Search health and Failed sync surfaces are then extracted into pure view-models and shared function components under that safety net (a before and after rendered-HTML parity capture shows no unintended change, the journey stays green unmodified); one `catalog_contract_test.exs` carries render-all, route, component coverage, no-identical-variations, copy lint and DOM hygiene as required-gate ledger row 11 of 12; a stable seeded storybook runs on 127.0.0.1:4003 with a `storybook` block in `.planning/UI-PREVIEW.json` and a landing page showing `main@sha`; then the run stops (Pause 1) for the maintainer's look. Not in this phase: Sync and index as a whole surface (only its two recovery areas), Control room, Search, Help, a second journey, Clinicly and Chatly sets, a browser CI job, any authorization refactor of `Gating`, never-index or read-denial stories.

</domain>

<decisions>
## Implementation Decisions

### Recorded maintainer decisions (adopted 2026-11-21, SYNTHESIS.md, ADR 0001 and 0002; not re-opened here)
- The pilot job is JOB-03 end to end, entering at Search health (Search health is the cheapest first extraction slice, not the pilot) — **Reversibility:** costly — SYNTHESIS records it; changing the pilot changes the plans, stories and contract test
- Journey first and green on current code, then extraction; the parity capture is throwaway local evidence (not a CI gate); the journey stays green unmodified through extraction
- Story tiers are the glossary tiers `primitives/ patterns/ areas/ surfaces/ jobs/` (not Screen/Flow); JOB ids in file paths; adopter as a variation dimension; both themes shown; scrypath chrome keeps the Scrypath brand; adopter theming only in one Hosting story; story descriptions claim no more than the linked test proves. The glossary and the playbook tier wording are edited in the same change so they agree — **Reversibility:** costly — folder names and ids are public to the maintainer's review notes
- The catalog contract test runs inside the existing `ops-ui` job as ledger row 11 of 12 with a deletion trigger and expected churn recorded in `CONTRIBUTING.md`; no new required CI context, no branch-protection change
- The seeded storybook is on 127.0.0.1:4003 with its own `storybook` block in `.planning/UI-PREVIEW.json`; the 4002 preview stays the mounted-behavior surface; `npm run ui:preflight` checks both; AGENTS.md "UI work" is updated to match
- Findings stay with the maintainer unless they say otherwise: F1, F2, D2, F3, F4 (see GO-NO-GO.md and 196-FINDINGS.md); the stale-sudo `return_to` defect D1 is the one defect fixed here, in `scrypath_ops` only, with no root `lib/` change, under a `chore` or `test` PR title that says plainly it fixes a defect
- No Hex release and no release PR; PR titles are `docs`, `chore`, `test` or `ci`; never stage `.planning/config.json`, `.planning/state.json`, `.impeccable/config.json`; at most 5 plans (the milestone stops and re-asks at 20; 8 of 17 planned are done)
- One operator persona in this phase; no `decide` function for authorization; `retry_decision` (eligibility, not authorization) is cut first if the pilot overruns
- Refused: state grids or manifests, hash-bound or screenshot baselines, an LLM critic as a gate, a parallel gallery, a second journey

### Carried from Phase 195 and 196
- Phase 195 mounted `phoenix_storybook` (dev/test only, route guard outside the quote with `Application.compile_env`, `storybook.js` hooks, five primitives, render-all through the real iframe route with LazyHTML selectors and cause-pinned planted failures). `catalog_contract_test.exs` already exists with the render-all describes: this phase extends it, never replaces it
- Phase 196 built `fixtures/scrypath_fixtures` (11 scenarios across Logistify, Shopadelic, Wikily; `Check.invariants/0` with 31 tags; the check task first in the `test` alias). Shopadelic `settings_drift` and `failed_journey` are the pilot's data; builders take `now`; the fake client and fake inspector feed the real normalizers
- The fidelity probe deferred from Phase 195 (a local, non-gating computed-style comparison of a story against the real ops screen, light and dark) is a Phase 197 task with a recorded result, not a gate
- Phase 196 review hand-offs this phase must check before claiming counts: the fake Oban inspector models schema scoping only (the real inspector filters by queue and caps at 100 rows, so a 195-job deep queue is not reachable through it); several `states/0`-style functions have no callers until stories use them
- Lessons: assert with LazyHTML selectors, never regexes over raw HTML; every planted failure asserts its cause; long lanes are phase gates, not per-task checks; commit nothing while a Docker lane runs; set `HEX_HTTP_TIMEOUT=120` for local `mix verify.ops_ui`

### Fixtures fold evaluation (ADR 0002 exit rule, decided here)
- `fixtures/scrypath_fixtures` still has one consumer (`scrypath_ops`) and the storybook lives inside it. The exit rule folds it into `scrypath_ops/` if no second consumer appears by Phase 197. This phase does not fold it silently: the Pause 1 note presents the evidence (one consumer; the measured hosted cost of keeping it was warm minus control of -3 s; folding is one plan of renames plus reversing the root accounting) with a recommendation, and the maintainer decides at the pause — **Reversibility:** costly — folding moves a top-level project and touches the boundary tests, Docker stages and classifier

### Decided autonomously
- [Plan order] Q: "How are the five plans ordered?" → Selected: "(1) journey on current code, repaired `failed_sync_live_test.exs:540`, parity capture script; (2) view-models and Search health areas and stories; (3) Failed sync areas and stories; (4) recovery areas, the `return_to` fix and the catalog contract test; (5) the 4003 seeded storybook, `UI-PREVIEW.json`, preflight, AGENTS.md, landing page, the fidelity probe and the Pause 1 note" — plan boundaries are planning metadata and cheap to re-cut; the planner may re-cut within the 5-plan cap
- [View-model split] Q: "How is `Posture.summary/4` made storiable?" → Selected: "Split into `scan/2` (I/O) and `build/4` (pure), closed enums for page state, summary kind, row action and recovery status" — internal module shapes, cheap to revise
- [Story count] Q: "How many stories?" → Selected: "About 40 variations at most; drop any that render identically" — a cap, not a contract
- [Copy lint reuse] Q: "How is copy linted?" → Selected: "Reuse the existing `copy_rules.json` and `CopyRules` helpers over every story's rendered HTML, adding 4 to 6 pilot surfaces only for states the mounted pages can reach" — no new rule engine
- [Seeded server mechanism] Q: "How does 4003 serve stable seeded data?" → Selected: "A dev-env storybook serving fixtures with the pinned preview epoch, no database data required; the planner and researcher choose the exact mechanism and prove it is stable across restarts" — an implementation detail with a recorded proof

### Claude's Discretion
- Module, component and story names within the tiers, the exact set of areas per surface, the parity-capture script's form, and the landing page layout (it must show `main@sha`, the tiers, and a short "what you are looking at" note; it must not claim a design is approved)

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scrypath_ops/lib/scrypath_ops_web/live/{posture_live,failed_sync_live,sync_drift_live}.ex`, `ScrypathOps.Posture` (summary/4 does scan I/O), `OpsUi` function components, `CopySurfaces` test helper and `copy_rules.json`, `Phase173FixtureSource` (do not edit; identity-hashed in receipts), `Gating` (imperative, reads `DateTime.utc_now()`)
- `scrypath_ops/catalog/lib/scrypath_ops/catalog/storybook.ex`, `scrypath_ops/storybook/primitives/*.story.exs`, `catalog_contract_test.exs`, `test/support/catalog_render_all.ex`, `fixtures/scrypath_fixtures`
- `.planning/UI-PREVIEW.json`, `npm run ui:preflight` (demo directory), `examples/scrypath_ecommerce/e2e/UI-REVIEW.md`, `operator.spec.ts` (the real-browser proof of the chain; do not duplicate)

### Established Patterns
- Presentation in Failed sync is mostly `defp` over assigns (`failed_sync_live.ex` ~473-830); recovery helpers in `sync_drift_live.ex` ~578-667; only SearchLive assigns `:return_to` (defect D1)
- Receipts are in-process LiveView state (return from Sync and index likely shows Retry again: finding D2, recorded not fixed; the journey records what it observes without encoding the defect as expected behavior)

### Integration Points
- `scrypath_ops/mix.exs` (any new dependency would be a decision; none expected), `.planning/UI-PREVIEW.json`, `AGENTS.md` "UI work", `CONTRIBUTING.md` gate ledger, `GLOSSARY.md` tier names

</code_context>

<specifics>
## Specific Ideas

Primary references: [D-pilot-job-and-composable-liveviews.md](../../research/catalog-prep/D-pilot-job-and-composable-liveviews.md) (journey steps, extraction pattern, tier ladder, story names), [F-review-loop-and-catalog-ux.md](../../research/catalog-prep/F-review-loop-and-catalog-ux.md) (landing page, feedback rows), [E-verification-and-gates.md](../../research/catalog-prep/E-verification-and-gates.md), and the Phase 195 and 196 summaries and GO-NO-GO. Where a note disagrees with SYNTHESIS.md, SYNTHESIS and H win.

</specifics>

<deferred>
## Deferred Ideas

- Sync and index as a whole surface, Control room, Search, Help, Clinicly and Chatly sets, the local browser check: Phase 198 or v1.51
- Findings F1, F2, F3, F4, D2 and the dashboard_routes guard defect: with the maintainer
- A typed authorization `Gating.decide` and a read-denial model: no second consumer, deferred

</deferred>
