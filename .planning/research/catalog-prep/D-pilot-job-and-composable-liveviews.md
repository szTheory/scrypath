# Catalog prep D: the pilot job and composable LiveViews (2026-11-21)

Read-only research. Tags: V = read or run this session, J = judgment, U = unverified. Paths are under `/Users/jon/projects/scrypath/` unless noted. Nothing here is a phase plan.

## Findings that change the pilot (all V)

1. **The stale-sudo test proves less than its title, and its redirect target cannot occur in production.** `scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs:540` hand-builds a socket with `loads: nil`, so `find_row` returns nil and the "Could not find that failed job" branch runs (`failed_sync_live.ex:301-305`); the row-present gate at `:319-323` and the delete-confirm gate at `:97-101` are never reached, and no row is rendered. It also builds `host_uri` with a path. Real LiveView prunes `host_uri` to scheme, host and port (`scrypath_ops/deps/phoenix_live_view/lib/phoenix_live_view/utils.ex:171-178`). `Gating.return_to/1` (`integrations/sigra/gating.ex:~160`) uses `assigns.return_to || host_uri.path || "/"`, and only `SearchLive` assigns `:return_to` (`search_live.ex:122`). So a stale-sudo operator leaving Failed sync work or Sync and index returns to `/`, not the page they left. The journey test will expose this as a red assertion (J: fix is one assign in `handle_params`, a behavior change with its own test).
2. **Gating is imperative, not a decision.** `gate_sensitive_action(socket, action, fun)` returns a socket with a flash or `push_navigate`; there is no typed reason (`gating.ex:25-110`). It also reads `DateTime.utc_now()` directly, not `ScrypathOps.Clock`. ScrypathOps has no read-authorization at all: reads are the host router's concern, and only six write actions are gated.
3. **The recovery handoff is in-process state.** Receipts live in `recovery_receipts` assigned in `mount` (`failed_sync_live.ex:41`). The handoff is `navigate` to `/sync-and-index?schema&recovery&recovery_generation` (`:832-846`). Returning remounts Failed sync work with empty receipts, while the original job is "retained", so Retry likely shows again (J, needs the journey test to confirm; it could allow a second retry). This is the accrue "original failure disappears or duplicates between steps" class.
4. **Viewer identity is invisible in the UI.** No layout or LiveView renders the operator or org; the viewer matters only server-side: the receipt handle is bound to host, org, schema and generation (`recovery_observation.ex:36-42`, test `recovery_observation_test.exs:146`), so a wrong-org handle yields `:unknown`.
5. **The only existing chain Failed sync -> retry -> Check sync status -> Recovery verified is Playwright** (`examples/scrypath_ecommerce/e2e/operator.spec.ts:43-204`, Docker lane). ExUnit stops at hand-built sockets (`sync_drift_live_test.exs:579-760`).
6. **Presentation is already mostly pure.** Failed sync's copy and facet logic are `defp`s over `assigns` (`:473-830`); Posture is a struct with closed `state` (`posture.ex:20`), but `summary/4` performs the scan I/O (`:279-297`), so stories cannot feed it plain data until `scan` and `build` are split. `CopySurfaces` already renders 16 anchored surfaces and injects impossible states by merging assigns into `render/1` (`test/support/copy_surfaces.ex:235-249`), which is the thing closed enums remove.
7. **Counts.** `:if=` occurrences: sync_drift 63 (the "62" figure is off by one), search 41, failed_sync 31, posture 19, control_room 14. The two recovery sections of Sync and index (`sync_drift_live.ex:2072-2192`) hold 15 of the 63 and about 10 pure helpers (`:578-667`).
8. **Tier vocabulary conflict.** Playbook C1 says Primitive/Pattern/Area/Screen/Flow; `GLOSSARY.md` says Primitive/Pattern/Area/Surface/Job and bans "section" and "page" for them.

## D1. Which job is the pilot

**Recommendation: JOB-03 end to end, "from an unhealthy verdict to a verified retry", entering at Search health.** Confidence 0.75. Search health is the cheapest first extraction slice, not the pilot.

| Candidate | States exposed | Extraction | What it teaches |
|---|---|---|---|
| Search health alone | 4 posture states times about 6 status words; 16 existing scenarios | low | builder and clock only; no action, no denial, no handoff |
| Failed sync recovery | filters, 5 causes, failed/retrying, 3 ineligible reasons, delete modal, receipt, load error, setup/unavailable; then 8 recovery statuses and 6 document states | moderate; the row is an inline `<article>` | events, denial, receipts, handoff, retained evidence |
| Control room | 14 `:if` | trivial | nothing new; reuses `Posture` |

Reasons: JOB-03's "done" (`OPERATOR-UI-QUALITY.md`) is "exact work correlated, post-recovery check reports observed visibility or an honest unknown", which forces the cross-screen handoff that sigra, accrue and threadline all said to prove. It is also where `CopyStubs.FailedSync` and about 28 tests already give states and fixtures. Rejected: Search health only (teaches least; the siblings' warning is a catalog nobody can use to review one decision); Control room (no new lesson, leave to scale). Early warning: if three extraction slices need more than 5 plans, cut Sync and index and keep Health plus Failed sync. Would change: the stub observer in D4 cannot reach "verified" cheaply (then the pilot ends at the queued state and the Playwright spec keeps "verified").

## D2. Extraction pattern

- **Process stays in the LiveView:** mount, params, events, `start_async`/`handle_async`, `Scrypath.*`, `Gating`, receipt registration. Nothing else moves.
- **Pure view-model modules** in `lib/scrypath_ops/` (next to `Posture`, no Phoenix): `Posture.build/4` split from `scan/2`; `FailedSyncView.build(loads, scope, receipts, now)`; `RecoveryView.build(status, evidence, doc_observation, error, loading?)`. Closed enums, all already latent in the code: page state `:setup | :unavailable | :runtime_missing | :ready`; summary kind `:warning | :neutral | :partial | :success` (`failed_sync_live.ex:609`); row action `:retry | :receipt | :ineligible`; recovery status the 8 values at `sync_drift_live.ex:578-588`. Impossible combinations cannot be built, so cannot be storied.
- **One small deep function:** `retry_decision(row, receipts, allowlist) :: :unavailable | :already_queued | :not_retryable | :confirm_delete | :proceed`, replacing the ordered `cond` at `:295-334`. It is eligibility, not authorization. Confidence 0.6; cut it first if the pilot overruns.
- **Function components** in `lib/scrypath_ops_web/components/` with declared `attr`s taking view-model fields, `mount_path` and `now` explicitly; no `@flash`, `@live_action` or socket reads. Each component is called by both the LiveView and its story.
- **Async:** keep it in the LiveView and hand the component `loading?` plus the retained last result. Retained-plus-loading-plus-error is a real combination (`sync_drift_live_test.exs:703`), so it is a view-model field, not three booleans. Failed sync loads are synchronous, so "loading" there is just `loads: nil`.
- **The 62 (63) `:if`s:** the pilot touches the 15 in the recovery slice and leaves the other 48 until scale (D2 of the UI engine ordered Sync and index last for the same reason).
- **Pixel parity, cheaply and without baselines.** Identical normalized HTML plus unchanged CSS and hooks implies identical pixels. Procedure: a local script (not committed, not a gate) renders the `CopySurfaces` set plus 6 to 8 pilot states to HTML in a `git worktree` of base and of head, normalizes `ops-time-<n>` ids, csrf and phx tokens, collapses whitespace runs to one space (never deletes whitespace between inline elements), and diffs. Any difference is read, not waved through. Standing replacement inside the existing `ops-ui` ExUnit lane, with no new gate row: one **seam test per Area** asserting the mounted page HTML contains the component's own rendered HTML for the same view-model (accrue's "story output equals production output"). Footgun: `ops_time` without `snapshot_at` falls back to `Clock.utc_now()` (`ops_ui.ex:1916-1922`) and without `id` uses `System.unique_integer`; the extracted row passes `snapshot_at={@now}` and ids. Visible text is absolute UTC, only the tooltip is relative.
- Net first: write the mounted journey (D4) and capture the parity corpus on current code, then extract under them.

## D3. Tier ladder (ScrypathOps nouns)

Use the glossary words for folders: `primitives/ patterns/ areas/ surfaces/ jobs/`. "Flow" is not a story tier; it is an ExUnit journey (C7, C23: static stories cannot reach events). Glossary "Job" = one page in one persona's JOB-03 situation. Edit `GLOSSARY.md` and C1 in the same change so the vocabularies agree (J, 0.6; the other option is C1's Screen/Flow).

- **Primitives (existing OpsUi):** `ops_sync_status`, `ops_condition`, `ops_status`, `ops_verdict`, `ops_time`, `ops_code_block`, `ops_disclosure`, `ops_modal`, `ops_handoff`, `ops_empty_state`, `ops_config_empty`. The spike covers five; the pilot adds none.
- **Patterns (inline markup today, small group):** cause and schema filter chips (`ops-filter-chip`), error block with clamp and copy, retry receipt, delete confirmation, denial flash.
- **Areas (new, 3 to 6 per surface):** Health `verdict`, `schema_row` (ok and error variants); Failed sync `summary`, `filters`, `row`, `receipt`, `delete_confirmation`, `load_error`; Sync and index `recovery_status`, `document_freshness`.
- **Surfaces:** Search health, Failed sync work. Sync and index is only its two recovery areas in the pilot.
- **Jobs:** `job_03/on_call_recovers_failed_product_sync`, an ordered set of the surfaces above with one persona caption.

## D4. The one mounted journey

ExUnit LiveViewTest in `scrypath_ops` (DB-light, in the existing `ops-ui` lane), asserting handoffs rather than screenshots. Confidence 0.65 that the stubs reach "verified" within one plan; the observer needs a stub Oban instance exporting `config/0`, a repo exporting `get/3` for `Oban.Job`, and a client with `task/2` (`sync_drift_live.ex:785-1000`). Fallback: end at "Retry running/queued for the same job" and leave "verified" to `operator.spec.ts`, recorded as a split, not hidden.

- **Who:** on-call engineer (`ROLE-OPS`, `JOB-03`), Sigra mode, org X. **Adopter and item:** Shopadelic, queue `search_sync`, a discarded upsert of 3 product records after a Meilisearch restart, on the **second** schema (the existing rule: change the selected schema, do not enter the non-first one directly). The failure text must be one `Translation` actually classifies (`translation.ex:196-232`: "Req.TransportError", "timeout", 5xx); fixtures feed real Oban and Meilisearch shapes through `Scrypath.failed_sync_work/2` with explicit opts, as `Phase173FixtureSource` already does (J, U that opts-only injection covers every field).
- **Steps and assertions:**
  1. Health: degraded verdict, the Product row has a failed word, link `View failed sync work` carries the schema.
  2. Failed sync work scoped to Product only; row shows source `Oban search_sync #id`, "3 records" with ids, cause label, guidance.
  3. **Denial:** `sudo_at` 600 s old, window 300. Retry gives redirect to the sudo path with `return_to` equal to this page and schema (expected RED today, finding 1); zero enqueues; no receipt; remount shows the same row.
  4. Fresh sudo: Retry gives receipt (replacement job, "Original job #id is retained"), one enqueue, flash.
  5. Handoff link carries canonical schema, `recovery` handle and `recovery_generation` equal to the page's `context_generation`.
  6. Sync and index: `selected_schema` is Product, `recovery_origin_generation` equals the carried generation, the evidence line shows the same job id, attempt and index, "Refresh recovery status" is enabled.
  7. Verified (if reachable): the exact backend task and the expected documents were observed in the active index. Queue completion alone shows "Queue job completed; backend evidence pending". Fields changed: new queue job, receipt, status; unchanged: original failed row, schema.
  8. Return via "Review failed sync work": assert what the origin shows. If Retry reappears, record it as a named register finding (C23's `unproven`) instead of encoding the defect as expected behavior.
- **Reuse:** keep the existing tests; rename or repair `:540` by mounting the page, putting stale sudo in the live assigns (the `sudo!/1` helper at `:84`), and asserting redirect, row still in the next render, and zero inserts. Add a table-driven pure test per deny reason through `Gating` directly (existing `gating_test.exs`).

## D5. Denial and never-index

- ScrypathOps cannot honestly story "failed work this operator may not read" or a never-index list: no read denial exists, and `search_indexable?/1` is a deferred adopter feature. A story of either is a contrived-data defect (playbook C31 rule). Clinicly contributes PII-shaped record ids and the allowlist denial instead.
- Real denials, each storiable with safe fields only: (a) `scope_error: :unavailable` ("That schema is unavailable", echoes no schema name); (b) denial flashes in Gating (impersonation, unverifiable identity, integration unavailable), as a Pattern story over the flash component; (c) recovery `:unknown` for a wrong-org or expired handle. The stale-sudo redirect is not a render, so it is journey-only.
- **No `decide` for authorization in the pilot** (J, 0.65). Revisit when a second consumer of denial copy appears or an action is added. If a typed reason is wanted later: `Gating.decide(context, action, now) :: :allow | {:deny, reason}` with `now` and the window passed in (this also fixes the wall-clock read); flagged because Gating exists in two compile-time variants.

## D6. Personas and copy

One operator persona in the pilot, the paged on-call engineer (trigger, device, skill per the glossary), mapped to `ROLE-OPS`/`JOB-03`. Story description pattern from C22 (140 characters, linted): "Shopadelic, on-call, JOB-03, retry queued". Copy lint already exists: `test/support/copy_rules.json` (269 lines) plus `copy_rules.ex` helpers that are macro-free precisely so other callers can reuse them, and 16 anchored surfaces. Run those helpers over every story's rendered HTML in the render-all test (cheap, no new gate); add 4 to 6 pilot surfaces only for states the mounted pages can reach. Candidate copy defects to review (J): raw `inspect` shown to operators in `"Reconcile failed: #{inspect(reason)}"`, `Check detail: #{inspect(error)}` and `document_observation_copy` (atoms like `:identity_mismatch`).

## Stories (names only)

Patterns: `filters/mixed_causes`, `retry_receipt/queued`, `delete_confirmation/three_documents`, `denial_flash/impersonating`, `denial_flash/unverified`, `denial_flash/integration_unavailable`, `schema_unavailable/not_allowlisted`.
Areas: `health_verdict/{ok,degraded,partial,setup_missing,backend_missing}`; `health_schema_row/{failed,retrying,pending,clear,unchecked_retained,queue_unused}`; `failed_row/{retryable_transport,retrying_next_try,retry_queued,ineligible_meilisearch_task,ineligible_no_record_ids,delete_retry,long_error_clamped}`; `failed_summary/{failed_and_retrying,filtered_out,clear_after_partial_load}`; `failed_load_error/one_schema`; `recovery_status/{queued,running,queue_done_backend_pending,verified,failed,canceled,unchecked_after_verified}`; `document_freshness/{verified_upsert,verified_delete,running,unchecked}`.
Surfaces: `search_health/shopadelic_degraded`, `failed_sync/shopadelic_two_schemas`. Job: `job_03/on_call_recovers_failed_product_sync`.
That is about 40 variations; cap it, and drop any that render identically.

**Refuses:** a state grid or manifest, hash-bound or screenshot baselines, a Sync and index surface story (63 `:if`s, scale phase), Control room, Search, Help, `Gating` refactor, never-index or read-denial stories, a second journey, a persona set beyond one, a parallel gallery.

## Adversarial pass

- "Search health first is cheaper": true, so it is plan 2 after the net, not the pilot. Cheapest test: if the journey cannot be written green on current code in one plan, the pilot shrinks to Health plus Failed sync.
- "View-model layer is ceremony": test it by counting moved `defp`s and enum values; if a builder only renames assigns, drop it and keep the component.
- "HTML parity misses pixels": it cannot catch CSS changes, which extraction does not make; keep it to extraction PRs only.
- "ExUnit journey diverges from a real browser": the Playwright `operator.spec.ts` stays as the real-browser proof; do not duplicate it.
- Finding 1 rests on LiveView 1.1.34 source (V); the journey test confirms it in one run.

## Phase implications (J)

One pilot phase, at most 5 plans, ordered: (1) journey on current code, repaired `:540`, parity capture script; (2) builders and Health areas with stories; (3) Failed sync areas with stories, then the maintainer gets the stable seeded link (the cut line); (4) recovery areas; (5) `return_to` fix and findings note. Depends on Phase 195 fixtures emitting real shapes with a fixed `now`, and on the spike registering the same JS hooks as `app.js` (`OpsTimestampCopy` and the rest).
