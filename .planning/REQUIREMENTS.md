# Requirements: Scrypath v1.37 Code Quality Ratchet

**Milestone goal:** Systematically raise Scrypath's non-UI engineering quality until remaining opportunities are low-leverage, controversial, or unsupported by evidence.

## Scope

All non-UI library, operator API, test, Mix task, example, CI/CD, and release surfaces are in scope. ScrypathOps presentation, UX, and visual review are excluded. Preserve existing public behavior/APIs; additive APIs are permitted only when materially simplifying.

## Requirements

### Runtime Safety

- [x] **SAFE-01**: Runtime external values cannot create atoms.
- [x] **SAFE-02**: Oban payload/recovery never persist or expose Meilisearch API key; workers resolve secrets at runtime.
- [x] **SAFE-03**: `req_options` cannot override configured endpoint/auth while transport/test options remain compatible.
- [x] **SAFE-04**: Telemetry keeps event names but emits bounded sanitized error metadata.
- [x] **SAFE-05**: Bounded Meilisearch task pagination with explicit partial/truncated observation.

### Architecture

- [x] **ARCH-01**: Internal schema metadata readers remove lower-layer callbacks through Scrypath facade.
- [x] **ARCH-02**: Shared internal composition pipeline removes Composition/Multi cycle.
- [x] **ARCH-03**: Mix xref runtime cycles = zero.
- [x] **ARCH-04**: Common sync/backfill use one backend-neutral internal write-result contract.
- [x] **ARCH-05**: `Scrypath.Options` delegates settings/faceting/search validation to focused internal modules preserving behavior.
- [x] **ARCH-06**: Meilisearch settings pure resolution/wire translation separated from mutation/drift behind facade.
- [x] **ARCH-07**: Search separates single/facet/many orchestration preserving telemetry/errors.
- [x] **ARCH-08**: FailedWork separates retrieval, translation/classification, telemetry preserving struct/classes.

### Test Quality

- [x] **TEST-01**: Characterization tests lock behavior before each extraction.
- [x] **TEST-02**: Targeted property tests cover normalization idempotence, tenant preservation, settings, composition, decoder safety.
- [x] **TEST-03**: Test-source warnings fatal; zero support-file discovery/local telemetry handler warnings.
- [x] **TEST-04**: Root library compiles without optional dependencies warnings-as-errors.
- [x] **TEST-05**: Scheduled/manual informational coverage, no threshold.

### CI/CD and Release

- [x] **CI-01**: Capability-named canonical verify commands.
- [x] **CI-02**: Historical `verify.phase*` tasks remain compatible focused commands with strict args and canonical replacement guidance; no mechanical rewrite of bespoke proof.
- [x] **CI-03**: Root fast suite/docs/live-Meili suite each execute once while proof preserved.
- [x] **CI-04**: Correct cache keys and secret-safe failure diagnostics.
- [x] **CI-05**: Valid compatibility tuples cover Elixir 1.17-1.19 / OTP 26-28 without Cartesian matrix.
- [x] **CI-06**: Root Dialyzer/Hex audit/namespace/no-optional proof independent from `scrypath_ops`.
- [x] **CI-07**: Action SHA pinning, least permissions, workflow pin/syntax check, dependency review.
- [x] **CI-08**: Release dry-run/publish/consumer/HexDocs/parity chain intact.

### Performance

- [x] **PERF-01**: Reproducible time/memory/reductions baselines for stable pure hot paths; profile first.
- [x] **PERF-02**: Runtime optimizations require before/after evidence and no quality regression.

### Quality Closeout

- [x] **QUAL-01**: Ranked quality ledger with evidence/impact/benefit/churn/verification/disposition.
- [x] **QUAL-02**: Touched-code-only cleanup of redundant history comments/duplication; no cosmetic sweep.
- [x] **QUAL-03**: Close only when no confirmed high/medium-leverage compatible findings remain.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SAFE-01 | Phase 149 | Complete |
| SAFE-02 | Phase 149 | Complete |
| SAFE-03 | Phase 149 | Complete |
| SAFE-04 | Phase 149 | Complete |
| SAFE-05 | Phase 149 | Complete |
| ARCH-01 | Phase 150 | Complete |
| ARCH-02 | Phase 150 | Complete |
| ARCH-03 | Phase 150 | Complete |
| ARCH-04 | Phase 151 | Complete |
| ARCH-05 | Phase 152 | Complete |
| ARCH-06 | Phase 152 | Complete |
| ARCH-07 | Phase 153 | Complete |
| ARCH-08 | Phase 153 | Complete |
| TEST-01 | Phase 148 | Complete |
| TEST-02 | Phase 149 | Complete |
| TEST-03 | Phase 148 | Complete |
| TEST-04 | Phase 148 | Complete |
| TEST-05 | Phase 148 | Complete |
| CI-01 | Phase 154 | Complete |
| CI-02 | Phase 154 | Complete |
| CI-03 | Phase 155 | Complete |
| CI-04 | Phase 155 | Complete |
| CI-05 | Phase 155 | Complete |
| CI-06 | Phase 155 | Complete |
| CI-07 | Phase 156 | Complete |
| CI-08 | Phase 156 | Complete |
| PERF-01 | Phase 157 | Complete |
| PERF-02 | Phase 157 | Complete |
| QUAL-01 | Phase 148 | Complete |
| QUAL-02 | Phase 158 | Complete |
| QUAL-03 | Phase 158 | Complete |

**Coverage:** 31/31 requirements mapped exactly once.
