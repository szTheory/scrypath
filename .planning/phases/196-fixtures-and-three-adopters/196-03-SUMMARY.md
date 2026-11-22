---
phase: 196-fixtures-and-three-adopters
plan: 03
subsystem: testing
tags: [fixtures, meilisearch, recordings, failure-table, determinism, lazyhtml, docker, adr-0002]

requires:
  - phase: 196-fixtures-and-three-adopters
    provides: "plan 01's builders, fake client, Check and the Logistify deep queue; plan 02's fixtures boundary and README (whose Recordings section now resolves)"
provides:
  - "31 raw Meilisearch v1.15.2 response bodies recorded once from a task-scoped, removed Docker container, with Scrypath-owned values, a re-runnable record.sh and PROVENANCE.md"
  - "ScrypathFixtures.Recordings: a compile-time loader (external resources plus a recompile hook) exposing exemplars per status, details key sets per type, default settings and value types"
  - "Check invariants task_shape and details_keys: every builder task's value types and details keys equal the recorded ones"
  - "A fake-client conformance suite against the recorded pages, continuation, empty page and invisible swap task (the fake needed no fix)"
  - "ScrypathFixtures.Failures: a closed table of seven entries, each with a resolving source, plus the cannot-produce list; builders can no longer take failure text"
  - "Check invariants unknown_failure, failure_source_missing and forbidden_failure"
  - "A render-determinism test with a cause-pinned plant (two clocks differ only in time-derived text)"
  - "196-FINDINGS.md: F3 recorded for the maintainer, nothing fixed"
affects: [196-04, 196-05, 197-catalog-and-pilot, 198-chatly-and-clinicly]

actuals:
  tokens: 28453
  tasks: 3
  commits: 3
commits: 3
plan_head_before: 7e62ddb33880f0164a48bdf72ae39e493d92b584
plan_head_after: ab6442926721bf53ae6e021048ac7a910d89607a

tech-stack:
  added: ["no package added, removed or upgraded; no lock file touched; no root lib/ change"]
  patterns:
    - "Compare key sets and value types of recorded evidence, never values; every re-record then differs only in noise"
    - "A table, not a builder, owns failure text; the builder head rejects an inline error and the check rejects text that is not a table render"
    - "Every plant asserts its exact tag beside a positive control, and the real files were broken on purpose once to confirm each check fails for its own cause"
    - "A determinism comparison runs over a normalized projection of the whole DOM, and its plant asserts the cause (relative age), never bare inequality"

key-files:
  created:
    - fixtures/scrypath_fixtures/recordings/record.sh
    - fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/PROVENANCE.md
    - fixtures/scrypath_fixtures/recordings/meilisearch-v1.15/ (31 JSON bodies)
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/recordings.ex
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/failures.ex
    - scrypath_ops/test/scrypath_ops/fixtures_recordings_test.exs
    - scrypath_ops/test/scrypath_ops_web/live/fixtures_determinism_test.exs
    - .planning/phases/196-fixtures-and-three-adopters/196-FINDINGS.md
  modified:
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/meili.ex
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/oban_job.ex
    - fixtures/scrypath_fixtures/lib/scrypath_fixtures/check.ex

key-decisions:
  - "The escaper rewrites every non-ASCII character as a JSON unicode escape, not only the listed format characters, so the recordings are pure ASCII and no raw right-to-left letter or emoji reaches the repository (value-preserving; the plan's perl scan still passes)"
  - "Meili.task derives details from the recorded key set per type (counts from :documents) and requires canceled_by for a canceled task, because the details_keys and task_shape invariants would otherwise fail every ordinary scenario"
  - "Failure entries carry task_types as well as source: a real error on a task type the server never produces it for is an unknown_failure"
  - "Table-level problems use :failures where the scenario id would be, so Check.run/1 keeps one problem shape"
  - "An Oban entry's reason is matched as an exact string or a prefix, and the task-failed text is built from the real Scrypath.Operations.Task through inspect/1, so its shape and line breaks cannot drift from the library"

patterns-established:
  - "Recordings.__mix_recompile__?/0 so adding or removing a recording recompiles the loader, not only editing one"
  - "Hostile text is never typed into a source file: tests read the echoed id and document back out of the recording"

requirements-completed: [FIX-02, FIX-04, FLOW-03, FLOW-04]

coverage:
  - id: D1
    description: "Real Meilisearch v1.15.2 payloads recorded once from a task-scoped container (loopback port, tmpfs, no key), committed as raw JSON with Scrypath-owned values, a re-runnable script and provenance naming the image id, version body, date and each request; the container is gone and docker system df is identical before and after"
    requirement: "FIX-02"
    verification:
      - kind: other
        ref: "bash -n record.sh; docker ps -a --filter name=scrypath-p196 prints nothing; docker system df and the container name list identical before and after; 31 JSON files; perl scan for raw format characters empty; grep for research example values empty"
        status: pass
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops/fixtures_recordings_test.exs#Recordings (every file is decoded and named in PROVENANCE.md; a file missing from it is reported by name)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every builder task's key set and value types equal the recorded exemplar for its status, and its details keys equal the recorded ones for its type, with plants for a duration forced to an integer, a stamp of the wrong type and a details map that gains or loses a key"
    requirement: "FIX-02"
    verification:
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops/fixtures_recordings_test.exs#builder shapes and #check against the recordings (8 tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The fake client, given the recorded task set, returns the recorded limit-3 page with its from and next, the recorded continuation, the recorded empty page for an unknown index, and never lists a null-index swap under an indexUids filter"
    requirement: "FIX-02"
    verification:
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops/fixtures_recordings_test.exs#fake client against the recorded lists (6 tests); flipping the sort order fails 3 of them"
        status: pass
    human_judgment: false
  - id: D4
    description: "Every failure string comes from the closed table of seven entries; each entry's source resolves to a recording or an existing repository path; nothing on the cannot-produce list is in the table; builders reject an inline error; the check reports unknown_failure, failure_source_missing and forbidden_failure"
    requirement: "FIX-02"
    verification:
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops/fixtures_recordings_test.exs#Failures table, #builders cannot take failure text and #check against the failure table (20 tests)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Two renders of the Logistify deep queue three days apart are equal after normalizing per-render ids and absolute times, and their relative ages do not move; a plant that pins the task times while the clock moves differs in relative age and, with relative ages masked, in nothing else"
    requirement: "FIX-04"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/live/fixtures_determinism_test.exs (3 tests); identity normalizer fails all 3, unnormalized per-render ids fail the same-clock pair, an unpinned plant fails on the relative-age assertion"
        status: pass
    human_judgment: false
  - id: D6
    description: "Finding F3 (v1.15.2 omits indexSwap tasks from indexUids-filtered lists, so Scrypath can never show a swap row; Phase 198 Chatly must derive its cutover from __reindex index tasks) is recorded for the maintainer and not fixed; the recorded evidence is pinned by a test"
    requirement: "FLOW-04"
    verification:
      - kind: unit
        ref: "scrypath_ops/test/scrypath_ops/fixtures_recordings_test.exs#finding F3 evidence"
        status: pass
      - kind: other
        ref: "grep -c F3 and grep -c __reindex over 196-FINDINGS.md are 5 and 3; git diff --name-only over the plan range lists no root lib/ file"
        status: pass
    human_judgment: false

duration: 24min
completed: 2026-11-21
status: complete
---

# Phase 196 Plan 03: Recordings, failure table and determinism Summary

**The fixture shapes now rest on 31 payloads recorded from a real Meilisearch v1.15.2 server instead of memory: builders and the fake client are checked against them, every failure string comes from a closed table with a resolving source, two renders at different clocks are proven to differ only in time text, and the swap-task blind spot is recorded as finding F3.**

## Performance

- **Duration:** about 24 min (the start time was not captured when the plan began; it is reconstructed from the first scratchpad file, 01:47Z)
- **Completed:** 2026-11-22T02:11Z
- **Tasks:** 3
- **Files:** 41 (the 31 recorded bodies, 7 other files created and 3 modified)

## Accomplishments

- **Recordings.** One script run against a task-scoped container produced 31 raw bodies: every status, the four failure kinds (plus a 512-byte id, a hostile id and a markup document), the default and narrowed settings, three error bodies, the swap and the list pages. `PROVENANCE.md` names the image id, the version body and each request. The container was removed by the script's own trap and Docker's counts are identical before and after.
- **Shapes checked against evidence.** `Recordings` loads the bodies at compile time. `Check` now flags a builder task whose value types differ from the recorded task of its status (`task_shape`) or whose details keys differ from the recorded ones (`details_keys`). `Meili.task` fills details from the recorded key set, which the ordinary Logistify scenario needed to keep passing.
- **Fake client conformance.** Given the recorded task set, the fake returns the recorded first page (uids 13, 11, 10, `from` 13, `next` 9), the continuation (9, 6, 5, `next` 4), the full list with no `next`, the empty page for an unknown index, and no swap under an index filter. It needed no change.
- **Closed failure table.** Seven entries (four Meilisearch task errors, three Oban errors), each with a `source:` that must resolve, plus the cannot-produce list. `Meili.task` renders a failed task's error from an entry and rejects an inline `:error`; `ObanJob` renders errors from tuples and rejects raw maps. The check reports `unknown_failure`, `failure_source_missing` and `forbidden_failure`.
- **Determinism.** The deep queue renders the same at two clocks once per-render ids and absolute times are normalized, and its relative ages ("just now", "2 hrs ago") do not move. The plant moves only the scenario clock and fails on relative age, which is its cause.
- **F3 recorded** in `196-FINDINGS.md`, with a second fact from the same recording: a swap moves each index's task history to the other name.

## Task Commits

1. **Task 1: Record the payloads, load them, check shapes and fake-client paging** - `7fdbfe4e` (test, 37 paths: 31 recordings, PROVENANCE.md, record.sh, Recordings, Meili, Check, the test)
2. **Task 2: Closed failure table with sources, wired into builders and the check** - `b8cd7a70` (test, 5 paths)
3. **Task 3: Two renders differ only in time text; record F3** - `ab644292` (test, 2 paths)

**Plan metadata:** the `docs(196-03)` commits that hold this file, STATE.md and ROADMAP.md. The three task commits keep the plan's prescribed `test(ops-ui)` subjects, so a resolver that matches the `(196-03)` scope sees only the docs commits.

## Results the plan asked to keep

| Item | Result |
|------|--------|
| Image | `getmeili/meilisearch:v1.15`, id `sha256:edae2a6bb59ca587b68ad74b157a9008fba10085ff3c09a143d2051c8355dbec`, repo digest `sha256:fe500cf9...`; it pre-existed locally and backs the maintainer's retained preview, so it was not pulled and is not removed |
| Server version body | `{"commitSha":"6b4d69996ce9c1e0d0b8d52af2fcea4a5750bfa7","commitDate":"2025-06-12T16:41:47.000000000Z","pkgVersion":"1.15.2"}` |
| `docker system df` before | Images 246 (47 active, 96.81GB); Containers 56 (18 active, 7.843GB); Local Volumes 195 (63 active, 37.09GB); Build Cache 260 (0 active, 31GB) |
| `docker system df` after | Identical, line for line. The container name list (56) is identical too; no `scrypath-p196` container, and no network or volume carries the task label |
| Recorded files | 31 JSON bodies (4.5 s per run; 5.6 KB for each of the two long lists, under 1.3 KB for the rest) plus PROVENANCE.md and record.sh |
| Key sets against the research bodies | No difference: 12 task keys for every task, 20 settings keys, `message/code/type/link` in every error, `results/total/limit/from/next` in every page, `taskUid` in the enqueue summary |
| Hostile id echo (file 08) | Meilisearch rejects it with `invalid_document_id` and echoes the id back inside the message exactly as sent: the right-to-left override, `<b>7</b>`, the CJK and Arabic letters and the ZWJ emoji all survive, shown as a JSON string. The escaper then wrote them as `\uXXXX`. Rebuilding the message from the table with `Jason.encode!` reproduces the recording byte for byte |
| Markup document echo (file 09) | The whole document is echoed in the message in its original key order, markup and non-Latin text intact (fresh F2 evidence). The table reproduces it with `Jason.OrderedObject` |
| 511 versus 512 bytes | A 512-byte id is rejected and a 511-byte id is accepted (files 06 and 07), so the cap in the message is exact |
| Swap | A swap task has a null `indexUid`; filtered swap lists return an empty `results` while `total` is 1; and the swap moves the task history to the other index name (files 26 to 31) |
| Identity normalizer revert | `normalize/1` replaced by the identity function: all 3 determinism tests fail. Keeping only the per-render ids un-normalized fails the same-clock pair, where only per-render ids can differ. An unpinned plant fails at `assert relative_ages(clean_page) != relative_ages(planted_page)` with "both sides are exactly equal" |
| Conformance | 6 fake-client tests green; flipping the sort order to ascending fails 3 of them; a builder with an integer `duration` is rejected by the check task before any test runs |
| Plan-level focused tests | recordings, determinism and tracer files: 65 tests, 0 failures; check task prints `Fixtures OK: 1 scenario(s)` with `PGPORT=1` |
| Wider local mirrors | whole `scrypath_ops` suite 2 doctests and 632 tests, 0 failures; `mix precommit` exit 0; root `mix format --check-formatted`; root fixtures, package, fence, dependency-boundary and workflow-wiring tests 186, 0 failures; `ops_dependency_boundary_test --include integration --warnings-as-errors` on committed head `ab644292`: 2 tests, 0 failures, 183.5 s |
| Guard row | `git diff --exit-code origin/main` over both `phase173_fixture_source.ex` copies and `posture_live.ex` exits 0; the three lock files are identical to `origin/main`; no root `lib/` file changed |

## Failure table

| Entry | Surface | Source |
|-------|---------|--------|
| `invalid_document_id` | Meilisearch task | recording `05-task-failed-invalid-document-id-space-slash` |
| `missing_document_id` | Meilisearch task | recording `09-task-failed-missing-document-id-markup` |
| `index_not_found_task` | Meilisearch task (delete) | recording `10-task-failed-document-deletion-index-not-found` |
| `primary_key_no_candidate` | Meilisearch task | recording `11-task-failed-primary-key-no-candidate` |
| `oban_transport` | Oban error | `lib/scrypath/meilisearch/client.ex` |
| `oban_task_failed` | Oban error | `lib/scrypath/meilisearch/tasks.ex` |
| `oban_cancel_invalid_job` | Oban error | `lib/scrypath/oban/upsert_worker.ex` |

Oban 2.24's executor gives a returned error an empty stacktrace, so the stored error text is the single `** (Oban.PerformError) <worker> failed with <inspected return value>` line, and nothing is left out of the table's text (research assumption A3 is closed). The cannot-produce list (`payload_too_large`, `database_size_limit_reached`, `no_space_left_on_device`, per-tenant drift, minutes of lag, a per-document size limit, out-of-order overwrite, price-as-string) each carries a one-line reason.

## Planted-revert results (real files broken on purpose, then restored)

| Broken on purpose | What failed, and why |
|-------------------|----------------------|
| `Meili.task` writes `"duration"` as an integer | the check task, before any test: `{:task_shape, uid, "duration"}` for every task |
| fake client sorts oldest first | 3 of the 6 conformance tests |
| `oban_transport` source points at a missing file | the check task: `{:failures, {:failure_source_missing, :oban_transport}}` |
| `invalid_document_id` template says "is not valid" | the test that compares the table with the recorded error object |
| builder falls back to an inline error object | the check task: `{:task_shape, uid, "error"}` and `{:unknown_failure, uid}` |
| determinism test: identity `normalize/1`, un-normalized unique ids, unpinned plant | see the table above |

Every file was restored from a copy and the focused tests re-run green afterwards.

## Decisions Made

See `key-decisions` above. The two that matter most to later phases: the check compares types and key sets only, so a re-record cannot fail it for noise, and failure text can only enter a scenario through a table entry.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The first recording took the list pages after the swap**
- **Found during:** Task 1 (inspecting the recorded lists)
- **Issue:** The script listed document tasks after the swap, and a swap moves each index's task history to the other name, so the live index's pages were empty and `from=null` was requested.
- **Fix:** The script now takes the four list pages before the swap and adds the two post-swap document lists as evidence (files 30 and 31). The script also stops if page 1 has no `next`. Re-ran with a fresh container.
- **Files modified:** `fixtures/scrypath_fixtures/recordings/record.sh`
- **Commit:** `7fdbfe4e`

**2. [Rule 1 - Bug] Raw format characters in the first script**
- **Found during:** Task 1 acceptance (the perl scan of `record.sh`)
- **Issue:** The writing tool turned some of the `\uXXXX` text in the script into the characters themselves, so `record.sh` held a raw right-to-left override and a ZWJ. The recording was unaffected but the acceptance scan failed.
- **Fix:** The two hostile requests build their escapes from a `bs` variable (`${bs}u202e`), so the script is pure ASCII. Re-ran. The same care was taken in every Elixir file; tests read hostile text back out of the recording.
- **Files modified:** `fixtures/scrypath_fixtures/recordings/record.sh`
- **Commit:** `7fdbfe4e`

### Auto-added

**3. [Rule 2 - Missing critical] Escaper covers every non-ASCII character**
- **Found during:** Task 1
- **Issue:** The plan's escaper covered only the listed format characters, which would have left a raw Arabic letter (it can reorder neighbouring text in editors) and an emoji in the repository.
- **Fix:** It rewrites all non-ASCII as `\uXXXX`. That is a superset, still value-preserving, and the plan's perl scan passes.
- **Files modified:** `record.sh`, `PROVENANCE.md` (the escaping note)
- **Commit:** `7fdbfe4e`

**4. [Rule 2 - Missing critical] Three extra recordings and extra evidence tests**
- **Found during:** Task 1
- **Issue:** The 511-byte id boundary and the swap moving task history change what Phase 198 can rely on, and neither was in the plan's list.
- **Fix:** Files 07, 30 and 31, a test that `PROVENANCE.md` names every file, and a test that pins the F3 evidence so a server bump that changes it fails loudly.
- **Commit:** `7fdbfe4e`

**5. [Rule 2 - Missing critical] Builder details, `canceled_by` and `task_types`**
- **Found during:** Tasks 1 and 2
- **Issue:** `details_keys` would have failed every ordinary scenario (the builder left details empty); a canceled task with no `canceledBy` is not a shape the server produces; a real error on the wrong task type is not either.
- **Fix:** `Meili.task` derives details from the recorded key set per type and requires `:canceled_by` for a canceled task; failure entries carry `task_types` and the check enforces it. `logistify.ex` needed no change.
- **Files modified:** `meili.ex`, `failures.ex`, `check.ex`
- **Commits:** `7fdbfe4e`, `b8cd7a70`

**6. [Rule 1 - Bug] Type-checker warning in a closed-table test**
- **Found during:** Task 2
- **Issue:** Elixir 1.19's type checker warned that `Failures.entry!(:made_up)` can never match.
- **Fix:** The test passes an id the checker cannot see, so the call is a runtime test and the suite compiles warning-free.
- **Commit:** `b8cd7a70`

**Total deviations:** 2 auto-fixed bugs in the recording step, 3 auto-added hardening items, 1 test fix. **Impact:** the recording took three container runs (each removed its container; Docker's counts are identical after the last). No scope change.

`fake_meilisearch_client.ex` is in the plan's file list but was not changed: the conformance tests exposed nothing to fix.

## Issues Encountered

- The shared local Postgres logged `too_many_connections` (other projects' connections) during ops test runs. It did not affect any result, and the new tests that need no database do not touch it.
- Hosted CI was not run (nothing was pushed). The local mirrors above are the evidence, and the Docker lane scripts (`ecommerce-mounted`, `ecommerce-e2e`) were not run here by plan; Plan 05 owns them.
- The README's recordings pointer, which Plan 02 flagged as dangling, now resolves to `PROVENANCE.md`. No test pins that link yet.

## Known Stubs

None. No placeholder text or empty-value-to-UI data in the files this plan created or changed.

## Threat Flags

None. Mitigations recorded for T-196-09 (loopback random port, tmpfs, `--rm`, trap, no key), T-196-10 (closed table, source resolution, builders reject inline text), T-196-11 (Scrypath-owned values; the research example values grep is empty), T-196-12 (task-scoped name and label, `docker ps -a` empty, `docker system df` identical, image not removed) and T-196-13 (pure-ASCII recordings and script, perl scan empty).

## Next Phase Readiness

Plan 04 can build Shopadelic, Wikily and the Logistify steady and F1 stress states on these builders: a failed task is `failure: {entry_id, bindings}`, an Oban error is a `{entry_id, attempt, bindings}` tuple, and the check will reject anything else. Wikily's `index_not_found` states can use the recorded empty page and `index_not_found_task`. Plan 05 owns the permanent raw-character lint and the hostile set. Nothing blocks Plan 04.

## Self-Check: PASSED

- All 10 non-recording plan files and the 31 recorded bodies exist on disk (`[ -f ]`, `ls | wc -l` is 31).
- Commits `7fdbfe4e`, `b8cd7a70` and `ab644292` are ancestors of HEAD (`git merge-base --is-ancestor`); `rev-list --count` over the ledger range is 3.
- Every task `<acceptance_criteria>` re-run and passing: the container and loopback-port counts, the research-value grep, the raw-character perl scan, `pkgVersion`, 31 JSON files, `source:` count 8, tag count 7, no inline `"message" =>` in the builders, LazyHTML count 2, no bare-inequality assertion, F3 and `__reindex` counts 5 and 3.
- Plan-level `<verification>` re-run on the final head: the three test files (65 tests), the check task, `bash -n`, Docker leftovers and `docker system df`.
- No protected config file (`.planning/config.json`, `.planning/state.json`, `.impeccable/config.json`) staged in any commit; no commit deleted a tracked file.
