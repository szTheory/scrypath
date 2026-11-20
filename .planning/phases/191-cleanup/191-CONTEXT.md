# Phase 191: Cleanup - Context

**Gathered:** 2026-11-20
**Status:** Ready for planning
**Mode:** Pre-seeded for `gsd-autonomous --only 191`. The discussion and research already happened upstream: [prep note D](../../research/v1.47-prep/D-verification-and-cleanup.md) (main source), [prep note A](../../research/v1.47-prep/A-scope-and-shape.md), and the gap-pass notes [E](../../research/v1.47-gap-pass/E-adversarial-review.md), [F](../../research/v1.47-gap-pass/F-autonomy-stalls.md) and [H](../../research/v1.47-gap-pass/H-wording-cleanup.md) (Phase 191 sections). Those notes ran the fan-out through the role lenses, an adversarial pass and primary sources. This file transcribes their decisions; nothing here was re-decided and nothing is to be asked of the maintainer. Where the transcription needed a call the notes did not make, it is marked "(consequence)" and explained.

<domain>
## Phase Boundary

The old identity's last code is gone and stays gone: the demo favicon is the pinned light favicon, the retired brand book directory's readers and data are deleted with the retired-identity allowlist ending empty, cheap static invariants and an unthemed-favicon tripwire guard what the re-skin promised, and `brand/tokens.json` is the named single token authority.

Test, tooling and asset work only. The one visible change is the demo storefront's tab icon colour. No library change ships (squash titles are `chore(...)` or `docs(...)`). At most 2 plans, neither evidence-only. Requirements: CLEAN-01..06 and the standing GATE-02. Also closes the Phase 191 half of SITE-03 (the three shared hexes).

Depends on Phase 190 landed on `main` and on Phase 189's removal of the two `p189` allowlist entries. Starts from fresh `origin/main`; no stacked PR.

</domain>

<decisions>
## Implementation Decisions

### Deletion chain and ratchet (CLEAN-01, CLEAN-02, CLEAN-03)
- **D-01: Three commits, in this order, each moving its allowlist entries and both ceilings in the same commit.** (1) Demo favicon. (2) The readers. (3) The data. Readers go before data because deleting the directory first breaks `repository-contracts` (186 verifier finding). Expected ceiling chain after Phase 189 has merged: start 5 entries / 197 hits, after commit 1 4 / 194, after commit 2 2 / 178, after commit 3 0 / 0 (`ALLOWLIST_CEILING` and `HITS_CEILING` in `examples/scrypath_ecommerce/ui-tokens.test.mjs`). The executing plan recomputes every number from the live `retired-identity-allowlist.json` on merged `main` and trusts the file, not these figures. A stale entry, a hit count below its ceiling, or a ceiling that differs from the sum of `max_hits` each fail the token test, so a mismatch shows locally in about 2 seconds.
  - Commit 1 removes the demo favicon entry (3 hits). Commit 2 removes the `dev/mix/tasks/verify/ui_tokens.ex` entry (1) and the `test/mix/tasks/ui_tokens_contract_test.exs` entry (15). Commit 3 removes the retired directory's prefix entry (177) and the `.github/workflows/ci.yml` entry (1).
  - Commit 3 also drops the retired directory from the `ops-ui-path` regex in `.github/workflows/ci.yml`. That regex edit is why the `ci.yml` entry goes stale in the same commit. `ops-ui` runs on this commit (it is a `ci.yml` change); that is expected.
  - Commits 2 and 3 may be one commit (also green; the split buys bisectability for one extra full-lane run). The three-step order is the default, not the only safe one. The plan picks the split unless a measured cost says otherwise.
- **D-02: The three shared hexes join the deny set in commit 3.** `d08e54`, `0c0f14` and `9aa4b6` also appear in the retired directory (4, 10 and 1 hits), so adding them earlier would push its exact prefix entry above `max_hits` and the ceiling is shrink-only (E finding 1). Phase 189 already put the rest of the old website palette in the deny set. Add the three to `DENY_HEX` in the same commit that deletes the directory. The Phase 189 website contract asserts them absent until then; once the deny set owns them, that interim assertion either goes or builds the values at runtime (consequence: a literal `"d08e54"` in a test file is itself a deny hit, so it would break the 0/0 end state).
- **D-03: Keep the deny-list, `RETIRED_DIR`, the `retire-last` tag and the allowlist file.** The deny-list and the directory tripwire are permanent: they stop the old identity coming back from old branches or sibling copy-paste. `RETIRED_DIR`, `ALLOWLIST_TAGS` (including `retire-last`) and the planted fixtures that use them stay in `ui-tokens.test.mjs`; an executor must not delete them as dead code once the allowlist is empty (E nit 20). The allowlist file stays with `"entries": []` (consequence: `checkAllowlist` and the live tests read it; the checker tolerates an empty list).
- **D-04: Phase 191 docs never spell the retired directory path.** Anything tracked outside `.planning/` (CONTRIBUTING, `DESIGN-TOKENS.md`, `docs/`, code comments, new test text) says "the retired brand book directory" and never writes the path with its trailing slash; the directory string is scanned case-insensitively in every tracked file not exempt (exempt: `.planning/`, `brand/BRAND.md`, `brand/brand.json`, the allowlist file). New test text builds the name at runtime, as `brand_pin_contract_test.exs` already does with `"brand" <> "book"`. The final commit passes the deny-list with zero allowlist entries. (`.planning/` files such as this one are exempt and may name it.)
- **D-05: The lost clean-clone baseline is covered by the hosted exact-head run; a class-level assertion map is still recorded.** Deleting `ui_tokens_contract_test.exs` removes the only `clean_status == 0` assertion (a clean clone passes `verify.repository_contracts`). The contrast child tests assert only `status != 0`, so a clone broken for an unrelated reason would pass them vacuously. Decision: accept the hosted `repository-contracts` run on the exact PR head as the replacement and add no new baseline assertion. Why: it is the same canonical command on a clean checkout and is already required on every PR; a local baseline would add another nested clone-and-verify run to the slowest required lane (about 911 s on a PR) for no extra proof, against the CI efficiency rule. The plan still records, in 191-01's summary, which deleted assertion class maps to which surviving check, because prep A requires every deleted assertion to map to a survivor or be marked "retired-book only, dropped". The map to carry (test names from `ui_tokens_contract_test.exs`):
  - DTCG structure, bounded-validator and `token_review` cases (about 14 tests) and the legacy `ops.*` mirror checks: dropped, retired-book only. Survivor for live-token truth: the parity, applied-row and built-CSS checks in `ui-tokens.test.mjs`, with `brand/tokens.json` hash-pinned by `brand_pin_contract_test.exs`.
  - "brandbook documentation separates the warm palette from the CSS-authoritative Ops mirror": dropped with the directory.
  - "canonical repository contracts pass clean copies and reject each independent token source mutation": the CSS-only mutation maps to the contrast child tests plus the planted cases in `ui-tokens.test.mjs`; the JSON-only mutation of the mirror is dropped (no mirror); the clean baseline maps to the hosted run (this decision).
- **D-06: What commit 2 removes (CLEAN-02).** `dev/mix/tasks/verify/ui_tokens.ex`; `test/mix/tasks/ui_tokens_contract_test.exs`; the `"test/mix/tasks/ui_tokens_contract_test.exs"` line in `@focused_tests` in `dev/mix/tasks/verify.phase99.ex`; the `"verify.ui_tokens": :test` line in the `preferred_envs` list in `mix.exs` (a `preferred_envs` entry, not an alias). `verify.phase99_test.exs` names only the contrast test, so it needs no edit. `Scrypath.TestSupport.UiTokens` (`test/support/ui_tokens.ex`) and `ui_tokens_helper_test.exs` stay: the contrast test uses them. After the commit a scan finds no reader of the retired directory outside the directory itself and `.planning/`.
  - (consequence, found in research, not in the requirement text) `test/release/package_contents_test.exs` pins `later_hidden = [Mix.Tasks.Verify.UiTokens]` and asserts at least 53 verifier modules (55 today). Deleting the task breaks the first and leaves a margin of 1 on the second. Commit 2 removes the `later_hidden` list and its comment and leaves the Phase 183 identity assertion otherwise intact; the `>= 53` floor stays as is (no lowering to make room).
- **D-07: CLEAN-01, the demo favicon.** Replace `examples/scrypath_ecommerce/priv/static/favicon.svg` with a byte copy of `brand/assets/icon/favicon-light.svg`. Add a root-level ExUnit test in `core` (it reads `brand/`, so it lives in the root `test/` tree, not the demo project and not the ops-ui lane: `ops-ui-path` does not include `examples/`, and the demo suite is in no required lane) asserting the two files are byte-identical. The demo's own `page_controller_test.exs` is untouched: it keeps comparing the served file to its priv copy. No Docker-side check is needed (the build context is the repo root and does not exclude `brand/`, but nothing depends on it). Visible effect: the demo tab icon changes colour; no preview is needed.

### Static invariants (CLEAN-04)
- **D-08: What is asserted, and on what.** In `ui-tokens.test.mjs`, on ops-authored source only: `scrypath_ops/lib` (`.ex` and `.heex`), `scrypath_ops/assets/js` excluding `vendor/`, and `scrypath_ops/assets/css/app.css`. Never the tracked built CSS (`scrypath_ops/priv/static/assets/css/app.css`), `scrypath_ops/assets/vendor/`, or demo host CSS. Five invariants, each with a planted failing case and an accept case, no new gate:
  1. Every resolved `font-size` is at least 12 px. `var(--text-*)` chains resolve through the custom properties; `rem` and `px` literals are converted (16 px per rem); `inherit` passes; percent, `em`, `calc(` and `clamp(` values are rejected with a clear message (they fail closed rather than being resolved).
  2. No `text-[` length arbitrary value. Match only `text-\[(\d|calc|clamp|length:|min|max)` so `text-[var(--color)]` and colour forms are not false positives.
  3. No `uppercase` class and no `text-transform: uppercase`. Match the class as a whole token (`(?<![\w-])uppercase(?![\w-])`) and the CSS as a declaration, never as a substring (`upcase_first` is fine).
  4. No whole-word `infinite` (`\binfinite\b`).
  5. No `size: :xs` caller (a call with `size: :xs` or `size={:xs}`; the `attr(:size, ... values: [:xs, :sm, :md])` declarations and the `size == :xs && "btn-xs"` branch in `ops_ui.ex` are not callers).
- **D-09: The false-positive trap list (H-9).** Each trap needs a handling and an accept case. (a) Built CSS has 3 `infinite` (daisyUI `progress`, `skeleton`), `font-size: 80%` and `75%`, and `btn-xs` at 11 px; `assets/vendor/daisyui.js` has `infinite` too; scanning any of them fails today, hence source-only scope. (b) `/infinit/i` would match the `:infinity` atoms at `result_ui.ex` and `search_live.ex` (`limit: :infinity`); use the whole-word match. (c) Prose in comments and docstrings that says "no uppercase" or "infinite" would trip a text scan; strip comments (`/* */`, `#`, `<%!-- --%>`, `//`) or scope the class check to `class=` attributes and CSS declarations. The accept cases include a comment, an `:infinity` atom and an `inherit` value. (d) `font: inherit` appears three times in `app.css` and `font-size: inherit` twice: all accepted. (e) The resolver must handle the existing chains (`--text-ops-xs` and `--text-ops-sm` are `0.75rem`, body `0.875rem`, one literal `0.875rem`). (f) Demo host CSS is outside "ops-authored source"; the docs line says so.
- **D-10: Floor raise and new tests are one commit.** New tests use a literal `test("...",` at line start so the wrapper counts them. In the same commit raise `@min_token_test_calls` in `test/mix/tasks/ui_contrast_contract_test.exs` (53 today; raise by the number of `test("...",` calls the commit adds, counted from the file) and add each new "live ..." test name to `@token_test_names`, so renaming a live test cannot pass on count alone. Reason (H-12): the snapshot-based child tests clone committed HEAD and overwrite only five working-tree files, so an uncommitted floor raise runs against HEAD's older token test and passes for the wrong reason. Commit the token tests and the floor raise together before the snapshot gate.
- **D-11: Docs say what this proves.** `CONTRIBUTING.md` (the token and deny-list ledger row) and `scrypath_ops/assets/css/DESIGN-TOKENS.md` (Typography section) say these invariants check source declarations, not rendered size. Known hole stated plainly: a caller-supplied variant that emits daisyUI `btn-xs` (11 px) is only caught by the `size: :xs` caller check and by the browser spec on the advisory lane; computed size stays browser-only. No spec is promoted to a required lane (REQUIREMENTS Out of Scope).

### Favicon tripwire and consumer scan (CLEAN-05)
- **D-12: Tripwire.** A test in `test/mix/tasks/brand_pin_contract_test.exs` (the `core` lane, hash-guarded, reads only `brand/`) fails if the pinned `brand/assets/icon/favicon.svg` contains `<style`, `fill=`, `currentColor` or `prefers-color-scheme`. Its message lists the workarounds to remove: the `mix.exs` favicon comment and `put_if_file(:favicon, ...)` line, `test/release/package_metadata_test.exs`, `scrypath_ops/test/scrypath_ops_web/reskin_static_contract_test.exs`, the demo favicon (CLEAN-01), `docs/releasing.md`. It fires on the `mix brand.update` that picks up an upstream fix, which is intended.
- **D-13: Consumer scan.** A scan in `ui-tokens.test.mjs` (it already has `listRepoFiles` over tracked plus untracked-not-ignored files, the exempt-path set, binary handling and `makeTree`; it runs in `core` and `repository-contracts`) fails if any file outside `brand/`, `.planning/` and `dev/mix/tasks/brand/update.ex` contains the path `icon/favicon.svg` or has the same bytes as the pinned file. Bytes, not names: ops, the demo, `scrypath_ops/priv/static/favicon.svg` and the website all legitimately serve a file NAMED `favicon.svg` whose bytes are `favicon-light.svg`. Planted cases: a text reference and a renamed byte copy. Accept case: `favicon-light.svg` served under the name `favicon.svg`. Today no file outside `brand/` matches by bytes (sha256 of the pinned file is `16a86401dcf480f7de851ab788ab3b9d60a7ae00ae95d81390ef1cda970e6a4f`, 891 bytes) and `dev/mix/tasks/brand/update.ex` is the only outside text reference.
  - (consequence) The tripwire test and the scan's own source must not contain the literal path either, or the scan fails on itself and the requirement's exemption list (which names only `brand/`, `.planning/` and the updater) would need a self-exemption. Build the needle at runtime in both files (for example `"icon/" + "favicon.svg"`), the same way the guard builds retired values and the retired directory. Do not widen the exemption list.
  - Built website output is not tracked, so the Phase 189 static contract owns it; CLEAN-05 claims only the repository.
  - Do not put either check in the ecommerce Mix project or an ops test: the demo suite is in no required lane, `ops-ui` is path-scoped without `examples/`, and a Docker-side check has no `.git`.
- **D-14: The upstream defect report is drafted text in the phase record, not a gate.** The draft (wording in prep D item 5, copied into 191-RESEARCH.md) goes into the Phase 191 record (the 191-02 summary or verification file). Filing it in `szTheory/scrypath-brand` needs the maintainer's account and never blocks the phase. No `gh issue create` is run.

### Ledger and token authority (CLEAN-06)
- **D-15: CLEAN-06 ledger rewording.** In `CONTRIBUTING.md`, identify rows by gate name, not by line number (Phases 189 and 190 insert rows):
  - "Token parity and retired-identity deny-list" row: the deny-list and the directory tripwire are permanent (deleted only if `brand/` stops being vendored); the parity half stays while `app.css` is a hand-kept projection of `brand/tokens.json`, the single token authority; churn is one token-map row per changed theme property. Remove the literally-true-but-wrong "delete once the allowlist holds no `retire-last` entries" and "once the token map has no pending rows" triggers and the stale "the allowlist only shrinks" churn clause.
  - Budget sentence: names v1.47 or states the cap of 12 carries forward (today it names only v1.46). The cap itself does not change.
  - "ScrypathOps re-skin component contract" row: trigger says v1.48, not v1.47.
  - "Offline brand pin" row (the row the requirement calls the favicon row): its churn text, "None unless brand assets change", names the new favicon tripwire, which fails on the refresh that picks up an upstream favicon fix.
  - No cell contains a pipe (`workflow_wiring_test` splits cells on it and requires five). `workflow_wiring_test` stays green: header exactly `Gate | Enforced by | Runs in | Deletion trigger | Expected churn per UI PR`, 1 to 12 rows, the first backticked path in "Enforced by" exists, the line reads exactly `Budget used: <rows> of 12.`, and the five mandatory Phase 186 gate files stay named. The token row cannot be deleted by rewording. Do not hard-code "8": read the live row count (Phase 189 adds row 9 and Phase 190 may add or extend one).
  - Lands in or after the commit that empties the allowlist (the reword may only claim "no `retire-last` entries" once that is true).
  - `CONTRIBUTING.md` is an ExDoc extra: do not name any `Mix.Tasks.Verify` module in it (a package test fails on that), and keep `mix docs --warnings-as-errors` clean.
- **D-16: `brand/tokens.json` is named as the token authority in `scrypath_ops/assets/css/DESIGN-TOKENS.md`.** One sentence in the "Brand colors" section (which already mentions the file at about line 31) saying it is the single token authority and `app.css` is a hand-maintained projection checked both ways by `ui-tokens.test.mjs`. No generator, no new test (prep D item 3: single-source in authority with a checked projection).

### Guardrails and protocol (GATE-02)
- **D-17: Commit, then gate, per commit.** For each commit: run the cheap focused checks first (`node --test examples/scrypath_ecommerce/ui-tokens.test.mjs`, about 1.5 s; then `MIX_ENV=test mix test test/mix/tasks/ui_contrast_contract_test.exs test/mix/tasks/workflow_wiring_test.exs test/mix/tasks/verify.phase99_test.exs --exclude contrast_child`, plus any file the commit changed), commit, then run `mix verify.repository_contracts` once on the committed state. Some contracts clone HEAD, so an uncommitted fix cannot repair a clean-copy check of the previous commit; commit the fix before any rerun. The first `mix verify.repository_contracts` run uses the escalated permission up front (it writes the worktree `FETCH_HEAD`; a sandbox failure there is not behavioral RED). Run it in the background; it takes about 15 minutes. One full gate run per commit SHA, no stale receipt, no run from a dirty tree. Export `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5` for `mix`.
- **D-18: Whole CI Node step first when a fixture-copied file is touched.** A plan that touches `contrast-checker.mjs`, `app.css`, `contrast-pairs.mjs`, `brand/tokens.json` or `brand/brand.json` (the files `scripts/ci/ecommerce_lifecycle.test.cjs` copies) runs the whole CI Node step locally first. Phase 191 does not plan to touch any of them; keep the CLEAN-04 resolver inside `ui-tokens.test.mjs`.
- **D-19: No new required gate.** Budget stays within 12. CLEAN-04 and CLEAN-05 ride the existing token and brand-pin rows; CLEAN-01 rides `core`.

### Plan split
- **D-20: Two plans, neither evidence-only.** 191-01 is the deletion chain (D-01 to D-07) with the research-discovered consequences; its docs work is limited to keeping the retired path unspelled and the allowlist notes honest. 191-02 is the static invariants, tripwire, scan, ledger rewording and the `DESIGN-TOKENS.md` sentence (D-08 to D-16). 191-02 starts after 191-01's commit 3 so the reword can truthfully say the allowlist is empty.

### Verification rule
- **D-21: Executable assertions only.** Every success criterion is proved by an executable check (unit test, static contract, request or hash assertion, hosted CI at the exact head SHA) or is a recorded decision stated as such. No `<human-check>` block, no `verification: backstop` annotation, no "looks right" truth, no UAT file. Do not quote those two markers inside any PLAN file: `test/scrypath/no_human_gates_contract_test.exs` scans every incomplete `.planning/phases/**/*-PLAN.md` for them and fails `core`, and it also fails any VERIFICATION file whose status is `human_needed`. If `human_needed` ever appears, convert the item to a test and re-verify; do not choose "continue without validation". The phase record carries a "what this does not prove" line (see RESEARCH). Nothing claims aesthetic or independent-review approval.
- **D-22: No preview refresh and no `ui:review` run.** The demo favicon colour change is proved by byte equality, not by a capture. `UI-PREVIEW.json` is untouched here; the refresh is the first rendered-evidence phase of v1.48.

### Delivery
- **D-23: One non-draft PR, squash on green.** Branch from fresh `origin/main` after Phase 190 has merged. The PR is non-draft. The squash title is `chore(...)` or `docs(...)`, never `feat` or `fix` (a `feat` or `fix` on `main` opens a Release Please PR with misleading notes). Squash-merge yourself once the required checks are green on the exact head (AGENTS.md standing instruction). No merge yes. Hex releases remain the maintainer's separate explicit yes; none is planned.

### Claude's Discretion
- File and test names, helper structure, where the CLEAN-01 root test lives (default: `test/mix/tasks/brand_pin_contract_test.exs` beside the tripwire, since both guard consumers of the pinned favicons; a new small file under `test/` is equally fine as long as it runs in `core`).
- Commit grouping inside 191-02 (default: CLEAN-04 tests, floor raise and their doc lines in one commit; CLEAN-05 tripwire, scan and a second floor raise in another; CLEAN-06 reword, `DESIGN-TOKENS.md` sentence and the upstream draft in a third). Run the full `mix verify.repository_contracts` once on 191-02's final committed state rather than after every commit (one full run per SHA is a ceiling, not a quota), then rely on the hosted exact-head run.
- Whether the `font:` shorthand is rejected or only named in the docs line (see RESEARCH pitfalls): today only `font: inherit` appears.
- Whether to update the header comments in `ui-tokens.test.mjs` that describe the v1.46 deletion trigger.
- `[informational]` Run `mix verify.package` once after commit 2 because `mix.exs` changed (about 115 s); the hosted `package` job covers it either way.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `examples/scrypath_ecommerce/ui-tokens.test.mjs` (1848 lines): `listRepoFiles` (tracked plus untracked-not-ignored), `scanFiles`, `checkAllowlist`, `makeTree` and `scanTree` for planted trees, `anyFailure`, `isExempt`, and a CSS rule walker used by the spacing and selector ratchets. The CLEAN-04 and CLEAN-05 tests extend it.
- `test/mix/tasks/ui_contrast_contract_test.exs`: the ExUnit wrapper that runs the token test in `core` and `repository-contracts`; `@token_test_names`, `@min_token_test_calls` (53), and `copy_repository/0` (clone of HEAD plus five working-tree overwrites).
- `test/mix/tasks/brand_pin_contract_test.exs`: `@root`, test-owned `@expected_zip_sha256` and `@expected_assets_digest`, and the guard that builds `"brand" <> "book"` at runtime.
- `test/mix/tasks/workflow_wiring_test.exs`: the ledger parser (`budget_ledger_errors/1`, `@ledger_header`, `@phase_186_gate_files`).

### Established Patterns
- Ratchets are exact and shrink-only; every count change is a two-file edit (allowlist file plus test constant).
- Guard sources never contain a retired value: deny set stored without the leading hash, directory joined at runtime. The same rule now covers the favicon path.
- Planted failure plus accept case for every guard, on a temp git tree.

### Integration Points
- `.github/workflows/ci.yml` `ops-ui-path` regex (commit 3) and, after Phase 188.1, the `ecommerce-path` classifier; Phase 190 may also edit the `ops-ui-path` line. Rebase and re-read both before editing.
- `mix.exs` `preferred_envs`; `dev/mix/tasks/verify.phase99.ex` `@focused_tests`; `test/release/package_contents_test.exs`.
- `CONTRIBUTING.md` (ExDoc extra) and `scrypath_ops/assets/css/DESIGN-TOKENS.md`.

</code_context>

<specifics>
## Specific Ideas

- Cheapest checks first, in order: `node --test examples/scrypath_ecommerce/ui-tokens.test.mjs` (about 1.5 s, 59 tests today); the three root Mix tests with `--exclude contrast_child`; `MIX_ENV=test mix test test/release/package_contents_test.exs`; then `mix verify.repository_contracts` in the background; then the hosted run.
- A throwaway local dry run of the whole chain in a scratch copy of the repository (done in research, not committed) is a good way to see the ceilings before editing; keep the script out of the repo.
- Dirty `.planning/config.json` and `.planning/state.json` edits are not part of owned commits. After any `gsd-sdk state` verb, diff `STATE.md` and restore `milestone_name` and `status` if it was clobbered.
- `[informational]` Record the measured `repository-contracts` duration before and after this phase in `.planning/reference/CI-EFFICIENCY.md` (the deleted test ran three nested canonical runs), with no claim beyond what the hosted runs show.
- `[informational]` The `ui_phase` config flag is true, but this phase has no UI hint; do not run a UI design contract step for it.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap
- `.planning/REQUIREMENTS.md` - CLEAN-01..06, SITE-03 (the three shared hexes), GATE-02 (standing guardrails).
- `.planning/ROADMAP.md` - "Phase 191: Cleanup" detail, the v1.47 section (delivery, guardrails, run notes).
- `.planning/phases/191-cleanup/191-RESEARCH.md` - re-verified facts, drift flags, tasks for plan 191-01, pitfalls, validation architecture.

### Prep and gap-pass notes (decisions came from here)
- `.planning/research/v1.47-prep/D-verification-and-cleanup.md` - main source: cleanup chain, single token source, favicon tripwire, static invariants.
- `.planning/research/v1.47-prep/A-scope-and-shape.md` - shape, footgun 4 (a deleted assertion must map to a survivor), footgun 2 (the deletion trigger fires in 191).
- `.planning/research/v1.47-gap-pass/H-wording-cleanup.md` - H-6, H-9 to H-15, ordering summary (Phase 191 sections).
- `.planning/research/v1.47-gap-pass/E-adversarial-review.md` - findings 1 (shared hexes), 11 (CLEAN-05 scan exemption, upstream report), 12.
- `.planning/research/v1.47-gap-pass/F-autonomy-stalls.md` - sections 1 and 5 (autonomy stalls and the Phase 191 defaults).

### Code and docs
- `examples/scrypath_ecommerce/ui-tokens.test.mjs`, `examples/scrypath_ecommerce/retired-identity-allowlist.json`
- `test/mix/tasks/{workflow_wiring_test,ui_contrast_contract_test,verify.phase99_test,brand_pin_contract_test,ui_tokens_contract_test}.exs`, `test/release/package_contents_test.exs`
- `dev/mix/tasks/verify/ui_tokens.ex`, `dev/mix/tasks/verify.phase99.ex`, `dev/mix/tasks/brand/update.ex`, `mix.exs`, `.github/workflows/ci.yml`
- `brand/` (pinned; never edit), `CONTRIBUTING.md` ("Required-gate budget"), `scrypath_ops/assets/css/DESIGN-TOKENS.md`, `AGENTS.md`
- `.planning/reference/CI-EFFICIENCY.md`, `.planning/reference/BRAND-ADOPTION-PLAYBOOK.md` (update only if this phase proves or refines a rule)

</canonical_refs>

<deferred>
## Deferred Ideas

- Filing the upstream favicon defect (maintainer's step, outside the gate).
- Promoting a browser computed-style spec to a required lane (revisit only if a regression reaches `main` that only a browser spec would have caught).
- The palette input focus-outline defect (v1.49 screens work).
- Preview refresh and `ui:review` (first rendered-evidence phase of v1.48).
- Catalog, storybook, fixtures (v1.48); adopter features (v1.50); any Hex release (maintainer's separate yes).
- `[informational]` The README-header guard and URL switch for hex.pm belong to the next release PR, not this phase.
- `[informational]` Stale text in `.planning/reference/ROLLING-ROADMAP.md` (its Phase 191 row says the "mix alias" and "stays at 8 of 12"); this phase does not edit it.

</deferred>

## Superseded statements

These appear in older notes and are wrong or overridden for this phase. This file is authoritative.

- Prep D's ceiling chain 6/198, 4/182, 2/4 assumes the two `p189` allowlist entries still exist. After Phase 189 the start is 5/197 and the chain is 4/194, 2/178, 0/0 (D-01). (On a tree where Phase 189 has not landed, the old chain is also green; verified in research.)
- "Merge yes": prep A ("one merge yes for the 189 website PR", "191 needs none"), prep B and F's X14 list. There is no merge yes for any v1.47 phase. The PR is non-draft and is squash-merged on green under the AGENTS.md standing instruction; a Draft PR cannot be squash-merged. Releases and release-please PRs still need the maintainer's explicit yes.
- Prep D placed the `DESIGN-TOKENS.md` sentence and the ledger wording in plan 1. The roadmap and H put the reword in or after the allowlist-emptying commit; D-20 places them in 191-02.
- Prep D's tripwire (`<style` and `fill` only) is widened by CLEAN-05 to `currentColor` and `prefers-color-scheme`.
- Prep D's ledger oddity (both deletion triggers "now fire") is resolved by D-15: neither half is deleted.
- H-9 treats `1em` and `100%` as passes for the floor resolver; CLEAN-04 rejects every percent and `em` value. CLEAN-04 governs (D-08).
- F section 5 offers "one `gh issue create` or a committed draft" for the upstream report; CLEAN-05 says draft only (D-14).

## Open contradictions

Recorded, not resolved by editing REQUIREMENTS.md, ROADMAP.md, STATE.md or PROJECT.md. Each has the working resolution used above.

1. **CLEAN-02 omits a consumer.** `test/release/package_contents_test.exs` names `Mix.Tasks.Verify.UiTokens` (`later_hidden`) and asserts at least 53 verifier modules (55 now). Resolved in D-06 as a necessary consequence of deleting the task; the requirement text should list it.
2. **CLEAN-05's exemption list vs the guard's own source.** The requirement exempts only `brand/`, `.planning/` and `dev/mix/tasks/brand/update.ex`, but H-15 also exempted "the test file itself". Resolved in D-13: no self-exemption; the path is built at runtime in both the tripwire test and the scan.
3. **Budget count.** GATE-02, STATE and the ROLLING-ROADMAP Phase 191 row say 8 of 12, but Phase 189 takes row 9 (and Phase 190's COPY-03 may add or extend one). Resolved in D-15: read the live row count; `Budget used` must equal it.
4. **"Deletion chain with docs".** The roadmap says 191-01 includes docs, but grep finds no doc outside the retired directory that references the deleted readers; the ledger and `DESIGN-TOKENS.md` work is CLEAN-06 and sits in 191-02 (D-20), whereas prep D put it in plan 1.
5. **CLEAN-06's "favicon row".** No ledger row is named that. H-11 means the "Offline brand pin" row (churn "None unless brand assets change"). Rows are addressed by gate name because line numbers shift with Phases 189 and 190.
6. **Ceiling chain depends on Phase 189 having landed.** At research time (local `main` 85ca0cd1, `origin/main` e6fc151b) Phases 188.1, 189 and 190 had not landed and the allowlist is 7 entries / 201 hits; the chain from the live allowlist is 6/198, 4/182, 2/4, and with the two `p189` entries gone the expected chain above follows by subtraction (2 entries, 4 hits). The plan recomputes.
7. **Stale roll-forward text.** `ROLLING-ROADMAP.md` still says "mix alias" for what is a `preferred_envs` entry. REQUIREMENTS.md already says `preferred_envs`. No action in this phase.
8. **Interim website assertion.** SITE-03 has the Phase 189 website contract assert the three shared hexes absent "until Phase 191". If that assertion spells them literally it becomes a deny hit when they join the deny set (D-02). Whether 189 spelled them literally is unknown until it lands.

---

*Phase: 191-cleanup*
*Context gathered: 2026-11-20*
