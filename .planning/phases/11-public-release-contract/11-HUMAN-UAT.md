---
status: partial
phase: 11-public-release-contract
source: [11-VERIFICATION.md]
started: 2026-04-16T21:06:00Z
updated: 2026-04-16T21:05:15Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Run the first real Release Please publish and confirm the workflow-owned live checks pass
expected: `publish-hex` checks out `tag_name`, verifies `@version`, passes `mix verify.phase11`, passes `mix hex.publish --dry-run --yes`, publishes to Hex, and `mix verify.release_publish X.Y.Z` succeeds.
result: [pending]

## Summary

total: 1
passed: 0
issues: 0
pending: 1
skipped: 0
blocked: 0

## Gaps

- After the first public release exists, `.github/workflows/verify-published-release.yml` should begin succeeding on the latest published Scrypath version automatically.
