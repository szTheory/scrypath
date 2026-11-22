# scrypath_fixtures

A dev and test only Mix project ([ADR 0002](../../.planning/adr/0002-shared-fixtures-mix-project.md)). It holds pure builders for three Scrypath-owned adopters: Shopadelic (a storefront), Logistify (shipments) and Wikily (a wiki). All three are fictional. The data is written for this repository, and nothing is copied from the sibling brand repositories. The project never ships in the Hex package or in a release.

The builders emit raw Meilisearch task maps and Oban job maps. The real Scrypath code (`Scrypath.sync_status/2`, `failed_sync_work/2`, the Ops posture summary) turns them into the states an operator sees, so only states the library can actually reach appear in a fixture.

## How to run the check

```sh
cd scrypath_ops && mix scrypath_fixtures.check_fixtures
```

The `preferred_envs` entry in `scrypath_ops/mix.exs` runs it in the test environment. It needs no database, and it is the first step of `mix test` in `scrypath_ops`.

## Exit rule

Fold this project into `scrypath_ops/catalog/` if no second consumer appears by Phase 197. A second consumer is a Mix project other than `scrypath_ops` that lists `scrypath_fixtures` in its deps (the candidate is the demo host replacing its phase173 copy). The decision is evaluated at the start of Phase 197 planning. Module names stay stable, so folding is a rename.

The cost input is the warm ops-ui delta against a same-day control, recorded by Phase 196 in `.planning/reference/CI-EFFICIENCY.md`. A delta above about 60 s also argues for folding. That threshold is advisory, from prep note B (`.planning/research/catalog-prep/B-fixtures-and-adopters.md`, the D1 revisit trigger and its adversarial pass). It is not an ADR trigger and does not stop a run by itself.

## Phase 173 deletion trigger

The two `phase173_fixture_source.ex` copies (one under `examples/scrypath_ecommerce/test/support/`, one under `scrypath_ops/test/support/`) and the `:phase173_fixture` branches of `PostureLive` stay as they are. Delete them when the four host specs that use them are ported to catalog scenarios or retired:

- `ops_reskin_contract.spec.ts`
- `ui_iteration3.spec.ts`
- `ui_followup.spec.ts`
- `ui_baseline.spec.ts`

Update `PRESERVATION_FIXTURE_FILES` in `scripts/ci/ecommerce_evidence.cjs` and its receipts in the same change. Both copies are identity-hashed into the Phase 185 preservation receipts, so editing or deleting either one on its own invalidates them.

## Boundary decisions

These record why the new top-level `fixtures/` directory needed no change in some places and a small one in others. Each is pinned by a test.

- The compatibility path classifier lists `fixtures` as irrelevant: the root `mix test` never compiles it, so a fixtures-only change rightly skips the advisory matrix.
- `ops-ui-path` already covers `fixtures/`, so ops-ui runs for a fixtures change.
- The ecommerce classifier runs the Docker lanes for it, because the images copy and compile it.
- `package_contents_test` needs no change: `allowed_top_level` is derived from `files:` in the root `mix.exs`, so `fixtures` can never be allowed.
- `package_metadata_test` refutes it from the package non-vacuously: it checks that the tree exists and that no `files:` entry reaches it.
- `.dockerignore` keeps the sources (the builder and test stages compile them) and ignores `_build` and `deps` under `fixtures/`.
- The Dockerfile copies this project's `mix.exs` in its three early blocks, so `deps.get` sees the manifest.
- The Docker verify script forbids `scrypath_fixtures` in the prod image and in the host project, and forbids the `ScrypathFixtures` module in its runtime probe.
- There is no Dependabot entry and no lock file: the project has no Hex dependency of its own.
- The UI literal policy does not scan it.
- The root formatter and the namespace fence cover it.

## Recordings

The Meilisearch payloads the fake client is checked against were recorded once from a pinned server image. See `recordings/meilisearch-v1.15/PROVENANCE.md` for the image, the method and how to repeat it.
