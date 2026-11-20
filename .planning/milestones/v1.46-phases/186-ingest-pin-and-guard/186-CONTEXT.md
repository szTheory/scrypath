# Phase 186: Ingest, pin and guard - Context

**Gathered:** 2026-11-18
**Status:** Ready for planning
**Mode:** Autonomous discuss. The decision fan-out for this phase was done in the milestone prep ([V1.46-PREP.md](../../research/brand-and-catalog/V1.46-PREP.md): seven research agents, role lenses, adversarial passes, primary sources). This file records the decisions the planner must follow. Nothing below is hard to reverse or a preference call, so nothing was asked.

<domain>
## Phase Boundary

Maintainers can prove the committed brand assets are exactly the pinned ones and that retired identity values cannot re-enter the repository, and the existing contract tests read live tokens so the Phase 187 recolor fails only on what Phase 187 owns.

Test and evidence only: no rendered UI change. At most 3 plans (progress guard). Requirements: PIN-01..03, TOK-01..04, GATE-01, GATE-02.

</domain>

<decisions>
## Implementation Decisions

### Brand pin (D6)
- Commit only adopted assets under a new `brand/` directory (about 330 KB): BRAND.md, brand.json, tokens.json, assets README, logo SVGs, icon files, README headers, avatar SVGs, the ExDoc CSS, the social card PNG, OFL texts. Skip PDFs, HTML books, motion, sounds, previews and TTFs. Do not vendor the brand HTML (inline script).
- `brand/brand.pin.json` records the zip sha256 `3fc6d80f597eb232b6c25d5929cbe9dbbe6503c346c1360456ea839f3334be88` (6,729,996 bytes, 108 entries), the brand repo commit `ced7c40e`, and per asset: path, source member, sha256, size, license, role, kind. Owned directories are `brand/` and `scrypath_ops/priv/static/assets/fonts/`, closed, dotfiles included.
- The zip is available at `/private/tmp/claude-501/-Users-jon-projects-scrypath/e3f4fd1b-7d2d-43c7-a92e-8fdf9232a7f3/scratchpad/scrypath-brand.zip` (sha256 verified equal to the pin). The update task itself downloads from https://sztheory.github.io/scrypath-brand/ and refuses on mismatch. Verify the sha before using any local copy.
- Implement in Elixir: `dev/mix/tasks/verify/brand.ex`, `dev/mix/tasks/brand/update.ex`, `test/mix/tasks/brand_pin_contract_test.exs`, a `preferred_envs` entry. Node is used only under `website/` and the e2e directories; a Node verifier would add `npm ci` to a merge-blocking gate.
- The offline verify is merge-blocking and holds a test-owned `@expected_zip_sha256`. The online re-download check lives only in the update task, never in CI. Update refuses on size or hash mismatch, caps size, entry count and uncompressed size, extracts in memory with `:zip`, and writes only allowlisted members.
- Fonts (the three `web/*.woff2`, byte-identical, 53,076 B) land under `scrypath_ops/priv/static/assets/fonts/` with the OFL license texts beside them. Pinning them is in scope here; wiring them into CSS is Phase 187.
- Keep `brand` and `brandbook` out of the Hex `files` list; the root allowlist, `PackageContract` and `verify.package` guard the real package. `scrypath_ops` is not on Hex.

### Token parity and deny-list (D4, D5)
- One Node test (existing required step, e.g. extend the contrast-checker's area) covers token-map parity both directions, resolved hex equals brand hex, system-dark against the built CSS, built-CSS freshness, the hex allowlist, and the retired-value deny-list. A small `token-map.json` (about 35 rows: property, light and dark source, disposition adopt, derive, keep-platform, retire, local) is the parity source. Verify, do not generate: brand `tokens.json` lacks Selected Night `#2B2130`, dark Control Edge `#8F7F94` and Night Sunken as colors.
- Extend `examples/scrypath_ecommerce/contrast-checker.mjs` (it already has the theme parser, contrast math and alpha compositing); do not add a second pair document.
- Deny-list: one scan of `git ls-files` for lowercase hex, rgb and rgba triplets of the old identity values and the string `brandbook/`. The list is old values minus all new values, so a reused color such as `#0c0f14` is never denied. The allowlist is path-level and shrink-only, seeded with today's roughly 30 files; each entry carries a phase tag and a stale entry fails. Six planted failures run through the same scan on a temp tree, built by string concatenation so the guard source never contains a retired value. Old values to include: `#191e25 #353d48 #f1f2f4 #dce2e9 #f3f5f8 #edf1f5 #202124 #2a3446 #302b4c #eeebff #a85d2e #111419 #222831` and rgb triplets 108,92,231 and 193,122,62; confirm the full list against the live files.
- Do not retire the 898-line `dev/mix/tasks/verify/ui_tokens.ex`, the `ops.*` DTCG mirror or `ui_tokens_contract_test.exs` in this phase; they retire last, after the Phase 187 re-skin.

### Lifting pinned literals (D5)
- Rewrite about 12 literal lines in 3 files: `ui_tokens_contract_test.exs` (lines about 150, 159, 178, 202, 437 and `@legacy_shadows`), `ui_contrast_contract_test.exs` (about 151, 173, 178; 107, 162 if values change), `surface_depth_token_contract_test.exs:15-17`. Rewrite to read the live value by regex and mutate that, and assert the elevation relationship, not a hex. Add a resolved-token helper. At most 3 test-only commits; re-derive line numbers on the current tree.
- Measured dry run exists (recolor of `app.css` alone fails 8 of 18; after the literal lift 16 of 16 pass). No scratch-tree dry run here. If the projection after the commits still shows failures that Phase 187 does not own, stop and re-plan.
- Phase 185 preservation specs: `scripts/ci/ui_state_pairs.cjs` (about lines 549-596, not wired in `ci.yml`) fails every case on a recolor by design. Replace only the pixel check with a recolor-tolerant structural check, calibrated with one accept and one reject case; keep copy, geometry, state, action and identity checks. This replacement is unproven until prototyped; prototype before committing to it.

### Gates and governance (D2, D14, D16)
- `ops-ui` becomes a required check. Step 0b (PR #126) already widened its path list to `brand/`, `language/` and `fixtures/` and left making it required as a separate setting; confirm current state first. Amend `workflow_wiring_test`, which asserts exactly five required jobs. Setting the branch-protection rule is a repository setting change: do the code and test change in the PR, and record the setting change for the maintainer if the API call is not authorized. Put cheap static checks (`lib/` never mentions PhoenixStorybook; the dependency is `only: [:dev, :test]`) in `core` or `package`.
- Gate budget: at most 12 new required gates in the milestone; each states its deletion trigger and expected churn per UI PR; a gate red twice for non-defects in 30 days drops to advisory.
- Guardrails: second consecutive evidence-only plan forces stop-and-decide; one full gate per commit SHA; a stale receipt is a failed gate; no capture from a dirty tree. Snapshot-based contracts read committed HEAD, so commit a fix before rerunning them. First `verify.repository_contracts` and Buildx runs need escalated permission (AGENTS.md).

### Decisions from research (2026-11-18; follow these where they differ from the sections above)
Source: [186-RESEARCH.md](186-RESEARCH.md). Each is reversible and technical, so decided without asking.
- **GATE-01 is code-only.** `ops-ui (path-scoped)` is already a required check on `main` (six contexts, no rulesets). Do not rename the job and do not touch branch protection. Update `workflow_wiring_test` (the "exactly five required jobs" assertion, about `:989-1004`) and the CONTRIBUTING contract (about `:601-608`) to six names, and add the static storybook-boundary tests to `dependency_boundary_contract_test.exs`.
- **Token-map `applied` flag.** `app.css` is not recolored until Phase 187, so "resolved hex equals brand hex" cannot hold yet. Each token-map row carries `applied: false|true`; applied rows are checked against the brand hex, pending rows are checked for presence and parity only, a stale `applied` claim fails symmetrically, and the pending count is shrink-only. Phase 187 flips rows to applied.
- **"Fresh built CSS" is token-level.** A fresh Tailwind 4.1.12 build differs from the tracked CSS by 510 diff lines, so compare the token properties across the three emissions (prototype passes: 0 mismatches over 29 properties), not bytes.
- **Deny-list source of "new".** Take new values from `brand/tokens.json` plus the token map, not every hex in the brand files (`BRAND.md` and `brand.json` print retired `#5B4AD1` and `#C17A3E`); exempt those two hash-pinned files by path and match case-insensitively. Deny set = the CONTEXT list plus `#5b4ad1 #aaa0ff #6c5ce7 #c17a3e #141923` and the warm-paper tier, with rgb triplets derived from the denied hexes. Leave the tier-4 semantic colors (`#0c0f14 #5ca9e6 #4fae74 #d9a441 #d96262` and four more) off the deny-list until Phase 187's `local` decision.
- **Allowlist seed** is the 22 non-planning files plus the `brandbook/` prefix from the research table; `.planning/` is exempt as a whole. Tags: `p187` for files Phase 187 recolors, `retire-last` for `brandbook/`, the DTCG mirror and their tests (no v1.46 requirement deletes them; the allowlist is shrink-only but is not required to be empty at the end of 187). Neutralize the contrast-checker self-test fixture's 14 deny hits by string concatenation now.
- **Fonts and OFL:** one copy of the three OFL texts, beside the fonts. Adopted allowlist is the 44 files, 326,773 B, listed in the research.
- **Three advisory-lane e2e specs** (`admin_path_motion`, `admin_surface_depth`, `phase173_shell`) hold old RGB constants in glow and path code that Phase 187 retires; they are 187-owned and stay allowlisted with a `p187` tag.
- **TOK-04:** land it before any Phase 187 "before" capture (editing `ui_state_pairs.cjs` changes the fixture-overlay digest through `PRESERVATION_FIXTURE_FILES`). Existing pair tests use solid-color PNGs and would pass vacuously under a structural check, so rewrite them. Use the ink-coverage grid prototype (16 px blocks, mode-relative, tolerance at most 0.25% of blocks), and prototype it on a real before/after pair before committing. The tests run inside the existing focused step; no new gate.
- **GATE-02 checkpoint:** a three-plan evidence phase hits the "second consecutive evidence-only plan" rule by design. Record an explicit stop-and-decide checkpoint at the end of Plan 02 (the projection result and whether Plan 03 still earns its place); Plan 03 may proceed only if the projection shows Phase 187 owns every remaining failure.
- **Suggested slicing:** Plan 01 pin (all new files); Plan 02 token test, deny-list and the at most 3 test-only lift commits, with the projection recorded; Plan 03 TOK-04 plus the gate wiring.
- **Speed win to record, not implement here:** 575 of `repository-contracts`' 823 s is the four-file Node step (about 16 lifecycle tests at 30-36 s each plus one of 67 s). Note it in the phase summary as a candidate for a later CI change.

### Claude's Discretion
- File layout inside the paths named above, helper naming, test structure, commit slicing within the 3-plan cap, and ordering of the cheap checks. Run cheap consistency checks (contrast checker, ops pure-regex tests, the deny-list scan) before the long suites.
- Per standing instruction, look for low-hanging CI speed wins whenever a CI run happens and record them; do not weaken what a check proves.

</decisions>

<code_context>
## Existing Code Insights

- `examples/scrypath_ecommerce/contrast-checker.mjs`: theme parser, contrast math, alpha compositing; passes in about 0.05 s.
- `scrypath_ops/assets/css/app.css`: the two daisyUI theme blocks are the single authoring place for tokens (Phase 187 edits them).
- `scripts/ci/ui_literal_policy.cjs` (ledger and ratchet; `parseLedgerText` pins `bootstrap_commit`; do not repin) and `scripts/ci/ui_state_pairs.cjs`.
- `dev/mix/tasks/verify/` holds maintainer tasks outside the Hex package; `mix.exs` `preferred_envs` registers them.
- Local toolchain needs `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5` exported.
- The tracked `brandbook/` (36 files, old identity) stays until Phase 187 and is allowlisted with a phase tag.

</code_context>

<specifics>
## Specific Ideas

- Cheapest checks, in order: `node examples/scrypath_ecommerce/contrast-checker.mjs`; ops pure-regex tests; the three root `ui_*` tests with `--exclude contrast_child` (about 24 s); the deny-list scan; the offline brand verify. Only then the `contrast_child` tests (they clone the repo and run a nested `mix verify.repository_contracts` about 18 times) and Docker lanes.
- Dirty `.planning/config.json` and `state.json` edits are not part of owned commits.

</specifics>

<deferred>
## Deferred Ideas

- The theme-block recolor, fonts wiring, logo, status component and everything visible: Phase 187.
- Retiring `ui_tokens.ex`, the `ops.*` DTCG mirror and `ui_tokens_contract_test.exs`: after Phase 187.
- Online re-download check in CI, SHA-bound evidence manifests, a hosted browser lane: cut by the gate budget.
- Tagging the brand repo and asking for a LICENSE; the brand-author send-back list: maintainer's own action.

</deferred>
