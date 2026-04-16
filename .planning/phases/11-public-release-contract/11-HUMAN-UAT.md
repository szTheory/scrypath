---
status: partial
phase: 11-public-release-contract
source: [11-VERIFICATION.md]
started: 2026-04-16T21:06:00Z
updated: 2026-04-16T21:06:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Run the canonical GitHub release flow for a real version
expected: Release Please creates `vX.Y.Z`, `publish-hex` checks out `tag_name`, Hex shows the same version, and the tag, changelog, manifest, and package state all agree.
result: [pending]

### 2. Verify the published package from a throwaway consumer app
expected: A fresh app using `{:scrypath, "~> X.Y.Z"}` runs `mix deps.get`, `mix compile`, and the minimal `use Scrypath` schema compiles successfully.
result: [pending]

### 3. Confirm the versioned HexDocs page is reachable after publish
expected: `curl -Ifs https://hexdocs.pm/scrypath/X.Y.Z` returns success for the released version.
result: [pending]

## Summary

total: 3
passed: 0
issues: 0
pending: 3
skipped: 0
blocked: 0

## Gaps
