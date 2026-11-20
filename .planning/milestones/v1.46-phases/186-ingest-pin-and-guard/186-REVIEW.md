---
phase: 186-ingest-pin-and-guard
reviewed: 2026-11-19T04:24:19Z
depth: standard
files_reviewed: 19
files_reviewed_list:
  - dev/mix/tasks/brand/update.ex
  - dev/mix/tasks/verify/brand.ex
  - examples/scrypath_ecommerce/contrast-checker.mjs
  - examples/scrypath_ecommerce/ui-tokens.test.mjs
  - examples/scrypath_ecommerce/retired-identity-allowlist.json
  - scrypath_ops/assets/css/token-map.json
  - scripts/ci/ui_state_pairs.cjs
  - scripts/ci/ui_state_pairs.test.cjs
  - test/mix/tasks/brand_pin_contract_test.exs
  - test/mix/tasks/dependency_boundary_contract_test.exs
  - test/mix/tasks/ui_contrast_contract_test.exs
  - test/mix/tasks/ui_tokens_contract_test.exs
  - test/mix/tasks/ui_tokens_helper_test.exs
  - test/mix/tasks/workflow_wiring_test.exs
  - test/support/ui_tokens.ex
  - scrypath_ops/test/scrypath_ops_web/surface_depth_token_contract_test.exs
  - mix.exs
  - .github/workflows/ci.yml
  - CONTRIBUTING.md
findings:
  critical: 1
  warning: 8
  info: 7
  total: 16
  necessity: 1
status: issues_found
---

# Phase 186: Code Review Report

**Reviewed:** 2026-11-19T04:24:19Z
**Depth:** standard
**Files Reviewed:** 19
**Status:** issues_found

## Summary

Phase 186 adds an offline-verified brand pin, an untrusted-zip refresh task, a token-parity and retired-value
deny-list, a recolor-tolerant pixel comparator, and the CI-contract tests around them. The baseline is green: the
brand pin and helper ExUnit files (65 tests), `ui-tokens.test.mjs` (25 of 25) and `ui_state_pairs.test.cjs`
(24 of 24) all pass. The `ci.yml` and `mix.exs` changes only add the pair test to the existing Node step and register
two task environments; neither weakens a gate. No fixed-size gate slack exists today (pending 38/38, hex-outside
34/34, allowlist 22/22), and I found no retired value hiding in the repo in a non-`#` form.

The problems are in the controls themselves. Where I could, I reproduced each one with a probe kept outside the
repo:

- The zip-bomb cap in `brand.update` checks sizes the archive itself declares, and the extraction step inflates
  without a bound (reproduced: declared 10 bytes, 100,000,000 bytes inflated). This is the one blocker.
- The pin does not bind the vendored bytes to anything the test owns, and the online check never compares archive
  members to the committed files, so the claimed "two-key" property does not hold for the assets.
- `fetch!` follows an https-to-http redirect (reproduced).
- The active-content scanner and the retired-value scanner are deny-lists with several cheap bypasses (reproduced).
- The structural comparator passes grid-aligned flat regions, 1-2 px lines and up to 12 whole new blocks on a desktop
  raster (reproduced), while its report still says `exact-match`.

`ReDoS` was checked and is not present: the `verify.brand` regexes and both deny-list regexes ran linearly on
adversarial whitespace runs. Zip slip is structurally impossible because no archive member name ever becomes a path
(`write!` derives destinations from the compile-time allowlist). The wider CI Node step (build, lifecycle, evidence,
target) did not finish inside my time budget, so I did not confirm it separately.

## Critical Issues

### CR-01: Zip-bomb cap is defeated by a lying central directory; `extract!` inflates without a bound

**File:** `dev/mix/tasks/brand/update.ex:150-170` (also `385-398`, `451-463`)
**Issue:** Every size cap runs against the sizes the archive declares for itself. `list_entries!/1` reads the declared
uncompressed size from the central directory (`elem(info, 1)`), and `check_uncompressed!/2` and the 16 MiB cap are
applied to that sum. `extract!/2` then calls `:zip.zip_get/2`, which inflates the whole member into memory, and only
afterwards compares `byte_size(bytes)` with the declared size (lines 159-165). OTP does not enforce the declared size
during inflation, so the post-check runs after the allocation it was meant to prevent.

I confirmed this on OTP 28.5: a 354 KB archive whose central and local headers declare 10 bytes, and whose deflate
stream holds 100,000,000 zero bytes, passes `zip_list_dir` with "declared size 10" and `zip_get` returns
100,000,000 bytes. Deflate reaches roughly 1000:1, so an 8 MiB archive (under `@max_zip_bytes`) can ask for
about 8 GB in one `zip_get`. The SHA-256 does not save this: in the refresh path the hash is the maintainer's own
`--sha256` argument, and the check mode prints the actual hash in its mismatch message, so it is natural to copy it.
There is also no test for the declared-versus-actual branch, so nothing exercises this check.

**Fix:** Do not use `:zip.zip_get/2` on untrusted input. Inflate each allowlisted member with a byte budget, for
example by reading the member's raw compressed range from the central-directory record (`offset`, `comp_size`),
parsing the local header, and driving `:zlib` with a bounded loop:

```elixir
defp bounded_inflate!(compressed, limit) do
  z = :zlib.open()
  try do
    :ok = :zlib.inflateInit(z, -15)
    do_inflate(z, :zlib.safeInflate(z, compressed), [], 0, limit)
  after
    :zlib.close(z)
  end
end

defp do_inflate(_z, {:finished, out}, acc, size, limit), do: finish!(acc, out, size, limit)
defp do_inflate(z, {:continue, out}, acc, size, limit) do
  size = size + IO.iodata_length(out)
  if size > limit, do: refuse!("member inflates past its declared size #{limit}")
  do_inflate(z, :zlib.safeInflate(z, []), [acc | out], size, limit)
end
```

Pass the member's declared size as `limit`, refuse any member whose local-header size differs from the central
directory, and add a test that builds an archive with a falsified declared size (the probe in this review is a
10-line recipe: patch the 4 bytes at offset 24 of the central header and 22 of the local header).

## Warnings

### WR-01: The pin's per-asset hashes are bound to nothing the test owns, and the online check never compares members to them

**File:** `test/mix/tasks/brand_pin_contract_test.exs:18-31` and `204-211`; `dev/mix/tasks/brand/update.ex:209-214`; `dev/mix/tasks/verify/brand.ex:148-163`
**Issue:** The "two-key" claim (pin file plus test-owned constant; CONTRIBUTING row 1) only covers the four archive
fields (`zip_sha256`, size, entries, uncompressed bytes). Each asset's own `sha256` and `size` live only in
`brand/brand.pin.json`, next to the files they describe. A change that edits `brand/assets/docs/scrypath-exdoc.css`
and the matching pin entry, and leaves `zip_sha256` alone, passes `verify.brand` and every test. The test at line
204 already proves it: it appends to a pinned SVG, re-hashes the pin entry, and asserts `Brand.check!(tmp) == :ok`.
The online check does not close the gap either: `check_live!/2` verifies only that the downloaded archive matches
the pinned archive hash. It never extracts the allowlisted members and compares them with the pinned asset hashes
or with the committed files. Nothing in the repo ever re-derives the vendored bytes from the archive after refresh.
**Fix:** Either extend `check_live!/2` to run `extract!/2` and compare each member's sha256 and size with the pin
and with the file on disk, or give the test a second constant that covers the vendored bytes, for example a single
digest over the sorted `path:sha256` lines:

```elixir
@expected_assets_digest "..."   # sha256 of "path:sha256\n" for every pinned asset, sorted by path
test "pinned asset hashes equal the test-owned digest" do
  digest = read_pin!(@root)["assets"] |> Enum.sort_by(& &1["path"])
           |> Enum.map_join(&"#{&1["path"]}:#{&1["sha256"]}\n") |> sha256()
  assert digest == @expected_assets_digest
end
```

Update the refresh message to say the second constant changes too, and fix the CONTRIBUTING wording to match.

### WR-02: `fetch!` is documented as https-only but follows an https-to-http redirect

**File:** `dev/mix/tasks/brand/update.ex:192-206`
**Issue:** The scheme check at line 193 covers only the first URL. Req follows up to `max_redirects: 3` and does not
refuse a scheme downgrade. I reproduced it with a `Req.Test` plug: an https request answered with
`302 location: http://...` returned the body served over plain http. In the check path the pinned hash still
refuses wrong bytes, so the damage there is a confusing failure. In the `--url` refresh path the hash comes from the
operator, so a downgrade turns the "only https URLs are accepted" guarantee into a cleartext fetch.
**Fix:** Enforce the scheme on every hop with a request step (Req re-runs request steps for each redirect):

```elixir
req =
  [decode_body: false, max_redirects: 3, retry: false, into: &capped_chunk/2]
  |> Kernel.++(req_options)
  |> Req.new()
  |> Req.Request.prepend_request_steps(
    https_only: fn request ->
      if request.url.scheme == "https",
        do: request,
        else: Req.Request.halt(request, %RuntimeError{message: "refusing non-https hop #{request.url}"})
    end
  )

case Req.get(req, url: url) do ...
```

Add a stub test that redirects to `http://`.

### WR-03: An uppercase `--sha256` passes the check but is written to the pin unnormalized, which `verify.brand` then rejects

**File:** `dev/mix/tasks/brand/update.ex:233`, `266`, `362-368`; `dev/mix/tasks/verify/brand.ex:20`, `82`
**Issue:** `check_sha256!/2` downcases only for the comparison. `expected_from_opts!/1` stores `opts[:sha256]` as given,
`refresh!/3` passes it to `build_pin/2` as `zip_sha256`, and the follow-up message prints it for the test constant.
`@hex64` in `verify.brand` is lowercase-only, so a refresh run with an uppercase hash (as many tools print) writes a
pin that the very next `verify.brand` run refuses, and tells the maintainer to paste an uppercase value into the test.
**Fix:** Validate and normalize in `expected_from_opts!/1`:

```elixir
sha256 = String.downcase(opts[:sha256])
unless sha256 =~ ~r/\A[0-9a-f]{64}\z/, do: Mix.raise("brand.update: --sha256 must be 64 hex characters")
%{sha256: sha256, ...}
```

### WR-04: The active-content scanner is a deny-list with several cheap bypasses

**File:** `dev/mix/tasks/verify/brand.ex:19-32`, `165-173`
**Issue:** I ran the eight patterns against probe inputs. All of these pass unflagged:

| Probe | Why it passes |
|-------|---------------|
| `<a href="//evil.example/x">` and `url(//evil.example/a.png)` | patterns require the literal `http` |
| `<use href="data:image/svg+xml;base64,...">` | `data:` is not listed |
| `href="&#106;avascript:alert(1)"` | entity-encoded scheme |
| `<img/src=x/onerror=alert(1)>` in the `.html` snippet | handler pattern needs whitespace before `on...` |
| `<set attributeName="onmouseover" to="alert(1)"/>` | handler arrives as an attribute value |
| `@\69mport "https://..."` | CSS escape |
| a UTF-16 (BOM) SVG with `<script>` | the byte-level regexes never see ASCII |

The control is described as T-186-04 and is meant to catch a hostile or compromised upstream refresh, so each
bypass is a way through. Note that the scan also does not run in `mix brand.update`; it only runs later in
`verify.brand`.
**Fix:** Invert the logic for the three scanned types. Refuse a file that is not valid UTF-8 or starts with a BOM or
contains a NUL. Require every `href`, `xlink:href` and `url(...)` argument to start with `#`, refuse `data:` and
entity references (`&#`) inside attribute values, refuse `<set`, `<animate`, `<use` with non-fragment targets, and
refuse any `on` attribute name regardless of the preceding character. Keep the existing patterns as a second layer.

### WR-05: The structural comparator can pass vacuously for flat, aligned and thin-line changes

**File:** `scripts/ci/ui_state_pairs.cjs:27-31`, `518-553`, `584-602`
**Issue:** The check compares, per 16 px block, the share of pixels that differ from the block's most common color,
rounded to 16 steps, and tolerates a delta of 2 steps (about 12-19 percent of a block) in any block, plus 0.25
percent of blocks over. I ran `comparePngStructural` on synthetic 1440 by 900 pages:

- an added 1440 by 64 solid header bar: `equal=true`, 0 of 5130 over
- an added 240 by 900 solid sidebar: `equal=true`, 0 of 5130 over
- a full-height 1 px rule moved by 8 px: `equal=true`, worst step 0
- a 400 by 320 white card with a 1 px border added to a plain page: `equal=true`, 0 over, worst step 2
- 12 completely new striped blocks: `equal=true` (12 of 5130 is under 0.25 percent)

Aligned flat regions have only uniform blocks, so their share is 0 in both images. 1-2 px lines are under the
step tolerance. Surface fills, borders and dividers are exactly what a re-skin changes, and the PROVENANCE "Limits"
paragraph and the code comment mention only band shifts, not these classes. Different sizes are correctly treated as
unequal, so that part is sound.
**Fix:** Add a second recolor-invariant signal per block: the count of horizontally and vertically adjacent pixel
pairs whose RGBA differ, attributing a pair that straddles a block edge to the block of its first pixel. A
palette swap that keeps regions distinct leaves it unchanged, while borders, aligned fill edges and moved rules
change it. Calibrate on the same four fixtures, add planted cases for the five probes above, and record the new
limits in `PROVENANCE.md`.

### WR-06: Pair report still says `exact-match` and keeps schema v3 although equality is now structural

**File:** `scripts/ci/ui_state_pairs.cjs:12`, `702`; `scripts/ci/ui_state_pairs.test.cjs:295`, `714`
**Issue:** A candidate whose every pixel was recolored now yields `passed: true` and `status: "exact-match"`, under
the same `scrypath.ui-state-pair-comparison.v3` schema string that earlier receipts used for byte-exact
comparisons. Phase 185 archives already quote "exact-match" as pixel-identical evidence, and the repository's own
rule is to never claim more than the automated evidence proves. The summary records this as a deliberate cosmetic
deferral, but the label is the one string a later closeout will copy.
**Fix:** Emit a distinguishing value now, for example `status: "structural-match"` and `pixel_comparison:
"structural-recolor-tolerant-v1"`, bump the schema to v4, and update the two test references. If a rename is out of
scope, at least add the `pixel_comparison` field so consumers can tell the modes apart.

### WR-07: Retired-value scanner has several false negatives

**File:** `examples/scrypath_ecommerce/ui-tokens.test.mjs:689-690`, `718-730`, `750-757`
**Issue:** I ran the two patterns on probes of a denied value. These do not match: `%23191e25` (the usual form
inside `url("data:image/svg+xml,...")` data URIs, which is where background textures and icons carry colors),
`rgb(25.0 30.0 37.0)`, `rgb(9.8% 11.8% 14.5%)`, `color(srgb 0.098 0.118 0.145)`, a bare `"191E25"` in JSON and
`0x191e25` in JS. Separately, `scanFiles` skips any file with a NUL in its first 8192 bytes, so a UTF-16 CSS or SVG
file, or a text file with a planted NUL, is never scanned. I grepped the live tree for these forms and found nothing
today, so this is a gap, not a present leak.
**Fix:** Percent-decode `%23` before matching, widen the rgb pattern to `[\d.]+%?` and normalize before the triplet
lookup, and treat a NUL-bearing file with a text extension (`.css .svg .html .js .mjs .json .md`) as a failure to
scan rather than a skip (or decode it as UTF-16LE first). Add a planted case for each form.

### WR-08: The allowlist is path-level, so "shrink-only" is not enforced for files already on it

**File:** `examples/scrypath_ecommerce/ui-tokens.test.mjs:16-23`, `52-56`, `779-826`
**Issue:** The header says a new entry "means a new retired value landed in a new file", but a retired value that
lands in a file already listed is invisible. `scrypath_ops/assets/css/app.css`, the tracked built CSS and the whole
`brandbook/` prefix are listed, so a new `background: #1b2230` anywhere in them passes. The stale check only needs
one hit in any covered file (lines 817-824), entries record no expected hit count, and the ceiling counts entries
rather than hits. A single `prefix` entry can also silently widen coverage to a whole directory.
**Fix:** Store the current hit count (or the sorted set of denied values) per entry and fail when a file's count
rises or an unlisted value appears; tighten `prefix` entries to named directories and require `retire-last` for
them. The planted tests already have the scaffolding to prove a rising count fails.

## Info

### IN-01: `write!/3` validates inside the write loop and writes through symlinks

**File:** `dev/mix/tasks/brand/update.ex:173-189`
**Issue:** The allowlist check runs per entry inside the loop, so a rogue entry after valid ones leaves a partial
tree and the old pin (the offline verify then fails, so it is fail-safe, but untidy). `File.write!` follows symlinks,
so a checkout where `brand` or one of its files is a symlink is written through before `verify.brand` can refuse it.
**Fix:** Validate every entry first, then write; `File.lstat` each destination (and the owned directories) and refuse
a symlink before writing.

### IN-02: Hard-coded commit id in `@brand_license` goes stale on the first refresh

**File:** `dev/mix/tasks/brand/update.ex:23`
**Issue:** The license string embeds `at ced7c40e`, and `build_pin/2` stamps it into the `license` field of all 44
asset rows, while the `--commit` flag can name a different commit.
**Fix:** Drop the commit from the constant, or interpolate `source_meta.repository_commit` in `build_pin/2`.

### IN-03: The ExUnit wrapper does not require the planted or accept tests to run

**File:** `test/mix/tasks/ui_contrast_contract_test.exs:88-120`
**Issue:** `@token_test_names` lists the seven live tests, so deleting or renaming every planted and accept case in
`ui-tokens.test.mjs` (the proof that each check can fail) leaves the wrapper green.
**Fix:** Add the 17 planted and accept names, or assert `# tests 25` and update the number deliberately.

### IN-04: Storybook boundary tests guard a dependency that does not exist yet

**File:** `test/mix/tasks/dependency_boundary_contract_test.exs:610-698`
**Category:** necessity
**Issue:** `phoenix_storybook` appears nowhere in the root `mix.exs`, `lib/`, or `scrypath_ops/mix.exs` (grep is
empty), so the three live tests pass vacuously (the file says so) and cost one of the 12 required-gate ledger slots.
This is a judgment call because v1.47 is planned to add the dependency, so the guard will become live; but the
boundary can be added in the phase that adds the dependency, and the slot saved until then. Separately,
`dependency_options!/2` matches `{^dependency, _version} -> []` first, so a compliant keyword-only declaration such
as `{:phoenix_storybook, github: "...", only: [:dev, :test]}` (a two-tuple in the AST) would be reported as a
violation.
**Fix:** Move these tests into the v1.47 phase, or keep them and reorder the helper so a keyword second element is
read as options.

### IN-05: `UiTokens.relative_luminance/1` is dead code with a different WCAG constant

**File:** `test/support/ui_tokens.ex:113-121`; `test/mix/tasks/ui_tokens_helper_test.exs:95-100`
**Issue:** Only its own test calls it. The ops contract test copies its own `luminance/1`, and `contrast-checker.mjs`
uses `0.04045` where this helper uses `0.03928`.
**Fix:** Delete the function and its test, or use it in a contract test and align the constant.

### IN-06: Ratchet ceilings never tighten themselves

**File:** `examples/scrypath_ecommerce/ui-tokens.test.mjs:52-56`
**Issue:** The three ceilings equal the live counts today (verified: 38, 34, 22), but nothing fails when a count
drops below its ceiling. After Phase 187 flips rows, a forgotten ceiling quietly becomes slack that lets pending
cells or non-brand hexes grow back.
**Fix:** Fail when `count < ceiling` with "lower the ceiling to N", which makes every drop an explicit edit.

### IN-07: "Built CSS parity" covers only `--color-*` and `--ops-*` keys

**File:** `examples/scrypath_ecommerce/ui-tokens.test.mjs:66`, `393-408`
**Issue:** `TOKEN_KEY` limits the comparison, but the header says the emissions hold "the same token values as the
source blocks". Radius, depth and size properties in the tracked CSS can drift unnoticed.
**Fix:** Say so in the header, or compare all source properties.

---

_Reviewed: 2026-11-19T04:24:19Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
