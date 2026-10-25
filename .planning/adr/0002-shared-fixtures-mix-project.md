# Shared fixtures live in their own dev/test-only Mix project

Fixture data (operator personas, adopter twins, and their scenarios) lives in a top-level `fixtures/scrypath_fixtures` Mix project. `scrypath_ops` and the demo host both use it as a path dependency with `only: [:dev, :test]`, and it depends only on `scrypath`.

A path dependency compiles in `:prod`, and `test/support` isn't reachable from another app. Before this, that forced two drifting copies of the same fixture source, so neither a `Mix.env()` guard inside `scrypath_ops/lib` nor `test/support` would have worked.

The root package's `files:` is an explicit allowlist, so `fixtures/` never ships. `mix verify.package` asserts this.
