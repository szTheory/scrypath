# Roadmap: Scrypath

## Milestones

- ✅ **v1.28 Realistic Demo App & Admin UI Proof** — Phases 102-105 (shipped 2026-05-31) — see `milestones/v1.28-ROADMAP.md`
- ✅ **v1.29 Contract Repair and Proof Hardening** — Phases 106-108 (shipped 2026-05-31) — see `milestones/v1.29-ROADMAP.md`
- ✅ **v1.30 Release Trust and Evidence Maintenance** — Phases 109-112 (shipped 2026-06-01) — see `milestones/v1.30-ROADMAP.md`
- ✅ **v1.31 Adoption Evidence Demo Hardening** — Phases 113-115 (UAT passed 2026-06-01)
- ✅ **v1.32 Admin UI/UX Design System Cleanup** — Phases 116-118 (shipped 2026-06-01) — see `milestones/v1.32-ROADMAP.md`
- ✅ **v1.33 Admin UI Insane Polish** — Phases 119-127 (shipped 2026-06-03) — see `milestones/v1.33-ROADMAP.md`
- ✅ **v1.34 Both-Themes Perfection — Dark Signature + AA Gate** — Phases 128-136 (shipped 2026-06-29; archived 2026-07-11) — see `milestones/v1.34-ROADMAP.md`
- ✅ **v1.35 Brand System & Logo Identity** — Phases 137-143 (shipped directly 2026-06-24; archived 2026-07-11) — see `milestones/v1.35-ROADMAP.md`
- ✅ **v1.36 Dependency Security Remediation** — Phases 144-147 (shipped 2026-08-25) — see `milestones/v1.36-ROADMAP.md`
- ✅ **v1.37 Code Quality Ratchet** — Phases 148-158 (implemented 2026-08-26; ready for milestone audit)

## Active Roadmap

**Milestone goal:** Systematically raise Scrypath's non-UI engineering quality until remaining opportunities are low-leverage, controversial, or unsupported by evidence. Preserve public behavior and APIs; only small additive APIs that materially simplify are in scope. ScrypathOps presentation, UX, and visual review are excluded.

[PHASE97-SCOPE-GUARD] Runtime breadth remains closed unless the established reopen-policy evidence is met; this milestone improves the existing library contract.

## Phases

- [x] **Phase 148: Quality Baseline** - Evidence ledger and executable behavior baseline before extraction.
- [x] **Phase 149: Runtime Safety Hardening** - Safe external inputs, secret handling, transport boundaries, telemetry, and task polling.
- [x] **Phase 150: Dependency-Leaf Core** - Remove metadata/composition runtime dependency cycles.
- [x] **Phase 151: Neutral Write Results** - Share one backend-neutral internal write-result contract.
- [x] **Phase 152: Configuration and Settings Boundaries** - Isolate options and settings responsibilities behind facades.
- [x] **Phase 153: Search and Failed-Work Boundaries** - Separate orchestration responsibilities without public behavior change.
- [x] **Phase 154: Canonical Verification Commands** - Capability-named checks with compatible historical focused commands.
- [x] **Phase 155: Lean, Independent CI Proof** - Deduplicate proof and strengthen independent core-library quality checks.
- [x] **Phase 156: Workflow and Release Supply-Chain Trust** - Secure and retain the complete release proof chain.
- [x] **Phase 157: Evidence-Based Performance** - Baseline stable hot paths and accept only measured optimizations.
- [x] **Phase 158: Ratchet Closeout** - Finish with targeted cleanup and evidence-backed disposition of findings.

## Phase Details

### Phase 148: Quality Baseline
**Goal**: Maintainers can identify quality work by evidence and safely preserve existing behavior before any extraction or cleanup.
**Depends on**: Nothing
**Requirements**: QUAL-01, TEST-01, TEST-03, TEST-04, TEST-05
**Success Criteria** (what must be TRUE):
  1. Maintainers can inspect one ranked quality ledger recording each finding's evidence, impact, expected benefit, churn, verification method, and disposition.
  2. Every later extraction has characterization coverage demonstrating its existing public behavior before the extraction begins.
  3. Test-source diagnostics, support-file discovery warnings, and local telemetry-handler warnings fail the relevant quality gate.
  4. The root library compiles with optional dependencies absent and warnings treated as errors.
  5. Scheduled/manual coverage is available as informational evidence without a percentage threshold.
**Plans**: Direct execution complete

### Phase 149: Runtime Safety Hardening
**Goal**: External runtime input and operational failures cannot create unsafe state, leak credentials, bypass configured transport boundaries, or hide incomplete backend work.
**Depends on**: Phase 148
**Requirements**: SAFE-01, SAFE-02, SAFE-03, SAFE-04, SAFE-05, TEST-02
**Success Criteria** (what must be TRUE):
  1. Supplying arbitrary external values never increases the VM atom table, and invalid values retain compatible failure behavior.
  2. Oban payloads, retries, failed-work views, and telemetry never persist or expose a Meilisearch API key; workers resolve credentials at execution.
  3. Supported transport/test `req_options` remain usable but cannot replace configured endpoint or authentication.
  4. Existing telemetry event names remain stable while error metadata is bounded, sanitized, and credential-safe.
  5. Meilisearch task polling terminates within configured bounds and explicitly reports partial or truncated observation.
**Plans**: Direct execution complete

### Phase 150: Dependency-Leaf Core
**Goal**: Scrypath's internal metadata and composition paths have a one-way dependency structure with no runtime xref cycles.
**Depends on**: Phase 148, Phase 149
**Requirements**: ARCH-01, ARCH-02, ARCH-03
**Success Criteria** (what must be TRUE):
  1. Lower-layer code reads schema metadata through a dedicated internal reader rather than calling upward through the public facade.
  2. Composition and `Ecto.Multi` behavior uses one shared internal composition pipeline without a module dependency cycle.
  3. The canonical runtime xref check reports zero cycles.
  4. Existing composition, tenant, and error behavior remains covered by characterization and property tests.
**Plans**: Direct execution complete

### Phase 151: Neutral Write Results
**Goal**: Sync and backfill orchestration consume one stable internal result vocabulary without branching on Meilisearch task payload details.
**Depends on**: Phase 150
**Requirements**: ARCH-04
**Success Criteria** (what must be TRUE):
  1. Common sync and backfill paths consume the same backend-neutral internal write-result contract.
  2. Inline, manual, and Oban flows preserve accepted, completed, and error semantics.
  3. Backend-native task detail remains confined to the explicit backend namespace.
  4. Existing public return shapes and operator-facing lifecycle distinctions remain unchanged.
**Plans**: Direct execution complete

### Phase 152: Configuration and Settings Boundaries
**Goal**: Configuration validation and Meilisearch settings logic are focused, testable internal responsibilities while public behavior remains unchanged.
**Depends on**: Phase 151
**Requirements**: ARCH-05, ARCH-06
**Success Criteria** (what must be TRUE):
  1. `Scrypath.Options` delegates settings, faceting, and search validation to focused internal modules without changing accepted inputs or errors.
  2. Meilisearch settings resolution and wire translation can be exercised as pure behavior.
  3. Settings mutation and drift inspection remain behind the Meilisearch facade.
  4. Existing settings application, drift, and reindex workflows retain observable outcomes.
**Plans**: Direct execution complete

### Phase 153: Search and Failed-Work Boundaries
**Goal**: Search and failed-work behavior remains stable while each orchestration concern becomes independently understandable and testable.
**Depends on**: Phase 152
**Requirements**: ARCH-07, ARCH-08
**Success Criteria** (what must be TRUE):
  1. Single-search, facet-search, and multi-search orchestration are separate paths while preserving public telemetry, result, and error behavior.
  2. Failed-work retrieval, translation/classification, and telemetry are separate responsibilities.
  3. Failed-work structs and retryability/error classifications remain compatible for operators and Mix-task callers.
  4. Search and recovery flows retain tenant, pagination, backend-error, and telemetry contracts.
**Plans**: Direct execution complete

### Phase 154: Canonical Verification Commands
**Goal**: Contributors use clear capability-named verification commands without breaking historical workflow entry points.
**Depends on**: Phase 148, Phase 153
**Requirements**: CI-01, CI-02
**Success Criteria** (what must be TRUE):
  1. Contributor documentation and CI invoke canonical commands named for the capability they verify.
  2. Historical `mix verify.phase*` tasks remain compatible focused commands with strict argument handling.
  3. Contributor guidance maps historical focused proof to canonical replacements without weakening proof.
  4. Focused proof demonstrates that each canonical command and wrapper enforce the same capability contract.
**Plans**: Direct execution complete

### Phase 155: Lean, Independent CI Proof
**Goal**: The repository preserves its required proof while CI removes duplicate execution and independently validates core-library quality.
**Depends on**: Phase 154
**Requirements**: CI-03, CI-04, CI-05, CI-06
**Success Criteria** (what must be TRUE):
  1. Root fast tests, docs, and live-Meilisearch suites each run once per intended CI path with proof obligations preserved.
  2. Cache keys cover build inputs and failure diagnostics remain actionable without secret disclosure.
  3. Compatibility CI exercises valid representative Elixir 1.17-1.19 / OTP 26-28 tuples without a Cartesian matrix.
  4. Root Dialyzer, Hex audit, namespace fence, and no-optional-dependencies proof run independently of ScrypathOps.
  5. Required/advisory job boundaries remain explicit, including the required mounted ecommerce gate.
**Plans**: Direct execution complete

### Phase 156: Workflow and Release Supply-Chain Trust
**Goal**: CI/CD and release automation remain secure, reviewable, and complete from pre-publish proof through consumer and documentation parity.
**Depends on**: Phase 155
**Requirements**: CI-07, CI-08
**Success Criteria** (what must be TRUE):
  1. Actions are pinned to immutable SHAs and execute with least-privilege permissions.
  2. Workflow edits receive syntax, pin, and dependency-review coverage.
  3. Release dry-run, publish, consumer verification, HexDocs publication, and release-parity proof remain an ordered intact chain.
  4. Failure output provides actionable release diagnostics without exposing credentials.
**Plans**: Direct execution complete

### Phase 157: Evidence-Based Performance
**Goal**: Maintainers can distinguish real, repeatable performance gains from speculative optimization.
**Depends on**: Phase 153, Phase 155
**Requirements**: PERF-01, PERF-02
**Success Criteria** (what must be TRUE):
  1. Stable pure hot paths have reproducible elapsed-time, memory, and reductions baselines under documented conditions.
  2. Baselines are informational evidence, not a manufactured threshold.
  3. Any accepted optimization includes before/after evidence against the baseline.
  4. Optimized behavior retains correctness, warning-free, and quality-gate evidence.
**Plans**: Direct execution complete

### Phase 158: Ratchet Closeout
**Goal**: The milestone ends with only low-leverage, controversial, or unsupported quality opportunities remaining.
**Depends on**: Phases 149-157
**Requirements**: QUAL-02, QUAL-03
**Success Criteria** (what must be TRUE):
  1. Cleanup is limited to touched code and removes only redundant history comments or duplication supported by the quality ledger.
  2. No repository-wide cosmetic sweep is introduced.
  3. The final ledger shows no confirmed compatible high- or medium-leverage finding without an implemented resolution or evidence-backed disposition.
  4. Closeout evidence confirms public APIs/behavior remain preserved and ScrypathOps presentation/UX was excluded.
**Plans**: Direct execution complete

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 148. Quality Baseline | Direct | Complete | 2026-08-26 |
| 149. Runtime Safety Hardening | Direct | Complete | 2026-08-26 |
| 150. Dependency-Leaf Core | Direct | Complete | 2026-08-26 |
| 151. Neutral Write Results | Direct | Complete | 2026-08-26 |
| 152. Configuration and Settings Boundaries | Direct | Complete | 2026-08-26 |
| 153. Search and Failed-Work Boundaries | Direct | Complete | 2026-08-26 |
| 154. Canonical Verification Commands | Direct | Complete | 2026-08-26 |
| 155. Lean, Independent CI Proof | Direct | Complete | 2026-08-26 |
| 156. Workflow and Release Supply-Chain Trust | Direct | Complete | 2026-08-26 |
| 157. Evidence-Based Performance | Direct | Complete | 2026-08-26 |
| 158. Ratchet Closeout | Direct | Complete | 2026-08-26 |

## Historical Milestone Note

Historical phase details and evidence live under `milestones/`. Phases 137-143 are direct-completion history and must never be synthesized or reused.

### Phase 159: Audit Gap Closure — Coverage Wiring and Verification Provenance

**Goal:** Maintainers can close v1.37 with a scheduled/manual informational coverage artifact and truthful, exact-SHA verification provenance that preserves original requirement ownership and historical limitations.
**Requirements**: TBD
**Scope note:** No requirements are newly mapped; this phase repairs TEST-05's integration path and restores evidence for the original Phase 148–158 ownership.
**Depends on:** Phase 158
**Plans:** 7 plans

Plans:
**Wave 1**

- [ ] 159-01-PLAN.md — Wire and structurally prove the scheduled/manual advisory coverage tracer.

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 159-02-PLAN.md — Run bounded Git forensics and build the canonical 31-row evidence matrix.

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 159-03-PLAN.md — Restore retrospective SUMMARY/VERIFICATION indexes for Phases 148–151.
- [ ] 159-04-PLAN.md — Restore retrospective SUMMARY/VERIFICATION indexes for Phases 152–155.
- [ ] 159-05-PLAN.md — Restore retrospective SUMMARY/VERIFICATION indexes for Phases 156–158.

**Wave 4** *(blocked on Wave 3 completion)*

- [ ] 159-06-PLAN.md — Perform per-phase Nyquist validation and reconcile the Phase 159 task map.

**Wave 5** *(blocked on Wave 4 completion)*

- [ ] 159-07-PLAN.md — Capture local/hosted exact-SHA closure evidence, rerun the audit last, and obtain human provenance approval.
