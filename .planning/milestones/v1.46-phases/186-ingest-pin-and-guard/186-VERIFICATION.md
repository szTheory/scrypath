---
phase: 186-ingest-pin-and-guard
verified: 2026-11-19T05:58:00Z
status: passed
score: 5/5 roadmap success criteria verified; 9/9 requirement IDs satisfied (PIN-01..03, TOK-01..04, GATE-01, GATE-02)
covered_files:
  - ".github/workflows/ci.yml"
  - ".planning/phases/186-ingest-pin-and-guard/186-01-PLAN.md"
  - ".planning/phases/186-ingest-pin-and-guard/186-01-SUMMARY.md"
  - ".planning/phases/186-ingest-pin-and-guard/186-02-PLAN.md"
  - ".planning/phases/186-ingest-pin-and-guard/186-02-SUMMARY.md"
  - ".planning/phases/186-ingest-pin-and-guard/186-03-PLAN.md"
  - ".planning/phases/186-ingest-pin-and-guard/186-03-SUMMARY.md"
  - "CONTRIBUTING.md"
  - "brand/brand.pin.json"
  - "dev/mix/tasks/brand/update.ex"
  - "dev/mix/tasks/verify/brand.ex"
  - "examples/scrypath_ecommerce/retired-identity-allowlist.json"
  - "examples/scrypath_ecommerce/ui-tokens.test.mjs"
  - "mix.exs"
  - "scripts/ci/ui_state_pairs.cjs"
  - "scripts/ci/ui_state_pairs.test.cjs"
  - "scrypath_ops/assets/css/token-map.json"
  - "scrypath_ops/test/scrypath_ops_web/surface_depth_token_contract_test.exs"
  - "test/mix/tasks/brand_pin_contract_test.exs"
  - "test/mix/tasks/dependency_boundary_contract_test.exs"
  - "test/mix/tasks/ui_contrast_contract_test.exs"
  - "test/mix/tasks/ui_tokens_contract_test.exs"
  - "test/mix/tasks/workflow_wiring_test.exs"
  - "test/support/ui_tokens.ex"
covered_digest: "v4:sha256:e873b38b4a90b042e741dbd45f7dea3370bf566218c591f8f1320f7305659e7f"
behavior_unverified: 0
overrides_applied: 0
coincidental_reliance_items:
  - truth: "The Phase 185 pair comparator still fails on a state change (SC4)"
    reason: fixture-only
    harden: "The only state mutation in `ui_state_pairs.test.cjs` also rewrites the hover capture's state, so removing `stateEqual` alone from the verdict leaves every test green (verified on a scratch copy); only removing both `stateEqual` and `hoverStateEqual` turns a test red. Add one test that changes only the neutral capture's state."
  - truth: "The token test passes on the committed tree (SC2)"
    reason: undeclared-precondition
    harden: "The deny-list scans `git ls-files --cached --others --exclude-standard`, so a local pass also depends on no generated, untracked, un-ignored file holding a retired value. One such file (the contrast checker's root `test-results/`) was found and ignored in 21f13530; no other generator is guaranteed absent. Hosted CI is a clean checkout and is not affected."
---

# Phase 186: Ingest, pin and guard Verification Report

**Phase Goal:** Maintainers can prove the committed brand assets are exactly the pinned ones and that retired identity values cannot re-enter the repository, and the existing contract tests read live tokens so the Phase 187 recolor fails only on what Phase 187 owns.
**Verified:** 2026-11-19T05:58:00Z
**Status:** passed
**Re-verification:** No, initial verification
**Code verified:** branch `feat/v1.46-186-brand-pin-and-guard`. The full lane runs below were made on `21f13530`; the report was refreshed against `f2fb2929` after the orchestrator's `6744e0f8` (reason text of the `brandbook/` allowlist entry, plus the ROADMAP Phase 188 scope note) and `f2fb2929` (the security audit). Working-tree changes are limited to `.planning/STATE.md`, `.planning/config.json`, `.planning/state.json`.
**Security audit:** [186-SECURITY.md](186-SECURITY.md) reports SECURED, 20 of 20 threats closed, 0 open (audited 2026-11-19). I did not re-derive its dispositions; my own probes overlap the update-task and verify-task threats (zip slip, zip bomb, tampering, active content, deny-list and comparator looseness) and agree with it.

## Plain-language result

**Refresh after `6744e0f8`:** the only code-side change since the lane runs is one `reason` string in `examples/scrypath_ecommerce/retired-identity-allowlist.json`, which only `ui-tokens.test.mjs` reads. On `f2fb2929` that test still passes 42 of 42, every `retire-last` entry still carries an `owner: ` name (6 of 6), the entry count (22) and hit total (485) are unchanged, and the ExUnit wrapper plus the workflow-wiring and token-contract tests pass (90 tests, 0 failures). The Phase 188 sequencing problem (finding 3) is resolved.

The goal is achieved. I did not rely on the SUMMARY files: I re-ran every automated check, compared the committed brand files byte for byte against the source archive, and broke each guard on scratch copies outside the repository to confirm it fails when it should. Every guard failed on its planted defect, and every refusal path of the update task refused.

Nothing here needs a person to look at it. I also ran `verify.core`, `verify.repository_contracts`, `verify.ops_ui` and `verify.package` once each on the exact HEAD commit, plus the CI Node step and the docs build; all passed, which closes the stale-receipt question left by the review-fix commits. What is not proven is hosted CI: nothing is pushed, so no required check has run on a hosted runner. Details are under "What is not proven".

## Goal Achievement

### Observable Truths (ROADMAP success criteria, then plan must-haves)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| SC1 | The offline brand verify passes on a clean checkout and blocks merging on an unpinned file, a changed byte, a deleted or symlinked asset; the update task refuses tampered size, hash, entry-count and uncompressed-size inputs and writes only allowlisted members; `brand/` holds only the adopted assets; no `brand/` or `brandbook/` in the Hex `files` | VERIFIED | `MIX_ENV=test mix verify.brand` printed `verify.brand: ok (44 assets, 326773 bytes)` in 0.4 s. Independently recomputed: all 44 pinned sha256 values match disk, and each disk file equals its member of the source archive (archive sha256 `3fc6d80f...` equals the pin); 0 mismatches. 64 non-adopted archive members (PDF, TTF, MP3, MP4, WAV, WebM, JPG, large PNG, HTML books) are absent. Scratch-copy mutations all raised with the named reason: appended byte (size mismatch), same-size one-byte flip in `mono.woff2` and `tokens.json` (sha256 mismatch), unpinned file, dotfile in the fonts dir, deleted asset, symlink, deleted pin entry, appended `<script`. Merge-blocking path: `core (required)` runs `mix verify.core`, whose `mix test` includes `brand_pin_contract_test.exs` (no exclusion tags; it calls `Brand.check!(@root)` on the committed tree). Update task spot-check through `verify_archive!/2` on crafted archives: wrong size, wrong sha256, entries 109, uncompressed +1, flipped byte, garbage, 8 MiB + 1, 201 entries, 20 MB declared, `..` name and backslash name were each refused with a distinct message; the real archive extracts exactly 44 members. `write!/3` takes destinations only from the compile-time allowlist. `git ls-files -- brand scrypath_ops/priv/static/assets/fonts` is 45 files (44 assets + the pin), 0 symlinks, 0 matches for pdf/ttf/audio/video/index.html/fonts.css. Hex `files:` has no `brand` entry; `mix verify.package` passed on HEAD and the unpacked package holds no brand path. |
| SC2 | One Node token test, run by an existing required step, passes on main and fails each of its six planted sabotage cases while accepting valid fixtures | VERIFIED | `node --test examples/scrypath_ecommerce/ui-tokens.test.mjs`: 42 pass, 0 fail. Run through the existing `core` and `repository-contracts` suites by the wrapper test in `ui_contrast_contract_test.exs` (requires 7 live test names as passing TAP lines and `# fail 0`); no `ci.yml` step was added for it. On a scratch git copy I sabotaged each class and the live test failed every time: missing token row (`missing token row for --color-info`), orphan row, resolved-hex mismatch (applied row re-pointed at another brand token; also a brand hex changed under an applied row), a pending row falsely marked applied, stale built CSS (one emission value changed), retired hex in a non-allowlisted file (upper case too), retired `rgb(25 30 37)` triplet, retired `rgba(25, 30, 37, .5)` in an untracked file, the retired directory string in a new file, growth of a retired value inside an allowlisted file (`README.md`), and a stale allowlist entry (its retired values removed). The unmodified copy passed 42 of 42. |
| SC3 | The ~12 pinned old-identity literals are gone from the three root and ops contract tests, which assert relationships through a resolved-token helper, in at most 3 test-only commits; the recolor projection shows no failing test outside Phase 187's scope | VERIFIED (one documented exception, see note) | 0 old-identity hex, `170 160 255` or `18 / 255` literals remain in `ui_contrast_contract_test.exs`, `surface_depth_token_contract_test.exs`, `test/support/ui_tokens.ex` or the helper test. Three lift commits (`ab728791`, `6d6d50ca`, `37ff7d2e`), each touching only `test/`, `scrypath_ops/test/` and `examples/scrypath_ecommerce/` test data; two further commits (`8cf4768a`, `aa93fb51`) add the new wrapper test to `ui_contrast_contract_test.exs`, which the plan's counting rule treats as a contract introduction. Independent recolor projection (my own, not the SUMMARY's) on a shared clone of HEAD with deps copied: the control run was fully green (contrast checker PASS, token test 42/42, 27 root tests, 24 ops tests); after setting all 34 changing adopt/derive/local cells of both theme blocks to their resolved brand targets, the failures were: the token test's applied-row and built-CSS cases (SKIN-01), the allowlist `max_hits` shrink for `app.css` (`holds 8 retired values, under its max_hits 34: lower max_hits to 8`, SKIN-01/SKIN-05), the contrast checker's muted-alpha guard (`D-15 Guard 2: named muted token --ops-text-muted ... no matching declaration`, SKIN-01/A11Y-01) and its ExUnit wrapper, the token validator's mirror cases (`ops.dark.ops-bg: CSS expression mapping ... does not match the live CSS source`, plus the example-JS parity assertion, SKIN-01 mirror remap, which I did not apply) and the `64%, transparent` alpha pin (SKIN-01/A11Y-01). The four ops regex tests stayed green (24/24). No failure traced to a hex literal in test code. The three advisory e2e specs still hold their old constants (grep counts 3, 4, 2) and are 187-owned (SKIN-05). Note: `ui_tokens_contract_test.exs` still holds two old hexes (`#5B4AD1`, `#C17A3E`, lines 425-426); they assert the content of the retired `brandbook/` directory, are unaffected by an `app.css` recolor, were left on purpose by the plan, and the file is on the allowlist as `retire-last`. |
| SC4 | The Phase 185 preservation specs still fail on copy, geometry, state, action and identity changes; the structural check accepts its calibrated recolor case and rejects its calibrated regression case | VERIFIED | `node --test scripts/ci/ui_state_pairs.test.cjs`: 33 pass, 0 fail (it is in the existing `repository-contracts` Node step; the other four files of that step were also run on HEAD, see below). Calibration reads four committed crops of real v1.43 captures (144 KiB, no `.planning/milestones` reference in the test): real recolor accepted, real state change rejected, real 8 px band shift rejected. Verdict line still ANDs all eight terms (`pixelsEqual && stateEqual && hoverStateEqual && actionEqual && geometryEqual && copyEqual && assertionsEqual && identityEqual`). Scratch-copy mutation probes, each making a test red: drop `actionEqual`, drop `identityEqual`, drop `copyEqual`, drop `geometryEqual`, drop `assertionsEqual`, drop `stateEqual` plus `hoverStateEqual`; loosen share tolerance, block cap and edge threshold together (12 failures including both real-capture rejects); remove the edge signal (5 failures); remove the block cap (1 failure); make the step delta over-strict (recolor accept goes red). The WR-05 fix (edge-count signal plus an 8-block cap) is covered by planted tests that fail when removed, so it needs no human decision. One weak spot, see coincidental reliance: removing `stateEqual` alone is not detected. |
| SC5 | `ops-ui (path-scoped)` is a required check asserted by the wiring test with its path list covering `brand/`, `language/`, `fixtures/`; storybook-boundary checks run in a required job; every new required gate records its deletion trigger and churn within the budget of 12; closes in at most 3 plans with one full gate per commit SHA | VERIFIED | Wiring test "exactly six required contexts" passes and also pins the exact job name `ops-ui (path-scoped)`. Live branch protection (read-only `gh api`): `["backend (required)","core (required)","ecommerce-mounted (required)","package (required)","repository-contracts (required)","ops-ui (path-scoped)"]`, six contexts. The `ops-ui-path` filter regex in `ci.yml` includes `brand/`, `brandbook/`, `language/` and `fixtures/` (that list predates this phase). Storybook boundary: three live checks plus a planted case in `dependency_boundary_contract_test.exs`, run by `core` and `repository-contracts`; they pass vacuously until v1.47 adds the dependency. CONTRIBUTING `### Required-gate budget` has 5 rows, each with enforcing file, lane, deletion trigger and churn, and `Budget used: 5 of 12.`; a parser test fails on planted defects. Three plans (`186-01..03-PLAN.md`). Per-plan receipts and the GATE-02 record are checked below. |
| M1 | `mix brand.update` is the only place the online re-download check lives (no CI job or test touches the network) | VERIFIED | The Pages URL appears only in `dev/mix/tasks/brand/update.ex`, the pin and the contract test; online-check tests use `Req.Test` stubs; no workflow references the brand archive. |
| M2 | Six required contexts in the wiring test | VERIFIED | `workflow_wiring_test.exs:1071` asserts exactly backend, core, ecommerce-mounted, ops-ui, package, repository-contracts. |
| M3 | Calibration tests read committed fixtures, not the archive | VERIFIED | Four PNGs plus `PROVENANCE.md` under `scripts/ci/fixtures/ui-state-pairs/`; `grep -c ".planning/milestones"` in the test prints 0. |
| M4 | GATE-02 stop-and-decide recorded with the go decision; 3-plan cap honored; no dirty-tree capture | VERIFIED | `186-02-SUMMARY.md` contains the "GATE-02 stop-and-decide (end of Plan 02)" section and the line `decision: go` (line 132) before any Plan 03 work. No capture was taken (TOK-04 used committed crops only). |

**Score:** 5/5 roadmap success criteria verified (0 present-but-behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `brand/brand.pin.json` | zip sha256, size, entries, commit, per-asset rows, owned directories | VERIFIED | 44 asset rows, 326,773 B, schema `scrypath.brand-pin.v1`, owned dirs `brand` and the fonts dir |
| `dev/mix/tasks/verify/brand.ex` | offline verifier with `check!/1` | VERIFIED | Wired through `mix.exs` `preferred_envs` and the contract test; exercised by mutation |
| `dev/mix/tasks/brand/update.ex` | capped download, bounded in-memory inflate, allowlisted writes, online check | VERIFIED | Refusal spot-checks above; review fixes CR-01, WR-01..04 present with tests |
| `test/mix/tasks/brand_pin_contract_test.exs` | test-owned `@expected_zip_sha256` and `@expected_assets_digest`, tamper and refusal cases | VERIFIED | 96 tests, 0 failures |
| `scrypath_ops/priv/static/assets/fonts/` | 3 woff2 + 3 OFL texts, byte-pinned | VERIFIED | 6 tracked files, not git-ignored |
| `scrypath_ops/assets/css/token-map.json` | 37 rows, per-theme disposition and applied flag | VERIFIED | 37 rows, 74 cells, 38 pending (equals `PENDING_CEILING`) |
| `examples/scrypath_ecommerce/ui-tokens.test.mjs` | parity, applied, built CSS, hex allowlist, deny-list, planted and accept cases | VERIFIED | 42 tests |
| `examples/scrypath_ecommerce/retired-identity-allowlist.json` | shrink-only, phase-tagged, hit-capped | VERIFIED | 22 entries, 485 hits (matches `HITS_CEILING`); tags p187 12, retire-last 6, p188 2, p189 2; every `retire-last` reason names an owner |
| `test/support/ui_tokens.ex` | resolved-token helper | VERIFIED | Used by `ui_tokens_contract_test.exs`; 0 old literals |
| `scripts/ci/ui_state_pairs.cjs` | structural comparator replacing only the pixel term | VERIFIED | `comparePngStructural`, `inkCoverageGrid`, `edgeCountGrid`; schema v4, status `structural-match` |
| `scripts/ci/fixtures/ui-state-pairs/*` | 4 crops + provenance | VERIFIED | 134,612 B of PNG |
| `CONTRIBUTING.md` | gate ledger | VERIFIED | 5 of 12 |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| brand pin contract test | `Verify.Brand.check!/1` | direct call on repo root and temp copies | WIRED | Live-tree test plus tamper tests |
| `verify.brand` allowlist | `Brand.Update.adopted_members/0` | pinned paths must equal the allowlist | WIRED | Deleting a pin entry raises `pinned paths differ from the adopted allowlist` |
| `mix.exs` | both tasks | `preferred_envs` `:test` | WIRED | lines 101-102 |
| `ui_contrast_contract_test.exs` wrapper | `ui-tokens.test.mjs` | `System.cmd node --test` | WIRED | Runs in `core` and in `repository-contracts` via `@focused_tests` |
| `ui-tokens.test.mjs` | `contrast-checker.mjs` | `readThemeProperties` import | WIRED | |
| `token-map.json` | `brand/tokens.json` | adopt `source` paths resolve | WIRED | Planted unknown-path case throws |
| `ui_tokens_contract_test.exs` | `Scrypath.TestSupport.UiTokens` | `theme_value!/3`, `bump_hex/1` | WIRED | |
| `ci.yml` repository-contracts Node step | `ui_state_pairs.test.cjs` | file list | WIRED | `ci.yml:195` |
| `workflow_wiring_test.exs` | CONTRIBUTING ledger | table parser | WIRED | Planted defects fail |

### Data-Flow Trace (Level 4)

Not applicable: this phase renders no dynamic data. `app.css`, the built CSS, ops lib code, images and favicon are unchanged against `main` (`git diff --stat` empty).

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Offline brand verify | `MIX_ENV=test mix verify.brand` | `ok (44 assets, 326773 bytes)`, 0.4 s | PASS |
| Contrast checker and self-test (from the demo directory) | `node contrast-checker.mjs` and `--self-test` | `Contrast check: PASS`, 0 AA failures; `self-test passed` | PASS |
| Token test | `node --test examples/scrypath_ecommerce/ui-tokens.test.mjs` | 42 pass, 0 fail | PASS |
| Pair comparator test | `node --test scripts/ci/ui_state_pairs.test.cjs` | 33 pass, 0 fail | PASS |
| Root contract tests | `MIX_ENV=test mix test` on the seven named files, `--exclude contrast_child` | 228 tests, 0 failures | PASS |
| Remaining repository-contracts focused tests | `mix test` on phase99, phase111, no_human_gates, verify.phase99, ci_monitor, package_contents | 63 tests, 0 failures | PASS |
| Literal ratchet | `mix test test/mix/tasks/ui_literal_contract_test.exs` | 2 tests, 0 failures (1 excluded by tag) | PASS |
| Ops regex tests | `mix test` four files in `scrypath_ops` | 24 tests, 0 failures | PASS |
| Hex package | `mix verify.package` on HEAD | exit 0, package holds no brand path | PASS |
| Docs | `mix docs --warnings-as-errors` on HEAD | exit 0, no warnings | PASS |
| `core` lane | `mix verify.core --exclude integration --exclude docs_contract` on HEAD | format, workspace clean, compile with warnings as errors, credo (no issues), 5 properties and 1158 tests with 0 failures (103 excluded), docs with warnings as errors, no-optional-deps; exit 0 | PASS |
| `repository-contracts` lane (ExUnit part, includes the four clone-based `contrast_child` tests and the fetch-dependent literal policy) | `mix verify.repository_contracts` on HEAD | 157 tests, 0 failures, 179.5 s; exit 0 | PASS |
| `ops-ui` lane | `mix verify.ops_ui` on HEAD (task-scoped database `scrypath_ops_test_186_verify`, dropped afterwards) | root boundary 2 tests, then 2 doctests and 329 tests, 0 failures; exit 0 | PASS |
| Zip bomb with a falsified declared size (all 44 members present, one inflates to 100,000,000 bytes while declaring 71,836) | `Brand.Update.extract!/2` on a crafted archive | `member scrypath-brand/BRAND.md inflates past its declared size 71836`, 4 ms | PASS |
| Other four files of the CI Node step | `node --test` ecommerce_build, lifecycle, evidence, target on HEAD | 123 tests, 123 pass, 0 fail, exit 0 (together with the 33 pair tests, the whole CI step is green on HEAD) | PASS |

### Probe Execution

No probe scripts are declared by the plans (`scripts/*/tests/probe-*.sh` does not apply): SKIPPED.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| PIN-01 | 186-01 | Offline verify of `brand/` and fonts against the pin, closed directories, merge-blocking | SATISFIED | SC1 evidence |
| PIN-02 | 186-01 | Update task refuses size, hash, entry-count, uncompressed-size mismatch; extracts allowlisted members in memory; only home of the online check | SATISFIED | SC1 evidence, M1 |
| PIN-03 | 186-01 | Only adopted assets committed; `brand/` and `brandbook/` out of the Hex `files` | SATISFIED | SC1 evidence, `verify.package` on HEAD |
| TOK-01 | 186-02 | One Node token test in an existing required step: parity both ways, resolved hex, system-dark vs built CSS, fresh CSS | SATISFIED | SC2 evidence |
| TOK-02 | 186-02 | Hex allowlist and retired-value deny-list over `git ls-files`, shrink-only phase-tagged allowlist, planted failures | SATISFIED | SC2 evidence |
| TOK-03 | 186-02 | Pinned old-identity literals lifted, at most 3 test-only commits, projection leaves only 187-owned failures | SATISFIED | SC3 evidence (documented exception) |
| TOK-04 | 186-03 | Preservation specs keep copy/geometry/state/action/identity checks; pixel comparison becomes recolor-tolerant structural check calibrated with accept and reject cases | SATISFIED | SC4 evidence |
| GATE-01 | 186-03 | `ops-ui` required with path list; wiring and storybook-boundary checks; gate budget within 12 | SATISFIED | SC5 evidence; branch protection read |
| GATE-02 | 186-02, 186-03 | Guardrails: stop-and-decide, 3 plans, one full gate per SHA, stale receipt is a failed gate, no dirty-tree capture | SATISFIED: each plan's own receipts are valid, and the post-review commits are now covered by one green run of each lane on HEAD (see receipts) | M4 and the receipts table |

No orphaned requirements: REQUIREMENTS.md maps exactly PIN-01..03, TOK-01..04, GATE-01 and GATE-02 to Phase 186, and all nine appear in plan frontmatter. (Its traceability table and the ROADMAP plan checkboxes still read Pending; updating them is bookkeeping for the orchestrator.)

### GATE-02 receipts, checked against git

| Plan | GATE_SHA | In HEAD ancestry | Recorded gates | Later commits touched |
|------|----------|------------------|----------------|-----------------------|
| 01 | `a876a613` | yes | `verify.core` steps 1-5 green, step 6 (docs) red from a pre-existing `AGENTS.md` link (fixed by `97f6ea8c`, an ancestor of the next two SHAs); `verify.ops_ui` and `verify.package` green | only `.planning/` until Plan 02's code |
| 02 | `b58fd05b` | yes | `verify.repository_contracts`, `verify.core` (all six steps), `verify.ops_ui` green | only `.planning/` until Plan 03's code |
| 03 | `6af22174` | yes | `verify.repository_contracts` (157 tests), `verify.core` (1117 tests, docs clean), `verify.ops_ui` green | `.planning/` only until the review-fix round |
| review fixes | `ea9c859c` | yes | `verify.core` green (1158 tests, docs clean); cheap checks green | `.gitignore` only (`21f13530`), then `.planning/` |
| verifier | `21f13530` | yes | `verify.core` (1158 tests), `verify.repository_contracts` (157 tests), `verify.ops_ui` (2 + 329 tests), `verify.package`, CI Node step (123 + 33 tests), docs, format, credo: all green | `6744e0f8` (allowlist reason text, ROADMAP), `f2fb2929` (security audit): the allowlist is read only by `ui-tokens.test.mjs` (42/42 on `f2fb2929`); the full lanes were not repeated for a one-string change |

Since `6af22174`, `git diff --name-only` shows no change under `scrypath_ops/`, `lib/`, `mix.exs`, `mix.lock`, `test/release/` or `.github/`, so the `ops-ui` inputs are the same as when that gate ran green. Changes after it are in `dev/`, `scripts/ci/`, `examples/scrypath_ecommerce/`, brand tests and `CONTRIBUTING.md`.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (added lines in all phase files) | - | `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, `PLACEHOLDER` | none found | no debt markers introduced |

### Findings and classification

No blockers. Everything below is non-blocking.

| # | Finding | Class | Why not a blocker |
|---|---------|-------|-------------------|
| 1 | The SUMMARY receipts for `verify.repository_contracts`, `verify.ops_ui` and `verify.package` predate the nine review-fix commits, `verify.core` ran on `ea9c859c`, and the `.gitignore`-only commit `21f13530` had no receipt. GATE-02 says a stale receipt is a failed gate. | non-blocking, closed locally | I ran each of those lanes once on HEAD `21f13530` (table above) and all passed, so the exact final code SHA now has a green receipt for `core`, `package`, `repository-contracts` and `ops-ui`. The remaining item is the hosted exact-SHA run, already the `/gsd-ship` follow-up. |
| 2 | `stateEqual` is protected by tests only jointly with `hoverStateEqual` (the one state mutation changes both); dropping `stateEqual` alone stays green. Pre-existing coverage shape, not introduced here. | non-blocking | The real verdict still contains both terms and a state change fails the pair. Harden with a neutral-capture-only state mutation. |
| 3 | Sequencing conflict for Phase 188: its scope note deleted `brandbook/`, but `mix verify.ui_tokens` and `ui_tokens_contract_test.exs` (part of `repository-contracts`) read it and are retired in the first v1.47 phase. | **resolved** by `6744e0f8` | The ROADMAP Phase 188 scope note and exit check now say Phase 188 only removes documentation references and deletes or rewrites `prompts/scrypath-brand-book.md`; the directory is deleted in the first v1.47 cleanup together with `verify.ui_tokens` and its contract test. The `brandbook/` allowlist entry's reason now names that owner, and no `Phase 188 deletes` wording remains in ROADMAP, REQUIREMENTS, STATE or the allowlist. Minor residual: the ROADMAP "Deferred to v1.47" line lists retiring `verify.ui_tokens`, the mirror and the contract test but does not name deleting `brandbook/` itself or its `retire-last` prefix entry; the allowlist reason does. |
| 4 | The structural pair check is explicitly not font-invariant and geometry stays exact. Phase 187 swaps fonts (SKIN-02) and may add a visible dark-surface ramp border; both are likely to reject preservation pairs by design. Thresholds were calibrated on one recolor family. | non-blocking (forward flag) | Meets TOK-04 as written (calibrated accept and reject). Phase 187 planning should decide what the pair check is expected to prove across a font change. |
| 5 | The GATE-02 projection in `186-02-SUMMARY.md` predates the review fixes. My re-run shows one new 187-owned item: after the recolor, `app.css` holds fewer retired values, so Phase 187 must lower that entry's `max_hits` and `HITS_CEILING` in lockstep (SKIN-01/SKIN-05). | non-blocking | Still 187-owned; the guard fails loudly and says the number to use. |
| 6 | Unfixed review items (out of scope for the fix round): IN-03 the wrapper does not require the 17 planted/accept test names, so deleting them would keep CI green; IN-04 `dependency_options!/2` reports a keyword-only dependency such as `{:phoenix_storybook, github: "...", only: [:dev, :test]}` as a violation (latent false positive, guard is vacuous today); IN-06 `PENDING_CEILING`, `HEX_OUTSIDE_CEILING` and `ALLOWLIST_CEILING` do not fail when the live count drops below them (only `HITS_CEILING` does); IN-01 `write!/3` validates inside its write loop and follows symlinks; IN-02 the license string hard-codes commit `ced7c40e`; IN-05 `relative_luminance/1` is dead code; IN-07 built-CSS parity covers only `--color-*` and `--ops-*`. | non-blocking | Each is advisory and none weakens a success criterion. IN-03 and IN-06 are worth taking in the next test-only commit before Phase 187 flips rows. |
| 7 | `ui_tokens_contract_test.exs` keeps two retired hexes (lines 425-426). | non-blocking | See SC3 note: they pin the retired directory, not a live token. |

## What is not proven

- **Hosted CI has not run.** Nothing is pushed. No required check has run on a hosted runner for this branch. Checks that depend on the hosted environment (clean checkout, Node and git versions, cache keys, `ops-ui` Postgres service) are untested there.
- **`backend (required)` and `ecommerce-mounted (required)` were not run.** Neither is touched by this phase's files in a way I can see, but both need Meilisearch or Docker and browser lanes that I did not start. The other four required lanes (`core`, `package`, `repository-contracts`, `ops-ui`) ran locally once each on HEAD and passed; these are local runs, not hosted ones.
- **My recolor projection did not apply the DTCG mirror remap** (the `ops.*` subtree and example theme JS under the retired directory) and did not rebuild the built CSS, so the mirror-related failures are attributed to Phase 187 by their messages, not shown to clear after a remap. Because the contrast checker stops at its muted-alpha guard, contrast results under the new palette are not evaluated by this phase.
- **The online re-download check against the live Pages URL was not run** (by design it is a maintainer action, not a gate). The local archive I compared against matches the pin.
- **Rendered output, aesthetic quality and independent review are not claimed.** No UI changed in this phase.

## Human Verification Required

None. Nothing in this phase is impossible to automate, and the zero-human-verification rule holds. The review-fix note that WR-05's thresholds are "a judgment call" is covered by planted tests that fail when each signal is removed or loosened, so it is not carried as a human item.

## Gaps Summary

No gaps. All five roadmap success criteria and all nine requirement IDs are met on the code at `21f13530`, and still hold on `f2fb2929` (the later changes are an allowlist reason string, a ROADMAP note and the security report). The non-blocking findings above should be handled as follows: take 2, 5 and the IN-03 and IN-06 items in the Phase 187 planning or a small test-only commit; settle finding 4 when planning Phase 187; finding 3 is resolved (optionally name the `brandbook/` deletion in the ROADMAP "Deferred to v1.47" line); close the hosted gap (finding 1) with the exact-SHA run of all six required checks when the branch is pushed.

---

_Verified: 2026-11-19T05:58:00Z_
_Verifier: Claude (gsd-verifier)_
