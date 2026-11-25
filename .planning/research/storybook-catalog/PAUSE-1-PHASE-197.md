---
date: 2026-11-22
phase: 197
type: pause-1-review-packet
status: waiting for the maintainer's look; nothing in the catalog is an approved design
---

# Pause 1 after Phase 197: the JOB-03 storybook, ready to look at

Phase 197 took one job, JOB-03 (the paged on-call engineer, ROLE-OPS: search looks unhealthy or sync work failed, find the affected work, take a safe recovery step), from the unhealthy verdict to a verified retry, and drew it in the storybook. The run stops here. This note is the packet for your look, the empty table for your feedback, the fixtures decision with evidence, every finding handed to you, and what sizes Phase 198.

## The packet

1. **Where and which build:** http://127.0.0.1:4013/storybook/welcome, built from `main@33aac70fa7d6` at writing (the Phase 197 code PR, [#177](https://github.com/szTheory/scrypath/pull/177); the checkout is then fast-forwarded to this note's docs-only commit and the landing page shows the current sha). It is port 4013 and not the planned 4003 because another project holds 4003; see "Port deviation" below, where the decision is yours. The landing page prints the current `main@sha`, the served HEAD, the checkout and the frozen time, and `npm run ui:preflight` refuses a storybook that is behind `main`.
2. **UI changed:** `git diff --stat 33aac70f^..33aac70f -- scrypath_ops/lib scrypath_ops/storybook fixtures` is 32 files, +3703 -1535. Search health, Failed sync and the two recovery areas of Sync and index now render from shared components that the stories draw with the same code the real screens use (stories: `screens/search_health`, `screens/failed_sync`, `areas/*`, `patterns/*`, `jobs/job_03_on_call_recovers_failed_sync`, plus `welcome`). The real screens did not change by the parity captures (details under "What was checked"), with two exceptions that are the two fixes: an operator whose sudo went stale now returns to the page they left after confirming (D1), and Sync and index shows a closed "could not be checked" state instead of crashing when a recovery link cannot be resolved (D3).
3. **60-second tour:** open the welcome page and read "Start here" (what the screens are, the five tiers, the frozen time 2026-11-20 14:00 UTC, "nothing here is an approved design"). Open the Job story (link 1 below), then flip it to the retry-queued state. Open Search health in light, then dark (links 2 and 3). Open the three Failed sync rows (links 4 to 6). Open the three recovery states (links 7 to 9). Shrink the window to a phone width on any one of them.
4. **Where behavior lives:** the storybook shows static renders (buttons do nothing). Clicking, retry and navigation are in the 4002 preview (http://127.0.0.1:4002/admin/search, refreshed to the same `main`, data intact) and in the mounted journey test.
5. **Reply `ok`, or give rows** in the table below (storybook path, variation id, theme, viewport, your words).

## Screens and states worth a look

Every link below was fetched on 2026-11-22 against the running storybook: the story page and its bare iframe both answered 200. An unknown variation id answers 500, so a 200 here means the variation exists. All use port 4013.

| # | Look at | Link | The question it answers |
|---|---------|------|-------------------------|
| 1 | The Flow story, arriving from Search health | http://127.0.0.1:4013/storybook/flows/job_03_on_call_recovers_failed_sync?variation_id=shopadelic_failed_journey_arrived_from_health&theme=light | Can the on-call engineer tell which record failed and what to do next? (second variation: `shopadelic_failed_journey_retry_queued`, the same page after Retry) |
| 2 | Search health, Shopadelic degraded, light | http://127.0.0.1:4013/storybook/screens/search_health?variation_id=shopadelic_failed_journey&theme=light | Does the verdict read as "something failed, here is where to go"? |
| 3 | The same, dark | http://127.0.0.1:4013/storybook/screens/search_health?variation_id=shopadelic_failed_journey&theme=dark | Same page, dark: anything that stops reading in dark? |
| 4 | Failed row, retryable | http://127.0.0.1:4013/storybook/areas/failed_row?variation_id=shopadelic_failed_journey_retryable&theme=light | Is Retry obvious on a row that can be retried? |
| 5 | Failed row, ineligible | http://127.0.0.1:4013/storybook/areas/failed_row?variation_id=shopadelic_failed_journey_ineligible_task&theme=light | Is it clear why this row has no Retry? |
| 6 | Failed row, very long error | http://127.0.0.1:4013/storybook/areas/failed_row?variation_id=shopadelic_hostile_ids_long_error&theme=light | A 729-character backend error with hostile ids: readable, or a wall of text? |
| 7 | Recovery: queue done, backend evidence pending | http://127.0.0.1:4013/storybook/areas/recovery_status?variation_id=shopadelic_failed_journey_queue_done_backend_pending&theme=light | Is it clear that "completed" is not "verified"? |
| 8 | Recovery: verified | http://127.0.0.1:4013/storybook/areas/recovery_status?variation_id=shopadelic_failed_journey_verified&theme=light | Does verified look different enough from the pending state above? |
| 9 | Recovery: unavailable (the new D3 state) | http://127.0.0.1:4013/storybook/areas/recovery_status?variation_id=shopadelic_failed_journey_unavailable&theme=light | When the recovery link cannot be resolved, does the page say so calmly, and is "Refresh recovery status" still the right button? |

Also worth a glance: `screens/failed_sync` (http://127.0.0.1:4013/storybook/screens/failed_sync?variation_id=shopadelic_failed_journey&theme=light, 200) for the whole page, and `patterns/retry_receipt`. The storybook sidebar and toolbar belong to the upstream storybook, not to Scrypath.

Deep-link check results (page / iframe): welcome 200; links 1 to 9 each 200 / 200; the extra `screens/failed_sync` 200 / 200; the second Job variation 200 / 200; the three F1 links under Findings 200 / 200.

### Copy defects the fixtures expose (kind: product)

Read from the rendered storybook in Chromium on 2026-11-22 (text of the rendered page, not the source), so these are confirmed as the screens say them:

- **"3 sync jobs and 1 Meilisearch tasks failed"** on Search health (links 2 and 3): no singular for the task count (`degraded_evidence` in `posture.ex`).
- **"Check detail: :receipt_unavailable."** on the unavailable recovery state (link 9): an internal atom shown as operator copy; the document observation copy does the same (`(:receipt_unavailable)`). Moved verbatim by the extraction.
- **A gap before the period after inline code**: "...add or update records in shopadelic_product ." in the retry receipt. `ops_inline_code` puts its text on its own lines inside `<code>`, which leaves a space before the following period. The cause is the primitive, so any use followed by punctuation shares it (Plan 02 saw the same gap in the missing-backend empty state; I did not re-check that one in a browser).

From the plan summaries, not re-checked here in a browser:

- The Failed sync load error shows the raw Elixir error term (`{:task_history_truncated, %{next: 200, limit: 1000, ...}}`) to the operator (adjacent to F1).
- A retrying row still offers Retry, as the journey asserts; after Retry the row keeps its Failed status next to "Retry queued" because the original job is retained.
- The unavailable state still offers "Refresh recovery status", though a refresh with an unresolved handle returns the same answer. Whether to hide it there is a product call.
- The Recovery evidence line prints the full module name (`ScrypathFixtures.Shopadelic.Product`) after `Schema:`.
- The shell links inside the screen stories point at `/ops/...`, which the storybook does not serve (they go nowhere there), and the shell's theme control sits inside the story frame beside the storybook's own toggle. Both come from rendering the real shell.
- The blank evidence line ("Queue job · attempt · Active index" with empty values) that the old render would have shown for an unresolved handle is gone: D3 removed the line instead of printing blanks.

## Your feedback

Paste your words verbatim. Rules: quotes are never paraphrased; theme is `light`, `dark`, `system` or `unknown`; viewport is a width in px or the literal `unknown` (it is in no storybook URL; say it if it matters); kind is `product` (the real screen should change), `data` (the made-up data should change) or `catalog` (the storybook itself); triage is fix now, next milestone, later, or "looked at it, keep as is".

| # | Verbatim quote | Storybook path | Variation id | Theme | Viewport | Kind | Triage | Disposition |
|---|----------------|----------------|--------------|-------|----------|------|--------|-------------|
| 1 | "there's this weird rounded card effect around the whole main panel" | /storybook/welcome | unknown | unknown | unknown | catalog | looked at it, keep as is | phoenix_storybook's own page chrome (rounded, bordered panel on a frame); it does not load our CSS there. Not overridden. |
| 2 | "looks like the ops badges all styled the same way... css bug with phoenix storybook?" | /storybook/primitives/ops_badge | all seven (neutral, info, success, warning, error, partial, running) | unknown | unknown | catalog | fix now | Not a CSS bug: `.ops-badge` is plain muted text and `kind` has no visual effect, in the real app too. The story showed seven identical looks, so it is cut to one variation (`default`) and DESIGN-TOKENS.md says the kind table is for notice surfaces, not badges. |

## Fixtures fold: evidence and recommendation

The decision on the table (from the Phase 196 ADR exit rule): keep `fixtures/scrypath_fixtures` as its own project, or fold it into `scrypath_ops`. It is the maintainer's decision.

| Evidence | Value |
|---|---|
| Consumers | One. `scrypath_ops` lists it (`only: [:dev, :test]`); the demo host does not. |
| Hosted cost, Phase 196 (CI-EFFICIENCY finding 29) | `ops-ui` warm minus same-hour control: -3 s in the job, +1 s in the step. |
| Hosted cost, this phase (finding 30) | `ops-ui` warm minus same-day control: -2 s in the job, +2 s in the step (450 s against 452 s; 404 s against 402 s). The catalog contract test is about 1.6 s locally. |
| What a fold touches | 14 files (checked with grep today) that name the project by path or name: `.formatter.exs`, `scrypath_ops/mix.exs`, the demo `Dockerfile`, `verify-dependency-boundaries.sh`, five root tests (`fixtures_project_contract`, `verify_namespace_fence`, `dependency_boundary_contract`, `ops_dependency_boundary`, `package_metadata`) and five `scrypath_ops` fixtures tests (`check`, `check_task`, `provenance`, `recordings`, `round_trip`); the Phase 196 estimate of about 20 also counts the `.dockerignore`, CI workflow and path classifier lines that mention `fixtures/`, which I did not individually confirm as fold edits. The project itself is 57 tracked files (24 outside the recordings). A further 23 files (13 stories, the serve task, the contract test, the journey, five other tests and two test-support files) use the module name `ScrypathFixtures` and change only if it is renamed. One plan of renames. |
| Unused functions (Phase 196 IN-03, recomputed now with grep) | 6 still have no caller anywhere: `Logistify.states/0`, `Shopadelic.states/0`, `Wikily.states/0`, `Meili.types/0`, `Meili.statuses/0`, `Bulk.max_rows/0`. `ObanJob.states/0` now has one (the job-shape check in `Check`), so it stays. The Phase 197 stories did not become their callers: they read scenarios by id. |

**Recommendation: keep it as its own project.** The measured cost does not argue for folding (both phases are within a few seconds of their same-hour control), and the rule's purpose, avoiding an orphan project, is served while the catalog and the journey both consume it. **Revisit when the four `phase173` host specs are ported** (the likely second consumer, so the rule's own test becomes decidable) **or at v1.51.** The six unused functions are deferred to the same decision (prune them with a fold, or keep them as small reference points). Confidence: moderate; what would change it is a second consumer appearing without a fold, or a hosted warm run more than about 60 s above its same-day control.

## Findings

All handed to you. Nothing below was fixed by this pause (FLOW-04), except the two defects fixed earlier in the phase.

### Fixed in this phase (PR [#177](https://github.com/szTheory/scrypath/pull/177), `scrypath_ops` only, no root `lib/` change)

- **D1 fixed.** An operator whose sudo had gone stale was sent back to `/` after confirming instead of the page they left. `OnMount` now assigns the return path from the request (path and query, never a host), with a test that was red first.
- **D3 fixed.** Sync and index crashed with `KeyError :replacement_job` whenever the recovery link in the URL could not be resolved (an expired 10-minute receipt, another node, a different organization), and the reconnect crashed again. The page now says the outcome could not be checked and shows no evidence line.

### Left with you, in the order I would look at them

- **F1: task history is cut at 1,000.** `Tasks.list_sync_tasks` returns a truncation error and the posture reads "could not be fully checked". Three stories show it, all from the scenario `logistify_history_over_limit_f1`: the verdict ([link](http://127.0.0.1:4013/storybook/areas/health_verdict?variation_id=logistify_history_over_limit_f1&theme=light)), the schema row that says "Not checked" ([link](http://127.0.0.1:4013/storybook/areas/health_schema_row?variation_id=logistify_history_over_limit_f1_not_checked&theme=light)) and the Failed sync load error with its raw error term ([link](http://127.0.0.1:4013/storybook/areas/failed_summary?variation_id=logistify_history_over_limit_f1_load_error&theme=light)). A fix needs a root `lib/` change, so it is ask-first.
- **F2: unbounded, copyable Meilisearch error text in the operator UI.** A failed task echoes whatever the customer sent, markup and right-to-left text included. Link 6 shows it: a "Show all" toggle clamps it past 240 characters or three lines, but the whole text is in the page and the copy button.
- **F3: Scrypath can never show an indexSwap task.** Meilisearch leaves swap tasks out of any task list filtered by index, and Scrypath always filters. Phase 198's Chatly set would have to derive its cutover story from the `__reindex` index tasks. Root `lib/` change, ask-first. Source: `.planning/phases/196-fixtures-and-three-adopters/196-FINDINGS.md`.
- **F4: a schema's `sortable:` list is never sent to Meilisearch.** The drift report shows `only_declared` forever unless the app also passes `settings:`. Whether `sort:` then fails on the backend was not measured. Root `lib/` change, ask-first. Same source.
- **D2: retry receipts live only in the LiveView process** (and a per-node observer with a 10-minute lifetime), so a reconnect to another node or an expiry loses them. D3 made that symptom calm, not gone. Source: `.planning/phases/195-mount-and-prove/GO-NO-GO.md`.
- **The `dashboard_routes` guard defect** in `scrypath_ops/lib/scrypath_ops_web/dev_router.ex`: the guard's `and dev_routes?` is always truthy, so `dev_routes` is never consulted. Unobservable today (LiveDashboard is dev-only). Same source.
- **Phase 195 IN-03: `storybook.js` ships in the prod and test static trees** of `scrypath_ops` (the tracked bundle that also carries Plan 01's story-font fix). Recorded as the plan named it; I did not measure anything about it here.
- **Phase 196 IN-01: the fake Oban inspector models schema scoping only** (the real one filters by queue and caps at 100). No Phase 197 story shows the 195-job deep-queue count: `logistify_deep_queue` is deliberately not storied for this reason.
- **Phase 196 IN-03:** the six unused fixtures functions above (decision folded into the fixtures recommendation).
- **The copy defects above** (singular, the atom shown as copy, the gap before a period, the raw error term, Retry on a retrying row, Refresh offered on the unavailable state, shell links the storybook does not serve).
- **Dead observer branches in `SyncDriftLive`** (Plan 04): shapes of observer results that cannot occur (`{:running, nil}` and similar). The new refusal of an observed status without evidence covers them. Cleanup for a later pass.
- **Coverage gaps (data, not code):** no scenario has two schemas, so the Schema chip group has no story; the unavailable-schema state and a receipt without a status link are covered by tests but not storied.
- **Not storied yet, by recorded deferral:** 61 listed components and routes (57 components: 47 `OpsUi`, 2 `ResultUi`, 2 `CoreComponents`, 6 `Layouts`; 4 routes: Control room, Search, Help, Sync and index as a whole), each with a one-line reason in the contract test.

### The fidelity probe, first run against a real page (non-gating)

The probe compares the computed styles of a story with the same screen rendered for real (Search health, Shopadelic failed journey, light and dark, 1280 by 900, five selectors: the verdict, its heading, the sync-status word and its container, the time value; twelve properties each: color, background, border color and width, radius, padding, font family, size and weight, line height, letter spacing).

- **First run, as the plan described it:** every selector differed, 66 differences. Cause: the real page dump from the parity capture script is a LiveView fragment, not a document, so the probe loaded it with no stylesheet (the real side read Times, black, no padding). That is a mismatch between the two tools, not a catalog problem.
- **Second run, the same fragment wrapped in a minimal document that links `/assets/css/app.css`:** `RESULT: no differences` for all five selectors, light and dark.
- **What that does and does not show:** the story and the real screen agree on those twelve properties at those five places. It does not cover other selectors, other viewports or the real layout shell around the page. **Small follow-up for you to schedule:** let the capture script (or the probe) write or wrap a full document so the compare mode works on the script's output without a hand step.

### The verified-recovery test outcome

"Recovery verified" stayed in the journey test (it was not cut): the whole file ran green under four random seeds and seed 0 (four tests each, 0 failures), and a plant (removing the simulated worker) fails it on its own cause. `operator.spec.ts` remains the real-browser proof of the same chain; the mounted lane ran it green locally on the PR head and hosted on the PR head and on `main` after the merge.

### What was checked (so you do not have to)

- **Real screens unchanged by the extraction:** a canonical-tree comparison of 54 captured real pages (11 scenarios times two pages, 16 `phase173` pages, 16 copy surfaces) against the commit before: 0 differences, with a planted text change failing exactly the pages that contain it. Five new copy surfaces for the new states exist only on the new side.
- **Stories draw the same code:** a story's output equals the real screen's output by the seam tests, and one catalog contract test (ledger row 11 of 12 in `ops-ui`) renders every variation in light and dark, checks structure, coverage, provenance and copy rules. Hosted cost of that test is within noise (finding 30).
- **The storybook is stable across a restart:** the canonical iframe documents of `screens/failed_sync` (light and dark) and `screens/search_health` (light) were identical before and after a stop and start (compared as canonical trees; the raw HTML differs because attribute order and session tokens change per start, which is why raw HTML is never compared).
- **Not checked by anything automatic:** whether it looks and reads right. No design review by an independent reviewer happened, and none is claimed.

## Port deviation (decision for you)

ROADMAP success criterion 5 and PILOT-06 name 127.0.0.1:4003. When this phase started the storybook, another project's process held 4003: `beam.smp` pid 22117, started Sat Nov 21 09:34:22 2026, working directory `/Users/jon/projects/fablebook/hosts/operator` (found with `lsof -nP -iTCP:4003 -sTCP:LISTEN` on 2026-11-22). Nothing here stops or signals another project's process, so the storybook serves on **4013**. The configured default stays 4003.

- **Consequence:** the URL you open is 4013; `npm run ui:preflight` checks whichever port the `storybook` block in `.planning/UI-PREVIEW.json` records (it records 4013 with a `deviation` field).
- **To move it back to 4003, once 4003 is free:** (1) the holder's owner stops that process; `lsof -nP -iTCP:4003 -sTCP:LISTEN` must print nothing. (2) Stop this storybook with the block's `stop` command, then run the block's `start` command (no `CATALOG_PORT`) from `<the storybook checkout named in .planning/UI-PREVIEW.json>/scrypath_ops`. (3) In `.planning/UI-PREVIEW.json` set `storybook.url` to `http://127.0.0.1:4003`, `storybook.port` to `4003` and delete `storybook.deviation`. (4) From that checkout's `examples/scrypath_ecommerce` run `npm run ui:preflight`. An agent can do 2 to 4 as soon as you say 4003 is free. The same start command with the port override is what runs on 4013 now; the 4003 path itself has not been run because the port is held.
- **Or** change the recorded decision to 4013 (edit ROADMAP criterion 5 and PILOT-06). Your call; I recommend moving back, since 4003 is the recorded default and the number other notes name.

## What sizes Phase 198

Phase 198 (the remaining small screens, the Clinicly and Chatly sets, a local browser check, at most 4 plans) is cut by default and sized by your feedback: **cut, shrink or run.**

- **Recommendation: cut**, as the roadmap defaults, unless your look asks for more. JOB-03 is covered end to end, the contract gate is in place, and the open findings (F1 to F4, D2) change what a further set should show, so building more stories before you decide them risks drawing states you then change.
- **It would shrink or run if you ask for:** Search or Sync and index as whole surfaces (the roadmap adds them only on feedback); the Chatly cutover story (blocked by F3 unless you accept deriving it from the `__reindex` tasks); the local browser check over fixed iframe URLs (SCALE-03, not a required gate).
- **If it is cut:** the milestone-end review (FLOW-05) runs next, before the audit, complete and cleanup steps, and this note's feedback folds into the v1.50 input. The run does not start Phase 198, the audit, complete or cleanup, or any release on its own, and no release PR is open (0 before and after the code PR merge; the count after the docs merge is in the hand-off).

## Decisions (maintainer, 2026-11-22: "follow ur recs")

- **Phase 198: cut.** FLOW-05 (the milestone-end review, Pause 2) is next; the audit, complete and cleanup steps have not run. PILOT-07 is closed.
- **Fixtures project: keep separate**, revisit at the `phase173` host-spec port or v1.51.
- **Badge story: one variation** (feedback row 2). Feedback row 1 stays as is.
- **Port: accepted as 4013 (maintainer, 2026-11-22: "you can just restart and use another port").** PILOT-06 closed with the port wording amended.
