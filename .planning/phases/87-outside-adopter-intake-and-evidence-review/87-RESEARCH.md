# Phase 87: Outside-Adopter Intake And Evidence Review - Research

## Research Goal

Answer: what does Scrypath need to plan well for a phase that introduces one canonical outside-adopter intake path, reviews at least two real adopter attempts, and turns those reviews into a credible "stop soon vs reopen one wedge" verdict?

## Current Branch-Tip Facts

- `guides/support-and-compatibility.md` is the current support/readiness authority and already separates defended in-repo proof from outside-adopter evidence.
- `README.md` already routes support/readiness questions to that guide and keeps the Phoenix + Meilisearch path explicit.
- `examples/phoenix_meilisearch/README.md` already owns the live repo-clone runbook and the `mix verify.adopter --live` CI-shaped command sequence.
- `lib/mix/tasks/verify.adopter.ex`, `doc/Mix.Tasks.Verify.Adopter.md`, `CONTRIBUTING.md`, and `test/scrypath/readiness_contract_test.exs` already protect the fast/live proof-command family.
- No current in-tree intake guide, evidence template, or reviewed-attempt ledger exists for outside adopters.

## Planning Implications

### 1. The intake surface should be a thin new guide, not a second support matrix

The phase should add one canonical intake guide that:

- points to the defended repo-clone Phoenix + Meilisearch path
- names the `mix verify.adopter` fast/live family
- makes the repo-clone versus Hex-package boundary explicit
- defines the required evidence bundle and admissibility classes
- explains how maintainers classify and close findings

`README.md` and `guides/support-and-compatibility.md` should route to that guide, not restate it. `CONTRIBUTING.md` should name the maintainer review workflow but should not become the canonical checklist.

### 2. The evidence template must be repo-owned and reviewable in git

The simplest durable shape is:

- one canonical public-facing guide under `guides/`
- one canonical markdown evidence template under a stable repo path
- optional transport wiring under `.github/ISSUE_TEMPLATE/` only as a convenience layer

That preserves one repo-owned authority while still allowing a structured GitHub submission path later.

### 3. The review artifacts should live in the phase directory, not in adopter-facing docs

The two reviewed attempts and the verdict memo are milestone-planning artifacts, not permanent end-user docs. The cleanest artifact split is:

- adopter-facing guide/template in `guides/` and possibly `.github/ISSUE_TEMPLATE/`
- maintainer review evidence in `.planning/phases/87-outside-adopter-intake-and-evidence-review/`

That keeps shipped docs calm while still making the reviewed evidence durable and auditable.

### 4. The review plan must model an external-evidence checkpoint honestly

The repo currently does not contain two obvious reviewed outside-adopter attempts. Planning should not fake autonomy here. One plan should explicitly:

- create the review ledger and rubric
- ingest two real attempts once they exist
- classify each finding
- pause for human-supplied evidence if the attempts are not yet present

That means at least one Phase 87 plan should be `autonomous: false`.

### 5. The verdict update belongs in a separate final plan

The "stop soon vs reopen one wedge" decision should be isolated from intake-surface work and raw evidence review. Keeping the verdict in `87-03` avoids mixing:

- intake-authority edits
- raw attempt classification
- rolling milestone truth updates

The final plan should update planning truth only after the reviewed evidence exists.

## Recommended Artifact Layout

### Public / adopter-facing

- `guides/outside-adopter-intake.md` — canonical intake guide
- `docs/templates/outside-adopter-evidence.md` or `guides/outside-adopter-evidence-template.md` — canonical evidence bundle template
- optional `.github/ISSUE_TEMPLATE/outside-adopter-evidence.yml` or `.md` — transport convenience only

### Maintainer / planning-facing

- `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-EVIDENCE-REVIEW.md` — reviewed-attempt ledger
- `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-ATTEMPT-01.md`
- `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-ATTEMPT-02.md`
- `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-VERDICT.md` — verdict memo and next-pull decision

## Analog Patterns In This Repo

- Phase 86 used one canonical public guide plus short-doc routing and bounded docs/readiness tests.
- Phase 70 used bounded papercut fixes, docs-contract assertions, and a separate milestone-close plan after the evidence existed.
- Current `docs_contract_test.exs` favors structural string/order assertions rather than freezing large prose blocks.
- Current readiness verification already protects support/proof wording, so Phase 87 should extend those seams rather than invent a new verifier family.

## Risk Register

### Risk 1: Duplicate authority

If the new intake instructions are copied into `README.md`, `CONTRIBUTING.md`, and the support guide, the phase recreates the drift Phase 86 just repaired.

Mitigation:

- keep one canonical intake guide
- keep other docs link-shaped
- use bounded docs/readiness assertions to enforce routing

### Risk 2: Anecdote masquerading as evidence

If maintainers accept vague reports without commands, versions, or failure points, the verdict becomes story-driven instead of evidence-driven.

Mitigation:

- require exact command history, environment matrix, and first failure/confusion point
- classify attempts into Classes A-D
- record non-evidence separately from reviewed evidence

### Risk 3: Product verdict chosen before papercuts are separated

If docs/support/env papercuts are not separated from real product gaps, the phase may reopen the wrong wedge.

Mitigation:

- classify every finding first
- only let repeated, defended-path product gaps influence the wedge decision
- keep related-data first, tenant-safe access second, facet search later unless evidence clearly overturns that ranking

### Risk 4: False autonomy

Execution cannot honestly complete the review plan without two real adopter attempts.

Mitigation:

- mark the review plan as non-autonomous
- add a manual evidence checkpoint
- keep the intake surface plan and verdict-update plan separate so useful work can land before external evidence arrives

## Validation Architecture

Phase 87 should verify three distinct seams:

1. **Public intake authority**
   - docs/readiness/tests prove the new intake guide exists and the short docs route to it
2. **Evidence bundle and review ledger**
   - bounded shell checks prove the template, reviewed attempts, classifications, and verdict memo exist and contain the required buckets/classes
3. **Rolling milestone truth**
   - planning-file grep checks prove `ADOPT-01` through `ADOPT-03` and the next-pull verdict are reflected only after the reviewed evidence exists

## Recommended Plan Split

### Plan 87-01

Create the public intake path and canonical evidence template, then route README/support/contributing surfaces to it and add bounded docs/readiness guards.

### Plan 87-02

Review two real outside-adopter attempts using the new template/rubric, classify every finding, and preserve the evidence in phase-local planning artifacts. This plan should include a human checkpoint if the two attempts are not yet available.

### Plan 87-03

Update rolling planning truth only after the reviewed evidence exists, record the explicit verdict (`stop soon`, `related-data propagation`, or `tenant-safe access`), and keep the ranking guardrail explicit in planning artifacts.

## Suggested Verification Commands

- `mix test test/scrypath/readiness_contract_test.exs`
- `mix test test/scrypath/docs_contract_test.exs`
- `mix docs --warnings-as-errors`
- `rg -n "outside-adopter|verify\\.adopter|repo-clone|Hex-package|Class A|Class B|Class C|Class D|docs/onboarding gap|support-truth drift|product gap|env/setup papercut" <files>`
- `test -f` checks for phase-local review and verdict artifacts

## Recommendation

Plan Phase 87 as three plans:

1. public intake authority and bounded regression guards
2. non-autonomous review of two real adopter attempts with a durable classification ledger
3. rolling-planning and verdict updates after the evidence exists
