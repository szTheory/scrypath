---
phase: 11-public-release-contract
reviewed: 2026-04-16T20:40:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - mix.exs
  - lib/mix/tasks/verify.phase11.ex
  - test/release/package_metadata_test.exs
  - test/release/consumer_smoke_test.exs
  - docs/releasing.md
  - test/scrypath/docs_contract_test.exs
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 11: Code Review Report

**Reviewed:** 2026-04-16T20:40:00Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Reviewed the Phase 11 public-release contract changes across package metadata, the `mix verify.phase11` gate, the clean-consumer smoke harness, maintainer release docs, and the docs contract tests.

The current implementation passes the targeted tests and `mix verify.phase11`, but there are two verification gaps: the workflow contract check is too loose to reliably catch semantic drift, and the new release docs are not covered by the existing Elixir fence syntax test.

## Warnings

### WR-01: `verify.phase11` only checks for loose token presence in release config

**File:** `lib/mix/tasks/verify.phase11.ex:14-19`, `lib/mix/tasks/verify.phase11.ex:50-57`
**Issue:** The release workflow validation reduces the Release Please and publish contract to one broad `grep -E` over three files. That only proves that tokens like `release_created`, `tag_name`, `manifest-file`, and `mix hex.publish --yes` appear somewhere in the files. It does not prove the required relationships still hold, such as the publish job being gated on `release_created == 'true'`, checking out `tag_name`, and publishing from that tagged ref. A future edit could leave the same words in comments, dead steps, or unrelated jobs and still pass `mix verify.phase11`.
**Fix:**
```elixir
# Replace the broad multi-file grep with targeted assertions per file.
run_system_command!(
  "grep",
  ["-n", "if: ${{ needs.release-please.outputs.release_created == 'true' }}", ".github/workflows/release-please.yml"],
  "publish job release_created guard validation"
)

run_system_command!(
  "grep",
  ["-n", "ref: ${{ needs.release-please.outputs.tag_name }}", ".github/workflows/release-please.yml"],
  "publish job tag checkout validation"
)

run_system_command!(
  "grep",
  ["-n", "run: mix hex.publish --yes", ".github/workflows/release-please.yml"],
  "publish job hex publish validation"
)
```

### WR-02: Release docs snippets are not included in the syntax fence contract

**File:** `test/scrypath/docs_contract_test.exs:184-194`
**Issue:** The docs contract test parses Elixir code fences from `README.md`, `ARCHITECTURE.md`, and the guides, but it does not include `docs/releasing.md`. Phase 11 added maintainer-facing Elixir snippets there, including the dependency example and the manual smoke schema. Those examples can now drift into invalid Elixir without any test failing.
**Fix:**
```elixir
test "all Elixir code fences in docs stay syntactically valid" do
  for snippet <-
        extract_elixir_fences(@readme) ++
          extract_elixir_fences(@architecture) ++
          extract_elixir_fences(@release_docs) ++
          guide_fences() do
    assert {:ok, _quoted} = Code.string_to_quoted(snippet)
  end
end
```

---

_Reviewed: 2026-04-16T20:40:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
