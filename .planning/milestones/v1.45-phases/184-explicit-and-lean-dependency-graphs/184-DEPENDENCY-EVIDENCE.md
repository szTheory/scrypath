# Phase 184 Dependency Evidence

Execution ledger for the four independent Mix dependency graphs. Registry facts below were refreshed on 2026-10-30; exact selections are recorded from each final `mix.lock`, not inferred from broad version requirements.

## Root graph — Task 184-07-01

### Identity and selected versions

- Toolchain used: Elixir 1.19.5 / OTP 28.5 (`ASDF_ELIXIR_VERSION=1.19.5-otp-28`, `ASDF_ERLANG_VERSION=28.5`). This is the project's supported 1.19/28 tuple; it does not prove the 1.17/26 floor.
- Manifest: `mix.exs`, initial SHA-256 `fe61287439d8ca813bc1fae4c1227ddcfe2abc92deb8c09a4f4fcb8b61524eb6`, final SHA-256 `6906ac46c93c41bf5ff8f894c215ddfff44a2353c4b21765f45b308bd7570525`.
- Lock: `mix.lock`, initial SHA-256 `bd30554574b9b902df5e28f027db4dfc04afcb7a7fd8c93b757391e5337d20f8`, final SHA-256 `40535db1c56fdd39c3ec55327c29b6044fe6becb1626289a2973a5d8878f96b3`.
- Selected direct releases: Req 0.7.5; Oban 2.24.2 (still optional); StreamData 1.4.0; ExDoc 0.40.4; Dialyxir 1.4.8. The shipped Req union (`~> 0.6.1 or ~> 0.7`) and Telemetry requirement remain unchanged. ExDoc is now bounded by `~> 0.40`; official release metadata declares Elixir `~> 1.15`, so this keeps the supported 1.17 floor.
- Req 0.7.5 release notes document the `Req.Test` API transition from `put_plug`/`run_plug` to `Req.Test.with_plug`/`Req.Test.stub`; current repository assertions and package consumer checks pass with this lock. The v0.6.3 consumer witness remains available for the lower admitted branch.

### Primary sources

- [Req package metadata](https://hex.pm/api/packages/req) and [Req 0.7.5 release metadata](https://hex.pm/api/packages/req/releases/0.7.5).
- [Req 0.7.5 changelog](https://raw.githubusercontent.com/wojtekmach/req/v0.7.5/CHANGELOG.md), [Req.Test 0.7.5 docs](https://req.hexdocs.pm/0.7.5/Req.Test.html), and [Req.Test 0.6.3 docs](https://req.hexdocs.pm/0.6.3/Req.Test.html).
- [Oban 2.24.2 release metadata](https://hex.pm/api/packages/oban/releases/2.24.2), [StreamData 1.4.0](https://hex.pm/api/packages/stream_data/releases/1.4.0), [ExDoc 0.40.4](https://hex.pm/api/packages/ex_doc/releases/0.40.4), and [Dialyxir 1.4.8](https://hex.pm/api/packages/dialyxir/releases/1.4.8).

### Root proposal dispositions

| Proposal | Evidence and disposition | Revisit trigger |
| --- | --- | --- |
| #69 StreamData | Adopted 1.4.0; current metadata supports the existing `~> 1.3` bound and the root property suite passes. | Revisit if a future release changes its Elixir support or property behavior. |
| #73 Req | Adopted 0.7.5 within the approved Req union; retained optional-independent Req boundary and v0.6 consumer witness. Current `Req.Test` consumers pass. | Revisit on a new stable 0.7.x/0.8 release, a Req.Test API change, or changed support floor. |
| #74 ExDoc | Adopted 0.40.4 and advanced only the dev/test bound to `~> 0.40`; official metadata preserves the 1.17 floor. | Revisit if 0.40 releases change the supported Elixir floor or docs build. |
| #75 Dialyxir | Adopted 1.4.8 under existing `~> 1.4`; dialyzer passes with zero errors. | Revisit on a bound-breaking release or supported-toolchain failure. |
| #76 Oban | Adopted coordinated 2.24.2 (superseding the open 2.24.1 proposal) while preserving `optional: true`; no new public abstraction or runtime requirement. | Revisit on a stable compatible release or change to the optional integration contract. |

The upstream PRs #69, #73, #74, #75 and #76 were all still open when checked; no PR was modified by this execution.

### Verification receipts

All commands ran from the checkout root with the tuple above and task-specific dependency/build paths where applicable:

| Command | Result |
| --- | --- |
| `mix test --exclude integration --exclude docs_contract` | PASS — 5 properties, 1,012 tests, 0 failures; 103 excluded. |
| `mix docs --warnings-as-errors` | PASS. |
| `mix dialyzer` | PASS — zero errors. |
| `mix verify.no_optional_deps` | PASS — isolated build without Oban. |
| `mix test test/scrypath/docs_contract_test.exs --warnings-as-errors` | PASS — 74 tests, 0 failures, including the adjusted verifier contract assertion. |
| `mix verify.package` | PASS — root package/release contract completed and artifact saved. The same gate is repeated after all final locks in Task 184-07-02. |

The original package gate exposed a stale test that expected the removed literal `"mix test"` verifier text. The verifier now builds `{mix, ["test", ...]}` and invokes `System.cmd/3`; the assertion now checks those live dispatch markers. This scoped contract correction is included with the root task.

## Ops and example graphs — Task 184-07-02

### Graph identities and selected releases

All three manifests are unchanged. Their final bounds remain `req: "~> 0.6.1 or ~> 0.7"` and `bandit: "~> 1.13"`; Phoenix/ecommerce keep their existing Oban range, and Ops keeps optional `sigra: "~> 1.5"`.

| Graph | Manifest SHA-256 (unchanged) | Initial lock SHA-256 | Final lock SHA-256 | Final direct selection |
| --- | --- | --- | --- | --- |
| `scrypath_ops` | `771c5b4fe55fcf580cf0a9c141fa33ba9792aa9aa5ba96553bacafc52eb9d58c` | `a9685eba8236f7925d30044db9b2bf96a3c644d61c5f4a13db66af037f4dc95c` | `e6b66680698bac4fc206faeab8af420c9c75dece788013ab8f3afc1bb9b5acc8` | Req 0.7.5; Bandit 1.14.1; Sigra 1.7.1 (optional); no Oban lock entry. |
| `examples/phoenix_meilisearch` | `880f416e409b17a44d3dde88bfa40545d45179f58c4310a60d7062e4ad028fc0` | `2d5aef31720e5d7c428c57d3cfcb3e6392d2d6ec3f3a2219ca017464a171f291` | `61844005edac11b96e952ab06d08fce5dcc8ac5392d50d4ee76b5c2dfea74980` | Req 0.7.5; Oban 2.24.2; Bandit 1.14.1. |
| `examples/scrypath_ecommerce` | `90f0a43f9b1bbfd7fb27196be975afb1132974ce69fa03e1c21145ca1723cca9` | `9c30fb79d83a5e6ce8b97f583bd62774aff9fd466ec998c4070c4d903b5cb4e1` | `36c28d35941568acc6e1f48680bd331ea4497e995d72c9595dd3e1e7154865c3` | Req 0.7.5; Oban 2.24.2; Bandit 1.14.1. |

Elixir 1.19.5 / OTP 28.5 was used for the Ops Sigra tier and all consumer resolution/checks. This verifies the selected supported tier, not every advertised Elixir/OTP matrix tuple. The root no-Oban verifier and package consumer witnesses separately prove the optional boundary and Req 0.6.x branch.

Sigra 1.20.0 is marked retired by Hex as invalid with the message to use the supported `~> 1.5.0` requirement. The Ops manifest's existing `~> 1.5` requirement is intentionally unchanged; because that range admits 1.20.0, the resolver was temporarily narrowed to `~> 1.7.0` to select 1.7.1, then restored. The final lock was checked against the restored manifest. Sigra 1.7.1 is current non-retired 1.x, declares Elixir `~> 1.18`, and therefore was exercised only on the documented 1.18+ tier. Do not replace it with retired 1.20.0 based solely on version ordering.

### Primary sources and advisory evidence

- [Bandit 1.14.1 Hex release metadata](https://hex.pm/api/packages/bandit/releases/1.14.1) and [Bandit package metadata](https://hex.pm/api/packages/bandit).
- [Sigra 1.7.1 release metadata](https://hex.pm/api/packages/sigra/releases/1.7.1), [Sigra 1.20.0 retirement metadata](https://hex.pm/api/packages/sigra/releases/1.20.0), and [Sigra package metadata](https://hex.pm/api/packages/sigra).
- [Oban 2.24.2](https://hex.pm/api/packages/oban/releases/2.24.2) and the Req/Req.Test evidence in the root section.
- [EEF-CVE-2026-95105 / CVE-2026-95105](https://osv.dev/vulnerability/EEF-CVE-2026-95105) reports the high-severity Cloak 1.1.4 AES-CTR authentication issue; [EEF-CVE-2026-94206 / CVE-2026-94206](https://osv.dev/vulnerability/EEF-CVE-2026-94206) reports the medium-severity Cloak Ecto 1.3.0 PBKDF2 iteration-count issue.
- The final [dependency audit implementation](../../../scripts/ci/dependency_audit.exs) ran with its required isolated Hex 2.5.1 archive. It checked each final lock via `mix deps.get --check-locked` and `mix hex.audit`, verified lock bytes remained unchanged, and reported default empty ignore settings for every graph.

Hex 2.5.1's final audit result: root, Phoenix example and ecommerce are `clean`; Ops is `affected` and exits non-zero only for the two Cloak findings above. The aggregate audit is `failed` because of those active Ops advisories. No advisory or retirement was ignored. Bandit 1.14.1 is selected in all three HTTP graphs and produces no Bandit advisory in Hex's update or final full-lock audit; Bandit 1.13.1 was the affected prior release. The Cloak results remain explicitly unaccepted and are not cleared by the Bandit fix.

`mix deps.unlock --unused` ran only after each complete graph was fetched and inspected. It removed only `swoosh` and `idna` where they were present (Ops and ecommerce); Phoenix required no additional prune. Both packages are absent from all three final active `mix deps.tree` outputs and locks. Other active transitive packages were retained. Each post-prune `mix deps.get --check-locked` resolved without changing the lock.

The first Ops resolution selected retired Sigra 1.20.0. That result was not accepted; the temporary resolver constraint described above produced the verified non-retired 1.7.1 lock. The final Ops audit's high and medium Cloak findings remain a known, unaccepted limitation.

### Final-lock behavior receipts

The four final locks were checked after pruning with `mix deps.get --check-locked`; all resolved without lock mutation. Using Elixir 1.19.5 / OTP 28.5 and independent private build/dependency paths:

| Command | Result |
| --- | --- |
| Root `mix verify.package` after consumer lock updates | PASS — final confirmation completed; package consumer witnesses selected Req 0.6.3 and 0.7.5 and the release contract completed. |
| `mix verify.ops_ui` | PASS — root boundary: 2 tests, 0 failures; Ops direct suite: 2 doctests, 316 tests, 0 failures. The Ops test log also contains PostgreSQL `53300 too_many_connections` connection-attempt errors while the suite was running; the command and suite completed successfully. |
| `mix verify.phoenix_example --package` | PASS — staged package artifact compiled in the Phoenix consumer; 18 integration tests, 0 failures. Package proof resolved Bandit 1.14.1, Oban 2.24.2 and Req 0.7.5. |
| `mix verify.backend` | PASS — Meilisearch smoke checks and Postgres loader checks completed; loader property: 15 tests, 0 failures. |
| `mix verify.ecommerce_mounted` | PASS — default cold test/prod dependency-boundary image proof passed with four served assets per target; focused Playwright: 4 passed; verifier cleanup exit 0. Receipt: `/private/tmp/scrypath-phase184-07-20261030T043624Z/ecommerce-mounted-receipts/scrypath-dependency-boundary-20261030t064636z-48238-17544395.j193KZ/runtime-receipt.json`. |

The Phoenix example's verification services used a unique disposable Compose project and were removed after verification. The retained `scrypath_ecommerce` preview services were left running and unchanged. Runtime receipts and logs remain outside the checkout.

## Final four-graph audit receipt — Plan 184-10

The final aggregate audit ran against source commit `6838085626174c8016e9cf57aa9af84dccab20df` after the four final graph manifests and locks had been selected. Each graph's `mix deps.get --check-locked` returned 0, all lock bytes were unchanged, Hex 2.5.1 reported default empty ignore configuration, and every graph was attempted. The aggregate command returned 1 because the Ops audit returned 1 for the two unaccepted Cloak findings; no finding was ignored or relabeled clean. `mix dialyzer` was then run independently against the same source and returned 0 with zero errors.

| Graph | Source SHA | Manifest SHA-256 | Lock SHA-256 before | Lock SHA-256 after | Toolchain | Hex | Fetch exit | `mix hex.audit` exit | Audit status | Raw evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `.` | `6838085626174c8016e9cf57aa9af84dccab20df` | `6906ac46c93c41bf5ff8f894c215ddfff44a2353c4b21765f45b308bd7570525` | `40535db1c56fdd39c3ec55327c29b6044fe6becb1626289a2973a5d8878f96b3` | `40535db1c56fdd39c3ec55327c29b6044fe6becb1626289a2973a5d8878f96b3` | Elixir 1.19.5 / OTP 28.5 | 2.5.1 | 0 | 0 | clean | `/private/tmp/scrypath-phase184-10-20261030T072352Z/logs/root-hex-audit-final.stdout`, `.stderr`, and `receipts/root-hex-audit-final.exit` |
| `examples/phoenix_meilisearch` | `6838085626174c8016e9cf57aa9af84dccab20df` | `880f416e409b17a44d3dde88bfa40545d45179f58c4310a60d7062e4ad028fc0` | `61844005edac11b96e952ab06d08fce5dcc8ac5392d50d4ee76b5c2dfea74980` | `61844005edac11b96e952ab06d08fce5dcc8ac5392d50d4ee76b5c2dfea74980` | Elixir 1.19.5 / OTP 28.5 | 2.5.1 | 0 | 0 | clean | `/private/tmp/scrypath-phase184-10-20261030T072352Z/logs/phoenix-hex-audit-final.stdout`, `.stderr`, and `receipts/phoenix-hex-audit-final.exit` |
| `examples/scrypath_ecommerce` | `6838085626174c8016e9cf57aa9af84dccab20df` | `90f0a43f9b1bbfd7fb27196be975afb1132974ce69fa03e1c21145ca1723cca9` | `36c28d35941568acc6e1f48680bd331ea4497e995d72c9595dd3e1e7154865c3` | `36c28d35941568acc6e1f48680bd331ea4497e995d72c9595dd3e1e7154865c3` | Elixir 1.19.5 / OTP 28.5 | 2.5.1 | 0 | 0 | clean | `/private/tmp/scrypath-phase184-10-20261030T072352Z/logs/ecommerce-hex-audit-final.stdout`, `.stderr`, and `receipts/ecommerce-hex-audit-final.exit` |
| `scrypath_ops` | `6838085626174c8016e9cf57aa9af84dccab20df` | `771c5b4fe55fcf580cf0a9c141fa33ba9792aa9aa5ba96553bacafc52eb9d58c` | `e6b66680698bac4fc206faeab8af420c9c75dece788013ab8f3afc1bb9b5acc8` | `e6b66680698bac4fc206faeab8af420c9c75dece788013ab8f3afc1bb9b5acc8` | Elixir 1.19.5 / OTP 28.5 | 2.5.1 | 0 | 1 | affected | `/private/tmp/scrypath-phase184-10-20261030T072352Z/logs/ops-hex-audit-final.stdout`, `.stderr`, and `receipts/ops-hex-audit-final.exit` |

The aggregate command's complete captured streams and process result are `/private/tmp/scrypath-phase184-10-20261030T072352Z/logs/dependency-audit-final.stdout`, `logs/dependency-audit-final.stderr`, and `receipts/dependency-audit-final.exit` (1). The before/after manifest and lock fingerprints are in `receipts/audit-final-identities-before.txt` and `receipts/audit-final-identities-after.txt`; they compare equal. The independently executed Dialyzer streams and final result are `logs/dialyzer-final.stdout`, `logs/dialyzer-final.stderr`, and `receipts/dialyzer-final.exit` (0); it reported `Total errors: 0` on source `6838085626174c8016e9cf57aa9af84dccab20df`.

An earlier Dialyzer attempt exited 1 before analysis because the temporary `MIX_REBAR3` path was incorrect (`:enoent`). The private path was corrected to the installed Rebar executable and the complete independent analysis then passed. The failed attempt is retained in `logs/dialyzer.stdout`, `logs/dialyzer.stderr`, and `receipts/dialyzer.exit` for audit history.


## Post-review registry refresh — Phoenix.HTML 4.4.0

The root hosted candidate exposed [CVE-2026-117645](https://cna.erlef.org/cves/CVE-2026-117645.html), published 2026-10-30 after the earlier audit. The [upstream 4.4.0 changelog](https://raw.githubusercontent.com/phoenixframework/phoenix_html/v4.4.0/CHANGELOG.md) and [official release metadata](https://hex.pm/api/packages/phoenix_html/releases/4.4.0) identify the compatible fix and Elixir `~> 1.7` requirement. The isolated Ops and ecommerce resolvers selected only Phoenix.HTML 4.3.0 → 4.4.0; no manifest change or support-floor change was needed. This supersedes those two earlier final lock identities:

| Graph | New lock SHA-256 | Second fetch | Selection |
| --- | --- | --- | --- |
| `scrypath_ops` | `f1771d6219216b5b144f1cf3d220ee487de39da7df071c8bbdaba1b2b3a44fdf` | exit 0; unchanged bytes | Phoenix.HTML 4.4.0 |
| `examples/scrypath_ecommerce` | `19024cdcc5be4d78f43ba990ec6b6113b8f9f58004031591d573834ba4c8817e` | exit 0; unchanged bytes | Phoenix.HTML 4.4.0 |

Both other graph locks remain unchanged. Raw registry responses, independent resolver output and lock identities are external in `/private/tmp/scrypath-phase184-execution/phoenix-html-*`. Canonical Ops, repository-script tests and workflow lint passed after the refresh; hosted four-graph audit and exact-source candidate evidence are still required. The known Cloak/Cloak Ecto findings remain explicitly affected and unaccepted.


Fresh complete audit at repaired-root source `779c13312de1f2a774d39ad6928aac60d2eecfac` is preserved in `/private/tmp/scrypath-phase184-execution/current-root-audit.term`, `.log`, `.exit`. Root, Phoenix example and ecommerce are clean (fetch/audit exit 0); Ops fetches successfully and its audit exits 1 for only Cloak/Cloak Ecto. All before/after hashes equal the current locks, Hex is 2.5.1, and both ignore lists are empty default inputs. The hosted repaired-root audit independently reports the same residual findings in `candidate-repaired-failed.log`. Aggregate exit 1 is preserved.
