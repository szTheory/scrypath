# Architecture Research

**Project:** Scrypath v1.41
**Updated:** 2026-09-28 after fanout review

## Boundaries

No runtime architecture redesign is warranted. Keep responsibilities explicit:

| Owner | Contract |
|---|---|
| Each of four Mix projects | Its own resolved Mint/HPAX graph and audit; root lock does not govern host locks. |
| Existing Phoenix package harness | Package provenance and actual consumer graph identity after resolution. |
| Coherent PR and merged main | Delivered selected code with source-specific verification; preserved unrelated worktree state. |
| Release Please, published Hex artifact and parity receipts | Package availability and released support truth, distinct from local artifact version labels. |
| README / golden path / JTBD | Brief first-hour context, linear tutorial, and one job-oriented navigation set. |
| Sync guide / API reference | Operational semantics and exact return structures respectively. |
| Readiness authority and terminal evidence | Unchanged six-condition gate, finite claim inventory and dated source-specific judgment. |

## Sequence

1. Establish current public-main source and ownership boundary using supported GSD isolation; do not push the accumulated local branch.
2. Deliver affected-graph remediation and the mounted-readiness fix, prove resolved identities/applicable behavior, and cover the explicit graph inventory in the existing advisory audit lane independently of bulk history.
3. Integrate selected existing tenant/facet runtime fixes and their coherent proof; disposition the frozen PR cohort and owned local delta.
4. Consolidate docs, merge final selected edits, complete warranted release/parity and current delivery evidence.
5. Freeze tracked assessment inputs, archives and cleanup dispositions; attest the exact final source; issue the authoritative terminal decision outside that tested tree without a post-attestation tracked edit.

Downstream planning owns the exact PR partition, supported isolation mechanism, durable terminal-record surface and minimal verification implementation. Any external terminal record must be discoverable, durable beyond expiring CI artifacts, and explicitly combine semantic condition judgments with final evidence. Existing attestation alone certifies jobs/artifacts, not readiness.

## Guardrails

Preserve historical assessments and their dated claim limits. Reuse semantic evidence only after relevant-source comparisons; old SHAs do not become new-SHA receipts. Keep root, path consumer, package consumer, PR merge ref, squash-main and package identities explicit. No shared override that conceals vulnerable child locks, direct Mint dependency without separate policy evidence, new backend/auth facade, or automatic UI start.

See [SUMMARY.md](SUMMARY.md) and the three specialist review reports for provenance and rationale.
