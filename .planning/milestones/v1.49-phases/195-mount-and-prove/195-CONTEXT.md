# Phase 195: Mount and prove - Context

**Gathered:** 2026-11-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Mount phoenix_storybook in ScrypathOps for dev and test only, with the real styling and hooks. Prove it cannot reach a production dependency graph, a production route table or the Hex tarball. Record a measured go/no-go (`GO-NO-GO.md`, ADR 0001 amended with numbers). Five primitive stories exist, rendered by a render-all test through the real iframe route. Fixtures, adopters, the pilot job and the 4003 preview are later phases (196, 197).

</domain>

<decisions>
## Implementation Decisions

### Recorded maintainer decisions (adopted 2026-11-21, SYNTHESIS.md and ADR 0001; not re-opened here)
- phoenix_storybook `~> 1.5` is a dev/test-only dependency of `scrypath_ops` (`only: [:dev, :test]`), not a hand-rolled harness — **Reversibility:** costly — ADR 0001 records the 2026-10-25 maintainer decision and its fallback; undoing it touches mix.lock, boundary tests and the Docker asset-builder stage
- Spike first (195), fixtures second (196): the spike's risks are external (Rust NIF via mdex, cold `ops-ui`, story-type limits) and fixtures pay off on a no-go
- The catalog runs inside the existing `ops-ui` job; no new required CI context and no branch-protection change (ask-first if one becomes necessary)
- Pre-authorized to continue after the go/no-go unless an ADR 0001 trigger trips: advisory open over 14 days; cold `ops-ui` more than 3 minutes over baseline; isolation work over a day; Docker `asset_builder` stage more than 60 s over; NIF failure twice. If a trigger trips the run stops and asks the maintainer
- PR titles are `docs`, `chore`, `test` or `ci`, never `feat` or `fix` (release-please has one root package); no Hex release; no root `lib/` change
- Never stage `.planning/config.json`, `.planning/state.json` or `.impeccable/config.json`; commit with explicit paths

### Mount shape (verified against 1.5.0 source in H-adversarial-pass)
- `css_path` points at the built `/assets/css/app.css` (tracked at `scrypath_ops/priv/static/assets/css/app.css`); there is no separate `storybook.css`
- `themes_strategies: [data_attribute: "theme"]` puts the attribute on `<body>`, so a small `storybook.js` sets the `html` theme attribute and registers the same LiveView hooks as `app.js`
- Only `:component` and `:example` stories render in `container: :iframe`; `:page` stories cannot be iframed, so none are used
- The route macro's environment guard sits outside the `quote`; the route is loopback-bound and dev/test-only; the playground cannot be disabled, which is why loopback-only matters
- Render-all goes through the real iframe route, not a `render_component` helper (variation slots are HEEx strings; a helper could pass vacuously). Fails on empty output or `data-phx-error`; a planted failing story proves it can fail
- Five primitive stories; variations that carry adopter brand colors stay outside the roots the UI literal ratchet scans

### Boundary tests (flip vacuous to real)
- The existing storybook row in `test/mix/tasks/dependency_boundary_contract_test.exs` asserts presence plus the `only` list, with a planted loosening that fails it; `PhoenixStorybook` and `MDEx` join the absent-module list for mounted and direct-prod scratch consumers and the `forbidden_dep` and `forbidden_modules` lists of `verify-dependency-boundaries.sh`; `package_metadata_test.exs` refutes `fixtures` and `storybook` in the tarball; a production route-table test (`DevRouter.__routes__()` or the prod scratch probe) has no `/storybook` path, with a planted case for the removed guard

### Go/no-go
- `GO-NO-GO.md` records cold and warm `ops-ui` timings from a hosted run (`gh run view <id> --json jobs`), Rust NIF fetch time, lock growth and advisory status; each ADR 0001 trigger is evaluated explicitly; ADR 0001 is amended with the numbers. Baseline is the last green `ops-ui` run on main (about 368 s per the prep note)

### Decided autonomously
- [Plan split] Q: "How many plans?" → Selected: "Two (plan 1 dependency, lock, boundary rows, route macro, production-absence tests, hosted timing; plan 2 css_path, storybook.js, five primitives, render-all, GO-NO-GO and ADR amendment)" — plan boundaries are planning metadata and cheap to re-cut
- [Story file layout] Q: "Where do the five primitive stories live?" → Selected: "A `storybook/primitives/` tree under `scrypath_ops` per the recorded glossary tiers" — files can be moved before Phase 197 builds on them
- [Which primitives] Q: "Which five primitives?" → Selected: "Chosen from existing ops function components by the planner (buttons, status badge, panel, empty state, form field class)" — story content is cheap to swap
- [Timing method] Q: "How are timings measured?" → Selected: "A throwaway branch PR run on hosted CI, cold (cache miss) then warm" — measurement method, no persisted contract

### Claude's Discretion
- Exact module names, story variation ids, the render-all test's iframe-route plumbing, and where `GO-NO-GO.md` lives (phase directory preferred)
- Whether the Docker `asset_builder` timing is measured locally or hosted, provided the recorded number says which

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scrypath_ops/lib/scrypath_ops_web/dev_router.ex` (dev route seam), `router.ex`, `scrypath_ops/priv/static/assets/css/app.css` (built, tracked), `scrypath_ops/assets/js/app.js` and `ops_hooks.js` (hooks to mirror in `storybook.js`)
- `test/mix/tasks/dependency_boundary_contract_test.exs` already carries a vacuous storybook row; `test/mix/tasks/package_metadata_test.exs` is the tarball assertion home; `verify-dependency-boundaries.sh` has the prod-image lists
- Existing ops contract tests (`design_tokens`, `reskin_*`, `copy_rules`) show the local test style

### Established Patterns
- Required gates are counted in a ledger (row 11 of 12 is reserved for Phase 197's catalog contract test; this phase adds no gate row)
- Boundary checks use scratch consumers compiled in `:prod`

### Integration Points
- `scrypath_ops/mix.exs` deps and lock; `scrypath_ops/config/{dev,test}.exs`; the ops Dockerfile `asset_builder` stage; `.github/workflows` `ops-ui` job

</code_context>

<specifics>
## Specific Ideas

Prep notes C (technical shape) and H (adversarial pass, source-verified claims) are the primary references for the planner and researcher. Where a note disagrees with SYNTHESIS.md, SYNTHESIS and H win.

</specifics>

<deferred>
## Deferred Ideas

- Fixtures project and adopters (Phase 196); pilot job, view-model extraction, catalog contract test, 4003 seeded preview (Phase 197)
- Findings F1, F2, D1 (fixed in 197), D2: see SYNTHESIS; F1 and F2 need a root `lib/` change and stay ask-first

</deferred>
