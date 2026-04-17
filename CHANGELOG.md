# Changelog

All notable changes to this project will be documented in this file.

Release Please manages versioned entries after this baseline.

## Unreleased

### Added

- **OPS14-01:** Operator failure rollups — `FailedWork.reason_class_counts/1`, `%ReasonClassCounts{}`, opt-in `reason_class_counts: true` on `Scrypath.failed_sync_work/2` returning `%FailedSyncWorkInspection{}`, `failed_work_counts` on `%Reconcile{}`, human rollup + per-row `reason_class=` and **`--json`** / **`--no-class-summary`** on `mix scrypath.failed`.
- `mix verify.meilisearch_smoke` — CI/local entrypoint for curated live Meilisearch integration tests; GitHub Actions job `meilisearch-smoke`; optional `compose.yaml` for local Meilisearch.
- **TUNE14-01 / TUNE14-02:** `Scrypath.Meilisearch.Settings.hot_apply/3` for allow-listed live settings PATCHes (`synonyms`, `stop_words`, `typo_tolerance`) with `acknowledge_live_index: true`, task wait, and telemetry `[:scrypath, :settings, :hot_apply]`; operator entrypoint `mix scrypath.settings.hot_apply`; guides updated in `guides/relevance-tuning.md` and `guides/operator-mix-tasks.md`.
- Maintainer doc `docs/search-backend-sre.md` — SRE-oriented Meilisearch + Scrypath telemetry signals, anti–alert-fatigue guidance, and common operational footguns (cross-linked from README and `docs/operator-support.md`).
- Faceted search on the common path: schema `faceting:` (FACET-01/02/10), `Scrypath.search/3` options `:facets` / `:facet_filter` with `{:error, {:unknown_facet, _}}` validation (FACET-03), Meilisearch payload keys `facets` / `facetFilters` (FACET-04/09), `%Scrypath.SearchResult.Facets{}` decoding (FACET-05/06), and settings merge for `filterableAttributes` + `facetSearch` (FACET-07). ExDoc extra `guides/faceted-search-with-phoenix-liveview.md` documents Phoenix LiveView patterns.
- Relevance tuning for Meilisearch-first settings: declarative translation for **TUNE-01** (synonyms / typo tolerance / ranking rules / distinct attribute / stop words), **TUNE-02** synonym list sugar, **TUNE-05** `verify_applied/3` + `Client.get_settings/2` drift primitive, **TUNE-03** managed-reindex verify step, **TUNE-04** reindex-time ranking-rules guard, **TUNE-07** `mix scrypath.settings.diff`, **TUNE-08** `mix scrypath.settings.read`, and **TUNE-06** per-repo `Application.get_env/3` cascade in `Scrypath.Config.resolve!/1` (with optional `otp_app` when `Application.get_application/1` is nil).
- `mix verify.workspace_clean` — fails if the working tree has uncommitted or untracked files under packaged paths (`lib/`, `test/`, `guides/`, `docs/`, and other `mix.exs` `package.files` entries). Integrated into all three publish paths (`ci.yml` quality job, `release-please.yml` publish-hex job, `publish-hex.yml` manual recovery).
- `mix verify.release_parity X.Y.Z` — compares the published Hex tarball's `lib/ + guides/ + docs/` file list against the git tag of the same version. Exit codes: `0` parity, `2` drift, `1` runtime error. Runs daily via `verify-published-release.yml` cron and auto-files a deduplicated GitHub issue on drift.

### Changed

- Posture **D** normalization for schema `settings:` maps (camelCase in, canonical atom keys out) is documented in `guides/relevance-tuning.md` alongside the relevance workflow.
- GitHub Actions CI runtime upgraded to Node 24 — `actions/checkout@v6` and `actions/cache@v5` across all jobs in `.github/workflows/ci.yml` (clears the Node 20 deprecation ahead of the 2026-09 removal).

### Notes

- Release-parity gates were motivated by a historical **tag vs default-branch** divergence in an earlier cycle; see `docs/releasing.md` § Historical context.

## [0.3.3](https://github.com/szTheory/scrypath/compare/scrypath-v0.3.2...scrypath-v0.3.3) (2026-04-17)


### Bug Fixes

* **docs:** repair operator-support for ExDoc strict build ([352bbef](https://github.com/szTheory/scrypath/commit/352bbef399422317242caf5c2cada20c410f84ab))

## [0.3.2](https://github.com/szTheory/scrypath/compare/scrypath-v0.3.1...scrypath-v0.3.2) (2026-04-17)


### Miscellaneous Chores

* **main:** release 0.3.2 ([3695a8c](https://github.com/szTheory/scrypath/commit/3695a8c45b0a5fc99ba1b3cc3a291308e29c626d))

## [0.3.1](https://github.com/szTheory/scrypath/compare/scrypath-v0.3.0...scrypath-v0.3.1) (2026-04-17)


### Features

* **13:** add operator primitives ([36d9f65](https://github.com/szTheory/scrypath/commit/36d9f6577f9283811625b9f554f9d57ea11ee0a5))
* **14:** add operator mix tasks and guides ([079c2e2](https://github.com/szTheory/scrypath/commit/079c2e23479056f75b13c0c0e7f9264f52cd49bb))
* **15:** add verify.phase13 mix task ([1df12aa](https://github.com/szTheory/scrypath/commit/1df12aacaacae28033bfcc7976902ce900db3a5e))
* **16:** add verify.phase14 mix task ([09f8288](https://github.com/szTheory/scrypath/commit/09f82886c70702312d5559062995e05df62cdb03))
* **18-01:** register verify.workspace_clean and verify.release_parity in mix.exs ([020548b](https://github.com/szTheory/scrypath/commit/020548b7805b1a1575338c830a91eee7b1585b83))
* **18-02:** implement Mix.Tasks.Verify.WorkspaceClean (INFRA-01) ([0df164c](https://github.com/szTheory/scrypath/commit/0df164c3c5aa3ea50c5f6db361a47d4e6fe4e654))
* **18-03:** implement Mix.Tasks.Verify.ReleaseParity (INFRA-02) ([8e3cb4c](https://github.com/szTheory/scrypath/commit/8e3cb4c41c6f016b4b1f9a1acb31e15e763d0caf))
* **18-04:** swap 8 [@v4](https://github.com/v4) pins in ci.yml to Node-24-ready versions (INFRA-03) ([bf116d7](https://github.com/szTheory/scrypath/commit/bf116d7209fab0172f0e8a38470119c1ad0df803))
* **18-05:** wire verify.workspace_clean into ci.yml quality job (D-15) ([049fa57](https://github.com/szTheory/scrypath/commit/049fa579597af8a435c55eda4cccdef3bd30888d))
* **18-05:** wire verify.workspace_clean into publish-hex manual-recovery workflow (D-17) ([7b1332e](https://github.com/szTheory/scrypath/commit/7b1332e279d61be175c9185d534e01c0101e2be6))
* **18-05:** wire verify.workspace_clean into release-please publish-hex job (D-16) ([301e851](https://github.com/szTheory/scrypath/commit/301e851a468fc670289b25389d365360ce110671))
* **18-06:** add release-parity drift issue template ([0a26266](https://github.com/szTheory/scrypath/commit/0a26266abc6e2b59895af8a588dd1827e45dd1cb))
* **18-06:** wire release_parity + drift-issue steps into published-release monitor ([68c15ee](https://github.com/szTheory/scrypath/commit/68c15eeb6cb71a2e6adc523b37deeb98ac02caff))
* **18:** add release-parity gates + Node 20 CI cleanup ([80500de](https://github.com/szTheory/scrypath/commit/80500deec080041e982a5ed9a8e747be410066bb))
* **19:** relevance tuning, settings tasks, and CI hygiene ([6733348](https://github.com/szTheory/scrypath/commit/6733348a8d07f8d1f233a4f75da954ba7239717c))
* multi-index search, settings hot_apply, operator rollups, and verify gates ([c4efacc](https://github.com/szTheory/scrypath/commit/c4efacccc75c44979690bba3f8b5c9a49cef3203))
* **release:** pre-1.0 Release Please policy, post-publish parity, docs ([11335a8](https://github.com/szTheory/scrypath/commit/11335a8c591ee4db846595a3e5464dbb030b6d24))
* **search:** Faceting, facet filters, and faceted LiveView guide ([#6](https://github.com/szTheory/scrypath/issues/6)) ([87a479b](https://github.com/szTheory/scrypath/commit/87a479b75c8c1a9ba21535d50547d8cabbe79730))


### Bug Fixes

* **18:** remove stale duplicate Unreleased block from CHANGELOG (closes T-18-07-03) ([91b8a57](https://github.com/szTheory/scrypath/commit/91b8a577c24dd3bd4da6f2402e9ba05cb1a9c9e7))
* **credo:** split faceting validators to reduce complexity ([a318e52](https://github.com/szTheory/scrypath/commit/a318e52a177abebd792e46e569d6c723cdc539a0))
* **dialyzer:** drop unreachable validate_search_options! error clause ([2c303eb](https://github.com/szTheory/scrypath/commit/2c303eb87e4ba30981bd2c129e20252954cdb7e0))
* **release:** unblock 0.3.0 publish gate ([13f1789](https://github.com/szTheory/scrypath/commit/13f1789029ccf0e6d41e8e8309c6aa9250d7e4dc))

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
