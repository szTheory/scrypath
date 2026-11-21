# Phase 190: Wording that does not need the catalog - Research

**Researched:** 2026-11-20
**Domain:** ScrypathOps copy (Phoenix LiveView strings), one data-driven ExUnit guard, one Playwright assertion in the required lane, CI path and ledger wiring. No visual change.
**Confidence:** HIGH for in-repo facts (read or run today); MEDIUM for the design recommendations marked U.

Legend: **V** = verified today (2026-11-20) by reading the file or running the command. **U** = inferred or recommended, not proven. Line numbers are today's `origin/main` (e6fc151b; the source tree is identical to local `main`, only `.planning/` differs) and drift; search by string before editing.

This note re-verifies the coupling inventory in [H-wording-cleanup.md](../../research/v1.47-gap-pass/H-wording-cleanup.md) against current `main`, flags what drifted, and lists what is still unverified as tasks for plan 190-01. It was written to pre-seed `gsd-autonomous --only 190` and replaces the research step; the decisions it supports are in [190-CONTEXT.md](190-CONTEXT.md).

<user_constraints>
## User Constraints (from CONTEXT.md)

Locked decisions D-01 to D-31 in [190-CONTEXT.md](190-CONTEXT.md). The ones that bound this research:
- Glossary Status wording block first; final strings for Searchable, Last succeeded, Pending and Queued, Retry queued and accepted are fixed (D-03 to D-08), each marked `[pre-seed call]` for the maintainer to veto.
- Strings pinned by the required-lane `operator.spec.ts` and `harness.spec.ts` do not change (D-09).
- "Control room" in sentence case everywhere outside `.planning/`, `brand/` and the table file (D-10, D-11); `aria-current` and title test (D-12).
- `scrypath_ops/test/support/copy_rules.json` plus one `ops-ui` ExUnit test with planted failures (D-13 to D-17); extend the `ops-ui` path regex (D-18, D-19); new ledger row (D-20).
- Cancel focus in `operator.spec.ts`; ExUnit pins for the `ops_modal` default, the destructive dialogs and the promotion-notice sentences (D-21 to D-23).
- Exact-head `ci.yml` dispatch evidence (D-24); no preview refresh, no `npm run ui:review` (D-26); two plans, neither evidence-only (D-27).
- Executable assertions only: no `<human-check>`, no `verification: backstop` (D-31).

### Out of scope
Visual re-skin, new components, catalog or storybook work, JS-string copy, the Filterable and Sortable rows, IN-01, Phase 191 cleanup (including the ledger budget sentence and the component-contract row text), any Hex release.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research support |
|----|-------------|------------------|
| COPY-01 | Glossary block, then copy follows the rules; pinned strings unchanged | Section "Re-verification of H" rows 6 to 10; the mapping and its pins are D-03 to D-09 |
| COPY-02 | "Control room" sentence case everywhere; four exact-match Playwright sites; `aria-current` and title test | Counts re-verified (54 in 28 files); `layouts.ex:313-320` coupling; shell contract gap |
| COPY-03 | One table file, one `ops-ui` test, ledger and path regex | Row design, surface fixtures, regex and ledger constraints below |
| COPY-04 | Cancel focus in the required lane; ExUnit pins | `operator.spec.ts` locator facts; only two destructive `ops_modal` dialogs exist; 17 `promotion_reason/1` clauses, none pinned today |
| GATE-02 | Standing guardrails | `app.css` is a lifecycle-fixture file; snapshot gate reads HEAD; dispatch evidence goes stale on any later commit |

</phase_requirements>

## Summary

- The inventory in H is accurate. 54 occurrences of "Control Room" in 28 files, 12 e2e files, the four exact-match Playwright sites, the vacuous `refute` lines and every string cite in the H-4 table re-verified. Drift is small (a few line numbers) and listed below.
- H is wrong or incomplete in four places: (1) only two of the three "destructive dialogs" are `ops_modal`s, and `search_live.ex:1738` is the non-destructive Save-search modal; (2) the Cancel button's accessible name is "Cancel index swap", not "Cancel"; (3) `ops_shell_contract_test.exs` does assert `aria-current` on four routes, just not on the Control room; (4) the nightly baseline (44689855947) predates seven merges, so "any red is attributable to the phase" overstates it.
- New findings: `admin_shell_chrome.spec.ts:61` and `:510` are coupled by a map key; `scripts/ci/ui_preservation.test.cjs` and `ui-review.selftest.mjs` hold "Control Room" fixture text but are not in any CI step (run them by hand; both pass today); `app.css:27` is a file the lifecycle fixture copies, so GATE-02 requires the whole CI Node step locally; no test pins the promotion-notice body; the demo's ExUnit test cannot run on this machine until its dependencies are fetched.
- The cheapest feedback loop is fast: the whole ScrypathOps suite runs in 26 s locally (514 tests, 0 failures), the wiring test in 5 s, and `playwright test --list` parses all 300 specs in 2 s.
- Everything the success criteria need is an executable check in an existing lane (`ops-ui`, `core`, `ecommerce-mounted`) plus one hosted dispatch; nothing needs a human.

## Re-verification of H against current main

Method: `git grep` and direct reads on `origin/main` e6fc151b, plus runs listed in "Cheapest checks". Status: **holds**, **drift** (cite moved, claim true), **wrong** (claim is false or incomplete).

| # | H claim | Today | Status |
|---|---------|-------|--------|
| 1 | "Control Room" appears 54 times in 28 non-planning files | `git grep -o` outside `.planning/` and `brand/`: 54 occurrences, 28 files (26 lines carry the e2e ones; `layouts.ex:320`, `admin_path_motion.spec.ts:55`, `ops_reskin_contract.spec.ts:57` and `DESIGN.md:23` carry two each) | holds (V) |
| 2 | 12 e2e files (11 `.ts`, 1 `.mjs`) plus `scripts/ci/ui_preservation.test.cjs` | same 12 files, 28 occurrences (`ui-preservation-states.ts` 9, `admin_path_motion` 4, `ops_reskin_contract` 3, `admin_shell_chrome` 3, `phase1_screens` 2, six files with 1) | holds (V) |
| 3 | Rendered literals in ops lib: 6 (`layouts.ex:320` x2, `ops_ui.ex:1717`, `control_room_live.ex:17` and `:86`, `sync_drift_live.ex:2438`); comments 5 | exact match; comments `ops_ui.ex:560,629,691`, `posture.ex:182`, `app.css:27` | holds (V) |
| 4 | Exact-match Playwright sites: `admin_path_motion.spec.ts:55` (exact at `:201`), `ops_reskin_contract.spec.ts:57` (exact in `gotoPath`, `:913`), `ui_routes_preservation.spec.ts:93`, `ui-preservation-states.ts:194` | all present; `gotoPath` (`:910-914`) is called with `SCREENS[0]` at `:938` (loop), `:1019`, `:1195`, `:1363`, `:1571`, so the Control room route is exercised by the P-01..P-21 suite | holds (V) |
| 5 | `layouts.ex:317` is `nav_item_active?(item, page_title)` comparing `item.title == page_title` | the function is at `:313`; the label and title literal at `:320` | drift (V) |
| 6 | No ExUnit test asserts `aria-current` on the Control room nav item | `ops_shell_contract_test.exs:117-133` (`assert_ops_shell!`) asserts `aria-current="page"` and exactly two `.ops-nav-item-active` links, but is called only for `/ops/health`, `/ops/failed-sync`, `/ops/sync-and-index` and `/ops/search` (`:188-205`), not `/ops` | partly wrong: true for the Control room, the only route the rename touches (V) |
| 7 | Vacuous refutes: `control_room_live_test.exs:245-247`, `posture_live_test.exs:740`, `failed_sync_live_test.exs:654,823` | `:245` refutes "The last successful observation is retained below", which is not in lib (lib `control_room_live.ex:109` says "The last complete observation is retained below"); `:246-247` and `posture_live_test.exs:740` refute strings that disappear with the rename; `failed_sync_live_test.exs:654,823` refute "Retry queued", which is kept | holds (V) |
| 8 | H-4 table cites (Searchable `sync_drift_live.ex:1734`; Last succeeded `control_room_live.ex:146,177`, `sync_drift_live.ex:1994`, `posture_live.ex:443,500,610-611`; accepted `failed_sync_live.ex:319,351`, `sync_drift_live.ex:579,599-601,1602,2153,2364`, `help_live.ex:79,123`; Pending `sync_drift_live.ex:1560,1653,1703`) | every cite matches today's string at that line | holds (V) |
| 9 | Pinning tests: `sync_drift_live_test.exs:523,524,304,322,1067`; `control_room_live_test.exs:218,223,326`; `posture_live_test.exs:167,739,740,387,390`; `failed_sync_live_test.exs:704` | all match. `sync_drift_live_test.exs:274` also pins "No Meilisearch tasks waiting or failed." (kept) | holds (V) |
| 10 | Strings `operator.spec.ts` pins (`:144`, `:151`, `:153`, `:155`, `:166`, `:177`, `:185`, `:332`, `:273`, `:72-73`, `:267`) | all present; "Check sync status" is at `:161` and the `attempt (\d+)` regex at `:157`; the list is incomplete (see D-09 for the full set, and `harness.spec.ts` pins more) | drift (V) |
| 11 | `page_controller_test.exs:55` asserts `html =~ "Control Room"`; no required lane runs the demo ExUnit suite | line and assertion confirmed; `docker-playwright.sh:255` runs only `harness.spec.ts` and `operator.spec.ts` in `ecommerce-mounted`; `test/scrypath/phase147_e2e_contract_test.exs:40` pins that | holds (V) |
| 12 | `ci.yml:367` path regex lacks `examples/`, `GLOSSARY.md`, `DESIGN.md`; `workflow_wiring_test.exs` checks the directory list | regex at `ci.yml:367` is `^(scrypath_ops/\|lib/\|dev/\|config/\|priv/\|brand/\|brandbook/\|language/\|fixtures/\|scripts/ci/\|test/release/\|mix\.exs\|mix\.lock\|\.github/workflows/ci\.yml)`; the loop is at `workflow_wiring_test.exs:1295-1299` (H said `:1297`) | holds (V) |
| 13 | Ledger: header exact, 1 to 12 rows, five cells, no empty cell, first backticked path exists, `Budget used: <rows> of 12.`, five Phase 186 files mandatory | `workflow_wiring_test.exs:1351-1417` and `@phase_186_gate_files` at `:620-626`; `CONTRIBUTING.md:245-260` has 8 rows and `Budget used: 8 of 12.` | holds (V) |
| 14 | `operator.spec.ts:267-268` opens the promotion dialog in `ecommerce-mounted`; `ops_modal` defaults `initial_focus` to `[data-ops-modal-cancel]` (`ops_ui.ex:1563`); "the other two destructive dialogs are `failed_sync_live.ex:1208` and `search_live.ex:1738`" | dialog open at `:267`, default at `ops_ui.ex:1563`, `failed_sync_live.ex:1208` is the destructive retry-delete modal; **`search_live.ex:1738` is the Save-search modal with `initial_focus="#saved-search-name-input"`**, not a destructive one; the saved-search delete confirmation is an inline form in the `ops_sheet` (`search_live.ex:1782-2000`, delete form `:1896-1930`) | wrong for the third dialog (V) |
| 15 | Proposed assertion `confirmation.getByRole("button", { name: "Cancel", exact: true })` | the button is "Cancel index swap" (`operator.spec.ts:279` already defines `cancel` with that exact name); `sync_drift_live_test.exs:439` confirms the label | wrong (V) |
| 16 | The promotion-notice copy path is `upcase_first(promotion_reason(...))` at `sync_drift_live.ex:1574-1586`; pin each clause | confirmed; there are 17 `promotion_reason/1` clauses (`:1549-1565`: 16 named plus the `_` fallback); no test pins the notice body (the flash is pinned for four reasons at `sync_drift_live_test.exs:608-613`) | holds (V) |
| 17 | Baseline: nightly 44689855947 on `bd69905e`, `ecommerce-e2e` success, `deep-quality` failure (known), `ops-ui` skipped | confirmed with `gh run view`: `ecommerce-e2e (advisory)` success, 06:43:53 to 07:05:25 (1292 s); `deep-quality (advisory)` failure; `ops-ui (path-scoped)` skipped. But seven merges followed it (release 0.3.19 #146, dependency bumps #128, #131, #140, #142, docs #147 and #148) | holds, with a caveat: not a clean attribution baseline (V) |

## Additional findings not in H

1. **A map-key coupling inside one spec.** `admin_shell_chrome.spec.ts:61` (`{ name: "Control Room", ... }`) feeds `surface.name`, which keys the object at `:510` (`"Control Room": page.getByTestId("control-room-health-link")`, indexed `[surface.name]!`). Renaming one without the other makes the lookup `undefined`.
2. **Two files with fixture text are outside every CI step.** `scripts/ci/ui_preservation.test.cjs:226` (`links: ["Control Room", "Search"]`) and `e2e/ui-review.selftest.mjs:436` are only run by hand (`package.json` has `ui:review:selftest`; `ui_preservation.test.cjs` is wired nowhere). Both pass today (53 tests in 21 s; 32 tests in 0.4 s). The strings are synthetic: no validator in `ui_preservation.cjs` or `ui-review.mjs` matches "Control Room" (grep: zero hits), so renaming them is safe, but run both after the edit.
3. **`scrypath_ops/assets/css/app.css:27` is in the verifier fixture.** `scripts/ci/ecommerce_lifecycle.test.cjs:111-125` copies `app.css`, `contrast-pairs.mjs`, `contrast-checker.mjs`, `brand/tokens.json` and `brand/brand.json`. A comment-only edit still triggers AGENTS.md's rule (and GATE-02): run the whole CI Node step locally before the final gate. The built CSS (`priv/static/assets/css/app.css`) has zero "Control Room" hits, so token-level freshness is unaffected.
4. **`ops_command_palette` renders the label too** (`ops_ui.ex:1717`, item 0, `#ops-cmdk-item-0 .ops-cmdk__item-label`), as do the sidebar and the mobile drawer (two `ops-nav-item-active` links). The label lives in two literals (`layouts.ex:320`, `ops_ui.ex:1717`); a whole-page substring check cannot tell them apart, so D-12 asserts the nav link and the palette item separately.
5. **GLOSSARY.md is inside the scan.** The new Status wording block must not spell the old form of the label, and its `_Avoid_` lists hold the old status phrases, so those phrases may only be forbidden in `scrypath_ops/lib/**`, never in a `**` scope.
6. **Comments are scanned.** `posture.ex:342` says "Keep the last successful source-local references"; under the `last-succeeded` row's scope it must be reworded. Underscored identifiers (`last_successful_posture`, `last_success_refs`, `source_last_success_label`) do not match a pattern that needs a space.
7. **IN-02 is not in lib yet.** `control_room_live.ex:140-151` still passes `status={Posture.worst_status(@posture.rows)}` for a retained observation, exactly as the v1.46 review described.
8. **IN-01 interacts with the Pending rule.** `signal_status(:pending_queue_work)` is `:pending` and `Reconcile` raises that signal for a queue with only scheduled retries; the literal rule does not fix that (deferred).
9. **The `Filterable` and `Sortable` strings are pinned by advisory specs** (`ui_iteration3.spec.ts:146`, `ui-preservation-states.ts:466`), which supports leaving them unchanged (D-04).
10. **Source diff versus planning diff.** Local `main` is five commits ahead of `origin/main`, all `.planning/`; `git diff origin/main HEAD` outside `.planning/` is empty, so line numbers are the same on either. Another pre-seeding run is creating the 189 and 191 phase directories concurrently, and `REQUIREMENTS.md` and `ROADMAP.md` (Phase 189 and CLEAN-02 lines) were edited and an untracked `.planning/research/website-refresh/` appeared during this session; none of those edits touch Phase 190.
11. **CI interplay.** Phase 188.1 (classifier) edits `ci.yml`'s `ecommerce-path` job; 189 edits `website.yml`, the ledger and `workflow_wiring_test`; 191 removes `brandbook/` from the same `ops-ui-path` regex this phase extends. Whichever lands second rebases and recomputes the ledger budget line.

## Tasks for plan 190-01 (items still unverified)

Resolve these first; each is cheap and none needs the maintainer.

1. **`git ls-files` inside the `ops-ui` job (D-16).** Check the `ops-ui` job's checkout (`.github/workflows/ci.yml:369-420`) and the `mix verify.ops_ui` task: the scan runs `git ls-files -z` from the repository root while tests run from `scrypath_ops/`. Local run is fine; confirm in the first hosted log. Fallback: `Path.wildcard` over explicit globs (the files are the ones in D-11).
2. **Surface fixtures (D-14).** Confirm each registered surface can be rendered from an existing fixture: `control_room.refresh_retained` (test at `control_room_live_test.exs:195-226`), `control_room.refresh_no_prior` (`:229-248`), `sync_drift.queue_pending` and `sync_drift.caught_up` (`sync_drift_live_test.exs:297-322`), `sync_drift.settings_missing_field` (`:508-524`), `failed_sync.after_retry` (`failed_sync_live_test.exs:500-525`), `posture.default` (`posture_live_test.exs:160-170`), `posture.failed_row_retained` (`:730-740`). Four need the render-with-assigns pattern and may need a `reconcile_result` or recovery fixture that no existing test builds: `sync_drift.reconcile_error_retained` (no test covers "Showing the last successful check below." today), `sync_drift.recovery_queued`, `sync_drift.promotion_accepted`, `sync_drift.promotion_blocked_queue`. If one cannot be built in reasonable effort, drop that surface, list it in `not_covered`, keep the row's static scan.
3. **`<title>` in the dead render.** Confirm the `html` returned by `live/2` contains `<title ...>Control room</title>` from `root.html.heex` (`live_title`) so the title assertion in D-12 reads the real element.
4. **Whole-page absence checks.** Confirm the `\bClear\b` check passes on the retained surface after D-06 and does not match another "Clear" on the Control room page (grep of `control_room_live.ex` shows none besides the status word).
5. **Flash visibility after a retry.** Confirm the "Retry queued · queue job N" flash appears in `render(view)` on `failed_sync.after_retry` so the `retry-surfaces-no-accepted` row covers the flash and not only the receipt.
6. **`mix deps.get` for the demo** (D-25). `mix test examples/scrypath_ecommerce/test/...page_controller_test.exs` from the root stops with "lock mismatch" on this machine today. Run `cd examples/scrypath_ecommerce && mix deps.get` (network) or use the documented container route; confirm the test then passes before and after the rename.
7. **`jobs[].conclusion` for a `continue-on-error` job** (D-24). Confirm on the first dispatch that `gh run view --json jobs` reports `failure` for a failed `ecommerce-e2e (advisory)` (the nightly shows `deep-quality (advisory)` as `failure`, which suggests yes).
8. **Re-count after the edits.** `git grep -n "Control Room" -- . ':!.planning' ':!brand'` must return only the table file's exemption (zero tracked hits); record the command and the empty result in the phase record. Then `git grep -n -i -E "last success(ful)?\b|Retry accepted|Nothing queued|Not searchable" -- scrypath_ops/lib` must be empty.

Tasks for plan 190-02 that depend on facts above: confirm the exact `Budget used` count on `main` at that time (8 today); decide the final regex text against whatever 188.1 and 191 have merged by then; run the dispatch last.

## Architecture patterns

### Pattern 1: Table-driven copy guard (U, design)
One JSON file of rows; one pure helper module (`load!`, `validate`, `scan_source`, `evaluate_surface`); one ExUnit test that runs the helper against the real tree and real surfaces; the planted-failure tests run the same helper functions against temp files and altered HTML (playbook T17: calibrate through the gate's own code path). A surface is a registered function that renders an existing fixture state. Rows are split when a required phrase is not present on every surface (the `last-succeeded--absence` row exists only for the two fixtures that had vacuous refutes).

### Pattern 2: Render a LiveView state without a route (V)
`sync_drift_socket/1` plus `Map.merge(base_assigns, overrides) |> SyncDriftLive.render() |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()` is already used at `sync_drift_live_test.exs:1056-1067`. It reaches states a route cannot (promotion eligibility, promotion status, reconcile error with a retained result).

### Pattern 3: Component default pin (V)
`render_component(&OpsUi.ops_modal/1, id: "x", title: "t", inner_block: [...])` with no `initial_focus`, parsed with `LazyHTML` as in `result_ui_test.exs`. Assert `data-ops-modal-initial-focus="[data-ops-modal-cancel]"`.

### Pattern 4: Required-lane focus assertion (V)
In `operator.spec.ts` after `confirm` is defined: `await expect(cancel).toBeFocused();`. The hook's `queueInitialFocus` (`ops_hooks.js:570-579`) reads `dataset.opsModalInitialFocus`; the ecommerce host imports the same `OpsModal` (`examples/scrypath_ecommerce/assets/js/app.js:15,88`), so the mounted lane exercises the real hook.

### Anti-patterns
- Keeping old-string `refute` lines in tests: they become tracked hits for the whole-tree scan and are vacuous once the string is gone. The table owns old strings.
- Substring checks of a regex in the wiring test: assert behaviour (compile the extracted pattern and match representative paths).
- A second verbatim copy of every sentence in the table: the table holds rule-level anchors; tests keep their own positive assertions (playbook W13).
- Refactoring the label to one source or converting the saved-search delete to an `ops_modal` here: both are design changes with their own risk.

## Common pitfalls

1. **Renaming the nav `title` without `page_title` (or the reverse)** silently drops `aria-current="page"` (`layouts.ex:313`). D-12 fails it.
2. **The retired-identity guards scan new files.** The deny-list of old hex colors and the retired-directory tripwire read every tracked non-exempt file; new test text, the glossary block and the JSON must not contain a retired hex or spell the retired directory (build such strings by concatenation, as `brand_pin_contract_test.exs` does).
3. **Gap-pass H's `Searchable` regex is case-sensitive on purpose.** `searchableAttributes` (lowercase) appears in lib and tests; only the capital-S word is forbidden outside "Searchable fields". Use `Searchable(?! fields)`, not a case-insensitive match.
4. **`last success` patterns need the literal space** or they match `last_success_refs` and `source_last_success_label`.
5. **`allowed_in` must excuse an exact phrase, not a region.** Otherwise an allowed phrase hides a neighbouring violation.
6. **`accepted` appears as an atom and in docs in lib** (`:accepted`, `accepted_receipt`, `recovery_observation.ex`). A broad `\baccepted\b` static scan over lib is a false-positive machine; use the phrase list for the static scan and the broad pattern only on rendered retry surfaces (rows `retry-queued-not-accepted` and `retry-surfaces-no-accepted`).
7. **Do not touch `help_live.ex:79,97`.** They describe Meilisearch accepting a request and already conform.
8. **Playwright `name:` matching is a case-insensitive substring unless `exact: true`.** Most specs keep passing after the rename, which is why the four exact sites and the case-sensitive regex are the only ones that fail, and why they fail silently (advisory lane).
9. **A dispatch receipt goes stale on any later commit.** Do not push the `gsd-ship` ship-note commit; dispatch last.
10. **`mix verify.repository_contracts` clones committed HEAD.** An uncommitted fix cannot repair a clean-copy test of the previous commit; commit, then run it once. The first run needs the escalated permission for `FETCH_HEAD`.
11. **Parallel ledger edits.** 189 adds row 9 and 190 adds a row in the same file and the same wiring test; rebase and recompute, never hard-code the count.
12. **`ops-ui` now runs on example-only PRs** (D-18). That costs about 386 s per such PR; record it in `CI-EFFICIENCY.md`.

## Validation Architecture

### Test framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19 / OTP 28) for ScrypathOps and root contracts; Playwright for the required-lane spec; `node:test` for fixture scripts |
| Local env | `export ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5`; local Postgres is up for ScrypathOps tests |
| Quick run | `cd scrypath_ops && MIX_ENV=test mix test <changed files>` |
| Full ops suite | `cd scrypath_ops && MIX_ENV=test mix test` (V: 514 tests and 2 doctests, 0 failures, 26 s) |

### Success criterion to check and lane (cheapest first)
| SC | Criterion (ROADMAP Phase 190) | Check | Where it runs | Cost |
|----|-------------------------------|-------|---------------|------|
| 1 | Glossary block exists; each rule proved on the table's surfaces; pinned strings unchanged; uncovered surfaces listed | `copy_rules_contract_test.exs` (rows `searchable-*`, `pending-*`, `retry-*`, `last-succeeded*`, `clear-needs-observation`, glossary-term check, `not_covered` non-empty); in-place updated LiveView assertions; `git diff` check that the D-09 strings are untouched; `playwright test --list` | `ops-ui` (required); `core` for nothing here; `ecommerce-mounted` keeps `operator.spec.ts` green | 26 s locally for the ops suite |
| 2 | Sentence-case Control room; whole-tree scan clean; four exact-match sites updated; `aria-current` and title on the Control room route | row `control-room-casing` (static `git ls-files` scan plus rendered `control_room.default`, `sync_drift.default`); new `test "/ops"` in `ops_shell_contract_test.exs`; `playwright test --list`; `node --test scripts/ci/ui_preservation.test.cjs` and `ui-review.selftest.mjs` | `ops-ui`; hand-run node tests; advisory specs proved by the dispatch | seconds |
| 3 | Table scans and renders; planted failures fail; missing field fails; refutes repaired; regex and wiring test cover scanned paths; ledger row and budget line consistent | planted-failure tests in `copy_rules_contract_test.exs`; behavioural regex test and `source_scope` prefix check in `workflow_wiring_test.exs`; the ledger checks in the same file | `ops-ui` (table test), `core` (`workflow_wiring_test`) | 5 s for the wiring test |
| 4 | Cancel focused on open; ExUnit pins the `ops_modal` default, the destructive dialogs and each promotion-notice sentence; `page_controller_test.exs` passes locally; exact-head dispatch shows `ecommerce-e2e` green; no preview capture; no design-pass claim | `operator.spec.ts` line (required lane); ExUnit pins (D-22, D-23); local `mix test` of the demo test; `gh workflow run ci.yml --ref <branch>` and `gh run view` on the exact head | `ecommerce-mounted` (required, about 19 minutes on a cold cache); `ops-ui`; hosted dispatch (advisory, about 22 minutes) | dispatch about 1300 s |
| GATE-02 | One full gate run per SHA, stale receipt is a failed gate, no dirty-tree capture, whole CI Node step because `app.css` changed, squash title `chore(...)`, ledger within 12 | local Node step; at most one `mix verify.repository_contracts` on the committed final state; hosted required contexts on the exact head | `repository-contracts` (required) | local Node step several minutes; gate about 206 s plus Node step |

### Sampling
- **Per task:** the changed ExUnit file; `mix format --check-formatted`; for the rename, the D-28 counts.
- **Per plan:** whole ScrypathOps suite; `workflow_wiring_test.exs`; the two hand-run node tests; `playwright test --list`.
- **Phase gate:** six required contexts green on the exact PR head; then the `ci.yml` dispatch on that head; record both run ids; squash-merge.

### Wave 0 gaps
- [ ] `scrypath_ops/test/support/copy_rules.json`, `scrypath_ops/test/support/copy_rules.ex`, `scrypath_ops/test/scrypath_ops_web/copy_rules_contract_test.exs`
- [ ] Shared fixture helpers for the registered surfaces (extract from the LiveView tests, do not copy)
- [ ] Framework install: none (`Jason`, `LazyHTML`, `Phoenix.LiveViewTest` are already present)

## Cheapest checks, measured today

| Check | Result |
|-------|--------|
| `cd scrypath_ops && MIX_ENV=test mix test test/scrypath_ops_web/live/control_room_live_test.exs test/scrypath_ops_web/ops_shell_contract_test.exs` | 23 tests, 0 failures, 0.6 s |
| `cd scrypath_ops && MIX_ENV=test mix test` | 514 tests, 2 doctests, 0 failures, 26 s |
| `mix test test/mix/tasks/workflow_wiring_test.exs` (root) | 73 tests, 0 failures, 5.3 s |
| `node --test scripts/ci/ui_preservation.test.cjs` | 53 pass, 21 s |
| `node --test examples/scrypath_ecommerce/e2e/ui-review.selftest.mjs` | 32 pass, 0.4 s |
| `cd examples/scrypath_ecommerce && npx --no-install playwright test --list` | 300 tests in 25 files, 1.8 s |
| `mix test examples/scrypath_ecommerce/test/.../page_controller_test.exs` (root) | does not run: "lock mismatch" until the demo's dependencies are fetched (task 6) |
| `gh run view 44689855947 --json jobs` | `ecommerce-e2e (advisory)` success, 1292 s; `ops-ui (path-scoped)` skipped; `deep-quality (advisory)` failure (known) |

## Security domain

No authentication, session, access-control or cryptography change. The only trust consideration is the table file: it is data read by a test, with no code in it and no interpolation into shell commands (`git ls-files` is invoked with fixed arguments). Regex entries are test-authored; use simple anchored patterns without nested quantifiers (no ReDoS surface on a few hundred tracked text files). No new dependency, no new network call from a required job.

## What this does not prove

- That the new copy reads well, matches the brand voice or is understood by operators; no design pass, rendered review, screenshot comparison or maintainer or independent aesthetic approval is claimed.
- Rendering in any browser but Chromium, real screen reader behaviour, or the Cancel focus anywhere but the mounted host the required lane uses.
- Coverage of JavaScript strings, attribute text, states with no named fixture surface, or non-English text; these are listed in `not_covered`.
- That an edit to a file outside the extended `ops-ui` path regex (for example `website/` or `README.md`) re-introducing the old label is caught before merge; it is caught by the same test on the push to `main`.
- That the advisory Playwright specs are green beyond the one dispatch on the exact head, or that a red dispatch is caused by this phase when `main` is also red (compare against a dispatch on `main`).
- That the glossary rules are complete (`waiting`, "No successful observation recorded.", Filterable and Sortable, IN-01 are outside them).

## Assumptions log

| # | Claim | Risk if wrong |
|---|-------|---------------|
| A1 | `git ls-files` works in the `ops-ui` job's checkout | Fall back to `Path.wildcard` over the D-11 globs (task 1) |
| A2 | All registered surfaces can be rendered from existing fixtures with the render-with-assigns pattern | Drop a surface, list it in `not_covered` (task 2) |
| A3 | The live-view dead render carries the `<title>` element | Assert the title through the root layout render or `page_title` assign (task 3) |
| A4 | A failed `continue-on-error` job reports `failure` in `jobs[].conclusion` | Read step outcomes and the evidence bundle instead (task 7) |
| A5 | Splitting rows by surface is acceptable to the v1.48 lint | Rows only share the schema in D-13; merging rows later is mechanical |
| A6 | Pending in "Pending, 1 job pending" is acceptable | Maintainer veto: change P-1 to a neutral count and update one row |

## Environment availability

| Dependency | Needed by | Available | Notes |
|------------|-----------|-----------|-------|
| Elixir 1.19 / OTP 28 | all ExUnit | yes, with the two `ASDF_*` variables exported | |
| Postgres | ScrypathOps tests | yes (`pg_isready` accepting on port 5432) | |
| Node and `node_modules` in `examples/scrypath_ecommerce` | Playwright `--list`, node tests | yes | `npm ci --ignore-scripts` with `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1` if missing |
| `gh` | dispatch, run inspection | yes | authorized |
| Docker | none required in this phase | running (other projects' containers present) | no local e2e run is planned; if one is wanted, follow AGENTS.md Docker cleanup |
| Demo Mix dependencies | `page_controller_test.exs` | not fetched | task 6 |

## Sources

### Primary (verified today)
- Repository files read: `AGENTS.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, gap-pass `E`, `F`, `H`, prep `A`, `V1.46-PREP.md`, `GLOSSARY.md`, `OPERATOR-UI-QUALITY.md`, the Brand playbook rows T9, T17, W4, W13, `187-REVIEW.md` (IN-01, IN-02), `CONTRIBUTING.md:238-260`, `.github/workflows/ci.yml`, `scrypath_ops/lib/scrypath_ops_web/**` (the files in D-03 to D-11), `scrypath_ops/test/**` (the files in D-12 and D-22), `examples/scrypath_ecommerce/e2e/**` (the files in D-11 and `operator.spec.ts`, `harness.spec.ts`), `scripts/ci/ecommerce_lifecycle.test.cjs`, `test/mix/tasks/workflow_wiring_test.exs`, `mix.exs`, `docker-playwright.sh`.
- Commands run: `git grep` (counts, per-file occurrences, string cites), `gh run view 44689855947`, `gh run list`, `git log bd69905e..origin/main`, the checks in the table above.
- Archived format examples: `.planning/milestones/v1.46-phases/186-ingest-pin-and-guard/186-{CONTEXT,RESEARCH,DISCUSSION-LOG}.md` and `~/.claude/gsd-core/templates/context.md`.

### Secondary / tertiary
- None. No external web source was needed: every open question was answerable from the repository.

## Metadata

**Confidence breakdown:**
- Inventory and coupling: HIGH (all re-verified).
- Table and test design: MEDIUM (design recommendations, tasks 1 to 5 settle them).
- CI wiring: HIGH for current state, MEDIUM for the merge order with 188.1, 189 and 191.

**Research date:** 2026-11-20
**Valid until:** 2026-11-27 (the tree is moving: 188.1, 189 and 191 are being pre-seeded and will edit `ci.yml`, `CONTRIBUTING.md` and `workflow_wiring_test.exs`)
