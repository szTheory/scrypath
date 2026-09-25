# Technology Stack

**Project:** Scrypath — v1.39 Pre-Operator UI Quality Readiness Ratchet  
**Researched:** 2026-09-25  
**Confidence:** HIGH for the existing stack and proof inventory (dated project evidence); MEDIUM for current upstream documentation details.

## Recommendation

Do not add or replace technology for v1.39. This is a whole-product evidence assessment and bounded gap-closure program, not a new product capability. Keep the supported Elixir/Ecto/Phoenix/Oban/Meilisearch stack and the existing Mix, ExUnit, GitHub Actions, and package verification system. Start the baseline by assessing the evidence already recorded in v1.37 and v1.38, then add only the cheapest suitable proof for a confirmed gap.

The key stack decision is a verification policy: use focused tests and contract/seam checks first, then real-service, browser, or hosted exact-SHA evidence only where the claim requires it. Scrypath already has canonical capability-named `mix verify.*` commands, built-in coverage, selected property tests, required and advisory/scheduled CI lanes, and package-backed Phoenix proof. Do not introduce a new coverage, test, CI, or observability product without a specific demonstrated evidence gap and a cost/value case.

## Recommended Stack

### Core Framework

| Technology | Version / support | Purpose | Why |
|---|---|---|---|
| Elixir | Project declaration `~> 1.17`; CI currently exercises 1.19.0 | Library language and Mix task host | Matches the existing public support contract. The baseline should assess representative supported-version evidence; it should not raise the support floor as a side effect of readiness work. |
| OTP | CI currently exercises 28.1; project context records floor 26 and test-through 28 | Runtime and BEAM platform | Retain the established BEAM target. Add matrix coverage only when the baseline finds a meaningful compatibility gap. |
| Ecto | `~> 3.13` in root `mix.exs` | Schema and persistence integration | Core to Scrypath's Ecto-native contract and current runtime behavior. |
| Phoenix / LiveView | Consumer and operator applications have separately resolved dependency graphs | Phoenix adoption and ScrypathOps | Preserve boundaries: Phoenix remains an integration/consumer surface, not a dependency of the root runtime. |

### Database and Search Integrations

| Technology | Version / support | Purpose | Why |
|---|---|---|---|
| PostgreSQL | Used in Phoenix adopter and mounted ecommerce service proof | Consumer persistence integration | Keep real database proof at the existing adopter seam; do not make PostgreSQL a root-library runtime dependency. |
| Meilisearch | CI backend service currently uses `getmeili/meilisearch:v1.15` | Public v1 search backend | This is the declared v1 backend target. Reuse existing backend and package proof; do not broaden the public backend promise during a readiness audit. |
| Oban | Optional dependency, root constraint `~> 2.21` | Production asynchronous synchronization | Preserve optional integration and use its existing adopter proof where relevant. |

### Verification and Infrastructure

| Technology | Version / support | Purpose | Why |
|---|---|---|---|
| Mix + ExUnit | Native project toolchain | Focused tests and canonical verification tasks | Existing `mix verify.core`, `verify.package`, `verify.backend`, `verify.phoenix_example`, `verify.deep_quality`, and other capability commands already map proof to adopter and maintainer capabilities. |
| Erlang `:cover` via Mix | Built-in line coverage | Coverage inspection and gap discovery | Already wired with a zero threshold. Official Mix documentation cautions that line coverage misses some branch behavior and even 100% coverage does not prove assertions; do not use a percentage as a readiness verdict. |
| StreamData | Existing test-only dependency | Property tests for selected high-risk invariants | Reuse for named input spaces where generated cases add meaningful evidence; avoid broad property-test adoption without a concrete invariant. |
| GitHub Actions | Existing workflow, immutable action pins, exact-SHA evidence | Required merge gates and advisory/scheduled proof | Retain the current lean required lanes and proof classifications. Promote a lane only when recurring confidence justifies its runtime and maintenance cost. |
| Docker-backed services and Playwright | Existing mounted ecommerce/browser proof | Boundary-level integration and browser claims | Use only for claims that cannot be established more cheaply. Existing hermetic setup/health/diagnostics/teardown patterns are the reference. |

## Existing Evidence Stack to Reuse

| Evidence source | What it supports | Limit |
|---|---|---|
| v1.37 Phase 159 evidence matrix | Capability-named verification, selected runtime safety and architecture claims, dependency/CI/release evidence, measured performance decisions, explicit provenance classes | Each row states its own source, date/SHA, evidence class, and limitation. It is not a whole-product adopter-readiness audit. |
| v1.38 milestone audit and Phase 161 release evidence | Package-backed Phoenix inline, Oban, and related-data flows; exact-SHA CI; Hex/HexDocs; clean consumer compile; package/tag parity | Phoenix real-service lane is advisory; its final candidate success does not make future runs required. Release evidence proves the named package/release claims only. |
| `.planning/reference/PRE-OPERATOR-UI-READINESS.md` | Baseline dimensions, evidence-ranking fields, exit gate, and automation-first policy | It requires explicit assessment of all dimensions; passing prior work must not be assumed to cover omitted dimensions. |
| `CONTRIBUTING.md` and `.github/workflows/ci.yml` | Maintainer commands, current CI lane topology, current Elixir/OTP job environment | Workflow source proves configuration, not a hosted run; use exact-SHA hosted evidence for claims about a specific run. |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|---|---|---|---|
| Test/coverage platform | Existing ExUnit and built-in Mix coverage | Add a third-party coverage suite or raise coverage threshold | No demonstrated coverage-tool gap. Coverage is diagnostic, not a sufficient readiness metric. |
| CI orchestration | Existing GitHub Actions workflow and capability-named Mix tasks | Add another CI provider or duplicate verification in more jobs | Duplicated lanes add cost and competing evidence without demonstrated value. |
| Integration proof | Existing prerequisite-bound service lanes and package-backed adopter verifier | Make every service/browser lane a required PR gate | Existing policy explicitly weighs repeat confidence against CI runtime and maintenance cost; v1.38's Phoenix service lane remains advisory despite passing final-SHA proof. |
| Runtime or backend surface | Existing Ecto-first Elixir library and Meilisearch v1 backend target | Add public multi-backend support, Phoenix coupling, or a new runtime category | These are product-scope changes prohibited by current scope authority absent a separate owner-approved decision. |

## Installation

No installation or dependency changes are recommended for this milestone. Use the checked-in toolchain and project commands. If the baseline discovers a concrete capability gap, research that narrow addition during its bounded implementation plan before introducing a dependency or CI service.

## Sources

- `.planning/reference/PRE-OPERATOR-UI-READINESS.md` — owner-approved program and exit-gate authority, reconciled 2026-09-25. **HIGH** for project policy.
- `.planning/milestones/v1.37-phases/159-close-v1-37-audit-gaps-coverage-wiring-and-verification-prov/159-EVIDENCE-MATRIX.md` — canonical evidence classes, exact source/command/provenance and limitations for v1.37. **HIGH** for recorded v1.37 claims.
- `.planning/milestones/v1.38-MILESTONE-AUDIT.md` and `.planning/milestones/v1.38-phases/161-release-and-tidy-closeout/161-RELEASE-EVIDENCE.md` — 8/8 requirement audit, exact-SHA runs, package/release evidence, and advisory-lane limitation, dated 2026-09-25. **HIGH** for the named v1.38 claims.
- `mix.exs`, `.github/workflows/ci.yml`, and `CONTRIBUTING.md` — live source for project support declaration, dependencies, test coverage configuration, CI topology, and contributor commands; inspected 2026-09-25. **HIGH** for checked-in configuration; workflow source alone does not prove execution.
- [Mix 1.19.5 `mix test.coverage` documentation](https://hexdocs.pm/mix/Mix.Tasks.Test.Coverage.html) — built-in line-coverage behavior and limitations; accessed 2026-09-25. **MEDIUM** for general tool behavior; project support floor begins at Elixir 1.17.
- [GitHub Actions workflow syntax documentation](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax) — current scheduled-run semantics and token permission configuration; accessed 2026-09-25. **MEDIUM** for current platform behavior; use as context, not evidence that a particular repository run passed.

---
*Stack research for: Scrypath v1.39 Pre-Operator UI Quality Readiness Ratchet*  
*Researched: 2026-09-25*
