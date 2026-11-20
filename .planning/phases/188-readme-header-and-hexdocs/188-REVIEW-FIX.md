---
phase: 188-readme-header-and-hexdocs
fixed_at: 2026-11-19T21:45:00Z
review_path: .planning/phases/188-readme-header-and-hexdocs/188-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
final_code_commit: 728d467e657be22365cf495716cfde4dee734c42
---

# Phase 188: Code Review Fix Report

**Fixed at:** 2026-11-19
**Source review:** `.planning/phases/188-readme-header-and-hexdocs/188-REVIEW.md`
**Iteration:** 1

**Scope (set by the caller):** WR-01, WR-02, and the third point of IN-09 (`logo:` and `favicon:` raise when `brand/` is absent). The other IN-* findings and the other two points of IN-09 are out of scope and untouched.

**Summary:**
- Findings in scope: 3
- Fixed: 3
- Skipped: 0

**Where this ran:** the main checkout on branch `feat/v1.46-188-readme-hexdocs`, as the caller directed (no other agent was running, and a hand-rolled worktree has no `deps/` or `_build/` to run the gates). No worktree, temporary branch or recovery sentinel was created. Every verification number below came from that checkout, so it is reproducible from the tree you are looking at.

## Fixed Issues

### WR-01: Retained ExDoc operator color fails WCAG AA on the new brand code background (light mode)

**Status:** fixed (measured, and confirmed in Chromium)
**Files modified:** `dev/docs/scrypath-exdoc.css`, `docs/releasing.md`, `test/release/package_metadata_test.exs`
**Commits:** `b2c34c33` (stylesheet, guide, derivation allowlist), `6318df77` (contrast test and planted failure)

**Applied fix:**
- One docs-owned rule in `dev/docs/scrypath-exdoc.css`, written for both `body ` and `body.dark ` like every other color rule (so it outranks ExDoc's own `.dark .makeup ...` rules and follows ExDoc's toggle), sets `color:var(--scrypath-doc-text)` on `.o`, `.ni`, `.nl`, `.dl` and `.err`.
- Color choice: `--scrypath-doc-text`, which is brand token `color.code.text-light` / `text-dark` (`#1E1220` on `#F0E9E6` = 15.06:1; `#F4EDF3` on `#110A14` = 16.94:1). I computed all six brand code and secondary candidates against both backgrounds. Comment (5.02:1 light) would also pass but makes operators look disabled, and keyword/atom colors would make operators look like keywords. Ink is the neutral choice and matches how the pinned book already colors function and module names.
- The derivation test (`docs_rules() == pinned derivation ++ additional rules`) now compares against an explicit, named `@additional_rules` block (the contrast rule and the dark-logo rule) instead of the logo rule alone. No comparison was loosened. The class-mapping test lists the contrast classes explicitly and asserts they stay disjoint from the pinned classes, so the addition cannot hide a changed mapping.
- New test over the BUILT ExDoc CSS plus the built docs-owned stylesheet: for every token class that occurs in a built code block (and every class the contrast rule recolors) it resolves the color the browser applies in each theme (property by property, in specificity order, with inheritance from the brand `pre code.makeup` rule, and the class's own background when ExDoc sets one) and requires at least 4.5:1. Non-vacuity: it asserts `k`, `o`, `p` and `s` spans exist in the build.
- Planted-failure self-check: this test file did not already use that pattern, but a second test removes the contrast rule from the stylesheet and requires the check to report failures (`o`, `ni`, `nl`, `dl` in light, `err` in dark) and to pass with the rule. It also pins the contrast helper against 21:1 (black on white) and the brand pair.
- `docs/releasing.md` records the exception to "token classes the book does not color keep ExDoc's own colors", and says to send new classes back to the brand book owner.

**Evidence:**
- Red before the stylesheet change: the new check reported `light .o #bc5400 3.97:1`, `.ni 3.97:1`, `.nl 3.99:1`, `.dl 3.97:1` and `dark .err #960050 on #1e0010 2.27:1`. The light numbers match the review exactly.
- Green after: `MIX_ENV=test mix test test/release/package_metadata_test.exs` runs 26 tests, 0 failures.
- Rendered check (Playwright Chromium, run once on a fresh `mix docs` build, not committed): `.o` computes to `rgb(30, 18, 32)` on `rgb(240, 233, 230)` with ExDoc set to light, and to `rgb(244, 237, 243)` on `rgb(17, 10, 20)` with ExDoc set to dark, with the operating-system scheme set both ways. Keyword color and block background were unchanged.

**Beyond the review (stated so you can disagree):**
- `err` was added. The review said dark mode passes for every class that occurs in the docs, but one `.err` span occurs (a shell line-continuation backslash in the `Mix.Tasks.Scrypath.Settings.HotApply` page, which the highlighter cannot lex), and ExDoc's dark lexer-error pair is 2.27:1. The new test would not have been honest without it.
- The override is written for both themes, because the stylesheet's own rule requires every color rule to exist for both. So `.o`, `.ni`, `.nl`, `.dl` and `.err` also lose ExDoc's Monokai colors in dark mode (pink operators, yellow delimiters become pale ink), and `.err` loses its red in light mode (it passed at 6.79:1 there). That keeps these tokens consistent with the brand-colored tokens around them, but it is a visible change you may want to review.

### WR-02: Built-docs output directory name is not unique across concurrent OS processes

**Status:** fixed
**Files modified:** `test/release/package_metadata_test.exs`
**Commit:** `23fe8137`
**Applied fix:** the directory name is now `scrypath-docs-<System.pid()>-<System.unique_integer()>`, as in `ui_contrast_contract_test.exs`. It is still created under `System.tmp_dir!()` (outside the repository) and still removed in `on_exit`. After the runs, no `scrypath-docs-*` directory remained in the temporary directory and `git status` showed no residue.

### IN-09 (third point only): `logo:` and `favicon:` raise ENOENT when `brand/` is absent

**Status:** fixed
**Files modified:** `mix.exs`, `test/release/package_metadata_test.exs`
**Commits:** `53bf4efc` (mix.exs), `728d467e` (test)
**Applied fix:** `docs/0` now adds `logo` and `favicon` through a small `put_if_file/3` helper only when the files exist, the same way the `assets:` mirrors tolerate a missing directory. I confirmed in `deps/ex_doc/lib/ex_doc/formatter.ex` that ExDoc copies both with `File.copy!/2`. The comment now says that only `assets:` degrades gracefully and that `logo:` and `favicon:` are added conditionally. A new test evaluates the real `mix.exs` in a subprocess from a temporary directory, first without `brand/` (neither option present) and then with the two brand files copied in (both present); it failed before the `mix.exs` change and passes after. The repository build is unchanged (the built-docs tests still check the favicon and logo bytes).

## Skipped Issues

None.

## Documented limits

- **Diff classes `gi` and `gr`:** ExDoc paints them below AA in light mode (2.90:1 and 3.49:1), but no built docs page uses them, so they are not recolored. The contrast test covers classes that occur in the build, so it will fail the moment a docs page adds a `diff` block, with the class and ratio in the message. Recoloring them to ink would erase the diff meaning, so that stays a decision for whoever adds such a block.
- **Brand pin send-back:** the review suggests sending these classes back to the brand book owner so the pin carries them and the derivation becomes "pin plus one rule". I did not edit `V1.46-PREP.md` or the playbook (outside the requested scope). The guide now says to do this when a new class is added.
- **Unpacked tarball, stylesheet link:** `before_closing_head_tag` still links `assets/scrypath-exdoc.css` when `dev/` is absent (the `dev/docs` mirror is skipped, so the link 404s). That is a harmless dead link, not an ENOENT, and is not part of the IN-09 point I was asked to fix.
- **Other IN-09 points** (maintainer prose in the shipped stylesheet header, light-only favicon trade-off) and IN-01 to IN-08 were out of scope and are unchanged.

## Verification

All on the final code commit `728d467e657be22365cf495716cfde4dee734c42`, in the main checkout, cheap checks first. The working tree had only the pre-existing `.planning/STATE.md`, `.planning/config.json`, `.planning/state.json` edits and untracked review artifacts (none staged or committed by me).

| Command | Result |
| --- | --- |
| `MIX_ENV=test mix test test/release/package_metadata_test.exs` | 26 tests, 0 failures |
| `mix docs --warnings-as-errors` | exit 0 |
| `node --test --test-reporter=tap examples/scrypath_ecommerce/ui-tokens.test.mjs` | 59 pass, 0 fail |
| `mix verify.brand` | ok (44 assets, 326773 bytes) |
| `mix format --check-formatted` | ok |
| `MIX_ENV=test mix credo --strict` | no issues (280 files) |
| `mix test --include docs_contract` on docs_contract, phase108, phase111, phase112 | 85 tests, 0 failures |
| `mix verify.package` | exit 0 (about 59 s) |
| `mix verify.core --exclude integration --exclude docs_contract` | exit 0; 5 properties, 1178 tests, 0 failures (103 excluded); Standard Maturity Gate PASSED |
| `git diff 140c25da -- brand/` | empty (the pinned book is untouched) |

Neither heavy gate needed escalated permission. `mix verify.package` left `scrypath-0.3.18/` in the repository root; I removed it. The seven older `scrypath-*/` directories predate this run (April to October) and are gitignored, so I left them.

Not run: `mix verify.repository_contracts` (not requested for this pass; Plan 02 ran it before these fixes, and none of these commits touch the files it reads other than the docs guide and tests).

## Commits

| Commit | Type | Content |
| --- | --- | --- |
| `23fe8137` | test | WR-02: process id in the built-docs directory name |
| `b2c34c33` | docs | WR-01: contrast rule in the docs-owned stylesheet, guide update, named additional-rules block in the derivation test |
| `6318df77` | test | WR-01: AA contrast check over the built CSS, with the planted-failure self-check |
| `53bf4efc` | docs | IN-09 third point: `logo` and `favicon` only when their files exist |
| `728d467e` | test | IN-09 third point: subprocess test for the docs config |

Final code commit: `728d467e657be22365cf495716cfde4dee734c42`. Only this report and `.planning/` bookkeeping follow it (checked with `git diff --name-only 728d467e..HEAD` after the report commit).

---

_Fixed: 2026-11-19_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
