---
phase: 168
plan: "01"
delivery: merged
base_sha: 40c9978c975dbfb42db75511f44ff0369c8d7d88
candidate_sha: e7858cd9afd7b236b8bc7566405183750d1328bf
pr: 82
merge_ref_sha: 5ce7be74777ea03938087b73ebfa2a44da04e082
main_sha: ad73b92d5883b4136fa961e134c987a95939fac2
main_run_id: 36481236762
---

# Phase 168 Plan 01 Delivery Receipt

## Scope

The candidate changes exactly these two paths:

- `examples/scrypath_ecommerce/docker-e2e-entrypoint.sh`
- `test/scrypath/phase147_e2e_contract_test.exs`

The finite `mix e2e.prepare` and `mix scrypath.demo.seed` commands now run with `PHX_SERVER=false`. The final `exec env SCRYPATH_E2E_NO_SANDBOX=1 mix phx.server` command remains the persistent server launch.

## Clean base and preservation

- Refreshed public `main` immediately before branch creation and again before PR opening: `40c9978c975dbfb42db75511f44ff0369c8d7d88`.
- The task-owned GSD clone had an empty tracked and untracked source status before the two-file patch was transferred. The selected branch was `fix/phase168-mounted-readiness`.
- The maintainer checkout started at `dc7101d29b7d9a9e8c387839d3de16a25e1c58bb` on `gsd/v1.38-cleanup-merged`; its original porcelain status and the selected two-file patch were snapshotted before execution. The selected patch snapshot SHA-256 was `ed649abc93ef544624ff6bd79ea3cb84b62db0711f3137185ee07d7cc674e14c`.
- No source edits were made in the maintainer checkout. Its original selected fix and unrelated work remain separate from the clean-main candidate.

## Candidate and local proof

- Base: `40c9978c975dbfb42db75511f44ff0369c8d7d88`.
- RED commit: `4889774` (`test(168-01): assert mounted readiness setup behavior`). On the unchanged public-main entrypoint, the focused ExUnit run exited 2 with 3 tests and 1 expected failure at the `PHX_SERVER=false mix e2e.prepare` assertion.
- GREEN candidate: `e7858cd9afd7b236b8bc7566405183750d1328bf` (`feat(168-01): suppress setup server readiness`). The focused contract passed: 3 tests, 0 failures, using Elixir 1.19.5 / OTP 28.
- Mounted proof on candidate `e7858cd9afd7b236b8bc7566405183750d1328bf`: `mix verify.ecommerce_mounted`; all 4 Playwright checks passed, then the task-scoped containers, volume, and network were removed.
- Standard-depth internal review: clean, 0 findings. Report: `168-REVIEW.md`, committed as `17d95fb` in the maintainer planning checkout.
- The first local dependency restore was redirected to task-owned `HEX_HOME` after the read-only global Hex cache rejected a write; the second restore completed with all locked dependencies unchanged. The root `mix.lock` hash remained unchanged.

## Pull request and hosted closeout

- PR: [#82](https://github.com/szTheory/scrypath/pull/82), titled `fix(ecommerce): keep setup processes from advertising server readiness`.
- Candidate branch: `fix/phase168-mounted-readiness`.
- Candidate SHA: `e7858cd9afd7b236b8bc7566405183750d1328bf`.
- Immediately before delivery, public `main` still named base `40c9978c975dbfb42db75511f44ff0369c8d7d88`. The PR run's five branch-protected contexts were `core`, `package`, `repository-contracts`, `backend`, and `ecommerce-mounted`; all passed at the candidate SHA. Branch protection was strict and required no pull-request review. No administrative bypass was used.
- Synthetic PR merge ref: `5ce7be74777ea03938087b73ebfa2a44da04e082`. Its source entries had the same Git blob IDs as the candidate for both selected paths: entrypoint `fefe017442bf3102bb1eaa4ad0341a29d681a794`; contract test `c7336960c234b91d268a1de994739b31da94b9ae`.
- Candidate PR CI run: [36480023672, attempt 1](https://github.com/szTheory/scrypath/actions/runs/36480023672), event `pull_request`, head `e7858cd9afd7b236b8bc7566405183750d1328bf`, conclusion `success`. Required jobs: `core` [109123091095](https://github.com/szTheory/scrypath/actions/runs/36480023672/job/109123091095), `package` [109123090803](https://github.com/szTheory/scrypath/actions/runs/36480023672/job/109123090803), `repository-contracts` [109123091006](https://github.com/szTheory/scrypath/actions/runs/36480023672/job/109123091006), `backend` [109123090911](https://github.com/szTheory/scrypath/actions/runs/36480023672/job/109123090911), and `ecommerce-mounted` [109123091291](https://github.com/szTheory/scrypath/actions/runs/36480023672/job/109123091291): all `success`.
- Exact-SHA closeout: [workflow-dispatch run 36480151012, attempt 1](https://github.com/szTheory/scrypath/actions/runs/36480151012), conclusion `success`, head `e7858cd9afd7b236b8bc7566405183750d1328bf`. All five required jobs plus `coverage (advisory)` and `closeout-attestation` succeeded. Coverage artifact `10995817637`, digest `sha256:0572547fd742bb4d3595afe336bd623f064a2a6acff20d8c826cada84ab4a014`; closeout artifact `10995593216`, digest `sha256:ce2e5051eaa2b553e9be0809c1344e8e7ab00789e0d421987f75d98b7480a023`.
- `deep-quality (advisory)` failed in both candidate and closeout runs because `mix hex.audit` reported Mint 1.10.1 advisories EEF-CVE-2026-91043 (high), EEF-CVE-2026-92103 (medium), and EEF-CVE-2026-94194 (medium). The jobs are advisory and do not appear among the five protected contexts; the failure remains open for Plan 02's dependency remediation.
- Ordinary squash merge used an exact-head match (`gh pr merge 82 --squash --match-head-commit e7858cd9afd7b236b8bc7566405183750d1328bf`), with no admin override. PR state is `MERGED`; merge commit and refreshed `origin/main`: `ad73b92d5883b4136fa961e134c987a95939fac2`.
- Post-merge verification: [push CI run 36481236762, attempt 1](https://github.com/szTheory/scrypath/actions/runs/36481236762), event `push`, head `ad73b92d5883b4136fa961e134c987a95939fac2`, conclusion `success`. All five required jobs passed: `core` [109127115076](https://github.com/szTheory/scrypath/actions/runs/36481236762/job/109127115076), `package` [109127115141](https://github.com/szTheory/scrypath/actions/runs/36481236762/job/109127115141), `repository-contracts` [109127115223](https://github.com/szTheory/scrypath/actions/runs/36481236762/job/109127115223), `backend` [109127115196](https://github.com/szTheory/scrypath/actions/runs/36481236762/job/109127115196), and `ecommerce-mounted` [109127115507](https://github.com/szTheory/scrypath/actions/runs/36481236762/job/109127115507). The merged main tree retains both candidate blob IDs above.
- The original maintainer checkout still carries its pre-existing selected two-file edits and unrelated dirty work separately; none entered the delivery branch. The original tracked/untracked items remain present. Phase execution added GSD state/lock changes, the review report commit `17d95fb`, and this delivery receipt/summary in planning only.

No Hex package publication or dependency remediation is claimed by this receipt.
