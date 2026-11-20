---
phase: 189-website-re-skin
reviewed: 2026-11-20T19:14:29Z
depth: standard
files_reviewed: 29
files_reviewed_list:
  - .github/workflows/website.yml
  - CONTRIBUTING.md
  - dev/mix/tasks/verify.phase99.ex
  - docs/releasing.md
  - examples/scrypath_ecommerce/retired-identity-allowlist.json
  - examples/scrypath_ecommerce/ui-tokens.test.mjs
  - test/mix/tasks/ui_contrast_contract_test.exs
  - test/mix/tasks/verify.phase99_test.exs
  - test/mix/tasks/website_contract_test.exs
  - test/mix/tasks/workflow_wiring_test.exs
  - website/package.json
  - website/scripts/build.mjs
  - website/scripts/check.mjs
  - website/scripts/lib/contract.mjs
  - website/scripts/lib/golden.mjs
  - website/scripts/lib/server.mjs
  - website/scripts/lib/wcag.mjs
  - website/scripts/serve.mjs
  - website/scripts/site-contract.test.mjs
  - website/scripts/smoke.mjs
  - website/scripts/theme-mode.mjs
  - website/src/assets/styles.css
  - website/src/assets/theme.js
  - website/src/layout.html
  - website/src/pages/docs.html
  - website/src/pages/index.html
  - website/src/pages/operators.html
  - website/src/partials/diagram.svg
  - website/src/partials/theme-picker.html
findings:
  critical: 1
  warning: 9
  info: 3
  total: 13
  necessity: 1
status: issues_found
---

# Phase 189: Code Review Report

**Reviewed:** 2026-11-20T19:14:29Z
**Depth:** standard
**Files Reviewed:** 29
**Status:** issues_found

## Summary

Reviewed the phase 189 source changes at HEAD 5c1d461c against origin/main: the website deploy workflow,
the build, serve, smoke and browser-check scripts, the static contract and its test, theme.js, the CSP
meta, the layout and stylesheet, and the wiring and ledger tests around them. Necessity was assessed
against `necessity-review.md`.

Cheap runs were green and are not evidence of correctness here: `node --test` on the site contract (82 of
82), `node --test` on `ui-tokens.test.mjs` (61 of 61), `mix test` on `workflow_wiring_test.exs` (87 of 87)
and on `website_contract_test.exs`. Several findings below were reproduced in a scratch copy under the
session scratchpad (never in the repository), and each one passes every test that exists today.

What holds up: `serve.mjs` refused every traversal form tried (`..%2f`, double slash, NUL, backslash,
header injection through the redirect path), `theme.js` is 1791 bytes with try/catch around every storage
access and a synchronous head script, the CSP meta is first after the charset and matches the contract,
the stylesheet uses CSS-relative font URLs, and the built pages carry no root-absolute reference. The
problems are in the deploy safety net (the rollback path does not work for the case it exists for), in
guards with holes, and in a smoke check that is weaker than the fallback it replaces.

Not verified: browser behavior (no Playwright run, per instructions), the live Pages deployment-branch
behavior, and the hosted workflow itself.

## Critical Issues

### CR-01: A rollback to any commit before this phase cannot pass `build-and-check`, so the documented rollback fails for its main use

**File:** `.github/workflows/website.yml:66-80` (and the soft-check branch at `:141-148`)
**Issue:** The "Select browser" step skips `npx playwright install` whenever the runner's Chrome launches,
and only passes the choice on through `SCRYPATH_BROWSER_CHANNEL=chrome`. Only the new `check.mjs` reads
that variable (`website/scripts/check.mjs:107-116`). The `check.mjs` on origin/main calls a bare
`chromium.launch()` (`git show origin/main:website/scripts/check.mjs`, line 42), which needs Playwright's
own Chromium, and that is exactly what was just not installed. A `workflow_dispatch` run with
`ref=<a commit from before this phase>` therefore fails in `build-and-check` with "Executable doesn't
exist", `deploy` never starts, and the old site is not restored. That is the scenario the rollback input
and the whole safety net were built for: the re-skin turns out bad and the previous site must come back.

It also makes the soft-check branch (`if [ -f website/scripts/smoke.mjs ] ... else curl`) unreachable on
main's history. This repository squash-merges, so every commit that lacks `smoke.mjs` also lacks the
channel support in `check.mjs`; the commits that have one have the other. `docs/releasing.md` ("A rollback
to a commit that predates the smoke script runs only a soft check") describes a path that cannot be reached.

The wiring test passes while this is wrong: `assert_website_safety_net!` checks that the probe string
and the install string exist and appear in order (`test/mix/tasks/workflow_wiring_test.exs`, the probe
and install index asserts), never that the checked-out ref's `check.mjs` can use the channel.

**Fix:** Take the runner Chrome only when the checked-out ref can use it:
```yaml
run: |
  if grep -q SCRYPATH_BROWSER_CHANNEL scripts/check.mjs \
    && google-chrome --version \
    && node -e "import('playwright').then(async ({ chromium }) => { const browser = await chromium.launch({ channel: 'chrome' }); await browser.close(); })"; then
    ...
  else
    npx playwright install --with-deps chromium
  fi
```
Add a wiring assertion that the `grep -q SCRYPATH_BROWSER_CHANNEL` guard is part of the condition. The
documented rollback is then also worth one real dry run: dispatch with `ref=2bfaeab3` (origin/main before
this branch) and confirm it reaches the soft check.

## Warnings

### WR-01: The workflow-level group still cancels an in-flight deploy, a main push can cancel a rollback, and the docs say the opposite

**File:** `.github/workflows/website.yml:34-36` and `:94-96`; `docs/releasing.md:157`
**Issue:** `concurrency.group: website-${{ github.workflow }}-${{ github.ref }}` with
`cancel-in-progress: true` applies to the whole run. A `workflow_dispatch` run from `main` and a push to
`main` both resolve `github.ref` to `refs/heads/main`, so they share one group and whichever starts later
cancels the other, deploy job included. The job-level `website-pages-deploy` group (`cancel-in-progress:
false`) never gets a chance to protect anything, because the run holding it is cancelled first. The doc's
first sentence ("a newer push waits for a deploy that is already running instead of cutting it off") is
false; its second sentence concedes the opposite.

Concrete failure: an operator dispatches a rollback; while its `build-and-check` runs (about a minute), any
Dependabot or docs push to `main` that matches the path filter starts a run in the same group, cancels the
rollback, and deploys the bad `main` again. Nothing tells the operator the rollback never ran.

**Fix:** Drop the workflow-level group, give `build-and-check` its own job-level group (cancel superseded
checks), key rollbacks separately, and keep the no-cancel group on `deploy`:
```yaml
  build-and-check:
    concurrency:
      group: website-check-${{ github.event_name == 'workflow_dispatch' && 'rollback' || github.ref }}
      cancel-in-progress: true
```
Update the wiring assertion that currently pins the workflow-level block, and rewrite the doc paragraph to
match the behavior that results. Also state in the rollback doc that the next matching push to `main`
redeploys `main` unless the bad commit is reverted.

### WR-02: The deploy job has no timeout and the smoke has no request timeout

**File:** `.github/workflows/website.yml:90-148`; `website/scripts/smoke.mjs:62-87`
**Issue:** `build-and-check` got `timeout-minutes: 10`, `deploy` did not, so it inherits the 360-minute
default. The new smoke step is the first step in this workflow that talks to a remote host with
unbounded waits: `fetch(target, { redirect: 'follow' })` has no `AbortSignal`, so each hung connection
waits out undici's default (about 5 minutes) and, being a network error, is retried twice more. Six
requests make a worst case measured in hours. The wiring contract asserts the build timeout
(`assert build =~ "timeout-minutes: 10"`) and nothing for deploy.

**Fix:** Add `timeout-minutes: 15` to `deploy` and pin it in `assert_website_safety_net!`; add
`signal: AbortSignal.timeout(20000)` to the `fetch` call in `request()` (a timeout then counts as a network
error and is retried by the existing policy).

### WR-03: The smoke never fetches the stylesheet, tokens or theme script, so it is weaker than the soft check it replaces

**File:** `website/scripts/smoke.mjs:139-213`
**Issue:** The declared-asset list covers font preloads, lockups, icon links and the social image only. A
deploy that serves the HTML but 404s `assets/styles.css`, `assets/tokens.css` or `assets/theme.js` passes.
Reproduced: building the real site, serving it under `/scrypath/`, deleting those three files and running
`runSmoke` returns `ok = true`. The pre-smoke fallback in the workflow does request
`assets/styles.css`, so a new ref gets less verification of the one asset that makes the page look right
than an old ref does. The docs list what the smoke checks and do not claim styles, so the docs are honest;
the gap is in what the safety net covers.

**Fix:** Add the `link[rel=stylesheet]` hrefs and the head `script[src]` to `declared`, and a `stylesheet`
check (200, `text/css`). Add a planted case next to "planted smoke fails when a pinned font is missing".

### WR-04: `smoke.mjs` silently does nothing and exits 0 when it is started through a symlinked path

**File:** `website/scripts/smoke.mjs:238-240`
**Issue:** The "run main only when executed directly" guard compares `path.resolve(process.argv[1])` with
`fileURLToPath(import.meta.url)`. Node resolves symlinks for the main module, so the two differ whenever
the path used to start the script crosses a symlink. Reproduced: with the website directory symlinked,
`node lnk/scripts/smoke.mjs` printed nothing and exited 0, where the direct path exits 1 with the "needs a
base URL" message. A safety check that can pass by not running is the worst failure mode for it. GitHub's
hosted runners use a real workspace path, so the deploy job is not affected today; `npm run smoke` from a
symlinked checkout or worktree, or a self-hosted runner with a symlinked workspace, is.

**Fix:**
```js
import { realpathSync } from 'node:fs';
if (process.argv[1] && realpathSync(process.argv[1]) === fileURLToPath(import.meta.url)) {
  await main();
}
```
Add a case that runs the script through a symlink and expects the missing-URL exit code 1.

### WR-05: The build's output guard only protects one direction, so `--out` inside the sources deletes them

**File:** `website/scripts/build.mjs:220-230`
**Issue:** `assertSafeOut` refuses an output directory that equals or contains `repoRoot`, `websiteDir`,
`srcDir`, `brandDir`, the home directory or the filesystem root. It does not refuse one that sits inside
them, and `build.mjs` then runs `rm(distDir, { recursive: true })`. Reproduced in a scratch copy of the
repository: `node website/scripts/build.mjs --out <repo>/website/scripts` wiped the build scripts and wrote
the site there; `--out <repo>/brand/assets` deleted the pinned brand assets and the build then crashed on
the missing source file. Both exit paths passed the guard. The same flaw means any ordinary directory
(`--out ~/Documents`) is accepted and emptied. The only planted case covers the contains-brand direction.

**Fix:** Refuse an output directory that is inside any input directory or the pinned-source directories,
and refuse a non-empty directory that does not look like a previous build output (for example require a
marker file the build writes, or an empty directory). Add planted cases for `--out` inside `srcDir`,
inside `websiteDir/scripts` and inside the brand directory.

### WR-06: The root-absolute guards miss several forms, and the request-log check cannot see origin-root 404s

**File:** `website/scripts/lib/contract.mjs:634-637` and `:752-760`; `website/scripts/check.mjs:284-295` and `:925-929`
**Issue:** The contract and the browser check look for root-absolute URLs in `href`, `src`, `srcset`
(first candidate only), `poster`, `xlink:href` and CSS `url(...)`. Reproduced against a build of the real
site, each of these passes `checkBuilt` with zero violations: `@import "/assets/other.css";` in
`styles.css`, `<meta http-equiv="refresh" content="0;url=/" />`, and a `srcset` whose second candidate is
`/assets/b.png 2x`. Under `/scrypath/` each of these resolves at the origin root and 404s. The late
request-log assertion in `check.mjs` was meant to catch what the static scans miss, but it only counts
404s whose path starts with `/scrypath/` plus a root `/favicon.ico`, so a root-absolute fetch that 404s at
the origin root is invisible. Nothing in today's source uses these forms; the guard is what is supposed to
stop the next edit that does.

**Fix:** Parse every `srcset` candidate, scan `@import` (with and without `url()`), scan `content` of
`meta[http-equiv=refresh]`; in the request-log check fail on any 404 except the check's own probes
(`/`, `/index.html`, the flush marker). Add one planted case per form.

### WR-07: A failure while taking review screenshots fails `build-and-check`, which blocks the deploy

**File:** `website/scripts/check.mjs:937-941` and `:974-1008`
**Issue:** The screenshots are documented as "never gate" (`:934`, `:1007`), but `captureScreenshots` runs
inside the `try` with no `catch`. Any throw there (a `page.screenshot` timeout, `open()` waiting on
`networkidle`, an unwritable directory in CI, which the code deliberately rethrows at `:988-992`)
propagates out of the `finally`, ends the process with a non-zero exit before the `check-summary` line is
printed, and turns the job red after every assertion passed. Because `deploy` has `needs: build-and-check`,
a flaky capture stops a deploy and, on a rollback, stops the rollback.

**Fix:** Wrap the capture call so an error is logged and the run continues:
```js
try {
  await captureScreenshots(browser);
} catch (error) {
  console.log(`screenshots: failed, ${String(error?.message ?? error).split('\n')[0]}; they do not gate`);
}
```

### WR-08: Nothing in the workflow restricts the deploy to `main`; the doc relies on an environment the deploy job never names

**File:** `.github/workflows/website.yml:90-91`; `docs/releasing.md` (Rollback paragraph); `test/mix/tasks/workflow_wiring_test.exs` (`refute deploy =~ "environment:"`)
**Issue:** The doc states "The `github-pages` environment allows `main` only, so the dispatch runs on
`main`". The environment does restrict deployments to `main` (checked through the API), but the `deploy`
job declares no `environment:` and the wiring test asserts it must not. GitHub evaluates deployment branch
policies for jobs that reference the environment; the repository shows nothing that makes the Pages
deployment API enforce the policy for a job that never names it. If it does not, any contributor with write
access can dispatch the workflow from a branch whose copy of `website.yml` is edited and publish arbitrary
content with `pages: write` and `id-token: write`, without a PR. This could not be proven either way from
the repository, so the doc's claim is unsupported rather than shown false.

**Fix:** Make it deterministic and independent of the environment setting, then update the exact-match
assertion in the wiring test:
```yaml
if: (github.event_name == 'push' || github.event_name == 'workflow_dispatch') && github.ref == 'refs/heads/main'
```

### WR-09: Phantom requirement: the light-only theme mode is machinery for a fallback that has lapsed, and it is not a working switch anyway

**File:** `website/scripts/theme-mode.mjs:1-10`; `website/scripts/build.mjs:322-330` and `:373-396`; `website/scripts/lib/contract.mjs:601-605`, `:685-695`, `:869-872`, `:905-907`; `website/scripts/check.mjs:647-683`; `website/scripts/lib/golden.mjs`, `website/scripts/site-contract.test.mjs` (the `PICKER_MODE` else branches)
**Category:** necessity
**Issue:** The `THEME_MODE` switch and every `light-only` branch exist for the SITE-02 fallback (D-25), which
was "decided now" with a deadline: take it only if the picker is not green by the end of plan 189-02. The
phase record states the picker was green on the first run, the fallback did not fire, and `THEME_MODE`
stays `picker` (`189-PHASE-RECORD.md` line 23, `189-02-SUMMARY.md`). The requirement has lapsed, and about
24 references across the build, contract, browser check, fixture and test carry it. It is also not the
one-line switch its header comment promises: with `THEME_MODE` set to `light-only` in a scratch copy,
`build.mjs` still copies `src/assets/theme.js` into the output (`cp` of the whole assets directory) and
`styles.css` still carries `data-theme` selectors, so the real site fails its own contract with 14
violations. The light-only path is exercised only on the synthetic fixture, never on the real source.
**Fix:** This is a scope decision, so it is flagged rather than prescribed: either delete the light-only
branches and the constant (the picker is the shipped product), or keep them and make the real source
mode-aware (skip copying `theme.js` and the dark and system selectors in light-only mode) with a live case
that builds the real site in that mode. Do not leave a documented switch that does not work.

## Info

### IN-01: A dispatch with a branch or tag name can validate one commit and deploy another

**File:** `.github/workflows/website.yml:44-51` and `:106-110`
**Issue:** Both jobs check out `ref: ${{ inputs.ref }}` independently, and the input defaults to `main`. On
a push the checkout resolves to the event SHA, so the two jobs agree; for a branch or tag name they resolve
separately, and a push landing between the jobs means `deploy` builds a commit `build-and-check` never saw.
The docs recommend a commit SHA, which avoids it, but the default does not.
**Fix:** Resolve the input to a SHA in `build-and-check` (`git rev-parse HEAD` as a job output) and have
`deploy` check out `needs.build-and-check.outputs.sha`. This keeps `inputs.ref` out of any `run` text.

### IN-02: Build robustness: `SITE_URL` is not normalized and a failed pin check leaves a half-written output

**File:** `website/scripts/build.mjs:34` and `:148-156`
**Issue:** `siteUrl` is used as `{{SITE_URL}}assets/...`, so a value without a trailing slash produces
`https://host/scrypathassets/...` in `og:image`, the canonical link and the sitemap; `smoke.mjs:101-103`
normalizes the same value, so the two tools disagree on what a valid base is. Separately, the pin hash of
each copied asset is verified inside `copyPinned` after `rm(distDir)` has run, so a pin mismatch leaves a
partial `website/dist` (the planted case for it does not assert the output is absent, unlike the role-map
case that does). CI is unaffected because the build fails the job.
**Fix:** Append `/` when `SCRYPATH_SITE_URL` lacks one, and verify every pin before the `rm`.

### IN-03: `finalUrl` is recorded by the smoke and never used, so a redirect out of the base path goes unnoticed

**File:** `website/scripts/smoke.mjs:73` and `:80`
**Issue:** `request()` follows redirects and stores `response.url` as `finalUrl`, but no check reads it. The
base-path check compares only the URLs the page declares, so a declared in-base asset that redirects to
another origin or path still counts as fetched and, for the lockups and favicon, passes on status and
content type alone.
**Fix:** Either assert `new URL(response.finalUrl).href` stays under the base in `check()` or drop the field.

---

_Reviewed: 2026-11-20T19:14:29Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

---

## Fix disposition

**Applied:** 2026-11-20, in the main checkout (no worktree), on top of `a9b07109`. One commit per
finding; each new test was run red on the unfixed code first and green after. Verification ran in the main
checkout, so every number below reproduces from this tree.

### Fixed

| Finding | Commit | What changed | Regression test (red before, green after) |
| --- | --- | --- | --- |
| CR-01 | `58737f61` | `Select browser` takes the runner Chrome only when `grep -q SCRYPATH_BROWSER_CHANNEL scripts/check.mjs` holds, otherwise runs `npx playwright install --with-deps chromium`. Rollback section of `docs/releasing.md` says so. | `workflow_wiring_test.exs`: the guard must exist and precede the Chrome probe; a planted workflow without it is rejected; a new test runs the real step script against stub `google-chrome`, `node` and `npx` and shows a pre-phase `check.mjs` gets the install and no `SCRYPATH_BROWSER_CHANNEL`, a supporting one gets the channel and no install. |
| WR-01 | `5fb4366c`, `209260ec` | Workflow-level `cancel-in-progress` is `${{ github.event_name == 'pull_request' }}`; a `workflow_dispatch` run keys its own `rollback` group; the job-level non-cancelling deploy group is kept. The self-contradicting sentence in `docs/releasing.md` is rewritten, and the doc now says a rollback holds only until the next matching push (revert the bad commit) and that a waiting rollback deploy can be replaced by GitHub, so the smoke step must be confirmed. | Wiring test pins the exact block and refutes a workflow-level `cancel-in-progress: true`; two planted workflows (cancel everything, rollback shares the push group) are rejected. The old assertion that pinned `cancel-in-progress: true` at workflow level was replaced, not loosened: it asserted the defect. |
| WR-02 | `7303c544` | `timeout-minutes: 15` on `deploy`; every smoke request (headers and body) is abandoned after `timeoutMs` (default 20000) and retried as a network error. | Wiring test pins the deploy timeout and rejects its removal. New `planted smoke fails within its request timeout ...` stalls a local server before the headers and mid-body and expects a failed `home` check within the timeout and one retry; before the fix it hung until the 20 s test timeout. |
| WR-03 | `0f13ce38` | The smoke requires `styles.css` and `tokens.css` to be declared, fetches every declared stylesheet (200, `text/css`, non-empty) and script (200, JavaScript type, non-empty), and includes their URLs in the base-path check. | Four planted cases: stylesheet missing, `tokens.css` missing, `theme.js` missing (`theme-picker`-tagged with a light-only form), stylesheet and script served as `text/plain`. The accept case now expects the `stylesheet` and `script` codes. |
| WR-04 | `3b88320c` | Entry-point guard compares real paths on both sides. | `planted smoke still runs and exits 1 ... through a symlinked path`; before the fix it exited 0 with no output. |
| WR-05 | `b0aa3f45` | `assertSafeOut` now also refuses an output that is, or is inside, the source directory, the given and the repository's own brand directory, `scrypath_ops`, `website/scripts`, `website/node_modules` or `.git`, comparing real paths so a symlink cannot hide one. `website/dist` stays allowed. | Five planted cases (inside src, a src subdirectory, inside a brand copy, inside the real brand, font and scripts directories, through a symlink), each safe by construction (scratch copies, or a path that does not exist yet). |
| WR-06 | `ea379d1f` | `checkBuilt` scans every `srcset` candidate, `@import "..."` string form in built CSS, and the target of `meta http-equiv=refresh` in the `0;url=/`, `0; URL='/x'` and `0;/x` forms. | Three planted cases plus one accept case (relative and absolute-URL forms raise nothing). |
| WR-07 | `4653b876` | `captureScreenshots(browser)` runs inside try/catch that logs the first error line and carries on. | Scratch run with an unwritable website directory under `CI=1`: old script crashes with EACCES and exit 1, no summary line; fixed script logs `screenshots: failed ...; they do not gate`, prints `check-summary: ran=11 failed=none`, exits 0. In the contract, a `live` case reads `check.mjs` (the contract cannot run a browser) and a `planted` case proves the reader rejects a missing catch, a rethrow and a silent catch. |
| WR-08 | `43fa0990` | `deploy` job `if:` is `(push or workflow_dispatch) && github.ref == 'refs/heads/main'`; `docs/releasing.md` no longer relies on the `github-pages` environment and says a dispatch from another branch builds and checks but does not deploy. The job still does not name the environment. | Wiring tests pin the full condition (two places) and reject a workflow that drops the ref clause or the event clause. |

### Counted floors

- `@min_site_test_calls` in `test/mix/tasks/website_contract_test.exs`: 82 to 99, equal to the number of
  `test(...)` calls in `site-contract.test.mjs` (17 added; raised in each commit that added cases, never
  lowered).
- The `theme-picker` vacuity floor (6) is unchanged: 12 cases now carry the tag, so the floor still
  cannot be met by accident. All new case names start with `live`, `planted` or `accept`, are unique and
  contain neither `#` nor a backslash.
- `workflow_wiring_test.exs`: 87 to 88 tests. No ledger row was added, so `CONTRIBUTING.md` stays at
  9 of 12.

### Checks run (main checkout)

`node --test website/scripts/site-contract.test.mjs`: 99 of 99 on Node 26.10, 22.14 and 20.18.
`node --test examples/scrypath_ecommerce/ui-tokens.test.mjs`: 61 of 61. `mix test --warnings-as-errors`
on `workflow_wiring_test.exs` and `website_contract_test.exs`: 89 tests, 0 failures. `mix format
--check-formatted`, `mix credo --strict` on the two changed test files, and `actionlint
.github/workflows/website.yml`: clean. Not run, by instruction: `mix verify.repository_contracts`,
`mix verify.core`, any Docker lane, a dispatch of the real workflow.

### Deferred, no code change

- **WR-09** (necessity, `THEME_MODE` light-only machinery): scope decision, left alone. The picker shipped
  and the SITE-02 fallback lapsed, so the light-only branches are dead weight, and the documented
  one-line switch does not work on the real source (14 violations with `THEME_MODE` set to `light-only`).
  Note for later removal: delete the constant and every `light-only` branch in `build.mjs`,
  `contract.mjs`, `check.mjs`, `golden.mjs` and the `PICKER_MODE` else branches in the contract test, or
  make the real source mode-aware. Until then the new smoke and contract cases keep a light-only form
  where they are mode-dependent.
- **IN-01** (branch or tag `ref` can validate one commit and deploy another): not requested. The docs
  recommend a commit SHA, which avoids it.
- **IN-02** (`SITE_URL` trailing slash, half-written output after a failed pin check): not requested.
- **IN-03** (`finalUrl` recorded and unused in the smoke): not requested.

### Not done within a fixed finding

- WR-05: an ordinary directory outside every protected path (`--out ~/Documents`) is still accepted and
  emptied. The requested fix was the inside-a-protected-path direction; a marker file or an empty-directory
  rule would close this and was not asked for.
- WR-06: the late request-log assertion in `check.mjs` still counts only 404s under `/scrypath/` and a
  root `/favicon.ico`, so a root-absolute fetch that 404s at the origin root is invisible to the browser
  check. The static detectors now catch the three missed forms; the request-log tightening was left out of
  the requested scope.

### What still needs hosted evidence

These edits touch the workflow, wiring tests, docs and website scripts, so the receipt for `76948c2e` no
longer covers the tree. Gate evidence for the pushed head comes from the hosted required checks (the
orchestrator records that decision). The reviewer's suggested real rollback dry run (dispatch with
`ref=2bfaeab3` and confirm it reaches the soft check) cannot run before a push and is still worth doing
once the fix is on `main`.
