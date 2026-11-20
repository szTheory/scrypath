# CI and CD efficiency ledger

Standing rule: [AGENTS.md "CI and CD efficiency"](../../AGENTS.md). Every CI, release, deploy or bot-PR run is looked at for low-hanging speed, iteration-time and cost wins that do not weaken what a check proves. This file is where measured findings, candidates and decisions live. Newest findings first. A candidate is not a decision: apply the low-risk ones in the next CI change, and write the outcome next to the row.

How to measure: `gh run view <run-id> --json jobs --jq '.jobs[]|[.name,.conclusion,((.completedAt|fromdateiso8601)-(.startedAt|fromdateiso8601))]|@tsv'` (skipped jobs have a zero timestamp, filter them out), and `gh run view <run-id> --log-failed` for failures.

## Local-first checklist (before waiting on hosted CI)

1. `mix format --check-formatted <files>` and the one test file you changed.
2. Token and pair tests: `node --test examples/scrypath_ecommerce/ui-tokens.test.mjs scripts/ci/ui_state_pairs.test.cjs` (about 1 s).
3. Package changes: `mix verify.package`. Docs changes: the built-docs contract in `test/release/package_metadata_test.exs`.
4. Static analysis: `MIX_ENV=test mix dialyzer` (about 35 s with a warm PLT; run `mix deps.get` first after a lock change). Found two real errors on 2026-11-20 that the hosted advisory lane had been hiding.
5. Workflow wiring: `act -l -W .github/workflows/ci.yml` lists the jobs (act 0.2.87 at `/opt/homebrew/bin/act`, verified 2026-11-20); `act -j <job> --container-architecture linux/amd64` for the cheap jobs (`backend`, `package`, `core`) with a pinned image that has a working Beam/OpenSSL stack. Not yet measured end to end; record the first real run here. The browser lanes (`ecommerce-mounted`, `ecommerce-e2e`) need the repository's own Docker wrappers, not `act`.
6. A change to anything the verifier fixture copies: run the whole CI Node step locally (`.github/workflows/ci.yml`, "Verify browser build, lifecycle, evidence, and target behavior").
7. A shallow checkout (the `package` job) lacks history: tests that use `git merge-base` or `git show` must handle that (the README header pin test does).

## Measured timings (hosted, 2026-11-20, PR #145 run 44670776239 unless noted)

| Job | Seconds | Required | Notes |
|---|---|---|---|
| ecommerce-mounted | 1134 | yes | critical path of every PR, even planning-only ones |
| repository-contracts | 858 | yes | the Node step is about 575 s of it (earlier run: 575 of 823) |
| compatibility (advisory), 4 cells | 311 to 395 each | no | about 22 runner-minutes per PR, all advisory |
| ops-ui (path-scoped) | 386 | yes | already skipped when its path classifier says no |
| core | 292 | yes | |
| deep-quality (advisory) | 190 to 206 | no | red on every run (see finding 1) |
| phoenix-example (advisory) | 112 | no | |
| package | 106 | yes | |
| backend | 60 | yes | |

Wall time of a PR run: about 19 minutes (04:11:19 to 04:30:16 UTC). `ecommerce-e2e` (advisory) runs about 1394 s on schedule or dispatch only; per the v1.47 prep it failed on 7 of 8 nightlies from 2026-11-12 to 2026-11-18 unnoticed. Read the 2026-11-20 nightly first: it is the first on the re-skinned `main`.

Bot PR serialization (2026-11-20): four Dependabot PRs merged one at a time because `strict` branch protection requires each to be up to date, about 20 minutes each (07:10:55, 07:31:25, 07:51:52, 08:07:44), roughly an hour of wall time for four patch and minor bumps.

## Findings and candidates

1. **An always-red advisory lane hides new reds (found 2026-11-20).** `deep-quality (advisory)` fails on every run because of the known cloak and cloak_ecto advisory, and that masked two new dialyzer errors from Phase 186's brand tooling (`refuse!/1` in `dev/mix/tasks/brand/update.ex`, `fail!/2` in `dev/mix/tasks/verify/brand.ex`: "has no local return"). They had been red since 2026-11-19 with nobody looking. Fixed with `@spec ... :: no_return()` (the same pattern as `verify.release_parity`). Candidate: split the lane so dialyzer and the other deep checks report as their own advisory job and only the dependency audit stays red for the known cause (or make the dependency audit its own job), so the lane is green when only cloak is wrong. Quality gain, small cost change. Status: candidate.
2. **Planning-only and docs-only PRs pay the full 19 minutes.** PRs #144 (`.planning/` only) and #145 (README, docs and one test) each ran `ecommerce-mounted` (1134 s) and the whole `repository-contracts` Node step. `ops-ui-path` already shows the pattern: a classifier job and a job-level `if`, so the required context still reports as skipped-green. Candidate: add an `ecommerce-path` classifier and skip `ecommerce-mounted` (and the Node step of `repository-contracts`) when only `.planning/**`, `docs/**`, `*.md` and tests that those lanes do not read changed. Must keep `workflow_wiring_test` passing and must not skip when `brand/`, `scrypath_ops/`, `examples/`, `scripts/ci/` or workflow files change. Estimated saving: about 19 minutes of wall time and about 35 runner-minutes per docs-only PR. Risk low to medium (path list correctness). Status: candidate, next CI change.
3. **Compatibility matrix on every PR.** Four advisory cells, about 22 runner-minutes, on PRs that cannot change compatibility (planning, docs, website). Candidate: gate them behind a `lib/`, `mix.exs`, `mix.lock` path classifier on PRs and keep them on schedule and push to `main`. No required check involved. Status: candidate.
4. **Serial strict merges for bot PRs.** About 20 minutes each. Candidates: a merge queue (batches and tests the combined result once), or keep `strict` but group Dependabot more aggressively so there are fewer PRs; do not drop `strict` without a decision, because it is a quality control. Status: candidate, needs the maintainer's call on branch protection.
5. **Website `build-and-check` install time.** About 8 of 8.5 minutes is the browser install (per the v1.47 website note). Candidate: cache the browser or drop `--with-deps`; measure in the Phase 189 plan. Status: candidate, folded into v1.47 Phase 189.
6. **Repository-contracts Node step.** 575 s of 823 to 858 s, mostly `ecommerce_lifecycle`. Candidate: split the step into a parallel job so it overlaps `ecommerce-mounted` (the critical path is already `ecommerce-mounted`, so this only helps once finding 2 lands). Status: candidate.
7. **Advisory nightly that is always red.** `ecommerce-e2e` nightly failed 7 of 8 times unnoticed (standalone copy specs, one failure inspected). A lane nobody reads costs 23 minutes a night and trains everyone to ignore red. Candidate: read it, fix or delete the failing specs, and surface a nightly failure somewhere it is seen. Status: candidate, read the 2026-11-20 nightly first.
8. **Release run.** Release Please opens its PR automatically since the 2026-11-20 repository-setting fix. A bot-authored release PR gets no CI until a human-authored event; `gh pr update-branch <n>` triggers it without close-and-reopen and also brings the branch up to date in one call (used for 0.3.19). Record the publish job's timings after the 0.3.19 release below.

## Release (CD) timings

- 0.3.19: release PR created by Release Please at 2026-11-20 13:22 UTC after the repository setting was enabled; hand-edited changelog; CI triggered by `gh pr update-branch`. Publish timings: to be recorded after the merge.
