# Releasing Scrypath

Release Please owns the version bump and changelog PR flow. CI already runs the non-publishing package gate on every mainline change, and GitHub Actions publishes to Hex when Release Please creates a tagged release.

## Automated Release Gate

Run `mix verify.phase10` when you want the same auth-free package checks outside CI from one canonical maintainer entrypoint:

```bash
mix verify.phase10
```

That command runs the focused release-doc and package metadata contract tests, builds docs with warnings as errors, validates the Release Please workflow/config files, and unpacks the Hex package locally.

If you want to inspect the unpacked package contents after `mix verify.phase10`, run:

```bash
find scrypath-* -maxdepth 3 -type f | grep -E '^scrypath-[^/]+/(README.md|CHANGELOG.md|ARCHITECTURE.md|docs/releasing.md|guides/|lib/|mix.exs)'
```

## Release-Only Publish Validation

Use this only when you are preparing an actual release and have `HEX_API_KEY` configured for a publisher account:

```bash
HEX_API_KEY=... mix hex.publish --dry-run --yes
```

That command checks publish credentials and must stay out of the always-on CI gate.

## Automated Publish

The release workflow publishes from GitHub Actions only when Release Please reports `release_created == true`. Keep `HEX_API_KEY` scoped to that publish job; normal CI does not receive publish credentials.

## Human-Only Review

Keep the manual pass short:

1. Confirm the Release Please PR version and changelog entry match the merged commit scope.
2. Confirm the generated docs and package metadata still point at the tagged `vX.Y.Z` source ref.
3. Confirm the tarball contents still read like a public library package, especially the README, guides, and changelog.
4. After publishing, confirm the Hex package page and HexDocs source links render as expected.
