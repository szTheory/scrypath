---
phase: 186-ingest-pin-and-guard
fixed_at: 2026-11-19T04:54:25Z
review_path: .planning/phases/186-ingest-pin-and-guard/186-REVIEW.md
iteration: 1
findings_in_scope: 9
fixed: 9
skipped: 0
status: all_fixed
final_code_sha: ea9c859c83f37a068ecb9af8f4c5dd67f1a25f40
---

# Phase 186: Code Review Fix Report

**Fixed at:** 2026-11-19T04:54:25Z
**Source review:** `.planning/phases/186-ingest-pin-and-guard/186-REVIEW.md`
**Iteration:** 1
**Scope:** CR-01 and WR-01 to WR-08. Info findings IN-01 to IN-07 were not in scope and none was touched (`write!/3` was not edited, so IN-01 stands).

**Summary:**
- Findings in scope: 9
- Fixed: 9 (WR-05 is fixed with residual limits that are documented, see its entry)
- Skipped: 0

**Final code SHA:** `ea9c859c83f37a068ecb9af8f4c5dd67f1a25f40`. Every commit after it touches only `.planning/` (the playbook update and this file).

**Where this ran.** In the main checkout `/Users/jon/projects/scrypath` on `feat/v1.46-186-brand-pin-and-guard`, as the orchestrator directed. `workflow.use_worktrees` is `true` in `.planning/config.json`, but no worktree, temporary branch or recovery sentinel was created: a hand-rolled worktree has no `deps/`, `_build/` or `node_modules`, so the gates below could not have run in it. The pre-existing local edits to `.planning/STATE.md`, `.planning/config.json` and `.planning/state.json` were never staged or committed.

## Fixed Issues

### CR-01: Zip-bomb cap defeated by a lying central directory

**Disposition:** fixed
**Commit:** `dc67609b`
**Files:** `dev/mix/tasks/brand/update.ex`, `test/mix/tasks/brand_pin_contract_test.exs`
**What changed:** `extract!` no longer calls `:zip.zip_get/2`. Each allowlisted member is read through its local header and inflated with `:zlib.safeInflate` under a byte budget equal to the size the central directory declares; the first output chunk that crosses the budget raises `member ... inflates past its declared size N`, so at most the budget plus one 16 KiB buffer is ever held. Added checks the review did not ask for but the same trust gap needs: the local header must name the same member and agree with the central directory sizes, the member must inflate to exactly the declared size, the CRC-32 must match, and encrypted members and methods other than stored and deflate are refused. `refresh!/3` is now `@doc false def` so the "nothing is written" case can be tested end to end.
**Deviation from the suggested fix:** `:zlib.setBufSize/2` no longer exists in OTP 28, so the budget is enforced per safeInflate chunk instead of by shrinking the buffer. The "pinned size" half of the orchestrator's instruction is met by two existing and new layers: the declared sizes are summed and compared with the pinned uncompressed total (and the 16 MiB cap) before any inflation, and the online check now compares each extracted member's size and hash with its pin entry (see WR-01).
**Evidence:** tests build archives that declare 10 bytes and hold 20,000,000 (refused with the distinct message, and a `refresh!` from it leaves the target directory empty), a lie in the central directory only (local header disagrees), a short member, a bad CRC, an unsupported method, a corrupt deflate stream, and an honest archive. Deleting the budget check turns two tests red. The real brand archive (sha256 `3fc6d80f...`) extracts through the new path in about 32 ms to a tree byte-identical to the committed `brand/` and fonts directories.

### WR-01: Per-asset hashes bound to nothing the test owns

**Disposition:** fixed
**Commit:** `ea95bfd3`
**Files:** `dev/mix/tasks/brand/update.ex`, `dev/mix/tasks/verify/brand.ex`, `test/mix/tasks/brand_pin_contract_test.exs`, `CONTRIBUTING.md`
**What changed:** Two layers. (1) The contract test now owns `@expected_assets_digest`, the sha256 over the sorted `path:sha256` lines of every pinned asset (`361c8fc6...`), so a change that edits an asset together with its pin entry needs a second reviewed edit in a different file. A test proves the edited-together case passes `verify.brand` but fails the digest, and another proves `Update.assets_digest/1` and the test's independent definition agree. (2) `check_live!/2` now extracts the archive and compares every member with its pin entry (size, sha256) and with the committed file, so a maintainer who edits the pin, the asset and both constants together is still caught by the online check. The refresh message prints both constants. The trade-off is written in the `Mix.Tasks.Brand.Update` and `Mix.Tasks.Verify.Brand` module docs, in the test header, and in the CONTRIBUTING ledger row (a refresh edits the pin plus two test-owned constants).
**Evidence:** three online-check tests (edited pin size, edited pin hash, edited committed file) go red if the member comparison is removed; the digest tests go red if the constant changes. `check_live!` against the real archive stubbed through `Req.Test` passes on the committed tree.

### WR-02: https-to-http redirect followed

**Disposition:** fixed
**Commit:** `d6d9c0af`
**Files:** `dev/mix/tasks/brand/update.ex`, `test/mix/tasks/brand_pin_contract_test.exs`
**What changed:** `fetch!/2` builds the request with a prepended `https_only` request step. Req re-runs request steps on every redirect hop (confirmed in `deps/req/lib/req/steps.ex`), so a downgrade halts with `refusing non-https hop http://...` before the plain-http request is made.
**Evidence:** a `Req.Test` stub that answers 302 to `http://` is refused and receives exactly one request (the https one); an https-to-https redirect is still followed; removing the step turns the downgrade test red.

### WR-03: Uppercase `--sha256` written to the pin unnormalized

**Disposition:** fixed
**Commit:** `c9206008`
**Files:** `dev/mix/tasks/brand/update.ex`, `test/mix/tasks/brand_pin_contract_test.exs`
**What changed:** `expected_from_opts!/1` lowercases `--sha256` and requires 64 hex characters before anything is read or written.
**Evidence:** an uppercase value is stored lowercase, printed lowercase for the test constant, and the written tree passes `verify.brand`; values that are 63 characters, non-hex or empty are refused with the target directory still empty. Removing the downcase turns the uppercase test red. Running the real archive with an uppercase hash now reproduces the committed pin byte for byte.

### WR-04: Active-content scanner bypasses

**Disposition:** fixed
**Commit:** `152c0f4c`
**Files:** `dev/mix/tasks/verify/brand.ex`, `test/mix/tasks/brand_pin_contract_test.exs`
**What changed:** Added detection for protocol-relative `//host` URLs (in `href`, `src`, `srcset` and `url()`), `data:` URIs, numeric and obfuscating character references (`&#`, `&Tab;`, `&colon;` and similar), tab- or newline-split `javascript:`, event handlers preceded by a slash or quote, SMIL `<set>` and `<animate>` elements (refused wholesale), and CSS-escaped rules (the text is scanned both as written and with CSS escapes resolved). SVG and CSS must reference only fragments inside the file; HTML is exempt because the README snippet links sibling files. UTF-16 and UTF-32 files with a BOM are decoded before scanning, and a NUL byte or invalid UTF-8 is now refused instead of skipped. The original eight labels keep their order and first claim on a match (their patterns were widened to cover the bypasses), so the existing label assertions are unchanged.
**Deviation from the suggested fix:** the reviewer proposed inverting the logic (refuse any `on` attribute name, refuse unless UTF-8 with no BOM). I added the specific bypasses and the fragment-only rule instead, as the orchestrator directed, because the real assets are plain enough (the 23 SVG, CSS and HTML files use only `svg` and `path` with `class d fill height role viewBox width xmlns`, no `href`, `url(`, entity or backslash) that the stricter rules cost nothing today and a refresh that needs more is a maintainer decision.
**Found while doing it:** the review reported the patterns as linear, but the existing `url\(\s*["']?\s*http` and `href\s*=\s*["']?\s*http` patterns split two whitespace runs and were quadratic (1.1 s on 60 KB of spaces; roughly 50 s extrapolated to the 400 KB ceiling). They are now one flat character class. A timing test (six hostile inputs, under 1 s at 70 KB) goes red on the old form.
**Evidence:** 19 planted bypass fixtures through a rehashed pinned file, all four UTF-16 and UTF-32 BOM variants, a BOM-less wide file, a NUL byte, invalid UTF-8, a clean UTF-8 BOM (accepted), and the unchanged real tree (`verify.brand: ok (44 assets, 326773 bytes)`).

### WR-05: Structural comparator can pass vacuously

**Disposition:** fixed: requires human verification (the thresholds are a judgment call; the residual limits below are documented, not eliminated)
**Commit:** `1d0dd1f6`
**Files:** `scripts/ci/ui_state_pairs.cjs`, `scripts/ci/ui_state_pairs.test.cjs`, `scripts/ci/fixtures/ui-state-pairs/PROVENANCE.md`
**What changed:** A second per-block, recolor-invariant signal, the count of horizontally and vertically adjacent pixel pairs whose RGBA differs, and an absolute ceiling of 8 blocks over beside the 0.25 percent rule (0.25 percent of a 1440 x 900 capture is 12 blocks). A block is over on the edge signal when its count moves by more than 12. Result objects gain `edge_blocks_over` and `worst_edge_delta`. No existing threshold was loosened.
**Calibration (unchanged results):** the four committed crops give the same share results (accept 0 of 500, state reject 179, shift reject 71). On the edge signal the real recolor crop is 0 of 500 over (worst delta 1), the real state change 333 of 500, the shifted band 60 of 500. On the four full real cool-to-warm recolors (light and dark, 390 and 1440, not committed) the worst edge delta is 5, 2, 7 and 2 with 0 blocks over, so the threshold of 12 has at least 1.7 times margin; the two real state changes measured are 568 of 1725 and 816 of 6210 blocks over.
**Probes from the review, all rejected now** (each was accepted by the share-only check at 1440 x 900): added full-width solid header (90 edge blocks over, 0 share blocks), added solid sidebar, 1 px rule added, 1 px rule moved by 8 px (0 share blocks, 112 edge blocks), 400 x 320 card with a 1 px border, and 12 new striped blocks (rejected by the cap and the edge signal). A palette swap of the full synthetic layout is accepted with 0 over on both signals. Removing the edge signal, removing the cap, or raising the edge threshold to 40 each turn the matching tests red.
**Residual limits (documented in `PROVENANCE.md` "Limits", and one planted as a documented-limit test):** an edge that moves 1-2 px but stays inside one 16 px block is invisible to both block-count signals; neither signal is font-invariant (a font change is expected to be rejected, which matters for Phase 187's font wiring); a recolor that makes two identical neighbouring surfaces distinct changes the edge count along that boundary (a few blocks are tolerated, a long new border is rejected); the thresholds were calibrated on one real recolor family and retuning needs a new real capture pair. The geometry, copy, state, action, transport and identity checks stay exact beside it. A human should decide whether a long newly visible border in the Phase 187 recolor (for example the dark surface elevation ramp) may need a retune.
**Evidence note:** `scripts/ci/ui_state_pairs.cjs` and its test are in `PRESERVATION_FIXTURE_FILES`, so any capture taken with the Plan 03 comparator carries a different fixture-overlay digest than one taken now. No Phase 187 "before" capture is known to exist yet; confirm before capturing.

### WR-06: Report says `exact-match` under schema v3

**Disposition:** fixed
**Commit:** `4d51f28f`
**Files:** `scripts/ci/ui_state_pairs.cjs`, `scripts/ci/ui_state_pairs.test.cjs`
**What changed:** Consumers were grepped first: nothing outside the pair script and its own test reads the schema or the status (the `.planning` receipts quoting `exact-match` are historical and were not touched). The report now carries schema `scrypath.ui-state-pair-comparison.v4`, status `structural-match` (failures stay `mismatch`) and a new `pixel_comparison: "structural-recolor-tolerant-v1"`. The `*_pixels_equal` field names are kept (changing them is wider than the finding) with a comment that they mean structural equality. No v3 report was produced under the structural comparator, so the `v1` label has no earlier meaning.
**Evidence:** the main pair test asserts the new schema, status and field; the output-writing test uses the new values.

### WR-07: Retired-value scanner false negatives

**Disposition:** fixed
**Commit:** `d4c75074`
**Files:** `examples/scrypath_ecommerce/ui-tokens.test.mjs`
**What changed:** The scan now matches `%23` hex (the data-URI form), `0x` literals, quoted bare tokens (JSON and YAML), decimal and percent `rgb()` and `rgba()` channels, and `color(srgb ...)`, all still without nested quantifiers. Files with a UTF-16 BOM, or recognizably UTF-16 without one (a quarter or more NUL bytes, nearly all at one parity), are decoded instead of skipped; known binary extensions are skipped without reading; a NUL byte in a text-extension file of unknown encoding now fails the scan with a clear message (previously it was skipped); unknown-extension binaries are still skipped. The deny set moved into one unquoted template-literal list because the new quoted-token pattern otherwise matched the guard's own array. The tree had none of these forms, so the allowlist did not change.
**Evidence:** a planted fixture per form (six), all four UTF-16 variants, the failure-to-scan case, and accept cases for new-identity values in every encoding and for real binaries (`.png`, `.woff2`, an unknown `.dat`). Each of seven pattern or decoding removals (`%23`, `0x`, quoted tokens, `color(srgb)`, decimal and percent channels, the NUL failure, BOM decoding) turns its planted test red.

### WR-08: Allowlist is path-level

**Disposition:** fixed
**Commit:** `feb0ddbe`
**Files:** `examples/scrypath_ecommerce/ui-tokens.test.mjs`, `examples/scrypath_ecommerce/retired-identity-allowlist.json`
**What changed:** Every entry carries `max_hits`, the number of retired-value occurrences across the files it covers, seeded from the live scan (22 entries, 485 in total; `brandbook/` is 270 of them). More hits than `max_hits` fails as `unlisted retired identity values in allowlisted entry ...` (so the existing "no unlisted value" live test catches it); fewer fails with `lower max_hits to N`; a missing or non-positive-integer `max_hits` fails; a prefix entry must be tagged `retire-last`. A test-owned `HITS_CEILING = 485` must equal the sum of all `max_hits`, so raising or lowering any count is an edit in two files (the second key). The allowlist's entry list is unchanged.
**Evidence:** planted growth in a listed file, growth through a different form, growth inside a prefix, a drop below the ceiling, missing and invalid `max_hits`, a non-`retire-last` prefix, and the sum ceiling in both directions; each guard removed turns its test red. A live probe that appended one retired value to `README.md` failed with `3 found, max_hits is 2` (reverted).

## Extra commit

- `ea9c859c` (`test(186): capture the redirect debug log in the brand pin contract test`): the two redirect tests printed Req's debug log into the suite output; the module now captures logs. Test-only, no behavior change.

## Verification

All commands used `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5`, ran in the **main checkout** (not an isolated worktree), and were run once on the final code SHA `ea9c859c` unless noted. Cheap checks ran first, and again on `ea9c859c` before the full gate.

| Command | Result |
|---|---|
| `node examples/scrypath_ecommerce/contrast-checker.mjs` | pass (0 AA failures, 135 AAA advisory) |
| `node --test examples/scrypath_ecommerce/ui-tokens.test.mjs` | pass: 42 tests (was 25) |
| `node --test scripts/ci/ui_state_pairs.test.cjs` | pass: 33 tests (was 24) |
| `MIX_ENV=test mix test` on the seven named files, `--exclude contrast_child` | pass: 228 tests, 0 failures, 3 excluded (the brand pin file alone: 96 tests, was 55) |
| `mix format --check-formatted` | pass |
| `MIX_ENV=test mix credo --strict` | pass: 280 files, no issues |
| `MIX_ENV=test mix verify.brand` | pass: `verify.brand: ok (44 assets, 326773 bytes)` |
| `mix verify.core --exclude integration --exclude docs_contract` on `ea9c859c` | **pass, exit 0**: format, packaged-paths workspace clean, compile with warnings as errors, credo, 5 properties and 1158 tests with 0 failures (103 excluded), docs with warnings as errors, then the isolated no-optional-deps compile |

The `contrast_child` tests (clone-based, nested gates) were excluded from the targeted cheap run as instructed; they are not excluded by default in `test/test_helper.exs`, so they ran inside the `mix test` step of `verify.core`.

Not run: `verify.repository_contracts`, `verify.ops_ui` and `verify.package`. This iteration changed no workflow, package, `scrypath_ops` or `.github` file, but none of the three was re-run and none is claimed passed. No fetch-dependent gate was attempted, so no escalated permission was needed or denied. Hosted CI has not run (nothing was pushed).

**Note for later runs:** running `node examples/scrypath_ecommerce/contrast-checker.mjs` from the repository root writes an untracked `test-results/` directory there, and the deny-list scan (which covers untracked-but-not-ignored files) then flags the retired hexes in its report. I removed it after each run. Run the checker from `examples/scrypath_ecommerce/` or delete `test-results/` before the token test.

## Commit ledger

| Finding | Commit |
|---|---|
| CR-01 | `dc67609b` |
| WR-02 | `d6d9c0af` |
| WR-03 | `c9206008` |
| WR-01 | `ea95bfd3` |
| WR-04 | `152c0f4c` |
| WR-05 | `1d0dd1f6` |
| WR-06 | `4d51f28f` |
| WR-07 | `d4c75074` |
| WR-08 | `feb0ddbe` |
| log noise (extra) | `ea9c859c` (final code SHA) |

---

_Fixed: 2026-11-19T04:54:25Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
