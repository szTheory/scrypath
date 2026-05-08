# Changelog

All notable changes to this project will be documented in this file.

Release Please manages versioned entries after this baseline.

## Unreleased

### Added

- Example app **`examples/phoenix_meilisearch/`** — Postgres + Meilisearch Docker Compose (explicit network), path dependency on Scrypath, and **`scripts/smoke.sh`** for an integration smoke (Ecto insert → `Scrypath.sync_record` → hydrated `Scrypath.search`). Documented from the root README; **`CONTRIBUTING.md`** CI section updated to list all workflow jobs.
- **OPS14-01:** Operator failure rollups — `FailedWork.reason_class_counts/1`, `%ReasonClassCounts{}`, opt-in `reason_class_counts: true` on `Scrypath.failed_sync_work/2` returning `%FailedSyncWorkInspection{}`, `failed_work_counts` on `%Reconcile{}`, human rollup + per-row `reason_class=` and **`--json`** / **`--no-class-summary`** on `mix scrypath.failed`.
- `mix verify.meilisearch_smoke` — CI/local entrypoint for curated live Meilisearch integration tests; GitHub Actions job `meilisearch-smoke`; optional `compose.yaml` for local Meilisearch.
- **TUNE14-01 / TUNE14-02:** `Scrypath.Meilisearch.Settings.hot_apply/3` for allow-listed live settings PATCHes (`synonyms`, `stop_words`, `typo_tolerance`) with `acknowledge_live_index: true`, task wait, and telemetry `[:scrypath, :settings, :hot_apply]`; operator entrypoint `mix scrypath.settings.hot_apply`; guides updated in `guides/relevance-tuning.md` and `guides/operator-mix-tasks.md`.
- Maintainer doc `docs/search-backend-sre.md` — SRE-oriented Meilisearch + Scrypath telemetry signals, anti–alert-fatigue guidance, and common operational footguns (cross-linked from README and `docs/operator-support.md`).
- Faceted search on the common path: schema `faceting:` (FACET-01/02/10), `Scrypath.search/3` options `:facets` / `:facet_filter` with `{:error, {:unknown_facet, _}}` validation (FACET-03), Meilisearch payload keys `facets` / `facetFilters` (FACET-04/09), `%Scrypath.SearchResult.Facets{}` decoding (FACET-05/06), and settings merge for `filterableAttributes` + `facetSearch` (FACET-07). ExDoc extra `guides/faceted-search-with-phoenix-liveview.md` documents Phoenix LiveView patterns.
- Relevance tuning for Meilisearch-first settings: declarative translation for **TUNE-01** (synonyms / typo tolerance / ranking rules / distinct attribute / stop words), **TUNE-02** synonym list sugar, **TUNE-05** `verify_applied/3` + `Client.get_settings/2` drift primitive, **TUNE-03** managed-reindex verify step, **TUNE-04** reindex-time ranking-rules guard, **TUNE-07** `mix scrypath.settings.diff`, **TUNE-08** `mix scrypath.settings.read`, and **TUNE-06** per-repo `Application.get_env/3` cascade in `Scrypath.Config.resolve!/1` (with optional `otp_app` when `Application.get_application/1` is nil).
- `mix verify.workspace_clean` — fails if the working tree has uncommitted or untracked files under packaged paths (`lib/`, `test/`, `guides/`, `docs/`, and other `mix.exs` `package.files` entries). Integrated into all three publish paths (`ci.yml` quality job, `release-please.yml` publish-hex job, `publish-hex.yml` manual recovery).
- `mix verify.release_parity X.Y.Z` — compares the published Hex tarball's `lib/ + guides/ + docs/` file list against the git tag of the same version. Exit codes: `0` parity, `2` drift, `1` runtime error. Runs daily via `verify-published-release.yml` cron and auto-files a deduplicated GitHub issue on drift.

### Changed

- **LIB-01:** Clearer sync outcomes—tagged `{:invalid_options, field, message}` from NimbleOptions on search option validation, shared `Scrypath.Errors.format_reason/1` for exception copy, and `@doc` on public sync/delete entrypoints describing `:accepted` vs `:completed`.
- **LIB-02:** Documentation and typespec clarity for `Scrypath.Query`, richer runtime option `doc:` strings for sync timing knobs, and an **Entry points** map in `Scrypath` module docs (no new macros).
- **LIB-03:** `guides/overview.md` added to the published-guide contract list; README and `docs_contract_test` assert sync visibility spine strings stay wired.
- Posture **D** normalization for schema `settings:` maps (camelCase in, canonical atom keys out) is documented in `guides/relevance-tuning.md` alongside the relevance workflow.
- GitHub Actions CI runtime upgraded to Node 24 — `actions/checkout@v6` and `actions/cache@v5` across all jobs in `.github/workflows/ci.yml` (clears the Node 20 deprecation ahead of the 2026-09 removal).

### Notes

- Adopters should read the **Versioning and upgrades** section in `README.md` for semver posture and upgrade expectations; maintainers should follow `docs/releasing.md` for verify gates and Release Please (without duplicating the full `mix verify.phase11` task list here).
- Release-parity gates were motivated by a historical **tag vs default-branch** divergence in an earlier cycle; see `docs/releasing.md` § Historical context.

## [0.3.6](https://github.com/szTheory/scrypath/compare/scrypath-v0.3.5...scrypath-v0.3.6) (2026-05-08)


### Features

* **65-01:** add playbook run failure enrichment ([c92852f](https://github.com/szTheory/scrypath/commit/c92852f3c2208b05bb14ecad44027a7c2ab0417e))
* **65-02:** async playbook run lifecycle ([73b687e](https://github.com/szTheory/scrypath/commit/73b687eb01459b64d88674b4f33d6f3029912f2a))
* **65-03:** add structured playbook run failure UI ([89b3409](https://github.com/szTheory/scrypath/commit/89b3409ba4b55eba836f30563e14c8fba1d949ae))
* **65-04:** harden playbook run lifecycle tests ([63bb8f3](https://github.com/szTheory/scrypath/commit/63bb8f33a1c7bbaf37c3b77d59bc9f5a960005cf))
* **65:** automate playbook run lifecycle verification ([193fe36](https://github.com/szTheory/scrypath/commit/193fe364b519bf9bd27ad63b060e95794c394b96))
* **66-02:** align runner parity with scrypath contract ([f1e289e](https://github.com/szTheory/scrypath/commit/f1e289ef80b3df282fc23784fcdee19d59b58318))
* **71-01:** make Sigra optional in ops UI boot path ([9aee601](https://github.com/szTheory/scrypath/commit/9aee6017d7b79bd3792ee30c6cd9a91a890252fe))
* **71-02:** add Sigra runtime integration ([85db7ee](https://github.com/szTheory/scrypath/commit/85db7ee794579159869d55c5a45b4aedd42405cb))
* **71-03:** add namespace fence task ([f72bbf3](https://github.com/szTheory/scrypath/commit/f72bbf36f0875eb9b15be75e752aea1c8795bd97))
* **71-03:** lock audit prefixes in CI ([ffcec6d](https://github.com/szTheory/scrypath/commit/ffcec6dbe5e03fbfc3281a6826c178eeb54713ea))
* **72-02:** gate posture swap_live action ([1aaa556](https://github.com/szTheory/scrypath/commit/1aaa556a70984c8baff99643613500ec8296b19a))
* **72-02:** gate sync-drift swap_live action ([c31f0e6](https://github.com/szTheory/scrypath/commit/c31f0e65190a9bfdad45288245e05fce739c018b))


### Bug Fixes

* **66:** align playbook schema docs with runner contract ([61b9bff](https://github.com/szTheory/scrypath/commit/61b9bff9f08a4bc3884bb0a46ae3e422f818bcca))
* **72-01:** gate failed-sync retry and preserve local state ([b1ab863](https://github.com/szTheory/scrypath/commit/b1ab8633af32e5e955fffcae91975ed223634bc4))
* **72-01:** gate playbook delete and keep run paths ungated ([3068a9a](https://github.com/szTheory/scrypath/commit/3068a9a8508347b33e6731bcd4982522a18fb11e))
* **76-01:** fail fast when live adopter services are down ([96d9f76](https://github.com/szTheory/scrypath/commit/96d9f76bb510ce489e3128dbea777a2886aafb53))
* align opsui auth mode contract test ([58c9487](https://github.com/szTheory/scrypath/commit/58c948707d1a13e9362c9feb3b7fa4589e371fff))
* align readme wording with telemetry contract ([6906e8e](https://github.com/szTheory/scrypath/commit/6906e8e10bc859e4a866a3a71f38346b24ffd433))
* keep sigra optional compile warning-free ([6d78087](https://github.com/szTheory/scrypath/commit/6d780874151a64ae20dd025defb1159363b3b9d3))
* prepare scrypath_ops deps in quality CI ([3b27e57](https://github.com/szTheory/scrypath/commit/3b27e57477955942c5c71d2ad580e0578830c6f6))
* restore CI contract after main reconciliation ([bb51053](https://github.com/szTheory/scrypath/commit/bb5105352050181a206f7256edc2d5424dcb6e59))
* restore readme product-shape contract ([acff4ef](https://github.com/szTheory/scrypath/commit/acff4ef33141d44eb82b358da931d538095583b4))
* run verify.adopter in test env ([693b62e](https://github.com/szTheory/scrypath/commit/693b62e2e31cd33bccda8795ae728a79703e4fca))
* satisfy dialyzer in namespace fence ([156d355](https://github.com/szTheory/scrypath/commit/156d3559cc832865bd59403b870d4081cef31549))
* silence exdoc readme path warning ([8d9036e](https://github.com/szTheory/scrypath/commit/8d9036ea5f70b3b4d8c10b5b68031ddfe6c66e7d))

## [0.3.5](https://github.com/szTheory/scrypath/compare/scrypath-v0.3.4...scrypath-v0.3.5) (2026-04-23)


### Features

* **39-01:** quads and federation_weight validation in Entries.normalize ([118368e](https://github.com/szTheory/scrypath/commit/118368e2f704dbd2efe554ce841bcc2a95a2bdbc))
* **39-01:** search_many quad pipeline and fed_opts on search_many rows ([4cde8fc](https://github.com/szTheory/scrypath/commit/4cde8fcbe0b2effcf300015544850cee4ac706c8))
* **39-02:** Meilisearch federationOptions.weight per query ([d11add2](https://github.com/szTheory/scrypath/commit/d11add28c1d4595af32f982ac4769be31ea1df62))
* **39-02:** merge_hit_order decode and MultiSearchResult.merge_projection ([39e62fb](https://github.com/szTheory/scrypath/commit/39e62fb4bb8f1292dcb6d881a22f041ec8a562b6))
* **39-02:** weighted FakeBackend, tests, and federation docs ([a9e794d](https://github.com/szTheory/scrypath/commit/a9e794dee6f14433a396b2874555a4d769a0254e))
* **41-01:** add Mix.Tasks.Verify.Phase41 doc-contract verify slice ([881c536](https://github.com/szTheory/scrypath/commit/881c53608441454d304e5381a0d8b704c543ff48))
* **41-01:** register verify.phase41 in Mix.Project cli preferred_envs ([328b827](https://github.com/szTheory/scrypath/commit/328b827862b2debb96436984daf557198a618d9d))
* **43-01-01:** validate per_query and project Meilisearch ranking fields ([bfb4682](https://github.com/szTheory/scrypath/commit/bfb4682938709047abfdef11e5bda2f1c5db2ad7))
* **43-01-02:** surface ranking score details in search telemetry ([2a4182c](https://github.com/szTheory/scrypath/commit/2a4182cb8615d19e8cdb201cd70f4c27b383da2d))
* **43-02-01:** shallow Map.merge for per_query in search_many normalize ([cf0bf48](https://github.com/szTheory/scrypath/commit/cf0bf48c48487a9a54a13923aa581c779675382c))
* **43-03-01:** add mix verify.phase43 thin composer ([4467849](https://github.com/szTheory/scrypath/commit/4467849e3c86b1748c5dce0cc35ad5bc1475c58d))
* **44:** add ScrypathOps Phoenix shell and prod auth gate ([9d0a90e](https://github.com/szTheory/scrypath/commit/9d0a90ec373b54110dc9707ed157efb859381cb3))
* **48-01:** add ScrypathOpsWeb.Nav.primary for ops nav ([70b847e](https://github.com/szTheory/scrypath/commit/70b847e94bf230a04c1f271bc0cdb01111e57ed8))
* **48-01:** render ops shell nav from Nav.primary/0 ([63f76a9](https://github.com/szTheory/scrypath/commit/63f76a98312159f428e507664b5fd68c11d8786b))
* **48-02:** add mix scrypath_ops.check_nav_contract ([b29fa28](https://github.com/szTheory/scrypath/commit/b29fa28a30765570ebbe74f2e9ce613eef664bd0))
* **48-03:** add posture headline, evidence, and next checks for JTBD 1 ([91b2257](https://github.com/szTheory/scrypath/commit/91b2257dc53928e88226aa7eece47a913cd3b7b3))
* **49-01:** add ops_main_width variant to ops shell layout ([bd191f2](https://github.com/szTheory/scrypath/commit/bd191f20b98311afc99a39fe1948e8aff9263cf5))
* **49-01:** add OpsUi page header and panel components ([dfc7f62](https://github.com/szTheory/scrypath/commit/dfc7f6272d604ebed6cd0c052838b597e08294cb))
* **49-01:** import OpsUi in html_helpers for LiveViews ([6ed65c9](https://github.com/szTheory/scrypath/commit/6ed65c93e1525eb1c38e06998b39e07247bc3bfa))
* **50-01:** add skip link and ops-main landmark to :ops layout ([e2dd725](https://github.com/szTheory/scrypath/commit/e2dd72550c32df92b69d55adf798b3f2a1d22bc3))
* **50-01:** add stable ops-page-title id on ops_page_header h1 ([ec70de1](https://github.com/szTheory/scrypath/commit/ec70de191340febb27647102b119a1a07b206ae2))
* **50-02:** add landmark sections and table column scope on PostureLive ([426dd65](https://github.com/szTheory/scrypath/commit/426dd65b19a23c7760fa786dd87737508a0f31f0))
* **50-02:** semantic sections and table headers on FailedSyncLive ([8684b02](https://github.com/szTheory/scrypath/commit/8684b028a05955e2d7024de1c2828b05b875fe4a))
* **50-02:** tables and sections for reconcile and drift on SyncDriftLive ([0e15487](https://github.com/szTheory/scrypath/commit/0e1548796582949be3e25ad26729341f742bc2fe))
* **50-03:** fieldset chapters and federation status region on SearchLive ([0bb5115](https://github.com/szTheory/scrypath/commit/0bb5115241cc8ebd5719fc811ddc5882ab3344d8))
* **52-02:** add Scrypath.Search.Error for bang search failures ([123b506](https://github.com/szTheory/scrypath/commit/123b506afd647ad4bc527fefc9a516eef4c4799f))
* **52-02:** raise Scrypath.Search.Error from bang search helpers ([377beff](https://github.com/szTheory/scrypath/commit/377beff148b8202f47e723c46285f75b7e7c07e1))
* **60-01:** add Playbook.Runner dispatch bridge for validated playbooks ([d6adf68](https://github.com/szTheory/scrypath/commit/d6adf683b3ab380c24bb2baed7f07862bec3f1f7))
* **60-01:** add Playbook.Store with basename-only path containment ([2dfd1f6](https://github.com/szTheory/scrypath/commit/2dfd1f68f26615d68b65fd7bd96e241bc5e18848))
* **60-01:** wire SCRYPATH_OPS_PLAYBOOK_DIR and dev/test workspace dirs ([51efe12](https://github.com/szTheory/scrypath/commit/51efe12f71d55a858e7fbb1a8fe7b93b1c1c79b4))
* **60-02,60-03:** PlaybookLive UI and ops nav for saved playbooks ([731fc7c](https://github.com/szTheory/scrypath/commit/731fc7c2a82bb078aa3713a566c3690ea6dac267))
* **60-02:** register PlaybookLive at /ops/playbooks ([46acc02](https://github.com/szTheory/scrypath/commit/46acc022ac0f5c5c178bccd1ada52adedcb92b78))
* **62-01:** optional playbook title, description, and tags in V1 ([c00a02b](https://github.com/szTheory/scrypath/commit/c00a02b4b3799a2da0a160ff6b52c41d3f919db8))
* **62-02:** playbook store rename, duplicate, and basename suggest ([507f6f1](https://github.com/szTheory/scrypath/commit/507f6f1fd8565fbe2773337b666e6b96214b159a))
* **62-03:** SearchLive save search as playbook with V1 preview ([baa9a51](https://github.com/szTheory/scrypath/commit/baa9a514a5d6f66a2f646441e947593ba518cdbd))
* **62-04:** PlaybookLive catalog metadata, rename, and duplicate ([1b8f1f3](https://github.com/szTheory/scrypath/commit/1b8f1f3477f957c1236bb0021115b3b7b63e404a))
* **ci:** add scrypath-ops CI job for OPSUI (47-01) ([9857450](https://github.com/szTheory/scrypath/commit/9857450923af62cc574a9fdfdb1211d70d34452b))
* **FED-02:** expand {:all, …} in search_many before normalize ([d66edb8](https://github.com/szTheory/scrypath/commit/d66edb8cb53475b984739efa68e94a7646677005))
* **ops:** phase 59 playbook v1 codec, docs, and planning closure ([868d04e](https://github.com/szTheory/scrypath/commit/868d04e10ea7885666b6c3a398cee40796e562ae))
* **opsui:** add mix verify.opsui and formatter inputs (47-02) ([3e88a6f](https://github.com/szTheory/scrypath/commit/3e88a6feee2b5893f74ced0564020bf5a8ef4c87))
* **opsui:** complete phase 46 search playground and federation honesty ([7de764b](https://github.com/szTheory/scrypath/commit/7de764bc796846d8b637763de11aa1e737c29473))
* **opsui:** ship phase 45 posture, failed sync, and drift LiveViews ([2e11eda](https://github.com/szTheory/scrypath/commit/2e11eda838f3d687098fd1ec221b4cc4251f2f95))
* **phase-58:** B1 library QoL (LIB-01..03) ([7c91f87](https://github.com/szTheory/scrypath/commit/7c91f87146631c699cbaf443f32cb659b8b373d9))
* **scrypath_ops:** add playbooks validate mix task and examples (63-02) ([bfb174f](https://github.com/szTheory/scrypath/commit/bfb174f593d5a92e6f78312a1083f043d34d9c1d))
* **scrypath_ops:** complete phase 49 ops UI scaffold, theming, and shell tests ([be5b197](https://github.com/szTheory/scrypath/commit/be5b1977016211280ac0cb9dd39efbb70bccc6e4))


### Bug Fixes

* **57-01:** restore STATE frontmatter; link EVID-01 ledger in ROADMAP (57-01-06/07) ([04e5c92](https://github.com/szTheory/scrypath/commit/04e5c9228ef7b60c57695a5996aa8c9bcd87f8a9))
* restore main CI stability ([#13](https://github.com/szTheory/scrypath/issues/13)) ([126340d](https://github.com/szTheory/scrypath/commit/126340dc758d5957990f09f71bda70d5d98e6221))
* **state:** repair frontmatter after phase 57 session ([4eda255](https://github.com/szTheory/scrypath/commit/4eda255d404412d0af7e32c2a236ee945245c4b1))

## [0.3.4](https://github.com/szTheory/scrypath/compare/scrypath-v0.3.3...scrypath-v0.3.4) (2026-04-20)


### Features

* **034-01:** slim README Quick Path with canonical string status ([217596a](https://github.com/szTheory/scrypath/commit/217596ab4a90dc8b05e9d53f94eb9c706f458ed8))
* **36-01:** opt-in nested facet paths and hierarchy expansion ([9be8e8b](https://github.com/szTheory/scrypath/commit/9be8e8b1b33577e890a7ca56793e1055f11194a3))
* **36-02:** dotted facet names in settings merge and drift tests ([00bc51e](https://github.com/szTheory/scrypath/commit/00bc51eb287e76130a744d6f06680d18fc0a2f31))
* **36-03:** hierarchical facets guide, verify.phase36, and contracts ([cec43ea](https://github.com/szTheory/scrypath/commit/cec43ea80498de75b96b88d094b16196c87c93fd))
* **37-01:** add Scrypath.Facets.Disjunctive.merge_distributions ([700021f](https://github.com/szTheory/scrypath/commit/700021fa8efc0ea003ef2e47185d6383fd9c0c7e))
* **38:** add search_within_facet/4, guide contracts, and mix verify.phase38 ([d6a3d9e](https://github.com/szTheory/scrypath/commit/d6a3d9eefb25542d8fce8fdc9331d8f12b5fa198))
* **phase-27:** index contract drift report and reconcile opt-in ([ebc4e21](https://github.com/szTheory/scrypath/commit/ebc4e21048494e76763d451664fdbf0bdff0f71d))
* **phase-28:** index contract drift CLI, docs, and verify.phase28 ([3bbbe3f](https://github.com/szTheory/scrypath/commit/3bbbe3fcc1c564969dc190f97b5242c7451a0405))


### Bug Fixes

* **ci:** credo cleanups, ExDoc extras for CONTRIBUTING, federated decode split ([af9a6b2](https://github.com/szTheory/scrypath/commit/af9a6b25af73bc0f7a80adc89b5260e9d5ae510b))
* **ci:** format options, widen feat(18) git window, isolate Hex in consumer smoke ([fb327fa](https://github.com/szTheory/scrypath/commit/fb327fa644a3485e5ac2025b245080e39145a5da))
* **dialyzer:** silence no_return on contract_drift halt path ([b516210](https://github.com/szTheory/scrypath/commit/b5162100fd1976d2b27898058c02ed2eec95a4ba))
* **oban:** carry Meilisearch URL and index_prefix in job payload ([49c3b75](https://github.com/szTheory/scrypath/commit/49c3b7530b0d59672fdfed1cc2c3a8f9884b21a1))
* **oban:** wait for Meilisearch tasks after worker writes ([8e1f15e](https://github.com/szTheory/scrypath/commit/8e1f15ee8996285c46288965db68dd3b30ae4909))
* **state:** restore v1.6 frontmatter; record phase 35 discuss ([2e096c5](https://github.com/szTheory/scrypath/commit/2e096c53445e8149683012744498a0881b9a8263))

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
