---
title: Remediate reproduced dependency security advisories
status: completed
priority: high
category: security-dependency
created: 2026-08-16
completed: 2026-08-25
resolves_phase: 147
---

# Remediate reproduced dependency security advisories

## Result

The reproduced dependency advisories are remediated across root Scrypath, the legacy Phoenix example, ScrypathOps, and the ecommerce example. The authoritative current receipt is [Phase 147 closure evidence](../../phases/147-ecommerce-mounted-ops-remediation-and-closure-evidence/147-CLOSURE-EVIDENCE.md).

## Four ordered remediation batches

1. Shared Req compatibility handoff `f711521` updated the three direct manifests and four locks that consume the common HTTP cohort.
2. Legacy primary `e50fbd5` plus Plug recovery `4e2abed` completed the legacy-only graph and compatibility proof.
3. Ops primary `59d2e6a` plus test-only closure `ff1531c` completed the Ops graph and Swoosh contract proof.
4. Ecommerce implementation `fca4c82` independently remediated its mounted integration graph.

## Acceptance

- Each graph has an independent checked-lock and unsuppressed audit row in one Phase 147 UTC evidence window.
- Exact-SHA ecommerce fresh resolution, deterministic gates, service preparation, and focused Docker browser proof passed.
- Full Docker E2E automation passed 99 browser tests, 20 parity checks, and the AA contrast gate without human UAT.
- The ledger proves the ordered constituent commits and their path roles without rewriting history.
