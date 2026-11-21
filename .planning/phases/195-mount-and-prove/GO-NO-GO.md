---
phase: 195-mount-and-prove
decision: go
decided_by: "the maintainer, against a tripped cold sample (not a pass): selected \"Continue (Recommended)\" in an interactive dialog on 2026-11-21, reported to the executor by the orchestrating agent"
measured: 2026-11-21
pull_request: 171
cold_run: 44955813968
---

# Phase 195 go/no-go: what phoenix_storybook costs on hosted CI

## Decision

**Go, as the maintainer's choice against a tripped cold sample, not as a pass.** The checkpoint was reached, because one of the two hosted cold samples is over its line, and the maintainer answered it.

> Maintainer selected "Continue (Recommended)" in an interactive dialog on 2026-11-21

The options shown were Continue, Remeasure first and No-go, with the numbers in the table below (the 620 s main run, the 517 s PR run, the 378 s warm rerun, the 38-run median and maximum, the controls and the cache-miss inference). The executor did not see the dialog: the orchestrating agent ran it and relayed the choice, and this line records the relay.

| Cold sample | Run, attempt | Job total | Against the 548 s line |
|---|---|---|---|
| The PR's first run, after the lock change (the sample the plan names) | 44955813968, attempt 1 | **517 s** | 31 s under |
| The first main push run after the merge (cache cold again, because a pull request's caches are not visible to main) | 44958204651, attempt 1 | **620 s** | 72 s over, and 30 s above the slowest of the previous 38 main runs |

The warm sample is within its line: **378 s** against 428 s. The other four ADR 0001 triggers are not tripped.

What I did and when: I merged the phase PR (#171) on the first cold sample, which was under the line, with all six required checks green on the measured head. The second cold sample arrived about ten minutes later, from the main push run that the merge started. By the adopted rule a cold run over 548 s is a tripped trigger, and a result inside the historic noise band is the maintainer's judgment, not the executor's, so the executor stopped there and held this record in a draft docs PR (#172) until the maintainer answered. Nothing else was merged in the meantime.

Evidence for the judgment (details in the sections below):

- **The storybook's own marginal cost is small.** Warm against the same-day control: 378 s against 342 s, **+36 s**, at the same minute. The cold excess is mostly something else.
- **Cold is noisy, with or without the storybook.** Of the previous 38 main push runs (2026-11-19 to 2026-11-21), median 410 s, p90 553 s, maximum 590 s, **5 exceeded 548 s and none of those five changed a lock file**. The only earlier main run after an ops lock change took 449 s.
- **A lock change also throws away the root-graph BEAM cache** (both keys "Cache not found" on both cold runs, "Cache hit" on the warm rerun): about 135 s in `verify.ops_ui` on the PR runs. That cost is paid by every pull request or merge that changes a lock, storybook or not (CI-EFFICIENCY finding 26 is the candidate fix).
- **Where the 620 s went:** the root half of `verify.ops_ui` (the boundary integration tests, which compile scratch consumers) took 415 s against 341 s on the PR cold run and 267 s warm; the ops half 104 s against 87 s and 73 s. The main run was slower in both halves, which looks like a slower runner, but I cannot prove that from the logs.
- **A time-matched control moved too.** The main job from before the merge, rerun at 22:57 UTC while the main cold run was finishing, took 417 s; the same job on the same commit took 342 s at 22:32 UTC. Against the time-matched control the main cold run's excess is +203 s. Take away the roughly 135 s lock-change cache miss measured on the PR runs and about +70 s is left for the storybook plus runner variance. That subtraction is an inference, not a measurement.

Options the maintainer was given, each with its consequence:

- **Continue (go), selected.** The code is already merged; this keeps it. Recorded as the maintainer's choice against a tripped cold sample, not as a pass. Recommended: the marginal cost is about +36 s, the 620 s is one sample 30 s above anything seen in 38 runs, and the larger cold cost belongs to lock changes in general.
- **Measure again.** The only way to get another cold run is another lock change on a branch (an extra push and a full PR run, about 16 minutes of wall time and a lot of runner time), so I would not choose this unless you want a second sample on a pull request.
- **Stop (no-go).** The ADR 0001 fallback is the hand-rolled harness. Because #171 is already merged, this means a revert PR for the storybook mount; the Phase 196 fixtures still pay off either way.

Method change from CONTEXT: the real phase PR (#171) was the timing run, not a throwaway PR. Nothing was pushed before the full phase code existed, so its first run is the cold sample of exactly what merges, and a job rerun is the warm sample. No separate PR was opened or closed.

## Baseline

- **Locked baseline: 368 s** (the last green main `ops-ui` run named in the prep note; runs 44930917171 and 44922150467 read 368 s). The trigger lines come from it: **548 s** (368 + 180) for cold and **428 s** (368 + 60) for warm.
- **Evidence only, not a line:** over 14 successful main pushes on 2026-11-21 (research Finding 9) the job ranged **360 to 579 s** with a **median of 409.5 s** (mean 427 s). Two of the 14 (553 s and 579 s) were above 548 s, so a cold result inside that band is a judgment call; that never came up because the cold result was under the line.
- **Latest green main push run (44943834998, commit a11c36cd):** `ops-ui` 374 s, `Run mix verify.ops_ui` step 334 s. The two runs before it (44943130548, 44939887715): 409 s and 484 s.
- **Same-day paired control:** `gh run rerun 44943834998 --job 136966725694` (attempt 2, job 137007989641), started at the same minute as the warm sample: **342 s** total, **307 s** `Run mix verify.ops_ui` step.
- **Time-matched control, second sample:** the same main job rerun again (attempt 3, job 137014561618) at 22:57 UTC: **417 s** total, **378 s** step. The same job on the same commit took 342 s at 22:32 UTC, so the runner-to-runner spread for identical work is at least 75 s inside 25 minutes.
- **Previous 38 main push runs (2026-11-19 to 2026-11-21, `gh run view <id> --json jobs`):** min 342 s, median 410 s, mean 433.6 s, p90 553 s, max 590 s. **Five exceeded 548 s** (579, 553, 574, 590 and 553 s) and **none of them changed a lock file**; the only earlier main run after an ops lock change took 449 s (805c47a7). Run ids and lock-change flags are in the 195-03 scratch history, reproducible with `gh run list --branch main --workflow ci.yml --event push --limit 40`.
- **Earlier cold runs after an ops lock change (Dependabot branch for PR #151, no storybook):** 508 s (run 44860899193), 437 s (44859824928), 555 s (44845716201), 424 s (44792978871).

## Hosted ops-ui timings

Job `ops-ui (path-scoped)`, `gh run view <id> --json jobs`, seconds from `startedAt` to `completedAt`.

| Sample | Run id | Attempt | Job id | Result | Job total (s) | `Run mix verify.ops_ui` step (s) | Root-graph BEAM caches |
|---|---|---|---|---|---|---|---|
| Cold | 44955813968 | 1 | 137003601222 | success | 517 (22:15:52 to 22:24:29 UTC) | 479 | downloads and resolved keys both "Cache not found" |
| Warm | 44955813968 | 2 | 137007958395 | success | 378 (22:32:11 to 22:38:29 UTC) | 344 | both "Cache hit" |
| Same-day control (main a11c36cd) | 44943834998 | 2 | 137007989641 | success | 342 (22:32:17 to 22:37:59 UTC) | 307 | not applicable |
| **Cold, post-merge main push (96521ab1)** | 44958204651 | 1 | 137010963728 | success | **620** (22:43:36 to 22:53:56 UTC) | **581** | both "Cache not found" |
| Control matched to that main run (main a11c36cd rerun at 22:57 UTC) | 44943834998 | 3 | 137014561618 | success | 417 (22:57:36 to 23:04:33 UTC) | 378 | not applicable |

- PR cold run (517 s) against the locked baseline: +149 s. Against the 14-run median: +107.5 s. Against the 22:32 control: +175 s.
- **Post-merge main cold run (620 s)** against the locked baseline: **+252 s**. Against the 14-run median: +210.5 s. Against the 22:32 control: +278 s. Against the control matched to its hour (417 s): +203 s.
- Where the time went in each cold-cache run (gaps between log flushes of the printed subprocess output): the root half of `verify.ops_ui` took 341 s on the PR cold run, 267 s on the warm rerun and 415 s on the main cold run; the ops half took 87 s, 73 s and 104 s. The main run was slower in both halves.
- Warm against the locked baseline: +10 s. Against the same-day control: +36 s.
- **Cold versus warm differ by 139 s (verify step: 135 s).** The plan predicted "a few seconds", because `verify.ops_ui` isolates the ops build, deps and Hex homes in scratch directories, so only the root-graph caches could help. The measured gap is larger because the root half of `verify.ops_ui` still needs the root `deps` and `_build/test`, and the `ops` cache key digests both lock files, so an ops lock change invalidates it with no prefix fallback. The attribution comes from the cache logs (miss against hit) and the isolation analysis, not from a profile.
- Other jobs on the cold run (all required ones green on head f9af18d4): `ecommerce-mounted` 955 s (bake step 292 s), `repository-contracts` 595 s, `core` 471 s, `package` 103 s, `backend` 59 s; the run was done in about 16 minutes wall. `deep-quality (advisory)` was red for its known cause (see Advisory status).

## Rust NIF fetch

`mdex_native` 0.3.2 downloads a precompiled NIF through `rustler_precompiled` 0.10.1. Artifact for hosted Linux: `libmdex_native_nif-v0.3.2-nif-2.15-x86_64-unknown-linux-gnu.so.tar.gz` (the default variant) from `https://github.com/leandrocp/mdex_native/releases/download/v0.3.2/`, with a sha256 entry in `scrypath_ops/deps/mdex_native/checksum-Elixir.MDExNative.Native.exs`. Source of the URL and target: `lib/mdex_native/native/artifact_url.ex` and `lib/mdex_native/native.ex` in the dependency.

| Number | Source | Target triple |
|---|---|---|
| **0.400 s** (22:17:31.966 to 22:17:32.366) | hosted log, run 44955813968 attempt 1, step `Bake and load checked mounted images`, Docker `asset_builder` stage (`_build/dev`); the Elixir logger's own timestamps, which BuildKit streams line by line | `x86_64-unknown-linux-gnu` |
| **0.655 s** (22:20:11.508 to 22:20:12.163) | same step, `runtime_test` stage (`_build/test`) | `x86_64-unknown-linux-gnu` |
| 0.66 s and about 0.8 s | local, macOS: the Plan 01 compile log and the research spike | `aarch64-apple-darwin` |
| 1.14 s, 2.86 s, 3.17 s (1,513,806 bytes) | local `curl -sS -L` of the hosted artifact URL, three runs, on a loaded machine; the sha256 of the download equals the checksum file entry | `x86_64-unknown-linux-gnu` |

- **Not separable inside the `ops-ui` job (both attempts).** `verify.ops_ui` prints each subprocess's output after the subprocess exits, so its lines share one flush timestamp. The only NIF line it prints is `Copying NIF from cache and extracting to ...` (logger clock 22:23:18.690 cold, 22:37:29.025 warm), which is the cache copy, not the download; the download happened earlier in the same job in output that is not echoed (an inference: the root boundary test captures its probes' output). So the hosted fetch time comes from the Docker builds above. Either way it is under one second per fetch, small next to the job time.
- **NIF failures: 0** across both hosted attempts of this PR (every job green; no download or checksum error in the logs of attempt 1, and the attempt 2 `ops-ui` log shows the cache copy only). The trigger counts failures across all hosted runs of the PR, so any later run is added to this count in the merge notes.

## Lock growth

- `scrypath_ops/mix.lock`: **56 to 65 lines (+9 packages)**: `phoenix_storybook`, `mdex`, `mdex_native`, `rustler_precompiled`, `makeup`, `makeup_eex`, `makeup_html`, `makeup_elixir`, `nimble_parsec`. No existing entry changed.
- The root `mix.lock` and `examples/scrypath_ecommerce/mix.lock` are byte-identical to `origin/main` (`git diff --quiet origin/main -- mix.lock examples/scrypath_ecommerce/mix.lock` exits 0).
- `mix deps.get --check-locked` exits 0 in the root, `scrypath_ops/` and `examples/scrypath_ecommerce/` (inside `scripts/ci/pre_push.sh`, on the pushed commit).
- A mounted consumer in `test` or `prod` has none of these packages in its lock (Plan 01 probe, asserted by `test/release/ops_dependency_boundary_test.exs`).

## Advisory status

Resolved versions: `phoenix_storybook` 1.5.0, `mdex` 0.14.7, `mdex_native` 0.3.2 (all read from `scrypath_ops/mix.lock`). Read on 2026-11-21.

- **phoenix_storybook:** three advisories in the GitHub advisory database (`gh api -X GET /advisories -f ecosystem=erlang -f affects=phoenix_storybook`): GHSA-55hg-8qxv-qj4p (critical, HEEx template injection in the playground), GHSA-833p-95jq-929q (high), GHSA-mrhx-6pw9-q5fh (low). All are `< 1.1.0` or lower ranges, first patched in 1.1.0. Resolved 1.5.0 is clear.
- **mdex and mdex_native:** the global database lists none for either (`affects=mdex`, `affects=mdex_native`). The projects' own security advisories (`gh api repos/leandrocp/mdex/security-advisories`, `.../mdex_native/security-advisories`, all published 2026-06-29): GHSA-4383-7xfp-gpph and GHSA-923r-7vf4-5vw8 (mdex, patched 0.13.2), and GHSA-j93q-9cvj-rxfm, GHSA-cmvp-gp9f-23xw, GHSA-v664-pmxr-mxxx, GHSA-3w4f-53g2-f66p (mdex patched `>= 0.12.3`, mdex_native patched 0.2.3). Resolved mdex 0.14.7 and mdex_native 0.3.2 are clear of every range.
- **`mix hex.audit` in `scrypath_ops`:** only `sigra 1.20.0` (retired), exit 1, which is the baseline. No line names any of the nine added packages.
- **Hosted `deep-quality (advisory)` on run 44955813968:** the `scrypath_ops` graph reports `sigra 1.20.0` retired, `cloak 1.1.4` (EEF-CVE-2026-95105, HIGH) and `cloak_ecto 1.3.0` (EEF-CVE-2026-94206, MEDIUM): the known baseline. The root and example graphs are clean; no finding names any added package. The step "Run deep quality checks independently of the dependency audit" passed. (A local `elixir scripts/ci/dependency_audit.exs` could not produce a comparable result: it stops on "Hex ignore configuration is active" in this environment, so the hosted run is the number of record.)
- **Unrelated, found while reading the audit:** the `examples/phoenix_meilisearch` graph reports `phoenix 1.8.16` vulnerable (EEF-CVE-2026-128361 and EEF-CVE-2026-129344, both HIGH, published today, fixed in 1.8.17). `scrypath_ops` and the ecommerce example already lock 1.8.17. Not a storybook dependency and not caused by this PR; see the findings below.
- Result: no new findings from the storybook subtree; no advisory is open on a resolved version.

## Docker asset_builder

- **Method: hosted proxy.** The `ecommerce-mounted` step `Bake and load checked mounted images` contains the `asset_builder` stage on its critical path (it compiles `DevRouter` with the flag on, which loads the storybook backend) and also compiles the storybook in `runtime_test`, so its delta is an upper bound for the stage. Hosted per-stage times are not separable (build markers share a timestamp).
- PR run 44955813968 attempt 1: **292 s**. Last three green main push runs: 273 s (44943834998), 259 s (44943130548), 253 s (44939887715); **median 259 s**.
- Delta: **+33 s** against the median (+19 s against the largest of the three). At or under the 60 s line, so no local `docker buildx` measurement was needed. No task-scoped builder was created for this measurement.

## Trigger evaluation

| Trigger | Measured | Threshold | Verdict |
|---|---|---|---|
| Advisory open over 14 days | none open on a resolved version (storybook advisories are all patched before 1.1.0, mdex ones before 0.13.2, mdex_native ones before 0.2.3; hosted audit shows only the baseline sigra, cloak and cloak_ecto items) | no advisory over 14 days on a resolved version | not tripped |
| Cold ops-ui over baseline plus 180 s | two cold samples: 517 s (PR run 44955813968, attempt 1, job 137003601222; 31 s under) and **620 s** (post-merge main run 44958204651, attempt 1, job 137010963728; 72 s over). Evidence: 14-run median 409.5 s and spread 360 to 579 s; previous 38 main runs median 410 s, max 590 s, 5 over 548 s with no lock change; controls 342 s and 417 s (cold excess +175 s and +203 s); earlier lock-change cold runs 424 to 555 s | 548 s (368 + 180) | **tripped** (one of two cold samples is over); the maintainer selected Continue, so this is a choice against a tripped trigger, not a pass (see Decision) |
| Isolation work over a day | 0.1 h (Plan 01: 0.0 h, Plan 02: 0.1 h, Plan 03: none) | 8 h | not tripped |
| Docker asset_builder over plus 60 s | +33 s (292 s against a main median of 259 s; hosted proxy) | +60 s | not tripped |
| NIF failure twice | 0 failures across both hosted attempts | 2 | not tripped |

SYNTHESIS exit criterion (not an ADR trigger, so it asks and never trips):

| Exit criterion | Measured | Threshold | Verdict |
|---|---|---|---|
| Warm ops-ui over baseline plus 60 s | 378 s (run 44955813968, attempt 2, job 137007958395); same-day control 342 s (+36 s) | 428 s (368 + 60) | within |

## Exit criteria

- **Non-vacuous boundary tests:** `test/mix/tasks/dependency_boundary_contract_test.exs` (planted storybook mention, unrestricted and wrong-requirement manifests, route-guard mutants moved, deleted and flag-blind, loopback rule, Docker script text check with planted mutants), `scrypath_ops/test/scrypath_ops_web/catalog_routes_test.exs` (a guard-stripped copy of the macro mounts the storybook with the flag off), `test/release/ops_dependency_boundary_test.exs` (mounted test and prod consumers and direct prod lack the apps; direct dev and test have them) and `test/release/package_metadata_test.exs` (tarball refutes). Each has a planted failing case recorded in the 195-01 SUMMARY. Green hosted: `core`, `repository-contracts` and `ops-ui` on run 44955813968.
- **Render-all with the planted tree:** `scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs` ("render-all" and "planted tree"): 5 stories, 17 variations, each in light and dark through the real iframe route, and the same loop reports a raising story, an empty story and unknown variation ids. `data-phx-error` is never emitted by the server (LiveView 1.1.34, phoenix_storybook 1.5.0), so the real failure signals are the crash, empty and unknown-variation plants; the selector check stays for the requirement wording.
- **Prod graphs lack PhoenixStorybook and MDEx:** `test/release/ops_dependency_boundary_test.exs` (prod compile: 14 routes, no `/storybook`, no loaded storybook modules) and the Docker boundary proof inside the required `ecommerce-mounted` job (green on hosted run 44955813968; locally `DEPENDENCY_BOUNDARY_CATALOG ... status=404` for the host and for standalone Ops in both the test and prod images).
- **Cold at or under +180 s and warm at or under +60 s:** warm 378 s against 428 s is met (hosted run 44955813968, attempt 2). Cold is met on the PR run (517 s against 548 s) and not met on the post-merge main run (620 s); the maintainer selected Continue against that second sample.
- **H exit item, `handle_params` in an `:example` story:** impossible, with evidence rather than a measurement. phoenix_storybook 1.5.0 `lib/phoenix_storybook/stories/story.ex` lines 98 and 99: "Examples are rendered as a child LiveView, so you can implement `mount/3`, `render/1` or any `handle_event/3` callback. Unfortunately `handle_params/3` cannot be defined in a child LiveView." H marked this CONFIRMED.
- **H exit item, fidelity probe (computed-style parity, three themes by two color schemes):** deferred to Phase 197 under orchestrator decision 7; not run in this phase. It is not a CI gate and not part of this phase's success criteria.

## Recorded choices

- **Method change.** The real phase PR is the timing run, not a throwaway PR, so the cold sample measures the code that merges. CONTEXT had said "a throwaway branch PR".
- **Flag read.** The catalog route flag is read at expansion with `Application.get_env`, which returns a value, rather than through `Macro.expand`, which returns a call AST (Research Finding 1). `test.exs` turns the flag off when `PHX_SERVER=true`, so the Docker `runtime_test` image (which binds all interfaces) never mounts `/storybook`.
- **`.dockerignore` skipped.** No `.dockerignore` entries were added for `scrypath_ops/storybook` and `scrypath_ops/catalog`. Only the `asset_builder` stage (`MIX_ENV=dev`) needs those sources, because it compiles `DevRouter` with the flag on, which names the backend module, and the backend loads the stories. `runtime_test` compiles with `PHX_SERVER=true`, so the flag is off there, and `runtime_prod` compiles `lib` only. Excluding the trees would therefore break `asset_builder`, while in the other images the sources are inert. Revisit if the maintainer wants the image contents asserted, for example with a per-stage `COPY --exclude` in the runtime stages.
- **Fifth story.** The planner chose `ops_sync_status` in place of the form-field class: `ops_field` is mostly `phx-hook` behavior that a server-side render-all cannot exercise, so a story for it would claim more than its test proves (195-02 SUMMARY). The form-field story moves to Phase 197's patterns tier.
- **No gate row, no CI context.** This phase added neither. `scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs` is the file Phase 197 extends into ledger row 11.
- **Record lands after the merge.** This record goes in a post-merge planning-only `docs(phase-195):` PR, which saves one full path-scoped run on the phase PR (see the CI-EFFICIENCY entry). That PR (#172) was held as a draft until the maintainer answered the checkpoint, then marked ready and merged.
- **The phase PR merged before the second cold sample existed.** #171 merged on the PR cold run (517 s, under the line) with six green required checks on the measured head. The post-merge main run, which the merge itself started, then measured 620 s. The merge was correct against the sample the plan names; the second sample is why the checkpoint was presented after the merge.
- **Plan counts.** The phase has 3 plans (cap 5); the milestone has 16 planned against the stop at 20.

## Findings for the maintainer

Recorded and not fixed (FLOW-04). The first two are new from this phase.

- **(a) Latent guard defect in `ScrypathOpsWeb.OptionalDevRoutes.dashboard_routes/1`** (`scrypath_ops/lib/scrypath_ops_web/dev_router.ex`, lines 4 to 7). It passes `Application.compile_env(...)` through `Macro.expand`, which returns a call AST, so its `and dev_routes?` is always truthy and `dev_routes` is never consulted. This is unobservable today because LiveDashboard is a dev-only dependency. A fix would read the value the way the catalog macro does (`Application.get_env` at expansion) and add a mutation test. Outside this phase's scope; the maintainer decides whether to fix it.
- **(b) Residual: the catalog flag is read at compile time.** A stale local test-env build that was compiled without `PHX_SERVER=true` and is later served with it would still carry `/storybook`. CI and the Docker images compile fresh, so only a long-lived local build is exposed. Accepted as low.
- **(c) Still open and not fixed in Phase 195:** F1 (`Tasks.list_sync_tasks` truncation error, needs a root `lib/` change, so it is ask-first), F2 (unbounded, copyable Meilisearch error messages in the ops UI), D2 (retry receipts live only in the LiveView process), and the SYNTHESIS test-hygiene items (see [SYNTHESIS.md, "Findings handed to you"](../../research/catalog-prep/SYNTHESIS.md)). The stale "v1.47 catalog" describe label was renamed only because Plan 01 rewrote that block.
- **(d) Unrelated advisory, found today:** `examples/phoenix_meilisearch/mix.lock` pins `phoenix 1.8.16`, which two new HIGH advisories published on 2026-11-21 cover (fixed in 1.8.17; the other two locks already use 1.8.17). It only turns the advisory `deep-quality` lane redder, and it is the kind of bump Dependabot proposes. Not part of this phase.
- **(e) Cold-run cost of any lock change:** an `ops` lock change misses the whole root-graph BEAM cache and costs about 135 s in `verify.ops_ui` (recorded in CI-EFFICIENCY as a candidate). That is a property of the cache key, not of the storybook.
- **(f) The measure-then-merge order cannot see the main-run cold number.** PR #171 merged on the 517 s PR sample, before the 620 s main-run sample existed, because a pull request's caches are not visible to main and the first cold main run only exists after the merge. The plan's order (measure on the PR, then merge) therefore could not see it. Recommendation: future gates of this kind measure on the main-run cold sample after merge (or treat the PR cold sample as a lower bound), and keep the post-merge stop-and-ask path open, as this phase did.
