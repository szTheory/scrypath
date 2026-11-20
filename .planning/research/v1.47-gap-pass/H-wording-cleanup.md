# v1.47 gap pass H: Phases 190 (wording) and 191 (cleanup)

Checked 2026-11-20 against `main` at 27a3cbed (read-only; one cheap `node --test` run of `ui-tokens.test.mjs`: 59 tests, all green; one `gh run view` of the 11-20 nightly). Severity: blocker, should-fix, nit. Line numbers are from today and drift.

## Verdict on the prep notes

| Claim | Today | Holds? |
|-------|-------|--------|
| Allowlist has 7 entries and 201 hits (`ALLOWLIST_CEILING` 7, `HITS_CEILING` 201) | Entries 7; max_hits 2+2+177+1+15+1+3 = 201; `ui-tokens.test.mjs:68,72` | Yes |
| Token test floor `@min_token_test_calls 53` | 53 `test("...",` calls (59 node tests; the rest are loop-generated) | Yes, floor equals today's count exactly |
| "Prep A: exact grep over `.ts` found no e2e spec pinning old casing" | `Control Room` appears 54 times in 28 non-planning files; 12 are e2e files (11 `.ts`, 1 `.mjs`) plus `scripts/ci/ui_preservation.test.cjs` | **No** (see H-1) |
| "9 or 10 occurrences / 10 files mention Control Room" | 10 files is only ops lib+tests+one ecommerce test. Rendered literals in ops lib: 6 (`layouts.ex:320` x2, `ops_ui.ex:1717`, `control_room_live.ex:17` and `:86`, `sync_drift_live.ex:2438`); comments 5 | Partly (undercount of the real blast radius) |
| `sync_drift_live.ex:1724` is the Searchable tuple | Now `:1734` | Drifted |
| D numbers for ceilings 6/198, 4/182, 2/4 per commit | Assume the two `p189` entries still exist. After Phase 189 the start is 5/197 | **Wrong at 191 time** (see H-6) |
| `mix.exs` `verify.ui_tokens` is an alias | `mix.exs:100` is a `preferred_envs` entry (`"verify.ui_tokens": :test`), not an alias | Wording nit |
| Static invariants (floor, arbitrary sizes, uppercase, infinite) are green today | Yes on source (H-9) | Yes |
| ledger 8 of 12; wiring test fails on >12, empty cell, missing file | Yes, plus more constraints (H-11) | Yes, incomplete |
| 11-20 nightly result | Run 44689855947 on bd69905e: `ecommerce-e2e (advisory)` success; `deep-quality` failure (known sigra/cloak); `ops-ui` skipped | Free baseline: all advisory browser specs are green before the rename |

---

## COPY-01 / COPY-02 (Phase 190)

### H-1 (should-fix, large) The real rename list is 28 files, and exact-match e2e specs will break silently on the nightly

Playwright `getByRole(..., {name: "Control Room"})` is a case-insensitive substring match, so most specs keep passing after the rename, but these do not (all advisory, so the required lane will not notice):

- `examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts:55` heading, used with `exact: true` at `:201`.
- `examples/scrypath_ecommerce/e2e/ops_reskin_contract.spec.ts:57` heading, used with `exact: true` in `gotoPath` at `:913` (called for `SCREENS[0]` at `:938`, `:1019`, `:1195`, `:1363`); this takes the whole P-01..P-21 computed-style suite for the Control room route down.
- `examples/scrypath_ecommerce/e2e/ui_routes_preservation.spec.ts:93` (`exact: true`).
- `examples/scrypath_ecommerce/e2e/helpers/ui-preservation-states.ts:194` (`E2: /^Control Room$/`, case-sensitive regex).

Required-lane spec: `operator.spec.ts:64` uses the case-insensitive form, so it stays green but still counts for the COPY-02 scan.

Complete COPY-02 change list (case-sensitive `Control Room` to `Control room`; keep `control-room-*` test ids and `:control_room` atoms):

- Rendered code (6): `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex:320` (label and title), `components/ops_ui.ex:1717` (command palette label), `live/control_room_live.ex:17` (`page_title`) and `:86` (h1), `live/sync_drift_live.ex:2438` ("Return to Control room").
- Comments (5): `ops_ui.ex:560,629,691`, `posture.ex:182`, `assets/css/app.css:27`.
- Ops tests (5): `control_room_live_test.exs:64`, `sync_drift_live_test.exs:1457`, `router_test.exs:148`, `reskin_component_contract_test.exs:426` (comment), plus the new guard.
- Ecommerce: `test/scrypath_ecommerce_web/controllers/page_controller_test.exs:55`, `lib/mix/tasks/scrypath.demo.seed.ex:195` ("OPSUI at /admin/search/ (Control Room)").
- E2E (12 files): `admin_path_motion` (4), `admin_screenshot_matrix:132`, `admin_screenshots:41`, `admin_shell_chrome` (3, incl. `:510` map key), `admin_shell_wash:55`, `helpers/theme-grid.ts:47`, `helpers/ui-preservation-states.ts` (9: one regex, eight assertion names), `operator.spec.ts:64`, `ops_reskin_contract.spec.ts` (3), `phase1_screens.spec.ts` (2), `ui_routes_preservation.spec.ts:93`, `ui-review.selftest.mjs:436`.
- CI fixture: `scripts/ci/ui_preservation.test.cjs:226` (`links: ["Control Room", "Search"]`).
- Docs: root `DESIGN.md:23,41`, `scrypath_ops/assets/css/DESIGN-TOKENS.md:225,243,587`, `scrypath_ops/docs/operator-ia.md:14,18`.
- Already sentence case (leave): `GLOSSARY.md:31`, demo `Makefile:99`, `README.md:179`, `docker-entrypoint.sh:35`, `docs/local-demo-docker-dx.md`, `reskin_static_contract_test.exs:107`.
- `brand/` has zero hits (it is hash-pinned and must stay exempt from the scan).

Proposed requirement wording (replace COPY-02): "The label 'Control room' renders in sentence case in the page title, navigation (sidebar, mobile drawer and command palette), the h1 and the 'Return to Control room' link; a case-sensitive scan of `scrypath_ops/{lib,test,docs,assets/css}`, root `DESIGN.md`, `examples/scrypath_ecommerce/{lib,test,e2e,scripts}` and `scripts/ci` finds no `Control Room`, and every Playwright locator that matches the label with `exact: true` or a case-sensitive regex is updated."

### H-2 (should-fix) Hidden coupling: nav title and `page_title` must change together

`layouts.ex:317` `nav_item_active?(item, page_title)` is `item.title == page_title`. Renaming `control_room_live.ex:17` without `layouts.ex:320` (or the reverse) silently drops `aria-current="page"` on the Control room nav item. No ExUnit test asserts `aria-current` (the only checks are advisory e2e: `admin_shell_chrome.spec.ts:296`, `ops_reskin_contract.spec.ts:339`).

Proposed criterion: "A LiveView test asserts the Control room nav link carries `aria-current="page"` on `/ops` and the `<title>` starts with 'Control room'." The label also lives in two places (`layouts.ex:320` and `ops_ui.ex:1717`); pick one source (nit) or let the table test both.

### H-3 (should-fix) Negative assertions go vacuous after the wording change

These `refute` lines pass trivially once the old string is gone, and one already refutes a string that is not in lib:

- `control_room_live_test.exs:245` refutes "The last successful observation is retained below" (not in lib today; the lib text is "The last complete observation is retained below", `control_room_live.ex:109`).
- `control_room_live_test.exs:246-247` refute "Last successful observation" and "Last successful check:".
- `posture_live_test.exs:740` refutes `Last success</dt><dd>—`.
- `failed_sync_live_test.exs:654,823` refute "Retry queued" (fine only while that string is kept).

Proposed criterion: "Every `refute` of a renamed string is replaced by a refute of the old string plus an `assert` of the new one on the same fixture." The COPY-03 table gives this for free if each rule has both a forbidden and a required cell evaluated on the same surface.

### H-4 (should-fix) COPY-01 is under-specified: the Pending/Queued rule lives only in a prep note, and some strings need an owner decision

Evidence: `GLOSSARY.md` has no Pending, Queued, Retry queued or Last succeeded entry (only "Control room", "Document visibility", and Meilisearch task "accepted", line 77). The rule text is one sentence in `V1.46-PREP.md` D10. COPY-03's "rule" column has nothing durable to cite.

Proposed: Phase 190 plan 1 first adds a "Status wording" block to `GLOSSARY.md` (Searchable, Pending, Queued, Retry queued, accepted, Last succeeded, each with Avoid terms), and each table row cites the entry.

Exact current strings the rule touches (all in `scrypath_ops/lib/scrypath_ops_web/live/` unless noted), with the proposed target and the test that pins it today:

| Rule | Current text (file:line) | Proposed | Pinned by |
|------|--------------------------|----------|-----------|
| Searchable | `sync_drift_live.ex:1734` tuple `{"Searchable fields", "Searchable", "Not searchable", "Not searched yet."}` | `"Used for search"`, `"Not used for search"`, effect `"Not used for search yet."` (owner call on the effect sentence) | `sync_drift_live_test.exs:523,524` |
| Sibling rows (same tuple list) | `"Filterable"`, `"Not enabled for filtering"`, `"Sortable"`, `"Not enabled for sorting"` | Decide: leave (rule only names Searchable) or align to "Used for filtering/sorting". Say which in the plan so the table does not flag them | none |
| Last succeeded | `control_room_live.ex:146` label "Last successful observation"; `:177` "Last successful check:"; `sync_drift_live.ex:1994` "Showing the last successful check below." | Owner call: label and sentence forms; suggested "Last succeeded" label, "Last succeeded: <time>.", "Showing the check that last succeeded below." | `control_room_live_test.exs:218,223,326` |
| Last succeeded | `posture_live.ex:443,500` `<dt>Last success</dt>`; `:610-611` "Meilisearch last success", "Queue last success" | "Last succeeded"; "Meilisearch last succeeded"; "Queue last succeeded" | `posture_live_test.exs:167,739,740` |
| Last succeeded (already conformant) | `posture_live.ex:707`, `lib/scrypath/cli/operator_task.ex:139,144` | none | `posture_live_test.exs:387,390` |
| accepted = Meilisearch task only | `failed_sync_live.ex:319` "A retry for job N is already accepted."; `:351` flash "Retry accepted . queue job N"; `sync_drift_live.ex:579` "Retry accepted"; `:599-601` "The queue accepted this retry"; `:2153` "observes the accepted operation"; `help_live.ex:123` "Acceptance alone does not confirm recovery" | Host queue outcomes become "queued" ("A retry for job N is already queued", "Retry queued . queue job N", "Retry queued", "The queue has this retry"). Keep "Index swap accepted" (`:1602`, `:2364`) and `help_live.ex:79`: those are Meilisearch task states and already conform | Only `failed_sync_live_test.exs:704` ("already accepted") and `sync_drift_live_test.exs:1067` ("Index swap accepted", keep). "Retry accepted" and the flash have no test at all |
| Pending vs Queued | `sync_drift_live.ex:1653` "N jobs queued"; `:1703` "Nothing queued, retrying or failed."; `:1560` "wait for queued work to finish" | Ambiguous under the rule (aggregate means Pending). Decide explicitly; tests pin both (`sync_drift_live_test.exs:304,322`) | those two |
| Pending status word | `ops_ui.ex:1967`, `posture_live.ex:425,477,686,694,701` | Already Pending | `ui_followup.spec.ts:71-73` (nightly) |

Strings that must NOT change because the required lane pins them (`operator.spec.ts`, `ecommerce-mounted`): "Failed sync work refreshed." (`:144`), `Original job #N is retained` (`:151`), `Oban job #N` and `attempt N` regexes (`:153,155`), "Check sync status" (`:166`), "Recovery verified" (`:177`), `Queue job N` (`:185`), "Index swap completed" (`:332`), "Effect: replace live index contents and settings with the prepared target." (`:273`), "Check sync and settings", "Try a search" (`:72-73`), `Confirm index promotion` dialog name (`:267`). Add this protected list to the plan.

The first clause of the rule ("bare Searchable only for a record or update state with an observation time") guards nothing today: the only capitalised "Searchable" in ops lib is the settings tuple. Make it a forbidden-text row anyway: forbidden case-sensitive `Searchable` except the label `Searchable fields`.

Owner-decision note (AGENTS.md: resolve subjective choices before implementation): the "Last succeeded" label/sentence forms and the effect sentence are visible wording. Resolve them in discuss and list the final strings in the plan; "one batched yes" in prep A is not a verification gate under the repo's rules.

### H-5 (should-fix) Tests that read the copy but are not in any required lane

- `examples/scrypath_ecommerce/test/.../page_controller_test.exs:55` (`html =~ "Control Room"`): the ecommerce ExUnit suite is not run by `ecommerce-mounted` (that lane runs `harness.spec.ts` and `operator.spec.ts` only), not by `ops-ui`, and not by `phoenix-example`. I found no required lane that runs it. It will fail only when someone runs the README command (`README.md:306`) or `mix test examples/scrypath_ecommerce/test/...` (delegated by `mix.exs:156-160`).
- Advisory e2e: the four exact-match sites in H-1, plus `ui_followup.spec.ts` (Pending).

Proposed criterion (replaces the "one local run of the ordinary e2e partition" wording): "Before the PR is marked ready, run the changed ecommerce ExUnit files (`mix test examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/page_controller_test.exs`) and dispatch `ci.yml` on the exact PR head so `ecommerce-e2e (advisory)` runs the full spec set; record both run ids." This replaces a local Docker run with the v1.46 practice already in the prep (hosted, exact head, 1394 s measured). The 11-20 nightly is green, so any red afterwards is attributable to the change.

### H-6 (see Phase 191 below for ceiling arithmetic)

### H-7 (should-fix) COPY-03 is a gate-budget event and its scan scope falls outside the `ops-ui` path filter

Evidence:
- `ci.yml:367` runs `ops-ui` only when changed files match `^(scrypath_ops/|lib/|dev/|config/|priv/|brand/|brandbook/|language/|fixtures/|scripts/ci/|test/release/|mix\.exs|mix\.lock|\.github/workflows/ci\.yml)`. `examples/`, `GLOSSARY.md` and `DESIGN.md` are not in it. A PR that edits only an e2e spec back to `Control Room`, or edits `GLOSSARY.md`, skips the guard (on push to `main` it runs, so it is caught after merge).
- `verify.ops_ui` runs the root boundary test and `mix test` in `scrypath_ops`; it can read `../examples` (the re-skin static test already reads `@repo_root` brand files) but only when triggered.
- A new table test in `scrypath_ops/test` is a required gate. The ledger counts rows, and today "ScrypathOps re-skin component contract" (row 258, `ops-ui`) is the nearest. Prep A proposed extending that file; its deletion trigger still says "when the ops component catalog contract replaces it in v1.47", which is stale (catalog moved to v1.48).

Proposed criteria:
- "The copy table is `scrypath_ops/test/support/copy_rules.json` (language-neutral: `id`, `rule` text, `glossary` entry, `forbidden` (list of `{text, match: literal|regex, case: sensitive|insensitive}`), `required` (same), `allowed_in` (exact phrases that excuse a forbidden hit, e.g. 'Index swap accepted'), `source_scope` (globs) and `surface` (a named existing LiveView fixture state)). One ExUnit test loads it, scans `source_scope` for `forbidden`, and renders each `surface` and asserts `required` and the absence of `forbidden`. A planted forbidden string in a scoped file and on a rendered surface each fail it."
- "Static (`source_scope`) checks cover forbidden text; rendered `surface` checks cover required text. State-dependent strings (for example the refresh-issue label) are reached by naming the existing test fixture state, not by a route alone."
- "The ops-ui path regex gains `examples/scrypath_ecommerce/e2e/` and `GLOSSARY.md` and `DESIGN.md` (and `workflow_wiring_test.exs:1297` adds them to its directory list), or the scan scope is limited to paths that already trigger `ops-ui`. State which."
- "CONTRIBUTING gets a ledger row for the table test (or names the existing row it extends) with a deletion trigger and expected churn; `Budget used: N of 12.` equals the row count on `main` at planning time (189 may already have added one)."

---

## COPY-04 (Phase 190)

### H-8 (should-fix) Put the Cancel-focus assertion in the required lane, not a new nightly spec

Evidence: `operator.spec.ts:267-268` already opens the destructive "Confirm index promotion" dialog in `ecommerce-mounted` and asserts the successor attribute. One added line there, `await expect(confirmation.getByRole("button", { name: "Cancel", exact: true })).toBeFocused()`, adds no lane time and is shifted left. `ops_modal` defaults `initial_focus` to `[data-ops-modal-cancel]` (`ops_ui.ex:1563`) and the hook reads `data-ops-modal-initial-focus`; the other two destructive dialogs are `failed_sync_live.ex:1208` and `search_live.ex:1738`.

Proposed criterion: "In `operator.spec.ts` the promotion dialog's Cancel button is focused when it opens; ExUnit pins `data-ops-modal-initial-focus="[data-ops-modal-cancel]"` as the `ops_modal` default and on each destructive dialog, and pins the promotion-notice body copy. Prep D's 'nightly/dispatch lane' placement is superseded."
Note: the promotion-notice copy fix is the `upcase_first(promotion_reason(...))` path at `sync_drift_live.ex:1574-1586`; pin exact output sentences for each `promotion_reason/1` clause.

---

## Phase 191 (cleanup)

### H-6 (should-fix) Ceiling arithmetic: 191 starts from 5 entries / 197 hits, not 7 / 201

Allowlist today: 2 `p189` entries (2+2), brandbook prefix 177, `ui_tokens.ex` 1, contract test 15, `ci.yml` 1, demo favicon 3. After Phase 189 removes the `p189` entries: 5 / 197. Correct chain:

| Commit | Removes | Entries | Hits (`HITS_CEILING`) |
|--------|---------|---------|------------------------|
| start of 191 | | 5 | 197 |
| 1 favicon | favicon entry (3) | 4 | 194 |
| 2 readers | `ui_tokens.ex` (1), contract test (15) | 2 | 178 |
| 3 data | `brandbook/` prefix (177), `ci.yml` (1) | 0 | 0 |

(Prep D's 6/198, 4/182, 2/4 assume the `p189` entries are still present.) CLEAN-03 text "7 entries and 201 hits today" is correct as of today but 191's plan must recompute from `main` after 189 lands. Proposed CLEAN-03 wording: "...removed in the same commit as their ratchet ceilings (`ALLOWLIST_CEILING` and `HITS_CEILING` end at 0 and 0; the intermediate values are computed from `main` after Phase 189)".
The checker tolerates an empty allowlist (`checkAllowlist` has no non-empty assumption; `ui-tokens.test.mjs:1010-1017`, `:1062-1073`); the "stale allowlist entry" rule (`:1050`) is why each entry must go with its deletion.

### H-10 (blocker-if-missed, easy) The retired-directory tripwire will flag new docs

`RETIRED_DIR` (`ui-tokens.test.mjs:808`) is scanned case-insensitively in every tracked, non-exempt file (exempt: `.planning/`, `brand/BRAND.md`, `brand/brand.json`, the allowlist file). Once the allowlist is empty, any CLEAN-02/03/06 documentation in `CONTRIBUTING.md`, `DESIGN-TOKENS.md`, `docs/` or a code comment that writes the old directory name with a trailing slash fails the final commit. Likewise new test text must build the name at runtime (as `brand_pin_contract_test.exs:859` does).

Proposed criterion: "Phase 191 docs name the retired book as 'the retired brand book directory' and never spell the path; the final commit passes the deny-list with zero allowlist entries."

### H-11 (should-fix) Ledger and `workflow_wiring_test` constraints, stated accurately

`workflow_wiring_test.exs:1351-1417` enforces: the header is exactly `Gate | Enforced by | Runs in | Deletion trigger | Expected churn per UI PR`; 1 to 12 rows; each row has exactly five cells (a `|` inside a cell breaks it, so reworded triggers must not contain a pipe); no empty gate/runs-in/trigger/churn cell; the first backticked path in "Enforced by" exists; the budget line is exactly `Budget used: <rows> of 12.`; and five rows are mandatory by file (`@phase_186_gate_files` lines 620-626: `brand_pin_contract_test.exs`, `ui-tokens.test.mjs`, `workflow_wiring_test.exs`, `dependency_boundary_contract_test.exs`, `ui_state_pairs.test.cjs`). So the token row cannot be deleted by rewording, and the roadmap's "literal conditions are met, so reword" must not leave a deletable-looking trigger.

Today's row text (`CONTRIBUTING.md:252`): "Delete the deny-list half once the allowlist holds no `retire-last` entries; delete the parity half once the token map has no pending rows" and churn "...the allowlist only shrinks". After 191 both conditions are literally true and the churn clause is stale. Also stale and related: the budget sentence (`CONTRIBUTING.md:247`) names only v1.46; row 258's trigger says the catalog replaces it "in v1.47"; row 251's churn ("None unless brand assets change") becomes wrong once the favicon tripwire fails on the refresh that picks up an upstream favicon fix.

Proposed CLEAN-06 wording: "The token and deny-list row states that the deny-list and directory tripwire are permanent (deleted only if `brand/` stops being vendored), that the parity half is permanent while `app.css` is a hand-kept projection of `brand/tokens.json` (the single token authority), and that churn is one token-map row per theme property; the budget sentence names v1.47; row 258's trigger says v1.48 or later; row 251's churn names the favicon tripwire; `workflow_wiring_test` stays green and `Budget used` equals the row count."
Timing: the reword can only claim "no retire-last entries" in the commit that empties the allowlist; put CLEAN-06 in the same or a later commit than commit 3, not before.

### H-12 (should-fix) Snapshot gate: what reads HEAD and what reads the working tree

`ui_contrast_contract_test.exs:346` (`copy_repository/0`) does `git clone --shared` of committed HEAD, then overwrites only five working-tree files (itself, `ui_literal_contract_test.exs`, `verify.phase99.ex`, `contrast-checker.mjs`, `contrast-pairs.mjs`) and runs `mix verify.repository_contracts` in the clone. So:
- The clone runs HEAD's `ui-tokens.test.mjs`, allowlist, `ci.yml` and `brandbook/`, but the working tree's `ui_contrast_contract_test.exs` and `verify.phase99.ex`. CLEAN-04 raises `@min_token_test_calls` in the wrapper; an uncommitted floor raise runs against HEAD's older token test inside the clone. The mutation tests still pass (they only require failure), but they pass for the wrong reason, which is the stale-input hazard AGENTS.md describes. Rule: commit the new token tests and the floor raise together before the snapshot gate.
- `ui_tokens_contract_test.exs:795` (deleted in commit 2) is the second clone-based test; after commit 2 only the contrast one remains.
- Lost coverage worth recording: the deleted test is the only place that asserts a clean clone passes `verify.repository_contracts` (`clean_status == 0`, `ui_tokens_contract_test.exs:456`). The contrast child tests assert only `status != 0` and never prove the unmutated clone is green, so a clone broken for an unrelated reason makes them pass vacuously. Proposed (nit to should-fix): add a baseline `status == 0` assertion to one contrast child test, or record in the 191 plan that the hosted `repository-contracts` run on the exact head is the accepted replacement.
- Per-commit protocol from the roadmap holds: focused checks (`node --test examples/scrypath_ecommerce/ui-tokens.test.mjs`, about 1.5 s; wiring, phase99 and contrast tests), commit, then `mix verify.repository_contracts` once on the committed state. Measured cost of that gate is about 206 s plus the Node step; 3 commits means 3 runs, which is the stated GATE-02 "one full gate run per commit SHA".
- Phase 189 and 191 both edit `ALLOWLIST_CEILING`, `HITS_CEILING`, `@min_token_test_calls` and the allowlist file; sequential PRs (no stacking) make this safe, but 191 must rebase and recompute the chain from merged `main`.

### H-13 (nit) `mix.exs` entry and Phase 99 list

Requirement CLEAN-02 says "the `verify.ui_tokens` mix alias". It is a `preferred_envs` line (`mix.exs:100`). Say "the `preferred_envs` entry". Also remove `test/mix/tasks/ui_tokens_contract_test.exs` from `@focused_tests` (`verify.phase99.ex:13`); `verify.phase99_test.exs:26-34` does not name it, so no test edit is needed there. `Scrypath.TestSupport.UiTokens` (test/support) stays: the contrast test uses it.

### H-14 (should-fix) CLEAN-01 pin location

The demo favicon is `examples/scrypath_ecommerce/priv/static/favicon.svg` (981 bytes, 3 retired hits) and is linked from `layouts.ex:25` for non-admin routes. Pin it in a root-level `test/` file (runs in `core` on every PR) rather than in the ops-ui lane: `ops-ui-path` does not include `examples/`, so a PR changing only the demo favicon would not run an ops-ui test. The demo's own ExUnit suite is not in a required lane (H-5), and root tests do not run in Docker, so the Docker build context (repo root; `.dockerignore` does not exclude `brand/`) is not a constraint for a root test.
Proposed CLEAN-01 wording: "A root-level ExUnit test in `core` asserts `examples/scrypath_ecommerce/priv/static/favicon.svg` is byte-identical to `brand/assets/icon/favicon-light.svg`; the demo's own `page_controller_test.exs` keeps comparing the served file to its priv copy."

### H-9 (nit with details) CLEAN-04 static invariants: green today, with specific false-positive traps

Run against source today: 90 `font-size` lines in `scrypath_ops/assets/css/app.css`; `--text-ops-xs` and `-sm` are `0.75rem` (`app.css:250-251`), body `0.875rem`; one literal `0.875rem` (`:1093`); `inherit` at `:2200,:2231`; `font: inherit` at `:418,2154,2280`. Zero `text-[` arbitrary sizes, zero `uppercase`/`text-transform`, zero `infinite` in `scrypath_ops/lib`, `assets/js`, `assets/css/app.css`. All four invariants pass on today's source.

Traps:
- Scan scope must be source only: `lib/**/*.{ex,heex}`, `assets/js/*.js` (not `vendor/`), `assets/css/app.css`. The tracked built file `priv/static/assets/css/app.css` has 3 `infinite` (daisyUI `progress`, `skeleton`), `font-size: 80%` and `75%`, and daisyUI `btn-xs` at 11 px; `assets/vendor/daisyui.js` has `infinite` too. Scanning them fails today.
- Case-insensitive `uppercase` would match nothing today, but `/infinit/i` would match `:infinity` (`result_ui.ex:50-51`, `search_live.ex:1244-1245`). Match `\binfinite\b` as a whole word, and `uppercase` as a CSS declaration (`text-transform:\s*uppercase`) or a class token (`(?<![\w-])uppercase(?![\w-])`), not substrings (`upcase_first` is fine).
- Prose in comments and docstrings that says "no uppercase" or "infinite" would trip a text scan once someone writes it; strip comments (`/* */`, `#`, `<%!-- --%>`, `//`) or scope the class check to `class=` attributes and CSS declarations.
- The floor resolver must resolve `var(--text-*)` chains and treat `inherit`, `1em`, `100%` as pass but `%`/`em` below 100 as fail (the built CSS shows daisyUI does emit them). Fail closed on `calc(`/`clamp(` with a clear message, or resolve them.
- `text-[...]` also forms colors and lengths: match only `text-\[(\d|calc|clamp|length:|min|max)` so `text-[var(--color)]` is not a false positive.
- Known hole to state in the docs line: `button_classes/2` (`ops_ui.ex:1854`) emits daisyUI `btn-xs` (11 px) for `size: :xs`; zero callers pass it today. Add a cheap invariant: "no ops source passes `size={:xs}` / `size: :xs`" (green today), or document as browser-only.
- Wrapper bookkeeping: new tests must use literal `test("...", ` at line start to be counted; raise `@min_token_test_calls` (53) by the number added in the same commit (H-12) and add the new "live ..." names to `@token_test_names` so renaming them cannot pass on count alone.
- Demo host CSS (`examples/scrypath_ecommerce/assets`) is outside "ops-authored source"; say so.

Proposed CLEAN-04 wording: "`ui-tokens.test.mjs` asserts, on ops-authored source only (`scrypath_ops/lib`, `scrypath_ops/assets/js` excluding `vendor/`, `scrypath_ops/assets/css/app.css`; never built CSS or vendor files): every resolved `font-size` is at least 12 px with percent, em, calc and clamp values rejected; no `text-[` length arbitrary value; no `uppercase` class or `text-transform: uppercase`; no whole-word `infinite`; no `size: :xs` caller. Each has a planted failing case, an accept case that includes a comment, an `:infinity` atom and an `inherit` value, adds no gate, and `CONTRIBUTING.md` says these check source declarations, not rendered size."

### H-15 (should-fix) CLEAN-05 favicon scan: feasible, but 'uses it' must be defined by bytes, not by name

Today: no tracked file outside `brand/` and the retired book is byte-identical to `brand/assets/icon/favicon.svg` (sha256 16a86401...; 891 bytes; checked over all tracked files) and the only text references to `icon/favicon.svg` outside `brand/` are `dev/mix/tasks/brand/update.ex:84` (the pin updater; legitimate) and, after this phase, the test itself.

A scan for the bare string `favicon.svg` is a false-positive machine: ops (`reskin_static_contract_test.exs:57`), the demo (`layouts.ex:25`, `page_controller_test.exs`), `scrypath_ops/priv/static/favicon.svg` and the website all serve a file NAMED `favicon.svg` whose bytes are `favicon-light.svg`. The consumer check that works:

1. Path reference: no tracked file outside `brand/`, `.planning/` and an explicit allowlist (`dev/mix/tasks/brand/update.ex`, the test file itself) contains `icon/favicon.svg`. The variants (`favicon-light.svg`, `favicon-dark.svg`, `favicon.ico`, sized files) do not match.
2. Byte reference: no tracked or untracked-not-ignored file outside `brand/` has the same sha256 as the pinned `favicon.svg` (catches a copy under any name).
3. Built output: website build output is not tracked, so the Phase 189 static contract (which builds into a temp dir) owns it. CLEAN-05 should say that explicitly to avoid a double claim; 189's criterion 1 ("no file references the unthemed `favicon.svg`") should be scoped to the built site and CLEAN-05 to the repository.

Tripwire definition: the pinned `favicon.svg` has neither `<style`, `fill=`, `currentColor` nor `prefers-color-scheme`. The failure message must name the workarounds to unwind: `mix.exs:294-298` comment and ExDoc favicon, `package_metadata_test.exs:411,433`, `reskin_static_contract_test.exs:56-57`, the demo favicon (CLEAN-01), `docs/releasing.md:29`. It fires on the `mix brand.update` that picks up an upstream fix, which is intended; the ledger churn text for row 251 should say so.

Where it should live: the tripwire in `test/mix/tasks/brand_pin_contract_test.exs` (row 251, `core`, hash-guarded, reads only `brand/`). The scan in `examples/scrypath_ecommerce/ui-tokens.test.mjs` because it already has `listRepoFiles` (tracked plus untracked, so a new untracked consumer is caught pre-commit), the exempt-path set, binary handling and the `makeTree` planted-fixture helper, and runs in both `core` and `repository-contracts`; the byte comparison is a few lines. Alternatively the same file as the tripwire using `git ls-files`. Do not put either in the ecommerce Mix project or an ops test: the ecommerce suite is in no required lane (H-5), ops-ui is path-scoped without `examples/`, and a Docker-side check has no `.git`. The Docker context is repo root and includes `brand/` (`.dockerignore` does not exclude it), so reading `../../brand` works there, but nothing needs it.

Proposed CLEAN-05 wording: "A test in `core` fails if the pinned `brand/assets/icon/favicon.svg` gains a `<style`, `fill=`, `currentColor` or `prefers-color-scheme` (the message lists the workarounds to remove). A scan in `ui-tokens.test.mjs` fails if any file outside `brand/`, `.planning/` and `dev/mix/tasks/brand/update.ex` contains the path `icon/favicon.svg` or has the same bytes as it; each has a planted failing case (a text reference and a renamed byte copy) and an accept case (`favicon-light.svg` served under the name `favicon.svg`). The upstream report is linked from the phase record; it is not a gate."

Upstream report: still unfiled per prep D (no record found); ask the owner or file it from the plan with the wording in prep D item 5. It needs the maintainer account, so list it as the one non-automatable step.

---

## Ordering summary

1. 189 (removes the two `p189` entries and lowers 7/201 to 5/197, edits DENY_HEX and the token-test floor) then 190 then 191, no stacking: fine. Each phase must recompute ceilings and the ledger count from merged `main`.
2. 190 must not run before the glossary rule text exists (H-4); write it first.
3. 191 internal order: favicon, then readers, then data (matches prep D), each with focused checks then one `verify.repository_contracts` on the committed state; CLEAN-04 tests and the floor raise are one commit; CLEAN-06 rewording lands with or after the commit that empties the allowlist.
4. 190's PR edits `examples/` and `scrypath_ops/`: the kickoff chore's `ecommerce-path` classifier must not skip it (the roadmap already says it must not skip on `examples/`); and `ops-ui` runs because `scrypath_ops/` changes.

## Suggested plan checklist additions (one line each)

- Plan 190-01: glossary status-wording block; explicit string-mapping table (H-4) with owner-resolved final wording; copy table (H-7); rename list from H-1 including exact-match Playwright sites; `aria-current` and title test (H-2); replace vacuous refutes (H-3).
- Plan 190-02: run page_controller_test and dispatch `ci.yml` on the exact head (H-5); Cancel-focus line in `operator.spec.ts` (H-8); ledger row and path-regex update (H-7).
- Plan 191-01: favicon byte copy plus root test (H-14); readers; data; ceilings from 5/197 (H-6); docs avoid the retired path (H-10).
- Plan 191-02: static invariants with the trap list (H-9); tripwire and scan (H-15); CLEAN-06 reword including budget sentence and row 258/251 text (H-11); name `brand/tokens.json` as the single token authority in `scrypath_ops/assets/css/DESIGN-TOKENS.md`.
