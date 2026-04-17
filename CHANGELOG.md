# Changelog

All notable changes to this project will be documented in this file.

Release Please manages versioned entries after this baseline.

## Unreleased

### Added

- Relevance tuning for Meilisearch-first settings: declarative translation for **TUNE-01** (synonyms / typo tolerance / ranking rules / distinct attribute / stop words), **TUNE-02** synonym list sugar, **TUNE-05** `verify_applied/3` + `Client.get_settings/2` drift primitive, **TUNE-03** managed-reindex verify step, **TUNE-04** reindex-time ranking-rules guard, **TUNE-07** `mix scrypath.settings.diff`, **TUNE-08** `mix scrypath.settings.read`, and **TUNE-06** per-repo `Application.get_env/3` cascade in `Scrypath.Config.resolve!/1` (with optional `otp_app` when `Application.get_application/1` is nil).
- `mix verify.workspace_clean` — fails if the working tree has uncommitted or untracked files under packaged paths (`lib/`, `test/`, `guides/`, `docs/`, and other `mix.exs` `package.files` entries). Integrated into all three publish paths (`ci.yml` quality job, `release-please.yml` publish-hex job, `publish-hex.yml` manual recovery).
- `mix verify.release_parity X.Y.Z` — compares the published Hex tarball's `lib/ + guides/ + docs/` file list against the git tag of the same version. Exit codes: `0` parity, `2` drift, `1` runtime error. Runs daily via `verify-published-release.yml` cron and auto-files a deduplicated GitHub issue on drift.

### Changed

- Posture **D** normalization for schema `settings:` maps (camelCase in, canonical atom keys out) is documented in `guides/relevance-tuning.md` alongside the relevance workflow.
- GitHub Actions CI runtime upgraded to Node 24 — `actions/checkout@v6` and `actions/cache@v5` across all jobs in `.github/workflows/ci.yml` (clears the Node 20 deprecation ahead of the 2026-09 removal).

### Notes

- See `.planning/milestones/v1.2-MILESTONE-AUDIT.md` for the historical v1.2 tag-vs-main divergence that motivated this phase's release-parity gates.

## [0.3.0](https://github.com/szTheory/scrypath/compare/scrypath-v0.2.0...scrypath-v0.3.0) (2026-04-17)


### Features

* **06-03:** add release automation baseline ([82306a8](https://github.com/szTheory/scrypath/commit/82306a899f026a93640522e96e00a024ad2e5c49))
* **06-03:** tighten package metadata and release gate ([226bbf4](https://github.com/szTheory/scrypath/commit/226bbf403b1115bef38eb2efa214e61df395199d))
* **08-02:** add shared empty-batch no-op handling ([1058269](https://github.com/szTheory/scrypath/commit/1058269c74cef4f366567859a908b4d0d08b7643))
* **08-03:** add phase 8 verification command ([0cac567](https://github.com/szTheory/scrypath/commit/0cac56711a6766af802affb59bb523eb2e7d5f29))
* **10-01:** add phase 10 release gate ([4ffd567](https://github.com/szTheory/scrypath/commit/4ffd567788f24cb2d92ccc4897b3031acdc39aa7))
* **11-02:** add clean consumer smoke verification ([41fa6f8](https://github.com/szTheory/scrypath/commit/41fa6f809ad86c87812bb4f539b68343371b3f8b))
* **11-02:** enforce the phase 11 release contract ([7a34f44](https://github.com/szTheory/scrypath/commit/7a34f446836228320a891523a1c2f55b3a94fa28))
* **11-public-release-contract-01:** add phase 11 release alignment gate ([f778312](https://github.com/szTheory/scrypath/commit/f778312453fcdfca15e9e2f3dbea7dccca068a6c))
* **12-01:** add internal operations seam contracts ([6f9e13f](https://github.com/szTheory/scrypath/commit/6f9e13f31ee0ec70b13889ae16f2d44af11bd688))
* **12-02:** move sync orchestration onto the operations seam ([a4abdd6](https://github.com/szTheory/scrypath/commit/a4abdd6db0e5295fca156410e2fa130aeec39147))
* **12-02:** wire seam-owned adapter task references ([fc1471f](https://github.com/szTheory/scrypath/commit/fc1471fe72327deb6cb52d88fad68d71ec8b8285))
* **12-03:** move backfill and reindex onto seam results ([2b2eaa0](https://github.com/szTheory/scrypath/commit/2b2eaa09958d491a0b0f4876586a1888fc795f4b))
* **13-01:** add root sync status operator API ([8c2ccae](https://github.com/szTheory/scrypath/commit/8c2ccaec3015fce34907de8682ad7acaeb1199be))
* **13-01:** tighten status inspection seam coverage ([0017732](https://github.com/szTheory/scrypath/commit/00177329892568831528db302a5f4efc978d4852))


### Bug Fixes

* **06-04:** harden release-quality public contracts ([4e1eb59](https://github.com/szTheory/scrypath/commit/4e1eb59393575f487adbbbf1ace35854e7d28794))
* **06-04:** lock phoenix json pagination example ([5f73cf2](https://github.com/szTheory/scrypath/commit/5f73cf2b317f0db9ad73838e4f589a623f0a1b06))
* **06:** restore readme operational wording contract ([cfb51ce](https://github.com/szTheory/scrypath/commit/cfb51cee0702f488750dd6347d5eb8a63f03554d))
* **08-01:** harden meilisearch task normalization ([8db7129](https://github.com/szTheory/scrypath/commit/8db7129b4be33af4038ed87ed2cfe0c320ad7212))
* **12:** harden seam wait normalization ([aa9f179](https://github.com/szTheory/scrypath/commit/aa9f17952a8697660673ddb548129e4279a032d0))

## [0.2.0](https://github.com/szTheory/scrypath/compare/scrypath-v0.1.0...scrypath-v0.2.0) (2026-04-17)


### Features

* **06-03:** add release automation baseline ([82306a8](https://github.com/szTheory/scrypath/commit/82306a899f026a93640522e96e00a024ad2e5c49))
* **06-03:** tighten package metadata and release gate ([226bbf4](https://github.com/szTheory/scrypath/commit/226bbf403b1115bef38eb2efa214e61df395199d))
* **08-02:** add shared empty-batch no-op handling ([1058269](https://github.com/szTheory/scrypath/commit/1058269c74cef4f366567859a908b4d0d08b7643))
* **08-03:** add phase 8 verification command ([0cac567](https://github.com/szTheory/scrypath/commit/0cac56711a6766af802affb59bb523eb2e7d5f29))
* **10-01:** add phase 10 release gate ([4ffd567](https://github.com/szTheory/scrypath/commit/4ffd567788f24cb2d92ccc4897b3031acdc39aa7))
* **11-02:** add clean consumer smoke verification ([41fa6f8](https://github.com/szTheory/scrypath/commit/41fa6f809ad86c87812bb4f539b68343371b3f8b))
* **11-02:** enforce the phase 11 release contract ([7a34f44](https://github.com/szTheory/scrypath/commit/7a34f446836228320a891523a1c2f55b3a94fa28))
* **11-public-release-contract-01:** add phase 11 release alignment gate ([f778312](https://github.com/szTheory/scrypath/commit/f778312453fcdfca15e9e2f3dbea7dccca068a6c))
* **12-01:** add internal operations seam contracts ([6f9e13f](https://github.com/szTheory/scrypath/commit/6f9e13f31ee0ec70b13889ae16f2d44af11bd688))
* **12-02:** move sync orchestration onto the operations seam ([a4abdd6](https://github.com/szTheory/scrypath/commit/a4abdd6db0e5295fca156410e2fa130aeec39147))
* **12-02:** wire seam-owned adapter task references ([fc1471f](https://github.com/szTheory/scrypath/commit/fc1471fe72327deb6cb52d88fad68d71ec8b8285))
* **12-03:** move backfill and reindex onto seam results ([2b2eaa0](https://github.com/szTheory/scrypath/commit/2b2eaa09958d491a0b0f4876586a1888fc795f4b))
* **13-01:** add root sync status operator API ([8c2ccae](https://github.com/szTheory/scrypath/commit/8c2ccaec3015fce34907de8682ad7acaeb1199be))
* **13-01:** tighten status inspection seam coverage ([0017732](https://github.com/szTheory/scrypath/commit/00177329892568831528db302a5f4efc978d4852))


### Bug Fixes

* **06-04:** harden release-quality public contracts ([4e1eb59](https://github.com/szTheory/scrypath/commit/4e1eb59393575f487adbbbf1ace35854e7d28794))
* **06-04:** lock phoenix json pagination example ([5f73cf2](https://github.com/szTheory/scrypath/commit/5f73cf2b317f0db9ad73838e4f589a623f0a1b06))
* **06:** restore readme operational wording contract ([cfb51ce](https://github.com/szTheory/scrypath/commit/cfb51cee0702f488750dd6347d5eb8a63f03554d))
* **08-01:** harden meilisearch task normalization ([8db7129](https://github.com/szTheory/scrypath/commit/8db7129b4be33af4038ed87ed2cfe0c320ad7212))
* **12:** harden seam wait normalization ([aa9f179](https://github.com/szTheory/scrypath/commit/aa9f17952a8697660673ddb548129e4279a032d0))
