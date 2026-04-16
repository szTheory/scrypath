---
quick_task: 260416-if2
status: complete
completed: 2026-04-16T17:18:00Z
---

# Quick Task 260416-if2 Summary

- Updated Scrypath package metadata to use the canonical `szTheory/scrypath` GitHub repository.
- Added a `publish-hex` GitHub Actions job that runs only when Release Please reports a created release.
- Scoped `HEX_API_KEY` to the publish job so normal CI and Release Please bookkeeping do not receive Hex publish credentials.
- Updated maintainer release docs to describe the new automated publish path and keep the manual dry-run credential check explicit.

## Verification

- `mix test test/release/package_metadata_test.exs`
- `mix docs --warnings-as-errors`
- `mix hex.build --unpack`
