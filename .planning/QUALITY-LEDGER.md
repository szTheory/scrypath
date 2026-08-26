# Quality Evidence Ledger

**Scope:** v1.37 Code Quality Ratchet (non-UI)
**Closed:** 2026-08-26

This ledger records evidence, expected benefit, implementation churn, verification,
and final disposition. ScrypathOps presentation, UX, and visual judgment were
explicitly excluded.

| Rank | Finding and evidence | Impact / benefit | Churn | Verification | Disposition |
|---:|---|---|---:|---|---|
| 1 | External settings, failed-work, and payload values could reach atom conversion paths | Prevent VM atom exhaustion from untrusted runtime values | Medium | Runtime-safety properties and focused settings/operator tests | **Fixed:** unknown external keys remain strings; recovery uses existing atoms only |
| 2 | Oban payloads and transport options could carry credentials or override endpoint/auth boundaries | Prevent durable secret exposure and configuration bypass | Medium | Payload/retry/related-sync tests plus property checks | **Fixed:** API keys resolve at execution; ephemeral-only enqueue is rejected; transport options are bounded |
| 3 | Telemetry error metadata and task-history traversal were not explicitly bounded | Prevent secret leakage, oversized events, and silent partial operational views | Medium | Telemetry suites and Meilisearch task pagination tests | **Fixed:** sanitized bounded metadata; default 1,000-task cap with explicit truncation error |
| 4 | Runtime xref cycles crossed schema metadata, composition, search, and failed-work responsibilities | Improve local reasoning, testability, and change isolation | High | `mix xref graph --format cycles` | **Fixed:** zero cycles; dedicated leaf modules and orchestration facades |
| 5 | Sync/backfill paths interpreted backend-shaped write results independently | Reduce duplicated lifecycle semantics and backend leakage | Medium | Sync/backfill/Oban focused suites | **Fixed:** shared `Scrypath.Operations.Result` and task vocabulary |
| 6 | Search and failed-work modules mixed retrieval, translation, telemetry, and result decoration | Make high-change orchestration readable without public API churn | Medium | Search, tuning, failed-work, status, and reconcile suites | **Fixed:** focused internal modules behind preserved facades |
| 7 | Quality commands were phase-number-centric and CI duplicated proof | Make intent discoverable and reduce repeated test/docs work | Medium | Canonical task tests; `verify.core`, `verify.package`, `verify.repository_contracts`, `verify.compatibility` | **Fixed:** capability-named commands and lean required/advisory job graph |
| 8 | Workflow actions used mutable tags and workflow edits lacked an executable pin policy | Reduce third-party supply-chain drift and over-privileged automation | Low | `actionlint`; local immutable-pin scan; release contract tests | **Fixed:** full SHA pins, least permissions, dependency review, syntax/pin workflow |
| 9 | Optional-dependency compilation, test warnings, and coverage evidence were fragmented | Catch undeclared runtime coupling and warning regressions | Low | `mix verify.no_optional_deps`; warning-fatal core suite; `mix verify.coverage` | **Fixed:** forced child compile and informational coverage command |
| 10 | The new deep gate initially exposed four impossible guards and strict-Credo complexity | Turn advisory tooling into an executable signal instead of decorative CI | Low | `mix verify.deep_quality` | **Fixed:** Hex audit and Dialyzer run independently; zero Dialyzer/Credo findings |
| 11 | Two stable pure paths lacked reproducible cost evidence | Avoid speculative micro-optimization | Low | `BENCHMARK_TIME=1 BENCHMARK_WARMUP=1 MIX_ENV=dev mix run bench/core_paths.exs` | **Measured, no change:** both paths are sub-microsecond; backend/network dominates |
| 12 | Historical `verify.phase*` tasks contain bespoke focused proof rather than sharing one artificial dispatcher | A mechanical rewrite would create broad churn without reducing runtime risk | High | Existing strict argument/contract suites; canonical replacement table in `CONTRIBUTING.md` | **Retained:** compatible focused commands remain; canonical commands own new CI/docs usage |
| 13 | Supporting both `verify.opsui` and `verify.ops_ui` creates case-only BEAM module names on case-insensitive filesystems | Dual spelling produces loader errors even when one spelling is only a Mix alias | Low | clean compile, ExDoc warnings-as-errors, task help | **Resolved by canonicalization:** `verify.ops_ui` is the sole spelling; historical docs remain in archives only |
| 14 | Extraction review found boolean `one_way` precedence had drifted from the original settings translator | Preserve explicit canonical `false` over duplicate unrecognized values | Low | Focused settings regression test plus full gates | **Fixed:** explicit non-nil canonical values retain precedence |
| 15 | ScrypathOps visual/UI polish opportunities exist outside this milestone | Avoid consuming maintainer feedback time and mixing presentation judgment with library quality | — | Scope guard | **Excluded by owner direction** |

## Final evidence

- `mix verify.core --exclude integration --exclude docs_contract`: 556 tests, 4 properties, strict Credo, format, warning-free compile, workspace proof, and ExDoc passed.
- `mix verify.package`: 76 release/package tests and unpacked Hex build passed.
- `mix verify.repository_contracts`: 60 repository/workflow contract tests passed.
- `mix verify.compatibility`: 556 tests and 4 properties passed locally; CI owns the four explicit Elixir/OTP tuples.
- `mix verify.deep_quality`: no-optional-dependencies compile, namespace fence, Hex audit, and Dialyzer passed with zero findings.
- `mix verify.backend`: 7 live Meilisearch integration tests across four curated suites passed.
- `actionlint .github/workflows/*.yml` and the immutable action-pin scan passed.
- `mix xref graph --format cycles`: no cycles found.
- Manual security and correctness review found no remaining Critical, High, or Medium findings.

## Diminishing-return boundary

No confirmed compatible high- or medium-leverage finding remains open. The
remaining candidates are historical-command consolidation, speculative hot-path
micro-optimization, or UI judgment; each is either higher churn than benefit,
unsupported by measurements, or explicitly out of scope.
