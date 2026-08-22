# Roadmap: Scrypath

## Milestones

- ✅ **v1.28 Realistic Demo App & Admin UI Proof** - Phases 102-105 (shipped 2026-05-31) - see `milestones/v1.28-ROADMAP.md`
- ✅ **v1.29 Contract Repair and Proof Hardening** - Phases 106-108 (shipped 2026-05-31) - see `milestones/v1.29-ROADMAP.md`
- ✅ **v1.30 Release Trust and Evidence Maintenance** - Phases 109-112 (shipped 2026-06-01) - see `milestones/v1.30-ROADMAP.md`
- ✅ **v1.31 Adoption Evidence Demo Hardening** - Phases 113-115 (UAT passed 2026-06-01)
- ✅ **v1.32 Admin UI/UX Design System Cleanup** - Phases 116-118 (shipped 2026-06-01) - see `milestones/v1.32-ROADMAP.md`
- ✅ **v1.33 Admin UI Insane Polish** - Phases 119-127 (shipped 2026-06-03) - see `milestones/v1.33-ROADMAP.md`
- ✅ **v1.34 Both-Themes Perfection - Dark Signature + AA Gate** - Phases 128-136 (shipped 2026-06-29; archived 2026-07-11) - see `milestones/v1.34-ROADMAP.md`
- ✅ **v1.35 Brand System & Logo Identity** - Phases 137-143 (shipped directly 2026-06-24; archived 2026-07-11) - see `milestones/v1.35-ROADMAP.md`
- 🚧 **v1.36 Dependency Security Remediation** - Phases 144-147 (planned)

## Active Roadmap

**Milestone goal:** Clear the reproduced dependency advisories across four independent Mix dependency graphs while preserving behavior, release confidence, and the maintenance-only product boundary.

**Execution guardrails:** Execute the four phases and commits in order. Each batch owns only its graph-local manifest, lockfile, and any narrowly demonstrated compatibility fix; stop on any failed required gate before beginning the next batch. Use recorded fixed-compatible versions rather than package-head upgrades. Required deterministic proof and service-dependent advisory proof must be reported separately. A Postgrex constraint change is blocked until the live advisory and Hex registry both confirm a stable, published fixed release; never invent a version or use a prerelease.

## Phases

- [ ] **Phase 144: Root HTTP Client Dependency Remediation** - Remediate the root Req/HTTP stack with behavior-preserving library proof.
- [ ] **Phase 145: Legacy Phoenix and Ecto/Decimal Remediation** - Resolve the legacy example's coordinated web and data dependency constraints.
- [ ] **Phase 146: ScrypathOps Web/Client Remediation** - Prove ScrypathOps independently resolves and operates on fixed-compatible dependencies.
- [ ] **Phase 147: Ecommerce Mounted-Ops Remediation and Closure Evidence** - Remediate the mounted integration and close all four graph-local evidence and commit boundaries.

## Phase Details

### Phase 144: Root HTTP Client Dependency Remediation

**Goal**: Maintainers can use the root Scrypath dependency graph without its recorded Req, Mint, hpax, or Plug advisories while retaining covered Req-backed behavior.
**Depends on**: Nothing (first phase)
**Requirements**: SEC-01, COMPAT-02
**Success Criteria** (what must be TRUE):

  1. A fresh root dependency resolution selects fixed-compatible Req, Mint, hpax, and Plug versions rather than the recorded advisory versions.
  2. The root library's documented deterministic compile, fast-test, verification, phase-11, and phase-99 gates pass on the remediated graph.
  3. Existing Req-backed Meilisearch request/error handling and Swoosh behavior remain covered and pass after the Req 0.6 transition.
  4. One minimal, explained shared Req compatibility handoff spans the three direct manifests and four locks, followed by graph-local legacy, Ops, and ecommerce remediation.

**Plans**: 1/3 plans executed

Plans:
**Wave 1**

- [x] 144-01-PLAN.md — Reconcile delivery truth and land the atomic three-manifest/four-lock Req-floor handoff.

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 144-02-PLAN.md — Prove focused Req.Test and telemetry compatibility with conditional private-source ownership.

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 144-03-PLAN.md — Run deterministic release gates and exact-candidate fresh-resolution/audit evidence.

### Phase 145: Legacy Phoenix and Ecto/Decimal Remediation

**Goal**: Maintainers can run the legacy Phoenix example on a coordinated fixed-compatible Phoenix, Bandit, Ecto, Ecto SQL, and Decimal dependency set.
**Depends on**: Phase 144
**Requirements**: SEC-02
**Success Criteria** (what must be TRUE):

  1. A fresh resolution from the legacy example directory selects the bounded fixed-compatible Phoenix/Bandit and Ecto/Ecto SQL/Decimal set without its recorded advisories.
  2. The legacy example's documented deterministic tests and required root fast regression proof pass with its local path dependency.
  3. Legacy application database, migration, fixture, cast, and endpoint behavior remains usable under the coordinated Ecto/Decimal upgrade.
  4. The legacy example's manifest and lockfile form one isolated, explained second commit with no Decimal override or package-head churn.

**Plans**: TBD

### Phase 146: ScrypathOps Web/Client Remediation

**Goal**: Maintainers can independently run ScrypathOps on its fixed-compatible web, LiveView, mailer, HTTP, database, and transitive dependency graph.
**Depends on**: Phase 145
**Requirements**: SEC-03, EVID-03
**Success Criteria** (what must be TRUE):

  1. A fresh ScrypathOps resolution selects fixed-compatible bounded web, LiveView, Swoosh, Req, and applicable transitive versions without its recorded advisories.
  2. `mix verify.opsui` and the named required root regression gates pass against the standalone remediated ScrypathOps graph.
  3. The configured Req-backed Swoosh integration remains covered and works without relying on ecommerce as proof.
  4. Any Postgrex update uses only a stable published release confirmed fixed by both the live advisory and Hex registry; otherwise this batch stops without a substitute version.
  5. The ScrypathOps manifest and lockfile form one isolated, explained third commit with no unrelated upgrades.

**Plans**: TBD

### Phase 147: Ecommerce Mounted-Ops Remediation and Closure Evidence

**Goal**: Maintainers can run the ecommerce mounted integration on its own remediated graph and can audit complete, ordered closure evidence for all four graphs.
**Depends on**: Phase 146
**Requirements**: SEC-04, COMPAT-01, COMPAT-03, EVID-01, EVID-02
**Success Criteria** (what must be TRUE):

  1. A fresh ecommerce-directory resolution selects fixed-compatible dependencies without its recorded advisories while consuming the green root and ScrypathOps sources through their mounted paths.
  2. `mix e2e.prepare` and the documented required deterministic checks pass before the ecommerce batch is committed.
  3. Available ecommerce browser proof is recorded separately as passed, failed, or unavailable with its prerequisites; unavailable service/browser prerequisites are never reported as passing required proof.
  4. Dated `mix deps.get` evidence from each of the root, legacy Phoenix, ScrypathOps, and ecommerce directories shows none of the 2026-08-16 recorded advisories.
  5. The final evidence records four ordered, graph-local commits and explains every manifest/lockfile change, with each required gate passing before the following batch began.

**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 144. Root HTTP Client Dependency Remediation | 1/3 | In Progress|  |
| 145. Legacy Phoenix and Ecto/Decimal Remediation | 0/TBD | Not started | - |
| 146. ScrypathOps Web/Client Remediation | 0/TBD | Not started | - |
| 147. Ecommerce Mounted-Ops Remediation and Closure Evidence | 0/TBD | Not started | - |

## Direct-Completion Bookkeeping Note

v1.35 Brand System & Logo Identity was completed directly in commit `fcb8fc7` (`feat(brand): v1.35 brand system & scry/path logo + adoption`) rather than through normal GSD plan/execute phase artifacts.

That is expected historical state. Do **not** reopen phases 137-143 and do **not** create synthetic PLAN/SUMMARY files or phase directories for phases 138-143. The canonical evidence is archived in:

- `milestones/v1.35-ROADMAP.md`
- `milestones/v1.35-REQUIREMENTS.md`
- `milestones/v1.35-MILESTONE-AUDIT.md`

`roadmap.analyze` or similar artifact-count tools may report v1.35 as incomplete because the normal plan files do not exist. Treat that as a bookkeeping artifact, not an open milestone.

## Archived Milestone Note

Historical details remain archived under `milestones/`. Phases 137-143 are direct-completion history and must never be synthesized or reused; v1.36 begins at Phase 144.
