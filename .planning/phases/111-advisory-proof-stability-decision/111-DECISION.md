# Phase 111 Advisory Proof Stability Decision

Date: 2026-06-01
Phase: 111-advisory-proof-stability-decision
Requirements: STAB-01, STAB-02

## Current Decision

Current decision: remain advisory in Phase 111

`phase105-e2e` stays advisory while we harden policy evidence and preserve the lean required merge blockers.

## Required vs Advisory Posture

- Required merge blockers remain: `main-ci`, `repo-hygiene`, `release-truth`, `phase99-trust`.
- `phase105-e2e` remains advisory evidence and is not promoted to required in this phase.
- no path-scoped required promotion
- no branch-protection change in Phase 111
- no new runtime APIs

## Evidence Model

Canonical stability (push to main + schedule)

Merge risk (pull_request)

Treat pre-change and post-change job identity evidence separately

## Promotion Threshold Contract

- 20 eligible runs
- 10 main/schedule runs
- 10 pull_request runs
- flake rate <= 5%
- p95 runtime <= 900 seconds
- artifacts classify failures without rerun
- owner response within 1 business day
- 14 calendar days
- 10 consecutive eligible pull requests

## Remote Evidence Snapshot (Frozen in Phase 111)

Command shape:

```bash
gh run list --workflow ci.yml --limit 25 --json databaseId,headSha,event,conclusion,createdAt,updatedAt
gh run view <run_id> --json jobs
```

Sample window taken on 2026-06-01 UTC from latest runs:

- Run `26684807477` (push, head `88dd8545a63e85f216d3a07517ff367f0ab41d79`, conclusion `success`)
- Run `26684609991` (pull_request, head `3e1048bf962abb2109a781857c1f9ad0a3007699`, conclusion `success`)
- Run `26684232995` (pull_request, head `c527d52afce3fa2461ed60b3e5bec6b2f0451c36`, conclusion `failure`)
- Run `26684212603` (push, head `6828ef2743964b4689138abe167d40662fd31c8f`, conclusion `success`)

Observed jobs in sampled runs include required and advisory lanes such as `main-ci`, `repo-hygiene`, `release-truth`, `phase99-trust`, `compatibility-truth`, `phase5-verification`, `phase13-verification`, `meilisearch-smoke`, `adopter-verify`, `phoenix-example-integration`, and `scrypath-ops` jobs.

Phase 111 rationale: the remote sample still does not provide enough stable, contiguous, directly useful `phase105-e2e` job evidence to satisfy the thresholds above for required-promotion readiness. This remains an evidence sufficiency issue, not a philosophical refusal to promote.

## Artifact Usefulness Standard

Bounded advisory artifacts should keep failure triage actionable:

- `phase105-playwright.json`
- `phase105-evidence.ndjson`
- `phase105-evidence.json`
- `phase105-evidence-summary.md`

Policy: artifacts classify failures without immediate rerun and support retry-as-flake interpretation.

## Promotion Path (Future, Not in Phase 111)

1. Keep advisory collection active with dual-window evidence tracking.
2. If thresholds hold, run a short shadow-required period with explicit rollback criteria.
3. Promote to required only after evidence gates hold and owner-response behavior stays within policy.
