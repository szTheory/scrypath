---
phase: 191-cleanup
verified: 2026-11-20T00:00:00Z
status: passed
score: 11/11 must-haves verified
covered_files:
  - ".github/workflows/ci.yml"
  - ".planning/phases/191-cleanup/191-01-PLAN.md"
  - ".planning/phases/191-cleanup/191-01-SUMMARY.md"
  - ".planning/phases/191-cleanup/191-02-PLAN.md"
  - ".planning/phases/191-cleanup/191-02-SUMMARY.md"
  - "CONTRIBUTING.md"
  - "dev/mix/tasks/verify.phase99.ex"
  - "examples/scrypath_ecommerce/priv/static/favicon.svg"
  - "examples/scrypath_ecommerce/retired-identity-allowlist.json"
  - "examples/scrypath_ecommerce/ui-tokens.test.mjs"
  - "mix.exs"
  - "scrypath_ops/assets/css/DESIGN-TOKENS.md"
  - "test/mix/tasks/brand_pin_contract_test.exs"
  - "test/mix/tasks/ui_contrast_contract_test.exs"
  - "test/release/package_contents_test.exs"
  - "website/scripts/build.mjs"
covered_digest: "v4:sha256:9dd84cd180df3d9551dadb7a438369dcb01bbe8b1430a84580a54c77bc5029c5"
behavior_unverified: 0
overrides_applied: 0
re_verification: false
---

# Phase 191: Cleanup Verification Report

**Phase Goal:** The old identity's last code is gone and stays gone: the demo favicon is the pinned light favicon, the old brand directory's readers and data are deleted with the allowlist ending empty, cheap static invariants and an unthemed-favicon tripwire guard what the re-skin promised, and `brand/tokens.json` is the named single token authority.
**Verified:** 2026-11-20 on branch `gsd/phase-191-cleanup`, HEAD `885b300b` (last code commit `ce250655`; everything after it is under `.planning/`)
**Status:** passed
**Re-verification:** No, initial verification

## Goal Achievement

The goal is achieved in the code. Every claim below was checked against the tree and re-run, not read from the summaries. The new guards were also mutation-tested in a scratch copy of HEAD (outside the repo): each planted violation went red in the test that is meant to catch it and for the stated reason, and each valid case stayed green.

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | SC1 / CLEAN-01: a root `core` test proves the demo favicon is byte-identical to `brand/assets/icon/favicon-light.svg`, and the demo favicon's allowlist entry is gone | ✓ VERIFIED | `cmp` exits 0 and the sha256 of both files is `832e6098...`; the test is `brand_pin_contract_test.exs` "the demo storefront favicon is byte-identical to the pinned light favicon" (root `test/` tree, runs in `core`, not excluded by default tags: 99 tests ran). Scratch mutation: one appended byte, and the unthemed bytes copied over the demo file, each failed that test with "must be a byte copy of brand/assets/icon/favicon-light.svg". Demo `page_controller_test.exs` is not in the phase diff. Allowlist entry removed in commit `9a3b875e` (5/197 to 4/194) |
| 2 | SC2 / CLEAN-02: the verifier, its contract test, its `verify.phase99` line and its `preferred_envs` line are gone; no reader remains; `mix verify.repository_contracts` passed on the committed state; the deleted-assertion map is recorded | ✓ VERIFIED | `git ls-files` lists neither deleted file; `git grep` for `Mix.Tasks.Verify.UiTokens`, `verify.ui_tokens`, `ui_tokens_contract_test`, `verify/ui_tokens` outside `.planning/` returns nothing. `Scrypath.TestSupport.UiTokens` and `ui_tokens_helper_test.exs` remain by design (D-06; the contrast test uses them). Commit `f7515d5c` removes exactly one line each from `verify.phase99.ex` and `mix.exs`, and removes `later_hidden` from `package_contents_test.exs`. Verifier modules counted 54 against the unchanged floor of 53. Canonical gate: passed on `f7515d5c` (159 tests, 0 failures) and again on `ce250655` (receipt). The assertion class map and the hosted-run baseline decision are in `191-01-SUMMARY.md` |
| 3 | SC3 / CLEAN-03: the old brand directory and its `ci.yml` regex member are deleted with their allowlist entries and ceilings; allowlist 0 entries and 0 hits; the three shared hexes join the deny set; the kept deny-list and directory tripwire still fail a planted retired value and path; docs never spell the path | ✓ VERIFIED | No tracked file under the directory (36 removed in `ea8f5401`) and none on disk. Allowlist is `{"schema": ..., "entries": []}`; `ALLOWLIST_CEILING = 0` and `HITS_CEILING = 0`; sum of `max_hits` is 0. `DENY_HEX` holds 51 values and the last three are the three shared hexes. The `ops-ui-path` pattern lost only that member and keeps `brand/` (one-line diff). `RETIRED_DIR`, `ALLOWLIST_TAGS` (with `retire-last`) and the allowlist file are kept. Scratch mutations: each of the three shared hexes planted (bare with a hash, and as a quoted bare token) went red in "live deny-list scan finds no unlisted retired value", as did another retired hex and a retired path in slash form. A planted stale allowlist entry and a ceiling set to 1 went red in "live allowlist entries are current and tagged". `git grep -i` for the slash form outside `.planning/` is empty; no line added by the phase spells the name in any form |
| 4 | SC4 / CLEAN-04: the 12 px floor, arbitrary-size, `uppercase`, `infinite` and `size: :xs` invariants each fail a planted case and accept valid cases on ops-authored source only; no required gate is added; floor count and names rise in the same commit; docs say source, not rendered size | ✓ VERIFIED | Scratch mutations on live source, each exactly one failing test, named for the right invariant: `font-size: 10px`, `0.7rem`, a low `var()` chain, `80%`, `calc(`, `11px !important`, a `font: 10px` shorthand (CSS and inline style), an inline `font-size:10px` in HEEx, and the real `--text-ops-sm` and `--text-ops-xs` lowered to `0.6rem` (resolves to 9.6 px through the live `app.css`); `text-[13px]` in `.ex` and `.heex`, `text-[length:`, `text-[min`; `uppercase` as a class, in a class list and as `text-transform: uppercase`; `infinite` in CSS and JS; `size: :xs` and `size={:xs}`. Valid cases stayed green: `12px`, `0.75rem`, `var(--text-ops-xs)`, `inherit`, `font: inherit`, `text-[var(--x)]`, `text-[#123456]`, `text-xs`, `String.upcase`, `upcase_first`, `limit: :infinity`, `values: [:xs, :sm, :md]`, the `size == :xs && "btn-xs"` branch, and the words in every comment style. Violations planted in built CSS, vendored JS and demo host CSS were not scanned. Floor 56, 72, 76 equals the literal `^test("` count at each of the three commits that add tests, and the five live names plus the favicon scan name are in `@token_test_names`; raising the floor to 77, deleting a live test, and renaming a live test each failed the wrapper. Ledger stays 10 of 12 (it was 10 of 12 before the phase), so no gate was added. `DESIGN-TOKENS.md`, the `CONTRIBUTING.md` token row and the test header all say these read source declarations, not rendered size, and name the `btn-xs` hole |
| 5 | SC5a / CLEAN-05: the unthemed-favicon tripwire and the path-and-bytes consumer scan pass on the tree and fail their planted cases | ✓ VERIFIED | Tripwire (`brand_pin_contract_test.exs`, reads only `brand/`): in scratch, appending `<style`, `fill=`, `currentColor` or `prefers-color-scheme` to the pinned unthemed favicon failed both tripwire tests, and the message lists the five workarounds (all five exist in the tree: `mix.exs` favicon line, `package_metadata_test.exs`, `reskin_static_contract_test.exs`, the demo favicon, `docs/releasing.md`); a marker-free comment stayed green. Scan (`ui-tokens.test.mjs`): a renamed byte copy in `scrypath_ops/priv/static`, a `.dat` copy in `website/src`, the unthemed bytes copied over the demo `favicon.svg`, and a text reference in a doc and in ops JS each failed "live favicon consumer scan finds nothing outside the exempt paths" naming the file; a needle in a sibling of the updater (`dev/mix/tasks/brand/other.ex`) failed, so the exempt set is exactly `brand/`, `.planning/` and `dev/mix/tasks/brand/update.ex`; the light favicon under the name `favicon.svg` (ops, demo, scratch dirs), its file name in prose, and the needle inside the exempt paths all passed. The needle is built at runtime in both guards: no added line outside `.planning/` spells the contiguous path |
| 6 | SC5b: the upstream defect report is drafted in the phase record, not filed | ✓ VERIFIED | `191-PHASE-RECORD.md` has "Upstream favicon issue (D-14): DRAFT ONLY, not filed" with the draft as a quoted block and the statement that no `gh issue create` was run. No tracked or planning file in the phase records an outward action |
| 7 | SC5c / CLEAN-06: the ledger is reworded by gate name; `brand/tokens.json` is named the single token authority; `workflow_wiring_test` stays green | ✓ VERIFIED | Diff of `CONTRIBUTING.md` touches only the budget sentence and three rows. Token row: deny-list and directory tripwire permanent, parity half tied to the hand-kept projection of `brand/tokens.json`, "the single token authority"; the phrases "retire-last", "pending rows" and "only shrinks" are gone. Budget sentence names v1.47 and carries the cap of 12 forward. Component-contract row says v1.48. Offline brand pin row names the favicon tripwire. 10 rows, `Budget used: 10 of 12.`, no `Mix.Tasks.Verify` in the file. `DESIGN-TOKENS.md` Brand colors says `brand/tokens.json` is the single token authority and `app.css` a hand-maintained projection checked both ways. `workflow_wiring_test.exs` passes (part of 222 tests, 0 failures); a scratch edit to `Budget used: 9 of 12.` failed it ("the budget line must read: Budget used: 10 of 12."), and adding a `Mix.Tasks.Verify` name to the file failed `package_contents_test` |
| 8 | Goal clause: `brand/tokens.json` is the named single token authority | ✓ VERIFIED | Named in `CONTRIBUTING.md` (token row) and `scrypath_ops/assets/css/DESIGN-TOKENS.md` (Brand colors). `brand/tokens.json` and `brand/brand.json` are not in the phase diff, so the pin holds |
| 9 | Invariants apply only to ops-authored source and the docs say they are source checks | ✓ VERIFIED | `opsSourceFiles` selects `scrypath_ops/lib` `.ex` and `.heex`, `scrypath_ops/assets/js` `.js` outside any `vendor/`, and exactly `app.css`. The scope test and the scratch scope mutations (built CSS, `assets/vendor`, `assets/js/vendor`, demo CSS) confirm. Docs: see truth 4 |
| 10 | GATE-02: one canonical run per SHA, no stale receipt, no new required gate, no capture, no outward action, fixture-copied files untouched, `chore`/`docs` titles | ✓ VERIFIED | Receipt `191-GATE-RECEIPT.md` names `ce250655b7e90e737f3a922287114c402c8a3b9d`, which is an ancestor of HEAD; `git diff --name-only ce250655..HEAD -- . ':!.planning'` is empty, so the receipt is fresh. None of `contrast-checker.mjs`, `contrast-pairs.mjs`, `app.css`, `brand/tokens.json`, `brand/brand.json` is in the phase diff, so the whole-CI-Node-step rule did not apply. `UI-PREVIEW.json` and `ui-review-artifacts/` untouched. All six code commits are `chore(...)` or `docs(...)`; no `lib/` file changed. Neither plan is evidence-only |
| 11 | Plan 191-02 must-have: no tracked file outside the exempt paths spells the unthemed favicon path after the phase, including the website build comment | ✓ VERIFIED | `website/scripts/build.mjs` comment reworded (comment-only diff); `git grep -F` of the path outside `.planning/`, `brand/` and the updater is empty |

**Score:** 11/11 truths verified (0 present, behavior-unverified)

### Deferred Items

None. Nothing is deferred to a later phase. The post-merge items below are pending-by-design, not deferred gaps.

### Pending by design (deferred-to-ship, not gaps, not human verification)

These cannot exist before the PR is pushed and merged. Each has a command, an owner and a pass condition in the "Post-ship evidence" table of `191-PHASE-RECORD.md`, whose Result cells are empty on purpose; the orchestrator fills them after the merge.

| # | Item | Status |
|---|------|--------|
| 1 | Required contexts on the exact PR head (`core`, `package`, `repository-contracts`, `backend`, `ecommerce-mounted`, `ops-ui (path-scoped)`) | pending-by-design |
| 2 | Content landed on `main` | pending-by-design |
| 3 | Post-merge push run on `main` | pending-by-design |
| 4 | Hosted `repository-contracts` duration before and after (`CI-EFFICIENCY.md` finding 13 says "expected, not measured") | pending-by-design |
| 5 | Website `build-and-check` on the PR head and the post-merge `deploy` and smoke run | pending-by-design |

The upstream favicon issue is drafted only and not filed, by design.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `examples/scrypath_ecommerce/priv/static/favicon.svg` | byte copy of the light favicon | ✓ VERIFIED | `cmp` clean, same sha256 as ops' served favicon |
| `test/mix/tasks/brand_pin_contract_test.exs` | demo equality test and tripwire | ✓ VERIFIED | substantive, mutation-tested, runs in `core` |
| `examples/scrypath_ecommerce/retired-identity-allowlist.json` | empty allowlist, schema kept | ✓ VERIFIED | `entries: []` |
| `examples/scrypath_ecommerce/ui-tokens.test.mjs` | ceilings 0/0, 51 deny hexes, five invariants, consumer scan | ✓ VERIFIED | 82 of 82 pass in 1.8 s |
| `test/mix/tasks/ui_contrast_contract_test.exs` | floor 76 and 13 live names | ✓ VERIFIED | floor equals literal count; wrapper passes (16 tests, 0 failures, 2 `contrast_child` excluded) |
| `test/release/package_contents_test.exs` | no deleted-module pin, floor 53 kept | ✓ VERIFIED | 54 modules counted |
| `CONTRIBUTING.md`, `scrypath_ops/assets/css/DESIGN-TOKENS.md` | reworded ledger, authority sentence, source-not-rendered note | ✓ VERIFIED | see truths 4, 7, 8 |
| `191-GATE-RECEIPT.md`, `191-PHASE-RECORD.md`, `.planning/reference/CI-EFFICIENCY.md` finding 13 | evidence records | ✓ VERIFIED | present and consistent with the code |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `ui-tokens.test.mjs` ceilings | allowlist file | `ALLOWLIST_CEILING` and `HITS_CEILING` equal entry count and `max_hits` sum | ✓ WIRED | 0 and 0 on both sides; mismatch mutation went red |
| `brand_pin_contract_test.exs` | demo favicon | `File.read!` byte comparison | ✓ WIRED | mutation red |
| `.github/workflows/ci.yml` `ops-ui-path` | `workflow_wiring_test` | pattern keeps `brand/` | ✓ WIRED | wiring test passes |
| `ui_contrast_contract_test.exs` | `ui-tokens.test.mjs` | `token_test_call_names` count and `@token_test_names` | ✓ WIRED | floor, delete and rename mutations each red |
| `CONTRIBUTING.md` | `workflow_wiring_test` | `budget_ledger_errors/1` | ✓ WIRED | Budget used mutation red |
| `191-GATE-RECEIPT.md` | tested SHA | no non-`.planning` change after it | ✓ WIRED | diff empty |

### Data-Flow Trace (Level 4)

Not applicable. This phase ships test, tooling and asset changes with no runtime data path. The one rendered artifact (the demo tab icon) is proved by byte equality only.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Token test (live, planted, accept) | `node --test examples/scrypath_ecommerce/ui-tokens.test.mjs` | 82 pass, 0 fail | ✓ PASS |
| Contract tests | `mix test` on `workflow_wiring_test`, `brand_pin_contract_test`, `verify_capability_test`, `package_contents_test` | 222 tests, 0 failures | ✓ PASS |
| Contrast wrapper, helper and phase99 tests | `mix test ui_contrast_contract_test ui_tokens_helper_test verify.phase99_test --exclude contrast_child` | 16 tests, 0 failures | ✓ PASS |
| No human gates | `mix test test/scrypath/no_human_gates_contract_test.exs` | 2 tests, 0 failures | ✓ PASS |
| Mutation tests (scratch copy, 50+ cases) | planted violations and valid cases, see truths 3 to 7 | every violation red for the right reason, every valid case green | ✓ PASS |

`mix verify.repository_contracts` and `mix verify.core` were not re-run, by instruction: they ran once on `ce250655` per the receipt and only `.planning/` files changed after it (confirmed by diff). The contrast child tests (`contrast_child`) were excluded for the same reason.

### Probe Execution

No probes declared by the plans and none apply. Step 7c: not applicable.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| CLEAN-01 | 191-01 | demo favicon equality test and allowlist entry removed | ✓ SATISFIED | truth 1 |
| CLEAN-02 | 191-01 | readers gone, gate green on committed state | ✓ SATISFIED | truth 2 |
| CLEAN-03 | 191-01 | directory, regex member, entries and ceilings together; three hexes; kept guards | ✓ SATISFIED | truth 3 |
| CLEAN-04 | 191-02 | five source invariants, floor and names, docs | ✓ SATISFIED | truth 4 |
| CLEAN-05 | 191-02 | tripwire, consumer scan, upstream draft | ✓ SATISFIED | truths 5 and 6 |
| CLEAN-06 | 191-02 | ledger reword, token authority named | ✓ SATISFIED | truths 7 and 8 |
| GATE-02 | 191-01, 191-02 | guardrails | ✓ SATISFIED | truth 10 |
| SITE-03 (Phase 191 half) | 191-01 | three shared hexes in the deny set | ✓ SATISFIED | truth 3 |

No orphaned requirements: REQUIREMENTS.md maps CLEAN-01 to CLEAN-06 to Phase 191 and every one is claimed by a plan. The traceability table and checkboxes in REQUIREMENTS.md still read Pending; updating them is the orchestrator's post-ship bookkeeping, not a code gap.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `test/mix/tasks/brand_pin_contract_test.exs` | 859 | the old directory's name spelled without its trailing slash (`["brand", "brandbook"]`, the expected value of a planted package-files case) | ℹ️ Info | Predates the phase (commit `8beb3ed0f`, 2026-11-19). Not the scanned form: the deny scan matches the slash form, and the requirement and D-04 concern the path with its slash. Recorded as an optional follow-up in the phase record. No effect on any guard |

No `TBD`, `FIXME`, `XXX`, `TODO`, `HACK` or placeholder text and no `console.log` in any line the phase added outside `.planning/`.

### Human Verification Required

None. Per the run book there are no human-check items. The Post-ship items above are executable commands owned by the orchestrator, not checks for a person.

### What this does not prove

- Rendered size or appearance. The five invariants read ops-authored source declarations. A caller-supplied variant that emits the daisyUI `btn-xs` class (11 px) is caught only by the `size: :xs` caller check and by the browser spec on the advisory lane; computed size stays browser-only. Also not read: camelCase `style.fontSize` assignments in JavaScript, a font shorthand inside a JavaScript string, and prose in strings (only comments are stripped).
- How the demo tab icon looks in any browser. Byte equality with the pinned light favicon is the whole claim; no preview, capture or `ui:review` ran.
- That upstream fixed the unthemed favicon. The tripwire only fires when the pinned file changes. What the built website serves is owned by the Phase 189 static contract; the consumer scan covers tracked and untracked-not-ignored repository files only.
- That the deleted contract test's coverage was complete. The assertion map names survivors by test name.
- That the hosted lanes pass on the exact PR head. Those are the pending-by-design items above.
- Aesthetic approval, independent review, other browsers or a real screen reader. This report is a goal-backward check of the code, not any of those.

### Gaps Summary

No gaps. All five ROADMAP success criteria and the plan-level must-haves hold in the code, and the new guards demonstrably fail what they claim to fail. The only items open are the post-merge evidence rows that the phase record deliberately leaves empty for the orchestrator.

---

_Verified: 2026-11-20_
_Verifier: Claude (gsd-verifier)_
