---
phase: 186-ingest-pin-and-guard
plan: 01
subsystem: brand-pin-tooling
tags: [brand, pin, sha256, elixir, mix-task, zip, offline-verify, exunit, req-test]

requires:
  - phase: 185
    provides: preservation specs and the green-main release train this phase guards
provides:
  - "brand/ (38 files) and scrypath_ops/priv/static/assets/fonts/ (6 files): the 44 adopted brand files, 326,773 B, byte-pinned"
  - "brand/brand.pin.json: zip sha256, size, entries, declared uncompressed total, brand commit, per-asset path/source member/sha256/size/license/role/kind"
  - "mix verify.brand: offline, merge-blocking verify of the pinned tree (closed owned directories, dotfiles and symlinks refused, active-content scan)"
  - "mix brand.update: the only place that touches the network; capped download, in-memory :zip, allowlisted writes, online re-download check"
  - "test/mix/tasks/brand_pin_contract_test.exs: 55 tests, test-owned @expected_zip_sha256, tamper and refusal cases, Hex files guard"
affects: [186-02, 186-03, 187, 188]

actuals:
  tokens: 76600
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Verify task shape: use Mix.Task, public @doc false check!/1 for tests, preferred_envs :test entry"
    - "Pin refusal order: caps before pin-match checks, size then sha256 before the zip parser sees bytes"
    - "Write paths come from the task's own allowlist, never from archive entry names"

key-files:
  created:
    - dev/mix/tasks/brand/update.ex
    - dev/mix/tasks/verify/brand.ex
    - test/mix/tasks/brand_pin_contract_test.exs
    - brand/brand.pin.json
    - brand/BRAND.md
    - brand/brand.json
    - brand/tokens.json
    - scrypath_ops/priv/static/assets/fonts/ui.woff2
    - .planning/phases/186-ingest-pin-and-guard/deferred-items.md
  modified:
    - mix.exs
    - .planning/reference/BRAND-ADOPTION-PLAYBOOK.md

key-decisions:
  - "Both brand tasks carry a real @moduledoc instead of @moduledoc false, because the tooling-boundary test pins which Verify* modules are hidden from mix help"
  - "The 44-entry allowlist is a compile-time table of {member, kind, role} rows expanded to maps (path derived: fonts and OFL texts beside the ops fonts, the rest under brand/)"
  - "A refresh validates every flag before it reads the source or touches the network"
  - "The Pages zip is an acceptable fetch source because the pin binds the bytes; the committed assets, not the URL, are the source of truth"

patterns-established:
  - "Guard changes are proven by deleting each guard and watching a test fail (16 probes, recorded below)"

requirements-completed: [PIN-01, PIN-02, PIN-03]

coverage:
  - id: D1
    description: "Offline verify of brand/ and the shipped fonts against brand/brand.pin.json; closed owned directories; merge-blocking through the root suite in core"
    requirement: PIN-01
    verification:
      - kind: unit
        ref: "test/mix/tasks/brand_pin_contract_test.exs (describes: committed pin, offline verify tamper)"
        status: pass
      - kind: other
        ref: "MIX_ENV=test mix verify.brand -> verify.brand: ok (44 assets, 326773 bytes)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Update task refuses wrong size, sha256, entry count, uncompressed total, caps, bad names, missing members and oversize downloads; writes only allowlisted members; online check only here"
    requirement: PIN-02
    verification:
      - kind: unit
        ref: "test/mix/tasks/brand_pin_contract_test.exs (describes: update archive refusals, online re-download check)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Only the 44 adopted files (326,773 B) are committed; Hex files list has no brand entry; the real Hex archive has none"
    requirement: PIN-03
    verification:
      - kind: unit
        ref: "test/mix/tasks/brand_pin_contract_test.exs (describe: Hex package files)"
        status: pass
      - kind: integration
        ref: "mix verify.package on GATE_SHA a876a613 (110 tests, 0 failures; hex.build --unpack)"
        status: pass
    human_judgment: false

duration: 24min
completed: 2026-11-18
plan_head_before: 9cda456f125818e4681a8df07a47de3de5900049
plan_head_after: 94f21a6c8a0a7e4096494d89bc1e19b478780cf1
commits: 4
status: complete
---

# Phase 186 Plan 01: Brand pin Summary

**The 44 adopted brand files (326,773 B) are committed and byte-pinned against the zip sha256 `3fc6d80f...`, with an offline `mix verify.brand` that fails closed on every tamper case and a `mix brand.update` that refuses every wrong archive and writes only allowlisted paths.**

## Performance

- **Duration:** 24 min
- **Started:** 2026-11-18T21:41Z (local, from worktree creation)
- **Completed:** 2026-11-18T22:05Z (local)
- **Tasks:** 2
- **Files modified:** 49 (48 new, `mix.exs`), plus the two `.planning/` files below

## What this means in plain terms

Later phases can now trust the brand bytes. If anyone adds an unlisted file or a dotfile under `brand/` or the fonts directory, changes one byte of a pinned file, deletes one, or swaps one for a symlink, the offline check fails, and it runs in the required `core` job with no new CI step. Refreshing the brand assets is a deliberate maintainer action that refuses any archive that is not exactly the expected one. No rendered UI changed.

## Accomplishments

- `mix verify.brand` prints `verify.brand: ok (44 assets, 326773 bytes)` in about 0.4 s and rejects unpinned files (dotfiles included), changed bytes, size changes, deleted files, symlinked files and directories, disallowed extensions, a total over 400,000 B, and script, `javascript:`, event-handler, foreignObject, iframe, `@import`, remote `url()` and remote `href` content.
- `mix brand.update` refuses a wrong size or sha256, a wrong entry count (108) or declared uncompressed total (8,912,608), more than 200 entries, more than 16 MiB declared, an archive over 8 MiB, absolute, `..` and backslash entry names, missing or duplicated allowlisted members, garbage and truncated archives, non-https URLs and non-200 responses. A download over the cap is halted mid-stream (the test sends 16 MiB and asserts the task stopped after more than the 8 MiB cap but well before the 16 MiB sent).
- A valid archive with extra members (`evil.html`, `assets/index.html`, a preview image) writes exactly the 44 allowlisted paths plus the pin, and the tree it writes passes `verify.brand`.
- The online re-download check exists only in `mix brand.update` and is tested through `Req.Test` stubs; nothing reaches the network in tests or CI.

## Task Commits

1. **Task 1: end-to-end brand pin (tracer)** - `58f50389` (chore). Update task, verify task, 44 assets, pin, happy-path contract tests, `preferred_envs`.
2. **Task 2: tamper, refusal and Hex-package cases** - `0f4a3cdb` (test). Brings the contract test to 55 tests; update task validates refresh flags before touching disk or network.
3. **Deviation fix: moduledoc for the tooling-boundary test** - `a876a613` (chore). See Deviations.
4. **Playbook evidence and deferred item** - `94f21a6c` (docs, `.planning/` only).

The SUMMARY commit follows these four and is not counted in `commits:` (measured from `plan_head_before` at write time).

**Tracer feedback gate:** the task-1 slice was proven end to end before Task 2 expanded it: `mix brand.update` ran against the sha-verified archive, produced the tree and pin, and `mix verify.brand` plus the happy-path tests passed. TDD note: red was observed locally (4 of 5 happy-path tests failed while no pin existed) and then green; each task is one commit by instruction.

## Files Created/Modified

- `dev/mix/tasks/brand/update.ex` - `Mix.Tasks.Brand.Update`: allowlist, `verify_archive!/2`, `extract!/2`, `write!/3`, `fetch!/2`, `check_live!/2`
- `dev/mix/tasks/verify/brand.ex` - `Mix.Tasks.Verify.Brand`: offline verifier with public `check!/1`
- `test/mix/tasks/brand_pin_contract_test.exs` - 55 tests, test-owned `@expected_zip_sha256`
- `brand/` (38 files) and `scrypath_ops/priv/static/assets/fonts/` (6 files): adopted assets; `brand/brand.pin.json`: the pin
- `mix.exs` - `"verify.brand": :test` and `"brand.update": :test` in `preferred_envs`
- `.planning/reference/BRAND-ADOPTION-PLAYBOOK.md` - S13 and T15 evidence, change-log line
- `.planning/phases/186-ingest-pin-and-guard/deferred-items.md` - the pre-existing docs warning

## Verification and gate receipts

**GATE_SHA = `a876a61379685de2c1034e5781c188a24fac63ec`**, the last commit that touches non-`.planning/` files. Each gate below ran once on that SHA (or on an earlier SHA where noted as cheap per-task evidence).

| Command (all with `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5`) | Result |
|---|---|
| `MIX_ENV=test mix verify.brand` | pass: `verify.brand: ok (44 assets, 326773 bytes)`, 0.41 s wall |
| `MIX_ENV=test mix test test/mix/tasks/brand_pin_contract_test.exs test/mix/tasks/verify_capability_test.exs` | pass: 65 tests, 0 failures |
| `MIX_ENV=test mix test test/release/package_contents_test.exs test/mix/tasks/brand_pin_contract_test.exs test/mix/tasks/verify_capability_test.exs --warnings-as-errors` (after the moduledoc fix) | pass: 89 tests, 0 failures |
| `MIX_ENV=test mix compile --warnings-as-errors` | pass (also step 3 of `verify.core` on GATE_SHA) |
| `mix format --check-formatted` (whole repo), `MIX_ENV=test mix credo --strict` (whole repo, 278 files) | pass, no issues |
| `mix verify.package` on GATE_SHA | pass: exit 0, 110 release tests, 0 failures, `hex.build --unpack` clean (the package contains no `brand` entry) |
| `mix verify.core --exclude integration --exclude docs_contract` on GATE_SHA | **steps 1 to 5 pass** (format, workspace clean, compile, credo, `mix test`: 5 properties, 1100 tests, 0 failures, 103 excluded). **Step 6 `mix docs --warnings-as-errors` fails**, see Blocked gates. |
| `mix verify.ops_ui` on GATE_SHA (host Postgres, task-scoped database `scrypath_ops_test_186_01`, dropped afterwards) | pass: root boundary 2 tests, ops suite 2 doctests and 329 tests, 0 failures |

`git diff --name-only a876a613..HEAD` after the plan commits lists only `.planning/` paths:

```
.planning/phases/186-ingest-pin-and-guard/186-01-SUMMARY.md
.planning/phases/186-ingest-pin-and-guard/deferred-items.md
.planning/reference/BRAND-ADOPTION-PLAYBOOK.md
```

Task-1 acceptance greps all hold: 45 tracked files under the owned directories, no PDF/TTF/audio/video/`index.html`/`fonts.css` entry, pin holds the zip sha256 once, `@expected_zip_sha256` appears twice, both `preferred_envs` entries present, `git check-ignore -q` on the fonts directory exits 1 (not ignored), the font sha equals the pin. Task-2 acceptance greps hold: 47 literal `test "` lines, the four describe blocks, `Req.Test` used, 9 refusal lines in the update task, no `brandbook/` string in any of the three new files, no `brand` entry in the `files:` list.

**Guard mutation probes (16).** To confirm the tests are not vacuous, each guard was deleted in turn (closed-directory scan, size ceiling, active-content scan, symlink refusal, allowlist equality, per-file sha, entry-name checks, adopted-member check, entry cap, size cap, entry-count pin match, uncompressed cap, stream halt, archive sha, write allowlist, https-only) and the contract test run. Every deletion made at least one test fail, except deleting only the first-layer symlink refusal in `check_asset!`: the directory scan refuses the same symlink a second time, so one layer can be removed without a failure. Originals were restored.

## Blocked gates

- **`verify.core` step 6 (`mix docs --warnings-as-errors`) is red on this branch for a reason this plan did not introduce.** The two warnings are both `documentation references file "AGENTS.md" but it does not exist`, from `CONTRIBUTING.md` line 225. That link was added by `fa8affde`, which is on the feature branch but not in `origin/main` (`origin/main:CONTRIBUTING.md` has no `AGENTS.md` reference). This plan touches neither `CONTRIBUTING.md` nor the docs configuration, and the docs run produced no warning for the two new modules. Not fixed here (scope boundary); logged in `deferred-items.md` with three one-line fixes. It is not marked passed. The hosted `core` job will hit the same step once the branch is pushed, so it needs a fix before then. Plan 03 edits `CONTRIBUTING.md` and is a natural place for it.
- No escalated-permission gate was denied or needed. Plan 01 did not run `verify.repository_contracts` or any Docker/Buildx step (not in the plan's verification list); no Docker resources were created.

## Playbook dispositions

- **T15 (fetch safety for the update path): refined.** Evidence added to `.planning/reference/BRAND-ADOPTION-PLAYBOOK.md` with provenance. The update task downloads from the Pages URL, which is a generated, mutable archive with no tag, so T15's "pin URL must be the raw committed file at the commit (never a generated archive)" could not hold as written. The sha256, size, entry-count and uncompressed-total pin makes mutability detectable, and the committed assets, not the URL, are the source of truth. Built from T15: size then sha256 before parsing, mid-stream size cap, zip-slip refusal. Not built: cache-first and offline or skip modes (a local `--zip` copy stands in); zip64 and symlink entries are not rejected by name (the pinned archive hash keeps them out).
- **S13 (pin the signed-off book): build evidence added.** Difference recorded: the online re-download check is not advisory in CI, it lives only in the local update task (gate budget).
- **S18 (decouple pinned old-value tests before the re-skin): not exercised by this plan.** Plan 01 lifts no pinned literals and adds no old-value pin; its one hard-coded value is the brand zip hash, a test-owned constant by design (S13). Plan 02 owns the S18 evidence. No change to S18.

## Decisions Made

- Moduledocs on both tasks (see Deviation 1). `Mix.Tasks.Brand.Update` now appears in generated docs, as other documented dev verifiers do; no docs warning came from it.
- Allowlist as a 44-row table expanded to maps at compile time. `adopted_members/0` returns 44 maps with `path`, `member`, `kind`, `role`, `license` exactly as the plan's contract requires.
- Check order in `verify.brand` is: pin shape, per-asset path and extension, total-size ceiling, allowlist equality, per-file lstat/size/sha/active content, closed-directory scan. Extension and ceiling run before allowlist equality so a pin-plus-tree addition of a PDF or oversize file raises the named reason instead of the generic allowlist one.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The new `@moduledoc false` made an existing test fail**
- **Found during:** verification (`mix verify.package`)
- **Issue:** `test/release/package_contents_test.exs` ("documented verifiers do not become hidden from mix help") pins the exact set of `Mix.Tasks.Verify*` modules that have `@moduledoc false`. The plan told me to use `@moduledoc false`, which added `Mix.Tasks.Verify.Brand` to that set and failed the test (also part of the `core` suite).
- **Fix:** gave both new tasks a real `@moduledoc` rather than widening a test's pinned list. The plan's reason for `false` (avoid ExDoc link warnings) did not materialize: the docs run reported nothing for these modules.
- **Files modified:** `dev/mix/tasks/verify/brand.ex`, `dev/mix/tasks/brand/update.ex`
- **Commit:** `a876a613`

**2. [Rule 2 - Missing critical functionality] Extra hardening inside the planned modules**
- **Issue:** the plan did not spell these out, and each closes a gap in its own threat entries (T-186-01 to T-186-03): only `https://` URLs for `--url`; `--commit` must be a lowercase hex id; `--zip` is stat-checked against the size cap before it is read; `write!/3` raises if handed an entry that is not on the allowlist; a refresh validates all flags before reading the source or touching the network; `retry: false` on the download so a mismatched archive is never retried.
- **Commit:** `58f50389`, `0f4a3cdb`

**3. [Rule 1 - Bug] A test depended on leftover state**
- **Found during:** the guard mutation probes. The first "write! refuses an entry not on the allowlist" test looked for `escape.txt` in the shared system temp directory, so a probe that let the escape through left a file that failed later runs.
- **Fix:** the test now escapes into a throwaway sandbox directory and asserts the target root stays empty. I deleted the one stray file the probe left.
- **Commit:** `0f4a3cdb` (the final test file)

**Form differences, no behavior change:** the allowlist is a row table expanded at compile time rather than 44 literal maps; red-green was run locally but committed as one commit per task as instructed.

## Known Stubs

None.

## Threat Flags

None beyond the plan's register. The update task adds an outbound fetch by design; it is maintainer-only, https-only, size-capped, and covered by T-186-02 and T-186-03.

## Notes for later plans and CI

- Brand tests cost about 0.9 s (55 tests) in the root suite and `verify.brand` about 0.4 s; no new CI job or step was added. `verify.core`'s `mix test` step took 272 s locally and `verify.package` 52 s.
- The `repository-contracts` Node step (575 of 823 s in CI, from the research) is still the candidate speed win for a later CI change; not touched here.
- Phase 188 must derive a corrected copy of the ExDoc CSS elsewhere; `brand/assets/docs/scrypath-exdoc.css` stays byte-identical to the pin.

## Self-Check: PASSED

- Files present: `brand/brand.pin.json`, `dev/mix/tasks/brand/update.ex`, `dev/mix/tasks/verify/brand.ex`, `test/mix/tasks/brand_pin_contract_test.exs`, `scrypath_ops/priv/static/assets/fonts/ui.woff2`, `deferred-items.md`.
- Commits reachable from HEAD: `58f50389`, `0f4a3cdb`, `a876a613`, `94f21a6c`.
- `STATE.md` and `ROADMAP.md` untouched; `.planning/config.json` and `.planning/state.json` not created or staged.
