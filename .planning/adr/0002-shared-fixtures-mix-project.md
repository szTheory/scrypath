# Shared fixtures live in their own dev/test-only Mix project

Fixture data (operator personas, adopter twins, and their scenarios) lives in a top-level `fixtures/scrypath_fixtures` Mix project. `scrypath_ops` uses it as a path dependency with `only: [:dev, :test]`, and it depends only on `scrypath`. The demo host was meant to be the second user and does not depend on it yet (corrected 2026-11-25; the maintainer kept the project separate on 2026-11-22).

A path dependency compiles in `:prod`, and `test/support` isn't reachable from another app. Before this, that forced two drifting copies of the same fixture source, so neither a `Mix.env()` guard inside `scrypath_ops/lib` nor `test/support` would have worked.

The root package's `files:` is an explicit allowlist, so `fixtures/` never ships. `mix verify.package` asserts this.
