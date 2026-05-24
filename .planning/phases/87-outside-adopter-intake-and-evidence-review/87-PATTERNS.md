# Phase 87: Outside-Adopter Intake And Evidence Review - Pattern Map

## Closest Existing Analogs

### `guides/support-and-compatibility.md`, `README.md`, `CONTRIBUTING.md`

Use the Phase 86 pattern:

- one canonical guide owns the contract
- short docs route to it
- maintainer docs name the workflow without duplicating the guide body

Planner guidance:

- the new intake guide should follow the same authority split
- route from `README.md` and `guides/support-and-compatibility.md`
- keep `CONTRIBUTING.md` focused on maintainer review workflow and CI parity

### `test/scrypath/readiness_contract_test.exs`

Use the existing readiness-contract style:

- assert file existence
- assert short docs route to canonical authority
- assert exact command/env vocabulary for `mix verify.adopter`

Planner guidance:

- extend this test with bounded assertions for the new intake guide and evidence-path routing
- do not turn it into a full markdown parser or broad snapshot harness

### `test/scrypath/docs_contract_test.exs`

Use the existing docs-contract style:

- string containment checks
- ordering checks where routing priority matters
- branch-tip truth assertions, not prose freeze

Planner guidance:

- add only the structural assertions needed to keep the intake guide, template, and repo-clone boundary discoverable
- use order assertions if README or guides overview gain new wayfinding bullets

### `.planning/phases/86-*/86-03-PLAN.md`

Use the Phase 86 planning-truth update pattern:

- separate branch-tip truth updates from the earlier docs/task work
- use grep-based verification on `.planning/*` files
- keep archive nuance explicit without rewriting history

Planner guidance:

- Phase 87 final verdict updates should be isolated in `87-03`
- update rolling planning truth only after reviewed evidence exists

### `.planning/milestones/v1.17-phases/70-*.md`

Use the Phase 70 evidence-backed papercut + readiness-close pattern:

- bounded evidence first
- then milestone close bookkeeping
- explicit next-step verdict in a separate final plan

Planner guidance:

- `87-02` should own the reviewed attempts and classifications
- `87-03` should own the verdict and rolling truth updates

## File-Level Recommendations

### Public files likely touched in 87-01

- `guides/outside-adopter-intake.md`
- `README.md`
- `guides/support-and-compatibility.md`
- `CONTRIBUTING.md`
- `guides/overview.md` if the new guide is published there
- `mix.exs` if ExDoc extras/groups need the new guide
- `test/scrypath/readiness_contract_test.exs`
- `test/scrypath/docs_contract_test.exs`
- optional `.github/ISSUE_TEMPLATE/outside-adopter-evidence.*`

### Planning files likely touched in 87-02

- `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-EVIDENCE-REVIEW.md`
- `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-ATTEMPT-01.md`
- `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-ATTEMPT-02.md`

### Planning files likely touched in 87-03

- `.planning/PROJECT.md`
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `docs/jtbd-gap-map.md`
- `.planning/phases/87-outside-adopter-intake-and-evidence-review/87-VERDICT.md`

## Boundary Rules

- Do not create a second support matrix beside `guides/support-and-compatibility.md`.
- Do not make a GitHub issue template the only canonical evidence template.
- Do not let planning truth claim reviewed evidence before the two attempts are actually captured.
- Do not let one vivid anecdote override the locked ranking without repeated defended-path evidence.
