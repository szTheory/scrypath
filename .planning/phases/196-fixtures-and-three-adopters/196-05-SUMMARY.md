---
phase: 196-fixtures-and-three-adopters
plan: 05
subsystem: testing
tags: [fixtures, hostile-text, bulk-data, golden-digest, provenance, source-lints, ci-cost, adr-0002, release-train]

requires:
  - phase: 196-fixtures-and-three-adopters
    provides: "plan 01 to 04: the project, recorded payloads, closed failure table, three adopters, the registry-driven check and a plant per invariant"
provides:
  - "ScrypathFixtures.Hostile: twelve named stress strings written only as escapes, used only by one named stress variation, Shopadelic hostile_ids, in the places Meilisearch and Scrypath can carry them"
  - "ScrypathFixtures.Bulk: deterministic pick/4, row/3, rows/3 (capped at 5,000) and a golden SHA-256 digest over a fixed sample; no Faker, no StreamData, no new dependency"
  - "Five new check invariants (raw_format_char, impure_source, denylisted_word, provenance_missing, bulk_digest), 26 in all, each with a cause-pinned planted failure"
  - "The phase PR (#174, squash-merged on green required checks) and the measured hosted cost of the fixtures, recorded as CI-EFFICIENCY finding 29"
affects: [197-catalog-and-pilot, 198-chatly-and-clinicly]

actuals:
  tokens: 13952
  tasks: 3
  commits: 3
commits: 3
plan_head_before: aa2459579e86f9c428ca578f7d28d80183a227ee
plan_head_after: 9a164bc3c3998529033e603d81b3153ede387757

tech-stack:
  added: ["no package added, removed or upgraded; no lock file touched; no root lib/ change"]
  patterns:
    - "Source lints scan a list of paths or {path, content} pairs, so a planted failure needs no file and a real temp file proves the disk path too"
    - "An impure-call token counts only where a word starts, and the lint's own token list is written in two pieces, so the check file stays under its own lint instead of being exempt"
    - "The denied-word attribute lives in one file that the scan skips by path; every other file, the README and every scenario string is scanned"

key-files:
  created:
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/hostile.ex
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/bulk.ex
    - scrypath_ops/test/scrypath_ops_web/live/fixtures_hostile_render_test.exs
    - scrypath_ops/test/scrypath_ops/fixtures_provenance_test.exs
  modified:
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/check.ex
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/shopadelic.ex
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/scenarios.ex
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/logistify.ex
    - fixtures/scrypath_fixtures/README.md
    - scrypath_ops/test/scrypath_ops/fixtures_check_test.exs
    - scrypath_ops/test/scrypath_ops/fixtures_round_trip_test.exs
    - test/support/release/shipped_docs.ex
    - .planning/reference/CI-EFFICIENCY.md

key-decisions:
  - "Hostile text sits only where the real system can carry it: invalid-character ids and the 512-byte id only inside the invalid_document_id failures that echo them, markup and non-Latin text only inside one echoed document, the 511-byte id and the 200-character token only as valid job document_ids"
  - "The 200-character token uses letters and digits only, so it has no hyphen and no line-break opportunity and is also a valid document id"
  - "The five new invariants scan a list of paths or {path, content} pairs; the plant table in fixtures_check_test.exs uses in-memory pairs, and fixtures_provenance_test.exs plants the same causes as real temporary files"
  - "check.ex is exempt from the denied-word scan only (its attribute names the words) and stays under the impure-call scan by splitting its tokens"
  - "The fixtures' hosted cost is read from the warm rerun against a same-day control, not from a cold number: warm minus control is -3 s total and +1 s in the verify step, far under the advisory 60 s"

patterns-established:
  - "A new stress scenario sets kind :stress, says 'stress' in its label and is registered after its adopter's ordinary states; two now exist (F1 history and hostile ids)"
  - "A repo-only Mix task defined outside lib/ and test/ must have its glob in the shipped-docs derivation"

requirements-completed: [FIX-02, FIX-03, FIX-04, FLOW-01, FLOW-02, FLOW-03, FLOW-04]

coverage:
  - id: D1
    description: "Hostile text exists only as escapes, in one named stress variation (Shopadelic hostile_ids), only where the real system can carry it, and the operator pages render the markup as text with no script element"
    requirement: "FIX-02"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/fixtures_hostile_render_test.exs (9 tests: placement, 13 failed rows on /ops/failed-sync, no script element on the failed-sync and health pages, markup as text); the text and script assertions were also run against a raw and an escaped fragment and tell them apart"
        status: pass
    human_judgment: false
  - id: D2
    description: "Bulk ids come from a deterministic phash2 pick with a golden digest over the picked sample, capped at 5,000; changing one word in a word list is reported as bulk_digest"
    requirement: "FIX-03"
    verification:
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops/fixtures_provenance_test.exs#bulk data (5 tests); one word of the product adjective list changed once, the check printed {:bulk, {:bulk_digest, ...}}, the file was restored byte-identical"
        status: pass
    human_judgment: false
  - id: D3
    description: "The check fails, each time with exactly its own tag, on a raw format character, a wall-clock/random/OS/repository call in lib source, a compliance word or the sibling canon id, an adopter file without its provenance line, and a bulk digest change"
    requirement: "FIX-04"
    verification:
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops/fixtures_check_test.exs (11 tests, plants for all 26 tags) and fixtures_provenance_test.exs (21 tests); six deliberate breakages of the check (one per rule plus the scenario-data and file scans) each failed their own plants"
        status: pass
    human_judgment: false
  - id: D4
    description: "The local mirror ran on the pushed commit or its parent with a result or a concrete reason per lane; the phase PR (#174) was squash-merged with every required check green on the exact head; no release PR appeared"
    requirement: "FLOW-01"
    verification:
      - kind: other
        ref: "gh pr checks 174 --required on head 9a164bc3: backend, core, package, repository-contracts, ecommerce-mounted and ops-ui all pass; merge commit 7a18da12; gh pr list --state open was 0 before and 0 after"
        status: pass
    human_judgment: false
  - id: D5
    description: "The fixtures' hosted cost is measured (cold, warm, same-day control, main cold) and recorded as CI-EFFICIENCY finding 29, read against the advisory 60 s threshold"
    requirement: "FLOW-03"
    verification:
      - kind: other
        ref: ".planning/reference/CI-EFFICIENCY.md finding 29; gh run view of runs 44983386664 (attempts 1 and 2), 44965770542 (attempts 1 and 2) and 44985247843"
        status: pass
    human_judgment: false

duration: 130min
completed: 2026-11-22
status: complete
---

# Phase 196 Plan 05: Hostile text, bulk data, source lints and the phase ship Summary

**The last fixture rules (hostile text as escapes in one stress variation, a deterministic bulk digest, provenance and denied-word and purity lints, each with a planted failure) landed, and the whole phase shipped as PR #174 with every required check green on the exact head and a measured hosted cost of about zero seconds over a same-day control.**

## Performance

- **Duration:** about 2 h 10 min up to the start of the docs PR (the local mirror and its retries were most of it); the docs PR's own CI wait comes after
- **Started:** 2026-11-22T02:37:09Z
- **Completed:** 2026-11-22 (phase PR merged 04:29Z, main cold run green about 04:46Z)
- **Tasks:** 3
- **Files:** 16 changed in the three code commits (4 created, 12 modified, 1,259 lines added), plus this file and CI-EFFICIENCY in the docs PR

## Accomplishments

- **Hostile text.** `ScrypathFixtures.Hostile` holds twelve named strings, every non-ASCII character an `\u{...}` escape. Shopadelic `hostile_ids` is the one stress variation that uses them: ten `invalid_document_id` failures (nine invalid-character ids and the 512-byte id), one `missing_document_id` failure whose echoed document carries the markup, Han and Arabic text, and valid long ids (511 bytes, 200 characters) only as job `document_ids`, including the discarded and retryable jobs. The failed-sync page lists 13 failed rows for it, shows the markup as literal text and creates no script element.
- **Bulk data.** `ScrypathFixtures.Bulk` picks ordinary ids with `:erlang.phash2` and carries a golden SHA-256 digest over a fixed sample (50 records of each kind at seed 196). The ordinary Logistify and Shopadelic job ids now come from it; the round-trip, determinism and check tests needed no expectation change.
- **Five new invariants** (26 in all): `raw_format_char`, `impure_source`, `denylisted_word`, `provenance_missing` and `bulk_digest`. Every adopter module and schema carries a line saying it is a fictional adopter, Scrypath-owned data, with no records copied.
- **Shipped.** PR #174 (`test(ops-ui)`) was squash-merged as `7a18da12` with all required checks green on the exact head `9a164bc3`. No release PR appeared.
- **Measured cost.** Warm `ops-ui` 433 s against a same-day control of 436 s: the fixtures cost nothing measurable. Details below and in CI-EFFICIENCY finding 29.

## Task Commits

1. **Task 1: hostile strings as escapes in one stress variation, rendered escaped** - `bd4c9f43` (test, 5 paths)
2. **Task 2: bulk pick with a golden digest, provenance, denied words and purity lints, README** - `12f166d3` (test, 11 paths)
3. **Task 3: a red found by the local mirror, fixed at its cause** - `9a164bc3` (test, 1 path): the shipped-docs derivation now reads `fixtures/*/lib/mix/tasks`
4. **Phase PR #174** squash-merged as `7a18da12` (all of Plans 01 to 05, 27 commits)
5. **Docs PR** (this file, CI-EFFICIENCY finding 29, STATE, ROADMAP and REQUIREMENTS; planning-only `docs(phase-196)` title): its number and merge commit are in the executor's hand-off report, because they do not exist until this file is committed

**Plan metadata:** the `docs(196-05)` content rides in the docs PR. The task commits keep the plan's `test(ops-ui)` subjects, so a resolver that matches the `(196-05)` scope sees only the docs commit; the measured instrument is the ledger above (`plan_head_before` to `plan_head_after`, 3 commits).

## Local mirror (AGENTS.md pre-push confidence)

Run on `12f166d3` (head of Task 2) unless noted; the pushed head `9a164bc3` adds one test-support glob.

| Lane | Command | Result | Wall |
|------|---------|--------|------|
| cheap subset | `bash scripts/ci/pre_push.sh` | exit 0, 11 steps passed, none skipped | 62 s |
| `core` | `mix verify.core --exclude integration --exclude docs_contract` | **red, then fixed.** 1 failure in 1,336 tests (6 properties, 104 excluded): `ShippedDocsContractTest` "every Mix task source outside lib/ and test/ is read by the derivation" (the fixtures check task, added in Plan 01, was not in the derivation's globs). Fixed in `9a164bc3`; the seven test files that use the derivation ran with `--include docs_contract`: 161 tests, 0 failures. The whole lane was not rerun (10 minutes; the fix is one glob). Hosted `core` then passed. | 9 min 54 s |
| `package` | `mix verify.package` | exit 0 | 63 s |
| `repository-contracts` | `mix verify.repository_contracts` (standing fetch access) | exit 0, 183 tests, 0 failures | 9 min 25 s |
| `repository-contracts` | `node scripts/ci/ui_literal_policy.cjs` | exit 0 | 1.7 s |
| CI Node step | `node --test` over the five files | exit 0, 162 tests, 0 failures | 9 min 49 s |
| classifiers | `node --test` over the two path classifier files | exit 0, 52 tests, 0 failures | included above |
| `ops-ui` | `mix verify.ops_ui` | two runs red in the root boundary integration test (`mix deps.get --check-locked` timed out downloading `sigra-1.20.0` into the test's empty Hex home, 469 s and 708 s); third run with `HEX_HTTP_TIMEOUT=120`: exit 0, 2 boundary tests, 2 doctests and 715 tests, 0 failures | 6 min 18 s |
| `ops-ui` | `cd scrypath_ops && mix precommit` | exit 0, 715 tests, 0 failures | 29 s |
| `ecommerce-mounted` | `mix verify.ecommerce_mounted` | **not completed locally, four attempts.** (1) on `12f166d3` the Docker dependency boundary proof passed for the test and prod images (catalog 404, served assets, forbidden dependency and module checks), then failed at the checkout fingerprint check because I committed the `core` fix while it ran; (2) and (4) the cold `runtime_test` build hit the script's 900 s bound on a Docker VM shared with other work; (3) a Hex timeout inside the build. The browser specs did not run. Hosted `ecommerce-mounted` then passed on the pushed head (963 s). | 12 to 15 min each |
| `backend` | none | not affected: no root `lib/` change (guard row G4) | |

### Guard rows (on the pushed head `9a164bc3`)

| Row | Check | Result |
|-----|-------|--------|
| G1 | `git diff --exit-code origin/main` over both `phase173_fixture_source.ex` copies and `posture_live.ex` | exit 0 |
| G2 | `git diff --quiet origin/main` over the three lock files | exit 0 |
| G3 | protected config files in `git diff --name-only origin/main...HEAD` | prints nothing |
| G4 | root `lib/` in the same diff | prints nothing |
| G5 | `feat` or `fix` subject in `origin/main..HEAD` | none (13 `test`, 13 `docs`, 1 `chore`) |

## Hosted runs and cost

| Sample | Run (attempt) | `ops-ui` job | Total | `Run mix verify.ops_ui` | Notes |
|--------|---------------|--------------|-------|-------------------------|-------|
| PR cold | 44983386664 (1) | 137088630382 | 482 s | 433 s | both BEAM cache keys "not found" (finding 26 mechanism) |
| PR warm | 44983386664 (2), `gh run rerun --job` | 137092408421 | 433 s | 388 s | both keys "hit" |
| Control, same hour | 44965770542 (2), main run, job rerun together with the warm sample | 137092421487 | 436 s | 387 s | |
| Control, earlier original | 44965770542 (1) | 137034378644 | 427 s | 377 s | |
| Main cold | 44985247843 (1), first main push run after the merge | 137094338060 | 469 s | 426 s | both keys "not found" (a PR's caches are not visible to main); +33 s over the same-hour control; run green |

- **Warm minus control: -3 s total, +1 s in the verify step** (against the earlier original control: +6 s and +11 s). That is noise, and about 59 s under the advisory 60 s threshold from prep note B. The threshold is an input to the Phase 197 fold decision, not an ADR 0001 trigger, and it was not reached.
- **Cold minus warm: +49 s total, +45 s in the step.** The cold run did not find either BEAM cache key (the `scrypath_ops/mix.exs` edit changes both prefixes with no fallback), which is the mechanism of finding 26; no lock changed this time, so it is smaller than Phase 195's +139 s.
- **Main cold:** 469 s (step 426 s), 33 s above the same-hour control and well under Phase 195's 620 s. The main run was green (`core` 512 s, `repository-contracts` 599 s, `ecommerce-mounted` 999 s with a 295 s bake step, `package` 108 s, `backend` 56 s; advisory `deep-quality` red as on every recent run).
- **Docker side:** the `ecommerce-mounted` bake step took 300 s against 380, 279 and 292 s on the last three green main runs (median 292 s, +8 s); the whole job took 963 s against 1,267, 879 and 937 s.
- **Other required jobs on the PR run:** `core` 472 s, `repository-contracts` 603 s, `package` 104 s, `backend` 59 s. Advisory: four compatibility cells 461 to 590 s (green), `phoenix-example` 85 s (green), `deep-quality` 209 s (red).
- **`deep-quality` red** is not new and is not from this PR: the same job is red on the latest main run. Its log flags `phoenix 1.8.16` with two HIGH advisories in the root graph; the ops and ecommerce locks already pin 1.8.17. No lock changed here and I did not investigate further.
- **Fixtures' local test time:** the eight fixtures test files run 145 tests in 6.6 s of ExUnit time on a warm local build (Plan 04 measured 117 tests in 2.7 s for six).

## Other results the plan asked to keep

| Item | Result |
|------|--------|
| Planted revert, Task 2 | Five deliberate breakages of `check.ex`, one per new rule, each failed its own plants (raw character 4 tests, impure call 4, provenance 5, bulk digest 3, denied word in a label 4); the scenario-data scan and the README and lib file scan each failed exactly one plant when disabled. Changing one word in the product adjective list made `mix scrypath_fixtures.check_fixtures` print `{:bulk, {:bulk_digest, "1ae04e5e..."}}`; `check.ex` and `bulk.ex` were restored from copies and byte-compared |
| Escaping proof | The text and script assertions were run on a raw `<script>` fragment and on the escaped one: they report 1 script and no text for the raw one, 0 scripts and the literal text for the escaped one |
| `hostile_ids` as observed | `sync_status`, `failed_sync_work` and `index_contract_drift` all `:ok`; posture `degraded`, headline "Sync jobs and Meilisearch tasks failed"; 13 failed rows (10 invalid ids, 1 echoed document, 1 discarded job, 1 retrying job) |
| No new dependency | no Faker or StreamData reference in `fixtures/scrypath_fixtures` or `scrypath_ops/mix.exs`; the three lock files equal `origin/main` |
| Docker before and after | before: images 246 (96.81 GB), containers 56, volumes 195 (37.09 GB), build cache 260 (31 GB). After: images 246 (96.81 GB), containers 56, volumes 195 (37.57 GB), build cache 250 (32.85 GB). The image list is identical to the one recorded before the first run. The volume count is unchanged and the verifier reported `volumes=0` for every project of this task, so the size change is other projects'. The build cache is the default builder's and was not pruned (no builder was created for this task). |
| Docker removed | by exact name: three image tags the boundary script left after its timed-out runs (`scrypath_dependency_boundary_20261122t030152z-39706-52549050:asset-builder` and `:runtime-test`, `scrypath_dependency_boundary_20261122t034740z-1018-2653712826:asset-builder`) and four temp directories under the OS temp folder. No container, network or volume of the task projects remained (`docker ps -a`, `docker network ls`, `docker volume ls` by project label and by name). The verifier of attempts 2 and 4 reported `cleanup=failed` because it hit its deadline; nothing was left. One unrelated old network (`scrypath_ecommerce_verify_full_53268690_...`) belongs to an earlier run and was left alone. |
| Release-please | 0 open PRs before and 0 after both merges |
| PRs and merges | #174 `test(ops-ui): add the scrypath_fixtures project with three fictional adopters`, squash-merged as `7a18da12`; the docs PR in the hand-off report |

## Decisions Made

See `key-decisions` above. The two Phase 197 should know: the hosted cost of the fixtures is about zero, so the advisory 60 s fold input does not argue for folding; and the fixtures project still has no second consumer, which is the exit rule's own test.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] The round-trip test asserted exactly one stress scenario**
- **Found during:** Task 1
- **Issue:** `fixtures_round_trip_test.exs` asserted that the F1 variation is the only stress scenario; adding `hostile_ids`, which the plan prescribes, made it fail.
- **Fix:** it now asserts the registry holds exactly those two stress scenarios, in that order.
- **Files modified:** `scrypath_ops/test/scrypath_ops/fixtures_round_trip_test.exs` (not in the plan's file list)
- **Commit:** `bd4c9f43`

**2. [Rule 1 - Bug] The `core` lane failed on the fixtures check task**
- **Found during:** Task 3, local mirror
- **Issue:** Plan 01 added `Mix.Tasks.ScrypathFixtures.CheckFixtures` under `fixtures/`, outside the trees the shipped-docs derivation reads, so `ShippedDocsContractTest` failed. No earlier plan ran that lane.
- **Fix:** added `fixtures/*/lib/mix/tasks/**/*.ex` to `@task_source_globs` (the task is repo-only by construction, so the derivation now also guards that no shipped file tells an adopter to run it).
- **Files modified:** `test/support/release/shipped_docs.ex`
- **Commit:** `9a164bc3`

### Design deviations

**3. The five source invariants accept `{path, content}` pairs as well as paths.** The plan prescribed temp files for the plants. The plant table in `fixtures_check_test.exs` (which the coverage test reads) uses in-memory pairs, so a table that is rebuilt on every call needs no files to clean up; `fixtures_provenance_test.exs` plants the same causes as real temporary files, so the read-from-disk path is tested too. Commit `12f166d3`.

**4. `check.ex` stays under the impure-call scan.** The plan had the scan exclude one file by path. Only the denied-word scan does that (its attribute names the words). The impure tokens are written in two pieces, so the check file is scanned like any other. A token also counts only where a word starts, so `NaiveDateTime` is one problem and not also one for the `DateTime` token it contains. Commit `12f166d3`.

**5. Four adopter files outside the plan's list changed.** `shopadelic/product.ex`, `logistify/shipment.ex`, `wikily.ex` and `wikily/page.ex` gained the provenance line the new invariant requires (a doc line only). Commit `12f166d3`.

**6. `Bulk.row/3` is public next to `rows/3`.** The Logistify and Shopadelic job builders need two ids per job, and building a list of 1,200 rows per call would be wasteful. No ordinary lane carries a lane string (job args have no such key), so only ids come from `Bulk` today; `:page` records exist for Phase 197 stories. Commit `12f166d3`.

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug), 4 design. **Impact:** none on scope; the bug fix removed a hosted `core` red before the push.

## Issues Encountered

- `mix verify.ecommerce_mounted` did not complete locally (see the table). The cause is the shared Docker VM and a slow Hex path, not this change; hosted `ecommerce-mounted` passed on the exact head.
- Committing while the mounted lane ran made its own checkout-fingerprint check fail. Lesson for the next local run of that lane: nothing may be committed or edited while it runs.
- The local `mix verify.ops_ui` needs `HEX_HTTP_TIMEOUT=120` on this machine's current network; that is the setting Hex itself names, and it does not weaken what the test proves.
- The shared local Postgres logged `too_many_connections` during test runs (other projects' sessions). It did not affect a result.
- `gsd-tools check evaluation-scope` finds commits by a `(196-05)` subject scope; the task commits use the plan's `test(ops-ui)` subjects, so the measured instrument is the ledger.

## Known Stubs

None. No placeholder text, empty-value-to-UI data or unwired data source in the files this plan created or changed.

## Threat Flags

None new. Threat register outcomes: T-196-18 (Trojan Source): `raw_format_char` over the whole fixtures tree with real temp-file and in-memory plants, plus the perl scan in acceptance; T-196-19 (stored markup): the hostile render test with LazyHTML; T-196-20 (claims, sibling records): `denylisted_word` and `provenance_missing` with plants; T-196-21 (release-please): `test(ops-ui)` and `docs(phase-196)` titles, no `feat` or `fix` subject, 0 open PRs before and after; T-196-22 (protected files): explicit-path staging, cached-name check before every commit, guard row G3 and a check on main after the merge; T-196-23 (Docker leftovers): removal by exact name and `docker system df` before and after; T-196-SC: no package installed, locks identical.

## Next Phase Readiness

Phase 197 starts with the fold evaluation the fixtures README names: there is still no second consumer, and the fixtures' hosted cost (warm minus control about 0 s) does not argue for folding. Read `196-FINDINGS.md` first (F3 and F4, the missing-backend raise, and the fresh F1 and F2 evidence), and note that two stress scenarios now exist and must be labelled as stress in any story that shows them. The maintainer has no decision pending from this plan; F3 and F4 are worth a look when someone relies on `sortable:` or on a reindex cutover.

## Self-Check: PASSED

- All created and modified files exist on disk (`[ -f ]`): `hostile.ex`, `bulk.ex`, `fixtures_hostile_render_test.exs`, `fixtures_provenance_test.exs`, `check.ex`, `shipped_docs.ex`, `CI-EFFICIENCY.md` and this file.
- Commits `bd4c9f43`, `12f166d3` and `9a164bc3` are ancestors of the phase branch tip `9a164bc3` (`git merge-base --is-ancestor`), and `rev-list --count` over the ledger range is 3. The squash commit `7a18da12` is an ancestor of the docs branch, and the code paths (`fixtures`, `scrypath_ops`, `test`, `lib`, `scripts`) are identical between the branch tip and `7a18da12`.
- Every task `<acceptance_criteria>` re-run and passing: raw-character scan over `hostile.ex`, the hostile test and `shopadelic.ex` empty; `kind: :stress` 1 in `shopadelic.ex`; `LazyHTML` 9 in the hostile test; `phash2` 3 in `bulk.ex`; the five tags 12 in `check.ex`; `:denylisted_word` 6 in the provenance test; no denied word in any fixtures file other than `check.ex`; no Faker or StreamData reference; three lock files equal `origin/main`; the bulk word-list change reported `{:bulk_digest, _}` and was restored.
- Plan-level `<verification>` re-run on the final code head: the three focused test files, `Fixtures OK: 11 scenario(s)` with `PGPORT=1`, root `mix format --check-formatted`, and the staged-file guard before every commit.
- `gh pr view 174` reports MERGED with a `test(ops-ui):` title; `git show --name-only --format= origin/main` lists none of the three protected config files; the open PR list was 0 before and after.
- No protected config file (`.planning/config.json`, `.planning/state.json`, `.impeccable/config.json`) is in any commit of the plan range or of the docs PR; no commit deleted a tracked file.
