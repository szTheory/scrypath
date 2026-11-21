---
phase: 191-cleanup
plan: 02
subsystem: testing
tags: [source-invariants, favicon-tripwire, consumer-scan, ledger-reword, token-authority, gate-receipt]

requires:
  - phase: 191-cleanup
    provides: plan 191-01's deletion chain, the empty retired-identity allowlist and the live ledger row count
provides:
  - five source invariants on ops-authored source (12 px floor, no arbitrary text size, no uppercase, no infinite, no size xs caller), each with live, planted and accept tests
  - core-lane tripwire for the pinned unthemed favicon and a path-and-bytes consumer scan
  - CONTRIBUTING gate ledger reworded by gate name, brand/tokens.json named as the single token authority
  - gate receipt for the final code head and the phase record with the Post-ship evidence table
affects: [v1.48 rendered-evidence phase, the next brand refresh (the tripwire fires on it if upstream fixed the favicon)]

plan_head_before: ec5842cb1fad191115cf2e56733e22f0d02cc6b5
plan_head_after: 5cfcebd1bfc41536459f760aa8a92b603fea92e5

actuals:
  tokens: 14500   # chars/4 over the added lines of the four commits (code and docs 35426 chars, .planning records 22696 chars); code and docs alone are about 8900
  tasks: 4
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Guard files join the forbidden path at runtime from two pieces, so no self-exemption is needed"
    - "Planted sub-cases each get their own throwaway tree and file, with a per-file assertion that names the invariant"
    - "The count of literal test calls, the live names and the floor change in the same commit"

key-files:
  created:
    - .planning/phases/191-cleanup/191-GATE-RECEIPT.md
    - .planning/phases/191-cleanup/191-PHASE-RECORD.md
  modified:
    - examples/scrypath_ecommerce/ui-tokens.test.mjs
    - test/mix/tasks/ui_contrast_contract_test.exs
    - test/mix/tasks/brand_pin_contract_test.exs
    - website/scripts/build.mjs
    - scrypath_ops/assets/css/DESIGN-TOKENS.md
    - CONTRIBUTING.md
    - .planning/reference/CI-EFFICIENCY.md

key-decisions:
  - "Rejected the font: shorthand (other than font: inherit) as well as resolving font-size, because a shorthand carries a size a font-size scan cannot see"
  - "Reused the deny scan's file classification and decoding in the consumer scan, so UTF-16 text is read and an unreadable text encoding throws, as it does there"
  - "Ran each long gate once, on the final code head, after focused checks covered commits A and B"

requirements-completed: [CLEAN-04, CLEAN-05, CLEAN-06, GATE-02]

coverage:
  - id: D1
    description: "Five source invariants hold on ops-authored source and each fails its planted cases"
    requirement: CLEAN-04
    verification:
      - kind: unit
        ref: "examples/scrypath_ecommerce/ui-tokens.test.mjs (5 live, 5 planted, 5 accept and 1 scope test; 82 of 82 pass)"
        status: pass
      - kind: integration
        ref: "test/mix/tasks/ui_contrast_contract_test.exs wrapper: floor 76 equals the 76 literal test calls, the five live names are reported as passing"
        status: pass
    human_judgment: false
  - id: D2
    description: "The pinned unthemed favicon is guarded by a tripwire and has no consumer outside the exempt paths"
    requirement: CLEAN-05
    verification:
      - kind: unit
        ref: "test/mix/tasks/brand_pin_contract_test.exs#unthemed favicon tripwire (2 tests)"
        status: pass
      - kind: unit
        ref: "examples/scrypath_ecommerce/ui-tokens.test.mjs (live scan, planted text reference, planted renamed byte copy, accept case)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The ledger is reworded by gate name, brand/tokens.json is named in both docs, and the wiring test and docs build stay green"
    requirement: CLEAN-06
    verification:
      - kind: unit
        ref: "test/mix/tasks/workflow_wiring_test.exs (10 rows, Budget used: 10 of 12.)"
        status: pass
      - kind: integration
        ref: "mix docs --warnings-as-errors (exit 0)"
        status: pass
    human_judgment: false
  - id: D4
    description: "One repository_contracts run and one core run passed on the final code head"
    requirement: GATE-02
    verification:
      - kind: integration
        ref: "mix verify.repository_contracts on ce250655b7e90e737f3a922287114c402c8a3b9d (159 tests, 0 failures)"
        status: pass
      - kind: integration
        ref: "mix verify.core --exclude integration --exclude docs_contract on ce250655b7e90e737f3a922287114c402c8a3b9d (5 properties, 1183 tests, 0 failures)"
        status: pass
    human_judgment: false

duration: 1.5h (estimate, start not recorded)
completed: 2026-11-20
status: complete
---

# Phase 191 Plan 02: Guard what the re-skin promised Summary

**Five source invariants on ops-authored source, an unthemed-favicon tripwire with a path-and-bytes consumer scan, a ledger reworded by gate name that names brand/tokens.json as the single token authority, and one repository_contracts plus one core run that passed on the final code head `ce250655`.**

## Performance

- **Duration:** not timed from the start (an estimate is about 1.5 hours of wall time); the two long gates took about 5.5 and 6 minutes
- **Tasks:** 4 of 4
- **Files changed:** 7 code and docs files, 3 planning files (the receipt, the record and the CI-efficiency entry)

## Commits

| Task | Commit | SHA | What it did |
| ---- | ------ | --- | ----------- |
| 1 | A invariants | `9e450f13ed85038598c967f35740fec3bf856492` | five source invariants with 16 tests, floor 56 to 72, five live names, typography note |
| 2 | B tripwire and scan | `f09c3f150b116cc7b9572a59e724807c76258213` | favicon tripwire (2 ExUnit tests), consumer scan (4 Node tests), floor 72 to 76, one website comment reworded |
| 3 | C ledger | `ce250655b7e90e737f3a922287114c402c8a3b9d` | CONTRIBUTING rows by gate name, token authority sentence in `DESIGN-TOKENS.md` (final code head) |
| 4 | records | `5cfcebd1bfc41536459f760aa8a92b603fea92e5` | gate receipt, phase record, CI-efficiency finding 13 (`.planning/` only) |

`git rev-list --count ec5842cb..HEAD` measured 4 commits before this summary's own commit, from `plan_head_before` to `plan_head_after` above. Each code commit touched exactly the files its task lists (3, 4 and 2 files).

## Number chain

| State | Node token test calls (`^test("`) | `@min_token_test_calls` | live token names | allowlist entries and hits | `DENY_HEX` |
| ----- | --------------------------------- | ----------------------- | ---------------- | -------------------------- | ---------- |
| start (ec5842cb) | 56 | 56 | 7 | 0 and 0 | 51 |
| after commit A | 72 | 72 | 12 | 0 and 0 | 51 |
| after commit B | 76 | 76 | 13 | 0 and 0 | 51 |

The counts were read from the files after each edit (`grep -c '^test("'`), and the wrapper test confirmed the floor and that each live name is reported as a passing TAP line. Node reports 82 passing tests (76 literal `test("...",` calls plus 6 loop-generated planted forms).

## Gates (GATE-02)

| Gate | SHA | Result |
| ---- | --- | ------ |
| `mix verify.repository_contracts` | `ce250655b7e90e737f3a922287114c402c8a3b9d` | passed, exit 0, 159 tests, 0 failures, 23:48:08 to 23:53:33 UTC |
| `mix verify.core --exclude integration --exclude docs_contract` | `ce250655b7e90e737f3a922287114c402c8a3b9d` | passed, exit 0, 5 properties, 1183 tests, 0 failures, 23:53:42 to 23:59:46 UTC |
| `test/scrypath/no_human_gates_contract_test.exs` | after the records were written | passed, 2 tests |

Both long gates ran once each, from a clean tree, one after the other, in the background, unsandboxed from the first invocation (the first writes `FETCH_HEAD`), with no tracked edit while either ran. No failure, so no fix cycle and no rerun. The receipt is `191-GATE-RECEIPT.md`. `git diff --name-only ce250655..HEAD` outside `.planning/` is empty. The earlier readers-commit run (`f7515d5c`, plan 191-01) is carried in the receipt as an earlier run and not as evidence for the tested SHA.

Focused checks before each commit: the Node token test (82 of 82), the wrapper and `workflow_wiring_test` (92 tests), the brand pin, wrapper and website contract tests (103 tests), then workflow wiring, package contents and brand pin again for commit C (212 tests), `mix format --check-formatted` and `mix docs --warnings-as-errors` (exit 0).

## Invariant sub-case calibration

Each detector was removed or narrowed one at a time in a scratch copy of the token test (kept outside the repository and deleted after every run; nothing from these runs was committed) and the result was read from the TAP output. Every mutation failed the test that should catch it and named the sub-case:

- **Font-size floor.** A px multiplier change failed the px literal, the heex inline style and the JS string cases; a wrong rem factor failed the rem literal, the low var chain and the ex inline case plus the live floor test; a chain resolving to a pass failed the chain case and the live floor test; a missing custom property passing failed that case alone; an off-by-one floor failed the px literal case; the CSS shorthand detector off failed the low shorthand case alone; the style-attribute shorthand detector off failed that case alone; the inline font-size detector off failed the heex, ex and JS cases; the CSS font-size detector off failed all eight CSS font-size cases that existed when that run was made (the keyword and viewport cases came after it). Removing the percent, calc, clamp or em branch one at a time failed exactly that sub-case (with the generic fallthrough turned off).
- **Masked branch found and fixed.** With the generic fallthrough turned off and the explicit percent, em, calc and clamp branch intact, no test failed, so that fallthrough had no planted case of its own. Two sub-cases (a keyword value and a viewport unit value) were added; the same mutation then failed exactly those two.
- **Arbitrary text size.** Dropping each alternative (digit, calc, clamp, length:, min, max) failed exactly the matching sub-case (digit also fails the ex and JS string forms); a pattern widened to any `text-[` failed the colour accept case.
- **Uppercase, infinite, size xs.** Each detector turned off failed all of its planted forms; a substring uppercase match failed the upcase_first accept case and the live test; a prefix infinite match failed the infinity atom accept case and the live test; a size xs pattern that also matched declarations failed the attr accept case and the live test.
- **Scope.** Including built CSS, demo host CSS, vendored JS under `assets/js`, or dropping `app.css` each failed the scope test (and the live selection checks).
- **Comments.** Turning off each comment form (Elixir hash, HEEx, HTML, JS line, block) failed the comment accept test; dropping newlines when blanking failed the line-number assertion.
- **Consumer scan.** Byte-copy detector off, text-reference detector off, an exempt prefix without its slash, a widened exempt path, an includes-based exempt check, a prefix-only byte compare, a needle that also matches the light favicon name, and name-based reporting each failed the test that guards that behaviour (the lookalike prefix, the sibling updater path and the nested planning name are planted and reported).
- **Tripwire.** Doctoring the pinned favicon in a scratch run (a style element appended, restored byte-for-byte afterwards, `brand/` clean in `git status`) failed the tripwire with the workaround list in its message; the planted-marker test flags all five markers on a doctored copy and none on the real bytes.

## Deviations from Plan

None to the plan's behavior or scope. Notes, each a small addition or reading:

1. **[Rule 2 - correctness] Extra planted sub-cases.** The font-size planted test has 15 sub-cases, not the 9 listed: the plan's nine plus a missing custom property, an ex inline style, a JS string, a style-attribute shorthand, and the keyword and viewport cases that the calibration run showed were needed. Each CSS sub-case is its own tree because `app.css` is the only selected stylesheet; every sub-case still has its own file and a per-file assertion, and the test now collects all missed cases before asserting.
2. **Tripwire marker count.** The plan's predicate has five markers (it lists `fill=` and `fill:` separately) while the test text says four; the planted test covers all five, plus an upper-case `currentColor` and a mixed-case `prefers-color-scheme` for the case-insensitive comparison.
3. **Comment stripping in `.ex`.** An Elixir file can hold a `~H` template, so the HEEx and HTML comment forms are also blanked in `.ex` files, beyond the plan's per-kind rule. The `#` hazard the plan names (a hash inside a string hides the rest of that line) is documented in the test header and exercised by an accept case.
4. **Scan reuse.** The consumer scan calls the deny scan's `classifyFile` and `decodeFile`, so UTF-16 text is read and a text file with an unreadable encoding throws, as it already does there. It skips text over `MAX_SCAN_BYTES` instead of throwing, because the deny scan already fails first on such a file.
5. **Vacuity guards.** The live floor test also asserts the resolver reads the live custom properties (`var(--text-ops-sm)` resolves to 12), and the first live test asserts the selection holds `app.css` and an `.ex`, `.heex` and `.js` file, so no live invariant can pass on an empty scan.
6. **The upstream draft spells the unthemed path.** The phase record copies the draft from `191-RESEARCH.md` verbatim, and its title names the path. `.planning/` is exempt from both scans, and the plan asked for the verbatim copy. The draft is not filed.
7. **Slashless literal left in place.** `test/mix/tasks/brand_pin_contract_test.exs` near line 859 spells the old directory's name without its trailing slash, as plan 191-01 noted. Neither the deny scan nor the consumer scan flags it, so it was left alone and listed as an optional follow-up in the phase record.
8. **Tooling.** The worktree sandbox refused compound git commands that expand a shell variable or substitute output, so the `git grep` needle scan used a literal and the verify blocks ran piece by piece with the same checks. `mix docs` built `doc/` in the worktree; it is gitignored.

No auth gates, no architectural decisions, no outward commands (no push, PR, merge, dispatch or `gh issue create`).

## Known Stubs

None. No placeholder values, empty data flows or TODO markers were added.

## Threat Flags

None. This plan added test code, docs and planning records only; no endpoint, auth path, file access beyond reading repository files, or schema at a trust boundary. Threat register T-191-06 to T-191-11: the new scans use linear patterns, skip binaries, cap reads and compare sizes before bytes; the needle is built at runtime in both guards with no widened exemption; the upstream issue is drafted text only; the receipt is checked against the diff outside `.planning/`; T-191-10 is accepted and stated in the docs and the test header (source declarations, not rendered size).

## What this does not prove

Rendered size or appearance: the invariants read source declarations, and a variant that emits `btn-xs` (11 px) is caught only by the `size: :xs` caller check and by the browser spec on the advisory lane. That the pinned unthemed favicon was fixed upstream (the tripwire only fires when it changes). What the built website serves (the Phase 189 static contract owns that). Aesthetic approval, independent review, other browsers or a real screen reader: nothing was rendered or captured. The hosted lanes (`ops-ui`, `ecommerce-mounted`, `backend`, `package` and the exact-head `repository-contracts` run) are the Post-ship evidence in the phase record, not covered by the local receipt.

## Self-Check: PASSED

- Files present: `ui-tokens.test.mjs` (76 literal test calls, floor 76), `ui_contrast_contract_test.exs`, `brand_pin_contract_test.exs`, `website/scripts/build.mjs`, `DESIGN-TOKENS.md`, `CONTRIBUTING.md`, `191-GATE-RECEIPT.md`, `191-PHASE-RECORD.md` and the CI-efficiency entry.
- Commits `9e450f13`, `f09c3f15`, `ce250655` and `5cfcebd1` are ancestors of `HEAD`; the working tree was clean after each commit; `.planning/config.json` and `.planning/state.json` were never staged.
- `git grep` for the unthemed favicon path outside `.planning/`, `brand/` and the updater printed nothing; no file outside `.planning/` spells the old brand directory with its trailing slash.
