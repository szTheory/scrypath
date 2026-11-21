# v1.49 Catalog foundation: reconciled recommendation (2026-11-21)

**What this is.** The single set of recommendations that comes out of seven parallel prep notes ([A](A-milestone-shape-and-autonomous-run.md) shape and run, [B](B-fixtures-and-adopters.md) fixtures, [C](C-storybook-technical-shape.md) storybook shape and spike, [D](D-pilot-job-and-composable-liveviews.md) pilot job, [E](E-verification-and-gates.md) gates, [F](F-review-loop-and-catalog-ux.md) review loop and UX, [G](G-roadmap-after-catalog.md) roadmap after) and one adversarial pass ([H](H-adversarial-pass.md), which resolved 17 contradictions and verified the load-bearing claims against the 1.5.0 source, Meilisearch's docs and Scrypath's code). Where a note disagrees with this file, this file and H win. It is research and direction, not phase plans: the downstream OpenGSD discuss, plan, execute and verify workflow owns those. Subagent claims not marked CONFIRMED in H are unverified.

## The shape

**Pre-work, two small PRs, no phase.** (1) `docs(...)`/`test(ops-ui)`: merge PR #168 so the milestone input is on main; fix the false `guides/per-query-tuning-pipeline.md:64` line and the `posture.ex:416` guide path (each with a test); reconcile glossary names in the docs; scope-guard and AGENTS wording; the proposed 14-day release cadence text marked as a recommendation. (2) `ci(...)`: split `deep-quality` so the spike's audit shows up alone (drop if costly). Titles must be `docs`, `chore`, `test` or `ci`, never `feat` or `fix`, because release-please has one root package and no `exclude-paths`, so a `feat:` or `fix:` that touches `scrypath_ops/` opens a release PR.

**Phase 195, Mount and prove (2 plans).** The spike goes first because its risks are external (the NIF, cold `ops-ui`, the story-type limits) and fixtures pay off on a no-go anyway. Plan 1: dependency, lock, boundary rows flipped from vacuous to real, dev and test route macro with the guard outside the `quote`, production-absence cases, `refute "fixtures"`/`"storybook"` in `package_metadata_test`, then record cold and warm `ops-ui` timings from a hosted run. Plan 2: `css_path` at `/assets/css/app.css`, a small `storybook.js` that sets the html theme attribute and registers the same hooks as `app.js`, five primitives, render-all through the real iframe route, a `GO-NO-GO.md`, and ADR 0001 amended with the measured numbers. Exit: non-vacuous boundary tests, render-all with a planted failing story, production graphs lack `PhoenixStorybook` and `MDEx`, cold `ops-ui` under baseline plus 180 s and warm under plus 60 s. **Pre-authorized to continue** unless an ADR 0001 trigger trips (advisory open over 14 days; cold `ops-ui` over +3 minutes; isolation work over a day; the Docker asset-builder stage over +60 s; NIF failure twice).

**Phase 196, Fixtures and three adopters (4 plans).** A `fixtures/scrypath_fixtures` project per ADR 0002 (exit: fold it into `scrypath_ops/` if no second consumer appears by 197), pure builders that take `now` and emit raw Meilisearch task maps and Oban job maps so the real `Operator.Status`, `FailedWork` and `Posture` code does the normalizing (only reachable states can be written). Tracer bullet first: Logistify through the fake client to a rendered posture, before any other builder. Real Meilisearch payloads recorded once in a task-scoped Docker run; a closed table of failure strings, each with a `source:` pointing at a real Meilisearch code or Scrypath path; hostile text stored as escapes; a DB-free `check_fixtures` task first in the `test` alias. Adopters: **Shopadelic** (the journey and settings drift), **Logistify** (a deep queue with nothing failed), **Wikily** (an empty install, Scrypath-owned). The host's `phase173` fixtures and their branches stay (four e2e specs use `?scenario=`) with a recorded deletion trigger.

**Phase 197, Pilot: JOB-03, unhealthy verdict to verified retry (5 plans).** Start with Search health (cheapest slice), then Failed sync and recovery. Write the **mounted journey first and green on current code** (repaired `failed_sync_live_test.exs:540` with a positive control; denial through the schema allowlist and through stale sudo), plus a throwaway rendered-HTML parity capture. Then extract (pure view-models with closed enums, `Posture.summary/4` split into scan and build, function components shared by LiveView and story) under that safety net. One test file carries render-all, route and component coverage (no counts), no-identical-variations, copy lint and DOM hygiene, each with one planted input: **ledger row 11 of 12**, inside `ops-ui`, with a deletion trigger. The `storybook` block in `UI-PREVIEW.json`, a `main@sha` landing page and a preflight extension ship here. Stories use the recorded glossary tiers: `primitives/ patterns/ areas/ surfaces/ jobs/`, adopter as a variation dimension (`clinicly_denied_read`-style ids), JOB ids in file paths because the sidebar search reads only story path and name. A cross-screen walk is the ExUnit journey, not a story. **Pause 1:** you look at the storybook and size 198.

**Phase 198, Scale (at most 4 plans, cut by default).** Control room, help and the failed-sync remainder, then Clinicly (real denials only) and Chatly (reindex swap, CJK). Search and Sync-and-index only if your feedback asks. A browser check (at most 10 fixed iframe URLs, 375 and 1280, three themes) runs locally first and advisory later.

**Totals.** About 15 plans; stop and re-ask at 20. **Pause 2:** milestone end, before the audit, the storybook open for your feedback. No Hex release.

## Decisions that changed an earlier recommendation

| Was | Now | Why |
|---|---|---|
| Fixtures first (195) | Spike first (195), fixtures 196 | The spike's risks are external; fixtures survive a no-go |
| Separate advisory catalog CI job | Inside `ops-ui`, ledger row 11 of 12 | The dependency is already compiled there and `ops-ui` (368 s) is not the critical path; `ecommerce-mounted` (1,142 s) is |
| Tiers Primitive/Pattern/Area/Screen/Flow | Primitive/Pattern/Area/Surface/Job | The ops glossary (recorded 2026-10-25) outranks a sibling's naming |
| Seven adopters, Clinicly's never-index as headline | Three first; real denials only | ScrypathOps has no read-denial (the gating covers six write actions); a never-index story would be contrived data |
| `storybook.css` and `:page` stories in iframes | `css_path` at `app.css`; `:component`/`:example` in iframes | Verified in 1.5.0: `:page` cannot be iframed (`story_live.ex:428`); `data_attribute` themes land on `<body>` |
| Render via `render_component` helper | Render through the real iframe route | Variation slots are strings of HEEx; a helper could pass vacuously |
| Delete the host's `phase173` branches in 196 | Keep them, with a deletion trigger | Four host e2e specs depend on them |
| `fix(docs)` readiness commit as release accumulator | `docs`/`chore`/`test` titles | A `fix:` touching `scrypath_ops/` opens a release PR; the first release comes with v1.50 and your yes |
| Catalog on the 4002 preview | Catalog on 127.0.0.1:4003 with its own block in `UI-PREVIEW.json` | The host would put the dependency on the critical lane; 4002 stays the mounted-behavior surface |

## Findings handed to you (not scope for v1.49 unless you say so)

- **F1, a real library bug (CONFIRMED).** `Tasks.list_sync_tasks` (`lib/scrypath/meilisearch/tasks.ex:66-81`) returns a "task history truncated" error once more than 1,000 matching tasks exist, but Meilisearch keeps up to about 1M finished tasks, so a busy production index will show "Search task history exceeded its configured limit" in the ops UI. Needs a root `lib/` change, so it is ask-first.
- **F2, low to medium (CONFIRMED, narrow).** The ops UI prints Meilisearch error messages unbounded and copyable (`translation.ex:112-117`, `failed_sync_live.ex:1101-1109`). Meilisearch's `missing_document_id` message echoes the whole document; Scrypath's projection makes that nearly unreachable, so the exposure is small, but it should be bounded and scrubbed.
- **D1, a real UI bug (CONFIRMED).** A stale-sudo operator returns to `/` in production, not the page they left, because LiveView prunes the path from `host_uri` and only `search_live.ex:122` assigns `:return_to`. The pilot fixes it with its own test (197-5).
- **D2.** Retry receipts live only in the LiveView process, so returning from Sync-and-index likely shows Retry again. Recorded as a finding, not encoded as expected behavior.
- **Test hygiene.** The stale-sudo test at `failed_sync_live_test.exs:540` never renders the row; `ops_a11y_contract_test` covers four routes yet reads as broader; the `ui_contrast_contract_test` "live text" title overclaims; "v1.47/v1.48" labels are stale. ADR 0002 says `verify.package` asserts `fixtures/` never ships, but no such assertion exists (`package_metadata_test.exs:127-133`).
- **Realism.** Scrypath indexes per schema, not per tenant, so "per-store drift" and "11 minutes of lag" cannot be shown; no per-document size limit exists in Meilisearch (100 MB payload, 511-byte key); a bad id fails the whole batch; an out-of-order replay overwrite is impossible on the Oban path because the job loads the current record (PR #108). Most of the fictional adopters' proposed failures needed rewriting or dropping (list in B section 4).

## How to run it in GSD autonomous mode

`.planning/config.json` is dirty with `mode: yolo`, confirmations off and `branching_strategy: phase`, so no built-in pause will fire. Pauses come from the flags, verified in the workflow: `--to N` stops cleanly after phase N and skips the lifecycle; with no incomplete phases `/gsd-autonomous` goes straight to audit, complete and cleanup. So:

1. After the pre-work PRs: `/gsd-new-milestone v1.49`.
2. `/gsd-autonomous --to 197` runs phases 195 to 197 and stops (**pause 1**: your storybook look).
3. `/gsd-autonomous --only 198` after your feedback (skip it if you cut 198).
4. **Pause 2**: your storybook look before the lifecycle.
5. `/gsd-autonomous` with nothing left runs audit, complete and cleanup.

Never stage `.planning/config.json`, `.planning/state.json` or `.impeccable/config.json`; commit with explicit paths and check `git diff --cached --name-only`; restore STATE.md focus lines after each state verb. **Pre-authorized:** discuss fan-out and following it; plan, check, execute, verify, review; PRs and squash-merge on required checks green at the exact head; the ADR 0001 dependency and ADR 0002 fixtures project; advisory-only jobs; accepting `tech_debt` at audit. **Ask first:** an ADR 0001 trigger tripping or a no-go; a new required CI context or branch-protection change; any Hex release or release PR; changing root `lib/` behavior (including F1 and F2); copying from the six brand repos; a runtime dependency beyond the storybook subtree; reaching 20 plans; dropping Clinicly's never-index headline (default: proceed with real denials).

## After v1.49 (confidence in parentheses)

| Slot | Milestone | Goal | Size |
|---|---|---|---|
| 1 | v1.49 Catalog foundation (decided) | Thin storybook on Scrypath-owned adopter data, one job end to end | 195 to 198, about 15 plans |
| 2 | v1.50 Adopter-ready (0.7) | "Testing your app" guide, fresh-consumer walk (the read-only walk can start as an agent side task during v1.49), then only after an API-grilling session highlight/crop or a paging guard; first release 0.3.21 with your yes | phases 199 to 201, 3 to 5 plans, cut after the guide and walk |
| 3 | v1.51 Catalog breadth (0.4) | Remaining screens, a second mounted journey, the storybook becomes the review surface; only if 198 was cut or your review says widen | 5 to 8 plans |
| 4 | v1.52 Announce-ready (0.6) | Website content with real product images from stories, then a maintainer-run announcement, once a release carrying the testing guide exists | 3 to 4 plans |
| 5 | ScrypathOps on Hex (0.8 not planned) | A decision, not a milestone; needs lockstep pin, no `@moduledoc false` internals, an allowlisted `files:`, prebuilt assets, clean `hex.audit` | an ADR and a package dry run first |

v1.34 is **not** paused (shipped 2026-06-29; the earlier note was stale), so there is no theme milestone: the catalog's light, dark and System stories plus the milestone-end review cover its residual gap. The v1.46 re-skin's computed-style specs still run only on schedule, and "how the new look reads" is not proven; the catalog is the cheap place to close that.

## Open for you

1. Confirm the pause after Phase 197 (a first storybook look that sizes 198) in addition to the end-of-milestone review. 2. Say when to merge PR #168 and run the two pre-work PRs. 3. Whether to fix F1 and F2 (root `lib/`, ask-first). 4. The brand-repo reuse grant is no longer blocking: the first three adopters are Scrypath-owned; it matters only when copying becomes useful.
