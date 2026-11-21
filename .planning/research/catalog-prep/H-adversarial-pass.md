# Catalog prep H: adversarial pass over notes A to G (2026-11-21)

Tags: V = I read it (file:line or URL), J = judgment, U = unverified. Research only. Library source: phoenix_storybook 1.5.0 Hex tarball, read from a scratch copy.

## 1. Contradictions and the one resolved choice each

| # | Conflict | Better supported | Resolved choice |
|---|---|---|---|
| 1 | Order: A spike (195) then fixtures (196); MILESTONE-CONTEXT, B, C, F, G number fixtures 195 and spike 196. The notes also disagree on which number is which. | A. The spike's risks are external (NIF, cold `ops-ui`, `:example` limits); fixtures pay off on a NO-GO too (hand harness needs them). MILESTONE-CONTEXT calls sequence "the one open scope choice", so this is not a recorded-decision reversal (V). | Spike first as 195 (2 plans, inline attrs only), fixtures 196. Update numbers in every note. |
| 2 | Render-all lane: A/E/C say inside `ops-ui`; MILESTONE-CONTEXT says a separate advisory job. | Inside `ops-ui`: it already compiles the dep in test; `ops-ui` (368 s) is not the critical path, `ecommerce-mounted` is (1142 s) (V run 44930917171). | Inside `ops-ui`. No new job. |
| 3 | Gate count: A says budget stays 10 of 12; E says one new ledger row, 11 of 12. | E. `workflow_wiring_test` reads the ledger table; a new enforcing test file is a row (V `CONTRIBUTING.md:256-267`, budget used 10 of 12). | 11 of 12, one row for render-all plus coverage plus no-identical-variations, with a deletion trigger. Journey, boundary extension and copy lint extend existing rows. |
| 4 | Serving: C standalone port 4003; AGENTS and the maintainer's flow use the 4002 preview; F wants a `storybook` block in `UI-PREVIEW.json`; C wants `catalog_url`/`catalog_container` keys. | Not truly in conflict. AGENTS.md says that once the first screen story exists the review runs on "stable seeded server, one port" (V AGENTS.md "Milestone-end review"). | One `storybook` block in `UI-PREVIEW.json` (url 127.0.0.1:4003, checkout, branch, base_main), preflight extended with a `main@sha` check (F). 4002 stays the mounted-behavior surface. Built in 197, not 195. |
| 5 | Tier names: F/D use glossary Surface/Job; playbook C1 and MILESTONE-CONTEXT use Screen/Flow. | Glossary: recorded 2026-10-25 decision (V `GLOSSARY.md:19-27`; AGENTS "Recorded owner decisions"). | Folders `primitives/ patterns/ areas/ surfaces/ jobs/`; edit C1 and MILESTONE-CONTEXT names in the same change. Flow is an ExUnit journey, not a story tier. |
| 6 | What a Job story is: glossary says "a whole page in one persona's JOB situation" (V); F says an ordered walk across surfaces; D mixes both. | Glossary. A static walk cannot prove handoffs (C7/C23). | A Job story is one surface state with a persona caption. The cross-screen walk is the ExUnit journey; a story may link to it by test name. |
| 7 | Adopters: B five, A three. | A on staging (sigra: one job, three cases). | Three in 196: Shopadelic (journey and settings drift), Logistify (backlog), Wikily (empty install, Scrypath-owned, zero fiction risk). Clinicly and Chatly in 198; Classwell and Finanza only as variations. |
| 8 | Clinicly "failed work the operator may not read" and never-index headline (MILESTONE-CONTEXT, A's table, E's sentinel check) versus B and D: no read-denial exists. | B and D. V: gating covers six write actions only (`gating.ex`), reads are the host router's concern; a never-index story is a contrived-data defect by the maintainer's own standard. | Real denials only: schema `:unavailable` with zero inserts, stale sudo, impersonation, unverifiable identity. Drop E's never-index sentinel; keep its positive control. One-line ask-first (section 6) because MILESTONE-CONTEXT named Clinicly's state. |
| 9 | Pilot job: A "Search-health job"; MILESTONE-CONTEXT "Search health first"; D JOB-03 failed sync to verified retry; E Health to Failed sync to retry to "return link back to Search health". | D, with Health as the entry. The real handoff is Failed sync to `/sync-and-index?...recovery` (V `failed_sync_live.ex` per D); I found no Health return link, so E's end step is U. | Stories start with Search health (cheapest slice, plan 1). Journey is JOB-03 per D. Return assertion recorded as a finding, not encoded as expected behavior. |
| 10 | Render-all mechanism: C real route via `live/2` on `/storybook/iframe/...`; E `render_component(story.function(), attrs)` with its own helper. | C. Variation `slots` are strings of HEEx (V `variation.ex:26-48`, `guides/components.md:185`), which E's helper cannot render. | Iterate story index and variation ids through the real iframe route; data checks (coverage, duplicates) use the variation structs. |
| 11 | Old fixtures: A deletes both `Phase173FixtureSource` copies and the `PostureLive` branches in 196; B says generalize, keep. | B. V: four host e2e specs use `/admin/search/phase173/health?scenario=` (`ops_reskin_contract.spec.ts:67-68`, `ui_iteration3.spec.ts:129`, `ui_followup.spec.ts:63`, `ui_baseline.spec.ts:72`); `phase173` appears in 11 files incl. the host router, `compose.phase173.yaml`, two contract tests. | Ops copy replaced by fixtures; host copy and branches stay with a recorded deletion trigger (specs ported or retired). Drop A's "a test greps they are gone". |
| 12 | Where story markup lives: C `catalog/lib` wrappers; D production function components used by both LiveView and story. | D (story output equals production output). | Wrappers in `catalog/lib` only supply `now` and `mount_path`; markup stays in `lib/scrypath_ops_web/components/`. |
| 13 | CSS: ADR 0001 and A `storybook.css`; C points `css_path` at `app.css`. | C. V: hash is by file under `priv/static` (`asset_helpers.ex`), and `app.css` is tracked at `scrypath_ops/priv/static/assets/css/app.css` (git ls-files). | `css_path: "/assets/css/app.css"`. |
| 14 | Theme dropdown: C three themes with System via JS; F Light/Dark only, System by emulation. | C for the config, F for the legend. | Three entries, "system" sets no attribute; legend says "follows your OS"; browser check covers it locally. |
| 15 | Readiness PR title: A `docs`/`test` keeps release-please quiet; G `fix(docs)` opens the release PR as accumulator. | A. V: root package only, no `exclude-paths` (`release-please-config.json`). | `docs(...)` / `chore(ops-ui)` / `test(ops-ui)` titles. The release PR comes from v1.50 with a yes. |
| 16 | DB: C says the catalog needs a Repo or `PGHOST`; F says DB-free. | C. V: `dev.exs:5-9` hardcodes `localhost`; `ScrypathOps.Repo` starts with the app. | Compose Postgres with `PGHOST` read in `dev.exs`. |
| 17 | Plan counts: A 16; B 4 to 5 for fixtures; C 2 spike; D 5 pilot; E 3 for checks and journey; F 2 for the loop. Summed with each note's own phase boundaries this is about 21 to 23. | None; each note scoped its own phase to the cap of 5. | See section 5: 15 planned, hard stop at 20. |

## 2. Claim verification

| Claim | Verdict | Evidence |
|---|---|---|
| C: `:page` not iframeable | CONFIRMED | `live/story_live.ex:428-438` renders inline; only `:component`/`:example` take iframes (`:440-455`) |
| C: `data_attribute` theme lands on `<body>` | CONFIRMED | `templates/layout/root_iframe.html.heex:72-75` (`sandbox_attributes` on `<body>`); `<html>` gets only `root_class` (`:2-6`) |
| C: playground cannot be disabled | CONFIRMED | tabs hard-wired `story_live.ex:293-301`; config keys list has no playground key |
| C: `:example` cannot `handle_params` | CONFIRMED | `stories/story.ex:99` |
| C: mdex/mdex_native advisories, all patched | CONFIRMED | `gh api` advisories published 2026-06-29; mdex patched 0.13.2 |
| B: no per-document size limit; 100 MB payload; 511-byte key | CONFIRMED | meilisearch.com/docs/learn/resources/known_limitations |
| B: ids alphanumeric, `-`, `_`; one bad id fails the batch | CONFIRMED | meilisearch.com/docs/learn/getting_started/primary_key |
| B: ">1000 tasks truncated history" | CONFIRMED but mislabeled | It is Scrypath's own limit, not Meilisearch's (`lib/scrypath/meilisearch/tasks.ex:11,66-81`). Meilisearch keeps tasks until about 1M. See finding F1 |
| D: stale-sudo test hits the not-found branch | CONFIRMED with nuance | `loads: nil` gives `find_row` nil; the not-found branch is itself wrapped in the gate (`failed_sync_live.ex:300-305`), so the test passes for the redirect but never reaches the row-present gate (`:319-323`). Title overclaims; no row is asserted |
| D: production stale-sudo returns to `/` | CONFIRMED | `prune_uri` keeps scheme, host, port only (`phoenix_live_view/utils.ex:171-178`); `gating.ex:182-183` falls back to `"/"`; only `search_live.ex:122` assigns `:return_to` |
| D: receipts are in-process only | CONFIRMED | `assign(:recovery_receipts, %{})` in `mount` (`failed_sync_live.ex:42`), cleared at `:217` |
| E: `ops-ui` 368 s, verify step 330 s | CONFIRMED | run 44930917171 job steps. The 261 s boundary-test and 64 s suite split: U (needs logs) |
| E: C26 prod-exclusion "mostly built" | CONFIRMED for the pattern, not storybook | Esbuild/Tailwind are `only: :dev` and in `@absent_modules` (`ops_dependency_boundary_test.exs:8-17`, `mix.exs:61-62`); script forbids them (`verify-dependency-boundaries.sh:658,691`); storybook rows pass vacuously (`dependency_boundary_contract_test.exs:617-686`) |
| B: no `refute "fixtures"` in package test | CONFIRMED | `package_metadata_test.exs:127-133` |
| B/E: new top-level `fixtures/` forces a classifier decision | CONFIRMED | `compat_path_classifier.test.cjs:140-196` inventory test |
| A: `posture.ex:416` guide path wrong | CONFIRMED | resolves to `scrypath_ops/guides/`, which does not exist |
| A: guide line 64 false | CONFIRMED | `lib/scrypath/options.ex` has no highlight/crop key |
| A: a `feat:` touching `scrypath_ops/` opens a release PR | CONFIRMED | single root package, no `exclude-paths` |
| A: local Docker lanes about 2h20 | UNVERIFIED | not in the ledger text I read |
| E: render helper via `function/0` | REFUTED for slotted stories | variation slots are strings (see row 10) |

**F1 (new product finding, real).** `Tasks.list_sync_tasks` pulls task history with no status filter and returns `{:task_history_truncated, ...}` as soon as more than 1,000 matching tasks exist (`tasks.ex:66-81`). `Status.fetch` and `FailedWork.Retrieval` both use it (`status.ex:72-73`, `retrieval.ex:26-29`). Meilisearch retains up to about 1M finished tasks, so any busy production index will show "Search task history exceeded its configured limit" (`posture_live.ex:659`). That is a library correctness issue, not a story. Hand to the maintainer as a bug candidate; not in v1.49 scope (root `lib/` is out of scope per A).

**F2 (B's error.message question).** REAL, LOW to MEDIUM, narrow.
- Backend failures show `error.message` verbatim: `translation.ex:112-117` takes `raw["error"]["message"]` unbounded (queue reasons are bounded to 500, `:7`), and the UI prints it in a copyable block (`failed_sync_live.ex:1101-1109`).
- Meilisearch's `missing_document_id` message embeds the whole serialized document: ``"Document doesn't have a `{}` attribute: `{}`"`` (V `meilisearch/crates/milli/src/error.rs:298`). `invalid_document_id` echoes the id value.
- Reachability through Scrypath is small: projection always sets an `id` (`projection.ex:30-50`), so a body echo needs a nil or missing id value. An id echo is not new exposure; ids are already on screen.
- The Meilisearch task and Oban error already hold the same text; the new exposure is anyone with ops UI access who lacks backend access, plus screenshots and copy-to-clipboard. Fix is a small bounded, scrubbed display (root `lib` or ops `FailedSyncView`). Record in the findings note; do not paper over it in a fixture.

## 3. Premortem: top 8

1. **Cold `ops-ui` and the boundary test trip the +3 min trigger on the first lock change.** Direct dev and test graphs each compile nine packages plus an `mdex_native` download in isolated build dirs (V `verify.ops_ui` scratch dirs per E). Early sign: the first PR run over about 650 s. Cheapest check: a PR with only the dep, lock and boundary rows, then `gh run view --json jobs`, cold and warm. Carry: 195-1.
2. **Plan-count creep.** Sibling counts 76 to 138. Early sign: a plan named manifest, matrix, evidence or baseline; plan-check hitting 3 rounds twice; a phase over 5. Check: counter in STATE. Carry: every phase; hard stop at 20.
3. **Fixtures project drags in packaging and CI inventory work.** V: compat classifier inventory, `package_contents_test`, namespace fence (U), `ui_literal_policy` roots, 11 `phase173` files, four e2e specs. Early sign: more than one plan before one adopter reaches `Posture.summary`. Check: B's tracer bullet (Logistify through the fake client to a rendered posture) before any other builder. Carry: 196-1, with ADR 0002's exit to a module in `scrypath_ops` as the named fallback.
4. **Stories diverge from mounted behavior** (static HTML cannot reach events; D's finding that denial redirect is wrong in production). Early sign: a story whose markup is not produced by a function the LiveView also calls. Check: D's seam test per Area; journey written green first on current code. Carry: 197-1.
5. **Contrived data creeps back** (never-index, lag, "48,206 vs 47,950", the overwrite races B ruled out). Early sign: a failure string with no `source:` mapping to a Meilisearch code or Scrypath path. Check: closed-list test (A) plus recording one real Meilisearch payload set in Docker once (B). Carry: 196-2.
6. **Review fatigue and silent staleness.** The maintainer sees a stale or empty storybook, or gets asked too often. Early sign: URL answers but `main@sha` differs from `origin/main`. Check: preflight sha check; pauses limited to 197 and milestone end. Carry: 197-5.
7. **Autonomous-mode context clobbers.** V: `.planning/config.json` is dirty with `mode: yolo`, `confirm_transition: false`, `confirm_milestone_scope: false`, `branching_strategy: phase` (git diff); so no built-in pause will fire, and `gsd/phase-*` branches get created. `state.json` and `.impeccable/config.json` also dirty. Early sign: `git diff --cached --name-only` shows any of the three, or STATE.md loses `milestone_name`. Check: commit with explicit paths only; restore STATE focus lines after each state verb (A's list). Carry: every phase, as a pre-commit habit; add a staged-files grep to the phase verify step.
8. **Gate that proves less than it claims.** Render-all green while the real chrome is broken (body-vs-html theme, C's 0.3 leak risk), and 'coverage' passing via `@no_story` exceptions. Early sign: an exception list that grows, or a fidelity check that exists only as throwaway local Playwright. Check: planted-failure case in the same file for every gate (house style), and the computed-style fidelity probe run once in 195-2 with its result recorded. Carry: 195-2, 197-3.

Also real, smaller: `storybook.js` as a third bundle (C says gitignored) when `app.js` and `app.css` are tracked artifacts (V git ls-files); Dependabot grouping `makeup*`/`mdex*` PRs; cache at 10.73 GB against a 10 GB cap (V `gh api .../cache/usage`).

## 4. Missed, and rule conflicts

**Missed:**
- F1 and F2 above (neither A to G reads `tasks.ex`'s default as a product bug; B only half-saw F2).
- `mode: yolo` with confirmations off means the pauses in A and F exist only if the run uses `--only N`. Make that explicit in the run instructions.
- Mix `only:` semantics for a nested path dep (`fixtures` depending on `{:scrypath, path: "../.."}` while `scrypath_ops` also depends on `{:scrypath, path: ".."}`): same target, different relative strings. U. Spike it in 196-1 before building.
- The catalog changes `PROJECT.md:224` scope guard wording (G caught it) and memory entry for v1.34 (G caught it); also AGENTS "UI work" still names 4002 as the surface until the first screen story ships. Docs fix in the pre-work PR.
- Tracked `priv/static` assets mean a story needing a new Tailwind class silently renders unstyled in CI (the committed `app.css` lacks it) while looking fine locally after a rebuild. Add: a render-all check that the iframe CSS file equals a fresh build is too heavy; instead, rule "stories use only emitted classes", enforced by C's early-warning, and the `ui_literal_policy` roots.
- E's own hygiene finds (a11y test name, "live text" contrast test title, stale "v1.47" labels) are real but cosmetic; do them once in 195-2, not as a plan.

**Standing-rule conflicts:**
- A's pause list item 10 ("`human_needed` is a plan defect") is right; but F's milestone-end packet, E's "Taste stays with the maintainer" and the 197 pause are the AGENTS-sanctioned human review, not UAT. Keep them labeled that way so they are not read as gating evidence (AGENTS Phase 185 correction).
- "Never weaken what a check proves": E's check 3 helper (not slot-capable) would pass vacuously; fixed by choice 10. B/E's "advisory first" browser check is fine only if the advisory label is not used as completion evidence.
- "Copy over dependency": B's own `pick/4` hash generator over StreamData/Faker is good; ADR 0001's dependency is a recorded owner decision, so no violation, but 9 packages plus a NIF is the largest dependency add in the repo; the ADR triggers are the control.
- G's "no Hex release inside v1.49" and A's cadence text agree with "releases need an explicit yes". A's proposed cadence text in `docs/releasing.md` is agent guidance and should be marked proposed until the maintainer says yes.

## 5. Final recommended shape for v1.49 (J unless tagged)

**Pre-work (before `/gsd-new-milestone`), 2 PRs, no phase:**
1. Merge PR #168 (this docs branch) first so MILESTONE-CONTEXT is on `main` (V one open PR, #168). Same or next PR: false line `guides/per-query-tuning-pipeline.md:64`, `posture.ex:416` path fix with a test, glossary names reconciled in MILESTONE-CONTEXT and playbook C1, `PROJECT.md` scope-guard note, AGENTS wording that the first screen story moves review to the storybook. Titles `docs(...)`/`test(ops-ui)`.
2. `ci(...)`: split `deep-quality` (ledger finding 1) so the spike's audit and dialyzer show up alone. Drop it if costly; then 195-2 records `mix hex.audit` by hand.

**Phase 195 Mount and prove (2 plans).**
- 195-1: dependency, lock, boundary rows flipped from vacuous to real, dev+test route macro (guard outside `quote`), prod-absence cases for mounted-prod and direct-prod, `refute "fixtures"`/`"storybook"` in `package_metadata_test`, then `gh run view` cold and warm timings.
- 195-2: `css_path` at `app.css`, `storybook.js` for html theme attribute and hook parity with the `ops_shell_contract` regex, five primitives inline-attrs, render-all over the real iframe route, `GO-NO-GO.md` with `decision:` field, ADR 0001 corrected and updated with the numbers (and the Docker `asset_builder` delta, C).
- Exit (executable): boundary tests green and non-vacuous; render-all green incl. a planted failing story; prod graphs lack `PhoenixStorybook`/`MDEx`; `ops-ui` cold under baseline plus 180 s, warm under plus 60 s; `handle_params`-in-`:example` result recorded (V: still impossible); fidelity probe result recorded.
- **Pre-authorized to continue** unless an ADR trigger trips (advisory open over 14 days; cold `ops-ui` over +3 min; isolation work over one day; Docker `asset_builder` over +60 s; NIF failure twice).

**Phase 196 Fixtures, three adopters (4 plans).**
- 196-1 tracer bullet and project (`fixtures/scrypath_fixtures`, ADR 0002, path-dep check, `now`-taking builders, fake client honoring `limit`), classifier inventory, `package_contents` decision. Exit: Logistify through real `Posture.summary` in a test.
- 196-2 recorded real Meilisearch payloads (task-scoped Docker, cleaned up), closed error table with `source:` per failure, `check_fixtures` task first in the `test` alias.
- 196-3 Shopadelic, Logistify, Wikily; hostile-text module as escapes; "(fictional)" and compliance-word denylist tests.
- 196-4 migrate the ops copy's 16 posture scenarios; generalize the `PostureLive` branch via the existing `scrypath_ops_opts` session key; host copy stays.
- Exit: invariants and no-wall-clock static test green; old ops copy removed; `mix verify.package` green; no `compat` classifier or package test red.

**Phase 197 Pilot, JOB-03 (5 plans).**
- 197-1 mounted journey written green on current code first (repaired `:540`, positive control, denial via allowlist and stale sudo), plus HTML parity capture script (local, not a gate). Expected RED: stale-sudo `return_to` (D finding 1), fixed in 197-5 with its own test.
- 197-2 Search health Areas and stories, then 197-3 Failed sync and recovery Areas and stories with the checks (coverage, no identical variations, copy lint, DOM hygiene) in one file, one ledger row.
- 197-4 `storybook` block in `UI-PREVIEW.json`, `main@sha` landing page, preflight extension, documented one-command start, "Start here" page, link-resolution test.
- 197-5 return_to fix, findings note (F1, F2, receipt retention, Retry reappearing), review packet.
- **PAUSE 1:** maintainer reviews the storybook and sizes 198 (one word continues).
- Exit: journey with denial green; coverage and duplicate checks green; preflight passes on current `main`; seam tests per Area present.

**Phase 198 Scale (sized after pause 1, at most 4 plans; default cut).** Remaining small screens (control room, help, failed sync remainder), Clinicly (PII-shaped ids, allowlist denial) and Chatly. Search and Sync and index only if feedback asks. Browser check (10 URLs, 375 and 1280, three themes) local first.

**Total planned 15; stop and re-ask at 20.** **PAUSE 2:** milestone end, before audit, per AGENTS (packet per F3). Run `--only N` per phase; never the lifecycle before pause 2. No Hex release; no release PR expected (check after each merge).

**Pre-authorized:** discuss fan-out and following it; plan, check, execute, verify, review; PRs and squash-merge on green required checks at the exact head; the storybook dependency (ADR 0001) and fixtures project (ADR 0002); advisory-only jobs; audit with `tech_debt` accepted; writing F1/F2 into a findings note.

**Ask first:** an ADR 0001 trigger tripping or a NO-GO; a new required CI context or branch-protection change; any Hex release or release PR, or `exclude-paths`; changing root `lib/` public behavior (incl. fixing F1 or F2); copying from the six brand repos; any runtime dependency beyond the storybook subtree; reaching 20 plans; dropping Clinicly's never-index headline in favor of real denials (one line; default proceeds with real denials, since the maintainer's own rule bans contrived data).

**What would change this:** a NO-GO (swap to the hand harness, keep fixtures); the maintainer wanting no pause at 197; the path-dep check failing in 196-1 (fold fixtures into `scrypath_ops/catalog/`).
