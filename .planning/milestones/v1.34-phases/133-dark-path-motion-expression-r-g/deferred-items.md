# Deferred Items — Phase 133

Out-of-scope discoveries logged during execution (not caused by Phase 133 changes).

## Pre-existing OpsShellContractTest failures (logo.svg → inline SVG drift)

- truth: "The shell contract still expected the removed `/ops/images/logo.svg` image."
  status: resolved
  discovered_during: "Phase 133 Plan 01 verification (`mix verify.opsui`)"
  root_cause: "The v1.35 brand adoption replaced the image with an inline SVG mark without updating the shell contract."
  resolution: "The contract now asserts the inline `ops-brand-mark` SVG and its copper slash accent."
  evidence: "`mix test test/scrypath_ops_web/ops_shell_contract_test.exs` passed 8 tests with 0 failures on 2026-08-27."
