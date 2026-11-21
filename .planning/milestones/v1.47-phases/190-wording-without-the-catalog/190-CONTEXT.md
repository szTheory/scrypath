# Phase 190: Wording that does not need the catalog - Context

**Gathered:** 2026-11-20
**Status:** Ready for planning
**Mode:** Pre-seeded for `gsd-autonomous --only 190`. The decision fan-out already happened upstream: prep notes A to D ([v1.47-prep](../../research/v1.47-prep/)), gap-pass notes E to H ([v1.47-gap-pass](../../research/v1.47-gap-pass/)) and the glossary rulings in [V1.46-PREP.md](../../research/brand-and-catalog/V1.46-PREP.md) D10, each through the role lenses with an adversarial pass. This file transcribes those decisions and records the few wording calls that upstream left to "discuss". Those calls were made by the pre-seeding pass using the stricter literal reading of the glossary rules and the principle of least surprise. They are tagged `[pre-seed call]` and listed again in [190-DISCUSSION-LOG.md](190-DISCUSSION-LOG.md) so the maintainer can veto any of them. Nothing here needs an answer before the run starts.

<domain>
## Phase Boundary

Operators read consistent ScrypathOps screen copy that follows the recorded glossary rules and the sentence-case label "Control room". Each rule is guarded by one data table (`scrypath_ops/test/support/copy_rules.json`) that one ExUnit test in the required `ops-ui` job scans and renders, in a shape the v1.48 copy lint can ingest unchanged. The destructive promotion dialog's Cancel button is proved focused on open.

Copy, tests and docs only. No visual re-skin, no new component, no layout change, no preview refresh, no `npm run ui:review`. At most 2 plans, neither evidence-only. Requirements: COPY-01, COPY-02, COPY-03, COPY-04, and GATE-02 as a standing rule.

Depends on Phase 189 being on `main` (no stacked PRs, no code dependency). 190 and 189 touch disjoint files except `CONTRIBUTING.md`, `.github/workflows/ci.yml` and `test/mix/tasks/workflow_wiring_test.exs`; if both are open, the second to land rebases on fresh `origin/main` and recomputes the ledger row count and the budget line.

</domain>

<decisions>
## Implementation Decisions

Decisions are locked. Items tagged `[informational]` need no plan task (they are constraints, delivery rules or recorded reasoning). Every untagged decision must be covered by a plan task or a stated check. Line numbers were re-verified on 2026-11-20 against `origin/main` e6fc151b (the source tree is identical to local `main`; only `.planning/` differs) and drift, so re-derive them by searching the old string.

### Glossary status wording (COPY-01), written first

- **D-01:** Plan 190-01's first commit appends a `## Status wording` section to the end of `GLOSSARY.md` (after "Storage folder"), in the file's existing entry format (`**Term**:` then definition then `_Avoid_:`). Final text, `[pre-seed call]` for the wording of the entries (the rules themselves are from V1.46-PREP D10 and REQUIREMENTS COPY-01):

  ```markdown
  ## Status wording

  The words ScrypathOps screens use to report sync state. Screen copy follows these entries, and `scrypath_ops/test/support/copy_rules.json` enforces them.

  **Searchable**:
  A label for one record's or update's state, used only together with the time it was observed: that record could be found in the active index at that time. It is never a setting value. The settings row for fields is "Searchable fields", and its values are "Used for search" and "Not used for search".
  _Avoid_: Searchable (as a setting value, or without an observation time), Not searchable, Not searched yet

  **Pending**:
  Sync work that has not finished, counted for a row or a schema: "2 pending", or the Pending status word beside such a count. It is an aggregate, not the state of one update.
  _Avoid_: queued (for a count over a row or a schema)

  **Queued**:
  The step one update is in once the host application's queue holds it, and the outcome shown after a retry hands work to that queue. It is not a count over a row or a schema; that is Pending.
  _Avoid_: Pending (for one update's step), accepted (for the host queue)

  **Retry queued**:
  What the operator sees after retrying failed sync work: the host application's queue now holds the retry job. It says nothing about Meilisearch and does not confirm recovery.
  _Avoid_: Retry accepted, Retry sent, resubmitted

  **Accepted**:
  Reserved for a Meilisearch task that Meilisearch has taken (see Meilisearch task). "Index swap accepted" is correct. Work in the host application's queue is queued, never accepted.
  _Avoid_: accepted (for sync work, a queue job or a retry)

  **Last succeeded**:
  The time of the most recent success, written "Last succeeded" or "<source> last succeeded" beside a time.
  _Avoid_: Last success, Last successful

  **Clear**:
  The status word for a source that was observed with nothing pending, retrying or failed. It needs an observation, and it is not shown beside an earlier observation that a failed refresh left on screen. It does not mean documents are searchable.
  _Avoid_: Healthy, All good, Searchable (as a synonym for Clear)
  ```

  `Clear` is an addition to the six entries COPY-01 names, needed so the Clear rule has a glossary entry to cite from the table. The block must not spell the old title-case form of the Control room label (the COPY-02 scan covers `GLOSSARY.md`); the existing "Control room" entry stays as it is.
- **D-02:** Every row of `copy_rules.json` cites one of these entries (or "Control room") in its `glossary` field. The glossary edit lands before any string change, and the table test fails a row whose `glossary` value is not a `**Term**` in `GLOSSARY.md`.

### String-by-string mapping (COPY-01)

All paths are under `scrypath_ops/` unless noted; "table row" names the `copy_rules.json` row (D-17) that guards the string. Where the old string is also pinned by an existing test, that test is updated in place to the new string (it stays the one verbatim layer for its surface; the table holds the rule-level phrase, not a second copy of every sentence).

- **D-03 Searchable settings row** `[pre-seed call]`. `lib/scrypath_ops_web/live/sync_drift_live.ex:1734`, the `@set_dimensions` tuple `{setting, declared, live_missing, effect}`:
  - old `{"Searchable fields", "Searchable", "Not searchable", "Not searched yet."}`
  - new `{"Searchable fields", "Used for search", "Not used for search", "Not used for search yet."}`
  - Reason for the effect sentence: it keeps the existing structure (the effect repeated the live cell with "yet"), reuses the glossary phrase verbatim so the table can require it exactly, and avoids a new consequence sentence that would be a fresh copy choice. The same tuple feeds the declared cell, the live cell of an "only in the live index" row (line 1792-1803), and the setting label (line 1868), so one edit covers all three.
  - Tests to update: `test/scrypath_ops_web/live/sync_drift_live_test.exs:523` ("Not searchable" becomes "Not used for search") and `:524` ("Not searched yet." becomes "Not used for search yet."); add an assertion that the declared cell (`td[data-label='Declared in schema']`) reads "Used for search" in the same fixture. Table rows `searchable-observation-only` and `searchable-settings-row`.
- **D-04 Sibling rows stay** `[pre-seed call]`. `"Filterable"`, `"Not enabled for filtering"`, `"Can't filter by it yet."`, `"Sortable"`, `"Not enabled for sorting"` and `"Can't sort by it yet."` (same tuple list, lines 1736-1739) do not change. Reasons: COPY-01's rule names only Searchable; advisory specs pin them (`e2e/ui_iteration3.spec.ts:146` with `exact: true`, and `e2e/helpers/ui-preservation-states.ts:466` asserts `declared === "Filterable"` and the live "Not enabled for filtering" text); `help_live.ex:138` explains the "Not enabled for filtering" phrase to operators. Leaving them is the least surprising choice, so the table does not flag them (no forbidden entry names them). Aligning them to "Used for filtering/sorting" is deferred (see Deferred).
- **D-05 Last succeeded** `[pre-seed call]`. Label and sentence forms: the bare label "Last succeeded"; the time sentence "Last succeeded: <time>."; the source forms "Meilisearch last succeeded" and "Queue last succeeded"; the retained-check sentence "Showing the check that last succeeded below." Reason: "Last succeeded" is the glossary phrase, `posture_live.ex:707` and `lib/scrypath/cli/operator_task.ex:139,144` already use it with a timestamp, and the label-plus-time pattern keeps today's structure (label above the verdict, sentence below it).

  | ID | Where | Old | New | Tests updated |
  |----|-------|-----|-----|---------------|
  | C-1 | `lib/scrypath_ops_web/live/control_room_live.ex:146` (verdict label) | `Last successful observation` | `Last succeeded` | `control_room_live_test.exs:218` |
  | C-2 | `control_room_live.ex:177` | `Last successful check: <time>.` | `Last succeeded: <time>.` | `control_room_live_test.exs:223`, `:326` |
  | C-3 | `lib/scrypath_ops_web/live/sync_drift_live.ex:1994` | `Showing the last successful check below.` | `Showing the check that last succeeded below.` | none pin it today; table row `last-succeeded` (rendered where a fixture exists, static otherwise) |
  | C-4 | `lib/scrypath_ops_web/live/posture_live.ex:443,500` | `<dt>Last success</dt>` | `<dt>Last succeeded</dt>` | `posture_live_test.exs:167` |
  | C-5 | `posture_live.ex:610-611` | `Meilisearch last success`, `Queue last success` | `Meilisearch last succeeded`, `Queue last succeeded` | `posture_live_test.exs:739` |
  | C-6 | `lib/scrypath_ops/posture.ex:342` (comment) | "Keep the last successful source-local" | reword so the comment no longer contains the phrase (the static scan reads comments) | none |

  Not changed: `control_room_live.ex:109` "The last complete observation is retained below; ..." (it says "complete", not "success"), `posture_live.ex:646` "No successful observation recorded." (not a "Last success" form; also pinned by advisory `e2e/phase173_time.spec.ts:76`), identifiers with underscores (`last_successful_posture`, `last_success_refs`, `source_last_success_label`; the forbidden pattern needs a space), and the CLI forms (`lib/scrypath/cli/operator_task.ex:139,144`, already conformant and outside `scrypath_ops`).
- **D-06 Clear beside a retained observation** (COPY-01's last clause; the v1.46 review item IN-02). `control_room_live.ex:140-151`: pass `status={if @refresh_issue, do: nil, else: Posture.worst_status(@posture.rows)}` to `ops_verdict`, so a retained or partial observation shows its headline and label without a status word (fix text from `187-REVIEW.md` IN-02). A LiveView test asserts there is no `[data-sync-status]` inside `[data-testid='control-room-verdict']` when `@refresh_issue` is set (retained and no-prior fixtures), and that the healthy no-issue fixture still shows its status word. Table row `clear-needs-observation` (forbidden whole-word `Clear` on the retained surface).
- **D-07 Queue outcomes are queued, not accepted** `[pre-seed call]`. "accepted" stays only for a Meilisearch task. Each host-queue use becomes "queued", reusing the receipt title "Retry queued" that already exists:

  | ID | Where | Old | New | Tests updated |
  |----|-------|-----|-----|---------------|
  | Q-1 | `lib/scrypath_ops_web/live/failed_sync_live.ex:319` (flash) | `A retry for job N is already accepted.` | `A retry for job N is already queued.` | `failed_sync_live_test.exs:704` |
  | Q-2 | `failed_sync_live.ex:351` (flash) | `Retry accepted · queue job N` | `Retry queued · queue job N` | none pin it; table row `retry-queued-not-accepted` (rendered after a retry) |
  | Q-3 | `sync_drift_live.ex:579` (`recovery_status_label(:accepted)`) | `Retry accepted` | `Retry queued` | none pin it; same table row (rendered where the recovery fixture exists) |
  | Q-4 | `sync_drift_live.ex:599-601` | `The queue accepted this retry; refresh to observe this same job. Refresh never resubmits work.` | `The queue has this retry; refresh to observe this same job. Refresh never resubmits work.` | none |
  | Q-5 | `sync_drift_live.ex:2153` | `Refresh recovery status observes the accepted operation and never resubmits it.` | `Refresh recovery status observes the queued retry and never resubmits it.` | none |
  | Q-6 | `lib/scrypath_ops_web/live/help_live.ex:123` | `Acceptance alone does not confirm recovery.` | `A queued retry alone does not confirm recovery.` | none (help text) |

  Kept because they name a Meilisearch task and already conform: "Index swap accepted" (`sync_drift_live.ex:1602`, pinned by `sync_drift_live_test.exs:1067`), "The backend accepted this swap. Waiting for its terminal result." (`:2364`), "Index swap was not accepted: ..." (`:1248`), `help_live.ex:79` ("A request being accepted ...") and `:97` ("... returns when Meilisearch accepts them"). Internal atoms and docs (`:accepted`, `accepted_receipt`, `recovery_observation.ex`) are not copy and stay.
- **D-08 Pending versus Queued for aggregates** `[pre-seed call]`. Stricter literal reading: any count or sentence over a schema's work is an aggregate, so it says Pending.

  | ID | Where | Old | New | Tests updated |
  |----|-------|-----|-----|---------------|
  | P-1 | `sync_drift_live.ex:1653` | `N jobs queued` (suffix `" queued"`) | `N jobs pending` (suffix `" pending"`) | `sync_drift_live_test.exs:322` ("1 job queued, 1 scheduled retry" becomes "1 job pending, 1 scheduled retry") |
  | P-2 | `sync_drift_live.ex:1703` | `Caught up. Nothing queued, retrying or failed.` | `Caught up. Nothing pending, retrying or failed.` | `sync_drift_live_test.exs:304` |
  | P-3 | `sync_drift_live.ex:1560` (`promotion_reason(:queue_work_pending)`) | `wait for queued work to finish` | `wait for pending sync work to finish` | new notice-body pin (D-24), flash pattern in `:582-600` still matches |

  Reasons: `posture_live.ex:477` already says "No pending, retrying or failed jobs." for the same aggregate, so this aligns Sync and index to Search health; "sync work" is the glossary term for host-queue work. Known cost, recorded for the veto: the P-1 line renders the Pending status word before "N jobs pending" (`signal_status(:pending_queue_work)` is already `:pending`), so the line reads "Pending, 1 job pending, ...". Accepting that repetition is the literal result of the rule; no new word is introduced to avoid it.
  Not changed: "N Meilisearch tasks waiting" and "No Meilisearch tasks waiting or failed." (`sync_drift_live.ex:1646,1704`, pinned by `sync_drift_live_test.exs:274`; "waiting" is not a rule term, so it is outside the literal rule), the help paragraphs that already say "pending work" and "A queued retry is a new operation" (`help_live.ex:111,164`), and the Pending status word itself (`ops_ui.ex:1967`, `posture_live.ex:425,477,686,694,701`, pinned by advisory `e2e/ui_followup.spec.ts:71-73`).
- **D-09 Protected strings, must NOT change** `[informational]` as a list, enforced by the existing required-lane spec staying green. These are asserted by `examples/scrypath_ecommerce/e2e/operator.spec.ts` and `harness.spec.ts`, which `ecommerce-mounted` runs (`docker-playwright.sh:255`): "View search health" (link), "Check sync and settings", "Try a search", heading names "Search health", "Failed sync work", "Sync and index", "Search" and "Variant", "Failed sync work refreshed." (exact), the receipt text "Original job #N is retained", the regexes `Oban job #(\d+)` and `attempt (\d+)`, the row source regex `Oban \S+ #<id>`, the "Retry" and "Refresh failed sync work" buttons, "Check sync status" (link), "Refresh recovery status", "Recovery verified", `Queue job N`, `Meilisearch task N`, "That schema is unavailable.", "Refresh sync and index settings", the regex `/Meilisearch settings (match|differ)/`, "Promote target index", the dialog name "Confirm index promotion", "Schema: ...", "Live index:", "Target index:", "Effect: replace live index contents and settings with the prepared target.", the button names "Close Confirm index promotion dialog", "Cancel index swap" and "Replace live index with target", "Index swap completed", `Task N`, "Refresh checks", and from `harness.spec.ts` "Tenant-scoped catalog search", the nav name "Demo operator links" and the dialog "Manage saved searches". All `data-testid` values and `control-room-*` ids stay. The only protected-lane edit in this phase is the rename of the heading text at `operator.spec.ts:64` (D-11) and the added Cancel-focus line (D-23). The plan's last check before the final push is `cd examples/scrypath_ecommerce && npx --no-install playwright test --list` (parses every spec, about 2 s) plus a grep that none of the strings above changed in lib.

### "Control room" casing (COPY-02)

- **D-10:** The label is "Control room" (capital C only; the GLOSSARY entry and the already-conformant files use it). Keep `control-room-*` test ids, `:control_room` atoms, `ControlRoomLive`, file names and CSS classes. Rendered code to change (6 literals on 5 lines of live code): `lib/scrypath_ops_web/components/layouts.ex:320` (both `label:` and `title:`; `nav_item_active?/2` at `:313` compares `item.title == page_title`, so this line and `control_room_live.ex:17` must change together or the nav item silently loses `aria-current="page"`), `lib/scrypath_ops_web/components/ops_ui.ex:1717` (command palette label), `lib/scrypath_ops_web/live/control_room_live.ex:17` (`page_title`) and `:86` (h1 `title`), `lib/scrypath_ops_web/live/sync_drift_live.ex:2438` ("Return to Control room"). Keep the two literals of the label (layouts and palette) rather than refactoring to one source; D-12 and D-19 test both.
- **D-11:** Full change list (54 occurrences in 28 files, re-counted 2026-11-20; case-sensitive `Control Room` to `Control room`). Comments and docs are in scope because the scan reads every tracked file.

  | Group | Files and lines |
  |-------|-----------------|
  | Rendered code (4 files, 6 literals) | as D-10 |
  | Comments and docstrings in lib | `ops_ui.ex:560,629,691`; `lib/scrypath_ops/posture.ex:182`; `assets/css/app.css:27` (a file the lifecycle verifier fixture copies, see D-27 task 7) |
  | Ops tests (4 files) | `test/scrypath_ops_web/live/control_room_live_test.exs:64`; `live/sync_drift_live_test.exs:1457`; `router_test.exs:148`; `reskin_component_contract_test.exs:426` (comment) |
  | Demo host | `examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/page_controller_test.exs:55`; `lib/mix/tasks/scrypath.demo.seed.ex:195` ("OPSUI at /admin/search/ (Control Room)") |
  | E2E specs and helpers (12 files, 28 occurrences) | `e2e/admin_path_motion.spec.ts` (3: `:55` name and heading, `:315`, `:345`); `admin_screenshot_matrix.spec.ts:132`; `admin_screenshots.spec.ts:41`; `admin_shell_chrome.spec.ts` (3: `:61`, `:510`, `:710`); `admin_shell_wash.spec.ts:55`; `helpers/theme-grid.ts:47`; `helpers/ui-preservation-states.ts` (9: `:194` regex, `:249`, `:289`, `:351`, `:353`, `:504`, `:505`, `:512`, `:789`); `operator.spec.ts:64`; `ops_reskin_contract.spec.ts` (`:57` x2, `:1572`); `phase1_screens.spec.ts` (`:1` comment, `:23`); `ui_routes_preservation.spec.ts:93`; `ui-review.selftest.mjs:436` |
  | CI fixture | `scripts/ci/ui_preservation.test.cjs:226` (`links: ["Control Room", "Search"]`) |
  | Docs | root `DESIGN.md:23,41`; `scrypath_ops/assets/css/DESIGN-TOKENS.md:225,243,587`; `scrypath_ops/docs/operator-ia.md:14,18` |
  | Already sentence case, leave | `GLOSSARY.md:31`, `examples/scrypath_ecommerce/Makefile:99`, `README.md:179`, `docker-entrypoint.sh:35`, `docs/local-demo-docker-dx.md:159`, `examples/scrypath_ecommerce/docs/local-demo-docker-dx.md:101`, `scripts/reskin-capture.mjs:4`, `e2e/phase1_screens.spec.ts:21` (test title), `reskin_static_contract_test.exs:107` |
  | Exempt from the scan | `.planning/` (history), `brand/` (hash-pinned; has zero hits), `scrypath_ops/test/support/copy_rules.json` (it holds the forbidden string) |

  Exact-match Playwright sites that fail silently on the advisory lane unless updated (all in the list above): `admin_path_motion.spec.ts:55` heading used with `exact: true` at `:201`; `ops_reskin_contract.spec.ts:57` heading used with `exact: true` in `gotoPath` at `:913` (called for `SCREENS[0]` at `:1019`, `:1195`, `:1363`, `:1571`); `ui_routes_preservation.spec.ts:93` (`exact: true`); `helpers/ui-preservation-states.ts:194` (`E2: /^Control Room$/`, case-sensitive). Hidden coupling: in `admin_shell_chrome.spec.ts` the surface `name` at `:61` is the key of the map at `:510` (`{ "Control Room": ... }[surface.name]!`), so both change together or the lookup is `undefined`. Assertion names in `ui-preservation-states.ts` are strings only; no other file or manifest quotes them (checked 2026-11-20), so they change with the label.
- **D-12 aria-current and title test:** a LiveView test in `test/scrypath_ops_web/ops_shell_contract_test.exs` (new `test "/ops"` beside the four existing route tests, which cover Search health, Failed sync work, Sync and index and Search but not the Control room) asserts: `assert_ops_shell!(html, "Control room")` (this already checks that exactly two `.ops-nav-item-active` links carry `aria-current="page"`, sidebar and mobile drawer); the link `a[href='/ops']` carries `aria-current="page"` and the text "Control room"; the document `<title>` starts with "Control room" (the root layout renders `page_title` through `live_title`); and the command palette's first item (`#ops-cmdk-item-0 .ops-cmdk__item-label`) reads "Control room". A second assertion on another route (Search health) confirms the Control room link does not carry `aria-current` there, so the test would fail if the match were loosened.

### Table file and its test (COPY-03)

- **D-13 `copy_rules.json` shape** (`scrypath_ops/test/support/copy_rules.json`, language-neutral so the v1.48 lint can read it unchanged, no code in it). Top level: `{"version": 1, "exempt_paths": [...], "not_covered": [...], "rules": [...]}`. `exempt_paths` are prefixes the static scan never reads (`.planning/`, `brand/`, `scrypath_ops/test/support/copy_rules.json`). `not_covered` lists, in plain sentences, the forms the table does not guard (playbook W4): JavaScript strings in `scrypath_ops/assets/js`, HTML attributes whose text never appears in rendered text (`aria-label`, `title`, `placeholder`), Playwright locators and assertion names (only the Control room scan reads them), states with no named fixture surface, and non-English text. Each rule row has exactly these fields, all required, none inferred:

  ```json
  {
    "id": "last-succeeded",
    "rule": "Say Last succeeded, never Last success or Last successful.",
    "glossary": "Last succeeded",
    "forbidden": [{"text": "last success(ful)?\\b", "match": "regex", "case": "insensitive"}],
    "required": [{"text": "last succeeded", "match": "literal", "case": "insensitive"}],
    "allowed_in": [],
    "source_scope": ["scrypath_ops/lib/**"],
    "surfaces": ["control_room.refresh_retained", "posture.default"]
  }
  ```

  `forbidden` and `required` entries are `{text, match: "literal"|"regex", case: "sensitive"|"insensitive"}`. `allowed_in` is a list of exact phrases; a forbidden hit is excused only when it lies inside one of them. `source_scope` is a list of globs read with `git ls-files` (empty list means a rendered-only row). `surfaces` is a non-empty list of surface ids. The key is plural: REQUIREMENTS COPY-03 lists the field as `surface` but its own failure condition says "empty `surfaces`", which only a list can be (see Open contradictions).
- **D-14 Rows** `[pre-seed call]` for the exact split. One rule may span several rows when a required phrase is not present on every surface; a row is `<rule-id>` or `<rule-id>--<variant>`. A row needs a non-empty `forbidden` or `required`. Minimum set (each cites its glossary entry):

  | Row id | forbidden (static scan of `source_scope`, then rendered on each surface) | required (rendered, each surface) | source_scope | surfaces |
  |--------|----------------------------------------------------------------------------|-----------------------------------|--------------|----------|
  | `control-room-casing` | literal `Control Room`, case-sensitive | literal `Control room` | `**` (every tracked file minus `exempt_paths`) | `control_room.default`, `sync_drift.default` |
  | `searchable-observation-only` | regex `Searchable(?! fields)` case-sensitive; literals `Not searchable`, `Not searched yet` | none | `scrypath_ops/lib/**` | `sync_drift.settings_missing_field` |
  | `searchable-settings-row` | none | literals `Used for search`, `Not used for search`, `Not used for search yet.` | none | `sync_drift.settings_missing_field` |
  | `pending-aggregate` | regex `\bjobs? queued\b`, literals `Nothing queued`, `queued work` (insensitive) | none | `scrypath_ops/lib/**` | `sync_drift.queue_pending`, `sync_drift.caught_up`, `sync_drift.promotion_blocked_queue` |
  | `pending-count` | none | regex `\d+ jobs? pending` | none | `sync_drift.queue_pending` |
  | `pending-caught-up` | none | literal `Nothing pending, retrying or failed` | none | `sync_drift.caught_up` |
  | `pending-promotion-reason` | none | literal `Wait for pending sync work to finish.` | none | `sync_drift.promotion_blocked_queue` |
  | `retry-queued-not-accepted` | literals `Retry accepted`, `already accepted`, `The queue accepted`, `accepted operation`, `Acceptance alone` | literal `Retry queued` on the retry surfaces | `scrypath_ops/lib/**` | `failed_sync.after_retry`, `sync_drift.recovery_queued` |
  | `retry-surfaces-no-accepted` | regex `\baccept(ed\|ance)\b` insensitive (rendered only; the retry surfaces carry no Meilisearch task text) | none | none | `failed_sync.after_retry`, `sync_drift.recovery_queued` |
  | `accepted-is-meilisearch-only` | none | literal `Index swap accepted` | none | `sync_drift.promotion_accepted` (guards that the kept Meilisearch uses survive) |
  | `last-succeeded` | regex `last success(ful)?\b` insensitive (the literal space keeps underscored identifiers out); `allowed_in` empty | regex `last succeeded` insensitive | `scrypath_ops/lib/**` | `control_room.refresh_retained`, `posture.default`, `sync_drift.reconcile_error_retained` |
  | `last-succeeded--absence` | the same forbidden | none | none | `control_room.refresh_no_prior`, `posture.failed_row_retained` (the two fixtures whose old vacuous `refute` lines this replaces) |
  | `clear-needs-observation` | regex `\bClear\b` case-sensitive | none | none | `control_room.refresh_retained`, `control_room.refresh_no_prior` |

  Rows whose rendered surface cannot be built from an existing fixture within the plan (`sync_drift.reconcile_error_retained`, `sync_drift.recovery_queued`, `sync_drift.promotion_accepted`, `sync_drift.promotion_blocked_queue`) are still built; the existing render-with-assigns pattern (`sync_drift_socket/1` merged with overrides, then `SyncDriftLive.render/1`, used at `sync_drift_live_test.exs:1056-1067`) reaches them. If one truly cannot be reached, the row keeps its static scan, loses that surface, and the surface is listed in `not_covered`; every row still keeps at least one surface.
- **D-15 The test** `[pre-seed call]` for file placement: `scrypath_ops/test/scrypath_ops_web/copy_rules_contract_test.exs` plus a small pure helper `scrypath_ops/test/support/copy_rules.ex` (`load!/0`, `validate/1`, `scan_source/3`, `evaluate_surface/3`) so the planted-failure tests exercise the same functions the real test uses. One ExUnit test loads the JSON (`Jason`), fails any row missing a field, with an empty `surfaces`, an unknown or duplicate id, a `glossary` that is not a term in `GLOSSARY.md`, an unregistered surface id, or a registered surface no row uses; scans each row's `source_scope` for `forbidden` (reading comments; binary files skipped; `exempt_paths` skipped; `allowed_in` excuses only the exact phrase); renders each named surface and asserts every `required` entry present and every `forbidden` entry absent. Surfaces are ids registered in the test file, each mapped to a function that renders the existing fixture state named in D-14 (reuse the setup of the LiveView test that already covers it; move shared setup into `test/support/` rather than copying it). The test fails with the row id, the surface id and the matching text. Planted failures, all through the helper functions: a forbidden string written into a temp file under a row's scope; a forbidden string in a rendered surface's HTML; a row with a missing field; a row with empty `surfaces`; a row naming an unregistered surface; an `allowed_in` phrase that excuses its own phrase but not a neighbouring hit; plus accept cases for each (required present and forbidden absent). Planted strings are built by concatenation so the guard's own source never contains a forbidden phrase.
- **D-16 Whole-tree scan for Control room:** the `control-room-casing` row reads every tracked file via `git ls-files -z` run from the repository root (outside `.planning/` and `brand/`; skip files that contain a NUL byte). This is COPY-02's literal scan. Task 1 of 190-01 confirms `git ls-files` works in the `ops-ui` job (full checkout); the fallback is `Path.wildcard` over the globs in D-19.
- **D-17 Vacuous negative assertions:** every `refute` of a renamed string is replaced by assert-new on the same fixture, and the old string becomes a `forbidden` entry evaluated on that fixture through the table. Concretely: `control_room_live_test.exs:245` refutes "The last successful observation is retained below", a string that is not in lib today (lib says "The last complete observation is retained below"); replace it with a refute of the real string on the no-prior fixture plus the surface in row `last-succeeded--absence`. `:246-247` and `posture_live_test.exs:740` (`refute failed_row =~ "Last success</dt><dd>—"`) become refutes of the new label with a dash placeholder plus the same row. `failed_sync_live_test.exs:654,823` refute "Retry queued" and stay (that string is kept). Old-string `refute` lines are removed from tests rather than kept, because a test file may not carry the old phrase under the whole-tree Control room scan and the table is the one place that names old strings (playbook W13).

### CI path regex and ledger (COPY-03)

- **D-18 ops-ui path regex: extend it** `[pre-seed call]`. In `.github/workflows/ci.yml:367` (`ops-ui-path`), add `GLOSSARY\.md`, `DESIGN\.md` and `examples/scrypath_ecommerce/(e2e|lib|test|scripts)/` to the `grep -qE` alternation, keeping every existing entry (if Phase 188.1 or 191 already changed the line, add to the merged line; 191 removes `brandbook/`). Reason: with squash-on-green and no human merge, a PR that only edits an e2e spec, the glossary or `DESIGN.md` back to "Control Room" or a retired status word would otherwise skip the guard and be caught only after the merge on the push run, leaving `main` red. Cost, measured: `ops-ui (path-scoped)` takes about 386 s (CI-EFFICIENCY, nightly 44689855947 shows it skipped), paid only by PRs that touch those paths; the demo's e2e specs change in a minority of PRs. The alternative (limit the scan to paths that already trigger `ops-ui`) was rejected because COPY-02 requires the e2e specs and `DESIGN.md` in scope and a skipped guard is the failure mode COPY-03 exists to prevent. The `ecommerce-path` classifier that 188.1 changes is a different job and must not skip a PR that edits `examples/` (its allowlist already guarantees that).
- **D-19 Wiring test:** `test/mix/tasks/workflow_wiring_test.exs` (the test at `:1285`, "ops-ui is a required context that reports instead of being path-filtered") gains a behavioural check instead of substring checks: extract the `grep -qE` pattern from the `ops-ui-path` job block, compile it, and assert it matches representative paths (`GLOSSARY.md`, `DESIGN.md`, `examples/scrypath_ecommerce/e2e/operator.spec.ts`, `examples/scrypath_ecommerce/test/x_test.exs`, `scrypath_ops/lib/x.ex`) and does not match `README.md` or `website/src/index.html`; and assert that the literal directory prefix of every `source_scope` glob in `copy_rules.json` (except `**`) matches the pattern, so the table and the regex cannot drift. The existing substring loop stays. The whole-tree `**` scope is the one place where PR-time coverage is partial; it is still enforced on every push to `main` (`ops-ui-path` always runs there). This is recorded in "what this does not prove".
- **D-20 Ledger row** `[pre-seed call]`: add a new row rather than extending an existing one, because Playbook S26 and the gate-budget rule count a check that rides an existing job. Row text (no cell may contain a pipe; the first backticked path must exist; `workflow_wiring_test` header is `Gate | Enforced by | Runs in | Deletion trigger | Expected churn per UI PR`):

  ```
  | ScrypathOps copy rules table | `scrypath_ops/test/scrypath_ops_web/copy_rules_contract_test.exs` (rows in `scrypath_ops/test/support/copy_rules.json`) | `ops-ui (path-scoped)` | Delete when the v1.48 rendered-text copy lint ingests `copy_rules.json` and enforces the same rows, or when scrypath_ops leaves this repository | One row edit when a glossary status word changes; one surface edit when a covered LiveView state moves |
  ```

  Update the line `Budget used: N of 12.` so N equals the row count on `main` at the time plan 190-02 runs (8 at the start of v1.47, 9 once Phase 189 lands its static-contract row, so expect 10; recompute, do not assume). Also extend the `ops-ui-path` / `ops-ui` description at `CONTRIBUTING.md:239` with "or a copy input the copy table scans (the glossary, `DESIGN.md` or the demo e2e specs)". Do not touch the budget sentence that names only v1.46, or the "in v1.47" trigger of the component-contract row: both are Phase 191's CLEAN-06. Record the path-regex cost in `.planning/reference/CI-EFFICIENCY.md` (one dated entry: what now triggers `ops-ui`, the 386 s measurement, and the reason).

### Cancel focus and promotion pins (COPY-04)

- **D-21 Cancel focus in the required lane:** in `examples/scrypath_ecommerce/e2e/operator.spec.ts`, immediately after the existing `const confirm = confirmation.getByRole("button", { name: "Replace live index with target", exact: true });` line (and before `await close.focus();`), add `await expect(cancel).toBeFocused();`. The `cancel` locator already exists at `:279` with the accessible name "Cancel index swap" (exact), which is the button the dialog's `data-ops-modal-cancel` attribute marks. The spec at `:267` already opens this dialog in the required `ecommerce-mounted` lane, so this adds no lane time and no new spec file. Prep D's placement on the nightly or dispatch lane is superseded. Playwright's `toBeFocused` retries, which covers the hook's queued focus (`ops_hooks.js:519-579`).
- **D-22 ExUnit pins for the dialogs** (`scrypath_ops/test/scrypath_ops_web/...`):
  - The `ops_modal` default: render `OpsUi.ops_modal/1` with `render_component/2` and no `initial_focus` and assert `data-ops-modal-initial-focus="[data-ops-modal-cancel]"` (`ops_ui.ex:1563`). Planted failure: an override passes a different selector and the assertion sees it.
  - The two destructive `ops_modal` dialogs already pin the attribute: Confirm index promotion (`sync_drift_live_test.exs:434`) and Confirm delete sync work (`failed_sync_live_test.exs:871`). Keep those assertions and make them part of the COPY-04 record. The Save-search modal (`search_live.ex:1738`) is not destructive and correctly uses `#saved-search-name-input`; a one-line assertion pins that it is not the Cancel default, so nobody "fixes" it.
  - The third destructive confirmation, deleting a saved search, is not an `ops_modal`: it is an inline form inside the `ops_sheet` "Manage saved searches" (`search_live.ex:1896-1930`, type-the-name confirm with a Cancel button), and the sheet's own default is `[data-ops-sheet-close]`. REQUIREMENTS COPY-04 and gap-pass E say "each of the three destructive dialogs" carry the Cancel selector. Resolution: pin what exists, not what the wording assumed. Assert the delete form renders its Cancel button (`phx-click="cancel_row"`) and that Escape inside it returns to the list (`search_saved_searches_test.exs:404-416` already does the latter). Do not convert the form to an `ops_modal` in this phase (a redesign, not wording). Recorded in Open contradictions.
- **D-23 Promotion-notice sentences:** `sync_drift_live.ex:1574-1586` renders the promotion notice body as `upcase_first(promotion_reason(reason)) <> "."`, and no test pins the body (only the flash is pinned, for four reasons). Add one ExUnit test that renders the notice (merge `show_promotion?: true`, `promotion_eligibility: {:blocked, reason}` and a reconcile result into `sync_drift_socket/1` and call `SyncDriftLive.render/1`) for every `promotion_reason/1` clause and asserts the exact sentence. There are 17 clauses (16 named plus the `_` fallback); render each by assigning `{:blocked, reason}` directly. Expected sentences, from `sync_drift_live.ex:1549-1565` with P-3 applied: "Select an available schema.", "Meilisearch is unavailable.", "Refresh sync and queue status." (for both `:reconcile_failed` and `:reconcile_not_current`), "Refresh the index contract check.", "Run the index contract check.", "Wait for the current check.", "Refresh checks for this schema and index.", "Confirm live and target indexes differ.", "Observe the prepared target index first.", "Wait for backend tasks to finish.", "Wait for pending sync work to finish.", "Wait for reindex work to finish.", "Wait for the current cutover to finish.", "Resolve failed sync work first.", "Resolve contract differences first.", and for an unknown reason "Refresh current checks." The eligible and nil states keep "Current checks are clear for this schema and index pair." and "Refresh current checks before promotion." (pin both). Table row `pending-promotion-reason` guards the P-3 sentence on a rendered surface.

### Evidence and delivery

- **D-24 Exact-head dispatch evidence:** after the last commit is pushed, run `gh workflow run ci.yml --ref <branch>` (the workflow has `workflow_dispatch`; `ecommerce-e2e (advisory)` runs on `schedule` or `workflow_dispatch` only, `ci.yml:636-638`) and record: the run id; that `headSha` equals the PR head (`git rev-parse HEAD` on the pushed branch); the job `ecommerce-e2e (advisory)` with conclusion `success` and its duration (about 1300 s measured, timeout 30 minutes); and the id of the PR's own required run. Any later commit makes that dispatch stale (a stale receipt is a failed gate), so dispatch is the last act before the squash merge. Baseline: the 2026-11-20 nightly, run 44689855947, head `bd69905e`, `ecommerce-e2e (advisory)` success in 1292 s, `deep-quality (advisory)` failure (the known sigra and cloak cause), `ops-ui` skipped. Caveat found while pre-seeding: that run predates seven merges to `main` (release 0.3.19, four dependency bumps including the ecommerce Mix group #142, and two docs PRs), so on a red dispatch first dispatch `ci.yml` on `main` and compare the failing specs, then fix only failures this phase caused and record any that `main` shows too. `ecommerce-e2e` has `continue-on-error: true`; read `jobs[].conclusion` from `gh run view <id> --json jobs`, which reports the real result (`deep-quality`, also advisory, shows `failure` there), and confirm that on the first dispatch.
- **D-25 The demo ExUnit test:** `examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/page_controller_test.exs:55` asserts the rendered page contains the label and is run by no required lane (the `ecommerce-mounted` lane runs only `harness.spec.ts` and `operator.spec.ts`; `ecommerce-e2e` runs Playwright specs, not ExUnit). Run it locally before the PR is marked ready and record the result: from the repository root `mix test examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/page_controller_test.exs` (delegated by `mix.exs:150-160`). Today that command stops with "lock mismatch" because the demo's dependencies are not fetched on this machine, so the task first runs `cd examples/scrypath_ecommerce && mix deps.get`, or uses the documented container route (`docker compose exec ... mix test`, with the Docker cleanup rules in AGENTS.md). Use `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5`.
- **D-26 `[informational]` No rendered review.** No preview refresh, no `npm run ui:preflight`, no `npm run ui:review`, no capture, no edit to `.planning/UI-PREVIEW.json` in this phase (roadmap Delivery paragraph; ROADMAP "UI-PREVIEW.json gets a one-line note" belongs to the milestone's closing change, not here). Wording is proved by ExUnit and the exact-head dispatch only. The phase record states that no design pass was done and that nothing here claims aesthetic or independent-review approval. The roadmap's `UI hint: yes` does not call for `gsd-ui-phase`; if it runs, it must not ask component-library, stack or palette questions (the answers are: no change, the brand tokens and the existing components).
- **D-27 Plans:** exactly two, neither evidence-only (GATE-02).
  - **190-01 Glossary, wording, rename and the table.** Tasks in order: (1) verify the RESEARCH "tasks for 190-01" list; (2) D-01 glossary block (own commit); (3) D-03 to D-08 string changes and D-06 status fix with their test updates in place; (4) D-10, D-11 rename across lib, tests, docs, e2e, `scripts/ci` fixture and the demo, including the four exact-match sites; (5) D-12 aria-current and title test; (6) D-13 to D-17 `copy_rules.json`, helper, test, planted failures, repaired refutes; (7) cheap checks (D-28), including the whole CI Node step locally because `scrypath_ops/assets/css/app.css` (edited at `:27`) is a file the lifecycle verifier fixture copies (GATE-02).
  - **190-02 Focus pins, regex, ledger, evidence.** Tasks in order: (1) D-21 Cancel-focus line; (2) D-22 and D-23 ExUnit pins; (3) D-18 to D-20 regex, wiring test, ledger row, `CONTRIBUTING.md` sentence, `CI-EFFICIENCY.md` entry; (4) D-25 local demo test; (5) push, the six required contexts green on the exact head, D-24 dispatch, record both run ids and the "what this does not prove" line in the phase record; (6) squash-merge.
- **D-28 Cheap checks first** (measured 2026-11-20, all green before any change): `cd scrypath_ops && MIX_ENV=test mix test test/scrypath_ops_web/live/control_room_live_test.exs test/scrypath_ops_web/ops_shell_contract_test.exs` (0.6 s); the single changed ops test files; `mix test test/mix/tasks/workflow_wiring_test.exs` from the root (5 s, 73 tests); `cd scrypath_ops && MIX_ENV=test mix test` (26 s, 514 tests and 2 doctests, needs the local Postgres); `node --test scripts/ci/ui_preservation.test.cjs` (21 s, 53 tests; it is not wired into CI, so run it by hand after editing `:226`); `node --test examples/scrypath_ecommerce/e2e/ui-review.selftest.mjs` (0.4 s, 32 tests); `cd examples/scrypath_ecommerce && npx --no-install playwright test --list` (2 s, 300 tests in 25 files, catches a syntax slip in any renamed spec); `mix format --check-formatted`. Then, because `app.css` is touched, the whole CI Node step: `node --test scripts/ci/ecommerce_build.test.cjs scripts/ci/ecommerce_lifecycle.test.cjs scripts/ci/ecommerce_evidence.test.cjs scripts/ci/ecommerce_target.test.cjs scripts/ci/ui_state_pairs.test.cjs` (needs `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 npm ci --ignore-scripts --prefix examples/scrypath_ecommerce` first if `node_modules` is missing; lifecycle cases run 30 to 36 s each). Commit, then at most one `mix verify.repository_contracts` on the final committed state (first run with the escalated permission for `FETCH_HEAD`; it clones HEAD, so a fix is committed before it reruns); the hosted run on the exact head is also that gate, so do not run it twice on one SHA.
- **D-29 `[informational]` Delivery.** One non-draft PR from a branch cut by hand from fresh `origin/main` (`git.branching_strategy` is `none` and local `main` carries unpushed planning commits), no stacked PRs, squash title `chore(ops-ui): ...` or `docs(...)`, never `feat` or `fix` (no library change ships; ScrypathOps is not on Hex). No merge yes: squash-merge once the six required contexts are green on the exact head and the D-24 evidence is recorded (AGENTS.md, 2026-11-19). Do not push the ship-note commit that `gsd-ship` adds; it moves the PR head and stales the dispatch. The workflow never opens or merges a PR itself, so the orchestrator or maintainer does that between `--only` runs.
- **D-30 `[informational]` Superseded statements.** Where an older note disagrees, this file wins:
  - Prep A "What needs the maintainer" item 2 ("one batched yes for 190's visible wording"), gap-pass F X14 and ROLLING-ROADMAP's "batched yes on visible copy" are superseded by `AGENTS.md` (2026-11-19) and the roadmap Delivery paragraph: no yes, a non-draft PR, squash on green. The wording rules are already recorded, so there is no copy approval step.
  - Prep D's placement of the Cancel-focus assertion on the nightly or dispatch lane, and ROLLING-ROADMAP's "Cancel-focus and two unpinned copy values go to 194", are superseded by COPY-04 (the required `operator.spec.ts`, Phase 190).
  - Prep A footgun 5 ("exact-string grep found no spec pinning the old casing") and "9 or 10 occurrences in 10 files" are wrong: 54 occurrences in 28 files, four exact-match Playwright sites (D-11).
  - Prep A's "extend `reskin_component_contract_test.exs`" and its deletion trigger "replaces it in v1.47" are superseded by D-15 and D-20 (a new test file and a new ledger row; the catalog is v1.48).
  - V1.46-PREP D10's `sync_drift_live.ex:1724` (now `:1734`) and gap-pass H's "no ExUnit test asserts `aria-current`" (the shell contract asserts it on four routes, not the Control room, D-12) are corrected here.
  - Gap-pass H-4's "Proposed" strings are proposals; D-03, D-05, D-07 and D-08 are the final strings.
- **D-31 Verification rule.** Every success criterion is an executable assertion: ExUnit (`ops-ui`, `core`), a Playwright assertion in the required lane, a static scan, or hosted CI evidence on the exact head. Plans contain no `<human-check>` blocks and no `verification: backstop` truths (either routes the verifier to `human_needed` and halts the autonomous run, and `AGENTS.md` says backstop annotations are not passing evidence). Subjective notes on how the copy reads go in a nonblocking review note and claim no approval. If the verifier still reports `human_needed`, convert the item to a test and re-verify; never choose "continue without validation".

### Claude's Discretion

- File and helper names inside the paths named above, the exact surface ids and how fixture setup is shared (extract to `test/support/` or call existing helpers), the split of rows beyond the minimum in D-14, and commit slicing inside the two plans.
- The rewording of the `posture.ex:342` comment and of any other comment that trips the static scan, provided the scan stays case-insensitive and reads comments.
- Regex flavour details for the table (Elixir `Regex` with the `u` flag), provided each pattern is tested by its planted and accept cases.
- Whether to add an `id`-based `data-testid` where a surface assertion needs a stable hook (no visible change).
- Run the cheapest checks first (D-28) and look for a low-hanging CI speed win whenever a run happens; record it in `CI-EFFICIENCY.md`, never weaken a check.

</decisions>

<specifics>
## Specific Ideas

- The table is the one place that names old strings, so tests stop carrying `refute "old text"` lines (D-17). Existing positive assertions are edited in place; the table adds rule-level anchors (for example the regex `\d+ jobs? pending`), not a second copy of every sentence (playbook W13).
- A row that passes today but would fail if its guarded string came back is the whole point: run each planted failure against the old string by temporarily restoring one (a throwaway check in the executor's worktree, not a committed change) to see the row go red for the right reason.
- The two literals of the Control room label (layouts and command palette) are deliberately left as two edits; D-12 asserts both.
- AGENTS.md house rule: a small copy beats a new dependency. No new dependency in this phase (`Jason`, `LazyHTML` and `Phoenix.LiveViewTest` are already in `scrypath_ops`).

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap
- `.planning/REQUIREMENTS.md` - COPY-01 to COPY-04 and GATE-02 (standing).
- `.planning/ROADMAP.md` - Phase 190 detail, the v1.47 "Delivery", "Verification default" and "Run notes for gsd-autonomous" paragraphs.

### Prep, gap-pass and glossary rulings
- `.planning/research/v1.47-gap-pass/H-wording-cleanup.md` - the coupling inventory and string mapping this file finalizes (H-1 to H-5, H-7, H-8).
- `.planning/research/v1.47-gap-pass/E-adversarial-review.md` - findings 4, 5 and 6 (preservation receipts, the unstated glossary rule, Cancel focus).
- `.planning/research/v1.47-gap-pass/F-autonomy-stalls.md` - sections 1 and 4 (stall defaults, the Phase 190 table).
- `.planning/research/v1.47-prep/A-scope-and-shape.md` - phase shape and the footguns it names (superseded points listed in D-30).
- `.planning/research/brand-and-catalog/V1.46-PREP.md` - D10 status vocabulary and the rules COPY-01 cites.
- `GLOSSARY.md` and `.planning/reference/OPERATOR-UI-QUALITY.md` - canonical terms and the copy and states rules.
- `.planning/reference/BRAND-ADOPTION-PLAYBOOK.md` - T9 and T17 (a text-must-not-change guard needs the approved diff listed and a self-test), W4 (state what the inventory does not cover), W13 (one verbatim copy layer), S26 (a check riding an existing job still counts).
- `.planning/milestones/v1.46-phases/187-scrypathops-re-skin/187-REVIEW.md` IN-01 and IN-02 - IN-02 is D-06; IN-01 is deferred.
- `.planning/reference/CI-EFFICIENCY.md` and `.planning/reference/ROLLING-ROADMAP.md` - efficiency ledger to update; roadmap statements superseded in D-30.
- `AGENTS.md` - standing rules (squash on green, no human UAT, cheap checks first, escalated first `repository_contracts` run, fixture-copy rule).

### Code and tests this phase edits
- `scrypath_ops/lib/scrypath_ops_web/live/{control_room,sync_drift,posture,failed_sync,help}_live.ex`, `components/{layouts,ops_ui}.ex`, `lib/scrypath_ops/posture.ex`.
- `scrypath_ops/test/scrypath_ops_web/live/{control_room,sync_drift,posture,failed_sync,search_saved_searches}_test.exs`, `ops_shell_contract_test.exs`, `router_test.exs`, `reskin_component_contract_test.exs`.
- `examples/scrypath_ecommerce/e2e/` (the files in D-11, plus `operator.spec.ts` for D-21), `scripts/ci/ui_preservation.test.cjs`.
- `.github/workflows/ci.yml:357-373` (`ops-ui-path`, `ops-ui`), `test/mix/tasks/workflow_wiring_test.exs:1285-1300` and the ledger helpers at `:1351-1417`, `CONTRIBUTING.md:239-260`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `sync_drift_socket/1` and `SyncDriftLive.render/1` in `sync_drift_live_test.exs` (render a state without a route); `put_healthy_posture_config!/0` and the `control_room_client_state` env switch in `control_room_live_test.exs`; the Oban job stubs at `sync_drift_live_test.exs:310-322`.
- `assert_ops_shell!/2` in `ops_shell_contract_test.exs:117` (title fragment, `aria-current`, two active nav links).
- `render_component/2` with `LazyHTML` (`result_ui_test.exs`) for the `ops_modal` default pin.
- `workflow_job_block/2` and the ledger helpers in `workflow_wiring_test.exs`.
- `ops_hooks.js` `OpsModal` (`queueInitialFocus`) reads `data-ops-modal-initial-focus`; the ecommerce host imports the same hook, so the required lane exercises it.

### Established Patterns
- Copy lives in `scrypath_ops/lib` LiveViews and components; strings that tests pin are edited in place with their tests.
- Advisory Playwright specs run only on `schedule` or `workflow_dispatch`; the required lane is `harness.spec.ts` plus `operator.spec.ts`.
- Guard self-tests plant a failure through the guard's own code (playbook T17); planted strings are built by concatenation.

### Integration Points
- `ops-ui` runs `mix verify.ops_ui` (root boundary test, then the isolated Postgres-backed ScrypathOps suite); the new test rides it.
- `.planning/config.json` and `state.json` are dirty and not part of any owned commit.

</code_context>

<deferred>
## Deferred Ideas

- Aligning the Filterable and Sortable rows to "Used for filtering" and "Used for sorting" (D-04): a copy decision with advisory-spec churn; revisit with the v1.48 copy lint.
- IN-01 (187 review): Sync and index shows "Pending" for a queue holding only scheduled retries, while Search health says "Retrying"; pinned by `sync_drift_live_test.exs:293-295`. A product decision, not a glossary-rule fix.
- "waiting" for Meilisearch task counts (`sync_drift_live.ex:1646,1704`) and "No successful observation recorded." (`posture_live.ex:646`): outside the literal rules; candidates for the v1.48 rendered-text lint.
- Stale area names in docs (`DESIGN.md` still says "Sync and drift" and "Saved searches" in places): outside COPY scope.
- Turning the saved-search delete form into an `ops_modal` with Cancel as initial focus (D-22): a design change.
- JavaScript strings and attribute text in the copy table (listed in `not_covered`), the rendered-text lint, and the palette-input focus outline (IN-07): v1.48 and v1.49.
- Preview refresh and `npm run ui:review`: the first rendered-evidence phase of v1.48.

</deferred>

<open_contradictions>
## Open contradictions

Recorded, not papered over. None blocks starting; each has the default used here.

1. **COPY-04 and gap-pass E say three destructive dialogs carry `data-ops-modal-initial-focus="[data-ops-modal-cancel]"`, but only two are `ops_modal` dialogs.** The third (delete a saved search) is an inline confirm form inside the `ops_sheet`, whose default is `[data-ops-sheet-close]`; `search_live.ex:1738` is the non-destructive Save-search modal and correctly focuses its name input. Default (D-22): pin the default and the two real destructive modals, pin the delete form's existing Cancel and Escape behaviour, and do not redesign it. The roadmap and requirement text should say "the two destructive dialogs and the saved-search delete confirmation".
2. **Gap-pass H-8's proposed assertion names the button `"Cancel"`, but the button's accessible name is "Cancel index swap".** Default (D-21): use the existing `cancel` locator.
3. **REQUIREMENTS COPY-03 lists the row field `surface`, but its failure condition says "empty `surfaces`".** Default (D-13): `surfaces`, a non-empty list. If the maintainer wants the singular key, only the JSON and the helper change; nothing else depends on it.
4. **REQUIREMENTS COPY-02 says the scan has an "explicit exception list: files already sentence case".** A case-sensitive scan needs no such list (those files simply have no hit). The real exceptions are `.planning/`, `brand/` and `copy_rules.json` (D-11), and `GLOSSARY.md` must not spell the old form. Default: as D-11.
5. **The roadmap says a red `ecommerce-e2e` after this phase is attributable to it because the 2026-11-20 nightly (44689855947) was green.** That run predates seven merges to `main` (release 0.3.19, four dependency bumps including the ecommerce Mix group #142, two docs PRs). Default (D-24): on red, dispatch on `main` and compare before attributing.
6. **Gap-pass H says no ExUnit test asserts `aria-current`.** `ops_shell_contract_test.exs:128-133` does, for four routes, but not for the Control room route, which is where the rename coupling bites. Default (D-12): add the Control room case there.
7. **COPY-01's Pending-aggregate rule collides with the existing component structure and IN-01.** Sync and index already renders the Pending status word before the count, so the literal rule yields "Pending, 1 job pending"; and IN-01 (a retry-only queue shows Pending) is an unresolved product question. Default (D-08): follow the literal rule, accept the repetition, defer IN-01. Veto if the repetition is unwelcome.
8. **The ledger row count depends on merge order.** The roadmap has 190-02 add a row and 189 also takes row 9 in its own change; both edit `CONTRIBUTING.md`, `workflow_wiring_test.exs` and `ci.yml`. Default (D-20, header paragraph): whichever lands second rebases and recomputes the budget line; do not hard-code 9 or 10.
9. **COPY-04 and the roadmap name a dispatch of `ci.yml` as the evidence, but `ecommerce-e2e` is `continue-on-error: true` and runs no ExUnit.** Default (D-24, D-25): read the job conclusion from `gh run view --json jobs`, and run `page_controller_test.exs` separately (it needs the demo's dependencies fetched first).

</open_contradictions>

---

*Phase: 190-wording-without-the-catalog*
*Context gathered: 2026-11-20*
