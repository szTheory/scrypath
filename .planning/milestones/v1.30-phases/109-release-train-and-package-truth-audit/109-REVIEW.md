---
phase: 109-release-train-and-package-truth-audit
reviewed: 2026-05-31T21:05:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - .github/workflows/publish-hex.yml
  - CONTRIBUTING.md
  - docs/releasing.md
  - lib/mix/tasks/verify.phase11.ex
  - test/mix/tasks/verify_phase11_test.exs
  - test/mix/tasks/workflow_wiring_test.exs
  - test/release/consumer_smoke_test.exs
  - test/release/package_metadata_test.exs
  - test/scrypath/docs_contract_test.exs
findings:
  critical: 0
  warning: 3
  info: 0
  total: 3
status: issues_found
---
# Phase 109: Code Review Report

**Reviewed:** 2026-05-31T21:05:00Z
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Reviewed Phase 109 release-train workflow/docs/task updates with focus on publish-path safety and truth-gate coverage. No direct secret exposure was found, but there are release-contract coverage and reliability gaps that can allow workflow drift to pass the claimed gate.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: `verify.phase11` does not assert post-publish parity wiring despite being documented as release-contract authority

**File:** `lib/mix/tasks/verify.phase11.ex:48`
**Issue:** The task validates only selected `release-please.yml` strings (up through `verify.release_publish`) and does not verify `verify.release_parity` or any required wiring inside `.github/workflows/publish-hex.yml`. This leaves a gap where parity checks can be removed or reordered in publish workflows while `mix verify.phase11` still passes, conflicting with the release-contract claims in docs.
**Fix:**
```elixir
# In validate_release_contract!/0, add explicit checks for both workflows:
run_system_command!(
  "grep",
  ["-nF", "run: mix verify.release_parity \"${{ needs.release-please.outputs.version }}\"", ".github/workflows/release-please.yml"],
  "publish job post-publish parity validation"
)

run_system_command!(
  "grep",
  ["-nF", "run: mix verify.release_parity \"${{ inputs.release_version }}\"", ".github/workflows/publish-hex.yml"],
  "recovery workflow post-publish parity validation"
)
```

### WR-02: Release docs describe `opsui.test_a11y` as running release/package checks it does not run

**File:** `docs/releasing.md:47`
**Issue:** The paragraph states `mix opsui.test_a11y` runs package metadata, release workflow checks, docs warnings, and `mix hex.build --unpack`. The actual alias only runs nav contract setup + DB setup + `mix test --only opsui_a11y` (`scrypath_ops/mix.exs:98-103`). This is an operationally risky instruction mismatch because maintainers may incorrectly treat the a11y slice as a release-truth gate.
**Fix:** Replace the sentence with the real behavior and route release checks back to `mix verify.phase11`. Example:
```markdown
That alias runs `scrypath_ops.check_nav_contract`, `ecto.create --quiet`,
`ecto.migrate --quiet`, then `mix test --only opsui_a11y`.
It is an OPSUI accessibility slice and does not replace `mix verify.phase11`.
```

### WR-03: Workflow ordering tests can pass on comments/duplicate text instead of step semantics

**File:** `test/mix/tasks/workflow_wiring_test.exs:350`
**Issue:** `assert_ordered_steps/2` uses `:binary.match/2` against raw file text for first occurrence of each token. If a token appears earlier in comments or unrelated jobs, the test can pass/fail for the wrong reason, reducing trust in release-wiring regression detection.
**Fix:** Match on more precise markers (for example `run:` lines scoped to the target job block), or parse YAML and assert ordered `steps` in the specific job.
```elixir
# Minimal hardening example:
assert_ordered_steps(yml, [
  ~s(run: mix verify.workspace_clean),
  ~s(run: grep -n "@version \\"${{ inputs.release_version }}\\"" mix.exs),
  ~s(run: mix verify.phase11),
  ~s(run: mix hex.publish --dry-run --yes),
  ~s(run: mix hex.publish --yes),
  ~s(run: mix verify.release_publish "${{ inputs.release_version }}"),
  ~s(run: mix verify.release_parity "${{ inputs.release_version }}")
])
```

---

_Reviewed: 2026-05-31T21:05:00Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
