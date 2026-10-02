# Phase 169: Library Fix Delivery and PR Triage - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `169-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-09-28
**Phase:** 169-Library Fix Delivery and PR Triage
**Areas discussed:** Frozen Dependabot cohort, Planning-only history

---

## Frozen Dependabot cohort

| Option | Description | Selected |
|--------|-------------|----------|
| Evidence-gated decision per PR | Keep/update only when current evidence demonstrates security, compatibility, reliability, or material maintenance value; close/defer other updates with a revisit trigger. | ✓ |
| Merge every PR with green checks | Clear the cohort whenever current checks are green. | |
| Defer the whole cohort to maintenance | Defer all updates and keep the phase focused on the library fixes. | |

**User's choice:** `1` — approve the evidence-gated per-PR recommendation.
**Notes:** The frozen cohort is #65 and #68–76; its phase-start main/head/base identities are in `169-CONTEXT.md`. Refresh head/base and current evidence before action. A green check by itself is insufficient. New routine PRs remain in maintenance; material security or compatibility evidence can reopen scope; an empty inbox is not required. User requested specialist research per area, broad relevant engineering and maintainer lenses, tradeoffs, and developer ergonomics, then approved the synthesized recommendations.

---

## Planning-only history

| Option | Description | Selected |
|--------|-------------|----------|
| Current authority plus a compact delivery inventory | Record selected changes, source/evidence identities, and every remainder's path or disposition in existing canonical planning records; link historical material only when needed for a current decision or proof. | ✓ |
| A separate, selected archive PR | Publish a bounded set of v1.39/v1.40 archive records when current maintainer work needs them. | |
| Keep unpublished history local | Update current status but retain all earlier unpublished archive material locally. | |

**User's choice:** `1` — approve current authority plus a compact, source-linked inventory.
**Notes:** Keep historical assessments immutable. Planning archives should not delay runtime delivery, and the accumulated local history is not a delivery unit. A separate archive change remains suitable only when specific material is needed to understand a current decision or proof.

### Research references

- [GitHub Dependabot version-update guidance](https://docs.github.com/en/code-security/concepts/supply-chain-security/dependabot-version-updates)
- [GitHub PR grouping and cooldown guidance](https://docs.github.com/en/code-security/tutorials/secure-your-dependencies/optimizing-pr-creation-version-updates)
- [Mix `deps.update`](https://mix.hexdocs.pm/Mix.Tasks.Deps.Update.html)
- [Ecto changelog](https://github.com/elixir-ecto/ecto/blob/master/CHANGELOG.md)
- [Phoenix changelog](https://github.com/phoenixframework/phoenix/blob/main/CHANGELOG.md)
- [Google ADR guidance](https://docs.cloud.google.com/architecture/architecture-decision-records)
- [SLSA source requirements](https://slsa.dev/spec/v1.2/source-requirements)

## the agent's Discretion

- Recheck cohort PR metadata and evidence; choose each keep/update/close/defer disposition with an explicit reason and revisit trigger where relevant.
- Choose coherent PR grouping, targeted proof, and the precise owned-change inventory. Reuse historical semantic evidence only after relevant-source comparison.

## Deferred Ideas

None.
