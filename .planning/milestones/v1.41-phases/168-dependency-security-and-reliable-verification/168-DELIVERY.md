---
phase: 168
plan: "05"
delivery: merged
base_sha: ad73b92d5883b4136fa961e134c987a95939fac2
candidate_sha: c2072c15e48993d09b9ea97204b248ab6c0e99e5
pr: 84
merge_ref_sha: a0b22c6fb35d7bdd7a9031b17b06800be991fec2
main_sha: 2832e91d725d70eff9ba11d08052260ba17e2747
main_run_id: 36503602888
---

# Phase 168 Security Delivery Receipt

## Delivered scope and provenance

Security/proof PR [#84](https://github.com/szTheory/scrypath/pull/84), `fix: secure and verify maintained dependency graphs`, was ordinarily squash-merged at 2026-09-29 00:32:24 UTC. It was opened from `fix/phase168-dependency-security` after refreshing public `main` to `ad73b92d5883b4136fa961e134c987a95939fac2`. The candidate remained based on that clean public-main commit; no rebase followed its final source-specific receipts.

The source candidate is `c2072c15e48993d09b9ea97204b248ab6c0e99e5`; the GitHub pull-request merge ref tested by PR CI is `a0b22c6fb35d7bdd7a9031b17b06800be991fec2`; squash-integrated `main` is `2832e91d725d70eff9ba11d08052260ba17e2747`. Candidate, merge-ref, and current `origin/main` trees all resolve to `cbd9633fc73dba607c808feca97849348ee6eec1`. The merge commit has the expected base and candidate parents. The task-owned candidate checkout was clean after delivery.

The reviewed candidate contains these 21 paths relative to the refreshed base:

- `.github/workflows/ci.yml`
- `examples/phoenix_meilisearch/README.md`
- `mix.lock`
- `examples/phoenix_meilisearch/mix.lock`
- `examples/scrypath_ecommerce/mix.lock`
- `scrypath_ops/mix.lock`
- `scrypath_ops/mix.exs`
- `lib/mix/tasks/verify/adopter.ex`
- `lib/mix/tasks/verify/capability.ex`
- `lib/mix/tasks/verify/phoenix_example/lock_graph.ex`
- `lib/mix/tasks/verify/phoenix_example/package.ex`
- `scripts/ci/dependency_audit.ex`
- `scripts/ci/dependency_audit.exs`
- `test/mix/tasks/dependency_audit_test.exs`
- `test/mix/tasks/verify_adopter_test.exs`
- `test/mix/tasks/verify_capability_test.exs`
- `test/mix/tasks/verify_lock_graph_test.exs`
- `test/mix/tasks/verify_phoenix_example_package_test.exs`
- `test/mix/tasks/workflow_wiring_test.exs`
- `test/release/consumer_smoke_test.exs`
- `test/scrypath/phase99_contract_test.exs`

The source history retains the selected Plan 02/03/04 commits and focused review corrections. The final two fixes bound package/audit failures to their exact rows, and locate Erlang from the active toolchain in CI. Plan 01 remains linked in [168-01-DELIVERY.md](168-01-DELIVERY.md): its startup correction was delivered separately by PR #82 and produced the clean security base `ad73b92d5883b4136fa961e134c987a95939fac2`.

Internal review found two actionable issues, both fixed before PR creation. The GitHub review decision is empty; the repository's required-check policy did not require a pull-request approval. No reviewer identity or approval was simulated.

## Candidate and hosted checks

| Evidence | Source / event | Result |
|---|---|---|
| [PR CI run 36502225556, attempt 1](https://github.com/szTheory/scrypath/actions/runs/36502225556) | PR #84, candidate `c2072c1`; tests ran on merge ref `a0b22c6` | Success. Required `core`, `package`, `repository-contracts`, `backend`, and `ecommerce-mounted` passed. Named `deep-quality`, `phoenix-example`, and path-selected Ops proof passed. |
| [Workflow Security run 36502225479](https://github.com/szTheory/scrypath/actions/runs/36502225479) | PR #84 candidate | Success, including action lint/pin and dependency review checks. |
| [Exact-SHA closeout run 36502764736, attempt 1](https://github.com/szTheory/scrypath/actions/runs/36502764736) | `workflow_dispatch`, candidate `c2072c1` | Success. `core`, `package`, `repository-contracts`, `backend`, `ecommerce-mounted`, `coverage`, and `closeout-attestation` all succeeded. Manual closeout does not select Ops; its successful PR and main jobs are recorded separately. |

The closeout artifacts were coverage artifact `11005868811`, digest `sha256:5e90be802c29c71cce0524438eaa40b24ac8814557dbd8ce6e36d18947a04d18`, and attestation artifact `11005949117`, digest `sha256:ff76ab819578bd306d40698f0f6358a95d3c319ddafb8c766d03fa9b483d9e6d`. Both reported expiry `2026-10-06`; the immutable digests are retained here.

## Four-graph audit and cost

All runs used Hex 2.5.1. The final candidate audit and the PR merge-ref/main deep-quality outputs reported four complete clean graphs, the default ignore source with ignore values `[]`, no retired or advisory packages, and matching pre/post lock hashes. PR merge-ref and integrated main trees equal the candidate tree.

| Maintained graph | Candidate `mix.lock` SHA-256 | Relevant resolved packages |
|---|---|---|
| Root | `eddb9ca9c92557f5a550ff66f3b8f4ce3eb1a1ffc6e1d162654e9b5cc3d90490` | Mint 1.11.0; HPAX 1.1.0 |
| Phoenix example | `881a93c36747f2e19c29df42a0b59a47ec913110fc75c8b7c028a72d90d0549f` | Mint 1.11.0; HPAX 1.1.0 |
| Ecommerce example | `fd5012b15692b72731c8a576b03787f22e932c5e06e0e086a7778f1d2b2ce136` | Mint 1.11.0; HPAX 1.1.0; lazy_html 0.1.13 |
| Standalone Ops | `887aaa6506a3d6525863b515bafa7801abfffb225432ee503cb5553be28a3fbe` | Mint 1.11.0; HPAX 1.1.0; lazy_html 0.1.13 |

Cold and reused-cache samples were taken at the same candidate in isolated disposable workspaces with separate per-project dependency/build caches. Values below are fetch/audit milliseconds; the audit inventory includes the root baseline row.

| Graph | Cold fetch / audit | Reused fetch / audit |
|---|---:|---:|
| Root baseline | 2,973 / 1,415 | 1,201 / 1,565 |
| Phoenix | 1,750 / 1,408 | 961 / 1,482 |
| Ecommerce | 2,483 / 1,612 | 1,230 / 1,649 |
| Ops | 3,672 / 1,923 | 1,284 / 1,791 |
| Three consumers, added over root | 7,905 / 4,943 (12.848 s combined) | 3,475 / 4,922 (8.397 s combined) |
| All four rows | 10,878 / 6,358 (17.236 s combined; 17.72 s wall) | 4,676 / 6,487 (11.163 s combined; 11.67 s wall) |

The root baseline itself was 4.388 s cold and 2.766 s reused. The measurements did not justify adding another GitHub cache. They exclude compilation and Dialyzer, and are local Mac samples rather than a hosted-latency promise. The cold sample used task-owned isolated caches; the global Hex cache was not used as acceptance evidence.

## Phoenix modes and local verification

At candidate `c2072c15e48993d09b9ea97204b248ab6c0e99e5`:

- `mix verify.phoenix_example` passed 10 tests. Its resolved lock SHA was `881a93c36747f2e19c29df42a0b59a47ec913110fc75c8b7c028a72d90d0549f`, unchanged from the reviewed Phoenix lock.
- `mix verify.phoenix_example --package` passed 10 tests. It resolved the explicitly built local Scrypath artifact tied to candidate source `c2072c1`, tag `v0.3.13`, local artifact commit `6349711b0d5329641edd34ac4a91e0725c8ac4ff`, and package graph lock SHA `c5cada4219fab62d158584466f413cc26b4dcb5c8b9f7658a7655aa5a3d4b5b6`.
- The candidate source archive was kept outside the checkout in external temporary storage, SHA-256 `a2b45ccdd224e82374b16a757620b94cb208e8216d55c077c6d799df1b4f1fb4`.
- `MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors --exclude integration --exclude docs_contract` passed: 4 properties, 610 tests, 0 failures (82 excluded). `MIX_ENV=test mix verify.core --exclude integration --exclude docs_contract` passed formatting, cleanliness, warnings-as-errors compile, Credo, those tests, and docs with warnings as errors.
- `mix verify.ops_ui` passed 2 doctests and 154 tests. It printed existing nonfatal Dialyzer warnings, but the named task succeeded.

The local archive and local package commit are test artifacts, not a public publication. Hosted Phoenix package steps also passed: PR validation recorded package artifact commit `1e531d02a82d3404c7f94c03fb794289f5c5b45a` and package lock SHA `0e4d5de8a81b26b6b066133f626b88b57b7de0d587d924a00a285324b5a51657`; main validation recorded artifact commit `cad0e8603acf58043314102b94bcb1650698bdcb` and package lock SHA `bdef2714de3e2c8015ac404cc4379f3974bbf5ead3b3ae6d2c4ba4f4a934304f`.

## Protected merge and integrated main

PR #84 merged normally with the candidate head matched; no branch-protection bypass was used. The merge ref's tree and squash-main tree match the candidate's tree. Refreshed `origin/main` is `2832e91d725d70eff9ba11d08052260ba17e2747`.

The source-specific [push run 36503602888, attempt 1](https://github.com/szTheory/scrypath/actions/runs/36503602888) completed successfully at the integrated main SHA. Its five required jobs (`core`, `package`, `repository-contracts`, `backend`, `ecommerce-mounted`) all passed. The named `deep-quality` advisory, `phoenix-example` advisory, and path-selected `ops-ui` jobs also passed. `coverage`, `ecommerce-e2e`, and `closeout-attestation` were skipped for this push event as configured; they passed where applicable in the exact-candidate closeout or are not push gates. The Phoenix path and package steps, four graph summaries, and Ops proof were inspected in the run logs. The Ops task passed 2 doctests and 154 tests.

## Delivery limits and cleanup

- Published Hex identity for candidate `c2072c1`: **none**. Existing published Scrypath 0.3.13 is not evidence of this candidate. Release Please opened [PR #83](https://github.com/szTheory/scrypath/pull/83); it was not merged or published as part of Phase 168. Phase 170 retains its approved release/readiness work.
- There are no remaining delivery blockers or resume actions for Phase 168. Plan 01's startup PR #82 and receipt remain linked above.
- The isolated source candidate and cold-audit checkout/caches, plus the explicitly named task-owned containers, are disposable Phase 168 resources. They are scheduled for removal after the receipts and verification report are durable. The original maintainer checkout's unrelated tracked and untracked changes are preserved.

---
*Phase: 168 — Dependency Security and Reliable Verification*
*Plan: 05 — protected security delivery*
