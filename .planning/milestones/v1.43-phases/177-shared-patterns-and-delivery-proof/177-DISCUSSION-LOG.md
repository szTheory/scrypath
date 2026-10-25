# Phase 177: Shared Patterns and Delivery Proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `177-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-10-11
**Phase:** 177-Shared Patterns and Delivery Proof
**Areas discussed:** Shared six-surface vocabulary and design catalog; requirement-level verification and delivery evidence; release decision and task-owned cleanup

---

The user authorized automatic follow-through on recommendations and requested broad, adversarial, multidisciplinary consideration. All gray areas were selected in one pass; the options below show the recommended choices selected automatically under that authorization, not individual interactive user selections. We compared product/design, accessibility, Phoenix/LiveView engineering, QA, security, DevOps/release, operator, and maintainer perspectives. No new dependency or required CI service is recommended.

## Shared six-surface vocabulary and design catalog

| Option | Description | Selected |
|--------|-------------|----------|
| Evidence-led inventory and bounded corrections | Inspect all six surfaces; document patterns proven by current source; fix only concrete drift. | ✓ Auto-selected recommendation |
| Catalog-driven general componentization | Turn each pattern into a new abstraction and standardize all screens around it. | |
| Documentation-only inventory | Update docs even if audit finds source inconsistencies. | |
| Broad visual normalization/redesign | Reopen all surfaces and replace the current visual system. | |

**Auto-selected choice:** Evidence-led inventory and bounded corrections (recommended; user authorized automatic recommendations).
**Notes:** W3C WCAG 2.2 consistent-identification guidance applies to repeated components with the same function; it explicitly allows context-sensitive identification and does not require visually similar components with different functions to use the same labels. Reuse the existing `OpsUi` and token contract. The exploratory brand book is not a binding visual contract. Root `DESIGN.md` is absent and is an in-scope documentation deliverable; root `PRODUCT.md` is also absent, so `.planning/PROJECT.md` and the approved v1.43 scope remain current product truth.

## Requirement-level verification and delivery evidence

| Option | Description | Selected |
|--------|-------------|----------|
| Linked requirement-level trace | For each of 20 requirements, link prior/current verification, actual source SHA, reviewed PR source, and applicable exact-SHA required checks. | ✓ Auto-selected recommendation |
| Copied aggregate evidence bundle | Duplicate all previous reports in one new report. | |
| New CI artifact/attestation system | Add workflows/permissions/artifact retention to generate new evidence infrastructure. | |
| Rerun every historical requirement | Repeat all closed phase suites as one final gate. | |

**Auto-selected choice:** One linked 20-row trace with existing reports authoritative (recommended; user authorized automatic recommendations).
**Notes:** Reuse prior local evidence only at its recorded source/scenario. Distinguish local phase proof from hosted PR evidence and name the SHA that each CI job tested. A green branch or PR approval does not itself prove each requirement's behavior. Do not create a new verification service or claim hosted proof where unavailable. Finish bookkeeping before any final-source attestation.

## Release decision and task-owned cleanup

| Option | Description | Selected |
|--------|-------------|----------|
| Decide from final package contents | No Hex release for Ops/planning-only changes excluded from the package; re-evaluate if package-included files change. | ✓ Auto-selected recommendation |
| Release for milestone completion | Publish/bump a package to mark planning milestone completion. | |
| Assume no release without checking | Rely on phase scope without verifying the package boundary. | |
| Owner-aware cleanup | Record and remove task-owned disposable stacks while preserving preview 4012 and its volumes. | ✓ Auto-selected recommendation |
| Generic cleanup note | Record only that cleanup happened. | |
| Stop all operator UI services | Stop unrelated or retained preview services alongside disposable test resources. | |

**Auto-selected choices:** Package-diff-based release decision and explicit ownership ledger with preview retention (recommended; user authorized automatic recommendations).
**Notes:** The current repository indicates `scrypath_ops/` is excluded from the Hex package, so no release is expected if the final package file set confirms this remains true. Hex publication is public/versioned, so do not use a milestone label as a package version. Track owner, purpose, container/project, port, artifact collection, and cleanup for disposable resources. Keep the normal-checkout feedback preview and volumes at port 4012 untouched and do not count it as phase-worktree evidence.

## External sources and synthesis

- [W3C WCAG 2.2 — Consistent Identification](https://www.w3.org/WAI/WCAG22/Understanding/consistent-identification.html) supports predictable recognition for repeated same-function components while preserving contextual labels where function or purpose differs.
- [GitHub protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches) supports recording actual review and required status-check evidence against the delivery source.
- [GitHub Actions retention settings](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository) and [artifact attestations](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations) informed the distinction between traceability/provenance and requirement-level behavior proof; neither justifies adding new evidence infrastructure for this scope.
- [Hex publishing](https://hex.pm/docs/publish) and [Hex FAQ](https://hex.pm/docs/faq) informed the package-diff release posture. The no-release recommendation is an inference from those sources plus the repository's package boundary and Phase 177 scope.
- The UI pattern matrix and evidence matrix were independently assessed against exact source `02ea81aa2fed1ba45f16ec2bae532ea24c5ea761`; release/cleanup was assessed against the same source. No research agent edited files.

## the agent's Discretion

- Pick a compact format and useful examples for the 20-row trace.
- Select the smallest existing commands that validate actual changes; avoid redundant historical runs.

## Deferred Ideas

None.
