# Phase 159: Audit Gap Closure — Coverage Wiring and Verification Provenance - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-26
**Phase:** 159-audit-gap-closure-coverage-wiring-and-verification-provenance
**Areas discussed:** Coverage evidence lane, Characterization chronology, Verification provenance artifact shape, Closure evidence bar

---

## Coverage Evidence Lane

| Option | Description | Selected |
|--------|-------------|----------|
| Local command only | Keep `mix verify.coverage` as an occasional maintainer command with no centralized artifact. | |
| Every PR/push | Run and retain coverage for each code change, accepting duplicate suite cost and PR/check noise. | |
| Scheduled/manual advisory artifact | Reuse built-in Mix coverage on schedule/manual dispatch, keep it non-blocking, and retain `cover/` briefly. | ✓ |
| Hosted coverage service | Add richer trends/annotations through ExCoveralls, Codecov, or another reporting integration. | |

**User's choice:** Accepted the complete researched recommendation set.
**Notes:** Preserve Phase 148's dependency-free, threshold-free fast-suite contract. Reuse the existing daily schedule/manual workflow and seven-day artifact pattern; add structural wiring tests and contributor guidance. No badge, PR comment, hosted service, converter, token, or artifact attestation.

---

## Characterization Chronology

| Option | Description | Selected |
|--------|-------------|----------|
| Treat current tests as historical proof | Use present passing tests to claim characterization preceded every extraction. | |
| Mark all chronology unproven | Preserve maximum caution but discard any exact evidence recoverable from Git. | |
| Infer chronology from commits | Treat commit titles, filenames, and ordering as sufficient evidence. | |
| Evidence-tier hybrid | Prove only reproducible Git-backed slices, label current verification separately, and waive irrecoverable history. | ✓ |

**User's choice:** Accepted the complete researched recommendation set.
**Notes:** Repository history contains mixed production/test commits and runtime work before the later quality-baseline commit. TEST-01 must fail closed wherever parent-revision tests cannot genuinely prove pre-extraction coverage; do not rewrite the requirement for a cosmetic score.

---

## Verification Provenance Artifact Shape

| Option | Description | Selected |
|--------|-------------|----------|
| One Phase 159 report only | Keep navigation simple but leave historical phase inputs absent for formal audit machinery. | |
| Independent full narratives per phase | Recreate extensive phase-local stories at high duplication and synthetic-history risk. | |
| Reassign requirements to Phase 159 | Make formal accounting easy by erasing original ownership. | |
| Canonical matrix plus thin phase-local indexes | Keep one authoritative matrix and restore explicitly retrospective SUMMARY/VERIFICATION/VALIDATION inputs. | ✓ |

**User's choice:** Accepted the complete researched recommendation set.
**Notes:** Phase-local records must be short indexes, not duplicated truth. Preserve original requirement ownership, invent no plans, and label every retrospective artifact and evidence limitation explicitly.

---

## Closure Evidence Bar

| Option | Description | Selected |
|--------|-------------|----------|
| Local deterministic checks only | Reproduce code quality locally without proving the hosted workflow/artifact connection. | |
| Rerun every external lane | Maximize contemporary evidence at disproportionate cost and flake exposure. | |
| Bounded exact-SHA closure | Require the local bundle plus one exact-commit hosted run of required jobs and the new coverage artifact flow. | ✓ |
| Reuse historical evidence only | Avoid new external proof while leaving the repaired CI seam unverified. | |

**User's choice:** Accepted the complete researched recommendation set.
**Notes:** Existing required jobs stay required; advisory and path-scoped jobs retain their classifications. Record same-run advisory outcomes when available, but do not publish Hex or reopen unrelated release, compatibility, UI, or browser work.

---

## the agent's Discretion

- Exact evidence-matrix column widths, cross-link wording, detached-worktree directory names, and coverage artifact name may follow established repository patterns.
- Retrospective artifact generation may be mechanically batched, but each verdict must derive from phase-specific requirements and actual evidence.
- Existing daily schedule timing and seven-day retention may be reused without adding another cron or retention policy.

## Deferred Ideas

- Hosted coverage dashboards, PR annotations, historical trends, branch/delta thresholds, mutation testing, and automatic commit-structure enforcement.
- Artifact attestations for future published release assets.
- UI, ScrypathOps presentation, accessibility, theme, graphic-design, and brand work.
