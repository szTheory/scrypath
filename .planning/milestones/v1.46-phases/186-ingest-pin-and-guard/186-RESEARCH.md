# Phase 186: Ingest, pin and guard - Research

**Researched:** 2026-11-18
**Domain:** Test and evidence infrastructure for a brand adoption (Elixir maintainer tasks, one Node token test, existing-CI wiring). No rendered UI change.
**Confidence:** HIGH for in-repo facts (read or run this session); MEDIUM for the design recommendations marked U.

Legend: **V** = verified this session by reading the file or running the command (`[VERIFIED: ...]`). **U** = inferred or recommended, not proven (`[ASSUMED]`). Discrete in-repo values are quoted verbatim beside the claim with path and line.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Claude's Discretion
- File layout inside the paths named above, helper naming, test structure, commit slicing within the 3-plan cap, and ordering of the cheap checks. Run cheap consistency checks (contrast checker, ops pure-regex tests, the deny-list scan) before the long suites.
- Per standing instruction, look for low-hanging CI speed wins whenever a CI run happens and record them; do not weaken what a check proves.

### Deferred Ideas (OUT OF SCOPE)
- The theme-block recolor, fonts wiring, logo, status component and everything visible: Phase 187.
- Retiring `ui_tokens.ex`, the `ops.*` DTCG mirror and `ui_tokens_contract_test.exs`: after Phase 187.
- Online re-download check in CI, SHA-bound evidence manifests, a hosted browser lane: cut by the gate budget.
- Tagging the brand repo and asking for a LICENSE; the brand-author send-back list: maintainer's own action.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PIN-01 | Offline verify of `brand/` and shipped fonts against `brand/brand.pin.json`, closed owned dirs, merge-blocking | Sections "Brand zip", "Elixir implementation facts", Validation row PIN-01. 44 pinned files, all sizes and hashes computed (V). Rides `core` via the root ExUnit suite (V: `core` runs full `mix test`). |
| PIN-02 | Update task refuses on size, hash, entry-count, uncompressed-size mismatch; in-memory `:zip`; only allowlisted members; online check only here | `:zip` behaviors probed on the real zip (V); Req 0.7.5 capped-download pattern from its docs (V); zip gotchas in Pitfalls. |
| PIN-03 | Only adopted assets (about 330 KB); `brand/` and `brandbook/` out of Hex `files` | Allowlist sums to 326,773 B (V); `mix.exs` `files:` quoted; `PackageContract` closed top-level list (V). No new package gate needed. |
| TOK-01 | One Node token test in an existing required step: parity both ways, resolved hex = brand hex, system-dark = built CSS, built CSS fresh | 37 theme properties per theme, same key set (V); `readThemeProperties` already exported (V); built-CSS emission structure and a token-level freshness prototype that passes today (V); byte-level rebuild equality fails today (V). |
| TOK-02 | Hex allowlist plus deny-list over `git ls-files`, shrink-only path allowlist with phase tags, six planted failures | Complete current inventory (V): 22 non-planning files plus `brandbook/`; `.planning/` adds 113 files and must be exempt; scan runs in 126 ms (V). |
| TOK-03 | About 12 pinned literals rewritten to read live tokens, at most 3 test-only commits, projection shows no failure outside 187 | Current line numbers and exact patterns below (V); recolor projection reproduced on the current tree: 7 failures, all in `UiTokensContractTest` (V). |
| TOK-04 | Preservation specs keep copy/geometry/state/action/identity checks; pixel check replaced by calibrated structural check | Pixel comparison at `ui_state_pairs.cjs:507-537` and `:579-595` (V); prototype on synthetic fixtures separates accept from reject (V, unproven on real captures). |
| GATE-01 | `ops-ui` required; wiring test and static storybook-boundary checks amended; budget of 12 | `ops-ui (path-scoped)` is already a required context on `main` (V, `gh api`). Remaining work is test and doc amendments only. |
| GATE-02 | Guardrails honored (3-plan cap, stop-and-decide, one full gate per SHA, no dirty capture) | Plan slicing and checkpoint recommendation below; GATE-02 reading is an open question. |
</phase_requirements>

## Summary

The prep's decisions hold against the current tree, but eight facts differ from what CONTEXT assumes and change the plans. (1) `ops-ui (path-scoped)` is already a required status check on `main`, so GATE-01 needs no repository-setting action, only a test, a doc and a static-check amendment. (2) The token test cannot assert "resolved hex equals brand hex" for any `adopt` row at the end of Phase 186, because `app.css` is not recolored until 187; rows need an `applied` flag with a symmetric staleness check. (3) The "old minus all new" rule must take "new" from `brand/tokens.json` plus the token map, not from every hex in the brand files: `BRAND.md:1081` and `brand.json:1480` print the retired `#5B4AD1` and `#C17A3E`. (4) The seeded allowlist is 22 non-planning files plus the `brandbook/` directory (23 of its 36 files hit), not roughly 30; `.planning/` holds 113 more files with old values and must be exempt wholesale. (5) The tracked built CSS is not byte-identical to a fresh Tailwind 4.1.12 build today (510 diff lines), so "fresh" has to mean token-level freshness, which passes today. (6) Line numbers in `ui_contrast_contract_test.exs` have drifted from the prep. (7) Old-identity RGB constants also sit in three advisory-lane e2e specs, outside the 12 lines. (8) Editing `scripts/ci/ui_state_pairs.cjs` changes the Phase 185 fixture-overlay digest.

Recommended slicing is three plans: Plan 01 pin (PIN-01..03, all new files, no edits to existing tests); Plan 02 token test, deny-list and the three test-only literal-lift commits (TOK-01..03); Plan 03 structural compare and gate wiring (TOK-04, GATE-01, GATE-02). No new CI job, step, or Hex dependency is needed: the Node test rides the existing `ui_contrast_contract_test.exs` wrapper pattern (runs in `core` and `repository-contracts`), the brand test rides the root suite in `core`, and the static boundary checks extend `dependency_boundary_contract_test.exs`.

**Primary recommendation:** build the offline pin verify and update task first (independent, all-new files), then one Node token test wrapped by ExUnit with a data-driven `token-map.json` carrying an `applied` flag, then lift the literals in three test-only commits and prove the projection with a throwaway scripted recolor before touching TOK-04.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Offline pin verify (`mix verify.brand`) | Maintainer Mix task, `dev/mix/tasks/verify/` (compiled under `:test` only) | ExUnit contract test in `core` | `verify.*` tasks and their tests are the repo's convention; `core` already runs the whole root suite (V). |
| Online refresh and re-download check (`mix brand.update`) | Maintainer Mix task only | none | Must never run in CI (locked decision). |
| Token parity, hex allowlist, deny-list | Node test under `examples/scrypath_ecommerce/` | ExUnit wrapper in `ui_contrast_contract_test.exs` | The Node lane already owns the theme parser; the wrapper is how that file already reaches CI (V). |
| Literal lifts | Root and ops ExUnit tests | Elixir test-support helper | The pinned literals live in Elixir tests. |
| Structural PNG comparison | `scripts/ci/` Node (pngjs) | none | Same module as the pixel check it replaces. |
| Required `ops-ui` check | Repository setting (already applied) | `workflow_wiring_test`, `CONTRIBUTING.md` | Setting exists; tests only need to describe it. |
| Static storybook-boundary checks | Root ExUnit (`dependency_boundary_contract_test.exs`) | `core` job | Cheap file reads, already in `core` and `repository-contracts` (V). |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / OTP | 1.19.0 / 28 (local, asdf env vars needed); CI 1.19.0 / 28.1 | Mix tasks and tests | `ci.yml:49` `{elixir-version: "1.19.0", otp-version: "28.1"}` (V). |
| `:zip`, `:crypto` (OTP) | OTP 28 stdlib | In-memory zip listing and extraction, sha256 | Already probed on the real zip (V). No dependency. |
| Jason | 1.4.5 | Read and write `brand.pin.json` | In `mix.lock` (V). |
| Req | 0.7.5 | Download in `mix brand.update` only | Already a runtime dep (`mix.exs` deps, V); capped streaming via `into:` fun documented at `deps/req/lib/req.ex:296-303` (V). |
| Node built-ins | v26.10.0 local; CI Node version not observed (U) | `node:test`, `node:assert/strict`, `node:crypto`, `node:fs`, `node:child_process` | No dependency; write Node-20-compatible code (U). |
| pngjs | 7.0.0 | PNG decode for TOK-04 | Already in `examples/scrypath_ecommerce/package.json:26` and lock (V); `ui_state_pairs.cjs` already requires it. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Mix.Tasks.Verify.UiTokens` pattern | in-tree | Shape for a bounded verifier: `use Mix.Task`, `@moduledoc false`, `run([])` plus a public `check!/N` for tests | Copy for `Verify.Brand` (V: `dev/mix/tasks/verify/ui_tokens.ex:1-34`). |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Elixir pin verifier | Node verifier | Rejected by CONTEXT: would add `npm ci` to a merge-blocking gate. |
| ExUnit wrapper for the Node token test | Add the file to the 4-file `node --test` step in `repository-contracts` | The step takes 575 s today (V) and the wiring test pins its file list; the wrapper needs no `ci.yml` edit. Either is allowed. |
| Generate `token-map.json` | Verify only | Locked: verify, do not generate. |

**Installation:** none. No new Hex or npm packages.
**Version verification:** `req` 0.7.5 from `mix.lock:34`; `jason` 1.4.5 from `mix.lock:21`; `pngjs` 7.0.0 from `package-lock.json` (V).

## Package Legitimacy Audit

No external package is added or changed by this phase, so the legitimacy gate (`package-legitimacy check`) does not apply. Every library named above is already locked in this repository (V: `mix.lock`, `examples/scrypath_ecommerce/package-lock.json`).

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| (none new) | - | - | - | - | - | Approved: nothing installed |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
brand site zip (mutable, Pages)           maintainer machine only
  https://sztheory.github.io/scrypath-brand/ ──► mix brand.update ──► verify size/sha/entries/uncompressed
                                                    │ (no args: re-download check, read only)
                                                    │ (with expected values: refresh)
                                                    ▼ writes ONLY allowlisted members, in memory via :zip
                    brand/ (38 files) + scrypath_ops/priv/static/assets/fonts/ (6 files) + brand/brand.pin.json
                                                    │
 CI (core, repository-contracts) ◄── ExUnit ◄── mix verify.brand (offline): pin sha const in test,
   per-file path/size/sha256, closed dirs incl. dotfiles, mix.exs files: has no brand/brandbook

 app.css theme blocks (2) ─┐
 scrypath_ops/priv/static/assets/css/app.css (built, tracked) ─┤
 token-map.json (37 rows, applied flag) ─┤──► Node token test ──► parity both ways, adopt rows vs brand/tokens.json,
 brand/tokens.json + brand.json ─┘                               system-dark vs built, token-level freshness
 git ls-files (--cached --others) ──► deny-list scan (hex, derived rgb triplets, "brandbook/")
                                       minus .planning/ and brand/BRAND.md,brand/brand.json (exempt)
                                       minus shrink-only allowlist (path + phase tag; stale entry fails)
                                       ▲ 6 planted failures + accept cases on a temp tree (string-concatenated values)
 wrapper: test/mix/tasks/ui_contrast_contract_test.exs shells `node` (same pattern as line 9-41)

 Phase 185 PNG pairs ──► ui_state_pairs.cjs compareValidatedBundles
        pixel equality ──► structural ink-coverage compare (calibrated accept/reject)
        copy/geometry/state/action/identity checks unchanged
```

### Recommended Project Structure
```
brand/
├── BRAND.md  brand.json  tokens.json  brand.pin.json
└── assets/  README.md  logo/ icon/ readme/ avatar/ docs/ social/
scrypath_ops/priv/static/assets/fonts/   # display.woff2 ui.woff2 mono.woff2 + 3 OFL-*.txt (closed dir)
scrypath_ops/assets/css/token-map.json   # JSON on purpose: the literal ratchet scans only .heex .ex .css .js .mjs .cjs .ts .tsx (V ui_literal_policy.cjs:16)
examples/scrypath_ecommerce/ui-tokens.test.mjs   # name is discretionary; imports from contrast-checker.mjs
dev/mix/tasks/verify/brand.ex        # Mix.Tasks.Verify.Brand
dev/mix/tasks/brand/update.ex        # Mix.Tasks.Brand.Update
test/mix/tasks/brand_pin_contract_test.exs
test/support/ui_tokens.ex            # resolved-token helper (root); ops test inlines a few lines (copy over dependency)
```

### Pattern 1: In-memory `:zip` with pre-checks (V, run on the real zip)
**What:** hash and size the whole archive before `:zip` sees it, list, cap, then extract by exact allowlisted name and write to pin-derived paths.
```elixir
# Source: run against the pinned zip on OTP 28 in this session
{:ok, h} = :zip.zip_open(bin, [:memory])
{:ok, [{:zip_comment, _} | list]} = :zip.zip_list_dir(h)       # 108 {:zip_file, name, info, _, _, comp} records
sizes = for {:zip_file, n, info, _, _, _} <- list, do: {to_string(n), elem(info, 1), elem(info, 2)}
{:ok, {_name, data}} = :zip.zip_get(~c"scrypath-brand/assets/fonts/web/ui.woff2", h)  # 16128 bytes
```
**When to use:** the update task. Names are charlists; the first list element is `{:zip_comment, []}`.

### Pattern 2: Capped streaming download (Req 0.7.5, documented at `deps/req/lib/req.ex:296-303`)
```elixir
Req.get(url, decode_body: false, max_redirects: 3,
  into: fn {:data, d}, {req, resp} ->
    n = Req.Response.get_private(resp, :bytes, 0) + byte_size(d)
    resp = Req.Response.put_private(resp, :bytes, n)
    if n > @max_zip_bytes, do: {:halt, {req, resp}}, else: {:cont, {req, resp}} end)
```
Accumulate chunks separately (process-local `Agent` or private key); treat `:halt` as "cap exceeded, refuse". U for exact helper names; the `into:` contract is V.

### Pattern 3: Token-map row with an `applied` flag (U, design)
Rows carry per-theme `{source, disposition, target?, applied}`. `adopt` rows point into `brand/tokens.json` (for example `color.light.panel`); `derive` and `local` rows carry their hex and a reason; `keep-platform` rows carry the literal. Test rule: `applied: true` requires CSS value equals resolved brand hex; `applied: false` requires CSS value does not equal it (stale pending row fails) and the pending count may only shrink. Phase 187 flips rows; Phase 186 ends with every `adopt` row pending.

### Pattern 4: Resolved-token helper for Elixir tests (U, design)
`theme_value(css, :dark, "--ops-bg")` returns the live value by regex inside the named `@plugin ... daisyui-theme` block (the dark block comes first in the file, so `String.replace(..., global: false)` on a bare property hits dark only by accident). Mutations are derived from the live value (flip a hex digit) so no literal remains. Reuse the existing private `css_theme_values!/2` and `replace_dark_theme!/3` (`ui_tokens_contract_test.exs:688-720`).

### Anti-Patterns to Avoid
- **Computing "new values" from every hex in `brand/`:** drops `#5b4ad1` and `#c17a3e` from the deny-list (see Pitfall 2).
- **Pinning old values inside the token map as the expected current value:** moves the literal pin into a data file. Use the `applied` flag instead.
- **A rebuild-and-compare freshness check in CI:** needs the Tailwind binary (network) and fails today (Pitfall 5).
- **Editing pinned brand files in place** (for example the ExDoc CSS that Phase 188 must fix): derive a copy elsewhere.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Zip parsing | A central-directory reader | `:zip` (`zip_open/2`, `zip_list_dir/1`, `zip_get/2`) | Verified on the real archive; bad-EOCD handling included. |
| Hashing | A digest routine | `:crypto.hash(:sha256, bin)` / `node:crypto` | Stdlib. |
| Theme parsing | A second CSS parser | `readThemeProperties` from `contrast-checker.mjs:972` (already exported at `:1226`) | Quote, comment and brace aware; throws on duplicates and non-hex colors. |
| PNG decoding | A decoder | pngjs 7.0.0 | Already used by the module being edited. |
| DTCG validation | Anything | Leave `verify.ui_tokens` untouched | Locked: retires after 187. |
| Download size cap | Manual socket reads | Req `into:` fun with `{:halt, ...}` | Documented contract. |

**Key insight:** every piece of this phase is a small composition of things that already exist in the tree; the risk is in the seams (flags, exemptions, ownership of values), not in the mechanisms.

## Runtime State Inventory

Not applicable as a deliverable: Phase 186 changes tests, tooling and committed assets only; it renames nothing at runtime. Two facts matter for Phase 187's own inventory: the tracked built CSS `scrypath_ops/priv/static/assets/css/app.css` carries the old theme and must be rebuilt and committed by 187 (V: tracked, not ignored per `scrypath_ops/.gitignore:29-34`), and the ecommerce host and ops favicons and logos are tracked copies of the old identity (V: inventory below).

## Common Pitfalls

### Pitfall 1: The token test cannot be green and also assert brand hexes
**What goes wrong:** "resolved hex equals pinned brand hex" fails for every `adopt` row while `app.css` still holds old values (V: `app.css:29-115`).
**Why:** Phase 186 must change no rendered UI.
**How to avoid:** Pattern 3 (`applied` flag, symmetric staleness check, shrink-only pending count). Parity both directions (every theme property has a row and every row a property) is fully enforceable now: 37 properties per theme, identical key sets (V).
**Warning signs:** a plan that edits `app.css` colors in Phase 186.

### Pitfall 2: Prose mentions of retired colors in the pinned brand files
**What goes wrong:** `BRAND.md:1081` reads "Violet `#5B4AD1` as the lead color, and copper `#C17A3E` as the second." and `brand.json:1480` repeats it. A naive "old minus every hex found in brand files" removes the two most important retired colors from the deny-list.
**How to avoid:** take "new" from `brand/tokens.json` `$value.hex` plus token-map target and local values, exempt `brand/BRAND.md` and `brand/brand.json` from the scan by path (hash-pinned, so safe), and add a self-check that the deny set and the new set are disjoint. V: the only overlap between 40 candidate old hexes and the 34 hexes in all adopted members is `#5b4ad1` and `#c17a3e`; `#0c0f14` appears in no adopted member, so it is not reused by the brand data (the prep's example); it stays denied-or-not purely by the token-map `local` decision (Open Question 2).
**Also:** brand files print hex in uppercase (`tokens.json` `"hex": "#F8F4F2"`, CSS `#F0E9E6`), so every comparison must be case-insensitive.

### Pitfall 3: `.planning/` and the allowlist size
**What goes wrong:** scanning all of `git ls-files` hits 113 files under `.planning/` on top of 45 elsewhere (V, tiers 1-3).
**How to avoid:** exempt `.planning/` by prefix with a stated reason (maintainer record, not shipped). The allowlist is then 22 files plus the `brandbook/` prefix entry.

### Pitfall 4: Guard sources and tests that contain retired values
`contrast-checker.mjs:538-561` (self-test fixture) alone carries 14 denied hits; `ui_tokens_contract_test.exs` keeps 15 after the lifts (rgba tints at lines 10-23, `brandbook/` x5, `#5b4ad1` and `#c17a3e` at 415-416). Either rewrite fixtures with neutral placeholders (the checker fixture is synthetic) or allowlist with a phase tag. New guard code must build retired values by concatenation.

### Pitfall 5: Built CSS is not byte-fresh today
A fresh local build (`scrypath_ops/_build/tailwind-macos-arm64 --input=assets/css/app.css`, Tailwind 4.1.12, daisyUI 5.0.35, 94 ms) writes 204,231 B; the tracked file is 200,700 B and differs in 510 diff lines (for example `.tab` rules present in the fresh build only; variable order differs). Token-level freshness does pass today (prototype, below). Define "fresh" as: the three theme emissions in the built CSS hold the same 29 `--color-*` and `--ops-*` values as the source blocks.

### Pitfall 6: Snapshot-based children read committed HEAD
`ui_contrast_contract_test.exs:207-257` and `ui_tokens_contract_test.exs:756-` clone `HEAD` (`git clone --shared`) and copy only named working files over it. A new support file (`test/support/ui_tokens.ex`) or an uncommitted fix is invisible to the child. Commit each lift before running the four `contrast_child` tests.

### Pitfall 7: `:zip` edge behavior (V, probed)
`unzip` with `{:file_list, names}` silently omits a missing name (compare counts); `zip_open` on garbage bytes returns `{:error, {:EXIT, ...}}` (check size and sha256 first); a truncated archive returns `{:error, :bad_eocd}`; entry sizes are declared, so verify `byte_size` and sha256 after extraction; derive output paths from the pin, never from the entry name.

### Pitfall 8: Lint and docs gates on new Elixir
`mix verify` runs `format --check-formatted`, `credo --strict` over `lib/ dev/ test/ mix.exs` (V `.credo.exs`), `mix test --warnings-as-errors` and `mix docs --warnings-as-errors`. Use `@moduledoc false` on the new tasks (as `ui_tokens.ex` does) to avoid ExDoc link warnings. `verify_capability_test.exs:72-98` fails any `Mix.Tasks.Verify*` module without a `:test` entry in `preferred_envs`.

### Pitfall 9: Editing `ui_state_pairs.cjs` changes the evidence identity
`scripts/ci/ecommerce_evidence.cjs:88-89` lists `scripts/ci/ui_state_pairs.cjs` and its test (and `e2e/ui-review.mjs` is in the same `PRESERVATION_FIXTURE_FILES` list) inside the fixture-overlay digest (`fixtureOverlayDigest`, `:189`). Digests are computed, not pinned, in tests (V), but any earlier "before" qualification is now stale: land TOK-04 before any Phase 187 before-capture. Prefer allowlisting `ui-review.mjs` over editing it.

### Pitfall 10: Existing pair tests would pass vacuously under a structural check
`ui_state_pairs.test.cjs` builds solid-color PNGs (`png(12, 8, 20)` versus `21`, `:348-363`; `imageColor: 20` versus `21`, `:365-375`, `:430-431`). A structural check sees two uniform images as equal. Those cases must become structural mutations (moved block) and the calibration pair added.

### Pitfall 11: Phase 188 needs a corrected ExDoc stylesheet
The pinned `brand/assets/docs/scrypath-exdoc.css` carries the two known bugs (prep D11). Keep it byte-identical; derive the fixed copy under a non-pinned path.

### Pitfall 12: Duplicate member contents
`favicon-32-dark.svg` and `favicon-dark.svg` share sha `cdb47ac9...`; `favicon-32-light.svg` and `favicon-light.svg` share `832e6098...` (V). Key pin rows by repo path, not by hash.

## Code Examples

### Deny-list scan skeleton (V timing: 729 files, 6.8 MB, 126 ms on this machine)
```js
// git ls-files -z --cached --others --exclude-standard  (untracked-but-not-ignored files are scanned too)
// skip: ".planning/", exempt brand files; skip files whose first 8192 bytes hold NUL (8 skipped)
// derive rgb triplets from every denied hex instead of hand-listing two
const hexRe = /#([0-9a-f]{6})\b/gi;            // compare lowercased
const rgbRe = /rgba?\(\s*(\d+)\s*[, ]\s*(\d+)\s*[, ]\s*(\d+)/gi;
```
Use `execFileSync("git", [...args])` (no shell). Built-in regexes have no nested quantifiers.

### Token-level built-CSS emission (V, prototype passed: 0 mismatches over 29 props x 3 emissions)
The built CSS holds three `@layer base` emissions with selectors `:root` inside `@media (prefers-color-scheme: dark)` (`app.css` built, line 6516-6560 region), `:root:has(input.theme-controller[value=dark]:checked),[data-theme="dark"]` and `:where(:root),:root:has(input.theme-controller[value=light]:checked),[data-theme="light"]`. Each holds the declarations flat except a nested `@supports (color: color-mix(in lab, red, red))` that re-declares `--ops-text-muted`; the fallback line reads `--ops-text-muted: var(--color-base-content);`. `--color-primary-strong` is emitted after `--noise`, so compare as a map, not by order.

### Structural compare (V on synthetic fixtures only; U on real captures)
```js
// per 16x16 block: ink = share of pixels whose exact RGBA differs from the block's modal color, quantized to 16 steps.
// recolor-invariant (palette substitution keeps regions distinct), sensitive to moved/added/removed content.
equal = blocksWithStepDelta>2 / totalBlocks <= 0.0025 && worstStepDelta <= 8   // plus identical dimensions
```
Prototype results (390x640 synthetic page, 1,000 blocks): recolor old palette to brand palette: share 0, equal true; recolor plus 1-bit antialias noise: equal true; recolor plus one row shifted 8 px: 36 blocks over, equal false; recolor plus primary button removed: 10 blocks over, equal false (at a 1% tolerance this one wrongly passed, so keep the tolerance at or below 0.25%); same palette plus row shift: equal false. Exact equality (today's check) on the recolor: false.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `ops-ui` advisory and path-filtered | `ops-ui (path-scoped)` required, reports success when skipped | PR #126, setting applied (V) | GATE-01 needs tests and docs only. |
| Pixel-exact Phase 185 pair check | Structural ink-coverage check (this phase) | TOK-04 | Recolor no longer fails every case. |

**Deprecated/outdated:** the CONTEXT line numbers for `ui_contrast_contract_test.exs` ("151, 173, 178; 107, 162") and the "roughly 30 files" allowlist seed; use the numbers below.

## Findings by question

### 1. Current state of each named file (all V)

**`contrast-checker.mjs`** (1,233 lines). Exports `{ contrastRatioRaw, evaluatePair, passesAA, readThemeProperties }` (`:1226`); runs `main()` only when invoked directly (`:1228`). `readThemeProperties` (`:972-993`) returns `{light, dark}` maps keyed without the leading `--`, throws on duplicate properties and on any non-`#rrggbb` `--color-*`. Passes in 0.05 s (`Contrast check: PASS`, 0 AA failures, 135 AAA advisories); `--self-test` passes in 0.04 s. Items Phase 187 owns that live in this file: `assertTokenCount` locks 21 tokens and requires `primary-strong` (`:689-702`); `PAIR_RULES` includes `{ fg: "primary-content", bg: "primary-strong", role: "text" }` (`:96`); the self-test fixture at `:536-589` repeats both. Consider making the count data-driven from `token-map.json` now so 187 does not edit checker logic (U).

**`app.css` theme blocks.** Dark block `:29-71`, light `:73-115`; 37 properties each: 21 `--color-*`, 8 `--ops-*` (`ops-bg, ops-surface-1, ops-surface-2, ops-selection, ops-theme-selection, ops-text-muted, ops-warning-text, ops-error-text`), 8 platform (`radius-selector, radius-field, radius-box, size-selector, size-field, border, depth, noise`). Examples: `:63` `--ops-bg: #111419;` (dark), `:107` `--ops-bg: #f3f5f8;` (light), `:65` `--ops-surface-2: #222831;`, `:109` `--ops-surface-2: #edf1f5;`, `:68` and `:112` `--ops-text-muted: color-mix(in oklch, var(--color-base-content) 64%, transparent);`. Retired-identity code outside the theme blocks: glow tokens `:2412-2413` and `:2422-2423` (`rgba(108,92,231,0.30)`, `rgba(193,122,62,0.25)`), `uppercase` at `:786, 1149, 1510, 1750`, `infinite` at `:896, 1616`.

**`ui_literal_policy.cjs`** (1,090 lines). `SOURCE_ROOTS` are `scrypath_ops/lib`, `scrypath_ops/assets`, `examples/scrypath_ecommerce/lib`, `examples/scrypath_ecommerce/assets` (`:10-15`); extensions `.heex .ex .css .js .jsx .mjs .cjs .ts .tsx` (`:16`). `parseLedgerText` requires `bootstrap_commit` to equal the pin (`:745-747`); do not touch. Runs in about 1 s and passes (`Finding occurrences: 33`). It runs first in `repository-contracts` (`ci.yml:169-170`).

**`ui_state_pairs.cjs`** (712 lines). Not wired in `ci.yml` or any Makefile or script: the only references are `scripts/ci/ecommerce_evidence.cjs:88-89` (fixture-overlay list) and its own test. `comparePngExact` is `:507-537`; the pixel equality is `:531`: `equal: before.width === candidate.width && before.height === candidate.height && (sameRawBytes || before.data.equals(candidate.data)),`. The per-case verdict is `:595`: `const passed = pixelsEqual && stateEqual && hoverStateEqual && actionEqual && geometryEqual && copyEqual && assertionsEqual && identityEqual;`. Its test file (612 lines, 19 tests) passes and takes 25.1 s locally; it needs pngjs from `examples/scrypath_ecommerce/node_modules` (`repository-contracts` installs it at `ci.yml:186-187`).

**Root contract tests** (`mix test ... --exclude contrast_child`: 18 tests, 0 failures, 1.8 s; four `contrast_child` tests excluded at `ui_contrast_contract_test.exs:80,110`, `ui_tokens_contract_test.exs:426`, `ui_literal_contract_test.exs:32`).

**Ops pure-regex tests** (`surface_depth`, `design_tokens`, `shell_chrome`, `motion`; 24 tests, 0 failures, 0.5 s plus about 18 s first compile; run from `scrypath_ops/`).

**`dev/mix/tasks/verify/*`.** `repository_contracts.ex`, `package.ex`, `core.ex` are 7-line shims into `Mix.Tasks.Verify.Capability.run/2` (`capability.ex:6-17`). `repository_contracts` runs `Verify.Phase99.run_without_docs/0` whose `@focused_tests` (`verify.phase99.ex:7-18`) are: `phase99_contract_test.exs`, `phase111_contract_test.exs`, `no_human_gates_contract_test.exs`, `verify.phase99_test.exs`, `ui_contrast_contract_test.exs`, `ui_tokens_contract_test.exs`, `ui_literal_contract_test.exs`, `dependency_boundary_contract_test.exs`, `workflow_wiring_test.exs`, `scripts/ci_monitor_test.exs`.

**`mix.exs`.** `cli/0` `preferred_envs` at `:46-105`; `"verify.ui_tokens": :test` at `:100`. Maintainer tasks compile only under `:test` (`elixirc_paths(:test)` is `["lib", "dev/mix/tasks"]`). Package `files:` (`:285`): `~w(lib .formatter.exs mix.exs README.md CONTRIBUTING.md ARCHITECTURE.md CHANGELOG.md LICENSE SECURITY.md guides docs/jtbd-gap-map.md docs/releasing.md docs/operator-support.md docs/search-backend-sre.md docs/local-demo-docker-dx.md)`; no `brand` or `brandbook` entry. `test/support/release/package_contract.ex` holds the closed top-level list `@allowed_top_level ~w(.formatter.exs ARCHITECTURE.md CHANGELOG.md CONTRIBUTING.md LICENSE README.md SECURITY.md docs guides hex_metadata.config lib mix.exs)` and checks a real `mix hex.build --unpack` directory.

**`workflow_wiring_test.exs`.** Repository-contracts node-test contract `:554-591` (asserts four named files are present; extras are allowed); CONTRIBUTING contract `:601-608` (asserts four job names only); required-jobs test `:989-1004` (regex `^  ([a-z][a-z0-9-]+):\n    name: .*\(required\)$` must yield `["backend", "core", "ecommerce-mounted", "package", "repository-contracts"]`); ops-ui contract `:1197-1213` already asserts `name: ops-ui (path-scoped)`, `needs.ops-ui-path.result != 'success'`, no top-level `paths:` and the path list `scrypath_ops/ lib/ dev/ brand/ language/ fixtures/ scripts/ci/ test/release/`.

**`ci.yml` layout.** See section 2.

### 2. CI layout and where new checks attach (V)

Jobs and their cost on the latest main push run (run 44431707668, head 345853c8): `core (required)` 329 s, `package (required)` 129 s, `repository-contracts (required)` 823 s, `backend (required)` 110 s, `ecommerce-mounted (required)` 843 s, `ops-ui (path-scoped)` 532 s, `ops-ui-path` 7 s.

| Job (ci.yml lines) | Steps that matter | Runs the new work how |
|---|---|---|
| `core` `:34-135` | checkout (full history), setup-beam, cache restore, `mix deps.get`, `core_verify`: `mix verify.core --exclude integration --exclude docs_contract` (`:92-94`), which is format check, `verify.workspace_clean`, `compile --warnings-as-errors`, `credo --strict`, full `mix test --warnings-as-errors`, `docs --warnings-as-errors`, then `verify.no_optional_deps` (304 s step) | `brand_pin_contract_test.exs`, the token-test wrapper and the static boundary tests all run here with no YAML change. |
| `package` `:137-158` | `mix verify.package` (115 s): package metadata, contents, consumer smoke, docs contract, release contract, `hex.build --unpack` | Existing guard for PIN-03's Hex side; nothing to add. |
| `repository-contracts` `:160-197` | `node scripts/ci/ui_literal_policy.cjs` (5 s); `npm ci --ignore-scripts --prefix examples/scrypath_ecommerce` (3 s); step "Verify browser build, lifecycle, evidence, and target behavior" runs four `scripts/ci/*.test.cjs` (575 s); `mix verify.repository_contracts` (207 s) | The Node token test runs here through the ExUnit wrapper because `ui_contrast_contract_test.exs` is in `@focused_tests`. |
| `ops-ui-path` / `ops-ui` `:356-402` | path regex at `:366` (includes `brand/\|brandbook/\|language/\|fixtures/\|scripts/ci/`); `mix verify.ops_ui` at `:402` | Unchanged. |
| `closeout-attestation` `:586-633` | `needs: [core, package, repository-contracts, backend, ecommerce-mounted, coverage]` (`:589`); `required_jobs` lists five (`:625`) | Does not name `ops-ui`; leave it (gate budget). |

**Recommended attachment (U on exact file names):** (a) Node token test file next to `contrast-checker.mjs`, invoked from `ui_contrast_contract_test.exs` with the same `System.cmd(node, ...)` pattern as `:9-41`; (b) `brand_pin_contract_test.exs` is picked up by `core`'s full suite; also add it to `@focused_tests` if repository-contracts coverage is wanted (the `verify.phase99_test.exs` source assertions tolerate extra entries, V `:26-42`); (c) static storybook-boundary tests extend `dependency_boundary_contract_test.exs`, which already has `direct_dependency_names!/1` (`:787`) and `dependency_options!/2` (`:799`) and constants for `scrypath_ops/mix.exs` and `scrypath_ops/lib/scrypath_ops_web/dev_router.ex`. Today `phoenix_storybook` is not declared and `PhoenixStorybook` appears nowhere in code (V: `git grep` hits only AGENTS.md and GLOSSARY.md prose), so the checks pass vacuously and become enforcing when v1.47 adds the dependency; say so in the test comment.

**Gate budget (U, counting convention).** Phase 186 spends about four of the twelve: (1) offline brand pin verify, (2) token parity plus deny-list (one mechanism), (3) `ops-ui` required, (4) static storybook-boundary checks. TOK-04's structural check is not a gate unless its test file is wired into CI (it would be a fifth). Each needs a stated deletion trigger and churn per UI PR; put the ledger in one place (suggest `.planning/reference/GATE-BUDGET.md`) and cite it from each test's moduledoc comment.

**Low-hanging CI win to record (V):** in `repository-contracts`, 575 of 823 s is the four-file Node step, dominated by roughly 16 tests of 30-36 s each plus one of 67 s in the lifecycle suite (for example "owned network or volume leaks fail success while every query is project-scoped"). Worth a measured follow-up outside this phase; do not weaken what they prove.

### 3. `ops-ui` required-check state (V)

`gh api repos/szTheory/scrypath/branches/main/protection` returns, verbatim: `"required_status_checks":{"strict":true,"contexts":["backend (required)","core (required)","ecommerce-mounted (required)","package (required)","repository-contracts (required)","ops-ui (path-scoped)"]` with `app_id` 15368 for each, `required_linear_history` enabled, `enforce_admins` false. `gh api .../rulesets` returns `[]`; default workflow permissions are `read`. PR #126 (merged 2026-11-18T23:39:20Z, merge commit 852248c6) closed a fail-open hole, widened the path filter, added no-floating-runner and permission tests, and left "A follow-up setting adds `ops-ui (path-scoped)` to the required checks"; that setting is now applied (who and when not observed). The check reports on main (latest run: `ops-ui (path-scoped)` success, 532 s).

So making it required is not a pending maintainer action. Needed regardless: (a) rename and extend the wiring test at `:989-1004` to name six required contexts (five `(required)` jobs plus `ops-ui (path-scoped)`) rather than "exactly the five"; (b) extend the CONTRIBUTING contract at `:601-608` to the six names (the doc already says so at `CONTRIBUTING.md:243`); (c) keep the job name unchanged: renaming it to `(required)` would orphan the live required context and block merges until the setting is edited; (d) the static boundary checks above. Do not add `ops-ui` to `closeout-attestation` in this phase.

### 4. The brand zip (V)

sha256 `3fc6d80f597eb232b6c25d5929cbe9dbbe6503c346c1360456ea839f3334be88`, 6,729,996 bytes: matches the pin. 108 entries, all regular files, no directory entries, no absolute, `..` or backslash names; every name starts `scrypath-brand/`; declared uncompressed total 8,912,608. Extracted only into a new empty scratchpad directory (`.../scratchpad/zipx`), nothing executed. Adopted SVGs, the README snippet and the ExDoc CSS contain no `<script`, `javascript:`, `on*=`, `foreignObject`, `<iframe` or external `href`/`@import`/`url(http` (grep clean).

**Proposed adopted allowlist (44 files, 326,773 B), member names relative to `scrypath-brand/`:**

| Repo path | Source member | Size | Notes |
|---|---|---|---|
| `brand/BRAND.md` | `BRAND.md` | 71,836 | scan-exempt (prints retired values) |
| `brand/brand.json` | `brand.json` | 74,133 | scan-exempt; `legal`: "Scrypath is released under the Apache License 2.0. The logo files and this book fall under the same license, unless the repository states a different one." |
| `brand/tokens.json` | `tokens.json` | 18,847 | source for `adopt` rows |
| `brand/assets/README.md` | `assets/README.md` | 3,466 | |
| `brand/assets/logo/` 8 SVGs | `assets/logo/scrypath-{lockup,symbol}-{dark,light,one-color-ink,one-color-pale-ink}.svg` | 5,830 5,773 5,746 5,803 1,131 1,106 1,079 1,104 = 27,572 | no 2048 PNGs |
| `brand/assets/icon/` 19 files | all `assets/icon/*` (9 PNG 16/32/48 x dark/light/mono, 9 SVG, `favicon.ico` 1,573) | 18,580 | two content-duplicate pairs |
| `brand/assets/readme/` 3 files | `scrypath-header-dark.svg` 5,829, `scrypath-header-light.svg` 5,772, `header-snippet.html` 461 | 12,062 | snippet is a `<picture>` fragment, not the book |
| `brand/assets/avatar/` 2 SVGs | `scrypath-avatar-{dark,light}.svg` | 2,535 | no 512 PNGs |
| `brand/assets/docs/scrypath-exdoc.css` | `assets/docs/scrypath-exdoc.css` | 1,809 | known bugs; keep byte-identical |
| `brand/assets/social/scrypath-social-card-1280x640.png` | same | 29,652 | |
| `scrypath_ops/priv/static/assets/fonts/display.woff2` | `assets/fonts/web/display.woff2` | 27,072 | magic `wOF2` |
| `.../fonts/ui.woff2` | `assets/fonts/web/ui.woff2` | 16,128 | |
| `.../fonts/mono.woff2` | `assets/fonts/web/mono.woff2` | 9,876 | |
| `.../fonts/OFL-BricolageGrotesque.txt` `OFL-HankenGrotesk.txt` `OFL-SometypeMono.txt` | `assets/fonts/OFL-*.txt` | 4,403 + 4,402 + 4,400 = 13,205 | license `OFL-1.1`; `OFL-HankenGrotesk.txt` says "licensed under the SIL Open Font License, Version 1.1" |

`brand/` subtotal 260,492 B (38 files); fonts directory 66,281 B (6 files); woff2 alone 53,076 B, which equals CONTEXT. The "about 330 KB" budget therefore already includes the fonts and a single copy of the OFL texts; keeping OFL both under `brand/` and beside the fonts would add 13 KB (about 340 KB). Recommend one copy, beside the fonts (distribution location); this is a layout choice within Claude's discretion. Skip: `.nojekyll`, `index.html`, `assets/index.html`, `assets/fonts/web/fonts.css` (479 B, declarations Phase 187 will write itself), all TTFs, PDFs, HTML books, motion, sound, previews, 2048 and 512 PNGs.

Suggested `kind` values: `doc`, `data`, `logo`, `icon`, `readme-header`, `avatar`, `stylesheet`, `social-card`, `font`, `license`. `license`: `Apache-2.0 (per brand.json legal; the brand repo has no LICENSE file, commit ced7c40e)` for brand assets, `OFL-1.1` for the six font-directory files. Pin test can also assert a closed extension set (`.md .json .svg .png .ico .css .html .woff2 .txt`) and a total-size ceiling so a PDF or TTF cannot be pinned later (PIN-03).

### 5. Old-identity inventory and deny-list (V)

Scan: `git ls-files` (2,077 tracked; 40 binary skipped), case-insensitive, hex plus rgb/rgba triplets plus the string `brandbook/`.

**Candidate deny set, in tiers (U on tier assignment, V on contents):**
- **Tier 1, CONTEXT list (13 hex):** `#191e25 #353d48 #f1f2f4 #dce2e9 #f3f5f8 #edf1f5 #202124 #2a3446 #302b4c #eeebff #a85d2e #111419 #222831`.
- **Tier 2, live and missing from CONTEXT (5):** `#5b4ad1 #aaa0ff #6c5ce7 #c17a3e #141923` (old violet, dark primary, accent, copper, old ink).
- **Tier 3, warm paper and brandbook-only ramp (12):** `#fffdf8 #faf7f2 #f4f1ea #ded8ce #1b2230 #475066 #6b7388 #7f8aa3 #b3bdcf #d7d0c4 #e0b487 #f2eee7`.
- **Tier 4, decide in 187 (9):** `#0c0f14 #5ca9e6 #4fae74 #d9a441 #d96262 #f2c66d #ffaaa2 #805000 #ad2922`. None is in the adopted brand data (V), and send-back item 6 says danger, info and success fills become locally invented colors; leave them out of the deny-list until 187 decides, then either list them in the token map as `local` (new) or deny them.
- **Triplets:** derive them from every denied hex rather than hand-listing two. Present today: `108,92,231` (=`#6c5ce7`: brandbook tokens x4, `admin_path_motion.spec.ts` x2, `DESIGN-TOKENS.md`, `app.css` x2, built CSS x2, `ui_tokens_contract_test.exs` x2), `193,122,62` (=`#c17a3e`: `DESIGN-TOKENS.md`, `app.css` x2, built CSS x2), `20,25,35` (=`#141923`: `brandbook/tokens/tokens.css` x6, `ui_tokens_contract_test.exs` x6), `170,160,255` (=`#aaa0ff`: `ui_contrast_contract_test.exs:152`), `34,40,49` (=`#222831`: `admin_surface_depth.spec.ts:48`), `17,20,25` and `243,245,248` (=`#111419`, `#f3f5f8`: `phase173_shell.spec.ts:188,311`).
- **String:** `brandbook/`.

**Seed (tiers 1-3, `.planning/` exempt): 22 files plus the `brandbook/` prefix.** Hits are tier 1-3 occurrences; proposed phase tag is U, `?` means no phase in the roadmap owns it.

| Path | Hits | Proposed tag |
|---|---|---|
| `.github/workflows/ci.yml` | 1 (`brandbook/` in the path regex, `:366`) | with `brandbook/` removal |
| `DESIGN.md` | 7 | 187 |
| `PRODUCT.md` | 1 | 188 |
| `README.md` | 2 | 188 (BDOC-01) |
| `dev/mix/tasks/verify/ui_tokens.ex` | 1 | retire-last |
| `examples/scrypath_ecommerce/contrast-checker.mjs` | 14 (`:536-561` fixture) | 186 (neutralize fixture) or 187 |
| `examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts` | 2 | 187 (retired glow) |
| `examples/scrypath_ecommerce/e2e/ui-review.mjs` | 2 | 187; editing shifts the overlay digest |
| `examples/scrypath_ecommerce/priv/static/favicon.svg` | 3 | `?` (host favicon; assign) |
| `prompts/scrypath-brand-book.md` | 34 | `?` (local reference prompt; assign or exempt) |
| `scrypath_ops/assets/css/DESIGN-TOKENS.md` | 42 | 187 |
| `scrypath_ops/assets/css/app.css` | 34 | 187 |
| `scrypath_ops/priv/static/assets/css/app.css` (built) | 51 | 187 |
| `scrypath_ops/priv/static/favicon.svg`, `images/logo.svg`, `images/scrypath-wordmark.svg`, `images/scrypath-wordmark-inverse.svg` | 3, 3, 3, 3 | 187 (SKIN-03) |
| `scrypath_ops/test/scrypath_ops_web/surface_depth_token_contract_test.exs` | 3 | none after the lift |
| `test/mix/tasks/ui_contrast_contract_test.exs` | 4 | none after the lift |
| `test/mix/tasks/ui_tokens_contract_test.exs` | 16 (about 15 remain after the lift: tints, `brandbook/` x5, `:415-416`) | retire-last |
| `website/src/assets/brand-mark.svg`, `og-image.svg` | 2, 2 | 189 |
| `brandbook/**` | 23 of 36 files hit (353 raw hits over all tiers) | retire-last |

Counts of files with hits: 158 total, 113 under `.planning/` (exempt), 22 non-`brandbook/` outside `.planning/`, 23 in `brandbook/`.

**Inconsistency to resolve:** the prep says the allowlist is "emptied by phase 187", but CONTEXT keeps `brandbook/tokens/tokens.json`, `ui_tokens.ex` and `ui_tokens_contract_test.exs` until after 187, and no v1.46 requirement deletes `brandbook/`. The allowlist cannot reach zero inside v1.46; use a distinct `retire-last` tag for those entries and record who deletes them (Open Question 3).

**Self-consistency checks the test should carry:** deny set and new set are disjoint; every allowlist entry exists and still contains a denied value (stale fails); no allowlist entry covers a path under an exempt prefix.

### 6. Elixir implementation facts (V unless marked)

- **Task shape.** `Mix.Tasks.Verify.UiTokens`: `use Mix.Task`, `@moduledoc false`, `@impl true def run([])` computes `root = Path.dirname(Mix.Project.project_file())`, `def run(args)` raises `Mix.raise("verify.ui_tokens does not accept arguments: ...")`, and a public `check!(json_path, css_path)` carries `@doc false` so tests call it directly with temp files (`ui_tokens.ex:1-45`). The thin canonical shims instead call `Mix.Tasks.Verify.Capability.run/2`.
- **Registration.** Add `"verify.brand": :test` and `"brand.update": :test` to `cli/0` `preferred_envs`; without the second, `mix brand.update` is "not found" outside `MIX_ENV=test`, because `dev/mix/tasks` compiles only under `:test`. The capability test requires the first (`verify_capability_test.exs:72-98`).
- **Test organization.** `test/mix/tasks/*_test.exs`, modules named `Mix.Tasks.<Name>Test`, `async: false` where they touch the repo, `@root Path.expand("../../..", __DIR__)`, temp dirs under `System.tmp_dir!()` with `on_exit(fn -> File.rm_rf!(...) end)`. `test/test_helper.exs` loads `test/support/**/*.ex` by `Code.require_file`.
- **Tamper tests in memory.** Build fake archives with `:zip.create(~c"x.zip", [{name, bin}], [:memory])` (U on exact options) and assert refusal for each of: whole-archive sha, whole-archive size, entry count, declared uncompressed total, per-member sha, per-member size; copy `brand/` and the fonts dir to a temp tree for "unpinned file", "one byte changed", "dotfile added", "pinned file deleted".
- **Hex files.** `PackageContract` reads a real unpacked archive; add a cheap direct assertion that `Scrypath.MixProject.project()[:package][:files]` has no entry starting `brand`.
- **Update task CLI (U).** No arguments: re-download check against the pin (read only, nonzero on mismatch). Explicit `--sha256 --size --commit` plus a source (`--zip PATH` or the Pages URL): refresh pin and files, and print that the test-owned `@expected_zip_sha256` must change in the same PR (two keys). Never derive a write path from a zip entry name.
- **Req caps (U on constants).** Cap compressed size near the pinned size plus margin (for example 8 MiB against 6.73 MB), entries at 200 against 108, declared uncompressed total at 16 MiB against 8.9 MB.

### 7. TOK-04 prototype (see Code Examples; V synthetic, U real)

Smallest recolor-tolerant check: replace `comparePngExact`'s `equal` (`ui_state_pairs.cjs:531`) with the ink-coverage grid compare; keep the dimension and metadata checks (`:515-529`) and every other `compareValidatedBundles` input (`:579-595`). Keep the result field names (`pixels_equal`, `full_page_pixels`, `hover_pixels`) so downstream readers and the `scrypath.ui-state-pair-comparison.v3` schema string need not change, or bump the schema deliberately (U). The Phase 185 recipe fixes the font (`fixed_font_family: "Liberation Mono"`, V `ui_state_pairs.test.cjs` recipe), which removes glyph-shape noise from the comparison.

**Calibration pair (one accept, one reject), as in the synthetic prototype:** accept = same layout, old palette mapped to the brand palette; reject = same recolor with one row shifted 8 px (36 of 1,000 blocks over tolerance). Add the "button removed" case as a second reject if cheap. **Unproven:** real captures contain shadows, hover tints, anti-aliased text and gradients; "Search health: drop the shadow" in 187 will legitimately change margin blocks. Prototype against a real before and after capture pair from the retained preview before committing thresholds, and be ready to tune block size and tolerance (this is the CONTEXT's "unproven until prototyped"). Rewrite the existing solid-color mutation cases first (Pitfall 10). If wired into CI the test file adds about 25 s to a required job; alternatively keep calibration cases in a small separate test file (U).

### 8. TOK-03 literal inventory and projection (V)

Current literal sites (verbatim):

| File:line | Text | Action |
|---|---|---|
| `ui_tokens_contract_test.exs:8-25` | `@legacy_shadows` (`rgba(20,25,35,...)` at 10, 14, 18; `rgba(0,0,0,...)`; glow `rgba(108,92,231,.25)` and `.18` at 23) | Compared against `brandbook/tokens/tokens.json` shadows (`:524-533`); not changed by an `app.css` recolor. Allowlist the file as retire-last rather than rewrite. |
| `:150` | `changed_css = String.replace(css, "--ops-bg: #111419;", "--ops-bg: #121519;", global: false)` | read live dark `--ops-bg`, mutate by flipping a digit |
| `:159` | `String.replace(css, "  --ops-bg: #111419;", "  --ops-bg: #111419;\n  --ops-bg: #111419;",` | duplicate the live declaration |
| `:172` | `put_in(tokens, ["ops", "dark", "ops-bg", "$value", "hex"], "#121519")` (and components `[18 / 255, 21 / 255, 25 / 255]` at `:173`) | derive hex and components from the bumped live value |
| `:178` | `assert_raise Mix.Error, ~r/typed color does not match CSS #111419/, fn ->` | interpolate the live value |
| `:202` | `\|> put_in(["$extensions", "org.scrypath", "css", "expression"], "#111419")` | live value |
| `:437`, `:451` | same pair as 150 and 172 inside the `contrast_child` canonical test | same helper |
| `:415-416` | `assert brand_css =~ "--sp-primary:      #5B4AD1;"` and `"--sp-copper-500:   #C17A3E;"` | reads `brandbook/tokens/tokens.css`; unaffected by recolor; allowlist (retire-last) |
| `:422-423` | `js_theme_values!(example, "Light") == css_theme_values!(ops_css, "light")` (and dark) | 187-owned: fails on any recolor until `brandbook/tokens/daisyui-theme.example.js` is remapped |
| `ui_contrast_contract_test.exs:90-91` | `"--color-secondary-content: #0c0f14;"` to `#333333` | regex on the live dark declaration |
| `:147` | `String.replace(original_css, "--color-warning: #d9a441;", "--color-renamed: #d9a441;")` | replace the property name only; no hex needed |
| `:151-152` | `"--color-primary: #aaa0ff;"` to `"--color-primary: rgb(170 160 255);"` | derive `rgb(r g b)` from the live hex |
| `:161-162` | `"var(--color-base-content) 64%, transparent"` to `63%` | 187-owned (alpha text and the muted lockstep retire); do not lift, but note it fails as a no-op |
| `:173` | `String.replace(original_css, "--ops-surface-2: #edf1f5;", "--ops-surface-2: #5b4ad1;")` | live light value; contrast-breaking replacement taken from another live token |
| `:178` | `"background-color: #5b4ad1;"` | same |
| `surface_depth_token_contract_test.exs:15-17` | `assert Regex.match?(~r/--ops-surface-2:\s*#222831;/, css())` | assert dark `--ops-bg` < `--ops-surface-1` < `--ops-surface-2` by relative luminance, parsed live; the other tests in that file reference `var(--ops-surface-2)` by name, and 187 retires that name (prep D4), so they are 187-owned |

The prep's "107, 162" do not exist at those numbers now; the correct "if values change" sites are `:90-91` and `:147`, plus `:161-162` above.

Not in the 12 but recolor-sensitive: three advisory-lane e2e specs hold RGB constants for old values: `admin_path_motion.spec.ts:219-222` (`const GLOW_RGB = "108, 92, 231";`), `admin_surface_depth.spec.ts:47-48` (`GLOW_RGB` and `const DARK_SURFACE_2_RGB = "rgb(34, 40, 49)";`), `phase173_shell.spec.ts:188,311` (`"rgb(17, 20, 25)"`, `"rgb(243, 245, 248)"`). They run only in the advisory full lane (the required mounted lane runs `e2e/harness.spec.ts e2e/operator.spec.ts`, V `docker-playwright.sh:253-256`), and the glow and path code they test is retired by 187. Treat as 187-owned and say so in the projection record. Also name-level pins on `--ops-surface-2`, `--ops-selection` (`design_tokens_contract_test.exs:183`, `shell_chrome_token_contract_test.exs:84`) change meaning in 187; they pass in 186 and are 187-owned.

**Projection reproduced on the current tree (V).** In a `git archive` copy with only the two theme blocks recolored (old neutrals and primary mapped to brand hexes): contrast checker PASS (0 AA failures), and `ui_contrast_contract_test.exs` plus `ui_tokens_contract_test.exs` with `--exclude contrast_child`: 16 tests, 7 failures, all in `UiTokensContractTest` (four that call `Verify.UiTokens.check!` on the live pair, one brandbook documentation parity, two validator-drift tests whose first step is the clean `check!`). The `--ops-bg` literal pins at `:150, :159, :178, :202` sit behind those and are masked. Before lifts the failing set is therefore: mirror mismatches and brandbook parity (187 remaps the `ops.*` mirror and the example JS) plus the masked literals (this phase lifts them). The prep's measured claim that remapping the mirror and example JS then leaves 1 literal failure and 16 of 16 after the lift is carried (U; not re-run here). Recommended Plan 02 evidence: a throwaway scripted projection (recolor plus mirror remap in a scratch copy, run the cheap checks) recorded in a short projection note; the CONTEXT forbids committing a scratch-tree dry-run deliverable, so keep the script out of the repo.

Suggested three test-only commits: (A) `test/support/ui_tokens.ex` helper plus `ui_tokens_contract_test.exs` lifts; (B) `ui_contrast_contract_test.exs` lifts; (C) `surface_depth_token_contract_test.exs` lift plus `@legacy_shadows` allowlist decision. After each: contrast checker, the four ops regex tests, three root ui tests `--exclude contrast_child`. Commit before running the four `contrast_child` tests.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | CI Node version supports the planned Node APIs (Node 20-compatible code is enough) | Standard Stack | Test fails in CI only; write conservatively, check a CI log line. |
| A2 | `applied` flag with symmetric staleness check is the right way to keep TOK-01 green in 186 | Pattern 3, Pitfall 1 | Alternative designs exist; the constraint (no recolor in 186) is firm. |
| A3 | Ink-coverage thresholds (16 px blocks, step 2, 0.25% of blocks) transfer from synthetic pages to real captures | Structural compare | TOK-04 reject case could be too loose or too strict; prototype on a real pair. |
| A4 | `mix brand.update` CLI shape (no args = check, flags = refresh) | Section 6 | Cosmetic; locked decisions fix only the refusal rules. |
| A5 | Gate budget counting convention (about four spent) | Section 2 | Maintainer may count TOK-04 or the wrapper differently. |
| A6 | Phase tags for allowlist entries without an owning phase (`prompts/`, host favicon) | Section 5 | Unowned entries never shrink; needs an owner or an exemption. |
| A7 | GATE-02's "second consecutive evidence-only plan" reading for a phase whose plans are all evidence-only | Open Question 4 | Planner may over- or under-insert a checkpoint. |
| A8 | The post-lift projection (16 of 16 after the mirror remap) from the prep still holds | Section 8 | Stop-and-replan condition could trigger late. |
| A9 | Offline brand verify costs well under 1 s (44 files, 326,773 B) | Validation | Negligible; measure when written. |
| A10 | Tier 3 values (warm paper, brandbook ramp) are safe to deny now | Section 5 | If 187 reuses one as a local color, it moves to the token map; low cost. |

## Open Questions (RESOLVED)

1. **Token-map `applied` semantics.**
   - Known: no `adopt` row can match brand hex before 187 (V). Parity both ways is enforceable now.
   - Unclear: whether the maintainer wants pending rows visible as a count in output.
   - Recommendation: Pattern 3; print the pending count; 187's plan lists "pending count reaches 0" as its own exit check.
   - **RESOLVED** by CONTEXT "Decisions from research", bullet "Token-map `applied` flag" (symmetric check, shrink-only pending count; Phase 187 flips rows). Planned in 186-02 Task 1.
2. **Tier 4 semantic colors (`#0c0f14 #5ca9e6 #4fae74 #d9a441 #d96262 ...`).** Not in any adopted brand member (V). Recommend leaving them off the deny-list in 186 and deciding in 187's token map (`local` or retired).
   - **RESOLVED** by CONTEXT "Decisions from research", bullet "Deny-list source of new" (tier 4 stays off the deny-list until Phase 187's `local` decision). Planned in 186-02 Tasks 1-2 (rows `local` with target equal to the current value).
3. **Who deletes `brandbook/`, the DTCG mirror and their tests?** No v1.46 requirement does, yet the allowlist is described as emptying by 187. Recommend a `retire-last` tag now and an explicit later item (v1.47 first plan) so the shrink-only rule has a finish line.
   - **RESOLVED** by CONTEXT "Decisions from research", bullet "Allowlist seed" (`retire-last` tag; allowlist need not be empty at the end of 187), plus ownership recommended defaults recorded by the orchestrator under the maintainer's delegated-decisions rule (2026-11-18); the maintainer may override at the Phase 188 boundary: the `brandbook/` directory and `prompts/scrypath-brand-book.md` are owned by Phase 188 (BDOC-01 already requires no `brandbook/` reference in the built docs, so deleting the directory fits there; ROADMAP Phase 188 carries the exit check); `dev/mix/tasks/verify/ui_tokens.ex`, the `ops.*` DTCG mirror, `test/mix/tasks/ui_tokens_contract_test.exs`, the `ci.yml` path regex and the demo host favicon are a tracked cleanup item for the first v1.47 phase. Both are recorded in ROADMAP (Phase 188 scope note and the v1.47 "Deferred" line) and in each allowlist entry's reason.
4. **GATE-02 in an all-evidence phase.** Roadmap allows three plans here but also says a second consecutive evidence-only plan forces a stop-and-decide. Recommend a recorded checkpoint at the end of Plan 02 (projection result plus a go or no-go for Plan 03), not a user question unless the projection fails (AGENTS.md: ask only when scope, risk or cost change).
   - **RESOLVED** by CONTEXT "Decisions from research", bullet "GATE-02 checkpoint" (recorded stop-and-decide at the end of Plan 02; Plan 03 proceeds only on a projection where Phase 187 owns every remaining failure). Planned in 186-02 Task 3 and the 186-03 Task 1 precondition.
5. **Do TOK-04's tests run in CI?** Wiring `ui_state_pairs.test.cjs` adds about 25 s and a gate; leaving it unwired keeps the replacement unexercised after this phase. Recommend wiring only a small calibration test file and counting it in the budget.
   - **RESOLVED** by CONTEXT "Decisions from research", bullet "TOK-04" ("The tests run inside the existing focused step; no new gate"). Planned in 186-03 Task 1: the test file joins the existing `repository-contracts` Node step and is counted conservatively in the gate ledger.
6. **Neutralize the contrast-checker self-test fixture now?** Removes 14 deny hits from guard source and lets the allowlist drop that file; touching `:536-589` also touches the 21-token lock that 187 flips. Recommend neutralizing hexes only, leaving the 21 count for 187 (or make the count data-driven; U).
   - **RESOLVED** by CONTEXT "Decisions from research", bullet "Allowlist seed" ("Neutralize the contrast-checker self-test fixture's 14 deny hits by string concatenation now"); the 21-token lock stays for Phase 187. Planned in 186-02 Task 2.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / OTP | all Elixir work | yes (needs `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5`) | 1.19.0 / OTP 28 | none |
| Node | token test, TOK-04, deny scan | yes | v26.10.0 (CI version not observed) | none |
| git | deny scan, snapshot tests | yes | system | none |
| gh (authorized, scopes repo, workflow) | read branch protection, CI timings | yes | system | none |
| pngjs | TOK-04 | yes (`examples/scrypath_ecommerce/node_modules`) | 7.0.0 | `npm ci --prefix examples/scrypath_ecommerce` |
| Tailwind standalone binary | scratch rebuild only (not a deliverable) | yes (`scrypath_ops/_build/tailwind-macos-arm64`) | 4.1.12 | not needed |
| Network (Pages, git fetch) | `mix brand.update` online check, `ui_literal_policy` | yes | - | offline verify needs none |
| Docker | none of the 186 deliverables | not checked | - | not required |

**Missing dependencies with no fallback:** none.
**Local first-run permissions (AGENTS.md):** the first `mix verify.repository_contracts` (and any `contrast_child` run, which clones the repo and runs it nested) needs the escalated permission up front; do not treat a FETCH_HEAD write failure as behavioral RED.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19) for Mix tasks and contract tests; `node:test` for the token test and TOK-04 |
| Config file | `test/test_helper.exs` (loads `test/support/**/*.ex`); none for Node |
| Quick run command | `node examples/scrypath_ecommerce/contrast-checker.mjs` then `mix test <new files> --exclude contrast_child` |
| Full suite command | `mix verify.repository_contracts` (and `mix verify.core --exclude integration --exclude docs_contract`) in CI |

### Phase Requirements to Test Map (cheapest first)
| Req ID | Behavior | Test Type | Automated Command | Cost | File Exists? |
|--------|----------|-----------|-------------------|------|-------------|
| TOK-01/02 live scan | contrast and live-token health | cli | `node examples/scrypath_ecommerce/contrast-checker.mjs` and `--self-test` | 0.05 s | yes |
| TOK-01 | parity both ways, adopt rows vs `brand/tokens.json`, system-dark vs built CSS, token-level freshness | unit (node) | `node --test examples/scrypath_ecommerce/ui-tokens.test.mjs` | about 0.2 s (U) | no, Wave 0 |
| TOK-02 | deny-list, allowlist ratchet, six planted failures plus accept cases on a temp tree | unit (node) | same file | scan 0.13 s (V prototype) | no, Wave 0 |
| TOK-03 | ops pure-regex lifts | unit | `cd scrypath_ops && mix test test/scrypath_ops_web/{surface_depth_token_contract,design_tokens_contract,shell_chrome_token_contract,motion_contract}_test.exs` | 0.5 s (+18 s first compile) (V) | yes (edited) |
| TOK-03 | root lifts | unit | `MIX_ENV=test mix test test/mix/tasks/ui_contrast_contract_test.exs test/mix/tasks/ui_tokens_contract_test.exs test/mix/tasks/ui_literal_contract_test.exs --exclude contrast_child` | 1.8 s (18 tests, V) | yes (edited) |
| TOK-03 | recolor projection | throwaway script | scratch `git archive` copy, recolor plus mirror remap, run the line above | about 30 to 60 s (U) | not committed |
| PIN-01/02/03 | offline verify, tamper refusals, update refusals, Hex `files:` | unit | `MIX_ENV=test mix test test/mix/tasks/brand_pin_contract_test.exs` | under 2 s (U) | no, Wave 0 |
| GATE-01 | six required contexts, CONTRIBUTING names, static storybook boundary | unit | `MIX_ENV=test mix test test/mix/tasks/workflow_wiring_test.exs test/mix/tasks/dependency_boundary_contract_test.exs test/mix/tasks/verify_capability_test.exs` | 4.7 s (99 tests, V) | yes (edited) |
| GATE-01 | branch protection | read-only API | `gh api repos/szTheory/scrypath/branches/main/protection` | 1 s | n/a |
| TOK-04 | calibrated accept and reject, existing checks intact | unit (node) | `node --test scripts/ci/ui_state_pairs.test.cjs` (needs pngjs) | 25 s (V) | yes (edited) |
| PIN-03 (package side) | real Hex archive | integration | `mix verify.package` | 115 s in CI (V) | yes |
| all | canonical gate | integration | `mix verify.repository_contracts` (nested `contrast_child` runs) | 207 s step in CI (V) | yes |
| PIN-02 (online) | live zip still equals the pin | manual-by-design, local only | `mix brand.update` (no args) | network | not a CI gate by decision |

Zero human verification: every row above is an executable check. The online re-download check is local and intentionally outside CI (locked decision), not a UAT item.

### Sampling Rate
- **Per task commit:** contrast checker, ops regex tests, the three root ui tests with `--exclude contrast_child`, the new Node and brand test files.
- **Per wave merge:** `mix test test/mix/tasks/workflow_wiring_test.exs test/mix/tasks/dependency_boundary_contract_test.exs test/mix/tasks/verify_capability_test.exs`, `node --test scripts/ci/ui_state_pairs.test.cjs` once TOK-04 lands.
- **Phase gate:** one full CI run on the exact head SHA (core, package, repository-contracts, ops-ui all green); commit fixes before any `contrast_child` rerun.

### Wave 0 Gaps
- [ ] `test/mix/tasks/brand_pin_contract_test.exs`, `dev/mix/tasks/verify/brand.ex`, `dev/mix/tasks/brand/update.ex`, `preferred_envs` entries
- [ ] `brand/` tree and `brand/brand.pin.json`; fonts directory files
- [ ] `scrypath_ops/assets/css/token-map.json` (37 rows) and the Node token test file
- [ ] `test/support/ui_tokens.ex` helper
- [ ] Framework install: none

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes | Treat the zip as untrusted: pre-check sha256 and size before `:zip`, cap entries and declared uncompressed size, extract by exact allowlisted name, write to pin-derived paths only |
| V10 Malicious Code and supply chain integrity | yes | Hash pinning with a test-owned constant (two-key change), no TTF or HTML book vendored, scan adopted SVG, CSS and HTML fragments for script and external references |
| V12 Files and Resources | yes | Closed owned directories including dotfiles; no symlinks followed; size ceiling in the pin test |
| V14 Configuration | yes | No new workflow permissions; no secrets; `execFile`, never a shell string, for git |
| V2, V3, V4, V6 | no | No authentication, session, access-control or cryptography design here (sha256 is integrity, not a secret) |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Zip slip (`..` or absolute entry name) | Tampering | Never build paths from entry names; allowlist by exact member; checked: pinned zip has none (V) |
| Zip bomb (declared sizes lie) | Denial of service | Cap compressed bytes while streaming, entries, declared total; verify `byte_size` and sha256 per member after extraction |
| Mutable remote artifact (Pages serves `main`) | Tampering | Re-download check compares to the pin and fails loudly; refresh needs explicit expected values and a test-constant change |
| Active content in vendored SVG or HTML | Elevation / tampering | Pin test greps for script and external references; do not vendor the brand HTML |
| Retired value reintroduced | Tampering (repo integrity) | Deny-list with shrink-only allowlist and stale-entry failure |
| ReDoS in scan regexes | Denial of service | Simple anchored patterns; no nested quantifiers (V design) |

## Sources

### Primary (HIGH confidence)
- In-tree files read this session: `186-CONTEXT.md`, `REQUIREMENTS.md`, `STATE.md`, `ROADMAP.md` (Phase 186 section), `V1.46-PREP.md`, `AGENTS.md`, `.github/workflows/ci.yml`, `mix.exs`, `dev/mix/tasks/verify/*.ex`, `dev/mix/tasks/verify.{ex,phase99.ex,phase11.ex,ops_ui.ex,namespace_fence.ex,workspace_clean.ex}`, `test/mix/tasks/{ui_contrast_contract,ui_tokens_contract,ui_literal_contract,workflow_wiring,dependency_boundary_contract,verify_capability,verify.phase99}_test.exs`, `test/support/release/package_contract.ex`, `examples/scrypath_ecommerce/contrast-checker.mjs`, `scrypath_ops/assets/css/app.css`, `scrypath_ops/test/scrypath_ops_web/surface_depth_token_contract_test.exs`, `scripts/ci/{ui_literal_policy,ui_state_pairs,ecommerce_evidence}.cjs`, `scripts/ci/ui_state_pairs.test.cjs`, `deps/req/lib/req.ex`.
- Commands run: `gh api repos/szTheory/scrypath/branches/main/protection`, `.../rulesets`, `.../actions/permissions/workflow`, `.../actions/runs/44431707668/jobs`, `gh pr view 126`; `unzip -l`, `unzip -Z1`, `shasum -a 256` on the pinned zip; Elixir `:zip` probes; Tailwind rebuild to the scratchpad; contrast checker, ops regex tests, root ui tests, wiring and boundary tests, `ui_state_pairs.test.cjs`; throwaway prototypes in the session scratchpad (`proto/structure_proto.cjs`, `proto/built_fresh_proto.mjs`, `proto/scan_proto.mjs`, `exproto/zipcheck*.exs`).

### Secondary (MEDIUM confidence)
- `V1.46-PREP.md` claims not re-run here: the 16 of 16 post-lift projection, ExDoc stylesheet bugs, font coverage and metrics.

### Tertiary (LOW confidence)
- None used. No external web source was needed: no library documentation question remained open, so the research-plan seam was not invoked.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH, nothing new is installed and every library is already locked.
- Architecture: MEDIUM, the `applied` flag, wrapper attachment and allowlist tags are recommendations.
- Pitfalls: HIGH, each was observed by reading or running.

**Research date:** 2026-11-18
**Valid until:** 2026-12-02 (14 days; the tree and the brand zip are both moving: Pages serves from `main`, and `main` will gain the Phase 186 commits)
