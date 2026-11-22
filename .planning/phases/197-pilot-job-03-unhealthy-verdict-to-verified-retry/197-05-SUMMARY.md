---
phase: 197-pilot-job-03-unhealthy-verdict-to-verified-retry
plan: 05
subsystem: ui
tags: [storybook, landing-page, preflight, ui-preview, docs, local-mirror, phase-pr, ci-cost, ops-ui, pause-1]
status: complete

# `commits` is measured from the plan ledger (`.git/gsd-plan-head-before-197-05`), never narrated:
# `git rev-list --count 472a3b1e..95d716ae` = 3 (landing page and preflight, docs, the one core fix; all squashed into
# `33aac70f` by PR #177), plus 1 for the Task 3 docs commit that carries this file. A commit cannot name its own hash, so
# `plan_head_after` is the last code commit; the docs commit and its squash merge are in the hand-off.
plan_head_before: 472a3b1e9c576088a142690672ee054d2ef3f094
plan_head_after: 95d716ae04d048efe888aac0adf7bc48544feb5d
commits: 4

requires:
  - phase: 197-01
    provides: "the catalog server (Endpoint, Router, serve task, port refusal), the storybook font fix, the fidelity probe (compare mode untried on a real page), the JOB-03 journey"
  - phase: 197-04
    provides: "57 story variations in 17 stories, the catalog contract test and its shared render pass, CatalogChecks, ledger row 11 of 12"
provides:
  - "welcome.story.exs (the Start here page) with data-catalog-main-sha, -head-sha, -dirty, -checkout and -epoch markers, reading build facts stored by the serve task at render time"
  - "_start.index.exs (root index): the page reads Start here in the sidebar and sorts first"
  - "serve task: build_info/1 (git runner injectable, 12-character shas, dirty flag, checkout, fixtures epoch, every git value degrades to unknown), port_verdict/3 (:free | :ours | {:held, holder}), landing-body fetch over loopback"
  - "RenderAll page targets ({path, :page}), page_url/2, page_markup/1, page_problems/1; contract test renders page stories through the shell and applies hygiene and copy to them"
  - "contract test: /storybook redirect, markers (unknown and stored), welcome copy claims, page font rule, build_info/1 and port_verdict/3 cases, storybook bundle font check with a plant"
  - "ui-review.mjs: parseCatalogMarkers, storybookErrors (one message per cause), checkStorybook (loopback only, 5 s), independent two-result preflight; selftest cases for each"
  - ".planning/UI-PREVIEW.json storybook block (4003 default, CATALOG_PORT override, start and stop commands), and in Task 3 its runtime fields and the 4013 deviation"
  - "AGENTS.md UI work (present tense), UI-REVIEW.md preflight paragraph, glossary Job level, playbook C1 and a Phase 197 history line"
  - "merged phase PR #177 (squash 33aac70fa7d6cb90dcc6eee34ca8cc599c52d214), required lanes green on the exact head"
  - "the storybook (port 4013) and the 4002 preview serving main 33aac70f, preflight green for both"
  - ".planning/research/storybook-catalog/PAUSE-1-PHASE-197.md (packet, deep links, empty feedback table, fold evidence and recommendation, findings, port deviation, Phase 198 sizing)"
  - "CI-EFFICIENCY finding 30 (the phase's hosted cost record)"
affects: [pause-1, phase-198, milestone-end-review]

tech-stack:
  added: []
  patterns:
    - "A page story reads build facts from :persistent_term at render time and prints them in data-catalog-* markers; a script reads the dead render"
    - "A loopback preflight check is a pure error function plus a thin fetch wrapper, each cause its own message and its own selftest"
    - "A page story renders in the storybook shell, where the catalog bundle does not load: it sets the product font itself and carries its own scoped layout rules"
    - "Run the local mirror of every required lane before the push: it found a real core failure that no focused test of Plans 01 to 04 could"
    - "Compare renders as canonical trees, never raw HTML: raw HTML differs by attribute order and session tokens between two starts of the same server"

key-files:
  created:
    - scrypath_ops/storybook/welcome.story.exs
    - scrypath_ops/storybook/_start.index.exs
    - .planning/research/storybook-catalog/PAUSE-1-PHASE-197.md
  modified:
    - scrypath_ops/catalog/lib/mix/tasks/scrypath_ops.catalog.serve.ex
    - scrypath_ops/test/support/catalog_render_all.ex
    - scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs
    - .planning/UI-PREVIEW.json
    - examples/scrypath_ecommerce/e2e/ui-review.mjs
    - examples/scrypath_ecommerce/e2e/ui-review.selftest.mjs
    - AGENTS.md
    - examples/scrypath_ecommerce/e2e/UI-REVIEW.md
    - GLOSSARY.md
    - .planning/reference/BRAND-ADOPTION-PLAYBOOK.md
    - .planning/reference/CI-EFFICIENCY.md
    - .planning/reference/README.md
    - test/support/release/shipped_docs.ex
    - test/release/shipped_docs_contract_test.exs

key-decisions:
  - "The welcome page sets font-family: var(--font-sans) and its own scoped layout rules: a page story renders inside the storybook shell, where storybook.js (the iframe's font fix) does not load, so the sandbox serif face showed through until the page set the font itself"
  - "A root index (_start.index.exs) labels the landing page Start here and sorts it first; without it the sidebar listed Welcome last"
  - "The serve task tells this catalog from another program by the data-catalog-main-sha=\" attribute with a substring check, because lazy_html is test-only; the contract test proves the substring verdict agrees with a parsed document"
  - "ui:preflight reports two independent results (preview and storybook), exits non-zero when either fails, and treats an unreadable remote as unverified for both; the storybook also refuses a served HEAD that differs from the checkout's HEAD and a checkout that does not include origin/main"
  - "The storybook serves on 4013, not 4003, because another project's process holds 4003; recorded in the storybook block, the Pause 1 note and the hand-off as a decision for the maintainer, with the move-back steps"
  - "The retained preview's pending Tailwind watcher output was proved generated and left in place instead of stashed, because the fast-forward does not touch that file"
  - "The Pause 1 note recommends keeping the fixtures project (revisit at the four phase173 host specs or v1.51) and cutting Phase 198 by default; both are the maintainer's call"

patterns-established:
  - "Plant one cause, assert that cause (carried): a removed marker and a forbidden phrase planted into the real welcome page each failed only their own check, then were restored and diffed"
  - "A tool run on its documented input for the first time finds the mismatch: the probe's compare mode needs a document, the parity capture writes fragments (recorded as a finding, not fixed)"

requirements-completed: [PILOT-04, PILOT-07, FLOW-01, FLOW-02, FLOW-03, FLOW-04]
requirements-partial:
  - "PILOT-06: the storybook, its landing page with main@sha, the block and the two-surface preflight are done and green, but it serves on 127.0.0.1:4013 and not the named 4003 (held by another project; maintainer decision recorded in the Pause 1 note)"

# Estimate versus actual (ADR-2629): estimateTokens (chars/4) over the realized diff, not a harness count.
actuals:
  tokens: 31600
  tasks: 3
  commits: 4

coverage:
  - id: C1
    description: "The storybook opens on a Start here page that prints main@sha, the served HEAD, a dirty flag, the checkout and the fixtures time in stable markers, says what the screens are and claims no approval"
    requirement: "PILOT-06"
    verification:
      - kind: integration
        ref: "scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs#start here page (redirect, markers unknown and stored, copy claims, page font)"
        status: pass
    human_judgment: false
  - id: C2
    description: "ui:preflight checks the storybook independently of the 4002 preview and reports both; stale, foreign, absent and non-loopback storybooks are refused, each with its own message"
    requirement: "PILOT-06"
    verification:
      - kind: unit
        ref: "examples/scrypath_ecommerce/e2e/ui-review.selftest.mjs (storybookErrors, parseCatalogMarkers, checkStorybook against a real loopback server)"
        status: pass
    human_judgment: false
  - id: C3
    description: "The serve task exits 0 when the port holder is this catalog and non-zero, naming the holder, for anything else, and never signals it"
    requirement: "PILOT-06"
    verification:
      - kind: integration
        ref: "scrypath_ops contract test port_verdict/3 cases, plus a local run against 4013 (ours, exit 0) and 4003 (held by another project's beam.smp, exit 1)"
        status: pass
    human_judgment: false
  - id: C4
    description: "Every required lane ran locally on the pushed head or its predecessor with a recorded result; the phase PR is squash-merged with every required context green on the exact head and no release PR"
    requirement: "FLOW-03"
    verification:
      - kind: command
        ref: "mix verify.core, verify.package, verify.repository_contracts, verify.ops_ui, verify.ecommerce_mounted, the CI Node step; hosted run 45041897678 on 95d716ae"
        status: pass
    human_judgment: false
  - id: C5
    description: "The storybook and the 4002 preview serve current main from the retained checkout, with 4002 data unchanged, and ui:preflight reports both green"
    requirement: "PILOT-06"
    verification:
      - kind: command
        ref: "npm run --silent ui:preflight from the retained checkout (JSON under Task 3 below): ok true, preview ok, storybook ok, markers main 33aac70fa7d6 equal to origin/main; 4002 row counts and my-search.json hash equal before and after"
        status: pass
    human_judgment: false
  - id: C6
    description: "The Pause 1 note carries the packet, nine deep links that all answer 200 (page and iframe), the empty feedback table, the fold evidence and recommendation, every finding with D1 and D3 as fixed, the port deviation and the Phase 198 sizing"
    requirement: "PILOT-07"
    verification:
      - kind: command
        ref: "curl status of each deep link and iframe URL against the running storybook (table under Task 3); the note's feedback table header appears exactly once"
        status: pass
    human_judgment: false
  - id: C7
    description: "The phase's hosted cost is recorded with run ids, job ids, a same-day control and the main run after the merge, each verified against the GitHub API"
    requirement: "FLOW-03"
    verification:
      - kind: command
        ref: "gh api jobs/<id> for the five ops-ui jobs and gh run view --log cache lines; CI-EFFICIENCY finding 30"
        status: pass
    human_judgment: false
---

# Phase 197 Plan 05: Landing page, preflight, ship, refresh and Pause 1 Summary

**The storybook now opens on a Start here page that says where it comes from (`main@sha`, served HEAD, checkout, frozen time); `npm run ui:preflight` checks it independently of the 4002 preview and refuses an old or foreign one; the whole phase shipped as PR #177 (squash `33aac70f`) with every required lane green on the exact head; both preview surfaces now serve that `main` from the retained checkout with the 4002 data untouched (the storybook on 4013, because another project holds 4003); and the Pause 1 note, the 4013 deviation and the hosted cost record are written. The run stops here and waits for the maintainer.**

## Status

| Task | State |
|---|---|
| 1. Landing page to preflight | done, commit `2a5891d5` |
| 2. Docs, local mirror, PR, hosted samples, merge | done: docs `ce9ab33c`, one mirror fix `95d716ae`, PR #177 merged as `33aac70f` |
| 3. Refresh 4003 and 4002, probe, Pause 1 note, CI record, docs PR, stop | done as far as this file can say: refresh, probe, note and cost record are below; the docs PR number, its merge, its checks and the final refresh happen after this file is committed and are in the hand-off (see "After this file merges") |

No phase or plan completion verb ran, STATE.md and ROADMAP.md are untouched, and no `198-*` directory exists.

## Task 1: what was built and how it was checked

- **Serve task** (`scrypath_ops.catalog.serve.ex`): `build_info/1` reads `origin/main` and `HEAD` as 12-character shas, whether `git status --porcelain` is empty, the top-level checkout and the fixtures epoch; any git failure or a non-sha answer reads `unknown`. It is stored with `:persistent_term` before the endpoint starts. `port_verdict/3` is `:free` (nothing listens), `:ours` (the listener's `/storybook/welcome` carries `data-catalog-main-sha="`) or `{:held, " by <holder>"}`. `:ours` prints "already serving" and exits 0; held raises and names the holder from `lsof`; nothing is ever signalled. The landing fetch uses `Req` over loopback with a 2 s timeout.
- **Landing page** (`welcome.story.exs`, a `:page` story): the five markers in a definition list, what the screens are (same components as the real app, made-up data for Logistify, Shopadelic and Wikily, static renders, time frozen at 2026-11-20 14:00 UTC), the five tiers in the glossary's words, the one persona in a paragraph with no invented name, where behavior lives, that the frame is upstream's, and "Nothing here is an approved design". The root index `_start.index.exs` labels it Start here and sorts it first.
- **Contract test**: page stories render through the shell (`RenderAll.targets/1` returns `{path, :page}`; the shared setup renders each once) and get DOM hygiene (tier `:other`, no main-count rule) and copy lint over their own content, not the upstream shell. The unsupported-target refutation stays. New cases: `/storybook` redirects to `/storybook/welcome`; exactly one node per marker, `unknown` with nothing stored and the stored values otherwise; the page's claims; the font rule; `build_info/1` with a fake runner, with failing, raising and junk runners, and with real git (shape only: a shallow hosted checkout has no `origin/main`); `port_verdict/3` for free, ours (a real dead render, cross-checked with a parsed document), foreign, unanswered, and a page that only mentions the marker in text; and the bundle-font check (`storybook.js` sets the product font on the iframe body; removing the assignment, or swapping the family, reports `:missing_body_font`).
- **Preflight**: `storybookErrors/1` (unreachable; no markers; checkout mismatch; printed `main@sha` differs from the local `origin/main`; started at another HEAD than the checkout's; local `origin/main` stale against the remote; checkout does not include `origin/main`), `parseCatalogMarkers/1`, `checkStorybook/1` (loopback only, 5 s, no redirects, refuses a block whose url and port disagree) and a `preflight()` that runs the 4002 check and the storybook check independently, prints both in one JSON document with an overall `ok`, writes each failure to stderr and exits 1 when either fails. An unreadable remote makes both read as unverified.
- **UI-PREVIEW.json**: a `storybook` block (url, port 4003, `port_env` `CATALOG_PORT`, checkout and branch of the retained preview, `base_main`, landing, start, stop, seed, status, `runtime_checked_at: null`). The pre-existing top-level `url`, `container` and `compose_project` are unchanged (checked with `node -e`).

### Local acceptance evidence (Task 1)

- A catalog started with `CATALOG_PORT=4013` from this checkout printed `main@84afaba095a0 (HEAD 472a3b1e9c57, uncommitted changes: true)` and served the markers: main `84afaba095a0`, head `472a3b1e9c57`, dirty `true`, checkout `/Users/jon/projects/scrypath`, epoch `2026-11-20T14:00:00Z`; the page says nothing here is an approved design.
- Port verdicts: a second start on 4013 said "already serving" and exited 0; a start on 4003 exited 1 with "Port 4003 on 127.0.0.1 is already in use by beam.smp (pid 22117)" and stopped nothing.
- Preflight from this checkout, block temporarily pointed at 4013 (restored by `diff`): `storybook.ok: true`, markers as above, `local_main` and `remote_main` both `84afaba095a0`; `preview.ok: false` with "Preview source mismatch: .../ui-experience-reconciliation; expected /Users/jon/projects/scrypath" because the 4002 container mounts the other checkout. That is the independence the plan asks for (the 4002 failure did not hide the storybook result). After the Task 1 commit moved HEAD, the same preflight refused the running storybook: "Storybook was started at HEAD 472a3b1e9c57; this checkout is at 2a5891d54f04. Restart the storybook."
- Plants: removing `data-catalog-dirty` from the real page failed exactly the two marker tests ("expected exactly one [data-catalog-dirty] node"); a forbidden casing phrase planted into the page failed exactly the page copy check (`control-room-casing`) and the page-claims test; both restored and `diff`ed empty. The bundle-font plant is a standing test.
- Screenshot of the page in the storybook frame (Playwright, light): the first render drew the content in serif (the sandbox face) with no section spacing because the product stylesheet has no spacing utilities for this file; both fixed (see Deviations), then re-checked visually.
- Task 1 verify: `mix compile --warnings-as-errors`, the contract test (36 tests, 0 failures, 1.6 s), `npm run ui:review:selftest` (35 tests), the JSON key check, and `mix precommit` (2 doctests, 804 tests, 0 failures).

## Task 2: docs, guard rows, local mirror, PR, hosted samples, merge

### Docs (commit `ce9ab33c`)

AGENTS.md "UI work" now describes the storybook on 127.0.0.1:4003 in the present tense (start, status, refresh, port-collision rule; the 4002 preview stays the mounted-behavior surface) and the preflight sentence names the storybook check; `Until the catalog` is gone. UI-REVIEW.md's preflight paragraph lists what the storybook check compares. GLOSSARY.md's Job level is "one surface state in one persona's `JOB-*` situation". Playbook C1 uses Primitive, Pattern, Area, Surface, Job (and keeps the old list and provenance), and a 2026-11-22 history line records what Phase 197 proved. The acceptance greps all pass (`Until the catalog` 0, `CATALOG_PORT` 2, `catalog.serve` 1, `one surface state` 1, `a whole page in one persona` 0, `Surface, Job` 2).

### Guard rows (on `95d716ae`, the pushed head)

| Guard | Result |
|---|---|
| Phase 173 fixture source files unchanged against `origin/main` | pass (no diff) |
| `phase173` occurrences in `posture_live.ex` at least 27 | 27 |
| `mix.lock`, `scrypath_ops/mix.lock`, demo `mix.lock` unchanged | pass |
| protected config files in the PR diff | none |
| `lib/` or `.github/` in the PR diff | none |
| `feat` or `fix` commit subjects | none (7 chore, 10 docs, 6 test, then 1 docs and 1 chore and 1 test from this plan) |
| journey file commits after its baseline `d913b8b6` | none |
| open release-please PRs before and after the merge | 0 and 0 |

### Local mirror (every required lane; results and wall times)

| Lane | Command | Result | Wall time | Head |
|---|---|---|---|---|
| cheap set | `bash scripts/ci/pre_push.sh` | 11 steps pass, none skipped (actionlint, format, lock checks, compile, Credo, workspace clean, wiring and fence tests, Node classifier, BEAM cache and token and state-pair tests) | 71 s | `ce9ab33c` |
| core | `mix verify.core --exclude integration --exclude docs_contract` | **first run red**: 6 properties, 1337 tests, 1 failure; rerun after the fix green: 6 properties, 1337 tests, 0 failures | 563 s, 594 s | `ce9ab33c`, `95d716ae` |
| package | `mix verify.package` | pass | 69 s | `ce9ab33c` |
| repository-contracts | `mix verify.repository_contracts`; `node scripts/ci/ui_literal_policy.cjs` | 184 tests, 0 failures; literal policy pass (30 finding occurrences, unchanged) | 516 s, 1 s | `95d716ae` |
| CI Node step | the five `ecommerce_*` and `ui_state_pairs` files (tap), the two path classifier files, `npm run ui:review:selftest` | 162 of 162, 52 of 52, 35 of 35 | 593 s, 3 s, under 1 s | `ce9ab33c` |
| ops-ui | `HEX_HTTP_TIMEOUT=120 mix verify.ops_ui`; `cd scrypath_ops && mix precommit` | boundary test 3 of 3, then 2 doctests and 804 tests, 0 failures; precommit the same 804 | 318 s, 38 s | `ce9ab33c` |
| ecommerce-mounted | `mix verify.ecommerce_mounted` (Docker, `BUILDX_CONFIG` in the scratchpad) | pass: static and runtime dependency boundary (test and prod graphs), then 5 browser tests including `operator.spec.ts` "verifies a rendered recovery for the non-first Variant schema" and "promotes only this returned task pair"; verifier ownership `containers=0 networks=0 volumes=0 cleanup=clean` | 457 s | `95d716ae` |
| backend | not run | no root `lib/` change, proven by the guard row | n/a | n/a |

Heads: the mirror started on `ce9ab33c` (Task 1 plus docs). The first core run failed one test; the fix is `95d716ae`, which changes two root test files and nothing the package, ops-ui or Node lanes read, so `package`, `ops-ui` and the Node step were not repeated; `core`, `repository-contracts` and `ecommerce-mounted` ran on `95d716ae`. The hosted runs below are on `95d716ae`.

**The red result and its cause (deviation 1).** `Scrypath.Release.ShippedDocsContractTest` "every Mix task source outside lib/ and test/ is read by the derivation" failed because Plan 01's storybook task lives in `scrypath_ops/catalog/lib/mix/tasks/`, a tree the repo-only task derivation (`test/support/release/shipped_docs.ex`, `@task_source_globs`) did not read. Plans 01 to 04 never ran the core lane, so only this mirror could find it; hosted CI would have, after about 16 minutes. Fixed at the cause: the glob is added (the task is dev and test only, repo-only by construction, so no shipped file may tell an adopter to run it) and the test now asserts the task name appears. The focused test file passed (40 tests) before the commit.

### Docker (task-scoped, no prune)

`docker system df` before and after the whole mirror: images 246 (96.81 GB), containers 56 (7.843 GB), local volumes 195 (37.57 GB) identical; build cache 242 records (30.13 GB) before and 243 (31.39 GB) after. The lane's two image tags, `scrypath_ecommerce_verify_focused_95d716ae_86837-web:latest` and `-browser:latest`, were removed by exact name; the verifier removed its own containers, network and volumes; the dependency-boundary project `scrypath_dependency_boundary_20261122t155713z-87098-2938711865` cleaned itself (`cleanup status=passed`). The image list is identical to the one saved before. One BuildKit cache record (about 1.3 GB) remains: BuildKit's cache is shared across projects and not attributable by label, so it was not pruned. A network `scrypath_ecommerce_verify_full_53268690_81314_default` exists that is not this run's (another session's `full` scope run); it was left alone. The retained 4002 preview's containers were not touched.

### Phase PR #177

- Draft first, `test(ops-ui): cover JOB-03 end to end and serve its components in the storybook`; body says plainly that it fixes D1 and D3 in `scrypath_ops` only, makes no root `lib/` change and releases nothing, lists the mirror table, and ends with the attribution line. Squash-merged as `33aac70fa7d6cb90dcc6eee34ca8cc599c52d214` at 2026-11-22T16:30:20Z with the repository's `PR_BODY` squash setting overridden by an explicit short body ending in the Co-Authored-By line.
- Required contexts (branch protection: backend, core, ecommerce-mounted, package, repository-contracts, ops-ui (path-scoped)) all `success` on head `95d716ae`, read through `gh api .../check-runs` before merging; `ops-ui-path` reported. `mergeStateStatus` was UNSTABLE only because the advisory `deep-quality` job failed at `Run elixir scripts/ci/dependency_audit.exs` (the known advisory; the latest main run fails it the same way). Branch was not behind main.
- Both Task 2 verify commands pass (MERGED with a `test(ops-ui):` title; no protected file in the merge commit).

### Hosted jobs on the PR head (run 45041897678, attempt 1 unless noted; re-read with `gh api` in Task 3)

| Job | Seconds |
|---|---|
| ops-ui (path-scoped), job 137268032415 | 423 (step `Run mix verify.ops_ui` 384) |
| core (required) | 468 |
| repository-contracts (required) | 605 |
| ecommerce-mounted (required), job 137268029920 | 922 (bake 289, E2E proof 580) |
| package (required) | 100 |
| backend (required) | 61 |
| ops-ui-path, ecommerce-path, compat-path | 12, 12, 15 |
| deep-quality (advisory) | 269, failed at the dependency audit (known) |

### Hosted ops-ui cost: first run, warm rerun and same-day control (all re-verified with `gh api` in Task 3)

| Sample | Run, attempt | Job id | Job s | Step s |
|---|---|---|---|---|
| PR first attempt | 45041897678, 1 | 137268032415 | 423 | 384 |
| PR warm (rerun of the job) | 45041897678, 2 | 137272586339 | 450 | 404 |
| Same-day control (rerun of the latest green main push run, `d69fbb82`) | 44987197491, 2 | 137272601737 | 452 | 402 |
| Control's original attempt | 44987197491, 1 | 137100290739 | 577 | 539 |
| Main push run after the merge (`33aac70f`) | 45044204458, 1 | 137275188458 | 450 | 409 |

**Warm minus control: -2 s in the job, +2 s in the step.** The catalog contract test (about 1.6 s locally, 36 tests) and the whole phase add nothing measurable to the hosted `ops-ui` job. Against finding 25's 428 s warm line the PR's 450 s is higher, but the same-hour control is 452 s, so the difference is the day's runner speed and not this phase. The same-day spread across the four fresh samples is 29 s in the job and 25 s in the step.

**Correction made in Task 3 (the earlier text called the first attempt and the main run "cold").** The cache logs show both BEAM caches were restored in all four samples (`beam-v1-downloads` hit on its primary key, `beam-v1-resolved` hit on its primary key or its restore key, no "Cache not found"), because this phase changed no `mix.exs`, lock or manifest file the cache key digests. So these were first runs with caches, not cold-cache samples in the sense of CI-EFFICIENCY findings 25, 26 and 29, and finding 26's mechanism did not apply on this merge. The older "cold 577 s" control attempt was not re-read for its cache state.

### Main push run after the merge (run 45044204458, `33aac70f`)

Conclusion **success**. `ops-ui (path-scoped)` 450 s (step 409 s); `ecommerce-mounted` job 137275187544 922 s (bake 298 s, E2E proof 572 s); `core` 478; `repository-contracts` 596; `package` 107; `backend` 57; advisory `phoenix-example` 84; advisory `deep-quality` 262 (failed at the dependency audit, as on the PR; the run still concludes success). The Release Please run on the same commit (45044204493) succeeded and opened nothing: open PRs 0 before and after.

## Task 3: refresh, probe, Pause 1 note, cost record

### Retained preview checkout (`/Users/jon/projects/scrypath/.claude/worktrees/ui-experience-reconciliation`, branch `ui/next`)

- **Preflight before the refresh** (from its `examples/scrypath_ecommerce`): exit 1, `Checkout does not include origin/main. Reconcile newer merged work before reviewing the current UI.` The checkout was at `9b6ec911`, 11 commits behind `origin/main` `33aac70f`; no JSON is printed for that failure. The refresh is the repair.
- **Pending work, classified** (`git status --porcelain --untracked-files=all`): ` M scrypath_ops/priv/static/assets/css/app.css` and `?? examples/scrypath_ecommerce/priv/playbooks/my-search.json`.
  - `app.css` is generated output of the preview's Tailwind watcher. Its diff is 42 insertions and no deletions, all Tailwind's built-in `animate-spin`, `-ping`, `-pulse` and `-bounce` theme variables, utilities and keyframes; the file is `tailwindcss v4.1.12` output; the web container runs `mix tailwind scrypath_ops --watch`. Confirmed by building `assets/css/app.css` with the checkout's own Tailwind 4.1.12 binary into the scratch directory: **byte-identical** to the working-tree file.
  - `my-search.json` is untracked and was left in place; its SHA-256 `3c8de6b45b9b3bc6f5daff18ce71da1ee817b5270ddc57a8c064f59a1a42c0f7` is the same before and after.
  - **No stash was taken** (deviation 8): the fast-forward does not touch `app.css`, so git left the generated file in place and nothing needed stashing, which also avoids the repository's shared stash list. Stash name: none. Nothing authored or unclassifiable was found, so nothing was discarded and nothing stopped the refresh.
- `git fetch origin main`, then `git merge --ff-only origin/main`: `9b6ec911` to `33aac70fa7d6cb90dcc6eee34ca8cc599c52d214` (fast-forward).

### 4002 preview refresh (data preserved)

`docker compose -f compose.yaml -f compose.dev.yaml -f compose.preview.yaml up -d --no-deps --force-recreate web` from the retained checkout's `examples/scrypath_ecommerce` (the compose file set the running container already carried, so the same project `scrypath_ecommerce`). Only the web container was recreated; Postgres and Meilisearch kept running (up 3 days). The new container has `DEMO_SEED_ON_START=0` and `MIX_ENV=dev`; its log shows the CSS watcher built (`tailwindcss v4.1.12`, done in 33 ms) and `GET /` answered; `http://127.0.0.1:4002/` and `/admin/search` both returned 200 about 10 s after the recreate.

| Row counts (`scrypath_ecommerce_dev`) | Before | After |
|---|---|---|
| products | 19 | 19 |
| tenants | 3 | 3 |
| categories | 8 | 8 |
| variants | 21 | 21 |
| oban_jobs | 24 | 24 |
| scrypath_ops_saved_searches | 3 | 3 |
| schema_migrations | 3 | 3 |

`docker system df` before and after the refresh: images 246 (96.81 GB) and volumes 195 (37.57 GB) identical, containers 56 (7.843 GB then 7.841 GB, the web container's recreate), build cache 243 (31.39 GB) identical. The image list is identical to the saved one; nothing was pruned, and no volume, network or image of the retained preview was removed.

### Storybook (port 4013)

- `mix deps.get` in the retained `scrypath_ops` fetched the locked set only (2 s; no lock file changed).
- **Port 4003** was still held at the start: `lsof -nP -iTCP:4003 -sTCP:LISTEN` shows `beam.smp` pid 22117, started Sat Nov 21 09:34:22 2026 (Erlang 29.1.2), working directory `/Users/jon/projects/fablebook/hosts/operator`. It was not contacted or signalled. **The storybook serves on 4013 as the recorded deviation** (deviation 9), started with `CATALOG_PORT=4013` and the block's `start` command from the retained `scrypath_ops` (first answer about 35 s after the start, most of it the dev compile). Move-back: the four steps in the `storybook.deviation.move_back` field of `.planning/UI-PREVIEW.json` and the Pause 1 note (free 4003; stop and start without `CATALOG_PORT`; set the block's url and port to 4003 and delete the deviation; run preflight). The 4003 path itself has not been run, because the port is held.
- Landing markers: `main` `33aac70fa7d6` (equal to `git rev-parse --short=12 origin/main`), `head` `33aac70fa7d6`, `dirty` `true` (the pending `app.css` and `playbooks/` files), checkout the retained path, epoch `2026-11-20T14:00:00Z`.
- **Preflight, both surfaces green.** The committed block names 4003 until the docs PR merges, so the retained checkout's copy of `.planning/UI-PREVIEW.json` was temporarily pointed at 4013 for the run (deviation 10) and is restored from a saved copy before the final fast-forward. Command and output (`npm run --silent ui:preflight`, exit 0, saved at `.../scratchpad/preflight-after-refresh.json`):

```json
{
  "ok": true,
  "checkout": "/Users/jon/projects/scrypath/.claude/worktrees/ui-experience-reconciliation",
  "command_cwd": "/Users/jon/projects/scrypath/.claude/worktrees/ui-experience-reconciliation/examples/scrypath_ecommerce",
  "branch": "ui/next",
  "source": {
    "head": "33aac70fa7d6cb90dcc6eee34ca8cc599c52d214",
    "tree_sha256": "acc1c199aa26e482df77d20800efe364bc60426a0ca3c6fff90caf678664e26d"
  },
  "runtime": {
    "container": "scrypath_ecommerce-web-1",
    "source_match": true,
    "mount": "/Users/jon/projects/scrypath/.claude/worktrees/ui-experience-reconciliation",
    "main_included": true,
    "main_ref": "33aac70fa7d6cb90dcc6eee34ca8cc599c52d214"
  },
  "preview": { "ok": true },
  "storybook": {
    "ok": true,
    "url": "http://127.0.0.1:4013/storybook/welcome",
    "markers": {
      "mainSha": "33aac70fa7d6",
      "headSha": "33aac70fa7d6",
      "dirty": "true",
      "checkout": "/Users/jon/projects/scrypath/.claude/worktrees/ui-experience-reconciliation",
      "epoch": "2026-11-20T14:00:00Z"
    },
    "local_main": "33aac70fa7d6",
    "remote_main": "33aac70fa7d6",
    "errors": []
  },
  "pending_work": [
    " M .planning/UI-PREVIEW.json",
    " M scrypath_ops/priv/static/assets/css/app.css",
    "?? examples/scrypath_ecommerce/priv/playbooks/my-search.json"
  ]
}
```

- **Restart stability** (stop by pid file, start again, compare the canonical iframe documents): the project's own canonical form (`ScrypathOps.Test.HtmlCanon.digest`, run with `MIX_ENV=test mix run --no-start`) gave identical digests before and after a restart for `surfaces/failed_sync` `shopadelic_failed_journey` light (`0bf502718a9de489...`) and dark (`0d4176ccc81d1584...`) and for `surfaces/search_health` `shopadelic_failed_journey` light (`750158ca6e903ea7...`). The raw HTML differed by one to three bytes between starts (attribute order on a Heroicons svg, session tokens). My first comparison used a quick regex normalizer, which both mangled `data-phx-session` and could not see attribute order, and reported a difference; the HtmlCanon result is the one that counts and matches the project's rule never to compare raw HTML (deviation 12).

### Fidelity probe, compare mode, first run on a real page (non-gating)

The real page dump is `shopadelic_failed_journey__health.html`, written by the parity capture script (`197-parity-capture.exs` copied to `scrypath_ops/test/zz_parity_capture_test.exs`, run, deleted; 59 files; the copy is gone and `git status` is clean of it). Commands run from `examples/scrypath_ecommerce` against `--base http://127.0.0.1:4013 --compare surfaces/search_health:shopadelic_failed_journey`, light and dark, 1280 by 900, the default five selectors, twelve properties each.

| Run | Input | Result |
|---|---|---|
| 1, as the plan described | the dump as written (a LiveView fragment, no `<head>`) | exit 1, **66 DIFFERENT** lines: the real side read Times, black, no padding and no border (no stylesheet loaded). Tool-input mismatch, not a catalog difference |
| 2 | the same fragment wrapped in a minimal document (`<!DOCTYPE html>`, a `<link rel="stylesheet" href="/assets/css/app.css">`, the fragment in `<body>`) | exit 0, **`RESULT: no differences`**: all five selectors identical in light and dark |

What run 2 shows: the story and the real screen agree on those twelve properties at those five selectors. What it does not: other selectors, other viewports, the real layout shell around the page, or the `@import ... layer(app)` versus `<link>` cascade difference. The mismatch itself is recorded as a finding in the Pause 1 note (the capture script writes fragments; the probe wants a document) and not fixed (FLOW-04).

### Pause 1 note

`.planning/research/storybook-catalog/PAUSE-1-PHASE-197.md` (front matter `date: 2026-11-22`, `phase: 197`): the five-line packet, the 60-second tour, nine linked screens with the question each answers, the copy defects, the empty feedback table with its rules (header appears exactly once), the fixtures fold evidence and recommendation (keep; revisit at the four `phase173` host specs or v1.51; the maintainer decides), the findings (D1 and D3 fixed with the PR link; F1, F2, F3, F4, D2, the `dashboard_routes` guard, Phase 195 IN-03, Phase 196 IN-01 and IN-03, the probe result, the verified-test outcome), the port deviation as its own section, and what sizes Phase 198 (recommendation: cut by default; FLOW-05 runs next if cut).

**Deep links** (checked 2026-11-22 against the running storybook; page status then bare iframe status; an unknown variation id answers 500, so 200 proves the id exists):

| Page | Variation | Theme | Page | Iframe |
|---|---|---|---|---|
| `welcome` | none | none | 200 | not applicable (a page story) |
| `jobs/job_03_on_call_recovers_failed_sync` | `shopadelic_failed_journey_arrived_from_health` | light | 200 | 200 |
| `jobs/job_03_on_call_recovers_failed_sync` | `shopadelic_failed_journey_retry_queued` | light | 200 | 200 |
| `surfaces/search_health` | `shopadelic_failed_journey` | light | 200 | 200 |
| `surfaces/search_health` | `shopadelic_failed_journey` | dark | 200 | 200 |
| `surfaces/failed_sync` | `shopadelic_failed_journey` | light | 200 | 200 |
| `areas/failed_row` | `shopadelic_failed_journey_retryable` | light | 200 | 200 |
| `areas/failed_row` | `shopadelic_failed_journey_ineligible_task` | light | 200 | 200 |
| `areas/failed_row` | `shopadelic_hostile_ids_long_error` | light | 200 | 200 |
| `areas/recovery_status` | `shopadelic_failed_journey_queue_done_backend_pending` | light | 200 | 200 |
| `areas/recovery_status` | `shopadelic_failed_journey_verified` | light | 200 | 200 |
| `areas/recovery_status` | `shopadelic_failed_journey_unavailable` | light | 200 | 200 |
| `areas/health_verdict`, `areas/health_schema_row`, `areas/failed_summary` (F1 stories) | `logistify_history_over_limit_f1`, `..._not_checked`, `..._load_error` | light | 200 each | 200 each |

**Three copy defects are now confirmed as rendered**, read from the page text in Chromium with a scratch script (extra evidence, read-only): "3 sync jobs and 1 Meilisearch tasks failed" (Search health), "Check detail: :receipt_unavailable." (unavailable recovery state) and a space before the period in "...add or update records in shopadelic_product ." (retry receipt; the `ops_inline_code` text sits on its own lines inside `<code>`). The others stay as the plan summaries recorded them (not re-checked in a browser).

**Fold evidence recomputed with grep:** one consumer (`scrypath_ops`; the demo host does not list the project); 14 files name it by path or name in config and contract tests (the Phase 196 estimate of about 20 also counts `.dockerignore`, CI workflow and classifier lines that mention `fixtures/`); 23 more use the module name only; 6 functions still have no caller (`Logistify`, `Shopadelic` and `Wikily` `states/0`, `Meili.types/0`, `Meili.statuses/0`, `Bulk.max_rows/0`; `ObanJob.states/0` now has one, in `Check`).

### CI-EFFICIENCY finding 30

Written in `.planning/reference/CI-EFFICIENCY.md` after finding 29: the PR first attempt, warm rerun and same-day control (run ids, attempts, job ids, seconds), warm minus control -2 s job and +2 s step, the main run after the merge, the PR run's other lanes, the bake step (289 s PR, 298 s main), the catalog contract test's local time (36 tests, about 1.6 s), the cache correction (no cold samples: all four restored both caches), local-versus-hosted notes (`core` 594 s local against 468 s hosted; `ops-ui` 318 s against 423 s), the lesson that `gh run rerun --job` waits for the whole run, and the revisit triggers (finding 29's trigger is answered). Every number was re-read with `gh api` for this task.

### UI-PREVIEW.json

The top-level 4002 runtime fields (`base_main`, `implementation_head`, `status`, `runtime_checked_at`, `runtime_status`) and the `storybook` block (`url` and `port` 4013, `base_main`, `status`, `runtime_checked_at` 2026-11-22T16:50:36Z, and a `deviation` object with the holder, pid, working directory, date, the 4013 start command and the four move-back steps) were updated. The pre-existing top-level `url`, `container` and `compose_project` are unchanged, and the `storybook` keys the Task 1 verify requires are all present.

### Docs PR: local check before the push (merge point 2)

The docs commit changes `.planning/` files only (the Pause 1 note, `UI-PREVIEW.json`, `CI-EFFICIENCY.md`, this file, the `reference/README.md` index line). Run on the exact contents: `bash scripts/ci/pre_push.sh` **11 steps pass** (76 s, machine load about 9) and `node --test scripts/ci/ui_preservation.test.cjs` **53 of 53** (the preservation script reads the top-level `url`, `container` and `compose_project` of `UI-PREVIEW.json`, unchanged). **Not run locally:** `core`, `package`, `repository-contracts`, `backend` (about 10 minutes each for core and repository-contracts). Reason: the diff touches no code, workflow, lock or test file, and a grep of every root test that reads `.planning/` shows they read `ROADMAP.md`, `PROJECT.md`, `STATE.md`, `REQUIREMENTS.md`, `CLAIM-OWNER-MAP.md` and archived milestone files, none of which this commit changes; `no_human_gates_contract_test` scans `*-PLAN.md`, `*-VERIFICATION.md` and `*-UAT.md`, not these. It is a known risk that is bounded by that read-set, not an assumption. The path-scoped heavy lanes (`ops-ui`, `ecommerce-mounted`, compatibility) should skip and still report, as finding 28 measured; whether they did is in the hand-off.

## Deviations from Plan

1. **[Rule 1 - Bug, found by the mirror] The core lane failed one test because the storybook task's tree was not in the repo-only derivation.** Fixed at the cause in `95d716ae` (two root test files); see above. Files: `test/support/release/shipped_docs.ex`, `test/release/shipped_docs_contract_test.exs`. The plan lists no root test among Task 2's files; the PR body says so.
2. **[Design] A root index `_start.index.exs`** (the plan said none was needed). Without it the sidebar listed the page last, as "Welcome", while the app opened on it; the index labels it Start here and sorts it first. One file, eight lines.
3. **[Design] The welcome page sets its own font and layout.** A page story renders inside the storybook frame, where `storybook.js` (which fixes the iframe body font) does not load, so the page first drew in serif; and the committed product stylesheet is built from the app's own markup and lacks the spacing utilities the first draft used. A scoped `<style>` block (outside the literal ratchet roots) fixes both; a test pins the font rule. The Phase 197 playbook line records the lesson.
4. **[Design] `port_verdict` uses a substring check for the marker, not LazyHTML.** The plan said LazyHTML in the task; `lazy_html` is a test-only dependency and the serve task runs in dev. The test cross-checks the substring verdict against a parsed document for the real page, a foreign page and a page that only mentions the marker in text.
5. **[Design] Preflight output shape.** The success document keeps `checkout`, `command_cwd`, `branch`, `source`, `runtime` and `pending_work` and adds `ok`, `preview` and `storybook`; on a 4002 failure `runtime` is null. Run it as `npm run --silent ui:preflight` to get JSON without npm's banner lines. The storybook check also refuses a served HEAD different from the checkout's and a checkout that does not include `origin/main`, which the plan did not list (a restarted-too-late storybook is the stale case that matters most).
6. **[Design] Local mirror ran as streams, and `core`, `repository-contracts` and `ecommerce-mounted` ran on `95d716ae`.** See the heads note above.
7. **[Accepted, carried] Port 4003** was held by another project's `beam.smp` (pid 22117) while Task 1 was proven, so the local run used `CATALOG_PORT=4013`. The committed block keeps 4003 as the configured default until Task 3.
8. **[Design, Task 3] No stash of the retained checkout's pending `app.css`.** The plan said to stash generated watcher output. The file was proved generated (byte-identical to a fresh build with the checkout's Tailwind) and the fast-forward does not touch it, so git left it in place; the shared stash list stayed untouched (it holds an unrelated 2026-10-02 entry) and nothing was discarded.
9. **[Accepted, Task 3] The storybook serves on 4013, not 4003** (context rule W5). Holder, pid, working directory, date and the move-back steps are in the `storybook.deviation` field, the Pause 1 note and the hand-off. The configured default in the start command and the roadmap stay 4003.
10. **[Design, Task 3] The preflight in the retained checkout ran with that checkout's copy of the block temporarily pointed at 4013.** The committed block names 4003 until the docs PR merges, and preflight reads the port from the block in the checkout it runs from. The copy is restored from a saved original before the final fast-forward (a modified `UI-PREVIEW.json` there would also block it).
11. **[Finding, Task 3] The probe's compare mode needs a full document and the parity capture writes LiveView fragments.** The first run reported 66 differences from that mismatch; the second, with the fragment wrapped in a minimal document, reported none. Recorded in the Pause 1 note; not fixed (FLOW-04).
12. **[Design, Task 3] Restart stability was compared with `HtmlCanon`, not raw or regex-normalized HTML.** Raw HTML differs between two starts (attribute order, tokens); Plan 01's byte-identical result held for primitives without that component. Canonical digests matched for the surfaces compared.
13. **[Process, Task 3] The project-root guard was run once from inside the retained checkout.** It correctly refused (that checkout is not the pinned root); the compose recreate in the same command line was independent of it and authorized by the task. Every later guard run was from `/Users/jon/projects/scrypath`, before each edit and commit.
14. **[Extra evidence, Task 3] Three copy defects were confirmed in Chromium with a scratch script** (read-only, a loopback-only route filter), which the plan did not require; it turns three "unconfirmed" items into confirmed ones.
15. **[Correction, Task 3] The Task 2 text called the PR first attempt and the main push run "cold".** The cache logs show all four ops-ui samples hit both caches; corrected above and in finding 30.

16. **[Design, Task 3] One extra path in the docs commit: `.planning/reference/README.md`.** The index of `research/storybook-catalog/` lists each note; without one line the Pause 1 note would not be discoverable from it. The plan named three paths plus this file; this is a single line in an index.

Total deviations: 16 (1 bug found by the mirror, 15 design, accepted, finding, process, correction or index). No cut from the plan was taken. No root `lib/`, dependency, lock or workflow file changed.

## Authentication gates

None. `gh` was already authenticated; the repository-contracts, ops-ui and Docker lanes ran with the escalated git and Docker access AGENTS.md already authorizes.

## Known Stubs

None. The Start here page prints `unknown` for every git fact when the catalog is not started through the serve task, by design and under test.

## Threat Flags

None beyond the plan's register. T-197-17: the endpoint stays loopback, the preflight fetches only loopback URLs and prints shas, a local path and the epoch; the Chromium copy check and the probe route filter allow loopback hosts only. T-197-18: a held port is refused and named, never signalled (proven against the real holder on 4003 in Task 1, and 4003 was only read with `lsof` in Task 3). T-197-19: five fixed attributes parsed by a pure function, 5 s timeout, no redirects. T-197-20: PR title `test(ops-ui)` and `docs(phase-197)`, no feat or fix commit, 0 release PRs. T-197-21: explicit staging, cached-name check before each commit, guard row on the PR diff and on main. T-197-22: preflight first, each pending path classified, the generated file proved byte-identical to a fresh build and left in place, fast-forward only, seed-disabled override, row counts and the `my-search.json` hash equal before and after. T-197-23: both compose kinds clean, exact image tags removed, no prune, image list identical.

## After this file merges (not in this file because it does not exist yet)

The docs PR number, its merge commit, which required checks ran or skipped (the path-scoped heavy lanes should skip and still report), the release-please PR count after it, the final fast-forward of the retained checkout to the docs-only commit, the restarted storybook, the final `npm run ui:preflight` output with the final `main@sha`, the `lsof` check that nothing else from this task listens, the final `docker system df` and the chat hand-off are in the executor's report to the orchestrator; a commit cannot name its own merge. The Task 3 verify commands (the note on `origin/main` with one feedback-table header, the docs PR `MERGED`) run after the merge.

## Performance

- **Started:** 2026-11-22T15:24:46Z (plan ledger). Tasks 1 and 2: about 66 minutes to the merge at 16:30:20Z, most of it the local mirror and the hosted run. Task 3 ran from about 16:40Z (refresh, storybook, probe, note, cost record) to the docs commit.
- **Realized diff:** Tasks 1 and 2 (3 commits, 14 files, +838 -32) about 12.1k tokens by chars/4 over added lines; Task 3 (the note, finding 30, the block and this file, chars/4 over added lines) about 19.5k more; the `actuals.tokens` figure is the sum, 31.6k, against the 80k estimate for the whole plan (this plan was mostly waiting on lanes and hosted runs, and its Task 3 evidence is mostly prose).
- **Commits:** `472a3b1e..95d716ae` is 3 (`2a5891d5` chore(ops-ui) landing page and preflight; `ce9ab33c` docs(phase-197); `95d716ae` test(release)), all squashed into `33aac70f`; the Task 3 docs commit is the fourth.

## Self-Check: PASSED

Checked after writing this file and before the commit:

- Files exist: the Pause 1 note, this SUMMARY, the edited `UI-PREVIEW.json` and `CI-EFFICIENCY.md`, and (from Tasks 1 and 2) `welcome.story.exs` and `_start.index.exs`.
- Commits exist: `33aac70f` (the squash of PR #177) is an ancestor of `origin/main` and is `origin/main` at the time of writing; the three branch commits `2a5891d5`, `ce9ab33c` and `95d716ae` exist as objects (they are not ancestors of `main` because the squash replaced them), and `git rev-list --count 472a3b1e..95d716ae` is 3.
- The Task 3 acceptance checks that can be run before the merge pass: `Phase 197` appears on at least two lines of `CI-EFFICIENCY.md`; the note's feedback-table header appears exactly once; every deep link answered 200; the 4002 row counts and the `my-search.json` hash are equal before and after; the final-form preflight (block temporarily on 4013) is green for both surfaces with `main@sha` equal to `origin/main`; `ls .planning/phases | grep -c '^198'` is 0.
- The post-merge checks (the docs PR is `MERGED`, the note is on `origin/main`, the final preflight) are reported in the hand-off and are not claimed here.
