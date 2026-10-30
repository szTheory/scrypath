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
