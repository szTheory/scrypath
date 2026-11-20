# Phase 189 record: website re-skin

Written in plan 189-03 (2026-11-20). It holds the decisions, the procedures the orchestrator runs after the push and the merge, the drafted upstream issue, the follow-ups, and what the evidence does not prove. Detail for each plan is in `189-01-SUMMARY.md`, `189-02-SUMMARY.md` and `189-03-SUMMARY.md`.

## Resolved notes

**(a) The closed hex set.** The website contract asserts that every hex in the built output belongs to one closed set. The set is every hex the role map can legitimately emit, in three parts:

1. every hex in `brand/tokens.json`;
2. every `text` and `background` hex in `brand.json` `color.contrastPairs` (the dark selected-row color `#2B2130` lives only there, under the ids `selected-row` and `selected-status`);
3. the Control Edge sentence hex (the dark control edge, named only in the Control Edge role description in `brand.json` and `tokens.json`).

The earlier wording "the brand token set" in `189-CONTEXT.md` D-27 and in ROADMAP Phase 189 success criterion 1 meant this set. Criterion 1 in `.planning/ROADMAP.md` now says it in full (a scoped edit in this plan). The binding `189-CONTEXT.md` is unchanged and points here. The implementation is `closedHexSet` in `website/scripts/lib/contract.mjs`, with its own cases in `site-contract.test.mjs`.

**(b) The three open contradictions in `189-CONTEXT.md`, as resolved.**

1. The dark control-edge hex `#8F7F94` is in no contrast pair. It is held as one literal in the `build.mjs` role map, and both the build and the contract assert it equals the hex named in the Control Edge sentence of `brand.json` and `tokens.json`, so a brand change that moves it fails the build (`189-01-SUMMARY.md`, key decisions).
2. Ledger row 9 landed in plan 189-01 with the wrapper, so `CONTRIBUTING.md` says 9 of 12 and `workflow_wiring_test` is green with the row. Plan 189-03 adds no gate.
3. The picker fallback was pre-authorized (D-25). It was not needed: see Outcome.

## Outcome

**Picker shipped.** The Light, Dark and System picker, `theme.js` and the dark, system and print token blocks were green on the first run in plan 189-02, so the light-only fallback did not fire. `THEME_MODE` is still `picker`. There is no `SITE-02 FALLBACK TAKEN` line because the fallback was not taken; SITE-02 and success criterion 2 stand as written in `REQUIREMENTS.md`. Source: `189-02-SUMMARY.md`, "Picker outcome".

## Decisions recorded

**`build-and-check` stays a non-required check (D-39).** Reasons:

1. It is a browser job whose recent runs take a median of 64 s (28 completed runs, 2026-11-20), with a slow tail of up to 407 s that the new `timeout-minutes: 10` bounds. Numbers and run ids: `.planning/reference/CI-EFFICIENCY.md` finding 5.
2. Making it required is a branch-protection change. Branch protection is a maintainer setting, and `AGENTS.md` does not grant it to agents.
3. `deploy` has `needs: build-and-check`, so a red check stops the deploy after the merge. That is the post-merge backstop.

**Re-open trigger:** a rendering regression that only this job would have caught reaches `main`. It then becomes gate 10 in the `CONTRIBUTING.md` ledger (9 of 12 used today) with a deletion trigger and its expected churn per UI PR. The same decision is in `docs/releasing.md` ("Website deploy and rollback") and `CI-EFFICIENCY.md` finding 11. Because merging to `main` deploys the website and this check is not required, the orchestrator merges the Phase 189 PR only after `build-and-check` is green on the exact head (procedure below).

**Plan split and why plan 189-03 also edits the workflow (deviation from D-44).** D-44 puts the path filters, install fix, deploy concurrency, smoke script and dispatch input in plan 189-01. They are in plan 189-03 for two reasons: the smoke accept case (the real build served under `/scrypath/` and smoke-tested) needs the 189-02 markup (font preloads, lockups, og meta, icon links), so it cannot pass earlier; and plan 189-01 was already full. As a result plan 189-03 is not evidence-only (it edits `website.yml`, ships `smoke.mjs` and changes a wiring test), and no second consecutive evidence-only plan exists, so the GATE-02 stop did not trigger.

**Browser selection on the runner (D-33).** `build-and-check` uses the runner's Chrome through Playwright's `chrome` channel when `google-chrome --version` succeeds and a launch probe exits 0, and otherwise runs the known-good `npx playwright install --with-deps chromium`. Known limit: `check.mjs` falls back to the default Chromium if a channel launch throws, but on a runner that took the Chrome path that Chromium is not installed, so a failure after a green probe fails the job instead of reinstalling. The probe launches the same channel from the same Playwright for that reason.

## Post-ship evidence

These items are **deferred-to-ship**. They cannot exist before the PR is pushed and merged, so they are not unverified and not `human_needed`: each has a command, an owner and a pass condition. The orchestrator fills the Result column in a `.planning`-only commit after the merge, never by pushing to the PR branch (a push to the PR branch would cost another full CI run and make the exact-head evidence stale).

| # | Item | Command | Owner | Pass condition | Result |
|---|------|---------|-------|----------------|--------|
| 1 | Exact-head check on the PR head | `gh api --paginate repos/szTheory/scrypath/commits/<head>/check-runs --jq '.check_runs[] \| [.name, .status, .conclusion, .head_sha] \| @tsv'` | orchestrator, before the squash merge | `build-and-check` is `completed` with conclusion `success` and `head_sha` equal to the PR head; the six required contexts (`core`, `package`, `repository-contracts`, `backend`, `ecommerce-mounted`, `ops-ui (path-scoped)`) are `success` on the same head | |
| 2 | Post-merge `deploy` run and its smoke step | `gh run list --workflow website.yml --branch main --limit 5 --json databaseId,headSha,status,conclusion,event`, then `gh run view <id> --log` for the merge commit's run | orchestrator, after the merge | `deploy` is green for the merge commit and the smoke step output shows `ok` for the ui font (200, `font/woff2`, pinned hash), both lockups, the social card and `favicon.ico`, all under `/scrypath/` | |
| 3 | After numbers for the browser install | `gh run view <id> --json jobs` for the PR's `build-and-check` run; read the whole-job time and the "Select browser" step time | orchestrator, after the merge | cold and warm numbers (or the one hosted number there is) are written into `CI-EFFICIENCY.md` finding 5 beside the 64 s median and 175 s p90 before numbers | |

## Exact-head evidence procedure (D-40)

Run by the orchestrator before the squash merge:

```bash
gh api --paginate repos/szTheory/scrypath/commits/<head>/check-runs \
  --jq '.check_runs[] | [.name, .status, .conclusion, .head_sha] | @tsv'
```

Read three things. `build-and-check` is `completed` and `success`. Its `head_sha` equals the PR head (a green run on an earlier head does not count, because the squash merge deploys the head). The six required contexts are `success` on that same head. If any is missing, queued or red, do not merge. A `build-and-check` that is absent means the path filter did not match the PR, which for this phase would itself be a defect in the filter, since the PR changes `website/**` and `brand/**`.

## Post-merge proof procedure (D-43)

Run by the orchestrator after the squash merge:

1. Find the merge commit's run: `gh run list --workflow website.yml --branch main --limit 5 --json databaseId,headSha,status,conclusion,event`, and wait for `completed`.
2. Confirm `deploy` is green and read its "Smoke test the deployed site" step in `gh run view <id> --log`. It must show `ok` for the ui font (200, `font/woff2`, the pinned sha256), both lockups, the social card and `favicon.ico`, with every asset URL under `/scrypath/`.
3. This first smoke is also the evidence for the one fact no earlier check can establish: the `content-type` GitHub Pages sends for `.woff2`. The live site has served no `.woff2` before. If that header is not `font/woff2`, the smoke is red for a real reason, and the answer is to decide whether the header or the check is wrong, not to loosen the check unseen.
4. If the smoke is red, roll back with a manual run, not a retry loop: `gh workflow run website.yml --ref main -f ref=<last-good-sha>`. The `github-pages` environment allows `main` only, so the dispatch runs on `main` and `ref` names the commit to redeploy. A rollback to a commit that predates `smoke.mjs` ends in the soft check (`curl -fsSI` on the home page and the stylesheet). Details: `docs/releasing.md`, "Website deploy and rollback".

No Hex release, no tag and no branch-protection change are part of this phase.

## Residuals

- The workflow-level concurrency group keeps `cancel-in-progress: true`. A newer push to `main` can cancel an in-flight run, including its deploy job, and the newer run then redeploys. The deploy job's own group (`cancel-in-progress: false`) protects against its own queue, not against the workflow-level group.
- GitHub Pages answers `max-age=600` and the asset URLs are not content-hashed, so for up to ten minutes a visitor can get new HTML with an old stylesheet. The `?smoke=` query keeps the smoke itself from reading a stale copy; it does not change what a visitor gets.
- Safari's handling of the meta Content-Security-Policy, other browsers, real screen readers, social-platform card cropping and how the `.ico` renders are not exercised by anything in this phase.
- The bundled Playwright Chromium has not run locally (Chrome 158 was used for every local browser step). The first hosted `build-and-check` is its evidence, and under the new step it may run the runner's Chrome instead.

## Upstream favicon issue (D-52): DRAFT ONLY, not filed

Filing this in `szTheory/scrypath-brand` is the maintainer's step and does not gate the phase. The Phase 191 tripwire test and consumer scan (CLEAN-05) belong to Phase 191, not here. Wording adapted from prep note D, "Item 5"; the claims were re-checked on 2026-11-20 against the pinned copy.

> **Title:** `assets/icon/favicon.svg` renders black in every theme
>
> `assets/icon/favicon.svg` (the copy pinned at `ced7c40e`) puts class names on its paths (`g`, `l`) but has no `<style>` block and no `fill` attribute; a search for `<style` and `fill` finds nothing. Browsers paint it black on both light and dark tab strips. The brand book says the favicon follows the device's light or dark setting (`BRAND.md`, "With System chosen..." paragraph, line 794) and lists `icon/favicon.svg` as the symbol file (line 1017).
>
> Please add a `<style>` block with a `prefers-color-scheme: dark` rule (Orchid slash, Pale Ink letters) or ship the file with explicit fills, and add a test that renders it in both schemes.
>
> Scrypath's website does not use this file. It serves the themed `favicon-light.svg` and `favicon-dark.svg` and the `.ico` instead.
>
> A related, smaller point from the same adoption: the dark Control Edge color `#8F7F94` appears only inside the Control Edge role sentence in `brand.json` and `tokens.json`. It is in no contrast pair and no token value, so a consumer has to read prose to get it. A token or a contrast pair for it would let consumers derive it. (Scrypath holds it as one literal in its role map and asserts it equals the sentence.)

## Follow-up (D-54): two Hex-shipped guides still name a repo-only task

Two guides that ship in the Hex package still describe `mix verify.adopter` and `mix verify.adopter --live`, which exist only in a source checkout of the repository:

- `guides/outside-adopter-intake.md` lines 32 and 33.
- `guides/support-and-compatibility.md` lines 131 and 132 (the live command is explained again on line 134).

They are contract-tested (`test/scrypath/docs_contract_test.exs`, around lines 315 to 325, asserts the `mix verify.adopter` parity), so they were not changed in Phase 189. A document that ships in a Hex release cannot be corrected after that release, so the fix rides the next library release the maintainer chooses, together with the contract test that pins the wording. The website pages themselves no longer name the repo-only task (SITE-06, plan 189-02); the docs-page tile now points readers at the support guide, whose wording differs from the tile.

## What this does not prove

- Rendered quality and aesthetics. No aesthetic or independent-review approval is claimed; screenshots are review artifacts only and nothing here depends on them.
- Browsers other than the Chromium family (Chrome 158 locally, the runner's Chrome or Playwright Chromium in CI). Safari's handling of the meta Content-Security-Policy in particular.
- Real screen readers.
- Social-platform card cropping.
- How the `.ico` renders.
- The Pages `content-type` for `.woff2` and the live behavior of the deploy and the smoke, until the post-merge items above are filled in.
- Hosted behavior of the new browser-selection step: it has run only as shell logic and a local probe, not on a runner.

## Gate receipts

See 189-GATE-RECEIPT.md

Result summary: one `mix verify.repository_contracts` and one `mix verify.core --exclude integration --exclude docs_contract` ran once each on commit `76948c2ebd5baae68755f9d359faaef53af83c87` and both passed. The only commits after it change files under `.planning/`. Hosted lanes (`ops_ui`, the browser lanes, `backend`, `package`, `build-and-check`) are not covered by the receipt; they are the Post-ship evidence above.
