# Phase 159 Closure Receipt

## Scope and source identity

This receipt separates repeatable local present-state evidence from the hosted
exact-SHA evidence required by D-19. It does not reconstruct TEST-01 chronology
and it does not publish a Hex package or reopen release-parity work.

| Field | Value |
| --- | --- |
| Local source SHA | `ae66c14d9f99dc8f4ab6333b4bd2ab15bbbb95f9` |
| Local evidence window (UTC) | `2026-08-26T21:10:58Z`–`2026-08-26T21:12:45Z` |
| Git | `2.41.0` |
| Elixir / Mix | `1.19.5` / `1.19.5` |
| OTP | `28` (`erts-16.3`) |
| actionlint | `1.7.12` (Go `1.26.1`) |
| OS | Darwin `25.5.0`, arm64 |
| Workspace status | Known dirty only: two user-owned UAT edits plus the pre-existing Phase 159 `.gitkeep` and `.planning/research/.cache/`; no generated coverage output was left untracked. |

## D-18 local evidence — present-state verified

Every command below ran independently against the local source SHA above and
exited `0`. Results are deliberately bounded; generated reports and raw command
logs are not retained in this receipt.

| Check | Command | UTC window | Exit | Bounded result | Scope |
| --- | --- | --- | ---: | --- | --- |
| Core | `mix verify.core --exclude integration --exclude docs_contract` | `21:10:58Z`–`21:11:19Z` | 0 | Format, packaged-path cleanliness, warning-fatal compile, Credo, fast suite, and docs gate passed. | Required root release-train gate; service/docs-contract exclusions are explicit. |
| Optional-dependency fence | `mix verify.no_optional_deps` | `21:11:19Z`–`21:11:21Z` | 0 | Compiled 142 files without optional dependencies, warnings fatal. | Root optional-dependency boundary. |
| Repository contracts | `mix verify.repository_contracts` | `21:11:21Z`–`21:11:22Z` | 0 | 61 trust/repository contract tests passed, including the explicit full-history checkout contract for UAT-09. | Required workflow/repository topology. |
| Package contract | `mix verify.package` | `21:11:38Z`–`21:11:54Z` | 0 | Release package/consumer contract suite passed. | Required package/release-source contract; no publish. |
| Deep quality | `mix verify.deep_quality` | `21:11:54Z`–`21:12:02Z` | 0 | Optional-dependency compile, namespace fence, Hex audit, and Dialyzer completed with zero errors. | Advisory deep-analysis capability, verified locally only. |
| Coverage producer | `mix verify.coverage` | `21:12:13Z`–`21:12:35Z` | 0 | Informational fast-suite coverage report produced under `cover/` (3.3 MiB locally). | Producer success only; hosted retention/artifact identity remains pending D-19. |
| Xref cycles | `mix xref graph --format cycles` | `21:12:44Z`–`21:12:44Z` | 0 | `No cycles found`. | Runtime dependency graph. |
| Workflow wiring | `mix test test/mix/tasks/workflow_wiring_test.exs --warnings-as-errors` | `21:12:44Z`–`21:12:45Z` | 0 | Focused executable workflow contract passed, including advisory coverage wiring and the history checkout contract. | CI configuration contract. |
| Workflow syntax | `actionlint .github/workflows/ci.yml` | `21:12:45Z`–`21:12:45Z` | 0 | No syntax findings. | CI workflow syntax. |
| Pin / least-privilege proof | `find .github/workflows -name '*.yml' -type f -print0 | xargs -0 rg -o 'uses: [^ @]+@[0-9a-f]{40}'`; immutable-ref negative scan; inspect `permissions` in `ci.yml` and `workflow-security.yml` | `21:12:45Z`–`21:12:45Z` | 0 | Every executable `uses:` ref is a 40-character SHA; both checked workflows declare least-privilege permissions, with `ci.yml` defaulting to `contents: read`; dependency review has only its job-scoped read permissions. | Phase 156 supply-chain and least-privilege source contract; no secrets emitted. |

The source-only proof confirms the planned coverage job remains scheduled/manual,
informational, and non-blocking. It cannot establish that a hosted run used this
source or that an always-uploaded artifact had a successful producer; those facts
are intentionally deferred to the hosted section.

## Hosted exact-SHA evidence — Task 2 verified

Task 1 must be committed before a candidate closing SHA is derived. Task 2 will
record the candidate SHA, GitHub repository/workflow/run URL, trigger, attempt,
timestamps, `headSha` equality, required-job conclusions, advisory/path-scoped
outcomes, coverage producer/upload conclusions, and inspected artifact metadata,
digest, and retention here. Branch-name-only evidence is insufficient.

| Field | Value |
| --- | --- |
| Candidate closing SHA | `a35874178b79392caa0f3c1dcc010ea149e1e5bf` |
| Hosted run ID | `33014343041` |
| Hosted workflow/source SHA | `a35874178b79392caa0f3c1dcc010ea149e1e5bf` / `a35874178b79392caa0f3c1dcc010ea149e1e5bf` (equal to candidate) |
| Hosted workflow / repository / URL | CI / `szTheory/scrypath` / https://github.com/szTheory/scrypath/actions/runs/33014343041 |
| Trigger / attempt / created | `workflow_dispatch` / `1` / `2026-08-26T21:13:33Z` |
| Required jobs | `core`, `package`, `repository-contracts`, `backend`, and `ecommerce-mounted`: all `success` |
| Coverage producer / upload | `Run mix verify.coverage`: `success`; `Upload informational coverage report`: `success` |
| Coverage artifact | `coverage-report-a35874178b79392caa0f3c1dcc010ea149e1e5bf` (ID `9623867267`), 559,802 bytes hosted, expires `2026-09-02T21:14:32Z` |
| Artifact inspection | Downloaded once to a unique `/tmp` directory; report root had `index.html` and 149 files (3,256 KiB); SHA-256 archive `35a80d3bd0a52c080c20bd8bef0299570103aff7792206e846418d7a1ab45819`; content-tree SHA-256 `0b93aad8a14dc2f8f03ad697693dc675f4474d18dd4c41b7b80b083389999dbc`; validated directory removed. |
| D-20 advisory/path-scoped disposition | Compatibility (all four), deep quality, and Phoenix example succeeded; `ops-ui` was correctly path-scoped/skipped; full ecommerce E2E was still in progress at inspection and remains advisory/nonblocking. No lane was promoted. |
| D-21 release disposition | No Hex publish and no release-parity reopening performed |

## Evidence boundary

- Local results are **present-state verified** under D-10/D-18, not evidence of
  an earlier development action.
- TEST-01 remains historically unprovable for only the four bounded parent probes
  listed in `159-HISTORICAL-PROBES.md`; no local or future hosted success can
  launder that chronology.
- The candidate hosted run must show green `core`, `package`,
  `repository-contracts`, `backend`, and `ecommerce-mounted`, while keeping
  compatibility, deep quality, Phoenix example, ScrypathOps, and full ecommerce
  E2E advisory or path-scoped as documented.
