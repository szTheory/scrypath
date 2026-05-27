# Phase 101: ci-compatibility-truth-and-drift-guard-completion - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves alternatives considered.

**Date:** 2026-05-27
**Phase:** 101-ci-compatibility-truth-and-drift-guard-completion
**Areas discussed:** Compatibility truth resolution path, Supported-range semantics, Drift guard assertion strategy, Surface ownership and routing

---

## Compatibility truth resolution path

| Option | Description | Selected |
|--------|-------------|----------|
| Docs-first correction | Update support wording to match current CI lanes without changing CI topology | |
| CI-first full alignment | Add missing compatibility evidence lanes so current support claims are executable truth | ✓ |
| Policy reset + split lanes | Keep required checks lean while introducing compatibility-truth lane semantics | ✓ |
| Compatibility manifest first | Introduce generated single-source contract manifest before parity closure | |

**User's choice:** Discuss/consider all with one-shot recommendation set; lock cohesive recommendations.
**Notes:** Recommendation emphasized executable trust parity first, with required-check stability preserved.

---

## Supported-range semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Tuple-only support | Only exact CI tuples are documented as supported | |
| Range-only support | Broad range claim without explicit CI-evidence split | |
| Range + evidence | Declared support range plus explicit currently tested tuples | ✓ |
| Tiered support model | Canonical owner shows policy tiers (supported, CI-verified, boundaries) | ✓ |

**User's choice:** One-shot cohesive recommendation; no additional back-and-forth requested.
**Notes:** Recommended model combines clarity for adopters with defensible CI evidence and least-surprise wording.

---

## Drift guard assertion strategy (CI/version parity)

| Option | Description | Selected |
|--------|-------------|----------|
| Literal token checks only | Expand `String.contains?` checks without semantic normalization | |
| Normalized semantic parity checks | Parse normalized compatibility facts and compare support-guide claims vs CI/floor truth | ✓ |
| Manifest-driven parity | Introduce machine-readable compatibility contract source and project assertions from it | |
| Snapshot-style section checks | Compare full section snapshots across files | |

**User's choice:** One-shot recommendation set with deep tradeoff analysis and ecosystem lessons.
**Notes:** Recommended checks stay deterministic and actionable, avoid brittle prose snapshots, and fit existing phase99 trust-lane architecture.

---

## Surface ownership and routing for compatibility matrix

| Option | Description | Selected |
|--------|-------------|----------|
| Strict single owner | Support guide owns all compatibility details; all other surfaces route only | |
| Full duplication | Repeat full matrix in README/CONTRIBUTING/support guide | |
| Single owner + micro-contract routing | Canonical owner in support guide; route-first tokens elsewhere without competing matrix values | ✓ |
| Generated mirrored snippets | Automation-generated matrix snippets mirrored to multiple surfaces | |

**User's choice:** Discuss all; provide coherent recommendations so no additional decision burden is needed.
**Notes:** Recommendation preserves authority boundaries from phases 97-100 and minimizes future drift risk.

---

## Claude's Discretion

- Exact CI lane topology implementation (matrix vs dedicated compatibility job) while preserving required-check token stability.
- Exact helper implementation shape for semantic parity assertions (`phase99_contract_test` primary ownership).
- Final micro-contract wording on non-owner surfaces as long as routing/authority boundaries remain intact.

## Deferred Ideas

- Contract-manifest/codegen system for docs+tests as a future hardening step.
- Broad CI matrix expansion beyond targeted compatibility-truth proof lanes.
- Any runtime or backend breadth changes (out of scope under active scope guard).
