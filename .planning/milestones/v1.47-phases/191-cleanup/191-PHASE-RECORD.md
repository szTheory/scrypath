# Phase 191 record: cleanup

Written in plan 191-02 (2026-11-20). It holds the decisions, the procedures the orchestrator runs after the push and the merge, the drafted upstream issue (not filed), the follow-ups, and what the evidence does not prove. Detail for each plan is in `191-01-SUMMARY.md` and `191-02-SUMMARY.md`.

## What landed

- **The old identity's last code is gone (plan 191-01, three commits in order).** The demo storefront serves a byte copy of the pinned light favicon, guarded by a core-lane byte-equality test. The two readers of the old brand directory (the `verify.ui_tokens` task and its 15-test contract test, with their wiring in `mix.exs` and `verify.phase99.ex`) were deleted first, with the one consumer the requirement text did not list (`package_contents_test.exs`). The old brand directory (36 tracked files) and its member of the `ops-ui-path` pattern were deleted last. The retired-identity allowlist ends at zero entries and zero hits, both ceilings at 0, and the last three shared website values joined the deny set with a planted case.
- **Number chain, recomputed from the live files at the end of this plan.** Allowlist entries 5, 4, 2, 0 and the sum of `max_hits` 197, 194, 178, 0 across plan 191-01's three commits (`ALLOWLIST_CEILING` and `HITS_CEILING` equal to those sums at every step, now both 0). Node token test calls (`^test("` lines) 55, 55, 55, 56 after plan 191-01, then 72 after commit A (the five live, five planted, five accept tests and the scope test) and 76 after commit B (the live scan, the planted text reference, the planted renamed byte copy and the accept case). `@min_token_test_calls` equals that count after every commit that adds tests (56, 72, 76). The deny set went from 48 to 51 values. The live allowlist file reads `"entries": []`.
- **Five source invariants on ops-authored source only (CLEAN-04, commit A).** In `ui-tokens.test.mjs`: every resolved `font-size` is at least 12 px (resolved through the `--text-ops-*` custom properties of the tree's `app.css`; px and rem literals converted; `inherit` passes; percent, em, calc, clamp, keywords, other units and missing or cyclic custom properties fail closed as unresolvable; a `font:` shorthand other than `font: inherit` fails because it carries a size, in CSS and in `style` attributes); no `text-[` followed by a digit, calc, clamp, length:, min or max; no `uppercase` class token and no `text-transform: uppercase`; no whole-word `infinite`; no `size: :xs` or `size={:xs}` caller. Scope is `scrypath_ops/lib` (`.ex`, `.heex`), `scrypath_ops/assets/js` without any `vendor/` directory, and exactly `app.css`; built CSS, `scrypath_ops/assets/vendor/` and demo host CSS are never scanned. Each invariant has a live test, a planted test whose sub-cases each live in their own throwaway tree and file with a per-file assertion, an accept test, and one scope test.
- **Unthemed-favicon tripwire and consumer scan (CLEAN-05, commit B).** `brand_pin_contract_test.exs` (core lane, reads only `brand/`) fails when the pinned unthemed favicon gains a style element, `fill=`, `fill:`, `currentColor` or `prefers-color-scheme` (case-insensitive), and its message names the five workaround places to remove; a planted doctored copy proves each marker is flagged and the real bytes flag nothing. `ui-tokens.test.mjs` fails when a file outside `brand/`, `.planning/` and the brand updater names the unthemed favicon path or holds the same bytes, under any name; the light favicon served as `favicon.svg` is accepted, the exempt set is exactly those three entries, and lookalike prefixes and sibling paths are planted and reported. Both guards join the path from two pieces at runtime, so neither spells what it forbids and no self-exemption exists.
- **Ledger and token authority (CLEAN-06, commit C).** The `CONTRIBUTING.md` ledger rows were edited by gate name: the token row says the deny-list and the directory tripwire are permanent and the parity half stays while `app.css` is a hand-kept projection of `brand/tokens.json`, the single token authority, and its churn cell carries the source-not-rendered sentence; the budget sentence names v1.47 and carries the cap of 12 forward; the component-contract row says v1.48; the offline brand pin row names the favicon tripwire. The row count stayed at 10 and the line reads `Budget used: 10 of 12.` `DESIGN-TOKENS.md` names `brand/tokens.json` as the single token authority, and its Typography section says the invariants read source declarations, not rendered size.

## Resolved notes

The eight open contradictions of `191-CONTEXT.md`, as resolved (one line each), plus two notes from execution.

1. CLEAN-02 omitted a consumer: `package_contents_test.exs` pinned the deleted verifier by name and counted modules against a floor of 53. It was fixed in the readers commit (the identity list removed, the floor kept; 55 modules before, 54 after).
2. CLEAN-05's exemption list versus the guard's own source: no self-exemption. The needle is built at runtime in both guard files, and the exemption set is not widened.
3. The budget count: the live row count was read (10) and kept; `Budget used` equals it. No gate was added.
4. The ledger and `DESIGN-TOKENS.md` work lives in plan 191-02, after the allowlist-emptying commit, so the reword could say so truthfully.
5. The "favicon row" is the Offline brand pin row, addressed by gate name.
6. The number chain was recomputed from the live files after Phases 189 and 190 landed (5 and 197 at the start, not the older figures).
7. The stale roll-forward text in `ROLLING-ROADMAP.md` ("mix alias", "8 of 12") was left alone, as the context file directs.
8. The interim website assertion that the three shared values are absent builds them from two pieces at runtime, so it is not a deny hit and needed no edit.
9. Extra consumer found by the new scan: one comment in `website/scripts/build.mjs` spelled the unthemed path. It was reworded (comment text only) in commit B so the scan passes without widening any exemption.
10. The token row's "source declarations, not rendered size" sentence was put in commit C with the rest of that row's reword, so the cell is edited once. The `DESIGN-TOKENS.md` typography note stayed in commit A with the tests it describes.

## Decisions recorded

**Gate-run budget (GATE-02).** Six code commits (1, 2, 3 in plan 191-01; A, B, C in plan 191-02). Canonical runs happened only where they add information.

| Commit | Gate run | Reason | Revisit when |
|--------|----------|--------|--------------|
| 1 favicon | skipped | Covered by focused checks; commit 2's run contains it | a focused check was red for an unclear reason (none was) |
| 2 readers | `mix verify.repository_contracts`, passed on `f7515d5cf5254f5ef799c29322b8672f7c9d6468` | The only state where a lane that still names a deleted reader can fail, and the point before the data is gone | n/a (run) |
| 3 data | skipped | The final-head run contains it | plan 191-02 does not run |
| A invariants | skipped | The final-head run contains it; the Node token test, the wrapper test (floor and names), the workflow wiring test and format passed before the commit | a failure in the final-head run cannot be attributed to A, B or C |
| B tripwire and scan | skipped | The final-head run contains it; the Node token test, the brand pin, wrapper and website contract tests and format passed before the commit | same |
| C ledger | `mix verify.repository_contracts` and `mix verify.core --exclude integration --exclude docs_contract`, both passed on `ce250655b7e90e737f3a922287114c402c8a3b9d` | The final code head; the receipt names this SHA | n/a (run) |

**The hosted exact-head run replaces the deleted clean-clone baseline.** The deleted contract test was the only `clean_status == 0` assertion. The hosted `repository-contracts` run on the exact PR head is the same canonical command on a clean checkout and is already required on every PR, so no local baseline was added (it would have added another nested clone-and-verify run to the slowest required lane). The deleted-to-surviving assertion map is in `191-01-SUMMARY.md`; it names survivors by test name and does not claim the deleted coverage was complete.

**No new required gate, no branch-protection change, no Hex release.** CLEAN-04 and CLEAN-05 ride the existing token and brand-pin rows, CLEAN-01 rides `core`, and the budget stays at the live row count (10 of 12). The squash title is `chore(...)` or `docs(...)`, never `feat` or `fix`, because no library change ships.

**The `font:` shorthand is rejected, not only named.** Today only `font: inherit` appears; any other shorthand carries a size that a `font-size` scan cannot see, so it fails in CSS and in `style` attributes. A comment marker inside a string is treated as a comment start, which can only hide a real violation on the same line; this is stated in the test header.

**No design pass.** There is no preview refresh, no `npm run ui:preflight`, no `npm run ui:review`, no capture. The demo tab icon change is proved by byte equality only. Nothing in this phase claims aesthetic or independent-review approval.

## Upstream favicon issue (D-14): DRAFT ONLY, not filed

Filing this in `szTheory/scrypath-brand` needs the maintainer's account and never blocks the phase. No `gh issue create` was run, and nothing was sent upstream. The draft is copied from `191-RESEARCH.md` ("Upstream defect report"). The Phase 189 record carries an earlier adaptation of the same issue; this one is the current text.

> **`assets/icon/favicon.svg` renders black in every theme**
>
> The file (891 bytes) draws its paths with `class="g"` and `class="l"` but contains no `<style>` block and no `fill`, so it renders black in light and dark. `BRAND.md` (the favicon line, about 225) says it "follows the device's light or dark setting: in dark mode its slash is Orchid", and `assets/README.md` says it "swaps its letter and slash with the device theme".
>
> Suggested fix: add a `<style>` with a `prefers-color-scheme: dark` rule (Orchid slash, Pale Ink letters), or ship the file with explicit fills; add a test that renders it under both schemes.
>
> Consumer impact: downstream projects currently serve `favicon-light.svg` under the name `favicon.svg` as a workaround and guard against using the unthemed file (a tripwire fails when the pinned file gains a `<style` or `fill`, so a refresh that picks up the fix prompts removing the workarounds).

## Post-ship evidence

These items are **deferred-to-ship**. They cannot exist before the PR is pushed and merged, so they are not gaps in the evidence and they do not route the verifier to a person: each has a command, an owner and a pass condition. The orchestrator fills the Result column in a `.planning`-only commit after the merge, never by pushing to the PR branch (a push to the PR branch would cost another full CI run and make the exact-head evidence stale).

| # | Item | Command | Owner | Pass condition | Result |
|---|------|---------|-------|----------------|--------|
| 1 | Required contexts on the exact PR head, before the squash merge | `gh api --paginate repos/szTheory/scrypath/commits/<head>/check-runs --jq '.check_runs[] \| [.name, .status, .conclusion, .head_sha] \| @tsv'` | orchestrator, before the squash merge | `core`, `package`, `repository-contracts`, `backend`, `ecommerce-mounted` and `ops-ui (path-scoped)` are `completed` and `success` with `head_sha` equal to the PR head; `repository-contracts` is the accepted replacement for the deleted clean-clone assertion, and `ops-ui` runs because `ci.yml` changed in plan 191-01 | |
| 2 | Content landed on `main` | `git fetch origin`, then `git diff --stat <branch>..origin/main`, then on merged `main` `OLD="brand""book/"` and `git ls-files -- "$OLD"`, and `grep -c '"entries": \[\]' examples/scrypath_ecommerce/retired-identity-allowlist.json` | orchestrator, after the merge | the diff is empty, the `git ls-files` command prints nothing, and the allowlist file has `"entries": []` | |
| 3 | The post-merge push run on `main` | `gh run list --workflow ci.yml --branch main --event push --limit 3 --json databaseId,headSha,conclusion`, then `gh run view <id> --json jobs` for the merge commit's run | orchestrator, after the merge | the required jobs concluded `success` on the merge commit, including `ops-ui (path-scoped)` | |
| 4 | `repository-contracts` duration before and after the deleted contract test's three nested canonical runs left | `gh run view <id> --json jobs` on the PR head's `repository-contracts` job, compared with the 858 to 911 s measured earlier in `CI-EFFICIENCY.md` | orchestrator, after the PR head's run completes | the hosted duration is read and written into `CI-EFFICIENCY.md` finding 13 with no claim beyond what the hosted runs show | |
| 5 | The website workflow on the PR head and after the merge | `gh api --paginate repos/szTheory/scrypath/commits/<head>/check-runs --jq '.check_runs[] \| [.name, .status, .conclusion, .head_sha] \| @tsv'` for `build-and-check` on the PR head; then `gh run list --workflow website.yml --branch main --limit 5 --json databaseId,headSha,status,conclusion,event` and `gh run view <id> --log` for the merge commit's run | orchestrator, before the squash merge for the first half and after it for the second | `build-and-check` is `completed` and `success` with `head_sha` equal to the PR head; after the merge `deploy` is `success` and its smoke step shows `ok` for the ui font, both lockups, the social card and `favicon.ico` under `/scrypath/`. This PR edits `mix.exs` (plan 191-01) and `website/scripts/build.mjs` (plan 191-02 Task 2), both inside the `website.yml` path filters (`CI-EFFICIENCY.md` findings 10 and 11), so the redeploy is expected and serves byte-identical site output, because the website source, brand assets and build inputs are unchanged apart from one comment | |

## Follow-ups (recorded, not done here)

- The maintainer files the upstream favicon issue from the draft above.
- The browser computed-style spec stays on the advisory lane; revisit only if a regression that only a browser spec would catch reaches `main`.
- The palette input focus-outline defect (v1.49 screens work).
- Stale roll-forward text in `ROLLING-ROADMAP.md` (its Phase 191 row says "mix alias" and "8 of 12").
- The preview refresh and `npm run ui:review` as the first rendered-evidence step of v1.48.
- The README-header guard and the hex.pm URL switch belong to the next release PR.
- Optional cleanup: the slashless literal in `test/mix/tasks/brand_pin_contract_test.exs` (the planted package-files expectation, near line 859) still spells the old directory's name without its trailing slash. It is not the scanned form, so every guard passes; build it at runtime like its neighbouring line if the stricter reading is ever wanted.

## What this does not prove

Source declarations, not rendered size: the 12 px floor, `uppercase`, `infinite`, arbitrary-size and `size: :xs` checks read ops-authored source, so a daisyUI default or a variant that emits a smaller size (the `btn-xs` class, 11 px) is only caught by the `size: :xs` caller check and by the browser spec on the advisory lane. Computed size stays browser-only, and demo host CSS is outside "ops-authored source". Not read either: camelCase `style.fontSize` assignments in JavaScript, a font shorthand inside a JavaScript string, and prose in strings or docstrings (only comments are stripped).

The demo favicon check proves byte equality with the pinned light favicon, not how any browser renders it. The tripwire proves the pinned `favicon.svg` is still the unthemed one and says nothing about whether upstream fixed it; it only fires when the file changes. The consumer scan proves no tracked or untracked-not-ignored file outside the exempt paths references or copies the unthemed file, not what the built website serves (the Phase 189 static contract owns that output). The assertion map records survivors by test name; it does not prove the deleted checks' coverage was complete. The local receipt proves the two long gates passed on one commit; the hosted lanes (`ops-ui`, `ecommerce-mounted`, `backend`, `package` and the exact-head `repository-contracts` run) are the Post-ship evidence above. None of this is independent review, aesthetic approval, rendered-quality evidence, other-browser evidence or a real screen reader pass. No preview, capture or `ui:review` ran.

## Gate receipts

See 191-GATE-RECEIPT.md

Result summary: one `mix verify.repository_contracts` (159 tests, 0 failures) and one `mix verify.core --exclude integration --exclude docs_contract` (5 properties, 1183 tests, 0 failures) ran once each on commit `ce250655b7e90e737f3a922287114c402c8a3b9d`, the last code commit, and both passed. The only commits after the tested SHA change files under `.planning/`. The earlier readers-commit run on `f7515d5cf5254f5ef799c29322b8672f7c9d6468` (plan 191-01) is recorded in `191-01-SUMMARY.md` and is not part of the receipt. Hosted lanes are not covered by the receipt.
