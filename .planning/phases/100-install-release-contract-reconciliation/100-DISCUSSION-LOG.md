# Phase 100: Install/Release Contract Reconciliation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `100-CONTEXT.md` — this log preserves alternatives considered.

**Date:** 2026-05-27
**Phase:** 100-install-release-contract-reconciliation
**Areas discussed:** Install version contract token, Release-backed vs main wording, Surface ownership boundaries, Assertion strategy

---

## Install version contract token

| Option | Description | Selected |
|--------|-------------|----------|
| Uniform `~> 1.0` everywhere | Simple but incorrect pre-v1 and contradicts current release truth | |
| Uniform released minor token everywhere | Semver-correct today but still duplicates literals across many surfaces | |
| Exact patch token everywhere | Deterministic but high-churn and high maintenance noise | |
| Canonical owner + route-only references | One authority owns token; other surfaces route and avoid conflicting literals | ✓ |

**User's choice:** One-shot recommendation accepted: canonical-owner model with current release line token.
**Notes:** Subagent synthesis converged on support guide as authority and non-owner route discipline to reduce drift recurrence.

---

## Release-backed vs `main` wording

| Option | Description | Selected |
|--------|-------------|----------|
| Pointer-only canonical | Minimal duplication but weak first-hop clarity | |
| Micro-contract everywhere + canonical expansion | Short, repeated high-signal wording + one authority for full policy | ✓ |
| Dual-track table on each surface | Very explicit but verbose and maintenance-heavy | |
| Audience-split hard separation | Clean by audience but fragile when users jump between surfaces | |

**User's choice:** One-shot recommendation accepted: fixed micro-contract wording on entry surfaces, full policy in support guide.
**Notes:** Chosen for best least-surprise balance between immediate clarity and anti-drift maintainability.

---

## Surface ownership boundaries

| Option | Description | Selected |
|--------|-------------|----------|
| Strict single-canonical policy | Strongest drift resistance with clear ownership boundaries | ✓ |
| Topic-split canonicals | Better local convenience but increases cross-surface drift risk | |
| Audience-split canonicals | Contributor convenience but high policy duplication pressure | |
| Manifest-driven snippet generation | Strong automation but complexity overkill for phase scope | |

**User's choice:** One-shot recommendation accepted: strict layered ownership model.
**Notes:** Support guide = normative authority; README = first-hop routing; intake = evidence workflow; CONTRIBUTING = maintainer execution.

---

## Assertion strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Literal token parity only | Easy to read but misses semantic divergence | |
| Central constants map only | Better maintainability but still string-fragile alone | |
| Structured extractor checks only | Strong semantic detection but less explicit intent alone | |
| Hybrid: constants + structured extractors + owner guards | Strong semantic parity, low flake, bounded deterministic scope | ✓ |

**User's choice:** One-shot recommendation accepted: hybrid parity strategy in deterministic trust tests.
**Notes:** Keep scope bounded to TRUTH-01/TRUTH-02 in Phase 100; defer TRUTH-03 matrix parity to Phase 101.

---

## Claude's Discretion

- Exact sentence-level micro-contract wording.
- Exact helper names and assertion helper placement.
- Exact file-level split between phase trust-contract tests and broader docs-contract tests.

## Deferred Ideas

- Phase 101 CI/runtime compatibility truth parity (`TRUTH-03`, `TEST-01` remainder).
- Generalized manifest/snippet codegen for contract text.

