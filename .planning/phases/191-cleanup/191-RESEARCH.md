# Phase 191: Cleanup - Research

**Researched:** 2026-11-20
**Domain:** Deleting the retired identity's last code (a verifier, its contract test, a brand book directory, a CI regex entry), emptying a shrink-only ratchet, and adding cheap static invariants to one existing Node token test. Test, tooling and asset work only; the one visible change is the demo tab icon.
**Confidence:** HIGH for in-repo facts (each was read or run this session on the tree below); MEDIUM for anything that depends on Phases 188.1, 189 and 190, which had not landed.

Legend: **V** = verified this session by reading the file or running the command. **U** = inferred, not proven. `.planning/` files may name the retired directory (it is exempt from the scan); nothing tracked outside `.planning/` may (CONTEXT D-04).

**Tree state at research time:** local `main` at `2668b2f9` (docs-only commits on top of `85ca0cd1`), `origin/main` at `e6fc151b`. Phases 188.1, 189 and 190 have NOT landed. So every number below is the pre-189 state (allowlist 7 entries / 201 hits), and the expected post-189 start (5 / 197) is derived by arithmetic and cross-checked with a dry run, not observed. **The first task of plan 191-01 is to re-run the verification table below on merged `main`.** Two docs-only commits landed while this note was being written (SITE-06 added to Phase 189); they do not touch any file cited here.

<user_constraints>
## User Constraints (from CONTEXT.md)

Locked decisions are D-01 to D-23 in [191-CONTEXT.md](191-CONTEXT.md). In one line each: three commits (favicon, readers, data) with allowlist and ceilings in lockstep; three shared hexes join the deny set in the directory-deleting commit; keep the deny-list, `RETIRED_DIR`, `retire-last` and the (empty) allowlist file; docs never spell the retired path; hosted exact-head run replaces the lost clean-clone baseline, class map recorded; commit 2 also fixes `package_contents_test.exs`; CLEAN-04 invariants on ops-authored source only, floor raise in the same commit; CLEAN-05 tripwire plus byte-and-path scan with runtime-built needle; upstream issue drafted, not filed; CLEAN-06 reword by gate name; `brand/tokens.json` named authority; commit then gate per commit; two plans; executable assertions only; no preview refresh; non-draft PR squashed on green with a `chore` or `docs` title.

Out of scope: promoting a browser spec to a required lane, the palette focus-outline defect, preview refresh, catalog work, Hex release, filing the upstream issue.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CLEAN-01 | Root `core` test: demo favicon byte-identical to `brand/assets/icon/favicon-light.svg`; allowlist entry removed | Current demo favicon is 981 B and differs from the 901 B light favicon (V). Controller test compares served file to priv copy only (V). Dry run: swapping bytes keeps the token test green at 6/198 (V). |
| CLEAN-02 | Readers gone; `verify.repository_contracts` green on committed state | Complete reader inventory below (V); one reader the requirement does not list (`package_contents_test.exs`). |
| CLEAN-03 | Directory, regex entry, allowlist entries and ceilings together; three shared hexes join the deny set; kept guards | Dry run of all three commits green (V). The three hexes have no hit outside the directory and the website (V). |
| CLEAN-04 | Source-only invariants with planted and accept cases; floor raise; docs | All four invariants pass on today's source (V). Trap list re-verified (V). |
| CLEAN-05 | Favicon tripwire plus path-and-byte scan | No file outside `brand/` matches by bytes; one legitimate text reference outside `brand/` (V). |
| CLEAN-06 | Ledger reworded; `brand/tokens.json` named | Current row text, line numbers and the wiring-test constraints (V). |
| GATE-02 | Commit-then-gate, one run per SHA, escalated first run | Snapshot mechanics re-read (V). |
</phase_requirements>

## Summary

The prep and gap-pass decisions hold against the current tree. The deletion chain works exactly as written: a scratch copy of the repository with each commit applied in order kept the token test green at every step (7/201 to 6/198 to 4/182 to 2/4 on today's tree, which has the two `p189` entries; the post-189 chain 4/194, 2/178, 0/0 follows by subtracting 2 entries and 4 hits). Three things the requirement text does not say and a plan must handle:

1. `test/release/package_contents_test.exs` still names `Mix.Tasks.Verify.UiTokens` (`later_hidden`, about line 251) and counts verifier modules against a floor of 53 (55 today). Deleting the task breaks the identity assertion and leaves a margin of 1.
2. The CLEAN-05 guard and its test would contain the very path they forbid unless the needle is built at runtime; the requirement's exemption list does not cover the guard's own source.
3. Phase 189's interim "the three shared hexes are absent" website assertion, if it spells them literally, becomes a deny hit when they join the deny set in commit 3 and blocks the 0/0 end state.

Everything else is bookkeeping: lockstep ceilings, a wiring-test-safe ledger reword by gate name, and a floor raise committed with the tests it counts. The deleted `ui_tokens_contract_test.exs` ran three nested canonical `verify.repository_contracts` runs; removing it is probably a CI time saving worth recording (U until measured).

## Re-verification against current main (flag drift)

Checked 2026-11-20. "Cited" is the number in the prep or gap-pass note; drift is flagged.

| Claim | Cited in | Now | Status |
|-------|----------|-----|--------|
| Allowlist 7 entries, 201 hits; `ALLOWLIST_CEILING` 7, `HITS_CEILING` 201 | D, H verdict | 7 entries: 2+2 (`p189`), 177 (retired directory prefix), 1 (`ui_tokens.ex`), 15 (`ui_tokens_contract_test.exs`), 1 (`ci.yml`), 3 (demo favicon) = 201. `ui-tokens.test.mjs:68` (`= 7`) and `:72` (`= 201`) (V) | Holds (pre-189 state) |
| After Phase 189: 5 entries, 197 hits | H-6 | Not observable yet; follows by removing the two `p189` entries (-2, -4) | Derived (U until 189 lands) |
| Chain 6/198, 4/182, 2/4 (prep D) | D | Dry run on a scratch `git archive` copy with the two `p189` entries present: each commit step green (59 of 59 tests) at 6/198, 4/182, 2/4 (V) | Holds for a pre-189 tree; superseded for 191 |
| Final 0/0 | CLEAN-03 | With the two `p189` entries removed from the allowlist but website files untouched, the live scan test fails (website SVGs still hold retired values), as expected; so 0/0 is only reachable after 189's asset swap (V) | Holds, depends on 189 |
| `@min_token_test_calls 53` and 53 `test("...",` calls; 59 node tests | H verdict | `ui_contrast_contract_test.exs:104` is `@min_token_test_calls 53`; `grep -c '^test("'` gives 53; `node --test` reports 59 pass, 0 fail, 1.6 s (V) | Holds |
| `RETIRED_DIR` at `ui-tokens.test.mjs:808`, `ALLOWLIST_TAGS` at `:793` | H-10, E nit 20 | `:808` and `:793` (V) | Holds |
| Exempt set: `.planning/`, `brand/BRAND.md`, `brand/brand.json`, the allowlist file | H-10 | `:810` (`EXEMPT_PREFIXES`), `:812` (`EXEMPT_PATHS`) (V) | Holds (lines `:810-812`) |
| Checker tolerates an empty allowlist | H-6 | `checkAllowlist` at `:1006`; entry-count check at `:1011-1015` uses `Number.isFinite`; hits check at `:1066-1072`; stale-entry message at `:1056` (V). Prep and H cite `:1010-1017`, `:1062-1073`, `:1050` | Holds; lines drifted by 4 to 6 |
| `mix.exs:100` is a `preferred_envs` entry | H-13 | `mix.exs:100` is `"verify.ui_tokens": :test,` (V) | Holds |
| `verify.phase99.ex:13` lists the contract test | D, H-13 | `verify.phase99.ex:13` (V) | Holds |
| `ci.yml:367` holds the retired directory in the `ops-ui-path` regex | D | `ci.yml:357` job start, regex on `:367`; the only `brandbook` hit in the file (V) | Holds. **Phase 188.1 edits this area; re-read after rebase** |
| `workflow_wiring_test.exs:1297` checks the regex names `brand/` | D | The `for dir <- ~w(scrypath_ops/ lib/ dev/ brand/ ...)` loop is at about `:1297` (V) | Holds |
| `verify.phase99_test.exs:26-34` does not name the contract test | D, H-13 | Lines 26-34 name phase99, phase111, `verify.phase99_test`, `ui_contrast_contract_test`, `workflow_wiring_test`; not `ui_tokens_contract_test` (V) | Holds |
| Ledger: `workflow_wiring_test.exs:1351-1417`; `@phase_186_gate_files` `:620-626` | H-11 | `@ledger_header` at `:613`; `@phase_186_gate_files` `:620-626`; `budget_ledger_errors/1` begins about `:1351` (V) | Holds |
| `ui_contrast_contract_test.exs:346` is `copy_repository/0`'s `git clone` | H-12 | Function at `:336`, clone call at `:346`; it overwrites five working-tree files (itself, `ui_literal_contract_test.exs`, `verify.phase99.ex`, `contrast-checker.mjs`, `contrast-pairs.mjs`) (V) | Holds |
| `ui_tokens_contract_test.exs:456` is the clean baseline; `:795` the clone | H-12 | `:456-457` (`clean_status == 0`), clone at `:795` (V) | Holds |
| `ui_tokens.ex` 898 lines; contract test 836 lines; retired directory 36 files, 384 KB | D | 898, 836, 36 files, 384 KB (V) | Holds |
| `CONTRIBUTING.md:247` budget sentence names v1.46; `:251` pin row churn; `:252` token row; `:258` component-contract row says v1.47; `:260` budget line | H-11 | Same line numbers today (V) | Holds now; **will shift** when Phases 189 and 190 add or edit rows. Address rows by gate name |
| `Budget used: 8 of 12` | CONTRIBUTING, GATE-02 | `CONTRIBUTING.md:260` today; Phase 189 takes row 9 | Drift expected; plan reads the live count |
| Favicon: demo copy 981 B, 3 hits; pinned `favicon.svg` 891 B, sha256 `16a86401...`; light favicon 901 B | H-14, H-15 | Same sizes and hash; demo favicon differs from the light one (`cmp`: char 41) (V) | Holds |
| No tracked or untracked-not-ignored file outside `brand/` is byte-identical to the pinned `favicon.svg` | H-15 | Hash scan over `git ls-files --cached --others --exclude-standard`: only `brand/assets/icon/favicon.svg` matches (V) | Holds |
| Text references to `icon/favicon.svg` outside `brand/`: only the updater | H-15 | `dev/mix/tasks/brand/update.ex:84` (V). Others are inside `brand/` (`BRAND.md:1017`, `assets/README.md:26,93`, `brand.json:1551`, `brand.pin.json:225-226`) | Holds |
| Workarounds to name in the tripwire message | H-15 | `mix.exs:294-298` (comment and `put_if_file(:favicon, ...)`); **`test/release/package_metadata_test.exs:147,168,434`** (cited as `package_metadata_test.exs:411,433`, drifted and in `test/release/`); `scrypath_ops/test/scrypath_ops_web/reskin_static_contract_test.exs:56-57`; demo favicon; `docs/releasing.md:29` (V) | **Drift** (package_metadata lines) |
| 12 px floor: 90 `font-size` lines in `app.css`; `--text-ops-xs` and `-sm` `0.75rem` at `:250-251`, body `0.875rem` at `:252`; one literal `0.875rem` at `:1093`; `inherit` at `:2200,:2231`; `font: inherit` at `:418,2154,2280` | H-9 | All as cited (V). No `%`, `em`, `calc`, `clamp` font-size in source | Holds |
| Zero `text-[`, `uppercase`, `text-transform`, `infinite` in `scrypath_ops/lib`, `assets/js`, `app.css`; `:infinity` atoms at `result_ui.ex:50-51`, `search_live.ex:1244-1245` | H-9 | All as cited (V) | Holds |
| Built CSS: 3 `infinite`, `font-size: 75%` and `80%`; `assets/vendor/daisyui.js`: `infinite` | H-9 | 3, 1 each of 75% and 80%, and 2 `infinite` in `daisyui.js` (V) | Holds |
| `ops_ui.ex:1854` emits `btn-xs` for `size: :xs`; zero callers | D, H-9 | `size == :xs && "btn-xs"` at `ops_ui.ex:1854`; `attr(:size, ... values: [:xs, :sm, :md])` at `:187, :230, :274, :309`; no `size: :xs` or `size={:xs}` caller in `scrypath_ops/lib` (V) | Holds. The attr `values:` lines and the branch are NOT callers |
| `sync_drift_live.ex`, copy sites | H-1 to H-8 | Phase 190 scope, not checked | n/a |
| Shared hexes in the retired directory: `d08e54` 4, `0c0f14` 10, `9aa4b6` 1 hits | E finding 1 | By line: `d08e54` in 3 directory files plus 2 website files; `0c0f14` in 7 directory files (4 lines in `tokens.css`/`tokens.json`) plus 1 website file; `9aa4b6` in 1 directory file plus 1 website file. No other tracked file holds them, and no `rgb(...)` form of their triplets exists outside the directory (V) | Holds (E counts occurrences, this counts lines) |
| `brand/tokens.json` and `brand/brand.json` hold none of the three hexes | E | No match (V) | Holds; the "deny set and new set are disjoint" test stays green |
| `DESIGN-TOKENS.md` names `brand/tokens.json` | prep D item 3 | Line 31 already says the palette is the pinned brand book "with its tokens in `brand/tokens.json`" (V). Nothing yet calls it the single authority | Holds; add one sentence |
| Docs referencing `verify.ui_tokens`, the retired directory, or `ui_tokens_contract_test` outside `.planning/` and the readers | D ("Not referenced") | `git grep` over tracked files: only `ci.yml:367`, `ui_tokens.ex:27`, the allowlist file, `brand_pin_contract_test.exs:859` (builds the name), `ui_tokens_contract_test.exs`, `mix.exs:100`, `verify.phase99.ex:13` (V) | Holds, plus the new consumer below |
| **New:** `test/release/package_contents_test.exs` pins `later_hidden = [Mix.Tasks.Verify.UiTokens]` and `length(verifiers) >= 53` | not in any note | `package_contents_test.exs` about `:210-253`; 55 verifier modules counted by the test's own collector (V). The "tooling boundary" tests pass today (V) | **New finding** (CONTEXT D-06) |
| `.dockerignore` does not exclude `brand/` | H-14 | Confirmed (V) | Holds |

## Tasks for plan 191-01 (unverified items and carried verification)

These were not provable before Phases 188.1, 189 and 190 land. Run them first, as one cheap pass, before any edit.

1. **Rebase and re-derive.** Start from fresh `origin/main` after Phase 190 merges. Read the live allowlist and compute the chain (entries and hits per commit from the entries actually present). Confirm `ALLOWLIST_CEILING` and `HITS_CEILING` equal the live sums before editing. Expected 5 / 197 if 189 removed both `p189` entries.
2. **Reader re-scan.** `git grep -n 'ui_tokens\|UiTokens\|verify\.ui_tokens' -- . ':!.planning'` and a scan for the retired directory. Expect only the files listed in the table above. Any new hit is a new reader and joins commit 2.
3. **Spellings introduced by 189 and 190.** Grep the website static contract, `build.mjs`, `check.mjs` and Phase 190 files for the literal `d08e54`, `0c0f14`, `9aa4b6` (any case, also quoted bare forms and `0x`/`%23` forms) and for the path `icon/favicon.svg`. Each literal is a deny hit (hexes) or a CLEAN-05 hit (path) the moment the guard lands. Neutralize by runtime concatenation, or delete the interim assertion the deny set now owns. Also confirm the interim "absent until Phase 191" assertion exists and decide per CONTEXT D-02.
4. **CI file edits after 188.1 and 190.** Re-read `.github/workflows/ci.yml` around the `ops-ui-path` regex (and the `ecommerce-path` classifier) and `workflow_wiring_test.exs` for how they cover that regex; the retired directory must be the only token removed from the regex.
5. **Package-contents consumer.** Run `MIX_ENV=test mix test test/release/package_contents_test.exs` before and after commit 2. After the deletion the collector should count 54 modules against the floor of 53; confirm, and do not lower the floor.
6. **Gate budget and ledger shape.** Read the live ledger (row count, the exact row text for the token, offline-pin and component-contract rows) before 191-02 so the reword is by gate name and `Budget used` is the live count.
7. **Dry run.** Before editing, do the throwaway chain in a scratch `git archive` copy (initialise git inside it, apply each commit's deletions and the allowlist and ceiling edits, run the token test) to see the numbers. Keep the script out of the repository.
8. **Demo project test, if the environment allows.** `examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/page_controller_test.exs` compares the served `/favicon.svg` to the priv copy; it should be unaffected by the byte swap. It is in no required lane and may need Postgres; if it cannot run locally, record that and rely on the byte-equality root test (the controller test only proves the file is served, independent of its content).
9. **`mix verify.package` after commit 2** (U on whether it is needed: `mix.exs` changes, but `files:` does not). About 115 s; cheap insurance, and the hosted `package` job covers it either way.

## Common pitfalls

1. **Deleting the directory before the readers.** Breaks `repository-contracts` (186 verifier finding). The three-commit order is the fix.
2. **Entry and ceiling out of step.** Each of entry-count, `max_hits`, `HITS_CEILING` fails independently and with a message that names the number to use. Edit the allowlist file and both constants in the same commit.
3. **The `ci.yml` entry goes stale the moment the regex is edited.** Same commit.
4. **Adding the three hexes early.** Raises the directory prefix entry's counted hits above `max_hits` and the ceiling is shrink-only. Commit 3 only (D-02).
5. **A literal retired value in a guard or a test.** `"d08e54"` (quoted bare) matches the deny pattern; so does `#d08e54`. Build at runtime, or delete the assertion. The same applies to the retired directory name (D-04) and to the favicon path (D-13).
6. **Docs that spell the retired directory.** The final commit has zero allowlist entries, so CONTRIBUTING, `DESIGN-TOKENS.md`, `docs/`, code comments and new test names must say "the retired brand book directory".
7. **Snapshot gates read HEAD.** `ui_contrast_contract_test.exs` clones committed HEAD and overwrites only five working-tree files. An uncommitted floor raise runs against HEAD's older token test and the mutation tests pass for the wrong reason. Commit tests and the floor raise together, then run the gate. The first `mix verify.repository_contracts` run needs the escalated permission up front (it writes `FETCH_HEAD` in the worktree; a sandbox failure is not RED).
8. **Wiring-test ledger traps.** A pipe inside a cell breaks the five-cell split; `Budget used: N of 12.` must equal the row count; the first backticked path in "Enforced by" must exist; five rows are mandatory by enforcing file (`brand_pin_contract_test.exs`, `ui-tokens.test.mjs`, `workflow_wiring_test.exs`, `dependency_boundary_contract_test.exs`, `ui_state_pairs.test.cjs`), so the token row cannot be removed by rewording. `CONTRIBUTING.md` is an ExDoc extra: no `Mix.Tasks.Verify` module names, and `mix docs --warnings-as-errors` stays clean.
9. **Floor bookkeeping.** New Node tests count only when written as `test("...",` at line start. `@token_test_names` should gain each new live test so a rename cannot pass on count alone. The floor is a lower bound the wrapper asserts (`length(names) >= floor`); raise it by the number added. CLEAN-04 and CLEAN-05 each add tests, so each commit that adds `test("...",` calls raises the floor in that commit.
10. **Static-invariant false positives (CONTEXT D-09).** Built CSS and vendor files; `:infinity` atoms; comment prose; `text-[var(--color)]`; `values: [:xs, :sm, :md]` attribute declarations and the `size == :xs` branch; `font: inherit` and `font-size: inherit`. The resolver must read `font-size` through `var(--text-*)` chains. A `font:` shorthand other than `inherit` carries a size too and is not resolved by a `font-size` scan; none exists today (V), so either reject it or name the hole in the docs line.
11. **`size: :xs` and the browser hole.** The static check catches callers, not another path to a small size; computed size is browser-only (the advisory-lane spec `ops_reskin_contract.spec.ts`, P-02). The docs say so (CONTEXT D-11).
12. **`package_contents_test.exs` floor margin.** 55 verifier modules now, 54 after deleting the task, floor 53. Do not delete or hide another verifier in this phase without checking it.
13. **Contrast child tests need a deps and `_build` copy.** The wrapper copies `deps` and `_build` into the clone; running them locally takes minutes. Use `--exclude contrast_child` for the cheap pass and commit before the child runs.
14. **Rebase hazards.** Phases 189 and 190 both edit `ALLOWLIST_CEILING`, `HITS_CEILING`, the floor, the allowlist file and the CONTRIBUTING ledger; 190 may also edit the `ops-ui-path` regex. Sequential PRs make that safe, but 191 recomputes everything from merged `main`.
15. **Pipes and the retired directory inside planning artifacts are fine, inside PLAN files they trip a different guard.** `test/scrypath/no_human_gates_contract_test.exs` scans incomplete `.planning/phases/**/*-PLAN.md` for the strings `<human-check>`, `checkpoint:human-verify` and `verification: backstop`, and fails any `*-VERIFICATION.md` with status `human_needed`. Do not quote those markers in a PLAN.
16. **`ops-ui` will run on commit 3** (it edits `ci.yml`), about 450 s. Expected. With the Phase 188.1 classifier a workflow-file change always runs the browser lanes too.

## Code examples (sketches, not the implementation)

Resolve a `font-size` value in ops source (Node):

```js
// px or rem literal -> px; var(--x) -> resolve through the custom-property map; reject the rest.
function fontSizePx(value, props, depth = 0) {
  const v = value.trim();
  if (v === "inherit") return Infinity; // passes the floor
  if (/%|\bem\b|calc\(|clamp\(/.test(v)) throw new Error(`unresolvable font-size ${v}`); // fail closed
  const ref = v.match(/^var\(\s*(--[\w-]+)\s*\)$/);
  if (ref) return depth > 8 ? NaN : fontSizePx(props.get(ref[1]) ?? "", props, depth + 1);
  const n = v.match(/^(\d*\.?\d+)(px|rem)$/);
  return n ? Number(n[1]) * (n[2] === "rem" ? 16 : 1) : NaN; // NaN fails the floor
}
```

Needle built at runtime so the guard never contains the path it forbids (both the ExUnit tripwire and the Node scan):

```js
const FAVICON_REFERENCE = ["icon/", "favicon.svg"].join(""); // never written out whole in this file
```

Planted and accept cases use `makeTree` (a throwaway git tree) and the same `listRepoFiles` and exempt-path logic as the live scan; the accept case writes the light favicon's bytes under the name `favicon.svg`.

## Validation architecture

Every row is an executable check. Cheapest first.

| Success criterion | Check | Lane and cost |
|-------------------|-------|---------------|
| SC1 (CLEAN-01): demo favicon byte-identical to the pinned light favicon; its allowlist entry gone | The new root ExUnit byte-equality test; `node --test examples/scrypath_ecommerce/ui-tokens.test.mjs` (allowlist and ceilings) | `core` (full root suite); about 2 s locally. Planted failure: temporarily change one byte of the demo file in a scratch run and see the test fail (record the result, no committed fixture) |
| SC2 (CLEAN-02): readers gone, no reader scan hit, `repository-contracts` passes on the committed state | `git grep` reader scan (task 2 above); `MIX_ENV=test mix test test/release/package_contents_test.exs test/mix/tasks/verify.phase99_test.exs test/mix/tasks/workflow_wiring_test.exs`; `mix compile --warnings-as-errors`; `mix format --check-formatted`; then `mix verify.repository_contracts` on the committed state (background, about 15 min, escalated first run); then hosted `repository-contracts` on the exact head | Local focused (seconds), local canonical (about 15 min), hosted `repository-contracts` and `core` (required). The class map and the accepted hosted-run baseline are recorded in the 191-01 summary |
| SC3 (CLEAN-03): directory, regex entry, entries and ceilings gone at 0/0; three hexes in the deny set; kept guards still fail a planted retired value and path | `node --test ui-tokens.test.mjs` (live scan, live allowlist, "deny set and new set are disjoint", the existing planted retired hex, rgb, directory and stale-entry cases); `git ls-files` shows no retired directory; `grep -c` of the regex shows it absent; hosted `ops-ui` (runs because `ci.yml` changed) | Node about 2 s; hosted `ops-ui` about 450 s; `repository-contracts` canonical run as above |
| SC4 (CLEAN-04): five invariants, planted and accept cases, source-only, floor and names raised, docs say source not rendered | `node --test ui-tokens.test.mjs`; the wrapper test in `ui_contrast_contract_test.exs` (floor and names); `workflow_wiring_test.exs` (ledger intact); a `git grep` that the CONTRIBUTING and `DESIGN-TOKENS.md` lines exist | `core` and `repository-contracts`; about 2 s plus the wrapper |
| SC5 (CLEAN-05, CLEAN-06): tripwire and consumer scan pass on `main` and fail their planted cases; ledger reworded; `brand/tokens.json` named; `workflow_wiring_test` green | `MIX_ENV=test mix test test/mix/tasks/brand_pin_contract_test.exs` (tripwire, which also needs a planted case: read a doctored copy through the same predicate); `node --test ui-tokens.test.mjs` (scan, planted text reference and renamed byte copy, accept case); `MIX_ENV=test mix test test/mix/tasks/workflow_wiring_test.exs`; the upstream draft is present in the phase record (`grep`) | `core`; seconds locally |
| GATE-02 | One `mix verify.repository_contracts` run per commit SHA in 191-01 (three) and one on 191-02's final committed state; hosted exact-head run; no capture runs | Recorded in the phase record with SHAs |
| Hosted exact-head | PR head required checks green: `core`, `package`, `repository-contracts`, `backend`, `ecommerce-mounted`, `ops-ui (path-scoped)` | `gh pr checks` and `gh api repos/szTheory/scrypath/commits/<head>/check-runs` with `head_sha` equal to the PR head |

Sampling: per task, the Node token test and the focused Mix files; per commit, the canonical gate on the committed state; per phase, the hosted exact-head run. Wave 0: no new framework, no install; every needed tool is present (Node v26 locally, Elixir 1.19.0 / OTP 28 with the asdf environment variables).

**Zero human verification.** Nothing in this phase needs a person. Filing the upstream favicon issue is the maintainer's own action, outside the gate, and is recorded as such.

## What this does not prove

Source declarations, not rendered size: the 12 px floor, `uppercase`, `infinite`, arbitrary-size and `size: :xs` checks read ops-authored source, so a daisyUI default or a variant that emits a smaller size is only caught by the browser spec on the advisory lane. The demo favicon check proves byte equality with the pinned light favicon, not how any browser renders it. The tripwire proves the pinned `favicon.svg` is still the unthemed one and says nothing about whether upstream fixed it. The consumer scan proves no tracked file outside the exempt paths references or copies the unthemed file, not what the built website serves (the Phase 189 contract owns that). The assertion map records survivors by test name; it does not prove the deleted checks' coverage was complete. The hosted run proves the repository passes the canonical command on a clean checkout at that head; it is not independent review, aesthetic approval, rendered-quality evidence, other-browser evidence or a real screen reader pass. No preview, capture or `ui:review` ran.

## Assumptions log

| # | Claim | Risk if wrong |
|---|-------|---------------|
| A1 | The post-189 allowlist is exactly the five non-`p189` entries at 197 hits | Low: the plan recomputes from the live file (task 1) |
| A2 | Phase 189's interim three-hex assertion spells the values literally | Low: task 3 checks; either outcome has a handled fix |
| A3 | The deleted contract test's three nested canonical runs are a measurable `repository-contracts` saving | None for correctness; record the measured before and after only |
| A4 | The demo's `page_controller_test.exs` is unaffected by the favicon byte swap | Very low: it compares served bytes to the priv copy |
| A5 | Keeping `later_hidden` removal minimal (drop the list and comment, keep the Phase 183 assertion) is the right shape | Low: any equivalent edit that keeps the identity assertion for the other 27 hidden modules works |
| A6 | CLEAN-04's `font-size` scan across `.ex` and `.heex` inline styles finds no declaration today | Low: re-run in the plan; today's grep over `lib` shows no `font-size` outside CSS |

## Open questions (RESOLVED)

1. **Map or hosted run for the lost clean-clone baseline?** RESOLVED in CONTEXT D-05: accept the hosted exact-head run, record the class map.
2. **Does the tripwire test need an exemption from the scan?** RESOLVED in CONTEXT D-13: no, build the path at runtime.
3. **Does the allowlist file go away at 0 entries?** RESOLVED in CONTEXT D-03: it stays with an empty list (the live tests read it and the schema check expects it).
4. **Where do the ledger and token-authority docs go?** RESOLVED in CONTEXT D-20: 191-02, in or after the allowlist-emptying commit.

## Upstream defect report (draft for the phase record; filing is the maintainer's step)

Target: `szTheory/scrypath-brand`. Source: prep note D item 5, with the 2026-11-20 facts.

> **`assets/icon/favicon.svg` renders black in every theme**
>
> The file (891 bytes) draws its paths with `class="g"` and `class="l"` but contains no `<style>` block and no `fill`, so it renders black in light and dark. `BRAND.md` (the favicon line, about 225) says it "follows the device's light or dark setting: in dark mode its slash is Orchid", and `assets/README.md` says it "swaps its letter and slash with the device theme".
>
> Suggested fix: add a `<style>` with a `prefers-color-scheme: dark` rule (Orchid slash, Pale Ink letters), or ship the file with explicit fills; add a test that renders it under both schemes.
>
> Consumer impact: downstream projects currently serve `favicon-light.svg` under the name `favicon.svg` as a workaround and guard against using the unthemed file (a tripwire fails when the pinned file gains a `<style` or `fill`, so a refresh that picks up the fix prompts removing the workarounds).

## Sources

### Primary (HIGH confidence)
- In-tree files read or run this session: `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/research/v1.47-prep/{A,D}-*.md`, `.planning/research/v1.47-gap-pass/{E,F,H}-*.md`, `CONTRIBUTING.md`, `AGENTS.md`, `examples/scrypath_ecommerce/{ui-tokens.test.mjs,retired-identity-allowlist.json}`, `test/mix/tasks/{workflow_wiring_test,ui_contrast_contract_test,verify.phase99_test,brand_pin_contract_test,ui_tokens_contract_test}.exs`, `test/release/{package_contents_test,package_metadata_test}.exs`, `dev/mix/tasks/{verify/ui_tokens.ex,verify.phase99.ex,brand/update.ex}`, `mix.exs`, `.github/workflows/ci.yml`, `scrypath_ops/assets/css/{app.css,DESIGN-TOKENS.md}`, `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex`, `brand/`.
- Commands: `node --test examples/scrypath_ecommerce/ui-tokens.test.mjs` (59 of 59, 1.6 s); `MIX_ENV=test mix test test/release/package_contents_test.exs` (tooling-boundary tests green); a throwaway collector counting 55 verifier modules; `shasum` over `git ls-files --cached --others --exclude-standard`; `git grep` scans for readers, the retired directory, the three hexes (and their rgb triplets) and the favicon path; a scratch `git archive` dry run of the three-commit chain (scratchpad, not committed).

### Secondary (MEDIUM confidence)
- The post-189 numbers (5 / 197 and its chain) and the idea that Phase 189's website contract spells the three hexes: derived, not observed.

## Metadata

**Confidence breakdown:** deletion chain HIGH; invariants HIGH (all pass today, traps re-verified); ledger reword HIGH (parser read); post-189 interactions MEDIUM.
**Research date:** 2026-11-20
**Valid until:** the first of Phase 189 or Phase 190 landing on `main`, after which re-run the verification table (the files they edit are named in pitfalls 5, 6 and 14).
