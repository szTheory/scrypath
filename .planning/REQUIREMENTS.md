# Requirements: Scrypath v1.37 Code Quality Ratchet

**Milestone goal:** Systematically raise Scrypath's non-UI engineering quality until remaining opportunities are low-leverage, controversial, or unsupported by evidence.

## Scope

All non-UI library, operator API, test, Mix task, example, CI/CD, and release surfaces are in scope. ScrypathOps presentation, UX, and visual review are excluded. Preserve existing public behavior/APIs; additive APIs are permitted only when materially simplifying.

## Requirements

### Runtime Safety

- [ ] **SAFE-01**: Runtime external values cannot create atoms.
- [ ] **SAFE-02**: Oban payload/recovery never persist or expose Meilisearch API key; workers resolve secrets at runtime.
- [ ] **SAFE-03**: `req_options` cannot override configured endpoint/auth while transport/test options remain compatible.
- [ ] **SAFE-04**: Telemetry keeps event names but emits bounded sanitized error metadata.
- [ ] **SAFE-05**: Bounded Meilisearch task pagination with explicit partial/truncated observation.

### Architecture

- [ ] **ARCH-01**: Internal schema metadata readers remove lower-layer callbacks through Scrypath facade.
- [ ] **ARCH-02**: Shared internal composition pipeline removes Composition/Multi cycle.
- [ ] **ARCH-03**: Mix xref runtime cycles = zero.
- [ ] **ARCH-04**: Common sync/backfill use one backend-neutral internal write-result contract.
- [ ] **ARCH-05**: `Scrypath.Options` delegates settings/faceting/search validation to focused internal modules preserving behavior.
- [ ] **ARCH-06**: Meilisearch settings pure resolution/wire translation separated from mutation/drift behind facade.
- [ ] **ARCH-07**: Search separates single/facet/many orchestration preserving telemetry/errors.
- [ ] **ARCH-08**: FailedWork separates retrieval, translation/classification, telemetry preserving struct/classes.

### Test Quality

- [ ] **TEST-01**: Characterization tests lock behavior before each extraction.
- [ ] **TEST-02**: Targeted property tests cover normalization idempotence, tenant preservation, settings, composition, decoder safety.
- [ ] **TEST-03**: Test-source warnings fatal; zero support-file discovery/local telemetry handler warnings.
- [ ] **TEST-04**: Root library compiles without optional dependencies warnings-as-errors.
- [ ] **TEST-05**: Scheduled/manual informational coverage, no threshold.

### CI/CD and Release

- [ ] **CI-01**: Capability-named canonical verify commands.
- [ ] **CI-02**: All `verify.phase*` tasks remain thin compatible wrappers with strict args/replacement guidance.
- [ ] **CI-03**: Root fast suite/docs/live-Meili suite each execute once while proof preserved.
- [ ] **CI-04**: Correct cache keys and secret-safe failure diagnostics.
- [ ] **CI-05**: Valid compatibility tuples cover Elixir 1.17-1.19 / OTP 26-28 without Cartesian matrix.
- [ ] **CI-06**: Root Dialyzer/Hex audit/namespace/no-optional proof independent from `scrypath_ops`.
- [ ] **CI-07**: Action SHA pinning, least permissions, workflow pin/syntax check, dependency review.
- [ ] **CI-08**: Release dry-run/publish/consumer/HexDocs/parity chain intact.

### Performance

- [ ] **PERF-01**: Reproducible time/memory/reductions baselines for stable pure hot paths; profile first.
- [ ] **PERF-02**: Runtime optimizations require before/after evidence and no quality regression.

### Quality Closeout

- [ ] **QUAL-01**: Ranked quality ledger with evidence/impact/benefit/churn/verification/disposition.
- [ ] **QUAL-02**: Touched-code-only cleanup of redundant history comments/duplication; no cosmetic sweep.
- [ ] **QUAL-03**: Close only when no confirmed high/medium-leverage compatible findings remain.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SAFE-01 | Phase 149 | Pending |
| SAFE-02 | Phase 149 | Pending |
| SAFE-03 | Phase 149 | Pending |
| SAFE-04 | Phase 149 | Pending |
| SAFE-05 | Phase 149 | Pending |
| ARCH-01 | Phase 150 | Pending |
| ARCH-02 | Phase 150 | Pending |
| ARCH-03 | Phase 150 | Pending |
| ARCH-04 | Phase 151 | Pending |
| ARCH-05 | Phase 152 | Pending |
| ARCH-06 | Phase 152 | Pending |
| ARCH-07 | Phase 153 | Pending |
| ARCH-08 | Phase 153 | Pending |
| TEST-01 | Phase 148 | Pending |
| TEST-02 | Phase 149 | Pending |
| TEST-03 | Phase 148 | Pending |
| TEST-04 | Phase 148 | Pending |
| TEST-05 | Phase 148 | Pending |
| CI-01 | Phase 154 | Pending |
| CI-02 | Phase 154 | Pending |
| CI-03 | Phase 155 | Pending |
| CI-04 | Phase 155 | Pending |
| CI-05 | Phase 155 | Pending |
| CI-06 | Phase 155 | Pending |
| CI-07 | Phase 156 | Pending |
| CI-08 | Phase 156 | Pending |
| PERF-01 | Phase 157 | Pending |
| PERF-02 | Phase 157 | Pending |
| QUAL-01 | Phase 148 | Pending |
| QUAL-02 | Phase 158 | Pending |
| QUAL-03 | Phase 158 | Pending |

**Coverage:** 31/31 requirements mapped exactly once.
