---
quick_id: 260527-utq
status: complete
completed: 2026-05-28
commit: 9011ed8
---

# Quick Task 260527-utq Summary

## Goal

Clean up reader-facing Scrypath docs, HexDocs inputs, website copy/routing, and GitHub metadata without opening new product scope.

## What changed

- Tightened README and guide copy that read like internal planning language (`defended`, milestone-style `v1.x` wording, "proof surface" phrasing) where it appeared in adopter-facing docs.
- Fixed broken or awkward relative links in guide and maintainer docs.
- Removed `docs/jtbd-gap-map.md` from public ExDoc extras and stopped packaging the whole `docs/` directory; package files now include only the public maintainer docs that should ship.
- Added top-level `LICENSE` and `SECURITY.md`, linked the license badge to the repo license, and added a GitHub issue template for outside-adopter evidence.
- Replaced the packaged raw evidence template with the GitHub issue template and updated intake/readiness tests to use the new source.
- Updated website source for clearer nav labels, canonical directory-style links, absolute Open Graph image URL, less internal issue-reporting copy, and no-wrap status-strip code pills.
- Updated GitHub repository description to: `Ecto-native Meilisearch indexing and search orchestration for Elixir/Phoenix apps`.

## Verification

- `node` markdown local-link scan: no missing local markdown links.
- `mix docs --warnings-as-errors`: pass.
- `mix test test/release/package_metadata_test.exs test/scrypath/docs_contract_test.exs`: 73 tests, 0 failures.
- `mix test --exclude integration --exclude docs_contract`: 488 tests + 2 properties, 0 failures after rerun.
- `mix hex.build --unpack`: pass; unpacked package excludes `docs/jtbd-gap-map.md` and includes `LICENSE` / `SECURITY.md`.
- `mix verify --exclude integration`: pass; 558 tests + 2 properties, 0 failures.
- `npm run build && npm run check` in `website/`: pass.

## Notes

The older generated `CHANGELOG.md` still contains historical commit scopes from past automation. I left that alone because rewriting generated release history would create Release Please churn and is not a low-risk docs-navigation fix.
