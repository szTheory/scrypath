---
phase: 190-wording-without-the-catalog
verified: 2026-11-20T22:02:30Z
status: passed
score: 10/10 must-haves verified
covered_files:
  - ".github/workflows/ci.yml"
  - ".planning/phases/190-wording-without-the-catalog/190-01-PLAN.md"
  - ".planning/phases/190-wording-without-the-catalog/190-01-SUMMARY.md"
  - ".planning/phases/190-wording-without-the-catalog/190-02-PLAN.md"
  - ".planning/phases/190-wording-without-the-catalog/190-02-SUMMARY.md"
  - "CONTRIBUTING.md"
  - "DESIGN.md"
  - "GLOSSARY.md"
  - "examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts"
  - "examples/scrypath_ecommerce/e2e/admin_screenshot_matrix.spec.ts"
  - "examples/scrypath_ecommerce/e2e/admin_screenshots.spec.ts"
  - "examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts"
  - "examples/scrypath_ecommerce/e2e/admin_shell_wash.spec.ts"
  - "examples/scrypath_ecommerce/e2e/helpers/theme-grid.ts"
  - "examples/scrypath_ecommerce/e2e/helpers/ui-preservation-states.ts"
  - "examples/scrypath_ecommerce/e2e/operator.spec.ts"
  - "examples/scrypath_ecommerce/e2e/ops_reskin_contract.spec.ts"
  - "examples/scrypath_ecommerce/e2e/phase1_screens.spec.ts"
  - "examples/scrypath_ecommerce/e2e/ui-review.selftest.mjs"
  - "examples/scrypath_ecommerce/e2e/ui_routes_preservation.spec.ts"
  - "examples/scrypath_ecommerce/lib/mix/tasks/scrypath.demo.seed.ex"
  - "examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/page_controller_test.exs"
  - "scripts/ci/ui_preservation.test.cjs"
  - "scrypath_ops/assets/css/DESIGN-TOKENS.md"
  - "scrypath_ops/assets/css/app.css"
  - "scrypath_ops/docs/operator-ia.md"
  - "scrypath_ops/lib/scrypath_ops/posture.ex"
  - "scrypath_ops/lib/scrypath_ops_web/components/layouts.ex"
  - "scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex"
  - "scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex"
  - "scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex"
  - "scrypath_ops/lib/scrypath_ops_web/live/help_live.ex"
  - "scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex"
  - "scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex"
  - "scrypath_ops/test/scrypath_ops_web/copy_rules_contract_test.exs"
  - "scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs"
  - "scrypath_ops/test/scrypath_ops_web/live/failed_sync_live_test.exs"
  - "scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs"
  - "scrypath_ops/test/scrypath_ops_web/live/search_saved_searches_test.exs"
  - "scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs"
  - "scrypath_ops/test/scrypath_ops_web/modal_focus_contract_test.exs"
  - "scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs"
  - "scrypath_ops/test/scrypath_ops_web/reskin_component_contract_test.exs"
  - "scrypath_ops/test/scrypath_ops_web/router_test.exs"
  - "scrypath_ops/test/support/copy_rules.ex"
  - "scrypath_ops/test/support/copy_rules.json"
  - "scrypath_ops/test/support/copy_stubs/control_room.ex"
  - "scrypath_ops/test/support/copy_stubs/failed_sync.ex"
  - "scrypath_ops/test/support/copy_stubs/oban_job.ex"
  - "scrypath_ops/test/support/copy_stubs/posture.ex"
  - "scrypath_ops/test/support/copy_stubs/sync_drift.ex"
  - "scrypath_ops/test/support/copy_surfaces.ex"
  - "test/mix/tasks/workflow_wiring_test.exs"
covered_digest: "v4:sha256:5680f15e14e520455f4266618e81ba5391ed3d993a7e65ed1b39dba30389b3e9"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 190: Wording that does not need the catalog Verification Report

**Phase Goal:** Operators read consistent ScrypathOps screen copy that follows the recorded glossary rules and sentence-case "Control room", each rule guarded by one data table in the required `ops-ui` job that the v1.48 copy lint can ingest unchanged.
**Verified:** 2026-11-20 (code state `f7d59f1c`; HEAD moved to `181ed01f` during verification, a planning-only commit that adds `190-REVIEW.md`; branch `gsd/phase-190-wording-without-the-catalog`, base `origin/main` `08962944`)
**Status:** passed
**Re-verification:** No, initial verification

## Result in plain language

The goal is achieved in the code. The glossary section exists and was committed before any string changed. Every wording change is the one the pre-seed calls name, and none touches a string the required-lane specs pin. "Control room" is sentence case everywhere outside the exempt paths. One JSON table with 14 rows is validated, scanned and rendered by one ExUnit test in `ops-ui`, and it goes red for the right reason when an old string comes back (written contiguously), when a title-case label is planted in a tracked file, or when a row loses a field. The path regex and the ledger match. I re-ran the cheap checks myself and mutation-tested more than 30 cases in a scratch clone.

A concurrent code review (`190-REVIEW.md`, 0 critical, 5 warnings, 3 info) landed while I was verifying. I reproduced WR-01, WR-03, WR-04 and WR-05 myself and confirmed WR-02 from the diff. None of them fails a must-have or a roadmap success criterion, so the status stays `passed`, but WR-01 is a real user-visible side effect of the locked D-06 fix text and the others are real gaps in how tight the guards are. They are under Warnings below with a recommendation.

What is not yet known is by design: the hosted results on the exact PR head (the Cancel-focus line running for the first time in `ecommerce-mounted`, `ops-ui (path-scoped)`, and the exact-head `ci.yml` dispatch). They are listed below as pending-by-design with a command, owner and pass condition in `190-PHASE-RECORD.md`. They are not gaps and not human checks.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | COPY-01 (roadmap SC1): `GLOSSARY.md` carries the Status wording block and each rule is proved on a rendered surface; every string `operator.spec.ts` and `harness.spec.ts` pin is unchanged | VERIFIED | `GLOSSARY.md` ends with `## Status wording` and seven bold terms (Searchable, Pending, Queued, Retry queued, Accepted, Last succeeded, Clear); its commit `a7d8b447` precedes every `scrypath_ops/lib` commit. The `scrypath_ops/lib` diff is exactly the D-03 / D-05 to D-08 / D-10 / D-06 edits and nothing else (read hunk by hunk). I extracted 37 pinned strings from the two required-lane specs: all still in lib except `Close Confirm index promotion dialog`, which is composed from the dialog title at render time, and four template strings. No spec pins any changed string (grep of both specs). Old forms are gone: `git grep` finds none in lib. |
| 2 | COPY-02 (SC2): "Control room" is sentence case in title, nav, h1, palette and return link; case-sensitive whole-tree scan finds no old label; the four exact-match Playwright sites and the `admin_shell_chrome` map key are updated; a LiveView test proves `aria-current`, title and palette | VERIFIED | `git grep -o 'Control Room' -- . ':!.planning' ':!brand' ':!scrypath_ops/test/support/copy_rules.json'` exits 1 with no output. Rename diff: 50 changed-line pairs, each a one-word case change (scripted check of commit `109b334e`). `layouts.ex` label and title, `control_room_live.ex` `page_title` and h1, palette label, `Return to Control room` all changed together. `admin_path_motion`, `ops_reskin_contract`, `ui_routes_preservation` (`exact: true`) and the `E2: /^Control room$/` regex in `ui-preservation-states.ts` all end in the new form; `admin_shell_chrome.spec.ts` name and lookup key moved together. New `/ops` test in `ops_shell_contract_test.exs` passes; setting `page_title` back to the old casing turns it red on the missing `aria-current` (mutation M9). |
| 3 | COPY-03 (SC3, table half): `copy_rules.json` rows `{id, rule, glossary, forbidden, required, allowed_in, source_scope, surfaces}`; one `ops-ui` ExUnit test scans and renders them; planted failures fail; a row with a missing field or empty `surfaces` fails; old `refute`s are repaired | VERIFIED | 14 rows, 14 registered surfaces, each with a state anchor. `copy_rules_contract_test.exs`: 25 tests, 0 failures alone, and in the whole ops suite (546 tests, 0 failures on three seeds). Mutations in a scratch clone (table below): old strings restored in lib went red on the named row and surface; a title-case label planted in `README.md`, `DESIGN.md`, a Makefile and a CI script each went red naming file and line, while the same plant in `.planning/` (exempt) stayed green; deleting a field, emptying `surfaces`, an unregistered surface, a non-term glossary value, an entry without `case`, a typo in `source_scope`, an uncited Status wording term and an unreachable state anchor each went red. Old-string `refute`s are removed from the tests; the only old-phrase text left in tests is concatenated planted input in the contract test, outside every lib-scoped row. The two `Retry queued` refutes in `failed_sync_live_test.exs` remain. The posture failed-row refute was rewritten as `last succeeded</dt><dd>—`; that replacement cannot fail either (nothing renders a dash there, WR-05), but the two `assert ... last succeeded` lines above it do guard the new wording, so the string is covered and only that one negative line is dead. Guards match contiguous strings: a phrase wrapped across lines evades the `forbidden` entries (WR-03). Both are under Warnings. |
| 4 | COPY-03 (SC3, CI half): the `ops-ui-path` regex and `workflow_wiring_test` cover the scanned paths; the ledger row, trigger, churn and budget line are consistent and within 12 | VERIFIED | `ci.yml` diff is one line: `GLOSSARY\.md`, `DESIGN\.md` and `examples/scrypath_ecommerce/(e2e|lib|test|scripts)/` added inside the group, every old alternative kept (including `brandbook/`). Wiring test (89 tests) compiles the pattern the job really greps with and matches seven representative paths, refuses `README.md` and the website index, matches the literal directory of every `source_scope`, and runs a negative control. Mutations W1 to W3 (alternatives removed), W6 (a scope outside the regex) and W4, W5 (budget line and ledger row) each turned it red. `CONTRIBUTING.md` has 10 table rows and `Budget used: 10 of 12.`; row 10 names the contract test as its first backticked path, with trigger and churn; `CI-EFFICIENCY.md` finding 12 records the 386 s measurement, reason, rejected alternative and revisit trigger, and finding 11 now says gate 11 with 10 of 12 used. |
| 5 | COPY-04 (SC4): `operator.spec.ts` asserts the promotion dialog's Cancel button is focused when it opens, in the required `ecommerce-mounted` lane | VERIFIED (assertion present and wired; first hosted execution is pending-by-design) | The only change to the spec besides the heading rename is `await expect(cancel).toBeFocused();` at line 281, between the `confirm` locator (280) and the first `close.focus()` (282); the plan's awk placement check exits 0. `docker-playwright.sh:255` runs `harness.spec.ts` and `operator.spec.ts`, which `ecommerce-mounted` is. `playwright test --list` parses 300 tests in 25 files. The dialog marks `Cancel index swap` with `data-ops-modal-cancel` and `initial_focus="[data-ops-modal-cancel]"`, and `OpsModal.focusInitial` reads that selector. Playwright's `toBeFocused` retries, which covers the hook's queued focus. Whether the browser run passes is the first item under Deferred to ship. |
| 6 | COPY-04 (SC4): ExUnit pins the `ops_modal` default focus selector, each destructive `ops_modal`, the Save search exception, the saved-search delete confirmation's Cancel button, and every promotion-notice sentence; `page_controller_test.exs` passes locally | VERIFIED | `modal_focus_contract_test.exs` pins the default with a planted override that fails the same assertion (mutation M11 red). The Confirm index promotion and Confirm delete sync work pins are in place (`sync_drift_live_test.exs:312`, `failed_sync_live_test.exs:752`; M12 red). The Save search modal is pinned to its name input and not the Cancel default (M13 red); the delete form keeps a Cancel wired to `cancel_row` (inline form, pinned as it is, not converted). The promotion-notice test drives 17 reason and sentence pairs against the 17 `promotion_reason/1` clauses, plus the eligible and nil states, reading the notice element only (M6 and M14 red). The demo test, run in a scratch clone after a cold dependency fetch: 7 tests, 0 failures. |
| 7 | D-01 / D-02: glossary first, every row cites a bold glossary term, and a Status wording term cited by no row fails the table | VERIFIED | Commit order `a7d8b447` (glossary) before `e20a23e6` and later lib commits. `validate/2` rejects a non-term `glossary` (J3) and a Status wording term cited by no row (S1). All seven terms are cited by the real table. |
| 8 | The table is ingestible by the v1.48 copy lint unchanged | VERIFIED | Language-neutral JSON, `version` 1, no code or interpolation. Ids are stable kebab-case, unique, and enforced by `validate/2` (`@id_pattern`, duplicates rejected, `--` variant suffix). All eight row fields are required and unknown fields are rejected. I loaded the file in plain Node: 14 rows, all 14 ids match the pattern, no duplicates, every row has the eight fields and a non-empty `surfaces`, every `glossary` value is a bold glossary term, and every one of the 27 forbidden and required entries compiles under JavaScript with the `u` flag (`(?! fields)` and `\b` are portable). The schema is stated in `190-CONTEXT.md` D-13 and enforced in code by `ScrypathOps.Test.CopyRules.validate/2`; there is no separate schema document next to the file (informational, see notes). |
| 9 | The wording changes stayed inside the pre-seed calls | VERIFIED | The lib diff maps one to one onto the call tables: D-03 (Searchable tuple only; Filterable and Sortable byte-identical), D-05 C-1 to C-6, D-06, D-07 Q-1 to Q-6, D-08 P-1 to P-3, D-10 (six rendered literals and four comments). Kept strings are untouched: `Index swap accepted`, `The backend accepted this swap`, `Index swap was not accepted`, the two `help_live.ex` Meilisearch uses, the `Pending` status word, `Meilisearch tasks waiting`, the retained-observation sentence that says "complete". A scan of lib for `accept` leaves only those, atoms and docs. |
| 10 | GATE-02: one full gate run per SHA, the receipt names the tested SHA and is not stale, no capture or preview refresh, no new dependency, ledger within 12 | VERIFIED | `190-GATE-RECEIPT.md` names `f6c78bd243602701857891dd77332d602a392d3e` with `repository_contracts: pass` and `core: pass`; it records the superseded first round that caught the namespace-fence defect. `git diff --name-only f6c78bd2 HEAD` lists only files under `.planning/` (the receipt, the phase record, the efficiency note, the plan summary and now `190-REVIEW.md`), so the receipt is not stale. No `mix.exs`, `mix.lock`, `package.json` or lockfile change, no `.planning/UI-PREVIEW.json`, `config.json` or `state.json` in the phase diff. Budget 10 of 12. I did not re-run the two long gates (instructed; they ran once on the tested SHA). |

**Score:** 10/10 truths verified (0 present-but-behavior-unverified)

### Deferred to ship (pending by design, not gaps, not human checks)

Each has a command, owner and pass condition in `190-PHASE-RECORD.md` (Post-ship evidence). The orchestrator fills the empty Result cells in a planning-only commit after the merge.

| # | Item | Why it cannot exist yet | Pass condition (from the record) |
|---|------|-------------------------|----------------------------------|
| 1 | `ecommerce-mounted` on the exact PR head, including the new `expect(cancel).toBeFocused()` line running for the first time | needs the pushed head | `completed` and `success` with `head_sha` equal to the PR head |
| 2 | `ops-ui (path-scoped)` on the exact PR head: first hosted run of the table's `git ls-files` scan, and of `test/release/ops_dependency_boundary_test.exs` against the new test support files | needs the pushed head | `completed` and `success` on the PR head |
| 3 | Exact-head `ci.yml` dispatch: `ecommerce-e2e (advisory)` conclusion `success`, run id and the PR's own run id recorded | needs the pushed head | `headSha` equals the PR head; on red, compare with the clean baseline first |
| 4 | Content landed on `main` and the post-merge push run's `ops-ui` | needs the merge | empty diff, count command exits 1, `ops-ui (path-scoped)` success on the merge commit |
| 5 | Required contexts `core`, `package`, `repository-contracts`, `backend` on the exact head | needs the pushed head | all `success` with matching `head_sha` |

I independently confirmed the one baseline cell that is already filled: `gh run view 44805847191` reports `workflow_dispatch` on `main`, `headSha` `089629441b416103b81c29e716a79bf01aab41e0`, completed with success, `ecommerce-e2e (advisory)` success from 19:50:41 to 20:12:41 UTC (1320 s), and `deep-quality (advisory)` failure (the known sigra and cloak cause).

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `GLOSSARY.md` | Status wording section, seven entries | VERIFIED | seven bold terms, existing entry format, no old label |
| `scrypath_ops/test/support/copy_rules.json` | 14 rows, `version`, `exempt_paths`, `not_covered` | VERIFIED | parses in Node; rows validated by `validate/2` |
| `scrypath_ops/test/support/copy_rules.ex` | pure helper shared by the real and planted tests | VERIFIED | 527 lines, no ExUnit macros; `git ls-files -z` through `System.cmd` with a fixed argument list, no shell; raises on missing git, missing root or an empty file list |
| `scrypath_ops/test/support/copy_surfaces.ex` | 14 surfaces with state anchors | VERIFIED | real LiveViews rendered through `live/2`; four states a route cannot reach use the mounted view's own assigns merged with overrides and `SyncDriftLive.render/1` |
| `scrypath_ops/test/scrypath_ops_web/copy_rules_contract_test.exs` | the one `ops-ui` test | VERIFIED | 25 tests; planted failures call the same helper functions |
| `scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs` | `/ops` aria-current, title, palette | VERIFIED | passes; M9 red |
| `scrypath_ops/test/scrypath_ops_web/modal_focus_contract_test.exs` | `ops_modal` default pin and planted override | VERIFIED | 2 tests; M11 red |
| `examples/scrypath_ecommerce/e2e/operator.spec.ts` | Cancel-focus line | VERIFIED (execution pending by design) | one added line at 281 |
| `.github/workflows/ci.yml`, `test/mix/tasks/workflow_wiring_test.exs`, `CONTRIBUTING.md` | regex, behavioural test, ledger row 10 | VERIFIED | see truth 4 |
| `190-PHASE-RECORD.md`, `190-GATE-RECEIPT.md` | decisions, post-ship table, receipt | VERIFIED | record states "no design pass was done", names baseline run 44805847191, has no human-check items |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `copy_rules.json` `glossary` | `GLOSSARY.md` bold terms | `validate/2` | WIRED | J3 and S1 mutations red |
| rows `surfaces` | `copy_surfaces.ex` registry and anchors | `validate/2`, `check_surface/4` | WIRED | J5 (unregistered), S2 (anchor never reached) red |
| `layouts.ex` nav title | `control_room_live.ex` `page_title` | `nav_item_active?/2` | WIRED | M9: mismatch drops `aria-current`, the `/ops` test goes red |
| `workflow_wiring_test.exs` | `copy_rules.json` `source_scope` | prefix match against the compiled `ops-ui-path` pattern | WIRED | W6 red |
| `workflow_wiring_test.exs` | `.github/workflows/ci.yml` | extracts the one `grep -qE` pattern | WIRED | W1 to W3 red |
| `CONTRIBUTING.md` row 10 | `copy_rules_contract_test.exs` | first backticked path must exist | WIRED | ledger test passes; W4 and W5 red |
| `admin_shell_chrome.spec.ts` surface name | lookup map key | same string | WIRED | both read `Control room` |
| `operator.spec.ts` `cancel` locator | dialog `data-ops-modal-cancel` button | accessible name `Cancel index swap` | WIRED | name and marker both in `sync_drift_live.ex` |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Produces real data | Status |
|----------|------|--------|--------------------|--------|
| 14 surfaces | rendered HTML evaluated by the rows | mounted LiveViews with test-only stub clients (Meilisearch, Oban, posture), or the real template with forced assigns for four unreachable states | yes, real templates; stubs are fixtures, not placeholders | FLOWING |
| copy table scan | tracked file text | `git ls-files -z` from the repository root, text files only | yes; raises rather than passing on an empty list | FLOWING |

### Behavioral Spot-Checks (all re-run by me)

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Whole ScrypathOps suite, three seeds | `cd scrypath_ops && MIX_ENV=test mix test` (random, `--seed 0`, `--seed 12345`) | 2 doctests, 546 tests, 0 failures each (local Postgres up on 5432) | PASS |
| Copy rules contract test alone | `mix test test/scrypath_ops_web/copy_rules_contract_test.exs` | 25 tests, 0 failures | PASS |
| Contract, modal focus and shell tests together | the three files | 39 tests, 0 failures | PASS |
| Workflow wiring test | `mix test test/mix/tasks/workflow_wiring_test.exs` (root) | 89 tests, 0 failures | PASS |
| UI preservation fixture test | `node --test scripts/ci/ui_preservation.test.cjs` | 53 pass | PASS |
| UI review self-test | `node --test examples/scrypath_ecommerce/e2e/ui-review.selftest.mjs` | 32 pass | PASS |
| State pairs and target tests | `node --test scripts/ci/ui_state_pairs.test.cjs scripts/ci/ecommerce_target.test.cjs` | 39 and 17 pass | PASS |
| Retired-identity token guard (extra) | `node --test examples/scrypath_ecommerce/ui-tokens.test.mjs` | 61 pass | PASS |
| Old label gone | `git grep -o 'Control Room' -- . ':!.planning' ':!brand' ':!scrypath_ops/test/support/copy_rules.json'` | no output, exit 1 | PASS |
| Specs parse | `cd examples/scrypath_ecommerce && npx --no-install playwright test --list` | 300 tests in 25 files (no browser installed) | PASS |
| Cancel-focus placement | the plan's awk check on `operator.spec.ts` | exit 0 (confirm 280, focus 281, first `close.focus()` 282) | PASS |
| Forced warnings-as-errors compile (clean clone of HEAD) | `MIX_ENV=test mix compile --warnings-as-errors --force` in `scrypath_ops` | no warnings | PASS |
| Formatting | `mix format --check-formatted` at the root and in `scrypath_ops` | exit 0 | PASS |
| Namespace fence | `mix test test/mix/tasks/verify_namespace_fence_test.exs` | 3 tests, 0 failures | PASS |
| Demo test | `mix test examples/scrypath_ecommerce/test/.../page_controller_test.exs` in a scratch clone after `mix deps.get` and a cold compile | 7 tests, 0 failures | PASS |
| Table in plain Node | parse, id pattern, fields, glossary terms, every regex under the `u` flag | 14 rows, 0 problems | PASS |
| Pinned strings in lib | extract 37 strings from `operator.spec.ts` and `harness.spec.ts`, search lib | all present (one composed at render time, four are template strings) | PASS |
| Whole CI Node step | `node --test scripts/ci/ecommerce_build.test.cjs scripts/ci/ecommerce_lifecycle.test.cjs scripts/ci/ecommerce_evidence.test.cjs scripts/ci/ecommerce_target.test.cjs scripts/ci/ui_state_pairs.test.cjs` | First run: 162 tests, 161 pass, 1 fail (`ecommerce_build.test.cjs:620`, "full runtime handoff accepts measured identities and rejects forged provenance", `image handoff source SHA or fingerprint mismatch`). That test calls `git rev-parse HEAD` twice about 3 s apart, and the orchestrator's review commit `181ed01f` landed while the step was running, so HEAD moved between the two calls. Re-run with HEAD still: `ecommerce_build.test.cjs` 22 of 22 pass, and the one test alone passes (3.3 s). The lifecycle, evidence, target and state-pairs files passed in the first run. | PASS (one race with a concurrent commit, re-run clean) |

### Mutation tests (scratch clone at HEAD; the repository itself was never modified)

Each mutation restored an old string or broke a guard in one file, ran the named tests, and was reverted. Every one went red for the right reason.

| Mutation | Went red |
|----------|----------|
| M1 Searchable tuple back to the old values | `searchable-observation-only` static scan (3 hits, `sync_drift_live.ex:1735`) and rendered; `searchable-settings-row` 3 required strings missing |
| M2 `Last successful check:` back | `last-succeeded` static (`control_room_live.ex:177`) and surface `control_room.refresh_retained` |
| C3 / C4 reconcile sentence and Queue label back | `last-succeeded` static and on `sync_drift.reconcile_error_retained`, `posture.default`; `last-succeeded--absence` on `posture.failed_row_retained`; the posture LiveView test |
| M3 `Retry accepted` label back | `retry-queued-not-accepted` static and rendered (missing `Retry queued`), `retry-surfaces-no-accepted` |
| Q6 `Acceptance alone` back in help | `retry-queued-not-accepted` static, `help_live.ex:123` |
| M4 / M5 / M6 `Nothing queued`, `N jobs queued`, `queued work` back | `pending-caught-up`, `pending-count`, `pending-aggregate`, `pending-promotion-reason` on their surfaces, plus the existing LiveView tests; M5 is caught only by the rendered row (the suffix is built by concatenation), as designed |
| M7 `Clear` status restored beside a retained observation | `clear-needs-observation` on `control_room.refresh_retained` and the new verdict LiveView test |
| M9 `page_title` back to title case | `/ops` shell test (no `aria-current`), `control-room-casing` static and rendered |
| M8 title-case label planted in `README.md`, `DESIGN.md`, `examples/scrypath_ecommerce/Makefile`, `scripts/ci/ecommerce_build.test.cjs` | `control-room-casing` naming file and line; planted in `.planning/PROJECT.md` (exempt) stayed green |
| J1 to J6 field removed, empty `surfaces`, non-term glossary, entry without `case`, unregistered surface, `source_scope` typo | validation and unmatched-scope tests, each naming the cause |
| S1 the only row citing Queued re-pointed to Pending | uncited Status wording term |
| S2 anchor attribute renamed so the state is never reached | `state anchor ... missing, so no row was evaluated` |
| M11 / M12 / M13 / M14 modal default, promotion dialog focus selector, Save search focus, one promotion sentence | `modal_focus_contract_test`, the promotion dialog pin, the Save search pin, the promotion-notice test |
| W1 to W6 regex alternatives removed or narrowed, budget line 9, ledger row removed, a scope outside the regex | the wiring tests, each naming the cause |

### Probe Execution

Step 7c: SKIPPED (no probe is declared in either plan and `scripts/*/tests/probe-*.sh` does not exist).

### Requirements Coverage

| Requirement | Source plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| COPY-01 | 190-01, 190-02 | Status wording glossary first, then copy follows; pinned strings unchanged | SATISFIED | truths 1, 7, 9 |
| COPY-02 | 190-01 | Sentence-case Control room, whole-tree scan, exact-match sites, `aria-current` test | SATISFIED | truth 2 |
| COPY-03 | 190-01, 190-02 | One table, one `ops-ui` test, planted failures, path regex, wiring test, ledger | SATISFIED | truths 3, 4, 8 |
| COPY-04 | 190-02 | Cancel focus, `ops_modal` and destructive-dialog pins, promotion-notice sentences, demo test | SATISFIED (hosted execution of the Cancel-focus line pending by design) | truths 5, 6 |
| GATE-02 | 190-01, 190-02 | one gate run per SHA, no stale receipt, no capture, budget within 12 | SATISFIED | truth 10 |

No orphaned requirements: `REQUIREMENTS.md` maps COPY-01 to COPY-04 to Phase 190 and every one is claimed by a plan. The requirement checkboxes and status column in `REQUIREMENTS.md` and the `ROADMAP.md` progress row are still unchecked; that is post-merge bookkeeping for the orchestrator.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (none) | | `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, `PLACEHOLDER`, "coming soon" on added lines outside `.planning/` | none | no debt marker; `git diff --check` is clean |

### Human Verification Required

None. The run book and `190-CONTEXT.md` D-31 forbid human-check items, and nothing here needs one. Subjective wording quality is not a gate.

### Warnings (non-blocking; from `190-REVIEW.md`, each checked by me)

None of these fails a must-have, so they do not change the status. They are the places where the evidence is thinner than the headline suggests. A fix to any of them changes a file outside `.planning/`, so it makes the receipt for `f6c78bd2` stale and needs one fresh gate run on the new SHA (the receipt records about 14 minutes for the two long gates).

| # | Finding | My check | Effect on the goal | Recommendation |
|---|---------|----------|--------------------|----------------|
| WR-01 | A retained degraded Control room observation now reads `Last succeeded 1 Meilisearch task failed ...` with no `Failed` word. The locked D-06 fix text (`status={if @refresh_issue, do: nil, ...}`, from 187 review IN-02) hides every status word, not only `Clear`. | Reproduced with a throwaway probe in the scratch clone. Before the failed refresh the verdict reads `Failed 1 Meilisearch task failed ...`; after it reads `Last succeeded 1 Meilisearch task failed ...`, 0 `[data-sync-status]` elements, `data-verdict-kind="error"`. The new LiveView test covers only the healthy retained case. | The COPY-01 clause ("Clear is never shown beside a retained observation") holds, and the code matches D-06 as written. The side effect is outside what D-06 intended: the failure is still stated in the headline and the error rule, but the status word is gone. | Worth fixing before ship: drop only `Clear` (keep `Failed` and `Retrying`), add a retained-degraded test case, and update `DESIGN-TOKENS.md` row 225 (IN-02 of the review). Small change. |
| WR-02 | The `ops-ui-path` pattern omits most files the whole-tree `control-room-casing` scan reads (`README.md`, root `docs/`, `website/`, `guides/`, the demo's `README.md`, `Makefile`, `docker-entrypoint.sh` and `docs/`), and the wiring test pins that `README.md` and the website index do not match. | Same conclusion as my Note 1 below; the diff and the wiring test confirm it. | Recorded and accepted in D-18 and D-19 and in the phase record; the requirement text lists only the e2e specs, `GLOSSARY.md` and `DESIGN.md`. A PR that touches only an omitted path can reintroduce the label and is caught on the push to `main`, leaving `main` red. | A maintainer cost decision (386 s on website and docs PRs against a red `main`). The queued website refresh is the likeliest source of a title-case label, so decide before it starts. Not required for this phase. |
| WR-03 | Matching is single-space literal. A phrase wrapped across lines evades the `forbidden` entries in both the static scan and the rendered check. | Reproduced through the real helper: `Retry\n     accepted` and `Control\n Room` produce no violation; `Last\n   success` is missed as forbidden. | The table catches contiguous old strings (all my mutations), not line-wrapped ones. Hand-wrapped HEEx text exists in lib, so this is a normal edit. | Collapse whitespace on both sides before matching and add a planted wrapped case. Guard hardening. |
| WR-04 | The forbidden lists are narrower than the glossary Avoid lists (`Retry sent`, `2 queued jobs`, `Nothing is queued`, lower-case `not searchable`, `Healthy`, `All good`), and the Q-2 flash `Retry queued · queue job N` has no positive pin. | Reproduced: rewording the flash to `Retry sent · queue job N` in the scratch clone left the contract test and the failed-sync tests at 55 tests, 0 failures. | The table guards the old strings coming back (all my mutations), not every synonym the glossary lists under Avoid. D-14 specified exactly these rows, so the table matches the locked decision. | Add a `retry-queued-flash` row requiring `Retry queued · queue job \d+` and widen the forbidden regexes. Guard hardening. |
| WR-05 | The surviving refute `refute failed_row =~ ~r/last succeeded<\/dt>\s*<dd>\s*—/` can never fail: nothing renders a dash in that row. | Reproduced: the retained row HTML contains no `—`. The two `assert ... last succeeded` lines above it do guard the new wording. | Only that one negative line is dead; the string itself is guarded. It repeats the vacuous pattern D-17 set out to remove. | Delete the line or replace it with something the page can violate. |

Info items IN-01 (a retry-only queue reads Pending; deferred by D-08), IN-02 (`DESIGN-TOKENS.md` describes the old Control room status rule; follows WR-01) and IN-03 (two table requirements are subsumed by another entry on the same surface) change nothing in the verdict.

### Notes (non-blocking, recorded so they are not re-litigated)

1. **PR-time coverage of the whole-tree casing scan is partial, by design.** The `control-room-casing` row scans every tracked file, but the `ops-ui-path` pattern only starts `ops-ui` on a PR for the paths it lists. A PR that edits only `README.md`, `website/`, root `docs/`, `guides/`, or the demo's `Makefile`, `docker-entrypoint.sh` or `docs/` could reintroduce the old label and be caught only on the push run to `main`. The wiring test documents this, `CI-EFFICIENCY.md` finding 12 and the phase record say so, and `ops-ui-path` always runs on pushes to `main`. This is the accepted D-18 / D-19 trade, not a gap.
2. **Four surfaces and the promotion-notice test render the real template with forced assigns** (`sync_drift.reconcile_error_retained`, `.promotion_blocked_queue`, `.recovery_queued`, `.promotion_accepted`). They prove the wording of those states; they do not prove that the user flow reaches them. The retry flash and receipt are covered through the real click flow by `failed_sync.after_retry`.
3. **The boundary integration test was not run locally.** `test/release/ops_dependency_boundary_test.exs` needs a cold network dependency fetch; the forced warnings-as-errors compile of the committed tree stands in for it, and the new `Oban.Job` stub in `test/support` is not in `scrypath_ops/mix.lock`. The first hosted `ops-ui` run is the real observation (item 2 under Deferred to ship).
4. **Schema documentation.** The table's schema lives in `190-CONTEXT.md` D-13 and in `CopyRules.validate/2`; a v1.48 consumer would read those. A short in-repo schema note next to the JSON would help the lint author, but nothing requires it.
5. **Bookkeeping left for the orchestrator:** `190-VALIDATION.md` still says `status: draft` and `wave_0_complete: false` (its sign-off says "validated when the phase verifier passes"), and `REQUIREMENTS.md` and `ROADMAP.md` progress are unchecked.

### Gaps Summary

No gaps. No truth failed, no artifact is missing or a stub, no key link is unwired, and no blocker anti-pattern exists.

### What this does not prove

That the new wording reads well or suits the brand voice: no design pass, rendered review, screenshot comparison, aesthetic approval or independent review happened or is claimed. That Cancel receives focus in a real browser (only the hosted `ecommerce-mounted` run executes that line), or with a real screen reader. That the saved-search delete confirmation focuses Cancel first (it is an inline form, pinned as it exists). That the advisory Playwright specs pass beyond the one exact-head dispatch. That the hosted `ops-ui` job finds `git` and a full checkout the way the local run does. That a path outside the extended `ops-ui` pattern reintroducing a retired phrase is caught before the merge (it is caught on the push to `main`). Coverage of JavaScript strings, attribute-only text, states with no named surface and non-English text (the table's `not_covered`).

---

_Verified: 2026-11-20_
_Verifier: Claude (gsd-verifier)_
