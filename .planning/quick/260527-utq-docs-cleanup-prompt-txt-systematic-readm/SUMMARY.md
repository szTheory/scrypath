---
quick_task: 260527-utq
status: complete
completed: 2026-05-28
commit: 9011ed8
---

# Quick Task 260527-utq Summary

- Cleaned reader-facing README, guide, website, package metadata, and repository support surfaces without opening new product scope.
- Removed internal planning-style wording from adopter-facing docs where it created unnecessary friction.
- Fixed broken or awkward local documentation links and tightened public package contents.
- Added top-level `LICENSE`, `SECURITY.md`, and the outside-adopter evidence issue template.
- Updated website navigation, canonical links, Open Graph metadata, issue-reporting copy, and status-strip wrapping.

## Verification

- `node` markdown local-link scan
- `mix docs --warnings-as-errors`
- `mix test test/release/package_metadata_test.exs test/scrypath/docs_contract_test.exs`
- `mix test --exclude integration --exclude docs_contract`
- `mix hex.build --unpack`
- `mix verify --exclude integration`
- `npm run build && npm run check` in `website/`
