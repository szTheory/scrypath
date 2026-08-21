# Project Research Summary

**Project:** Scrypath v1.36 Dependency Security Remediation
**Domain:** Security maintenance for four independently resolved Elixir/Mix dependency graphs
**Researched:** 2026-08-21
**Confidence:** MEDIUM

## Executive Summary

This is a maintenance-only remediation, not a library or platform upgrade. Scrypath has four separately locked Mix projects—root, the legacy Phoenix example, ScrypathOps, and the ecommerce example—connected by local path dependencies but not by a shared resolver or lockfile. The correct delivery shape is therefore four serialized, graph-local batches and commits: root HTTP client first, legacy Phoenix/Ecto-Decimal next, standalone Ops third, and ecommerce with mounted Ops last. Every batch must update only its owned manifest and lockfile (plus a narrowly demonstrated compatibility fix), pass its native proof, and stop on failure before the next begins.

Use the 2026-08-16 advisory ledger's fixed-compatible minima rather than package-head upgrades. Raise direct lower bounds where a declared range could reselect a vulnerable version, especially Req `~> 0.6.1` in root, Ops, and ecommerce; let Mint and hpax resolve transitively; and move the legacy example's Ecto/Ecto SQL to the coordinated 3.14.x line so Decimal 3 can resolve. Preserve current Phoenix 1.8, LiveView 1.1, the existing CI topology, the advisory status of browser E2E, and all product/API scope boundaries.

The major implementation risk is false closure: root-only proof, broad unlocks, stale builds, or a skipped service lane can look green while a downstream graph remains vulnerable or broken. Require dated `mix deps.get` evidence from every owning working directory, explain every lock diff, and distinguish required deterministic gates from service-dependent advisory evidence. A specific release-truth conflict remains unresolved: triage names Postgrex `0.22.4` as the fixed floor, but current official Hex metadata lists `0.22.3` as the newest stable 0.22 release. Do not invent a substitute version or use the 1.0.0 prerelease; before any Postgrex constraint is changed, verify both the live advisory record and Hex publication, then use the first published stable 0.22 release explicitly marked fixed.

## Key Findings

### Recommended Stack

No new stack is warranted. Retain Elixir/Mix, Ecto/Phoenix, Bandit, Oban, Req, and the four-project repository topology; make only the bounded dependency floor changes needed to clear the recorded advisories. The root library's Req transition is the only expected source-compatibility review: Req 0.6 changes automatic decompression/decoding defaults, so existing JSON Meilisearch request and error paths must be covered rather than redesigned.

**Core technologies and remediation floors:**

- **Req `~> 0.6.1`**: direct root, Ops, and ecommerce HTTP-client floor; prevents a fresh resolve returning to the affected 0.5 line.
- **Mint `1.9.3+` and hpax `1.0.4+`**: transitive Req/Bandit HTTP stack floors; verify in each independent lockfile rather than adding unnecessary direct dependencies.
- **Plug `1.19.5+`**: root test-only direct floor and transitive web-app resolution; keep the 1.19 line.
- **Phoenix `~> 1.8.9`, Bandit `~> 1.12.1`, LiveView `~> 1.1.33`**: bounded web-stack fixes for the applicable example/Ops graphs; do not cross into Phoenix 1.9 or LiveView 1.2.
- **Swoosh `~> 1.26.3`**: Ops/ecommerce mail-client fix; exercise Ops's configured `Swoosh.ApiClient.Req` integration.
- **Ecto/Ecto SQL `3.14.x` plus Decimal `3.0.0+`**: coordinated legacy-example solution; Decimal cannot be upgraded safely under its current Ecto 3.13 contract.
- **Postgrex fixed stable `0.22.x`**: an implementation gate, not a preselected version, until official advisory and Hex metadata are reconciled.

### Expected Features

There are no user-facing features in this milestone. Its release contract is a minimal, auditable security remediation that preserves existing behavior and leaves four independently reviewable commits.

**Must have (table stakes):**

- **Four clean graph-local resolutions** — capture `mix deps.get` output in root, legacy Phoenix, Ops, and ecommerce; clear the recorded ledger advisories in each owning graph.
- **Fixed-compatible, declared constraints** — no lockfile-only Req upgrade, Decimal override, advisory suppression, or package-head refresh.
- **Per-batch behavior proof** — root required gates; legacy example tests; `mix verify.opsui`; ecommerce `mix e2e.prepare`; rerun specified root regression gates.
- **Atomic evidence and commits** — one ordered commit per graph, with no unrelated product, UI, docs, generated assets, or CI policy work.

**Should have (operational differentiators):**

- **Advisory-to-lock traceability** — a dated, per-graph before/after resolver and version matrix tied to the 2026-08-16 ledger.
- **Explicit proof boundaries** — report required deterministic gates separately from unavailable, skipped, failed, or passing live/browser evidence.
- **Stop-on-failure handoffs** — record cwd, commands, lock diff, selected versions, and gate outcomes before proceeding.

**Defer (outside v1.36):**

- Broader dependency modernization or package-head upgrades.
- New permanent CI/security scanners, shared dependency tooling, umbrella/workspace conversion, or changed required-check policy.
- Runtime/API, Phoenix UI, search backend, or product-scope changes.

### Architecture Approach

Path dependencies provide local source only; they do not centralize resolution. Root success therefore cannot establish downstream safety, and ecommerce's mounted integration cannot replace standalone Ops proof. Preserve all four manifests and locks as independent ownership boundaries, serialize their work in source/risk order, and treat every downstream resolution as a fresh solver result against local sources.

**Major components:**

1. **Root Scrypath graph** — owns the core Req/Plug change and library regression gates.
2. **Legacy Phoenix graph** — owns the Ecto/Ecto SQL/Decimal transition and legacy endpoint/database behavior.
3. **ScrypathOps graph** — owns standalone Phoenix, LiveView, Bandit, Swoosh, Req, and Postgres-backed proof.
4. **Ecommerce graph** — owns independent web-client resolution, both mounted path dependencies, database preparation, and advisory browser integration evidence.
5. **Cross-batch evidence matrix** — owns dated resolver output, package-version proof, gate status, and four-commit closure evidence.

### Critical Pitfalls

1. **Treating local path dependencies as a shared lockfile** — resolve and inspect every graph from its own cwd; never copy locks or close from root-only evidence.
2. **Broad unlocking or stale artifacts** — change only required constraints, explain every transitive move, and use only targeted cleanup if diagnosis requires it.
3. **Lockfile-only Req remediation** — change the root, Ops, and ecommerce manifests to `~> 0.6.1`; test Req JSON paths and Ops's Req-backed mailer.
4. **Decimal-only remediation** — move legacy Ecto and Ecto SQL together to 3.14.x, then test migrations, casts, Repo startup, and fixtures.
5. **Calling runtime/browser evidence a compile pass** — run the named app gates; report missing Postgres/Meilisearch/browser prerequisites as unavailable, never as passing proof.
6. **Closing with stale advisory data or an invented Postgrex version** — capture current resolver output and resolve the Postgrex registry/advisory conflict before changing its direct floor.

## Implications for Roadmap

Based on the research, the roadmap should contain exactly four implementation phases plus a cross-batch closure criterion. These are dependency-maintenance batches, not feature phases; no separate discovery, UX, API, CI-topology, or release-engineering phase is justified.

### Phase 1: Root HTTP Client Dependency Remediation

**Rationale:** Establish the direct Req floor and a disciplined minimal-diff procedure before downstream path consumers resolve against the updated root source.

**Delivers:** Root `mix.exs`/`mix.lock` selects Req `0.6.1+`, Mint `1.9.3+`, hpax `1.0.4+`, and Plug `1.19.5+`; root compile, fast test, `mix verify --exclude integration`, phase 11, and phase 99 proof pass; one root-only commit.

**Addresses:** Fixed declared constraints, core-library behavior, and auditable evidence.

**Avoids:** Lockfile-only Req changes, package-head churn, stale-build confidence, and untested Req 0.6 decode/decompression behavior.

### Phase 2: Legacy Phoenix and Ecto/Decimal Remediation

**Rationale:** This graph has the unique solver constraint: Ecto/Ecto SQL 3.13 prevents Decimal 3, and it consumes the now-remediated root through a path dependency.

**Delivers:** The legacy example alone moves to the smallest compatible Phoenix/Bandit/Ecto/Ecto SQL/Decimal solution, resolves its transitive Req HTTP stack, passes directory-native tests, and passes the required root fast regression test; one example-only commit.

**Addresses:** Legacy adopter compatibility, aligned Ecto/Decimal remediation, and real Phoenix/Postgres proof.

**Avoids:** Decimal overrides, direct Req addition solely to force a transitive lock, unplanned Phoenix 1.9 movement, and root-only validation.

### Phase 3: ScrypathOps Web/Client Remediation

**Rationale:** Ops has an independent web graph and production Req-backed Swoosh integration; it must prove standalone behavior before ecommerce mounts it.

**Delivers:** Ops-only manifest/lock remediation for Req, Phoenix, Bandit, LiveView, Swoosh, applicable transitive floors, and the verified Postgrex floor; `mix verify.opsui` and the named root gates pass; one Ops-only commit.

**Addresses:** Standalone Ops endpoint/LiveView/mailer behavior and isolated graph evidence.

**Avoids:** Assuming ecommerce can prove Ops, under-testing WebSocket/server changes, and bypassing the Postgrex publication gate.

### Phase 4: Ecommerce Mounted-Ops Remediation and Closure Evidence

**Rationale:** Ecommerce resolves independently and is the only graph that compiles both root and Ops through its mounted application path; it comes last after both source dependencies are green.

**Delivers:** Ecommerce-only fixed-compatible resolution, `mix e2e.prepare`, documented advisory `phase105-e2e` browser result when prerequisites exist, a final four-graph resolver/version/evidence matrix, and one ecommerce-only commit.

**Addresses:** Mounted path integration, tenant-aware preparation, and final advisory closure proof.

**Avoids:** Copying the Ops lock, altering the E2E sandbox contract, treating a skipped browser lane as a pass, and declaring the advisory feed clean without per-cwd output.

### Phase Ordering Rationale

- Root must land first because the other graphs consume its source, but each still resolves and locks independently.
- The legacy example follows because its Ecto/Decimal move is unique and highest solver/migration risk.
- Ops must pass standalone proof before ecommerce mounts it; ecommerce then supplies the final integration boundary.
- Every phase ends in its own green commit, so an unexpected resolver or runtime failure can be localized and rolled back without disturbing earlier proof.
- The Postgrex choice is a gate within every applicable web phase: do not begin the affected constraint update until official advisory status and current stable Hex availability agree.

### Research Flags

Phases likely needing deeper research during planning:

- **Phase 2:** Review Ecto/Ecto SQL 3.14 migration notes and confirm the current legacy fixture/migration behavior before changing the coordinated constraint set.
- **Phase 3:** Recheck the live Postgrex advisory and Hex package metadata immediately before implementation; review Req 0.6 and Swoosh behavior if Ops tests expose a compatibility failure.
- **Phase 4:** Recheck the same Postgrex gate in ecommerce's own solver and validate the documented service/browser prerequisites before attempting advisory E2E proof.

Phases with standard patterns (skip broad research-phase):

- **Phase 1:** Bounded Mix constraint/lock refresh with well-defined root gates; only inspect Req release notes if existing JSON request tests expose a failure.
- **All phases:** No research is needed for new architecture, UI, APIs, CI topology, or product behavior because those are explicitly out of scope.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM | Recorded minima, topology, and most upstream release notes are well supported; Postgrex `0.22.4` conflicts with current official Hex availability. |
| Features | HIGH | Repository scope, acceptance contract, commands, and non-goals are explicit and maintenance-only. |
| Architecture | HIGH | Four independent manifests/locks and path-dependency direction are directly verified repository facts. |
| Pitfalls | HIGH | Graph isolation, test boundaries, lockfile risk, and atomic-commit requirements are repository-specific and corroborated across all reports. |

**Overall confidence:** MEDIUM

### Gaps to Address

- **Postgrex fixed floor:** Verify the live EEF/Hex advisory record and Hex publication list immediately before each affected web-graph implementation. Use the first published stable `0.22.x` release the advisory explicitly marks fixed; if no such release exists, stop for a security/triage decision rather than selecting `0.22.3`, a prerelease, or an invented constraint.
- **Advisory-feed volatility:** The milestone closes against the recorded 2026-08-16 advisories, supported by dated per-cwd resolver output. A feed outage blocks final closure unless documented as a pending confirmation alongside verified lock versions and required gates.
- **Service-dependent behavior:** Postgres, Meilisearch, Node, and Playwright availability determines live/example/browser evidence. Preserve a precise unavailable/failed/passed record; do not weaken required deterministic gates or promote advisory E2E to a new merge blocker.
- **Compatibility fixes:** If a dependency transition requires application-code changes beyond a narrow demonstrated fix, stop the current batch and obtain separate scope approval rather than turning v1.36 into a refactor.

## Sources

### Primary (HIGH confidence)

- `.planning/quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-ADVISORY-TRIAGE.md` — recorded affected graphs, fixed-compatible targets, batch order, and gates.
- `.planning/quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-RESEARCH.md`, `260816-tzr-VERIFICATION.md`, and `.planning/todos/pending/2026-08-16-remediate-dependency-security-advisories.md` — acceptance, reproduced advisory evidence, and remediation boundary.
- Repository manifests and lockfiles; `.planning/PROJECT.md`; `CONTRIBUTING.md`; `.github/workflows/ci.yml`; and `lib/mix/tasks/verify.opsui.ex` — topology, local proof commands, and required/advisory gate boundaries.
- Official Req, Bandit, Phoenix LiveView, Swoosh, Decimal, Ecto, and Ecto SQL release notes — fixed-version and migration-sensitive behavior.

### Secondary (MEDIUM confidence)

- Official Hex package metadata queried 2026-08-21 — package publication/declaration evidence, including the Postgrex discrepancy that requires fresh implementation-time verification.
- Official Mix and Hex documentation — resolver, test, audit, and targeted-clean behavior.

### Tertiary (LOW confidence)

- External advisory-service corroboration and PR dependency review — useful supplemental evidence but not a replacement for the local ledger, per-graph resolver output, or project gates.

---
*Research completed: 2026-08-21*
*Ready for roadmap: yes*
