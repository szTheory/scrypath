# Phase 190 record: wording that does not need the catalog

Written in plan 190-02 (2026-11-20). It holds the decisions, the procedures the orchestrator runs after the push and the merge, the follow-ups, and what the evidence does not prove. Detail for each plan is in `190-01-SUMMARY.md` and `190-02-SUMMARY.md`.

## What landed

- **Glossary first, then the wording.** `GLOSSARY.md` has a Status wording section (Searchable, Pending, Queued, Retry queued, Accepted, Last succeeded, Clear). Screen copy follows it: the Searchable fields row reads Used for search, Not used for search and Not used for search yet.; Last succeeded is the only form; Clear is not shown beside an earlier observation a failed refresh left on screen; work in the host application's queue reads queued (Retry queued, A retry for job N is already queued, The queue has this retry) and accepted is kept only for Meilisearch tasks; schema-level counts read N jobs pending, Nothing pending, retrying or failed and wait for pending sync work to finish.
- **Control room** is in sentence case in 54 places across 28 files, and an `/ops` shell test proves the nav link's `aria-current`, the document title and the command palette item.
- **One table, one test.** `scrypath_ops/test/support/copy_rules.json` holds 14 rows on 14 rendered surfaces, each surface with a state anchor. One ExUnit test in the required `ops-ui` job validates the table against the glossary, scans the tracked files for forbidden text, renders each surface and checks every row. Planted failures run through the same helper code, and a self-check fails when a Status wording term is cited by no row.
- **Dialog pins.** `operator.spec.ts` asserts the promotion dialog's Cancel button is focused when it opens (required `ecommerce-mounted` lane). ExUnit pins the `ops_modal` default focus selector (with a planted override that fails the pin), the two destructive modals, the Save search modal's name-input exception, the saved-search delete confirmation's Cancel button, and every promotion notice sentence (16 named reasons, the fallback, the eligible state and the unchecked state).
- **CI.** The `ops-ui-path` pattern now also matches `GLOSSARY.md`, `DESIGN.md` and the demo's `e2e`, `lib`, `test` and `scripts` directories; `workflow_wiring_test` proves it by behaviour; the `CONTRIBUTING.md` ledger has a row for the table (10 of 12 used).

## Resolved notes

**(a) Deviation from D-27, and why.** `190-CONTEXT.md` D-27 puts the queue and pending wording (D-07, D-08), its rows and surfaces in plan 190-01. They moved to the front of plan 190-02 (Task 1), and plan 190-02's demo-test and phase-record work merged into its last task, because the plan checker measured plan 190-01 at the whole smart-zone budget. The orchestrator decided it under the maintainer's delegation. D-27's constraint holds: exactly two plans, neither evidence-only.

**(b) The nine open contradictions in `190-CONTEXT.md`, as resolved (one line each).**

1. COPY-04's "three destructive dialogs" means the two destructive `ops_modal` dialogs (Confirm index promotion, Confirm delete sync work) plus the saved-search delete confirmation, which is an inline form in the sheet and not a modal. It is pinned as it exists (a Cancel button wired to `cancel_row`; Escape is pinned by an older test). Converting it to a modal is a design change and is deferred.
2. The Cancel button's real accessible name is Cancel index swap, and the spec uses the `cancel` locator that already existed.
3. The table field is the plural `surfaces`, a non-empty list.
4. The COPY-02 exception list is `.planning/`, `brand/` and the table file. A case-sensitive scan needs no list of files already in sentence case.
5. The 2026-11-20 nightly baseline predates seven merges, so a red dispatch is compared with a dispatch on `main` first. The clean baseline is run 44805847191 (see Post-ship evidence, row 1).
6. The aria-current test was added for the Control room route, the one route the rename touches.
7. The repeated Pending (the status word then "1 job pending") is accepted as the literal result of the rule, and IN-01 (a retry-only queue shows Pending) is deferred.
8. The ledger row count is recomputed at merge. Phase 189 landed first (9 of 12), so this phase's row makes it 10 of 12, written as `Budget used: 10 of 12.`
9. The demo ExUnit test is run separately from the dispatch (it is in no required lane); its result is row 6 below.

**(c) The wording calls stand.** The `[pre-seed call]` choices in `190-CONTEXT.md` were followed as written: Used for search and Not used for search, Last succeeded, N jobs pending, and Retry queued replacing accepted for the host queue. The maintainer may veto any of them later; each is one string edit plus one table row.

**(d) Stubs live once.** The failed-sync stubs (client, Oban inspector, recording insert, environment) and the `Oban.Job` struct stub moved to `scrypath_ops/test/support/copy_stubs/`, so the failed-sync LiveView test and the table's `failed_sync.after_retry` surface share one definition. A consequence: `Oban.Job` is now defined in the whole test environment instead of only when the failed-sync test file loads (a whole-suite run already had it, since every test file loads before any test runs). The sudo confirmation (its Sigra environment and the `sudo!/1` helper) stays in the failed-sync LiveView test, because the namespace fence keeps references to the Sigra integration out of `test/support`; the surface renders the retry in the default host-authenticated mode, where the retry runs without one. The first `mix verify.core` caught the fence violation (see the receipt), and the fix is a code change.

## Decisions recorded

**The `ops-ui` path pattern is extended** (`ci.yml`, `ops-ui-path`) with `GLOSSARY\.md`, `DESIGN\.md` and `examples/scrypath_ecommerce/(e2e|lib|test|scripts)/`, keeping every existing entry. Reason: with squash-on-green and no human merge, a PR that only edits an e2e spec, the glossary or `DESIGN.md` back to the retired casing or a retired status word would skip the guard and be caught only on the push run to `main`, leaving `main` red. Cost: `ops-ui (path-scoped)` takes about 386 s, paid only by PRs that touch those paths (the demo's e2e specs change in a minority of PRs). The alternative, limiting the scan to paths that already trigger the job, was rejected because COPY-02 puts the e2e specs and `DESIGN.md` in scope. The cost, the reason and the revisit trigger are `.planning/reference/CI-EFFICIENCY.md` finding 12.

**Ledger row 10** (`CONTRIBUTING.md`, Required-gate budget): ScrypathOps copy rules table, enforced by `scrypath_ops/test/scrypath_ops_web/copy_rules_contract_test.exs`, running in `ops-ui (path-scoped)`. Deletion trigger: delete when the v1.48 rendered-text copy lint ingests `copy_rules.json` and enforces the same rows, or when scrypath_ops leaves this repository. Expected churn per UI PR: one row edit when a glossary status word changes, one surface edit when a covered LiveView state moves. The budget line reads 10 of 12.

**No branch-protection change, no new required context, no Hex release.** The only `ci.yml` edit is the one pattern line. The squash title is `chore(ops-ui): ...` or `docs(...)`, never `feat` or `fix`, because no library change ships (ScrypathOps is not on Hex).

**No design pass was done.** Nothing in this phase claims aesthetic or independent-review approval. There is no preview refresh, no `npm run ui:preflight`, no `npm run ui:review` and no capture. The wording is proved by ExUnit, a static scan of the source, one required-lane Playwright assertion and the exact-head dispatch only.

## Post-ship evidence

These items are **deferred-to-ship**. They cannot exist before the PR is pushed and merged, so they are not gaps in the evidence and they do not route the verifier to a person: each has a command, an owner and a pass condition. The orchestrator fills the Result column in a `.planning`-only commit after the merge, never by pushing to the PR branch (a push to the PR branch would cost another full CI run and make the exact-head evidence stale). Rows 2 to 5 are empty because nothing they describe exists yet.

| # | Item | Command | Owner | Pass condition | Result |
|---|------|---------|-------|----------------|--------|
| 1 | Clean baseline dispatch of `ci.yml` on `main` | `gh run view 44805847191 --json status,conclusion,headSha,jobs` | orchestrator | `headSha` starts with `08962944` and the job `ecommerce-e2e (advisory)` conclusion is recorded with its duration (a `deep-quality (advisory)` failure is the known sigra and cloak cause) | Run 44805847191 (workflow_dispatch on `main`), completed, conclusion success, `headSha` `089629441b416103b81c29e716a79bf01aab41e0`. `ecommerce-e2e (advisory)` success in 1320 s (19:50:41 to 20:12:41 UTC). `deep-quality (advisory)` failure (the known cause); the other jobs succeeded and `ops-ui (path-scoped)` was skipped (a dispatch runs no path diff). This is the baseline a red exact-head dispatch is compared with. |
| 2 | Required contexts on the exact PR head, before the squash merge | `gh api --paginate repos/szTheory/scrypath/commits/<head>/check-runs --jq '.check_runs[] \| [.name, .status, .conclusion, .head_sha] \| @tsv'` | orchestrator, before the squash merge | `core`, `package`, `repository-contracts`, `backend`, `ecommerce-mounted` and `ops-ui (path-scoped)` are `completed` and `success` with `head_sha` equal to the PR head (this includes the Cancel-focus line in the required lane and the first hosted run of the table's `git ls-files` scan) | |
| 3 | Exact-head dispatch of `ci.yml` | `gh workflow run ci.yml --ref <branch>`, then `gh run list --workflow ci.yml --branch <branch> --event workflow_dispatch --limit 3 --json databaseId,headSha,status,conclusion,createdAt` and `gh run view <id> --json headSha,status,conclusion,jobs` | orchestrator, immediately after the push and in parallel with row 2 | the run's `headSha` equals `git rev-parse origin/<branch>` and the PR head; the job `ecommerce-e2e (advisory)` conclusion is `success` (read from `jobs[].conclusion`; confirm on this first dispatch that a failed `continue-on-error` job reports `failure` there) with its duration recorded (about 1300 s measured, timeout 30 minutes); the id of the PR's own required run is recorded beside it. On red, compare with row 1 before attributing, fix only failures this phase caused, and record any that `main` also shows. A dispatch skips `ops-ui`, so the PR's own `ops-ui (path-scoped)` run in row 2 is its evidence | |
| 4 | Content landed on `main` | `git fetch origin`, then `git diff --stat <branch>..origin/main`, then `git grep -c 'Control Room' -- . ':!.planning' ':!brand' ':!scrypath_ops/test/support/copy_rules.json'` on merged `main` | orchestrator, after the merge | the diff is empty and the count command prints nothing and exits 1 (the old label appears nowhere outside the exempt paths) | |
| 5 | The post-merge push run on `main` | `gh run list --workflow ci.yml --branch main --event push --limit 3 --json databaseId,headSha,conclusion`, then `gh run view <id> --json jobs` for the merge commit's run | orchestrator, after the merge | `ops-ui (path-scoped)` concluded `success` on the merge commit (the whole-tree scan runs on every push to `main`) | |
| 6 | The demo ExUnit test | `mix test examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/page_controller_test.exs` from the repository root, with `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5` | plan 190-02 executor | the test passes; it asserts the rendered page contains the sentence-case label | Passed on 2026-11-20: 7 tests, 0 failures in 13.7 s, after `mix deps.get` inside `examples/scrypath_ecommerce` (the lock was already consistent, so no lockfile or vendored change resulted). Line 55 asserts the label. The `connection refused` warnings in the log are the page's Meilisearch client finding no server; no test asserts on them. No Docker was used, so there was nothing to clean up. |

## Exact-head dispatch procedure (D-24)

Run by the orchestrator, with no push after the head is verified:

1. Push the branch once. Its last commit is the gate-receipt commit, which changes only files under `.planning/`. Open a non-draft PR.
2. Immediately dispatch `ci.yml` on that branch (row 3). A dispatch runs on the pushed head, so it runs in parallel with the PR's required checks and needs no further push.
3. Check that the dispatch's `headSha` equals the PR head. Record the run id and the id of the PR's own required run.
4. Any later push to the branch makes both the dispatch and the required checks stale, and the dispatch must be repeated on the new head. This includes the ship-note commit that `gsd-ship` adds, which must not be pushed. A stale receipt is a failed gate.
5. Squash-merge only after rows 2 and 3 pass, with a `chore(ops-ui): ...` or `docs(...)` title. Then record rows 1 to 5 in a planning-only commit on `main`, as Phase 189 did.

## Follow-ups (recorded, not done here)

- The Dependabot axe finding `label-content-name-mismatch` on the command hint and the timestamp copy button (outside this phase's scope).
- Aligning the Filterable and Sortable rows to Used for filtering and Used for sorting, deferred with the v1.48 copy lint (advisory specs pin the current strings).
- IN-01: a queue holding only scheduled retries shows Pending on Sync and index while Search health says Retrying. A product decision, not a glossary-rule fix.
- The waiting wording for Meilisearch task counts and the No successful observation recorded. sentence, which the literal rules do not cover.
- Stale area names in `DESIGN.md` (Sync and drift, Saved searches).
- Converting the saved-search delete confirmation from an inline form to a modal with Cancel as the initial focus.
- JavaScript strings and attribute-only text in the table (listed in its `not_covered`), the rendered-text lint, and the palette input focus outline: v1.48 and later.

## What this does not prove

- That the new wording reads well or suits the brand voice. No design pass, rendered review, screenshot comparison, aesthetic approval or independent review happened or is claimed.
- That Cancel receives focus in any browser but the mounted host's Chromium run, or with a real screen reader. The local steps parse `operator.spec.ts` (`playwright test --list`) but do not run the focus line; only the hosted `ecommerce-mounted` lane runs it.
- That the saved-search delete confirmation focuses Cancel first. It is an inline form with its own Escape and Cancel behaviour, pinned as it exists.
- Coverage of JavaScript strings, attribute-only text, states with no named fixture surface or non-English text (the table's `not_covered`).
- That the advisory Playwright specs pass beyond the one exact-head dispatch, or that a red dispatch is caused by this phase when `main` is also red (compare with row 1 first).
- That a path outside the extended `ops-ui` pattern (for example `website/` or a root markdown file) re-introducing a retired phrase is caught before the merge. It is caught on the push to `main`, where `ops-ui-path` always runs.
- That the hosted `ops-ui` job finds `git` and a full checkout the way the local run does. This was read from the workflow, and the first hosted run (row 2) is the observation.

## Gate receipts

See 190-GATE-RECEIPT.md

Result summary: one `mix verify.repository_contracts` and one `mix verify.core --exclude integration --exclude docs_contract` ran once each on commit `f6c78bd243602701857891dd77332d602a392d3e` and both passed (174 tests and 1195 tests plus 5 properties, no failures). An earlier round on `47558725` found one real defect (a shared test stub broke the namespace fence), which was fixed in code, so both gates were rerun on the fixed commit and the earlier results are superseded. The only commits after the tested SHA change files under `.planning/`. Hosted lanes (`ops-ui`, `ecommerce-mounted` with the Cancel-focus line, `backend`, `package`, the advisory dispatch) are not covered by the receipt; they are the Post-ship evidence above.
