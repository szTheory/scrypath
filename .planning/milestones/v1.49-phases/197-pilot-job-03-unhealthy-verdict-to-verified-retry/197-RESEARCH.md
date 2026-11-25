# Phase 197: Pilot JOB-03, unhealthy verdict to verified retry - Research

**Researched:** 2026-11-22
**Domain:** Elixir/Phoenix LiveView extraction under a mounted-test safety net, `phoenix_storybook` 1.5.0 stories over pure view-models, a DB-free stable catalog server, and a review loop (Pause 1)
**Confidence:** HIGH for mechanics (every load-bearing claim below was run in a scratch copy of HEAD, not read off a prep note); MEDIUM for hosted CI cost predictions (estimates, not measurements)

How this was done: a clean `git archive HEAD` copy of the repo under the session scratchpad (`.../scratchpad/repo`), the real repo untouched (`git status` shows only the three config files that were dirty at the start). Scratch Postgres database and every started process were removed. Evidence tags: `[VERIFIED: scratch run]` means I ran it; `[VERIFIED: path:lines]` means I opened the file with Read this session and quote the value verbatim.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
(Copied verbatim from `197-CONTEXT.md` `## Decisions`.)

#### Recorded maintainer decisions (adopted 2026-11-21, SYNTHESIS.md, ADR 0001 and 0002; not re-opened here)
- The pilot job is JOB-03 end to end, entering at Search health (Search health is the cheapest first extraction slice, not the pilot) — **Reversibility:** costly — SYNTHESIS records it; changing the pilot changes the plans, stories and contract test
- Journey first and green on current code, then extraction; the parity capture is throwaway local evidence (not a CI gate); the journey stays green unmodified through extraction
- Story tiers are the glossary tiers `primitives/ patterns/ areas/ surfaces/ jobs/` (not Screen/Flow); JOB ids in file paths; adopter as a variation dimension; both themes shown; scrypath chrome keeps the Scrypath brand; adopter theming only in one Hosting story; story descriptions claim no more than the linked test proves. The glossary and the playbook tier wording are edited in the same change so they agree — **Reversibility:** costly — folder names and ids are public to the maintainer's review notes
- The catalog contract test runs inside the existing `ops-ui` job as ledger row 11 of 12 with a deletion trigger and expected churn recorded in `CONTRIBUTING.md`; no new required CI context, no branch-protection change
- The seeded storybook is on 127.0.0.1:4003 with its own `storybook` block in `.planning/UI-PREVIEW.json`; the 4002 preview stays the mounted-behavior surface; `npm run ui:preflight` checks both; AGENTS.md "UI work" is updated to match
- Findings stay with the maintainer unless they say otherwise: F1, F2, D2, F3, F4 (see GO-NO-GO.md and 196-FINDINGS.md); the stale-sudo `return_to` defect D1 is the one defect fixed here, in `scrypath_ops` only, with no root `lib/` change, under a `chore` or `test` PR title that says plainly it fixes a defect
- No Hex release and no release PR; PR titles are `docs`, `chore`, `test` or `ci`; never stage `.planning/config.json`, `.planning/state.json`, `.impeccable/config.json`; at most 5 plans (the milestone stops and re-asks at 20; 8 of 17 planned are done)
- One operator persona in this phase; no `decide` function for authorization; `retry_decision` (eligibility, not authorization) is cut first if the pilot overruns
- Refused: state grids or manifests, hash-bound or screenshot baselines, an LLM critic as a gate, a parallel gallery, a second journey

#### Carried from Phase 195 and 196
- Phase 195 mounted `phoenix_storybook` (dev/test only, route guard outside the quote with `Application.compile_env`, `storybook.js` hooks, five primitives, render-all through the real iframe route with LazyHTML selectors and cause-pinned planted failures). `catalog_contract_test.exs` already exists with the render-all describes: this phase extends it, never replaces it
- Phase 196 built `fixtures/scrypath_fixtures` (11 scenarios across Logistify, Shopadelic, Wikily; `Check.invariants/0` with 31 tags; the check task first in the `test` alias). Shopadelic `settings_drift` and `failed_journey` are the pilot's data; builders take `now`; the fake client and fake inspector feed the real normalizers
- The fidelity probe deferred from Phase 195 (a local, non-gating computed-style comparison of a story against the real ops screen, light and dark) is a Phase 197 task with a recorded result, not a gate
- Phase 196 review hand-offs this phase must check before claiming counts: the fake Oban inspector models schema scoping only (the real inspector filters by queue and caps at 100 rows, so a 195-job deep queue is not reachable through it); several `states/0`-style functions have no callers until stories use them
- Lessons: assert with LazyHTML selectors, never regexes over raw HTML; every planted failure asserts its cause; long lanes are phase gates, not per-task checks; commit nothing while a Docker lane runs; set `HEX_HTTP_TIMEOUT=120` for local `mix verify.ops_ui`

#### Fixtures fold evaluation (ADR 0002 exit rule, decided here)
- `fixtures/scrypath_fixtures` still has one consumer (`scrypath_ops`) and the storybook lives inside it. The exit rule folds it into `scrypath_ops/` if no second consumer appears by Phase 197. This phase does not fold it silently: the Pause 1 note presents the evidence (one consumer; the measured hosted cost of keeping it was warm minus control of -3 s; folding is one plan of renames plus reversing the root accounting) with a recommendation, and the maintainer decides at the pause — **Reversibility:** costly — folding moves a top-level project and touches the boundary tests, Docker stages and classifier

#### Decided autonomously
- [Plan order] "(1) journey on current code, repaired `failed_sync_live_test.exs:540`, parity capture script; (2) view-models and Search health areas and stories; (3) Failed sync areas and stories; (4) recovery areas, the `return_to` fix and the catalog contract test; (5) the 4003 seeded storybook, `UI-PREVIEW.json`, preflight, AGENTS.md, landing page, the fidelity probe and the Pause 1 note" — plan boundaries are planning metadata and cheap to re-cut; the planner may re-cut within the 5-plan cap
- [View-model split] "Split into `scan/2` (I/O) and `build/4` (pure), closed enums for page state, summary kind, row action and recovery status" — internal module shapes, cheap to revise
- [Story count] "About 40 variations at most; drop any that render identically" — a cap, not a contract
- [Copy lint reuse] "Reuse the existing `copy_rules.json` and `CopyRules` helpers over every story's rendered HTML, adding 4 to 6 pilot surfaces only for states the mounted pages can reach" — no new rule engine
- [Seeded server mechanism] "A dev-env storybook serving fixtures with the pinned preview epoch, no database data required; the planner and researcher choose the exact mechanism and prove it is stable across restarts" — an implementation detail with a recorded proof

### Claude's Discretion
Module, component and story names within the tiers, the exact set of areas per surface, the parity-capture script's form, and the landing page layout (it must show `main@sha`, the tiers, and a short "what you are looking at" note; it must not claim a design is approved)

### Deferred Ideas (OUT OF SCOPE)
- Sync and index as a whole surface, Control room, Search, Help, Clinicly and Chatly sets, the local browser check: Phase 198 or v1.51
- Findings F1, F2, F3, F4, D2 and the dashboard_routes guard defect: with the maintainer
- A typed authorization `Gating.decide` and a read-denial model: no second consumer, deferred
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PILOT-01 | Mounted journey first, green on current code; denial through allowlist and stale sudo with positive controls and absence check; repair `failed_sync_live_test.exs:540` | The journey runs today on Shopadelic `failed_journey` through "Retry queued" with two small stubs, and through "Recovery verified" with one fixtures edit plus five test-local seams (sections "Journey", Pitfalls 1-4). The `:540` test and D1 reproduced (Pitfall 5). |
| PILOT-02 | Fix D1 (`return_to`) in `scrypath_ops` only, with its own test | Confirmed by a mounted test; one assign in `Live.OnMount` covers all three gated LiveViews (Pattern 2, Pitfall 5). |
| PILOT-03 | Extract view-models and function components under the net; parity capture; journey unmodified | Exact `defp` inventory and a proven parity method (sorted-attribute DOM canonicalization; a raw text diff false-positives) (Patterns 3-5). |
| PILOT-04 | Glossary-tier stories, adopter dimension, JOB ids in paths, both themes, descriptions claim no more than the test proves | Story mechanics verified against 1.5.0: `variations/0` runs at compile time, struct attributes render, extra story functions load (Pattern 6). |
| PILOT-05 | One `catalog_contract_test.exs` as ledger row 11 of 12 inside `ops-ui` | Check designs with planted inputs, no hard-coded counts (Pattern 7); ledger rows, wiring test and cost (Pattern 8). |
| PILOT-06 | Stable seeded storybook on 127.0.0.1:4003, `storybook` block, `main@sha` landing page, preflight, AGENTS.md | `MIX_ENV=dev mix phx.server` is not stable without Postgres (measured). A dedicated catalog endpoint started by a Mix task is (measured). Port 4003 is currently held by another project (Pattern 9). |
| PILOT-07 | Pause 1 note and feedback template | Template, location, packet content and fixtures-fold evidence (Pattern 11). |
| FLOW-01..05 | Standing: no release, plan caps, never stage config files, record findings, milestone-end review | Local mirror table and PR-title rule (Validation Architecture). |
</phase_requirements>

## Summary

The prep notes were right about the shape and wrong in six places that change the plans. **(1)** The Phase 195 stories currently render in the browser with the wrong font: the storybook sandbox class `.psb-sandbox` sets `font-family: serif, system-ui, sans-serif` on `<body>` and beats the product stylesheet, so every story the maintainer would open on 4003 reads as Times, while the real screen uses Hanken Grotesk. Colors, borders, radii, padding, sizes and weights were identical in light and dark on the one story I probed; the font was the only difference. **(2)** A real production defect the journey finds on its own: `SyncDriftLive` crashes on render (`KeyError :replacement_job`) whenever the "Check sync status" handoff cannot be resolved (expired 10-minute receipt, another node, a deploy, a different organization), because `recovery_evidence` becomes `%{}` and the template reads `.replacement_job`. Call it D3. **(3)** `variations/0` in a story runs at compile time of the storybook backend, so story data can only come from pure builders: this is exactly why `Posture.summary/4` must split, and it is also why the story data path must call `Scrypath.sync_status/2` and `Scrypath.failed_sync_work/2` directly with the scenario's own opts. **(4)** The journey can reach "Recovery verified", not only "queued", but only with a one-function fixtures edit (`Product.search_records/2`) and about 90 lines of test-local seams; "queued" needs two stubs. **(5)** A raw-text diff of rendered HTML false-positives: after one unrelated recompile, the rest-attribute order on an untouched button changed. The parity capture and the no-identical-variations check must compare a parsed tree with sorted attributes. **(6)** `MIX_ENV=dev mix phx.server` cannot be the 4003 mechanism: with Postgres down each request takes 4 s, with the database missing every route returns 503, and on this machine's existing dev database it returns 503 for pending migrations.

**Primary recommendation:** Build in the CONTEXT order, but (a) make the journey end at "Retry queued on Sync and index" as the required result and add "Recovery verified" as a cut-able second test in the same file; (b) fix D1 with one assign in `Live.OnMount`; (c) put story data behind pure builders (`Posture.build`, `FailedSyncView.build`, `RecoveryView.build`) and compare parsed trees, never text; (d) serve 4003 from a small dedicated `ScrypathOps.Catalog.Endpoint` started by a Mix task (no Repo, no reloader, no watchers); (e) fix the sandbox font before the maintainer looks; (f) ask the maintainer about D3 before Plan 4 (a second defect fix is a scope change under CONTEXT).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Scan Meilisearch and Oban status, retry, receipts, gating, observation | LiveView process (`PostureLive`, `FailedSyncLive`, `SyncDriftLive`) | `Scrypath.*` (root library, unchanged) | Events, `start_async`, `Gating` and receipt registration stay in the process (CONTEXT, D note) |
| Classify and format what to show (headline, kind, facets, copy, row facts, recovery status) | Pure view-model modules in `lib/scrypath_ops/` | none | Closed enums, no Phoenix, no clock, no process; the only thing a story may call |
| Markup | Function components in `lib/scrypath_ops_web/components/` | `OpsUi` primitives | One implementation called by both the LiveView and its story (seam test proves it) |
| Fixture data | `fixtures/scrypath_fixtures` builders (pure) | `ScrypathOps.Test.FixtureEnv` (tests only) | Story data never touches global app env; tests may, with restore |
| Story definitions | `scrypath_ops/storybook/` (tracked, dev/test) | `scrypath_ops/catalog/lib` wrappers | Tiers by folder; wrappers only supply `now`, `mount_path`, `flash` |
| Catalog serving on 4003 | `ScrypathOps.Catalog.Endpoint` + Mix task (dev only, `catalog/lib`) | `.planning/UI-PREVIEW.json`, `npm run ui:preflight` | Isolates the review surface from Postgres and the code reloader |
| Gate | `catalog_contract_test.exs` in `ops-ui` | `CopyRules` helpers, `LazyHTML` | Untouched required context; one ledger row |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix_storybook` | 1.5.0 (in `scrypath_ops/mix.lock`, dev/test only) | Story index, iframe route, themes | Already adopted (ADR 0001); verified against its 1.5.0 source in `deps/` |
| `phoenix_live_view` | 1.1.34 | `render_component/2`, LiveViewTest | Already locked |
| `lazy_html` | 0.1.14 (`only: :test`) | All HTML assertions, canonical trees | Project lesson: never regex raw HTML |
| `req` | 0.7.5 | `Req.Test` plug and `Req.default_options/1` for the optional "verified" journey seam | Already locked; `Req.Test` ships in it |
| Playwright (`playwright-core` 1.60.0) | in `examples/scrypath_ecommerce/node_modules` | Local, non-gating fidelity probe | Already installed with Chromium builds in `~/Library/Caches/ms-playwright` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `ScrypathFixtures` | path dep, `only: [:dev, :test]` | Scenarios, fake client, fake inspector, preview epoch | Every story and the journey |
| `ScrypathOps.Test.FixtureEnv` | test/support | Puts a scenario into app env and a clock file, returns a restore fun | Journey and parity capture only (never stories) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Dedicated catalog endpoint + Mix task | `MIX_ENV=dev mix phx.server` | Rejected by measurement: needs a live, migrated Postgres, 4 s per request when it is down |
| Dedicated catalog endpoint | Docker Compose service (prep C) | Heavier, needs Docker and image rebuilds; keep as a later option if the maintainer wants a container |
| Parsed-tree comparison | Raw or whitespace-normalized text diff | False-positives on attribute order (measured) |

**Installation:** none. No new package, no `mix.lock` change.

**Version verification:** `phoenix_storybook` 1.5.0, `phoenix_live_view` 1.1.34, `lazy_html` 0.1.14, `req` 0.7.5 read from `scrypath_ops/mix.lock` (grep, 2026-11-22). Playwright `1.60.0` read from `examples/scrypath_ecommerce/node_modules/playwright-core/package.json`.

## Package Legitimacy Audit

No external package is added or changed in this phase, so no `package-legitimacy check` was needed. `phoenix_storybook`, `mdex` and friends were audited in Phase 195 (GO-NO-GO.md "Advisory status").

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| (none new) | - | - | - | - | - | - |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
 fixtures/scrypath_fixtures                     ScrypathOps (scrypath_ops)
 ┌──────────────────────────┐   scenario opts    ┌──────────────────────────────────────────────────┐
 │ Shopadelic/Logistify/    │ ─────────────────► │ MOUNTED PATH (tests, 4002 preview)               │
 │ Wikily builders (pure,   │  (fake client,     │  PostureLive ─link─► FailedSyncLive ─handoff─►   │
 │ take `now`)              │   fake inspector)  │  SyncDriftLive      (Gating, receipts, observe)  │
 └──────────────────────────┘                    │      │ scan (I/O)        │ build (pure)          │
              │                                   │      ▼                   ▼                      │
              │ called DIRECTLY at story compile  │  Posture.scan/2 ─► Posture.build/3              │
              │ (no app env, no processes)        │  Scrypath.failed_sync_work ─► FailedSyncView     │
              ▼                                   │  receipt/observation ─► RecoveryView             │
 ┌──────────────────────────┐                    │      │ view-model structs (closed enums)         │
 │ storybook/*.story.exs    │ ── attributes ───► │      ▼                                          │
 │ variations/0 (compile    │                    │  Function components (areas/patterns)           │
 │ time) per tier folder    │                    │   called by the LiveView render AND by stories   │
 └──────────────────────────┘                    └──────────────────────────────────────────────────┘
              │                                                     │
              ▼                                                     ▼
 ScrypathOps.Catalog.Endpoint (4003, no Repo)              catalog_contract_test.exs (ops-ui):
  /storybook/welcome (main@sha), /storybook/iframe/...      render-all → canonical tree → identical?,
              │                                              copy lint, DOM hygiene, coverage, planted inputs
              ▼
 npm run ui:preflight ──► .planning/UI-PREVIEW.json "storybook" block   Pause 1 note (.planning/research/)
```

### Recommended Project Structure
```
fixtures/scrypath_fixtures/lib/scrypath_fixtures/shopadelic/product.ex   # + search_records/2 (only if "verified" journey is kept)
scrypath_ops/
├── lib/scrypath_ops/
│   ├── posture.ex                  # scan/2 public + build/3 pure; summary/2..4 unchanged (thin composition)
│   ├── failed_sync_view.ex         # NEW pure: build(loads, scope, receipts, now) + Row struct
│   └── recovery_view.ex            # NEW pure: build(status, evidence, doc_observation, error, ...) 
├── lib/scrypath_ops_web/components/
│   ├── search_health.ex            # NEW: health_verdict, schema_row, schema_row_error
│   ├── failed_sync.ex              # NEW: failed_summary, failed_filters, failed_row, retry_receipt, delete_confirmation, load_error
│   └── recovery.ex                 # NEW: recovery_status, document_freshness
├── lib/scrypath_ops_web/live/on_mount.ex   # D1: one assign(:return_to, ...) in the existing handle_params hook
├── catalog/lib/scrypath_ops/catalog/{endpoint,router,build_info}.ex     # NEW dev-only serving + sha
├── catalog/lib/mix/tasks/scrypath_ops.catalog.serve.ex                  # NEW
├── storybook/{welcome.story.exs, _storybook.index.exs}                  # NEW landing (first leaf) 
├── storybook/primitives/ (existing 5) patterns/ areas/ surfaces/ jobs/  # NEW tiers, each with an *.index.exs
├── test/scrypath_ops_web/live/catalog_journey_test.exs                  # NEW (Sigra names allowed here by the fence)
├── test/scrypath_ops_web/catalog_contract_test.exs                      # EXTEND
└── test/support/{html_canon.ex, catalog_checks.ex}                      # NEW small pure helpers (copy, no dependency)
```

### Pattern 1: The journey on current code (PILOT-01)
**What:** one ExUnit file, `async: false`, Shopadelic `failed_journey` through `FixtureEnv.put/1`, then `Application.put_env` for the two queue seams, then `live/2` through the real router.
**What I ran (scratch, green on current code):**
- `live(conn, "/ops/health")` renders a degraded verdict (`Failed` word, headline "Sync jobs and Meilisearch tasks failed", evidence "3 sync jobs and 1 Meilisearch tasks failed. ..."), row statuses `["failed","failed","retrying","failed"]`, and the link `[data-testid='posture-failed-sync-link']` with href `/ops/failed-sync?schema=ScrypathFixtures.Shopadelic.Product` `[VERIFIED: scratch run]`. The link markup is `navigate={OperatorSelection.path(@mount_path, "failed-sync", mod)}` and `data-testid="posture-failed-sync-link"` `[VERIFIED: posture_live.ex:357-364]`.
- Failed sync for that schema lists 5 rows (ids 102 retrying, 43 Meilisearch task, 103, 101, 104; sort is last attempt descending); Retry buttons exist for 102, 103, 101, 104; row 43 (a Meilisearch task) has none `[VERIFIED: scratch run]`. Failed counts agree across the two pages (Health: 3 jobs + 1 task failed; Failed sync summary: 4 failed, 1 retrying by `summary_headline`), a useful cross-check assertion `[VERIFIED: failed_sync_live.ex:618-637]`.
- Retry of job 101 (a discarded upsert of `SPD-2041` and `SPD-2042` after transport errors) gives `Retry queued · queue job 991`, receipt text "Oban job #991 will add or update records in shopadelic_product ... Original job #101 is retained", one insert, flash `%{"info" => "Retry queued · queue job 991"}` `[VERIFIED: scratch run]`.
- The receipt link `Check sync status` goes to `/ops/sync-and-index?recovery=<24-byte url-safe handle>&recovery_generation=0&schema=ScrypathFixtures.Shopadelic.Product`. On Sync and index: `recovery_origin_generation` 0 (page `context_generation` 1, so the two generations are separate), status `:accepted`, "Retry queued", evidence line "Queue job 991 · attempt 1 · Active index shopadelic_product" `[VERIFIED: scratch run]`.
- Return links on Sync and index: "Review failed sync work" to `/ops/failed-sync?schema=ScrypathFixtures.Shopadelic.Product` and "Inspect search health" (`OperatorSelection.path(@mount_path, "health", @selected_schema)`, `sync_drift_live.ex` "Related search views" nav) `[VERIFIED: scratch run; operator_ia_contract_test.exs:144-145]`. The health link carries only `schema`; there is no "run" concept, so "same index and run" means schema scope plus the same job ids and counts.

**Seams the "queued" end needs (the only ones):** a queue module with `insert/1` and `config/0` (the existing `FailedSyncStubs.RecordingOban` has `insert/1` and the `:failed_sync_insert_counter` Agent but no `config/0`), and a repo module with `get/3` returning the inserted job. The inserted job must have `attempt: 0` (so the receipt expects attempt 1) and the repo must return it with `attempt: 1` and `state: "available"` `[VERIFIED: scratch run; attempt_mismatch otherwise]`.
**Seams "Recovery verified" adds (all scratch-proven, about 90 lines):** `Product.search_records/2` in the fixtures project (the fixtures `Product` is an `embedded_schema`, so the default loader cannot query it and `check_loadable` returns `repo_required` without a repo), a client wrapper that adds `task/2` to `FakeMeilisearchClient`, `Req.default_options(plug: {Req.Test, Name})` plus `Req.Test.set_req_test_to_shared/1` and a stub serving `GET /indexes/<index>/documents/<id>` (the document check issues real HTTP to the scenario's `.invalid` URL), the repo returning the job as `completed` attempt 1, and a simulated worker: in one `Task`, `:telemetry.execute` of `[:oban,:job,:start]`, `[:scrypath,:meilisearch,:task_wait,:start]`, `[:scrypath,:meilisearch,:task_wait,:stop]` (with `task_uid` and `final_status: "succeeded"`) and `[:oban,:job,:stop]` so `RecoveryObservation` learns the task uid. Result: "Recovery verified", evidence "Queue job 991 · attempt 1 · Meilisearch task 44 · Active index shopadelic_product", `expected_ids ["SPD-2041","SPD-2042"]` `[VERIFIED: scratch run]`. Use `:sys.get_state(ScrypathOps.RecoveryObservation)` as the barrier, not `Process.sleep` (scratch used a sleep; AGENTS test rules forbid it).
**Mode rule:** run the linear journey with `OPSUI_AUTH_MODE` unset (`basic`, no `operator_context`, so the gate runs the action directly) because the Sync and index mount runs `maybe_start_recovery` inside `handle_params` before a test can inject assigns; a Sigra-mode receipt is registered under org `o1` and the second mount has no org, so the handle resolves to `:unknown` (and crashes, Pitfall 3). Test denials in separate Sigra-mode tests on a single mounted Failed sync view.
**Denials (scratch-proven on Shopadelic):** `?schema=ScrypathFixtures.Shopadelic.Gone` shows "That schema is unavailable.", no row, no `SPD-2041`, and does not echo the requested name; the allowed page shows `SPD-2041` (positive control) `[VERIFIED: scratch run]`. Stale sudo (age 600 s, window 300) on the mounted view redirects to `/sudo/confirm?...`, zero inserts, and a fresh mount shows row 101 still retryable `[VERIFIED: scratch run]`. Do not assert the `return_to` value in the journey: today it is `%2F` (D1, Pitfall 5); the value is asserted by the D1 test in Plan 4.
**Helpers:** `sudo!/1` (`failed_sync_live_test.exs:76-86`) and `put_live_assigns/2` (`:810-819`) are private `defp`s, not shared. The namespace fence allows `Sigra.` in tests only under two prefixes, `"scrypath_ops/test/scrypath_ops/integrations/sigra/"` and `"scrypath_ops/test/scrypath_ops_web/live/"`, and in `scrypath_ops/lib/` only under `"scrypath_ops/lib/scrypath_ops/integrations/sigra/"` and `"scrypath_ops/lib/scrypath_ops_web/live/"`, so `test/support` and `lib/scrypath_ops_web/components/` may not name it `[VERIFIED: dev/mix/tasks/verify.namespace_fence.ex:19-28]`. Copy the two helpers into the journey file (house preference: copy over a dependency); do not move them into `test/support`.
**Repair of `:540`:** replace the hand-built socket (`loads: nil`, a `host_uri` with a path that real LiveView prunes) with a mounted view: `live(conn, "/ops/failed-sync?schema=...")`, stale-sudo assign, click the *rendered* `[data-testid='failed-sync-retry']`, `assert_redirect` path starts with `/sudo/confirm`, counter `0`, remount shows the row; positive control: fresh sudo, same click, counter `1`.

### Pattern 2: D1, `return_to` (PILOT-02)
**Confirmed on a mounted view:** `host_uri` is `%URI{path: nil, ...}` (LiveView prunes path and query) and a stale-sudo retry redirects to `"/sudo/confirm?return_to=%2F"`; with `:return_to` assigned the redirect carries it `[VERIFIED: scratch run]`. Cause: `defp return_to(%{assigns: assigns, host_uri: %URI{path: path}}) do Map.get(assigns, :return_to) || path || "/" end` `[VERIFIED: gating.ex:182-186]`.
**Fix location:** three LiveViews gate sensitive actions: `SearchLive` (assigns `:return_to` at `search_live.ex:122`), `FailedSyncLive` (three call sites) and `SyncDriftLive` (`swap_live`, `:1220`) `[VERIFIED: grep this session]`. One `assign(socket, :return_to, path <> query)` in the existing `attach_hook(:scrypath_ops_mount_path, :handle_params, ...)` in `ScrypathOpsWeb.Live.OnMount` covers all three (the hook runs before each view's own `handle_params`, so `SearchLive`'s explicit assign still wins). Build the value from the parsed `uri` path and query only; require it to start with `/` and not `//`; never use host. This keeps the filters (`?schema=`, `?cause=`) across the sudo round trip.
**Test (its own):** mount Failed sync with a filtered URL, stale sudo, click retry, assert the redirect `return_to` decodes to that exact path and query; a second assertion for `/ops/sync-and-index?schema=...` through `swap_live` if reachable cheaply; planted mutation: delete the assign, test goes red. PR title `test(ops-ui):` or `chore(ops-ui):` and the body says it fixes a defect (FLOW-01). The existing `gating_test.exs` stays as is (no `Gating` refactor, CONTEXT).

### Pattern 3: `Posture` split and the extraction inventory (PILOT-03)
**Posture today:** `summary/4` is a `cond` with three branches; only the third calls `scan(allowlist, opts)`, which starts `Task.Supervisor.async_stream_nolink(ScrypathOps.TaskSupervisor, ...)` `[VERIFIED: posture.ex:67-106, 279-297]`. The second half is already pure (counts, `classify/1`, `refresh_success_refs/3`). I proved the split in scratch: `summary/4` becomes `build(scan(allowlist, opts), snapshot_at, previous)` with `build/3` holding the old branch verbatim; Posture state values stay `:unconfigured | :missing_backend | :degraded | :ok` `[VERIFIED: posture.ex:18]` and the existing 16 scenario round trip (`fixtures_round_trip_test.exs`) is the net. Recommend `build(input, now, previous)` with `input :: :unconfigured | :missing_backend | [row]` so the Wikily setup states are storiable too. Keep `summary/2..4` signatures (`ControlRoomLive` calls them).
**What moves out of `posture_live.ex`** (23 `defp`s in lines 559-725, all pure `[VERIFIED: awk this session]`): `row_status_word`, `failed_work_present?`, `posture_schema_count`, `sync_summary`, `state_at`, `state_source_iso`, `time_state_text`, `queue_time_state_text`, `source_last_success_label`, `source_ref`, `retained_state_at`, `retained_source_iso`, `retained_snapshot_at`, `retained_state_text`, `fetch_error_copy`, `retained_evidence_text`, `queue_counts_text`, `backend_counts_text`, `counts_text`, `facts_time_label`, `lower_first`, `sync_mode_label`, `queue_unobserved_copy`. Stays: mount, refresh, `swap_live`, `load_posture`, the Phase 173 fixture branches (untouched; identity-hashed in receipts).
**What moves out of `failed_sync_live.ex`** (43 distinct `defp` names in lines 473-845): move all but the three the event handlers need (`find_row`, `row_by_key`, `row_key`; `all_rows` and `cause` are needed by both, so they live in `FailedSyncView` and the LiveView calls them). Closed enums already latent: causes `@causes [:validation, :transport, :backend_rejected, :queue_exhausted, :unknown]` `[VERIFIED: failed_sync_live.ex:21]`; summary kind from `cond` `rows != [] -> :warning`, `... -> :neutral`, `scoped_errors(assigns) != [] -> :partial`, `true -> :success` `[VERIFIED: :609-616]`; row sync status `:retrying` else `:failed` `[VERIFIED: :699-700]`; page state `:no_schemas`, `:unavailable`, `loads == :missing_backend`, ready (assigns at `:895-922`). Proposed row action enum: `:retry | :receipt | :ineligible` (+ `:confirm_delete` as state, not action).
**What moves out of `sync_drift_live.ex`:** six pure helpers (`recovery_status_label/kind/copy`, `document_observation_title/kind/copy`, lines 578-667) and the two sections `document-freshness` and `ordinary-recovery` (lines 2072-2192). Recovery status values `nil | :accepted | :running | :queue_only_completed | :verified | :failed | :cancelled | _` with labels `"Not checked"`, `"Retry queued"`, `"Retry running"`, `"Queue job completed; backend evidence pending"`, `"Recovery verified"`, `"Recovery failed"`, `"Recovery canceled"`, `"Recovery outcome could not be checked"` `[VERIFIED: sync_drift_live.ex:578-588]`. Make `RecoveryView.evidence` `nil | %{replacement_job, attempt, task_uid, index}` so the D3 shape cannot exist.
**Counts:** `:if=` occurrences 31 (failed sync), 63 (sync and index), 19 (posture) `[VERIFIED: grep -c]`; Plan 4 touches only the recovery slice of the 63.
**Component conventions (`OpsUi`):** `attr(...)` with parentheses (247 occurrences, 0 unparenthesized in `ops_ui.ex` `[VERIFIED: grep -c]`), closed atom lists via `values:`, doc strings, `attr(:class, :any, default: nil)`, no `@flash`/socket reads. `ops_time` falls back to `ScrypathOps.Clock.utc_now()` without `snapshot_at` and builds ids with `System.unique_integer` without `id` (`assign(:time_id, assigns.id || "ops-time-#{System.unique_integer([:positive])}")` `[VERIFIED: ops_ui.ex:1340]`), so every extracted component takes `now` and passes `snapshot_at={@now}` and explicit ids (`failed-attempt-<dom id>` etc. already exist).
**`retry_decision`:** cut first if the pilot overruns (CONTEXT). It does not block anything else.

### Pattern 4: The throwaway parity capture (PILOT-03)
**Method (proven in scratch):** one untracked ExUnit file that, for each of the 11 scenarios and each page (`/ops/health`, `/ops/failed-sync`), `FixtureEnv.put/1`, `live/2`, `render_async/1`, writes the HTML. Run it with `PARITY_OUT=<dir>` in a base tree and in the head tree (`git worktree add <dir> <base sha>`, then `rsync` `deps` and `_build` to avoid a cold compile; the `git archive` copy I used lacks `.git`, so `CopyRulesContractTest` cannot run there). Compare **canonical trees**, not text.
**Why not text:** after one unrelated source edit and recompile, the `phx-click="refresh"` attribute moved position on an untouched refresh button (the `{@rest}` global attribute order is not stable between builds); a whitespace-normalized text diff then reported all 22 captures as different, including pages whose code did not change `[VERIFIED: scratch run]`.
**Canonical form that worked:** parse with `LazyHTML.from_document/1` and `LazyHTML.to_tree/1`; drop comments; sort every element's attributes by name; replace `ops-time-<n>` with `ops-time-N`; replace `data-phx-session`, `data-phx-static` and long csrf `content` with `TOKEN`; replace `id`/`data-phx-id`/`data-phx-root-id` values starting `phx-` with `phx-ID`; collapse text whitespace and drop empty text; one node per line.
**Controls recorded:** same code run twice: 0 differences in 22 canonical captures; a planted text change (`Retry` to `Retry now`) changed exactly the 2 captures that render a retry button (Shopadelic `failed_journey` and `hostile_ids` failed pages) and none of the health pages `[VERIFIED: scratch run]`. The tooltip reads "just now · 2026-11-20T14:00:00Z" because `FixtureEnv` writes the clock file; both trees must run under it.
**Add 6 to 8 pilot states** the scenario pages cannot reach (delete confirmation open, receipt shown, load error, recovery statuses through `render_with_assigns`, `CopySurfaces`). `CopySurfaces` already renders 16 anchored surfaces and merges assigns into `SyncDriftLive.render/1` for unreachable states (`test/support/copy_surfaces.ex`, read via shell this session); reuse it.
**Standing replacement, no new gate:** one seam test per area (Pattern 5).

### Pattern 5: The seam test (story output equals production output)
Mounted page contains the component's own output: `render_component(&FailedSync.failed_row/1, assigns)` (the macro in `Phoenix.LiveViewTest`; there is no `rendered_component/2`) renders the component to a string; parse both it and the mounted page with `LazyHTML`; select the same root in both (`[data-testid='failed-sync-row']`, `[data-testid='posture-row']`, `section[aria-labelledby=...]`, `[data-testid='recovery-receipt']`) and assert canonical-tree equality for the same view-model built from the same scenario (`now` equals the clock file). A structural selector avoids adding attributes; adding one (for example a `data-testid`) is an intended change to list in the parity review.

### Pattern 6: Stories (PILOT-04)
- **`variations/0` runs at compile time.** First attempt (`Posture.summary` in a story) failed the compile of `ScrypathOps.Catalog.Storybook` with `GenServer.call(ScrypathOps.TaskSupervisor, ...) no process` `[VERIFIED: scratch run]`. Therefore story data = scenario opts handed straight to the real functions: `Scrypath.sync_status(mod, scenario.scrypath_opts)` then `Posture.build/3`; `Scrypath.failed_sync_work(mod, Keyword.put(opts, :reason_class_counts, true))` then `FailedSyncView.build/4`. Both work with no application started and return real entries (Shopadelic `failed_journey`: ids 43 meilisearch/validation, 101 oban/transport, 102 retrying/transport, 103 oban/unknown, 104 delete oban/queue_exhausted) `[VERIFIED: scratch run, mix run --no-start]`. A bad story fails `mix compile`, which is a free first gate.
- **Struct attributes are fine.** A `%ScrypathOps.Posture{}` (nested row maps) as a variation attribute rendered on the story page (2 iframes via `srcdoc`), the single-variation URL, the Playground tab and the real iframe route, none crashed `[VERIFIED: scratch run]`.
- **Extra public functions on a story module compile and load** (`job/0`, `covers/0`), so provenance metadata can be plain functions read by the contract test, no registry `[VERIFIED: scratch run]`. `load_story/1` takes the path without a leading slash.
- **Folders and the sidebar:** an index is any file whose name ends in `.index.exs` (`def index_file_suffix, do: ".index.exs"` `[VERIFIED: entries.ex:24]`), giving `folder_name`, `folder_index`, `entry("file") -> [name:, index:]` (`index.ex` docs); sidebar search reads only path and name (prep F note, 1.5.0 `search.ex`), so JOB ids go in file names (`jobs/job_03_on_call_recovers_failed_sync.story.exs`). `/storybook` with no story param patches to the first leaf: `case first_story_path(socket) do ... path -> {:noreply, patch_to(socket, socket.assigns.root_path, path)}` `[VERIFIED: story_live.ex:87-91]`; the docs say unindexed folders sort after files, so a root `welcome.story.exs` (a `:page` story) is the landing page; give it `entry("welcome") -> [name: "Start here", index: 0]` to be safe.
- **Iframes and events:** `:component` stories with `def container, do: :iframe`; clicks inside the iframe hit `def handle_event(_, _, socket), do: {:noreply, socket}` in `ComponentIframeLive`, so buttons do nothing and cannot crash a story `[VERIFIED: component_iframe_live.ex:253]`. `:page` stories cannot be iframed (Phase 195 H note) so the landing page renders in the PSB shell, fine for prose.
- **Themes:** the backend already declares `themes: [light: [name: "Light"], dark: [name: "Dark"], system: [name: "System"]]` and `themes_strategies: [data_attribute: "theme"]` `[VERIFIED: catalog/lib/scrypath_ops/catalog/storybook.ex:11-12]`. "Both themes shown" = the toolbar dropdown plus render-all rendering light and dark for every variation (already so); the iframe URL takes `?variation_id=<id>&theme=<light|dark|system>` `[VERIFIED: scratch run]`. A side-by-side is not required; `[data-theme=dark]` is a subtree selector in the product CSS if the planner wants one story with a dark wrapper (`app.css` lines 1975+, `@custom-variant dark` at 166).
- **Adopter brand colors and the literal ratchet:** the ratchet roots are `scrypath_ops/lib`, `scrypath_ops/assets`, and the demo `lib`/`assets` `[VERIFIED: ui_literal_policy.cjs:10-15]`; `scrypath_ops/storybook` and `scrypath_ops/catalog` are outside, so a Hosting story's `--color-primary` overrides and inline styles never trip it. The baseline ledger has no entry for the three LiveViews (30 findings, none in them), so moving markup within `lib/` creates no baseline churn unless the moved code already violates (it does not).
- **Variation ids and descriptions:** id = scenario id for scenario-driven variations (`shopadelic_failed_journey`, `wikily_unconfigured`, `logistify_history_over_limit_f1`) so the adopter is a dimension, not a folder; description at most 140 characters; `note` starts with one situation line `Adopter: Shopadelic (fictional) · Persona: On-call (ROLE-OPS) · Job: JOB-03 · Proof: render only|Mounted <test file>`. The contract test parses it with one regex and checks that the adopter is in `ScrypathFixtures.Scenarios.ids/0` adopters, `ROLE-OPS` and `JOB-03` exist in `OPERATOR-UI-QUALITY.md` (rows at lines 28 and 39), and a `Mounted` label names a file that exists. A variation's claim must not exceed its test ("render only" unless a mounted test covers the same state).
- **Cap and cuts:** about 33 area variations from D plus 2 surfaces plus 1 job plus the existing 17 primitive variations; drop any that render identically (the check does it). Cut candidates in order: `retry_decision`, denial-flash patterns (the flash strings live as literals in `gating.ex`; a story would duplicate them or require a `Gating` refactor, refused), the Hosting story.
- **Unreachable states are not stories.** Recovery stories take the `(status, evidence, document_observation)` triple through `RecoveryView.build/…` as the existing tests do; the builder must reject combinations the observer cannot emit (for example `:verified` without a `:verified` document observation).

### Pattern 7: `catalog_contract_test.exs` checks (PILOT-05), each with one planted input
All pure functions over data, each with a positive control; planted inputs live in the same file (house style).
| Check | Design | Planted input and the cause it must report |
|---|---|---|
| Render-all (exists) | Keep `RenderAll.targets/1`, iframe URL, `render_target/3`; the surfaces and areas join automatically | existing crash, empty, unknown variation plants stay green |
| Coverage, no counts | Components = every loaded module of the app with `function_exported?(m, :__components__, 0)` and a non-empty map (`OpsUi` 52, `ResultUi` 2, `CoreComponents` 2, `Layouts` 6 today; LiveViews report 0) `[VERIFIED: scratch run]`; a story covers a component when `story.function() \|> Function.info()` yields its `{module, name}`; routes = `Phoenix.Router.routes(ScrypathOpsWeb.DevRouter)` entries with `metadata.phoenix_live_view` (6 distinct LiveViews plus the Phase 173 and legacy actions and the `/storybook` ones to exclude) mapped by a story's `covers/0`; remainder must be keys of a literal `@no_story %{key => reason}`; a key that is covered or no longer exists fails (stale) | add a fake component name to `@no_story` (stale), delete a covering story entry (missing) |
| No two identical variations | Per story and theme, hash the canonical tree of `[data-phx-main] > *` only (hashing the container itself differs: its `data-phx-session` and `data-phx-static` tokens change per mount; verified: two identical variations hashed differently until tokens were excluded) | a planted story with two identical variations |
| Copy lint | For every rendered variation, evaluate every row of `copy_rules.json` with `required: []` through `CopyRules.evaluate_surface/3`; and `scan_source` already covers `**` scopes; add 4 to 6 surfaces to `CopySurfaces.@anchors`/`render/2` and to some row's `surfaces` (a registered surface no row cites fails `copy_rules_contract_test.exs:574`) | planted `Control Room` text in a story's HTML (casing row) |
| DOM hygiene | LazyHTML over `[data-phx-main]`: unique `id`s; every `aria-labelledby`/`aria-describedby`/`aria-controls` token exists and is not the literal `false`; every `button`, `a[href]`, non-hidden `input`, `select`, `textarea` has a name from non-`aria-hidden` text, `aria-label`, `aria-labelledby`, `label[for]` **or a wrapping `<label>`**, or `title`; exactly one `main` or `[role=main]` for surface-tier stories | duplicate id, dangling `aria-describedby="false"`, bare `<button></button>`, two mains |
| Provenance and description lint | regex over `note`, length, scenario id exists, `Mounted` file exists, `job/0` and `covers/0` resolve | planted bad `JOB-99` and a missing test file |
**Expected state of the hygiene check on current markup:** a probe over the 22 captured real pages found no duplicate ids, no dangling aria references and exactly one `main` on every page; its only hits were the Failed sync cause checkboxes, which are named by a wrapping `<label class="ops-filter-chip">`, a false positive of a naive "has a name" rule (so the implicit-label rule above is mandatory, not optional) `[VERIFIED: scratch run]`.

### Pattern 8: Ledger row 11 of 12 (PILOT-05)
The ledger is the table under `### Required-gate budget` with header `| Gate | Enforced by | Runs in | Deletion trigger | Expected churn per UI PR |` and the line `Budget used: 10 of 12.` `[VERIFIED: CONTRIBUTING.md:250-267]`. `workflow_wiring_test.exs` (`budget_ledger_errors/1`, `ledger_row_errors/1`) fails if there are more than 12 rows (`if length(rows) in 1..12`), any of gate, runs-in, trigger, churn is empty, the Enforced-by cell has no backticked path that exists, or the section lacks `"Budget used: #{length(rows)} of 12."` `[VERIFIED: workflow_wiring_test.exs:2141-2159; row-cell checks at 2162-2180 read via shell]`. Add one row and change the line to `Budget used: 11 of 12.`:

`| Component catalog contract | `scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs` | `ops-ui (path-scoped)` | Delete if the component catalog leaves `scrypath_ops` or moves to its own Mix project (the Storybook boundary row's trigger), or replace it when stories are generated from another source; drops to advisory if red twice in 30 days for non-defects (budget rule) | One `@no_story` entry added or removed per new or newly storied component or route, one description line per new variation; a new story needs no test edit (render-all iterates the story index); a changed `copy_rules.json` row re-runs over every story |`

No new required context: `mix verify.ops_ui` runs the root boundary test then `mix test` in `scrypath_ops` `[VERIFIED: verify.ops_ui.ex:51-58]`, which includes this file; `ops-ui-path` already matches `scrypath_ops/` and `fixtures/` (CI-EFFICIENCY finding 29; fixtures README). Optional hygiene while editing: rows 263 and 265 still say "v1.48" (stale labels; E note hygiene), edit only if the sentence stays true.
**Cost (measured locally, scratch, warm):** `catalog_contract_test.exs` now: 4 tests, 0.4 s ExUnit time (3.95 s wall with boot) for 17 variations times 2 themes; the whole `scrypath_ops` suite: 27.2 s ExUnit time, 28.5 s wall, 727 tests, 2 doctests, 0 failures (31 tests of `CopyRulesContractTest` were invalidated only because the scratch copy has no `.git`; the real tree runs them). Phase 196's local record for the same suite was 715 tests, `mix precommit` 29 s. Rendering costs about 12 ms per variation-theme, so about 100 renders plus parsing is a few seconds `[ASSUMED]` for the final count; hosted `ops-ui` was 342 to 436 s same-hour controls, so the catalog test is under 1 percent of the job `[CITED: GO-NO-GO.md, CI-EFFICIENCY.md finding 29]`. Measure warm against a same-day control after merge (finding 29's revisit trigger).

### Pattern 9: The 4003 storybook (PILOT-06)
**Measured, `MIX_ENV=dev mix phx.server` with the dev endpoint (scratch, port 4013):**
| Condition | Result |
|---|---|
| Postgres unreachable (`PGPORT=1`) | every request about 4 s (the `Phoenix.Ecto.CheckRepoStatus` plug waits), HTTP 200; log fills with `econnrefused` (63 lines in 45 s) |
| Postgres up, database missing | HTTP 503 on every route including `/storybook` |
| Postgres up, this machine's `scrypath_ops_dev` | HTTP 503 `Phoenix.Ecto.PendingMigrationError` |
So the dev endpoint makes the review surface hostage to database state; it also runs the code reloader and (unless disabled) two asset watchers.
**Recommended mechanism (proven):** a second endpoint with no Repo. `ScrypathOps.Catalog.Endpoint` (about 12 lines, same shape as the test-only `PlantedEndpoint`: `Phoenix.Endpoint`, socket `/live`, `Plug.Static` for `assets fonts images favicon.svg favicon.ico`, `Plug.Parsers`, `Plug.Session`) plus `ScrypathOps.Catalog.Router` (`storybook_assets()` and `live_storybook("/storybook", backend_module: ScrypathOps.Catalog.Storybook)`) plus a Mix task that sets `:standalone` to `false` before `app.start` (so neither Repo nor the main endpoint starts), starts the endpoint, and sleeps forever. Config in `dev.exs` only: loopback `ip: {127,0,0,1}`, `port: CATALOG_PORT || 4003`, `server: true`, `adapter: Bandit.PhoenixAdapter`, `pubsub_server: ScrypathOps.PubSub`, `check_origin: false`. All files in `catalog/lib` (compiled only in dev and test, `elixirc_paths`). `[VERIFIED: scratch run]` with `PGPORT=1`: `/storybook` 302 in 0.16 s, story page 200 in 0.39 s, iframe 200 in 0.08 s, `app.css` and fonts 2 ms, zero DB errors, startup to first response about 14 s on a warm `_build/dev`.
**Restart stability proof:** the iframe document fetched before and after a stop and start is byte-identical after normalizing `id="phx-..."`, `data-phx-session/static`, csrf and `ops-time-<n>`; the story page differs only in the csrf token inside `srcdoc` and PSB's random `data-group-id` highlight ids `[VERIFIED: scratch run]`. State is code (fixtures at `ScrypathFixtures.preview_epoch/0`, `~U[2026-11-20 14:00:00Z]`, the only datetime literal in the project) and `variations/0` is compile-time, so there is no data to preserve; the "preserve preview data" rule applies to 4002 only.
**Port 4003 is currently in use on this machine** by another project (a `beam.smp` whose cwd is `/Users/jon/projects/fablebook/hosts/operator`, answering 200 on `/`, `lsof` this session). The start script must (a) detect a holder, (b) call it ours only if `/storybook/welcome` carries the catalog marker, (c) otherwise exit non-zero naming the holder; the `storybook` block names `CATALOG_PORT` as the override.
**Landing page and `main@sha`:** root `storybook/welcome.story.exs` (`:page`). A small `ScrypathOps.Catalog.BuildInfo` (in `catalog/lib`) reads at task start: `git rev-parse --short=12 refs/remotes/origin/main`, `HEAD`, a dirty flag, the realpath of the checkout and the fixtures epoch, stores it in app env or `:persistent_term`, and degrades to `unknown` outside a git tree. The page prints those with stable markers (for example `data-catalog-main-sha`, `data-catalog-head-sha`, `data-catalog-checkout`) so a script can parse them from the dead render. It must say: what the screens are drawn by (the same code as the real app), made-up fictional data, static renders where buttons do nothing, time frozen at the epoch, the tiers, the one persona, the shell is upstream's, and not claim approval.
**`UI-PREVIEW.json`:** add a `storybook` block (existing consumers read named top-level keys only, for example `scripts/ci/ui_preservation.cjs` reads `url`, `container`, `compose_project` `[VERIFIED: ui_preservation.cjs:1271-1276 via shell]`): `url`, `port`, `checkout`, `branch`, `base_main`, `landing`, `start` command, `seed` (epoch, no database), `status`, `runtime_checked_at`. `ui:preflight` today is `verifyPreviewSource()` (a `docker inspect` of the 4002 container) then `remoteMain === runtime.main_ref` `[VERIFIED: ui-review.mjs:789-798]`. Extend it so the two checks are independent and both reported (a missing Docker container must not hide the storybook result): fetch `/storybook/welcome`, parse the markers, compare the printed checkout to `realpath(repoRoot)`, the printed main sha to `git rev-parse refs/remotes/origin/main` and to `ls-remote` (stale local main refuses, as today), and `main_included` by the existing merge-base rule. Add pure `storybookErrors(...)` cases to `ui-review.selftest.mjs` (`ui:review:selftest`, not part of the hosted Node step, so no CI wiring). The repo's CI Node step does not run it; run it locally.
**AGENTS.md "UI work" edits:** present-tense replacement of "Until the catalog's first screen story ships ..."; `npm run ui:preflight` checks the 4002 preview and the `storybook` block; start, status and refresh commands (`fetch`, fast-forward the serving checkout, restart on the same port, preflight); the port-collision rule; "stories are static renders; mounted behavior is 4002 and the journey". Also `examples/scrypath_ecommerce/e2e/UI-REVIEW.md` (the preflight paragraph), `GLOSSARY.md` (Job: "a whole page in one persona's situation" with "Avoid page (for job)" contradicts itself; say one surface state in one persona's JOB situation) and the playbook C1 row tier list (it already carries the correction note, line 86).
**Boundary follow-ups for the new modules:** add `ScrypathOps.Catalog.Endpoint` and `Router` to `@absent_modules` in `ops_dependency_boundary_test.exs` and to `forbidden_modules` in `verify-dependency-boundaries.sh` (the same places the backend module sits), so absence stays proven in prod and mounted builds.

### Pattern 10: The fidelity probe (carried from Phase 195, non-gating)
**Where Playwright lives and how it targets the catalog:** `playwright-core` 1.60.0 and Chromium are installed for the demo; `playwright.config.ts` uses `PLAYWRIGHT_BASE_URL` (default 4002) so a spec could target 4003, but **do not add a `*.spec.ts` under `examples/scrypath_ecommerce/e2e/`**: the advisory `playwright test` lane runs every spec there and would fail in CI where no storybook runs. Precedent for non-spec scripts in that directory: `ui-review.mjs`, `light-pixel-diff.mjs`, `admin-light-baseline-check.mjs`. Put `catalog-fidelity-probe.mjs` there, import `playwright-core`, and run it by hand.
**Cheapest design (proven, 1.1 s of browser time):** the parity-capture test also dumps the real page HTML for the story's scenario; the probe opens (a) the story iframe `.../storybook/iframe/<path>?variation_id=<id>&theme=<t>` and (b) the real HTML served through `page.route` at a fake path on the same origin (so `/assets/css/app.css` and fonts load from the catalog server), with JavaScript aborted and `data-theme` set on `<html>` as `storybook.js` does; then compares `getComputedStyle` of a fixed selector list (`.ops-verdict`, `.ops-verdict p.text-ops-h2`, `[data-sync-status]`, `.ops-sync-status__word`, `.ops-time__value`) over color, background-color, border-top-color/width, radius, padding, font-family/size/weight, line-height, letter-spacing, in light and dark.
**Result on the prototype story (light and dark):** identical on everything except `font-family`: story `serif, system-ui, sans-serif`, real `"Hanken Grotesk", "Hanken Grotesk Fallback", system-ui, sans-serif`. Cause: PSB's stylesheet has `.psb-sandbox { font-family: serif, system-ui, sans-serif }` in its `theme` layer and the iframe `<body class="psb-sandbox ops-storybook">` carries it, while `<html>` correctly has Hanken from `app.css`. Two fixes were verified live with the probe (computed family becomes Hanken): an inline `document.body.style.fontFamily = "var(--font-sans)"` and `@layer app { body.ops-storybook { font-family: var(--font-sans); } }`. Prefer the `storybook.js` route (catalog-only; rebuild the tracked bundle with `MIX_ENV=dev mix esbuild scrypath_ops_storybook`, the `ops_shell_contract_test` hook-parity check keeps working) over a rule in production `app.css`. This affects the five Phase 195 primitives too; fix it in Plan 2 so the maintainer's first look is not on serif text. Record the probe output in the plan summary; it is not a gate.

### Pattern 11: Pause 1 deliverables (PILOT-07)
- **Note path:** `.planning/research/storybook-catalog/REVIEW-<YYYY-MM-DD>-pause-1-phase-197.md` (the directory already holds `FEEDBACK-SESSION-2026-11-21.md`, same table shape). Plan 5 writes the packet and an empty rows table; the maintainer's words are appended verbatim by the orchestrator after the pause.
- **Packet (five lines, F note):** URL and `main@sha`; "UI changed: ..." with the changed renderer modules mapped to stories (`git diff --stat <phase base>..HEAD -- scrypath_ops/lib scrypath_ops/storybook fixtures`); three to five deep links each with the question it answers; the 60-second tour; "reply ok or give rows". Deep links use the real params: `/storybook/<path>?variation_id=<id>&theme=<light|dark>` and the anchor `#<id with _ turned to ->` on the page view.
- **Feedback row template:** `| # | Verbatim quote | Storybook path | Variation id | Theme | Viewport | Kind | Triage | Disposition |`; theme is `light`, `dark`, `system` or `unknown`; viewport is a width in px or the literal `unknown` (it is in no PSB URL); kind is `product`, `data` or `catalog`; triage is fix now, next milestone, later or "looked at it, keep as is"; quotes are never paraphrased.
- **Screens and states worth a look (propose, finalize after stories exist):** `welcome` (what this is and `main@sha`); the Job story in its ordinary state ("Can the on-call engineer tell which record failed and what to do next?"); `surfaces/search_health` Shopadelic degraded in light and dark; `areas/failed_row` retryable vs ineligible vs long error; `areas/recovery_status` `queue_done_backend_pending` vs `verified` ("is it clear that completed is not verified?"); one narrow-width look (the maintainer resizes; viewport stays `unknown` unless stated).
- **Fixtures fold evidence table:** one consumer (`scrypath_ops`; the demo host does not list `scrypath_fixtures`); measured hosted cost warm minus same-hour control -3 s in the job and +1 s in the step, cold main run 469 s (CI-EFFICIENCY finding 29); folding touches the ADR exit rule's list: `.formatter.exs`, `scrypath_ops/mix.exs`, 3 `scrypath_ops` fixtures tests, 5 root tests (`fixtures_project_contract`, `verify_namespace_fence`, `dependency_boundary_contract`, `ops_dependency_boundary`, `package_metadata`), the demo `Dockerfile`, `verify-dependency-boundaries.sh`, the project's own files, plus the compat classifier inventory and `.dockerignore` lines `[VERIFIED: grep this session]`; about 20 non-planning files, one plan of renames. Recommendation to put in the note: keep, because the measured cost does not argue for folding and the exit rule's purpose (avoid an orphan project) is served while the catalog and journey both consume it; revisit when the four `phase173` host specs are ported (the likely second consumer) or at v1.51. The maintainer decides.
- **Findings to carry into the note (not fixed unless asked):** F1, F2, F3, F4, D2, the `dashboard_routes` guard, D3 (new), the copy defects below, and the 195 IN-03 (`storybook.js` ships in the prod and test static trees).
- **Copy defects the fixtures expose (kind `product`):** "3 sync jobs and 1 Meilisearch tasks failed" (no singular in `degraded_evidence`, `posture.ex:405-406`); operator-facing `inspect/1` of atoms in "Check detail: :receipt_unavailable." and `document_observation_copy`; the empty evidence line "Queue job · attempt · Active index" when evidence is `%{}`.

### Anti-Patterns to Avoid
- **Hashing or diffing raw HTML** (attribute order, `data-phx-*` tokens, `ops-time-<n>`): canonicalize the parsed tree.
- **Calling `Posture.summary`, `RecoveryObservation` or anything needing `ScrypathOps.TaskSupervisor` from a story:** compile fails.
- **Putting `Sigra.` in `lib/scrypath_ops_web/components/` or `test/support`:** the namespace fence rejects it; gating stays in the LiveViews.
- **Asserting the `return_to` value in the journey before D1 is fixed**, or asserting D2 as expected behavior.
- **A new `*.spec.ts` for the probe**; **a new Tailwind class** in moved markup (the committed `app.css` lacks it, so CI renders unstyled while a local rebuild looks fine).

### Plan-by-plan implications (CONTEXT order kept; the planner may re-cut within 5 plans)
1. **Journey, `:540`, parity script.** Journey on Shopadelic to "Retry queued" (two stubs; extend `RecordingOban` with `config/0`), the denials with controls, the repaired `:540`, optional "verified" test with its cut rule, the throwaway parity script run twice on current code as its own control. Commit nothing that asserts `return_to` yet.
2. **Search health slice.** `Posture.scan/build`, `search_health.ex` components, stories, the seam tests, retarget the two source-reading tests, **fix the sandbox font** (so every story is truthful from here on), start the contract-test extension with render-all plus canonical/identical, copy and hygiene helpers and their planted inputs.
3. **Failed sync slice.** `FailedSyncView`, `failed_sync.ex` components, stories for rows, summary, filters, receipt, delete confirmation, load error; seam tests; parity run; journey must stay green unmodified.
4. **Recovery areas, D1, D3 decision, the ledger row.** `RecoveryView`, `recovery.ex`, recovery stories, the `return_to` one-liner and its test (red first), coverage and provenance checks and `@no_story`, the `CONTRIBUTING.md` row and `Budget used: 11 of 12.`, hosted-vs-local cost note. Ask the maintainer about D3 before writing this plan.
5. **4003, preflight, docs, probe, Pause 1.** Catalog endpoint, router, Mix task, `BuildInfo`, `welcome` story, port-collision-safe start script, `UI-PREVIEW.json` block, preflight extension and selftest, boundary module lists, AGENTS.md, `UI-REVIEW.md`, glossary and playbook tier wording, the fidelity probe run and recorded result, the Pause 1 note and template, then stop.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTML assertions | regexes over raw HTML | `LazyHTML.query/attribute/text/to_tree` | Project lesson; attribute order is unstable |
| Render a function component to a string | a custom renderer | `Phoenix.LiveViewTest.render_component/2` | Public, exact; only slot strings in stories are out of its reach |
| Copy rules | a new rule engine | `ScrypathOps.Test.CopyRules.evaluate_surface/3`, `check_surface/4` and `copy_rules.json` | Already macro-free for reuse |
| Fixture data | hand-typed task or job maps | `ScrypathFixtures` scenarios through the real `Scrypath.*` | Only reachable states |
| Coverage inventory | a manifest or state grid | `__components__/0` over loaded app modules, `Function.info/1`, `Phoenix.Router.routes/1`, one literal `@no_story` map | Refused list; no counts |
| Story index and tiers | a second gallery | PSB folders plus `*.index.exs` | Refused: parallel gallery |
| HTTP stub for the document check | a fake server | `Req.Test` with `Req.default_options/1` (global, restore in `on_exit`) | Already in `req` |
| Catalog serving | patching `Application` with dev-only branches | a dedicated endpoint under `catalog/lib` | Not compiled in prod; measured stable |
| Parity canonicalizer | a dependency | the 25-line sorted-attribute function (copy it into `test/support/html_canon.ex`, reused by the identical-variation check) | House preference: copy over dependency |

**Key insight:** every hard part of this phase already exists as a real function (`Scrypath.sync_status`, `failed_sync_work`, `RecoveryObservation`, `CopyRules`); the work is making them callable without processes and comparable without noise.

## Runtime State Inventory

Not a rename or migration phase. Extraction moves code between files in the same app; no stored data, live service config, OS registration or secret changes. Recorded explicitly: **stored data** none; **service config** none; **OS state** none (the Mix task writes only `scrypath_ops/tmp/`, which is gitignored `[VERIFIED: scrypath_ops/.gitignore:23]`); **secrets/env vars** new optional `CATALOG_PORT` only; **build artifacts** the tracked `scrypath_ops/priv/static/assets/js/storybook.js` is rebuilt if the font fix lands there.

## Common Pitfalls

### Pitfall 1: Shopadelic has one schema, two records, and no `search_records/2`
**What goes wrong:** the prep note's journey ("second schema", "3 records", a Meilisearch restart) does not exist. `Shopadelic.scenario/2` allowlists only `Product` (`allowlist: [Product]`), job 101 carries `SPD-2041` and `SPD-2042`, queue `:shopadelic_sync`, index prefix `shopadelic` `[VERIFIED: shopadelic.ex:42-48 and scratch run]`. The schema filter fieldset is hidden for one schema (`length(@schema_allowlist) > 1`). Retry additionally needs a `:repo` (else `{:error, :repo_required}` from `Loader.check_loadable/2`) and a queue module, neither of which the scenario sets `[VERIFIED: loader.ex:53-60 read via shell; scratch]`.
**How to avoid:** write the journey to the real data (one schema, job 101, two records); set `:repo` and `:oban` after `FixtureEnv.put/1` (its restore fun reinstates both).

### Pitfall 2: "Verified" has six seams
See Pattern 1. If more than a day of plan time goes to them, cut to "queued" and say so (D4 fallback), and leave "verified" to `operator.spec.ts` (`examples/scrypath_ecommerce/e2e/operator.spec.ts`, the real-browser chain). Never use `Process.sleep`.

### Pitfall 3: D3, a render crash on an unresolved handoff (new, real)
**What goes wrong:** `{status, nil, document_observation}` results (every `:unknown` outcome: `:receipt_unavailable`, `:identity_mismatch`, `:attempt_mismatch`, `:source_unavailable`, ...) become `recovery_evidence = %{}`, which is truthy, and the template reads `@recovery_evidence.replacement_job` at `sync_drift_live.ex:2182` `[VERIFIED: sync_drift_live.ex:2175-2187]`. Mounted reproduction: `/ops/sync-and-index?schema=ScrypathOps.Test.OpsPostA&recovery=expired-or-other-node-handle&recovery_generation=0` crashes the LiveView with `KeyError key :replacement_job not found in %{}`; a Sigra-mode handoff whose second mount lacks the operator context crashes the same way `[VERIFIED: scratch run, both]`. With the render guarded (scratch only), the page shows "Recovery refresh could not be checked ... Check detail: :receipt_unavailable. Schema: ... · Queue job · attempt · Active index" (blank evidence values). In production the handle sits in the URL, so a reconnect to another node or an expiry after 10 minutes (`@ttl_ms :timer.minutes(10)`, `recovery_observation.ex`) re-mounts and crashes again.
**Decision needed (Open Question 1):** CONTEXT says D1 is the one defect fixed here. Fixing D3 is a second behavior change in `scrypath_ops`. Default recommendation: fix it in Plan 4 with its own test, because the recovery view-model makes the crash unrepresentable and the pilot found it; fallback: leave the evidence line in `SyncDriftLive` unextracted and record D3 as a finding.

### Pitfall 4: Receipt identity binds host, org, schema and generation
In Sigra mode the receipt is registered under `org` from `operator_context`; a second mount without it resolves `:unknown` (Pitfall 3). The linear journey therefore runs in basic mode. The 10-minute TTL and per-node GenServer mean a multi-node host loses receipts (D2 family).

### Pitfall 5: D1 and the `:540` test
The existing test builds `host_uri: URI.parse("https://scrypath.example/ops/failed-sync")` and passes because it hand-sets a path real LiveView never provides; it also sets `loads: nil`, so `find_row` returns `nil` and the "Could not find that failed job." branch runs, never the row-present gate `[VERIFIED: failed_sync_live_test.exs:540-566; failed_sync_live.ex:307-312]`. Mounted behavior today: `return_to=%2F` `[VERIFIED: scratch run]`.

### Pitfall 6: Source-reading tests that the extraction trips (update in the same task)
These read LiveView source text and will fail when markup moves: `operator_ia_contract_test.exs:136-148` (`@posture_live =~ "OperatorSelection.path(@mount_path, \"failed-sync\", mod)"`, `@failed_sync_live =~ "phx-click=\"retry\""`, `@failed_sync_live =~ "summary=\"More details\""`), and `design_tokens_contract_test.exs:168-175` (`posture_live =~ "space-y-ops-4"` and `"gap-ops-4"`, refutes `mt-2`, `mt-4`, `mb-4`, `space-y-4`, `gap-4`) `[VERIFIED: Read this session]`. Retarget them to read the component file too, or better to assert on rendered DOM. Also scanned automatically and already clean for moved code: `design_tokens_contract_test` wildcard over `lib/scrypath_ops_web/**/*.{ex,heex}`, `reskin_component_contract_test.exs:417-421` (no `btn-error`, no `:danger`), copy rows with `source_scope` `scrypath_ops/lib/**` or `**`.

### Pitfall 7: Local environment noise
This machine's shared Postgres hits `too_many_connections` (53300) during `mix test`; tests still passed, but it can fail sandbox setup, so run the ops suite with the compose Postgres (`PGPORT=5434`) when a run needs to be trusted. Port 4003 is taken (Pattern 9). `mix verify.ops_ui` needs `HEX_HTTP_TIMEOUT=120` (Phase 196 record). A `git archive` scratch copy cannot run `CopyRulesContractTest` (no `.git`); use `git worktree` for the parity base.

### Pitfall 8: Compile-time evaluation couples story data to fixtures builds
Changing a fixtures builder recompiles the storybook backend; `mix compile` runs every `variations/0` (a free gate, a few seconds). Keep builders cheap and pure; never read the clock.

## Code Examples

### Canonical tree (parity capture and identical-variation check)
```elixir
# Verified in scratch: same code twice = 0 diffs over 22 captures; planted text change found in 2.
defp canon(html) do
  html |> LazyHTML.from_document() |> LazyHTML.to_tree() |> Enum.flat_map(&lines(&1, 0)) |> Enum.join("\n")
end

defp lines({:comment, _}, _d), do: []
defp lines(text, d) when is_binary(text) do
  t = text |> String.replace(~r/\s+/, " ") |> String.trim()
  if t == "", do: [], else: [String.duplicate(" ", d) <> inspect(t)]
end
defp lines({tag, attrs, children}, d) do
  attrs = attrs |> Enum.map(fn {k, v} -> {k, norm_attr(k, v)} end) |> Enum.sort()
  [String.duplicate(" ", d) <> "<#{tag} #{inspect(attrs)}>" | Enum.flat_map(children, &lines(&1, d + 1))]
end

defp norm_attr(k, v) do
  v = Regex.replace(~r/ops-time-\d+/, v, "ops-time-N")
  cond do
    k in ["data-phx-session", "data-phx-static"] -> "TOKEN"
    k == "content" and String.length(v) > 40 -> "TOKEN"
    k in ["id", "data-phx-id", "data-phx-root-id"] and String.starts_with?(v, "phx-") -> "phx-ID"
    k == "class" -> v |> String.split() |> Enum.join(" ")
    true -> v
  end
end
```

### The pure split of `Posture.summary/4` (verified compiling in scratch)
```elixir
def summary(allowlist, opts, %DateTime{} = snapshot_at, previous_summary) do
  cond do
    allowlist == [] -> classify(%Posture{state: :unconfigured, refreshed_at: snapshot_at})
    not Keyword.has_key?(opts, :backend) -> classify(%Posture{state: :missing_backend, refreshed_at: snapshot_at})
    true -> build(scan(allowlist, opts), snapshot_at, previous_summary)   # scan/2 stays the only I/O
  end
end

@spec build([row()], DateTime.t(), t() | nil) :: t()
def build(rows, %DateTime{} = snapshot_at, previous_summary) when is_list(rows) do
  # the old `true ->` branch, verbatim: counts, stuck_failed, classify(%Posture{...})
end
```

### A story over a pure builder (compile-time safe)
```elixir
defmodule ScrypathOps.Catalog.Stories.Areas.HealthVerdict do
  use PhoenixStorybook.Story, :component
  def function, do: &ScrypathOpsWeb.Components.SearchHealth.health_verdict/1
  def container, do: :iframe
  def job, do: "JOB-03"
  def covers, do: [ScrypathOpsWeb.PostureLive]

  def variations do
    now = ScrypathFixtures.preview_epoch()
    for id <- [:shopadelic_failed_journey, :shopadelic_settings_aligned] do
      s = ScrypathFixtures.Scenarios.get!(id, now)
      rows = for mod <- s.allowlist, do: {mod, Scrypath.sync_status(mod, s.scrypath_opts)}
      %Variation{
        id: id,
        description: "Shopadelic, on-call, JOB-03, #{s.label}",
        note: "Adopter: Shopadelic (fictional) · Persona: On-call (ROLE-OPS) · Job: JOB-03 · Proof: render only",
        attributes: %{summary: ScrypathOps.Posture.build(rows, now, nil), now: now, mount_path: "/ops"}
      }
    end
  end
end
```

### The catalog server (about 30 lines, verified in scratch)
```elixir
defmodule ScrypathOps.Catalog.Endpoint do
  @moduledoc false
  use Phoenix.Endpoint, otp_app: :scrypath_ops
  @session_options [store: :cookie, key: "_scrypath_catalog_key", signing_salt: "catalogsession", same_site: "Lax"]
  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])
  plug(Plug.Static, at: "/", from: :scrypath_ops, only: ~w(assets fonts images favicon.svg favicon.ico))
  plug(Plug.RequestId)
  plug(Plug.Parsers, parsers: [:urlencoded], pass: ["*/*"])
  plug(Plug.Session, @session_options)
  plug(ScrypathOps.Catalog.Router)
end

defmodule Mix.Tasks.ScrypathOps.Catalog.Serve do
  use Mix.Task
  @shortdoc "Serves the component catalog on 127.0.0.1 without a database"
  def run(_args) do
    Application.put_env(:scrypath_ops, :standalone, false)   # no Repo, no main endpoint
    Mix.Task.run("app.start")
    {:ok, _} = ScrypathOps.Catalog.Endpoint.start_link([])
    Process.sleep(:infinity)
  end
end
```

### Hygiene accessible-name rule (must include the wrapping label)
```elixir
# A control is named by: non-aria-hidden text, aria-label, aria-labelledby target with text,
# label[for=id], title, or a wrapping <label> with text (the Failed sync cause chips).
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Prep: one dev server on 4003 | Dedicated catalog endpoint, no Repo | this research | Stable without Postgres |
| Prep: raw-HTML parity diff | Sorted-attribute parsed-tree diff | this research | No false positives |
| Prep: render helper over `function/0` | Real iframe route (Phase 195) | 195 | Slots are strings |

**Deprecated/outdated:** the D prep note's journey data (second schema, 3 records) and `rendered_component/2` (does not exist; use `render_component/2`).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The final catalog test (about 100 renders plus parsing) costs a few seconds | Pattern 8 | Low; measured per-render cost is 12 ms, re-measure after merge |
| A2 | `Req.default_options(plug: ...)` plus `set_req_test_to_shared` is acceptable as a test-only global seam | Pattern 1 | Medium; if not, "verified" falls back to queued |
| A3 | A `storybook.js` body-font line is the right place for the font fix (vs `app.css`) | Pattern 10 | Low; both verified to work, the planner may prefer `app.css` |
| A4 | The maintainer prefers keeping the fixtures project (recommendation only) | Pattern 11 | Low; the maintainer decides at Pause 1 |
| A5 | Hosted `ops-ui` increase from this phase stays inside the noise band | Pattern 8 | Low; re-measure per CI-EFFICIENCY finding 29's revisit trigger |
| A6 | One mounted assertion set can stand in for the `Layouts.app` shell in surface stories without the sidebar's per-page nav state | Pattern 6 | Medium; surface stories need `Layouts.app` with `mount_path`, `flash: %{}`, `shell: :ops`, check at plan time |

## Open Questions (RESOLVED)

1. **Fix D3 in this phase? (needs the maintainer, ask-first: a second defect fix beyond D1)**
   - What we know: reproducible crash, `scrypath_ops` only, the recovery view-model removes it by construction.
   - What's unclear: whether the maintainer wants it fixed now or recorded.
   - Recommendation: fix in Plan 4 with its own test and a `test(ops-ui):` title that says it fixes a defect; fallback is to leave the evidence line unextracted and record D3. Needed before Plan 4 is written.
   - **RESOLVED:** the maintainer chose to fix it in this phase (interactive dialog 2026-11-22, orchestrator ruling 1, CONTEXT D3 decision). Implemented in 197-04 Task 1: `RecoveryView` yields a closed `:unavailable` state, a mounted test is red on the old code and green after; the phase PR body names it (197-05 Task 2).
2. **Is "Recovery verified" in the journey required or stretch?** PILOT-01's text ends at the return link, so queued satisfies it. Recommendation: required = queued; verified = a second test in the same file with a stated cut rule and one fixtures edit (`Product.search_records/2`). Planner decides.
   - **RESOLVED:** queued is required (197-01 Task 1); verified is a separate cut-able test with the CONTEXT cut rule (197-01 Task 2 step 5: stop after about a quarter of the plan or two failed attempts, and record it as `operator.spec.ts`'s job). Orchestrator ruling 2.
3. **Hosting story in 197?** Required only by the sentence "adopter theming appears in one Hosting story only". Recommendation: defer (no deliverable needs it) and record in the Pause 1 note, or include a 4-variation story and the allowlisted-variables check if there is room. Planner decides.
   - **RESOLVED:** no Hosting story in this phase (orchestrator ruling 3, CONTEXT decided autonomously); 197-04 Task 2 and 197-05 Task 1 add no adopter theming.
4. **Persona name.** The glossary defines an operator persona as "a named, fictional person" with trigger, skill, device and habits. Recommendation: one paragraph on the landing page for "the paged on-call engineer (ROLE-OPS, JOB-03)", no invented first name unless the maintainer wants one.
   - **RESOLVED:** one paragraph, no invented name (orchestrator ruling 3): the landing page (197-05 Task 1) and the Job story caption (197-04 Task 2).
5. **Font fix location** (RESOLVED as a defect, open as a choice): fix before Pause 1, inside Plan 2 or 5; `storybook.js` or `app.css`.
   - **RESOLVED:** first plan, `storybook.js` body style, product stylesheet untouched (orchestrator ruling 4, CONTEXT). 197-01 Task 3: bundle check with a cause-pinned plant, and the fidelity probe's font mode run with and without the fix.
6. **Hosted measurement of the 197 cost.** Plan 5 should record warm minus same-day control for `ops-ui` after merge (finding 29's revisit trigger).
   - **RESOLVED:** 197-05 Task 2 takes the PR cold, warm and same-day control samples and the main cold sample; 197-05 Task 3 records them as the next CI-EFFICIENCY finding.
7. (RESOLVED) Can the journey reach "verified"? Yes, with the seams in Pattern 1.
8. (RESOLVED) D1 location and cause, D2 confirmation. D2: after "Recovery verified" and the return link, a fresh mount of Failed sync lists job 101 with Retry again and no receipt `[VERIFIED: scratch run]`; record it, do not encode it.
9. (RESOLVED) Is the dev server a stable 4003 mechanism? No; the dedicated endpoint is (Pattern 9).
10. (RESOLVED) Can Playwright target the catalog? Yes, by importing `playwright-core` from the demo's `node_modules` in a non-spec script (Pattern 10).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / OTP | all | yes | 1.19.0 / OTP 28 (`ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5`) | none |
| Postgres (ops suite, `ConnCase`) | journey, contract test | yes, shared, near `max_connections` | on 5432 | compose Postgres `PGPORT=5434` |
| Node / Playwright | probe, preflight selftest | yes | node 26.10.0, playwright-core 1.60.0, Chromium builds present | none needed |
| Docker | `ecommerce-mounted`, 4002 half of preflight | yes (Docker 29.5.2, desktop-linux) | - | record skipped lane with reason |
| Port 4003 | PILOT-06 | **no, held by another project** (fablebook operator, `lsof`) | - | `CATALOG_PORT` override; ask the maintainer before taking 4003 |
| `act` | wiring check only | yes per AGENTS (`/opt/homebrew/bin/act`) | - | optional |

**Missing dependencies with no fallback:** none. **Missing with fallback:** 4003 (free it or override the port).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.0) with `Phoenix.LiveViewTest`, `LazyHTML` 0.1.14; Node `node --test` for `ui-review.selftest.mjs` |
| Config file | `scrypath_ops/test/test_helper.exs`, `scrypath_ops/config/test.exs`; the `test` alias runs `scrypath_fixtures.check_fixtures`, `scrypath_ops.check_nav_contract`, `ecto.create`, `ecto.migrate` first `[VERIFIED: mix.exs:91-97]` |
| Quick run command | `cd scrypath_ops && mix test test/scrypath_ops_web/live/catalog_journey_test.exs test/scrypath_ops_web/live/failed_sync_live_test.exs test/scrypath_ops_web/catalog_contract_test.exs` |
| Full suite command | `cd scrypath_ops && mix precommit` (about 29 s warm; `HEX_HTTP_TIMEOUT=120 mix verify.ops_ui` from the root for the lane) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PILOT-01 | Journey health → failed sync → retry → handoff → return; denials with controls | mounted | `mix test test/scrypath_ops_web/live/catalog_journey_test.exs` | Wave 0 (new) |
| PILOT-01 | `:540` repaired (mounted, row rendered) | mounted | `mix test test/scrypath_ops_web/live/failed_sync_live_test.exs` | exists, edit |
| PILOT-02 | `return_to` equals the page path and query; deleting the assign turns it red | mounted | `mix test test/scrypath_ops_web/live/failed_sync_live_test.exs` | Wave 0 (new test) |
| PILOT-03 | Parity (local) and journey unmodified | script + git | capture twice (control), base vs head; `git diff <plan-1 sha> HEAD --exit-code -- scrypath_ops/test/scrypath_ops_web/live/catalog_journey_test.exs` | throwaway script |
| PILOT-03 | Seam per area | mounted | `mix test test/scrypath_ops_web/live/` | Wave 0 (new) |
| PILOT-04, 05 | render-all, coverage, identical, copy, hygiene, provenance, planted inputs | contract | `mix test test/scrypath_ops_web/catalog_contract_test.exs` | exists, extend |
| PILOT-05 | Ledger row and budget line | root | `mix test test/mix/tasks/workflow_wiring_test.exs`, `mix test test/mix/tasks/verify_namespace_fence_test.exs` | exists |
| PILOT-06 | Serve, landing marker, stable restart, preflight | script | `mix scrypath_ops.catalog.serve` then `curl`, restart, compare canonical; `npm run ui:preflight`; `node --test examples/scrypath_ecommerce/e2e/ui-review.selftest.mjs` | Wave 0 (new) |
| PILOT-06 | Fidelity probe recorded | local script | `node examples/scrypath_ecommerce/e2e/catalog-fidelity-probe.mjs <real-html>` (not gating) | Wave 0 (new) |
| PILOT-07 | Note and template exist, rows empty, links resolve | ExUnit or shell | the contract test's link-resolution case over the note's deep links | Wave 0 |

### Sampling Rate
- **Per task commit:** the focused test file(s) the task changed plus `mix format --check-formatted` (about 4 to 9 s wall each).
- **Per wave merge:** `cd scrypath_ops && mix precommit` (about 29 s) and, from the root, `mix test test/mix/tasks/workflow_wiring_test.exs test/mix/tasks/verify_namespace_fence_test.exs`.
- **Phase gate:** the lane mirrors below on the exact head, then `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `scrypath_ops/test/scrypath_ops_web/live/catalog_journey_test.exs` (PILOT-01), copy `sudo!/1` and `put_live_assigns/2` locally
- [ ] `scrypath_ops/test/support/html_canon.ex` (sorted-attribute canonical tree, reused by contract and seam tests)
- [ ] `FailedSyncStubs.RecordingOban.config/0` and a job repo stub with `get/3` (and, for verified, the client `task/2` wrapper)
- [ ] `fixtures/.../shopadelic/product.ex` `search_records/2` (only if "verified" stays)
- [ ] throwaway `zz_parity_capture_test.exs` kept outside the commit (script form is the planner's)
- [ ] `catalog/lib` endpoint, router, build info, Mix task, `storybook/welcome.story.exs`, `*.index.exs` files
- Framework install: none.

### Local mirror of each required lane (run on the committed head; record what could not run)
| Lane | Command | Measured local cost (Phase 195/196 records) | Hosted (records) | Notes for 197 |
|---|---|---|---|---|
| `core` | `mix verify.core --exclude integration --exclude docs_contract` | 9 min 54 s (196-05) | 471 to 512 s | Touched by `CONTRIBUTING.md` ledger edit, root wiring and fence tests; run `workflow_wiring_test` and `verify_namespace_fence_test` first (about 1 s) |
| `package` | `mix verify.package` | 63 s | 103 s | No root `lib/`; cheap, run it |
| `repository-contracts` | `mix verify.repository_contracts` + the CI Node step | 9 min 25 s + 9 min 49 s (two terminals to match) | 595 to 599 s | `ui-review.mjs` is in the demo; `node scripts/ci/ui_literal_policy.cjs` (1.7 s) needs `origin`; commit first, several tests clone `HEAD` |
| `ops-ui` | `HEX_HTTP_TIMEOUT=120 mix verify.ops_ui` (root boundary test, then ops `mix test`) | 6 min 18 s (196-05); `mix precommit` 29 s | 342 to 436 s same-hour controls; cold 482 to 620 s | The real gate for this phase; boundary test needs the new endpoint modules in `@absent_modules` |
| `ecommerce-mounted` | `mix verify.ecommerce_mounted` | 12 to 15 min, fragile on a shared Docker VM (4 failed local attempts in 196) | 955 to 999 s (bake 292 to 300 s) | Extraction changes rendered markup that `operator.spec.ts` (retry, Check sync status, verified) drives in a real browser: this is the one real-browser net for LiveView wiring; run once after Plans 2 to 4 if the Docker VM is idle, else record the reason and rely on hosted |
| `backend` | compose Postgres + Meilisearch, `mix verify.backend` | 9 s | 59 s | Not affected (no root `lib/`) |
Never commit while a Docker lane runs (checkout fingerprint). PR titles `docs`, `chore`, `test`, `ci` only; stage explicit paths; never stage `.planning/config.json`, `.planning/state.json`, `.impeccable/config.json`.

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no (no new auth surface) | existing `Gating` untouched |
| V3 Session Management | minor | sudo window and `return_to` already exist; D1 assigns a value derived from the request path |
| V4 Access Control | yes | schema allowlist and sudo gate unchanged; journey proves them; storybook binds loopback only (`ip: {127,0,0,1}`) and is absent from prod (Phase 195 boundary tests) |
| V5 Input Validation | yes | `return_to` must be built from parsed `path` and `query`, start with `/`, not `//`, never from host; story attributes are static fixtures |
| V6 Cryptography | no | none added; do not touch receipt handles |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Open redirect through `return_to` | Tampering | local-path-only rule above; test with `//evil.example` and a full URL |
| Catalog reachable beyond loopback | Information disclosure | endpoint config `ip: {127,0,0,1}` only in `dev.exs`; Mix task never changes it; boundary tests keep the modules out of prod/mounted builds |
| Fixture text rendered as HTML | Tampering | HEEx escaping; Phase 196 hostile-text render test stays green |
| F2 (unbounded Meilisearch error text) in stories | Information disclosure | recorded finding; do not paper over it in fixtures |
| Receipt handle in URL | Information disclosure | existing host/org/schema/generation binding; D3 fix must not widen what an unresolved handle shows |

## Sources

### Primary (HIGH confidence)
- Scratch runs this session (mounted journey, D1, D2, D3, parity canonicalization, story compile and render, dev endpoint matrix, catalog endpoint, restart stability, Playwright fidelity probe, hygiene probe, full ops suite timing).
- Opened with the Read tool this session (the `[VERIFIED: path:lines]` tags rest on these): `197-CONTEXT.md`, the prep notes `SYNTHESIS.md`, `D-`, `E-`, `F-`, `H-`, `GO-NO-GO.md`, `196-FINDINGS.md`, `fixtures/scrypath_fixtures/README.md`, `posture.ex`, `posture_live.ex`, `failed_sync_live.ex`, `failed_sync_live_test.exs:1-820`, `gating.ex:168-190`, `sync_drift_live.ex:576-624, 2154-2188`, `catalog/lib/scrypath_ops/catalog/storybook.ex`, `shopadelic.ex:36-60`, `scrypath_ops/mix.exs:56-105`, `CONTRIBUTING.md:250-270`, `ui-review.mjs:786-799`, `ui_literal_policy.cjs:8-16`, `verify.ops_ui.ex:46-59`, `operator_ia_contract_test.exs:134-149`, `design_tokens_contract_test.exs:166-176`, `ops_ui.ex:1332-1343`, `verify.namespace_fence.ex:16-33`, `workflow_wiring_test.exs:2138-2160`, and in `scrypath_ops/deps/phoenix_storybook`: `entries.ex:22-28`, `component_iframe_live.ex:250-256`, `story_live.ex:86-92`.
- Read through the shell only (used for behavior, not for verbatim value tags): `catalog_contract_test.exs`, `catalog_render_all.ex`, `copy_surfaces.ex`, `copy_rules.ex`, `copy_stubs/*.ex`, `fixtures_tracer_test.exs`, `recovery_observation.ex`, `document_observation.ex`, `dev.exs`, `endpoint.ex`, `application.ex`, `loader.ex`, `ui_preservation.cjs`, `phoenix_storybook` `index.ex`, `router.ex`, `variation.ex` and guides.

### Secondary (MEDIUM confidence)
- `CI-EFFICIENCY.md` finding 29 and the local-first table, `196-05-SUMMARY.md` local mirror table (shell reads).

### Tertiary (LOW confidence)
- Hosted cost predictions (Assumption A1, A5).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH, no new dependency, versions read from the lock.
- Architecture: HIGH, every pattern was executed; the view-model and component names are proposals.
- Pitfalls: HIGH for D1, D2, D3, font, attribute order, compile-time variations, dev-endpoint matrix (all reproduced); MEDIUM for hosted effects.

**Research date:** 2026-11-22
**Valid until:** about 2026-12-22 for the mechanics (pinned versions); re-run the fidelity probe and the dev-endpoint check after any `phoenix_storybook` or LiveView bump.
