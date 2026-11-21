---
phase: 191-cleanup
plan: 01
subsystem: testing
tags: [retired-identity-allowlist, ratchet, favicon, verifier-deletion, deny-list, repository-contracts]

requires:
  - phase: 189-website-reskin
    provides: removal of the two Phase 189 allowlist entries, the 18-value website palette in the deny set
  - phase: 190-wording-without-the-catalog
    provides: ledger rows 9 and 10 in CONTRIBUTING (10 of 12 used)
provides:
  - demo storefront serves the pinned light favicon, guarded by a core-lane byte-equality test
  - the old brand directory's readers (a verifier, its contract test, their wiring) deleted
  - the old brand directory (36 tracked files) and its ops-ui-path regex member deleted
  - retired-identity allowlist at zero entries and zero hits, both ceilings at 0
  - the last three shared website hexes in the deny set with a planted case
affects: [191-02, v1.48 rendered-evidence phase]

plan_head_before: aa403e874082c7ab67a071e6e8d83c381f710ac9
plan_head_after: ea8f540102aa99f8f123b60eae60712585eb3701

actuals:
  tokens: 873   # chars/4 over the 3491 characters of added lines; the deleted lines (old brand directory, two Elixir files) are not counted
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Every ratchet change is a three-file edit in one commit: allowlist file, ALLOWLIST_CEILING, HITS_CEILING"
    - "Readers go before data; the canonical gate runs on the committed readers state"

key-files:
  created: []
  modified:
    - examples/scrypath_ecommerce/priv/static/favicon.svg
    - test/mix/tasks/brand_pin_contract_test.exs
    - examples/scrypath_ecommerce/retired-identity-allowlist.json
    - examples/scrypath_ecommerce/ui-tokens.test.mjs
    - dev/mix/tasks/verify.phase99.ex
    - mix.exs
    - test/release/package_contents_test.exs
    - test/mix/tasks/ui_contrast_contract_test.exs
    - .github/workflows/ci.yml
  deleted:
    - dev/mix/tasks/verify/ui_tokens.ex
    - test/mix/tasks/ui_tokens_contract_test.exs
    - "the old brand directory (36 tracked files)"

key-decisions:
  - "Ran the canonical gate once, on the committed readers state; skipped commits 1 and 3 with reasons and revisit triggers (below)"
  - "Left the slashless literal in brand_pin_contract_test.exs line 859 alone (not the scanned form; see Deviations)"

requirements-completed: [CLEAN-01, CLEAN-02, CLEAN-03, GATE-02]

coverage:
  - id: D1
    description: "Demo storefront favicon is byte-identical to the pinned light favicon and a core-lane test fails when it is not"
    requirement: CLEAN-01
    verification:
      - kind: unit
        ref: "test/mix/tasks/brand_pin_contract_test.exs#the demo storefront favicon is byte-identical to the pinned light favicon"
        status: pass
    human_judgment: false
  - id: D2
    description: "The old brand directory's readers are deleted and the canonical repository contracts pass on that committed state"
    requirement: CLEAN-02
    verification:
      - kind: integration
        ref: "mix verify.repository_contracts on f7515d5c (exit 0, 159 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The old brand directory is gone, the allowlist ends at zero entries and zero hits, and the three shared hexes are denied with a planted case"
    requirement: CLEAN-03
    verification:
      - kind: unit
        ref: "examples/scrypath_ecommerce/ui-tokens.test.mjs (62 of 62 pass at ceilings 0 and 0)"
        status: pass
    human_judgment: false

duration: 17min
completed: 2026-11-20
status: complete
---

# Phase 191 Plan 01: Delete the old identity's last code Summary

**The demo storefront now serves the pinned light favicon, and the old brand directory, its two readers and every allowlist entry are gone, with the retired-identity ratchet walked from 5 entries and 197 hits down to 0 and 0 in three ordered commits.**

## Performance

- **Duration:** about 17 minutes of wall time (the canonical gate took about 6 of them)
- **Tasks:** 3 of 3
- **Files changed:** 47 (9 edited code and test files, 2 deleted code files, 36 deleted old-directory files)

## Commits

| Task | Commit | SHA | What it did |
| ---- | ------ | --- | ----------- |
| 1 | favicon | `9a3b875e0ab8ba164fb7709086bcd63836a5d9e7` | demo favicon byte copy, core-lane equality test, entry and ceilings 5/197 to 4/194 |
| 2 | readers | `f7515d5cf5254f5ef799c29322b8672f7c9d6468` | verifier, contract test and wiring deleted, package test fixed, ceilings 4/194 to 2/178 |
| 3 | data | `ea8f540102aa99f8f123b60eae60712585eb3701` | old brand directory, regex member and last entries deleted, three hexes denied, ceilings 2/178 to 0/0 |

`git rev-list --count aa403e87..HEAD` measured 3 commits, from `plan_head_before` to `plan_head_after` above.

## Number chain (recomputed from the live allowlist file at every step)

| State | Entries | Sum of `max_hits` | `ALLOWLIST_CEILING` | `HITS_CEILING` | `DENY_HEX` | token test calls (`^test("`) | `@min_token_test_calls` |
| ----- | ------- | ----------------- | ------------------- | -------------- | ---------- | ---------------------------- | ----------------------- |
| start (aa403e87) | 5 | 197 | 5 | 197 | 48 | 55 | 55 |
| after commit 1 | 4 | 194 | 4 | 194 | 48 | 55 | 55 |
| after commit 2 | 2 | 178 | 2 | 178 | 48 | 55 | 55 |
| after commit 3 | 0 | 0 | 0 | 0 | 51 | 56 | 56 |

All figures matched the plan's expectations, so no recomputed number differed from the plan. Each step was computed with one `node -e` over `JSON.parse` of the allowlist file, then both constants were set from it; neither constant was ever raised. The node token test went from 61 to 62 passing tests (the one planted case added in commit 3).

## Preflight results (read-only, before the first edit)

1. Allowlist: 5 entries, 197 hits; constants 5 and 197. The Phase 189 tag appeared nowhere. Commit `c2e2fa2b` (Phase 190) is an ancestor of the branch.
2. Reader re-scan (tracked files outside `.planning/` and the old directory): hits only in the verifier, its contract test, `dev/mix/tasks/verify.phase99.ex`, `mix.exs`, the allowlist file and `test/release/package_contents_test.exs`. No new reader.
3. Spelling scan: no hit for the three shared hexes outside `.planning/`, the old directory and `brand/`. The favicon path appears only in `dev/mix/tasks/brand/update.ex` (line 84) and in one comment in `website/scripts/build.mjs` (line 91, plan 191-02 Task 2 rewords it; not edited here). The old directory's name appears in `.github/workflows/ci.yml`, the verifier, the contract test, the allowlist file and one slashless literal in `test/mix/tasks/brand_pin_contract_test.exs` (line 859; see Deviations).
4. `ops-ui-path`: the `grep -qE` pattern in `.github/workflows/ci.yml` (line 375) named the old directory exactly once. Members after commit 3: `scrypath_ops/`, `lib/`, `dev/`, `config/`, `priv/`, `brand/`, `language/`, `fixtures/`, `scripts/ci/`, `test/release/`, `mix\.exs`, `mix\.lock`, the `ci.yml` path, `GLOSSARY\.md`, `DESIGN\.md` and the four `examples/scrypath_ecommerce/` subdirectories.
5. Verifier modules counted the way `package_contents_test.exs` counts them: 55 before commit 2, 54 after, floor 53 (margin 1, floor untouched).
6. CONTRIBUTING ledger (for plan 191-02): 10 rows, `Budget used: 10 of 12.` The "Required-gate budget" paragraph names v1.46 ("The brand and UI milestone (v1.46) may add at most 12 new required gates"). Row text, by gate name: "Offline brand pin" churn cell is "None unless brand assets change (a refresh edits the pin file plus two test-owned constants: the zip hash and the assets digest)"; "Token parity and retired-identity deny-list" deletion cell is "Delete the deny-list half once the allowlist holds no `retire-last` entries; delete the parity half once the token map has no pending rows", churn cell "One token-map row edit per changed theme property; the allowlist only shrinks"; "ScrypathOps re-skin component contract" deletion cell says "in v1.47".

## Deleted-to-surviving assertion map (D-05)

The deleted file `test/mix/tasks/ui_tokens_contract_test.exs` held 15 tests. Names are quoted from it; the two that spelled the old directory's name are paraphrased as "the old brand directory".

| Deleted assertion class (test names) | Disposition | Survivor |
| ------------------------------------ | ----------- | -------- |
| "the old brand directory token document uses DTCG token structures"; "bounded validator accepts the whole CSS-authoritative source and preserves brand values"; "bounded validator rejects duplicate keys, bad types, bad colors and unresolved aliases"; "bounded validator rejects malformed token nodes and unknown token properties"; "bounded validator rejects CSS key, expression, and typed-value drift"; "bounded validator rejects dark-only mapping gaps and CSS value drift"; the seven "review ..." tests (inactive CSS themes and quoted theme lookalikes, one unambiguous live theme name, CSS none as extension metadata, standard shadow layers and inset, negative shadow blur, finite zero and negative dimensions, bounded source bytes JSON nesting token count and alias depth) | dropped, retired-book only (DTCG structure, bounded validator, `token_review`, legacy `ops.*` mirror checks) | live-token truth: the parity, applied-row and built-CSS tests of `ui-tokens.test.mjs` (`live token map parity both directions`, `live applied rows equal pinned brand hex and pending rows differ`, `live built CSS emissions equal source theme blocks`), with `brand/tokens.json` hash-pinned by `brand_pin_contract_test.exs` |
| "the old brand directory documentation separates the warm palette from the CSS-authoritative Ops mirror" | dropped with the directory | none needed |
| "canonical repository contracts pass clean copies and reject each independent token source mutation" | split three ways | CSS-only mutation: the `contrast_child` tests in `ui_contrast_contract_test.exs` plus the planted cases in `ui-tokens.test.mjs`; JSON-only mutation of the mirror: dropped (no mirror remains); clean baseline (`clean_status == 0`): the hosted `repository-contracts` run on the exact PR head, accepted as the replacement |

The baseline decision: the hosted run is the same canonical command on a clean checkout and is already required on every PR. A local baseline would add another nested clone-and-verify run to the slowest required lane for no extra proof. No replacement baseline assertion was added. This map names survivors; it does not prove the deleted coverage was complete.

## Gate-run ledger (GATE-02)

| Commit | Gate run | SHA | Result | Reason and revisit trigger |
| ------ | -------- | --- | ------ | -------------------------- |
| 1 favicon | skipped | n/a | n/a | Its whole effect (asset bytes, one ExUnit test, a three-hit ratchet drop) is covered by the focused checks, and commit 2's run contains it. Revisit if a focused check is red for an unclear reason or a later failure cannot be attributed. No focused check was red. |
| 2 readers | **run** | `f7515d5cf5254f5ef799c29322b8672f7c9d6468` | passed (exit 0; 159 tests, 0 failures; ExUnit 334.6 s, roughly 6 minutes wall) | The only state where a lane that still names a deleted reader can fail, and the point before the data is gone. Run unsandboxed from the first invocation (it writes `FETCH_HEAD`), in the background, from a clean tree, with no tracked edit while it ran. One run, no rerun needed. |
| 3 data | skipped | n/a | n/a | The final-head run in plan 191-02 contains this commit and a failure would be fixed and rerun once either way. Revisit if plan 191-02 is not going to run (then run on `ea8f540102aa99f8f123b60eae60712585eb3701`). |
| final head | owned by plan 191-02 | n/a | n/a | One `mix verify.repository_contracts` plus one `mix verify.core --exclude integration --exclude docs_contract` on the final code head. `mix verify.core` was not run here. |

Note for the CI-efficiency ledger: the local canonical run took about 6 minutes on an otherwise idle machine, against the roughly 15 minutes the plan assumed. The deleted contract test ran three nested canonical runs, so some of the difference may be that, but the plan assumption was not measured before the deletion, so this is a datapoint, not a before-and-after claim. `mix verify.package` was not run locally (`files:` is unchanged; the hosted `package` job covers it).

## Planted failures (no fixtures committed)

- Commit 1: one space appended to the demo favicon in a scratch run made the new test fail with "examples/scrypath_ecommerce/priv/static/favicon.svg must be a byte copy of brand/assets/icon/favicon-light.svg" at `test/mix/tasks/brand_pin_contract_test.exs:871`. The file was restored byte-for-byte (`cmp` clean) before the commit.
- Commit 3: `planted shared website hex fails the deny scan` takes the three values as `DENY_HEX.slice(48, 51)`, asserts the slice has exactly 3 values, plants each in its own stylesheet in a throwaway git tree and asserts the scan reports every file as an unlisted retired value. The test names are not added to `@token_test_names` (it is a planted case, not a live one); `@min_token_test_calls` went from 55 to 56 in the same commit and the wrapper counts 56 literal `test("` lines.
- The kept guards still pass unchanged at 0 entries: the planted retired hex, rgb, directory, stale-entry and prefix-entry cases, and the live deny scan, live allowlist and disjointness tests (62 of 62).

## Deviations from Plan

None to the plan's behavior. Notes:

1. **Slashless literal left in place.** `test/mix/tasks/brand_pin_contract_test.exs` line 859 (the `assert brand_entries(planted) == [...]` expectation in the planted package-files case) spells the old directory's name without the trailing slash. It predates this plan, is not the scanned form (the deny scan and the plan's own verify command match the name with its trailing slash, and both were clean), and the file is not in Task 3's file list, so it was left alone. Plan 191-02 or a later cleanup can build it at runtime like its line 857 does if the stricter reading of D-04 is wanted.
2. **Tooling, not scope.** The worktree sandbox refused compound shell commands that substitute `git` output (`$(git ...)`), so the preflight, the ledger file and the self-check were run as separate plain commands. The plan's `<automated>` blocks were run piece by piece with the same checks, from this worktree's own paths.
3. **Counts differ from the plan text only where the plan said to trust the file.** The node token test had 61 tests (plan text said 59 in RESEARCH, which predates Phases 189 and 190); the chain above uses the live numbers.

No auth gates, no architectural decisions, no auto-fix rules triggered.

## Known Stubs

None. No placeholder values, empty data flows or TODO markers were added.

## Threat Flags

None. This plan deleted code and data and edited tests and one CI path pattern; it added no endpoint, auth path, file access or schema at a trust boundary. Threat register T-191-01 to T-191-05: the deletion order was kept (readers, then data), the reader scan reached one allowlist-reason line after commit 2 and zero after commit 3, every ceiling was recomputed from the file and only lowered, staging used explicit paths only, and the one unsandboxed run was the canonical gate.

## What this does not prove

That the demo tab icon looks right in any browser (byte equality with the pinned light favicon is the whole claim; no preview, capture or `ui:review` ran); that the deleted contract test's coverage was complete (the map records survivors by test name); that the hosted lanes pass (`ops-ui`, which runs because `ci.yml` changed, `ecommerce-mounted`, `backend`, `package`, and the exact-head `repository-contracts` run are post-ship evidence in the phase record); that the final head passes the canonical gate (plan 191-02 owns that run, which also contains commit 3); anything about independent review or aesthetic approval.

## Self-Check: PASSED

- Files present: demo favicon (byte-equal to `brand/assets/icon/favicon-light.svg`), `brand_pin_contract_test.exs`, the allowlist file (`entries: []`), `ui-tokens.test.mjs`, `package_contents_test.exs`, `test/support/ui_tokens.ex`, `ui_tokens_helper_test.exs`.
- Files gone as intended: the ui_tokens verifier, its contract test, the old brand directory (no tracked path, none on disk).
- Commits `9a3b875e`, `f7515d5c` and `ea8f5401` are ancestors of `HEAD`; the working tree was clean after commit 3.
