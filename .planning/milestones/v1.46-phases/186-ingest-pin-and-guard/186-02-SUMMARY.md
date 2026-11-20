---
phase: 186-ingest-pin-and-guard
plan: 02
subsystem: token-guard-tests
tags: [tokens, token-map, parity, deny-list, allowlist, node-test, exunit, resolved-token-helper, recolor-projection, gate-02]

requires:
  - phase: 186
    plan: 01
    provides: brand/tokens.json pinned and verified offline (the source the token map resolves against)
provides:
  - "scrypath_ops/assets/css/token-map.json: 37 rows, per-theme disposition, applied flag, source or target"
  - "examples/scrypath_ecommerce/ui-tokens.test.mjs: 25 node:test cases (token parity, applied rows, built-CSS emissions, hex allowlist, retired-identity deny-list, planted and accept cases)"
  - "examples/scrypath_ecommerce/retired-identity-allowlist.json: 22 shrink-only, phase-tagged entries"
  - "Scrypath.TestSupport.UiTokens: resolved-token helper; three contract tests read live values"
  - "GATE-02 stop-and-decide record with the recolor projection (decision: go)"
affects: [186-03, 187, 188, 189]

actuals:
  # chars/4 over the added lines of the realized non-planning diff (73,737 chars). The plan's
  # estimate (85,000) was a work estimate that included reading and the projection; this is the
  # same scale the estimate names (estimateTokens over the diff), not a harness token count.
  tokens: 18400
  tasks: 3
  commits: 7

tech-stack:
  added: []
  patterns:
    - "Token map cells carry an applied flag, checked symmetrically; ceilings live in test source and only shrink"
    - "Planted and accept cases use small synthetic fixtures and take their limits as parameters"
    - "Deny values are stored without the leading hash and the retired directory string is joined at runtime"

key-files:
  created:
    - scrypath_ops/assets/css/token-map.json
    - examples/scrypath_ecommerce/ui-tokens.test.mjs
    - examples/scrypath_ecommerce/retired-identity-allowlist.json
    - test/support/ui_tokens.ex
    - test/mix/tasks/ui_tokens_helper_test.exs
  modified:
    - examples/scrypath_ecommerce/contrast-checker.mjs
    - test/mix/tasks/ui_contrast_contract_test.exs
    - test/mix/tasks/ui_tokens_contract_test.exs
    - scrypath_ops/test/scrypath_ops_web/surface_depth_token_contract_test.exs
    - .planning/reference/BRAND-ADOPTION-PLAYBOOK.md

key-decisions:
  - "Planted and accept cases use synthetic fixtures, not copies of the live files (found by the recolor projection)"
  - "Check functions take their ceilings as a parameter; the live tests use the shrink-only constants"
  - "The 64 percent muted-text alpha pins stay in the tests; the projection confirms Phase 187 owns them"
  - "Only the deny-set hexes in the Phase 132 checker fixture are built from a hash constant; non-retired fixture colors stay literal"
  - "GATE-02 decision after the projection: go"

requirements-completed: [TOK-01, TOK-02, TOK-03, GATE-02]

duration: 31min
completed: 2026-11-18
plan_head_before: 97f6ea8cc3097a81cc039f082c9ec49a699a55b6
plan_head_after: d9bd5542791b8748edf48a209acfdd1877d317ef
commits: 7
status: complete
---

# Phase 186 Plan 02: Token parity, deny-list and literal lifts Summary

**One Node test ties the two ScrypathOps theme blocks to the pinned brand tokens through a 37-row token map and keeps 30 retired colors out of the repository, three contract tests now read live tokens instead of pinned old colors, and a scratch recolor projection shows only Phase 187-owned failures (decision: go).**

## What this means in plain terms

Phase 187 changes the two theme blocks. Before this plan, that would have tripped hard-coded old colors in three tests and could have let old colors back in unnoticed. Now a recolor fails on named token-map rows and on things Phase 187 already owns (rebuilding the built CSS, flipping rows to applied, the muted-text alpha pins), and on nothing else. A retired color or the retired brand directory string in any file outside the allowlist fails the required `core` and `repository-contracts` jobs through the existing wrapper test, with no new CI step. No rendered UI changed: `app.css` and the built CSS are untouched.

## Accomplishments

- **Token map and parity test.** `token-map.json` has one row per theme property (37, identical key sets in both themes) with a per-theme disposition (adopt, derive, keep-platform, retire, local), an applied flag and a source token path or target hex. The test fails a missing row, an orphan row, a resolved-hex mismatch, a stale pending claim and a stale built-CSS emission, and passes the live tree. Pending cells: 38 of 74 (ceiling 38). Theme-block hex values outside the brand set: 34 (ceiling 34).
- **Built CSS freshness is token-level.** The three theme emissions in the tracked built CSS (system-dark, explicit dark, light) are compared to the source blocks over the 29 `--color-*` and `--ops-*` properties, including the nested `@supports` re-declaration of the muted text mix. No rebuild is needed or attempted.
- **Retired-identity deny-list.** One scan of `git ls-files --cached --others --exclude-standard` (no shell, files over 8 MiB throw, binaries skipped by a NUL sniff, symlinks not followed) for 30 retired hexes, the rgb and rgba triplets derived from them (comma and space forms), 8-digit hex with alpha, and the retired directory string, case-insensitive. The deny set and the new set (brand tokens plus declared targets) are asserted disjoint. Six planted failures (plus an allowlist-ceiling case) and three accept cases run through the same scan on a temp git tree.
- **Allowlist.** Seeded from a live scan with an empty list: 24 entries (23 files plus the retired directory prefix). The two `p186` entries were removed by the lifts, so the final count is **22**: 12 `p187`, 2 `p188`, 2 `p189`, 6 `retire-last` (each names an owner). The scan found exactly the 24 files the plan listed; no difference to explain. `contrast-checker.mjs` is not on the list.
- **Checker fixture neutralized.** The Phase 132 self-test fixture builds its retired hexes from a hash constant (runtime values unchanged; `--self-test` and the normal run both pass). One comment example in the same file also held a retired hex and was changed to a neutral one.
- **Three contract tests lifted.** The pinned old-color literals in `ui_tokens_contract_test.exs`, `ui_contrast_contract_test.exs` and `surface_depth_token_contract_test.exs` are gone. They read the live value from one named theme block and derive their mutation from it, and the surface test asserts a luminance order. Each still fails on its original mutation (the full suites pass, and a mutation probe on the surface test failed as expected before app.css was restored).
- **Recolor projection and GATE-02 record** below. Decision: go.

## Task Commits

| # | SHA | Label | What |
|---|-----|-------|------|
| 1 | `8cf4768a` | contract introduction | token map, token-parity test, ExUnit wrapper (Task 1) |
| 2 | `aa93fb51` | contract introduction | deny-list, allowlist, checker fixture neutralized, wrapper names (Task 2) |
| 3 | `ab728791` | lift A | helper plus `ui_tokens_contract_test.exs` |
| 4 | `6d6d50ca` | lift B | `ui_contrast_contract_test.exs`, allowlist entry removed |
| 5 | `37ff7d2e` | lift C | `surface_depth_token_contract_test.exs`, allowlist entry removed |
| 6 | `b58fd05b` | (does not touch the lifted files) | planted cases made self-contained, limits explicit (found by the projection) |
| 7 | `d9bd5542` | (planning only) | playbook S18 and T15 evidence |

**Tracer note.** Task 1 was proven end to end (map, Node test, wrapper, planted cases, live tree green, no rendered change) before Task 2 expanded the same test file.

## GATE-02 stop-and-decide (end of Plan 02)

This is the second consecutive evidence-only plan (Plan 01 was the first). The rule was decided in CONTEXT, so no user question is needed. The projection below is the evidence.

**Projection SHA:** `b58fd05b0ab6a0220edee0e92f30869246e76ac5` (the committed code the scratch copy was taken from). It is also `GATE_SHA`.

**Control (unrecolored copy): zero failures.** Contrast checker PASS; token test 25 of 25; three root ui tests with `--exclude contrast_child`: 19 tests, 0 failures; four ops regex tests: 24 tests, 0 failures.

**Recolor applied to the copy:** all adopt, derive and local cells of both theme blocks set to their resolved targets from `token-map.json` (27 properties per theme, the opaque muted value included, retire rows left), the `ops.*` subtree of the retired brand directory's DTCG mirror and its example theme JS remapped to the same values, committed in the copy so the deny scan sees it. The script and copy lived outside the repository and are removed.

### Projection harness

| What went wrong in the first control | Cause | Fix |
|---|---|---|
| `UiLiteralContractTest` "production command checks this checkout against fresh trusted history" failed in the control: `No such remote 'origin'` | The first copy was a bare `git archive` plus a throwaway `git init`: no remote and no history, but the literal policy fetches trusted history | Harness error, not a recolor effect. Rebuilt the copy as a shared clone of the committed code with the real origin URL (as the repo's own `copy_repository` helper does); control then fully green. Re-run on the final code SHA. |

### Projected failures

| Test | Message excerpt | Owner | Reason |
|---|---|---|---|
| `UiContrastContractTest` "token map parity and retired-identity guards pass" (wrapper) | the two Node cases below fail | SKIN-01 | The wrapper only reports the Node result |
| Node "live applied rows equal pinned brand hex and pending rows differ" | 34 x `stale pending claim: ... already equals <brand hex> but is marked pending` | SKIN-01 | Phase 187 flips each adopted cell to applied as it recolors (this is the designed handoff) |
| Node "live built CSS emissions equal source theme blocks" | 53 x `stale built CSS: <emission> --<prop> is <old>, source block has <new>` | SKIN-01 | Phase 187 rebuilds and commits the tracked built CSS with the recolor |
| `UiContrastContractTest` "live text and focus contrast passes AA" (and the CLI `node contrast-checker.mjs`) | `D-15 Guard 2: named muted token --ops-text-muted is referenced by ".ops-verdict__label" but no matching declaration exists in app.css` | SKIN-01 | The 64 percent muted alpha lockstep: opaque muted text replaces the alpha mix (also A11Y-01, no alpha on text). The checker stops at this guard, so AA pair results under the new palette are not evaluated here; that is A11Y-01 work |
| `UiTokensContractTest` "bounded validator rejects dark-only mapping gaps and CSS value drift" | `dark theme did not contain "64%, transparent"` | SKIN-01 | The same muted alpha pin, in the token validator's drift cases (also A11Y-01) |
| `admin_path_motion.spec.ts` | not run; 187-owned by assertion (SKIN-05) | SKIN-05 | Advisory Docker browser lane; asserts the glow that SKIN-05 retires |
| `admin_surface_depth.spec.ts` | not run; 187-owned by assertion (SKIN-05) | SKIN-05 | Advisory lane; pins the old dark surface and glow |
| `phase173_shell.spec.ts` | not run; 187-owned by assertion (SKIN-05) | SKIN-05 | Advisory lane; pins the old shell colors |

Passing under the recolor: the four ops regex tests (24 tests, 0 failures), the retired-identity scan and allowlist cases (the recolor leaves retired values in the allowlisted files, so no entry goes stale yet; Phase 187 removes entries as SKIN-05 deletes the retired code), the token-map parity case, the hex allowlist case, and the brand-documentation and example-JS parity asserts (they pass because the mirror remap was applied, which is Phase 187's remap).

**Old constants still present in the three advisory specs** (read-only grep on the real tree, each count must be at least 1): `admin_path_motion.spec.ts` 3, `admin_surface_depth.spec.ts` 4, `phase173_shell.spec.ts` 2. Same as at planning time.

**Limits of the projection.** It shows that no failure traces to a hex literal in test code and that each failure has a Phase 187 owner. It does not predict failures Phase 187 itself introduces (new components, new contrast pairs), and the AA pair results under the brand palette are masked behind the muted guard until that lockstep changes.

decision: go

Every failure has an owning Phase 187 requirement ID and none comes from a pinned literal in test code, so Plan 03 proceeds.

### Commits that touch the lifted files since 14bf9dca

Source: V1.46-PREP owner decision 4 (test edits for named token-map rows and a contract's first introduction may land in the same change). At most 3 commits rewrite pinned literals.

| SHA | Label |
|---|---|
| `8cf4768addecba1aa54d654aaf2f85c442f459f1` | contract introduction (adds the wrapper test to `ui_contrast_contract_test.exs`) |
| `aa93fb51f36b234e7802eb94ab2cb3aa6c96f3e6` | contract introduction (extends the wrapper's required test names) |
| `ab72879109186a815aa5a0d871e9bd8e4d95e2f7` | lift (A) |
| `6d6d50caf29a141c0104a0107f72ccffdb7907d6` | lift (B) |
| `37ff7d2e88cb1fcdc3d1706a193121d9b1d74769` | lift (C) |

Three lifts, two contract introductions. Each lift's `git show --stat` lists only files under `test/`, `scrypath_ops/test/` and `examples/scrypath_ecommerce/` (test and test data).

## Verification and gate receipts

**GATE_SHA = `b58fd05b0ab6a0220edee0e92f30869246e76ac5`**, the last commit that touches non-`.planning/` files. Each full gate ran once on it. Escalated permission was used for the fetch-dependent runs and was not denied.

| Command (with `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5`) | Result |
|---|---|
| `node examples/scrypath_ecommerce/contrast-checker.mjs` and `--self-test` | pass (`Contrast check: PASS`, `self-test passed`) |
| `node --test --test-reporter=tap examples/scrypath_ecommerce/ui-tokens.test.mjs` | pass: 25 tests, 0 fail, 0 skipped (0.5 s wall) |
| four ops regex tests from `scrypath_ops/` | pass: 24 tests, 0 failures |
| `MIX_ENV=test mix test` on the three root ui tests plus `ui_tokens_helper_test.exs` with `--exclude contrast_child` (at lift B and C) | pass: 29 tests, 0 failures |
| `MIX_ENV=test mix test test/mix/tasks/workflow_wiring_test.exs test/mix/tasks/dependency_boundary_contract_test.exs test/mix/tasks/verify_capability_test.exs` on GATE_SHA | pass: 99 tests, 0 failures |
| the four `contrast_child` tests (nested `mix verify.repository_contracts`) at `37ff7d2e`, before the last code commit | pass: 4 tests, 0 failures, 189.9 s; covered again on GATE_SHA by the two gates below |
| `mix format --check-formatted` and `MIX_ENV=test mix credo --strict` on the touched Elixir files | pass |
| `mix verify.repository_contracts` on GATE_SHA | pass: 151 tests, 0 failures, 193.7 s |
| `mix verify.core --exclude integration --exclude docs_contract` on GATE_SHA | pass: format, workspace clean, compile with warnings as errors, credo, `mix test` (5 properties, 1111 tests, 0 failures, 103 excluded), docs with warnings as errors, no-optional-deps |
| `mix verify.ops_ui` on GATE_SHA (host Postgres, task-scoped database `scrypath_ops_test_186_02`, dropped afterwards) | pass: root boundary 2 tests; ops 2 doctests, 329 tests, 0 failures |

`git diff --name-only b58fd05b0ab6a0220edee0e92f30869246e76ac5..HEAD` lists only `.planning/` paths:

```
.planning/phases/186-ingest-pin-and-guard/186-02-SUMMARY.md
.planning/reference/BRAND-ADOPTION-PLAYBOOK.md
```

Task acceptance greps all hold: 37 rows; the retired-value greps on the new and neutralized files print 0; `app.css` and the built CSS are unchanged since the plan base (no rendered change); the three lifted files hold none of their old literals; helper module present once; allowlist count 22; every `retire-last` reason contains `owner: `.

## Blocked gates

None. The fetch-dependent runs (projection control with the trusted-history literal policy, the four `contrast_child` tests, `verify.repository_contracts`, `verify.core`, `verify.ops_ui`) used the escalated route AGENTS.md authorizes and ran. No Docker or Buildx step was needed, no Docker resources were created, and the only task-scoped resource (the Postgres database) was dropped.

## Playbook dispositions

- **S18 (decouple pinned old-value tests before the re-skin): built and refined.** Evidence and provenance added to `.planning/reference/BRAND-ADOPTION-PLAYBOOK.md`. The e2e RGB constants stay Phase 187-owned in the advisory lane, measured by the read-only grep above. Refinements: planted and accept cases need synthetic fixtures and explicit ceilings (the first projection pass showed two planted cases that copied live state would have broken on any recolor); a trusted-history contract needs a real clone as the projection harness; alpha-mix pins are the same class as color literals and fail exactly where the re-skin retires them.
- **T15 (token map with dispositions and an orphan-row rule): built and refined.** Implemented by Task 1. Refinements: the `applied` flag with a symmetric check (the map lands before the recolor), and token-level built-CSS freshness (a fresh Tailwind build is not byte-identical to the tracked file). Not built: generating the map (verify only, by decision).

## CI speed-win note (recorded, not implemented)

From the research, on the latest main push run, `repository-contracts` spends 575 of its 823 s in the four-file Node step (about 16 lifecycle tests at 30 to 36 s each plus one of 67 s). Still the candidate for a later CI change; nothing here touches CI. Measured this plan: the new token test costs 0.5 s wall (0.6 s through the wrapper) and adds no CI step. Locally, the sync part of `verify.repository_contracts` (187.7 of 193.7 s) is where the four `contrast_child` tests run, because each one starts a nested `mix verify.repository_contracts` (189.9 s when run alone).

## Decisions Made

- Synthetic planted fixtures and parameterized ceilings (see Deviation 1).
- The deny set is the 13 CONTEXT hexes, 5 live hexes the CONTEXT list missed and 12 warm-paper tier hexes (30), with rgb triplets derived in code; the tier-4 semantic fills stay off the list for Phase 187's `local` decision.
- Token-map `local` rows carry a target equal to today's value, because no brand fill exists for info, success, warning and error; Phase 187 decides local or retire.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Two planted token cases depended on live row state**
- **Found during:** the recolor projection (Task 3), not by the tests themselves
- **Issue:** "planted resolved-hex mismatch fails" and "valid fixtures pass" cloned the live theme blocks, token map and built CSS, and picked a pending row to claim as applied. After a recolor they failed for reasons that are not what they test, which would have shown up as Phase 187 noise.
- **Fix:** the planted and accept cases now build small synthetic themes, token map, brand tokens and built CSS; the checks take their ceilings as a parameter, so a planted or accept case never depends on how far a live ceiling has shrunk; added ceiling-breach cases for the pending, hex and allowlist counters. The live tests are unchanged.
- **Files modified:** `examples/scrypath_ecommerce/ui-tokens.test.mjs`
- **Commit:** `b58fd05b`

**2. [Rule 3 - Blocking] The projection control failed on a bare archive copy**
- **Found during:** Task 3 control run (see the harness table). Fixed by using a shared clone with the real origin URL.

**3. [Rule 2 - Missing critical functionality] Small hardening in the guard**
- The hex pattern also catches 8-digit hex (a retired color with an alpha suffix), the rgb pattern uses alternatives instead of overlapping quantifiers (linear time), symlinks and non-regular files are not followed, and the allowlist check rejects duplicate entries, entries with neither or both of `path` and `prefix`, and entries under an exempt path. All inside the planned test file; each has a planted or live check.

**Form differences, no behavior change:**
- Added `test/mix/tasks/ui_tokens_helper_test.exs` (not in the plan's file list) to test the helper's behavior on neutral fixtures and the live stylesheet; it was committed with lift A.
- The dark secondary-content mutation gives the label the same color as its own fill (ratio 1) instead of a pinned `#333333`, so it fails below 4.5 whatever the palette is.
- Only the deny-set hexes in the checker fixture were converted to hash-constant interpolation; the non-retired fixture colors stay literal.
- `ALLOWLIST_CEILING` was 24 after Task 2 and 22 after the lifts, as planned.

## Known Stubs

None.

## Threat Flags

None beyond the plan's register. T-186-07 to T-186-12 are mitigated as planned: the deny scan runs in the required wrapper; the three ceilings and the allowlist rules make growth a visible edit; linear patterns and the 8 MiB throw cover scan cost; `execFileSync` with `-z` and no shell is used (acceptance greps hold); the applied check is symmetric; and the guard source holds no retired value. The scan only reads repository files and spawns `git`; it adds no network surface.

## Self-Check: PASSED

- Files present: `token-map.json`, `ui-tokens.test.mjs`, `retired-identity-allowlist.json`, `test/support/ui_tokens.ex`, `ui_tokens_helper_test.exs`.
- Commits reachable from HEAD: `8cf4768a`, `aa93fb51`, `ab728791`, `6d6d50ca`, `37ff7d2e`, `b58fd05b`, `d9bd5542`.
- `STATE.md` and `ROADMAP.md` untouched; `.planning/config.json` and `.planning/state.json` not created or staged.
