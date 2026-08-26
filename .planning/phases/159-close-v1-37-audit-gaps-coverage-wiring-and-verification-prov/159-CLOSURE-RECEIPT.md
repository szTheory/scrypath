# Phase 159 Closure Receipt

## Scope and source identity

This receipt separates repeatable local present-state evidence from the hosted
exact-SHA evidence required by D-19. It does not reconstruct TEST-01 chronology
and it does not publish a Hex package or reopen release-parity work.

| Field | Value |
| --- | --- |
| Local source SHA | `7409ee87b4c3c355644fb2b5a60fc271b845139c` |
| Local evidence window (UTC) | `2026-08-26T20:33:21Z`–`2026-08-26T20:35:12Z` |
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
| Core | `mix verify.core --exclude integration --exclude docs_contract` | `20:33:21Z`–`20:35:12Z` | 0 | Format, packaged-path cleanliness, warning-fatal compile, Credo, fast suite, and docs gate passed. | Required root release-train gate; service/docs-contract exclusions are explicit. |
| Optional-dependency fence | `mix verify.no_optional_deps` | `20:33:21Z`–`20:35:12Z` | 0 | Compiled 142 files without optional dependencies, warnings fatal. | Root optional-dependency boundary. |
| Repository contracts | `mix verify.repository_contracts` | `20:33:21Z`–`20:35:12Z` | 0 | 61 trust/repository contract tests passed. | Required workflow/repository topology. |
| Package contract | `mix verify.package` | `20:33:21Z`–`20:35:12Z` | 0 | Release package/consumer contract suite passed. | Required package/release-source contract; no publish. |
| Deep quality | `mix verify.deep_quality` | `20:34:00Z`–`20:35:12Z` | 0 | Optional-dependency compile, namespace fence, Hex audit, and Dialyzer completed with zero errors. | Advisory deep-analysis capability, verified locally only. |
| Coverage producer | `mix verify.coverage` | `20:34:00Z`–`20:35:12Z` | 0 | Informational fast-suite coverage report produced under `cover/` (3.3 MiB locally). | Producer success only; hosted retention/artifact identity remains pending D-19. |
| Xref cycles | `mix xref graph --format cycles` | `20:34:00Z`–`20:35:12Z` | 0 | `No cycles found`. | Runtime dependency graph. |
| Workflow wiring | `mix test test/mix/tasks/workflow_wiring_test.exs --warnings-as-errors` | `20:34:00Z`–`20:35:12Z` | 0 | Focused executable workflow contract passed, including advisory coverage wiring. | CI configuration contract. |
| Workflow syntax | `actionlint .github/workflows/ci.yml` | `20:34:00Z`–`20:35:12Z` | 0 | No syntax findings. | CI workflow syntax. |
| Pin / least-privilege proof | immutable-pin scan over `.github/workflows/*.yml`; inspect `permissions` in `ci.yml` and `workflow-security.yml` | `20:34:00Z`–`20:35:12Z` | 0 | Every executable `uses:` ref is a 40-character SHA; both checked workflows default to `contents: read`; dependency review has only its job-scoped read permissions. | Phase 156 supply-chain and least-privilege source contract; no secrets emitted. |

The source-only proof confirms the planned coverage job remains scheduled/manual,
informational, and non-blocking. It cannot establish that a hosted run used this
source or that an always-uploaded artifact had a successful producer; those facts
are intentionally deferred to the hosted section.

## Hosted exact-SHA evidence — pending Task 2

Task 1 must be committed before a candidate closing SHA is derived. Task 2 will
record the candidate SHA, GitHub repository/workflow/run URL, trigger, attempt,
timestamps, `headSha` equality, required-job conclusions, advisory/path-scoped
outcomes, coverage producer/upload conclusions, and inspected artifact metadata,
digest, and retention here. Branch-name-only evidence is insufficient.

| Field | Value |
| --- | --- |
| Candidate closing SHA | Pending Task 1 evidence commit |
| Hosted run ID | Pending exact-SHA run |
| Hosted workflow/source SHA | Pending exact-SHA run |
| Coverage artifact | Pending exact-SHA run |
| D-20 advisory/path-scoped disposition | Pending observation; no promotion is authorized |
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
