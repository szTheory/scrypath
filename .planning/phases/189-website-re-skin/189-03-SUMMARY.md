---
phase: 189-website-re-skin
plan: 03
subsystem: website
tags: [github-actions, github-pages, smoke-test, rollback, ci-efficiency, phase-record, gate-receipt]

requires:
  - phase: 189-website-re-skin
    provides: plan 189-01 pipeline and contract, plan 189-02 re-skinned markup the smoke accept case needs
provides:
  - website.yml with brand/** filters, a workflow_dispatch ref rollback, a 10-minute build timeout, runner-Chrome-or-install browser step, a non-cancelling deploy group and a live smoke step
  - website/scripts/smoke.mjs, a dependency-free live-URL check proven offline
  - docs/releasing.md "Website deploy and rollback" section
  - measured install picture, playbook lessons and the phase record
  - one long-gate run on the committed head and its receipt
affects: [189 shipping steps (orchestrator), 190, 191]

actuals:
  tokens: 26000
  tasks: 3
  commits: 3
plan_head_before: 802f079611c81687dd4e6f7f06fdef119b432add
plan_head_after: 8c4fa990c54ab13d9ed156646ef0614daba18785

tech-stack:
  added: []
  patterns:
    - "smoke script exports runSmoke(baseUrl, options) so offline cases call it with one attempt and no delay"
    - "workflow contract as one helper (assert_website_safety_net!) that the real file and nine planted mutations both go through"
    - "ref input reaches only a checkout ref: the wiring test counts every use of inputs.ref"

key-files:
  created:
    - website/scripts/smoke.mjs
    - .planning/phases/189-website-re-skin/189-PHASE-RECORD.md
    - .planning/phases/189-website-re-skin/189-GATE-RECEIPT.md
  modified:
    - .github/workflows/website.yml
    - website/scripts/site-contract.test.mjs
    - website/package.json
    - test/mix/tasks/website_contract_test.exs
    - test/mix/tasks/workflow_wiring_test.exs
    - docs/releasing.md
    - .planning/reference/CI-EFFICIENCY.md
    - .planning/reference/BRAND-ADOPTION-PLAYBOOK.md
    - .planning/ROADMAP.md

key-decisions:
  - "build-and-check stays non-required; reasons and re-open trigger are in the phase record, docs/releasing.md and CI-EFFICIENCY finding 11"
  - "The smoke never fetches a URL that resolves outside the base path; it reports it"
  - "The closed hex set is defined in the phase record and in ROADMAP criterion 1; CONTEXT stays unchanged"

requirements-completed: [SITE-04, SITE-05, SITE-06, GATE-02]

duration: not recorded
completed: 2026-11-20
status: complete
---

# Phase 189 Plan 03: Deploy safety net, phase record and gate receipt Summary

**The website deploy now has path filters that watch `brand/**`, a bounded browser step, a deploy job that cannot be cut off by its own group, a live smoke step that checks the font hash, lockups, card and `/scrypath/` paths, a documented rollback by `workflow_dispatch`, and both long gates passed once on the committed head.**

The site was not pushed, merged or deployed here. Everything that can only exist after the push and the merge is listed under "Deferred to ship".

## What shipped

1. **Workflow (`website.yml`).** `brand/**` is on both the `push` and the `pull_request` filters (the PR filter did not exist before, so PRs that touch none of the listed paths now skip the job). `workflow_dispatch` takes a `ref` input (default `main`) that is used only as the checkout `ref` in both jobs. `build-and-check` has `timeout-minutes: 10` and one browser step: it uses the runner's Chrome through Playwright's `chrome` channel when `google-chrome --version` succeeds and a launch probe exits 0, otherwise it runs the existing `npx playwright install --with-deps chromium`. The deploy job runs on push or dispatch, has its own `website-pages-deploy` group with `cancel-in-progress: false`, an `id: deployment` on the Pages step and a last step, "Smoke test the deployed site". That step runs `node website/scripts/smoke.mjs` when the checked-out ref has it, and otherwise a soft check (`curl -fsSI` with a short retry on the home page and `assets/styles.css`), so a rollback to an older commit has a defined outcome. The workflow-level group still cancels (`cancel-in-progress: true`). No `environment:` block, no new action, no dependency change. `actionlint` is clean.
2. **Smoke (`website/scripts/smoke.mjs`).** Reads the base URL from `SCRYPATH_SMOKE_URL` (then `SCRYPATH_SITE_URL`), reads pins from `brand/brand.pin.json`, and prints `ok` or `not ok` for: home page 200; every declared asset URL (font preloads, lockup images, icon links, `og:image`, `twitter:image`) stays on the base origin under the base path and none is root-absolute; the ui font is 200, `font/woff2` and matches its pinned sha256; both lockups are 200 images; the social card is 200, starts with the PNG signature and matches its pin; `favicon.ico` is 200. Every request carries `?smoke=<run id or time>`. Retries (three tries, 10 s apart) happen only for a network error, a 404 or a 5xx; a response that arrives and is wrong is final. `runSmoke` is exported with `attempts`, `retryDelayMs` and `repoRoot` options. `npm run smoke` is added to `website/package.json`.
3. **Contract cases (4, floor 78 to 82).** `accept smoke passes against the built site served under /scrypath/` (also asserts the server saw no request outside `/scrypath/`), `accept smoke command line exits 0 against the served site and 1 with a message when no base URL is set`, `planted smoke fails when a pinned font is missing from the served tree` (fails exactly the `font` check), and `planted smoke fails when og:image resolves outside the base path` (fails exactly `base-path` and `card`, and the out-of-base URL is never requested). Each builds the real site into a directory served on an ephemeral port, so nothing touches the network.
4. **Wiring test.** `assert_website_safety_net!` checks both filters, the dispatch `ref` input, that `inputs.ref` appears only twice and only as `ref: ${{ inputs.ref }}`, the build timeout, the workflow-level and deploy-level concurrency, the deploy `if`, `id: deployment`, the smoke step (env, full command, `curl -fsSI` branch, stylesheet URL, order after deploy), the Chrome probe before the install fallback, and that `build` has no `pages: write` or `id-token: write`. A second test runs nine planted mutations through the same helper and requires each to be rejected. The old deploy-`if` assertion now expects the push-or-dispatch expression.
5. **Docs.** `docs/releasing.md` has "Website deploy and rollback": what deploys, the deploy group, the smoke checks, the rollback command `gh workflow run website.yml --ref main -f ref=<commit-sha>`, the soft check for old refs, the exact-head command and the non-required decision with its re-open trigger. No retired path or value is named.
6. **Records.** `CI-EFFICIENCY.md` finding 5 now holds the measured picture, the chosen fix, the rejected candidates, a known limit and a revisit trigger, with the after numbers marked pending; findings 10 and 11 are new. The playbook records S26, T10 and T19 evidence and adds S29, S30 and T22 to T25 as `draft`. The phase record has the resolved notes, outcome, decisions, post-ship evidence table, both procedures, residuals, the drafted favicon issue (not filed), the guides follow-up and the does-not-prove list. ROADMAP criterion 1 now states the closed hex set in full (the scoped edit the plan names).

## Measured install picture (before numbers)

From the last 30 `website.yml` runs: 28 completed `build-and-check` jobs (one cancelled run and one run with no jobs left out). Whole job median 64 s, p90 175 s, max 407 s. Install step median 40 s, p90 141 s, max 377 s. One run is over 5 minutes (44672719383). The plan's remembered "47 to 64 s" described the recent runs only: the 12 runs from 02:45 to 04:30 UTC took 50 to 407 s, the 16 from 12:11 UTC onward 32 to 78 s. This replaced the stale "about 8 of 8.5 minutes" claim, which the measurement does not support.

## Gates

| Gate | Command | Tested SHA | Result |
| --- | --- | --- | --- |
| Cheap checks first | `actionlint`, `mix format --check-formatted`, `node --test` on the contract (82) and the token test (61), `mix test` on the wiring and website wrapper files | `76948c2e` | all green |
| Focused ExUnit during Task 1 | `mix test` on `workflow_wiring_test.exs`, `docs_contract_test.exs`, `package_metadata_test.exs` | before the first commit | 187 tests, 0 failures |
| repository contracts | `mix verify.repository_contracts` (once, unsandboxed for `FETCH_HEAD`) | `76948c2ebd5baae68755f9d359faaef53af83c87` | pass |
| core | `mix verify.core --exclude integration --exclude docs_contract` (once, after the first finished) | `76948c2ebd5baae68755f9d359faaef53af83c87` | pass |

Neither gate was rerun, so no fix cycle was used. The receipt is `189-GATE-RECEIPT.md`; the only commits after the tested SHA touch files under `.planning/` (`git diff --name-only 76948c2e HEAD` lists the receipt and the phase record). `docker system df` was checked: this plan started no Docker resources, so nothing task-scoped remains.

## Deviations from Plan

**1. [D-44 deviation, as the plan states] Workflow and smoke work live here, not in 189-01.** The smoke accept case (the real build served under `/scrypath/` and smoke-tested) needs the 189-02 markup (font preloads, lockups, og meta, icon links), so it could not pass in plan 189-01, which was also already full. The effect is that this plan is not evidence-only, so the GATE-02 stop did not trigger.

**2. [Rule 2 - Missing critical functionality] One extra contract case.** The plan lists three smoke cases. A fourth, `accept smoke command line exits 0 ... and 1 with a message when no base URL is set`, covers the CLI path the deploy step actually runs (exit codes and the missing-URL message), which the library-level cases do not. The `website_contract_test.exs` floor is 82, the new call count.

**3. [Rule 2 - Missing critical functionality] The smoke does not fetch URLs outside the base.** The plan says every resolved URL must be under `/scrypath/`. A URL that resolves outside is reported by the `base-path` check and not requested, so a bad `og:image` cannot send the smoke to an arbitrary host. The planted og:image case asserts the URL was not requested.

**4. [Rule 2 - Missing critical functionality] Soft-check retry and cache bypass.** The rollback soft check keeps the plan's `curl -fsSI` but adds `--retry 3 --retry-delay 10 --retry-all-errors` and the `?smoke=` query, so a rollback is not red for propagation delay and does not read a stale edge copy.

**5. [Honest limit, recorded] The Chrome path has no reinstall after a green probe.** `check.mjs` falls back to the default Chromium if a channel launch throws, but on a runner that took the Chrome path the default Chromium is not installed. The plan's wording ("a late failure still degrades to the known-good browser") holds only when the probe fails. The probe launches the same channel from the same Playwright, so a late failure is unlikely, and it would be a red job, not a hidden pass. Recorded in CI-EFFICIENCY finding 5 and the phase record. No code change, because reinstalling inside the check step would add a second install path to maintain for a case the probe already guards.

**6. [Rule 3 - Blocking] Plan-head ledger file not written.** The harness refused the compound git command that writes it, as in plans 189-01 and 189-02. `commits` is measured with `git rev-list --count` from the orchestrator-supplied base (`802f0796`) and is 3, before this summary's own docs commit.

**7. Playbook rule ids.** The plan said "next free ids". The new rules are S29, S30 and T22 to T25 (the S table ended at S28, the T table at T21). All are `draft`: no hosted run has exercised them.

**8. Nonblocking subjective note not written.** The plan allows a rendering-impressions note only if the screenshots were looked at. No captures were run in this plan (the plan forbids them), so there is none.

## Deferred to ship (named, with owner and command in `189-PHASE-RECORD.md`)

These do not exist before the push and the merge. They are deferred-to-ship, not unverified and not `human_needed`. The orchestrator fills the result cells in a `.planning`-only commit after the merge.

1. **Exact-head check:** `gh api --paginate repos/szTheory/scrypath/commits/<head>/check-runs`, showing `build-and-check` completed and successful with `head_sha` equal to the PR head, and the six required contexts successful on the same head. Run before the squash merge.
2. **Post-merge `deploy` run and smoke output:** the merge commit's run is green and the smoke step shows the font (200, `font/woff2`, pinned hash), both lockups, the social card and `favicon.ico` under `/scrypath/`. This is also the first evidence for the Pages `content-type` on `.woff2`.
3. **After install numbers:** the PR's `build-and-check` run times for `CI-EFFICIENCY.md` finding 5.

## Follow-ups and open items

- Upstream favicon issue: drafted in the phase record, not filed (the maintainer's step, D-52).
- Two Hex-shipped guides still name the repo-only `mix verify.adopter`: `guides/outside-adopter-intake.md` lines 32 and 33, `guides/support-and-compatibility.md` lines 131 and 132. Contract-tested, unchanged, and the fix rides the next library release the maintainer chooses (D-54).
- `docs/releasing.md` ships in the Hex package, so its new section ships with the next release.
- Residuals (workflow-level cancel group, Pages `max-age=600` with unhashed asset URLs, untested Safari CSP, screen readers, card cropping, `.ico` rendering, the bundled Playwright Chromium) are in the phase record.

## What this does not prove

Rendered quality and aesthetics, browsers other than the Chromium family (Safari's handling of the meta CSP in particular), real screen readers, social-platform card cropping, how the `.ico` renders, the Pages `content-type` for `.woff2` before the first post-merge smoke, the hosted behavior of the new browser step (it has run only as shell logic and a local probe with Chrome 158), and that anyone approved the result. Nothing here claims aesthetic or independent-review approval.

## Known Stubs

None. No placeholder data reaches any page.

## Threat Flags

None beyond the plan's register. T-189-12 (dispatch input) is asserted by the wiring test: `inputs.ref` must appear exactly twice and only as a checkout `ref:`. T-189-13 holds: no new action, existing pins unchanged. T-189-SC holds: `website/package.json` gains one script line and no dependency, and `package-lock.json` is unchanged.

## Self-Check: PASSED

The created files (`smoke.mjs`, the phase record, the receipt, this summary) exist; the three commits (`f9d607de`, `76948c2e`, `8c4fa990`) are ancestors of the head; the receipt's tested SHA is an ancestor and the diff from it to the head touches only `.planning/`; the working tree was clean before this file was added.
