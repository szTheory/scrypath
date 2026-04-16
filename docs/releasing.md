# Releasing Scrypath

Release Please owns the version bump and changelog PR flow. CI already runs the non-publishing package gate on every mainline change.

## Automated Release Gate

Run these commands locally when you want the same package checks outside CI:

```bash
mix docs --warnings-as-errors
mix test test/release/package_metadata_test.exs
mix hex.publish --dry-run
mix hex.build --unpack
```

After `mix hex.build --unpack`, inspect the unpacked package contents:

```bash
find scrypath-* -maxdepth 3 -type f | grep -E '^scrypath-[^/]+/(README.md|CHANGELOG.md|ARCHITECTURE.md|docs/releasing.md|guides/|lib/|mix.exs)'
```

## Human-Only Review

Keep the manual pass short:

1. Confirm the Release Please PR version and changelog entry match the merged commit scope.
2. Confirm the generated docs and package metadata still point at the tagged `vX.Y.Z` source ref.
3. Confirm the tarball contents still read like a public library package, especially the README, guides, and changelog.
4. After publishing, confirm the Hex package page and HexDocs source links render as expected.
