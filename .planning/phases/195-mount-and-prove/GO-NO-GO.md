---
phase: 195-mount-and-prove
decision: go
decided_by: "pre-authorized by CONTEXT and ADR 0001: no trigger tripped and warm is within the line, so the checkpoint was not presented; no maintainer reply was needed"
measured: 2026-11-21
pull_request: 171
cold_run: 44955813968
---

# Phase 195 go/no-go: what phoenix_storybook costs on hosted CI

## Decision

**Go.** Checkpoint not reached: cold at or under 548 s, warm at or under 428 s, no trigger tripped.

In plain terms: the hosted `ops-ui` job took **517 s cold** (the first run after the lock change) and **378 s warm** (a rerun of the same job on the same commit). The line for cold is 548 s (368 s locked baseline plus 180 s) and the line for warm is 428 s (368 s plus 60 s). Both are under. All five ADR 0001 triggers are not tripped, and the phase continues without a maintainer reply, as CONTEXT and ADR 0001 pre-authorized.

Two things are worth knowing, and neither changes the verdict:

- **Cold is under its line by 31 s.** Read against a same-day control (the same job on the main commit, rerun at the same time, 342 s), the cold excess is 175 s, five seconds under the 180 s margin. That is close.
- **Most of the cold excess is not the storybook.** The cold run missed the root-graph BEAM cache (both cache keys reported "Cache not found"); the warm rerun hit both. Any pull request that changes a `mix.lock` pays the same miss: the earlier Dependabot ops-lock runs took 424, 437, 508 and 555 s cold with no storybook in them. The storybook's own marginal cost is the warm-versus-control gap: **+36 s** (378 s against 342 s, run at the same time; one paired sample).

Method change from CONTEXT: the real phase PR (#171) was the timing run, not a throwaway PR. Nothing was pushed before the full phase code existed, so its first run is the cold sample of exactly what merges, and a job rerun is the warm sample. No separate PR was opened or closed.

## Baseline

- **Locked baseline: 368 s** (the last green main `ops-ui` run named in the prep note; runs 44930917171 and 44922150467 read 368 s). The trigger lines come from it: **548 s** (368 + 180) for cold and **428 s** (368 + 60) for warm.
- **Evidence only, not a line:** over 14 successful main pushes on 2026-11-21 (research Finding 9) the job ranged **360 to 579 s** with a **median of 409.5 s** (mean 427 s). Two of the 14 (553 s and 579 s) were above 548 s, so a cold result inside that band is a judgment call; that never came up because the cold result was under the line.
- **Latest green main push run (44943834998, commit a11c36cd):** `ops-ui` 374 s, `Run mix verify.ops_ui` step 334 s. The two runs before it (44943130548, 44939887715): 409 s and 484 s.
- **Same-day paired control:** `gh run rerun 44943834998 --job 136966725694` (attempt 2, job 137007989641), started at the same minute as the warm sample: **342 s** total, **307 s** `Run mix verify.ops_ui` step.
- **Earlier cold runs after an ops lock change (Dependabot branch for PR #151, no storybook):** 508 s (run 44860899193), 437 s (44859824928), 555 s (44845716201), 424 s (44792978871).

## Hosted ops-ui timings

Job `ops-ui (path-scoped)`, `gh run view <id> --json jobs`, seconds from `startedAt` to `completedAt`.

| Sample | Run id | Attempt | Job id | Result | Job total (s) | `Run mix verify.ops_ui` step (s) | Root-graph BEAM caches |
|---|---|---|---|---|---|---|---|
| Cold | 44955813968 | 1 | 137003601222 | success | 517 (22:15:52 to 22:24:29 UTC) | 479 | downloads and resolved keys both "Cache not found" |
| Warm | 44955813968 | 2 | 137007958395 | success | 378 (22:32:11 to 22:38:29 UTC) | 344 | both "Cache hit" |
| Same-day control (main a11c36cd) | 44943834998 | 2 | 137007989641 | success | 342 (22:32:17 to 22:37:59 UTC) | 307 | not applicable |

- Cold against the locked baseline: +149 s. Against the 14-run median: +107.5 s. Against the same-day control: +175 s.
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
| Cold ops-ui over baseline plus 180 s | 517 s (run 44955813968, attempt 1, job 137003601222); evidence: 14-run median 409.5 s, spread 360 to 579 s, same-day control 342 s (+175 s), earlier lock-change cold runs 424 to 555 s | 548 s (368 + 180) | not tripped (31 s under) |
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
- **Cold at or under +180 s and warm at or under +60 s:** cold 517 s against 548 s; warm 378 s against 428 s (hosted run 44955813968, attempts 1 and 2).
- **H exit item, `handle_params` in an `:example` story:** impossible, with evidence rather than a measurement. phoenix_storybook 1.5.0 `lib/phoenix_storybook/stories/story.ex` lines 98 and 99: "Examples are rendered as a child LiveView, so you can implement `mount/3`, `render/1` or any `handle_event/3` callback. Unfortunately `handle_params/3` cannot be defined in a child LiveView." H marked this CONFIRMED.
- **H exit item, fidelity probe (computed-style parity, three themes by two color schemes):** deferred to Phase 197 under orchestrator decision 7; not run in this phase. It is not a CI gate and not part of this phase's success criteria.

## Recorded choices

- **Method change.** The real phase PR is the timing run, not a throwaway PR, so the cold sample measures the code that merges. CONTEXT had said "a throwaway branch PR".
- **Flag read.** The catalog route flag is read at expansion with `Application.get_env`, which returns a value, rather than through `Macro.expand`, which returns a call AST (Research Finding 1). `test.exs` turns the flag off when `PHX_SERVER=true`, so the Docker `runtime_test` image (which binds all interfaces) never mounts `/storybook`.
- **`.dockerignore` skipped.** No `.dockerignore` entries were added for `scrypath_ops/storybook` and `scrypath_ops/catalog`. Only the `asset_builder` stage (`MIX_ENV=dev`) needs those sources, because it compiles `DevRouter` with the flag on, which names the backend module, and the backend loads the stories. `runtime_test` compiles with `PHX_SERVER=true`, so the flag is off there, and `runtime_prod` compiles `lib` only. Excluding the trees would therefore break `asset_builder`, while in the other images the sources are inert. Revisit if the maintainer wants the image contents asserted, for example with a per-stage `COPY --exclude` in the runtime stages.
- **Fifth story.** The planner chose `ops_sync_status` in place of the form-field class: `ops_field` is mostly `phx-hook` behavior that a server-side render-all cannot exercise, so a story for it would claim more than its test proves (195-02 SUMMARY). The form-field story moves to Phase 197's patterns tier.
- **No gate row, no CI context.** This phase added neither. `scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs` is the file Phase 197 extends into ledger row 11.
- **Record lands after the merge.** This record goes in a post-merge planning-only `docs(phase-195):` PR, which saves one full path-scoped run on the phase PR (see the CI-EFFICIENCY entry).
- **Plan counts.** The phase has 3 plans (cap 5); the milestone has 16 planned against the stop at 20.

## Findings for the maintainer

Recorded and not fixed (FLOW-04). The first two are new from this phase.

- **(a) Latent guard defect in `ScrypathOpsWeb.OptionalDevRoutes.dashboard_routes/1`** (`scrypath_ops/lib/scrypath_ops_web/dev_router.ex`, lines 4 to 7). It passes `Application.compile_env(...)` through `Macro.expand`, which returns a call AST, so its `and dev_routes?` is always truthy and `dev_routes` is never consulted. This is unobservable today because LiveDashboard is a dev-only dependency. A fix would read the value the way the catalog macro does (`Application.get_env` at expansion) and add a mutation test. Outside this phase's scope; the maintainer decides whether to fix it.
- **(b) Residual: the catalog flag is read at compile time.** A stale local test-env build that was compiled without `PHX_SERVER=true` and is later served with it would still carry `/storybook`. CI and the Docker images compile fresh, so only a long-lived local build is exposed. Accepted as low.
- **(c) Still open and not fixed in Phase 195:** F1 (`Tasks.list_sync_tasks` truncation error, needs a root `lib/` change, so it is ask-first), F2 (unbounded, copyable Meilisearch error messages in the ops UI), D2 (retry receipts live only in the LiveView process), and the SYNTHESIS test-hygiene items (see [SYNTHESIS.md, "Findings handed to you"](../../research/catalog-prep/SYNTHESIS.md)). The stale "v1.47 catalog" describe label was renamed only because Plan 01 rewrote that block.
- **(d) Unrelated advisory, found today:** `examples/phoenix_meilisearch/mix.lock` pins `phoenix 1.8.16`, which two new HIGH advisories published on 2026-11-21 cover (fixed in 1.8.17; the other two locks already use 1.8.17). It only turns the advisory `deep-quality` lane redder, and it is the kind of bump Dependabot proposes. Not part of this phase.
- **(e) Cold-run cost of any lock change:** an `ops` lock change misses the whole root-graph BEAM cache and costs about 135 s in `verify.ops_ui` (recorded in CI-EFFICIENCY as a candidate). That is a property of the cache key, not of the storybook.
